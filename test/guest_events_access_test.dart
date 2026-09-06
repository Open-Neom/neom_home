import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_home/domain/models/home_tab_item.dart';
import 'package:neom_home/ui/home_controller.dart';
import 'package:neom_home/ui/web/widgets/web_upcoming_events.dart';
import 'package:sint/sint.dart';

class _ProtectedPage extends StatefulWidget {
  final VoidCallback onInitialize;
  const _ProtectedPage(this.onInitialize);
  @override
  State<_ProtectedPage> createState() => _ProtectedPageState();
}

class _ProtectedPageState extends State<_ProtectedPage> {
  @override
  void initState() {
    super.initState();
    widget.onInitialize();
  }

  @override
  Widget build(BuildContext context) => const Text('Protected events content');
}

class _UnusedGuestUserService extends Fake implements UserService {
  int accesses = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    accesses++;
    throw StateError('Guest events must not read personal profile data');
  }
}

void main() {
  final previousGuest = AppConfig.instance.isGuestMode;
  setUp(() {
    AppConfig.instance.isGuestMode = true;
    Sint.testMode = true;
    AuthGuard.pendingRedirectRoute = null;
    AuthGuard.pendingRedirectArgs = null;
  });
  tearDown(() {
    Sint.reset();
    AppConfig.instance.isGuestMode = previousGuest;
  });

  List<HomeTabItem> tabs({Widget? events}) => [
    HomeTabItem(
      title: AppTranslationConstants.home,
      icon: Icons.home,
      page: const Text('Public home'),
    ),
    HomeTabItem(
      title: AppTranslationConstants.events,
      icon: Icons.event,
      page: events ?? const Text('Protected events content'),
    ),
    HomeTabItem(
      title: AppTranslationConstants.music,
      icon: Icons.music_note,
      page: const Text('Public audio'),
    ),
  ];

  testWidgets(
    'central event tab guard shows account dialog without changing page',
    (tester) async {
      final controller = HomeController()..pageController = PageController();
      controller.initTabs(tabs());
      await tester.pumpWidget(
        SintMaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => controller.selectTab(1, context: context),
                child: const Text('Open events'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open events'));
      await tester.pumpAndSettle();
      expect(
        find.text(AppTranslationConstants.accountRequired.tr),
        findsOneWidget,
      );
      expect(AuthGuard.pendingRedirectRoute, AppRouteConstants.events);
      expect(controller.currentIndex, 0);
      expect(controller.pageIndex, 0);
      expect(find.text('Protected events content'), findsNothing);
      expect(tester.takeException(), isNull);
      controller.pageController.dispose();
    },
  );

  test(
    'programmatic event selection and initial tab cannot bypass account gate',
    () {
      final controller = HomeController()..pageController = PageController();
      controller.currentIndex = 1;
      controller.initTabs(tabs());
      expect(controller.currentIndex, 0);
      controller.selectTab(1);
      controller.currentIndex = 1;
      expect(controller.currentIndex, 0);
      controller.selectTab(2);
      expect(
        controller.currentIndex,
        2,
        reason: 'Audio remains publicly accessible.',
      );
      controller.selectTab(0);
      expect(
        controller.currentIndex,
        0,
        reason: 'Home remains publicly accessible.',
      );
      controller.pageController.dispose();
    },
  );

  testWidgets('guest IndexedStack never mounts the protected events page', (
    tester,
  ) async {
    var eventInitializations = 0;
    final homeTabs = tabs(events: _ProtectedPage(() => eventInitializations++));
    await tester.pumpWidget(
      MaterialApp(
        home: IndexedStack(
          index: 0,
          children: homeTabs
              .where((tab) => tab.page != null)
              .map((tab) => tab.accessiblePage!)
              .toList(),
        ),
      ),
    );
    expect(eventInitializations, 0);
    expect(find.text('Public home'), findsOneWidget);
    expect(find.byType(_ProtectedPage, skipOffstage: false), findsNothing);
    expect(homeTabs[2].accessiblePage, same(homeTabs[2].page));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'upcoming events performs no guest profile read or Firebase initialization',
    (tester) async {
      final user = _UnusedGuestUserService();
      Sint.put<UserService>(user);
      await tester.pumpWidget(const MaterialApp(home: WebUpcomingEvents()));
      await tester.pumpAndSettle();
      expect(user.accesses, 0);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
