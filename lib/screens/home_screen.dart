import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/app_provider.dart';
import '../providers/comparison_provider.dart';
import '../widgets/property_grid.dart';
import '../widgets/property_advisor.dart';
import '../widgets/ai_overview_widget.dart';
import '../widgets/hero_search_widget.dart';
import '../widgets/app_logo.dart';
import '../widgets/ai_advisor_fab.dart';
import '../navigation/advisor_navigation.dart';
import 'comparison_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _propertyGridKey = GlobalKey();
  final GlobalKey _advisorKey = GlobalKey();

  // Empty State animations
  late AnimationController _emptyStateRotateController;
  late AnimationController _emptyStatePulseController;

  // Overview entry controller
  late AnimationController _overviewController;
  late Animation<double> _overviewFade;
  late Animation<Offset> _overviewSlide;

  bool _isOverviewExpanded = false;

  @override
  void initState() {
    super.initState();

    // 1. Empty State rotate (20s)
    _emptyStateRotateController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();

    // 2. Empty State center icon pulse
    _emptyStatePulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);

    // 3. AI Overview card transition
    _overviewController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _overviewFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _overviewController, curve: Curves.easeOutCubic),
    );
    _overviewSlide = Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _overviewController, curve: Curves.easeOutCubic),
    );

    AdvisorNavigation.scrollToAdvisor = scrollToAdvisor;
  }

  @override
  void dispose() {
    AdvisorNavigation.scrollToAdvisor = null;
    _scrollController.dispose();
    _emptyStateRotateController.dispose();
    _emptyStatePulseController.dispose();
    _overviewController.dispose();
    super.dispose();
  }

  void _scrollToResults() {
    final targetContext = _propertyGridKey.currentContext;
    if (targetContext == null) return;

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
      alignment: 0.08,
    );
  }

  void scrollToAdvisor() {
    final targetContext = _advisorKey.currentContext;
    if (targetContext == null) return;

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
      alignment: 0.05,
    );
  }

  void _triggerSearch(String queryText) {
    context.read<AppProvider>().updateQuery(queryText);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToResults());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final comparisonProvider = context.watch<ComparisonProvider>();
    final canCompare = comparisonProvider.count >= 2;
    final hasSearched = provider.query.trim().isNotEmpty;

    // Reactively drive Overview Entry transitions
    if (hasSearched && !provider.isLoading) {
      _overviewController.forward();
    } else {
      _overviewController.reverse();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // SECTION 2: Hero Area
                HeroSearchWidget(onSearchTriggered: _triggerSearch),

                // SECTION 3: Trust Bar
                _buildTrustBar(constraints.maxWidth),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48 : 16,
                    vertical: isDesktop ? 32 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasSearched) _buildResultsSection(provider) else _buildEmptyState(),
                    ],
                  ),
                ),

                KeyedSubtree(
                  key: _advisorKey,
                  child: const PropertyAdvisorWidget(),
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: AiAdvisorFab(
        additionalActions: canCompare
            ? [
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'compare_fab',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComparisonScreen()),
                    );
                  },
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.compare_arrows),
                  label: Text(
                    'Compare (${comparisonProvider.count})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ]
            : const [],
      ),
    );
  }

  //---------------------------------------------
  // APPBAR BUILDER
  //---------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 700;

    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: AppColors.border,
          height: 1.0,
        ),
      ),
      title: const AppLogo(),
      actions: isDesktop
          ? [
              TextButton(onPressed: () {}, child: const Text("Properties", style: TextStyle(color: AppColors.textSecond))),
              TextButton(onPressed: () {}, child: const Text("Virtual Tours", style: TextStyle(color: AppColors.textSecond))),
              TextButton.icon(
                onPressed: scrollToAdvisor,
                icon: const Icon(Icons.psychology_outlined, size: 18, color: AppColors.primary),
                label: const Text("AI Advisor", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGrad,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text("Get Started →", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ]
          : [
              TextButton.icon(
                onPressed: scrollToAdvisor,
                icon: const Icon(Icons.psychology_outlined, size: 18, color: AppColors.primary),
                label: const Text('Advisor', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                onPressed: () {},
              ),
            ],
    );
  }

  Widget _buildResultsSection(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _overviewController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _overviewFade,
              child: SlideTransition(
                position: _overviewSlide,
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
        const SizedBox(height: 12),
        KeyedSubtree(
          key: _propertyGridKey,
          child: const PropertyGrid(),
        ),
      ],
    );
  }

  //---------------------------------------------
  // TRUST BAR WIDGET
  //---------------------------------------------
  Widget _buildTrustBar(double width) {
    final isMobile = width < 700;

    if (isMobile) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border.symmetric(horizontal: BorderSide(color: AppColors.border, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 10,
          ),
          children: [
            _buildTrustItem(Icons.verified_rounded, "Zero Fake Listings", AppColors.accent),
            _buildTrustItem(Icons.currency_rupee, "Zero Upfront Fees", AppColors.primary),
            _buildTrustItem(Icons.support_agent, "Dedicated RM Support", AppColors.secondary),
            _buildTrustItem(Icons.view_in_ar_rounded, "Studio 360° Tours", AppColors.primary),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border.symmetric(horizontal: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTrustItem(Icons.verified_rounded, "Zero Fake Listings", AppColors.accent),
          _buildTrustItem(Icons.currency_rupee, "Zero Upfront Fees", AppColors.primary),
          _buildTrustItem(Icons.support_agent, "Dedicated RM Support", AppColors.secondary),
          _buildTrustItem(Icons.view_in_ar_rounded, "Studio 360° Tours", AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecond, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  //---------------------------------------------
  // EMPTY STATE BEFORE SEARCH
  //---------------------------------------------
  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _emptyStateRotateController,
              builder: (context, child) => Transform.rotate(
                angle: _emptyStateRotateController.value * 2 * pi,
                child: child,
              ),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid, // dashed simulated rotated solid border
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _emptyStatePulseController,
              builder: (context, child) {
                final scale = 1.0 + (_emptyStatePulseController.value * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.home_work_rounded, size: 28, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          "Search 50,000+ Verified Properties",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            "Use natural language — our AI understands exactly what you need.",
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecond,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Popular searches:",
          style: TextStyle(fontSize: 11, color: AppColors.textSecond, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildSuggestionChip("2 BHK in Gurugram under ₹80L"),
            _buildSuggestionChip("Villa with pool near DPS"),
            _buildSuggestionChip("Furnished flat near Cyber City"),
            _buildSuggestionChip("Ready to move 3 BHK Sector 50"),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () => _triggerSearch(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [AppColors.softShadow],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecond),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.north_east_rounded, size: 12, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
