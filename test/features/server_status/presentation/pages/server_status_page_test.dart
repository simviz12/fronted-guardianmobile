import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/core/error/failures.dart';
import 'package:guardian_mobile/features/server_status/domain/entities/server_status.dart';
import 'package:guardian_mobile/features/server_status/domain/repositories/server_status_repository.dart';
import 'package:guardian_mobile/features/server_status/domain/usecases/check_server_status.dart';
import 'package:guardian_mobile/features/server_status/presentation/pages/server_status_page.dart';
import 'package:guardian_mobile/features/server_status/presentation/providers/server_status_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockServerStatusRepository extends Mock implements ServerStatusRepository {}

void main() {
  late MockServerStatusRepository mockRepository;

  setUp(() {
    mockRepository = MockServerStatusRepository();
  });

  Widget buildTestableWidget(CheckServerStatus useCase) {
    return ProviderScope(
      overrides: [
        checkServerStatusUseCaseProvider.overrideWithValue(useCase),
      ],
      child: const MaterialApp(
        home: ServerStatusPage(),
      ),
    );
  }

  testWidgets('shows loading indicator while checking status', (tester) async {
    final completer = Completer<ServerStatus>();
    final useCase = CheckServerStatus(mockRepository);
    when(() => mockRepository.checkStatus()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildTestableWidget(useCase));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.text('Comprobando conexión con el servidor...'),
      findsOneWidget,
    );

    completer.complete(
      ServerStatus(
        status: 'ok',
        service: 'guardian-api',
        version: '0.0.1',
        time: DateTime.now(),
        database: 'up',
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('shows success card when server status returns up', (tester) async {
    final useCase = CheckServerStatus(mockRepository);
    final status = ServerStatus(
      status: 'ok',
      service: 'guardian-api',
      version: '0.0.1',
      time: DateTime.parse('2026-10-06T00:19:58.366Z'),
      database: 'up',
    );

    when(() => mockRepository.checkStatus()).thenAnswer((_) async => status);

    await tester.pumpWidget(buildTestableWidget(useCase));
    await tester.pumpAndSettle();

    expect(find.text('Servidor conectado'), findsOneWidget);
    expect(find.text('v0.0.1'), findsOneWidget);
    expect(find.text('UP'), findsOneWidget);
    expect(find.text('Sistema Operativo'), findsOneWidget);
  });

  testWidgets('shows error state with retry button when failure occurs', (tester) async {
    final useCase = CheckServerStatus(mockRepository);

    when(() => mockRepository.checkStatus()).thenThrow(
      const NetworkFailure(message: 'Error de red simulado'),
    );

    await tester.pumpWidget(buildTestableWidget(useCase));
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.text('Error al conectar'), findsOneWidget);
    expect(find.text('Error de red simulado'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
