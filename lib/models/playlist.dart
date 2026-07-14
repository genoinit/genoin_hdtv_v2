class Playlist {
  final String name;
  final String? url;
  final String? data; // Holds local file content if loaded offline/locally
  final String type; // 'm3u' or 'json'
  final bool isLocal;

  Playlist({
    required this.name,
    this.url,
    this.data,
    required this.type,
    this.isLocal = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'data': data,
      'type': type,
      'isLocal': isLocal,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      name: json['name'] ?? '',
      url: json['url'],
      data: json['data'],
      type: json['type'] ?? 'm3u',
      isLocal: json['isLocal'] ?? false,
    );
  }
}
