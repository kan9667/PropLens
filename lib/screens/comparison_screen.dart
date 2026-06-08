import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/comparison_provider.dart';
import '../data/types.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final comparisonProvider = context.watch<ComparisonProvider>();
    final properties = comparisonProvider.selectedProperties;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compare Properties',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear comparison',
            onPressed: () {
              comparisonProvider.clearSelection();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: properties.isEmpty
          ? const Center(
              child: Text('No properties selected for comparison.'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comparing ${properties.length} Properties',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Table(
                      defaultColumnWidth: const FixedColumnWidth(180),
                      border: TableBorder.all(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                        width: 1,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      children: [
                        //---------------------------------------------
                        // Image Row
                        //---------------------------------------------
                        TableRow(
                          children: [
                            const TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  'Property',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            ...properties.map((p) => TableCell(
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                    child: Image.network(
                                      p.imageUrl,
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, err, stack) => Container(
                                        height: 100,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.home, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'ID: ${p.id}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            // Fill remaining columns if fewer than 3 properties
                            ...List.generate(
                              3 - properties.length,
                              (_) => const TableCell(child: SizedBox.shrink()),
                            ),
                          ].take(4).toList(),
                        ),
                        //---------------------------------------------
                        // Price Row
                        //---------------------------------------------
                        _buildComparisonRow('Price', properties, (p) => '₹${p.price}'),
                        //---------------------------------------------
                        // BHK Row
                        //---------------------------------------------
                        _buildComparisonRow('BHK', properties, (p) => '${p.bhk} BHK'),
                        //---------------------------------------------
                        // Area Row
                        //---------------------------------------------
                        _buildComparisonRow('Area', properties, (p) => '${p.area} sq ft'),
                        //---------------------------------------------
                        // Furnishing Row
                        //---------------------------------------------
                        _buildComparisonRow('Furnishing', properties, (p) => p.furnishing),
                        //---------------------------------------------
                        // Amenities Row
                        //---------------------------------------------
                        _buildComparisonRow('Amenities', properties, (p) => p.amenities.join(', ')),
                        //---------------------------------------------
                        // Nearby Schools Row
                        //---------------------------------------------
                        _buildComparisonRow('Nearby Schools', properties, (p) => p.nearbySchools.join(', ')),
                        //---------------------------------------------
                        // Nearby Hospitals Row
                        //---------------------------------------------
                        _buildComparisonRow('Nearby Hospitals', properties, (p) => p.nearbyHospitals.join(', ')),
                        //---------------------------------------------
                        // Parking Row
                        //---------------------------------------------
                        _buildComparisonRow('Parking Slots', properties, (p) => '${p.parking}'),
                        //---------------------------------------------
                        // Age Row
                        //---------------------------------------------
                        _buildComparisonRow('Building Age', properties, (p) => '${p.ageYears} years'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  TableRow _buildComparisonRow(
    String label,
    List<Property> properties,
    String Function(Property) valueExtractor,
  ) {
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        ...properties.map((p) => TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(valueExtractor(p)),
              ),
            )),
        ...List.generate(
          3 - properties.length,
          (_) => const TableCell(child: SizedBox.shrink()),
        ),
      ].take(4).toList(),
    );
  }
}
