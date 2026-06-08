import 'package:flutter/material.dart';
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

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  String _aiAnswer = '';
  bool _isAiLoading = false;
  late TextEditingController _aiController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _aiController = TextEditingController();
    // Record view in RecentlyViewedService
    RecentlyViewedService().addViewed(widget.property);
  }

  @override
  void dispose() {
    _aiController.dispose();
    super.dispose();
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
      body: Stack(
        children: [
          CustomScrollView(
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // SECTION 1: Price + Identity
                    const SizedBox(height: 16),
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
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                property.title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (property.matchScore != null) ...[
                          const SizedBox(width: 8),
                          _DetailMatchScoreBadge(score: property.matchScore!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          "${property.locality}, ${property.city}",
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    if (property.isAiRecommended) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "🤖 AI Recommended",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, thickness: 0.5),
                    const SizedBox(height: 16),

                    // SECTION 2: Key Details Grid
                    const Text(
                      "Key Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      children: [
                        _InfoTile(icon: Icons.bed_outlined, label: "BHK", value: "${property.bhk} BHK"),
                        _InfoTile(icon: Icons.square_foot, label: "Area", value: "${property.areaSqft} sqft"),
                        _InfoTile(icon: Icons.bathtub_outlined, label: "Baths", value: "${property.bathrooms}"),
                        _InfoTile(icon: Icons.directions_car, label: "Parking", value: "${property.parking}"),
                        _InfoTile(icon: Icons.layers_outlined, label: "Floor", value: "${property.floor}/${property.totalFloors}"),
                        _InfoTile(icon: Icons.chair_outlined, label: "Furnished", value: property.furnishing),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, thickness: 0.5),
                    const SizedBox(height: 16),

                    // SECTION 3: Amenities
                    const Text(
                      "Amenities",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: property.amenities.map((amenity) => _AmenityChip(label: amenity)).toList(),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, thickness: 0.5),
                    const SizedBox(height: 16),

                    // SECTION 4: Nearby Places
                    const Text(
                      "Nearby Places",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "🏫 Schools",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      children: property.nearbySchools
                          .map(
                            (school) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.school, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(school, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "🏥 Hospitals",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      children: property.nearbyHospitals
                          .map(
                            (hospital) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_hospital, size: 14, color: AppColors.error),
                                  const SizedBox(width: 8),
                                  Text(hospital, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, thickness: 0.5),
                    const SizedBox(height: 16),

                    // SECTION 5: Match Score Breakdown
                    if (property.matchScore != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Why ${(property.matchScore! * 100).toStringAsFixed(0)}% Match?",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _DetailMatchScoreBadge(score: property.matchScore!),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          ...property.matchedReasons.map(
                            (reason) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(reason, style: const TextStyle(fontSize: 14)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ...property.missedReasons.map(
                            (reason) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(reason, style: const TextStyle(fontSize: 14)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.divider, thickness: 0.5),
                      const SizedBox(height: 16),
                    ],

                    // SECTION 6: Ask AI About This Property
                    Container(
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
                          const Row(
                            children: [
                              Text("🤖", style: TextStyle(fontSize: 20)),
                              SizedBox(width: 8),
                              Text(
                                "Ask AI About This Property",
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
                                    "🤖 AI says:",
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

                    const SizedBox(height: 100), // Space for sticky bottom bar
                  ]),
                ),
              ),
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
// INFO TILE WIDGET
//---------------------------------------------
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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