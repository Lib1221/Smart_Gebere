/// Comprehensive farm profile model for Ethiopian farmers
class FarmProfile {
  final String id;
  final String userId;
  final String farmerName;
  final String phoneNumber;
  
  // Location
  final String region;
  final String zone;
  final String woreda;
  final String kebele;
  final double? latitude;
  final double? longitude;
  final double? elevation;
  
  // Farm Details
  final double farmSizeHectares;
  final String soilType;
  final String irrigationType;
  final bool hasAccessToWater;
  final String farmingExperience; // years or level
  
  // Preferences
  final List<String> preferredCrops;
  final List<String> currentCrops;
  final String farmingType; // subsistence, commercial, mixed
  
  // Equipment
  final List<String> availableEquipment;
  final bool usesChemicalFertilizers;
  final bool usesOrganic;
  
  // Market Access
  final String nearestMarket;
  final double distanceToMarketKm;
  final bool hasTransport;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  FarmProfile({
    required this.id,
    required this.userId,
    required this.farmerName,
    required this.phoneNumber,
    required this.region,
    required this.zone,
    required this.woreda,
    required this.kebele,
    this.latitude,
    this.longitude,
    this.elevation,
    required this.farmSizeHectares,
    required this.soilType,
    required this.irrigationType,
    required this.hasAccessToWater,
    required this.farmingExperience,
    required this.preferredCrops,
    required this.currentCrops,
    required this.farmingType,
    required this.availableEquipment,
    required this.usesChemicalFertilizers,
    required this.usesOrganic,
    required this.nearestMarket,
    required this.distanceToMarketKm,
    required this.hasTransport,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FarmProfile.fromJson(Map<String, dynamic> json) {
    return FarmProfile(
      id: _asString(json['id'], ''),
      userId: _asString(json['userId'], ''),
      farmerName: _asString(json['farmerName'], ''),
      phoneNumber: _asString(json['phoneNumber'], ''),
      region: _asString(json['region'], 'Unknown'),
      zone: _asString(json['zone'], ''),
      woreda: _asString(json['woreda'], ''),
      kebele: _asString(json['kebele'], ''),
      latitude: _asDoubleNullable(json['latitude']),
      longitude: _asDoubleNullable(json['longitude']),
      elevation: _asDoubleNullable(json['elevation']),
      farmSizeHectares: _asDouble(json['farmSizeHectares'], 0.0),
      soilType: _asString(json['soilType'], 'Unknown'),
      irrigationType: _asString(json['irrigationType'], 'Rain-fed'),
      hasAccessToWater: _asBool(json['hasAccessToWater'], false),
      farmingExperience: _asString(json['farmingExperience'], ''),
      preferredCrops: _asStringList(json['preferredCrops']),
      currentCrops: _asStringList(json['currentCrops']),
      farmingType: _asString(json['farmingType'], 'subsistence'),
      availableEquipment: _asStringList(json['availableEquipment']),
      usesChemicalFertilizers: _asBool(json['usesChemicalFertilizers'], false),
      usesOrganic: _asBool(json['usesOrganic'], true),
      nearestMarket: _asString(json['nearestMarket'], ''),
      distanceToMarketKm: _asDouble(json['distanceToMarketKm'], 0.0),
      hasTransport: _asBool(json['hasTransport'], false),
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'farmerName': farmerName,
      'phoneNumber': phoneNumber,
      'region': region,
      'zone': zone,
      'woreda': woreda,
      'kebele': kebele,
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
      'farmSizeHectares': farmSizeHectares,
      'soilType': soilType,
      'irrigationType': irrigationType,
      'hasAccessToWater': hasAccessToWater,
      'farmingExperience': farmingExperience,
      'preferredCrops': preferredCrops,
      'currentCrops': currentCrops,
      'farmingType': farmingType,
      'availableEquipment': availableEquipment,
      'usesChemicalFertilizers': usesChemicalFertilizers,
      'usesOrganic': usesOrganic,
      'nearestMarket': nearestMarket,
      'distanceToMarketKm': distanceToMarketKm,
      'hasTransport': hasTransport,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FarmProfile copyWith({
    String? id,
    String? userId,
    String? farmerName,
    String? phoneNumber,
    String? region,
    String? zone,
    String? woreda,
    String? kebele,
    double? latitude,
    double? longitude,
    double? elevation,
    double? farmSizeHectares,
    String? soilType,
    String? irrigationType,
    bool? hasAccessToWater,
    String? farmingExperience,
    List<String>? preferredCrops,
    List<String>? currentCrops,
    String? farmingType,
    List<String>? availableEquipment,
    bool? usesChemicalFertilizers,
    bool? usesOrganic,
    String? nearestMarket,
    double? distanceToMarketKm,
    bool? hasTransport,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      farmerName: farmerName ?? this.farmerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      region: region ?? this.region,
      zone: zone ?? this.zone,
      woreda: woreda ?? this.woreda,
      kebele: kebele ?? this.kebele,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevation: elevation ?? this.elevation,
      farmSizeHectares: farmSizeHectares ?? this.farmSizeHectares,
      soilType: soilType ?? this.soilType,
      irrigationType: irrigationType ?? this.irrigationType,
      hasAccessToWater: hasAccessToWater ?? this.hasAccessToWater,
      farmingExperience: farmingExperience ?? this.farmingExperience,
      preferredCrops: preferredCrops ?? this.preferredCrops,
      currentCrops: currentCrops ?? this.currentCrops,
      farmingType: farmingType ?? this.farmingType,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      usesChemicalFertilizers: usesChemicalFertilizers ?? this.usesChemicalFertilizers,
      usesOrganic: usesOrganic ?? this.usesOrganic,
      nearestMarket: nearestMarket ?? this.nearestMarket,
      distanceToMarketKm: distanceToMarketKm ?? this.distanceToMarketKm,
      hasTransport: hasTransport ?? this.hasTransport,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper converters
  static String _asString(dynamic value, String fallback) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static double _asDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? _asDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _asBool(dynamic value, bool fallback) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  static List<String> _asStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static DateTime _asDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

/// Ethiopian regions enum
enum EthiopianRegion {
  addisAbaba('Addis Ababa'),
  afar('Afar'),
  amhara('Amhara'),
  benishangulGumuz('Benishangul-Gumuz'),
  direDawa('Dire Dawa'),
  gambela('Gambela'),
  harari('Harari'),
  oromia('Oromia'),
  sidama('Sidama'),
  somali('Somali'),
  southEthiopia('South Ethiopia'),
  southWestEthiopia('South West Ethiopia'),
  centralEthiopia('Central Ethiopia'),
  tigray('Tigray');

  final String displayName;
  const EthiopianRegion(this.displayName);
}

/// Soil types common in Ethiopia
enum SoilType {
  nitisol('Nitisol (Red Clay)'),
  vertisol('Vertisol (Black Cotton)'),
  cambisol('Cambisol (Brown)'),
  luvisol('Luvisol'),
  fluvisol('Fluvisol (Alluvial)'),
  andosol('Andosol (Volcanic)'),
  leptosol('Leptosol (Shallow)'),
  unknown('Unknown');

  final String displayName;
  const SoilType(this.displayName);
}

/// Irrigation types
enum IrrigationType {
  rainfed('Rain-fed'),
  furrow('Furrow Irrigation'),
  drip('Drip Irrigation'),
  sprinkler('Sprinkler'),
  flood('Flood Irrigation'),
  river('River/Stream'),
  groundwater('Groundwater/Well'),
  mixed('Mixed');

  final String displayName;
  const IrrigationType(this.displayName);
}

