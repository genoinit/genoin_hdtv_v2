import 'package:flutter/material.dart';
import '../models/channel.dart';
import 'channel_card.dart';

class ChannelGrid extends StatefulWidget {
  final List<Channel> channels;
  final Channel? activeChannel;
  final List<String> favorites;
  final String searchQuery;
  final bool isDesktop;
  final ValueChanged<Channel> onChannelTap;
  final ValueChanged<Channel> onFavoriteToggled;

  const ChannelGrid({
    super.key,
    required this.channels,
    required this.activeChannel,
    required this.favorites,
    required this.searchQuery,
    required this.isDesktop,
    required this.onChannelTap,
    required this.onFavoriteToggled,
  });

  @override
  State<ChannelGrid> createState() => _ChannelGridState();
}

class _ChannelGridState extends State<ChannelGrid> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    if (widget.isDesktop) {
      _scrollController.addListener(_updateScrollArrows);
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollArrows());
    }
  }

  @override
  void didUpdateWidget(covariant ChannelGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDesktop != oldWidget.isDesktop) {
      if (widget.isDesktop) {
        _scrollController.addListener(_updateScrollArrows);
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollArrows());
      } else {
        _scrollController.removeListener(_updateScrollArrows);
      }
    } else if (widget.isDesktop && widget.channels != oldWidget.channels) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollArrows());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollArrows() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    
    setState(() {
      _canScrollLeft = offset > 5;
      _canScrollRight = offset < maxScroll - 5;
    });
  }

  void _scroll(double direction) {
    if (!_scrollController.hasClients) return;
    final viewWidth = _scrollController.position.viewportDimension;
    final target = _scrollController.offset + (direction * viewWidth * 0.7);
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.channels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tv_off,
                size: 32,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No channels found.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.isDesktop) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Horizontal scrolling list
          SizedBox(
            height: 90,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.channels.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final channel = widget.channels[index];
                final isActive = widget.activeChannel?.name == channel.name;
                final isFav = widget.favorites.contains(channel.urls.isNotEmpty ? channel.urls.first : '');
                
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChannelCard(
                    channel: channel,
                    isActive: isActive,
                    isDesktop: true,
                    isFavorite: isFav,
                    searchQuery: widget.searchQuery,
                    onTap: () => widget.onChannelTap(channel),
                    onFavoriteToggled: () => widget.onFavoriteToggled(channel),
                  ),
                );
              },
            ),
          ),

          // Scroll arrows
          if (_canScrollLeft)
            Positioned(
              left: 6,
              child: _buildArrowButton(Icons.chevron_left, () => _scroll(-1)),
            ),
          if (_canScrollRight)
            Positioned(
              right: 6,
              child: _buildArrowButton(Icons.chevron_right, () => _scroll(1)),
            ),
        ],
      );
    }

    // Mobile vertical grid view
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.channels.length,
      padding: const EdgeInsets.only(left: 8, right: 8, top: 14, bottom: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 0,
        crossAxisSpacing: 6,
        childAspectRatio: 0.78, // Tightly fitted ratio for 5 items per row with logo & title
      ),
      itemBuilder: (context, index) {
        final channel = widget.channels[index];
        final isActive = widget.activeChannel?.name == channel.name;
        final isFav = widget.favorites.contains(channel.urls.isNotEmpty ? channel.urls.first : '');
        
        return ChannelCard(
          channel: channel,
          isActive: isActive,
          isDesktop: false,
          isFavorite: isFav,
          searchQuery: widget.searchQuery,
          onTap: () => widget.onChannelTap(channel),
          onFavoriteToggled: () => widget.onFavoriteToggled(channel),
        );
      },
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback onPressed) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF191928).withOpacity(0.9),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}
