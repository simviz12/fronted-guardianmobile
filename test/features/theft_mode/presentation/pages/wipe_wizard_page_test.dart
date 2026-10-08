import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/devices/domain/entities/device.dart';
import 'package:guardian_mobile/features/theft_mode/domain/repositories/wipe_repository.dart';
import 'package:guardian_mobile/features/theft_mode/presentation/pages/wipe_wizard_page.dart';
import 'package:guardian_mobile/features/theft_mode/presentation/providers/wipe_wizard_provider.dart';

class FakeWipeRepository implements WipeRepository {
  @override
  Future<void> wipeDevice({
    required String deviceId,
    required String password,
    String confirmationText = 'BORRAR',
    String? twoFactorCode,
  }) async {}
}

void main() {
  final testDevice = Device(
    id: 'test-device-uuid',
    ownerId: 'owner-uuid',
    installId: 'install-uuid',
    name: 'Samsung Galaxy S24',
    platform: 'android',
    model: 'SM-S921B',
    osVersion: '14.0',
    mode: DeviceMode.protected,
    isOnline: true,
    adminEnabled: true,
    wipeEnabled: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        wipeRepositoryProvider.overrideWithValue(FakeWipeRepository()),
      ],
      child: MaterialApp(
        home: WipeWizardPage(device: testDevice),
      ),
    );
  }

  testWidgets('WipeWizardPage renders Step 1 Consequences by default', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('PASO 1 DE 4'), findsOneWidget);
    expect(find.text('Consecuencias'), findsOneWidget);
    expect(find.text('ACCIÓN DEFINITIVA E IRREVERSIBLE'), findsOneWidget);
    expect(find.text('Siguiente (1/4)'), findsOneWidget);
  });

  testWidgets('WipeWizardPage navigates to Step 2 Checklist and enforces checks', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap Siguiente to go to Step 2
    await tester.tap(find.text('Siguiente (1/4)'));
    await tester.pumpAndSettle();

    expect(find.text('PASO 2 DE 4'), findsOneWidget);
    expect(find.text('Confirmación de Seguridad'), findsOneWidget);
    expect(find.text('Entiendo que se borrarán todos los datos'), findsOneWidget);

    // Verify Siguiente is disabled until checkboxes checked
    // Check all checkboxes
    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsNWidgets(3));

    await tester.tap(checkboxes.at(0));
    await tester.pumpAndSettle();
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();
    await tester.tap(checkboxes.at(2));
    await tester.pumpAndSettle();

    // Now step 2 can proceed
    await tester.tap(find.text('Siguiente (2/4)'));
    await tester.pumpAndSettle();

    // Step 3
    expect(find.text('PASO 3 DE 4'), findsOneWidget);
    expect(find.text('Confirmación por Texto'), findsOneWidget);
  });
}
