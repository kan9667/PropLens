// Responsible for ranking properties

import '../data/types.dart';
import 'query_parser.dart';

class SearchService {
  static bool _matchesFilters(Property property, Map<String, String> filters) {
    for (final entry in filters.entries) {
      final category = entry.key;
      final value = entry.value;

      if (category == 'BHK Type') {
        if (value == '1BHK' && property.bhk != 1) return false;
        if (value == '2BHK' && property.bhk != 2) return false;
        if (value == '3BHK' && property.bhk != 3) return false;
        if (value == '4BHK+' && property.bhk < 4) return false;
      } else if (category == 'Budget') {
        if (value == 'Under 50L' && property.price > 5000000) return false;
        if (value == '50–80L' && (property.price < 5000000 || property.price > 8000000)) return false;
        if (value == '80L–1Cr' && (property.price < 8000000 || property.price > 10000000)) return false;
        if (value == 'Above 1Cr' && property.price <= 10000000) return false;
      } else if (category == 'Locality') {
        final loc = property.location.toLowerCase();
        if (value == 'Sector 50' && !loc.contains('sector 50')) return false;
        if (value == 'Sector 57' && !loc.contains('sector 57')) return false;
        if (value == 'DLF Phase 1' && !loc.contains('dlf phase 1')) return false;
        if (value == 'Golf Course Road' && !loc.contains('golf course')) return false;
        if (value == 'Sohna Road' && !loc.contains('sohna road')) return false;
      } else if (category == 'Possession') {
        if (value == 'Ready to Move' && property.ageYears <= 0) return false;
        if (value == 'Within 1 Year' && property.ageYears > 1) return false;
        if (value == 'Under Construction' && property.ageYears != 0) return false;
      } else if (category == 'Amenities') {
        if (value == 'Near Metro' && !property.amenities.any((a) => a.toLowerCase().contains('metro'))) return false;
        if (value == 'Near School' && property.nearbySchools.isEmpty) return false;
        if (value == 'Gated Society' && !property.amenities.any((a) => a.toLowerCase().contains('gated') || a.toLowerCase().contains('security') || a.toLowerCase().contains('park'))) return false;
        if (value == 'With Parking' && property.parking < 1) return false;
        if (value == 'East Facing' && !property.amenities.any((a) => a.toLowerCase().contains('sunlight') || a.toLowerCase().contains('east'))) return false;
      }
    }
    return true;
  }

  static List<Property> search({
    required ParsedQuery query,
    required List<Property> properties,
    Map<String, String>? activeFilters,
  }) {
    final List<Property> results = [];

    // Calculate dynamic maxPossibleScore based on filters present in the query
    // BHK match = +40
    // Budget match = +30
    // Location match = +20
    // Amenity match = +15 each
    // Furnishing match = +15
    // Landmark match = +15 (if specified in search)
    double maxPossibleScore = 0;
    if (query.bhk != null) maxPossibleScore += 40;
    if (query.maxBudget != null) maxPossibleScore += 30;
    if (query.location != null) maxPossibleScore += 20;
    if (query.landmark != null) maxPossibleScore += 15;
    if (query.amenities.isNotEmpty) maxPossibleScore += query.amenities.length * 15;
    if (query.furnished != null) maxPossibleScore += 15;

    for (final property in properties) {
      if (activeFilters != null && activeFilters.isNotEmpty) {
        if (!_matchesFilters(property, activeFilters)) {
          continue;
        }
      }

      double score = 0;
      List<String> reasons = [];

      //--------------------------------------------------
      // BHK MATCH (Hard Filter)
      //--------------------------------------------------
      if (query.bhk != null) {
        if (property.bhk == query.bhk) {
          score += 40;
          reasons.add('Matches ${query.bhk} BHK requirement');
        } else {
          continue; // Exclude properties that don't match the BHK
        }
      }

      //--------------------------------------------------
      // BUDGET MATCH (Hard Filter)
      //--------------------------------------------------
      if (query.maxBudget != null) {
        if (property.price <= query.maxBudget!) {
          score += 30;
          reasons.add('Within your budget');
        } else {
          continue; // Exclude properties that exceed budget
        }
      }

      //--------------------------------------------------
      // LOCATION MATCH (Hard Filter)
      //--------------------------------------------------
      if (query.location != null) {
        if (property.location
            .toLowerCase()
            .contains(
              query.location!.toLowerCase(),
            )) {
          score += 20;
          reasons.add(
            'Located in ${query.location}',
          );
        } else {
          continue; // Exclude properties in other locations
        }
      }

      //--------------------------------------------------
      // LANDMARK MATCH (Soft Filter / Preference)
      //--------------------------------------------------
      if (query.landmark != null) {
        final landmarkLower = query.landmark!.toLowerCase().trim();
        final matchesSchool = property.nearbySchools.any(
          (school) => school.toLowerCase().contains(landmarkLower),
        );
        final matchesHospital = property.nearbyHospitals.any(
          (hospital) => hospital.toLowerCase().contains(landmarkLower),
        );

        if (matchesSchool || matchesHospital) {
          score += 15; // +15 score for matching landmark/places
          reasons.add('Near landmark: ${query.landmark}');
        }
      }

      //--------------------------------------------------
      // AMENITIES MATCH (Soft Filter / Preference)
      //--------------------------------------------------
      for (final amenity in query.amenities) {
        final queryAmenity = amenity.toLowerCase().trim();
        final matchedAmenity = property.amenities.firstWhere(
          (a) {
            final propAmenity = a.toLowerCase().trim();
            return propAmenity.contains(queryAmenity) || queryAmenity.contains(propAmenity);
          },
          orElse: () => '',
        );

        if (matchedAmenity.isNotEmpty) {
          score += 15; // +15 score for each matched amenity
          // Capitalize first letter of matched amenity for cleaner UI display
          final capitalizedAmenity = '${matchedAmenity[0].toUpperCase()}${matchedAmenity.substring(1)}';
          reasons.add('Has $capitalizedAmenity');
        }
      }

      //--------------------------------------------------
      // FURNISHING MATCH (Soft Filter / Preference)
      //--------------------------------------------------
      if (query.furnished != null) {
        final furnishing = property.furnishing.toLowerCase().trim();
        if (query.furnished == true) {
          if (furnishing == 'furnished') {
            score += 15; // +15 score if matches furnishing
            reasons.add('Furnished as requested');
          }
        } else {
          if (furnishing == 'unfurnished') {
            score += 15; // +15 score if matches unfurnished
            reasons.add('Unfurnished as requested');
          }
        }
      }

      //--------------------------------------------------
      // STORE SCORE (Normalized between 0.0 and 1.0)
      //--------------------------------------------------
      if (maxPossibleScore > 0) {
        property.matchScore = score / maxPossibleScore;
      } else {
        property.matchScore = null;
      }

      property.matchReasons = reasons;
      results.add(property);
    }

    //--------------------------------------------------
    // SORT BEST MATCHES FIRST
    //--------------------------------------------------
    results.sort(
      (a, b) =>
          (b.matchScore ?? 0)
              .compareTo(a.matchScore ?? 0),
    );

    return results;
  }
}
