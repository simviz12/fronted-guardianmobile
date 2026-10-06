import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../devices/domain/entities/device.dart';
import '../providers/command_provider.dart';
import '../widgets/command_live_status_stepper.dart';

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
  Widget build(BuildContext context) {
    final commandState = ref.watch(commandNotifierProvider);
    final isProtectedMode = widget.device.mode == DeviceMode.protected;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.device.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
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

              if (commandState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.spaceMd),
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
                    'ACCIONES TÁCTICAS INMEDIATAS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeadings,
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
                childAspectRatio: 0.95,
                children: [
                  // 1. HACER SONAR (Active if target is PROTECTED)
                  _buildRingActionTile(
                    isProtectedMode: isProtectedMode,
                    isLoading: commandState.isSubmitting || commandState.isPolling,
                  ),

                  // 2. LOCALIZAR (Disabled - Próximamente)
                  _buildDisabledActionTile(
                    title: 'Localizar',
                    subtitle: 'Triangulación GPS de alta precisión',
                    icon: Icons.my_location_rounded,
                  ),

                  // 3. BLOQUEAR (Disabled - Próximamente)
                  _buildDisabledActionTile(
                    title: 'Bloquear',
                    subtitle: 'PIN forzoso e inhabilita biometría',
                    icon: Icons.lock_rounded,
                  ),

                  // 4. ENVIAR MENSAJE (Disabled - Próximamente)
                  _buildDisabledActionTile(
                    title: 'Mensaje',
                    subtitle: 'Pantalla fijada con mensaje de contacto',
                    icon: Icons.message_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceHeaderCard() {
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadings,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.device.model ?? 'Modelo no especificado'} • SO ${widget.device.osVersion ?? '—'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          StatusChip(
            label: widget.device.mode == DeviceMode.protected ? 'Protegido' : 'Controlador',
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
    if (!isProtectedMode) {
      return _buildDisabledActionTile(
        title: 'Hacer sonar',
        subtitle: 'Solo disponible para dispositivos en modo Protegido',
        icon: Icons.volume_up_rounded,
        badgeLabel: 'No protegido',
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
              color: AppColors.primary.withValues(alpha: 0.25),
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hacer sonar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Máximo volumen incluso si está en silencio',
                  style: TextStyle(
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
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
                child: Icon(icon, color: AppColors.textMuted, size: 22),
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Hacer sonar alarma?'),
        content: Text(
          'Se emitirá un sonido de alarma a máximo volumen en "${widget.device.name}", ignorando el modo silencio o vibración.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Hacer Sonar'),
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
}
