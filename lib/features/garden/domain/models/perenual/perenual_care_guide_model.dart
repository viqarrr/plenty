import 'package:flutter/foundation.dart';

/// Single section in a plant care guide (e.g. watering, sunlight, pruning).
@immutable
class PerenualCareGuideSection {
  final int? id;
  final String type;
  final String description;

  const PerenualCareGuideSection({
    this.id,
    required this.type,
    required this.description,
  });

  factory PerenualCareGuideSection.fromJson(Map<String, dynamic> json) {
    return PerenualCareGuideSection(
      id: (json['id'] as num?)?.toInt(),
      type: (json['type'] as String?)?.trim() ?? 'general',
      description: (json['description'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'type': type,
        'description': description,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerenualCareGuideSection &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          description == other.description;

  @override
  int get hashCode => type.hashCode ^ description.hashCode;

  @override
  String toString() => 'PerenualCareGuideSection(type: $type, description: $description)';
}

/// DTO representing a plant care guide returned from `/species-care-guide-list`.
@immutable
class PerenualCareGuideModel {
  final int id;
  final int speciesId;
  final String commonName;
  final List<String> scientificName;
  final List<PerenualCareGuideSection> sections;

  const PerenualCareGuideModel({
    required this.id,
    required this.speciesId,
    required this.commonName,
    this.scientificName = const [],
    this.sections = const [],
  });

  factory PerenualCareGuideModel.fromJson(Map<String, dynamic> json) {
    final rawSci = json['scientific_name'];
    final List<String> sciNames = switch (rawSci) {
      List list => list.map((e) => e.toString()).toList(),
      String s when s.isNotEmpty => [s],
      _ => const [],
    };

    final rawSections = json['section'] ?? json['sections'];
    final List<PerenualCareGuideSection> sectionList = switch (rawSections) {
      List list => list
          .whereType<Map<String, dynamic>>()
          .map((item) => PerenualCareGuideSection.fromJson(item))
          .toList(),
      _ => const [],
    };

    return PerenualCareGuideModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      speciesId: (json['species_id'] as num?)?.toInt() ?? 0,
      commonName: (json['common_name'] as String?)?.trim() ?? '',
      scientificName: sciNames,
      sections: sectionList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'species_id': speciesId,
        'common_name': commonName,
        'scientific_name': scientificName,
        'section': sections.map((s) => s.toJson()).toList(),
      };

  String? get wateringAdvice {
    try {
      return sections
          .firstWhere((s) => s.type.toLowerCase().contains('water'))
          .description;
    } catch (_) {
      return null;
    }
  }

  String? get sunlightAdvice {
    try {
      return sections
          .firstWhere((s) => s.type.toLowerCase().contains('sun'))
          .description;
    } catch (_) {
      return null;
    }
  }

  String? get pruningAdvice {
    try {
      return sections
          .firstWhere((s) => s.type.toLowerCase().contains('prun'))
          .description;
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerenualCareGuideModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          speciesId == other.speciesId;

  @override
  int get hashCode => id.hashCode ^ speciesId.hashCode;

  @override
  String toString() =>
      'PerenualCareGuideModel(id: $id, speciesId: $speciesId, commonName: $commonName, sections: ${sections.length})';
}
