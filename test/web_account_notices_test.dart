import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_home/ui/web/widgets/web_notification_panel.dart';
import 'package:sint/sint.dart';

void main() {
  testWidgets('web notification panel opens account notices separately from activity', (tester) async {
    var opened = false;
    var closed = false;
    await tester.pumpWidget(SintMaterialApp(
      translationsKeys: const {'es': {'accountNotifications': 'Avisos de cuenta'}},
      locale: const Locale('es'),
      home: Scaffold(body: SizedBox(width: 400, child: WebNotificationPanel(
        onClose: () => closed = true,
        onOpenAccountNotices: () => opened = true,
      ))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Avisos de cuenta'), findsOneWidget);
    await tester.tap(find.text('Avisos de cuenta'));
    expect(opened, isTrue);
    expect(closed, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
