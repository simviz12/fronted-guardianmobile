import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/fcm_notification_service.dart';
import '../../../../core/network/native_bridge_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';

class ProtectedSetupPage extends ConsumerStatefulWidget {
  const ProtectedSetupPage({super.key});

  @override
  ConsumerState<ProtectedSetupPage> createState() => _ProtectedSetupPageState();
}

class _ProtectedSetupPageState extends ConsumerState<ProtectedSetupPage> {
  bool _notificationGranted = false;
  bool _batteryExempted = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    final nativeBridge = ref.read(nativeBridgeServiceProvider);
    final isIgnored = await nativeBridge.isBatteryOptimizationIgnored();
    if (mounted) {
      setState(() {
        _batteryExempted = isIgnored;
      });
    }
  }

  Future<void> _requestNotification() async {
    final service = ref.read(fcmNotificationServiceProvider);
    final granted = await service.requestNotificationPermissions();
    if (mounted) {
      setState(() {
        _notificationGranted = granted;
      });
    }
  }

  Future<void> _requestBatteryOptimization() async {
    final nativeBridge = ref.read(nativeBridgeServiceProvider);
    final success = await nativeBridge.requestIgnoreBatteryOptimization();
    if (mounted) {
      setState(() {
        _batteryExempted = success;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configuración de Protección'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.spaceMd),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: AppSpacing.spaceMd),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modo Protegido Activo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textHeadings,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Para que este celular suene y ejecute órdenes incluso bloqueado o con la pantalla apagada, concede los siguientes permisos:',
                            style: TextStyle(fontSize: 12, color: AppColors.textBody),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.spaceLg),

              // Card 1: Notificaciones Críticas (Android 13+)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.spaceSm),
                        const Expanded(
                          child: Text(
                            'Permiso de Notificaciones',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textHeadings,
                            ),
                          ),
                        ),
                        if (_notificationGranted)
                          const StatusChip(label: 'Concedido', type: StatusChipType.safe)
                        else
                          const StatusChip(label: 'Pendiente', type: StatusChipType.warning),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spaceXs),
                    const Text(
                      'Requerido en Android para mostrar la alerta en primer plano y permitirte detener la alarma cuando tú lo decidas.',
                      style: TextStyle(fontSize: 12, color: AppColors.textBody),
                    ),
                    const SizedBox(height: AppSpacing.spaceSm),
                    if (!_notificationGranted)
                      OutlinedButton(
                        onPressed: _requestNotification,
                        child: const Text('Conceder Notificaciones'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.spaceMd),

              // Card 2: Batería sin restricciones
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.battery_charging_full_rounded, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.spaceSm),
                        const Expanded(
                          child: Text(
                            'Sin Restricción de Batería',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textHeadings,
                            ),
                          ),
                        ),
                        if (_batteryExempted)
                          const StatusChip(label: 'Listo', type: StatusChipType.safe)
                        else
                          const StatusChip(label: 'Recomendado', type: StatusChipType.neutral),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spaceXs),
                    const Text(
                      'Evita que el sistema operativo suspenda el servicio de alarma cuando el teléfono lleve varias horas sin usarse.',
                      style: TextStyle(fontSize: 12, color: AppColors.textBody),
                    ),
                    const SizedBox(height: AppSpacing.spaceSm),
                    OutlinedButton(
                      onPressed: _requestBatteryOptimization,
                      child: const Text('Ajustar Ahorro de Batería'),
                    ),
                  ],
                ),
              ),

              const Spacer(),
              PrimaryButton(
                text: 'Continuar al Panel',
                icon: Icons.check_circle_outline_rounded,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
