import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/types.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

class _OverviewSection {
  final String icon;
  final String title;
  final String body;
  final bool isRating;
  final String? ratingLine;

  const _OverviewSection({
    required this.icon,
    required this.title,
    required this.body,
    this.isRating = false,
    this.ratingLine,
  });
}

class AiOverviewWidget extends StatefulWidget {
  final List<PropertyModel> results;
  final String userQuery;
  final AiOverview? overview;
  final AiState state;
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

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

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
                  _shimmerAnim.value.clamp(0.0, 1.0),
                  1.0,
                ],
              ),
            ),
          ),
        );
      },
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
        child: Text(text.trim(), style: AppTextStyles.bodyMedium),
      );
    }

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4, right: 8),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
              ),
              Expanded(child: Text(item, style: AppTextStyles.bodyMedium)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String icon, String title) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
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
        style: TextStyle(color: chipColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<_OverviewSection> _buildSections(AiOverview overview) {
    final rec = overview.fullRecommendation;
    final sections = <_OverviewSection>[];

    final bestReason = rec['BEST_MATCH'] ?? overview.bestMatchReason;
    if (_hasText(bestReason)) {
      sections.add(_OverviewSection(
        icon: '🏆',
        title: 'Best Match',
        body: '${overview.bestMatch.title} • ${overview.bestMatch.priceDisplay}\n$bestReason',
      ));
    }

    if (widget.results.length >= 2 && _hasText(rec['RUNNER_UP'])) {
      final runner = widget.results[1];
      sections.add(_OverviewSection(
        icon: '🥈',
        title: 'Runner-Up',
        body:
            '${runner.bhk} BHK in ${runner.location.split(',').first.trim()} • ₹${(runner.price / 100000).toStringAsFixed(0)}L\n${rec['RUNNER_UP']}',
      ));
    }

    if (_hasText(rec['PROS'])) {
      sections.add(_OverviewSection(icon: '✅', title: 'Pros', body: rec['PROS']!));
    }
    if (_hasText(rec['CONS'])) {
      sections.add(_OverviewSection(icon: '❌', title: 'Cons', body: rec['CONS']!));
    }
    if (_hasText(rec['INVESTMENT'])) {
      sections.add(_OverviewSection(
        icon: '📈',
        title: 'Investment Score',
        body: rec['INVESTMENT']!.contains('\n')
            ? rec['INVESTMENT']!.substring(rec['INVESTMENT']!.indexOf('\n') + 1)
            : rec['INVESTMENT']!,
        isRating: true,
        ratingLine: rec['INVESTMENT']!.split('\n').first,
      ));
    }
    if (_hasText(rec['RENTAL_YIELD'])) {
      sections.add(_OverviewSection(icon: '💰', title: 'Rental Yield', body: rec['RENTAL_YIELD']!));
    }
    if (_hasText(rec['FAMILY'])) {
      sections.add(_OverviewSection(icon: '👨‍👩‍👧', title: 'Family Suitability', body: rec['FAMILY']!));
    }
    if (_hasText(rec['APPRECIATION'])) {
      sections.add(_OverviewSection(icon: '📅', title: 'Future Appreciation', body: rec['APPRECIATION']!));
    }

    final schools = rec['SCHOOLS'] ??
        (widget.results.isNotEmpty && widget.results.first.nearbySchools.isNotEmpty
            ? widget.results.first.nearbySchools.join(', ')
            : null);
    if (_hasText(schools)) {
      sections.add(_OverviewSection(icon: '🏫', title: 'Nearby Schools', body: schools!));
    }

    final hospitals = rec['HOSPITALS'] ??
        (widget.results.isNotEmpty && widget.results.first.nearbyHospitals.isNotEmpty
            ? widget.results.first.nearbyHospitals.join(', ')
            : null);
    if (_hasText(hospitals)) {
      sections.add(_OverviewSection(icon: '🏥', title: 'Nearby Hospitals', body: hospitals!));
    }

    return sections;
  }

  Widget _buildSectionBody(_OverviewSection section) {
    if (section.title == 'Pros' || section.title == 'Cons') {
      return _buildBulletList(
        section.body,
        section.title == 'Pros' ? AppColors.success : AppColors.error,
      );
    }
    return Text(section.body, style: AppTextStyles.bodyMedium);
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
          border: const Border(left: BorderSide(color: AppColors.primary, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🤖 AI Overview', style: AppTextStyles.titleMedium),
                  const Spacer(),
                  if (widget.state == AiState.loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  if (widget.state == AiState.loaded)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    ),
                ],
              ),
              const SizedBox(height: 12),

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
                      child: Text('AI analysis unavailable', style: AppTextStyles.bodyMedium),
                    ),
                    TextButton(
                      onPressed: () => context.read<AppProvider>().generateAiOverview(),
                      child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ] else if (widget.state == AiState.loaded && overview != null) ...[
                Text(
                  'Found ${widget.results.length} matching properties',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),

                if (_hasText(overview.fullAnalysis)) ...[
                  Text(
                    overview.fullAnalysis,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                    maxLines: widget.isExpanded ? null : 2,
                    overflow: widget.isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],

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
                            const Text('Best Match', style: AppTextStyles.labelSmall),
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
                            Text(overview.bestMatch.priceDisplay, style: AppTextStyles.titleMediumBold),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      MatchScoreBadge(score: overview.bestMatch.matchScore),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                if (overview.quickInsights.isNotEmpty)
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

                if (widget.isExpanded) ...[
                  Builder(
                    builder: (context) {
                      final sections = _buildSections(overview);
                      if (sections.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildShimmerBar(0.8, 12),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppColors.divider, thickness: 0.5),
                          for (int i = 0; i < sections.length; i++) ...[
                            if (i > 0) const Divider(height: 24, color: AppColors.divider, thickness: 0.5),
                            if (sections[i].isRating && _hasText(sections[i].ratingLine))
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSectionHeader(sections[i].icon, sections[i].title),
                                  _buildRatingChip(sections[i].ratingLine!),
                                ],
                              )
                            else
                              _buildSectionHeader(sections[i].icon, sections[i].title),
                            const SizedBox(height: 6),
                            _buildSectionBody(sections[i]),
                          ],
                        ],
                      );
                    },
                  ),
                ],

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
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '${(score * 100).toStringAsFixed(0)}% Match',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
