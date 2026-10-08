import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, user?.displayName),
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
        label: const Text('Vincular Celular'),
        onPressed: () => context.push('/link-device'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String? displayName) {
    final initial = (displayName != null && displayName.isNotEmpty)
        ? displayName[0].toUpperCase()
        : 'U';

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.spaceSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${displayName ?? 'Usuario'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeadings,
                ),
              ),
              const Text(
                'Guardian Mobile',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.textHeadings),
          onPressed: () => context.push('/settings'),
        ),
        GestureDetector(
          onTap: () => context.push('/settings'),
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.marginMobile),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
              text: 'Reintentar',
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
          const Text(
            'Sin dispositivos vinculados',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeadings,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          const Text(
            'Vincula este celular ahora para protegerlo remotamente o administrar otros equipos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textBody,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceXl),
          PrimaryButton(
            text: 'Vincular este Celular',
            icon: Icons.add_link_rounded,
            onPressed: () => context.push('/link-device'),
          ),
        ],
      );
    }

    final thisPhone = state.thisPhoneDevice;
    final otherDevices = state.otherDevices;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
        top: AppSpacing.spaceSm,
        bottom: 80,
      ),
      children: [
        // Global security summary banner
        _buildSummaryBanner(state.devices.length),
        const SizedBox(height: AppSpacing.spaceMd),

        // THIS PHONE CARD (If linked)
        if (thisPhone != null) ...[
          _buildThisPhoneCard(context, ref, thisPhone),
          const SizedBox(height: AppSpacing.spaceLg),
        ] else ...[
          _buildLinkPromptBanner(context),
          const SizedBox(height: AppSpacing.spaceLg),
        ],

        // OTHER DEVICES SECTION
        if (otherDevices.isNotEmpty) ...[
          Row(
            children: [
              const Text(
                'Otros Dispositivos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeadings,
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
              child: _buildDeviceCard(context, ref, device, isThisPhone: false),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryBanner(int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spaceMd,
        vertical: AppSpacing.spaceSm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
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
              '$totalCount ${totalCount == 1 ? 'dispositivo bajo vigilancia' : 'dispositivos bajo vigilancia continua'}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textHeadings,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkPromptBanner(BuildContext context) {
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vincular este Celular',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Activa la protección o el panel de control en este equipo',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textBody,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textHeadings,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'ESTE TELÉFONO • DISPOSITIVO PRINCIPAL',
                        style: TextStyle(
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
                  onPressed: () => _showDeviceActionsSheet(context, ref, device, isThisPhone: true),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Chips row
          Row(
            children: [
              _buildModeChip(device.mode),
              const SizedBox(width: AppSpacing.spaceXs),
              _buildOnlineChip(device.isOnline),
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
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            device.batteryLevel != null
                                ? Icons.battery_charging_full_rounded
                                : Icons.battery_unknown_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            device.batteryLevel != null ? '${device.batteryLevel}%' : 'Sin datos',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textHeadings,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Modelo: ${device.model ?? '—'}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textBody,
                        ),
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
                          'Última pos: ${device.lastLocation!.latitude.toStringAsFixed(4)}, ${device.lastLocation!.longitude.toStringAsFixed(4)} (±${device.lastLocation!.accuracyMeters?.round() ?? '?'}m)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textBody,
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
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 18, color: AppColors.warningText),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Activar protección de bloqueo (Recomendado)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warningText,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.warningText),
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
                        color: AppColors.textHeadings,
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textHeadings,
                            ),
                          ),
                          Text(
                            'Modelo: ${device.model ?? '—'} • SO: ${device.osVersion ?? '—'}',
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
                tooltip: 'Administrar dispositivo',
                onPressed: () => context.push('/device-detail', extra: device),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onPressed: () => _showDeviceActionsSheet(context, ref, device, isThisPhone: isThisPhone),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Row(
            children: [
              _buildModeChip(device.mode),
              const SizedBox(width: AppSpacing.spaceXs),
              _buildOnlineChip(device.isOnline),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.battery_std_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Text(
                    device.batteryLevel != null ? '${device.batteryLevel}%' : 'Sin datos',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
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
                        'Última pos: ${device.lastLocation!.latitude.toStringAsFixed(4)}, ${device.lastLocation!.longitude.toStringAsFixed(4)} (±${device.lastLocation!.accuracyMeters?.round() ?? '?'}m)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textBody,
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

  Widget _buildModeChip(DeviceMode mode) {
    final isProtected = mode == DeviceMode.protected;
    return StatusChip(
      label: isProtected ? 'Protegido' : 'Controlador',
      type: isProtected ? StatusChipType.safe : StatusChipType.neutral,
    );
  }

  Widget _buildOnlineChip(bool isOnline) {
    return StatusChip(
      label: isOnline ? 'En línea' : 'Desconectado',
      type: isOnline ? StatusChipType.safe : StatusChipType.neutral,
    );
  }

  void _showDeviceActionsSheet(
    BuildContext context,
    WidgetRef ref,
    Device device, {
    required bool isThisPhone,
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
                title: const Text('Renombrar dispositivo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameDialog(context, ref, device);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off_rounded, color: AppColors.alert),
                title: const Text(
                  'Desvincular dispositivo',
                  style: TextStyle(color: AppColors.alert),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showUnlinkConfirmation(context, ref, device, isThisPhone: isThisPhone);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Device device) {
    final controller = TextEditingController(text: device.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar Dispositivo'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nombre del dispositivo',
              hintText: 'Ingresa un nuevo nombre',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
              if (v.trim().length > 40) return 'Máximo 40 caracteres';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
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
                    const SnackBar(
                      content: Text('No se pudo renombrar el dispositivo.'),
                      backgroundColor: AppColors.alert,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
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
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Desvincular dispositivo?'),
        content: Text(
          isThisPhone
              ? 'Estás a punto de desvincular este mismo celular. Se eliminará el token de protección y dejará de recibir órdenes remotas.'
              : 'El dispositivo "${device.name}" dejará de estar conectado a tu cuenta y no podrá ser localizado o administrado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
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
                          ? 'Dispositivo desvinculado con éxito.'
                          : 'No se pudo desvincular el dispositivo.',
                    ),
                    backgroundColor: success ? AppColors.primary : AppColors.alert,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.alert),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );
  }
}
