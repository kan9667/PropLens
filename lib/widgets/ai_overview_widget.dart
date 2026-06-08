import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/types.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

class AiOverviewWidget extends StatefulWidget {
  final List<PropertyModel> results;
  final String userQuery;
  final AiOverview? overview; // null = still loading
  final AiState state; // loading | loaded | error
  final VoidCallback onExpand;
  final bool isExpanded;

  const AiOverviewWidget({
    super.key,
    required this.results,
    required this.userQuery,
    required this.overview,
    required this.state,
    required this.onExpand,
    required this.isExpanded,
  });

  @override
  State<AiOverviewWidget> createState() => _AiOverviewWidgetState();
}

class _AiOverviewWidgetState extends State<AiOverviewWidget> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(_shimmerController);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Widget _buildShimmerBar(double widthPct, double height) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, child) {
        return FractionallySizedBox(
          widthFactor: widthPct,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [baseColor, highlightColor, baseColor],
                stops: [
                  0.0,
                  (_shimmerAnim.value.clamp(0.0, 1.0)),
                  1.0,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppColors.divider, thickness: 0.5),
        const SizedBox(height: 16),
        _buildShimmerBar(0.8, 12),
        const SizedBox(height: 12),
        _buildShimmerBar(0.6, 12),
        const SizedBox(height: 12),
        _buildShimmerBar(0.9, 12),
        const SizedBox(height: 12),
        _buildShimmerBar(0.5, 12),
        const SizedBox(height: 12),
        _buildShimmerBar(0.7, 12),
        const SizedBox(height: 12),
        _buildShimmerBar(0.4, 12),
      ],
    );
  }

  Widget _buildBulletList(String text, Color dotColor) {
    final items = text
        .split(RegExp(r'(?:•|\n|✓)\s*'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Text(text, style: AppTextStyles.bodyMedium),
      );
    }

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4, right: 8),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildRatingChip(String rating) {
    Color chipColor = AppColors.primary;
    Color bg = AppColors.primaryLight;
    final r = rating.toLowerCase();

    if (r.contains('high') || r.contains('good') || r.contains('great')) {
      chipColor = AppColors.success;
      bg = AppColors.successLight;
    } else if (r.contains('medium') || r.contains('average') || r.contains('moderate')) {
      chipColor = AppColors.warning;
      bg = AppColors.warning.withAlpha(30);
    } else if (r.contains('low') || r.contains('poor')) {
      chipColor = AppColors.error;
      bg = AppColors.error.withAlpha(30);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withAlpha(80)),
      ),
      child: Text(
        rating.toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overview = widget.overview;

    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardDecoration.boxShadow,
          border: const Border(
            left: BorderSide(
              color: AppColors.primary,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //---------------------------------------------
              // Row 1: Title & Status Indicator
              //---------------------------------------------
              Row(
                children: [
                  const Text(
                    '🤖 AI Overview',
                    style: AppTextStyles.titleMedium,
                  ),
                  const Spacer(),
                  if (widget.state == AiState.loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  if (widget.state == AiState.loaded)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              //---------------------------------------------
              // Row 2 / Body based on state
              //---------------------------------------------
              if (widget.state == AiState.loading) ...[
                _buildShimmerBar(0.7, 14),
                const SizedBox(height: 8),
                _buildShimmerBar(0.5, 12),
              ] else if (widget.state == AiState.error) ...[
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'AI analysis unavailable',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<AppProvider>().generateAiOverview();
                      },
                      child: const Text(
                        'Retry',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ] else if (widget.state == AiState.loaded && overview != null) ...[
                Text(
                  '✓ Found ${widget.results.length} matching properties',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                //---------------------------------------------
                // Row 3: Best Match Mini Card
                //---------------------------------------------
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withAlpha(isDark ? 30 : 255),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Best Match',
                              style: AppTextStyles.labelSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              overview.bestMatch.title,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              overview.bestMatch.priceDisplay,
                              style: AppTextStyles.titleMediumBold,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      MatchScoreBadge(score: overview.bestMatch.matchScore),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                //---------------------------------------------
                // Row 4: Quick Insight Chips
                //---------------------------------------------
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: overview.quickInsights.take(3).map((reason) {
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.successLight.withAlpha(isDark ? 30 : 255),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '✓ $reason',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                //---------------------------------------------
                // EXPANDED STATE CONTENT
                //---------------------------------------------
                if (widget.isExpanded) ...[
                  if (overview.fullRecommendation.isEmpty)
                    _buildShimmerLoadingState()
                  else ...[
                    const SizedBox(height: 8),
                    const Divider(height: 24, color: AppColors.divider, thickness: 0.5),

                    // 1. Best Match
                    _buildSectionHeader('🏆', 'Best Match'),
                    const SizedBox(height: 6),
                    Text(
                      '${overview.bestMatch.title} • ${overview.bestMatch.priceDisplay} • ${widget.results.isNotEmpty ? widget.results.first.location : "Gurgaon"}',
                      style: AppTextStyles.titleSmall.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      overview.bestMatchReason,
                      style: AppTextStyles.bodyMedium,
                    ),

                    const Divider(height: 24, color: AppColors.divider, thickness: 0.5),

                    // 2. Runner-Up
                    _buildSectionHeader('🥈', 'Runner-Up'),
                    const SizedBox(height: 6),
                    if (widget.results.length >= 2) ...[
                      Text(
                        '${widget.results[1].bhk} BHK in ${widget.results[1].location.split(',')[0]} • ₹${(widget.results[1].price / 100000).toStringAsFixed(0)}L',
                        style: AppTextStyles.titleSmall.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        overview.fullRecommendation['RUNNER_UP']?.isNotEmpty == true
                            ? overview.fullRecommendation['RUNNER_UP']!
                            : 'Highly rated second choice matching your preferences.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ] else
                      const Text(
                        'No runner-up available matching the filter conditions.',
                        style: AppTextStyles.bodyMedium,
                      ),

                    const Divider(height: 24, color: AppColors.divider, thickness: 0.5),

                    // 3. Pros
                    _buildSectionHeader('✅', 'Pros'),
                    const SizedBox(height: 6),
                    _buildBulletList(
                      overview.fullRecommendation['PROS'] ?? 'Matches primary parameters',
                      AppColors.success,
                    ),

                    const Divider(height: 24, color: AppColors.divider, thickness: 0.5),

                    // 4. Cons
                    _buildSectionHeader('❌', 'Cons'),
                    const SizedBox(height: 6),
                    _buildBulletList(
                      overview.fullRecommendation['CONS'] ?? 'No major negative factors identified',
                      AppColors.error,
                    ),

                    const Divider(height: 24, color: AppColors.divider, thickness: 0.5),

                    // 5. Investment Score
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('📈', 'Investment Score'),
                        _buildRatingChip(
                          overview.fullRecommendation['INVESTMENT']?.split('\n').first ?? 'Medium',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      overview.fullRecommendation['INVESTMENT']?.contains('\n') == true
                          ? overview.fullRecommendation['INVESTMENT']!.substring(
                              overview.fullRecommendation['INVESTMENT']!.indexOf('\n') + 1)
                          : overview.fullRecommendation['INVESTMENT'] ?? 'Good asset values and high growth potential.',
                      style: AppTextStyles.bodyMedium,
                    ),

                    const Divider(height: 24, color: AppColors.divider, thickness: 0.5),

                    // 6. Rental Yield
                    _buildSectionHeader('💰', 'Rental Yield'),
                    const SizedBox(height: 6),
                    Text(
                      overview.fullRecommendation['RENTAL_YIELD'] ?? 'Estimated 3% - 4.5% annual yield based on historical sector stats.',
                      style: AppTextStyles.bodyMedium,
                    ),

                    const Divider(height: 24, color: AppColors.divider, thickness: 0.5),

                    // 7. Family Suitability
                    _buildSectionHeader('👨‍👩‍👧', 'Family Suitability'),
                    const SizedBox(height: 6),
                    Text(
                      overview.fullRecommendation['FAMILY'] ?? 'Great safety records, multiple nearby schools and parks.',
                      style: AppTextStyles.bodyMedium,
                    ),

                    const Divider(height: 24, color: AppColors.divider, thickness: 0.5),

                    // 8. Future Appreciation
                    _buildSectionHeader('📅', 'Future Appreciation'),
                    const SizedBox(height: 6),
                    Text(
                      overview.fullRecommendation['APPRECIATION'] ?? 'High infrastructure growth expectations in the region.',
                      style: AppTextStyles.bodyMedium,
                    ),

                    const Divider(height: 24, color: AppColors.divider, thickness: 0.5),

                    // 9. Nearby Schools
                    _buildSectionHeader('🏫', 'Nearby Schools'),
                    const SizedBox(height: 6),
                    Text(
                      widget.results.isNotEmpty
                          ? widget.results.first.nearbySchools.join(', ')
                          : 'No school lists parsed.',
                      style: AppTextStyles.bodyMedium,
                    ),

                    const Divider(height: 24, color: AppColors.divider, thickness: 0.5),

                    // 10. Nearby Hospitals
                    _buildSectionHeader('🏥', 'Nearby Hospitals'),
                    const SizedBox(height: 6),
                    Text(
                      widget.results.isNotEmpty
                          ? widget.results.first.nearbyHospitals.join(', ')
                          : 'No hospital lists parsed.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ],

                //---------------------------------------------
                // Footer: Expand / Collapse analysis
                //---------------------------------------------
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: widget.onExpand,
                    child: Text(
                      widget.isExpanded ? 'Collapse ↑' : 'Expand full analysis ↓',
                      style: AppTextStyles.labelMedium,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MatchScoreBadge extends StatelessWidget {
  final double score;

  const MatchScoreBadge({super.key, required this.score});

  Color _getMatchScoreColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getMatchScoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
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
          fontSize: 10,
        ),
      ),
    );
  }
}
