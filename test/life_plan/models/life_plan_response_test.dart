import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/life_plan/models/life_plan_response.dart';

void main() {
  group('LifePlanResponse', () {
    group('Error Response Tests', () {
      test('creates error response with correct formatting', () {
        final response = LifePlanResponse.error('Test error message');

        expect(response.isError, isTrue);
        expect(response.message, equals('Test error message'));
      });
    });

    group('Welcome Response Tests', () {
      test('creates welcome response with all options', () {
        final response = LifePlanResponse.welcome();

        expect(response.isError, isFalse);
        expect(response.message, contains('Olá! Sou seu assistente pessoal'));
        expect(response.message, contains('a. Objetivo Definido'));
        expect(response.message, contains('b. Rotina Personalizada'));
        expect(response.message, contains('c. Explorar Catálogo'));
        expect(response.message, contains('d. Transformar Hábitos'));
      });
    });

    group('Objective Based Flow Tests', () {
      test('creates objective based flow initial response', () {
        final response = LifePlanResponse.objectiveBased();

        expect(response.isError, isFalse);
        expect(response.message, contains('Qual é seu objetivo específico?'));
      });
    });

    group('Custom Routine Flow Tests', () {
      test('creates custom routine flow initial response', () {
        final response = LifePlanResponse.customRoutine();

        expect(response.isError, isFalse);
        expect(response.message,
            contains('Quais dimensões da vida você quer priorizar?'));
        expect(response.message, contains('Saúde Física'));
        expect(response.message, contains('Saúde Mental'));
        expect(response.message, contains('Relacionamentos'));
        expect(response.message, contains('Trabalho'));
        expect(response.message, contains('Espiritualidade'));
      });
    });

    group('Explore Catalog Flow Tests', () {
      test('creates explore catalog flow initial response', () {
        final response = LifePlanResponse.exploreCatalog();

        expect(response.isError, isFalse);
        expect(response.message, contains('Nosso catálogo de desafios'));
        expect(response.message, contains('1. Saúde Física (SF)'));
        expect(response.message, contains('2. Saúde Mental (SM)'));
        expect(response.message, contains('3. Relacionamentos (R)'));
        expect(response.message, contains('4. Espiritualidade (E)'));
        expect(response.message, contains('5. Trabalho Gratificante (TG)'));
      });
    });

    group('Transform Habits Flow Tests', () {
      test('creates transform habits flow initial response', () {
        final response = LifePlanResponse.transformHabits();

        expect(response.isError, isFalse);
        expect(response.message,
            contains('Qual hábito negativo você gostaria de transformar'));
      });
    });

    group('Assess Level Tests', () {
      test('creates assess level response', () {
        final response = LifePlanResponse.assessLevel('Saúde Física');

        expect(response.isError, isFalse);
        expect(response.message,
            contains('Você já tem experiência com hábitos nesta área?'));
        expect(response.message, contains('Iniciante'));
        expect(response.message, contains('Intermediário'));
        expect(response.message, contains('Avançado'));
      });
    });

    group('Suggest Track Tests', () {
      test('creates suggest track response', () {
        final response = LifePlanResponse.suggestTrack(
            'Mapa do Emagrecimento', 'Uma trilha para perda de peso saudável');

        expect(response.isError, isFalse);
        expect(response.message,
            contains('Baseado no seu objetivo e nível de experiência'));
        expect(response.message, contains('Mapa do Emagrecimento'));
        expect(response.message,
            contains('Uma trilha para perda de peso saudável'));
      });
    });

    group('Challenge Customization Tests', () {
      test('creates challenge customization response', () {
        final response = LifePlanResponse.challengeCustomization();

        expect(response.isError, isFalse);
        expect(response.message,
            contains('Como você gostaria de personalizar este desafio?'));
        expect(response.message, contains('Frequência dos hábitos'));
        expect(response.message, contains('Intensidade do desafio'));
        expect(response.message, contains('Adicionar/remover hábitos'));
      });
    });

    group('Help Response Tests', () {
      test('creates help response with all options', () {
        final response = LifePlanResponse.help();

        expect(response.isError, isFalse);
        expect(response.message, contains('Como posso ajudar você hoje?'));
        expect(response.message, contains('a. Objetivo Definido'));
        expect(response.message, contains('b. Rotina Personalizada'));
        expect(response.message, contains('c. Explorar Catálogo'));
        expect(response.message, contains('d. Transformar Hábitos'));
      });
    });

    group('Unknown Command Response Tests', () {
      test('creates unknown command response', () {
        final response = LifePlanResponse.unknown();

        expect(response.isError, isTrue);
        expect(response.message, contains('Não entendi sua solicitação'));
        expect(
            response.message, contains('escolha uma das opções disponíveis'));
      });
    });

    group('Response Immutability Tests', () {
      test('response objects preserve their values', () {
        const response = LifePlanResponse(message: 'Test', isError: false);

        expect(response.message, equals('Test'));
        expect(response.isError, isFalse);

        // Verify that we can't modify the values
        expect(() {
          // ignore: invalid_use_of_protected_member
          (response as dynamic).message = 'New message';
        }, throwsNoSuchMethodError);

        expect(() {
          // ignore: invalid_use_of_protected_member
          (response as dynamic).isError = true;
        }, throwsNoSuchMethodError);
      });
    });
  });
}
