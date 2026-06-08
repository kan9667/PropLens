import 'package:flutter/material.dart';

/// Bridges the persistent AI Advisor FAB to [HomeScreen]'s scroll target.
class AdvisorNavigation {
  static VoidCallback? scrollToAdvisor;

  static void navigateToAdvisor(BuildContext context) {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToAdvisor?.call();
    });
  }
}
