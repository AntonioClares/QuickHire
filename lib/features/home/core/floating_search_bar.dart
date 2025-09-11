import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/features/search/views/pages/search_page.dart';

class FloatingSearchBar extends StatelessWidget {
  final bool isVisible;
  final double headerHeight;
  final double searchBarHeight;
  final String? hintText;

  const FloatingSearchBar({
    super.key,
    required this.isVisible,
    required this.headerHeight,
    required this.searchBarHeight,
    this.hintText,
  });

  void _navigateToSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      top: isVisible ? headerHeight - searchBarHeight / 2 : -searchBarHeight,
      left: 24,
      right: 24,
      child: GestureDetector(
        onTap: () => _navigateToSearch(context),
        child: Container(
          height: searchBarHeight,
          decoration: BoxDecoration(
            color: Palette.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Palette.imagePlaceholder.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Icon(Icons.search, color: Palette.subtitle, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hintText ?? "Search job, employer, or location",
                    style: TextStyle(
                      color: Palette.subtitle,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Icon(Icons.tune, color: Palette.subtitle, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
