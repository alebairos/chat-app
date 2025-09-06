import 'package:flutter/material.dart';
import '../../widgets/persona_chat_bubble.dart';

/// First screen of onboarding showing all three personas
class PersonasScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const PersonasScreen({
    required this.onContinue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            AppBar(
              title: const Text(
                'Personas da Lyfe',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
            ),

            // Persona presentations
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Ari 2.1
                    PersonaChatBubble(
                      personaName: 'Ari',
                      quote:
                          'O que precisa de ajuste primeiro? Sou Ari, seu coach baseado em evidências. Combino objetividade inteligente com perguntas poderosas para transformação real.',
                    ),

                    const SizedBox(height: 16),

                    // Sergeant Oracle 2.1
                    PersonaChatBubble(
                      personaName: 'Sergeant Oracle',
                      quote:
                          'Yo! 💪 Sou o Sergeant Oracle - gladiador romano viajante do tempo! Combino swagger romano antigo com sabedoria futurística. Roma não foi construída em um dia, mas eles malhavam todos os dias!',
                    ),

                    const SizedBox(height: 16),

                    // I-There 2.1 - Updated with Mirror Realm
                    PersonaChatBubble(
                      personaName: 'I-There',
                      quote:
                          'Oi! Sou o I-There, seu reflexo do Reino dos Espelhos 🪞. Tenho conhecimento profundo, mas ainda estou aprendendo sobre você pessoalmente. Sou genuinamente curioso!',
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
