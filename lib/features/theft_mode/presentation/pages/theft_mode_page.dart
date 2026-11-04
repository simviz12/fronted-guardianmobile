import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../core/theme/guardian_theme.dart';
import '../../../../core/theme/guardian_tokens.dart';
import '../../../../core/widgets/guardian_widgets.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../devices/domain/entities/device.dart';
import '../../../devices/presentation/providers/devices_provider.dart';
import '../../../locations/presentation/providers/device_map_provider.dart';
import 'package:guardian_mobile/features/theft_mode/domain/entities/theft_mode_config.dart';
import 'package:guardian_mobile/features/theft_mode/presentation/providers/theft_mode_provider.dart';

class TheftModePage extends ConsumerStatefulWidget {
  final Device device;

  const TheftModePage({
    super.key,
    required this.device,
  });

  @override
  ConsumerState<TheftModePage> createState() => _TheftModePageState();
}

class _TheftModePageState extends ConsumerState<TheftModePage> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController(
    text: 'Este teléfono está perdido. Por favor contacta a su dueño.',
  );
  final _phoneController = TextEditingController();

  int _selectedIntervalMinutes = 1; // 1, 5, 15
  bool _alarm = true;
  bool _lock = true;

  @override
  void dispose() {
    _messageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Current live device data from devices provider
    final devicesState = ref.watch(devicesNotifierProvider);
    final currentDevice = devicesState.devices.firstWhere(
      (d) => d.id == widget.device.id,
      orElse: () => widget.device,
    );

    final theftState = ref.watch(theftModeProvider(widget.device.id));

    // Show SnackBar on state error or action success
    ref.listen<TheftModeState>(theftModeProvider(widget.device.id), (TheftModeState? previous, TheftModeState next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: context.gm.danger,
          ),
        );
      }
      if (next.actionSuccessMessage != null &&
          next.actionSuccessMessage != previous?.actionSuccessMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.actionSuccessMessage!),
            backgroundColor: context.gm.brand,
          ),
        );
      }
    });

    final bool isActuallyActive = theftState.isActive || currentDevice.theftModeActive;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  currentDevice.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.gm.ink,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActuallyActive ? context.gm.dangerSoft : context.gm.brandSoft,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(
                    isActuallyActive ? 'ACTIVO' : 'INACTIVO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActuallyActive ? context.gm.danger : context.gm.brand,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'PROTOCOLO DE EXTRAVÍO Y ROBO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: context.gm.brand,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: theftState.isLoading
            ? Center(child: CircularProgressIndicator(color: context.gm.brand))
            : RefreshIndicator(
                color: context.gm.brand,
                onRefresh: () async {
                  await ref
                      .read(theftModeProvider(widget.device.id).notifier)
                      .loadActiveConfig();
                },
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.marginMobile),
                  children: [
                    if (isActuallyActive)
                      _buildActiveState(context, currentDevice, theftState.activeConfig)
                    else
                      _buildInactiveState(context, currentDevice, theftState),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildActiveState(
    BuildContext context,
    Device device,
    TheftModeConfig? config,
  ) {
    final mapState = ref.watch(deviceMapProvider(device.id));
    final latestLoc = mapState.latestLocation;
    final isEn = ref.watch(languageProvider) == AppLanguage.en;
    final theme = Theme.of(context);
    final headingColor = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Critical Alert Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          decoration: BoxDecoration(
            color: context.gm.dangerSoft,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: context.gm.danger.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.gm.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: context.gm.onDanger,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'CRITICAL STATE ACTIVE' : 'ESTADO CRÍTICO ACTIVO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.gm.dangerInk,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          isEn ? 'THEFT / LOST MODE ACTIVE' : 'MODO ROBO / EXTRAVÍO ACTIVADO',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.gm.dangerInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              Text(
                isEn
                    ? 'The device is locked. Emergency tracking is actively broadcasting coordinates.'
                    : 'El dispositivo se encuentra bloqueado. El rastreo de emergencia está transmitiendo activamente.',
                style: TextStyle(
                  fontSize: 13,
                  color: context.gm.dangerInk.withValues(alpha: 0.9),
                  height: 1.3,
                ),
              ),
              if (config != null) ...[
                const SizedBox(height: 6),
                Text(
                  isEn
                      ? 'Activated: ${_formatDateTime(config.activatedAt)} (Interval: ${config.locationIntervalSeconds}s)'
                      : 'Activado: ${_formatDateTime(config.activatedAt)} (Frecuencia: ${config.locationIntervalSeconds}s)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.gm.dangerInk,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.spaceMd),

        // Live Telemetry Box
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: context.gm.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isEn ? 'Live Telemetry' : 'Telemetría en Vivo',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: headingColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (latestLoc?.accuracyMeters != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.gm.surfaceSunken,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Text(
                        'GPS ±${latestLoc!.accuracyMeters!.round()}m',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.gm.ink,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              if (latestLoc != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 16, color: context.gm.brand),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Lat: ${latestLoc.latitude.toStringAsFixed(5)}, Lon: ${latestLoc.longitude.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: headingColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isEn
                      ? 'Last report: ${_formatDateTime(latestLoc.recordedAt)} (${latestLoc.source.toContractString()})'
                      : 'Último reporte: ${_formatDateTime(latestLoc.recordedAt)} (${latestLoc.source.toContractString()})',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.gm.inkMuted,
                  ),
                ),
              ] else ...[
                Text(
                  isEn
                      ? 'Waiting for first emergency GPS fix...'
                      : 'Esperando primera fijación GPS de emergencia...',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.gm.inkMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.spaceMd),

        // Locked Screen Simulation Preview
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_rounded, size: 18, color: headingColor),
                  const SizedBox(width: 8),
                  Text(
                    isEn ? 'Active Locked Screen' : 'Pantalla Bloqueada Activa',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: headingColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isEn
                    ? 'Text displayed on front screen with maximum visibility:'
                    : 'Texto desplegado en pantalla frontal con la máxima visibilidad:',
                style: TextStyle(fontSize: 12, color: context.gm.ink),
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.spaceMd),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.report_problem_rounded,
                      color: Color(0xFFFFB3AD),
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEn ? 'LOST DEVICE' : 'DISPOSITIVO EXTRAVIADO',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFB3AD),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '“${config?.message ?? (isEn ? 'This phone is lost. Please contact the owner.' : 'Este teléfono está perdido. Por favor contacta a su dueño.')}”',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    if (config?.contactPhone != null && config!.contactPhone!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${isEn ? 'Contact' : 'Contacto'}: ${config.contactPhone}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF65DCA8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.spaceLg),

        // Deactivate Action Button
        DangerButton(
          text: isEn ? 'Deactivate Theft Mode' : 'Desactivar Modo Robo',
          icon: Icons.lock_open_rounded,
          onPressed: () => _showDeactivateDialog(context),
        ),

        const SizedBox(height: AppSpacing.spaceXl),

        // Zona de Destrucción Irreversible (Wipe Section)
        _buildDestructionZoneSection(context, device),
      ],
    );
  }

  Widget _buildInactiveState(
    BuildContext context,
    Device device,
    TheftModeState theftState,
  ) {
    final bool canLock = device.adminEnabled;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Informative Header Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            decoration: BoxDecoration(
              color: context.gm.surfaceSunken,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: context.gm.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: context.gm.brand,
                  size: 28,
                ),
                SizedBox(width: AppSpacing.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Protección Inmediata ante Pérdida o Robo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.gm.ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Al activar este modo, el dispositivo iniciará rastreo continuo de emergencia, bloqueará el acceso y mostrará un mensaje visible para su recuperación.',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.gm.ink,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Message Input Field
          Text(
            'Mensaje para mostrar en pantalla',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: context.gm.ink,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _messageController,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: 'Ingresa un mensaje claro para quien encuentre el teléfono',
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'El mensaje no puede estar vacío.';
              }
              if (val.trim().length > 200) {
                return 'Máximo 200 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.spaceSm),

          // Contact Phone Input Field
          Text(
            'Teléfono de contacto alternativo (Opcional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: context.gm.ink,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Ej. +52 55 1234 5678',
              prefixIcon: Icon(Icons.phone_rounded, color: context.gm.brand),
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Location Frequency Selector
          Text(
            'Frecuencia de rastreo de emergencia',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: context.gm.ink,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildIntervalOption(1, '1 minuto'),
              const SizedBox(width: AppSpacing.spaceSm),
              _buildIntervalOption(5, '5 minutos'),
              const SizedBox(width: AppSpacing.spaceSm),
              _buildIntervalOption(15, '15 minutos'),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Toggles
          AppCard(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: context.gm.brand,
                  title: Text(
                    'Activar alarma sonora',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.gm.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Emite un sonido de advertencia audible al recibir el comando.',
                    style: TextStyle(fontSize: 12, color: context.gm.ink),
                  ),
                  value: _alarm,
                  onChanged: (v) => setState(() => _alarm = v),
                ),
                const Divider(height: 16),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: context.gm.brand,
                  title: Text(
                    'Bloquear pantalla inmediatamente',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.gm.ink,
                    ),
                  ),
                  subtitle: Text(
                    canLock
                        ? 'Bloquea el acceso al teléfono remotamente.'
                        : 'Deshabilitado: El dispositivo aún no tiene concedido el permiso de Administrador de Dispositivo.',
                    style: TextStyle(
                      fontSize: 12,
                      color: canLock ? context.gm.ink : context.gm.dangerInk,
                    ),
                  ),
                  value: canLock ? _lock : false,
                  onChanged: canLock ? (v) => setState(() => _lock = v) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceLg),

          // Submit Button
          DangerButton(
            text: 'Activar Modo Robo',
            icon: Icons.shield_rounded,
            isLoading: theftState.isSubmitting,
            onPressed: () => _confirmActivation(context),
          ),

          const SizedBox(height: AppSpacing.spaceXl),

          // Zona de Destrucción Irreversible (Wipe Section)
          _buildDestructionZoneSection(context, device),
        ],
      ),
    );
  }

  Widget _buildIntervalOption(int minutes, String label) {
    final isSelected = _selectedIntervalMinutes == minutes;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIntervalMinutes = minutes),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? context.gm.brandSoft : context.gm.surfaceSunken,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: isSelected ? context.gm.brand : context.gm.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? context.gm.brand : context.gm.ink,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmActivation(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    // Bottom sheet + hold-to-confirm (design system): a deliberate gesture
    // for a high-impact action instead of a one-tap dialog button.
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(GSpace.s5, 0, GSpace.s5, GSpace.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const IconBox(Icons.gpp_maybe_rounded, danger: true),
                const SizedBox(width: GSpace.s3),
                Expanded(child: Text('¿Activar Modo Robo?', style: ctx.text.headlineSmall)),
              ]),
              const SizedBox(height: GSpace.s3),
              Text(
                'Se activará el protocolo de extravío en "${widget.device.name}":',
                style: ctx.text.bodyLarge,
              ),
              const SizedBox(height: GSpace.s2),
              _buildBulletPoint('Rastreo cada $_selectedIntervalMinutes minuto(s)'),
              if (_lock && widget.device.adminEnabled) _buildBulletPoint('Bloqueo inmediato de pantalla'),
              if (_alarm) _buildBulletPoint('Sirena de alarma audible'),
              _buildBulletPoint('Mensaje de aviso en pantalla principal'),
              const SizedBox(height: GSpace.s2),
              Text('Puedes desactivarlo después con tu contraseña.', style: ctx.text.bodySmall),
              const SizedBox(height: GSpace.s5),
              HoldToConfirmButton(
                label: 'Mantén presionado para activar',
                onConfirmed: () async {
                  Navigator.pop(ctx);
                  await ref.read(theftModeProvider(widget.device.id).notifier).activate(
                        message: _messageController.text.trim(),
                        contactPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                        locationIntervalSeconds: _selectedIntervalMinutes * 60,
                        alarm: _alarm,
                        lock: _lock && widget.device.adminEnabled,
                      );
                },
              ),
              const SizedBox(height: GSpace.s2),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: context.gm.brand),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final twoFactorController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar Modo Robo'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Por motivos de seguridad, ingresa la contraseña de tu cuenta para confirmar la desactivación:',
                style: TextStyle(fontSize: 13, color: context.gm.ink),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña de la cuenta',
                  hintText: 'Ingresa tu contraseña',
                  prefixIcon: Icon(Icons.lock_rounded, color: context.gm.brand),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: twoFactorController,
                decoration: InputDecoration(
                  labelText: 'Código 2FA (si está activo)',
                  hintText: 'TOTP o de respaldo',
                  prefixIcon: Icon(Icons.pin_outlined, color: context.gm.brand),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final nav = Navigator.of(ctx);
                final code = twoFactorController.text.trim();
                final success = await ref
                    .read(theftModeProvider(widget.device.id).notifier)
                    .deactivate(
                      password: passwordController.text,
                      twoFactorCode: code.isNotEmpty ? code : null,
                    );
                if (success) {
                  nav.pop();
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: context.gm.danger),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildDestructionZoneSection(BuildContext context, Device device) {
    final isWiped = device.wipedAt != null;
    final isProtectedMode = device.mode == DeviceMode.protected;
    final canWipe = isProtectedMode && device.adminEnabled && device.wipeEnabled && !isWiped;
    final isEn = ref.watch(languageProvider) == AppLanguage.en;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: context.gm.dangerSoft.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(
          color: context.gm.danger.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: context.gm.danger, size: 24),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: Text(
                  isEn ? 'Irreversible Destruction Zone' : 'Zona de Destrucción Irreversible',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.gm.dangerInk,
                  ),
                ),
              ),
              if (isWiped)
                StatusChip(label: isEn ? 'ERASED' : 'BORRADO', type: StatusChipType.danger),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            isWiped
                ? (isEn
                    ? 'This device has completed a full factory reset and is unlinked.'
                    : 'Este dispositivo ya ejecutó el restablecimiento de fábrica total y se encuentra desvinculado.')
                : (isEn
                    ? 'If the device is in unauthorized hands and contains critical data, proceed to remote wipe.'
                    : 'Si el dispositivo está en manos no autorizadas y contiene credenciales corporativas o personales críticas, procede a la destrucción remota.'),
            style: TextStyle(fontSize: 12, color: context.gm.dangerInk, height: 1.35),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          if (isWiped)
            Container(
              padding: const EdgeInsets.all(AppSpacing.spaceSm),
              decoration: BoxDecoration(
                color: context.gm.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                isEn
                    ? 'The device no longer responds to commands or tracking.'
                    : 'El dispositivo ya no responde a órdenes ni puede ser localizado.',
                style: TextStyle(fontSize: 12, color: context.gm.inkMuted),
                textAlign: TextAlign.center,
              ),
            )
          else if (!canWipe)
            Container(
              padding: const EdgeInsets.all(AppSpacing.spaceSm),
              decoration: BoxDecoration(
                color: context.gm.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: context.gm.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEn
                          ? 'The device does not have Device Administrator permissions for remote wipe.'
                          : 'El dispositivo no tiene permisos de Administrador de Dispositivos para borrado remoto.',
                      style: TextStyle(fontSize: 11, color: context.gm.dangerInk),
                    ),
                  ),
                ],
              ),
            )
          else
            DangerButton(
              text: isEn ? 'START REMOTE FACTORY WIPE' : 'INICIAR BORRADO REMOTO TOTAL (WIPE)',
              icon: Icons.delete_forever_rounded,
              onPressed: () {
                context.push('/wipe-wizard', extra: device);
              },
            ),
        ],
      ),
    );
  }
}
