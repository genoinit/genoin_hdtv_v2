import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/storage.dart';

class PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final bool isMuted;
  final double volume;
  final bool showControls;
  final bool isFullscreen;
  final BoxFit videoFit;
  final ValueChanged<BoxFit> onVideoFitChanged;
  final VoidCallback onPlayPauseToggle;
  final VoidCallback onMuteToggle;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onFullscreenToggle;
  final VoidCallback onPreviousChannel;
  final VoidCallback onNextChannel;
  final VoidCallback onListPanelToggle;
  final bool isMobile;
  final bool reelsMode;
  final VoidCallback? onEnterReels;

  final String? epgText;
  final String currentQuality;
  final List<String> availableQualities;
  final ValueChanged<String> onQualityChanged;
  final bool autoSwitchingEnabled;
  final VoidCallback onAutoSwitchingToggle;

  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.isMuted,
    required this.volume,
    required this.showControls,
    required this.isFullscreen,
    required this.videoFit,
    required this.onVideoFitChanged,
    required this.onPlayPauseToggle,
    required this.onMuteToggle,
    required this.onVolumeChanged,
    required this.onFullscreenToggle,
    required this.onPreviousChannel,
    required this.onNextChannel,
    required this.onListPanelToggle,
    required this.isMobile,
    required this.reelsMode,
    required this.currentQuality,
    required this.availableQualities,
    required this.onQualityChanged,
    required this.autoSwitchingEnabled,
    required this.onAutoSwitchingToggle,
    this.onEnterReels,
    this.epgText,
  });

  @override
  Widget build(BuildContext context) {
    final bool showChannelNav = !reelsMode && (isFullscreen || !isMobile);

    return Stack(
      children: [
        // Controls visibility fade
        AnimatedOpacity(
          opacity: showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            ignoring: !showControls,
            child: Stack(
              children: [
                // Floating Glassmorphic Pill Control Bar with Raw GestureDetector Icons (Zero default padding)
                Positioned(
                  bottom: reelsMode
                      ? 125.0 + MediaQuery.of(context).padding.bottom
                      : (isMobile && !isFullscreen)
                          ? 12.0
                          : 24.0 + MediaQuery.of(context).padding.bottom,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {}, // Swallows taps so they don't toggle overlay
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50.0),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: (isMobile && !isFullscreen) ? 16.0 : 18.0, // 1.3x larger
                              vertical: (isMobile && !isFullscreen) ? 9.0 : 10.0, // 1.3x larger
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xB31C1917), // 70% opacity dark surface
                              borderRadius: BorderRadius.circular(50.0),
                              border: Border.all(
                                color: const Color(0x26F59E0B), // Subtle amber outline
                                width: 1.0,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Left Group: Auto-Switch, Play/Pause, Mute, Volume Slider
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Auto-Switching Toggle Button
                                    GestureDetector(
                                      onTap: onAutoSwitchingToggle,
                                      behavior: HitTestBehavior.opaque,
                                      child: Icon(
                                        autoSwitchingEnabled ? Icons.sync : Icons.sync_disabled,
                                        color: autoSwitchingEnabled ? const Color(0xFFF59E0B) : Colors.white.withOpacity(0.5),
                                        size: 22, // 1.3x larger
                                      ),
                                    ),
                                    const SizedBox(width: 8), // 1.3x larger

                                    // Play / Pause Button
                                    GestureDetector(
                                      onTap: onPlayPauseToggle,
                                      behavior: HitTestBehavior.opaque,
                                      child: Icon(
                                        isPlaying ? Icons.pause : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 26, // 1.3x larger
                                      ),
                                    ),
                                    const SizedBox(width: 8), // 1.3x larger

                                    // Mute / Unmute Button
                                    GestureDetector(
                                      onTap: onMuteToggle,
                                      behavior: HitTestBehavior.opaque,
                                      child: Icon(
                                        isMuted || volume == 0
                                            ? Icons.volume_off
                                            : volume < 0.5
                                                ? Icons.volume_down
                                                : Icons.volume_up,
                                        color: Colors.white,
                                        size: 22, // 1.3x larger
                                      ),
                                    ),
                                    const SizedBox(width: 8), // 1.3x larger

                                    // Volume Slider with white circular thumb handle
                                    _buildVolumeSlider(),
                                  ],
                                ),

                                // Middle Group: Connected Channel Nav Pill (Zero padding icons inside)
                                if (showChannelNav) ...[
                                  const SizedBox(width: 10), // 1.3x larger
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 1.3x larger
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Prev Channel Button
                                        GestureDetector(
                                          onTap: onPreviousChannel,
                                          behavior: HitTestBehavior.opaque,
                                          child: const Icon(Icons.chevron_left, color: Colors.white, size: 25), // 1.3x larger
                                        ),
                                        const SizedBox(width: 8), // 1.3x larger

                                        // Playlist Toggle Button
                                        GestureDetector(
                                          onTap: onListPanelToggle,
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // 1.3x larger
                                            decoration: BoxDecoration(
                                              color: const Color(0x33F59E0B),
                                              borderRadius: BorderRadius.circular(50),
                                            ),
                                            child: const Icon(Icons.list, color: Color(0xFFF59E0B), size: 26), // 1.3x larger
                                          ),
                                        ),
                                        const SizedBox(width: 8), // 1.3x larger

                                        // Next Channel Button
                                        GestureDetector(
                                          onTap: onNextChannel,
                                          behavior: HitTestBehavior.opaque,
                                          child: const Icon(Icons.chevron_right, color: Colors.white, size: 25), // 1.3x larger
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(width: 10), // 1.3x larger

                                // Right Group: Aspect Ratio, Quality Selector, Fullscreen
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Aspect Ratio Cycle Button
                                    if (isFullscreen || !isMobile) ...[
                                      GestureDetector(
                                        onTap: () {
                                          BoxFit nextFit;
                                          if (videoFit == BoxFit.contain) {
                                            nextFit = BoxFit.cover;
                                          } else if (videoFit == BoxFit.cover) {
                                            nextFit = BoxFit.fill;
                                          } else {
                                            nextFit = BoxFit.contain;
                                          }
                                          onVideoFitChanged(nextFit);
                                        },
                                        behavior: HitTestBehavior.opaque,
                                        child: Icon(
                                          videoFit == BoxFit.contain
                                              ? Icons.aspect_ratio
                                              : videoFit == BoxFit.cover
                                                  ? Icons.fullscreen
                                                  : Icons.fit_screen,
                                          color: Colors.white,
                                          size: 22, // 1.3x larger
                                        ),
                                      ),
                                      const SizedBox(width: 8), // 1.3x larger
                                    ],

                                    // Quality Selector Button
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        cardColor: const Color(0xFF1C1917),
                                      ),
                                      child: PopupMenuButton<String>(
                                        initialValue: currentQuality,
                                        tooltip: 'Select Quality',
                                        position: PopupMenuPosition.over,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: const BorderSide(
                                            color: Color(0x3FF59E0B),
                                          ),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), // Slightly larger
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.tune,
                                                color: Color(0xFFF59E0B),
                                                size: 18, // 1.3x larger
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                currentQuality == 'Auto'
                                                    ? 'Auto'
                                                    : (currentQuality.endsWith('p') ? currentQuality : '${currentQuality}p'),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13, // 1.3x larger
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        onSelected: onQualityChanged,
                                        itemBuilder: (BuildContext context) {
                                          final List<String> qualityOptions = availableQualities.isEmpty
                                              ? ['Auto']
                                              : ['Auto', '1080p', '480p', '240p'];

                                          return qualityOptions.map((String val) {
                                            final isSelected = val == currentQuality;
                                            return PopupMenuItem<String>(
                                              value: val,
                                              height: 28,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.check,
                                                    color: const Color(0xFFF59E0B).withOpacity(isSelected ? 1.0 : 0.0),
                                                    size: 11,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    val,
                                                    style: TextStyle(
                                                      color: isSelected ? const Color(0xFFF59E0B) : Colors.white.withOpacity(0.8),
                                                      fontSize: 12,
                                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8), // 1.3x larger

                                    // Fullscreen Toggle Button
                                    GestureDetector(
                                      onTap: onFullscreenToggle,
                                      behavior: HitTestBehavior.opaque,
                                      child: Icon(
                                        isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                        color: Colors.white,
                                        size: 22, // 1.3x larger
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // EPG Live Program display
                if (epgText != null && epgText!.isNotEmpty)
                  Positioned(
                    left: 14 + MediaQuery.of(context).padding.left,
                    bottom: reelsMode
                        ? 160.0 + MediaQuery.of(context).padding.bottom
                        : (isMobile && !isFullscreen)
                            ? 42.0
                            : 54.0 + MediaQuery.of(context).padding.bottom,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xCC1C1917),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0x3FF59E0B),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Color(0xFFF59E0B),
                              size: 10,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              epgText!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Mobile Reels Toggle
                if (isMobile && !reelsMode && onEnterReels != null)
                  Positioned(
                    top: isFullscreen ? 10 + MediaQuery.of(context).padding.top : 6,
                    right: isFullscreen ? 10 + MediaQuery.of(context).padding.right : 6,
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xCC1C1917),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x3FF59E0B)),
                        ),
                        child: IconButton(
                          onPressed: onEnterReels,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          icon: const Icon(Icons.stay_current_portrait, color: Color(0xFFF59E0B), size: 14),
                          tooltip: 'Reels Mode',
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeSlider() {
    final double sliderWidth = (isMobile && !isFullscreen) ? 39.0 : 47.0; // 1.3x larger

    return Builder(
      builder: (context) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final double localX = box.globalToLocal(details.globalPosition).dx;
            final double newVol = (localX / sliderWidth).clamp(0.0, 1.0);
            onVolumeChanged(newVol);
          },
          onTapDown: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final double localX = box.globalToLocal(details.globalPosition).dx;
            final double newVol = (localX / sliderWidth).clamp(0.0, 1.0);
            onVolumeChanged(newVol);
          },
          child: Container(
            width: sliderWidth,
            height: 18,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // Track background
                Container(
                  width: sliderWidth,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Active fill track
                Container(
                  width: (isMuted ? 0.0 : volume) * sliderWidth,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // No circular thumb handle (removed per user request)
              ],
            ),
          ),
        );
      },
    );
  }
}
