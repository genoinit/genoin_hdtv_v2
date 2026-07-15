import 'dart:convert';
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/playlist.dart';
import '../utils/parser.dart';

class PlaylistService {
  static List<Playlist> getBuiltInPlaylists() {
    return [
      Playlist(
        name: 'Genoin',
        url: 'https://raw.githubusercontent.com/genoinit/genoinit.github.io/refs/heads/main/playlist/genoin.m3u',
        type: 'm3u',
      ),
      Playlist(
        name: 'Bangla',
        url: 'https://raw.githubusercontent.com/genoinit/genoinit.github.io/refs/heads/main/playlist/bangla.json',
        type: 'json',
      ),
      Playlist(
        name: 'Sports',
        url: 'https://raw.githubusercontent.com/genoinit/genoinit.github.io/refs/heads/main/playlist/sports.json',
        type: 'json',
      ),
      Playlist(
        name: 'FTP',
        url: 'https://raw.githubusercontent.com/genoinit/genoinit.github.io/refs/heads/main/playlist/ftp.json',
        type: 'json',
      ),
    ];
  }

  static Future<Map<String, List<Channel>>> fetchPlaylist(Playlist playlist) async {
    if (playlist.isLocal) {
      return await _pickAndParseLocalFile();
    }

    if (playlist.url == null) return {};

    try {
      final response = await http.get(Uri.parse(playlist.url!)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final content = response.body;
        // Inject Download APK channel placeholder to match original HTML
        final isM3U = playlist.type == 'm3u' || playlist.url!.contains('.m3u') || playlist.url!.contains('.m3u8');
        final Map<String, List<Channel>> parsed = isM3U 
            ? PlaylistParser.parseM3U(content)
            : PlaylistParser.parseJSON(content);
            
        return parsed;
      }
    } catch (e) {
      debugPrint('Error fetching playlist: $e');
    }
    return {};
  }

  static Future<Map<String, List<Channel>>> _pickAndParseLocalFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String content = '';
        String ext = file.extension?.toLowerCase() ?? '';
        
        if (file.bytes != null) {
          content = utf8.decode(file.bytes!);
        } else if (file.path != null) {
          final ioFile = io.File(file.path!);
          content = await ioFile.readAsString();
          if (ext.isEmpty) {
            ext = file.path!.split('.').last.toLowerCase();
          }
        }

        if (content.isNotEmpty) {
          if (ext == 'json' || content.trim().startsWith('{') || content.trim().startsWith('[')) {
            return PlaylistParser.parseJSON(content);
          } else {
            return PlaylistParser.parseM3U(content);
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking/parsing local file: $e');
    }
    return {};
  }

  static Future<Map<String, String>> parseHlsQualities(String masterUrl) async {
    final Map<String, String> qualities = {};
    if (!masterUrl.toLowerCase().contains('.m3u8')) return qualities;
    
    try {
      final response = await http.get(Uri.parse(masterUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final lines = response.body.split(RegExp(r'\r?\n'));
        final RegExp resReg = RegExp(r'RESOLUTION=\d+x(\d+)', caseSensitive: false);
        
        String? currentInfo;
        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty) continue;
          
          if (line.startsWith('#EXT-X-STREAM-INF')) {
            currentInfo = line;
          } else if (!line.startsWith('#') && currentInfo != null) {
            final resMatch = resReg.firstMatch(currentInfo);
            if (resMatch != null) {
              final height = resMatch.group(1)!;
              final String subUrl = Uri.parse(masterUrl).resolve(line).toString();
              qualities[height] = subUrl;
            }
            currentInfo = null;
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing HLS qualities: $e');
    }
    return qualities;
  }
}
