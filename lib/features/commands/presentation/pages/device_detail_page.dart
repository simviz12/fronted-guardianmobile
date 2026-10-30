import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../devices/domain/entities/device.dart';
import '../../../devices/presentation/providers/devices_provider.dart';
import '../providers/command_provider.dart';
import '../widgets/command_live_status_stepper.dart';
import '../widgets/send_message_bottom_sheet.dart';
import '../widgets/vibrate_duration_dialog.dart';

class DeviceDetailPage extends ConsumerStatefulWidget {
  final Device device;

  const DeviceDetailPage({
    super.key,
    required this.device,
  });

  @override
  ConsumerState<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends ConsumerState<DeviceDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commandNotifierProvider.notifier).clearActiveCommand();
      ref.read(commandNotifierProvider.notifier).clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    final commandState = ref.watch(commandNotifierProvider);
    final isProtectedMode = widget.device.mode == DeviceMode.protected;
    final isEn = ref.watch(languageProvider) == AppLanguage.en;
    final theme = Theme.of(context);
    final headingColor = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.medical_services_outlined, color: AppColors.primary),
            tooltip: isEn ? 'Connectivity Diagnostics' : 'Diagnóstico de Conectividad',
            onPressed: () {
              context.push('/device-diagnostics', extra: widget.device);
            },
          ),
          IconButton(
            icon: const Icon(Icons.map_rounded, color: AppColors.primary),
            tooltip: isEn ? 'View Tracking Map' : 'Ver Mapa de Rastreo',
            onPressed: () {
              context.push('/device-map', extra: widget.device);
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.primary),
            tooltip: isEn ? 'Command History' : 'Historial de Órdenes',
            onPressed: () {
              context.push('/command-history', extra: widget.device);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.alert),
            tooltip: isEn ? 'Delete Device' : 'Eliminar Celular',
            onPressed: () => _confirmDeleteDevice(context, isEn),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Device Info Header Card
              _buildDeviceHeaderCard(),
              const SizedBox(height: AppSpacing.spaceMd),

              // Live Command Status Stepper (if any active or recent command)
              if (commandState.activeCommand != null) ...[
                CommandLiveStatusStepper(command: commandState.activeCommand!),
                const SizedBox(height: AppSpacing.spaceMd),
              ],

              if (commandState.errorMessage != null && commandState.activeCommand == null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd, vertical: AppSpacing.spaceSm),
                  decoration: BoxDecoration(
                    color: AppColors.alertContainer,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.alert.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.alertText, size: 20),
                      const SizedBox(width: AppSpacing.spaceSm),
                      Expanded(
                        child: Text(
                          commandState.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.alertText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.alertText, size: 18),
                        onPressed: () {
                          ref.read(commandNotifierProvider.notifier).clearError();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceMd),
              ],

              // Banner / Section label
              Row(
                children: [
                  const Icon(Icons.flash_on_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    isEn ? 'IMMEDIATE TACTICAL ACTIONS' : 'ACCIONES TÁCTICAS INMEDIATAS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: headingColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spaceSm),

              // Grid of actions (Stitch design layout)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.spaceSm,
                crossAxisSpacing: AppSpacing.spaceSm,
                childAspectRatio: 0.88,
                children: [
                  // 1. HACER SONAR (Active if target is PROTECTED)
                  _buildRingActionTile(
                    isProtectedMode: isProtectedMode,
                    isLoading: commandState.isSubmitting || commandState.isPolling,
                  ),

                  // 2. VIBRAR (Active if target is PROTECTED)
                  _buildVibrateActionTile(
                    isProtectedMode: isProtectedMode,
                    isLoading: commandState.isSubmitting || commandState.isPolling,
                  ),

                  // 3. MOSTRAR MENSAJE (Active if target is PROTECTED)
                  _buildMessageActionTile(
                    isProtectedMode: isProtectedMode,
                    isLoading: commandState.isSubmitting || commandState.isPolling,
                  ),

                  // 4. BLOQUEAR (Active if target is PROTECTED, checks adminEnabled)
                  _buildLockActionTile(
                    isProtectedMode: isProtectedMode,
                    isAdminEnabled: widget.device.adminEnabled,
                    isLoading: commandState.isSubmitting || commandState.isPolling,
                  ),

                  // 5. LOCALIZAR (Active if target is PROTECTED, navigates to map)
                  _buildLocateActionTile(
                    isProtectedMode: isProtectedMode,
                  ),

                  // 6. MODO ROBO (Prominent action tile for Theft Mode)
                  _buildTheftModeActionTile(
                    isProtectedMode: isProtectedMode,
                    theftModeActive: widget.device.theftModeActive,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spaceSm),

              // 7. ZONA DE DESTRUCCIÓN IRREVERSIBLE (WIPE) - Full width card below grid
              _buildWipeActionTile(
                device: widget.device,
                isProtectedMode: isProtectedMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceHeaderCard() {
    final isEn = ref.watch(languageProvider) == AppLanguage.en;
    final theme = Theme.of(context);
    final headingColor = theme.colorScheme.onSurface;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(
              widget.device.platform == 'ios' ? Icons.apple_rounded : Icons.phone_android_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.device.model ?? (isEn ? 'Unspecified model' : 'Modelo no especificado')} • SO ${widget.device.osVersion ?? '—'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          StatusChip(
            label: widget.device.mode == DeviceMode.protected
                ? (isEn ? 'Protected' : 'Protegido')
                : (isEn ? 'Controller' : 'Controlador'),
            type: widget.device.mode == DeviceMode.protected ? StatusChipType.safe : StatusChipType.neutral,
          ),
        ],
      ),
    );
  }

  Widget _buildRingActionTile({
    required bool isProtectedMode,
    required bool isLoading,
  }) {
    final isEn = ref.watch(languageProvider) == AppLanguage.en;

    if (!isProtectedMode) {
      return _buildDisabledActionTile(
        title: isEn ? 'Ring' : 'Hacer sonar',
        subtitle: isEn
            ? 'Only available for Protected mode'
            : 'Solo disponible para dispositivos en modo Protegido',
        icon: Icons.volume_up_rounded,
        badgeLabel: isEn ? 'Not protected' : 'No protegido',
      );
    }

    return InkWell(
      onTap: isLoading ? null : _confirmAndSendRing,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 24),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Ring Alarm' : 'Hacer sonar',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEn ? 'Max volume even if device is muted' : 'Máximo volumen incluso si está en silencio',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    String badgeLabel = 'Próximamente',
  }) {
    final theme = Theme.of(context);
    final cardBg = theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : AppColors.surface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, color: theme.brightness == Brightness.dark ? const Color(0xFF94A3B8) : AppColors.textMuted, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.neutralBadge,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  badgeLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralBadgeText,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark ? Colors.white : AppColors.textHeadings,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.brightness == Brightness.dark ? const Color(0xFFE2E8F0) : AppColors.textMuted,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndSendRing() async {
    final isEn = ref.read(languageProvider) == AppLanguage.en;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEn ? 'Sound alarm?' : '¿Hacer sonar alarma?'),
        content: Text(
          isEn
              ? 'An alarm will ring at maximum volume on "${widget.device.name}", ignoring silent or vibrate mode.'
              : 'Se emitirá un sonido de alarma a máximo volumen en "${widget.device.name}", ignorando el modo silencio o vibración.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isEn ? 'Cancel' : 'Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(isEn ? 'Ring Now' : 'Hacer Sonar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(commandNotifierProvider.notifier)
          .sendRingCommand(deviceId: widget.device.id);
    }
  }

  Widget _buildVibrateActionTile({
    required bool isProtectedMode,
    required bool isLoading,
  }) {
    final isEn = ref.watch(languageProvider) == AppLanguage.en;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headingColor = isDark ? Colors.white : AppColors.textHeadings;
    final cardBg = isDark ? const Color(0xFF1E293B) : AppColors.surface;

    if (!isProtectedMode) {
      return _buildDisabledActionTile(
        title: isEn ? 'Vibrate' : 'Vibrar',
        subtitle: isEn
            ? 'Only available for Protected mode'
            : 'Solo disponible para dispositivos en modo Protegido',
        icon: Icons.vibration_rounded,
        badgeLabel: isEn ? 'Not protected' : 'No protegido',
      );
    }

    return InkWell(
      onTap: isLoading ? null : _openVibrateDialog,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(Icons.vibration_rounded, color: AppColors.primary, size: 24),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Vibrate' : 'Vibrar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEn ? 'Custom duration vibration (1-30 s)' : 'Vibración con duración ajustable (1-30 s)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : AppColors.textMuted,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageActionTile({
    required bool isProtectedMode,
    required bool isLoading,
  }) {
    final isEn = ref.watch(languageProvider) == AppLanguage.en;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headingColor = isDark ? Colors.white : AppColors.textHeadings;
    final cardBg = isDark ? const Color(0xFF1E293B) : AppColors.surface;

    if (!isProtectedMode) {
      return _buildDisabledActionTile(
        title: isEn ? 'Message' : 'Mensaje',
        subtitle: isEn
            ? 'Only available for Protected mode'
            : 'Solo disponible para dispositivos en modo Protegido',
        icon: Icons.message_rounded,
        badgeLabel: isEn ? 'Not protected' : 'No protegido',
      );
    }

    return InkWell(
      onTap: isLoading ? null : _openMessageBottomSheet,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(Icons.message_rounded, color: AppColors.primary, size: 24),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Message' : 'Mensaje',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEn ? 'Display on-screen banner & contact dialer' : 'Muestra texto y botón de llamada en pantalla',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : AppColors.textMuted,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openVibrateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => VibrateDurationDialog(
        onConfirm: (seconds) {
          ref
              .read(commandNotifierProvider.notifier)
              .sendVibrateCommand(deviceId: widget.device.id, durationSeconds: seconds);
        },
      ),
    );
  }

  void _openMessageBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SendMessageBottomSheet(
        onSend: (text, phone) {
          ref
              .read(commandNotifierProvider.notifier)
              .sendMessageCommand(deviceId: widget.device.id, text: text, contactPhone: phone);
        },
      ),
    );
  }

  Widget _buildLockActionTile({
    required bool isProtectedMode,
    required bool isAdminEnabled,
    required bool isLoading,
  }) {
    final isEn = ref.watch(languageProvider) == AppLanguage.en;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headingColor = isDark ? Colors.white : AppColors.textHeadings;
    final cardBg = isDark ? const Color(0xFF1E293B) : AppColors.surface;

    if (!isProtectedMode) {
      return _buildDisabledActionTile(
        title: isEn ? 'Lock' : 'Bloquear',
        subtitle: isEn
            ? 'Only available for Protected mode'
            : 'Solo disponible para dispositivos en modo Protegido',
        icon: Icons.lock_rounded,
        badgeLabel: isEn ? 'Not protected' : 'No protegido',
      );
    }

    if (!isAdminEnabled) {
      return _buildDisabledActionTile(
        title: isEn ? 'Lock' : 'Bloquear',
        subtitle: isEn
            ? 'Device Admin permission not granted'
            : 'Este dispositivo no ha activado el permiso de bloqueo',
        icon: Icons.lock_rounded,
        badgeLabel: isEn ? 'No permission' : 'Sin permiso',
      );
    }

    return InkWell(
      onTap: isLoading ? null : _confirmAndSendLock,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 24),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Lock' : 'Bloquear',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEn ? 'Instantly locks the screen remotely' : 'Bloquea la pantalla inmediatamente',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : AppColors.textMuted,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndSendLock() async {
    final isEn = ref.read(languageProvider) == AppLanguage.en;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEn ? 'Lock device now?' : '¿Bloquear dispositivo ahora?'),
        content: Text(
          isEn
              ? 'The screen on "${widget.device.name}" will turn off immediately and require the current PIN/pattern.'
              : 'La pantalla de "${widget.device.name}" se apagará de inmediato y exigirá el PIN o patrón de seguridad actual para poder acceder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isEn ? 'Cancel' : 'Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alert),
            child: Text(isEn ? 'Lock Now' : 'Bloquear ahora'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(commandNotifierProvider.notifier)
          .sendLockCommand(deviceId: widget.device.id);
    }
  }

  Widget _buildLocateActionTile({
    required bool isProtectedMode,
  }) {
    final isEn = ref.watch(languageProvider) == AppLanguage.en;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headingColor = isDark ? Colors.white : AppColors.textHeadings;
    final cardBg = isDark ? const Color(0xFF1E293B) : AppColors.surface;

    if (!isProtectedMode) {
      return _buildDisabledActionTile(
        title: isEn ? 'Locate' : 'Localizar',
        subtitle: isEn
            ? 'Only available for Protected mode'
            : 'Solo disponible para dispositivos en modo Protegido',
        icon: Icons.my_location_rounded,
      );
    }

    return InkWell(
      onTap: () {
        context.push('/device-map', extra: widget.device);
      },
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 24),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Locate' : 'Localizar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEn ? 'View real-time map & location history' : 'Ver mapa y rastreo en tiempo real',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : AppColors.textMuted,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTheftModeActionTile({
    required bool isProtectedMode,
    required bool theftModeActive,
  }) {
    final isEn = ref.watch(languageProvider) == AppLanguage.en;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headingColor = isDark ? Colors.white : AppColors.textHeadings;
    final defaultBg = isDark ? const Color(0xFF1E293B) : AppColors.surface;

    if (!isProtectedMode) {
      return _buildDisabledActionTile(
        title: isEn ? 'Theft Mode' : 'Modo Robo',
        subtitle: isEn
            ? 'Only available for Protected mode'
            : 'Solo disponible para dispositivos en modo Protegido',
        icon: Icons.shield_rounded,
        badgeLabel: isEn ? 'Not protected' : 'No protegido',
      );
    }

    final theftActiveBg = isDark ? const Color(0xFF2A1515) : AppColors.alertContainer;
    final theftActiveText = isDark ? const Color(0xFFFCA5A5) : AppColors.alertText;

    return InkWell(
      onTap: () {
        context.push('/theft-mode', extra: widget.device);
      },
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        decoration: BoxDecoration(
          color: theftModeActive ? theftActiveBg : defaultBg,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: theftModeActive ? (isDark ? const Color(0xFFEF4444) : AppColors.alert) : (isDark ? const Color(0xFF334155) : AppColors.primary.withValues(alpha: 0.5)),
            width: theftModeActive ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: theftModeActive ? Colors.red.withValues(alpha: isDark ? 0.2 : 0.08) : AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theftModeActive
                        ? (isDark ? const Color(0xFF450A0A) : AppColors.alertContainer)
                        : AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    color: theftModeActive ? (isDark ? const Color(0xFFFCA5A5) : AppColors.alert) : AppColors.primary,
                    size: 24,
                  ),
                ),
                if (theftModeActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.alert,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(
                      isEn ? 'ACTIVE' : 'ACTIVO',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Theft Mode' : 'Modo Robo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theftModeActive ? theftActiveText : headingColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  theftModeActive
                      ? (isEn ? 'Lost device protocol active' : 'Protocolo de extravío activo')
                      : (isEn ? 'Emergency lock & tracking' : 'Bloqueo y rastreo de emergencia'),
                  style: TextStyle(
                    fontSize: 11,
                    color: theftModeActive ? theftActiveText : (isDark ? Colors.white70 : AppColors.textMuted),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWipeActionTile({
    required Device device,
    required bool isProtectedMode,
  }) {
    final isWiped = device.wipedAt != null;
    final isEn = ref.watch(languageProvider) == AppLanguage.en;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isWiped) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Remote Wipe' : 'Borrado Remoto',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textHeadings,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEn
                        ? 'This device was already factory reset and erased'
                        : 'Este dispositivo ya fue restablecido y borrado de fábrica',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.neutralBadge,
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(
                isEn ? 'Device Erased' : 'Dispositivo Borrado',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutralBadgeText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!isProtectedMode) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Remote Wipe' : 'Borrado Remoto',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textHeadings,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEn
                        ? 'Only available for Protected mode'
                        : 'Solo disponible para dispositivos en modo Protegido',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.neutralBadge,
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(
                isEn ? 'Not protected' : 'No protegido',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutralBadgeText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!device.adminEnabled || !device.wipeEnabled) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Remote Wipe (Destruction Zone)' : 'Borrado Remoto (Zona de Destrucción)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textHeadings,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEn
                        ? 'Admin permissions required for factory reset'
                        : 'Sin permisos de Administrador para restablecimiento',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.neutralBadge,
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(
                isEn ? 'Admin required' : 'Admin requerido',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutralBadgeText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () {
        context.push('/wipe-wizard', extra: device);
      },
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A1515) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isDark ? const Color(0xFFEF4444) : AppColors.alert.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF450A0A) : AppColors.alertContainer,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: isDark ? const Color(0xFFFCA5A5) : AppColors.alert,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Destruction Zone (Remote Wipe)' : 'Zona de Destrucción (Wipe Remoto)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFCA5A5) : AppColors.alertText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEn ? 'Irreversible factory wipe protocol' : 'Restablecimiento de fábrica irreversible',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFFFECACA) : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: isDark ? const Color(0xFFFCA5A5) : AppColors.alert, size: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDevice(BuildContext context, bool isEn) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEn ? 'Delete Device' : 'Eliminar Celular'),
        content: Text(
          isEn
              ? 'Are you sure you want to delete "${widget.device.name}" from your account? This action cannot be undone.'
              : '¿Estás seguro de que deseas eliminar "${widget.device.name}" de tu cuenta? Esta acción desvinculará el dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isEn ? 'Cancel' : 'Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.alert),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isEn ? 'Delete' : 'Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(devicesNotifierProvider.notifier).unlinkDevice(widget.device.id);
      if (context.mounted) {
        if (success) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEn ? 'Device deleted successfully' : 'Celular eliminado correctamente'),
              backgroundColor: AppColors.safe,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEn ? 'Failed to delete device' : 'Error al eliminar el celular'),
              backgroundColor: AppColors.alert,
            ),
          );
        }
      }
    }
  }
}
