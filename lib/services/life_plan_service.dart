import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/life_plan/index.dart';
import '../utils/logger.dart';

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
  final _logger = Logger();

  // Getters for the models
  List<Goal> get goals => List.unmodifiable(_goals);
  List<Habit> get habits => List.unmodifiable(_habits);
  Map<String, Track> get tracks => Map.unmodifiable(_tracks);

  // Method to enable or disable logging
  void setLogging(bool enable) {
    _logger.setLogging(enable);
  }

  // Method to enable or disable startup logging specifically
  void setStartupLogging(bool enable) {
    _logger.setStartupLogging(enable);
  }

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
      _logger.error('Failed to initialize LifePlanService: $e');
      throw Exception('Failed to initialize LifePlanService: $e');
    }
  }

  Future<void> _loadGoals() async {
    try {
      final data = await rootBundle.loadString('assets/data/Objetivos.csv');
      _logger.logStartup('Goals data loaded successfully');

      // Configure CSV parser
      const parser = CsvToListConverter(
        fieldDelimiter: ';',
        eol: '\n',
        shouldParseNumbers: false,
      );

      final rows = parser.convert(data);
      _logger.logStartup('Parsed ${rows.length} rows from goals data');

      if (rows.isEmpty) {
        _logger.warning('No rows parsed from goals data');
        return;
      }

      // Skip header row and convert remaining rows
      final dataRows = rows.skip(1).toList();
      _logger.logStartup('Processing ${dataRows.length} data rows');

      _goals = dataRows.map((row) => Goal.fromCsv(row)).toList();
      _logger.logStartup('Goals created: ${_goals.length}');
    } catch (e) {
      _logger.error('Error loading goals: $e');
      rethrow;
    }
  }

  Future<void> _loadHabits() async {
    try {
      final data = await rootBundle.loadString('assets/data/habitos.csv');
      _logger.logStartup('Habits data loaded successfully');

      // Configure CSV parser
      const parser = CsvToListConverter(
        fieldDelimiter: ';',
        eol: '\n',
        shouldParseNumbers: false,
      );

      final rows = parser.convert(data);
      _logger.logStartup('Parsed ${rows.length} rows from habits data');

      if (rows.isEmpty) {
        _logger.warning('No rows parsed from habits data');
        return;
      }

      // Skip header row and convert remaining rows
      final dataRows = rows.skip(1).toList();
      _logger.logStartup('Processing ${dataRows.length} data rows');

      _habits = dataRows.map((row) => Habit.fromCsv(row)).toList();
      _logger.logStartup('Habits created: ${_habits.length}');
    } catch (e) {
      _logger.error('Error loading habits: $e');
      rethrow;
    }
  }

  Future<void> _loadTracks() async {
    try {
      final data = await rootBundle.loadString('assets/data/Trilhas.csv');
      _logger.logStartup('Tracks data loaded successfully');

      // Configure CSV parser
      const parser = CsvToListConverter(
        fieldDelimiter: ';',
        eol: '\n',
        shouldParseNumbers: false,
      );

      final rows = parser.convert(data);
      _logger.logStartup('Parsed ${rows.length} rows from tracks data');

      if (rows.isEmpty) {
        _logger.warning('No rows parsed from tracks data');
        return;
      }

      // Skip header row and convert remaining rows
      final dataRows = rows.skip(1).toList();
      _logger.logStartup('Processing ${dataRows.length} data rows');

      // Group rows by track code
      final trackGroups = <String, List<List<dynamic>>>{};
      for (final row in dataRows) {
        final trackCode =
            row[1].toString(); // Track code is in the second column
        trackGroups.putIfAbsent(trackCode, () => []).add(row);
      }
      _logger.logStartup('Track groups created: ${trackGroups.length}');

      // Create Track objects
      _tracks = trackGroups.map((code, rows) {
        return MapEntry(code, Track.fromCsvRows(rows));
      });
      _logger.logStartup('Tracks created: ${_tracks.length}');
    } catch (e) {
      _logger.error('Error loading tracks: $e');
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
