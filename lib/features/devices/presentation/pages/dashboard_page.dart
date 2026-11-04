import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/language_provider.dart';
import '../../../../core/motion/guardian_motion.dart';
import '../../../../core/theme/guardian_theme.dart';
import '../../../../core/theme/guardian_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/guardian_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../commands/presentation/providers/command_provider.dart';
import '../../domain/entities/device.dart';
import '../providers/devices_provider.dart';

/// Home screen, built on the Guardian Mobile design system
/// (tokens + motion + widgets in lib/core).
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(devicesNotifierProvider.notifier).loadDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final state = ref.watch(devicesNotifierProvider);
    final isEn = ref.watch(languageProvider) == AppLanguage.en;

    return Scaffold(
      appBar: _buildAppBar(context, user?.displayName, isEn),
      body: SafeArea(
        child: RefreshIndicator(
          color: context.gm.brand,
          onRefresh: () => ref.read(devicesNotifierProvider.notifier).loadDevices(),
          child: AnimatedSwitcher(
            duration: GMotion.d(context, GMotion.base),
            switchInCurve: GMotion.enter,
            switchOutCurve: GMotion.exit,
            child: _buildBody(context, state, isEn),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, isEn, state.thisPhoneDevice),
    );
  }

  // ─────────────────────────────── App bar ───────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, String? displayName, bool isEn) {
    final c = context.gm;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = (displayName != null && displayName.trim().isNotEmpty) ? displayName.trim() : null;
    final firstName = name?.split(' ').first;
    final initial = name != null ? name[0].toUpperCase() : 'G';

    return AppBar(
      titleSpacing: GSpace.s4,
      title: Row(children: [
        const IconBox(Icons.shield_rounded, size: 40),
        const SizedBox(width: GSpace.s3),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Guardian', style: context.text.titleLarge),
            Text(
              firstName != null ? (isEn ? 'Hi, $firstName' : 'Hola, $firstName') : (isEn ? 'Security' : 'Seguridad'),
              style: context.text.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
        ),
      ]),
      actions: [
        _AppBarAction(
          tooltip: isEn ? 'Switch to Spanish' : 'Cambiar a inglés',
          onTap: () => ref.read(languageProvider.notifier).toggleLanguage(),
          child: Text(isEn ? 'EN' : 'ES', style: context.text.labelLarge?.copyWith(color: c.brandInk, fontSize: 12)),
        ),
        _AppBarAction(
          tooltip: isEn ? 'Toggle theme' : 'Cambiar tema',
          onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          child: AnimatedSwitcher(
            duration: GMotion.base,
            transitionBuilder: (child, a) => RotationTransition(
              turns: Tween(begin: .75, end: 1.0).animate(a),
              child: FadeTransition(opacity: a, child: child),
            ),
            child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark), size: 20, color: c.ink),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: GSpace.s3, left: GSpace.s1),
          child: PopupMenuButton<String>(
            tooltip: isEn ? 'Account' : 'Cuenta',
            offset: const Offset(0, 52),
            shape: RoundedRectangleBorder(borderRadius: GRadius.rMd),
            icon: CircleAvatar(
              radius: 17,
              backgroundColor: c.brand,
              child: Text(initial, style: context.text.labelLarge?.copyWith(color: c.onBrand)),
            ),
            onSelected: (value) async {
              if (value == 'settings') {
                context.push('/settings');
              } else if (value == 'logout') {
                await _confirmLogout(context, isEn);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name ?? (isEn ? 'User' : 'Usuario'), style: context.text.titleMedium),
                  Text('Guardian Mobile', style: context.text.bodySmall),
                ]),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(children: [
                  Icon(Icons.settings_outlined, size: 20, color: c.brandInk),
                  const SizedBox(width: GSpace.s3),
                  Text(isEn ? 'Settings & profile' : 'Ajustes y perfil'),
                ]),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout_rounded, size: 20, color: c.dangerInk),
                  const SizedBox(width: GSpace.s3),
                  Text(isEn ? 'Sign out' : 'Cerrar sesión',
                      style: TextStyle(color: c.dangerInk, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────── Body ───────────────────────────────

  Widget _buildBody(BuildContext context, DevicesDashboardState state, bool isEn) {
    if (state.isLoading && state.devices.isEmpty) {
      return Center(
        key: const ValueKey('loading'),
        child: PulsingDot(color: context.gm.brand, size: 18),
      );
    }

    if (state.errorMessage != null && state.devices.isEmpty) {
      return _ScrollList(
        key: const ValueKey('error'),
        sections: [
          const SizedBox(height: GSpace.s12),
          _ErrorState(
            message: state.errorMessage!,
            retryLabel: isEn ? 'Retry' : 'Reintentar',
            onRetry: () => ref.read(devicesNotifierProvider.notifier).loadDevices(),
          ),
        ],
      );
    }

    final thisPhone = state.thisPhoneDevice;
    final others = state.otherDevices;
    final total = state.devices.length;
    final theftActive = state.devices.any((d) => d.theftModeActive);
    final target = thisPhone ?? (state.devices.isNotEmpty ? state.devices.first : null);

    if (total == 0) {
      return _ScrollList(
        key: const ValueKey('empty'),
        sections: [
          ShieldBanner(
            devices: 0,
            title: isEn ? 'Shield not active yet' : 'Escudo aún no activo',
            subtitle:
                isEn ? 'Link this phone to start protecting it' : 'Vincula este celular para empezar a protegerlo',
          ),
          _EmptyState(isEn: isEn),
        ],
      );
    }

    return _ScrollList(
      key: const ValueKey('content'),
      sections: [
        ShieldBanner(
          devices: total,
          theftMode: theftActive,
          title: isEn ? (theftActive ? 'Theft Mode active' : 'Shield active') : null,
          subtitle: isEn
              ? (theftActive
                  ? 'Tracking every 30 s · screen locked'
                  : '$total ${total == 1 ? 'device' : 'devices'} under watch')
              : null,
        ),
        if (thisPhone != null)
          _PrimaryDeviceCard(
            device: thisPhone,
            isEn: isEn,
            onDelete: () => _confirmDeleteDevice(context, thisPhone, isEn),
          )
        else
          _LinkPrompt(isEn: isEn),
        if (target != null) ...[
          _SectionLabel(isEn
              ? 'QUICK ACTIONS${thisPhone == null ? ' · ${target.name.toUpperCase()}' : ''}'
              : 'ACCIONES RÁPIDAS${thisPhone == null ? ' · ${target.name.toUpperCase()}' : ''}'),
          _QuickActions(
            device: target,
            isEn: isEn,
            onRing: () => _sendRing(target, isEn),
            onVibrate: () => _sendVibrate(target, isEn),
            onMessage: () => _sendMessage(context, target, isEn),
            onLock: () => _sendLock(context, target, isEn),
          ),
        ],
        _SectionLabel(
          isEn ? 'OTHER DEVICES' : 'OTROS DISPOSITIVOS',
          trailing: others.isEmpty ? null : '${others.length}',
        ),
        if (others.isEmpty)
          _NoOtherDevices(isEn: isEn)
        else
          for (final d in others)
            _SecondaryDeviceCard(
              device: d,
              isEn: isEn,
              onDelete: () => _confirmDeleteDevice(context, d, isEn),
            ),
        _EmergencyCard(device: target, isEn: isEn, theftActive: target?.theftModeActive ?? false),
      ],
    );
  }

  // ─────────────────────────────── Bottom nav ───────────────────────────────

  Widget _buildBottomNavigationBar(BuildContext context, bool isEn, Device? thisPhone) {
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: context.gm.border))),
      child: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) async {
          setState(() => _currentNavIndex = index);
          if (index == 1) {
            await context.push(thisPhone != null ? '/device-detail' : '/link-device', extra: thisPhone);
          } else if (index == 2) {
            await context.push(thisPhone != null ? '/device-map' : '/link-device', extra: thisPhone);
          } else if (index == 3) {
            await context.push('/settings');
          }
          if (mounted) setState(() => _currentNavIndex = 0);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.smartphone_outlined),
            selectedIcon: const Icon(Icons.smartphone_rounded),
            label: isEn ? 'Devices' : 'Dispositivos',
          ),
          NavigationDestination(
            icon: const Icon(Icons.bolt_outlined),
            selectedIcon: const Icon(Icons.bolt_rounded),
            label: isEn ? 'Actions' : 'Acciones',
          ),
          NavigationDestination(
            icon: const Icon(Icons.location_on_outlined),
            selectedIcon: const Icon(Icons.location_on_rounded),
            label: isEn ? 'Map' : 'Mapa',
          ),
          NavigationDestination(
            icon: const Icon(Icons.manage_accounts_outlined),
            selectedIcon: const Icon(Icons.manage_accounts_rounded),
            label: isEn ? 'Account' : 'Cuenta',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────── Commands ───────────────────────────────

  CommandNotifier get _commands => ref.read(commandNotifierProvider.notifier);

  void _snack(String text, {bool error = false}) {
    if (!mounted) return;
    final c = context.gm;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: error ? c.danger : null,
      ));
  }

  /// Shows the result of a send and returns whether it succeeded.
  bool _report(bool ok, String successText) {
    if (ok) {
      _snack(successText);
    } else {
      final err = ref.read(commandNotifierProvider).errorMessage;
      _snack(err ?? 'Error al enviar la orden.', error: true);
    }
    return ok;
  }

  Future<bool> _sendRing(Device d, bool isEn) async {
    final ok = await _commands.sendRingCommand(deviceId: d.id);
    return _report(ok, isEn ? 'Ringing "${d.name}"' : 'Sonando en "${d.name}"');
  }

  Future<bool> _sendVibrate(Device d, bool isEn) async {
    final ok = await _commands.sendVibrateCommand(deviceId: d.id);
    return _report(ok, isEn ? 'Vibrating "${d.name}"' : 'Vibrando "${d.name}"');
  }

  Future<bool> _sendMessage(BuildContext context, Device d, bool isEn) async {
    final controller = TextEditingController();
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(GSpace.s5, 0, GSpace.s5, MediaQuery.of(ctx).viewInsets.bottom + GSpace.s6),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isEn ? 'Message on screen' : 'Mensaje en pantalla', style: ctx.text.headlineSmall),
          const SizedBox(height: GSpace.s1),
          Text(
            isEn ? 'It will appear on "${d.name}".' : 'Aparecerá en la pantalla de "${d.name}".',
            style: ctx.text.bodyMedium,
          ),
          const SizedBox(height: GSpace.s4),
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: 200,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: isEn ? 'E.g. This phone is lost, please call…' : 'Ej. Este celular está perdido, llama al…',
              prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
            ),
          ),
          const SizedBox(height: GSpace.s3),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              icon: const Icon(Icons.send_rounded),
              label: Text(isEn ? 'Send message' : 'Enviar mensaje'),
            ),
          ),
        ]),
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty) return false;
    final ok = await _commands.sendMessageCommand(deviceId: d.id, text: text);
    return _report(ok, isEn ? 'Message sent' : 'Mensaje enviado');
  }

  Future<bool> _sendLock(BuildContext context, Device d, bool isEn) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(GSpace.s5, 0, GSpace.s5, GSpace.s6),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const IconBox(Icons.lock_outline_rounded),
            const SizedBox(width: GSpace.s3),
            Expanded(child: Text(isEn ? 'Lock "${d.name}"?' : '¿Bloquear "${d.name}"?', style: ctx.text.headlineSmall)),
          ]),
          const SizedBox(height: GSpace.s3),
          Text(
            isEn
                ? 'The screen turns off and the PIN or pattern will be required to use it.'
                : 'La pantalla se apagará y se pedirá el PIN o patrón para volver a usarlo.',
            style: ctx.text.bodyLarge,
          ),
          const SizedBox(height: GSpace.s5),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.lock_rounded),
              label: Text(isEn ? 'Lock now' : 'Bloquear ahora'),
            ),
          ),
          const SizedBox(height: GSpace.s2),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isEn ? 'Cancel' : 'Cancelar'),
            ),
          ),
        ]),
      ),
    );
    if (confirm != true) return false;
    final ok = await _commands.sendLockCommand(deviceId: d.id);
    return _report(ok, isEn ? 'Lock command sent' : 'Orden de bloqueo enviada');
  }

  // ─────────────────────────────── Dialogs ───────────────────────────────

  Future<void> _confirmLogout(BuildContext context, bool isEn) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEn ? 'Sign out?' : '¿Cerrar sesión?'),
        content: Text(isEn
            ? 'You will need to sign in again to control your devices.'
            : 'Tendrás que iniciar sesión otra vez para controlar tus dispositivos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isEn ? 'Cancel' : 'Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.gm.dangerInk),
            child: Text(isEn ? 'Sign out' : 'Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }

  Future<void> _confirmDeleteDevice(BuildContext context, Device device, bool isEn) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(GSpace.s5, 0, GSpace.s5, GSpace.s6),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const IconBox(Icons.delete_outline_rounded, danger: true),
            const SizedBox(width: GSpace.s3),
            Expanded(
              child: Text(isEn ? 'Remove "${device.name}"?' : '¿Eliminar "${device.name}"?',
                  style: ctx.text.headlineSmall),
            ),
          ]),
          const SizedBox(height: GSpace.s3),
          Text(
            isEn
                ? 'The device will be unlinked from your account and stop being protected.'
                : 'El dispositivo se desvinculará de tu cuenta y dejará de estar protegido.',
            style: ctx.text.bodyLarge,
          ),
          const SizedBox(height: GSpace.s5),
          HoldToConfirmButton(
            label: isEn ? 'Hold to remove' : 'Mantén presionado para eliminar',
            onConfirmed: () => Navigator.pop(ctx, true),
          ),
          const SizedBox(height: GSpace.s2),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isEn ? 'Cancel' : 'Cancelar'),
            ),
          ),
        ]),
      ),
    );

    if (confirm == true) {
      final success = await ref.read(devicesNotifierProvider.notifier).unlinkDevice(device.id);
      _snack(
        success
            ? (isEn ? 'Device removed' : 'Dispositivo eliminado')
            : (isEn ? 'Could not remove the device' : 'No se pudo eliminar el dispositivo'),
        error: !success,
      );
    }
  }
}

// ═══════════════════════════════ Sections ═══════════════════════════════

/// Scrollable list whose sections enter one after another.
class _ScrollList extends StatelessWidget {
  const _ScrollList({super.key, required this.sections});
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) => ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(GSpace.s4, GSpace.s2, GSpace.s4, GSpace.s8),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: GSpace.s4),
        itemBuilder: (_, i) => StaggeredIn(index: i, child: sections[i]),
      );
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({required this.tooltip, required this.onTap, required this.child});
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Pressable(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.gm.surfaceSunken,
              borderRadius: BorderRadius.circular(GRadius.md),
            ),
            child: child,
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.trailing});
  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: GSpace.s2),
        child: Row(children: [
          Expanded(child: Text(text, style: context.text.labelSmall, overflow: TextOverflow.ellipsis)),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: context.gm.brandSoft,
                borderRadius: BorderRadius.circular(GRadius.pill),
              ),
              child: Text(trailing!, style: context.text.bodySmall?.copyWith(color: context.gm.brandInk)),
            ),
        ]),
      );
}

// ─────────────────────────────── Primary device ───────────────────────────────

class _PrimaryDeviceCard extends StatelessWidget {
  const _PrimaryDeviceCard({required this.device, required this.isEn, required this.onDelete});
  final Device device;
  final bool isEn;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final d = device;
    final os = [
      d.platform == 'ios' ? 'iOS' : 'Android',
      if (d.osVersion != null && d.osVersion!.isNotEmpty)
        d.osVersion!.replaceFirst(RegExp(r'^(Android|iOS)\s*', caseSensitive: false), ''),
    ].join(' ');

    // Not wrapped in Pressable: it contains its own tappable children
    // (map preview, buttons) and nested press-scales would fight.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GSpace.s5),
        child: Column(children: [
          Row(children: [
            IconBox(d.platform == 'ios' ? Icons.phone_iphone_rounded : Icons.smartphone_rounded, size: 56),
            const SizedBox(width: GSpace.s4),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.name, style: context.text.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${isEn ? 'This phone' : 'Este teléfono'} · $os',
                    style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            _DeviceStatusBadge(device: d, isEn: isEn),
          ]),
          const SizedBox(height: GSpace.s4),
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: _BatteryMetric(device: d, isEn: isEn)),
              const SizedBox(width: GSpace.s3),
              Expanded(child: _NetworkMetric(device: d, isEn: isEn)),
            ]),
          ),
          const SizedBox(height: GSpace.s4),
          _MapPreview(device: d, isEn: isEn),
          const SizedBox(height: GSpace.s2),
          Row(children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => context.push('/device-detail', extra: d),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(isEn ? 'Manage' : 'Gestionar'),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: onDelete,
                style: TextButton.styleFrom(foregroundColor: context.gm.dangerInk),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(isEn ? 'Remove' : 'Eliminar'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _DeviceStatusBadge extends StatelessWidget {
  const _DeviceStatusBadge({required this.device, required this.isEn});
  final Device device;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    if (device.theftModeActive) {
      return StatusBadge(isEn ? 'Theft mode' : 'Modo robo', tone: GTone.danger, live: true);
    }
    if (device.mode == DeviceMode.controller) {
      return StatusBadge(isEn ? 'Controller' : 'Controlador', tone: GTone.neutral);
    }
    if (!device.isOnline) {
      return StatusBadge(isEn ? 'Offline' : 'Sin conexión', tone: GTone.neutral);
    }
    return StatusBadge(isEn ? 'Protected' : 'Protegido', live: true);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value, this.progress, this.iconColor});
  final IconData icon;
  final String label;
  final Widget value;
  final double? progress;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = context.gm;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GSpace.s4, vertical: GSpace.s3),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(GRadius.sm)),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(children: [
          Icon(icon, size: 18, color: iconColor ?? c.brandInk),
          const SizedBox(width: GSpace.s2),
          Expanded(child: value),
        ]),
        const SizedBox(height: 2),
        Text(label, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (progress != null) ...[
          const SizedBox(height: GSpace.s2),
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress!.clamp(0, 1)),
            duration: GMotion.d(context, GMotion.slow * 2),
            curve: GMotion.enter,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(GRadius.pill),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: c.border,
                color: progress! < .2 ? c.warning : c.brand,
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _BatteryMetric extends StatelessWidget {
  const _BatteryMetric({required this.device, required this.isEn});
  final Device device;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final level = device.batteryLevel;
    final charging = device.isCharging ?? false;
    final low = level != null && level < 20;
    return _Metric(
      icon: charging
          ? Icons.battery_charging_full_rounded
          : (low ? Icons.battery_alert_rounded : Icons.battery_std_rounded),
      iconColor: low && !charging ? context.gm.warning : null,
      label: charging ? (isEn ? 'Charging' : 'Cargando') : (isEn ? 'Battery' : 'Batería'),
      value: level != null
          ? CountUp(value: level, suffix: '%', style: context.text.titleLarge)
          : Text('—', style: context.text.titleLarge),
      progress: level != null ? level / 100 : null,
    );
  }
}

class _NetworkMetric extends StatelessWidget {
  const _NetworkMetric({required this.device, required this.isEn});
  final Device device;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (device.networkType) {
      'wifi' => (Icons.wifi_rounded, 'Wi-Fi'),
      'mobile' => (Icons.signal_cellular_alt_rounded, isEn ? 'Mobile' : 'Datos'),
      'none' => (Icons.signal_wifi_off_rounded, isEn ? 'No network' : 'Sin red'),
      _ => (Icons.sensors_rounded, isEn ? 'Unknown' : 'Desconocida'),
    };
    final online = device.isOnline;
    return _Metric(
      icon: icon,
      iconColor: online ? null : context.gm.inkSubtle,
      label:
          '${online ? (isEn ? 'Online' : 'En línea') : (isEn ? 'Offline' : 'Sin conexión')} · ${formatLastSeen(device.lastSeenAt, isEn)}',
      value: Text(label, style: context.text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.device, required this.isEn});
  final Device device;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final c = context.gm;
    final loc = device.lastLocation;
    return Pressable(
      onTap: () => context.push('/device-map', extra: device),
      child: Container(
        height: 168,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius: GRadius.rLg,
          border: Border.all(color: c.border),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _MapGridPainter(c.border))),
          Center(child: PulsingDot(color: loc != null ? c.brand : c.inkSubtle, size: 18, live: loc != null)),
          Positioned(
            left: GSpace.s3,
            right: GSpace.s3,
            bottom: GSpace.s3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: GSpace.s3, vertical: GSpace.s2),
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: .94),
                borderRadius: GRadius.rMd,
                border: Border.all(color: c.border),
              ),
              child: Row(children: [
                Icon(Icons.near_me_rounded, size: 16, color: c.brandInk),
                const SizedBox(width: GSpace.s2),
                Expanded(
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      loc != null
                          ? '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}'
                          : (isEn ? 'No location yet' : 'Sin ubicación aún'),
                      style: loc != null ? GuardianTheme.mono(context) : context.text.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (loc != null)
                      Text(
                        [
                          formatLastSeen(loc.recordedAt, isEn),
                          if (loc.accuracyMeters != null) '±${loc.accuracyMeters!.toStringAsFixed(0)} m',
                        ].join(' · '),
                        style: context.text.bodySmall,
                      ),
                  ]),
                ),
                Text(isEn ? 'Map' : 'Mapa', style: context.text.labelLarge?.copyWith(color: c.brandInk)),
                Icon(Icons.chevron_right_rounded, color: c.brandInk, size: 20),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Subtle street-grid illustration behind the location marker.
class _MapGridPainter extends CustomPainter {
  _MapGridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = color
      ..strokeWidth = 1;
    final road = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), thin);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), thin);
    }
    canvas.drawLine(Offset(0, size.height * .62), Offset(size.width, size.height * .38), road);
    canvas.drawLine(Offset(size.width * .3, 0), Offset(size.width * .42, size.height), road);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter old) => old.color != color;
}

// ─────────────────────────────── Quick actions ───────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.device,
    required this.isEn,
    required this.onRing,
    required this.onVibrate,
    required this.onMessage,
    required this.onLock,
  });
  final Device device;
  final bool isEn;
  final Future<bool> Function() onRing, onVibrate, onMessage, onLock;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ActionTile(
        icon: Icons.volume_up_rounded,
        title: isEn ? 'Ring' : 'Hacer sonar',
        subtitle: isEn ? 'Even on silent' : 'Incluso en silencio',
        runFor: const Duration(seconds: 8),
        onTap: onRing,
      ),
      ActionTile(
        icon: Icons.vibration_rounded,
        title: isEn ? 'Vibrate' : 'Vibrar',
        subtitle: isEn ? 'For 5 seconds' : 'Durante 5 segundos',
        runFor: const Duration(seconds: 5),
        onTap: onVibrate,
      ),
      ActionTile(
        icon: Icons.chat_bubble_outline_rounded,
        title: isEn ? 'Message' : 'Mensaje',
        subtitle: isEn ? 'On the screen' : 'En la pantalla',
        onTap: onMessage,
      ),
      ActionTile(
        icon: Icons.lock_outline_rounded,
        title: isEn ? 'Lock' : 'Bloquear',
        subtitle: isEn ? 'Instantly' : 'Al instante',
        onTap: onLock,
      ),
    ];
    // Two columns; rows size to content so larger text never overflows.
    return Column(children: [
      for (var r = 0; r < tiles.length; r += 2) ...[
        if (r > 0) const SizedBox(height: GSpace.s3),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: tiles[r]),
            const SizedBox(width: GSpace.s3),
            Expanded(child: tiles[r + 1]),
          ]),
        ),
      ],
    ]);
  }
}

// ─────────────────────────────── Other devices ───────────────────────────────

class _SecondaryDeviceCard extends StatelessWidget {
  const _SecondaryDeviceCard({required this.device, required this.isEn, required this.onDelete});
  final Device device;
  final bool isEn;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final d = device;
    final c = context.gm;
    final icon = switch (d.platform) {
      'ios' => Icons.phone_iphone_rounded,
      'windows' || 'macos' => Icons.laptop_mac_rounded,
      _ => Icons.smartphone_rounded,
    };
    final details = [
      if (d.isOnline)
        isEn ? 'Online' : 'En línea'
      else if (d.lastSeenAt != null)
        isEn ? 'Seen ${formatLastSeen(d.lastSeenAt, isEn)}' : 'Visto ${formatLastSeen(d.lastSeenAt, isEn)}'
      else
        isEn ? 'Offline' : 'Desconectado',
      if (d.batteryLevel != null) '${d.batteryLevel}%',
    ].join(' · ');

    return Pressable(
      onTap: () => context.push('/device-detail', extra: d),
      onLongPress: onDelete,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(GSpace.s4, GSpace.s3, GSpace.s2, GSpace.s3),
          child: Row(children: [
            IconBox(icon, danger: d.theftModeActive),
            const SizedBox(width: GSpace.s3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.name, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(details, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            _DeviceStatusBadge(device: d, isEn: isEn),
            Icon(Icons.chevron_right_rounded, color: c.inkSubtle),
          ]),
        ),
      ),
    );
  }
}

class _NoOtherDevices extends StatelessWidget {
  const _NoOtherDevices({required this.isEn});
  final bool isEn;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () => context.push('/link-device'),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(GSpace.s4),
            child: Row(children: [
              const IconBox(Icons.add_rounded),
              const SizedBox(width: GSpace.s3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isEn ? 'Add another device' : 'Agregar otro dispositivo', style: context.text.titleMedium),
                  Text(
                    isEn ? 'Protect a tablet or a family phone' : 'Protege una tablet o el celular de tu familia',
                    style: context.text.bodySmall,
                  ),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: context.gm.inkSubtle),
            ]),
          ),
        ),
      );
}

// ─────────────────────────────── Emergency ───────────────────────────────

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.device, required this.isEn, required this.theftActive});
  final Device? device;
  final bool isEn;
  final bool theftActive;

  @override
  Widget build(BuildContext context) {
    final c = context.gm;
    return Container(
      padding: const EdgeInsets.all(GSpace.s5),
      decoration: BoxDecoration(
        color: c.dangerSoft,
        borderRadius: GRadius.rLg,
        border: Border.all(color: c.danger.withValues(alpha: .35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const IconBox(Icons.gpp_maybe_rounded, danger: true),
          const SizedBox(width: GSpace.s3),
          Expanded(
            child: Text(
              theftActive
                  ? (isEn ? 'Theft mode is on' : 'Modo Robo activado')
                  : (isEn ? 'Lost your phone?' : '¿Perdiste el teléfono?'),
              style: context.text.titleMedium?.copyWith(color: c.dangerInk),
            ),
          ),
        ]),
        const SizedBox(height: GSpace.s2),
        Text(
          theftActive
              ? (isEn
                  ? 'Tracking every 30 seconds. Open it to follow or turn it off.'
                  : 'Rastreando cada 30 segundos. Ábrelo para seguirlo o desactivarlo.')
              : (isEn
                  ? 'Lock it and track it every 30 seconds. Reversible.'
                  : 'Bloquéalo y rastréalo cada 30 segundos. Reversible.'),
          style: context.text.bodyLarge,
        ),
        const SizedBox(height: GSpace.s4),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: c.danger, foregroundColor: c.onDanger),
            onPressed: () => device != null ? context.push('/theft-mode', extra: device) : context.push('/link-device'),
            icon: Icon(theftActive ? Icons.radar_rounded : Icons.my_location_rounded),
            label: Text(theftActive
                ? (isEn ? 'Open Theft Mode' : 'Abrir Modo Robo')
                : (isEn ? 'Activate Theft Mode' : 'Activar Modo Robo')),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────── Empty / error ───────────────────────────────

class _LinkPrompt extends StatelessWidget {
  const _LinkPrompt({required this.isEn});
  final bool isEn;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () => context.push('/link-device'),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(GSpace.s5),
            child: Row(children: [
              const IconBox(Icons.add_link_rounded, size: 56),
              const SizedBox(width: GSpace.s4),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isEn ? 'Link this phone' : 'Vincular este celular', style: context.text.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    isEn
                        ? 'Turn on remote protection and live status'
                        : 'Activa la protección remota y el estado en vivo',
                    style: context.text.bodyMedium,
                  ),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: context.gm.brandInk),
            ]),
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isEn});
  final bool isEn;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(GSpace.s6),
          child: Column(children: [
            const IconBox(Icons.phonelink_lock_rounded, size: 72),
            const SizedBox(height: GSpace.s4),
            Text(isEn ? 'No linked devices' : 'Sin dispositivos vinculados',
                style: context.text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: GSpace.s2),
            Text(
              isEn
                  ? 'Link this phone to ring it, lock it and see where it is from anywhere.'
                  : 'Vincula este celular para hacerlo sonar, bloquearlo y ver dónde está desde cualquier lugar.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: GSpace.s5),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/link-device'),
                icon: const Icon(Icons.add_link_rounded),
                label: Text(isEn ? 'Link this phone' : 'Vincular este celular'),
              ),
            ),
          ]),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.retryLabel, required this.onRetry});
  final String message, retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(children: [
        const IconBox(Icons.cloud_off_rounded, size: 72, danger: true),
        const SizedBox(height: GSpace.s4),
        Text(message, textAlign: TextAlign.center, style: context.text.titleMedium),
        const SizedBox(height: GSpace.s5),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(retryLabel)),
      ]);
}

/// "Justo ahora", "Hace 5 min", … Shared with other screens.
String formatLastSeen(DateTime? at, bool isEn) {
  if (at == null) return isEn ? 'no data' : 'sin datos';
  final diff = DateTime.now().difference(at);
  if (diff.inSeconds < 60) return isEn ? 'just now' : 'justo ahora';
  if (diff.inMinutes < 60) return isEn ? '${diff.inMinutes} min ago' : 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return isEn ? '${diff.inHours} h ago' : 'hace ${diff.inHours} h';
  return isEn ? '${diff.inDays} d ago' : 'hace ${diff.inDays} d';
}
