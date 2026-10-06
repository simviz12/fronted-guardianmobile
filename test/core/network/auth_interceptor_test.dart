import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/core/network/auth_interceptor.dart';
import 'package:guardian_mobile/core/network/token_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockTokenStorage mockTokenStorage;

  setUp(() {
    mockTokenStorage = MockTokenStorage();
  });

  test('AuthInterceptor adds Authorization header on private request', () async {
    when(() => mockTokenStorage.getAccessToken())
        .thenAnswer((_) async => 'fake-jwt-token');

    final interceptor = AuthInterceptor(
      tokenStorage: mockTokenStorage,
      dio: Dio(),
    );

    final options = RequestOptions(path: '/auth/me');
    final handler = RequestInterceptorHandler();

    await interceptor.onRequest(options, handler);

    expect(options.headers['Authorization'], 'Bearer fake-jwt-token');
  });

  test('AuthInterceptor does NOT add Authorization header on login request', () async {
    final interceptor = AuthInterceptor(
      tokenStorage: mockTokenStorage,
      dio: Dio(),
    );

    final options = RequestOptions(path: '/auth/login');
    final handler = RequestInterceptorHandler();

    await interceptor.onRequest(options, handler);

    expect(options.headers.containsKey('Authorization'), isFalse);
    verifyNever(() => mockTokenStorage.getAccessToken());
  });
}
