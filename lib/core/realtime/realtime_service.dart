import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';
import '../network/token_storage.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'realtime_events.dart';

enum RealtimeConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

abstract class RealtimeSocket {
  void connect();
  void disconnect();
  void on(String event, Function(dynamic) handler);
  void off(String event);
  bool get connected;
}

class IORealtimeSocketWrapper implements RealtimeSocket {
  final io.Socket _socket;

  IORealtimeSocketWrapper(this._socket);

  @override
  void connect() => _socket.connect();

  @override
  void disconnect() => _socket.disconnect();

  @override
  void on(String event, Function(dynamic) handler) => _socket.on(event, handler);

  @override
  void off(String event) => _socket.off(event);

  @override
  bool get connected => _socket.connected;
}

class RealtimeService {
  final TokenStorage _tokenStorage;
  final String Function() _getBaseUrl;

  RealtimeSocket? _socket;
  final _eventController = StreamController<RealtimeEvent>.broadcast();
  final _stateController = StreamController<RealtimeConnectionState>.broadcast();

  RealtimeConnectionState _currentState = RealtimeConnectionState.disconnected;
  RealtimeConnectionState get currentState => _currentState;

  Stream<RealtimeEvent> get events => _eventController.stream;
  Stream<RealtimeConnectionState> get connectionState => _stateController.stream;

  RealtimeService({
    required TokenStorage tokenStorage,
    String Function()? getBaseUrl,
    RealtimeSocket? mockSocket,
  })  : _tokenStorage = tokenStorage,
        _getBaseUrl = getBaseUrl ?? (() => ApiConfig.baseUrl),
        _socket = mockSocket;

  void _setState(RealtimeConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  Future<void> connect({String? explicitToken}) async {
    final token = explicitToken ?? await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('[Realtime] Cannot connect: No token available');
      _setState(RealtimeConnectionState.disconnected);
      return;
    }

    if (_socket != null && _socket!.connected) {
      debugPrint('[Realtime] Socket already connected');
      return;
    }

    _setState(RealtimeConnectionState.connecting);

    final rawBaseUrl = _getBaseUrl();
    final socketUrl = rawBaseUrl.endsWith('/')
        ? '${rawBaseUrl}realtime'
        : '$rawBaseUrl/realtime';

    debugPrint('[Realtime] Connecting socket to: $socketUrl (transport: websocket)');

    if (_socket == null) {
      final socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1500)
            .setReconnectionDelayMax(10000)
            .setReconnectionAttempts(9999)
            .build(),
      );
      _socket = IORealtimeSocketWrapper(socket);
    }

    _setupListeners();
    _socket?.connect();
  }

  void _setupListeners() {
    final s = _socket;
    if (s == null) return;

    s.on('connect', (_) {
      debugPrint('[Realtime] Socket connected successfully');
      _setState(RealtimeConnectionState.connected);
    });

    s.on('disconnect', (reason) {
      debugPrint('[Realtime] Socket disconnected. Reason: $reason');
      _setState(RealtimeConnectionState.disconnected);
    });

    s.on('connect_error', (error) {
      debugPrint('[Realtime] Socket connection error: $error');
      _setState(RealtimeConnectionState.reconnecting);
    });

    s.on('reconnect_attempt', (attempt) {
      debugPrint('[Realtime] Reconnecting attempt: $attempt');
      _setState(RealtimeConnectionState.reconnecting);
    });

    // 1. device.status
    s.on('device.status', (data) {
      debugPrint('[Realtime] Received device.status: $data');
      if (data is Map<String, dynamic>) {
        try {
          _eventController.add(DeviceStatusEvent.fromJson(data));
        } catch (e) {
          debugPrint('[Realtime] Error parsing device.status: $e');
        }
      }
    });

    // 2. device.linked
    s.on('device.linked', (data) {
      debugPrint('[Realtime] Received device.linked: $data');
      if (data is Map<String, dynamic>) {
        try {
          _eventController.add(DeviceLinkedEvent.fromJson(data));
        } catch (e) {
          debugPrint('[Realtime] Error parsing device.linked: $e');
        }
      }
    });

    // 3. device.unlinked
    s.on('device.unlinked', (data) {
      debugPrint('[Realtime] Received device.unlinked: $data');
      if (data is Map<String, dynamic>) {
        try {
          _eventController.add(DeviceUnlinkedEvent.fromJson(data));
        } catch (e) {
          debugPrint('[Realtime] Error parsing device.unlinked: $e');
        }
      }
    });

    // 4. command.updated
    s.on('command.updated', (data) {
      debugPrint('[Realtime] Received command.updated: $data');
      if (data is Map<String, dynamic>) {
        try {
          _eventController.add(CommandUpdatedEvent.fromJson(data));
        } catch (e) {
          debugPrint('[Realtime] Error parsing command.updated: $e');
        }
      }
    });

    // 5. location.updated
    s.on('location.updated', (data) {
      debugPrint('[Realtime] Received location.updated: $data');
      if (data is Map<String, dynamic>) {
        try {
          _eventController.add(LocationUpdatedEvent.fromJson(data));
        } catch (e) {
          debugPrint('[Realtime] Error parsing location.updated: $e');
        }
      }
    });
  }

  void updateToken(String newToken) {
    debugPrint('[Realtime] Re-authenticating socket with new token');
    disconnect();
    connect(explicitToken: newToken);
  }

  void disconnect() {
    debugPrint('[Realtime] Disconnecting socket');
    _socket?.disconnect();
    _setState(RealtimeConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _stateController.close();
  }
}

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final service = RealtimeService(tokenStorage: storage);

  // Auto-connect / disconnect based on auth state
  ref.listen<AuthState>(authNotifierProvider, (prev, next) {
    if (next.status == AuthStatus.authenticated) {
      service.connect();
    } else if (next.status == AuthStatus.unauthenticated) {
      service.disconnect();
    }
  });

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

final realtimeEventsStreamProvider = StreamProvider<RealtimeEvent>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  return service.events;
});

final realtimeConnectionStateProvider = StreamProvider<RealtimeConnectionState>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  return service.connectionState;
});
