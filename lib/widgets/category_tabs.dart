import 'package:flutter/material.dart';

class CategoryTabs extends StatefulWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategoryTabs({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Scroll to initial active tab once built
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive(animate: false));
  }

  @override
  void didUpdateWidget(covariant CategoryTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory ||
        widget.categories != oldWidget.categories) {
      _scrollToActive(animate: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActive({required bool animate}) {
    if (!_scrollController.hasClients || widget.categories.isEmpty) return;
    final index = widget.categories.indexOf(widget.selectedCategory);
    if (index == -1) return;

    // Estimate tab item offsets based on character counts
    double offsetOf(int targetIndex) {
      double sum = 8.0; // Horizontal list padding left
      for (int i = 0; i < targetIndex; i++) {
        sum += widget.categories[i].length * 7.0 + 32.0;
      }
      return sum;
    }

    final double itemWidth = widget.categories[index].length * 7.0 + 32.0;
    final double itemCenter = offsetOf(index) + itemWidth / 2.0;
    final double viewportWidth = _scrollController.position.viewportDimension;
    final double targetOffset = itemCenter - viewportWidth / 2.0;
    
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double clampedOffset = targetOffset.clamp(0.0, maxScroll);

    if (animate) {
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(clampedOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final cat = widget.categories[index];
          final isActive = cat == widget.selectedCategory;
          
          // Replicate capitalization logic from HTML
          String displayName = cat;
          if (cat != '⭐ Favorites' && cat != '🕒 Recent') {
            displayName = cat.isNotEmpty 
                ? cat[0].toUpperCase() + cat.substring(1) 
                : '';
          }

          return InkWell(
            onTap: () => widget.onCategorySelected(cat),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      color: isActive 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.45),
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: 30,
                    color: isActive ? const Color(0xFF667EEA) : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
