import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/life_plan/index.dart';

class LifePlanService {
  // Singleton instance
  static final LifePlanService _instance = LifePlanService._internal();
  factory LifePlanService() => _instance;
  LifePlanService._internal();

  // In-memory storage
  List<Goal> _goals = [];
  List<Habit> _habits = [];
  Map<String, Track> _tracks = {}; // Indexed by track code

  bool _isInitialized = false;

  // Getters for the models
  List<Goal> get goals => List.unmodifiable(_goals);
  List<Habit> get habits => List.unmodifiable(_habits);
  Map<String, Track> get tracks => Map.unmodifiable(_tracks);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load all data
      await Future.wait([
        _loadGoals(),
        _loadHabits(),
        _loadTracks(),
      ]);

      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize LifePlanService: $e'); // Debug log
      throw Exception('Failed to initialize LifePlanService: $e');
    }
  }

  Future<void> _loadGoals() async {
    try {
      final data = await rootBundle.loadString('assets/data/Objetivos.csv');
      print('Goals data loaded: $data'); // Debug log

      // Configure CSV parser
      final parser = CsvToListConverter(
        fieldDelimiter: ';',
        eol: '\n',
        shouldParseNumbers: false,
      );

      final rows = parser.convert(data);
      print('All rows: $rows'); // Debug log

      if (rows.isEmpty) {
        print('No rows parsed from goals data'); // Debug log
        return;
      }

      // Skip header row and convert remaining rows
      final dataRows = rows.skip(1).toList();
      print('Data rows: $dataRows'); // Debug log

      _goals = dataRows.map((row) => Goal.fromCsv(row)).toList();
      print('Goals created: ${_goals.length}'); // Debug log
    } catch (e) {
      print('Error loading goals: $e'); // Debug log
      rethrow;
    }
  }

  Future<void> _loadHabits() async {
    try {
      final data = await rootBundle.loadString('assets/data/habitos.csv');
      print('Habits data loaded: $data'); // Debug log

      // Configure CSV parser
      final parser = CsvToListConverter(
        fieldDelimiter: ';',
        eol: '\n',
        shouldParseNumbers: false,
      );

      final rows = parser.convert(data);
      print('All rows: $rows'); // Debug log

      if (rows.isEmpty) {
        print('No rows parsed from habits data'); // Debug log
        return;
      }

      // Skip header row and convert remaining rows
      final dataRows = rows.skip(1).toList();
      print('Data rows: $dataRows'); // Debug log

      _habits = dataRows.map((row) => Habit.fromCsv(row)).toList();
      print('Habits created: ${_habits.length}'); // Debug log
    } catch (e) {
      print('Error loading habits: $e'); // Debug log
      rethrow;
    }
  }

  Future<void> _loadTracks() async {
    try {
      final data = await rootBundle.loadString('assets/data/Trilhas.csv');
      print('Tracks data loaded: $data'); // Debug log

      // Configure CSV parser
      final parser = CsvToListConverter(
        fieldDelimiter: ';',
        eol: '\n',
        shouldParseNumbers: false,
      );

      final rows = parser.convert(data);
      print('All rows: $rows'); // Debug log

      if (rows.isEmpty) {
        print('No rows parsed from tracks data'); // Debug log
        return;
      }

      // Skip header row and convert remaining rows
      final dataRows = rows.skip(1).toList();
      print('Data rows: $dataRows'); // Debug log

      // Group rows by track code
      final trackGroups = <String, List<List<dynamic>>>{};
      for (final row in dataRows) {
        final trackCode =
            row[1].toString(); // Track code is in the second column
        trackGroups.putIfAbsent(trackCode, () => []).add(row);
      }
      print('Track groups created: ${trackGroups.length}'); // Debug log

      // Create Track objects
      _tracks = trackGroups.map((code, rows) {
        return MapEntry(code, Track.fromCsvRows(rows));
      });
      print('Tracks created: ${_tracks.length}'); // Debug log
    } catch (e) {
      print('Error loading tracks: $e'); // Debug log
      rethrow;
    }
  }

  // Query methods
  List<Goal> getGoalsByDimension(String dimension) {
    return _goals.where((goal) => goal.dimension == dimension).toList();
  }

  Habit? getHabitById(String habitId) {
    try {
      return _habits.firstWhere((habit) => habit.id == habitId);
    } catch (e) {
      return null;
    }
  }

  String _cleanId(String id) {
    return id.trim().replaceAll('\r', '');
  }

  Track? getTrackById(String trackId) {
    final cleanId = _cleanId(trackId);
    return _tracks[cleanId];
  }

  List<Habit> getHabitsByIds(List<String> habitIds) {
    return _habits.where((habit) => habitIds.contains(habit.id)).toList();
  }

  // Get all habits for a specific track and challenge
  List<Habit> getHabitsForChallenge(String trackId, String challengeCode) {
    final track = _tracks[trackId];
    if (track == null) return [];

    final challenge = track.getChallengeByCode(challengeCode);
    if (challenge == null) return [];

    return getHabitsByIds(challenge.habits.map((h) => h.habitId).toList());
  }

  // Get recommended habits based on dimension and impact threshold
  List<Habit> getRecommendedHabits(String dimension, {int minImpact = 3}) {
    return _habits
        .where((habit) => habit.getImpactForDimension(dimension) >= minImpact)
        .toList();
  }
}
