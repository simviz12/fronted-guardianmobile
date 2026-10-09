import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../devices/domain/entities/device.dart';
import '../providers/wipe_wizard_provider.dart';

class WipeWizardPage extends ConsumerStatefulWidget {
  final Device device;

  const WipeWizardPage({super.key, required this.device});

  @override
  ConsumerState<WipeWizardPage> createState() => _WipeWizardPageState();
}

class _WipeWizardPageState extends ConsumerState<WipeWizardPage> {
  final TextEditingController _confirmationController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _twoFactorController = TextEditingController();

  @override
  void dispose() {
    _confirmationController.dispose();
    _passwordController.dispose();
    _twoFactorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(wipeWizardProvider(widget.device.id));
    final notifier = ref.read(wipeWizardProvider(widget.device.id).notifier);

    // If active execution progress or final state reached, show progress screen
    if (wizardState.progressStep != WipeProgressStep.idle &&
        wizardState.progressStep != WipeProgressStep.failed) {
      return _buildProgressScaffold(context, wizardState);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Protocolo de Destrucción'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (wizardState.currentStep > 1) {
              notifier.previousStep();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Indicator Header
            _buildStepIndicator(wizardState.currentStep),

            if (wizardState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                  vertical: AppSpacing.spaceXs,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.spaceSm),
                  decoration: BoxDecoration(
                    color: AppColors.alertContainer,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.alert.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.alert, size: 20),
                      const SizedBox(width: AppSpacing.spaceSm),
                      Expanded(
                        child: Text(
                          wizardState.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.alertText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.marginMobile),
                child: _buildCurrentStepContent(context, wizardState, notifier),
              ),
            ),

            // Footer navigation buttons
            _buildFooterButtons(context, wizardState, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile, vertical: AppSpacing.spaceSm),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PASO $currentStep DE 4',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.alert,
                ),
              ),
              Text(
                _getStepTitle(currentStep),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeadings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(4, (index) {
              final stepNum = index + 1;
              final isPassed = stepNum <= currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 3 ? 6.0 : 0.0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isPassed ? AppColors.alert : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Consecuencias';
      case 2:
        return 'Lista de Verificación';
      case 3:
        return 'Confirmación Escrita';
      case 4:
        return 'Autorización Criptográfica';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepContent(
    BuildContext context,
    WipeWizardState state,
    WipeWizardNotifier notifier,
  ) {
    switch (state.currentStep) {
      case 1:
        return _buildStep1Consequences();
      case 2:
        return _buildStep2Checklist(state, notifier);
      case 3:
        return _buildStep3ConfirmationInput(state, notifier);
      case 4:
        return _buildStep4PasswordAuth(state, notifier);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: What will happen & Irreversibility
  Widget _buildStep1Consequences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          decoration: BoxDecoration(
            color: AppColors.alertContainer,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: AppColors.alert.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.alert,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: AppSpacing.spaceMd),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACCIÓN DEFINITIVA E IRREVERSIBLE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.alertText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Restablecimiento de Fábrica Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeadings,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.spaceLg),
        const Text(
          '¿Qué sucederá exactamente al ejecutar esta orden?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textHeadings,
          ),
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        const Text(
          'Al enviar la orden de autodestrucción criptográfica, el dispositivo recibirá la señal y borrará permanentemente todo su almacenamiento:',
          style: TextStyle(fontSize: 13, color: AppColors.textBody, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.spaceMd),
        _buildConsequenceTile(
          icon: Icons.photo_library_outlined,
          title: 'Fotos, videos y documentos personales',
          subtitle: 'Se destruirán todos los archivos de la memoria interna.',
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        _buildConsequenceTile(
          icon: Icons.account_balance_outlined,
          title: 'Cuentas bancarias y credenciales guardadas',
          subtitle: 'Se cerrarán y eliminarán tokens, sesiones y billeteras digitales.',
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        _buildConsequenceTile(
          icon: Icons.location_off_rounded,
          title: 'Pérdida irreversible de geolocalización',
          subtitle: 'El teléfono volverá a su estado de fábrica y ya no podrá ser rastreado por Guardian Mobile.',
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        _buildConsequenceTile(
          icon: Icons.phonelink_erase_rounded,
          title: 'Desvinculación permanente',
          subtitle: 'El equipo quedará sin apps de rastreo y no responderá a más comandos remotos.',
        ),
      ],
    );
  }

  Widget _buildConsequenceTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.alert, size: 22),
          const SizedBox(width: AppSpacing.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadings,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2: Checklist
  Widget _buildStep2Checklist(WipeWizardState state, WipeWizardNotifier notifier) {
    final targetDeviceName = '${widget.device.name} (${widget.device.model ?? 'Android'})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Confirmación de Seguridad',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textHeadings),
        ),
        const SizedBox(height: 4),
        const Text(
          'Debes marcar cada una de las siguientes casillas para demostrar que comprendes el alcance de esta operación:',
          style: TextStyle(fontSize: 13, color: AppColors.textBody, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.spaceLg),

        CheckboxListTile(
          value: state.checklistConsequences,
          onChanged: notifier.toggleChecklistConsequences,
          activeColor: AppColors.alert,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Entiendo que se borrarán todos los datos',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textHeadings),
          ),
          subtitle: const Text(
            'Comprendo que la pérdida de fotos, mensajes y documentos es permanente y no se puede deshacer.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const Divider(),

        CheckboxListTile(
          value: state.checklistOtherMethods,
          onChanged: notifier.toggleChecklistOtherMethods,
          activeColor: AppColors.alert,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Ya intenté recuperarlo de otras formas',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textHeadings),
          ),
          subtitle: const Text(
            'He intentado localizarlo, llamar al teléfono o enviar un mensaje en pantalla sin éxito.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const Divider(),

        CheckboxListTile(
          value: state.checklistCorrectDevice,
          onChanged: notifier.toggleChecklistCorrectDevice,
          activeColor: AppColors.alert,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Es el dispositivo correcto: $targetDeviceName',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textHeadings),
          ),
          subtitle: Text(
            'Confirmo que el identificador ${widget.device.id.substring(0, 8)}... corresponde al teléfono que deseo borrar.',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  // STEP 3: Typing word BORRAR
  Widget _buildStep3ConfirmationInput(WipeWizardState state, WipeWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Confirmación por Texto',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textHeadings),
        ),
        const SizedBox(height: 6),
        const Text(
          'Para prevenir borrados involuntarios o accidentales, escribe con exactitud la palabra clave en mayúsculas:',
          style: TextStyle(fontSize: 13, color: AppColors.textBody, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.spaceLg),

        Container(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.alert.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Escribe exactamente:',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.alertContainer,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Text(
                  'BORRAR',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.alert,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.spaceMd),
              TextField(
                controller: _confirmationController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'BORRAR',
                  hintStyle: TextStyle(
                    fontFamily: 'monospace',
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.alert),
                  suffixIcon: state.isConfirmationValid
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.safe)
                      : null,
                ),
                onChanged: (val) {
                  notifier.setConfirmationInput(val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 4: Password Re-authentication
  Widget _buildStep4PasswordAuth(WipeWizardState state, WipeWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Autorización Criptográfica',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textHeadings),
        ),
        const SizedBox(height: 6),
        const Text(
          'Re-autenticación obligatoria: ingresa la contraseña de tu cuenta de Guardian Mobile para firmar la orden.',
          style: TextStyle(fontSize: 13, color: AppColors.textBody, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.spaceLg),

        Container(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contraseña de tu cuenta',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textHeadings),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Ingresa tu contraseña',
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                ),
                onChanged: (val) {
                  notifier.setPasswordInput(val);
                },
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: AppColors.alert),
                  SizedBox(width: 6),
                  Text(
                    'Seguridad: límite de 3 intentos por hora.',
                    style: TextStyle(fontSize: 11, color: AppColors.alert, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spaceMd),
              const Text(
                'Código de Verificación 2FA (si está activo)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textHeadings),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _twoFactorController,
                decoration: const InputDecoration(
                  hintText: 'Código TOTP o de respaldo',
                  prefixIcon: Icon(Icons.pin_outlined, color: AppColors.primary),
                ),
                onChanged: (val) {
                  notifier.setTwoFactorCodeInput(val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButtons(
    BuildContext context,
    WipeWizardState state,
    WipeWizardNotifier notifier,
  ) {
    final isStep1 = state.currentStep == 1;
    final isStep2 = state.currentStep == 2;
    final isStep3 = state.currentStep == 3;
    final isStep4 = state.currentStep == 4;

    bool canProceed = false;
    if (isStep1) canProceed = true;
    if (isStep2) canProceed = state.isChecklistComplete;
    if (isStep3) canProceed = state.isConfirmationValid;
    if (isStep4) canProceed = state.isPasswordValid && !state.isSubmitting;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isStep4)
            DangerButton(
              text: 'Siguiente (${state.currentStep}/4)',
              icon: Icons.arrow_forward_rounded,
              onPressed: canProceed ? () => notifier.nextStep() : null,
            )
          else
            DangerButton(
              text: state.isSubmitting ? 'Transmitiendo orden...' : 'Borrar dispositivo definitivamente',
              icon: Icons.delete_forever_rounded,
              isLoading: state.isSubmitting,
              onPressed: canProceed ? () => notifier.executeWipe() : null,
            ),
          const SizedBox(height: AppSpacing.spaceSm),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancelar y mantener rastreo', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  // PROGRESS SCREEN (Driven by realtime events)
  Widget _buildProgressScaffold(BuildContext context, WipeWizardState state) {
    final isOfflineDone = state.progressStep == WipeProgressStep.offlineCompleted;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ejecutando Borrado'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: isOfflineDone ? AppColors.alert : AppColors.alertContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOfflineDone ? Icons.check_rounded : Icons.delete_forever_rounded,
                    color: isOfflineDone ? Colors.white : AppColors.alert,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.spaceLg),
              Text(
                isOfflineDone
                    ? 'Borrado Iniciado en Dispositivo'
                    : 'Transmitiendo Orden Criptográfica',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeadings,
                ),
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              Text(
                isOfflineDone
                    ? 'El dispositivo ya no responde: el borrado se inició y se desconectó de la red.'
                    : 'Esperando confirmación del dispositivo protegido vía canal seguro.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.spaceXl),

              // Step Progress Checklist
              _buildProgressRow(
                label: 'Orden transmitida al servidor',
                isCompleted: state.progressStep.index >= WipeProgressStep.sent.index,
                isCurrent: state.progressStep == WipeProgressStep.sending,
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              _buildProgressRow(
                label: 'Recibido por el dispositivo',
                isCompleted: state.progressStep.index >= WipeProgressStep.received.index,
                isCurrent: state.progressStep == WipeProgressStep.sent,
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              _buildProgressRow(
                label: 'Ejecución de restablecimiento (wipeData)',
                isCompleted: state.progressStep.index >= WipeProgressStep.wiping.index,
                isCurrent: state.progressStep == WipeProgressStep.received,
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              _buildProgressRow(
                label: 'Dispositivo desconectado (Completado)',
                isCompleted: isOfflineDone,
                isCurrent: state.progressStep == WipeProgressStep.wiping,
              ),

              const SizedBox(height: AppSpacing.spaceXl),
              if (isOfflineDone)
                PrimaryButton(
                  text: 'Volver al Inicio',
                  icon: Icons.home_rounded,
                  onPressed: () => context.go('/home'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd, vertical: AppSpacing.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          if (isCompleted)
            const Icon(Icons.check_circle_rounded, color: AppColors.safe, size: 20)
          else if (isCurrent)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.alert),
            )
          else
            const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textMuted, size: 20),
          const SizedBox(width: AppSpacing.spaceSm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCompleted || isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCompleted || isCurrent ? AppColors.textHeadings : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
