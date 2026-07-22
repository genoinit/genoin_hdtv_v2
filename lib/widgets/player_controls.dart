import 'package:flutter/material.dart';

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

  final String? epgText; // New EPG parameter!
  final String currentQuality; // New Quality selection parameters!
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
                // Bottom controls row with linear dark gradient backplate (wrapped to swallow tap bubbles)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {}, // Swallows taps so they don't propagate to the root video container
                    child: Container(
                      padding: EdgeInsets.only(
                        left: 12 + ((isFullscreen || reelsMode) ? MediaQuery.of(context).padding.left : 0),
                        right: 12 + ((isFullscreen || reelsMode) ? MediaQuery.of(context).padding.right : 0),
                        top: (isFullscreen || reelsMode) ? 10 : 6,
                        bottom: (isFullscreen || reelsMode) ? 10 + MediaQuery.of(context).padding.bottom : 6,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black87,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          // Auto-Switching Toggle Button (Left of Play/Pause)
                          IconButton(
                            onPressed: onAutoSwitchingToggle,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: Icon(
                              autoSwitchingEnabled
                                  ? Icons.sync
                                  : Icons.sync_disabled,
                            ),
                            color: autoSwitchingEnabled
                                ? const Color(0xFF667EEA)
                                : Colors.white.withOpacity(0.4),
                            iconSize: 18,
                            tooltip: autoSwitchingEnabled
                                ? 'Auto-Switching: Enabled'
                                : 'Auto-Switching: Disabled',
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                          ),
                          
                          // Play/Pause Button
                          IconButton(
                            onPressed: onPlayPauseToggle,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                            color: Colors.white,
                            iconSize: 20,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                          ),
                          
                          // Volume Mute/Slider Row
                          IconButton(
                            onPressed: onMuteToggle,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: Icon(
                              isMuted || volume == 0
                                  ? Icons.volume_off
                                  : volume < 0.5
                                      ? Icons.volume_down
                                      : Icons.volume_up,
                            ),
                            color: Colors.white,
                            iconSize: 18,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                          ),
                          
                          // Volume custom slider
                          _buildVolumeSlider(),

                          const Spacer(),

                           // Aspect Ratio Cycle Button (only shown in fullscreen or desktop landscape mode)
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
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              icon: Icon(
                                videoFit == BoxFit.contain
                                    ? Icons.aspect_ratio
                                    : videoFit == BoxFit.cover
                                        ? Icons.fullscreen
                                        : Icons.fit_screen,
                              ),
                              color: Colors.white,
                              iconSize: 18,
                              tooltip: videoFit == BoxFit.contain
                                  ? 'Fit'
                                  : videoFit == BoxFit.cover
                                      ? 'Full'
                                      : 'Stretch',
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                            ),

                          // Quality Selector Button (only shown if multiple resolutions are available)
                          if (availableQualities.isNotEmpty)
                            Theme(
                              data: Theme.of(context).copyWith(
                                cardColor: const Color(0xFF0F0F1B),
                              ),
                              child: PopupMenuButton<String>(
                                initialValue: currentQuality,
                                tooltip: 'Select Quality',
                                position: PopupMenuPosition.over,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.tune,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        currentQuality == 'Auto' ? 'Auto' : '${currentQuality}p',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onSelected: onQualityChanged,
                                itemBuilder: (BuildContext context) {
                                  return ['Auto', ...availableQualities].map((String val) {
                                    final isSelected = val == currentQuality;
                                    return PopupMenuItem<String>(
                                      value: val,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check,
                                            color: const Color(0xFF667EEA).withOpacity(isSelected ? 1.0 : 0.0),
                                            size: 12,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            val == 'Auto' ? 'Auto (Adaptive)' : '${val}p',
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                                              fontSize: 13,
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

                          // Fullscreen Toggle Button
                          IconButton(
                            onPressed: onFullscreenToggle,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: Icon(isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
                            color: Colors.white,
                            iconSize: 18,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Channel Navigation circular overlay above bottom controls (wrapped to swallow tap bubbles)
                if (!reelsMode && (isFullscreen || !isMobile))
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 70 + MediaQuery.of(context).padding.bottom,
                    child: GestureDetector(
                      onTap: () {}, // Swallows taps so they don't propagate to the root video container
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Prev Button
                            _buildNavButton(Icons.chevron_left, onPreviousChannel),
                            const SizedBox(width: 12),
                            // List Panel Toggle Button
                            _buildNavButton(Icons.grid_view, onListPanelToggle, isMain: true),
                            const SizedBox(width: 12),
                            // Next Button
                            _buildNavButton(Icons.chevron_right, onNextChannel),
                          ],
                        ),
                      ),
                    ),
                  ),

                // EPG Live Program display (above bottom bar, below chevrons if shown)
                if (epgText != null && epgText!.isNotEmpty)
                  Positioned(
                    left: 16 + MediaQuery.of(context).padding.left,
                    bottom: (isFullscreen || (!isMobile && !reelsMode))
                        ? 130 + MediaQuery.of(context).padding.bottom
                        : 70 + MediaQuery.of(context).padding.bottom,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Color(0xFF667EEA),
                              size: 13,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              epgText!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
                    top: isFullscreen ? 12 + MediaQuery.of(context).padding.top : 8,
                    right: isFullscreen ? 12 + MediaQuery.of(context).padding.right : 8,
                    child: GestureDetector(
                      onTap: () {}, // Swallows taps to prevent video player controls toggling
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: onEnterReels,
                          icon: const Icon(Icons.stay_current_portrait, color: Colors.white, size: 20),
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
    return Builder(
      builder: (context) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final double localX = box.globalToLocal(details.globalPosition).dx;
            final double newVol = (localX / 70.0).clamp(0.0, 1.0);
            onVolumeChanged(newVol);
          },
          onTapDown: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final double localX = box.globalToLocal(details.globalPosition).dx;
            final double newVol = (localX / 70.0).clamp(0.0, 1.0);
            onVolumeChanged(newVol);
          },
          child: Container(
            width: 70,
            height: 24,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Container(
              width: 70,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: isMuted ? 0.0 : volume,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap, {bool isMain = false}) {
    final size = isMain ? 54.0 : 46.0;
    final border = Border.all(
      color: Colors.white.withOpacity(isMain ? 0.4 : 0.35),
      width: 1.5,
    );
    final bgColor = isMain 
        ? const Color(0xFF667EEA).withOpacity(0.3) 
        : Colors.black.withOpacity(0.6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: border,
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
