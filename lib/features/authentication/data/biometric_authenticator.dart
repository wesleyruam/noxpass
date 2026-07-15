import 'package:local_auth/local_auth.dart';

/// Fina camada sobre o `local_auth` (BiometricPrompt / Face ID / Touch ID).
class BiometricAuthenticator {
  BiometricAuthenticator([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// O dispositivo tem hardware biométrico utilizável.
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() &&
          await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Solicita a autenticação biométrica. Retorna `true` se confirmada.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
