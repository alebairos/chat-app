import 'package:flutter/foundation.dart';

/// Represents a formatted response from the life plan system
@immutable
class LifePlanResponse {
  final String message;
  final bool isError;

  const LifePlanResponse({
    required this.message,
    this.isError = false,
  });

  /// Creates an error response
  factory LifePlanResponse.error(String message) {
    return LifePlanResponse(
      message: message,
      isError: true,
    );
  }

  /// Creates the welcome message with options
  factory LifePlanResponse.welcome() {
    final buffer = StringBuffer()
      ..writeln(
          'Olá! Sou seu assistente pessoal de desenvolvimento e estou aqui para ajudar você a criar novos hábitos positivos e alcançar seus objetivos.')
      ..writeln(
          'Durante nossa conversa, você pode pedir mais informações sobre qualquer trilha, desafio ou hábito mencionado.')
      ..writeln('Como posso ajudar você hoje?')
      ..writeln()
      ..writeln(
          'a. Objetivo Definido - Encontrar um desafio ideal baseado em seu objetivo específico')
      ..writeln(
          'b. Rotina Personalizada - Criar uma rotina personalizada do zero')
      ..writeln('c. Explorar Catálogo - Explorar nosso catálogo de desafios')
      ..writeln(
          'd. Transformar Hábitos - Transformar hábitos negativos em positivos');

    return LifePlanResponse(message: buffer.toString());
  }

  /// Creates the objective-based flow initial response
  factory LifePlanResponse.objectiveBased() {
    return const LifePlanResponse(
      message: 'Qual é seu objetivo específico?',
    );
  }

  /// Creates the custom routine flow initial response
  factory LifePlanResponse.customRoutine() {
    final buffer = StringBuffer()
      ..writeln('Quais dimensões da vida você quer priorizar?')
      ..writeln()
      ..writeln('Você pode escolher até 3 opções:')
      ..writeln('- Saúde Física')
      ..writeln('- Saúde Mental')
      ..writeln('- Relacionamentos')
      ..writeln('- Trabalho')
      ..writeln('- Espiritualidade');

    return LifePlanResponse(message: buffer.toString());
  }

  /// Creates the catalog exploration flow initial response
  factory LifePlanResponse.exploreCatalog() {
    final buffer = StringBuffer()
      ..writeln(
          'Nosso catálogo de desafios está organizado por dimensões da vida:')
      ..writeln()
      ..writeln('1. Saúde Física (SF)')
      ..writeln('2. Saúde Mental (SM)')
      ..writeln('3. Relacionamentos (R)')
      ..writeln('4. Espiritualidade (E)')
      ..writeln('5. Trabalho Gratificante (TG)')
      ..writeln()
      ..writeln('Qual dimensão você gostaria de explorar?');

    return LifePlanResponse(message: buffer.toString());
  }

  /// Creates the habit transformation flow initial response
  factory LifePlanResponse.transformHabits() {
    return const LifePlanResponse(
      message: 'Qual hábito negativo você gostaria de transformar em positivo?',
    );
  }

  /// Creates a response for assessing experience level
  factory LifePlanResponse.assessLevel(String dimension) {
    return const LifePlanResponse(
      message: 'Você já tem experiência com hábitos nesta área?\n\n'
          '- Iniciante - Estou começando agora\n'
          '- Intermediário - Já tenho alguns hábitos\n'
          '- Avançado - Busco desafios maiores',
    );
  }

  /// Creates a response for suggesting a track
  factory LifePlanResponse.suggestTrack(
      String trackName, String trackDescription) {
    return LifePlanResponse(
      message:
          'Baseado no seu objetivo e nível de experiência, recomendo a trilha: '
          '$trackName\n\n$trackDescription\n\n'
          'Gostaria de seguir com este desafio ou personalizar algum aspecto?',
    );
  }

  /// Creates a response for challenge customization options
  factory LifePlanResponse.challengeCustomization() {
    return const LifePlanResponse(
      message: 'Como você gostaria de personalizar este desafio?\n\n'
          '- Frequência dos hábitos\n'
          '- Intensidade do desafio\n'
          '- Adicionar/remover hábitos',
    );
  }

  /// Creates a help response with all available options
  factory LifePlanResponse.help() {
    final buffer = StringBuffer()
      ..writeln('Como posso ajudar você hoje?')
      ..writeln()
      ..writeln(
          'a. Objetivo Definido - Encontrar um desafio ideal baseado em seu objetivo específico')
      ..writeln(
          'b. Rotina Personalizada - Criar uma rotina personalizada do zero')
      ..writeln('c. Explorar Catálogo - Explorar nosso catálogo de desafios')
      ..writeln(
          'd. Transformar Hábitos - Transformar hábitos negativos em positivos');

    return LifePlanResponse(message: buffer.toString());
  }

  /// Creates an unknown command response
  factory LifePlanResponse.unknown() {
    return LifePlanResponse.error(
      'Não entendi sua solicitação. Por favor, escolha uma das opções disponíveis ou digite "ajuda" para ver as opções.',
    );
  }
}
