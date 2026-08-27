import 'package:flutter/material.dart';
import 'package:plenty/core/constants/site_icons.dart';
import 'package:plenty/features/garden/domain/models/site_model.dart';

extension SiteModelUIExtension on SiteModel {
  static final Map<int, IconData> _iconMap = {
    // Default site codes
    SiteIcons.livingRoomIconCode: Icons.weekend_outlined,
    SiteIcons.bedroomIconCode: Icons.bed_outlined,
    SiteIcons.balconyIconCode: Icons.balcony_outlined,
    SiteIcons.kitchenIconCode: Icons.soup_kitchen_outlined,
    SiteIcons.terraceIconCode: Icons.deck_outlined,
    // Solid icon codes
    Icons.weekend.codePoint: Icons.weekend_outlined,
    Icons.bed.codePoint: Icons.bed_outlined,
    Icons.balcony.codePoint: Icons.balcony_outlined,
    Icons.kitchen.codePoint: Icons.soup_kitchen_outlined,
    Icons.deck.codePoint: Icons.deck_outlined,
    // Outlined icon codes
    Icons.weekend_outlined.codePoint: Icons.weekend_outlined,
    Icons.bed_outlined.codePoint: Icons.bed_outlined,
    Icons.soup_kitchen_outlined.codePoint: Icons.soup_kitchen_outlined,
    Icons.computer_outlined.codePoint: Icons.computer_outlined,
    Icons.table_restaurant_outlined.codePoint: Icons.table_restaurant_outlined,
    Icons.chair_outlined.codePoint: Icons.chair_outlined,
    Icons.bathtub_outlined.codePoint: Icons.bathtub_outlined,
    Icons.meeting_room_outlined.codePoint: Icons.meeting_room_outlined,
    Icons.balcony_outlined.codePoint: Icons.balcony_outlined,
    Icons.yard_outlined.codePoint: Icons.yard_outlined,
    Icons.deck_outlined.codePoint: Icons.deck_outlined,
    Icons.fence_outlined.codePoint: Icons.fence_outlined,
    Icons.window_outlined.codePoint: Icons.window_outlined,
    Icons.roofing_outlined.codePoint: Icons.roofing_outlined,
    Icons.park_outlined.codePoint: Icons.park_outlined,
    Icons.local_florist_outlined.codePoint: Icons.local_florist_outlined,
  };

  IconData get iconData =>
      _iconMap[iconCode] ??
      (isIndoor ? Icons.meeting_room_outlined : Icons.park_outlined);
}
