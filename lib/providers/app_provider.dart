//stores app state- Provider provides centralized state management through ChangeNotifier. It allows widgets to reactively rebuild when state changes without passing data through multiple widget levels.


import 'package:flutter/material.dart';
import '../data/types.dart';
import '../data/properties.dart';
import '../services/search_service.dart';
import '../services/query_parser.dart';
import '../services/property_advisor_service.dart';
import '../services/llm_service.dart';

class AppProvider extends ChangeNotifier { //fluttr class that provides an observable pattern, allows widgets to listen for statechanges and rebuild when notify listener is called
  AppProvider() {
    results = List.from(mockProperties);
  }

  String query = '';

  List<Property> results = [];

  bool isLoading = false;

  Property? selectedProperty;

  // AI Property Advisor State
  String aiAnswer = '';
  bool isAiLoading = false;

  // AI Overview State
  AiOverview? aiOverview;
  AiState aiOverviewState = AiState.loaded;

  // Favorites State
  final Set<String> _favoriteIds = {};
  Set<String> get favoriteIds => _favoriteIds;

  void toggleFavorite(String propertyId) {
    if (_favoriteIds.contains(propertyId)) {
      _favoriteIds.remove(propertyId);
    } else {
      _favoriteIds.add(propertyId);
    }
    notifyListeners();
  }

  bool isFavorite(String propertyId) {
    return _favoriteIds.contains(propertyId);
  }

  // Active Filters state
  final Map<String, String> _activeFilters = {};
  Map<String, String> get activeFilters => _activeFilters;

  void setFilter(String category, String value) {
    _activeFilters[category] = value;
    notifyListeners();
    updateQuery(query);
  }

  void clearFilter(String category) {
    _activeFilters.remove(category);
    notifyListeners();
    updateQuery(query);
  }

  void resetFilters() {
    _activeFilters.clear();
    notifyListeners();
    updateQuery(query);
  }

  Future<void> updateQuery(String newQuery) async {
    query = newQuery;
    aiAnswer = ''; // Clear advisor answer when search context changes
    aiOverview = null;

    if (newQuery.trim().isEmpty && _activeFilters.isEmpty) {
      // Reset results to show all properties without active match scores
      results = List.from(mockProperties);
      for (final p in results) {
        p.matchScore = null;
        p.matchReasons = null;
      }
      aiOverviewState = AiState.loaded;
      notifyListeners();
      return;
    }

    setLoading(true);

    try {
      // Parse natural language query if not empty, otherwise use empty query
      final parsedQuery = newQuery.trim().isNotEmpty 
          ? await QueryParser.parse(newQuery)
          : const ParsedQuery();

      results = SearchService.search(
        query: parsedQuery,
        properties: mockProperties,
        activeFilters: _activeFilters,
      );

      // Automatically generate overview card details
      generateAiOverview();
    } catch (e) {
      debugPrint('Search Error: $e');
      results = [];
      aiOverviewState = AiState.error;
    }

    setLoading(false);
    notifyListeners();
  }

  Future<void> generateAiOverview() async {
    if (query.trim().isEmpty && _activeFilters.isEmpty) return;

    aiOverviewState = AiState.loading;
    notifyListeners();

    try {
      final overview = await LlmService.generateOverview(
        results: results,
        query: query,
        activeFilters: _activeFilters,
      );
      aiOverview = overview;
      aiOverviewState = AiState.loaded;
      notifyListeners();

      // Load detailed analytical sections in the background
      if (results.isNotEmpty) {
        final fullRec = await LlmService.generateFullRecommendation(
          results: results,
          query: query,
          activeFilters: _activeFilters,
        );
        final fallback = LlmService.buildFallbackRecommendation(
          results: results,
          query: query,
          activeFilters: _activeFilters,
        );
        final merged = LlmService.mergeRecommendations(fullRec, fallback);

        aiOverview = AiOverview(
          bestMatch: overview.bestMatch,
          quickInsights: overview.quickInsights,
          fullAnalysis: overview.fullAnalysis,
          bestMatchReason: merged['BEST_MATCH'] ?? overview.bestMatchReason,
          fullRecommendation: merged,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Overview generation error: $e');
      final fallback = LlmService.buildFallbackRecommendation(
        results: results,
        query: query,
        activeFilters: _activeFilters,
      );
      if (fallback.isNotEmpty) {
        aiOverview = AiOverview(
          bestMatch: BestMatch(
            title: '${results.first.bhk} BHK in ${results.first.location.split(',').first}',
            priceDisplay: results.first.priceDisplay,
            matchScore: results.first.matchScore ?? 0.85,
          ),
          quickInsights: results.first.matchReasons?.take(3).toList() ??
              ['Matches your search', 'Verified listing', 'Gurugram location'],
          fullAnalysis: 'Found ${results.length} properties matching "$query".',
          bestMatchReason: fallback['BEST_MATCH'] ?? '',
          fullRecommendation: fallback,
        );
        aiOverviewState = AiState.loaded;
      } else {
        aiOverviewState = AiState.error;
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> askAdvisor(String question) async {
    if (question.trim().isEmpty) return;

    isAiLoading = true;
    aiAnswer = '';
    notifyListeners();

    try {
      aiAnswer = await PropertyAdvisorService.askAdvisor(
        question: question,
        properties: results,
      );
    } catch (e) {
      aiAnswer = 'Error asking advisor: $e';
    } finally {
      isAiLoading = false;
      notifyListeners();
    }
  }

  void clearAdvisor() {
    aiAnswer = '';
    isAiLoading = false;
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