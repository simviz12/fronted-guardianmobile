import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/device.dart';
import '../providers/devices_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final dashboardState = ref.watch(devicesNotifierProvider);
    final isEn = ref.watch(languageProvider) == AppLanguage.en;

    return Scaffold(
      appBar: _buildAppBar(context, ref, user?.displayName, isEn),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(devicesNotifierProvider.notifier).loadDevices();
          },
          child: _buildBody(context, ref, dashboardState),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_link_rounded),
        label: Text(isEn ? 'Link Device' : 'Vincular Celular'),
        onPressed: () => context.push('/link-device'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref, String? displayName, bool isEn) {
    final initial = (displayName != null && displayName.isNotEmpty)
        ? displayName[0].toUpperCase()
        : 'U';

    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: false,
      titleSpacing: AppSpacing.marginMobile,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.spaceSm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hola, ${displayName ?? 'Usuario'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Guardian Mobile',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Quick Language Toggle: ES / EN
        IconButton(
          tooltip: 'Cambiar idioma / Change language',
          padding: const EdgeInsets.symmetric(horizontal: 4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.primary, width: 1.5),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              ref.watch(languageProvider) == AppLanguage.en ? 'EN' : 'ES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          onPressed: () {
            ref.read(languageProvider.notifier).toggleLanguage();
          },
        ),
        // Quick Theme Toggle: Dark / Light
        IconButton(
          tooltip: 'Cambiar tema (Oscuro / Claro)',
          padding: const EdgeInsets.symmetric(horizontal: 4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Icon(
            ref.watch(themeModeProvider) == ThemeMode.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            size: 20,
          ),
          onPressed: () {
            ref.read(themeModeProvider.notifier).toggleTheme();
          },
        ),
        // Profile Avatar Button (Direct link to Settings & Profile)
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: InkWell(
            onTap: () => context.push('/settings'),
            borderRadius: BorderRadius.circular(20),
            child: Tooltip(
              message: 'Mi Perfil y Ajustes',
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    DevicesDashboardState state,
  ) {
    final isEn = ref.watch(languageProvider) == AppLanguage.en;

    if (state.isLoading && state.devices.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.errorMessage != null && state.devices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.alertContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.alert,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.alertText,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceLg),
          Center(
            child: PrimaryButton(
              text: isEn ? 'Retry' : 'Reintentar',
              icon: Icons.refresh_rounded,
              onPressed: () =>
                  ref.read(devicesNotifierProvider.notifier).loadDevices(),
            ),
          ),
        ],
      );
    }

    if (state.devices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          const SizedBox(height: 60),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: const Icon(
                Icons.devices_other_rounded,
                size: 42,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spaceLg),
          Text(
            isEn ? 'No linked devices' : 'Sin dispositivos vinculados',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            isEn
                ? 'Link this phone now to protect it remotely or manage other devices.'
                : 'Vincula este celular ahora para protegerlo remotamente o administrar otros equipos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textBody,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceXl),
          PrimaryButton(
            text: isEn ? 'Link this Phone' : 'Vincular este Celular',
            icon: Icons.add_link_rounded,
            onPressed: () => context.push('/link-device'),
          ),
        ],
      );
    }

    final thisPhone = state.thisPhoneDevice;
    final otherDevices = state.otherDevices;
    final realtimeState = ref.watch(realtimeConnectionStateProvider).valueOrNull ?? RealtimeConnectionState.disconnected;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
        top: AppSpacing.spaceSm,
        bottom: 80,
      ),
      children: [
        // Realtime Reconnection subtle banner
        if (realtimeState != RealtimeConnectionState.connected) ...[
          _buildRealtimeDisconnectedBanner(isEn),
          const SizedBox(height: AppSpacing.spaceSm),
        ],

        // Global security summary banner
        _buildSummaryBanner(state.devices.length, isEn),
        const SizedBox(height: AppSpacing.spaceMd),

        // THIS PHONE CARD (If linked)
        if (thisPhone != null) ...[
          _buildThisPhoneCard(context, ref, thisPhone, isEn),
          const SizedBox(height: AppSpacing.spaceLg),
        ] else ...[
          _buildLinkPromptBanner(context, isEn),
          const SizedBox(height: AppSpacing.spaceLg),
        ],

        // OTHER DEVICES SECTION
        if (otherDevices.isNotEmpty) ...[
          Row(
            children: [
              Text(
                isEn ? 'Other Devices' : 'Otros Dispositivos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.spaceXs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  '${otherDevices.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          ...otherDevices.map(
            (device) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spaceSm),
              child: _buildDeviceCard(context, ref, device, isThisPhone: false, isEn: isEn),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryBanner(int totalCount, bool isEn) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spaceMd,
            vertical: AppSpacing.spaceSm + 2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: Text(
                  isEn
                      ? '$totalCount ${totalCount == 1 ? 'device under continuous monitoring' : 'devices under continuous monitoring'}'
                      : '$totalCount ${totalCount == 1 ? 'dispositivo bajo vigilancia' : 'dispositivos bajo vigilancia continua'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLinkPromptBanner(BuildContext context, bool isEn) {
    return InkWell(
      onTap: () => context.push('/link-device'),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Link this Phone' : 'Vincular este Celular',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEn
                        ? 'Activate protection or control center on this device'
                        : 'Activa la protección o el panel de control en este equipo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildThisPhoneCard(
    BuildContext context,
    WidgetRef ref,
    Device device,
    bool isEn,
  ) {
    return InkWell(
      onTap: () => context.push('/device-detail', extra: device),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(
                    Icons.smartphone_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEn ? 'THIS PHONE • PRIMARY DEVICE' : 'ESTE TELÉFONO • DISPOSITIVO PRINCIPAL',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onPressed: () => _showDeviceActionsSheet(context, ref, device, isThisPhone: true, isEn: isEn),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Chips row
          Row(
            children: [
              _buildModeChip(device.mode, isEn),
              const SizedBox(width: AppSpacing.spaceXs),
              if (device.wipedAt != null) ...[
                StatusChip(
                  label: isEn ? 'DEVICE WIPED' : 'DISPOSITIVO BORRADO',
                  type: StatusChipType.danger,
                ),
              ] else ...[
                _buildOnlineChip(device.isOnline, isEn),
                if (device.theftModeActive) ...[
                  const SizedBox(width: AppSpacing.spaceXs),
                  StatusChip(
                    label: isEn ? 'THEFT MODE ACTIVE' : 'MODO ROBO ACTIVO',
                    type: StatusChipType.danger,
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Telemetry box
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceSm),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildBatteryIndicator(device.batteryLevel, device.isCharging, isEn),
                    const SizedBox(width: AppSpacing.spaceMd),
                    _buildNetworkIndicator(device.networkType, isEn),
                    const Spacer(),
                    Text(
                      _formatLastSeen(device.lastSeenAt, isEn),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (device.lastLocation != null) ...[
                  const Divider(height: 12, thickness: 0.5),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${isEn ? 'Last pos' : 'Última pos'}: ${device.lastLocation!.latitude.toStringAsFixed(4)}, ${device.lastLocation!.longitude.toStringAsFixed(4)} (±${device.lastLocation!.accuracyMeters?.round() ?? '?'}m)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textBody,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Suggestion banner if protected mode and Device Admin is not enabled
          if (device.mode == DeviceMode.protected && !device.adminEnabled) ...[
            const SizedBox(height: AppSpacing.spaceSm),
            InkWell(
              onTap: () => context.push('/protected-setup'),
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warningSubtle,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 18, color: AppColors.warningText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEn ? 'Activate lock protection (Recommended)' : 'Activar protección de bloqueo (Recomendado)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warningText,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.warningText),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    WidgetRef ref,
    Device device, {
    required bool isThisPhone,
    required bool isEn,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/device-detail', extra: device),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Icon(
                        device.platform == 'ios' ? Icons.apple_rounded : Icons.phone_android_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${isEn ? 'Model' : 'Modelo'}: ${device.model ?? '—'} • SO: ${device.osVersion ?? '—'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
                tooltip: isEn ? 'Manage device' : 'Administrar dispositivo',
                onPressed: () => context.push('/device-detail', extra: device),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onPressed: () => _showDeviceActionsSheet(context, ref, device, isThisPhone: isThisPhone, isEn: isEn),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Row(
            children: [
              _buildModeChip(device.mode, isEn),
              const SizedBox(width: AppSpacing.spaceXs),
              if (device.wipedAt != null) ...[
                StatusChip(
                  label: isEn ? 'WIPED' : 'BORRADO',
                  type: StatusChipType.danger,
                ),
              ] else ...[
                _buildOnlineChip(device.isOnline, isEn),
                if (device.theftModeActive) ...[
                  const SizedBox(width: AppSpacing.spaceXs),
                  StatusChip(
                    label: isEn ? 'THEFT MODE' : 'MODO ROBO',
                    type: StatusChipType.danger,
                  ),
                ],
              ],
              const Spacer(),
              _buildBatteryIndicator(device.batteryLevel, device.isCharging, isEn),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildNetworkIndicator(device.networkType, isEn),
              const Spacer(),
              Text(
                _formatLastSeen(device.lastSeenAt, isEn),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
              if (device.lastLocation != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${isEn ? 'Last pos' : 'Última pos'}: ${device.lastLocation!.latitude.toStringAsFixed(4)}, ${device.lastLocation!.longitude.toStringAsFixed(4)} (±${device.lastLocation!.accuracyMeters?.round() ?? '?'}m)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textBody,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildRealtimeDisconnectedBanner(bool isEn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEn ? 'No real-time connection, reconnecting…' : 'Sin conexión en tiempo real, reconectando…',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textBody,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryIndicator(int? level, bool? isCharging, bool isEn) {
    if (level == null) {
      return Row(
        children: [
          const Icon(Icons.battery_unknown_rounded, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(isEn ? 'No data' : 'Sin datos', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      );
    }

    final Color color;
    final IconData icon;

    if (isCharging == true) {
      icon = Icons.battery_charging_full_rounded;
      color = AppColors.safe;
    } else if (level > 80) {
      icon = Icons.battery_full_rounded;
      color = AppColors.safe;
    } else if (level > 50) {
      icon = Icons.battery_6_bar_rounded;
      color = AppColors.primary;
    } else if (level > 20) {
      icon = Icons.battery_3_bar_rounded;
      color = AppColors.warning;
    } else {
      icon = Icons.battery_alert_rounded;
      color = AppColors.alert;
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$level%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (isCharging == true) ...[
          const SizedBox(width: 2),
          const Text('⚡', style: TextStyle(fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildNetworkIndicator(String? networkType, bool isEn) {
    IconData icon;
    String label;
    switch (networkType?.toLowerCase()) {
      case 'wifi':
        icon = Icons.wifi_rounded;
        label = 'Wi-Fi';
        break;
      case 'mobile':
        icon = Icons.signal_cellular_alt_rounded;
        label = isEn ? 'Cellular' : 'Datos';
        break;
      case 'none':
        icon = Icons.signal_cellular_connected_no_internet_4_bar_rounded;
        label = isEn ? 'No network' : 'Sin red';
        break;
      default:
        icon = Icons.help_outline_rounded;
        label = '—';
    }

    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }

  String _formatLastSeen(DateTime? lastSeen, bool isEn) {
    if (lastSeen == null) return isEn ? 'Seen —' : 'Visto hace —';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 60) {
      return isEn ? 'Seen just now' : 'Visto hace un momento';
    } else if (diff.inMinutes < 60) {
      return isEn ? 'Seen ${diff.inMinutes}m ago' : 'Visto hace ${diff.inMinutes} m';
    } else if (diff.inHours < 24) {
      return isEn ? 'Seen ${diff.inHours}h ago' : 'Visto hace ${diff.inHours} h';
    } else {
      return isEn ? 'Seen ${diff.inDays}d ago' : 'Visto hace ${diff.inDays} d';
    }
  }

  Widget _buildModeChip(DeviceMode mode, bool isEn) {
    final isProtected = mode == DeviceMode.protected;
    return StatusChip(
      label: isProtected ? (isEn ? 'Protected' : 'Protegido') : (isEn ? 'Controller' : 'Controlador'),
      type: isProtected ? StatusChipType.safe : StatusChipType.neutral,
    );
  }

  Widget _buildOnlineChip(bool isOnline, bool isEn) {
    return StatusChip(
      label: isOnline ? (isEn ? 'Online' : 'En línea') : (isEn ? 'Offline' : 'Desconectado'),
      type: isOnline ? StatusChipType.safe : StatusChipType.neutral,
    );
  }

  void _showDeviceActionsSheet(
    BuildContext context,
    WidgetRef ref,
    Device device, {
    required bool isThisPhone,
    required bool isEn,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.spaceMd),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                title: Text(isEn ? 'Rename device' : 'Renombrar dispositivo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameDialog(context, ref, device, isEn);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off_rounded, color: AppColors.alert),
                title: Text(
                  isEn ? 'Unlink device' : 'Desvincular dispositivo',
                  style: const TextStyle(color: AppColors.alert),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showUnlinkConfirmation(context, ref, device, isThisPhone: isThisPhone, isEn: isEn);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Device device, bool isEn) {
    final controller = TextEditingController(text: device.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEn ? 'Rename Device' : 'Renombrar Dispositivo'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: isEn ? 'Device name' : 'Nombre del dispositivo',
              hintText: isEn ? 'Enter a new name' : 'Ingresa un nuevo nombre',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return isEn ? 'Name is required' : 'El nombre es obligatorio';
              if (v.trim().length > 40) return isEn ? 'Maximum 40 characters' : 'Máximo 40 caracteres';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Cancel' : 'Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final nav = Navigator.of(ctx);
                final success = await ref
                    .read(devicesNotifierProvider.notifier)
                    .renameDevice(device.id, controller.text.trim());
                nav.pop();
                if (context.mounted && !success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEn ? 'Could not rename device.' : 'No se pudo renombrar el dispositivo.'),
                      backgroundColor: AppColors.alert,
                    ),
                  );
                }
              }
            },
            child: Text(isEn ? 'Save' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  void _showUnlinkConfirmation(
    BuildContext context,
    WidgetRef ref,
    Device device, {
    required bool isThisPhone,
    required bool isEn,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEn ? 'Unlink device?' : '¿Desvincular dispositivo?'),
        content: Text(
          isThisPhone
              ? (isEn
                  ? 'You are about to unlink this phone. The protection token will be deleted and it will stop receiving remote commands.'
                  : 'Estás a punto de desvincular este mismo celular. Se eliminará el token de protección y dejará de recibir órdenes remotas.')
              : (isEn
                  ? 'The device "${device.name}" will no longer be connected to your account and cannot be located or managed.'
                  : 'El dispositivo "${device.name}" dejará de estar conectado a tu cuenta y no podrá ser localizado o administrado.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Cancel' : 'Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final success = await ref
                  .read(devicesNotifierProvider.notifier)
                  .unlinkDevice(device.id);
              nav.pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (isEn ? 'Device unlinked successfully.' : 'Dispositivo desvinculado con éxito.')
                          : (isEn ? 'Could not unlink device.' : 'No se pudo desvincular el dispositivo.'),
                    ),
                    backgroundColor: success ? AppColors.primary : AppColors.alert,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.alert),
            child: Text(isEn ? 'Unlink' : 'Desvincular'),
          ),
        ],
      ),
    );
  }
}
