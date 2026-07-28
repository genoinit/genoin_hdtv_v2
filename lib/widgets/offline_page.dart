import 'package:flutter/material.dart';

class OfflinePage extends StatefulWidget {
  final Future<bool> Function() onRetry;

  const OfflinePage({super.key, required this.onRetry});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> with SingleTickerProviderStateMixin {
  bool _isChecking = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showErrorHint = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _showErrorHint = false;
    });

    // Run connection verify check
    final bool connected = await widget.onRetry();

    if (!connected) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _showErrorHint = true;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: const Text(
              'Connection failed. Still offline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E16),
      body: Stack(
        children: [
          // Background soft glowing blob decoration top-left
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.08),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          // Background soft glowing blob decoration bottom-right
          Positioned(
            bottom: -120,
            right: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.08),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing Connection icon holder
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1917),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: Color(0xFFEF4444),
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Title text
                  const Text(
                    'Connection Lost',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    'No internet connection detected. Please verify your WiFi or mobile data and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Action Button
                  GestureDetector(
                    onTap: _handleRetry,
                    child: Container(
                      width: 190,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isChecking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Retry Connection',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (_showErrorHint) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Unable to reach server',
                      style: TextStyle(
                        color: const Color(0xFFEF4444).withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
