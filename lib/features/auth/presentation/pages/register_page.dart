import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_field.dart';
import '../../../../core/theme/app_widgets.dart';
import '../providers/auth_provider.dart';
import '../../../../core/localization/language_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateBack() {
    ref.read(authNotifierProvider.notifier).clearError();
    context.go('/login');
  }

  void _submitRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authNotifierProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = ref.watch(languageProvider) == AppLanguage.en;
    final authState = ref.watch(authNotifierProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(isEn ? 'User Registration' : 'Registro de Usuario'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _navigateBack,
          ),
        ),
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.spaceSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRegisterHeader(isEn),
              const SizedBox(height: AppSpacing.spaceMd),
              if (authState.errorMessage != null) ...[
                _buildErrorBanner(authState.errorMessage!),
                const SizedBox(height: AppSpacing.spaceMd),
              ],
              _buildFormCard(authState.isLoading, isEn),
              const SizedBox(height: AppSpacing.spaceLg),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildRegisterHeader(bool isEn) {
    return Column(
      children: [
        Text(
          isEn ? 'Create your Account' : 'Crea tu Cuenta',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.spaceXs),
        Text(
          isEn ? 'Protect your devices instantly with real-time telemetry' : 'Protege tus dispositivos de inmediato con telemetría en tiempo real',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textBody,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.alertContainer,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: AppColors.alert.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.alertText,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.spaceSm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.alertText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isLoading, bool isEn) {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _nameController,
              label: isEn ? 'Full name or identifier' : 'Nombre completo o identificador',
              hintText: 'Alex Developer',
              prefixIcon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return isEn ? 'Name is required' : 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.spaceMd),
            AppTextField(
              controller: _emailController,
              label: isEn ? 'Email address' : 'Correo electrónico',
              hintText: 'usuario@guardianmobile.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return isEn ? 'Email is required' : 'El correo es requerido';
                }
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                if (!emailRegex.hasMatch(value.trim())) {
                  return isEn ? 'Enter a valid email address' : 'Ingresa un correo electrónico válido';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.spaceMd),
            AppTextField(
              controller: _passwordController,
              label: isEn ? 'Master password' : 'Contraseña maestra',
              hintText: isEn ? 'Min 8 characters, 1 letter, 1 number' : 'Mínimo 8 caracteres, 1 letra y 1 número',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return isEn ? 'Password is required' : 'La contraseña es requerida';
                }
                if (value.length < 8) {
                  return isEn ? 'Must be at least 8 characters' : 'Debe tener al menos 8 caracteres';
                }
                final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
                final hasDigit = RegExp(r'[0-9]').hasMatch(value);
                if (!hasLetter || !hasDigit) {
                  return isEn ? 'Must include at least 1 letter and 1 number' : 'Debe incluir al menos 1 letra y 1 número';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.spaceMd),
            AppTextField(
              controller: _confirmPasswordController,
              label: isEn ? 'Confirm master password' : 'Confirmar contraseña maestra',
              hintText: isEn ? 'Repeat your password' : 'Repite tu contraseña',
              prefixIcon: Icons.lock_reset_rounded,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitRegister(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return isEn ? 'Confirm your password' : 'Confirma tu contraseña';
                }
                if (value != _passwordController.text) {
                  return isEn ? 'Passwords do not match' : 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.spaceSm),
            // Password requirements hint
            Container(
              padding: const EdgeInsets.all(AppSpacing.spaceSm),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEn ? 'Requirements: Min 8 chars, 1 letter and 1 number.' : 'Requisitos: Mínimo 8 caracteres, 1 letra y 1 número.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.spaceLg),
            PrimaryButton(
              text: isEn ? 'Register Account' : 'Registrar Cuenta',
              icon: Icons.app_registration_rounded,
              isLoading: isLoading,
              onPressed: _submitRegister,
            ),
            const SizedBox(height: AppSpacing.spaceMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isEn ? 'Already have an account? ' : '¿Ya tienes una cuenta? ',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textBody,
                  ),
                ),
                GestureDetector(
                  onTap: _navigateBack,
                  child: Text(
                    isEn ? 'Sign in' : 'Inicia sesión',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
