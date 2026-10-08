import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/theft_mode/domain/repositories/wipe_repository.dart';
import 'package:guardian_mobile/features/theft_mode/domain/usecases/wipe_device_usecase.dart';
import 'package:guardian_mobile/features/theft_mode/presentation/providers/wipe_wizard_provider.dart';

class MockWipeRepository implements WipeRepository {
  String? lastDeviceId;
  String? lastPassword;
  String? lastConfirmation;
  bool shouldThrow = false;
  Exception? exceptionToThrow;

  @override
  Future<void> wipeDevice({
    required String deviceId,
    required String password,
    String confirmationText = 'BORRAR',
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? Exception('Network failure');
    }
    lastDeviceId = deviceId;
    lastPassword = password;
    lastConfirmation = confirmationText;
  }
}

void main() {
  group('WipeDeviceUseCase', () {
    late MockWipeRepository repository;
    late WipeDeviceUseCase useCase;

    setUp(() {
      repository = MockWipeRepository();
      useCase = WipeDeviceUseCase(repository);
    });

    test('calls repository with correct parameters', () async {
      await useCase(
        deviceId: 'dev-123',
        password: 'secretPassword123',
        confirmationText: 'BORRAR',
      );

      expect(repository.lastDeviceId, 'dev-123');
      expect(repository.lastPassword, 'secretPassword123');
      expect(repository.lastConfirmation, 'BORRAR');
    });
  });

  group('WipeWizardState', () {
    test('validates checklist completion correctly', () {
      const state = WipeWizardState();
      expect(state.isChecklistComplete, isFalse);

      final completedState = state.copyWith(
        checklistConsequences: true,
        checklistOtherMethods: true,
        checklistCorrectDevice: true,
      );
      expect(completedState.isChecklistComplete, isTrue);
    });

    test('validates BORRAR confirmation text strictly case-sensitive', () {
      const state = WipeWizardState();
      expect(state.isConfirmationValid, isFalse);

      final lowerState = state.copyWith(confirmationInput: 'borrar');
      expect(lowerState.isConfirmationValid, isFalse);

      final validState = state.copyWith(confirmationInput: 'BORRAR');
      expect(validState.isConfirmationValid, isTrue);
    });

    test('validates password input presence', () {
      const state = WipeWizardState();
      expect(state.isPasswordValid, isFalse);

      final validState = state.copyWith(passwordInput: 'my-pass');
      expect(validState.isPasswordValid, isTrue);
    });
  });
}
