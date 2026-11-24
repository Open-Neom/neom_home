import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/use_cases/shop_cart_service.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_home/ui/widgets/home_app_bar.dart';
import 'package:sint/sint.dart';

final Uint8List _transparentPng = Uint8List.fromList(const <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(_transparentPng);

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '{}';
}

class _FakeShopCartService implements ShopCartService {
  final RxInt _count = 0.obs;

  void setCount(int value) => _count.value = value;

  @override
  int get itemCount => _count.value;

  @override
  bool get isEmpty => _count.value <= 0;

  @override
  double get subtotal => _count.value * 100.0;

  @override
  void addItem(AppReleaseItem item, {int qty = 1}) {
    _count.value += qty;
  }

  @override
  void removeItem(String productId) {
    if (_count.value > 0) _count.value -= 1;
  }

  @override
  void updateQuantity(String productId, int qty) {
    _count.value = qty;
  }

  @override
  void clear() {
    _count.value = 0;
  }
}

void main() {
  late _FakeShopCartService cartService;

  setUp(() {
    Sint.reset();
    AppConfig.instance.appInUse = AppInUse.e;
    cartService = _FakeShopCartService();
    Sint.put<ShopCartService>(cartService);
  });

  tearDown(() {
    Sint.reset();
  });

  testWidgets('HomeAppBar hides shopping cart icon when cart is empty and shows it when items are added', (
    tester,
  ) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _TestAssetBundle(),
        child: const MaterialApp(
          home: Scaffold(
            appBar: HomeAppBar(profileImg: 'invalid-local', profileId: ''),
            body: SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();

    // Empty cart: icon is completely hidden to keep top bar uncluttered.
    expect(find.byIcon(Icons.shopping_cart_outlined), findsNothing);

    // Add 2 items: cart icon and badge appear reactively.
    cartService.setCount(2);
    await tester.pump();
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // Clear cart: icon hides again.
    cartService.clear();
    await tester.pump();
    expect(find.byIcon(Icons.shopping_cart_outlined), findsNothing);
  });
}
