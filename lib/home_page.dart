import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'models/channel.dart';
import 'models/playlist.dart';
import 'services/playlist_service.dart';
import 'utils/storage.dart';
import 'utils/parser.dart';
import 'widgets/category_tabs.dart';
import 'widgets/channel_grid.dart';
import 'widgets/search_bar.dart';
import 'widgets/video_player_widget.dart';
import 'widgets/reels_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Playlists
  List<Playlist> _playlists = [];
  Playlist? _selectedPlaylist;

  // Channels & Categories
  Map<String, List<Channel>> _rawChannels = {};
  List<String> _categories = [];
  String _selectedCategory = '';
  List<Channel> _displayedChannels = [];
  Channel? _activeChannel;
  int _activeChannelIndex = 0;

  // Favorites & Recents & History
  List<String> _favorites = [];
  List<Channel> _recents = [];
  List<String> _searchHistory = [];

  // Search States
  String _searchQuery = '';
  bool _searchMode = false;
  int _searchResultCount = 0;

  // Audio / Mute Preferences
  bool _isMuted = false;
  double _volume = 1.0;

  // UI state
  bool _showDesktopTray = false;
  bool _isLoadingPlaylist = false;
  bool _reelsModeActive = false;

  // Error retry counters
  int _consecutiveFailures = 0;
  Timer? _retryTimer;
  bool _isLocalErrorShowing = false;
  String _localErrorTitle = '';
  String _localErrorSub = '';

  // Focus Node for keyboard listener
  final FocusNode _keyboardFocusNode = FocusNode();

  // Video aspect ratio fit mode
  BoxFit _videoFit = BoxFit.contain;

  // Global key to preserve VideoPlayerWidgetState across mobile portrait / landscape orientation switches
  final GlobalKey _playerKey = GlobalKey();

  bool get _isMobileDevice => Theme.of(context).platform == TargetPlatform.android || Theme.of(context).platform == TargetPlatform.iOS;

  // Controller for mobile category swiping PageView carousel
  late PageController _mobilePageController;
  ScrollPhysics _pageScrollPhysics = const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  Offset? _dragStartOffset;
  double? _pageControllerStartOffset;
  bool _isPageScrolling = false;

  // Electronic Program Guide (EPG) parsed schedule data
  Map<String, Map<String, dynamic>> _epgData = {};

  Future<void> _loadEPGData(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = PlaylistParser.parseXMLTV(response.body);
        if (mounted) {
          setState(() {
            _epgData = data;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading EPG: $e');
    }
  }

  void _clearEPGData() {
    if (mounted) {
      setState(() {
        _epgData = {};
      });
    }
  }

  String? _getEPGText(Channel? channel) {
    if (channel == null) return null;
    final prog = _epgData[channel.tvgId];
    if (prog == null) return null;
    
    final start = prog['startTime'] as DateTime;
    final stop = prog['stopTime'] as DateTime;
    
    final sh = start.hour.toString().padLeft(2, '0');
    final sm = start.minute.toString().padLeft(2, '0');
    final eh = stop.hour.toString().padLeft(2, '0');
    final em = stop.minute.toString().padLeft(2, '0');
    
    final timeStr = "$sh:$sm - $eh:$em";
    return "${prog['title']} ($timeStr)";
  }

  @override
  void initState() {
    super.initState();
    // Default to index 2 ('📺 All Channels')
    _mobilePageController = PageController(initialPage: 2);
    _loadInitialData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _mobilePageController.dispose();
    _retryTimer?.cancel();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    // Load local storage items
    _favorites = AppStorage.getFavorites();
    _recents = AppStorage.getRecentWatched();
    _searchHistory = AppStorage.getSearchHistory();
    _isMuted = AppStorage.isMuted();
    _volume = AppStorage.getVolume();

    // Fetch built-in playlists list
    _playlists = PlaylistService.getBuiltInPlaylists();
    final lastIdx = AppStorage.getLastPlaylistIndex().clamp(0, _playlists.length - 1);
    
    if (_playlists.isNotEmpty) {
      _selectedPlaylist = _playlists[lastIdx];
      await _loadPlaylistChannels(_selectedPlaylist!, autoPlay: true);
    }
  }

  Future<void> _loadPlaylistChannels(Playlist playlist, {bool autoPlay = false}) async {
    setState(() {
      _isLoadingPlaylist = _activeChannel == null; // Only show fullscreen loading on app boot
      _rawChannels = {};
      _categories = [];
      _displayedChannels = [];
      _isLocalErrorShowing = false;
    });

    final data = await PlaylistService.fetchPlaylist(playlist);
    
    // Asynchronously fetch EPG data if present in parsed playlist header
    final epgUrl = PlaylistParser.parsedEpgUrl;
    if (epgUrl != null && epgUrl.isNotEmpty) {
      _loadEPGData(epgUrl);
    } else {
      _clearEPGData();
    }

    if (!mounted) return;

    setState(() {
      _rawChannels = data;
      
      // Setup category tabs list: exactly 3 categories
      _categories = ['🕒 Recent', '⭐ Favorites', '📺 All Channels'];
      
      _isLoadingPlaylist = false;
      _selectedCategory = '📺 All Channels';

      _updateDisplayedChannels();

      // Safely sync PageController to defaultIndex after layout frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mobilePageController.hasClients) {
          final defaultIndex = _categories.indexOf(_selectedCategory);
          if (defaultIndex != -1 && _mobilePageController.page?.round() != defaultIndex) {
            _mobilePageController.jumpToPage(defaultIndex);
          }
        }
      });

      // Play first channel on startup load only
      if (autoPlay && _displayedChannels.isNotEmpty) {
        _playChannel(_displayedChannels.first, 0);
      }
    });
  }

  void _updateDisplayedChannels() {
    if (_searchMode) {
      final query = _searchQuery.trim().toLowerCase();
      final results = <Channel>[];
      _rawChannels.forEach((cat, chList) {
        for (var ch in chList) {
          if (!ch.isAPK && ch.name.toLowerCase().contains(query)) {
            results.add(ch);
          }
        }
      });
      _displayedChannels = results;
      _searchResultCount = results.length;
    } else {
      if (_selectedCategory == '⭐ Favorites') {
        // Find favorite channels
        final favs = <Channel>[];
        _rawChannels.forEach((cat, chList) {
          for (var ch in chList) {
            if (_favorites.contains(ch.urls.isNotEmpty ? ch.urls.first : '')) {
              favs.add(ch);
            }
          }
        });
        _displayedChannels = favs;
      } else if (_selectedCategory == '🕒 Recent') {
        _displayedChannels = _recents;
      } else {
        // "📺 All Channels": Combine all channels from all categories at once
        final allCh = <Channel>[];
        final seenKeys = <String>{};
        _rawChannels.forEach((cat, chList) {
          for (var ch in chList) {
            final key = ch.urls.isNotEmpty ? ch.urls.first : ch.name;
            if (!ch.isAPK && !seenKeys.contains(key)) {
              seenKeys.add(key);
              allCh.add(ch);
            }
          }
        });
        _displayedChannels = allCh;
      }
    }
  }

  void _playChannel(Channel channel, int index) {
    if (channel.isAPK) {
      // Ignore APK placeholders in native Flutter
      return;
    }
    
    _retryTimer?.cancel();
    setState(() {
      _activeChannel = channel;
      _activeChannelIndex = index;
      _isLocalErrorShowing = false;
    });

    // Save to recents
    AppStorage.addRecentWatched(channel);
    setState(() {
      _recents = AppStorage.getRecentWatched();
    });
  }

  void _playNextChannel() {
    if (_displayedChannels.isEmpty) return;
    
    int nextIdx = _activeChannelIndex + 1;
    if (nextIdx >= _displayedChannels.length) {
      // Replicate HTML cross-category advance on desktop
      if (!_searchMode) {
        final nextCat = _getNextCategory(_selectedCategory);
        if (nextCat != null && nextCat != _selectedCategory) {
          _switchCategory(nextCat);
          if (_displayedChannels.isNotEmpty) {
            _playChannel(_displayedChannels.first, 0);
          }
          return;
        }
      }
      nextIdx = 0;
    }
    _playChannel(_displayedChannels[nextIdx], nextIdx);
  }

  void _playPreviousChannel() {
    if (_displayedChannels.isEmpty) return;
    
    int prevIdx = _activeChannelIndex - 1;
    if (prevIdx < 0) {
      if (!_searchMode) {
        final prevCat = _getPrevCategory(_selectedCategory);
        if (prevCat != null && prevCat != _selectedCategory) {
          _switchCategory(prevCat);
          if (_displayedChannels.isNotEmpty) {
            _playChannel(_displayedChannels.last, _displayedChannels.length - 1);
          }
          return;
        }
      }
      prevIdx = _displayedChannels.length - 1;
    }
    _playChannel(_displayedChannels[prevIdx], prevIdx);
  }

  String? _getNextCategory(String current) {
    if (_categories.isEmpty) return null;
    int idx = _categories.indexOf(current);
    if (idx == -1) idx = 0;
    
    int nextIdx = (idx + 1) % _categories.length;
    while (nextIdx != idx) {
      final cat = _categories[nextIdx];
      // Skip categories without channels
      if (_hasChannels(cat)) return cat;
      nextIdx = (nextIdx + 1) % _categories.length;
    }
    return null;
  }

  String? _getPrevCategory(String current) {
    if (_categories.isEmpty) return null;
    int idx = _categories.indexOf(current);
    if (idx == -1) idx = 0;
    
    int prevIdx = (idx - 1 + _categories.length) % _categories.length;
    while (prevIdx != idx) {
      final cat = _categories[prevIdx];
      if (_hasChannels(cat)) return cat;
      prevIdx = (prevIdx - 1 + _categories.length) % _categories.length;
    }
    return null;
  }

  bool _hasChannels(String cat) {
    if (cat == '⭐ Favorites') return _favorites.isNotEmpty;
    if (cat == '🕒 Recent') return _recents.isNotEmpty;
    if (cat == '📺 All Channels') return _rawChannels.isNotEmpty;
    return (_rawChannels[cat] ?? []).isNotEmpty;
  }

  void _switchCategory(String cat) {
    setState(() {
      _searchMode = false;
      _searchQuery = '';
      _selectedCategory = cat;
      _updateDisplayedChannels();
    });

    final index = _categories.indexOf(cat);
    if (index != -1 && _mobilePageController.hasClients) {
      _mobilePageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  List<Channel> _getChannelsForCategory(String category) {
    if (category == '⭐ Favorites') {
      final favs = <Channel>[];
      _rawChannels.forEach((cat, chList) {
        for (var ch in chList) {
          if (_favorites.contains(ch.urls.isNotEmpty ? ch.urls.first : '')) {
            favs.add(ch);
          }
        }
      });
      return favs;
    } else if (category == '🕒 Recent') {
      return _recents;
    } else if (category == '📺 All Channels') {
      final allCh = <Channel>[];
      final seenKeys = <String>{};
      _rawChannels.forEach((cat, chList) {
        for (var ch in chList) {
          final key = ch.urls.isNotEmpty ? ch.urls.first : ch.name;
          if (!ch.isAPK && !seenKeys.contains(key)) {
            seenKeys.add(key);
            allCh.add(ch);
          }
        }
      });
      return allCh;
    } else {
      return _rawChannels[category] ?? [];
    }
  }

  // --- Search Logic ---
  void _onSearchQueryChanged(String val) {
    setState(() {
      _searchQuery = val;
      _searchMode = val.trim().isNotEmpty;
      _updateDisplayedChannels();
    });
  }

  void _onSearchSubmitted(String val) {
    final query = val.trim();
    if (query.isEmpty) return;
    
    AppStorage.addSearchQuery(query);
    setState(() {
      _searchHistory = AppStorage.getSearchHistory();
    });
  }

  void _removeSearchHistoryItem(String item) {
    AppStorage.removeSearchQuery(item);
    setState(() {
      _searchHistory = AppStorage.getSearchHistory();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchMode = false;
      _updateDisplayedChannels();
    });
  }

  // --- Favorite Toggle ---
  void _toggleFavorite(Channel ch) {
    if (ch.urls.isEmpty) return;
    final url = ch.urls.first;
    AppStorage.toggleFavorite(url);
    setState(() {
      _favorites = AppStorage.getFavorites();
      _updateDisplayedChannels();
    });
  }

  // --- Player Settings Sync ---
  void _onMuteToggled(bool muted) {
    AppStorage.setMuted(muted);
    setState(() {
      _isMuted = muted;
    });
  }

  void _onVolumeChanged(double vol) {
    AppStorage.setVolume(vol);
    setState(() {
      _volume = vol;
      _isMuted = vol == 0.0;
    });
  }

  // --- Channel Playback Error Advanced Retry Flow ---
  void _handlePlayerError(String errorTitle, String errorSub, bool allowUrlRetry) {
    _retryTimer?.cancel();
    
    if (_activeChannel == null) return;
    
    // Check if auto switching is enabled
    if (!AppStorage.isAutoSwitchingEnabled()) {
      setState(() {
        _isLocalErrorShowing = true;
        _localErrorTitle = errorTitle;
        _localErrorSub = errorSub;
      });
      return;
    }
    
    final currentCh = _activeChannel!;
    final totalUrls = currentCh.urls.length;

    // 1. Try next server/url link if available
    if (allowUrlRetry && currentCh.currentUrlIndex < totalUrls - 1) {
      currentCh.currentUrlIndex++;
      final nextServer = currentCh.currentUrlIndex + 1;
      
      setState(() {
        _isLocalErrorShowing = true;
        _localErrorTitle = errorTitle;
        _localErrorSub = 'Switching Server ($nextServer/$totalUrls)...';
      });

      _retryTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isLocalErrorShowing = false;
          });
          _playChannel(currentCh, _activeChannelIndex);
        }
      });
    } 
    // 2. All urls failed: advance to next channel
    else {
      _consecutiveFailures++;
      final maxFailures = _displayedChannels.length > 5 ? _displayedChannels.length : 5;
      
      if (_consecutiveFailures >= maxFailures) {
        _consecutiveFailures = 0;
        setState(() {
          _isLocalErrorShowing = true;
          _localErrorTitle = 'Playback Failed';
          _localErrorSub = 'Please check your internet connection.';
        });
        return;
      }

      setState(() {
        _isLocalErrorShowing = true;
        _localErrorTitle = errorTitle;
        _localErrorSub = 'Switching channel...';
      });

      _retryTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) {
          setState(() {
            _isLocalErrorShowing = false;
          });
          _playNextChannel();
        }
      });
    }
  }

  void _onPlaybackStarted() {
    if (_isLocalErrorShowing) {
      setState(() {
        _isLocalErrorShowing = false;
        _consecutiveFailures = 0;
      });
    }
  }

  // Key Bindings
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      // Space: play/pause is handled inside player controller automatically
    } else if (key == LogicalKeyboardKey.keyC) {
      setState(() {
        _showDesktopTray = !_showDesktopTray;
      });
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _playNextChannel();
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _playPreviousChannel();
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _onVolumeChanged((_volume + 0.1).clamp(0.0, 1.0));
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _onVolumeChanged((_volume - 0.1).clamp(0.0, 1.0));
    } else if (key == LogicalKeyboardKey.keyM) {
      _onMuteToggled(!_isMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDesktop = media.orientation == Orientation.landscape && media.size.width > 768;

    final bool isMobileLandscape = !isDesktop && media.orientation == Orientation.landscape;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Intercept back button while inside Reels mode to exit to home page view
        if (_reelsModeActive) {
          setState(() {
            _reelsModeActive = false;
          });
          return;
        }

        // Show exit confirmation dialog in home page view
        final shouldExit = await _showExitConfirmation(context);
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: _reelsModeActive
          ? ReelsPage(
              channels: _displayedChannels,
              initialIndex: _activeChannelIndex,
              isMuted: _isMuted,
              volume: _volume,
              favorites: _favorites,
              onChannelChanged: (index) {
                _activeChannelIndex = index;
                _activeChannel = _displayedChannels[index];
              },
              onExit: () {
                setState(() {
                  _reelsModeActive = false;
                });
              },
              onFavoriteToggled: _toggleFavorite,
              onMuteToggled: _onMuteToggled,
              onVolumeChanged: _onVolumeChanged,
              epgData: _epgData,
            )
          : KeyboardListener(
              focusNode: _keyboardFocusNode,
              onKeyEvent: _handleKeyEvent,
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                backgroundColor: const Color(0xFF0E0E16),
                body: _isLoadingPlaylist
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                        ),
                      )
                    : isDesktop || isMobileLandscape
                        ? _buildDesktopLayout()
                        : _buildMobileLayout(),
              ),
            ),
    );
  }

  // --- Landscape Desktop Layout ---
  Widget _buildDesktopLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight;
        final double maxWidth = constraints.maxWidth;

        return Center(
          child: Container(
            width: maxWidth,
            height: maxHeight,
            color: Colors.black,
            child: Stack(
              children: [
                // Video Stream Component
                if (_activeChannel != null)
                  Positioned.fill(
                    child: VideoPlayerWidget(
                      key: _playerKey,
                      channel: _activeChannel!,
                      isMuted: _isMuted,
                      volume: _volume,
                      isMobile: _isMobileDevice,
                      reelsMode: false,
                      videoFit: _videoFit,
                      isListPanelOpen: _showDesktopTray,
                      externalErrorTitle: _isLocalErrorShowing ? _localErrorTitle : null,
                      externalErrorSubtext: _isLocalErrorShowing ? _localErrorSub : null,
                      onVideoFitChanged: (fit) {
                        setState(() {
                          _videoFit = fit;
                        });
                      },
                      onPreviousChannel: _playPreviousChannel,
                      onNextChannel: _playNextChannel,
                      onListPanelToggle: () {
                        setState(() {
                          _showDesktopTray = !_showDesktopTray;
                        });
                      },
                      onMuteToggle: () => _onMuteToggled(!_isMuted),
                      onVolumeChanged: _onVolumeChanged,
                      onError: _handlePlayerError,
                      onPlaybackStarted: _onPlaybackStarted,
                      epgText: _getEPGText(_activeChannel),
                    ),
                  )
                else
                  Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: const Text(
                      'No stream selected',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),

                // Sliding Bottom Tray Panel Overlay (Landscape Mode Grid Window)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  bottom: _showDesktopTray ? 12 : -320,
                  left: 12,
                  right: 12,
                  height: 290,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFA1C1917), // index.html --bg-surface #1C1917
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0x3FF59E0B), // index.html --border-subtle amber
                        width: 1.0,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black87,
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Search bar & server selection
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 4),
                          child: CustomSearchBar(
                            query: _searchQuery,
                            onQueryChanged: _onSearchQueryChanged,
                            playlists: _playlists,
                            selectedPlaylist: _selectedPlaylist!,
                            onPlaylistSelected: (pl) {
                              setState(() {
                                _selectedPlaylist = pl;
                                _loadPlaylistChannels(pl, autoPlay: false);
                              });
                            },
                            resultCount: _searchResultCount,
                            searchMode: _searchMode,
                            recentSearches: _searchHistory,
                            onSearchSubmitted: _onSearchSubmitted,
                            onRemoveRecent: _removeSearchHistoryItem,
                            onClearSearch: _clearSearch,
                          ),
                        ),

                        // Tabs
                        CategoryTabs(
                          categories: _categories,
                          selectedCategory: _selectedCategory,
                          onCategorySelected: _switchCategory,
                        ),

                        // Channel scroll list with arrows
                        Expanded(
                          child: _rawChannels.isEmpty
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                                  ),
                                )
                              : ChannelGrid(
                                  channels: _displayedChannels,
                                  activeChannel: _activeChannel,
                                  favorites: _favorites,
                                  searchQuery: _searchQuery,
                                  isDesktop: true,
                                  onChannelTap: (ch) {
                                    final idx = _displayedChannels.indexOf(ch);
                                    _playChannel(ch, idx);
                                  },
                                  onFavoriteToggled: _toggleFavorite,
                                ),
                        ),

                        // Collapse button area with 50% transparent background, arrow icon, and "Tap Here to Close This" text
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showDesktopTray = false;
                            });
                          },
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0x801C1917), // 50% transparent background (rgba(28, 25, 23, 0.50))
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: Color(0x3FF59E0B),
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Tap Here to Close This',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Portrait Mobile Layout ---
  Widget _buildMobileLayout() {
    return SafeArea(
      top: true,
      bottom: true,
      child: Column(
        children: [
          // Video viewport (Sticky 16:9 ratio at top)
          AspectRatio(
            aspectRatio: 16 / 9,
          child: _activeChannel != null
              ? VideoPlayerWidget(
                  key: _playerKey,
                  channel: _activeChannel!,
                  isMuted: _isMuted,
                  volume: _volume,
                  isMobile: _isMobileDevice,
                  reelsMode: false,
                  videoFit: _videoFit,
                  isListPanelOpen: _showDesktopTray,
                  externalErrorTitle: _isLocalErrorShowing ? _localErrorTitle : null,
                  externalErrorSubtext: _isLocalErrorShowing ? _localErrorSub : null,
                  onVideoFitChanged: (fit) {
                    setState(() {
                      _videoFit = fit;
                    });
                  },
                  onPreviousChannel: _playPreviousChannel,
                  onNextChannel: _playNextChannel,
                  onListPanelToggle: () {
                    // Desktop only panel, mobile grid is always visible underneath
                  },
                  onMuteToggle: () => _onMuteToggled(!_isMuted),
                  onVolumeChanged: _onVolumeChanged,
                  onError: _handlePlayerError,
                  onPlaybackStarted: _onPlaybackStarted,
                  onEnterReels: () {
                    setState(() {
                      _reelsModeActive = true;
                    });
                  },
                  epgText: _getEPGText(_activeChannel),
                )
              : Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Text('No stream active', style: TextStyle(color: Colors.white70)),
                ),
        ),

        // Sticky mobile header (Search & Categories stay fixed at the top)
        Container(
          color: const Color(0xFF0A0A12),
          padding: const EdgeInsets.only(left: 12, right: 12, top: 10),
          child: Column(
            children: [
              CustomSearchBar(
                query: _searchQuery,
                onQueryChanged: _onSearchQueryChanged,
                playlists: _playlists,
                selectedPlaylist: _selectedPlaylist!,
                onPlaylistSelected: (pl) {
                  setState(() {
                    _selectedPlaylist = pl;
                    _loadPlaylistChannels(pl, autoPlay: false);
                  });
                },
                resultCount: _searchResultCount,
                searchMode: _searchMode,
                recentSearches: _searchHistory,
                onSearchSubmitted: _onSearchSubmitted,
                onRemoveRecent: _removeSearchHistoryItem,
                onClearSearch: _clearSearch,
              ),
              const SizedBox(height: 8),
              CategoryTabs(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: _switchCategory,
              ),
            ],
          ),
        ),

        // Scrollable channel list grid
        Expanded(
          child: _rawChannels.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 60.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                    ),
                  ),
                )
              : _searchQuery.isNotEmpty
                  ? SingleChildScrollView(
                      child: ChannelGrid(
                        channels: _displayedChannels,
                        activeChannel: _activeChannel,
                        favorites: _favorites,
                        searchQuery: _searchQuery,
                        isDesktop: false,
                        onChannelTap: (ch) {
                          final idx = _displayedChannels.indexOf(ch);
                          _playChannel(ch, idx);
                        },
                        onFavoriteToggled: _toggleFavorite,
                      ),
                    )
                  : PageView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _mobilePageController,
                      itemCount: _categories.length,
                      onPageChanged: (index) {
                        if (_categories[index] != _selectedCategory) {
                          setState(() {
                            _selectedCategory = _categories[index];
                            _updateDisplayedChannels();
                          });
                        }
                      },
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final catChannels = _getChannelsForCategory(cat);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragStart: (details) {
                            _dragStartOffset = details.globalPosition;
                            _pageControllerStartOffset = _mobilePageController.hasClients ? _mobilePageController.offset : 0.0;
                            _isPageScrolling = false;
                          },
                          onHorizontalDragUpdate: (details) {
                            if (_dragStartOffset == null || _pageControllerStartOffset == null) return;
                            
                            final double deltaX = details.globalPosition.dx - _dragStartOffset!.dx;
                            final double deltaY = details.globalPosition.dy - _dragStartOffset!.dy;
                            
                            // Check if this is a deliberate horizontal drag:
                            // 1. Horizontal movement must be larger than vertical movement (1.8 ratio)
                            // 2. We require a threshold (slop) of at least 32 pixels horizontally before starting to slide!
                            if (!_isPageScrolling) {
                              if (deltaX.abs() > 32.0 && deltaX.abs() > deltaY.abs() * 1.8) {
                                _isPageScrolling = true;
                              }
                            }
                            
                            if (_isPageScrolling) {
                              final double targetOffset = _pageControllerStartOffset! - deltaX;
                              final double maxScroll = _mobilePageController.position.maxScrollExtent;
                              final double minScroll = _mobilePageController.position.minScrollExtent;
                              final double clamped = targetOffset.clamp(minScroll, maxScroll);
                              
                              _mobilePageController.position.jumpTo(clamped);
                            }
                          },
                          onHorizontalDragEnd: (details) {
                            if (!_isPageScrolling || _dragStartOffset == null || _pageControllerStartOffset == null) {
                              _dragStartOffset = null;
                              _pageControllerStartOffset = null;
                              _isPageScrolling = false;
                              return;
                            }
                            
                            final double deltaX = details.globalPosition.dx - _dragStartOffset!.dx;
                            final double velocity = details.primaryVelocity ?? 0.0;
                            final int activeIndex = _categories.indexOf(_selectedCategory);
                            
                            int targetPage = activeIndex;
                            if (deltaX.abs() > 32.0) {
                              if (velocity.abs() > 300.0) {
                                // Velocity-based flick
                                if (velocity > 0 && activeIndex > 0) {
                                  targetPage = activeIndex - 1;
                                } else if (velocity < 0 && activeIndex < _categories.length - 1) {
                                  targetPage = activeIndex + 1;
                                }
                              } else {
                                // Distance-based snap (requires swiping at least 35% of page width)
                                final double screenWidth = MediaQuery.of(context).size.width;
                                final double ratio = deltaX / screenWidth;
                                if (ratio.abs() > 0.35) {
                                  if (ratio > 0 && activeIndex > 0) {
                                    targetPage = activeIndex - 1;
                                  } else if (ratio < 0 && activeIndex < _categories.length - 1) {
                                    targetPage = activeIndex + 1;
                                  }
                                }
                              }
                            }
                            
                            if (_mobilePageController.hasClients) {
                              _mobilePageController.animateToPage(
                                targetPage,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                              );
                            }
                            
                            _dragStartOffset = null;
                            _pageControllerStartOffset = null;
                            _isPageScrolling = false;
                          },
                          onHorizontalDragCancel: () {
                            if (_isPageScrolling && _mobilePageController.hasClients) {
                              final int activeIndex = _categories.indexOf(_selectedCategory);
                              _mobilePageController.animateToPage(
                                activeIndex,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                              );
                            }
                            _dragStartOffset = null;
                            _pageControllerStartOffset = null;
                            _isPageScrolling = false;
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ChannelGrid(
                              channels: catChannels,
                              activeChannel: _activeChannel,
                              favorites: _favorites,
                              searchQuery: _searchQuery,
                              isDesktop: false,
                              onChannelTap: (ch) {
                                final idx = catChannels.indexOf(ch);
                                _playChannel(ch, idx);
                              },
                              onFavoriteToggled: _toggleFavorite,
                            ),
                          ),
                        );
                      },
                    ),
        ),
        // Fixed Footer Developer Credits at the bottom position of the screen
        _buildDevCredits(),
      ],
    ),
  );
}

  Widget _buildDevCredits() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1917), // index.html --bg-surface #1C1917
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x3FF59E0B), // index.html --border-subtle amber
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Developed By: ',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 11,
                ),
              ),
              const Text(
                'Saidur R.',
                style: TextStyle(
                  color: Color(0xFFF59E0B), // Amber gold accent
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSocialButton(
                icon: Icons.facebook,
                color: const Color(0xFF1877F2),
                url: 'https://www.facebook.com/Thesaidursumon',
                tooltip: 'Facebook',
              ),
              const SizedBox(width: 8),
              _buildSocialButton(
                icon: Icons.send,
                color: const Color(0xFF0088CC),
                url: 'https://t.me/thesaidursumon',
                tooltip: 'Telegram',
              ),
              const SizedBox(width: 8),
              _buildSocialButton(
                icon: Icons.chat,
                color: const Color(0xFF25D366),
                url: 'https://wa.me/8801891965724',
                tooltip: 'WhatsApp',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $urlString: $e');
    }
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String url,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => _launchURL(url),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
      ),
    );
  }

  Future<bool?> _showExitConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        title: const Text(
          'Exit Application?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to close GENOIN HDTV?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
            const SizedBox(height: 12),
            Text(
              'DEVELOPER INFO',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Saidur Rahman Bhuiyan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSocialButton(
                  icon: Icons.facebook,
                  color: const Color(0xFF1877F2),
                  url: 'https://facebook.com/thesaidursumon',
                  tooltip: 'Facebook',
                ),
                const SizedBox(width: 8),
                _buildSocialButton(
                  icon: Icons.send,
                  color: const Color(0xFF0088CC),
                  url: 'https://t.me/thesaidursumon',
                  tooltip: 'Telegram',
                ),
                const SizedBox(width: 8),
                _buildSocialButton(
                  icon: Icons.chat,
                  color: const Color(0xFF25D366),
                  url: 'https://wa.me/8801891965724',
                  tooltip: 'WhatsApp',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444).withOpacity(0.15),
              foregroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Exit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatermark() {
    return Positioned(
      right: 12,
      bottom: 12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'GENOIN',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.4),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'HDTV',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.4),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
