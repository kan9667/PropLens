

// final -> means this variable can be assigned once but cannot be changed later
//          prevents accidental modification of data

// required -> must provide value, compiler error if missing


class Property {
  final String id;
  final String imageUrl;
  final int bhk;
  final int area;
  final String location;
  final int sector;
  final int price;

  final List<String> amenities;

  final String furnishing;

  final int ageYears;

  final int floor;
  final int totalFloors;

  final List<String> nearbySchools;
  final List<String> nearbyHospitals;

  final int parking;

  double? matchScore;    // ? means it can contain null, matchscore is nullable 
  List<String>? matchReasons;

  Property({
    required this.id,
    required this.imageUrl,
    required this.bhk,
    required this.area,
    required this.location,
    required this.sector,
    required this.price,
    required this.amenities,
    required this.furnishing,
    required this.ageYears,
    required this.floor,
    required this.totalFloors,
    required this.nearbySchools,
    required this.nearbyHospitals,
    required this.parking,
    this.matchScore,
    this.matchReasons,
  });
}



class MatchResult {
  final Property property;

  final double score;

  final List<String> reasons;

  MatchResult({
    required this.property,
    required this.score,
    required this.reasons,
  });
}

// Type alias to match exact PropertyModel signature requirement
typedef PropertyModel = Property;

enum AiState { loading, loaded, error }

class BestMatch {
  final String title;
  final String priceDisplay;
  final double matchScore;

  const BestMatch({
    required this.title,
    required this.priceDisplay,
    required this.matchScore,
  });
}

class AiOverview {
  final BestMatch bestMatch;
  final List<String> quickInsights;
  final String fullAnalysis;
  final String bestMatchReason;
  final Map<String, String> fullRecommendation;

  const AiOverview({
    required this.bestMatch,
    required this.quickInsights,
    required this.fullAnalysis,
    required this.bestMatchReason,
    required this.fullRecommendation,
  });
}