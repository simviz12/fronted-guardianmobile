import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class VibrateDurationDialog extends StatefulWidget {
  final ValueChanged<int> onConfirm;

  const VibrateDurationDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  State<VibrateDurationDialog> createState() => _VibrateDurationDialogState();
}

class _VibrateDurationDialogState extends State<VibrateDurationDialog> {
  int _seconds = 5;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vibrar dispositivo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'El teléfono vibrará durante la duración seleccionada:',
            style: TextStyle(fontSize: 14, color: AppColors.textBody),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Text(
            '$_seconds segundos',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Slider(
            value: _seconds.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            activeColor: AppColors.primary,
            label: '$_seconds s',
            onChanged: (val) {
              setState(() {
                _seconds = val.round();
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
            widget.onConfirm(_seconds);
          },
          child: const Text('Vibrar ahora'),
        ),
      ],
    );
  }
}
