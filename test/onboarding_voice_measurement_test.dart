import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_home/data/translations/home_en_translations.dart';
import 'package:neom_home/ui/web/neom_onboarding_overlay.dart';
import 'package:neom_home/utils/constants/home_translation_constants.dart';
import 'package:sint/sint.dart';

void main() {
  setUp(() {
    Sint.addTranslations({'en': HomeEnTranslations.values});
    Sint.locale = const Locale('en');
  });
  tearDown(() {
    Sint.clearTranslations();
    Sint.locale = null;
  });

  Future<void> showOverlay(
    WidgetTester tester,
    NeomOnboardingOverlay overlay,
  ) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: overlay)));
    await tester.pump();
  }

  testWidgets(
    'only measured pitch is shown and its exact value starts the demo',
    (tester) async {
      final measurement = Completer<double?>();
      late ValueChanged<double> reportPitch;
      double? played;
      var cancelled = 0;
      var audioStops = 0;
      await showOverlay(
        tester,
        NeomOnboardingOverlay(
          stateCards: const [],
          onMeasureFrequency: (update) {
            reportPitch = update;
            return measurement.future;
          },
          onCancelMeasurement: () async {
            cancelled++;
          },
          onPlayFrequency: (value) => played = value,
          onStopAudio: () => audioStops++,
        ),
      );
      expect(find.text('Hz'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('onboarding-microphone')));
      await tester.pump(const Duration(seconds: 6));
      expect(
        find.text('Hz'),
        findsNothing,
        reason: 'Time alone must never create a pitch',
      );
      reportPitch(220.5);
      await tester.pump();
      expect(find.text('220.5'), findsOneWidget);
      expect(
        find.text(HomeTranslationConstants.onboardingNext.tr),
        findsNothing,
      );
      measurement.complete(220.5);
      await tester.pump();
      expect(cancelled, 1);
      final next = find.text(HomeTranslationConstants.onboardingNext.tr);
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(played, 220.5);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(
        audioStops,
        2,
        reason: 'Stop old output before measuring and release demo on dispose',
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final result in <double?>[null, double.nan, -10]) {
    testWidgets(
      'missing or invalid measurement ($result) offers retry without invented result',
      (tester) async {
        var cancelled = 0;
        await showOverlay(
          tester,
          NeomOnboardingOverlay(
            stateCards: const [],
            onMeasureFrequency: (update) async {
              update(double.infinity);
              return result;
            },
            onCancelMeasurement: () async {
              cancelled++;
            },
          ),
        );
        await tester.tap(find.byKey(const ValueKey('onboarding-microphone')));
        await tester.pump();
        expect(
          find.text(HomeTranslationConstants.onboardingVoiceNoPitch.tr),
          findsOneWidget,
        );
        expect(find.text('Hz'), findsNothing);
        expect(
          find.text(HomeTranslationConstants.onboardingNext.tr),
          findsNothing,
        );
        expect(
          find.byTooltip(HomeTranslationConstants.onboardingVoiceStart.tr),
          findsOneWidget,
        );
        expect(cancelled, 1);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('permission/capture failure is visible and does not advance', (
    tester,
  ) async {
    var cancelled = 0;
    await showOverlay(
      tester,
      NeomOnboardingOverlay(
        stateCards: const [],
        onMeasureFrequency: (_) =>
            Future.error(StateError('permission denied')),
        onCancelMeasurement: () async {
          cancelled++;
        },
      ),
    );
    await tester.tap(find.byKey(const ValueKey('onboarding-microphone')));
    await tester.pump();
    expect(
      find.text(HomeTranslationConstants.onboardingVoiceError.tr),
      findsOneWidget,
    );
    expect(find.text('Hz'), findsNothing);
    expect(find.text(HomeTranslationConstants.onboardingNext.tr), findsNothing);
    expect(cancelled, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('absent host capture is honestly unavailable', (tester) async {
    await showOverlay(tester, const NeomOnboardingOverlay(stateCards: []));
    await tester.tap(find.byKey(const ValueKey('onboarding-microphone')));
    await tester.pump();
    expect(
      find.text(HomeTranslationConstants.onboardingVoiceUnavailable.tr),
      findsOneWidget,
    );
    expect(find.text('Hz'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'closing during permission request cancels capture and ignores late values',
    (tester) async {
      final measurement = Completer<double?>();
      late ValueChanged<double> reportPitch;
      var cancelled = 0;
      var dismissed = 0;
      var stopped = 0;
      await showOverlay(
        tester,
        NeomOnboardingOverlay(
          stateCards: const [],
          onMeasureFrequency: (update) {
            reportPitch = update;
            return measurement.future;
          },
          onCancelMeasurement: () async {
            cancelled++;
          },
          onDismiss: () => dismissed++,
          onStopAudio: () => stopped++,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('onboarding-microphone')));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(cancelled, 1);
      expect(dismissed, 1);
      expect(stopped, 2);
      reportPitch(333);
      measurement.complete(333);
      await tester.pump();
      expect(find.text('333.0'), findsNothing);
      expect(
        find.text(HomeTranslationConstants.onboardingNext.tr),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      expect(
        stopped,
        2,
        reason: 'Dispose must not stop audio owned by a newly selected state',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelled attempt cannot overwrite a newer measurement', (
    tester,
  ) async {
    final first = Completer<double?>();
    final second = Completer<double?>();
    var attempts = 0;
    var cancelled = 0;
    await showOverlay(
      tester,
      NeomOnboardingOverlay(
        stateCards: const [],
        onMeasureFrequency: (_) =>
            ++attempts == 1 ? first.future : second.future,
        onCancelMeasurement: () async {
          cancelled++;
        },
      ),
    );
    final mic = find.byKey(const ValueKey('onboarding-microphone'));
    await tester.tap(mic);
    await tester.pump();
    await tester.tap(mic);
    await tester.pump();
    expect(cancelled, 1);
    await tester.tap(mic);
    await tester.pump();
    first.complete(100);
    await tester.pump();
    expect(find.text('100.0'), findsNothing);
    expect(
      cancelled,
      1,
      reason: 'Old completion must not cancel the new capture',
    );
    second.complete(246.5);
    await tester.pump();
    expect(find.text('246.5'), findsOneWidget);
    expect(cancelled, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'returning visit hands off a state without starting or stopping its audio',
    (tester) async {
      var demoStarts = 0;
      var stateOwnsAudio = false;
      var stopsAfterHandoff = 0;
      await showOverlay(
        tester,
        NeomOnboardingOverlay(
          isFirstVisit: false,
          stateCards: const [
            OnboardingStateCard(
              id: 'calm',
              name: 'Calm test',
              description: 'Test state',
              binauralBeat: 8,
              duration: Duration(minutes: 5),
              accentColor: Colors.cyan,
              icon: Icons.air,
            ),
          ],
          onMeasureFrequency: (_) async => 196,
          onCancelMeasurement: () async {},
          onPlayFrequency: (_) => demoStarts++,
          onStateSelected: (_) => stateOwnsAudio = true,
          onStopAudio: () {
            if (stateOwnsAudio) stopsAfterHandoff++;
          },
        ),
      );
      await tester.tap(find.byKey(const ValueKey('onboarding-microphone')));
      await tester.pump();
      final next = find.text(HomeTranslationConstants.onboardingNext.tr);
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump(const Duration(milliseconds: 550));
      expect(demoStarts, 0);
      await tester.tap(find.text('Calm test'));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(stateOwnsAudio, isTrue);
      expect(stopsAfterHandoff, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
