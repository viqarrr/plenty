import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/utils/result.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/datasources/plant_remote_data_source.dart';
import 'package:plenty/data/models/care_schedule_model.dart';
import 'package:plenty/data/models/growth_log_model.dart';
import 'package:plenty/data/models/perenual_care_guide_model.dart';
import 'package:plenty/data/models/plant_catalog_model.dart';
import 'package:plenty/data/models/plant_model.dart';
import 'package:plenty/data/models/time_capsule_model.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:plenty/domain/repositories/plant_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Implementation of [IPlantRepository] with strict Cache-First Perenual API integration.
class PlantRepositoryImpl implements IPlantRepository {
  final DatabaseHelper _dbHelper;
  final PlantRemoteDataSource _remoteDataSource;

  PlantRepositoryImpl({
    DatabaseHelper? dbHelper,
    PlantRemoteDataSource? remoteDataSource,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _remoteDataSource = remoteDataSource ?? PlantRemoteDataSourceImpl();

  @override
  Future<Result<List<PlantCatalogModel>>> getCatalogPlants({
    String? query,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    try {
      final db = await _dbHelper.database;
      final q = query?.trim();

      // 1. Check local SQLite Cache first (Quota preservation: 100 req/day)
      if (!forceRefresh) {
        final List<Map<String, dynamic>> localRows;
        if (q != null && q.isNotEmpty) {
          localRows = await db.query(
            DatabaseHelper.tablePlantCatalog,
            where: 'common_name LIKE ? OR scientific_name LIKE ?',
            whereArgs: ['%$q%', '%$q%'],
            orderBy: 'common_name ASC',
          );
        } else {
          localRows = await db.query(
            DatabaseHelper.tablePlantCatalog,
            orderBy: 'common_name ASC',
          );
        }

        if (localRows.isNotEmpty) {
          final cachedList =
              localRows.map((m) => PlantCatalogModel.fromMap(m)).toList();
          return Success(cachedList);
        }
      }

      // 2. Fetch from Remote Perenual API when absent locally or force refreshed
      try {
        final speciesList = await _remoteDataSource.fetchSpeciesList(
          page: page,
          query: q,
        );

        if (speciesList.isNotEmpty) {
          final catalogModels =
              speciesList.map((s) => s.toPlantCatalogModel()).toList();

          // Batch upsert into local SQLite
          final batch = db.batch();
          for (final model in catalogModels) {
            batch.insert(
              DatabaseHelper.tablePlantCatalog,
              model.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);

          return Success(catalogModels);
        }
      } catch (remoteError) {
        // If remote fails, fallback to checking local database or pre-seeded JSON
        final localCount = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.tablePlantCatalog}',
        ));

        if (localCount == null || localCount == 0) {
          return await seedCatalogFromAsset(query: q);
        }

        if (remoteError is Failure) {
          return Error(remoteError);
        }
        return Error(ServerFailure(remoteError.toString()));
      }

      // If remote returned empty and DB is empty, seed from asset
      final count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseHelper.tablePlantCatalog}',
      ));
      if (count == null || count == 0) {
        return await seedCatalogFromAsset(query: q);
      }

      return const Success([]);
    } catch (e) {
      return Error(DatabaseFailure('Gagal memuat katalog tanaman: $e'));
    }
  }

  @override
  Future<Result<PlantCatalogModel>> getPlantCatalogDetails(
    int speciesId, {
    bool forceRefresh = false,
  }) async {
    try {
      final db = await _dbHelper.database;
      final targetId = 'perenual_$speciesId';

      // 1. Check local SQLite Cache first
      if (!forceRefresh) {
        final rows = await db.query(
          DatabaseHelper.tablePlantCatalog,
          where: 'id = ? OR id = ?',
          whereArgs: [targetId, speciesId.toString()],
          limit: 1,
        );

        if (rows.isNotEmpty) {
          return Success(PlantCatalogModel.fromMap(rows.first));
        }
      }

      // 2. Fetch from Remote Perenual API
      try {
        final detail =
            await _remoteDataSource.fetchSpeciesDetails(speciesId);
        final catalogModel = detail.toPlantCatalogModel();

        // Upsert into local SQLite
        await db.insert(
          DatabaseHelper.tablePlantCatalog,
          catalogModel.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        return Success(catalogModel);
      } on Failure catch (failure) {
        return Error(failure);
      } catch (e) {
        return Error(ServerFailure(e.toString()));
      }
    } catch (e) {
      return Error(DatabaseFailure('Gagal memuat detail tanaman: $e'));
    }
  }

  @override
  Future<Result<List<PerenualCareGuideModel>>> getPlantCareGuides(
      int speciesId) async {
    try {
      final guides =
          await _remoteDataSource.fetchSpeciesCareGuides(speciesId);
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
    try {
      final db = await _dbHelper.database;
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
        // Hardcoded in-memory fallback if asset bundle is unavailable (e.g. unit test environment)
        seeds = _getHardcodedDefaultSeeds();
      }

      if (seeds.isNotEmpty) {
        final batch = db.batch();
        for (final seed in seeds) {
          batch.insert(
            DatabaseHelper.tablePlantCatalog,
            seed.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final filtered = seeds.where((s) {
          final name = s.commonName.toLowerCase();
          final sci = (s.scientificName ?? '').toLowerCase();
          return name.contains(q) || sci.contains(q);
        }).toList();
        return Success(filtered);
      }

      return Success(seeds);
    } catch (e) {
      return Error(CacheFailure('Gagal melakukan pre-seed katalog: $e'));
    }
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
    String? windowDistance,
    double? initialHeightCm,
    String growthStage = 'mature',
    String? coverPhotoPath,
    String? customPhotoPath,
    TimeCapsuleDraft? timeCapsule,
    int defaultWateringInterval = 3,
  }) async {
    try {
      final db = await _dbHelper.database;

      final int parsedUserId = int.tryParse(userId.toString()) ?? 1;

      final result = await db.transaction<AddPlantResult>((txn) async {
        // 1. Ensure user exists to satisfy foreign key constraint
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

        // 2. Ensure species exists in plant_catalog to satisfy foreign key constraint
        String? finalCatalogId = catalogId ?? species?.id;
        if (species != null) {
          await txn.insert(
            DatabaseHelper.tablePlantCatalog,
            species.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          finalCatalogId = species.id;
        } else if (finalCatalogId != null) {
          final catRows = await txn.query(
            DatabaseHelper.tablePlantCatalog,
            where: 'id = ?',
            whereArgs: [finalCatalogId],
            limit: 1,
          );
          if (catRows.isEmpty) {
            finalCatalogId = null; // Prevent FK failure if catalog id does not exist
          }
        }

        final existingPlants = await txn.query(
          DatabaseHelper.tableUserPlants,
          where: 'user_id = ? AND is_archived = 0',
          whereArgs: [parsedUserId],
        );
        final isFirstPlant = existingPlants.isEmpty;

        final adoptedAt = DateTime.now();
        final plantId =
            'plant_${adoptedAt.millisecondsSinceEpoch}_${nickname.hashCode.abs()}';

        final plant = PlantModel(
          id: plantId,
          userId: userId,
          catalogId: finalCatalogId,
          nickname: nickname,
          isIndoor: isIndoor,
          sunlightCondition: sunlightCondition,
          potSize: potSize,
          windowDistance: windowDistance,
          initialHeightCm: initialHeightCm ?? 30.0,
          growthStage: growthStage,
          adoptedAt: adoptedAt,
          coverPhotoPath: coverPhotoPath ?? customPhotoPath ?? species?.imageUrl ?? species?.localImagePath,
          healthStatus: 'healthy',
          level: 1,
          xp: 0,
          isArchived: false,
          commonName: species?.commonName,
          defaultWateringInterval:
              species?.defaultWateringInterval ?? defaultWateringInterval,
        );

        await txn.insert(
          DatabaseHelper.tableUserPlants,
          plant.toMap(),
        );

        final initialLog = GrowthLogModel(
          id: 'log_${adoptedAt.millisecondsSinceEpoch}',
          userPlantId: plantId,
          loggedAt: adoptedAt,
          heightCm: initialHeightCm ?? 30.0,
          photoPath: customPhotoPath,
          source: 'initial',
          note: 'Adopsi pertama $nickname',
        );
        await txn.insert(
          DatabaseHelper.tableGrowthLogs,
          initialLog.toMap(),
        );

        final interval =
            species?.defaultWateringInterval ?? defaultWateringInterval;
        final schedules = [
          CareScheduleModel(
            id: 'sched_${plantId}_siram',
            userPlantId: plantId,
            taskType: 'siram',
            intervalDays: interval,
            nextDueDate: adoptedAt.add(Duration(days: interval)),
            isActive: true,
          ),
          CareScheduleModel(
            id: 'sched_${plantId}_bersih',
            userPlantId: plantId,
            taskType: 'bersih_bersih',
            intervalDays: 7,
            nextDueDate: adoptedAt.add(const Duration(days: 7)),
            isActive: true,
          ),
          CareScheduleModel(
            id: 'sched_${plantId}_tinggi',
            userPlantId: plantId,
            taskType: 'monitor_tinggi',
            intervalDays: 1,
            nextDueDate: adoptedAt.add(const Duration(days: 1)),
            isActive: true,
          ),
        ];

        for (final s in schedules) {
          await txn.insert(
            DatabaseHelper.tableCareSchedules,
            s.toMap(),
          );
        }

        if (timeCapsule != null && timeCapsule.note != null && timeCapsule.note!.isNotEmpty) {
          final capsuleModel = TimeCapsuleModel(
            id: 'capsule_${adoptedAt.millisecondsSinceEpoch}',
            userPlantId: plantId,
            photoPath: timeCapsule.photoPath,
            note: timeCapsule.note,
            createdAt: adoptedAt,
            unlockAt: timeCapsule.unlockAt,
            isUnlocked: false,
          );
          await txn.insert(
            DatabaseHelper.tableTimeCapsules,
            capsuleModel.toMap(),
          );
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
      final parsedUserId = int.tryParse(userId.toString()) ?? 1;
      
      var maps = await db.rawQuery('''
        SELECT up.*, pc.common_name, pc.default_watering_interval
        FROM ${DatabaseHelper.tableUserPlants} up
        LEFT JOIN ${DatabaseHelper.tablePlantCatalog} pc ON up.catalog_id = pc.id
        WHERE (up.user_id = ? OR CAST(up.user_id AS TEXT) = ?) AND up.is_archived = 0
        ORDER BY up.adopted_at DESC
      ''', [parsedUserId, userId.toString()]);

      if (maps.isEmpty && parsedUserId != 1) {
        maps = await db.rawQuery('''
          SELECT up.*, pc.common_name, pc.default_watering_interval
          FROM ${DatabaseHelper.tableUserPlants} up
          LEFT JOIN ${DatabaseHelper.tablePlantCatalog} pc ON up.catalog_id = pc.id
          WHERE (up.user_id = 1 OR CAST(up.user_id AS TEXT) = '1' OR CAST(up.user_id AS TEXT) = 'usr_default') AND up.is_archived = 0
          ORDER BY up.adopted_at DESC
        ''');
      }

      if (maps.isEmpty) {
        maps = await db.rawQuery('''
          SELECT up.*, pc.common_name, pc.default_watering_interval
          FROM ${DatabaseHelper.tableUserPlants} up
          LEFT JOIN ${DatabaseHelper.tablePlantCatalog} pc ON up.catalog_id = pc.id
          WHERE up.is_archived = 0
          ORDER BY up.adopted_at DESC
        ''');
      }

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
      final maps = await db.rawQuery('''
        SELECT up.*, pc.common_name, pc.default_watering_interval
        FROM ${DatabaseHelper.tableUserPlants} up
        LEFT JOIN ${DatabaseHelper.tablePlantCatalog} pc ON up.catalog_id = pc.id
        WHERE up.id = ?
        LIMIT 1
      ''', [plantId]);

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
  }) async {
    try {
      final db = await _dbHelper.database;
      final values = <String, dynamic>{
        'nickname': nickname.trim(),
      };
      if (updatePhoto) {
        values['cover_photo_path'] = coverPhotoPath;
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
        {'cover_photo_path': photoPath},
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
}
