class PlantModel {
  final String id;
  final String scientificName;
  final String commonName;
  final String family;
  final String description;
  final double confidence;
  final String? imageUrl;
  final String? emoji;
  final CareData careData;
  final UsesData uses;
  final String? iucnStatus;
  final List<String> regionPills;
  final String? potdDate;

  // Overview cards
  final String? habitat;
  final String? height;
  final String? bloomSeason;
  final String? climate;

  // Facts
  final String? culturalSignificance;
  final List<String> funFacts;
  final List<String> distributionCountries;

  const PlantModel({
    required this.id,
    required this.scientificName,
    required this.commonName,
    required this.family,
    required this.description,
    required this.confidence,
    this.imageUrl,
    this.emoji,
    required this.careData,
    required this.uses,
    this.iucnStatus,
    this.regionPills = const [],
    this.potdDate,
    this.habitat,
    this.height,
    this.bloomSeason,
    this.climate,
    this.culturalSignificance,
    this.funFacts = const [],
    this.distributionCountries = const [],
  });

  factory PlantModel.fromJson(Map<String, dynamic> json) {
    return PlantModel(
      id: json['id'] as String? ?? '',
      scientificName: json['scientific_name'] as String? ?? '',
      commonName: json['common_name'] as String? ?? '',
      family: json['family'] as String? ?? '',
      description: json['description'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String?,
      emoji: json['emoji'] as String? ?? '🌿',
      careData: CareData.fromJson(json['care_data'] as Map<String, dynamic>? ?? {}),
      uses: UsesData.fromJson(json['uses'] as Map<String, dynamic>? ?? {}),
      iucnStatus: json['iucn_status'] as String?,
      regionPills: (json['region_pills'] as List<dynamic>?)?.cast<String>() ?? [],
      potdDate: json['potd_date'] as String?,
      habitat: json['habitat'] as String?,
      height: json['height'] as String?,
      bloomSeason: json['bloom_season'] as String?,
      climate: json['climate'] as String?,
      culturalSignificance: json['cultural_significance'] as String?,
      funFacts: (json['fun_facts'] as List<dynamic>?)?.cast<String>() ?? [],
      distributionCountries:
          (json['distribution_countries'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scientific_name': scientificName,
        'common_name': commonName,
        'family': family,
        'description': description,
        'confidence': confidence,
        'image_url': imageUrl,
        'emoji': emoji,
        'care_data': careData.toJson(),
        'uses': uses.toJson(),
        'iucn_status': iucnStatus,
        'region_pills': regionPills,
        'potd_date': potdDate,
        'habitat': habitat,
        'height': height,
        'bloom_season': bloomSeason,
        'climate': climate,
        'cultural_significance': culturalSignificance,
        'fun_facts': funFacts,
        'distribution_countries': distributionCountries,
      };

  PlantModel copyWith({
    String? id,
    String? scientificName,
    String? commonName,
    String? family,
    String? description,
    double? confidence,
    String? imageUrl,
    String? emoji,
    CareData? careData,
    UsesData? uses,
    String? iucnStatus,
    List<String>? regionPills,
    String? potdDate,
    String? habitat,
    String? height,
    String? bloomSeason,
    String? climate,
    String? culturalSignificance,
    List<String>? funFacts,
    List<String>? distributionCountries,
  }) {
    return PlantModel(
      id: id ?? this.id,
      scientificName: scientificName ?? this.scientificName,
      commonName: commonName ?? this.commonName,
      family: family ?? this.family,
      description: description ?? this.description,
      confidence: confidence ?? this.confidence,
      imageUrl: imageUrl ?? this.imageUrl,
      emoji: emoji ?? this.emoji,
      careData: careData ?? this.careData,
      uses: uses ?? this.uses,
      iucnStatus: iucnStatus ?? this.iucnStatus,
      regionPills: regionPills ?? this.regionPills,
      potdDate: potdDate ?? this.potdDate,
      habitat: habitat ?? this.habitat,
      height: height ?? this.height,
      bloomSeason: bloomSeason ?? this.bloomSeason,
      climate: climate ?? this.climate,
      culturalSignificance: culturalSignificance ?? this.culturalSignificance,
      funFacts: funFacts ?? this.funFacts,
      distributionCountries: distributionCountries ?? this.distributionCountries,
    );
  }
}

class CareData {
  final String soil;
  final String sunlight;
  final String water;
  final String ph;
  final String temperature;

  const CareData({
    this.soil = 'Well-draining',
    this.sunlight = 'Full sun',
    this.water = 'Moderate',
    this.ph = '6.0–7.0',
    this.temperature = '15–30°C',
  });

  factory CareData.fromJson(Map<String, dynamic> json) {
    return CareData(
      soil: json['soil'] as String? ?? 'Well-draining',
      sunlight: json['sunlight'] as String? ?? 'Full sun',
      water: json['water'] as String? ?? 'Moderate',
      ph: json['ph'] as String? ?? '6.0–7.0',
      temperature: json['temperature'] as String? ?? '15–30°C',
    );
  }

  Map<String, dynamic> toJson() => {
        'soil': soil,
        'sunlight': sunlight,
        'water': water,
        'ph': ph,
        'temperature': temperature,
      };
}

class UsesData {
  final String? medicinal;
  final String? culinary;
  final String? cosmetic;
  final String? industrial;
  final bool isToxic;

  const UsesData({
    this.medicinal,
    this.culinary,
    this.cosmetic,
    this.industrial,
    this.isToxic = false,
  });

  factory UsesData.fromJson(Map<String, dynamic> json) {
    return UsesData(
      medicinal: json['medicinal'] as String?,
      culinary: json['culinary'] as String?,
      cosmetic: json['cosmetic'] as String?,
      industrial: json['industrial'] as String?,
      isToxic: json['is_toxic'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'medicinal': medicinal,
        'culinary': culinary,
        'cosmetic': cosmetic,
        'industrial': industrial,
        'is_toxic': isToxic,
      };
}
