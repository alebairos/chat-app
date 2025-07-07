import 'package:flutter/material.dart';
import '../config/character_config_manager.dart';
import '../config/config_loader.dart';

class CharacterSelectionScreen extends StatefulWidget {
  final Function() onCharacterSelected;

  const CharacterSelectionScreen({
    Key? key,
    required this.onCharacterSelected,
  }) : super(key: key);

  @override
  _CharacterSelectionScreenState createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  final ConfigLoader _configLoader = ConfigLoader();
  late CharacterPersona _selectedPersona;

  @override
  void initState() {
    super.initState();
    _selectedPersona = _configLoader.activePersona;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Guide'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a character to guide your personal development journey:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _configLoader.availablePersonas,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading personas: ${snapshot.error}'),
                    );
                  }

                  final availablePersonas = snapshot.data ?? [];

                  if (availablePersonas.isEmpty) {
                    return const Center(
                      child: Text('No personas available'),
                    );
                  }

                  return ListView.builder(
                    itemCount: availablePersonas.length,
                    itemBuilder: (context, index) {
                      final persona = availablePersonas[index];
                      final personaKey = persona['key'] as String;
                      final personaEnum = _getPersonaEnumFromKey(personaKey);

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _selectedPersona == personaEnum
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPersona = personaEnum;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          _getAvatarColor(personaEnum),
                                      child: Text(
                                        persona['displayName'][0],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        persona['displayName'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Radio<CharacterPersona>(
                                      value: personaEnum,
                                      groupValue: _selectedPersona,
                                      onChanged: (CharacterPersona? value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedPersona = value;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  persona['description'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _configLoader.setActivePersona(_selectedPersona);
                  widget.onCharacterSelected();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CharacterPersona _getPersonaEnumFromKey(String key) {
    switch (key) {
      case 'personalDevelopmentAssistant':
        return CharacterPersona.personalDevelopmentAssistant;
      case 'sergeantOracle':
        return CharacterPersona.sergeantOracle;
      case 'zenGuide':
        return CharacterPersona.zenGuide;
      default:
        return CharacterPersona.sergeantOracle; // Default fallback
    }
  }

  Color _getAvatarColor(CharacterPersona persona) {
    switch (persona) {
      case CharacterPersona.personalDevelopmentAssistant:
        return Colors.blue;
      case CharacterPersona.sergeantOracle:
        return Colors.red;
      case CharacterPersona.zenGuide:
        return Colors.green;
    }
  }
}
