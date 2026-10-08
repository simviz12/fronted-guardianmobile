import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../domain/entities/device.dart';
import '../providers/devices_provider.dart';
import '../../data/models/device_diagnostics_dto.dart';

class DeviceDiagnosticsPage extends ConsumerWidget {
  final Device device;

  const DeviceDiagnosticsPage({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticsAsync = ref.watch(deviceDiagnosticsProvider(device.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Diagnóstico: ${device.name}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Actualizar diagnóstico',
            onPressed: () => ref.refresh(deviceDiagnosticsProvider(device.id)),
          ),
        ],
      ),
      body: SafeArea(
        child: diagnosticsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.alert),
                  const SizedBox(height: AppSpacing.spaceMd),
                  Text(
                    'No se pudo obtener el diagnóstico del dispositivo:\n$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.alertText),
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
              color: AppColors.alertContainer,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.alert.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.alert, size: 24),
                    const SizedBox(width: AppSpacing.spaceSm),
                    Expanded(
                      child: Text(
                        'Problemas Detectados (${diag.problems.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.alertText,
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
                          const Text('• ', style: TextStyle(color: AppColors.alertText, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              _translateProblem(p),
                              style: const TextStyle(color: AppColors.alertText, fontSize: 13),
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
              color: AppColors.safeSubtle,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.safe.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.safe, size: 24),
                const SizedBox(width: AppSpacing.spaceSm),
                const Expanded(
                  child: Text(
                    '¡Excelente! Todos los sistemas y permisos están activos.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.safeText,
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
              const Text(
                'CONECTIVIDAD Y TOKENS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              _buildCheckRow(
                label: 'Token de Notificaciones FCM',
                active: diag.hasFcmToken,
                explanation: diag.hasFcmToken
                    ? 'Registrado para órdenes remotas'
                    : 'Falta token FCM. Las órdenes no llegarán.',
              ),
              const Divider(height: 16),
              _buildCheckRow(
                label: 'Token de Dispositivo (Daemon)',
                active: diag.hasDeviceToken,
                explanation: diag.hasDeviceToken
                    ? 'Almacenado de forma segura'
                    : 'Falta token de daemon nativo',
              ),
              const Divider(height: 16),
              _buildInfoRow(
                label: 'Último latido (Heartbeat):',
                value: diag.lastSeenAt != null ? _formatDate(diag.lastSeenAt!) : 'Nunca visto',
              ),
              const SizedBox(height: 6),
              _buildInfoRow(
                label: 'Último reporte de estado:',
                value: diag.lastStatusAt != null ? _formatDate(diag.lastStatusAt!) : 'Sin reportes',
              ),
              const SizedBox(height: 6),
              _buildInfoRow(
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
                const Text(
                  'ESTADO DE PERMISOS NATIVOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceSm),
                _buildCheckRow(
                  label: 'Notificaciones en pantalla',
                  active: diag.permissions!.notifications ?? false,
                  explanation: 'Permiso POST_NOTIFICATIONS',
                ),
                const Divider(height: 16),
                _buildCheckRow(
                  label: 'Ubicación precisa (Primer plano)',
                  active: diag.permissions!.locationForeground ?? false,
                  explanation: 'GPS de alta precisión',
                ),
                const Divider(height: 16),
                _buildCheckRow(
                  label: 'Ubicación en segundo plano',
                  active: diag.permissions!.locationBackground ?? false,
                  explanation: 'Rastreo permanente "Todo el tiempo"',
                ),
                const Divider(height: 16),
                _buildCheckRow(
                  label: 'Sin optimización de batería',
                  active: diag.permissions!.batteryOptimizationIgnored ?? false,
                  explanation: 'Evita que Android cierre los servicios en reposo',
                ),
                const Divider(height: 16),
                _buildCheckRow(
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

  Widget _buildCheckRow({
    required String label,
    required bool active,
    required String explanation,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          active ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: active ? AppColors.safe : AppColors.alert,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeadings,
                ),
              ),
              Text(
                explanation,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textHeadings),
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
