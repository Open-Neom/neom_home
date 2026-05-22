import 'package:flutter_test/flutter_test.dart';
import 'package:neom_home/data/translations/home_en_translations.dart';
import 'package:neom_home/data/translations/home_es_translations.dart';
import 'package:neom_home/data/translations/home_de_translations.dart';
import 'package:neom_home/data/translations/home_fr_translations.dart';

void main() {
  final en = HomeEnTranslations.values;
  final es = HomeEsTranslations.values;
  final de = HomeDeTranslations.values;
  final fr = HomeFrTranslations.values;

  test('all language maps share same key set as English', () {
    final enKeys = en.keys.toSet();
    expect(es.keys.toSet(), enKeys, reason: 'es key drift');
    expect(de.keys.toSet(), enKeys, reason: 'de key drift');
    expect(fr.keys.toSet(), enKeys, reason: 'fr key drift');
  });

  test('no language has empty translation values', () {
    for (final entry in {'en': en, 'es': es, 'de': de, 'fr': fr}.entries) {
      for (final kv in entry.value.entries) {
        expect(kv.value.trim(), isNotEmpty,
            reason: '${entry.key}[${kv.key}] empty');
      }
    }
  });

  test('en map is non-empty', () {
    expect(en, isNotEmpty);
  });
}
