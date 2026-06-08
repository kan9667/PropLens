import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/voice_service.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
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
  final VoiceService _voiceService = VoiceService();
  bool _isSearchFocused = false;
  bool _isListening = false;

  // Recent Searches State
  List<String> _recentSearches = [
    "2BHK Sector 50",
    "Under 80L",
    "3BHK near metro",
    "Ready to move",
    "Sector 57 villa"
  ];

  void _addRecentSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _recentSearches.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    });
  }

  void _onChipTap(String query) {
    _searchTextController.text = query;
    _addRecentSearch(query);
    widget.onSearchTriggered(query);
  }

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
    _voiceService.stopListening();
    _pulsingDotController.dispose();
    _searchAnimController.dispose();
    _entryController.dispose();
    _searchFocusNode.dispose();
    _searchTextController.dispose();
    _hintTimer.cancel();
    super.dispose();
  }

  void _showVoiceMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);

    await _voiceService.startListening(
      onResult: (text) {
        if (mounted) {
          setState(() {
            _searchTextController.text = text;
          });
        }
      },
      onListeningStopped: () {
        if (!mounted) return;
        setState(() => _isListening = false);
        if (_searchTextController.text.trim().isNotEmpty) {
          _onSearch();
        }
      },
      onError: (message) {
        if (!mounted) return;
        setState(() => _isListening = false);
        _showVoiceMessage(message);
      },
    );
  }

  void _onSearch() {
    final queryText = _searchTextController.text;
    if (queryText.trim().isNotEmpty) {
      _addRecentSearch(queryText);
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
                          "INDIA'S #1 AI-POWERED SEARCH PLATFORM",
                          style: TextStyle(
                            fontSize: badgeSize,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Verified homes with instant AI matching',
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
                        'AI-Powered Search',
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
                      icon: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening ? AppColors.error : AppColors.textSecond,
                        size: 20,
                      ),
                      onPressed: _toggleListening,
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

        const SizedBox(height: 16),
        _buildRecentSearches(),
        const SizedBox(height: 16),
        _buildFiltersRow(context),
        const SizedBox(height: 24),

        // Stats row
        const Row(
          children: [
            _StatItem(value: "50K+", label: "Verified Properties"),
            _VerticalDivider(height: 32),
            _StatItem(value: "Instant", label: "AI Match"),
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

    return PropertyImageCube(size: cubeSize);
  }

  //---------------------------------------------
  // RECENT SEARCHES & FILTERS WIDGETS
  //---------------------------------------------
  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent searches",
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecond,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final queryText = _recentSearches[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _onChipTap(queryText),
                        child: Container(
                          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 6),
                          child: Text(
                            queryText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _recentSearches.removeAt(index);
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersRow(BuildContext context) {
    return Row(
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            SizedBox(width: 4),
            Text(
              "Filters",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterPill(context, "BHK Type", ['1BHK', '2BHK', '3BHK', '4BHK+']),
                _buildFilterPill(context, "Budget", ['Under 50L', '50–80L', '80L–1Cr', 'Above 1Cr']),
                _buildFilterPill(context, "Locality", ['Sector 50', 'Sector 57', 'DLF Phase 1', 'Golf Course Road', 'Sohna Road']),
                _buildFilterPill(context, "Possession", ['Ready to Move', 'Within 1 Year', 'Under Construction']),
                _buildFilterPill(context, "Amenities", ['Near Metro', 'Near School', 'Gated Society', 'With Parking', 'East Facing']),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(BuildContext context, String filterName, List<String> options) {
    final provider = context.watch<AppProvider>();
    final selectedValue = provider.activeFilters[filterName];
    final isActive = selectedValue != null;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          _showFilterOptions(context, filterName, options);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedValue ?? filterName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.textSecond,
                ),
              ),
              const SizedBox(width: 4),
              if (isActive)
                GestureDetector(
                  onTap: () {
                    provider.clearFilter(filterName);
                  },
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: isActive ? Colors.white : AppColors.textHint,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context, String filterName, List<String> options) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final provider = Provider.of<AppProvider>(context);
        final currentValue = provider.activeFilters[filterName];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select $filterName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (currentValue != null)
                    TextButton(
                      onPressed: () {
                        provider.clearFilter(filterName);
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Clear', style: TextStyle(color: AppColors.error)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((option) {
                  final isSelected = currentValue == option;
                  return ChoiceChip(
                    label: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        provider.setFilter(filterName, option);
                      } else {
                        provider.clearFilter(filterName);
                      }
                      Navigator.pop(sheetContext);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
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
