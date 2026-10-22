import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_field.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../core/network/fcm_notification_service.dart';
import '../../domain/entities/device.dart';
import '../providers/devices_provider.dart';
import '../../../../core/localization/language_provider.dart';

class LinkDevicePage extends ConsumerStatefulWidget {
  const LinkDevicePage({super.key});

  @override
  ConsumerState<LinkDevicePage> createState() => _LinkDevicePageState();
}

class _LinkDevicePageState extends ConsumerState<LinkDevicePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DeviceMode _selectedMode = DeviceMode.protected;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final fcmService = ref.read(fcmNotificationServiceProvider);
      final fcmToken = await fcmService.getFcmToken();

      final linkUseCase = ref.read(linkCurrentDeviceUseCaseProvider);
      await linkUseCase(
        name: _nameController.text.trim(),
        mode: _selectedMode,
        fcmToken: fcmToken,
      );

      // Refresh dashboard
      ref.read(devicesNotifierProvider.notifier).loadDevices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(languageProvider) == AppLanguage.en ? 'Device linked successfully.' : 'Dispositivo vinculado exitosamente.'),
            backgroundColor: AppColors.primary,
          ),
        );
        if (_selectedMode == DeviceMode.protected) {
          context.pushReplacement('/protected-setup');
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        String msg = 'No se pudo vincular el dispositivo.';
        final str = e.toString();
        if (str.contains('NetworkFailure')) {
          msg = 'No hay conexión con el servidor.';
        } else if (str.contains('VALIDATION_ERROR')) {
          msg = 'Nombre de dispositivo inválido (1-40 caracteres).';
        }
        setState(() {
          _isSubmitting = false;
          _errorMessage = msg;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final installInfoAsync = ref.watch(deviceInstallInfoProvider);
    final isEn = ref.watch(languageProvider) == AppLanguage.en;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEn ? 'Link this Phone' : 'Vincular este Celular'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: installInfoAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Text(isEn ? 'Error reading info: $err' : 'Error al leer información: $err'),
          ),
          data: (info) {
            if (_nameController.text.isEmpty) {
              _nameController.text = info.suggestedName;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
                vertical: AppSpacing.spaceMd,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.spaceMd),
                        decoration: BoxDecoration(
                          color: AppColors.alertContainer,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: AppColors.alert.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.alertText,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.spaceSm),
                            Expanded(
                              child: Text(
                                _errorMessage!,
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
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            isEn ? 'Device Name' : 'Nombre del dispositivo',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHeadings,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.spaceSm),
                          AppTextField(
                            controller: _nameController,
                            label: isEn ? 'Identifier Name' : 'Nombre identificador',
                            hintText: isEn ? 'e.g. Gabriel Pixel 8' : 'Ej. Pixel 8 de Gabriel',
                            prefixIcon: Icons.smartphone_rounded,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return isEn ? 'Name is required' : 'El nombre es obligatorio';
                              }
                              if (val.trim().length > 40) {
                                return isEn ? 'Maximum 40 characters' : 'Máximo 40 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.spaceSm),
                          Text(
                            isEn ? 'Model: ${info.model ?? "Unknown"} • OS: ${info.osVersion ?? "N/A"} • App: ${info.appVersion ?? "1.0.0"}' : 'Modelo: ${info.model ?? "Desconocido"} • SO: ${info.osVersion ?? "N/A"} • App: ${info.appVersion ?? "1.0.0"}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spaceLg),
                    Text(
                      isEn ? 'Select role for this phone' : 'Selecciona el rol de este celular',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.spaceMd),
                    // Protected Choice Card
                    _buildModeOption(
                      mode: DeviceMode.protected,
                      title: isEn ? 'Protected device' : 'Dispositivo protegido',
                      subtitle:
                          isEn ? 'This phone will receive commands: ring, lock, locate… Designed for the device you want to protect.' : 'Este celular recibirá las órdenes: sonar, bloquear, ubicar… Diseñado para el equipo que deseas proteger ante robo.',
                      icon: Icons.shield_rounded,
                    ),
                    const SizedBox(height: AppSpacing.spaceMd),
                    // Controller Choice Card
                    _buildModeOption(
                      mode: DeviceMode.controller,
                      title: isEn ? 'Controller' : 'Controlador',
                      subtitle:
                          isEn ? 'From here you manage your other devices, send alerts, and track protected phones.' : 'Desde aquí administrarás tus otros dispositivos. Podrás enviar alertas y rastrear los celulares protegidos.',
                      icon: Icons.admin_panel_settings_rounded,
                    ),
                    const SizedBox(height: AppSpacing.spaceXl),
                    PrimaryButton(
                      text: isEn ? 'Complete Pairing' : 'Completar Vinculación',
                      icon: Icons.link_rounded,
                      isLoading: _isSubmitting,
                      onPressed: _submitLink,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required DeviceMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == mode;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.spaceSm),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textHeadings,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textHeadings,
                          ),
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spaceXs),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textBody,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
