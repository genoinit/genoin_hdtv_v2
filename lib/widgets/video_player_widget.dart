import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/channel.dart';
import 'loading_overlay.dart' as loader;
import 'error_overlay.dart' as err;
import 'player_controls.dart';
import '../utils/storage.dart';
import '../services/playlist_service.dart';

class VideoPlayerWidget extends StatefulWidget {
  final Channel channel;
  final bool isMuted;
  final double volume;
  final bool isMobile;
  final bool reelsMode;
  final BoxFit videoFit;
  final ValueChanged<BoxFit> onVideoFitChanged;
  final VoidCallback onPreviousChannel;
  final VoidCallback onNextChannel;
  final VoidCallback onListPanelToggle;
  final Function(String errorTitle, String errorSubText, bool tryNextUrl) onError;
  final VoidCallback onMuteToggle;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback? onEnterReels;
  final VoidCallback? onPlaybackStarted;
  final String? epgText; // New EPG parameter!
  final bool isListPanelOpen;

  const VideoPlayerWidget({
    super.key,
    required this.channel,
    required this.isMuted,
    required this.volume,
    required this.isMobile,
    required this.reelsMode,
    required this.videoFit,
    required this.onVideoFitChanged,
    required this.onPreviousChannel,
    required this.onNextChannel,
    required this.onListPanelToggle,
    required this.onError,
    required this.onMuteToggle,
    required this.onVolumeChanged,
    this.onEnterReels,
    this.onPlaybackStarted,
    this.epgText,
    this.isListPanelOpen = false,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isError = false;
  String _errorTitle = 'Connection Error';
  String _errorSubtext = 'Switching channel...';
  
  // Controls overlay visibility
  bool _showControls = true;
  Timer? _controlsTimer;

  // Load timer states
  int _secondsRemaining = 10;
  Timer? _loadTimer;
  double _loadProgress = 1.0;

  // Buffering states
  Timer? _bufferTimer;
  bool _isBuffering = false;

  bool _isDesktopFullscreen = false;

  bool get _isFullscreen {
    if (widget.isMobile) {
      return MediaQuery.of(context).orientation == Orientation.landscape;
    } else {
      return _isDesktopFullscreen;
    }
  }

  // HLS stream quality selection properties
  Map<String, String> _hlsQualities = {};
  String _currentQuality = 'Auto';
  String _currentPlayUrl = '';

  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    _currentPlayUrl = widget.channel.streamUrl;
    _initializePlayer();
    _startControlsTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (_lastOrientation != orientation) {
      _lastOrientation = orientation;
      
      // Immersive Sticky overlay controls are bound to screen landscape physical state directly
      if (orientation == Orientation.landscape) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
      }
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.channel != oldWidget.channel) {
      _hlsQualities = {};
      _currentQuality = 'Auto';
      _currentPlayUrl = widget.channel.streamUrl;
      _initializePlayer();
    } else {
      if (widget.isMuted != oldWidget.isMuted) {
        _controller?.setVolume(widget.isMuted ? 0.0 : widget.volume);
      } else if (widget.volume != oldWidget.volume) {
        _controller?.setVolume(widget.isMuted ? 0.0 : widget.volume);
      }
    }
  }

  Future<void> _fetchHlsQualities(String masterUrl) async {
    final Map<String, String> parsed = await PlaylistService.parseHlsQualities(masterUrl);
    if (mounted && parsed.isNotEmpty) {
      setState(() {
        _hlsQualities = parsed;
        
        // Auto-apply preferred quality if saved in preferences
        final String pref = AppStorage.getPreferredQuality();
        if (pref != 'Auto' && _hlsQualities.containsKey(pref)) {
          _currentQuality = pref;
          _currentPlayUrl = _hlsQualities[pref]!;
          _initializePlayer();
        }
      });
    }
  }

  void _changeQuality(String quality) {
    if (quality == 'Auto') {
      _currentPlayUrl = widget.channel.streamUrl;
    } else {
      _currentPlayUrl = _hlsQualities[quality] ?? widget.channel.streamUrl;
    }
    setState(() {
      _currentQuality = quality;
    });
    
    // Persist preferred quality resolution setting
    AppStorage.setPreferredQuality(quality);
    
    _initializePlayer();
  }

  void _cycleServer() {
    setState(() {
      widget.channel.currentUrlIndex = (widget.channel.currentUrlIndex + 1) % widget.channel.urls.length;
      _hlsQualities = {};
      _currentQuality = 'Auto';
      _currentPlayUrl = widget.channel.streamUrl;
    });
    _initializePlayer();
  }

  @override
  void dispose() {
    _cancelLoadTimer();
    _cancelControlsTimer();
    _bufferTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    _cancelLoadTimer();
    setState(() {
      _isInitialized = false;
      _isLoading = true;
      _isError = false;
      _isBuffering = false;
      _secondsRemaining = 10;
      _loadProgress = 1.0;
    });

    // Start 10s countdown timer
    _startLoadTimer();

    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    final url = _currentPlayUrl;
    if (url.isEmpty) {
      _handleFailure('Playback Error', 'No stream URL available', false);
      return;
    }

    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      
      await _controller!.initialize();
      
      // Successfully initialized
      _cancelLoadTimer();
      
      _controller!.setVolume(widget.isMuted ? 0.0 : widget.volume);
      _controller!.play();
      _controller!.setLooping(true);

      _controller!.addListener(_onControllerChanged);

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      // Parse available quality levels asynchronously on successful HLS load
      if (_hlsQualities.isEmpty && url.toLowerCase().contains('.m3u8')) {
        _fetchHlsQualities(widget.channel.streamUrl);
      }

      if (widget.onPlaybackStarted != null) {
        widget.onPlaybackStarted!();
      }
    } catch (e) {
      _handleFailure('Connection Error', 'Failed to load video stream', true);
    }
  }

  void _onControllerChanged() {
    if (_controller == null) return;
    
    final value = _controller!.value;

    // Buffering detection
    if (value.isBuffering && !_isBuffering) {
      _isBuffering = true;
      _bufferTimer?.cancel();
      // Wait 1s to show loading spinner (bufferingTimeout in HTML)
      _bufferTimer = Timer(const Duration(seconds: 1), () {
        if (mounted && _isBuffering) {
          setState(() {
            _isLoading = true;
          });
        }
      });
    } else if (!value.isBuffering && _isBuffering) {
      _isBuffering = false;
      _bufferTimer?.cancel();
      setState(() {
        _isLoading = false;
      });
    }

    // Error detection
    if (value.hasError) {
      _handleFailure('Playback Error', value.errorDescription ?? 'Fatal error playing stream', true);
    }
  }

  void _handleFailure(String title, String subtitle, bool allowUrlRetry) {
    _cancelLoadTimer();
    setState(() {
      _isLoading = false;
      _isError = true;
      _errorTitle = title;
      _errorSubtext = subtitle;
    });
    
    widget.onError(title, subtitle, allowUrlRetry);
  }

  // --- Load Timer Countdown ---
  void _startLoadTimer() {
    _loadTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsRemaining--;
        _loadProgress = _secondsRemaining / 10.0;
        if (_secondsRemaining <= 0) {
          _cancelLoadTimer();
          _handleFailure('Connection Error', 'Loading stream timed out', true);
        }
      });
    });
  }

  void _cancelLoadTimer() {
    _loadTimer?.cancel();
    _loadTimer = null;
  }

  // --- Controls Fade Timer ---
  void _startControlsTimer() {
    _cancelControlsTimer();
    _controlsTimer = Timer(Duration(milliseconds: widget.isMobile ? 4000 : 2500), () {
      if (mounted && _controller != null && _controller!.value.isPlaying && !_isError) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _cancelControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = null;
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    } else {
      _cancelControlsTimer();
    }
  }

  void _toggleFullscreen() {
    if (widget.isMobile) {
      if (_isFullscreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    } else {
      setState(() {
        _isDesktopFullscreen = !_isDesktopFullscreen;
      });
      if (_isDesktopFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double parentWidth = constraints.maxWidth;
        final double parentHeight = constraints.maxHeight;

        final size = _controller?.value.size ?? Size.zero;
        final double videoWidth = size.width > 0 ? size.width : 16.0;
        final double videoHeight = size.height > 0 ? size.height : 9.0;

        // Replicate HTML dynamic video-bounded watermark position
        double paddingX = 0;
        double paddingY = 0;

        if (widget.videoFit == BoxFit.contain) {
          final double ratioVideo = videoWidth / videoHeight;
          final double ratioContainer = parentWidth / parentHeight;
          if (ratioVideo > ratioContainer) {
            final double actualHeight = parentWidth / ratioVideo;
            paddingY = (parentHeight - actualHeight) / 2;
          } else {
            final double actualWidth = parentHeight * ratioVideo;
            paddingX = (parentWidth - actualWidth) / 2;
          }
        }

        final double watermarkOffset = widget.isMobile ? 12.0 : 24.0;
        final double watermarkRight = paddingX + watermarkOffset;
        final double watermarkBottom = paddingY + watermarkOffset;

        return MouseRegion(
          onHover: (_) {
            if (!widget.isMobile) {
              setState(() {
                _showControls = true;
              });
              _startControlsTimer();
            }
          },
          child: GestureDetector(
          onTap: () {}, // No-op, handled by onTapDown to prevent conflicts
          onTapDown: (details) {
            final double parentHeight = constraints.maxHeight;
            if (!_isFullscreen) {
              _toggleControls();
            } else {
              // In fullscreen mode, only toggle controls if the tap was on the bottom half of the screen
              if (details.localPosition.dy >= parentHeight / 2) {
                _toggleControls();
              }
            }
          },
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Main Video Player layout (utilizes FittedBox to support Fit, Full, Stretch)
                  if (_isInitialized && _controller != null)
                    SizedBox.expand(
                      child: FittedBox(
                        fit: widget.videoFit,
                        child: SizedBox(
                          width: videoWidth,
                          height: videoHeight,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                    )
                  else
                    const SizedBox(),

                  // Dynamic bounded Watermark (always visible when playing)
                  if (_isInitialized && !_isError)
                    Positioned(
                      right: watermarkRight,
                      bottom: watermarkBottom,
                      child: IgnorePointer(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'GENOIN',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: widget.isMobile ? 16 : 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'HDTV',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withOpacity(0.4),
                                fontSize: widget.isMobile ? 9 : 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Server Badge Pill Overlay (Top Left, only shown in standard mode if multiple mirrors exist, autohides with controls)
                  if (!widget.reelsMode && widget.channel.urls.length > 1)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: AnimatedOpacity(
                        opacity: _showControls ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: IgnorePointer(
                          ignoring: !_showControls,
                          child: GestureDetector(
                            onTap: _cycleServer,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.dns,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Server ${widget.channel.currentUrlIndex + 1}/${widget.channel.urls.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Buffering / Loading Indicator
                  if (_isLoading)
                    loader.LoadingOverlay(
                      channelName: widget.channel.name,
                      channelLogo: widget.channel.logo,
                      secondsRemaining: _secondsRemaining,
                      progress: _loadProgress,
                      epgProgram: widget.epgText,
                    ),

                  // Error Dialog Overlay
                  if (_isError)
                    err.ErrorOverlay(
                      message: _errorTitle,
                      submessage: _errorSubtext,
                      onRetry: _initializePlayer,
                    ),

                  // Player Control Overlays (shown if initialized or loading, but not in error state)
                  if ((_isInitialized || _isLoading) && !_isError)
                    Opacity(
                      opacity: _isLoading ? 0.5 : 1.0,
                      child: PlayerControls(
                        isPlaying: _controller?.value.isPlaying ?? false,
                        isMuted: widget.isMuted,
                        volume: widget.volume,
                        showControls: _showControls,
                        isFullscreen: _isFullscreen,
                        videoFit: widget.videoFit,
                        onVideoFitChanged: widget.onVideoFitChanged,
                        onPlayPauseToggle: () {
                          if (_controller == null) return;
                          setState(() {
                            if (_controller!.value.isPlaying) {
                              _controller!.pause();
                            } else {
                              _controller!.play();
                            }
                          });
                          _startControlsTimer();
                        },
                        onMuteToggle: widget.onMuteToggle,
                        onVolumeChanged: widget.onVolumeChanged,
                        onFullscreenToggle: _toggleFullscreen,
                        onPreviousChannel: widget.onPreviousChannel,
                        onNextChannel: widget.onNextChannel,
                        onListPanelToggle: widget.onListPanelToggle,
                        isMobile: widget.isMobile,
                        reelsMode: widget.reelsMode,
                        onEnterReels: widget.onEnterReels,
                        epgText: widget.epgText,
                        currentQuality: _currentQuality,
                        availableQualities: _hlsQualities.keys.toList(),
                        onQualityChanged: _changeQuality,
                      ),
                    ),

                  // Top-half panel toggle trigger (always active, intercepts taps on top half of screen to open playlists during loading/error)
                  if (_isFullscreen)
                    Positioned(
                      top: 45, // Clear the top bar strip for Server badge and Reels button
                      left: 0,
                      right: 0,
                      height: widget.isListPanelOpen
                          ? (parentHeight - 260 - 45 > 0 ? parentHeight - 305 : 100)
                          : (parentHeight - 130 - 45 > 0 ? parentHeight - 175 : 150),
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: widget.onListPanelToggle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
