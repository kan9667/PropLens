//stores app state- Provider provides centralized state management through ChangeNotifier. It allows widgets to reactively rebuild when state changes without passing data through multiple widget levels.


import 'package:flutter/material.dart';
import '../data/types.dart';
import '../data/properties.dart';
import '../services/search_service.dart';
import '../services/query_parser.dart';

class AppProvider extends ChangeNotifier { //fluttr class that provides an observable pattern, allows widgets to listen for statechanges and rebuild when notify listener is called
  AppProvider() {
  results = List.from(mockProperties);
  }

  String query = '';

  List<Property> results = [];

  bool isLoading = false;

  Property? selectedProperty;

  Future<void> updateQuery(String newQuery) async {
    query = newQuery;

    if (newQuery.trim().isEmpty) {
      // Reset results to show all properties without active match scores
      results = List.from(mockProperties);
      for (final p in results) {
        p.matchScore = null;
        p.matchReasons = null;
      }
      notifyListeners();
      return;
    }

    setLoading(true);

    try {
      final parsedQuery =
          await QueryParser.parse(newQuery);

      results = SearchService.search(
        query: parsedQuery,
        properties: mockProperties,
      );
    } catch (e) {
      print('Search Error: $e');

      results = [];
    }

    setLoading(false);

    notifyListeners();
  }
  

  void updateResults(List<Property> newResults) {
    results = newResults;

    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;

    notifyListeners();
  }

  void selectProperty(Property property) {
    selectedProperty = property;

    notifyListeners();
  }
}