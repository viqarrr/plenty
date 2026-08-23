import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/garden/domain/models/custom_site_model.dart';

/// Contract interface for Site Repository.
abstract interface class ISiteRepository {
  /// Retrieves all custom sites for the specified user ordered chronologically.
  Future<Result<List<CustomSiteModel>>> getCustomSites([String userId = '1']);

  /// Inserts a new custom site record.
  Future<Result<void>> saveCustomSite(CustomSiteModel site);

  /// Updates an existing custom site record.
  Future<Result<void>> updateCustomSite(CustomSiteModel site);

  /// Deletes a custom site record by ID.
  Future<Result<void>> deleteCustomSite(String siteId);
}
