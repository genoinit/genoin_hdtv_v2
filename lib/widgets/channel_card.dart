import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/channel.dart';

class ChannelCard extends StatefulWidget {
  final Channel channel;
  final bool isActive;
  final bool isDesktop;
  final bool isFavorite;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggled;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.isActive,
    required this.isDesktop,
    required this.isFavorite,
    required this.searchQuery,
    required this.onTap,
    required this.onFavoriteToggled,
  });

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _CustomPulsePainter extends CustomPainter {
  final double progress;
  final Color color;

  _CustomPulsePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.55 * (1.0 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 + (3.0 * progress);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) + (3.0 * progress);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_CustomPulsePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _ChannelCardState extends State<ChannelCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    if (widget.isActive) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ChannelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat();
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildHighlightText(String text, String query, bool isActive, bool isDesktop) {
    final TextStyle baseStyle = TextStyle(
      fontSize: isDesktop ? 10.5 : 10.5,
      color: isActive ? AppColors.accent : AppColors.textSecondary,
      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
      fontFamily: 'sans-serif',
    );

    if (query.trim().isEmpty) {
      return Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final before = text.substring(0, index);
    final match = text.substring(index, index + query.length);
    final after = text.substring(index + query.length);

    return RichText(
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: const TextStyle(
              color: AppColors.textPrimary,
              backgroundColor: Color(0x40F59E0B),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double logoSize = widget.isDesktop ? AppSizes.channelLogoSizeDesktop : AppSizes.channelLogoSize;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular logo container styled same-to-same with Orange app ChannelTile
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: widget.isActive
                          ? _CustomPulsePainter(_pulseController.value, AppColors.accent)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: logoSize,
                        height: logoSize,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFFFFF), // White logo backdrop matching Orange app
                          border: Border.all(
                            color: widget.isActive ? AppColors.accent : AppColors.borderSubtle,
                            width: widget.isActive ? 2.0 : 1.0,
                          ),
                          boxShadow: widget.isActive
                              ? const [
                                  BoxShadow(
                                    color: AppColors.accentGlow,
                                    blurRadius: 12,
                                  ),
                                ]
                              : [],
                        ),
                        child: ClipOval(
                          child: widget.channel.logo.startsWith('data:')
                              ? Center(
                                  child: Text(
                                    widget.channel.name.substring(0, widget.channel.name.length > 3 ? 3 : widget.channel.name.length).toUpperCase(),
                                    style: const TextStyle(fontSize: 11, color: AppColors.bgDeep, fontWeight: FontWeight.bold),
                                  ),
                                )
                              : Image.network(
                                  widget.channel.logo,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey.shade400,
                                    alignment: Alignment.center,
                                    child: const Text('TV', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),

                // Star Favorite badge positioned same-to-same with Orange app (bottom-right -2)
                if (!widget.channel.isAPK)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: GestureDetector(
                      onTap: widget.onFavoriteToggled,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.bgSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isFavorite ? Icons.star : Icons.star_border,
                          color: widget.isFavorite ? AppColors.accent : AppColors.textMuted,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Channel name text matching Orange app DM Sans 10.5px styling
            _buildHighlightText(widget.channel.name, widget.searchQuery, widget.isActive, widget.isDesktop),
          ],
        ),
      ),
    );
  }
}
