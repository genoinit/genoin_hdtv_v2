import 'package:flutter/material.dart';
import '../core/constants.dart';

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

    double offsetOf(int targetIndex) {
      double sum = 8.0;
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

  double _getTextWidth(String text, FontWeight weight, double fontSize) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: weight, fontFamily: 'sans-serif'),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.width;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        padding: const EdgeInsets.only(left: 0, right: 8),
        itemBuilder: (context, index) {
          final cat = widget.categories[index];
          final isActive = cat == widget.selectedCategory;
          
          String displayName = cat;
          if (cat != '⭐ Favorites' && cat != '🕒 Recent' && cat != '📺 All Channels') {
            displayName = cat.isNotEmpty 
                ? cat[0].toUpperCase() + cat.substring(1) 
                : '';
          }

          return GestureDetector(
            onTap: () => widget.onCategorySelected(cat),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontFamily: 'sans-serif',
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                    child: Text(displayName),
                  ),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2,
                    width: _getTextWidth(displayName, isActive ? FontWeight.w600 : FontWeight.w500, 13.5),
                    color: isActive ? AppColors.accent : Colors.transparent,
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
