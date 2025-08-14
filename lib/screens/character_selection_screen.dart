import 'package:flutter/material.dart';

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
  late String _selectedPersonaKey;

  @override
  void initState() {
    super.initState();
    _selectedPersonaKey = _configLoader.activePersonaKey;
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

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _selectedPersonaKey == personaKey
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPersonaKey = personaKey;
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
                                          _getAvatarColor(personaKey),
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
                                    Radio<String>(
                                      value: personaKey,
                                      groupValue: _selectedPersonaKey,
                                      onChanged: (String? value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedPersonaKey = value;
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
                  _configLoader.setActivePersona(_selectedPersonaKey);
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

  Color _getAvatarColor(String personaKey) {
    // Generate colors based on persona key hash for consistency
    final int hash = personaKey.hashCode;
    final List<Color> colors = [
      Colors.teal,
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[hash.abs() % colors.length];
  }
}
