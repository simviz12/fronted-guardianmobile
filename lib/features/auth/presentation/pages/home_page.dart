import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final displayName = user?.displayName ?? 'Alex Developer';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Guardian Mobile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.spaceMd),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusChip(
                          label: 'Sesión activa',
                          type: StatusChipType.safe,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spaceLg),
                    Text(
                      'Hola, $displayName',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 22,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.spaceXs),
                    Text(
                      'Conectado como: $email',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.spaceMd),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: AppSpacing.spaceMd),
                    const Text(
                      'Esta pantalla provisional será reemplazada por el dashboard en la Parte 2.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              DangerButton(
                text: 'Cerrar sesión',
                icon: Icons.logout_rounded,
                isLoading: authState.isLoading,
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).logout();
                },
              ),
              const SizedBox(height: AppSpacing.spaceMd),
            ],
          ),
        ),
      ),
    );
  }
}
