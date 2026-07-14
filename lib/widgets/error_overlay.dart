import 'package:flutter/material.dart';

class ErrorOverlay extends StatelessWidget {
  final String message;
  final String submessage;
  final VoidCallback? onRetry; // Optional button since original has automatic transition

  const ErrorOverlay({
    super.key,
    required this.message,
    required this.submessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.4),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Satellite Icon
          const Text(
            '📡',
            style: TextStyle(
              fontSize: 42,
            ),
          ),
          const SizedBox(height: 10),

          // Main Error Title
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          // Submessage Status
          Text(
            submessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
            ),
          ),
          
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444).withOpacity(0.15),
                foregroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Retry Now',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
