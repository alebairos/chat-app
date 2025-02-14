class LifeDimension {
  static const String physical = 'SF'; // Saúde Física
  static const String mental = 'SM'; // Saúde Mental
  static const String relationships = 'R'; // Relacionamentos
  static const String work = 'T'; // Trabalho
  static const String spiritual = 'E'; // Espiritualidade
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
