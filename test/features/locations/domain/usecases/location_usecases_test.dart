import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/locations/domain/entities/device_location.dart';
import 'package:guardian_mobile/features/locations/domain/repositories/location_repository.dart';
import 'package:guardian_mobile/features/locations/domain/usecases/location_usecases.dart';
import 'package:guardian_mobile/features/locations/presentation/providers/device_map_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late MockLocationRepository mockRepository;
  late GetLocationsUseCase getLocationsUseCase;
  late GetLatestLocationUseCase getLatestLocationUseCase;

  final sampleLocation = DeviceLocation(
    id: 'loc-1',
    deviceId: 'dev-1',
    latitude: 4.60971,
    longitude: -74.08175,
    accuracyMeters: 5.2,
    speedMps: 1.2,
    recordedAt: DateTime.now(),
    source: LocationSource.locateCommand,
  );

  setUp(() {
    mockRepository = MockLocationRepository();
    getLocationsUseCase = GetLocationsUseCase(mockRepository);
    getLatestLocationUseCase = GetLatestLocationUseCase(mockRepository);
  });

  group('Location Use Cases', () {
    test('GetLatestLocationUseCase calls repository.getLatestLocation', () async {
      when(() => mockRepository.getLatestLocation(deviceId: 'dev-1'))
          .thenAnswer((_) async => sampleLocation);

      final result = await getLatestLocationUseCase(deviceId: 'dev-1');

      expect(result.id, 'loc-1');
      expect(result.latitude, 4.60971);
      verify(() => mockRepository.getLatestLocation(deviceId: 'dev-1')).called(1);
    });

    test('GetLocationsUseCase calls repository.getLocations with filters', () async {
      final from = DateTime.now().subtract(const Duration(hours: 2));
      final to = DateTime.now();

      when(() => mockRepository.getLocations(
            deviceId: 'dev-1',
            from: from,
            to: to,
            limit: 50,
          )).thenAnswer((_) async => [sampleLocation]);

      final result = await getLocationsUseCase(
        deviceId: 'dev-1',
        from: from,
        to: to,
        limit: 50,
      );

      expect(result.length, 1);
      expect(result.first.deviceId, 'dev-1');
      verify(() => mockRepository.getLocations(
            deviceId: 'dev-1',
            from: from,
            to: to,
            limit: 50,
          )).called(1);
    });
  });

  group('LocationRangeFilter tests', () {
    test('calculateBounds generates correct chronological boundaries', () {
      final (fromToday, toToday) = LocationRangeFilter.today.calculateBounds();
      expect(toToday.isAfter(fromToday), isTrue);

      final (fromYesterday, toYesterday) = LocationRangeFilter.yesterday.calculateBounds();
      expect(toYesterday.isAfter(fromYesterday), isTrue);

      final (from7Days, to7Days) = LocationRangeFilter.last7Days.calculateBounds();
      expect(to7Days.isAfter(from7Days), isTrue);
    });
  });

  group('DeviceLocation and LastLocationSummary serialization', () {
    test('LastLocationSummary roundtrip JSON', () {
      final now = DateTime.now();
      final summary = LastLocationSummary(
        latitude: 4.60971,
        longitude: -74.08175,
        accuracyMeters: 4.5,
        recordedAt: now,
      );

      final json = summary.toJson();
      final parsed = LastLocationSummary.fromJson(json);

      expect(parsed.latitude, 4.60971);
      expect(parsed.longitude, -74.08175);
      expect(parsed.accuracyMeters, 4.5);
    });
  });
}
