import 'package:flutter/material.dart';
import 'personas_screen.dart';
import 'features_screen.dart';
import '../../services/onboarding_manager.dart';

/// Main onboarding flow with PageView navigation
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _completeOnboarding() async {
    await OnboardingManager.markOnboardingComplete();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                PersonasScreen(onContinue: _nextPage),
                FeaturesScreen(onComplete: _completeOnboarding),
              ],
            ),
          ),

          // Progress indicators
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildProgressDot(0),
                const SizedBox(width: 8),
                _buildProgressDot(1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(int index) {
    final isActive = index == _currentPage;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Theme.of(context).primaryColor : Colors.grey[300],
      ),
    );
  }
}
