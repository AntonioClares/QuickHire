import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final FormFieldValidator<T>? validator;

  const CustomDropdown({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        dropdownColor: Colors.white,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        icon: Icon(Icons.keyboard_arrow_down, color: Palette.primary, size: 24),
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
        menuMaxHeight: 300,
      ),
    );
  }
}
