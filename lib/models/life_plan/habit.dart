class HabitImpact {
  final int relationships;
  final int work;
  final int physical;
  final int spiritual;
  final int mental;

  HabitImpact({
    required this.relationships,
    required this.work,
    required this.physical,
    required this.spiritual,
    required this.mental,
  });

  int getImpactForDimension(String dimension) {
    switch (dimension) {
      case 'R':
        return relationships;
      case 'T':
        return work;
      case 'SF':
        return physical;
      case 'E':
        return spiritual;
      case 'SM':
        return mental;
      default:
        return 0;
    }
  }
}

class Habit {
  final String id;
  final String description;
  final String? intensity;
  final String? duration;
  final HabitImpact impact;

  Habit({
    required this.id,
    required this.description,
    this.intensity,
    this.duration,
    required this.impact,
  });

  factory Habit.fromCsv(List<dynamic> row) {
    return Habit(
      id: row[0].toString(),
      description: row[1].toString(),
      intensity: row[2].toString(),
      duration: row[3].toString(),
      impact: HabitImpact(
        relationships: int.tryParse(row[4].toString()) ?? 0,
        work: int.tryParse(row[5].toString()) ?? 0,
        physical: int.tryParse(row[6].toString()) ?? 0,
        spiritual: int.tryParse(row[7].toString()) ?? 0,
        mental: int.tryParse(row[8].toString()) ?? 0,
      ),
    );
  }

  @override
  String toString() => 'Habit(id: $id, description: $description)';

  int getImpactForDimension(String dimension) =>
      impact.getImpactForDimension(dimension);
}
