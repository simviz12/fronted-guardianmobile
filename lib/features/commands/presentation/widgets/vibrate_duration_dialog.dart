import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/guardian_theme.dart';

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
          Text(
            'El teléfono vibrará durante la duración seleccionada:',
            style: TextStyle(fontSize: 14, color: context.gm.ink),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Text(
            '$_seconds segundos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.gm.brand,
            ),
          ),
          Slider(
            value: _seconds.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            activeColor: context.gm.brand,
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
            backgroundColor: context.gm.brand,
            foregroundColor: context.gm.onBrand,
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
