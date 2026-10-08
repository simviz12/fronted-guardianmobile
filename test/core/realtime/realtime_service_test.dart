import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/core/realtime/realtime_events.dart';
import 'package:guardian_mobile/core/realtime/realtime_service.dart';
import 'package:guardian_mobile/core/network/token_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockTokenStorage extends Mock implements TokenStorage {}
class MockRealtimeSocket extends Mock implements RealtimeSocket {}

void main() {
  late MockTokenStorage mockTokenStorage;
  late MockRealtimeSocket mockSocket;

  setUp(() {
    mockTokenStorage = MockTokenStorage();
    mockSocket = MockRealtimeSocket();
  });

  group('RealtimeEvent Deserialization', () {
    test('DeviceStatusEvent deserializes correctly', () {
      final json = {
        'deviceId': 'dev-123',
        'isOnline': true,
        'batteryLevel': 85,
        'isCharging': true,
        'networkType': 'wifi',
        'lastSeenAt': '2026-10-07T12:00:00Z',
      };

      final event = DeviceStatusEvent.fromJson(json);

      expect(event.deviceId, 'dev-123');
      expect(event.isOnline, isTrue);
      expect(event.batteryLevel, 85);
      expect(event.isCharging, isTrue);
      expect(event.networkType, 'wifi');
      expect(event.lastSeenAt, DateTime.parse('2026-10-07T12:00:00Z'));
    });

    test('DeviceLinkedEvent deserializes correctly', () {
      final json = {
        'deviceId': 'dev-123',
        'ownerId': 'owner-456',
      };

      final event = DeviceLinkedEvent.fromJson(json);

      expect(event.deviceId, 'dev-123');
      expect(event.ownerId, 'owner-456');
    });

    test('DeviceUnlinkedEvent deserializes correctly', () {
      final json = {
        'deviceId': 'dev-123',
        'ownerId': 'owner-456',
      };

      final event = DeviceUnlinkedEvent.fromJson(json);

      expect(event.deviceId, 'dev-123');
      expect(event.ownerId, 'owner-456');
    });

    test('CommandUpdatedEvent deserializes correctly', () {
      final json = {
        'commandId': 'cmd-789',
        'deviceId': 'dev-123',
        'type': 'RING',
        'status': 'EXECUTED',
        'failureReason': null,
        'updatedAt': '2026-10-07T12:05:00Z',
      };

      final event = CommandUpdatedEvent.fromJson(json);

      expect(event.commandId, 'cmd-789');
      expect(event.deviceId, 'dev-123');
      expect(event.type, 'RING');
      expect(event.status, 'EXECUTED');
      expect(event.failureReason, isNull);
    });

    test('LocationUpdatedEvent deserializes correctly', () {
      final json = {
        'deviceId': 'dev-123',
        'location': {
          'id': 'loc-1',
          'deviceId': 'dev-123',
          'latitude': 4.6097,
          'longitude': -74.0817,
          'accuracyMeters': 12.5,
          'speedMps': 1.2,
          'recordedAt': '2026-10-07T12:06:00Z',
          'receivedAt': '2026-10-07T12:06:01Z',
          'source': 'LOCATE_COMMAND',
        },
      };

      final event = LocationUpdatedEvent.fromJson(json);

      expect(event.deviceId, 'dev-123');
      expect(event.location.latitude, 4.6097);
      expect(event.location.longitude, -74.0817);
      expect(event.location.accuracyMeters, 12.5);
    });
  });

  group('RealtimeService Reconnection & Lifecycle', () {
    test('connect() does not connect if token is missing', () async {
      when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async => null);

      final service = RealtimeService(
        tokenStorage: mockTokenStorage,
        mockSocket: mockSocket,
      );

      await service.connect();

      expect(service.currentState, RealtimeConnectionState.disconnected);
      verifyNever(() => mockSocket.connect());
    });

    test('connect() connects mockSocket if token is available', () async {
      when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async => 'fake-jwt-token');
      when(() => mockSocket.connected).thenReturn(false);
      when(() => mockSocket.connect()).thenAnswer((_) {});

      final service = RealtimeService(
        tokenStorage: mockTokenStorage,
        mockSocket: mockSocket,
      );

      await service.connect();

      verify(() => mockSocket.connect()).called(1);
    });

    test('disconnect() disconnects socket and updates state', () {
      when(() => mockSocket.disconnect()).thenAnswer((_) {});

      final service = RealtimeService(
        tokenStorage: mockTokenStorage,
        mockSocket: mockSocket,
      );

      service.disconnect();

      expect(service.currentState, RealtimeConnectionState.disconnected);
      verify(() => mockSocket.disconnect()).called(1);
    });
  });
}
