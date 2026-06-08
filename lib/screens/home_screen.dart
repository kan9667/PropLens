import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/comparison_provider.dart';
import '../widgets/search_bar.dart';
import '../widgets/property_grid.dart';
import '../widgets/property_advisor.dart';
import '../widgets/ai_overview_widget.dart';
import 'comparison_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _isOverviewExpanded = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final comparisonProvider = context.watch<ComparisonProvider>();
    final canCompare = comparisonProvider.count >= 2;
    final hasSearched = provider.query.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (hasSearched) {
      _animController.forward();
    } else {
      _animController.reverse();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '360 Ghar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Search Bar (Always at the top)
            const SearchBarWidget(),

            // Animated Switcher to transition between empty/default state and results state
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: !hasSearched
                  ? _buildEmptyState(isDark)
                  : Column(
                      key: const ValueKey('results_layout'),
                      children: [
                        // 2. AI Overview Card (Animated Entry)
                        AnimatedBuilder(
                          animation: _animController,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnim,
                              child: SlideTransition(
                                position: _slideAnim,
                                child: child,
                              ),
                            );
                          },
                          child: AiOverviewWidget(
                            results: provider.results,
                            userQuery: provider.query,
                            overview: provider.aiOverview,
                            state: provider.aiOverviewState,
                            isExpanded: _isOverviewExpanded,
                            onExpand: () {
                              setState(() {
                                _isOverviewExpanded = !_isOverviewExpanded;
                              });
                            },
                          ),
                        ),

                        // 3. Property Results Grid
                        const PropertyGrid(),

                        // 4. Follow-up Advisor Panel at the bottom
                        const PropertyAdvisorWidget(),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: canCompare
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ComparisonScreen(),
                  ),
                );
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.compare_arrows),
              label: Text(
                'Compare (${comparisonProvider.count})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      key: const ValueKey('empty_state'),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_outlined,
            size: 64,
            color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
          ),
          const SizedBox(height: 16),
          const Text(
            'Explore Gurgaon Properties',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a natural language search query above to fetch property results and generate an instant AI Overview.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
