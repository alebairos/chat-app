import 'dart:convert';
import 'life_plan_service.dart';
import '../utils/logger.dart';

class LifePlanMCPService {
  final LifePlanService _lifePlanService;
  final _logger = Logger();

  LifePlanMCPService(this._lifePlanService);

  // Method to enable or disable logging
  void setLogging(bool enable) {
    _logger.setLogging(enable);
  }

  String processCommand(String command) {
    _logger.debug('Processing command: $command');

    try {
      final parsedCommand = json.decode(command);
      _logger.debug('Parsed command: $parsedCommand');

      final action = parsedCommand['action'] as String?;
      if (action == null) {
        _logger.warning('Missing action parameter');
        throw Exception('Missing required parameter: action');
      }
      _logger.debug('Action: $action');

      switch (action) {
        case 'get_goals_by_dimension':
          final dimension = parsedCommand['dimension'] as String?;
          if (dimension == null) {
            _logger.warning('Missing dimension parameter');
            throw Exception('Missing required parameter: dimension');
          }
          _logger.info('Getting goals for dimension: $dimension');

          final goals = _lifePlanService.getGoalsByDimension(dimension);
          _logger.info('Found ${goals.length} goals');

          return json.encode({
            'status': 'success',
            'data': goals
                .map((g) => {
                      'dimension': g.dimension,
                      'id': g.id,
                      'description': g.description,
                      'trackId': g.trackId,
                    })
                .toList(),
          });

        case 'get_track_by_id':
          final trackId = parsedCommand['trackId'] as String?;
          if (trackId == null) {
            _logger.warning('Missing trackId parameter');
            throw Exception('Missing required parameter: trackId');
          }
          _logger.info('Getting track with ID: $trackId');

          final track = _lifePlanService.getTrackById(trackId);
          if (track == null) {
            _logger.warning('Track not found');
            return json.encode({
              'status': 'error',
              'message': 'Track not found',
            });
          }
          _logger.info('Track found: ${track.name}');

          return json.encode({
            'status': 'success',
            'data': {
              'dimension': track.dimension,
              'code': track.code,
              'name': track.name,
              'challenges': track.challenges
                  .map((c) => {
                        'code': c.code,
                        'name': c.name,
                        'level': c.level,
                        'habits': c.habits
                            .map((h) => {
                                  'habitId': h.habitId,
                                  'frequency': h.frequency,
                                })
                            .toList(),
                      })
                  .toList(),
            },
          });

        case 'get_habits_for_challenge':
          final trackId = parsedCommand['trackId'] as String?;
          final challengeCode = parsedCommand['challengeCode'] as String?;

          if (trackId == null) {
            _logger.warning('Missing trackId parameter');
            throw Exception('Missing required parameter: trackId');
          }
          if (challengeCode == null) {
            _logger.warning('Missing challengeCode parameter');
            throw Exception('Missing required parameter: challengeCode');
          }

          _logger.info(
              'Getting habits for track: $trackId, challenge: $challengeCode');
          final habits = _lifePlanService.getHabitsForChallenge(
            trackId,
            challengeCode,
          );
          _logger.info('Found ${habits.length} habits');

          return json.encode({
            'status': 'success',
            'data': habits
                .map((h) => {
                      'id': h.id,
                      'description': h.description,
                      'intensity': h.intensity,
                      'duration': h.duration,
                      'impact': {
                        'relationships': h.impact.relationships,
                        'work': h.impact.work,
                        'physical': h.impact.physical,
                        'spiritual': h.impact.spiritual,
                        'mental': h.impact.mental,
                      },
                    })
                .toList(),
          });

        case 'get_recommended_habits':
          final dimension = parsedCommand['dimension'] as String?;
          if (dimension == null) {
            _logger.warning('Missing dimension parameter');
            throw Exception('Missing required parameter: dimension');
          }
          _logger.info('Getting recommended habits for dimension: $dimension');

          final minImpact = parsedCommand['minImpact'] as int? ?? 3;
          _logger.info('Minimum impact threshold: $minImpact');

          final habits = _lifePlanService.getRecommendedHabits(
            dimension,
            minImpact: minImpact,
          );
          _logger.info('Found ${habits.length} recommended habits');

          return json.encode({
            'status': 'success',
            'data': habits
                .map((h) => {
                      'id': h.id,
                      'description': h.description,
                      'intensity': h.intensity,
                      'duration': h.duration,
                      'impact': {
                        'relationships': h.impact.relationships,
                        'work': h.impact.work,
                        'physical': h.impact.physical,
                        'spiritual': h.impact.spiritual,
                        'mental': h.impact.mental,
                      },
                    })
                .toList(),
          });

        default:
          _logger.warning('Unknown command: $action');
          return json.encode({
            'status': 'error',
            'message': 'Unknown action: $action',
          });
      }
    } catch (e) {
      _logger.error('Error processing command: $e');
      return json.encode({
        'status': 'error',
        'message': e.toString(),
      });
    }
  }
}
