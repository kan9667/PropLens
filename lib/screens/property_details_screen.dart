import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../data/types.dart';
import '../utils/theme.dart';
import '../services/llm_service.dart';
import '../services/recently_viewed_service.dart';
import '../providers/app_provider.dart';

class PropertyDetailsScreen extends StatefulWidget {
  static const String routeName = '/property';
  final PropertyModel property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> with TickerProviderStateMixin {
  String _aiAnswer = '';
  bool _isAiLoading = false;
  late TextEditingController _aiController;
  int _currentImageIndex = 0;

  late AnimationController _entryController;
  final List<Animation<double>> _detailFades = [];
  final List<Animation<Offset>> _detailSlides = [];

  bool _amenitiesExpanded = true;
  bool _nearbyExpanded = false;
  bool _matchExpanded = true;

  final GlobalKey _askAiSectionKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _aiController = TextEditingController();
    RecentlyViewedService().addViewed(widget.property);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    for (int i = 0; i < 6; i++) {
      final start = i * 0.08;
      final end = (start + 0.35).clamp(0.0, 1.0);
      _detailFades.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _entryController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
      _detailSlides.add(
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }
    _entryController.forward();
  }

  @override
  void dispose() {
    _aiController.dispose();
    _entryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToAskAi() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _askAiSectionKey.currentContext;
      if (targetContext == null || !_scrollController.hasClients) return;

      final renderObject = targetContext.findRenderObject();
      if (renderObject == null) return;

      final viewport = RenderAbstractViewport.maybeOf(renderObject);
      if (viewport == null) return;

      // Place the Ask AI card just below the pinned app bar, not at page bottom.
      const revealAlignment = 0.14;
      final targetOffset = viewport.getOffsetToReveal(renderObject, revealAlignment).offset;
      final maxExtent = _scrollController.position.maxScrollExtent;

      _scrollController.animateTo(
        targetOffset.clamp(0.0, maxExtent),
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _askAI(String question) async {
    if (question.trim().isEmpty) return;
    setState(() {
      _isAiLoading = true;
      _aiAnswer = '';
    });
    final answer = await LlmService.analyzeProperty(
      property: widget.property,
      question: question,
    );
    if (mounted) {
      setState(() {
        _aiAnswer = answer;
        _isAiLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final property = widget.property;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.grey.shade50,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          heroTag: 'ask_ai_property_fab',
          onPressed: _scrollToAskAi,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.auto_awesome, size: 20),
          label: const Text(
            'Ask AI',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              //---------------------------------------------
              // SLIVER APP BAR
              //---------------------------------------------
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                foregroundColor: isDark ? Colors.white : Colors.black,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.4),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  FavoriteButton(propertyId: property.id),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.4),
                      child: IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied to clipboard')),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      PageView.builder(
                        itemCount: property.imageUrls.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            imageUrl: property.imageUrls[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                              highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                      // Dots Indicator
                      if (property.imageUrls.length > 1)
                        Positioned(
                          bottom: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              property.imageUrls.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              //---------------------------------------------
              // SLIVER LIST BODY
              //---------------------------------------------
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeaderCard(context, property, isDark),
                    const SizedBox(height: 20),
                    _buildKeyDetailsSection(property, isDark),
                    const SizedBox(height: 12),
                    _buildExpandableSection(
                      title: 'Amenities',
                      subtitle: '${property.amenities.length} available',
                      icon: Icons.spa_outlined,
                      isExpanded: _amenitiesExpanded,
                      onToggle: () => setState(() => _amenitiesExpanded = !_amenitiesExpanded),
                      isDark: isDark,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: property.amenities.map((amenity) => _AmenityChip(label: amenity)).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildExpandableSection(
                      title: 'Nearby Places',
                      subtitle: '${property.nearbySchools.length + property.nearbyHospitals.length} locations',
                      icon: Icons.place_outlined,
                      isExpanded: _nearbyExpanded,
                      onToggle: () => setState(() => _nearbyExpanded = !_nearbyExpanded),
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NearbyGroup(
                            title: 'Schools',
                            icon: Icons.school_outlined,
                            iconColor: AppColors.primary,
                            items: property.nearbySchools,
                          ),
                          const SizedBox(height: 12),
                          _NearbyGroup(
                            title: 'Hospitals',
                            icon: Icons.local_hospital_outlined,
                            iconColor: AppColors.error,
                            items: property.nearbyHospitals,
                          ),
                        ],
                      ),
                    ),
                    if (property.matchScore != null) ...[
                      const SizedBox(height: 12),
                      _buildExpandableSection(
                        title: 'Match Breakdown',
                        subtitle: '${(property.matchScore! * 100).toStringAsFixed(0)}% fit for your search',
                        icon: Icons.insights_outlined,
                        isExpanded: _matchExpanded,
                        onToggle: () => setState(() => _matchExpanded = !_matchExpanded),
                        isDark: isDark,
                        trailing: _DetailMatchScoreBadge(score: property.matchScore!),
                        child: Column(
                          children: [
                            ...property.matchedReasons.map(
                              (reason) => _MatchReasonRow(
                                icon: Icons.check_circle_rounded,
                                color: AppColors.success,
                                text: reason,
                              ),
                            ),
                            ...property.missedReasons.map(
                              (reason) => _MatchReasonRow(
                                icon: Icons.info_outline_rounded,
                                color: AppColors.warning,
                                text: reason,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    KeyedSubtree(
                      key: _askAiSectionKey,
                      child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryLight.withOpacity(isDark ? 0.15 : 0.8),
                            isDark ? Colors.grey.shade900 : Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Ask AI About This Property',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Get instant analysis, investment insights, and honest drawbacks",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              "Is this overpriced?",
                              "Good for rental investment?",
                              "What are the drawbacks?",
                              "Future appreciation?",
                            ].map((text) {
                              return ActionChip(
                                label: Text(text, style: const TextStyle(fontSize: 12)),
                                backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
                                surfaceTintColor: Colors.transparent,
                                side: const BorderSide(color: AppColors.primary, width: 0.8),
                                onPressed: () {
                                  _aiController.text = text;
                                  _askAI(text);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _aiController,
                                  decoration: InputDecoration(
                                    hintText: "Ask anything about this property…",
                                    hintStyle: const TextStyle(fontSize: 14),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    filled: true,
                                    fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                  onSubmitted: (value) => _askAI(value),
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primary,
                                child: IconButton(
                                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                                  onPressed: () => _askAI(_aiController.text),
                                ),
                              ),
                            ],
                          ),
                          if (_isAiLoading) ...[
                            const SizedBox(height: 16),
                            const Center(
                              child: _TypingIndicator(),
                            ),
                          ],
                          if (_aiAnswer.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.successLight.withOpacity(isDark ? 0.15 : 0.8),
                                borderRadius: BorderRadius.circular(8),
                                border: const Border(
                                  left: BorderSide(
                                    color: AppColors.success,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'AI Analysis',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _aiAnswer,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
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
                  ]),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),

          // STICKY BOTTOM BAR
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: const Text("Schedule Visit"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Visit scheduled successfully!')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text("Make Offer"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Offer submitted to advisor!')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, PropertyModel property, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.priceDisplay,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      property.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              if (property.matchScore != null)
                _DetailMatchScoreBadge(score: property.matchScore!),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: isDark ? Colors.grey.shade400 : AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${property.locality}, ${property.city}',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
          if (property.isAiRecommended) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'AI Recommended',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyDetailsSection(PropertyModel property, bool isDark) {
    final details = [
      (Icons.bed_outlined, '${property.bhk} BHK', 'Bedrooms'),
      (Icons.square_foot_outlined, '${property.areaSqft} sqft', 'Area'),
      (Icons.bathtub_outlined, '${property.bathrooms}', 'Baths'),
      (Icons.directions_car_outlined, '${property.parking}', 'Parking'),
      (Icons.layers_outlined, '${property.floor}/${property.totalFloors}', 'Floor'),
      (Icons.chair_outlined, property.furnishing, 'Furnished'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int index = 0; index < details.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    final (icon, value, label) = details[index];
                    return FadeTransition(
                      opacity: _detailFades[index],
                      child: SlideTransition(
                        position: _detailSlides[index],
                        child: _CompactDetailTile(
                          icon: icon,
                          value: value,
                          label: label,
                          isDark: isDark,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required bool isDark,
    required Widget child,
    Widget? trailing,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withOpacity(0.25)
              : (isDark ? Colors.grey.shade800 : AppColors.divider),
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(isDark ? 0.2 : 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    trailing,
                    const SizedBox(width: 8),
                  ],
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: child,
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}

//---------------------------------------------
// FAVORITE BUTTON
//---------------------------------------------
class FavoriteButton extends StatelessWidget {
  final String propertyId;

  const FavoriteButton({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isFavorite = appProvider.isFavorite(propertyId);
    return CircleAvatar(
      backgroundColor: Colors.black.withOpacity(0.4),
      child: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.white,
        ),
        onPressed: () {
          appProvider.toggleFavorite(propertyId);
        },
      ),
    );
  }
}

//---------------------------------------------
// COMPACT DETAIL TILE
//---------------------------------------------
class _CompactDetailTile extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isDark;

  const _CompactDetailTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  State<_CompactDetailTile> createState() => _CompactDetailTileState();
}

class _CompactDetailTileState extends State<_CompactDetailTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 104,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.primaryLight.withOpacity(widget.isDark ? 0.3 : 1)
                : (widget.isDark ? Colors.grey.shade800 : AppColors.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _pressed ? AppColors.primary.withOpacity(0.4) : AppColors.divider,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: widget.isDark ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.1,
                  color: widget.isDark ? Colors.grey.shade400 : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//---------------------------------------------
// NEARBY GROUP
//---------------------------------------------
class _NearbyGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> items;

  const _NearbyGroup({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

//---------------------------------------------
// MATCH REASON ROW
//---------------------------------------------
class _MatchReasonRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _MatchReasonRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

//---------------------------------------------
// AMENITY CHIP WIDGET
//---------------------------------------------
class _AmenityChip extends StatelessWidget {
  final String label;

  const _AmenityChip({required this.label});

  IconData _getIcon(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('gym')) return Icons.fitness_center;
    if (lower.contains('pool') || lower.contains('swim')) return Icons.pool;
    if (lower.contains('security')) return Icons.security;
    if (lower.contains('lift') || lower.contains('elevator')) return Icons.elevator;
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('backup') || lower.contains('power')) return Icons.bolt;
    if (lower.contains('club')) return Icons.villa;
    if (lower.contains('park') || lower.contains('garden')) return Icons.park;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(label), size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

//---------------------------------------------
// MATCH SCORE BADGE
//---------------------------------------------
class _DetailMatchScoreBadge extends StatelessWidget {
  final double score;

  const _DetailMatchScoreBadge({required this.score});

  Color _getMatchScoreColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getMatchScoreColor(score);
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Text(
        '${(score * 100).toStringAsFixed(0)}% Match',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

//---------------------------------------------
// TYPING INDICATOR WIDGET
//---------------------------------------------
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double delay = index * 0.25;
        double progress = _controller.value - delay;
        if (progress < 0) progress += 1.0;
        
        // Map 0 -> 1 -> 0 scale
        double scale = 1.0;
        if (progress < 0.5) {
          scale = 1.0 + (progress * 2 * 0.4);
        } else {
          scale = 1.4 - ((progress - 0.5) * 2 * 0.4);
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          transform: Matrix4.diagonal3Values(scale, scale, 1.0),
          transformAlignment: Alignment.center,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDot(0),
        _buildDot(1),
        _buildDot(2),
      ],
    );
  }
}