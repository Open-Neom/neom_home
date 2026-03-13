/// Lightweight story data extracted from Firestore documents.
/// Self-contained — no dependency on neom_stories module.
class StoryData {
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

  factory StoryData.fromMap(Map<String, dynamic> map) {
    return StoryData(
      id: map['id'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      ownerAvatarUrl: map['ownerAvatarUrl'] as String? ?? '',
      viewerIds: List<String>.from(map['viewerIds'] as List? ?? []),
    );
  }
}
