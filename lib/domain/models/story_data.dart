/// Lightweight story data extracted from Firestore documents.
/// Self-contained — no dependency on neom_stories module.
class StoryData {
  static const int maxViewerIds = 10000;

  static final RegExp _unsafeStoryControlChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B\u200C\u200E\u200F\u2028-\u202E\u2060-\u2069\uFEFF]',
  );

  static final RegExp _unsafeIdOrUrlChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060-\u2069\uFEFF\u3002\uFF0E\uFF61\\]',
  );

  static final RegExp _encodedTraversalOrBidi = RegExp(
    r'%(?:00|2e|2f|5c|25|c2%[89][0-9a-f]|d8%9c|e2%80%(?:8[b-f]|a[8-e])|e2%81%a[0-9]|ef%bb%bf)',
    caseSensitive: false,
  );

  static final RegExp _internalPromptTags = RegExp(
    r'<\|(?:channel|turn)\s*>\s*thought\b[\s\S]*?(?:<(?:channel|turn)\|>|$)'
    r'|<\|tool_call\s*>[\s\S]*?(?:<tool_call\|>|$)'
    r'|<\s*(think|thought|memory_recall|auto_memory|system_context|context)\b[^>]*>[\s\S]*?(?:<\s*/\s*\1\s*>|$)'
    r'|\[\s*(BIOCHIP|MEMORY_RECALL|AUTO_MEMORY|SYSTEM_CONTEXT)\b[^\]]*\](?:(?!\[\s*/?\s*\2\b)[\s\S])*?\[\s*/\s*\2\b[^\]]*\]',
    caseSensitive: false,
  );

  static final RegExp _internalStandaloneMarkers = RegExp(
    r'<\s*/?\s*(?:think|thought|memory_recall|auto_memory|system_context|context)\b[^>]*>'
    r'|<\|/?(?:turn|channel|tool_call|im_start|im_end|eot_id|eot)\|?>'
    r'|<(?:turn|channel|tool_call)\|>'
    r'|\[\s*/?\s*(?:BIOCHIP|MEMORY_RECALL|AUTO_MEMORY|SYSTEM_CONTEXT)\b[^\]]*\]',
    caseSensitive: false,
  );

  static final RegExp _closingContentTag = RegExp(
    r'<\s*/\s*content\s*>',
    caseSensitive: false,
  );

  static final RegExp _canonicalIpv4Re = RegExp(
    r'^(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}$',
  );

  static final RegExp _numericOrHexIpv4LikeRe = RegExp(
    r'^(?:0x[0-9a-f]+|\d+)(?:\.(?:0x[0-9a-f]+|\d+)){0,3}$',
    caseSensitive: false,
  );

  static const Set<String> _forbiddenIds = <String>{
    '.',
    '..',
    '__proto__',
    'constructor',
    'prototype',
  };

  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerAvatarUrl;
  final List<String> viewerIds;

  StoryData({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerAvatarUrl,
    required this.viewerIds,
  });

  static String _sanitizeId(Object? raw) {
    if (raw is! String) return '';
    if (_unsafeIdOrUrlChars.hasMatch(raw) ||
        _encodedTraversalOrBidi.hasMatch(raw)) {
      return '';
    }
    final cleaned = raw.trim();
    final lower = cleaned.toLowerCase();
    if (cleaned.isEmpty ||
        cleaned.contains('/') ||
        cleaned.contains('..') ||
        _forbiddenIds.contains(lower) ||
        (cleaned.startsWith('__') && cleaned.endsWith('__'))) {
      return '';
    }
    if (cleaned.length > 256) return cleaned.substring(0, 256);
    return cleaned;
  }

  static String _sanitizeName(Object? raw) {
    if (raw is! String) return '';
    var cleaned = raw
        .replaceAll(_internalPromptTags, ' ')
        .replaceAll(_internalStandaloneMarkers, ' ')
        .replaceAll(_closingContentTag, '[content_end]')
        .replaceAll(_unsafeStoryControlChars, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length > 120) {
      var cut = 120;
      final cu = cleaned.codeUnitAt(cut - 1);
      if (cu >= 0xD800 && cu <= 0xDBFF) cut--;
      cleaned = cleaned.substring(0, cut).trimRight();
    }
    return cleaned;
  }

  static String _sanitizeAvatarUrl(Object? raw) {
    if (raw is! String) return '';
    if (_unsafeIdOrUrlChars.hasMatch(raw) ||
        _encodedTraversalOrBidi.hasMatch(raw)) {
      return '';
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 2048 ||
        trimmed.startsWith('//') ||
        trimmed.contains('..') ||
        RegExp(r'[<>"\x27\s]').hasMatch(trimmed)) {
      return '';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.pathSegments.any((s) => s == '.' || s == '..')) {
      return '';
    }
    final lowerPath = uri.path.toLowerCase();
    if (lowerPath.endsWith('.svg') || lowerPath.endsWith('.svgz')) {
      return '';
    }
    if (!uri.hasScheme) {
      if (uri.hasAuthority || trimmed.contains(':')) return '';
      return trimmed;
    }
    final scheme = uri.scheme.toLowerCase();
    if ((scheme != 'https' && scheme != 'http') ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty) {
      return '';
    }
    final host = uri.host.trim().toLowerCase();
    if (host.isEmpty ||
        host.startsWith('.') ||
        host.endsWith('.') ||
        host.contains('..') ||
        host.contains(':') ||
        host == 'null' ||
        host == 'localhost' ||
        host == 'local' ||
        host == 'internal' ||
        host == 'lan' ||
        host == 'metadata' ||
        host == 'instance-data' ||
        host == 'metadata.google.internal' ||
        host == 'metadata.goog' ||
        host == 'metadata.azure.com' ||
        host == 'metadata.azure.internal' ||
        host.endsWith('.localhost') ||
        host.endsWith('.local') ||
        host.endsWith('.internal') ||
        host.endsWith('.corp') ||
        host.endsWith('.lan') ||
        host.endsWith('.home.arpa') ||
        host.endsWith('.invalid') ||
        host.endsWith('.onion') ||
        host.endsWith('.ts.net') ||
        host.endsWith('.metadata.google.internal') ||
        host.endsWith('.metadata.goog') ||
        host.endsWith('.metadata.azure.com') ||
        host.endsWith('.metadata.azure.internal')) {
      return '';
    }
    if (_canonicalIpv4Re.hasMatch(host)) {
      final octets = host.split('.').map(int.parse).toList();
      final a = octets[0];
      final b = octets[1];
      final c = octets[2];
      if (a == 0 ||
          a == 10 ||
          a == 127 ||
          (a == 100 && b >= 64 && b <= 127) ||
          (a == 169 && b == 254) ||
          (a == 172 && b >= 16 && b <= 31) ||
          (a == 192 && b == 0 && (c == 0 || c == 2)) ||
          (a == 192 && b == 168) ||
          (a == 198 && (b == 18 || b == 19)) ||
          (a == 198 && b == 51 && c == 100) ||
          (a == 203 && b == 0 && c == 113) ||
          a >= 224 ||
          octets[3] == 255) {
        return '';
      }
      return trimmed;
    }
    if (_numericOrHexIpv4LikeRe.hasMatch(host)) return '';
    if (host.contains('.')) {
      final tld = host.split('.').last;
      if (RegExp(r'^\d+$').hasMatch(tld)) return '';
    }
    return trimmed;
  }

  factory StoryData.fromMap(Map<String, dynamic> map) {
    final rawViewers = map['viewerIds'];
    final List<String> parsedViewers;
    if (rawViewers is List) {
      final bounded = rawViewers.length > maxViewerIds
          ? rawViewers.take(maxViewerIds)
          : rawViewers;
      final coercedStrings = List<String>.from(bounded);
      parsedViewers = coercedStrings
          .map(_sanitizeId)
          .where((id) => id.isNotEmpty)
          .toList();
    } else {
      parsedViewers = <String>[];
    }

    return StoryData(
      id: _sanitizeId(map['id']),
      ownerId: _sanitizeId(map['ownerId']),
      ownerName: _sanitizeName(map['ownerName']),
      ownerAvatarUrl: _sanitizeAvatarUrl(map['ownerAvatarUrl']),
      viewerIds: parsedViewers,
    );
  }
}
