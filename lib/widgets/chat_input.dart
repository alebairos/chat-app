import 'package:flutter/material.dart';
import 'audio_recorder.dart';
import '../controllers/persona_mention_controller.dart';
import '../models/persona_option.dart';
import '../config/config_loader.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String path, Duration duration) onSendAudio;
  final VoidCallback? onPersonaChanged; // FT-208: Add callback

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onSendAudio,
    this.onPersonaChanged, // FT-208: Add parameter
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final PersonaMentionController _mentionController =
      PersonaMentionController();
  final ConfigLoader _configLoader = ConfigLoader();
  List<PersonaOption> _filteredPersonas = [];
  bool _showAutocomplete = false;

  @override
  void initState() {
    super.initState();
    _initializeMentionController();
  }

  Future<void> _initializeMentionController() async {
    // Initialize the mention controller
    await _mentionController.initialize();

    // Set up callbacks for persona filtering and selection
    _mentionController.onPersonasFiltered = (personas) {
      if (mounted) {
        setState(() {
          _filteredPersonas = personas;
          _showAutocomplete = personas.isNotEmpty;
        });
      }
    };

    _mentionController.onPersonaSelected = (personaKey) async {
      // Switch persona using existing infrastructure
      try {
        await _configLoader.setActivePersona(personaKey);
        print('FT-207: Switched to persona: $personaKey');

        // FT-208: Notify parent about persona change
        if (widget.onPersonaChanged != null) {
          print('FT-208: Calling onPersonaChanged callback');
          widget.onPersonaChanged!();
        }
      } catch (e) {
        print('FT-207: Error switching persona: $e');
      }
    };

    _mentionController.onTextReplaced = (newText, newCursorPosition) {
      if (mounted) {
        widget.controller.text = newText;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: newCursorPosition),
        );
      }
    };
  }

  void _onTextChanged(String text) {
    // Get current cursor position
    final cursorPosition = widget.controller.selection.baseOffset;

    // Process text change for mention detection
    _mentionController.onTextChanged(text, cursorPosition);
  }

  void _selectPersona(PersonaOption persona) {
    final currentText = widget.controller.text;
    final cursorPosition = widget.controller.selection.baseOffset;

    _mentionController.selectPersona(persona, currentText, cursorPosition);
  }

  @override
  void dispose() {
    _mentionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // FT-207: Autocomplete suggestions (basic implementation)
        if (_showAutocomplete)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _filteredPersonas.map((persona) {
                return ListTile(
                  dense: true,
                  leading: Text(
                    persona.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(
                    persona.displayName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '@${persona.shortName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  onTap: () => _selectPersona(persona),
                );
              }).toList(),
            ),
          ),

        // Main chat input
        Container(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    onChanged: _onTextChanged, // FT-207: Add mention detection
                    decoration: const InputDecoration(
                      hintText: 'Send a message... (try @persona)',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (widget.controller.text.trim().isNotEmpty) {
                      widget.onSend();
                      widget.controller.clear();
                      // Hide autocomplete when sending message
                      _mentionController.hideAutocomplete();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              AudioRecorder(
                onSendAudio: widget.onSendAudio,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
