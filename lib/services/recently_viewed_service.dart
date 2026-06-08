import 'package:shared_preferences/shared_preferences.dart';
import '../data/types.dart';

class RecentlyViewedService {
  static final RecentlyViewedService _instance = RecentlyViewedService._internal();
  factory RecentlyViewedService() => _instance;
  RecentlyViewedService._internal();

  static const String _key = 'recently_viewed_properties';

  Future<void> addViewed(Property property) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> viewed = prefs.getStringList(_key) ?? [];
    
    // Remove if already exists (to push to the top/recent)
    viewed.remove(property.id);
    viewed.insert(0, property.id);
    
    // Limit to last 20 properties
    if (viewed.length > 20) {
      viewed = viewed.sublist(0, 20);
    }
    
    await prefs.setStringList(_key, viewed);
  }

  Future<List<String>> getViewedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }
}
