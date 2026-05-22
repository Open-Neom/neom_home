import 'package:flutter_test/flutter_test.dart';
import 'package:neom_home/domain/models/story_data.dart';

void main() {
  group('StoryData.fromMap', () {
    test('parses well-formed map', () {
      final s = StoryData.fromMap({
        'id': 's1',
        'ownerId': 'u1',
        'ownerName': 'Alice',
        'ownerAvatarUrl': 'http://x/a.png',
        'viewerIds': ['v1', 'v2'],
      });
      expect(s.id, 's1');
      expect(s.ownerName, 'Alice');
      expect(s.viewerIds, ['v1', 'v2']);
    });

    test('handles missing keys with defaults', () {
      final s = StoryData.fromMap({});
      expect(s.id, '');
      expect(s.ownerId, '');
      expect(s.ownerName, '');
      expect(s.ownerAvatarUrl, '');
      expect(s.viewerIds, isEmpty);
    });

    test('handles null values', () {
      final s = StoryData.fromMap({
        'id': null,
        'ownerId': null,
        'ownerName': null,
        'ownerAvatarUrl': null,
        'viewerIds': null,
      });
      expect(s.id, '');
      expect(s.viewerIds, isEmpty);
    });

    test('viewerIds with mixed types throws TypeError', () {
      // List<String>.from accepts dynamic but coerces; non-string causes throw
      expect(
        () => StoryData.fromMap({'viewerIds': [1, 2]}),
        throwsA(isA<TypeError>()),
      );
    });

    test('viewerIds preserved order and duplicates', () {
      final s = StoryData.fromMap({
        'viewerIds': ['a', 'b', 'a'],
      });
      expect(s.viewerIds, ['a', 'b', 'a']);
    });

    test('large viewerIds list handled', () {
      final big = List.generate(10000, (i) => 'v$i');
      final s = StoryData.fromMap({'viewerIds': big});
      expect(s.viewerIds.length, 10000);
    });
  });
}
