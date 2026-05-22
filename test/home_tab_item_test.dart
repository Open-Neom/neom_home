import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_home/domain/models/home_tab_item.dart';

/// Re-implements HomeController._getPageIndexFromVisualIndex (private) to
/// validate the dashboard slot/page index math: for a given visual tab index,
/// returns how many tabs before it have a non-null page (i.e. the PageView
/// page index that corresponds to the visual tab).
int pageIndexFromVisualIndex(List<HomeTabItem> tabs, int visualIndex) {
  int pageIndex = 0;
  for (int i = 0; i < visualIndex; i++) {
    if (i < tabs.length && tabs[i].page != null) {
      pageIndex++;
    }
  }
  return pageIndex;
}

void main() {
  HomeTabItem makeTab({String title = 't', Widget? page, bool isAction = false}) {
    return HomeTabItem(
      title: title,
      icon: Icons.home,
      page: page,
      isActionButton: isAction,
    );
  }

  group('HomeTabItem defaults', () {
    test('isActionButton default false, route default null', () {
      final t = makeTab();
      expect(t.isActionButton, isFalse);
      expect(t.route, isNull);
      expect(t.page, isNull);
    });
  });

  group('pageIndexFromVisualIndex (extracted from HomeController)', () {
    test('empty tabs at index 0 returns 0', () {
      expect(pageIndexFromVisualIndex([], 0), 0);
    });

    test('all-page tabs: visual index equals page index', () {
      final tabs = List.generate(
          5, (i) => makeTab(page: const SizedBox.shrink()));
      for (int i = 0; i < 5; i++) {
        expect(pageIndexFromVisualIndex(tabs, i), i);
      }
    });

    test('action button in the middle does not increment page index', () {
      final tabs = [
        makeTab(page: const SizedBox.shrink()), // 0 -> page 0
        makeTab(page: const SizedBox.shrink()), // 1 -> page 1
        makeTab(isAction: true),                // 2 -> action (no page)
        makeTab(page: const SizedBox.shrink()), // 3 -> page 2
        makeTab(page: const SizedBox.shrink()), // 4 -> page 3
      ];
      expect(pageIndexFromVisualIndex(tabs, 0), 0);
      expect(pageIndexFromVisualIndex(tabs, 1), 1);
      expect(pageIndexFromVisualIndex(tabs, 2), 2);
      expect(pageIndexFromVisualIndex(tabs, 3), 2);
      expect(pageIndexFromVisualIndex(tabs, 4), 3);
    });

    test('visual index out of bounds returns count of pageful tabs', () {
      final tabs = [
        makeTab(page: const SizedBox.shrink()),
        makeTab(isAction: true),
        makeTab(page: const SizedBox.shrink()),
      ];
      // Visual index 100 is invalid; algorithm caps at tabs.length
      expect(pageIndexFromVisualIndex(tabs, 100), 2);
    });

    test('negative visual index returns 0 (loop body never executes)', () {
      final tabs = [makeTab(page: const SizedBox.shrink())];
      expect(pageIndexFromVisualIndex(tabs, -5), 0);
    });

    test('all action buttons: page index always 0', () {
      final tabs = List.generate(4, (_) => makeTab(isAction: true));
      for (int i = 0; i <= 4; i++) {
        expect(pageIndexFromVisualIndex(tabs, i), 0);
      }
    });
  });
}
