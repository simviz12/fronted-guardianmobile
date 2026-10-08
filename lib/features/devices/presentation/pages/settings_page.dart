import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/native_bridge_service.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/devices_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _periodicEnabled = false;
  int _intervalMinutes = 15;
  bool _isLoadingLocationSettings = true;

  @override
  void initState() {
    super.initState();
    _loadLocationSettings();
  }

  Future<void> _loadLocationSettings() async {
    final nativeBridge = ref.read(nativeBridgeServiceProvider);
    final enabled = await nativeBridge.isPeriodicLocationEnabled();
    final interval = await nativeBridge.getLocationIntervalMinutes();
    if (mounted) {
      setState(() {
        _periodicEnabled = enabled;
        _intervalMinutes = interval;
        _isLoadingLocationSettings = false;
      });
    }
  }

  Future<void> _togglePeriodic(bool value) async {
    final nativeBridge = ref.read(nativeBridgeServiceProvider);
    await nativeBridge.setPeriodicLocationEnabled(value);
    if (mounted) {
      setState(() {
        _periodicEnabled = value;
      });
    }
  }

  Future<void> _updateInterval(int minutes) async {
    final nativeBridge = ref.read(nativeBridgeServiceProvider);
    await nativeBridge.setLocationIntervalMinutes(minutes);
    if (mounted) {
      setState(() {
        _intervalMinutes = minutes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ajustes y Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.spaceMd,
          ),
          children: [
            // User Card
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      (user?.displayName.isNotEmpty ?? false)
                          ? user!.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textHeadings,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '—',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMd),

            // Periodic Location Settings Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: const Icon(
                          Icons.radar_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spaceSm),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reporte Periódico de Ubicación',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textHeadings,
                              ),
                            ),
                            Text(
                              'Servicio en segundo plano con notificación activa',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (!_isLoadingLocationSettings)
                        Switch(
                          value: _periodicEnabled,
                          activeThumbColor: AppColors.primary,
                          onChanged: _togglePeriodic,
                        ),
                    ],
                  ),
                  if (_periodicEnabled) ...[
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Frecuencia de reporte:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Cada $_intervalMinutes min',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _intervalMinutes.toDouble(),
                      min: 5,
                      max: 60,
                      divisions: 11, // 5, 10, 15, ..., 60
                      label: '$_intervalMinutes min',
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _intervalMinutes = val.round();
                        });
                      },
                      onChangeEnd: (val) {
                        _updateInterval(val.round());
                      },
                    ),
                    const Text(
                      'Usa precisión balanceada para ahorrar batería. La notificación "Guardian protege este teléfono" permanecerá visible en la barra de estado según las políticas del sistema.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMd),

            // Lock Protection Setup link
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(
                    Icons.lock_person_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Protección y Permisos de Bloqueo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeadings,
                  ),
                ),
                subtitle: const Text(
                  'Configura permisos de Administrador de Dispositivo y Batería',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/protected-setup'),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMd),

            // Server URL & Connection Config
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: const Icon(
                          Icons.settings_ethernet_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spaceSm),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Servidor Backend (API)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textHeadings,
                              ),
                            ),
                            Text(
                              'URL base para órdenes, daemon y sincronización',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spaceSm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ApiConfig.baseUrl,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showEditUrlDialog(),
                          child: const Text('Cambiar'),
                        ),
                      ],
                    ),
                  ),
                  if (ApiConfig.baseUrl.contains('localhost') || ApiConfig.baseUrl.contains('127.0.0.1')) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warningSubtle,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warningText),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Advertencia: "localhost" solo funciona por cable con "adb reverse activo". Para Wi-Fi use la IP local (ej. http://192.168.1.9:3000).',
                              style: TextStyle(fontSize: 11, color: AppColors.warningText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMd),

            // Diagnostic link
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(
                    Icons.dns_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Diagnóstico del Servidor',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeadings,
                  ),
                ),
                subtitle: const Text(
                  'Verifica el estado de conexión y base de datos',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/server-status'),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceLg),
            // Logout button
            DangerButton(
              text: 'Cerrar Sesión Segura',
              icon: Icons.logout_rounded,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('¿Cerrar Sesión?'),
                    content: const Text(
                      'Se cerrará tu sesión activa en este teléfono y se limpiarán los tokens de acceso.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.alert,
                        ),
                        child: const Text('Cerrar Sesión'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditUrlDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    final newUrl = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configurar Servidor API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa la dirección IP o dominio del backend. En la misma red Wi-Fi suele ser la IP de tu PC (ej. http://192.168.1.9:3000):',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://192.168.1.9:3000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newUrl != null && newUrl.isNotEmpty && newUrl != ApiConfig.baseUrl) {
      await ApiConfig.setBaseUrl(newUrl);

      // Also update native credentials if this phone is linked
      final identityService = ref.read(deviceIdentityServiceProvider);
      final thisPhoneId = await identityService.getThisPhoneDeviceId();
      if (thisPhoneId != null) {
        final token = await identityService.getDeviceToken(thisPhoneId);
        if (token != null) {
          final nativeBridge = ref.read(nativeBridgeServiceProvider);
          await nativeBridge.saveDeviceCredentials(
            apiBaseUrl: newUrl,
            deviceId: thisPhoneId,
            deviceToken: token,
          );
        }
      }

      if (mounted) {
        setState(() {});
        messenger.showSnackBar(
          SnackBar(
            content: Text('Servidor actualizado a $newUrl'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }
}
