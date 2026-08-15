import 'dart:convert';

import 'package:plenty/models/plant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelperAG {
  DatabaseHelperAG._();

  static const String _keyUserPlants = "user_plants";
  static const String _keyProfileName = "profile_name";
  static const String _keyStreak = "streak_count";

  // Predefined catalog plants matching figma.json
  static final List<Plant> catalogPlants = [
    Plant(
      id: "cat_1",
      name: "Fiddle Leaf Fig",
      scientificName: "Ficus lyrata",
      location: "Indoor",
      containerDetail: "Ada Lubang Drainase",
      lightIntensity: "Sinar Tidak Langsung",
      distanceFromWindow: "Dekat Jendela (1-1.5 meter)",
      specificArea: "Ruang Tamu",
      imageAsset: "assets/images/fiddle_leaf.png",
      careLevel: "MEDIUM CARE",
      waterSchedule: "Setiap 7-10 Hari",
      lightSchedule: "Cahaya Tidak Langsung (Teduh Sebagian)",
      toxicity:
          "Beracun bagi kucing, anjing, dan manusia jika tertelan. Mengandung kristal kalsium oksalat.",
      description:
          "Ficus lyrata, umumnya dikenal sebagai Fiddle Leaf Fig, adalah spesies pohon ara yang berasal dari hutan hujan tropis Afrika Barat. Sangat populer sebagai tanaman hias dalam ruangan dengan daunnya yang lebar menyerupai biola.",
      maxHeight: "2-3 meter",
      growthRate: "Sedang",
      growthCycle: "Perenial (Menahun)",
      pruningSeason: "Musim Semi & Panas",
      flowerStatus: "Jarang Berbunga",
      pests:
          "Rentan terhadap kutu putih, tungau laba-laba, dan serangga sisik.",
      nextWaterDate: "Siram sekarang",
      lastCleanedDate: "Bersihkan sekarang",
    ),
    Plant(
      id: "cat_2",
      name: "Snake Plant",
      scientificName: "Dracaena trifasciata",
      location: "Indoor",
      containerDetail: "Ada Lubang Drainase",
      lightIntensity: "Pencahayaan Rendah",
      distanceFromWindow: "Jauh dari Jendela (2 meter +)",
      specificArea: "Kamar",
      imageAsset: "assets/images/snake_plant.png",
      careLevel: "EASY CARE",
      waterSchedule: "Setiap 14-20 Hari",
      lightSchedule: "Teduh Sebagian hingga Pencahayaan Rendah",
      toxicity: "Beracun bagi kucing, anjing, dan manusia jika tertelan.",
      description:
          "Dracaena trifasciata adalah spesies tumbuhan berbunga dalam keluarga Asparagaceae, yang berasal dari Afrika Barat tropis. Dikenal karena daunnya yang kaku dan tegak, tanaman ini sangat toleran terhadap kelalaian penyiraman.",
      maxHeight: "1-1.5 meter",
      growthRate: "Lambat",
      growthCycle: "Perenial (Menahun)",
      pruningSeason: "Tidak Perlu Pemangkasan Rutin",
      flowerStatus: "Sangat Jarang Berbunga",
      pests: "Rentan terhadap busuk akar jika terlalu sering disiram.",
      nextWaterDate: "Siram 5 hari lagi",
      lastCleanedDate: "Bersihkan sekarang",
    ),
  ];

  static Future<List<Plant>> getUserPlants() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyUserPlants);
    if (jsonString == null) {
      // Return some default plants for first-time visual experience
      return [
        Plant(
          id: "default_1",
          name: "Monstera",
          scientificName: "Monstera Deliciosa",
          location: "Indoor",
          containerDetail: "Ada Lubang Drainase",
          lightIntensity: "Sinar Tidak Langsung",
          distanceFromWindow: "Dekat Jendela",
          specificArea: "Ruang Tamu",
          imageAsset: "assets/images/monstera.png",
          careLevel: "EASY CARE",
          waterSchedule: "Setiap 7-10 Hari",
          lightSchedule: "Cahaya Tidak Langsung",
          toxicity: "Beracun bagi kucing, anjing, dan manusia.",
          description:
              "Monstera deliciosa adalah tanaman hias ikonik dengan daun berlubang indah.",
          maxHeight: "2-3 meter",
          growthRate: "Sedang",
          growthCycle: "Perenial",
          pruningSeason: "Musim Semi",
          flowerStatus: "Jarang Berbunga",
          pests: "Kutu putih",
          nextWaterDate: "Siram 2 hari lagi",
          lastCleanedDate: "Bersihkan sekarang",
        ),
        Plant(
          id: "default_2",
          name: "Snake Plant",
          scientificName: "Dracaena trifasciata",
          location: "Indoor",
          containerDetail: "Ada Lubang Drainase",
          lightIntensity: "Pencahayaan rendah",
          distanceFromWindow: "Jauh dari Jendela",
          specificArea: "Kamar",
          imageAsset: "assets/images/snake_plant.png",
          careLevel: "EASY CARE",
          waterSchedule: "Setiap 14 Hari",
          lightSchedule: "Pencahayaan rendah",
          toxicity: "Beracun bagi kucing",
          description: "Tanaman lidah mertua yang tangguh dan mudah dirawat.",
          maxHeight: "1 meter",
          growthRate: "Lambat",
          growthCycle: "Perenial",
          pruningSeason: "Tidak perlu",
          flowerStatus: "Sangat jarang",
          pests: "Busuk akar",
          nextWaterDate: "Bersihkan sekarang",
          lastCleanedDate: "Bersihkan sekarang",
        ),
        Plant(
          id: "default_3",
          name: "Fiddle Leaf",
          scientificName: "Ficus lyrata",
          location: "Indoor",
          containerDetail: "Ada Lubang Drainase",
          lightIntensity: "Sinar Tidak Langsung",
          distanceFromWindow: "Dekat Jendela",
          specificArea: "Dapur",
          imageAsset: "assets/images/fiddle_leaf.png",
          careLevel: "MEDIUM CARE",
          waterSchedule: "Setiap 7 Hari",
          lightSchedule: "Cahaya Terang",
          description: "Pohon ara daun biola yang artistik.",
          toxicity: "Sedikit beracun",
          maxHeight: "3 meter",
          growthRate: "Sedang",
          growthCycle: "Perenial",
          pruningSeason: "Musim Panas",
          flowerStatus: "Tidak berbunga",
          pests: "Tungau laba-laba",
          nextWaterDate: "Siram sekarang",
          lastCleanedDate: "Bersihkan sekarang",
        ),
      ];
    }
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((item) => Plant.fromJson(item)).toList();
  }

  static Future<void> saveUserPlants(List<Plant> plants) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = plants.map((p) => p.toJson()).toList();
    await prefs.setString(_keyUserPlants, jsonEncode(jsonList));
  }

  static Future<void> addUserPlant(Plant plant) async {
    final plants = await getUserPlants();
    // Avoid duplicates
    plants.removeWhere((p) => p.id == plant.id);
    plants.add(plant);
    await saveUserPlants(plants);
  }

  static Future<void> removeUserPlant(String id) async {
    final plants = await getUserPlants();
    plants.removeWhere((p) => p.id == id);
    await saveUserPlants(plants);
  }

  static Future<String> getProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProfileName) ?? "John";
  }

  static Future<void> setProfileName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfileName, name);
  }

  static Future<int> getStreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreak) ?? 1;
  }

  static Future<void> setStreakCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStreak, count);
  }
}
