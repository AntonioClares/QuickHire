import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickhire/core/routing/router.dart';
import 'package:quickhire/core/theme/app_theme.dart';

class QuickhireApp extends ConsumerWidget {
  const QuickhireApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.quickhireAppTheme,
      title: 'QuickHire',
    );
  }
}
