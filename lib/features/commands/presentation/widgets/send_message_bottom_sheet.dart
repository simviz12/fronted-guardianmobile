import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';

class SendMessageBottomSheet extends StatefulWidget {
  final void Function(String text, String? contactPhone) onSend;

  const SendMessageBottomSheet({
    super.key,
    required this.onSend,
  });

  @override
  State<SendMessageBottomSheet> createState() => _SendMessageBottomSheetState();
}

class _SendMessageBottomSheetState extends State<SendMessageBottomSheet> {
  final _textController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _textController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final text = _textController.text.trim();
      final phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
      Navigator.pop(context);
      widget.onSend(text, phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
        top: AppSpacing.spaceMd,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.marginMobile,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.spaceSm),
                  decoration: BoxDecoration(
                    color: AppColors.neutralBadge,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.message_rounded, color: AppColors.primary),
                  SizedBox(width: AppSpacing.spaceSm),
                  Text(
                    'Mostrar mensaje en pantalla',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeadings,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'El mensaje aparecerá a pantalla completa en el dispositivo protegido, incluso si está bloqueado.',
                style: TextStyle(fontSize: 12, color: AppColors.textBody),
              ),
              const SizedBox(height: AppSpacing.spaceMd),

              // Mensaje con contador de 200 caracteres
              TextFormField(
                controller: _textController,
                maxLength: 200,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mensaje *',
                  hintText: 'Ej: Por favor devolver este teléfono, recompensa garantizada.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El mensaje no puede estar vacío';
                  }
                  if (val.trim().length > 200) {
                    return 'Máximo 200 caracteres permitidos';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.spaceSm),

              // Teléfono de contacto opcional
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono de contacto (Opcional)',
                  hintText: '+57 300 123 4567',
                  prefixIcon: Icon(Icons.phone_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.spaceMd),

              PrimaryButton(
                text: 'Enviar Mensaje',
                icon: Icons.send_rounded,
                onPressed: _textController.text.trim().isEmpty ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
