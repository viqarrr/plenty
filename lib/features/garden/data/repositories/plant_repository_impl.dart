import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/daily_care/domain/models/care_schedule_model.dart';
import 'package:plenty/features/garden/data/data_sources/plant_remote_data_source.dart';
import 'package:plenty/features/garden/domain/models/growth_log_model.dart';
import 'package:plenty/features/garden/domain/models/perenual/perenual_care_guide_model.dart';
import 'package:plenty/features/garden/domain/models/perenual/plant_catalog_model.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:plenty/features/garden/data/datasources/garden_remote_datasource.dart';
import 'package:plenty/features/profile/domain/repositories/badge_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Implementation of [IPlantRepository] using Direct API calls + In-Memory Session Cache
/// and persisting adopted plants as self-contained snapshots in SQLite.
class PlantRepositoryImpl implements IPlantRepository {
  final DatabaseHelper _dbHelper;
  final PlantRemoteDataSource _remoteDataSource;
  final GardenRemoteDataSource? _gardenRemoteDataSource;
  final IBadgeRepository? _badgeRepo;

  // In-Memory Session Caches (zero SQLite disk hoarding)
  final Map<String, List<PlantCatalogModel>> _sessionCatalogCache = {};
  final Map<int, PlantCatalogModel> _sessionDetailCache = {};
  final Map<int, List<PerenualCareGuideModel>> _sessionCareGuideCache = {};

  PlantRepositoryImpl({
    DatabaseHelper? dbHelper,
    PlantRemoteDataSource? remoteDataSource,
    GardenRemoteDataSource? gardenRemoteDataSource,
    IBadgeRepository? badgeRepo,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance,
       _remoteDataSource = remoteDataSource ?? PlantRemoteDataSourceImpl(),
       _gardenRemoteDataSource = gardenRemoteDataSource,
       _badgeRepo = badgeRepo;

  /// Clears in-memory session cache.
  void clearSessionCache() {
    _sessionCatalogCache.clear();
    _sessionDetailCache.clear();
    _sessionCareGuideCache.clear();
  }

  @override
  Future<Result<List<PlantCatalogModel>>> getCatalogPlants({
    String? query,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final q = query?.trim();
    final cacheKey = '${q ?? ""}_$page';

    // 1. Check in-memory session cache
    if (!forceRefresh && _sessionCatalogCache.containsKey(cacheKey)) {
      return Success(_sessionCatalogCache[cacheKey]!);
    }

    // 2. Fetch directly from Remote Perenual API
    try {
      final speciesList = await _remoteDataSource.fetchSpeciesList(
        page: page,
        query: q,
      );

      if (speciesList.isNotEmpty) {
        final catalogModels = speciesList
            .map((s) => s.toPlantCatalogModel())
            .toList();
        _sessionCatalogCache[cacheKey] = catalogModels;
        return Success(catalogModels);
      }

      // If empty response from API, return empty list
      return const Success([]);
    } on Failure catch (failure) {
      // On network failure or rate limit, provide in-memory seed fallback for smooth offline UX
      final fallbackSeeds = await _loadInMemorySeeds(query: q);
      if (fallbackSeeds.isNotEmpty) {
        return Success(fallbackSeeds);
      }
      return Error(failure);
    } catch (e) {
      final fallbackSeeds = await _loadInMemorySeeds(query: q);
      if (fallbackSeeds.isNotEmpty) {
        return Success(fallbackSeeds);
      }
      return Error(ServerFailure('Gagal memuat katalog tanaman: $e'));
    }
  }

  @override
  Future<Result<PlantCatalogModel>> getPlantCatalogDetails(
    int speciesId, {
    bool forceRefresh = false,
  }) async {
    // 1. Check in-memory session cache
    if (!forceRefresh && _sessionDetailCache.containsKey(speciesId)) {
      return Success(_sessionDetailCache[speciesId]!);
    }

    // 2. Fetch directly from Remote Perenual API
    try {
      final detail = await _remoteDataSource.fetchSpeciesDetails(speciesId);
      final catalogModel = detail.toPlantCatalogModel();
      _sessionDetailCache[speciesId] = catalogModel;
      return Success(catalogModel);
    } on Failure catch (failure) {
      return Error(failure);
    } catch (e) {
      return Error(ServerFailure('Gagal memuat detail tanaman: $e'));
    }
  }

  @override
  Future<Result<List<PerenualCareGuideModel>>> getPlantCareGuides(
    int speciesId,
  ) async {
    if (_sessionCareGuideCache.containsKey(speciesId)) {
      return Success(_sessionCareGuideCache[speciesId]!);
    }

    try {
      final guides = await _remoteDataSource.fetchSpeciesCareGuides(speciesId);
      _sessionCareGuideCache[speciesId] = guides;
      return Success(guides);
    } on Failure catch (failure) {
      return Error(failure);
    } catch (e) {
      return Error(ServerFailure('Gagal memuat panduan perawatan: $e'));
    }
  }

  @override
  Future<Result<List<PlantCatalogModel>>> seedCatalogFromAsset({
    String? query,
  }) async {
    final seeds = await _loadInMemorySeeds(query: query);
    return Success(seeds);
  }

  Future<List<PlantCatalogModel>> _loadInMemorySeeds({String? query}) async {
    List<PlantCatalogModel> seeds = [];
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/seed_plants.json',
      );
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      seeds = jsonList
          .whereType<Map<String, dynamic>>()
          .map(
            (m) => PlantCatalogModel.fromMap({
              ...m,
              'cached_at': DateTime.now().toIso8601String(),
            }),
          )
          .toList();
    } catch (_) {
      seeds = _getHardcodedDefaultSeeds();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      return seeds.where((s) {
        final name = s.commonName.toLowerCase();
        final sci = (s.scientificName ?? '').toLowerCase();
        return name.contains(q) || sci.contains(q);
      }).toList();
    }

    return seeds;
  }

  @override
  Future<Result<AddPlantResult>> addPlant({
    required String userId,
    PlantCatalogModel? species,
    String? catalogId,
    required String nickname,
    required bool isIndoor,
    String? sunlightCondition,
    String? potSize,
    String siteId = 'site_default_ruang_tamu',
    double? initialHeightCm,
    String growthStage = 'mature',
    DateTime? adoptedAt,
    String? coverPhotoPath,
    String? customPhotoPath,
    TimeCapsuleDraft? timeCapsule,
    int defaultWateringInterval = 7,
  }) async {
    try {
      final db = await _dbHelper.database;
      UserModel? activeUser;
      try {
        activeUser = await PreferenceHandler.getUser();
      } catch (_) {}
      final resolvedId = (userId.isNotEmpty &&
              userId != 'usr_default' &&
              userId != '1' &&
              userId != '0')
          ? userId
          : ((activeUser?.id != null && activeUser!.id!.isNotEmpty && activeUser.id != '0')
              ? activeUser.id!
              : (userId.isNotEmpty && userId != '0' ? userId : '1'));
      final effectiveUserId = resolvedId == '0' ? '1' : resolvedId;
      final int rawParsed = int.tryParse(effectiveUserId.toString()) ?? (activeUser?.numericId ?? 1);
      final int parsedUserId = rawParsed > 0 ? rawParsed : 1;

      final result = await db.transaction<AddPlantResult>((txn) async {
        // 1. Ensure user row exists for relational integrity
        final userRows = await txn.query(
          DatabaseHelper.tableUsers,
          where: 'id = ?',
          whereArgs: [parsedUserId],
          limit: 1,
        );
        if (userRows.isEmpty) {
          await txn.insert(DatabaseHelper.tableUsers, {
            'id': parsedUserId,
            'email': activeUser?.email ?? 'user_$parsedUserId@plenty.app',
            'username': activeUser?.username ?? 'user_$parsedUserId',
            'password': '',
            'display_name': activeUser?.displayName ?? 'Pecinta Tanaman',
            'created_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }

        // Check if this is truly the user's first plant adoption ever
        final isDefaultUser = effectiveUserId == 'usr_default' ||
            effectiveUserId == '1' ||
            effectiveUserId == 'user_1';
        final existingPlants = await txn.query(
          DatabaseHelper.tableUserPlants,
          where: isDefaultUser
              ? "(user_id = ? OR CAST(user_id AS TEXT) = ? OR user_id = '1' OR user_id = 'user_1' OR user_id = 'usr_default') AND is_archived = 0"
              : "(user_id = ? OR CAST(user_id AS TEXT) = ?) AND is_archived = 0",
          whereArgs: [effectiveUserId, effectiveUserId],
        );

        final userBadgeRows = await txn.query(
          DatabaseHelper.tableUserBadges,
          where: 'user_id = ? AND badge_id = ?',
          whereArgs: [parsedUserId, 'first_plant'],
        );

        final bool badgeAlreadyUnlocked =
            userBadgeRows.isNotEmpty &&
            ((userBadgeRows.first['is_unlocked'] as int?) == 1 ||
                userBadgeRows.first['unlocked_at'] != null);

        final isFirstPlant = existingPlants.isEmpty && !badgeAlreadyUnlocked;

        final effectiveAdoptedAt = adoptedAt ?? DateTime.now();
        final plantId =
            'plant_${DateTime.now().millisecondsSinceEpoch}_${nickname.hashCode.abs()}';

        final effectiveSiteId = siteId;
        final photo =
            coverPhotoPath ??
            customPhotoPath ??
            species?.imageUrl ??
            species?.localImagePath;
        final interval =
            species?.defaultWateringInterval ?? defaultWateringInterval;
        final initialH = initialHeightCm ?? 30.0;
        final speciesIdNum = species != null
            ? int.tryParse(species.id.replaceAll(RegExp(r'[^0-9]'), ''))
            : null;

        // 2. Insert self-contained snapshot into user_plants (ZERO disk catalog dependency)
        final plant = PlantModel(
          id: plantId,
          userId: effectiveUserId,
          speciesId: speciesIdNum,
          catalogId: species?.id ?? catalogId,
          nickname: nickname,
          commonName: species?.commonName ?? nickname,
          speciesName: species?.commonName ?? nickname,
          scientificName: species?.scientificName,
          isIndoor: isIndoor,
          placementType: isIndoor ? 'Indoor' : 'Outdoor',
          sunlightCondition: sunlightCondition ?? species?.sunlightLevel,
          sunlightPreference: sunlightCondition ?? species?.sunlightLevel,
          potSize: potSize,
          siteId: effectiveSiteId,
          initialHeightCm: initialH,
          initialHeight: initialH,
          currentHeight: initialH,
          growthStage: growthStage,
          adoptedAt: effectiveAdoptedAt,
          coverPhotoPath: photo,
          imagePath: photo,
          healthStatus: 'healthy',
          level: 1,
          xp: 0,
          isArchived: false,
          defaultWateringInterval: interval,
          wateringIntervalDays: interval,
          isPetFriendly: species?.isToxic == false,
          careLevel: species?.careLevel,
          toxicity: species?.toxicityDescription,
          description: species?.overviewDisplay,
          growthRate: species?.growthRateDisplay,
          growthCycle: species?.cycleDisplay,
          pruningSeason: species?.pruningDisplay,
          flowerStatus: species?.floweringDisplay,
        );

        await txn.insert(DatabaseHelper.tableUserPlants, plant.toMap());

        // 3. Insert initial growth log
        final initialLog = GrowthLogModel(
          id: 'log_${effectiveAdoptedAt.millisecondsSinceEpoch}',
          userPlantId: plantId,
          loggedAt: effectiveAdoptedAt,
          heightCm: initialH,
          photoPath: customPhotoPath,
          source: 'initial',
          note: 'Adopsi pertama $nickname',
        );
        await txn.insert(DatabaseHelper.tableGrowthLogs, initialLog.toMap());

        // 4. Insert care schedules
        final now = DateTime.now();
        final schedules = [
          CareScheduleModel(
            id: 'sched_${plantId}_siram',
            userPlantId: plantId,
            taskType: 'siram',
            intervalDays: interval,
            nextDueDate: now,
            isActive: true,
          ),
          CareScheduleModel(
            id: 'sched_${plantId}_bersih',
            userPlantId: plantId,
            taskType: 'bersih',
            intervalDays: 7,
            nextDueDate: now,
            isActive: true,
          ),
          CareScheduleModel(
            id: 'sched_${plantId}_tinggi',
            userPlantId: plantId,
            taskType: 'monitor',
            intervalDays: 1,
            nextDueDate: now,
            isActive: true,
          ),
        ];

        for (final s in schedules) {
          await txn.insert(DatabaseHelper.tableCareSchedules, s.toMap());
        }

        // 5. Check first plant badge
        if (isFirstPlant) {
          final formattedDate =
              '${now.day} ${_monthName(now.month)} ${now.year}';
          if (userBadgeRows.isNotEmpty) {
            await txn.update(
              DatabaseHelper.tableUserBadges,
              {
                'is_unlocked': 1,
                'current_progress': 1,
                'unlocked_at': formattedDate,
              },
              where: 'user_id = ? AND badge_id = ?',
              whereArgs: [parsedUserId, 'first_plant'],
            );
          } else {
            await txn.insert(
              DatabaseHelper.tableUserBadges,
              {
                'id': 'ub_${parsedUserId}_first_plant',
                'user_id': parsedUserId,
                'badge_id': 'first_plant',
                'is_unlocked': 1,
                'current_progress': 1,
                'unlocked_at': formattedDate,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          final countResult = await txn.rawQuery(
            '''
            SELECT COUNT(DISTINCT badge_id) as count FROM ${DatabaseHelper.tableUserBadges}
            WHERE user_id = ? AND is_unlocked = 1
          ''',
            [parsedUserId],
          );
          final count = (countResult.first['count'] as int?) ?? 1;
          await txn.update(
            DatabaseHelper.tableUsers,
            {'unlocked_badges_count': count},
            where: 'id = ?',
            whereArgs: [parsedUserId],
          );
        }

        // 6. Insert time capsule if provided
        bool isFirstTimeCapsule = false;
        if (timeCapsule != null &&
            timeCapsule.note != null &&
            timeCapsule.note!.isNotEmpty) {
          final capsuleModel = TimeCapsuleModel(
            id: 'capsule_${effectiveAdoptedAt.millisecondsSinceEpoch}',
            userPlantId: plantId,
            photoPath: timeCapsule.photoPath,
            note: timeCapsule.note,
            createdAt: effectiveAdoptedAt,
            unlockAt: timeCapsule.unlockAt,
            isUnlocked: false,
          );
          await txn.insert(
            DatabaseHelper.tableTimeCapsules,
            capsuleModel.toMap(),
          );

          // Check if time_capsule badge is already unlocked
          final tcBadgeRows = await txn.query(
            DatabaseHelper.tableUserBadges,
            where: 'user_id = ? AND badge_id = ?',
            whereArgs: [parsedUserId, 'time_capsule'],
          );

          final bool tcBadgeAlreadyUnlocked =
              tcBadgeRows.isNotEmpty &&
              ((tcBadgeRows.first['is_unlocked'] as int?) == 1 ||
                  tcBadgeRows.first['unlocked_at'] != null);

          if (!tcBadgeAlreadyUnlocked) {
            isFirstTimeCapsule = true;
            final formattedDate =
                '${now.day} ${_monthName(now.month)} ${now.year}';
            if (tcBadgeRows.isNotEmpty) {
              await txn.update(
                DatabaseHelper.tableUserBadges,
                {
                  'is_unlocked': 1,
                  'current_progress': 1,
                  'unlocked_at': formattedDate,
                },
                where: 'user_id = ? AND badge_id = ?',
                whereArgs: [parsedUserId, 'time_capsule'],
              );
            } else {
              await txn.insert(
                DatabaseHelper.tableUserBadges,
                {
                  'id': 'ub_${parsedUserId}_time_capsule',
                  'user_id': parsedUserId,
                  'badge_id': 'time_capsule',
                  'is_unlocked': 1,
                  'current_progress': 1,
                  'unlocked_at': formattedDate,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }

          final countResult = await txn.rawQuery(
            '''
            SELECT COUNT(DISTINCT badge_id) as count FROM ${DatabaseHelper.tableUserBadges}
            WHERE user_id = ? AND is_unlocked = 1
          ''',
            [parsedUserId],
          );
          final count = (countResult.first['count'] as int?) ?? 1;
          await txn.update(
            DatabaseHelper.tableUsers,
            {'unlocked_badges_count': count},
            where: 'id = ?',
            whereArgs: [parsedUserId],
          );
        }

        return AddPlantResult(
          plant: plant,
          isFirstPlant: isFirstPlant,
          isFirstTimeCapsule: isFirstTimeCapsule,
        );
      });

      // Synchronize badges with IBadgeRepository & Cloud Firestore
      final badgeRepoToUse = _badgeRepo;
      if (result.isFirstPlant) {
        await badgeRepoToUse?.awardBadge(userId: effectiveUserId, badgeId: 'first_plant');
      }
      if (result.isFirstTimeCapsule) {
        await badgeRepoToUse?.awardBadge(userId: effectiveUserId, badgeId: 'time_capsule');
      }
      try {
        final allPlantsRes = await getUserPlants(effectiveUserId);
        final plantsList = allPlantsRes.dataOrNull ?? [];
        if (plantsList.isNotEmpty) {
          await badgeRepoToUse?.awardBadge(userId: effectiveUserId, badgeId: 'first_plant');
        }
        if (plantsList.length >= 5) {
          await badgeRepoToUse?.awardBadge(userId: effectiveUserId, badgeId: 'plant_collector');
        }
      } catch (_) {}

      // Migrate any legacy orphaned plants to effective user
      if (effectiveUserId.isNotEmpty &&
          effectiveUserId != 'usr_default' &&
          effectiveUserId != '1') {
        try {
          await db.update(
            DatabaseHelper.tableUserPlants,
            {'user_id': effectiveUserId},
            where: "user_id = 'usr_default' OR user_id = '1'",
          );
        } catch (_) {}
      }

      // Dual-write to Cloud Firestore
      if (_gardenRemoteDataSource != null &&
          effectiveUserId.isNotEmpty &&
          effectiveUserId != 'usr_default') {
        try {
          await _gardenRemoteDataSource.savePlant(result.plant);
        } catch (_) {
          // Offline resilience: SQLite persistence completed successfully
        }
      }

      return Success(result);
    } catch (e) {
      return Error(DatabaseFailure('Gagal menambahkan tanaman: $e'));
    }
  }

  @override
  Future<Result<List<PlantModel>>> getUserPlants([
    String userId = 'usr_default',
  ]) async {
    try {
      final db = await _dbHelper.database;
      UserModel? activeUser;
      try {
        activeUser = await PreferenceHandler.getUser();
      } catch (_) {}
      final effectiveUserId = (userId.isNotEmpty && userId != 'usr_default')
          ? userId
          : (activeUser?.id ?? userId);
      final parsedUserId = int.tryParse(effectiveUserId.toString());

      // Cloud sync from Firestore if remote data source is available
      if (_gardenRemoteDataSource != null &&
          effectiveUserId.isNotEmpty &&
          effectiveUserId != 'usr_default') {
        try {
          final remotePlants =
              await _gardenRemoteDataSource.getUserPlants(effectiveUserId);
          for (final plant in remotePlants) {
            await db.insert(
              DatabaseHelper.tableUserPlants,
              plant.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        } catch (_) {
          // Graceful fallback to SQLite local cache
        }
      }

      // Query user_plants directly - matches user ID, string UID, or legacy usr_default
      final maps = await db.query(
        DatabaseHelper.tableUserPlants,
        where:
            "(user_id = ? OR CAST(user_id AS TEXT) = ? OR user_id = ? OR user_id = 'usr_default') AND is_archived = 0",
        whereArgs: [
          parsedUserId ?? effectiveUserId,
          effectiveUserId.toString(),
          activeUser?.id ?? '',
        ],
        orderBy: 'adopted_at DESC',
      );

      final plants = maps.map((m) => PlantModel.fromMap(m)).toList();
      return Success(plants);
    } catch (e) {
      return Error(DatabaseFailure('Gagal mengambil daftar tanaman: $e'));
    }
  }

  @override
  Future<Result<PlantModel?>> getPlantById(String plantId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableUserPlants,
        where: 'id = ?',
        whereArgs: [plantId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Success(PlantModel.fromMap(maps.first));
      }

      // Check Cloud Firestore if absent from SQLite local cache
      if (_gardenRemoteDataSource != null) {
        try {
          final remotePlant =
              await _gardenRemoteDataSource.getPlantById(plantId);
          if (remotePlant != null) {
            await db.insert(
              DatabaseHelper.tableUserPlants,
              remotePlant.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            return Success(remotePlant);
          }
        } catch (_) {}
      }

      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Gagal mengambil tanaman: $e'));
    }
  }

  @override
  Future<Result<void>> archivePlant(String plantId) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        DatabaseHelper.tableUserPlants,
        {'is_archived': 1},
        where: 'id = ?',
        whereArgs: [plantId],
      );

      if (_gardenRemoteDataSource != null) {
        try {
          await _gardenRemoteDataSource.archivePlant(plantId);
        } catch (_) {}
      }

      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Gagal mengarsipkan tanaman: $e'));
    }
  }

  @override
  Future<Result<void>> updatePlantInfo({
    required String plantId,
    required String nickname,
    String? coverPhotoPath,
    bool updatePhoto = false,
    String? siteId,
  }) async {
    try {
      final db = await _dbHelper.database;
      final values = <String, dynamic>{'nickname': nickname.trim()};
      if (updatePhoto) {
        values['cover_photo_path'] = coverPhotoPath;
        values['image_path'] = coverPhotoPath;
      }
      if (siteId != null) {
        values['site_id'] = siteId;
      }
      await db.update(
        DatabaseHelper.tableUserPlants,
        values,
        where: 'id = ?',
        whereArgs: [plantId],
      );

      if (_gardenRemoteDataSource != null) {
        try {
          await _gardenRemoteDataSource.updatePlant(plantId, values);
        } catch (_) {}
      }

      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Gagal memperbarui informasi tanaman: $e'));
    }
  }

  @override
  Future<Result<void>> updatePlantPhoto(
    String plantId,
    String? photoPath,
  ) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        DatabaseHelper.tableUserPlants,
        {'cover_photo_path': photoPath, 'image_path': photoPath},
        where: 'id = ?',
        whereArgs: [plantId],
      );

      if (_gardenRemoteDataSource != null) {
        try {
          await _gardenRemoteDataSource.updatePlant(plantId, {
            'cover_photo_path': photoPath,
            'image_path': photoPath,
          });
        } catch (_) {}
      }

      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Gagal memperbarui foto tanaman: $e'));
    }
  }

  @override
  Future<Result<void>> deletePlant(String plantId) async {
    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        await txn.delete(
          DatabaseHelper.tableCareSchedules,
          where: 'user_plant_id = ?',
          whereArgs: [plantId],
        );
        await txn.delete(
          DatabaseHelper.tableCareActionLogs,
          where: 'user_plant_id = ?',
          whereArgs: [plantId],
        );
        await txn.delete(
          DatabaseHelper.tableGrowthLogs,
          where: 'user_plant_id = ?',
          whereArgs: [plantId],
        );
        await txn.delete(
          DatabaseHelper.tableTimeCapsules,
          where: 'user_plant_id = ?',
          whereArgs: [plantId],
        );
        await txn.delete(
          DatabaseHelper.tableUserPlants,
          where: 'id = ?',
          whereArgs: [plantId],
        );
      });

      if (_gardenRemoteDataSource != null) {
        try {
          await _gardenRemoteDataSource.deletePlant(plantId);
        } catch (_) {}
      }

      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Gagal menghapus tanaman: $e'));
    }
  }

  List<PlantCatalogModel> _getHardcodedDefaultSeeds() {
    return [
      PlantCatalogModel(
        id: 'cat_monstera',
        commonName: 'Monstera Deliciosa',
        scientificName: 'Monstera deliciosa',
        family: 'Araceae',
        defaultWateringInterval: 7,
        sunlightLevel: 'Sinar Tidak Langsung Terang',
        careLevel: 'EASY CARE',
        dimension: 'Tinggi 2,5 - 3 Meter',
        growthRate: 'Sedang',
        cycle: 'Perenial (Abadi)',
        pruningMonth: 'Musim Semi, Panas',
        floweringSeason: 'Jarang di Dalam Ruangan',
        description:
            'Monstera Deliciosa adalah tanaman hias tropis ikonik dari famili Araceae yang terkenal dengan daun lebar berlubang alami (fenestrasi).',
        toxicity:
            'Beracun jika tertelan oleh anjing atau kucing (kalsium oksalat).',
        isToxicToPets: true,
        cachedAt: DateTime.now(),
      ),
      PlantCatalogModel(
        id: 'cat_snake_plant',
        commonName: 'Snake Plant (Sansevieria)',
        scientificName: 'Dracaena trifasciata',
        family: 'Asparagaceae',
        defaultWateringInterval: 14,
        sunlightLevel: 'Pencahayaan Rendah s/d Terang',
        careLevel: 'EASY CARE',
        dimension: 'Tinggi 60 - 120 cm',
        growthRate: 'Lambat',
        cycle: 'Perenial (Abadi)',
        pruningMonth: 'Musim Semi',
        floweringSeason: 'Jarang di Dalam Ruangan',
        description:
            'Snake Plant (Sansevieria) adalah tanaman hias pemurni udara tangguh yang ideal bagi pemula.',
        toxicity: 'Beracun ringan bagi kucing & anjing.',
        isToxicToPets: true,
        cachedAt: DateTime.now(),
      ),
      PlantCatalogModel(
        id: 'cat_pothos',
        commonName: 'Golden Pothos (Sirih Gading)',
        scientificName: 'Epipremnum aureum',
        family: 'Araceae',
        defaultWateringInterval: 5,
        sunlightLevel: 'Pencahayaan Rendah s/d Sedang',
        careLevel: 'EASY CARE',
        dimension: 'Panjang 1,5 - 3 Meter',
        growthRate: 'Cepat',
        cycle: 'Perenial (Abadi)',
        pruningMonth: 'Sepanjang Tahun',
        floweringSeason: 'Jarang di Dalam Ruangan',
        description:
            'Golden Pothos (Sirih Gading) adalah tanaman merambat populer dengan daun bercorak cerah berbentuk hati.',
        toxicity: 'Beracun bagi hewan peliharaan jika daun tertelan.',
        isToxicToPets: true,
        cachedAt: DateTime.now(),
      ),
      PlantCatalogModel(
        id: 'cat_calathea',
        commonName: 'Calathea Orbifolia',
        scientificName: 'Calathea orbifolia',
        family: 'Marantaceae',
        defaultWateringInterval: 4,
        sunlightLevel: 'Sinar Tidak Langsung Sedang',
        careLevel: 'INTERMEDIATE',
        dimension: 'Tinggi 40 - 80 cm',
        growthRate: 'Sedang',
        cycle: 'Perenial (Abadi)',
        pruningMonth: 'Musim Semi',
        floweringSeason: 'Jarang di Dalam Ruangan',
        description:
            'Calathea Orbifolia memiliki corak daun lebar bergaris perak yang memukau dan aman bagi hewan peliharaan.',
        toxicity: 'Aman untuk kucing dan anjing (Non-toxic / Pet-friendly).',
        isToxicToPets: false,
        cachedAt: DateTime.now(),
      ),
    ];
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return 'Ags';
  }
}
