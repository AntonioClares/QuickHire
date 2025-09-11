import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';

class CustomField extends StatefulWidget {
  final String? hintText;
  final bool isPassword;
  final TextEditingController? controller;

  const CustomField({
    super.key,
    this.hintText,
    this.isPassword = false,
    this.controller,
  });

  @override
  State<CustomField> createState() => _CustomFieldState();
}

class _CustomFieldState extends State<CustomField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Color(0xFFF0F5FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: TextField(
          controller: widget.controller,
          cursorColor: Palette.primary,
          obscureText: widget.isPassword ? _obscureText : false,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            hintText: widget.hintText ?? 'example@gmail.com',
            hintStyle: TextStyle(
              color: const Color(0xFFA0A5BA),
              letterSpacing: widget.isPassword && _obscureText ? 7.5 : null,
            ),
            border: const OutlineInputBorder(borderSide: BorderSide.none),
            suffixIcon:
                widget.isPassword
                    ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFFB4B9CA),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                    : null,
          ),
        ),
      ),
    );
  }
}
