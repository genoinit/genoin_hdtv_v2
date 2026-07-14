class Channel {
  final String name;
  final String logo;
  final List<String> urls;
  final String category;
  final bool isAPK;
  final String tvgId; // New EPG field!
  int currentUrlIndex;

  Channel({
    required this.name,
    required this.logo,
    required this.urls,
    required this.category,
    this.isAPK = false,
    this.tvgId = '',
    this.currentUrlIndex = 0,
  });

  String get streamUrl {
    if (urls.isEmpty) return '';
    if (currentUrlIndex >= urls.length || currentUrlIndex < 0) {
      currentUrlIndex = 0;
    }
    return urls[currentUrlIndex];
  }

  Map<String, dynamic> toJson() {
    return {
      'channel_name': name,
      'image': logo,
      'urls': urls,
      'category': category,
      'isAPK': isAPK,
      'tvgId': tvgId,
      'currentUrlIndex': currentUrlIndex,
    };
  }

  factory Channel.fromJson(Map<String, dynamic> json) {
    var urlsList = json['urls'];
    List<String> parsedUrls = [];
    if (urlsList is List) {
      parsedUrls = urlsList.map((e) => e.toString()).toList();
    } else {
      var singleUrl = json['url'] ?? json['link'] ?? json['stream'];
      if (singleUrl != null) {
        parsedUrls = [singleUrl.toString()];
      }
    }
    return Channel(
      name: json['channel_name'] ?? json['name'] ?? json['title'] ?? 'Live Channel',
      logo: json['image'] ?? json['logo'] ?? json['icon'] ?? '',
      urls: parsedUrls,
      category: json['category'] ?? json['group'] ?? 'General',
      isAPK: json['isAPK'] ?? false,
      tvgId: json['tvgId'] ?? json['tvg-id'] ?? '',
      currentUrlIndex: json['currentUrlIndex'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Channel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          logo == other.logo &&
          category == other.category &&
          isAPK == other.isAPK &&
          tvgId == other.tvgId &&
          streamUrl == other.streamUrl;

  @override
  int get hashCode =>
      name.hashCode ^ logo.hashCode ^ category.hashCode ^ isAPK.hashCode ^ tvgId.hashCode ^ streamUrl.hashCode;
}
