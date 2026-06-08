import 'package:flutter/material.dart';
import '../data/types.dart';

class ComparisonProvider extends ChangeNotifier {
  final List<Property> _selectedProperties = [];

  List<Property> get selectedProperties => _selectedProperties;

  int get count => _selectedProperties.length;

  void toggleSelection(Property property) {
    final index = _selectedProperties.indexWhere((p) => p.id == property.id);
    if (index >= 0) {
      _selectedProperties.removeAt(index);
    } else {
      // Limit comparison to 3 properties side-by-side
      if (_selectedProperties.length < 3) {
        _selectedProperties.add(property);
      }
    }
    notifyListeners();
  }

  bool isSelected(String id) {
    return _selectedProperties.any((p) => p.id == id);
  }

  void clearSelection() {
    _selectedProperties.clear();
    notifyListeners();
  }
}
