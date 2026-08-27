/// Constants for plant sites and their corresponding icon code points.
abstract final class SiteIcons {
  SiteIcons._();

  // Default Site IDs
  static const String defaultLivingRoomId = 'site_default_ruang_tamu';
  static const String defaultBedroomId = 'site_default_kamar_tidur';
  static const String defaultBalconyId = 'site_default_balkon';
  static const String defaultKitchenId = 'site_default_dapur';
  static const String defaultTerraceId = 'site_default_teras';

  // Default Icon Code Points (Flutter Material Icons integer values)
  static const int livingRoomIconCode = 59087; // Icons.weekend.codePoint
  static const int bedroomIconCode = 57568;    // Icons.bed.codePoint
  static const int balconyIconCode = 57547;    // Icons.balcony.codePoint
  static const int kitchenIconCode = 58213;    // Icons.kitchen.codePoint
  static const int terraceIconCode = 57803;    // Icons.deck.codePoint
}
