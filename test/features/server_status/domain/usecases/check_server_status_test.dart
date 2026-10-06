import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/server_status/data/datasources/server_status_remote_data_source.dart';
import 'package:guardian_mobile/features/server_status/data/models/server_status_dto.dart';
import 'package:guardian_mobile/features/server_status/data/repositories/server_status_repository_impl.dart';
import 'package:guardian_mobile/features/server_status/domain/usecases/check_server_status.dart';
import 'package:mocktail/mocktail.dart';

class MockServerStatusRemoteDataSource extends Mock
    implements ServerStatusRemoteDataSource {}

void main() {
  late MockServerStatusRemoteDataSource mockDataSource;
  late ServerStatusRepositoryImpl repository;
  late CheckServerStatus useCase;

  setUp(() {
    mockDataSource = MockServerStatusRemoteDataSource();
    repository = ServerStatusRepositoryImpl(remoteDataSource: mockDataSource);
    useCase = CheckServerStatus(repository);
  });

  const testDto = ServerStatusDto(
    status: 'ok',
    service: 'guardian-api',
    version: '0.0.1',
    time: '2026-10-06T00:19:58.366Z',
    database: 'up',
  );

  test('CheckServerStatus returns ServerStatus entity on success', () async {
    when(() => mockDataSource.getHealth()).thenAnswer((_) async => testDto);

    final result = await useCase();

    expect(result.status, 'ok');
    expect(result.service, 'guardian-api');
    expect(result.version, '0.0.1');
    expect(result.database, 'up');
    expect(result.isDatabaseUp, isTrue);
    verify(() => mockDataSource.getHealth()).called(1);
  });
}
