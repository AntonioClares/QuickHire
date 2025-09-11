import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_button.dart';

class LocationPage extends StatelessWidget {
  const LocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Palette.imagePlaceholder,
                  borderRadius: BorderRadius.circular(90.0),
                ),
                height: MediaQuery.of(context).size.height * 0.28,
                width: MediaQuery.of(context).size.width * 0.5,
              ),
            ),
            const SizedBox(height: 94),
            CustomButton(
              text: "ACCESS LOCATION",
              onPressed: () {
                context.go('/home');
              },
            ),
            const SizedBox(height: 37),
            Text(
              "DFOOD WILL ACCESS YOUR LOCATION\nONLY WHILE USING THE APP",
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.subtitle),
            ),
          ],
        ),
      ),
    );
  }
}
