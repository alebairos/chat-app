import 'package:flutter/material.dart';
import '../../services/context_logger_service.dart';

/// FT-220: Context Logging Settings Screen
/// 
/// Allows users to enable/disable context logging for debugging.
/// MVP: Toggle + warning only. Export/clear deferred to Phase 5.
class ContextLoggingSettingsScreen extends StatefulWidget {
  const ContextLoggingSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ContextLoggingSettingsScreen> createState() =>
      _ContextLoggingSettingsScreenState();
}

class _ContextLoggingSettingsScreenState
    extends State<ContextLoggingSettingsScreen> {
  final _contextLogger = ContextLoggerService();
  bool _isLoading = true;
  bool _loggingEnabled = false;
  String? _logDirectoryPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      _loggingEnabled = _contextLogger.isEnabled;
      if (_loggingEnabled) {
        _logDirectoryPath = await _contextLogger.getLogDirectoryPath();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLogging(bool value) async {
    if (value) {
      // Show warning dialog before enabling
      final confirmed = await _showEnableWarningDialog();
      if (confirmed != true) return;
    }

    setState(() => _isLoading = true);

    try {
      await _contextLogger.setEnabled(value);
      _loggingEnabled = value;
      
      if (value) {
        _logDirectoryPath = await _contextLogger.getLogDirectoryPath();
      } else {
        _logDirectoryPath = null;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? '✅ Context logging enabled'
                  : '🚫 Context logging disabled',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showEnableWarningDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text('Enable Context Logging?'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Context logging will record:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Complete conversation history'),
              const Text('• All user messages (exact text)'),
              const Text('• All AI responses (exact text)'),
              const Text('• Complete system prompts'),
              const Text('• All configuration layers'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Privacy Warning',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Logs are stored locally and contain COMPLETE conversation history. '
                      'Enable only if you understand the privacy implications.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This feature is intended for debugging and optimization.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Context Logging'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Main toggle card
                Card(
                  color: _loggingEnabled ? Colors.orange.shade50 : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bug_report_outlined,
                              color: _loggingEnabled
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Context Logging',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _loggingEnabled
                                        ? '⚠️ ENABLED - Logging complete context'
                                        : 'Disabled',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _loggingEnabled
                                          ? Colors.orange.shade900
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _loggingEnabled,
                              onChanged: _toggleLogging,
                              activeColor: Colors.orange,
                            ),
                          ],
                        ),
                        if (_loggingEnabled) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 20,
                                      color: Colors.deepOrange,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'WARNING',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Logs contain COMPLETE conversation history including all your messages and AI responses.',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Access logs via Files app:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (_logDirectoryPath != null)
                                  SelectableText(
                                    _logDirectoryPath!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: Colors.grey.shade700,
                                    ),
                                  )
                                else
                                  Text(
                                    'logs/context/session_<timestamp>/',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'About Context Logging',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Context logging captures the exact context sent to the AI model for debugging and optimization.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'What gets logged:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildInfoItem('Complete system prompt'),
                        _buildInfoItem('Complete messages array'),
                        _buildInfoItem('API request and response'),
                        _buildInfoItem('Token usage'),
                        const SizedBox(height: 12),
                        const Text(
                          'What does NOT get logged:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildInfoItem('API key (redacted for security)'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ℹ️ Zero overhead when disabled - no performance impact.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

