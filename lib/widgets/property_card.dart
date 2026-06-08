// Property Card
// Displays a single property in a visually attractive card.

import 'package:flutter/material.dart';
import '../data/types.dart';
import '../screens/property_details_screen.dart';

class PropertyCard extends StatelessWidget {
  // Property data passed from parent widget
  final Property property;

  const PropertyCard({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PropertyDetailsScreen(
          property: property,
        ),
      ),
    );
  },

  child: Card(
      // Shadow depth
      elevation: 3,

      // Space outside card
      margin: const EdgeInsets.all(8),

      child: Padding(
        // Space inside card
        padding: const EdgeInsets.all(12),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            //--------------------------------------------------
            // PROPERTY IMAGE PLACEHOLDER
            //--------------------------------------------------
            Container(
              height: 120,
              width: double.infinity,

              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  property.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.home,
                        size: 40,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            //--------------------------------------------------
            // BHK + AREA
            //--------------------------------------------------
            Text(
              '${property.bhk} BHK • ${property.area} sq ft',

              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 6),

            //--------------------------------------------------
            // LOCATION
            //--------------------------------------------------
            Text(
              property.location,
            ),

            const SizedBox(height: 6),

            //--------------------------------------------------
            // PRICE
            //--------------------------------------------------
            Text(
              '₹${property.price}',

              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            //--------------------------------------------------
            // MATCH SCORE
            //--------------------------------------------------
            if (property.matchScore != null)
              Text(
                'Match: ${(property.matchScore! * 100).toStringAsFixed(0)}%',

                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 6),

            //--------------------------------------------------
            // FURNISHING STATUS
            //--------------------------------------------------
            Text(
              property.furnishing,

              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 6),

            //--------------------------------------------------
            // AMENITIES
            //--------------------------------------------------
            Wrap(
              spacing: 4,

              children: property.amenities
                  .take(3) // Show only first 3 amenities
                  .map(
                    (amenity) => Chip(
                      label: Text(
                        amenity,

                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            //--------------------------------------------------
            // MATCH REASONS (future AI explanations)
            //--------------------------------------------------
            if (property.matchReasons != null &&
                property.matchReasons!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: property.matchReasons!
                      .map(
                        (reason) => Text(
                          '✓ $reason',

                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    ),
    );
    
  }
}