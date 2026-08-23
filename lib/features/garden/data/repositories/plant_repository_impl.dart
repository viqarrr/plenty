import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/daily_care/domain/models/care_schedule_model.dart';
import 'package:plenty/core/domain/models/growth_log_model.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
import 'package:plenty/features/plant_catalog/data/datasources/plant_remote_data_source.dart';
import 'package:plenty/features/plant_catalog/domain/models/perenual_care_guide_model.dart';
import 'package:plenty/features/plant_catalog/domain/models/plant_catalog_model.dart';
import 'package:sqflite/sqflite.dart';

/// Implementation of [IPlantRepository] using Direct API calls + In-Memory Session Cache
/// and persisting adopted plants as self-contained snapshots in SQLite.
class PlantRepositoryImpl implements IPlantRepository {
  final DatabaseHelper _dbHelper;
  final PlantRemoteDataSource _remoteDataSource;

  // In-Memory Session Caches (zero SQLite disk hoarding)
  final Map<String, List<PlantCatalogModel>> _sessionCatalogCache = {};
  final Map<int, PlantCatalogModel> _sessionDetailCache = {};
  final Map<int, List<PerenualCareGuideModel>> _sessionCareGuideCache = {};

  PlantRepositoryImpl({
    DatabaseHelper? dbHelper,
    PlantRemoteDataSource? remoteDataSource,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _remoteDataSource = remoteDataSource ?? PlantRemoteDataSourceImpl();

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
        final catalogModels =
            speciesList.map((s) => s.toPlantCatalogModel()).toList();
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
      int speciesId) async {
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
      final jsonString =
          await rootBundle.loadString('assets/data/seed_plants.json');
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      seeds = jsonList
          .whereType<Map<String, dynamic>>()
          .map((m) => PlantCatalogModel.fromMap({
                ...m,
                'cached_at': DateTime.now().toIso8601String(),
              }))
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
    String? site,
    String? windowDistance,
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
      final int parsedUserId = int.tryParse(userId.toString()) ?? 1;

      final result = await db.transaction<AddPlantResult>((txn) async {
        // 1. Ensure user row exists for relational integrity
        final userRows = await txn.query(
          DatabaseHelper.tableUsers,
          where: 'id = ?',
          whereArgs: [parsedUserId],
          limit: 1,
        );
        if (userRows.isEmpty) {
          await txn.insert(
            DatabaseHelper.tableUsers,
            {
              'id': parsedUserId,
              'email': 'user_$parsedUserId@plenty.app',
              'username': 'user_$parsedUserId',
              'password': '',
              'display_name': 'Pecinta Tanaman',
              'created_at': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        // Check if this is the user's first plant
        final existingPlants = await txn.query(
          DatabaseHelper.tableUserPlants,
          where: 'user_id = ? AND is_archived = 0',
          whereArgs: [parsedUserId],
        );
        final isFirstPlant = existingPlants.isEmpty;

        final effectiveAdoptedAt = adoptedAt ?? DateTime.now();
        final plantId =
            'plant_${DateTime.now().millisecondsSinceEpoch}_${nickname.hashCode.abs()}';

        final effectiveSite = site ?? windowDistance ?? 'Ruang Tamu';
        final photo = coverPhotoPath ??
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
          userId: userId,
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
          site: effectiveSite,
          roomName: effectiveSite,
          windowDistance: windowDistance ?? effectiveSite,
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

        await txn.insert(
          DatabaseHelper.tableUserPlants,
          plant.toMap(),
        );

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
        await txn.insert(
          DatabaseHelper.tableGrowthLogs,
          initialLog.toMap(),
        );

        // 4. Insert care schedules
        final now = DateTime.now();
        final schedules = [
          CareScheduleModel(
            id: 'sched_${plantId}_siram',
            userPlantId: plantId,
            taskType: 'siram',
            intervalDays: interval,
            nextDueDate: now.add(Duration(days: interval)),
            isActive: true,
          ),
          CareScheduleModel(
            id: 'sched_${plantId}_bersih',
            userPlantId: plantId,
            taskType: 'bersih_bersih',
            intervalDays: 7,
            nextDueDate: now.add(const Duration(days: 7)),
            isActive: true,
          ),
          CareScheduleModel(
            id: 'sched_${plantId}_tinggi',
            userPlantId: plantId,
            taskType: 'monitor_tinggi',
            intervalDays: 1,
            nextDueDate: now.add(const Duration(days: 1)),
            isActive: true,
          ),
        ];

        for (final s in schedules) {
          await txn.insert(
            DatabaseHelper.tableCareSchedules,
            s.toMap(),
          );
        }

        // 5. Check first plant badge
        if (isFirstPlant) {
          final formattedDate =
              '${now.day} ${_monthName(now.month)} ${now.year}';
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

          final userQuery = await txn.query(
            DatabaseHelper.tableUsers,
            where: 'id = ?',
            whereArgs: [parsedUserId],
            limit: 1,
          );
          if (userQuery.isNotEmpty) {
            final currentBadges =
                (userQuery.first['unlocked_badges_count'] as int?) ?? 0;
            if (currentBadges < 1) {
              await txn.update(
                DatabaseHelper.tableUsers,
                {'unlocked_badges_count': 1},
                where: 'id = ?',
                whereArgs: [parsedUserId],
              );
            }
          }
        }

        // 6. Insert time capsule if provided
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

          final userQuery = await txn.query(
            DatabaseHelper.tableUsers,
            where: 'id = ?',
            whereArgs: [parsedUserId],
            limit: 1,
          );
          if (userQuery.isNotEmpty) {
            final currentBadges =
                (userQuery.first['unlocked_badges_count'] as int?) ?? 0;
            final targetBadges = currentBadges >= 5 ? currentBadges : 5;
            await txn.update(
              DatabaseHelper.tableUsers,
              {'unlocked_badges_count': targetBadges},
              where: 'id = ?',
              whereArgs: [parsedUserId],
            );
          }
        }

        return AddPlantResult(plant: plant, isFirstPlant: isFirstPlant);
      });

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
      final parsedUserId = int.tryParse(userId.toString());

      // Query user_plants directly - 100% self-contained snapshot with zero catalog joins
      final maps = await db.query(
        DatabaseHelper.tableUserPlants,
        where:
            '(user_id = ? OR CAST(user_id AS TEXT) = ?) AND is_archived = 0',
        whereArgs: [parsedUserId ?? userId, userId.toString()],
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

      if (maps.isEmpty) return const Success(null);
      return Success(PlantModel.fromMap(maps.first));
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
    String? site,
  }) async {
    try {
      final db = await _dbHelper.database;
      final values = <String, dynamic>{
        'nickname': nickname.trim(),
      };
      if (updatePhoto) {
        values['cover_photo_path'] = coverPhotoPath;
        values['image_path'] = coverPhotoPath;
      }
      if (site != null) {
        values['site'] = site;
        values['room_name'] = site;
        values['window_distance'] = site;
      }
      await db.update(
        DatabaseHelper.tableUserPlants,
        values,
        where: 'id = ?',
        whereArgs: [plantId],
      );
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
        {
          'cover_photo_path': photoPath,
          'image_path': photoPath,
        },
        where: 'id = ?',
        whereArgs: [plantId],
      );
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
