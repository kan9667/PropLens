import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/types.dart';
import '../screens/property_details_screen.dart';
import '../providers/app_provider.dart';
import '../providers/comparison_provider.dart';

class PropertyCard extends StatelessWidget {
  final Property property;

  const PropertyCard({
    super.key,
    required this.property,
  });

  Color _getMatchScoreColor(double score) {
    final pct = score * 100;
    if (pct >= 80) return Colors.green.shade600;
    if (pct >= 60) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final comparisonProvider = context.watch<ComparisonProvider>();
    final isFavorite = appProvider.isFavorite(property.id);
    final isSelectedForCompare = comparisonProvider.isSelected(property.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shadowColor: Colors.blue.withAlpha(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailsScreen(
                property: property,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //--------------------------------------------------
            // PROPERTY IMAGE + ACTIONS OVERLAY
            //--------------------------------------------------
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.5,
                  child: Image.network(
                    property.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                // Favorites Icon Button Overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        appProvider.toggleFavorite(property.id);
                      },
                    ),
                  ),
                ),
                // Compare Checkbox Overlay
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Theme(
                          data: Theme.of(context).copyWith(
                            unselectedWidgetColor: Colors.white,
                          ),
                          child: Checkbox(
                            value: isSelectedForCompare,
                            activeColor: Colors.blue,
                            checkColor: Colors.white,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            onChanged: (val) {
                              comparisonProvider.toggleSelection(property);
                            },
                          ),
                        ),
                        const Text(
                          'Compare',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //--------------------------------------------------
                  // BHK + AREA
                  //--------------------------------------------------
                  Text(
                    '${property.bhk} BHK • ${property.area} sq ft',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),

                  //--------------------------------------------------
                  // LOCATION
                  //--------------------------------------------------
                  Text(
                    property.location,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  //--------------------------------------------------
                  // PRICE & MATCH BADGE Row
                  //--------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${(property.price / 100000).toStringAsFixed(0)}L',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      if (property.matchScore != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getMatchScoreColor(property.matchScore!).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getMatchScoreColor(property.matchScore!),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${(property.matchScore! * 100).toStringAsFixed(0)}% Match',
                            style: TextStyle(
                              color: _getMatchScoreColor(property.matchScore!),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  //--------------------------------------------------
                  // AMENITIES
                  //--------------------------------------------------
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: property.amenities
                        .take(3)
                        .map(
                          (amenity) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              amenity,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}