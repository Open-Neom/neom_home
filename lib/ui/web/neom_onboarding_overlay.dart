import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:sint/sint.dart';

/// Data model for a frequency state card in the onboarding overlay.
/// Keeps this widget independent of neom_states — the app layer maps
/// [FrequencyState] objects into these before passing them in.
class OnboardingStateCard {
  final String id;
  final String name;
  final String description;
  final double binauralBeat;
  final Duration duration;
  final Color accentColor;
  final IconData icon;

  const OnboardingStateCard({
    required this.id,
    required this.name,
    required this.description,
    required this.binauralBeat,
    required this.duration,
    required this.accentColor,
    required this.icon,
  });
}

/// Full-screen onboarding overlay for Open Neom web.
///
/// 3 steps:
///   1. "Descubre tu Frecuencia" — simulated mic pitch detection
///   2. "Siente el Sonido" — breathing-synced pulsing circles
///   3. "Elige tu Estado" — 4 free state cards → navigate to /x/{stateId}
///
/// Shows only once per device (Hive flag `Open Neom_onboarded` in `settings` box).
class NeomOnboardingOverlay extends StatefulWidget {
  /// Free state cards to show in step 3.
  final List<OnboardingStateCard> stateCards;

  /// Called when the user taps a state card — typically `Sint.toNamed('/x/$id')`.
  final void Function(String stateId)? onStateSelected;

  /// Called when overlay is dismissed (skip, "Explorar primero", or state tap).
  /// The app layer should set the Hive flag here:
  ///   `Hive.box('settings').put('Open Neom_onboarded', true)`
  final VoidCallback? onDismiss;

  /// Audio callbacks — the app layer connects these to NeomSineEngine.
  /// Play the user's root frequency as a pure tone.
  final void Function(double frequencyHz)? onPlayFrequency;
  /// Play binaural beat: root frequency + beat offset.
  final void Function(double frequencyHz, double beatHz)? onPlayBinaural;
  /// Play frequency with spatial panning (L→R movement).
  final void Function(double frequencyHz)? onPlaySpatial;
  /// Stop all audio.
  final VoidCallback? onStopAudio;

  /// First visit: show audio demo with explanations.
  /// Subsequent visits: skip demo, go straight to state selection.
  final bool isFirstVisit;

  const NeomOnboardingOverlay({
    super.key,
    required this.stateCards,
    this.isFirstVisit = true,
    this.onStateSelected,
    this.onDismiss,
    this.onPlayFrequency,
    this.onPlayBinaural,
    this.onPlaySpatial,
    this.onStopAudio,
  });

  @override
  State<NeomOnboardingOverlay> createState() =>
      _NeomOnboardingOverlayState();
}

class _NeomOnboardingOverlayState
    extends State<NeomOnboardingOverlay> with TickerProviderStateMixin {
  // ── Navigation ───────────────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // ── Step 1: Frequency detection ──────────────────────────────
  bool _isRecording = false;
  bool _detectionComplete = false;
  double _detectedFrequency = 0;
  double _displayedFrequency = 0;
  late AnimationController _pulseController;
  late AnimationController _counterController;
  Timer? _counterTimer;

  // ── Step 2: Audio demo (pure → binaural 4Hz → binaural 20Hz → spatial) ──
  late AnimationController _breathController;
  Timer? _autoAdvanceTimer;
  double _step2Progress = 0;
  int _step2Phase = 0; // 0=pure, 1=binaural4, 2=binaural20, 3=spatial
  String _step2Label = '';
  static const _phaseDuration = Duration(seconds: 5);

  // ── Step transitions ─────────────────────────────────────────
  late AnimationController _fadeController;

  // ── Theme (derived from AppColor at runtime) ────────────────
  Color get _bgDark => AppColor.getMain().withAlpha(255); // #4F1964 for Open Neom
  Color get _bgMid => Color.lerp(AppColor.getMain(), Colors.black, 0.4)!;
  Color get _accent => AppColor.getAccentColor(); // #8C3CB4 for Open Neom

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _counterController.dispose();
    _breathController.dispose();
    _fadeController.dispose();
    _counterTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  // ── Step 1: Simulated recording ──────────────────────────────

  void _startRecording() {
    final rng = Random();
    _detectedFrequency = 150.0 + rng.nextDouble() * 250.0; // 150–400 Hz

    setState(() {
      _isRecording = true;
      _displayedFrequency = _detectedFrequency + (rng.nextDouble() - 0.5) * 100;
    });

    // Immediately start showing live frequency jitter
    int tick = 0;
    const totalTicks = 50; // 50 × 100ms = 5 seconds
    _counterTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      tick++;
      if (tick >= totalTicks) {
        t.cancel();
        setState(() {
          _displayedFrequency = _detectedFrequency;
          _isRecording = false;
          _detectionComplete = true;
        });
      } else {
        // Jitter decreases as we approach the end — converging to real value
        final jitterRange = 80.0 * (1.0 - tick / totalTicks);
        setState(() {
          _displayedFrequency =
              _detectedFrequency + (rng.nextDouble() - 0.5) * jitterRange;
        });
      }
    });
  }

  // ── Step 2: Auto-advance timer ───────────────────────────────

  void _startStep2Timer() {
    const tickMs = 100;
    final ticksPerPhase = _phaseDuration.inMilliseconds ~/ tickMs; // 30 ticks per 3s
    final totalPhases = 4;
    final totalTicks = ticksPerPhase * totalPhases;
    int tick = 0;

    // Start Phase 0: Pure frequency
    setState(() {
      _step2Phase = 0;
      _step2Label = 'Escucha tu frecuencia raíz: ${_detectedFrequency.toStringAsFixed(0)} Hz';
      _step2Progress = 0;
    });
    widget.onPlayFrequency?.call(_detectedFrequency);

    _autoAdvanceTimer = Timer.periodic(
      const Duration(milliseconds: tickMs),
      (t) {
        tick++;
        setState(() => _step2Progress = tick / totalTicks);

        // Phase transitions
        if (tick == ticksPerPhase && _step2Phase == 0) {
          // Phase 1: Binaural 4 Hz (Theta - meditación)
          setState(() {
            _step2Phase = 1;
            _step2Label = 'Beat binaural a 4 Hz — frecuencia de meditación profunda';
          });
          widget.onPlayBinaural?.call(_detectedFrequency, 4.0);
        } else if (tick == ticksPerPhase * 2 && _step2Phase == 1) {
          // Phase 2: Binaural 20 Hz (Beta - concentración)
          setState(() {
            _step2Phase = 2;
            _step2Label = 'Beat binaural a 20 Hz — frecuencia de concentración';
          });
          widget.onPlayBinaural?.call(_detectedFrequency, 20.0);
        } else if (tick == ticksPerPhase * 3 && _step2Phase == 2) {
          // Phase 3: Spatial panning (L → R movement)
          setState(() {
            _step2Phase = 3;
            _step2Label = 'Espacialización — tu frecuencia moviéndose entre oídos';
          });
          widget.onPlaySpatial?.call(_detectedFrequency);
        }

        if (tick >= totalTicks) {
          t.cancel();
          // Don't stop audio — leave frequency playing for navigation
          _dismiss();
        }
      },
    );
  }

  // ── Navigation helpers ───────────────────────────────────────

  void _goToStep(int step) {
    _autoAdvanceTimer?.cancel();
    _fadeController.reverse().then((_) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep = step);
      _fadeController.forward();

      if (step == 1) _startStep2Timer();
    });
  }

  void _dismiss() {
    // Don't stop audio — frequency stays active during navigation
    _autoAdvanceTimer?.cancel();
    widget.onDismiss?.call();
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _breathController,
            builder: (_, _) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _bgDark,
                    Color.lerp(_bgDark, _bgMid, _breathController.value)!,
                    _bgMid,
                  ],
                ),
              ),
            ),
          ),

          // Page content
          FadeTransition(
            opacity: _fadeController,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                // First visit: audio demo with explanations
                // Returning visit: state selection
                if (widget.isFirstVisit) _buildStep2(),
                if (!widget.isFirstVisit) _buildStep3(),
              ],
            ),
          ),

          // Skip button — always visible
          Positioned(
            top: 24,
            right: 24,
            child: TextButton.icon(
              onPressed: _dismiss,
              icon: const Icon(Icons.close, color: Colors.white54, size: 18),
              label: Text(
                AppTranslationConstants.skip.tr,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ),

          // Step indicator dots
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (i) {
                final active = i == _currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? _accent : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // STEP 1 — "Descubre tu Frecuencia"
  // ════════════════════════════════════════════════════════════════

  Widget _buildStep1() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Descubre tu Frecuencia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tu voz es única. Descubre la frecuencia que te define.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRecording
                  ? 'Mantén un sonido constante con tu voz...'
                  : 'Presiona el micrófono y mantén un sonido con tu voz\npara identificar tu frecuencia raíz',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _isRecording ? _accent.withAlpha(200) : Colors.white38,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 48),

            // Mic button
            if (!_detectionComplete)
              GestureDetector(
                onTap: _isRecording ? null : _startRecording,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) {
                    final scale = _isRecording
                        ? 1.0 + _pulseController.value * 0.15
                        : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording
                              ? _accent.withAlpha(77)
                              : _accent.withAlpha(38),
                          border: Border.all(
                            color: _accent,
                            width: 2,
                          ),
                          boxShadow: _isRecording
                              ? [
                                  BoxShadow(
                                    color: _accent.withAlpha(
                                        (102 * _pulseController.value).round()),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          _isRecording ? Icons.mic : Icons.mic_none,
                          size: 48,
                          color: _accent,
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (_isRecording) ...[
              const SizedBox(height: 24),
              const Text(
                'Escuchando...',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ],

            // Frequency display
            if (_displayedFrequency > 0) ...[
              const SizedBox(height: 32),
              _FrequencyDisplay(
                frequency: _displayedFrequency,
                settled: _detectionComplete,
              ),
            ],

            // "Siguiente" button
            if (_detectionComplete) ...[
              const SizedBox(height: 40),
              _OnboardingButton(
                label: 'Siguiente',
                onTap: () => _goToStep(1),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // STEP 2 — "Siente el Sonido"
  // ════════════════════════════════════════════════════════════════

  Widget _buildStep2() {
    // Color per phase: pure=accent, binaural4=indigo, binaural20=amber, spatial=cyan
    final phaseColors = [
      _accent,
      const Color(0xFF7C4DFF), // Deep purple for theta/meditation
      const Color(0xFFFFAB40), // Amber for beta/focus
      const Color(0xFF00E5FF), // Cyan for spatial
    ];
    final phaseLabels = ['TONO PURO', 'BINAURAL 4 Hz', 'BINAURAL 20 Hz', 'ESPACIAL'];
    final freqColor = phaseColors[_step2Phase.clamp(0, 3)];
    final phaseTag = phaseLabels[_step2Phase.clamp(0, 3)];

    // Frequency display text per phase
    final freqText = switch (_step2Phase) {
      0 => '${_detectedFrequency.toStringAsFixed(0)} Hz',
      1 => '${_detectedFrequency.toStringAsFixed(0)} + 4 Hz',
      2 => '${_detectedFrequency.toStringAsFixed(0)} + 20 Hz',
      3 => '${_detectedFrequency.toStringAsFixed(0)} Hz  L ↔ R',
      _ => '${_detectedFrequency.toStringAsFixed(0)} Hz',
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Frequency display
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                freqText,
                key: ValueKey('freq_$_step2Phase'),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w300,
                  color: freqColor,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: freqColor.withAlpha(153), blurRadius: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Phase tag
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey('tag_$_step2Phase'),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: freqColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: freqColor.withAlpha(80)),
                ),
                child: Text(
                  phaseTag,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: freqColor,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Pulsing circles — color changes with phase
            SizedBox(
              width: 260,
              height: 260,
              child: AnimatedBuilder(
                animation: _breathController,
                builder: (_, _) => CustomPaint(
                  painter: _BreathingCirclesPainter(
                    progress: _breathController.value,
                    color: freqColor,
                  ),
                  size: const Size(260, 260),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Dynamic explanation text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _step2Label.isNotEmpty ? _step2Label : 'Preparando audio...',
                key: ValueKey(_step2Label),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Phase dots (4 dots)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= _step2Phase
                      ? phaseColors[i]
                      : Colors.white12,
                ),
              )),
            ),
            const SizedBox(height: 24),

            // Progress bar
            SizedBox(
              width: 280,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _step2Progress,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(freqColor),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _OnboardingButton(
              label: 'Comenzar',
              onTap: _dismiss, // Don't stop audio — keep frequency active
              secondary: true,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // STEP 3 — "Elige tu Estado"
  // ════════════════════════════════════════════════════════════════

  Widget _buildStep3() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Que necesitas ahora?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 40),

            // State cards grid
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: widget.stateCards.map((card) {
                  return _StateCard(
                    card: card,
                    onTap: () {
                      widget.onDismiss?.call();
                      widget.onStateSelected?.call(card.id);
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            TextButton(
              onPressed: _dismiss,
              child: const Text(
                'Explorar primero',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Private widgets
// ══════════════════════════════════════════════════════════════════

/// Animated frequency counter with glow effect.
class _FrequencyDisplay extends StatelessWidget {
  final double frequency;
  final bool settled;

  const _FrequencyDisplay({required this.frequency, required this.settled});

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00BCD4);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          frequency.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w200,
            color: Colors.white,
            letterSpacing: 4,
            shadows: settled
                ? [
                    Shadow(color: cyan.withAlpha(204), blurRadius: 30),
                    Shadow(color: cyan.withAlpha(102), blurRadius: 60),
                  ]
                : null,
          ),
        ),
        Text(
          'Hz',
          style: TextStyle(
            fontSize: 24,
            color: settled ? cyan : Colors.white38,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

/// Styled button for onboarding navigation.
class _OnboardingButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool secondary;

  const _OnboardingButton({
    required this.label,
    required this.onTap,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00BCD4);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          decoration: BoxDecoration(
            color: secondary ? Colors.transparent : cyan,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: secondary ? Colors.white30 : cyan,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: secondary ? Colors.white70 : Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// State selection card for step 3.
class _StateCard extends StatefulWidget {
  final OnboardingStateCard card;
  final VoidCallback onTap;

  const _StateCard({required this.card, required this.onTap});

  @override
  State<_StateCard> createState() => _StateCardState();
}

class _StateCardState extends State<_StateCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.card.accentColor;
    final minutes = widget.card.duration.inMinutes;
    final beatHz = widget.card.binauralBeat.toStringAsFixed(1);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hovered
                ? accent.withAlpha(38)
                : Colors.white.withAlpha(13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? accent.withAlpha(153) : Colors.white12,
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: accent.withAlpha(51),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.card.icon, color: accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.card.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$beatHz Hz binaural beat  -  $minutes min',
                style: TextStyle(
                  fontSize: 13,
                  color: accent.withAlpha(230),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.card.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CustomPainter — concentric breathing circles
// ══════════════════════════════════════════════════════════════════

class _BreathingCirclesPainter extends CustomPainter {
  final double progress; // 0..1 (breathing cycle)
  final Color color;

  _BreathingCirclesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 5; i++) {
      final phase = (progress + i * 0.15) % 1.0;
      final radius = maxRadius * (0.2 + phase * 0.8);
      final opacity = (1.0 - phase) * 0.4;
      final paint = Paint()
        ..color = color.withAlpha((opacity.clamp(0.0, 1.0) * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, radius, paint);
    }

    // Center filled circle
    final coreRadius = maxRadius * (0.15 + progress * 0.08);
    final corePaint = Paint()
      ..color = color.withAlpha(77)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, coreRadius, corePaint);
  }

  @override
  bool shouldRepaint(_BreathingCirclesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
