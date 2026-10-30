import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/native_bridge_service.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/two_factor_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionsProvider.notifier).load();
    });
  }

  Future<void> _loadLocationSettings() async {
    try {
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingLocationSettings = false;
        });
      }
    }
  }

  Future<void> _togglePeriodic(bool value) async {
    try {
      final nativeBridge = ref.read(nativeBridgeServiceProvider);
      await nativeBridge.setPeriodicLocationEnabled(value);
      if (mounted) {
        setState(() {
          _periodicEnabled = value;
        });
      }
    } catch (_) {}
  }

  Future<void> _updateInterval(int minutes) async {
    try {
      final nativeBridge = ref.read(nativeBridgeServiceProvider);
      await nativeBridge.setLocationIntervalMinutes(minutes);
      if (mounted) {
        setState(() {
          _intervalMinutes = minutes;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final sessionsState = ref.watch(sessionsProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final currentLang = ref.watch(languageProvider);
    final isEn = currentLang == AppLanguage.en;
    final theme = Theme.of(context);
    final headingColor = theme.colorScheme.onSurface;
    final bodyColor = theme.textTheme.bodyMedium?.color ?? AppColors.textBody;

    void navigateBack() {
      context.go('/home');
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        navigateBack();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: navigateBack,
          ),
          title: Text(isEn ? 'Settings & Profile' : 'Ajustes y Perfil'),
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
            // Preference Card: Language & Theme
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
                          Icons.palette_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEn ? 'Appearance & Language' : 'Apariencia e Idioma',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: headingColor,
                              ),
                            ),
                            Text(
                              isEn
                                  ? 'Configure theme mode and UI language'
                                  : 'Configura el modo oscuro/claro y el idioma',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Language selector: ES / EN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.language_rounded, size: 20, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            isEn ? 'Language / Idioma' : 'Idioma / Language',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      SegmentedButton<AppLanguage>(
                        segments: const [
                          ButtonSegment<AppLanguage>(
                            value: AppLanguage.es,
                            label: Text('ES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          ButtonSegment<AppLanguage>(
                            value: AppLanguage.en,
                            label: Text('EN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                        selected: {currentLang},
                        onSelectionChanged: (newSelection) {
                          ref.read(languageProvider.notifier).setLanguage(newSelection.first);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Theme selector: Light / Dark
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              currentTheme == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isEn ? 'Theme' : 'Tema',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SegmentedButton<ThemeMode>(
                        style: const ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        segments: [
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            icon: const Icon(Icons.wb_sunny_outlined, size: 15),
                            label: Text(isEn ? 'Light' : 'Claro', style: const TextStyle(fontSize: 11)),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            icon: const Icon(Icons.nightlight_round, size: 15),
                            label: Text(isEn ? 'Dark' : 'Oscuro', style: const TextStyle(fontSize: 11)),
                          ),
                        ],
                        selected: {currentTheme == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light},
                        onSelectionChanged: (newSelection) {
                          ref.read(themeModeProvider.notifier).setTheme(newSelection.first);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMd),

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
                          user?.displayName ?? (isEn ? 'User' : 'Usuario'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: headingColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '—',
                          style: TextStyle(
                            fontSize: 13,
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMd),

            // Security & 2FA Section
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
                          Icons.security_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEn ? 'Account Security' : 'Seguridad de la Cuenta',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: headingColor,
                              ),
                            ),
                            Text(
                              isEn
                                  ? '2FA (TOTP), master password & active sessions'
                                  : '2FA (TOTP), contraseñas y sesiones activas',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // 2FA row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isEn ? 'Two-Factor (2FA)' : '2 Pasos (2FA)',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (user?.twoFactorEnabled ?? false)
                                        ? AppColors.safeSubtle
                                        : AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(AppRadii.full),
                                  ),
                                  child: Text(
                                    (user?.twoFactorEnabled ?? false)
                                        ? (isEn ? 'ACTIVE' : 'ACTIVO')
                                        : (isEn ? 'OFF' : 'OFF'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: (user?.twoFactorEnabled ?? false)
                                          ? AppColors.safeText
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEn
                                  ? 'Protects critical actions like wipe and deactivating theft mode'
                                  : 'Protege acciones sensibles como el borrado y desactivación de robo',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (user?.twoFactorEnabled ?? false)
                        TextButton(
                          onPressed: () => _showDisable2FaDialog(),
                          style: TextButton.styleFrom(foregroundColor: AppColors.alert),
                          child: Text(isEn ? 'Disable' : 'Desactivar'),
                        )
                      else
                        OutlinedButton(
                          onPressed: () => context.push('/2fa-setup'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            minimumSize: const Size(60, 32),
                          ),
                          child: Text(isEn ? 'Enable' : 'Activar', style: const TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Change password action
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.password_rounded, size: 20, color: AppColors.textMuted),
                    title: Text(
                      isEn ? 'Change Master Password' : 'Cambiar Contraseña Maestra',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () => _showChangePasswordDialog(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMd),

            // Active Sessions Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEn ? 'Active Sessions' : 'Sesiones Activas',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: headingColor,
                        ),
                      ),
                      if (sessionsState.sessions.isNotEmpty)
                        TextButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(isEn ? 'Close all sessions?' : '¿Cerrar todas las sesiones?'),
                                content: Text(
                                  isEn
                                      ? 'All active access tokens on any device will be revoked.'
                                      : 'Se revocarán todos los tokens de acceso activos en cualquier dispositivo.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(isEn ? 'Cancel' : 'Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: TextButton.styleFrom(foregroundColor: AppColors.alert),
                                    child: Text(isEn ? 'Close all' : 'Cerrar todas'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref.read(sessionsProvider.notifier).revokeAll();
                              if (context.mounted) context.go('/login');
                            }
                          },
                          child: Text(isEn ? 'Close all' : 'Cerrar todas', style: const TextStyle(fontSize: 12, color: AppColors.alert)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (sessionsState.isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                  else if (sessionsState.sessions.isEmpty)
                    Text(
                      isEn ? 'No other active sessions recorded.' : 'No hay otras sesiones activas registradas.',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    )
                  else
                    ...sessionsState.sessions.map((sess) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.devices_other_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sess.userAgent?.isNotEmpty ?? false ? sess.userAgent! : (isEn ? 'Guardian Device' : 'Dispositivo Guardian'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'ID: ${sess.id.length > 8 ? sess.id.substring(0, 8) : sess.id}...',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.alert),
                                onPressed: () => ref.read(sessionsProvider.notifier).revoke(sess.id),
                              ),
                            ],
                          ),
                        )),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEn ? 'Periodic Location Report' : 'Reporte Periódico de Ubicación',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: headingColor,
                              ),
                            ),
                            Text(
                              isEn
                                  ? 'Background service with active foreground notification'
                                  : 'Servicio en segundo plano con notificación activa',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
                        Text(
                          isEn ? 'Report frequency:' : 'Frecuencia de reporte:',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          isEn ? 'Every $_intervalMinutes min' : 'Cada $_intervalMinutes min',
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
                      divisions: 11,
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
                    Text(
                      isEn
                          ? 'Uses balanced power accuracy to save battery. The notification remains in status bar per Android system policy.'
                          : 'Usa precisión balanceada para ahorrar batería. La notificación "Guardian protege este teléfono" permanecerá visible en la barra de estado según las políticas del sistema.',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
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
                title: Text(
                  isEn ? 'Lock Protection & Permissions' : 'Protección y Permisos de Bloqueo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: headingColor,
                  ),
                ),
                subtitle: Text(
                  isEn
                      ? 'Configure Device Admin & Battery Optimization permissions'
                      : 'Configura permisos de Administrador de Dispositivo y Batería',
                  style: const TextStyle(fontSize: 12),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEn ? 'Backend Server (API)' : 'Servidor Backend (API)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: headingColor,
                              ),
                            ),
                            Text(
                              isEn
                                  ? 'Base URL for commands, daemon & sync'
                                  : 'URL base para órdenes, daemon y sincronización',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                          child: Text(isEn ? 'Change' : 'Cambiar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMd),

            // Privacy link
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
                    Icons.privacy_tip_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  isEn ? 'Privacy Policy & Data' : 'Información de Privacidad',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: headingColor,
                  ),
                ),
                subtitle: Text(
                  isEn ? 'Check what data is gathered and protected' : 'Consulta qué datos se recopilan y cómo se protegen',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/privacy'),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceSm),

            // App version info
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Guardian Mobile v1.0.0 (Release 10)',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMd),

            // Logout button
            DangerButton(
              text: isEn ? 'Secure Sign Out' : 'Cerrar Sesión Segura',
              icon: Icons.logout_rounded,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(isEn ? 'Sign Out?' : '¿Cerrar Sesión?'),
                    content: Text(
                      isEn
                          ? 'Your active session on this device will close and access tokens cleared.'
                          : 'Se cerrará tu sesión activa en este teléfono y se limpiarán los tokens de acceso.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(isEn ? 'Cancel' : 'Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.alert,
                        ),
                        child: Text(isEn ? 'Sign Out' : 'Cerrar Sesión'),
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
    ),
  );
  }

  Future<void> _showDisable2FaDialog() async {
    final passwordController = TextEditingController();
    final codeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar 2FA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa tu contraseña maestra y el código 2FA actual para confirmar.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña maestra'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(labelText: 'Código 2FA o de respaldo'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alert, foregroundColor: Colors.white),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (result == true) {
      final ok = await ref.read(twoFactorSetupProvider.notifier).disable(
            password: passwordController.text,
            twoFactorCode: codeController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '2FA desactivado correctamente.' : 'Error al desactivar 2FA.'),
            backgroundColor: ok ? AppColors.safe : AppColors.alert,
          ),
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña actual'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva contraseña'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (currentPassController.text.isEmpty || newPassController.text.length < 8) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('La nueva contraseña debe tener al menos 8 caracteres.')),
                );
                return;
              }
              final ok = await ref.read(changePasswordProvider.notifier).changePassword(
                    currentPassword: currentPassController.text,
                    newPassword: newPassController.text,
                  );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Contraseña actualizada. Vuelve a iniciar sesión.' : 'Error al cambiar contraseña.'),
                    backgroundColor: ok ? AppColors.safe : AppColors.alert,
                  ),
                );
                if (ok) {
                  ref.read(authNotifierProvider.notifier).logout();
                  if (mounted) context.go('/login');
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
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
              'Ingresa la dirección IP o dominio del backend (ej. http://192.168.1.9:3000):',
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
