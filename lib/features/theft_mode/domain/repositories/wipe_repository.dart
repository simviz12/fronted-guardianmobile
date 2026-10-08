abstract class WipeRepository {
  Future<void> wipeDevice({
    required String deviceId,
    required String password,
    String confirmationText = 'BORRAR',
  });
}
