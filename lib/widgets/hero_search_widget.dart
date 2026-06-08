import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'property_image_cube.dart';

class HeroSearchWidget extends StatefulWidget {
  final Function(String) onSearchTriggered;

  const HeroSearchWidget({super.key, required this.onSearchTriggered});

  @override
  State<HeroSearchWidget> createState() => _HeroSearchWidgetState();
}

class _HeroSearchWidgetState extends State<HeroSearchWidget> with TickerProviderStateMixin {
  // Pulsing Dot Controller
  late AnimationController _pulsingDotController;
  late Animation<double> _dotOpacity;

  // Search Bar Pop-Out Controller
  late AnimationController _searchAnimController;
  late Animation<double> _searchScale;
  late Animation<double> _searchOpacity;
  late Animation<Offset> _searchSlide;

  // Stagger entry controllers for text/pill
  late AnimationController _entryController;
  late Animation<double> _badgeFade;
  late Animation<Offset> _badgeSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  // Search input focus & controller
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchTextController = TextEditingController();
  bool _isSearchFocused = false;

  // Cycling Hints
  late Timer _hintTimer;
  int _currentHintIndex = 0;
  final List<String> _hints = [
    "2 BHK in Gurugram under ₹80L...",
    "Villa with pool near DPS school...",
    "Furnished flat near Cyber City...",
    "3 BHK ready to move in Sector 50..."
  ];

  @override
  void initState() {
    super.initState();

    // 1. Pulsing Dot (1200ms repeat)
    _pulsingDotController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _dotOpacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulsingDotController, curve: Curves.easeInOut),
    );

    // 2. Search Pop-out Spring (elasticOut)
    _searchAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _searchScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _searchAnimController, curve: Curves.elasticOut),
    );
    _searchOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchAnimController, curve: Curves.easeIn),
    );
    _searchSlide = Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _searchAnimController, curve: Curves.elasticOut),
    );

    // 3. Stagger entry animations
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _badgeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _badgeSlide = Tween<Offset>(begin: const Offset(0.0, -0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.1, 0.6, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0.0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic)),
    );
    // Focus handler
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });

    // Cycle hint timer
    _hintTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % _hints.length;
        });
      }
    });

    // Run entry animations in sequence
    _entryController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _searchAnimController.forward();
    });
  }

  @override
  void dispose() {
    _pulsingDotController.dispose();
    _searchAnimController.dispose();
    _entryController.dispose();
    _searchFocusNode.dispose();
    _searchTextController.dispose();
    _hintTimer.cancel();
    super.dispose();
  }

  void _onSearch() {
    final queryText = _searchTextController.text;
    if (queryText.trim().isNotEmpty) {
      widget.onSearchTriggered(queryText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 700;

        if (isDesktop) {
          return Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.heroBg,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 80),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildLeftColumn(constraints.maxWidth),
                ),
                const SizedBox(width: 48),
                Expanded(
                  flex: 4,
                  child: _buildRightColumn(true),
                ),
              ],
            ),
          );
        } else {
          // Mobile stack
          return Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.heroBg,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth < 360 ? 16 : 24,
              vertical: constraints.maxWidth < 360 ? 32 : 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeftColumn(constraints.maxWidth),
                const SizedBox(height: 40),
                _buildRightColumn(false),
              ],
            ),
          );
        }
      },
    );
  }

  double _headlineSize(double width) {
    if (width < 340) return 26;
    if (width < 400) return 30;
    if (width < 700) return 34;
    return 40;
  }

  //---------------------------------------------
  // LEFT COLUMN CONTENT
  //---------------------------------------------
  Widget _buildLeftColumn(double width) {
    final headlineSize = _headlineSize(width);
    final badgeSize = width < 360 ? 10.0 : 11.0;
    final isCompact = width < 400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: _badgeFade,
          child: SlideTransition(
            position: _badgeSlide,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14, vertical: isCompact ? 8 : 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.accent.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGrad,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "INDIA'S #1 AI + VR PLATFORM",
                          style: TextStyle(
                            fontSize: badgeSize,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Verified homes with immersive 360° tours',
                          style: TextStyle(
                            fontSize: badgeSize - 1,
                            color: AppColors.textSecond,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FadeTransition(
                    opacity: _dotOpacity,
                    child: Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: isCompact ? 14 : 20),

        FadeTransition(
          opacity: _titleFade,
          child: SlideTransition(
            position: _titleSlide,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find Your Dream',
                  style: TextStyle(
                    fontSize: headlineSize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Home with ',
                      style: TextStyle(
                        fontSize: headlineSize,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => AppColors.primaryGrad.createShader(bounds),
                      child: Text(
                        'AI + VR',
                        style: TextStyle(
                          fontSize: headlineSize,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: isCompact ? 20 : 28),

        // Search Bar Pop-Out Spring
        FadeTransition(
          opacity: _searchOpacity,
          child: ScaleTransition(
            scale: _searchScale,
            child: SlideTransition(
              position: _searchSlide,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isSearchFocused ? AppColors.accent : AppColors.border,
                    width: 1.5,
                  ),
                  boxShadow: [
                    AppColors.cardShadow,
                    AppColors.softShadow,
                    if (_isSearchFocused) AppColors.searchGlow,
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.search_rounded,
                        key: ValueKey(_isSearchFocused),
                        color: _isSearchFocused ? AppColors.accent : AppColors.textHint,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          if (_searchTextController.text.isEmpty)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 0.3),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                _hints[_currentHintIndex],
                                key: ValueKey(_currentHintIndex),
                                style: const TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          TextField(
                            focusNode: _searchFocusNode,
                            controller: _searchTextController,
                            cursorColor: AppColors.accent,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            onChanged: (val) {
                              setState(() {});
                            },
                            onSubmitted: (val) => _onSearch(),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 28,
                      width: 1,
                      color: AppColors.border,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.mic_rounded, color: AppColors.textSecond, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Listening...')),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _onSearch,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGrad,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              "Search",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Stats row
        const Row(
          children: [
            _StatItem(value: "50K+", label: "Verified Properties"),
            _VerticalDivider(height: 32),
            _StatItem(value: "360°", label: "Virtual Tours"),
            _VerticalDivider(height: 32),
            _StatItem(value: "98%", label: "AI Match Rate"),
          ],
        ),
      ],
    );
  }

  //---------------------------------------------
  // RIGHT COLUMN - PROPERTY IMAGE CUBE
  //---------------------------------------------
  Widget _buildRightColumn(bool isDesktop) {
    final cubeSize = isDesktop ? 220.0 : 165.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PropertyImageCube(size: cubeSize),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: const [AppColors.softShadow],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGrad,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.view_in_ar_rounded, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '50,000+ Verified Homes',
                      style: TextStyle(
                        fontSize: isDesktop ? 13 : 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Each face — a real property preview',
                      style: TextStyle(
                        fontSize: isDesktop ? 11 : 10,
                        color: AppColors.textSecond,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

//--------------------------------------------------
// STAT ITEM COMPONENT
//--------------------------------------------------
class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecond,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final double height;
  const _VerticalDivider({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: height,
      width: 1,
      color: AppColors.border,
    );
  }
}
