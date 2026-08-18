import 'package:flutter/foundation.dart';
import 'package:plenty/data/models/perenual_species_model.dart';

/// DTO representing the paginated envelope returned by Perenual `/species-list`.
@immutable
class PerenualSpeciesListResponse {
  final List<PerenualSpeciesModel> data;
  final int total;
  final int perPage;
  final int currentPage;
  final int? lastPage;
  final int? from;
  final int? to;

  const PerenualSpeciesListResponse({
    required this.data,
    this.total = 0,
    this.perPage = 30,
    this.currentPage = 1,
    this.lastPage,
    this.from,
    this.to,
  });

  factory PerenualSpeciesListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final List<PerenualSpeciesModel> speciesList = switch (rawData) {
      List list => list
          .whereType<Map<String, dynamic>>()
          .map((item) => PerenualSpeciesModel.fromJson(item))
          .toList(),
      _ => const [],
    };

    return PerenualSpeciesListResponse(
      data: speciesList,
      total: (json['total'] as num?)?.toInt() ?? speciesList.length,
      perPage: (json['per_page'] as num?)?.toInt() ?? 30,
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt(),
      from: (json['from'] as num?)?.toInt(),
      to: (json['to'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'data': data.map((item) => item.toJson()).toList(),
        'total': total,
        'per_page': perPage,
        'current_page': currentPage,
        'last_page': lastPage,
        'from': from,
        'to': to,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerenualSpeciesListResponse &&
          runtimeType == other.runtimeType &&
          total == other.total &&
          currentPage == other.currentPage &&
          listEquals(data, other.data);

  @override
  int get hashCode =>
      total.hashCode ^
      currentPage.hashCode ^
      Object.hashAll(data);

  @override
  String toString() =>
      'PerenualSpeciesListResponse(page: $currentPage/$lastPage, count: ${data.length}, total: $total)';
}
