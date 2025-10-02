import 'package:flutter/material.dart';

/// Loading skeleton for journal screen
class JournalLoadingSkeleton extends StatefulWidget {
  const JournalLoadingSkeleton({super.key});

  @override
  State<JournalLoadingSkeleton> createState() => _JournalLoadingSkeletonState();
}

class _JournalLoadingSkeletonState extends State<JournalLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header skeleton
                _buildSkeletonBox(
                  width: 200,
                  height: 20,
                ),
                const SizedBox(height: 8),
                _buildSkeletonBox(
                  width: 120,
                  height: 14,
                ),

                const SizedBox(height: 24),

                // Content skeleton
                _buildSkeletonBox(
                  width: double.infinity,
                  height: 16,
                ),
                const SizedBox(height: 12),
                _buildSkeletonBox(
                  width: double.infinity,
                  height: 16,
                ),
                const SizedBox(height: 12),
                _buildSkeletonBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 16,
                ),

                const SizedBox(height: 24),

                _buildSkeletonBox(
                  width: double.infinity,
                  height: 16,
                ),
                const SizedBox(height: 12),
                _buildSkeletonBox(
                  width: double.infinity,
                  height: 16,
                ),
                const SizedBox(height: 12),
                _buildSkeletonBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 16,
                ),

                const SizedBox(height: 32),

                // Footer skeleton
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildSkeletonBox(
                        width: 16,
                        height: 16,
                        borderRadius: 8,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSkeletonBox(
                          width: double.infinity,
                          height: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonBox({
    required double width,
    required double height,
    double borderRadius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
