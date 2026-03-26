import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/use_cases/stripe_api_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';
import 'package:url_launcher/url_launcher.dart';

class FilGuadalajaraPage extends StatelessWidget {
  const FilGuadalajaraPage({super.key});

  static const _purple = Color(0xFF7B1FA2);
  static const _amber = Color(0xFFFF8F00);
  static const _teal = Color(0xFF00897B);
  static const _indigo = Color(0xFF5C6BC0);
  static const _red = Color(0xFFEF5350);
  static const _orange = Color(0xFFFFA726);
  static const _green = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppFlavour.getBackgroundColor(),
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 1100.0 : screenWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 40 : 16,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      onPressed: () => Sint.back(),
                    ),
                    const SizedBox(height: 12),

                    // Hero
                    _buildHeroSection(),
                    const SizedBox(height: 28),

                    if (isWide) _buildWideLayout(context) else _buildMobileLayout(context),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Wide layout: Plans side-by-side, info around them ──
  Widget _buildWideLayout(BuildContext context) {
    return Column(
      children: [
        // ── Row 1: Location | Benefits | Distribution | Not Included ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildLocationSection()),
            const SizedBox(width: 14),
            Expanded(child: _buildBenefitsSection()),
            const SizedBox(width: 14),
            Expanded(child: _buildDistributionSection()),
            const SizedBox(width: 14),
            Expanded(child: _buildNotIncludedSection()),
          ],
        ),
        const SizedBox(height: 24),

        // ── Row 2: Both plans side by side (the stars) ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildPlanCard(
                context: context,
                title: 'Plan Entrevista',
                subtitle: 'Presencial en FIL Guadalajara',
                price: 5000,
                features: [
                  'Venta y promocion de un titulo',
                  '10-15 ejemplares en repisas',
                  'Mesa de novedades (1 dia)',
                  'Fotos y video en stand',
                  'Espacio "Autor Presente"',
                  'Entrevista 15 min',
                ],
                highlight: true,
                badgeText: 'Recomendado',
                totalSpots: 50,
                spotsLeft: 47,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildPlanCard(
                context: context,
                title: 'Plan Remoto',
                subtitle: 'Participacion a distancia',
                price: 3500,
                features: [
                  'Venta y promocion de un titulo',
                  '10-15 ejemplares en repisas',
                  'Mesa de novedades (1 dia)',
                  'Fotos y video en stand',
                  'Distribucion en librerias aliadas',
                ],
                totalSpots: 150,
                spotsLeft: 148,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Row 3: Priority | How it works | Rules | Recommendations ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildPrioritySection()),
            const SizedBox(width: 14),
            Expanded(child: _buildHowItWorksSection()),
            const SizedBox(width: 14),
            Expanded(child: _buildSection(
              icon: Icons.handshake_outlined, title: 'Reglas', color: _red,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bulletPoint('Respetar el espacio del stand'),
                  _bulletPoint('Mantener orden y limpieza'),
                  _bulletPoint('Portar gafete en todo momento'),
                  _bulletPoint('Ser puntual en horarios asignados'),
                ],
              ),
            )),
            const SizedBox(width: 14),
            Expanded(child: _buildSection(
              icon: Icons.lightbulb_outline, title: 'Recomendaciones', color: _orange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bulletPoint('Lleva suficientes ejemplares'),
                  _bulletPoint('Prepara material promocional'),
                  _bulletPoint('Promociona en redes sociales'),
                  _bulletPoint('Conecta con otros autores'),
                ],
              ),
            )),
          ],
        ),
      ],
    );
  }

  // ── Mobile: stacked layout ──
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildPlanCard(
          context: context,
          title: 'Plan Entrevista',
          subtitle: 'Presencial en FIL Guadalajara',
          price: 5000,
          features: [
            'Venta y promocion de un titulo',
            '10-15 ejemplares en repisas',
            'Mesa de novedades (1 dia)',
            'Fotos y video en stand',
            'Espacio "Autor Presente"',
            'Entrevista 15 min',
          ],
          highlight: true,
          badgeText: 'Recomendado',
          totalSpots: 50,
          spotsLeft: 47,
        ),
        const SizedBox(height: 16),
        _buildPlanCard(
          context: context,
          title: 'Plan Remoto',
          subtitle: 'Participacion a distancia',
          price: 3500,
          features: [
            'Venta y promocion de un titulo',
            '10-15 ejemplares en repisas',
            'Mesa de novedades (1 dia)',
            'Fotos y video en stand',
            'Distribucion en librerias aliadas',
          ],
          totalSpots: 150,
          spotsLeft: 148,
        ),
        const SizedBox(height: 24),
        _buildLocationSection(),
        const SizedBox(height: 16),
        _buildBenefitsSection(),
        const SizedBox(height: 16),
        _buildNotIncludedSection(),
        const SizedBox(height: 16),
        _buildDistributionSection(),
        const SizedBox(height: 16),
        _buildHowItWorksSection(),
        const SizedBox(height: 16),
        _buildPrioritySection(),
        const SizedBox(height: 16),
        _buildCompactRulesAndRecs(),
      ],
    );
  }

  // ── Hero ──

  Widget _buildHeroSection() {
    // Countdown to FIL 2026: Nov 28, 2026
    final filDate = DateTime(2026, 11, 28);
    final now = DateTime.now();
    final diff = filDate.difference(now);
    final days = diff.inDays;
    final months = (days / 30).floor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EMXI en la FIL Guadalajara 2026',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '40a edicion · Feria Internacional del Libro',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pais Invitado de Honor: Italia',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
                      ),
                      child: const Text(
                        'Escritores Mexicanos Independientes',
                        style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Countdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.amberAccent, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      days > 0 ? '$days' : '0',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'dias',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '($months meses)',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Info sections ──

  Widget _buildLocationSection() => _buildSection(
    icon: Icons.location_on_outlined, title: 'Ubicacion', color: _purple,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(Icons.place, 'Expo Guadalajara'),
        _infoRow(Icons.map_outlined, 'Av. Mariano Otero 1499, Verde Valle'),
        _infoRow(Icons.storefront, 'Area Nacional - Stand M10'),
        _infoRow(Icons.calendar_today, '28 Nov - 6 Dic 2026'),
      ],
    ),
  );

  Widget _buildHowItWorksSection() => _buildSection(
    icon: Icons.route_outlined, title: 'Como funciona', color: const Color(0xFF26C6DA),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _numberedStep('1', 'Reserva tu lugar con el pago'),
        _numberedStep('2', 'Envia tus ejemplares a EMXI'),
        _numberedStep('3', 'EMXI exhibe y vende en la FIL'),
        _numberedStep('4', 'Recibe reporte de ventas'),
      ],
    ),
  );

  Widget _buildBenefitsSection() => _buildSection(
    icon: Icons.star_outline, title: 'Beneficios', color: _amber,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bulletPoint('Venta y promocion de un titulo'),
        _bulletPoint('10-15 ejemplares en repisas'),
        _bulletPoint('Mesa de novedades (1 dia)'),
        _bulletPoint('Fotos y video del libro en stand'),
        _bulletPoint('Distribucion en librerias aliadas'),
      ],
    ),
  );

  Widget _buildNotIncludedSection() => _buildSection(
    icon: Icons.info_outline, title: 'No incluye', color: Colors.grey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bulletPoint('Credencial de profesionales'),
        _bulletPoint('Entrada diaria (\$30 MXN)'),
        _bulletPoint('Material promocional'),
        _bulletPoint('Garantia de venta total'),
        _bulletPoint('Envio de libros restantes'),
      ],
    ),
  );

  Widget _buildDistributionSection() => _buildSection(
    icon: Icons.local_shipping_outlined, title: 'Distribucion', color: _teal,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Libros restantes en librerias aliadas:',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _distributionChip('Librerias', '35%', const Color(0xFF4FC3F7)),
            const SizedBox(width: 6),
            _distributionChip('EMXI', '30%', _amber),
            const SizedBox(width: 6),
            _distributionChip('Autores', '35%', const Color(0xFFAED581)),
          ],
        ),
      ],
    ),
  );

  Widget _buildPrioritySection() => _buildSection(
    icon: Icons.groups_outlined, title: 'Prioridad de participacion', color: _indigo,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _priorityRow('Entrevista carrera literaria (15 min)', '50%'),
        _priorityRow('Venta y promocion presencial', '30%'),
        _priorityRow('Colaboracion & Networking', '20%'),
      ],
    ),
  );

  // ── Plan cards ──

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required int price,
    required List<String> features,
    bool highlight = false,
    String? badgeText,
    int totalSpots = 0,
    int spotsLeft = 0,
  }) {
    final borderColor = highlight ? _green : Colors.white.withValues(alpha: 0.15);
    final bgGradient = highlight
        ? [const Color(0xFF1B5E20).withValues(alpha: 0.25), const Color(0xFF2E7D32).withValues(alpha: 0.15)]
        : [Colors.white.withValues(alpha: 0.04), Colors.white.withValues(alpha: 0.02)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: bgGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: highlight ? 1.5 : 1),
      ),
      child: Column(
        children: [
          if (badgeText != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _green.withValues(alpha: 0.5)),
              ),
              child: Text(badgeText, style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          const SizedBox(height: 16),
          Text(
            '\$${_formatPrice(price)} MXN',
            style: TextStyle(
              color: highlight ? Colors.greenAccent : Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text('Pago unico', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          if (totalSpots > 0) ...[
            const SizedBox(height: 12),
            // FOMO spots indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: spotsLeft < 20
                    ? _red.withValues(alpha: 0.15)
                    : Colors.amberAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: spotsLeft < 20
                      ? _red.withValues(alpha: 0.3)
                      : Colors.amberAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    spotsLeft < 20 ? Icons.local_fire_department : Icons.event_seat,
                    color: spotsLeft < 20 ? _red : Colors.amberAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$spotsLeft de $totalSpots lugares disponibles',
                    style: TextStyle(
                      color: spotsLeft < 20 ? _red : Colors.amberAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Features
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: highlight ? Colors.greenAccent : Colors.white38, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(f, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5))),
              ],
            ),
          )),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: highlight ? _green : Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => _handlePayment(context, price),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, size: 18),
                  const SizedBox(width: 8),
                  Text('Reservar mi lugar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Pago seguro via Stripe', style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10)),
        ],
      ),
    );
  }

  // ── Compact rules & recommendations (mobile) ──

  Widget _buildCompactRulesAndRecs() {
    return Column(
      children: [
        _buildSection(
          icon: Icons.handshake_outlined, title: 'Reglas', color: _red,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bulletPoint('Respetar el espacio del stand'),
              _bulletPoint('Mantener orden y limpieza'),
              _bulletPoint('Portar gafete en todo momento'),
              _bulletPoint('Ser puntual en horarios asignados'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSection(
          icon: Icons.lightbulb_outline, title: 'Recomendaciones', color: _orange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bulletPoint('Lleva suficientes ejemplares'),
              _bulletPoint('Prepara material promocional'),
              _bulletPoint('Promociona en redes sociales'),
              _bulletPoint('Conecta con otros autores'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Payment ──

  void _handlePayment(BuildContext context, int amount) {
    AuthGuard.protect(
      context,
      () => _initiateStripeCheckout(amount),
      redirectRoute: AppRouteConstants.filGuadalajara,
    );
  }

  Future<void> _initiateStripeCheckout(int amount) async {
    try {
      if (!Sint.isRegistered<StripeApiService>()) return;
      final stripeApi = Sint.find<StripeApiService>();
      final email = Sint.find<UserService>().user.email;

      final checkoutSession = await stripeApi.createFilCheckoutSession(email, amount: amount);
      if (checkoutSession.url.isNotEmpty && kIsWeb) {
        await launchUrl(Uri.parse(checkoutSession.url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      AppConfig.logger.e('FIL checkout error: $e');
    }
  }

  // ── Shared widgets ──

  Widget _buildSection({
    required IconData icon, required String title,
    required Color color, required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(child: Text(title, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _numberedStep(String number, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF26C6DA).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF26C6DA).withValues(alpha: 0.5)),
          ),
          child: Center(child: Text(number, style: const TextStyle(color: Color(0xFF26C6DA), fontSize: 11, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 8),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5, height: 1.3)),
        )),
      ],
    ),
  );

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, color: Colors.white54, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5))),
    ]),
  );

  Widget _bulletPoint(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), shape: BoxShape.circle)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5, height: 1.3))),
      ],
    ),
  );

  Widget _distributionChip(String label, String pct, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text(pct, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
      ]),
    ),
  );

  Widget _priorityRow(String label, String pct) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 36, child: Text(pct, style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w700))),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5))),
    ]),
  );

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '${price ~/ 1000},${(price % 1000).toString().padLeft(3, '0')}';
    }
    return price.toString();
  }
}
