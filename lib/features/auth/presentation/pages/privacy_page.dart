import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacidad y Seguridad'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.privacy_tip_outlined,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMd),
            Text(
              'Compromiso de Privacidad Guardian',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadings,
                  ),
            ),
            const SizedBox(height: AppSpacing.spaceSm),
            const Text(
              'Guardian Mobile protege tu dispositivo minimizando la recolección de datos y aplicando cifrado en tránsito y en reposo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textBody,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.spaceLg),
            _buildSection(
              title: '¿Qué datos recolectamos?',
              items: [
                'Ubicación geográfica: Solo se reporta cuando el reporte periódico está activo, cuando solicitas localizar el equipo bajo demanda, o cuando el Modo Robo está encendido.',
                'Telemetría del dispositivo: Nivel y estado de carga de batería, tipo de conexión de red (Wi-Fi / Celular) y estado de conectividad.',
                'Identificadores técnicos: ID de dispositivo único asignado, modelo de hardware y capacidades de administración.',
              ],
            ),
            const SizedBox(height: AppSpacing.spaceMd),
            _buildSection(
              title: '¿Qué NO recolectamos?',
              items: [
                'No leemos mensajes de texto, chats, contactos o correos personales.',
                'No accedemos a fotos, videos o archivos multimedia del dispositivo a menos que se ejecute la orden explícita de Borrado Remoto de fábrica.',
                'No vendemos ni compartimos telemetría con anunciantes ni terceros.',
              ],
            ),
            const SizedBox(height: AppSpacing.spaceMd),
            _buildSection(
              title: 'Cifrado y Seguridad de Acceso',
              items: [
                'Todas las comunicaciones API y sockets usan cifrado TLS/HTTPS.',
                'Tokens y claves criptográficas se almacenan en el Keystore/EncryptedSharedPreferences de Android.',
                'La autenticación en dos factores (2FA / TOTP) y las contraseñas usan algoritmos robustos con límites de reintentos.',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<String> items}) {
    return AppCard(
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
          const SizedBox(height: AppSpacing.spaceSm),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spaceSm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textBody,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
