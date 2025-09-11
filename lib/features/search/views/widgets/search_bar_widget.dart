import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final bool hasActiveFilters;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Palette.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: focusNode.hasFocus ? Palette.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(
          color: Palette.secondary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: "Search...",
          hintStyle: TextStyle(
            color: Palette.subtitle,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          prefixIcon: Icon(Icons.search, color: Palette.subtitle, size: 20),
          suffixIcon:
              controller.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, color: Palette.subtitle, size: 20),
                    onPressed: onClear,
                    splashRadius: 16,
                  )
                  : hasActiveFilters
                  ? Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Palette.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.tune, color: Colors.white, size: 16),
                  )
                  : null,
        ),
      ),
    );
  }
}
