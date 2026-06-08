//stores app state- Provider provides centralized state management through ChangeNotifier. It allows widgets to reactively rebuild when state changes without passing data through multiple widget levels.


import 'package:flutter/material.dart';
import '../data/types.dart';
import '../data/properties.dart';
import '../services/search_service.dart';

class AppProvider extends ChangeNotifier { //fluttr class that provides an observable pattern, allows widgets to listen for statechanges and rebuild when notify listener is called
  AppProvider() {
  results = List.from(mockProperties);
  }

  String query = '';

  List<Property> results = [];

  bool isLoading = false;

  Property? selectedProperty;

  void updateQuery(String newQuery) {
  query = newQuery;

  results = SearchService.search(
    query: query,
    properties: mockProperties,
  );

  notifyListeners(); //updates all listening widgets
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