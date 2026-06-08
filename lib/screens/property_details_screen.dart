import 'package:flutter/material.dart';
import '../data/types.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final Property property;

  const PropertyDetailsScreen({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${property.bhk} BHK Property',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            //--------------------------------------------------
            // IMAGE PLACEHOLDER
            //--------------------------------------------------

            ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: Image.network(
    property.imageUrl,
    height: 220,
    width: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return Container(
        height: 220,
        color: Colors.grey.shade300,
        child: const Icon(
          Icons.home,
          size: 80,
        ),
      );
    },
  ),
),

            const SizedBox(height: 20),

            //--------------------------------------------------
            // PRICE
            //--------------------------------------------------

            Text(
              '₹${property.price}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              property.location,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const Divider(height: 30),

            //--------------------------------------------------
            // BASIC INFO
            //--------------------------------------------------

            Text(
              'Property Information',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),

            const SizedBox(height: 12),

            Text('BHK: ${property.bhk}'),
            Text('Area: ${property.area} sq ft'),
            Text('Floor: ${property.floor}'),
            Text(
              'Total Floors: ${property.totalFloors}',
            ),
            Text(
              'Property Age: ${property.ageYears} years',
            ),
            Text(
              'Parking: ${property.parking}',
            ),
            Text(
              'Furnishing: ${property.furnishing}',
            ),

            const Divider(height: 30),

            //--------------------------------------------------
            // AMENITIES
            //--------------------------------------------------

            Text(
              'Amenities',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              children: property.amenities
                  .map(
                    (a) => Chip(
                      label: Text(a),
                    ),
                  )
                  .toList(),
            ),

            const Divider(height: 30),

            //--------------------------------------------------
            // SCHOOLS
            //--------------------------------------------------

            Text(
              'Nearby Schools',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),

            const SizedBox(height: 10),

            ...property.nearbySchools.map(
              (school) => ListTile(
                leading:
                    const Icon(Icons.school),
                title: Text(school),
              ),
            ),

            const Divider(height: 30),

            //--------------------------------------------------
            // HOSPITALS
            //--------------------------------------------------

            Text(
              'Nearby Hospitals',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),

            const SizedBox(height: 10),

            ...property.nearbyHospitals.map(
              (hospital) => ListTile(
                leading:
                    const Icon(Icons.local_hospital),
                title: Text(hospital),
              ),
            ),

            const Divider(height: 30),

            //--------------------------------------------------
            // MATCH REASONS
            //--------------------------------------------------

            if (property.matchReasons != null)
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    'Why Recommended?',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),

                  const SizedBox(height: 10),

                  ...property.matchReasons!.map(
                    (reason) => Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 6,
                      ),

                      child: Text(
                        '✓ $reason',
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}