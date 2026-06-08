import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../navigation/advisor_navigation.dart';

/// Persistent bottom-left control that returns the user to the home AI advisor.
class AiAdvisorFab extends StatelessWidget {
  final List<Widget> additionalActions;

  const AiAdvisorFab({
    super.key,
    this.additionalActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FloatingActionButton.extended(
            heroTag: 'ai_advisor_fab',
            onPressed: () => AdvisorNavigation.navigateToAdvisor(context),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.psychology_outlined),
            label: const Text(
              'AI Advisor',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...additionalActions,
        ],
      ),
    );
  }
}
