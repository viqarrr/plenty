import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:plenty/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:plenty/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:plenty/features/auth/domain/repositories/auth_repository.dart';
import 'package:plenty/features/community/data/repositories/community_repository_impl.dart';
import 'package:plenty/features/community/domain/repositories/community_repository.dart';
import 'package:plenty/features/daily_care/data/repositories/daily_care_repository_impl.dart';
import 'package:plenty/features/daily_care/domain/repositories/daily_care_repository.dart';
import 'package:plenty/features/garden/data/data_sources/plant_remote_data_source.dart';
import 'package:plenty/features/garden/data/repositories/growth_repository_impl.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository_impl.dart';
import 'package:plenty/features/garden/data/repositories/site_repository_impl.dart';
import 'package:plenty/features/garden/data/repositories/streak_repository_impl.dart';
import 'package:plenty/features/garden/domain/repositories/growth_repository.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
import 'package:plenty/features/garden/domain/repositories/site_repository.dart';
import 'package:plenty/features/garden/domain/repositories/streak_repository.dart';
import 'package:plenty/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:plenty/features/profile/data/repositories/badge_repository_impl.dart';
import 'package:plenty/features/profile/data/repositories/user_repository_impl.dart';
import 'package:plenty/features/profile/domain/repositories/badge_repository.dart';
import 'package:plenty/features/profile/domain/repositories/user_repository.dart';

/// Central manual dependency injector using lazy initialization.
class Injector {
  Injector._();

  // Core & Database
  static DatabaseHelper? _databaseHelper;
  static DatabaseHelper get databaseHelper =>
      _databaseHelper ??= DatabaseHelper.instance;

  // Datasources
  static PlantRemoteDataSource? _plantRemoteDataSource;
  static PlantRemoteDataSource get plantRemoteDataSource =>
      _plantRemoteDataSource ??= PlantRemoteDataSourceImpl();

  static AuthRemoteDataSource? _authRemoteDataSource;
  static AuthRemoteDataSource get authRemoteDataSource =>
      _authRemoteDataSource ??= FirebaseAuthRemoteDataSourceImpl();

  static AuthLocalDataSource? _authLocalDataSource;
  static AuthLocalDataSource get authLocalDataSource =>
      _authLocalDataSource ??= AuthLocalDataSourceImpl(databaseHelper);

  static ProfileRemoteDataSource? _profileRemoteDataSource;
  static ProfileRemoteDataSource get profileRemoteDataSource =>
      _profileRemoteDataSource ??= FirestoreProfileRemoteDataSourceImpl();

  // Repositories
  static IAuthRepository? _authRepository;
  static IAuthRepository get authRepository =>
      _authRepository ??= AuthRepositoryImpl(
        remoteDataSource: authRemoteDataSource,
        localDataSource: authLocalDataSource,
      );

  static IBadgeRepository? _badgeRepository;
  static IBadgeRepository get badgeRepository =>
      _badgeRepository ??= BadgeRepositoryImpl(
        dbHelper: databaseHelper,
        remoteDataSource: profileRemoteDataSource,
      );

  static IUserRepository? _userRepository;
  static IUserRepository get userRepository =>
      _userRepository ??= UserRepositoryImpl(
        dbHelper: databaseHelper,
        remoteDataSource: profileRemoteDataSource,
      );

  static ISiteRepository? _siteRepository;
  static ISiteRepository get siteRepository =>
      _siteRepository ??= SiteRepositoryImpl(dbHelper: databaseHelper);

  static IPlantRepository? _plantRepository;
  static IPlantRepository get plantRepository =>
      _plantRepository ??= PlantRepositoryImpl(
        dbHelper: databaseHelper,
        remoteDataSource: plantRemoteDataSource,
        badgeRepo: badgeRepository,
      );

  static IStreakRepository? _streakRepository;
  static IStreakRepository get streakRepository =>
      _streakRepository ??= StreakRepositoryImpl(
        dbHelper: databaseHelper,
        badgeRepo: badgeRepository,
        remoteDataSource: profileRemoteDataSource,
      );

  static IDailyCareRepository? _dailyCareRepository;
  static IDailyCareRepository get dailyCareRepository =>
      _dailyCareRepository ??= DailyCareRepositoryImpl(
        dbHelper: databaseHelper,
        plantRepo: plantRepository,
        streakRepo: streakRepository,
        badgeRepo: badgeRepository,
        remoteDataSource: profileRemoteDataSource,
      );

  static ICommunityRepository? _communityRepository;
  static ICommunityRepository get communityRepository =>
      _communityRepository ??= CommunityRepositoryImpl(
        dbHelper: databaseHelper,
      );

  static IGrowthRepository? _growthRepository;
  static IGrowthRepository get growthRepository =>
      _growthRepository ??= GrowthRepositoryImpl(dbHelper: databaseHelper);

  // Setters for testing and mock injection
  static set databaseHelper(DatabaseHelper? helper) => _databaseHelper = helper;
  static set plantRemoteDataSource(PlantRemoteDataSource? ds) =>
      _plantRemoteDataSource = ds;
  static set authRemoteDataSource(AuthRemoteDataSource? ds) =>
      _authRemoteDataSource = ds;
  static set authLocalDataSource(AuthLocalDataSource? ds) =>
      _authLocalDataSource = ds;
  static set profileRemoteDataSource(ProfileRemoteDataSource? ds) =>
      _profileRemoteDataSource = ds;
  static set authRepository(IAuthRepository? repo) => _authRepository = repo;
  static set badgeRepository(IBadgeRepository? repo) => _badgeRepository = repo;
  static set userRepository(IUserRepository? repo) => _userRepository = repo;
  static set siteRepository(ISiteRepository? repo) => _siteRepository = repo;
  static set plantRepository(IPlantRepository? repo) => _plantRepository = repo;
  static set streakRepository(IStreakRepository? repo) =>
      _streakRepository = repo;
  static set dailyCareRepository(IDailyCareRepository? repo) =>
      _dailyCareRepository = repo;
  static set communityRepository(ICommunityRepository? repo) =>
      _communityRepository = repo;
  static set growthRepository(IGrowthRepository? repo) =>
      _growthRepository = repo;

  /// Resets all singleton instances for isolated unit/widget tests.
  static void reset() {
    _databaseHelper = null;
    _plantRemoteDataSource = null;
    _authRemoteDataSource = null;
    _authLocalDataSource = null;
    _profileRemoteDataSource = null;
    _authRepository = null;
    _badgeRepository = null;
    _userRepository = null;
    _siteRepository = null;
    _plantRepository = null;
    _streakRepository = null;
    _dailyCareRepository = null;
    _communityRepository = null;
    _growthRepository = null;
  }
}
