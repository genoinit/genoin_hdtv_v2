import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final String channelName;
  final String channelLogo;
  final int secondsRemaining;
  final double progress; // Range 0.0 to 1.0
  final String? epgProgram; // New EPG parameter!

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
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular Logo frame with spinning animation
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Spinning progress indicator (M3U8 load spinner style)
                  const SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                      strokeWidth: 2.0,
                    ),
                  ),
                  // Logo container
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.07),
                    ),
                    child: ClipOval(
                      child: channelLogo.startsWith('data:') || channelLogo.isEmpty
                          ? const Center(
                              child: Text(
                                'TV',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Image.network(
                              channelLogo,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Text(
                                  'TV',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            
            // Channel Name text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                channelName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
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
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
