import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/use_cases/mastering_service.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_home/data/translations/home_es_translations.dart';
import 'package:neom_home/ui/web/right_sidebar.dart';
import 'package:neom_home/utils/constants/home_translation_constants.dart';
import 'package:sint/sint.dart';

class _SpyMasteringService implements MasteringService {
  int showModalCalls = 0;

  @override
  Future<void> showMasteringModal(BuildContext context) async {
    showModalCalls++;
  }

  @override
  Future<MasteringTrackResult?> openMasteringForTrack({
    required BuildContext context,
    String? initialFilePath,
    Uint8List? initialBytes,
    String? fileName,
    String? trackTitle,
    String? genreHint,
  }) async =>
      null;
}

class _TestTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'es': HomeEsTranslations.values,
        'en': HomeEsTranslations.values,
      };
}

void main() {
  testWidgets('RightSidebar renders Gig Mastering card directly below Giglab DAW studio card',
      (tester) async {
    AppConfig.instance.appInUse = AppInUse.g;
    AppConfig.instance.isGuestMode = false;

    final spy = _SpyMasteringService();
    Sint.put<MasteringService>(spy);

    tester.view.physicalSize = const Size(1440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.reset();
      Sint.delete<MasteringService>();
    });

    await tester.pumpWidget(
      SintMaterialApp(
        translations: _TestTranslations(),
        locale: const Locale('es'),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: RightSidebar(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dawFinder = find.text(HomeEsTranslations.values[HomeTranslationConstants.dawStudioCardTitle]!);
    final masteringFinder =
        find.text(HomeEsTranslations.values[HomeTranslationConstants.gigMasteringCardTitle]!);

    // Scroll ListView until both studio CTA cards are visible
    await tester.scrollUntilVisible(
      masteringFinder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(dawFinder, findsOneWidget);
    expect(masteringFinder, findsOneWidget);

    // Verify Gig Mastering is positioned vertically below Giglab DAW card
    final dawY = tester.getTopLeft(dawFinder).dy;
    final masteringY = tester.getTopLeft(masteringFinder).dy;
    expect(masteringY, greaterThan(dawY));
  });
}
