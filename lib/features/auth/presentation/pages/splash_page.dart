import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/guardian_theme.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authNotifierProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.gm.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.gm.surfaceSunken,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_rounded,
                size: 36,
                color: context.gm.brand,
              ),
            ),
            const SizedBox(height: AppSpacing.spaceLg),
            CircularProgressIndicator(
              color: context.gm.brand,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
