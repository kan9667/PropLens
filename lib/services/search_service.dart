//responsible for ranking

import '../data/types.dart';

class SearchService {
  static List<Property> search({ // static method let us call search wiithout creating an object
    required String query,
    required List<Property> properties,
  }) {
    if (query.trim().isEmpty) {
      return properties;
    }

    final lowerQuery = query.toLowerCase();

    return properties.where((property) { //filtering 
      return property.location
              .toLowerCase()
              .contains(lowerQuery) ||
          '${property.bhk} bhk'
              .contains(lowerQuery);
    }).toList();
  }
}