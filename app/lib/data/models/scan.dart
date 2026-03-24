class ScanModel {
  final String id;
  final String userId;
  final String plantId;
  final String? imageUrl;
  final double confidence;
  final String scanMode;
  final DateTime scannedAt;
  final String? commonName;
  final String? scientificName;
  final String? emoji;
  final String? category;

  const ScanModel({
    required this.id,
    required this.userId,
    required this.plantId,
    this.imageUrl,
    required this.confidence,
    required this.scanMode,
    required this.scannedAt,
    this.commonName,
    this.scientificName,
    this.emoji,
    this.category,
  });

  factory ScanModel.fromJson(Map<String, dynamic> json) {
    return ScanModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      plantId: json['plant_id'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      scanMode: json['scan_mode'] as String? ?? 'leaf',
      scannedAt: json['scanned_at'] != null
          ? DateTime.parse(json['scanned_at'] as String)
          : DateTime.now(),
      commonName: json['plants']?['common_name'] as String?,
      scientificName: json['plants']?['scientific_name'] as String?,
      emoji: json['plants']?['emoji'] as String? ?? '🌿',
      category: json['plants']?['category'] as String?,
    );
  }
}
