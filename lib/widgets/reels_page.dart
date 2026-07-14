import 'package:flutter/material.dart';
import '../models/channel.dart';
import 'video_player_widget.dart';

class ReelsPage extends StatefulWidget {
  final List<Channel> channels;
  final int initialIndex;
  final bool isMuted;
  final double volume;
  final List<String> favorites;
  final ValueChanged<int> onChannelChanged;
  final VoidCallback onExit;
  final ValueChanged<Channel> onFavoriteToggled;
  final ValueChanged<bool> onMuteToggled;
  final ValueChanged<double> onVolumeChanged;
  final Map<String, Map<String, dynamic>> epgData; // New EPG parameter!

  const ReelsPage({
    super.key,
    required this.channels,
    required this.initialIndex,
    required this.isMuted,
    required this.volume,
    required this.favorites,
    required this.onChannelChanged,
    required this.onExit,
    required this.onFavoriteToggled,
    required this.onMuteToggled,
    required this.onVolumeChanged,
    required this.epgData,
  });

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  BoxFit _videoFit = BoxFit.contain; // Cycle state: BoxFit.contain, BoxFit.cover, BoxFit.fill
  late AnimationController _hintController;
  late Animation<double> _hintAnimation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Bouncing hint animation setup
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    
    _hintAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.channels.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: Center(
          child: Text(
            'No channels for Reels mode.',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
      );
    }

    final activeChannel = widget.channels[_currentIndex];
    final isFav = widget.favorites.contains(activeChannel.urls.isNotEmpty ? activeChannel.urls.first : '');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vertical PageView for swiping channels
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            itemCount: widget.channels.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              widget.onChannelChanged(index);
            },
            itemBuilder: (context, index) {
              if (index != _currentIndex) {
                // Return black placeholder for inactive pages to optimize memory
                return Container(color: Colors.black);
              }
              
              final channel = widget.channels[index];
              String? epgText;
              final prog = widget.epgData[channel.tvgId];
              if (prog != null) {
                final start = prog['startTime'] as DateTime;
                final stop = prog['stopTime'] as DateTime;
                final sh = start.hour.toString().padLeft(2, '0');
                final sm = start.minute.toString().padLeft(2, '0');
                final eh = stop.hour.toString().padLeft(2, '0');
                final em = stop.minute.toString().padLeft(2, '0');
                epgText = "${prog['title']} ($sh:$sm - $eh:$em)";
              }

              return VideoPlayerWidget(
                key: ValueKey(channel.urls.isNotEmpty ? channel.urls[channel.currentUrlIndex] : channel.name),
                channel: channel,
                isMuted: widget.isMuted,
                volume: widget.volume,
                isMobile: true,
                reelsMode: true,
                videoFit: _videoFit,
                onVideoFitChanged: (fit) {
                  setState(() {
                    _videoFit = fit;
                  });
                },
                onPreviousChannel: () {
                  if (_currentIndex > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                onNextChannel: () {
                  if (_currentIndex < widget.channels.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                onListPanelToggle: () {}, // No panel toggle in reels mode
                onMuteToggle: () => widget.onMuteToggled(!widget.isMuted),
                onVolumeChanged: widget.onVolumeChanged,
                onError: (title, desc, tryNextUrl) {
                  // Handled internally by video player retrying
                },
                epgText: epgText,
              );
            },
          ),

          // --- Reels Overlays ---

          // 1. Exit Button (Top Left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            left: 14,
            child: _buildIconButton(Icons.close, widget.onExit),
          ),

          // 2. Video Fit Button (Top Right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            right: 14,
            child: _buildIconButton(
              _videoFit == BoxFit.contain
                  ? Icons.aspect_ratio
                  : _videoFit == BoxFit.cover
                      ? Icons.fullscreen
                      : Icons.fit_screen,
              () {
                setState(() {
                  if (_videoFit == BoxFit.contain) {
                    _videoFit = BoxFit.cover;
                  } else if (_videoFit == BoxFit.cover) {
                    _videoFit = BoxFit.fill;
                  } else {
                    _videoFit = BoxFit.contain;
                  }
                });
              },
            ),
          ),

          // 3. Counter Badge (Top Center)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.channels.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),

          // 4. Channel Info details (Bottom Left)
          Positioned(
            left: 16,
            bottom: 70,
            right: 80, // Leave space for hint on the right
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Channel name and Server Badge Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        activeChannel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                    if (activeChannel.urls.length > 1) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            activeChannel.currentUrlIndex = (activeChannel.currentUrlIndex + 1) % activeChannel.urls.length;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667EEA).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            'Server ${activeChannel.currentUrlIndex + 1}/${activeChannel.urls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                // Category label (replaces with EPG live title if available)
                Text(
                  widget.epgData.containsKey(activeChannel.tvgId)
                      ? (widget.epgData[activeChannel.tvgId]?['title'] ?? activeChannel.category)
                      : activeChannel.category,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    shadows: const [
                      Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 5. Swipe Hint Overlay (Bottom Right)
          Positioned(
            right: 16,
            bottom: 70,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _hintAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _hintAnimation.value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.keyboard_double_arrow_up,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'swipe up/down',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.5),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}
