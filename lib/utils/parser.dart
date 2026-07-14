import 'dart:convert';
import '../models/channel.dart';

class PlaylistParser {
  static String? parsedEpgUrl;

  // Parses M3U or M3U8 string content
  static Map<String, List<Channel>> parseM3U(String text) {
    parsedEpgUrl = null; // Reset for new parse operations
    final Map<String, List<Channel>> grouped = {};
    final List<String> lines = text.split(RegExp(r'\r?\n'));
    
    Map<String, dynamic>? tempChannel;
    
    final RegExp logoReg = RegExp(r'(?:tvg-logo|logo)="([^"]+)"', caseSensitive: false);
    final RegExp groupReg = RegExp(r'group-title="([^"]+)"', caseSensitive: false);
    final RegExp tvgIdReg = RegExp(r'(?:tvg-id|id)="([^"]+)"', caseSensitive: false);

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTM3U')) {
        final tvgUrlMatch = RegExp(r'(?:x-tvg-url|url-tvg)="([^"]+)"', caseSensitive: false).firstMatch(line);
        if (tvgUrlMatch != null) {
          parsedEpgUrl = tvgUrlMatch.group(1);
        }
        continue;
      }

      if (line.startsWith('#EXTINF:')) {
        tempChannel = {};
        
        final logoMatch = logoReg.firstMatch(line);
        tempChannel['image'] = logoMatch != null ? logoMatch.group(1) : '';

        final groupMatch = groupReg.firstMatch(line);
        tempChannel['category'] = groupMatch != null ? groupMatch.group(1)!.trim() : 'General';

        final tvgIdMatch = tvgIdReg.firstMatch(line);
        tempChannel['tvgId'] = tvgIdMatch != null ? tvgIdMatch.group(1) : '';

        final commaIndex = line.lastIndexOf(',');
        tempChannel['channel_name'] = commaIndex != -1 ? line.substring(commaIndex + 1).trim() : 'Live Channel';
      } else if (line.startsWith('#')) {
        continue;
      } else if (tempChannel != null) {
        final url = line;
        tempChannel['url'] = url;
        tempChannel['urls'] = [url];
        
        final String category = tempChannel['category'] ?? 'General';
        final channel = Channel.fromJson(tempChannel);
        
        if (!grouped.containsKey(category)) {
          grouped[category] = [];
        }
        
        // Aggregate duplicates: if a channel name already exists in this category, we merge their URLs.
        final existingIdx = grouped[category]!.indexWhere((c) => c.name.toLowerCase() == channel.name.toLowerCase());
        if (existingIdx != -1) {
          final existing = grouped[category]![existingIdx];
          if (!existing.urls.contains(url)) {
            existing.urls.add(url);
          }
        } else {
          grouped[category]!.add(channel);
        }
        
        tempChannel = null;
      }
    }
    return grouped;
  }

  // Parses JSON string content
  static Map<String, List<Channel>> parseJSON(String text) {
    try {
      final decoded = jsonDecode(text);
      return formatJSONPlaylist(decoded);
    } catch (_) {
      return {};
    }
  }

  static Map<String, List<Channel>> formatJSONPlaylist(dynamic json) {
    final Map<String, List<Channel>> grouped = {};
    if (json == null) return grouped;

    // Case 1: Raw List of channels
    if (json is List) {
      for (var item in json) {
        if (item is Map<String, dynamic>) {
          final ch = Channel.fromJson(item);
          final cat = ch.category;
          if (!grouped.containsKey(cat)) {
            grouped[cat] = [];
          }
          grouped[cat]!.add(ch);
        }
      }
      return grouped;
    }

    // Case 2: Object containing channel lists under keys
    if (json is Map<String, dynamic>) {
      final genericWrappers = ['channels', 'playlist', 'playlists', 'data', 'list', 'items', 'results', 'records', 'response'];
      
      json.forEach((key, value) {
        if (value is List) {
          final isWrapper = genericWrappers.contains(key.toLowerCase());
          for (var item in value) {
            if (item is Map<String, dynamic>) {
              final ch = Channel.fromJson(item);
              // If the key is a generic wrapper, we group by the channel's category property.
              // Otherwise, the key itself is the category (unless channel explicitly defines its own).
              final cat = isWrapper 
                  ? ch.category 
                  : (item['category'] ?? item['group'] ?? key);
              
              final normalizedChannel = Channel(
                name: ch.name,
                logo: ch.logo,
                urls: ch.urls,
                category: cat,
                isAPK: ch.isAPK,
                currentUrlIndex: ch.currentUrlIndex,
              );

              if (!grouped.containsKey(cat)) {
                grouped[cat] = [];
              }
              grouped[cat]!.add(normalizedChannel);
            }
          }
        }
      });
      
      // Fallback: If it's just a single channel object
      if (grouped.isEmpty) {
        final ch = Channel.fromJson(json);
        if (ch.urls.isNotEmpty) {
          grouped['General'] = [ch];
        }
      }
    }

    return grouped;
  }

  static DateTime? parseXMLTVDate(String dateStr) {
    final match = RegExp(r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})').firstMatch(dateStr);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);
    final second = int.parse(match.group(6)!);

    final tzMatch = RegExp(r'\s*([+-])(\d{2})(\d{2})$').firstMatch(dateStr);
    if (tzMatch != null) {
      final sign = tzMatch.group(1) == '+' ? 1 : -1;
      final tzHour = int.parse(tzMatch.group(2)!);
      final tzMin = int.parse(tzMatch.group(3)!);
      
      final utcTime = DateTime.utc(year, month, day, hour, minute, second);
      final offsetDuration = Duration(hours: tzHour, minutes: tzMin) * sign;
      
      return utcTime.subtract(offsetDuration).toLocal();
    }
    return DateTime(year, month, day, hour, minute, second);
  }

  static Map<String, Map<String, dynamic>> parseXMLTV(String xmlString) {
    final Map<String, Map<String, dynamic>> currentEPG = {};
    final now = DateTime.now();

    final progRegex = RegExp(r'<programme\s+[^>]*start="([^"]+)"[^>]*stop="([^"]+)"[^>]*channel="([^"]+)"[^>]*>(.*?)</programme>', dotAll: true);
    final titleRegex = RegExp(r'<title[^>]*>(.*?)</title>', dotAll: true);
    final descRegex = RegExp(r'<desc[^>]*>(.*?)</desc>', dotAll: true);

    final matches = progRegex.allMatches(xmlString);
    for (final match in matches) {
      final startStr = match.group(1)!;
      final stopStr = match.group(2)!;
      final channelId = match.group(3)!;
      final content = match.group(4)!;

      final startTime = parseXMLTVDate(startStr);
      final stopTime = parseXMLTVDate(stopStr);

      if (startTime != null && stopTime != null && now.isAfter(startTime) && now.isBefore(stopTime)) {
        final titleMatch = titleRegex.firstMatch(content);
        final descMatch = descRegex.firstMatch(content);

        final title = titleMatch != null ? titleMatch.group(1)!.replaceAll(RegExp(r'<!\[CDATA\[(.*?)\]\]>'), r'\1').trim() : 'Live Show';
        final desc = descMatch != null ? descMatch.group(1)!.replaceAll(RegExp(r'<!\[CDATA\[(.*?)\]\]>'), r'\1').trim() : '';

        currentEPG[channelId] = {
          'title': title,
          'desc': desc,
          'startTime': startTime,
          'stopTime': stopTime,
        };
      }
    }
    return currentEPG;
  }
}
