import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../domain/entities/server_status.dart';
import '../providers/server_status_provider.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/theme/guardian_theme.dart';

class ServerStatusPage extends ConsumerWidget {
  const ServerStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(serverStatusNotifierProvider);
    final isEn = ref.watch(languageProvider) == AppLanguage.en;

    return Scaffold(
      backgroundColor: context.gm.bg,
      appBar: AppBar(
        title: Text(isEn ? 'Connection Diagnostics' : 'Diagnóstico de Conexión'),
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
                    loading: () => _buildLoadingState(context, isEn),
                    error: (error, _) => _buildErrorState(context, ref, error, isEn),
                    data: (status) => _buildSuccessState(context, status, isEn),
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

  Widget _buildLoadingState(BuildContext context, bool isEn) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            color: context.gm.brand,
            strokeWidth: 3,
          ),
        ),
        SizedBox(height: AppSpacing.spaceLg),
        Text(
          isEn ? 'Checking server connection...' : 'Comprobando conexión con el servidor...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: context.gm.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context, ServerStatus status, bool isEn) {
    final formattedTime = status.time.toLocal().toString().split('.').first;

    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusChip(
                label: isEn ? 'Server connected' : 'Servidor conectado',
                type: StatusChipType.safe,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.gm.surfaceSunken,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  'v${status.version}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.gm.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceLg),
          Text(
            isEn ? 'Operating System' : 'Sistema Operativo',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.spaceXs),
          Text(
            isEn ? 'Backend is responding normally and services are synchronized.' : 'El backend responde correctamente y los servicios están sincronizados.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Divider(color: context.gm.border),
          const SizedBox(height: AppSpacing.spaceMd),
          _buildInfoRow(context, isEn ? 'Service' : 'Servicio', status.service),
          const SizedBox(height: AppSpacing.spaceSm),
          _buildInfoRow(context, 
            isEn ? 'Database' : 'Base de datos',
            status.database.toUpperCase(),
            badge: StatusChip(
              label: status.database.toUpperCase(),
              type: status.isDatabaseUp
                  ? StatusChipType.safe
                  : StatusChipType.danger,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          _buildInfoRow(context, isEn ? 'Server time' : 'Hora del servidor', formattedTime),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error, bool isEn) {
    String errorMessage = isEn ? 'Could not communicate with server.' : 'No se pudo comunicar con el servidor.';
    String? errorCode;

    if (error is Failure) {
      errorMessage = error.message;
      errorCode = error.code;
    } else {
      errorMessage = error.toString();
    }

    return AppCard(
      backgroundColor: context.gm.surface,
      border: Border.all(color: context.gm.danger.withValues(alpha: 0.3), width: 1.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusChip(
                label: isEn ? 'Disconnected' : 'Sin conexión',
                type: StatusChipType.danger,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Text(
            isEn ? 'Connection Error' : 'Error al conectar',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: context.gm.dangerInk,
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
              isEn ? 'Error code: $errorCode' : 'Código de error: $errorCode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.gm.inkMuted,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.spaceLg),
          PrimaryButton(
            text: isEn ? 'Retry' : 'Reintentar',
            icon: Icons.refresh,
            onPressed: () => ref.read(serverStatusNotifierProvider.notifier).retry(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {Widget? badge}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: context.gm.inkMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        badge ??
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: context.gm.ink,
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
        color: context.gm.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dns_outlined,
            size: 16,
            color: context.gm.inkMuted,
          ),
          const SizedBox(width: AppSpacing.spaceSm),
          Flexible(
            child: Text(
              'Base URL: ${ApiConfig.baseUrl}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: context.gm.inkMuted,
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
