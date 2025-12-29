/// Farm record model for tracking expenses, inputs, yield, and harvest.
class FarmRecord {
  final String id;
  final String userId;
  final RecordType type;
  final String cropName;
  final DateTime date;
  final String description;
  
  // Financial
  final double? amount;
  final String? currency;
  final ExpenseCategory? expenseCategory;
  
  // Input details (for input type records)
  final String? inputType; // seed, fertilizer, pesticide, labor, etc.
  final double? quantity;
  final String? unit;
  
  // Yield/Harvest details
  final double? harvestQuantity;
  final String? harvestUnit;
  final double? qualityRating; // 1-5
  
  // Labor
  final int? laborHours;
  final int? numberOfWorkers;
  
  // Notes
  final String? notes;
  final List<String>? imageUrls;
  
  // Sync status
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  FarmRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.cropName,
    required this.date,
    required this.description,
    this.amount,
    this.currency = 'ETB',
    this.expenseCategory,
    this.inputType,
    this.quantity,
    this.unit,
    this.harvestQuantity,
    this.harvestUnit,
    this.qualityRating,
    this.laborHours,
    this.numberOfWorkers,
    this.notes,
    this.imageUrls,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FarmRecord.fromJson(Map<String, dynamic> json) {
    return FarmRecord(
      id: _asString(json['id'], ''),
      userId: _asString(json['userId'], ''),
      type: RecordType.fromString(_asString(json['type'], 'expense')),
      cropName: _asString(json['cropName'], ''),
      date: _asDateTime(json['date']),
      description: _asString(json['description'], ''),
      amount: _asDoubleNullable(json['amount']),
      currency: _asString(json['currency'], 'ETB'),
      expenseCategory: json['expenseCategory'] != null 
          ? ExpenseCategory.fromString(_asString(json['expenseCategory'], 'other'))
          : null,
      inputType: json['inputType'] as String?,
      quantity: _asDoubleNullable(json['quantity']),
      unit: json['unit'] as String?,
      harvestQuantity: _asDoubleNullable(json['harvestQuantity']),
      harvestUnit: json['harvestUnit'] as String?,
      qualityRating: _asDoubleNullable(json['qualityRating']),
      laborHours: _asIntNullable(json['laborHours']),
      numberOfWorkers: _asIntNullable(json['numberOfWorkers']),
      notes: json['notes'] as String?,
      imageUrls: _asStringListNullable(json['imageUrls']),
      isSynced: _asBool(json['isSynced'], false),
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'cropName': cropName,
      'date': date.toIso8601String(),
      'description': description,
      'amount': amount,
      'currency': currency,
      'expenseCategory': expenseCategory?.name,
      'inputType': inputType,
      'quantity': quantity,
      'unit': unit,
      'harvestQuantity': harvestQuantity,
      'harvestUnit': harvestUnit,
      'qualityRating': qualityRating,
      'laborHours': laborHours,
      'numberOfWorkers': numberOfWorkers,
      'notes': notes,
      'imageUrls': imageUrls,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FarmRecord copyWith({
    String? id,
    String? userId,
    RecordType? type,
    String? cropName,
    DateTime? date,
    String? description,
    double? amount,
    String? currency,
    ExpenseCategory? expenseCategory,
    String? inputType,
    double? quantity,
    String? unit,
    double? harvestQuantity,
    String? harvestUnit,
    double? qualityRating,
    int? laborHours,
    int? numberOfWorkers,
    String? notes,
    List<String>? imageUrls,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      cropName: cropName ?? this.cropName,
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      expenseCategory: expenseCategory ?? this.expenseCategory,
      inputType: inputType ?? this.inputType,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      harvestQuantity: harvestQuantity ?? this.harvestQuantity,
      harvestUnit: harvestUnit ?? this.harvestUnit,
      qualityRating: qualityRating ?? this.qualityRating,
      laborHours: laborHours ?? this.laborHours,
      numberOfWorkers: numberOfWorkers ?? this.numberOfWorkers,
      notes: notes ?? this.notes,
      imageUrls: imageUrls ?? this.imageUrls,
      isSynced: isSynced ?? this.isSynced,
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

  static double? _asDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _asIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _asBool(dynamic value, bool fallback) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  static List<String>? _asStringListNullable(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.map((e) => e.toString()).toList();
    return null;
  }

  static DateTime _asDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

enum RecordType {
  expense('Expense'),
  income('Income'),
  input('Input'),
  harvest('Harvest'),
  labor('Labor'),
  observation('Observation');

  final String displayName;
  const RecordType(this.displayName);

  static RecordType fromString(String value) {
    return RecordType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RecordType.expense,
    );
  }
}

enum ExpenseCategory {
  seed('Seeds'),
  fertilizer('Fertilizer'),
  pesticide('Pesticide'),
  herbicide('Herbicide'),
  labor('Labor'),
  equipment('Equipment'),
  irrigation('Irrigation'),
  transport('Transport'),
  storage('Storage'),
  marketing('Marketing'),
  other('Other');

  final String displayName;
  const ExpenseCategory(this.displayName);

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}

/// Analytics summary for farm records
class FarmAnalytics {
  final double totalExpenses;
  final double totalIncome;
  final double netProfit;
  final double totalHarvest;
  final int totalLaborHours;
  final Map<String, double> expensesByCategory;
  final Map<String, double> incomeByMonth;
  final Map<String, double> harvestByCrop;

  FarmAnalytics({
    required this.totalExpenses,
    required this.totalIncome,
    required this.netProfit,
    required this.totalHarvest,
    required this.totalLaborHours,
    required this.expensesByCategory,
    required this.incomeByMonth,
    required this.harvestByCrop,
  });

  factory FarmAnalytics.fromRecords(List<FarmRecord> records) {
    double totalExpenses = 0;
    double totalIncome = 0;
    double totalHarvest = 0;
    int totalLaborHours = 0;
    
    final expensesByCategory = <String, double>{};
    final incomeByMonth = <String, double>{};
    final harvestByCrop = <String, double>{};

    for (final record in records) {
      switch (record.type) {
        case RecordType.expense:
        case RecordType.input:
          final amount = record.amount ?? 0;
          totalExpenses += amount;
          final cat = record.expenseCategory?.displayName ?? 'Other';
          expensesByCategory[cat] = (expensesByCategory[cat] ?? 0) + amount;
          break;
        case RecordType.income:
          final amount = record.amount ?? 0;
          totalIncome += amount;
          final month = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
          incomeByMonth[month] = (incomeByMonth[month] ?? 0) + amount;
          break;
        case RecordType.harvest:
          final qty = record.harvestQuantity ?? 0;
          totalHarvest += qty;
          harvestByCrop[record.cropName] = (harvestByCrop[record.cropName] ?? 0) + qty;
          break;
        case RecordType.labor:
          totalLaborHours += record.laborHours ?? 0;
          final amount = record.amount ?? 0;
          if (amount > 0) {
            totalExpenses += amount;
            expensesByCategory['Labor'] = (expensesByCategory['Labor'] ?? 0) + amount;
          }
          break;
        case RecordType.observation:
          // No financial impact
          break;
      }
    }

    return FarmAnalytics(
      totalExpenses: totalExpenses,
      totalIncome: totalIncome,
      netProfit: totalIncome - totalExpenses,
      totalHarvest: totalHarvest,
      totalLaborHours: totalLaborHours,
      expensesByCategory: expensesByCategory,
      incomeByMonth: incomeByMonth,
      harvestByCrop: harvestByCrop,
    );
  }
}

