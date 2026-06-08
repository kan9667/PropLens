import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'property_card.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class PropertyGrid extends StatelessWidget {
  const PropertyGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>(); //listen for changes
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    // Calculate responsive column count and aspect ratio to prevent overflows
    int crossAxisCount = 2;
    double childAspectRatio = 0.65; // Mobile default (taller to avoid overflow)

    if (width > 1200) {
      crossAxisCount = 4;
      childAspectRatio = 0.8;
    } else if (width > 800) {
      crossAxisCount = 3;
      childAspectRatio = 0.72;
    } else if (width < 360) {
      // Extremely small devices
      crossAxisCount = 1;
      childAspectRatio = 1.2;
    }

    if (provider.isLoading) {
      return Shimmer.fromColors(
        baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4, // Show 4 skeleton cards
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const SizedBox(
                height: 200,
              ),
            );
          },
        ),
      );
    }

    return GridView.builder( //creates item only when needed - lazy loading
      padding: const EdgeInsets.all(12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.results.length, 
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount( //controls layout
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio, //controls card space
        crossAxisSpacing: 10, //horizontal spacing
        mainAxisSpacing: 10, //vertical spacing
      ),
      itemBuilder: (context, index) { 
        return PropertyCard(
          property: provider.results[index],
        );
      },
    );
  }
}