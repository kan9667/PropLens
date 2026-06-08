// Responsible for ranking properties

import '../data/types.dart';
import 'query_parser.dart';

class SearchService {
  static List<Property> search({
    required ParsedQuery query,
    required List<Property> properties,
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
