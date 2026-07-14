import 'package:flutter_test/flutter_test.dart';
import 'package:genoin_hdtv/utils/parser.dart';

void main() {
  group('PlaylistParser tests', () {
    test('Parse basic M3U text with aggregation', () {
      const m3uContent = '''
#EXTM3U
#EXTINF:-1 tvg-logo="http://example.com/logo.png" group-title="Sports",HBO Sports
http://example.com/hbo.m3u8
#EXTINF:-1 tvg-logo="http://example.com/logo2.png" group-title="Movies",Action Cinema
http://example.com/cinema.m3u8
#EXTINF:-1 tvg-logo="http://example.com/logo.png" group-title="Sports",HBO Sports
http://example.com/hbo_fallback.m3u8
''';

      final result = PlaylistParser.parseM3U(m3uContent);

      expect(result.keys.length, 2);
      expect(result.containsKey('Sports'), true);
      expect(result.containsKey('Movies'), true);

      final sportsList = result['Sports']!;
      expect(sportsList.length, 1); // Aggregated duplicate
      expect(sportsList.first.name, 'HBO Sports');
      expect(sportsList.first.logo, 'http://example.com/logo.png');
      expect(sportsList.first.urls.length, 2);
      expect(sportsList.first.urls[0], 'http://example.com/hbo.m3u8');
      expect(sportsList.first.urls[1], 'http://example.com/hbo_fallback.m3u8');
      expect(sportsList.first.category, 'Sports');

      final moviesList = result['Movies']!;
      expect(moviesList.length, 1);
      expect(moviesList.first.name, 'Action Cinema');
      expect(moviesList.first.logo, 'http://example.com/logo2.png');
      expect(moviesList.first.urls.first, 'http://example.com/cinema.m3u8');
      expect(moviesList.first.category, 'Movies');
    });

    test('Parse basic JSON list', () {
      const jsonContent = '''
[
  {
    "channel_name": "Sky News",
    "image": "http://example.com/sky.png",
    "url": "http://example.com/sky.m3u8",
    "category": "News"
  },
  {
    "name": "CNN",
    "logo": "http://example.com/cnn.png",
    "link": "http://example.com/cnn.m3u8",
    "group": "News"
  }
]
''';

      final result = PlaylistParser.parseJSON(jsonContent);
      expect(result.containsKey('News'), true);
      
      final newsList = result['News']!;
      expect(newsList.length, 2);
      expect(newsList[0].name, 'Sky News');
      expect(newsList[0].logo, 'http://example.com/sky.png');
      expect(newsList[0].urls.first, 'http://example.com/sky.m3u8');

      expect(newsList[1].name, 'CNN');
      expect(newsList[1].logo, 'http://example.com/cnn.png');
      expect(newsList[1].urls.first, 'http://example.com/cnn.m3u8');
      expect(newsList[1].category, 'News');
    });
  });
}
