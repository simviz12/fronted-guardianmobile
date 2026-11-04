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
  void disconnect() {
    _socket.disconnect();
    _socket.dispose();
  }

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

  /// Obtains a fresh access token (e.g. by performing an authenticated
  /// request that lets the HTTP interceptor rotate the session).
  final Future<String?> Function()? _refreshAccessToken;

  /// Socket injected by tests; reused on every connect().
  final RealtimeSocket? _injectedSocket;

  RealtimeSocket? _socket;
  final _eventController = StreamController<RealtimeEvent>.broadcast();
  final _stateController = StreamController<RealtimeConnectionState>.broadcast();

  RealtimeConnectionState _currentState = RealtimeConnectionState.disconnected;
  RealtimeConnectionState get currentState => _currentState;

  Stream<RealtimeEvent> get events => _eventController.stream;
  Stream<RealtimeConnectionState> get connectionState => _stateController.stream;

  bool _wantConnected = false;
  bool _disposed = false;
  int _authRetryCount = 0;
  Timer? _authRetryTimer;
  static const int _maxAuthRetries = 5;

  RealtimeService({
    required TokenStorage tokenStorage,
    String Function()? getBaseUrl,
    RealtimeSocket? mockSocket,
    Future<String?> Function()? refreshAccessToken,
  })  : _tokenStorage = tokenStorage,
        _getBaseUrl = getBaseUrl ?? (() => ApiConfig.baseUrl),
        _injectedSocket = mockSocket,
        _refreshAccessToken = refreshAccessToken,
        _socket = mockSocket;

  void _setState(RealtimeConnectionState state) {
    if (_disposed) return;
    _currentState = state;
    _stateController.add(state);
  }

  Future<void> connect({String? explicitToken}) async {
    if (_disposed) return;
    _wantConnected = true;

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

    // Tear down any previous or stale (non-injected) socket.
    if (_socket != null && !identical(_socket, _injectedSocket)) {
      _socket?.disconnect();
      _socket = null;
    }

    _setState(RealtimeConnectionState.connecting);

    if (_injectedSocket != null) {
      _socket = _injectedSocket;
    } else {
      final rawBaseUrl = _getBaseUrl();
      final socketUrl = rawBaseUrl.endsWith('/')
          ? '${rawBaseUrl}realtime'
          : '$rawBaseUrl/realtime';

      debugPrint('[Realtime] Connecting socket to: $socketUrl (transport: websocket)');

      final socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .disableAutoConnect()
            .enableForceNew()
            .enableReconnection()
            .setReconnectionDelay(1500)
            .setReconnectionDelayMax(10000)
            .setReconnectionAttempts(9999)
            .setTimeout(60000)
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
      _authRetryCount = 0;
      _setState(RealtimeConnectionState.connected);
    });

    s.on('disconnect', (reason) {
      debugPrint('[Realtime] Socket disconnected. Reason: $reason');
      _setState(RealtimeConnectionState.disconnected);

      // The server closes the socket itself ("io server disconnect") when the
      // access token is expired/invalid. Socket.IO does NOT auto-reconnect in
      // that case, so refresh the session and reconnect with a new token.
      if (reason == 'io server disconnect' && _wantConnected) {
        _scheduleReauthenticate();
      }
    });

    s.on('connect_error', (error) {
      debugPrint('[Realtime] Socket connection error: $error');
      _setState(RealtimeConnectionState.reconnecting);
    });

    s.on('reconnect_attempt', (attempt) {
      debugPrint('[Realtime] Reconnecting attempt: $attempt');
      _setState(RealtimeConnectionState.reconnecting);
    });

    void handle(String name, RealtimeEvent Function(Map<String, dynamic>) parse) {
      s.on(name, (data) {
        if (kDebugMode) debugPrint('[Realtime] Received $name: $data');
        if (data is Map) {
          try {
            _eventController.add(parse(Map<String, dynamic>.from(data)));
          } catch (e) {
            debugPrint('[Realtime] Error parsing $name: $e');
          }
        }
      });
    }

    handle('device.status', DeviceStatusEvent.fromJson);
    handle('device.linked', DeviceLinkedEvent.fromJson);
    handle('device.unlinked', DeviceUnlinkedEvent.fromJson);
    handle('command.updated', CommandUpdatedEvent.fromJson);
    handle('location.updated', LocationUpdatedEvent.fromJson);
  }

  void _scheduleReauthenticate() {
    if (_authRetryCount >= _maxAuthRetries || _disposed) {
      debugPrint('[Realtime] Giving up re-authentication after $_authRetryCount attempts');
      return;
    }
    _authRetryTimer?.cancel();
    final delay = Duration(seconds: 2 * (_authRetryCount + 1));
    _authRetryCount++;
    _authRetryTimer = Timer(delay, () async {
      if (!_wantConnected || _disposed) return;
      String? freshToken;
      try {
        freshToken = await _refreshAccessToken?.call();
      } catch (e) {
        debugPrint('[Realtime] Token refresh before reconnect failed: $e');
      }
      _releaseSocket();
      await connect(explicitToken: freshToken);
    });
  }

  void _releaseSocket() {
    if (_socket != null && !identical(_socket, _injectedSocket)) {
      _socket?.disconnect();
    }
    _socket = _injectedSocket;
  }

  void updateToken(String newToken) {
    debugPrint('[Realtime] Re-authenticating socket with new token');
    _releaseSocket();
    connect(explicitToken: newToken);
  }

  /// Reconnects if the socket dropped while the app was in background.
  void ensureConnected() {
    if (!_wantConnected || _disposed) return;
    if (_socket == null || !_socket!.connected) {
      _authRetryCount = 0;
      connect();
    }
  }

  void disconnect() {
    debugPrint('[Realtime] Disconnecting socket');
    _wantConnected = false;
    _authRetryTimer?.cancel();
    _socket?.disconnect();
    _socket = null;
    _setState(RealtimeConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _disposed = true;
    _eventController.close();
    _stateController.close();
  }
}

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final service = RealtimeService(
    tokenStorage: storage,
    refreshAccessToken: () async {
      // Any authenticated call lets AuthInterceptor rotate an expired token.
      try {
        await ref.read(authenticatedDioClientProvider).dio.get<dynamic>('/auth/me');
      } catch (_) {}
      return storage.getAccessToken();
    },
  );

  // Auto-connect if already authenticated
  if (ref.read(authNotifierProvider).status == AuthStatus.authenticated) {
    service.connect();
  }

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
