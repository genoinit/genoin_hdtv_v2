import 'package:flutter/material.dart';
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
    if (query.trim().isEmpty) {
      return Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: isDesktop ? 10 : 11,
          color: isActive 
              ? (isDesktop ? Colors.white : const Color(0xFF667EEA))
              : (isDesktop ? Colors.white.withOpacity(0.75) : Colors.white.withOpacity(0.65)),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
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
        style: TextStyle(
          fontSize: isDesktop ? 10 : 11,
          color: isActive 
              ? (isDesktop ? Colors.white : const Color(0xFF667EEA))
              : (isDesktop ? Colors.white.withOpacity(0.75) : Colors.white.withOpacity(0.65)),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
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
        style: TextStyle(
          fontSize: isDesktop ? 10 : 11,
          color: isActive 
              ? (isDesktop ? Colors.white : const Color(0xFF667EEA))
              : (isDesktop ? Colors.white.withOpacity(0.75) : Colors.white.withOpacity(0.65)),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: const TextStyle(
              color: Color(0xFFA5B4FC),
              backgroundColor: Color(0x2E667EEA), // rgba(102,126,234,0.18)
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
    const fallbackLogo = 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%2280%22 height=%2280%22%3E%3Ccircle cx=%2240%22 cy=%2240%22 r=%2240%22 fill=%22%23333%22/%3E%3Ctext x=%2250%25%22 y=%2255%25%22 dominant-baseline=%22middle%22 text-anchor=%22middle%22 fill=%22%23777%22 font-size=%2228%22%3ETV%3C/text%3E%3C/svg%3E';

    final logoSize = widget.isDesktop ? 55.0 : 64.0;
    
    // Desktop layout
    if (widget.isDesktop) {
      return InkWell(
        onTap: widget.onTap,
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular logo container
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: widget.isActive 
                            ? _CustomPulsePainter(_pulseController.value, const Color(0xFF667EEA))
                            : null,
                        child: Container(
                          width: logoSize,
                          height: logoSize,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                            border: Border.all(
                              color: widget.isActive 
                                  ? const Color(0xFF667EEA) 
                                  : Colors.white.withOpacity(0.15),
                              width: 2.0,
                            ),
                          ),
                          child: ClipOval(
                            child: widget.channel.logo.startsWith('data:') 
                                ? Center(
                                    child: Text(
                                      widget.channel.name.substring(0, widget.channel.name.length > 3 ? 3 : widget.channel.name.length).toUpperCase(),
                                      style: const TextStyle(fontSize: 10, color: Colors.white),
                                    ),
                                  )
                                : Image.network(
                                    widget.channel.logo,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFF333333),
                                      alignment: Alignment.center,
                                      child: const Text('TV', style: TextStyle(color: Color(0xFF777777), fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Favorite heart badge
                  if (!widget.channel.isAPK)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: widget.onFavoriteToggled,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.65),
                          ),
                          child: Icon(
                            widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: widget.isFavorite ? const Color(0xFFEF4444) : Colors.white.withOpacity(0.85),
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Name text
              _buildHighlightText(widget.channel.name, widget.searchQuery, widget.isActive, true),
            ],
          ),
        ),
      );
    }

    // Mobile layout
    return InkWell(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular logo container
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: widget.isActive 
                        ? _CustomPulsePainter(_pulseController.value, const Color(0xFF667EEA))
                        : null,
                    child: Container(
                      width: logoSize,
                      height: logoSize,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEFEFEF), // Off-white backdrop for mobile (rgba(255,255,255,0.92))
                        border: Border.all(
                          color: widget.isActive 
                              ? const Color(0xFF667EEA) 
                              : Colors.white.withOpacity(0.15),
                          width: 2.0,
                        ),
                      ),
                      child: ClipOval(
                        child: widget.channel.logo.startsWith('data:') 
                            ? Center(
                                child: Text(
                                  widget.channel.name.substring(0, widget.channel.name.length > 3 ? 3 : widget.channel.name.length).toUpperCase(),
                                  style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              )
                            : Image.network(
                                widget.channel.logo,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFFE0E0E0),
                                  alignment: Alignment.center,
                                  child: const Text('TV', style: TextStyle(color: Color(0xFF777777), fontSize: 20, fontWeight: FontWeight.bold)),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
              
              // Favorite heart badge
              if (!widget.channel.isAPK)
                Positioned(
                  top: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: widget.onFavoriteToggled,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.65),
                      ),
                      child: Icon(
                        widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: widget.isFavorite ? const Color(0xFFEF4444) : Colors.white.withOpacity(0.85),
                        size: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Name text
          _buildHighlightText(widget.channel.name, widget.searchQuery, widget.isActive, false),
          const SizedBox(height: 2),
          // Category label (mobile only)
          Text(
            widget.channel.category,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }
}
