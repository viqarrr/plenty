import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/garden/domain/models/site_model.dart';

/// Contract interface for Site Repository.
abstract interface class ISiteRepository {
  /// Mengambil semua site milik user (default + custom), diurutkan: default dulu baru custom.
  Future<Result<List<SiteModel>>> getSites([String userId = '1']);

  /// Menambah site custom baru. Selalu tersimpan dengan isCustom = true.
  Future<Result<void>> addCustomSite(SiteModel site);

  /// Mengubah site custom. Menolak (return Error) kalau site target isCustom == false.
  Future<Result<void>> updateCustomSite(SiteModel site);

  /// Menghapus site custom. Menolak (return Error) kalau site target isCustom == false.
  Future<Result<void>> deleteCustomSite(String siteId);
}
