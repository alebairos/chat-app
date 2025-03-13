import 'package:flutter/material.dart';
import '../services/tts_service_factory.dart';
import '../services/audio_message_provider.dart';
import '../services/eleven_labs_tts_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A screen for configuring TTS settings.
class TTSSettingsScreen extends StatefulWidget {
  /// The audio message provider instance.
  final AudioMessageProvider audioMessageProvider;

  /// Creates a new [TTSSettingsScreen] instance.
  const TTSSettingsScreen({
    Key? key,
    required this.audioMessageProvider,
  }) : super(key: key);

  @override
  State<TTSSettingsScreen> createState() => _TTSSettingsScreenState();
}

class _TTSSettingsScreenState extends State<TTSSettingsScreen> {
  late TTSServiceType _selectedServiceType;
  bool _isLoading = false;
  String _selectedVoiceId = '';

  // List of available voices with their names and IDs
  final List<Map<String, String>> _voices = [
    {'name': 'Josh (English)', 'id': 'TxGEqnHWrfWFTfGW9XjX'},
    {'name': 'Elli (English)', 'id': 'MF3mGyEYCl7XYWbV9V6O'},
    {'name': 'Adam (Brazilian Portuguese)', 'id': 'pNInz6obpgDQGcFmaJgB'},
    {'name': 'Rachel (Multilingual)', 'id': '21m00Tcm4TlvDq8ikWAM'},
    {'name': 'Antoni (Multilingual)', 'id': 'ErXwobaYiN019PkySvjV'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedServiceType = widget.audioMessageProvider.ttsServiceType;

    // Get the current voice ID from environment
    _selectedVoiceId =
        dotenv.env['ELEVEN_LABS_VOICE_ID'] ?? 'TxGEqnHWrfWFTfGW9XjX';
  }

  Future<void> _changeTTSService(TTSServiceType serviceType) async {
    if (_selectedServiceType == serviceType) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success =
          await widget.audioMessageProvider.changeTTSServiceType(serviceType);

      if (success) {
        setState(() {
          _selectedServiceType = serviceType;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'TTS service changed to ${_getServiceName(serviceType)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to change TTS service'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getServiceName(TTSServiceType serviceType) {
    switch (serviceType) {
      case TTSServiceType.flutterTTS:
        return 'Flutter TTS (Local)';
      case TTSServiceType.elevenLabs:
        return 'ElevenLabs (Cloud)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TTS Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Text-to-Speech Service',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose which service to use for generating audio from text.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                _buildServiceOption(
                  TTSServiceType.flutterTTS,
                  'Flutter TTS (Local)',
                  'Uses the device\'s built-in text-to-speech capabilities. Works offline but has limited voice quality.',
                  Icons.phone_android,
                ),
                const SizedBox(height: 12),
                _buildServiceOption(
                  TTSServiceType.elevenLabs,
                  'ElevenLabs (Cloud)',
                  'Uses ElevenLabs cloud API for high-quality, natural-sounding voices. Requires internet connection and API key.',
                  Icons.cloud,
                ),
                const SizedBox(height: 24),
                if (_selectedServiceType == TTSServiceType.elevenLabs)
                  _buildElevenLabsSettings(),
              ],
            ),
    );
  }

  Widget _buildServiceOption(
    TTSServiceType serviceType,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedServiceType == serviceType;

    return Card(
      elevation: isSelected ? 4 : 1,
      color:
          isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _changeTTSService(serviceType),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElevenLabsSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ElevenLabs Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Configure your ElevenLabs API settings.',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'API Key',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your API key is stored securely in the .env file.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Voice Selection',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildVoiceSelector(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            // This would open a browser to the ElevenLabs website
            // In a real app, you'd implement this with url_launcher package
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This would open the ElevenLabs website'),
              ),
            );
          },
          icon: const Icon(Icons.open_in_new),
          label: const Text('Visit ElevenLabs Website'),
        ),
      ],
    );
  }

  Widget _buildVoiceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select a voice:',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          value: _selectedVoiceId,
          items: _voices.map((voice) {
            return DropdownMenuItem<String>(
              value: voice['id'],
              child: Text(voice['name']!),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedVoiceId = value;
              });
              _updateVoice(value);
            }
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'English voices are recommended for English content. Brazilian Portuguese voices are recommended for Portuguese content.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _updateVoice(String voiceId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the audio generation service
      final audioGenService =
          widget.audioMessageProvider.getAudioGenerationService();

      // Set the voice ID if it's an ElevenLabs service
      if (audioGenService is ElevenLabsTTSService) {
        audioGenService.setVoiceId(voiceId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating voice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
