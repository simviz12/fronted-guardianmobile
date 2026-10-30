import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_field.dart';
import '../../../../core/theme/app_widgets.dart';
import '../providers/two_factor_provider.dart';

class TwoFactorSetupPage extends ConsumerStatefulWidget {
  const TwoFactorSetupPage({super.key});

  @override
  ConsumerState<TwoFactorSetupPage> createState() => _TwoFactorSetupPageState();
}

class _TwoFactorSetupPageState extends ConsumerState<TwoFactorSetupPage> {
  final _tokenController = TextEditingController();
  bool _secretVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(twoFactorSetupProvider.notifier).startSetup();
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(twoFactorSetupProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activar Autenticación en Dos Pasos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(twoFactorSetupProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TwoFactorSetupState state) {
    if (state.step == TwoFactorSetupStep.showBackupCodes) {
      return _buildBackupCodesScreen(context, state);
    }
    if (state.step == TwoFactorSetupStep.disabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return const SizedBox.shrink();
    }
    return _buildQrScreen(context, state);
  }

  Widget _buildQrScreen(BuildContext context, TwoFactorSetupState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step 1: Scan QR
          _buildStepHeader(
            step: '1',
            title: 'Escanea el código QR',
            subtitle:
                'Abre tu aplicación de autenticación (Google Authenticator, Authy, etc.) y escanea el código QR.',
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          if (state.isLoading || state.step == TwoFactorSetupStep.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.spaceLg),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (state.otpauthUrl != null) ...[
            AppCard(
              child: Center(
                child: QrImageView(
                  data: state.otpauthUrl!,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMd),

            // Manual secret
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿No puedes escanear? Ingresa el código manualmente:',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.spaceXs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _secretVisible
                              ? (state.secret ?? '')
                              : '•' * (state.secret?.length ?? 0),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _secretVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () =>
                            setState(() => _secretVisible = !_secretVisible),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_outlined,
                            size: 20, color: AppColors.textMuted),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: state.secret ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Clave copiada al portapapeles')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.spaceLg),

            // Step 2: Verify
            _buildStepHeader(
              step: '2',
              title: 'Verifica con el código',
              subtitle:
                  'Ingresa el código de 6 dígitos que aparece en tu aplicación de autenticación.',
            ),
            const SizedBox(height: AppSpacing.spaceMd),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _tokenController,
                    label: 'Código de verificación (6 dígitos)',
                    hintText: '000000',
                    prefixIcon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.spaceMd),

                  if (state.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.spaceSm),
                      decoration: BoxDecoration(
                        color: AppColors.alertContainer,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: AppColors.alertText, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spaceSm),
                  ],

                  PrimaryButton(
                    text: 'Activar 2FA',
                    icon: Icons.verified_user_rounded,
                    isLoading: state.isLoading,
                    onPressed: () async {
                      final token = _tokenController.text.trim();
                      if (token.isEmpty) return;
                      await ref
                          .read(twoFactorSetupProvider.notifier)
                          .enableWithToken(token);
                    },
                  ),
                ],
              ),
            ),
          ],

          if (state.errorMessage != null &&
              state.step != TwoFactorSetupStep.showQr) ...[
            const SizedBox(height: AppSpacing.spaceMd),
            Container(
              padding: const EdgeInsets.all(AppSpacing.spaceMd),
              decoration: BoxDecoration(
                color: AppColors.alertContainer,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: AppColors.alertText, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackupCodesScreen(BuildContext context, TwoFactorSetupState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            decoration: BoxDecoration(
              color: AppColors.warningSubtle,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.warningText, size: 22),
                SizedBox(width: AppSpacing.spaceSm),
                Expanded(
                  child: Text(
                    '¡Guarda estos códigos en un lugar seguro! Se muestran UNA SOLA VEZ. Úsalos si pierdes acceso a tu aplicación de autenticación.',
                    style: TextStyle(
                      color: AppColors.warningText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceLg),
          const Text(
            '🔐 Códigos de Respaldo (10)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeadings,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          AppCard(
            child: Column(
              children: [
                ...state.backupCodes.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text(
                              '${entry.key + 1}.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textHeadings,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 20),
                TextButton.icon(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Copiar todos los códigos'),
                  onPressed: () {
                    final text = state.backupCodes.join('\n');
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Códigos copiados al portapapeles')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceLg),
          PrimaryButton(
            text: 'He guardado mis códigos',
            icon: Icons.check_rounded,
            onPressed: () {
              ref.read(twoFactorSetupProvider.notifier).reset();
              context.pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader({
    required String step,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeadings,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textBody,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
