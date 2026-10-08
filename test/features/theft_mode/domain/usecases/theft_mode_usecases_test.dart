import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/theft_mode/data/models/theft_mode_dto.dart';
import 'package:guardian_mobile/features/theft_mode/domain/entities/theft_mode_config.dart';
import 'package:guardian_mobile/features/theft_mode/domain/repositories/theft_mode_repository.dart';
import 'package:guardian_mobile/features/theft_mode/domain/usecases/theft_mode_usecases.dart';
import 'package:mocktail/mocktail.dart';

class MockTheftModeRepository extends Mock implements TheftModeRepository {}

void main() {
  late MockTheftModeRepository mockRepo;
  late ActivateTheftModeUseCase activateUseCase;
  late GetActiveTheftModeUseCase getActiveUseCase;
  late DeactivateTheftModeUseCase deactivateUseCase;


  final activeConfig = TheftModeConfig(
    id: 'theft-1',
    deviceId: 'dev-1',
    message: 'Perdido. Contactar.',
    contactPhone: '+525512345678',
    locationIntervalSeconds: 60,
    alarm: true,
    lock: true,
    activatedAt: DateTime.parse('2026-10-07T10:00:00Z'),
    deactivatedAt: null,
  );

  setUp(() {
    mockRepo = MockTheftModeRepository();
    activateUseCase = ActivateTheftModeUseCase(mockRepo);
    getActiveUseCase = GetActiveTheftModeUseCase(mockRepo);
    deactivateUseCase = DeactivateTheftModeUseCase(mockRepo);
  });

  group('TheftModeConfigDto & Entity Serialization', () {
    test('fromJson and toEntity map all fields correctly', () {
      final json = {
        'id': 'theft-1',
        'deviceId': 'dev-1',
        'message': 'Este teléfono está perdido',
        'contactPhone': '+573001234567',
        'locationIntervalSeconds': 60,
        'alarm': true,
        'lock': false,
        'activatedAt': '2026-10-07T12:00:00Z',
        'deactivatedAt': null,
      };

      final dto = TheftModeConfigDto.fromJson(json);
      final entity = dto.toEntity();

      expect(entity.id, 'theft-1');
      expect(entity.deviceId, 'dev-1');
      expect(entity.message, 'Este teléfono está perdido');
      expect(entity.contactPhone, '+573001234567');
      expect(entity.locationIntervalSeconds, 60);
      expect(entity.alarm, isTrue);
      expect(entity.lock, isFalse);
      expect(entity.isActive, isTrue);
    });
  });

  group('TheftMode UseCases', () {
    test('ActivateTheftModeUseCase forwards parameters to repository', () async {
      when(() => mockRepo.activateTheftMode(
            deviceId: 'dev-1',
            message: 'Perdido. Contactar.',
            contactPhone: '+525512345678',
            locationIntervalSeconds: 60,
            alarm: true,
            lock: true,
          )).thenAnswer((_) async => activeConfig);

      final result = await activateUseCase(
        deviceId: 'dev-1',
        message: 'Perdido. Contactar.',
        contactPhone: '+525512345678',
        locationIntervalSeconds: 60,
        alarm: true,
        lock: true,
      );

      expect(result.id, 'theft-1');
      expect(result.isActive, isTrue);
      verify(() => mockRepo.activateTheftMode(
            deviceId: 'dev-1',
            message: 'Perdido. Contactar.',
            contactPhone: '+525512345678',
            locationIntervalSeconds: 60,
            alarm: true,
            lock: true,
          )).called(1);
    });

    test('GetActiveTheftModeUseCase returns active config or null', () async {
      when(() => mockRepo.getActiveTheftMode('dev-1')).thenAnswer((_) async => activeConfig);

      final result = await getActiveUseCase('dev-1');

      expect(result, isNotNull);
      expect(result!.id, 'theft-1');
      verify(() => mockRepo.getActiveTheftMode('dev-1')).called(1);
    });

    test('DeactivateTheftModeUseCase calls repository with credentials', () async {
      when(() => mockRepo.deactivateTheftMode(
            deviceId: 'dev-1',
            password: 'secretPassword123',
            force: false,
          )).thenAnswer((_) async {});

      await deactivateUseCase(
        deviceId: 'dev-1',
        password: 'secretPassword123',
        force: false,
      );

      verify(() => mockRepo.deactivateTheftMode(
            deviceId: 'dev-1',
            password: 'secretPassword123',
            force: false,
          )).called(1);
    });
  });
}
