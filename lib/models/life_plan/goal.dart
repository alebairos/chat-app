import '../life_plan/dimensions.dart';

/// Provides dimension code constants
/// @deprecated Use Dimensions class instead
class LifeDimension {
  // Private constructor to prevent instantiation
  LifeDimension._();

  // Using string literals to avoid constant expression errors
  static const String physical = 'SF';
  static const String mental = 'SM';
  static const String relationships = 'R';
  static const String spiritual = 'E';
  static const String work = 'TG';
}

class Goal {
  final String dimension;
  final String id;
  final String description;
  final String trackId;

  Goal({
    required this.dimension,
    required this.id,
    required this.description,
    required this.trackId,
  });

  factory Goal.fromCsv(List<dynamic> row) {
    return Goal(
      dimension: row[0].toString(),
      id: row[1].toString(),
      description: row[2].toString(),
      trackId: row[3].toString(),
    );
  }

  @override
  String toString() =>
      'Goal(dimension: $dimension, id: $id, description: $description, trackId: $trackId)';

  bool matchesDimension(String dimensionCode) => dimension == dimensionCode;
}
