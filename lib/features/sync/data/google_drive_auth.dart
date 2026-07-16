import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

/// Autenticação Google para acesso à pasta privada do app no Drive.
///
/// Usa **apenas** o escopo `drive.appdata`: uma pasta oculta e exclusiva do
/// NoxPass dentro do Drive DO USUÁRIO. Nenhum outro arquivo do Drive dele fica
/// visível para o app. Nada de texto claro trafega — só o backup já cifrado.
class GoogleDriveAuth {
  GoogleDriveAuth();

  static const List<String> scopes = <String>[drive.DriveApi.driveAppdataScope];

  /// ID do cliente OAuth do tipo **Aplicativo da Web** (não é segredo). Exigido
  /// pelo google_sign_in v7 no Android (Credential Manager). Deve pertencer ao
  /// mesmo projeto do Google Cloud que o cliente Android.
  static const String _serverClientId =
      '417932923212-9ctjr7d5ghmv62igovpbfdt3iovfvnb7.apps.googleusercontent.com';

  bool _initialized = false;
  GoogleSignInAccount? _account;

  String? get email => _account?.email;
  bool get isSignedIn => _account != null;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    // O login em si é resolvido pelo par pacote+SHA-1 (cliente Android), mas a
    // v7 exige o serverClientId (cliente Web) para emitir o token de ID.
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  /// Tenta reconectar sem interação (sessão anterior). Retorna a conta ou null.
  Future<GoogleSignInAccount?> restore() async {
    await _ensureInit();
    final future = GoogleSignIn.instance.attemptLightweightAuthentication();
    _account = future == null ? null : await future;
    return _account;
  }

  /// Login interativo. Lança [GoogleSignInException] se cancelado ou em erro.
  Future<GoogleSignInAccount> signIn() async {
    await _ensureInit();
    _account = await GoogleSignIn.instance.authenticate(scopeHint: scopes);
    return _account!;
  }

  Future<void> signOut() async {
    await _ensureInit();
    await GoogleSignIn.instance.signOut();
    _account = null;
  }

  /// Cliente Drive autorizado. Autentica e pede consentimento do escopo se
  /// necessário quando [interactive] for true; caso contrário só reaproveita
  /// uma autorização já concedida (retorna erro se não houver).
  Future<drive.DriveApi> driveApi({bool interactive = true}) async {
    await _ensureInit();
    final account = _account ?? (interactive ? await signIn() : null);
    if (account == null) {
      throw StateError('Conecte-se ao Google Drive primeiro.');
    }
    final client = account.authorizationClient;
    final authz = interactive
        ? await client.authorizeScopes(scopes)
        : await client.authorizationForScopes(scopes);
    if (authz == null) {
      throw StateError('Autorização do Google Drive não concedida.');
    }
    return drive.DriveApi(authz.authClient(scopes: scopes));
  }
}
