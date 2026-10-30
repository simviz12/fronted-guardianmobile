import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_field.dart';
import '../../../../core/theme/app_widgets.dart';
import '../providers/auth_provider.dart';

class TwoFactorLoginPage extends ConsumerStatefulWidget {
  const TwoFactorLoginPage({super.key});

  @override
  ConsumerState<TwoFactorLoginPage> createState() => _TwoFactorLoginPageState();
}

class _TwoFactorLoginPageState extends ConsumerState<TwoFactorLoginPage> {
  final _codeController = TextEditingController();
  bool _useBackupCode = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    final ok = await ref.read(authNotifierProvider.notifier).verifyTwoFactorLogin(code: code);
    if (ok && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(authNotifierProvider.notifier).cancelTwoFactorLogin();
            context.go('/login');
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.spaceMd),
              Text(
                'Verificación en Dos Pasos',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeadings,
                    ),
              ),
              const SizedBox(height: AppSpacing.spaceXs),
              Text(
                _useBackupCode
                    ? 'Ingresa uno de tus códigos de respaldo de 16 caracteres.'
                    : 'Ingresa el código de 6 dígitos de tu aplicación de autenticación (Google Authenticator, Authy, etc.).',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textBody,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.spaceLg),

              // Error banner
              if (authState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.spaceMd),
                  decoration: BoxDecoration(
                    color: AppColors.alertContainer,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.alert.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.alertText, size: 20),
                      const SizedBox(width: AppSpacing.spaceSm),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
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

              // Code card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _codeController,
                      label: _useBackupCode ? 'Código de respaldo' : 'Código de 6 dígitos',
                      hintText: _useBackupCode ? 'XXXX-XXXX-XXXX-XXXX' : '000000',
                      prefixIcon: _useBackupCode
                          ? Icons.vpn_key_outlined
                          : Icons.pin_outlined,
                      keyboardType: _useBackupCode
                          ? TextInputType.text
                          : TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppSpacing.spaceLg),
                    PrimaryButton(
                      text: 'Verificar',
                      icon: Icons.verified_user_rounded,
                      isLoading: authState.isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.spaceMd),

              // Toggle backup code
              GestureDetector(
                onTap: () {
                  setState(() {
                    _useBackupCode = !_useBackupCode;
                    _codeController.clear();
                    ref.read(authNotifierProvider.notifier).clearError();
                  });
                },
                child: Text(
                  _useBackupCode
                      ? 'Usar código de autenticación (TOTP)'
                      : 'Usar código de respaldo',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
