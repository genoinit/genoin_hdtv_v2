import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';

class AppStorage {
  static const String _keyFavorites = 'nbox_favorites';
  static const String _keyRecentWatched = 'nbox_recent_watched';
  static const String _keyLastPlaylist = 'nbox_last_playlist';
  static const String _keySearchHistory = 'nbox_search_history';
  static const String _keyVolume = 'nbox_volume';
  static const String _keyMuted = 'nbox_muted';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Favorites (Stored as list of channel URLs)
  static List<String> getFavorites() {
    return _prefs?.getStringList(_keyFavorites) ?? [];
  }

  static Future<void> toggleFavorite(String url) async {
    if (url.isEmpty) return;
    final favs = getFavorites();
    if (favs.contains(url)) {
      favs.remove(url);
    } else {
      favs.add(url);
    }
    await _prefs?.setStringList(_keyFavorites, favs);
  }

  static bool isFavorite(String url) {
    if (url.isEmpty) return false;
    return getFavorites().contains(url);
  }

  // Recently Watched (Stored as list of serialized Channel JSONs)
  static List<Channel> getRecentWatched() {
    final list = _prefs?.getStringList(_keyRecentWatched) ?? [];
    return list.map((item) {
      try {
        return Channel.fromJson(jsonDecode(item));
      } catch (_) {
        return null;
      }
    }).whereType<Channel>().toList();
  }

  static Future<void> addRecentWatched(Channel channel) async {
    if (channel.isAPK || channel.urls.isEmpty) return;
    final recents = getRecentWatched();
    
    // Remove duplicates based on URL or name
    recents.removeWhere((item) => 
      (item.urls.isNotEmpty && channel.urls.isNotEmpty && item.urls.first == channel.urls.first) || 
      item.name.toLowerCase() == channel.name.toLowerCase()
    );
    
    recents.insert(0, channel);
    
    // Max 20 items as requested in the requirements
    final listToSave = recents.take(20).map((ch) => jsonEncode(ch.toJson())).toList();
    await _prefs?.setStringList(_keyRecentWatched, listToSave);
  }

  // Last Selected Playlist Index
  static int getLastPlaylistIndex() {
    return _prefs?.getInt(_keyLastPlaylist) ?? 0;
  }

  static Future<void> setLastPlaylistIndex(int index) async {
    await _prefs?.setInt(_keyLastPlaylist, index);
  }

  // Search History
  static List<String> getSearchHistory() {
    return _prefs?.getStringList(_keySearchHistory) ?? [];
  }

  static Future<void> addSearchQuery(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    final history = getSearchHistory();
    history.removeWhere((item) => item.toLowerCase() == clean.toLowerCase());
    history.insert(0, clean);
    // Limit to 10 search history items
    await _prefs?.setStringList(_keySearchHistory, history.take(10).toList());
  }

  static Future<void> removeSearchQuery(String query) async {
    final history = getSearchHistory();
    history.removeWhere((item) => item.toLowerCase() == query.trim().toLowerCase());
    await _prefs?.setStringList(_keySearchHistory, history);
  }

  static Future<void> clearSearchHistory() async {
    await _prefs?.remove(_keySearchHistory);
  }

  // Player Settings (Volume & Mute)
  static double getVolume() {
    return _prefs?.getDouble(_keyVolume) ?? 1.0;
  }

  static Future<void> setVolume(double volume) async {
    await _prefs?.setDouble(_keyVolume, volume.clamp(0.0, 1.0));
  }

  static bool isMuted() {
    return _prefs?.getBool(_keyMuted) ?? false;
  }

  static Future<void> setMuted(bool muted) async {
    await _prefs?.setBool(_keyMuted, muted);
  }

  // Preferred Stream Resolution Quality
  static const String _keyPreferredQuality = 'nbox_preferred_quality';

  static String getPreferredQuality() {
    return _prefs?.getString(_keyPreferredQuality) ?? 'Auto';
  }

  static Future<void> setPreferredQuality(String quality) async {
    await _prefs?.setString(_keyPreferredQuality, quality);
  }

  // Auto Channel/Server Switching Settings
  static const String _keyAutoSwitching = 'nbox_auto_switching';

  static bool isAutoSwitchingEnabled() {
    return _prefs?.getBool(_keyAutoSwitching) ?? true;
  }

  static Future<void> setAutoSwitchingEnabled(bool enabled) async {
    await _prefs?.setBool(_keyAutoSwitching, enabled);
  }
}
