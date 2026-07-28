import 'package:flutter/material.dart';
import '../core/constants.dart';

class LoadingOverlay extends StatelessWidget {
  final String channelName;
  final String channelLogo;
  final int secondsRemaining;
  final double progress; // Range 0.0 to 1.0
  final String? epgProgram;

  const LoadingOverlay({
    super.key,
    required this.channelName,
    required this.channelLogo,
    required this.secondsRemaining,
    required this.progress,
    this.epgProgram,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xA60C0A09), // Color matching Orange app (rgba(12, 10, 9, 0.65))
      child: Stack(
        children: [
          // Top gradient bar matching Orange app with countdown progress animation
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 950),
                curve: Curves.linear,
                width: MediaQuery.of(context).size.width * progress.clamp(0.0, 1.0),
                decoration: const BoxDecoration(
                  gradient: AppColors.accentGradient,
                ),
              ),
            ),
          ),
          // Center spinner and channel logo
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                        strokeWidth: 2.0,
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: channelLogo.startsWith('data:') || channelLogo.isEmpty
                            ? const Center(
                                child: Text(
                                  'TV',
                                  style: TextStyle(
                                    color: AppColors.bgSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : Image.network(
                                channelLogo,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Text(
                                    'TV',
                                    style: TextStyle(
                                      color: AppColors.bgSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Channel Name text matching Orange app
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    channelName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (epgProgram != null && epgProgram!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      epgProgram!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
