class Challenge {
  final String code;
  final String name;
  final int level;
  final List<TrackHabit> habits;

  Challenge({
    required this.code,
    required this.name,
    required this.level,
    required this.habits,
  });

  @override
  String toString() =>
      'Challenge(code: $code, name: $name, level: $level, habits: $habits)';
}

class TrackHabit {
  final String habitId;
  final int frequency;

  TrackHabit({
    required this.habitId,
    required this.frequency,
  });

  @override
  String toString() => 'TrackHabit(habitId: $habitId, frequency: $frequency)';
}

class Track {
  final String dimension;
  final String code;
  final String name;
  final List<Challenge> challenges;

  Track({
    required this.dimension,
    required this.code,
    required this.name,
    required this.challenges,
  });

  factory Track.fromCsvRows(List<List<dynamic>> rows) {
    if (rows.isEmpty) {
      return Track(
        dimension: '',
        code: '',
        name: '',
        challenges: [],
      );
    }

    final firstRow = rows.first;
    final dimension = firstRow[0].toString();
    final code = firstRow[1].toString();
    final name = firstRow[2].toString();

    // Group rows by challenge code
    final challengeGroups = <String, List<List<dynamic>>>{};
    for (final row in rows) {
      final challengeCode = row[3].toString();
      challengeGroups.putIfAbsent(challengeCode, () => []).add(row);
    }

    // Create challenges
    final challenges = challengeGroups.entries.map((entry) {
      final challengeRows = entry.value;
      final firstChallengeRow = challengeRows.first;

      // Create habits for this challenge
      final habits = challengeRows.map((row) {
        return TrackHabit(
          habitId: row[6].toString(),
          frequency: int.tryParse(row[7].toString()) ?? 0,
        );
      }).toList();

      return Challenge(
        code: firstChallengeRow[3].toString(),
        name: firstChallengeRow[4].toString(),
        level: int.tryParse(firstChallengeRow[5].toString()) ?? 1,
        habits: habits,
      );
    }).toList();

    return Track(
      dimension: dimension,
      code: code,
      name: name,
      challenges: challenges,
    );
  }

  Challenge? getChallengeByCode(String code) {
    try {
      return challenges.firstWhere((c) => c.code == code);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() =>
      'Track(dimension: $dimension, code: $code, name: $name, challenges: $challenges)';
}
