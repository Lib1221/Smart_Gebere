import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/farmer_entity.dart';
import '../../domain/entities/crop_entity.dart';
import '../../domain/entities/field_entity.dart';
import '../../domain/entities/week_entity.dart';
import '../../domain/repositories/farmer_repository.dart';

/// Implementation of FarmerRepository using Firestore.
class FarmerRepositoryImpl implements FarmerRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NetworkInfo _networkInfo;
  final LoggerService _logger;

  FarmerRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required NetworkInfo networkInfo,
    required LoggerService logger,
  })  : _firestore = firestore,
        _auth = auth,
        _networkInfo = networkInfo,
        _logger = logger;

  String? get _currentUserId => _auth.currentUser?.uid;

  CollectionReference get _farmersCollection => _firestore.collection('Farmers');

  @override
  Future<Either<Failure, FarmerEntity>> getFarmer([String? farmerId]) async {
    try {
      final id = farmerId ?? _currentUserId;
      if (id == null) {
        return const Left(AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      _logger.debug('Fetching farmer: $id', tag: 'FARMER');

      final doc = await _farmersCollection.doc(id).get();

      if (!doc.exists) {
        return Left(NotFoundFailure(
          message: 'Farmer profile not found.',
        ));
      }

      final farmer = _mapDocToFarmer(doc);
      _logger.debug('Farmer fetched: ${farmer.name}', tag: 'FARMER');
      return Right(farmer);
    } catch (e, stack) {
      _logger.error('Error fetching farmer', error: e, stackTrace: stack);
      return Left(DatabaseFailure(
        message: 'Failed to load farmer data.',
        originalError: e,
      ));
    }
  }

  @override
  Stream<Either<Failure, FarmerEntity>> watchFarmer([String? farmerId]) {
    final id = farmerId ?? _currentUserId;
    if (id == null) {
      return Stream.value(const Left(AuthFailure(
        message: 'No user is currently signed in.',
        code: 'NOT_AUTHENTICATED',
      )));
    }

    return _farmersCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists) {
        return Left(NotFoundFailure(message: 'Farmer profile not found.'));
      }
      return Right(_mapDocToFarmer(doc));
    }).handleError((e) {
      _logger.error('Error watching farmer', error: e);
      return Left(DatabaseFailure(
        message: 'Failed to watch farmer data.',
        originalError: e,
      ));
    });
  }

  @override
  Future<Either<Failure, FarmerEntity>> updateFarmer(FarmerEntity farmer) async {
    try {
      await _farmersCollection.doc(farmer.id).update({
        'name': farmer.name,
        'phone': farmer.phone,
        'region': farmer.region,
      });

      _logger.info('Farmer updated: ${farmer.id}', tag: 'FARMER');
      return Right(farmer);
    } catch (e, stack) {
      _logger.error('Error updating farmer', error: e, stackTrace: stack);
      return Left(DatabaseFailure(
        message: 'Failed to update farmer.',
        originalError: e,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Crop Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<CropEntity>>> getCrops([String? farmerId]) async {
    try {
      final id = farmerId ?? _currentUserId;
      if (id == null) {
        return const Left(AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      final doc = await _farmersCollection.doc(id).get();
      if (!doc.exists) {
        return const Right([]);
      }

      final data = doc.data() as Map<String, dynamic>?;
      final cropsData = data?['crops'] as List<dynamic>? ?? [];

      final crops = cropsData
          .map((c) => _mapToCropEntity(c as Map<String, dynamic>))
          .toList();

      _logger.debug('Fetched ${crops.length} crops', tag: 'FARMER');
      return Right(crops);
    } catch (e, stack) {
      _logger.error('Error fetching crops', error: e, stackTrace: stack);
      return Left(DatabaseFailure(
        message: 'Failed to load crops.',
        originalError: e,
      ));
    }
  }

  @override
  Stream<Either<Failure, List<CropEntity>>> watchCrops([String? farmerId]) {
    final id = farmerId ?? _currentUserId;
    if (id == null) {
      return Stream.value(const Left(AuthFailure(
        message: 'No user is currently signed in.',
        code: 'NOT_AUTHENTICATED',
      )));
    }

    return _farmersCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists) {
        return const Right(<CropEntity>[]);
      }

      final data = doc.data() as Map<String, dynamic>?;
      final cropsData = data?['crops'] as List<dynamic>? ?? [];

      final crops = cropsData
          .map((c) => _mapToCropEntity(c as Map<String, dynamic>))
          .toList();

      return Right(crops);
    }).handleError((e) {
      _logger.error('Error watching crops', error: e);
      return Left(DatabaseFailure(
        message: 'Failed to watch crops.',
        originalError: e,
      ));
    });
  }

  @override
  Future<Either<Failure, CropEntity>> getCrop(String cropId) async {
    final cropsResult = await getCrops();
    return cropsResult.fold(
      (failure) => Left(failure),
      (crops) {
        final crop = crops.firstWhere(
          (c) => c.id == cropId,
          orElse: () => throw Exception('Crop not found'),
        );
        return Right(crop);
      },
    );
  }

  @override
  Future<Either<Failure, CropEntity>> saveCrop(CropEntity crop) async {
    try {
      final id = _currentUserId;
      if (id == null) {
        return const Left(AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      final cropData = _cropEntityToMap(crop);

      await _farmersCollection.doc(id).update({
        'crops': FieldValue.arrayUnion([cropData]),
      });

      _logger.info('Crop saved: ${crop.name}', tag: 'FARMER');
      return Right(crop);
    } catch (e, stack) {
      _logger.error('Error saving crop', error: e, stackTrace: stack);
      return Left(DatabaseFailure(
        message: 'Failed to save crop.',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, CropEntity>> updateCrop(CropEntity crop) async {
    try {
      final id = _currentUserId;
      if (id == null) {
        return const Left(AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      // Get current crops
      final doc = await _farmersCollection.doc(id).get();
      final data = doc.data() as Map<String, dynamic>?;
      final crops = List<Map<String, dynamic>>.from(data?['crops'] ?? []);

      // Find and update the crop
      final index = crops.indexWhere((c) => c['id'] == crop.id);
      if (index == -1) {
        return const Left(NotFoundFailure(message: 'Crop not found.'));
      }

      crops[index] = _cropEntityToMap(crop);

      await _farmersCollection.doc(id).update({'crops': crops});

      _logger.info('Crop updated: ${crop.name}', tag: 'FARMER');
      return Right(crop);
    } catch (e, stack) {
      _logger.error('Error updating crop', error: e, stackTrace: stack);
      return Left(DatabaseFailure(
        message: 'Failed to update crop.',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCrop(String cropId) async {
    try {
      final id = _currentUserId;
      if (id == null) {
        return const Left(AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      final doc = await _farmersCollection.doc(id).get();
      final data = doc.data() as Map<String, dynamic>?;
      final crops = List<Map<String, dynamic>>.from(data?['crops'] ?? []);

      crops.removeWhere((c) => c['id'] == cropId);

      await _farmersCollection.doc(id).update({'crops': crops});

      _logger.info('Crop deleted: $cropId', tag: 'FARMER');
      return const Right(null);
    } catch (e, stack) {
      _logger.error('Error deleting crop', error: e, stackTrace: stack);
      return Left(DatabaseFailure(
        message: 'Failed to delete crop.',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, CropEntity>> updateTaskCompletion({
    required String cropId,
    required int weekIndex,
    required int taskIndex,
    required bool isCompleted,
  }) async {
    try {
      final cropsResult = await getCrops();
      return await cropsResult.fold(
        (failure) async => Left(failure),
        (crops) async {
          final cropIndex = crops.indexWhere((c) => c.id == cropId);
          if (cropIndex == -1) {
            return const Left(NotFoundFailure(message: 'Crop not found.'));
          }

          final crop = crops[cropIndex];
          if (weekIndex >= crop.weeks.length) {
            return const Left(ValidationFailure(message: 'Invalid week index.'));
          }

          final week = crop.weeks[weekIndex];
          final updatedWeek = isCompleted
              ? week.copyWith(
                  completedTasks: {...week.completedTasks, taskIndex})
              : week.copyWith(
                  completedTasks: week.completedTasks
                      .where((i) => i != taskIndex)
                      .toSet());

          final updatedWeeks = List<WeekEntity>.from(crop.weeks);
          updatedWeeks[weekIndex] = updatedWeek;

          // Recalculate progress
          final totalTasks =
              updatedWeeks.fold(0, (sum, w) => sum + w.tasks.length);
          final completedTasks =
              updatedWeeks.fold(0, (sum, w) => sum + w.completedTasks.length);
          final progress =
              totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;

          final updatedCrop = crop.copyWith(
            weeks: updatedWeeks,
            progressPercentage: progress,
          );

          return await updateCrop(updatedCrop);
        },
      );
    } catch (e, stack) {
      _logger.error('Error updating task completion', error: e, stackTrace: stack);
      return Left(DatabaseFailure(
        message: 'Failed to update task.',
        originalError: e,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Field Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<FieldEntity>>> getFields([String? farmerId]) async {
    try {
      final id = farmerId ?? _currentUserId;
      if (id == null) {
        return const Left(AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      final doc = await _farmersCollection.doc(id).get();
      if (!doc.exists) {
        return const Right([]);
      }

      final data = doc.data() as Map<String, dynamic>?;
      final fieldsData = data?['fields'] as List<dynamic>? ?? [];

      final fields = fieldsData
          .map((f) => _mapToFieldEntity(f as Map<String, dynamic>))
          .toList();

      return Right(fields);
    } catch (e, stack) {
      _logger.error('Error fetching fields', error: e, stackTrace: stack);
      return Left(DatabaseFailure(
        message: 'Failed to load fields.',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, FieldEntity>> saveField(FieldEntity field) async {
    try {
      final id = _currentUserId;
      if (id == null) {
        return const Left(AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      final fieldData = _fieldEntityToMap(field);

      await _farmersCollection.doc(id).update({
        'fields': FieldValue.arrayUnion([fieldData]),
      });

      _logger.info('Field saved: ${field.name}', tag: 'FARMER');
      return Right(field);
    } catch (e, stack) {
      _logger.error('Error saving field', error: e, stackTrace: stack);
      return Left(DatabaseFailure(
        message: 'Failed to save field.',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> deleteField(String fieldId) async {
    try {
      final id = _currentUserId;
      if (id == null) {
        return const Left(AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      final doc = await _farmersCollection.doc(id).get();
      final data = doc.data() as Map<String, dynamic>?;
      final fields = List<Map<String, dynamic>>.from(data?['fields'] ?? []);

      fields.removeWhere((f) => f['id'] == fieldId);

      await _farmersCollection.doc(id).update({'fields': fields});

      _logger.info('Field deleted: $fieldId', tag: 'FARMER');
      return const Right(null);
    } catch (e, stack) {
      _logger.error('Error deleting field', error: e, stackTrace: stack);
      return Left(DatabaseFailure(
        message: 'Failed to delete field.',
        originalError: e,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Mapping Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  FarmerEntity _mapDocToFarmer(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final cropsData = data['crops'] as List<dynamic>? ?? [];
    final fieldsData = data['fields'] as List<dynamic>? ?? [];

    return FarmerEntity(
      id: doc.id,
      name: data['name'] as String?,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      region: data['region'] as String?,
      crops: cropsData.map((c) => _mapToCropEntity(c as Map<String, dynamic>)).toList(),
      fields: fieldsData.map((f) => _mapToFieldEntity(f as Map<String, dynamic>)).toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  CropEntity _mapToCropEntity(Map<String, dynamic> data) {
    final weeksData = data['weeks'] as List<dynamic>? ?? [];
    
    return CropEntity(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      weeks: weeksData.map((w) => _mapToWeekEntity(w as Map<String, dynamic>)).toList(),
      progressPercentage: (data['progressPercentage'] as num?)?.toInt() ?? 0,
      daysSinceFirstPlanting: (data['daysSinceFirstPlanting'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
      fieldId: data['fieldId'] as String?,
      fieldName: data['fieldName'] as String?,
      fieldAreaHectares: (data['fieldAreaHectares'] as num?)?.toDouble(),
      soilType: data['soilType'] as String?,
    );
  }

  WeekEntity _mapToWeekEntity(Map<String, dynamic> data) {
    final dateRange = data['date_range'] as List<dynamic>? ?? [];
    final completedTasks = data['completedTasks'] as List<dynamic>? ?? [];

    return WeekEntity(
      weekNumber: (data['week'] as num?)?.toInt() ?? 1,
      startDate: dateRange.isNotEmpty
          ? DateTime.tryParse(dateRange[0] as String) ?? DateTime.now()
          : DateTime.now(),
      endDate: dateRange.length > 1
          ? DateTime.tryParse(dateRange[1] as String) ?? DateTime.now()
          : DateTime.now(),
      stage: data['stage'] as String? ?? '',
      tasks: (data['tasks'] as List<dynamic>?)?.cast<String>() ?? [],
      completedTasks: completedTasks.map((e) => e as int).toSet(),
    );
  }

  FieldEntity _mapToFieldEntity(Map<String, dynamic> data) {
    final pointsData = data['points'] as List<dynamic>? ?? [];

    return FieldEntity(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      soilType: data['soilType'] as String? ?? '',
      areaHectares: (data['areaHectares'] as num?)?.toDouble() ?? 0,
      points: pointsData.map((p) => LatLngPoint.fromJson(p as Map<String, dynamic>)).toList(),
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _cropEntityToMap(CropEntity crop) {
    return {
      'id': crop.id,
      'name': crop.name,
      'weeks': crop.weeks.map((w) => _weekEntityToMap(w)).toList(),
      'progressPercentage': crop.progressPercentage,
      'daysSinceFirstPlanting': crop.daysSinceFirstPlanting,
      'createdAt': crop.createdAt.toIso8601String(),
      'fieldId': crop.fieldId,
      'fieldName': crop.fieldName,
      'fieldAreaHectares': crop.fieldAreaHectares,
      'soilType': crop.soilType,
    };
  }

  Map<String, dynamic> _weekEntityToMap(WeekEntity week) {
    return {
      'week': week.weekNumber,
      'date_range': [
        week.startDate.toIso8601String(),
        week.endDate.toIso8601String(),
      ],
      'stage': week.stage,
      'tasks': week.tasks,
      'completedTasks': week.completedTasks.toList(),
    };
  }

  Map<String, dynamic> _fieldEntityToMap(FieldEntity field) {
    return {
      'id': field.id,
      'name': field.name,
      'soilType': field.soilType,
      'areaHectares': field.areaHectares,
      'points': field.points.map((p) => p.toJson()).toList(),
      'createdAt': field.createdAt.toIso8601String(),
    };
  }
}

