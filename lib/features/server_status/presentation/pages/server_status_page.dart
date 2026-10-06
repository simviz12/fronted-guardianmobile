import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../domain/entities/server_status.dart';
import '../providers/server_status_provider.dart';

class ServerStatusPage extends ConsumerWidget {
  const ServerStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(serverStatusNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Diagnóstico de Conexión'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: statusAsync.when(
                    loading: () => _buildLoadingState(),
                    error: (error, _) => _buildErrorState(context, ref, error),
                    data: (status) => _buildSuccessState(context, status),
                  ),
                ),
              ),
              _buildDiagnosticFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
        SizedBox(height: AppSpacing.spaceLg),
        Text(
          'Comprobando conexión con el servidor...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textBody,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context, ServerStatus status) {
    final formattedTime = status.time.toLocal().toString().split('.').first;

    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const StatusChip(
                label: 'Servidor conectado',
                type: StatusChipType.safe,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.neutralBadge,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  'v${status.version}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralBadgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceLg),
          Text(
            'Sistema Operativo',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.spaceXs),
          Text(
            'El backend responde correctamente y los servicios están sincronizados.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.spaceMd),
          _buildInfoRow('Servicio', status.service),
          const SizedBox(height: AppSpacing.spaceSm),
          _buildInfoRow(
            'Base de datos',
            status.database.toUpperCase(),
            badge: StatusChip(
              label: status.database.toUpperCase(),
              type: status.isDatabaseUp
                  ? StatusChipType.safe
                  : StatusChipType.danger,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          _buildInfoRow('Hora del servidor', formattedTime),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    String errorMessage = 'No se pudo comunicar con el servidor.';
    String? errorCode;

    if (error is Failure) {
      errorMessage = error.message;
      errorCode = error.code;
    } else {
      errorMessage = error.toString();
    }

    return AppCard(
      backgroundColor: AppColors.surface,
      border: Border.all(color: AppColors.alert.withValues(alpha: 0.3), width: 1.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              StatusChip(
                label: 'Sin conexión',
                type: StatusChipType.danger,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Text(
            'Error al conectar',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.alertText,
                ),
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            errorMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (errorCode != null) ...[
            const SizedBox(height: AppSpacing.spaceSm),
            Text(
              'Código de error: $errorCode',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.spaceLg),
          PrimaryButton(
            text: 'Reintentar',
            icon: Icons.refresh,
            onPressed: () => ref.read(serverStatusNotifierProvider.notifier).retry(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? badge}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        badge ??
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textHeadings,
                fontWeight: FontWeight.w600,
              ),
            ),
      ],
    );
  }

  Widget _buildDiagnosticFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.neutralBadge,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.dns_outlined,
            size: 16,
            color: AppColors.neutralBadgeText,
          ),
          const SizedBox(width: AppSpacing.spaceSm),
          Flexible(
            child: Text(
              'Base URL: ${ApiConfig.baseUrl}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.neutralBadgeText,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
