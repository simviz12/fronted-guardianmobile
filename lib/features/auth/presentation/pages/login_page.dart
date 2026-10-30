import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_field.dart';
import '../../../../core/theme/app_widgets.dart';
import '../providers/auth_provider.dart';
import '../../../../core/localization/language_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final result = await ref.read(authNotifierProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (result == null && mounted) {
        // 2FA required: navigate to 2FA verification page
        context.push('/2fa-login');
      }
    }
  }

  Future<void> _showServerDialog(BuildContext context) async {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    String testStatus = '';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Row(
                children: [
                  Icon(Icons.dns_rounded, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Servidor / Backend', style: TextStyle(fontSize: 18, color: AppColors.textHeadings)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Configura la URL del backend para conectar tu app con la base de datos y comandos.',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      style: const TextStyle(color: AppColors.textHeadings, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'URL de la API',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Accesos rápidos:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          controller.text = ApiConfig.defaultUrl;
                          testStatus = '';
                        });
                      },
                      icon: const Icon(Icons.cloud_outlined, size: 16),
                      label: const Text('Túnel Seguro (Global)', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          controller.text = 'http://192.168.0.14:3001';
                          testStatus = '';
                        });
                      },
                      icon: const Icon(Icons.wifi_rounded, size: 16),
                      label: const Text('Wi-Fi Local (192.168.0.14:3001)', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceContainer),
                      onPressed: () async {
                        setDialogState(() => testStatus = 'Probando...');
                        try {
                          final testDio = Dio(BaseOptions(
                            baseUrl: controller.text.trim(),
                            connectTimeout: const Duration(seconds: 4),
                            receiveTimeout: const Duration(seconds: 4),
                          ));
                          final res = await testDio.get('/health');
                          if (res.statusCode == 200) {
                            setDialogState(() => testStatus = '¡Conexión Exitosa! (Online)');
                          } else {
                            setDialogState(() => testStatus = 'Error de respuesta: HTTP ${res.statusCode}');
                          }
                        } catch (e) {
                          setDialogState(() => testStatus = 'Fallo de conexión al servidor');
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Probar conexión', style: TextStyle(fontSize: 12)),
                    ),
                    if (testStatus.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        testStatus,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: testStatus.contains('Exitosa') ? Colors.green : Colors.amber,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newUrl = controller.text.trim();
                    if (newUrl.isNotEmpty) {
                      await ApiConfig.setBaseUrl(newUrl);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Servidor actualizado: $newUrl'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = ref.watch(languageProvider) == AppLanguage.en;
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _showServerDialog(context),
                    icon: const Icon(Icons.dns_rounded, size: 16),
                    label: const Text('Servidor / API'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => ref.read(languageProvider.notifier).toggleLanguage(),
                    icon: const Icon(Icons.language_rounded, size: 16),
                    label: Text(isEn ? 'ES' : 'EN'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spaceXs),
              _buildTrustHeader(isEn),
              const SizedBox(height: AppSpacing.spaceLg),
              if (authState.errorMessage != null) ...[
                _buildErrorBanner(authState.errorMessage!),
                const SizedBox(height: AppSpacing.spaceMd),
              ],
              _buildFormCard(authState.isLoading, isEn),
              const SizedBox(height: AppSpacing.spaceMd),
              _buildProtectionBadge(isEn),
              const SizedBox(height: AppSpacing.spaceLg),
              _buildFooter(isEn),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustHeader(bool isEn) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF82F9C2).withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 30,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spaceMd),
        Text(
          isEn ? 'Secure Access' : 'Acceso Seguro',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 24,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.spaceXs),
        Text(
          isEn ? 'Enter your credentials to manage and track your protected devices' : 'Ingresa tus credenciales para gestionar y localizar tus dispositivos protegidos',
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
              controller: _emailController,
              label: isEn ? 'Email address' : 'Correo electrónico institucional o personal',
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
              hintText: '••••••••••••',
              prefixIcon: Icons.key_outlined,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitLogin(),
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
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.spaceLg),
            PrimaryButton(
              text: isEn ? 'Secure Sign In' : 'Iniciar Sesión Segura',
              icon: Icons.verified_user_outlined,
              isLoading: isLoading,
              onPressed: _submitLogin,
            ),
            const SizedBox(height: AppSpacing.spaceMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isEn ? "Don't have an account? " : '¿No tienes una cuenta? ',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textBody,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ref.read(authNotifierProvider.notifier).clearError();
                    context.push('/register');
                  },
                  child: Text(
                    isEn ? 'Create account' : 'Crear cuenta',
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

  Widget _buildProtectionBadge(bool isEn) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield_rounded,
              color: AppColors.primary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isEn ? 'Secure remote authentication channel' : 'Canal seguro de autenticación remota',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textHeadings,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isEn) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.push('/server-status'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dns_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              SizedBox(width: 6),
              Text(
                isEn ? 'Server Status (Diagnostics)' : 'Estado del servidor (Diagnóstico)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.spaceXs),
        Text(
          isEn ? 'Protected with end-to-end AES-256 encryption' : 'Protegido con cifrado punto a punto AES-256',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
