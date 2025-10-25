import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/utils/mcp_pattern_detector.dart';

void main() {
  group('MCPPatternDetector', () {
    group('Category 1: Temporal Activity Queries', () {
      test('should detect "últimos 7 dias"', () {
        final hint =
            MCPPatternDetector.detectPattern('Me da um resumo dos últimos 7 dias');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
        expect(hint, contains('"days": 7'));
      });

      test('should detect "última semana"', () {
        final hint = MCPPatternDetector.detectPattern('Como foi minha última semana?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
        expect(hint, contains('"days": 7'));
      });

      test('should detect "último mês"', () {
        final hint = MCPPatternDetector.detectPattern('Resumo do último mês');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
        expect(hint, contains('"days": 30'));
      });

      test('should detect "hoje"', () {
        final hint = MCPPatternDetector.detectPattern('O que eu fiz hoje?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
        expect(hint, contains('"days": 0'));
      });

      test('should detect "ontem"', () {
        final hint = MCPPatternDetector.detectPattern('Minhas atividades ontem');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
        expect(hint, contains('"days": 1'));
      });

      test('should detect English "last 7 days"', () {
        final hint =
            MCPPatternDetector.detectPattern('Give me a summary of the last 7 days');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
        expect(hint, contains('"days": 7'));
      });

      test('should detect English "last week"', () {
        final hint = MCPPatternDetector.detectPattern('How was my last week?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
        expect(hint, contains('"days": 7'));
      });
    });

    group('Category 2: Quantitative Queries', () {
      test('should detect "quantas atividades"', () {
        final hint =
            MCPPatternDetector.detectPattern('Quantas atividades fiz essa semana?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
      });

      test('should detect "o que eu fiz"', () {
        final hint = MCPPatternDetector.detectPattern('O que eu fiz ontem?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
      });

      test('should detect "quantas vezes"', () {
        final hint =
            MCPPatternDetector.detectPattern('Quantas vezes meditei esse mês?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
      });

      test('should detect English "how many activities"', () {
        final hint =
            MCPPatternDetector.detectPattern('How many activities did I do this week?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
      });

      test('should detect English "what did I do"', () {
        final hint = MCPPatternDetector.detectPattern('What did I do yesterday?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
      });
    });

    group('Category 3: Progress & Trend Queries', () {
      test('should detect "meu progresso"', () {
        final hint = MCPPatternDetector.detectPattern('Como está meu progresso?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
        expect(hint, contains('"days": 30'));
      });

      test('should detect "evolução"', () {
        final hint =
            MCPPatternDetector.detectPattern('Qual a evolução dos meus exercícios?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
      });

      test('should detect "melhorei"', () {
        final hint =
            MCPPatternDetector.detectPattern('Melhorei em relação à semana passada?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
      });

      test('should detect "tendência"', () {
        final hint =
            MCPPatternDetector.detectPattern('Qual a tendência dos meus hábitos?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
      });

      test('should detect English "my progress"', () {
        final hint = MCPPatternDetector.detectPattern('How is my progress?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
      });
    });

    group('Category 4: Conversation Context Queries', () {
      test('should detect "o que a gente falou"', () {
        final hint =
            MCPPatternDetector.detectPattern('O que a gente falou sobre exercícios?');
        expect(hint, isNotNull);
        expect(hint, contains('search_conversation_context'));
      });

      test('should detect "lembra quando"', () {
        final hint =
            MCPPatternDetector.detectPattern('Lembra quando eu mencionei meu objetivo?');
        expect(hint, isNotNull);
        expect(hint, contains('get_conversation_context'));
      });

      test('should detect "você disse"', () {
        final hint =
            MCPPatternDetector.detectPattern('Você disse algo sobre dormir cedo');
        expect(hint, isNotNull);
        // Note: "sobre" triggers search_conversation_context (more specific)
        expect(hint, contains('search_conversation_context'));
      });

      test('should detect "busca na conversa"', () {
        final hint =
            MCPPatternDetector.detectPattern('Busca na conversa sobre meditação');
        expect(hint, isNotNull);
        expect(hint, contains('search_conversation_context'));
      });

      test('should detect English "what did we talk about"', () {
        final hint =
            MCPPatternDetector.detectPattern('What did we talk about yesterday?');
        expect(hint, isNotNull);
        // Note: "yesterday" triggers temporal pattern (higher priority)
        expect(hint, contains('get_activity_stats'));
      });

      test('should detect English "remember when"', () {
        final hint = MCPPatternDetector.detectPattern('Remember when I said that?');
        expect(hint, isNotNull);
        expect(hint, contains('get_conversation_context'));
      });
    });

    group('Category 5: Persona Switching Context', () {
      test('should detect "@ari"', () {
        final hint =
            MCPPatternDetector.detectPattern('@ari o dia hoje foi uma saga');
        expect(hint, isNotNull);
        // Note: "hoje" triggers temporal pattern (higher priority)
        expect(hint, contains('get_activity_stats'));
      });

      test('should detect "conversei com"', () {
        final hint =
            MCPPatternDetector.detectPattern('Conversei com Tony sobre exercícios');
        expect(hint, isNotNull);
        expect(hint, contains('get_interleaved_conversation'));
      });

      test('should detect "olhe as conversas"', () {
        final hint =
            MCPPatternDetector.detectPattern('Olhe as conversas anteriores');
        expect(hint, isNotNull);
        expect(hint, contains('get_interleaved_conversation'));
      });

      test('should detect English "@tony"', () {
        final hint = MCPPatternDetector.detectPattern('@tony check the messages');
        expect(hint, isNotNull);
        expect(hint, contains('get_interleaved_conversation'));
      });
    });

    group('Category 6: Goal & Objective Queries', () {
      test('should detect "minha meta"', () {
        final hint =
            MCPPatternDetector.detectPattern('Estou perto de alcançar minha meta?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
        expect(hint, contains('search_conversation_context'));
      });

      test('should detect "quanto falta"', () {
        final hint =
            MCPPatternDetector.detectPattern('Quanto falta para completar meu objetivo?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
      });

      test('should detect "progresso da meta"', () {
        final hint =
            MCPPatternDetector.detectPattern('Qual o progresso da meta de exercícios?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
      });

      test('should detect English "my goal"', () {
        final hint = MCPPatternDetector.detectPattern('Am I close to my goal?');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
      });
    });

    group('Category 7: Repetition Prevention', () {
      test('should detect "já disse isso"', () {
        final hint = MCPPatternDetector.detectPattern('Você já disse isso');
        expect(hint, isNotNull);
        expect(hint, contains('get_current_persona_messages'));
      });

      test('should detect "repetindo"', () {
        final hint = MCPPatternDetector.detectPattern('Está repetindo');
        expect(hint, isNotNull);
        expect(hint, contains('get_current_persona_messages'));
      });

      test('should detect "de novo"', () {
        final hint = MCPPatternDetector.detectPattern('Mesma coisa de novo');
        expect(hint, isNotNull);
        expect(hint, contains('get_current_persona_messages'));
      });

      test('should detect English "already said"', () {
        final hint = MCPPatternDetector.detectPattern('You already said that');
        expect(hint, isNotNull);
        expect(hint, contains('get_current_persona_messages'));
      });
    });

    group('No Pattern Detection', () {
      test('should return null for normal conversation', () {
        final hint = MCPPatternDetector.detectPattern('Olá, como vai?');
        expect(hint, isNull);
      });

      test('should return null for simple statements', () {
        final hint = MCPPatternDetector.detectPattern('Estou bem, obrigado');
        expect(hint, isNull);
      });

      test('should return null for questions without temporal/quantitative context', () {
        final hint = MCPPatternDetector.detectPattern('Como você está?');
        expect(hint, isNull);
      });
    });

    group('Days Extraction', () {
      test('should extract specific number of days', () {
        final hint =
            MCPPatternDetector.detectPattern('Resumo dos últimos 14 dias');
        expect(hint, contains('"days": 14'));
      });

      test('should extract weeks and convert to days', () {
        final hint =
            MCPPatternDetector.detectPattern('Últimas 2 semanas');
        expect(hint, contains('"days": 14'));
      });

      test('should default to 7 days for "semana"', () {
        final hint = MCPPatternDetector.detectPattern('Essa semana');
        expect(hint, contains('"days": 7'));
      });

      test('should use 30 days for "mês"', () {
        final hint = MCPPatternDetector.detectPattern('Este mês');
        expect(hint, contains('"days": 30'));
      });

      test('should use 0 days for "hoje"', () {
        final hint = MCPPatternDetector.detectPattern('Hoje');
        expect(hint, contains('"days": 0'));
      });

      test('should use 1 day for "ontem"', () {
        final hint = MCPPatternDetector.detectPattern('Ontem');
        expect(hint, contains('"days": 1'));
      });
    });

    group('Edge Cases', () {
      test('should handle mixed case', () {
        final hint =
            MCPPatternDetector.detectPattern('Me Da Um RESUMO dos Últimos 7 DIAS');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
      });

      test('should handle extra whitespace', () {
        final hint =
            MCPPatternDetector.detectPattern('Resumo   dos   últimos   7   dias');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
      });

      test('should handle Portuguese and English mixed', () {
        final hint =
            MCPPatternDetector.detectPattern('Me da um summary dos últimos 7 days');
        expect(hint, isNotNull);
        expect(hint, contains('get_activity_stats'));
      });
    });
  });
}

