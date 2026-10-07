import 'package:flutter/material.dart';
import '../../domain/entities/command.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class CommandLiveStatusStepper extends StatelessWidget {
  final Command command;

  const CommandLiveStatusStepper({
    super.key,
    required this.command,
  });

  @override
  Widget build(BuildContext context) {
    // Determine active step index
    // 0: Enviando
    // 1: Enviado (PENDING)
    // 2: Recibido (DELIVERED)
    // 3: Sonando (EXECUTED) / Falló (FAILED) / Expiró (EXPIRED)

    int currentStep = 1; // At least Enviado
    if (command.status == CommandStatus.delivered) {
      currentStep = 2;
    } else if (command.status == CommandStatus.executed ||
        command.status == CommandStatus.failed ||
        command.status == CommandStatus.expired) {
      currentStep = 3;
    }

    final isFailed = command.status == CommandStatus.failed;
    final isExpired = command.status == CommandStatus.expired;
    final isExecuted = command.status == CommandStatus.executed;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isFailed || isExpired ? AppColors.alert : AppColors.primary,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isExecuted
                    ? Icons.volume_up_rounded
                    : (isFailed || isExpired
                        ? Icons.error_outline_rounded
                        : Icons.sync_rounded),
                color: isFailed || isExpired ? AppColors.alert : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: Text(
                  _getHeaderTitle(command.status),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isFailed || isExpired ? AppColors.alert : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Stepper bar
          Row(
            children: [
              _buildStepItem(
                index: 0,
                label: 'Enviado',
                isCompleted: currentStep >= 1,
                isActive: currentStep == 1,
              ),
              _buildConnector(isCompleted: currentStep >= 2),
              _buildStepItem(
                index: 1,
                label: 'Recibido',
                isCompleted: currentStep >= 2,
                isActive: currentStep == 2,
              ),
              _buildConnector(isCompleted: currentStep >= 3),
              _buildStepItem(
                index: 2,
                label: isFailed
                    ? 'Falló'
                    : (isExpired
                        ? 'Expiró'
                        : (command.type == CommandType.vibrate
                            ? 'Vibrando'
                            : (command.type == CommandType.message
                                ? 'Mostrado'
                                : (command.type == CommandType.lock
                                    ? 'Bloqueado'
                                    : 'Sonando')))),
                isCompleted: currentStep >= 3,
                isActive: currentStep == 3,
                isError: isFailed || isExpired,
              ),
            ],
          ),

          if (command.failureReason != null) ...[
            const SizedBox(height: AppSpacing.spaceSm),
            Text(
              'Motivo: ${command.failureReason}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.alertText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getHeaderTitle(CommandStatus status) {
    switch (status) {
      case CommandStatus.pending:
        return 'Enviando orden al dispositivo...';
      case CommandStatus.delivered:
        return 'Orden recibida en el celular';
      case CommandStatus.executed:
        if (command.type == CommandType.vibrate) {
          return '¡Vibrando por el tiempo elegido!';
        } else if (command.type == CommandType.message) {
          return '¡Mensaje mostrado en pantalla!';
        } else if (command.type == CommandType.lock) {
          return '¡Pantalla bloqueada exitosamente!';
        }
        return '¡Sonando a máximo volumen!';
      case CommandStatus.failed:
        return 'La orden no pudo ejecutarse';
      case CommandStatus.expired:
        return 'Orden expirada (sin respuesta)';
    }
  }

  Widget _buildStepItem({
    required int index,
    required String label,
    required bool isCompleted,
    required bool isActive,
    bool isError = false,
  }) {
    Color color = AppColors.textMuted;
    if (isError) {
      color = AppColors.alert;
    } else if (isCompleted) {
      color = AppColors.primary;
    }

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted ? color : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    isError ? Icons.close_rounded : Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  )
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
            color: isError ? AppColors.alert : (isCompleted ? AppColors.textHeadings : AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildConnector({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: isCompleted ? AppColors.primary : AppColors.border,
      ),
    );
  }
}
