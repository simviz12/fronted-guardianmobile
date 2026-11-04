import 'package:flutter/material.dart';
import '../../domain/entities/command.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/guardian_theme.dart';

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
        color: context.gm.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isFailed || isExpired ? context.gm.danger : context.gm.brand,
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
                color: isFailed || isExpired ? context.gm.danger : context.gm.brand,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: Text(
                  _getHeaderTitle(command.status),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isFailed || isExpired ? context.gm.danger : context.gm.brand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Stepper bar
          Row(
            children: [
              _buildStepItem(context, 
                index: 0,
                label: 'Enviado',
                isCompleted: currentStep >= 1,
                isActive: currentStep == 1,
              ),
              _buildConnector(context, isCompleted: currentStep >= 2),
              _buildStepItem(context, 
                index: 1,
                label: 'Recibido',
                isCompleted: currentStep >= 2,
                isActive: currentStep == 2,
              ),
              _buildConnector(context, isCompleted: currentStep >= 3),
              _buildStepItem(context, 
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
                                    : (command.type == CommandType.locate
                                        ? 'Ubicado'
                                        : 'Sonando'))))),
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
              style: TextStyle(
                fontSize: 12,
                color: context.gm.dangerInk,
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
        } else if (command.type == CommandType.locate) {
          return '¡Ubicación GPS obtenida exitosamente!';
        }
        return '¡Sonando a máximo volumen!';
      case CommandStatus.failed:
        return 'La orden no pudo ejecutarse';
      case CommandStatus.expired:
        return 'Orden expirada (sin respuesta)';
    }
  }

  Widget _buildStepItem(BuildContext context, {
    required int index,
    required String label,
    required bool isCompleted,
    required bool isActive,
    bool isError = false,
  }) {
    Color color = context.gm.inkMuted;
    if (isError) {
      color = context.gm.danger;
    } else if (isCompleted) {
      color = context.gm.brand;
    }

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted ? color : context.gm.surface,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    isError ? Icons.close_rounded : Icons.check_rounded,
                    color: context.gm.surface,
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
            color: isError ? context.gm.danger : (isCompleted ? context.gm.ink : context.gm.inkMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(BuildContext context, {required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: isCompleted ? context.gm.brand : context.gm.border,
      ),
    );
  }
}
