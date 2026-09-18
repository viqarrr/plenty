import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';
import 'package:plenty/features/garden/domain/models/site_model.dart';

/// Contract interface for Garden Sites and User Plant Catalog operations in Cloud Firestore.
abstract interface class GardenRemoteDataSource {
  // --- Sites Operations ---
  /// Fetches all sites belonging to the specified user from Firestore collection `sites`.
  Future<List<SiteModel>> getSites(String userId);

  /// Saves or upserts a site to Firestore collection `sites/{siteId}`.
  Future<void> saveSite(SiteModel site);

  /// Updates an existing site in Firestore collection `sites/{siteId}`.
  Future<void> updateSite(SiteModel site);

  /// Deletes a site from Firestore collection `sites/{siteId}`.
  Future<void> deleteSite(String siteId);

  // --- Plant Operations ---
  /// Fetches all active (non-archived) plants belonging to the specified user from Firestore `user_plants`.
  Future<List<PlantModel>> getUserPlants(String userId);

  /// Fetches an adopted plant by its document ID from Firestore collection `user_plants/{plantId}`.
  Future<PlantModel?> getPlantById(String plantId);

  /// Saves or upserts a plant document in Firestore collection `user_plants/{plantId}`.
  Future<void> savePlant(PlantModel plant);

  /// Updates specific plant attributes in Firestore collection `user_plants/{plantId}`.
  Future<void> updatePlant(String plantId, Map<String, dynamic> data);

  /// Archives a plant document by setting `is_archived = true` in Firestore collection `user_plants/{plantId}`.
  Future<void> archivePlant(String plantId);

  /// Deletes a plant document from Firestore collection `user_plants/{plantId}`.
  Future<void> deletePlant(String plantId);
}

/// Concrete implementation of [GardenRemoteDataSource] backed by Cloud Firestore.
class FirestoreGardenRemoteDataSourceImpl implements GardenRemoteDataSource {
  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  static const String sitesCollection = 'sites';
  static const String userPlantsCollection = 'user_plants';

  FirestoreGardenRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  @override
  Future<List<SiteModel>> getSites(String userId) async {
    final querySnap = await _firestore
        .collection(sitesCollection)
        .where('user_id', isEqualTo: userId)
        .get();

    final sites = querySnap.docs
        .map((doc) => SiteModel.fromMap(doc.data()))
        .toList();

    // Sort in memory: default sites first, then by creation date
    sites.sort((a, b) {
      if (a.isCustom != b.isCustom) {
        return a.isCustom ? 1 : -1;
      }
      return a.createdAt.compareTo(b.createdAt);
    });

    return sites;
  }

  @override
  Future<void> saveSite(SiteModel site) async {
    await _firestore
        .collection(sitesCollection)
        .doc(site.id)
        .set(site.toFirestoreMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateSite(SiteModel site) async {
    await _firestore
        .collection(sitesCollection)
        .doc(site.id)
        .set(site.toFirestoreMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteSite(String siteId) async {
    await _firestore.collection(sitesCollection).doc(siteId).delete();
  }

  @override
  Future<List<PlantModel>> getUserPlants(String userId) async {
    final querySnap = await _firestore
        .collection(userPlantsCollection)
        .where('user_id', isEqualTo: userId)
        .get();

    final plants = querySnap.docs
        .map((doc) => PlantModel.fromMap(doc.data()))
        .where((plant) => !plant.isArchived)
        .toList();

    // Sort in memory: most recently adopted first
    plants.sort((a, b) => b.adoptedAt.compareTo(a.adoptedAt));

    return plants;
  }

  @override
  Future<PlantModel?> getPlantById(String plantId) async {
    final doc =
        await _firestore.collection(userPlantsCollection).doc(plantId).get();
    if (doc.exists && doc.data() != null) {
      return PlantModel.fromMap(doc.data()!);
    }
    return null;
  }

  @override
  Future<void> savePlant(PlantModel plant) async {
    await _firestore
        .collection(userPlantsCollection)
        .doc(plant.id)
        .set(plant.toFirestoreMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updatePlant(String plantId, Map<String, dynamic> data) async {
    final sanitizedData = Map<String, dynamic>.from(data)
      ..removeWhere((key, value) => value == null);

    await _firestore
        .collection(userPlantsCollection)
        .doc(plantId)
        .set(sanitizedData, SetOptions(merge: true));
  }

  @override
  Future<void> archivePlant(String plantId) async {
    await _firestore
        .collection(userPlantsCollection)
        .doc(plantId)
        .set({'is_archived': true}, SetOptions(merge: true));
  }

  @override
  Future<void> deletePlant(String plantId) async {
    await _firestore.collection(userPlantsCollection).doc(plantId).delete();
  }
}
