import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/server_status/data/models/server_status_dto.dart';

void main() {


  test('ServerStatusDto toJson and fromJson work correctly', () {
    const dto = ServerStatusDto(
      status: 'ok',
      service: 'guardian-api',
      version: '0.0.1',
      time: '2026-10-06T00:19:58.366Z',
      database: 'up',
    );

    final json = dto.toJson();
    final recreated = ServerStatusDto.fromJson(json);

    expect(recreated.status, dto.status);
    expect(recreated.service, dto.service);
    expect(recreated.version, dto.version);
    expect(recreated.time, dto.time);
    expect(recreated.database, dto.database);
    expect(recreated.toEntity().isDatabaseUp, isTrue);
  });
}
