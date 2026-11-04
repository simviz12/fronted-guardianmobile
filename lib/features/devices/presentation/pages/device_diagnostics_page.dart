import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../core/localization/language_provider.dart';
import '../../domain/entities/device.dart';
import '../providers/devices_provider.dart';
import '../../data/models/device_diagnostics_dto.dart';
import '../../../../core/theme/guardian_theme.dart';

class DeviceDiagnosticsPage extends ConsumerWidget {
  final Device device;

  const DeviceDiagnosticsPage({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticsAsync = ref.watch(deviceDiagnosticsProvider(device.id));
    final isEn = ref.watch(languageProvider) == AppLanguage.en;

    return Scaffold(
      appBar: AppBar(
        title: Text('${isEn ? 'Diagnostics' : 'Diagnóstico'}: ${device.name}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.gm.brand),
            tooltip: isEn ? 'Refresh diagnostics' : 'Actualizar diagnóstico',
            onPressed: () => ref.refresh(deviceDiagnosticsProvider(device.id)),
          ),
        ],
      ),
      body: SafeArea(
        child: diagnosticsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: context.gm.brand),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: context.gm.danger),
                  const SizedBox(height: AppSpacing.spaceMd),
                  Text(
                    'No se pudo obtener el diagnóstico del dispositivo:\n$err',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.gm.dangerInk),
                  ),
                  const SizedBox(height: AppSpacing.spaceLg),
                  PrimaryButton(
                    text: 'Reintentar',
                    icon: Icons.refresh_rounded,
                    onPressed: () => ref.refresh(deviceDiagnosticsProvider(device.id)),
                  ),
                ],
              ),
            ),
          ),
          data: (data) {
            final diag = data is DeviceDiagnosticsDto ? data : DeviceDiagnosticsDto.fromJson(data as Map<String, dynamic>);
            return _buildDiagnosticsContent(context, ref, diag);
          },
        ),
      ),
    );
  }

  Widget _buildDiagnosticsContent(
    BuildContext context,
    WidgetRef ref,
    DeviceDiagnosticsDto diag,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      children: [
        // Problems overview card
        if (diag.problems.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            decoration: BoxDecoration(
              color: context.gm.dangerSoft,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: context.gm.danger.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: context.gm.danger, size: 24),
                    const SizedBox(width: AppSpacing.spaceSm),
                    Expanded(
                      child: Text(
                        'Problemas Detectados (${diag.problems.length})',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.gm.dangerInk,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spaceSm),
                ...diag.problems.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: context.gm.dangerInk, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              _translateProblem(p),
                              style: TextStyle(color: context.gm.dangerInk, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            decoration: BoxDecoration(
              color: context.gm.brandSoft,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: context.gm.brand.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: context.gm.brand, size: 24),
                const SizedBox(width: AppSpacing.spaceSm),
                Expanded(
                  child: Text(
                    '¡Excelente! Todos los sistemas y permisos están activos.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.gm.brandInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
        ],

        // Tokens & Connectivity
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONECTIVIDAD Y TOKENS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.gm.inkMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              _buildCheckRow(
                context,
                label: 'Token de Notificaciones FCM',
                active: diag.hasFcmToken,
                explanation: diag.hasFcmToken
                    ? 'Registrado para órdenes remotas'
                    : 'Falta token FCM. Las órdenes no llegarán.',
              ),
              const Divider(height: 16),
              _buildCheckRow(
                context,
                label: 'Token de Dispositivo (Daemon)',
                active: diag.hasDeviceToken,
                explanation: diag.hasDeviceToken
                    ? 'Almacenado de forma segura'
                    : 'Falta token de daemon nativo',
              ),
              const Divider(height: 16),
              _buildInfoRow(
                context,
                label: 'Último latido (Heartbeat):',
                value: diag.lastSeenAt != null ? _formatDate(diag.lastSeenAt!) : 'Nunca visto',
              ),
              const SizedBox(height: 6),
              _buildInfoRow(
                context,
                label: 'Último reporte de estado:',
                value: diag.lastStatusAt != null ? _formatDate(diag.lastStatusAt!) : 'Sin reportes',
              ),
              const SizedBox(height: 6),
              _buildInfoRow(
                context,
                label: 'Última ubicación GPS:',
                value: diag.lastLocationAt != null ? _formatDate(diag.lastLocationAt!) : 'Sin ubicación',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.spaceMd),

        // Permissions Status
        if (diag.permissions != null) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTADO DE PERMISOS NATIVOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.gm.inkMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceSm),
                _buildCheckRow(
                  context,
                  label: 'Notificaciones en pantalla',
                  active: diag.permissions!.notifications ?? false,
                  explanation: 'Permiso POST_NOTIFICATIONS',
                ),
                const Divider(height: 16),
                _buildCheckRow(
                  context,
                  label: 'Ubicación precisa (Primer plano)',
                  active: diag.permissions!.locationForeground ?? false,
                  explanation: 'GPS de alta precisión',
                ),
                const Divider(height: 16),
                _buildCheckRow(
                  context,
                  label: 'Ubicación en segundo plano',
                  active: diag.permissions!.locationBackground ?? false,
                  explanation: 'Rastreo permanente "Todo el tiempo"',
                ),
                const Divider(height: 16),
                _buildCheckRow(
                  context,
                  label: 'Sin optimización de batería',
                  active: diag.permissions!.batteryOptimizationIgnored ?? false,
                  explanation: 'Evita que Android cierre los servicios en reposo',
                ),
                const Divider(height: 16),
                _buildCheckRow(
                  context,
                  label: 'Administrador de Dispositivo (Bloqueo)',
                  active: diag.permissions!.deviceAdmin ?? false,
                  explanation: 'Permiso de bloqueo remoto de pantalla',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckRow(
    BuildContext context, {
    required String label,
    required bool active,
    required String explanation,
  }) {
    final theme = Theme.of(context);
    final headingColor = theme.colorScheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          active ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: active ? context.gm.brand : context.gm.danger,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: headingColor,
                ),
              ),
              Text(
                explanation,
                style: TextStyle(fontSize: 11, color: context.gm.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final headingColor = theme.colorScheme.onSurface;
    final bodyColor = theme.textTheme.bodyMedium?.color ?? context.gm.ink;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: bodyColor)),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: headingColor),
        ),
      ],
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  String _translateProblem(String problem) {
    switch (problem) {
      case 'NO_FCM_TOKEN':
        return 'Sin token FCM registrado: las órdenes push no se pueden entregar.';
      case 'NO_HEARTBEAT':
        return 'Sin latidos recientes: el daemon protegido lleva tiempo inactivo.';
      case 'NO_LOCATION':
        return 'Sin ubicación registrada: nunca ha reportado coordenadas GPS.';
      case 'NOTIFICATIONS_DENIED':
        return 'Permiso de notificaciones denegado.';
      case 'LOCATION_DENIED':
        return 'Permiso de ubicación en primer plano denegado.';
      case 'BACKGROUND_LOCATION_DENIED':
        return 'Permiso de ubicación en segundo plano ("todo el tiempo") denegado.';
      case 'BATTERY_OPTIMIZED':
        return 'Optimización de batería activa: el sistema puede congelar el servicio.';
      case 'ADMIN_NOT_ENABLED':
        return 'Administrador de dispositivo no activado: la orden BLOQUEAR fallará.';
      default:
        return problem;
    }
  }
}
