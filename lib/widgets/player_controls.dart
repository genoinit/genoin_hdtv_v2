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
                // Compact Glassmorphic Floating Pill Control Bar with Larger Icons & Zero Gaps
                Positioned(
                  bottom: reelsMode
                      ? 125.0 + MediaQuery.of(context).padding.bottom
                      : (isMobile && !isFullscreen)
                          ? 12.0
                          : 24.0 + MediaQuery.of(context).padding.bottom,
                  left: 8.0 + ((isFullscreen || reelsMode) ? MediaQuery.of(context).padding.left : 0),
                  right: 8.0 + ((isFullscreen || reelsMode) ? MediaQuery.of(context).padding.right : 0),
                  child: GestureDetector(
                    onTap: () {}, // Swallows taps so they don't toggle overlay
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: (isMobile && !isFullscreen) ? 8.0 : 12.0,
                          vertical: (isMobile && !isFullscreen) ? 4.0 : 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xDC1C1917), // index.html --bg-surface
                          borderRadius: BorderRadius.circular(50.0),
                          border: Border.all(
                            color: const Color(0x3FF59E0B), // index.html --border-subtle amber
                            width: 1.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 1. Auto-Switching Toggle Button (Larger Icon: 20px)
                            IconButton(
                              onPressed: onAutoSwitchingToggle,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              icon: Icon(
                                autoSwitchingEnabled
                                    ? Icons.sync
                                    : Icons.sync_disabled,
                              ),
                              color: autoSwitchingEnabled
                                  ? const Color(0xFFF59E0B)
                                  : Colors.white.withOpacity(0.5),
                              iconSize: 20,
                              tooltip: autoSwitchingEnabled
                                  ? 'Auto-Switching: Enabled'
                                  : 'Auto-Switching: Disabled',
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                            ),

                            // 2. Play / Pause Button (Larger Icon: 22px)
                            IconButton(
                              onPressed: onPlayPauseToggle,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                              color: Colors.white,
                              iconSize: 22,
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                            ),

                            // 3. Mute / Unmute Button (Larger Icon: 20px)
                            IconButton(
                              onPressed: onMuteToggle,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              icon: Icon(
                                isMuted || volume == 0
                                    ? Icons.volume_off
                                    : volume < 0.5
                                        ? Icons.volume_down
                                        : Icons.volume_up,
                              ),
                              color: Colors.white,
                              iconSize: 20,
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                            ),

                            // 4. Volume Slider (Zero gap to mute button)
                            _buildVolumeSlider(),

                            // 5. Middle Group: Connected Channel Nav Pill (Landscape / Desktop)
                            if (showChannelNav) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: onPreviousChannel,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      icon: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                                      tooltip: 'Previous Channel',
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0x33F59E0B),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: IconButton(
                                        onPressed: onListPanelToggle,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                        icon: const Icon(Icons.list, color: Color(0xFFF59E0B), size: 22),
                                        tooltip: 'Open Playlist',
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: onNextChannel,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      icon: const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                                      tooltip: 'Next Channel',
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // 6. Aspect Ratio Cycle Button (Larger Icon: 20px)
                            if (isFullscreen || !isMobile)
                              IconButton(
                                onPressed: () {
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
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                icon: Icon(
                                  videoFit == BoxFit.contain
                                      ? Icons.aspect_ratio
                                      : videoFit == BoxFit.cover
                                          ? Icons.fullscreen
                                          : Icons.fit_screen,
                                ),
                                color: Colors.white,
                                iconSize: 20,
                                tooltip: videoFit == BoxFit.contain ? 'Fit' : videoFit == BoxFit.cover ? 'Full' : 'Stretch',
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                              ),

                            // 7. Quality Selector Button (Always Visible, Larger Icon: 15px, Zero outer margin)
                            Theme(
                              data: Theme.of(context).copyWith(
                                cardColor: const Color(0xFF1C1917),
                              ),
                              child: PopupMenuButton<String>(
                                initialValue: currentQuality,
                                tooltip: 'Select Quality',
                                position: PopupMenuPosition.over,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                    color: Color(0x3FF59E0B),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.tune,
                                        color: Color(0xFFF59E0B),
                                        size: 15,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        currentQuality == 'Auto'
                                            ? 'Auto'
                                            : (currentQuality.endsWith('p') ? currentQuality : '${currentQuality}p'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
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
                                      height: 32,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check,
                                            color: const Color(0xFFF59E0B).withOpacity(isSelected ? 1.0 : 0.0),
                                            size: 12,
                                          ),
                                          const SizedBox(width: 6),
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

                            // 8. Fullscreen Toggle Button (Larger Icon: 20px)
                            IconButton(
                              onPressed: onFullscreenToggle,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              icon: Icon(isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
                              color: Colors.white,
                              iconSize: 20,
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // EPG Live Program display (above bottom floating pill bar)
                if (epgText != null && epgText!.isNotEmpty)
                  Positioned(
                    left: 14 + MediaQuery.of(context).padding.left,
                    bottom: reelsMode
                        ? 165.0 + MediaQuery.of(context).padding.bottom
                        : (isMobile && !isFullscreen)
                            ? 48.0
                            : 64.0 + MediaQuery.of(context).padding.bottom,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              epgText!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Mobile Reels Toggle (positioned in top-right corner)
                if (isMobile && !reelsMode && onEnterReels != null)
                  Positioned(
                    top: isFullscreen ? 10 + MediaQuery.of(context).padding.top : 6,
                    right: isFullscreen ? 10 + MediaQuery.of(context).padding.right : 6,
                    child: GestureDetector(
                      onTap: () {}, // Swallows taps
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
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                          icon: const Icon(Icons.stay_current_portrait, color: Color(0xFFF59E0B), size: 16),
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
    final double sliderWidth = (isMobile && !isFullscreen) ? 36.0 : 42.0;

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
            height: 20,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // Track background
                Container(
                  width: sliderWidth,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Active fill track
                Container(
                  width: (isMuted ? 0.0 : volume) * sliderWidth,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Circular thumb handle
                if (!isMuted && volume > 0)
                  Positioned(
                    left: (((isMuted ? 0.0 : volume) * sliderWidth) - 4).clamp(0.0, sliderWidth - 8),
                    top: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 3,
                            offset: Offset(0, 1),
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
}
