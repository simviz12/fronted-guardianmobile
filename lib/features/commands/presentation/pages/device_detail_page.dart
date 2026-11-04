import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../core/motion/guardian_motion.dart';
import '../../../../core/theme/guardian_theme.dart';
import '../../../../core/theme/guardian_tokens.dart';
import '../../../../core/widgets/guardian_widgets.dart';
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
            icon: Icon(Icons.map_rounded, color: context.gm.brand),
            tooltip: isEn ? 'View Tracking Map' : 'Ver Mapa de Rastreo',
            onPressed: () {
              context.push('/device-map', extra: widget.device);
            },
          ),
          IconButton(
            icon: Icon(Icons.history_rounded, color: context.gm.brand),
            tooltip: isEn ? 'Command History' : 'Historial de Órdenes',
            onPressed: () {
              context.push('/command-history', extra: widget.device);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: context.gm.danger),
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
                    color: context.gm.dangerSoft,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: context.gm.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: context.gm.dangerInk, size: 20),
                      const SizedBox(width: AppSpacing.spaceSm),
                      Expanded(
                        child: Text(
                          commandState.errorMessage!,
                          style: TextStyle(
                            color: context.gm.dangerInk,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: context.gm.dangerInk, size: 18),
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
                  Icon(Icons.flash_on_rounded, size: 18, color: context.gm.brand),
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
              _buildActionGrid(
                isEn: isEn,
                isProtectedMode: isProtectedMode,
                busy: commandState.isSubmitting || commandState.isPolling,
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
              color: context.gm.surfaceSunken,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(
              widget.device.platform == 'ios' ? Icons.apple_rounded : Icons.phone_android_rounded,
              color: context.gm.brand,
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
                  style: TextStyle(fontSize: 12, color: context.gm.inkMuted),
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

  /// Six quick actions as design-system [ActionTile]s, two per row.
  /// Tiles that can't run on this device render as [_DisabledTile].
  Widget _buildActionGrid({required bool isEn, required bool isProtectedMode, required bool busy}) {
    final d = widget.device;
    final notProtected = isEn ? 'Only for Protected mode' : 'Solo en modo Protegido';
    final notProtectedBadge = isEn ? 'Not protected' : 'No protegido';

    Widget guard(Widget tile, {required IconData icon, required String title}) => isProtectedMode
        ? tile
        : _DisabledTile(icon: icon, title: title, subtitle: notProtected, badge: notProtectedBadge);

    // While a command is in flight, ignore taps on command tiles.
    Future<bool> Function() whenIdle(Future<bool> Function() run) => () => busy ? Future.value(false) : run();

    final tiles = <Widget>[
      guard(
        ActionTile(
          icon: Icons.volume_up_rounded,
          title: isEn ? 'Ring' : 'Hacer sonar',
          subtitle: isEn ? 'Max volume, even on silent' : 'Máximo volumen, incluso en silencio',
          runFor: const Duration(seconds: 8),
          onTap: whenIdle(_confirmAndSendRing),
        ),
        icon: Icons.volume_up_rounded,
        title: isEn ? 'Ring' : 'Hacer sonar',
      ),
      guard(
        ActionTile(
          icon: Icons.vibration_rounded,
          title: isEn ? 'Vibrate' : 'Vibrar',
          subtitle: isEn ? 'Pick 1 to 30 seconds' : 'Elige de 1 a 30 segundos',
          onTap: whenIdle(_openVibrateDialog),
        ),
        icon: Icons.vibration_rounded,
        title: isEn ? 'Vibrate' : 'Vibrar',
      ),
      guard(
        ActionTile(
          icon: Icons.chat_bubble_outline_rounded,
          title: isEn ? 'Message' : 'Mensaje',
          subtitle: isEn ? 'Shown on the screen' : 'Se muestra en la pantalla',
          onTap: whenIdle(_openMessageBottomSheet),
        ),
        icon: Icons.chat_bubble_outline_rounded,
        title: isEn ? 'Message' : 'Mensaje',
      ),
      if (isProtectedMode && !d.adminEnabled)
        _DisabledTile(
          icon: Icons.lock_outline_rounded,
          title: isEn ? 'Lock' : 'Bloquear',
          subtitle: isEn
              ? 'Device Admin permission not granted'
              : 'Este dispositivo no ha activado el permiso de bloqueo',
          badge: isEn ? 'No permission' : 'Sin permiso',
        )
      else
        guard(
          ActionTile(
            icon: Icons.lock_outline_rounded,
            title: isEn ? 'Lock' : 'Bloquear',
            subtitle: isEn ? 'Locks the screen instantly' : 'Bloquea la pantalla al instante',
            onTap: whenIdle(_confirmAndSendLock),
          ),
          icon: Icons.lock_outline_rounded,
          title: isEn ? 'Lock' : 'Bloquear',
        ),
      guard(
        ActionTile(
          icon: Icons.my_location_rounded,
          title: isEn ? 'Locate' : 'Localizar',
          subtitle: isEn ? 'Live map and history' : 'Mapa en vivo e historial',
          navigates: true,
          onTap: () async {
            context.push('/device-map', extra: d);
            return false;
          },
        ),
        icon: Icons.my_location_rounded,
        title: isEn ? 'Locate' : 'Localizar',
      ),
      guard(
        ActionTile(
          icon: d.theftModeActive ? Icons.radar_rounded : Icons.gpp_maybe_rounded,
          title: isEn ? 'Theft Mode' : 'Modo Robo',
          subtitle: d.theftModeActive
              ? (isEn ? 'Active · tap to manage' : 'Activo · toca para gestionar')
              : (isEn ? 'Emergency lock & tracking' : 'Bloqueo y rastreo de emergencia'),
          danger: true,
          navigates: true,
          onTap: () async {
            context.push('/theft-mode', extra: d);
            return false;
          },
        ),
        icon: Icons.gpp_maybe_rounded,
        title: isEn ? 'Theft Mode' : 'Modo Robo',
      ),
    ];

    return Column(children: [
      for (var r = 0; r < tiles.length; r += 2) ...[
        if (r > 0) const SizedBox(height: GSpace.s3),
        StaggeredIn(
          index: r ~/ 2 + 1,
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: tiles[r]),
              const SizedBox(width: GSpace.s3),
              Expanded(child: tiles[r + 1]),
            ]),
          ),
        ),
      ],
    ]);
  }

  Future<bool> _confirmAndSendRing() async {
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
            style: TextButton.styleFrom(foregroundColor: context.gm.brand),
            child: Text(isEn ? 'Ring Now' : 'Hacer Sonar'),
          ),
        ],
      ),
    );

    if (confirm != true) return false;
    return ref.read(commandNotifierProvider.notifier).sendRingCommand(deviceId: widget.device.id);
  }

  Future<bool> _openVibrateDialog() async {
    int? seconds;
    // The dialog pops itself and then calls onConfirm, so `seconds` is set
    // by the time showDialog's future completes.
    await showDialog<void>(
      context: context,
      builder: (ctx) => VibrateDurationDialog(onConfirm: (s) => seconds = s),
    );
    if (seconds == null) return false;
    return ref
        .read(commandNotifierProvider.notifier)
        .sendVibrateCommand(deviceId: widget.device.id, durationSeconds: seconds!);
  }

  Future<bool> _openMessageBottomSheet() async {
    String? text;
    String? phone;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SendMessageBottomSheet(
        onSend: (t, p) {
          text = t;
          phone = p;
        },
      ),
    );
    if (text == null) return false;
    return ref
        .read(commandNotifierProvider.notifier)
        .sendMessageCommand(deviceId: widget.device.id, text: text!, contactPhone: phone);
  }

  Future<bool> _confirmAndSendLock() async {
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
            style: TextButton.styleFrom(foregroundColor: context.gm.danger),
            child: Text(isEn ? 'Lock Now' : 'Bloquear ahora'),
          ),
        ],
      ),
    );

    if (confirm != true) return false;
    return ref.read(commandNotifierProvider.notifier).sendLockCommand(deviceId: widget.device.id);
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
          color: context.gm.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.gm.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: context.gm.inkMuted,
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
                      color: context.gm.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEn
                        ? 'This device was already factory reset and erased'
                        : 'Este dispositivo ya fue restablecido y borrado de fábrica',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.gm.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.gm.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(
                isEn ? 'Device Erased' : 'Dispositivo Borrado',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: context.gm.inkMuted,
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
          color: context.gm.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.gm.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: context.gm.inkMuted,
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
                      color: context.gm.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEn ? 'Only available for Protected mode' : 'Solo disponible para dispositivos en modo Protegido',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.gm.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.gm.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(
                isEn ? 'Not protected' : 'No protegido',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: context.gm.inkMuted,
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
          color: context.gm.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.gm.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: context.gm.inkMuted,
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
                      color: context.gm.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEn
                        ? 'Admin permissions required for factory reset'
                        : 'Sin permisos de Administrador para restablecimiento',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.gm.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.gm.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(
                isEn ? 'Admin required' : 'Admin requerido',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: context.gm.inkMuted,
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
          color: context.gm.dangerSoft,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: context.gm.danger.withValues(alpha: 0.6),
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
                color: context.gm.dangerSoft,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: context.gm.danger,
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
                      color: context.gm.dangerInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEn ? 'Irreversible factory wipe protocol' : 'Restablecimiento de fábrica irreversible',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.gm.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: context.gm.danger, size: 14),
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
            style: FilledButton.styleFrom(backgroundColor: context.gm.danger),
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
              backgroundColor: context.gm.brand,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEn ? 'Failed to delete device' : 'Error al eliminar el celular'),
              backgroundColor: context.gm.danger,
            ),
          );
        }
      }
    }
  }
}

/// Design-system tile for an action that can't run on this device.
class _DisabledTile extends StatelessWidget {
  const _DisabledTile({required this.icon, required this.title, required this.subtitle, required this.badge});
  final IconData icon;
  final String title, subtitle, badge;

  @override
  Widget build(BuildContext context) {
    final c = context.gm;
    return Semantics(
      label: '$title. $subtitle',
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        padding: const EdgeInsets.all(GSpace.s4),
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius: GRadius.rLg,
          border: Border.all(color: c.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(GRadius.md)),
              child: Icon(icon, size: 22, color: c.inkSubtle),
            ),
            const Spacer(),
            Flexible(child: StatusBadge(badge, tone: GTone.neutral)),
          ]),
          const SizedBox(height: GSpace.s5),
          Text(title, style: context.text.titleMedium?.copyWith(color: c.inkMuted)),
          const SizedBox(height: 2),
          Text(subtitle, style: context.text.bodyMedium?.copyWith(color: c.inkSubtle)),
        ]),
      ),
    );
  }
}
