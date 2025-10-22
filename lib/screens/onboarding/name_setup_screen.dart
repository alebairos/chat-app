import 'package:flutter/material.dart';
import '../../services/profile_service.dart';

/// Onboarding screen for setting up user's name
class NameSetupScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const NameSetupScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<NameSetupScreen> createState() => _NameSetupScreenState();
}

class _NameSetupScreenState extends State<NameSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize validation state
    _validateName(_nameController.text);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validateName(String value) {
    setState(() {
      _errorMessage = ProfileService.validateProfileName(value);
    });
  }

  Future<void> _saveName() async {
    if (_isLoading) return;

    final name = _nameController.text.trim();
    final error = ProfileService.validateProfileName(name);

    if (error != null) {
      setState(() {
        _errorMessage = error;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ProfileService.setProfileName(name);
      widget.onContinue();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save name. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _skip() {
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Header
              Icon(
                Icons.account_circle,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),

              Text(
                'Make it Personal',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'Your AI personas will address you by name in journals and conversations, creating a more personal experience.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Name input
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Your name',
                  hintText: 'How should AI address you?',
                  errorText: _errorMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                onChanged: _validateName,
                onSubmitted: (_) => _saveName(),
                textCapitalization: TextCapitalization.words,
              ),

              const Spacer(),

              // Action buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _errorMessage == null && !_isLoading
                          ? _saveName
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading ? null : _skip,
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
