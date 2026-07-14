import 'package:flutter/material.dart';
import '../models/playlist.dart';

class CustomSearchBar extends StatefulWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<Playlist> playlists;
  final Playlist selectedPlaylist;
  final ValueChanged<Playlist> onPlaylistSelected;
  final int resultCount;
  final bool searchMode;
  final List<String> recentSearches;
  final ValueChanged<String> onSearchSubmitted;
  final ValueChanged<String> onRemoveRecent;
  final VoidCallback onClearSearch;

  const CustomSearchBar({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.playlists,
    required this.selectedPlaylist,
    required this.onPlaylistSelected,
    required this.resultCount,
    required this.searchMode,
    required this.recentSearches,
    required this.onSearchSubmitted,
    required this.onRemoveRecent,
    required this.onClearSearch,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.query;
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  void didUpdateWidget(covariant CustomSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query && widget.query != _controller.text) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showHistory = _hasFocus && widget.query.trim().isEmpty && widget.recentSearches.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Row Container
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            border: Border.all(
              color: _hasFocus 
                  ? const Color(0xFF667EEA).withOpacity(0.65) 
                  : Colors.white.withOpacity(0.1),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Playlist Selector
              _buildPlaylistDropdown(),
              
              // Vertical Divider
              Container(
                width: 1,
                height: 24,
                color: Colors.white.withOpacity(0.15),
              ),
              const SizedBox(width: 10),

              // Search Icon
              Icon(
                Icons.search,
                color: Colors.white.withOpacity(0.45),
                size: 18,
              ),
              const SizedBox(width: 8),

              // Text Field Input
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search channel...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: widget.onQueryChanged,
                  onSubmitted: widget.onSearchSubmitted,
                ),
              ),

              // Search Count Badge
              if (widget.searchMode && widget.query.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.resultCount} found',
                    style: const TextStyle(
                      color: Color(0xFF667EEA),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // Clear Button
              if (widget.query.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _controller.clear();
                    widget.onClearSearch();
                  },
                  icon: const Icon(Icons.close),
                  color: Colors.white.withOpacity(0.5),
                  iconSize: 16,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
            ],
          ),
        ),

        // Recent Searches Chips
        if (showHistory) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.recentSearches.map((search) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _controller.text = search;
                    widget.onQueryChanged(search);
                    widget.onSearchSubmitted(search);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          search,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => widget.onRemoveRecent(search),
                          child: Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaylistDropdown() {
    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: const Color(0xFF0F0F1B),
      ),
      child: PopupMenuButton<Playlist>(
        initialValue: widget.selectedPlaylist,
        tooltip: 'Select Playlist',
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          constraints: const BoxConstraints(maxWidth: 130),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.dns,
                color: Color(0xFF667EEA),
                size: 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.selectedPlaylist.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white.withOpacity(0.45),
                size: 12,
              ),
            ],
          ),
        ),
        onSelected: (Playlist playlist) {
          widget.onPlaylistSelected(playlist);
        },
        itemBuilder: (BuildContext context) {
          return widget.playlists.map((Playlist playlist) {
            final isSelected = playlist.name == widget.selectedPlaylist.name;
            return PopupMenuItem<Playlist>(
              value: playlist,
              child: Container(
                constraints: const BoxConstraints(minWidth: 150),
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      color: const Color(0xFF667EEA).withOpacity(isSelected ? 1.0 : 0.0),
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        playlist.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList();
        },
      ),
    );
  }
}
