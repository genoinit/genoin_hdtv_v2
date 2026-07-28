import 'package:flutter/material.dart';
import '../core/constants.dart';
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
        // Search Row Container styled same-to-same with Orange app SearchBarWidget
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border.all(
              color: _hasFocus ? AppColors.accent : AppColors.borderSubtle,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusPill),
          ),
          child: Row(
            children: [
              // Server / Playlist Selector Dropdown (Orange app style)
              _buildPlaylistDropdown(),

              // Vertical Divider
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: AppColors.borderSubtle,
              ),

              // Search Icon
              const Icon(
                Icons.search,
                color: AppColors.textMuted,
                size: 15,
              ),
              const SizedBox(width: 8),

              // Text Field Input
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontFamily: 'sans-serif',
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: widget.onQueryChanged,
                  onSubmitted: widget.onSearchSubmitted,
                ),
              ),

              // Search Count Badge (Orange app style)
              if (widget.searchMode && widget.query.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.resultCount}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Clear Button
              if (widget.query.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    widget.onClearSearch();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, color: AppColors.textMuted, size: 15),
                  ),
                ),
            ],
          ),
        ),

        // Recent Search Chips (Orange app style)
        if (showHistory) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: widget.recentSearches.map<Widget>((search) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _controller.text = search;
                    widget.onQueryChanged(search);
                    widget.onSearchSubmitted(search);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      border: Border(
                        left: BorderSide(color: AppColors.accent, width: 2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.history,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          search,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => widget.onRemoveRecent(search),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: AppColors.textMuted,
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
        cardColor: AppColors.bgCard,
      ),
      child: PopupMenuButton<Playlist>(
        initialValue: widget.selectedPlaylist,
        tooltip: 'Select Playlist',
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: AppColors.borderSubtle,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          constraints: const BoxConstraints(maxWidth: 110),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.dns,
                color: AppColors.accent,
                size: 13,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.selectedPlaylist.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textMuted,
                size: 14,
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
                      color: AppColors.accent.withOpacity(isSelected ? 1.0 : 0.0),
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        playlist.name,
                        style: TextStyle(
                          color: isSelected ? AppColors.accent : AppColors.textSecondary,
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
