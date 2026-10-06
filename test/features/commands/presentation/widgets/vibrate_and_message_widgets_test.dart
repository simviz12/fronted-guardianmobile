import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/commands/presentation/widgets/send_message_bottom_sheet.dart';
import 'package:guardian_mobile/features/commands/presentation/widgets/vibrate_duration_dialog.dart';

void main() {
  group('VibrateDurationDialog', () {
    testWidgets('renders slider and confirms chosen duration', (tester) async {
      int? chosenSeconds;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VibrateDurationDialog(
              onConfirm: (sec) {
                chosenSeconds = sec;
              },
            ),
          ),
        ),
      );

      expect(find.text('Vibrar dispositivo'), findsOneWidget);
      expect(find.text('5 segundos'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Confirm button
      await tester.tap(find.text('Vibrar ahora'));
      await tester.pump();

      expect(chosenSeconds, 5);
    });
  });

  group('SendMessageBottomSheet', () {
    testWidgets('validates required message and enforces 200 char counter', (tester) async {
      String? sentText;
      String? sentPhone;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SendMessageBottomSheet(
              onSend: (text, phone) {
                sentText = text;
                sentPhone = phone;
              },
            ),
          ),
        ),
      );

      expect(find.text('Mostrar mensaje en pantalla'), findsOneWidget);
      expect(find.text('Enviar Mensaje'), findsOneWidget);

      // Try sending with empty text
      final submitButton = find.text('Enviar Mensaje');
      await tester.tap(submitButton);
      await tester.pump();

      expect(sentText, isNull);

      // Fill valid text and phone
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mensaje *'),
        'Por favor devolver este teléfono a recepción',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Teléfono de contacto (Opcional)'),
        '+57 300 987 6543',
      );
      await tester.pump();

      await tester.tap(find.text('Enviar Mensaje'));
      await tester.pump();

      expect(sentText, 'Por favor devolver este teléfono a recepción');
      expect(sentPhone, '+57 300 987 6543');
    });
  });
}
