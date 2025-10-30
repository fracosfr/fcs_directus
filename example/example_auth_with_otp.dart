import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'authentification avec gestion OTP (2FA)
/// Démontre l'utilisation des helpers DirectusAuthException

void main() async {
  final client = DirectusClient(
    DirectusConfig(baseUrl: 'https://your-directus-instance.com'),
  );

  // Exemple 1 : Authentification simple avec détection OTP
  await example1SimpleOtpDetection(client);

  // Exemple 2 : Flux d'authentification complet
  await example2CompleteAuthFlow(client);

  // Exemple 3 : Gestion d'erreur avec DirectusErrorCode
  await example3ErrorHandling(client);

  client.dispose();
}

/// Exemple 1 : Détection simple de l'OTP requis
Future<void> example1SimpleOtpDetection(DirectusClient client) async {
  print('=== Exemple 1 : Détection OTP ===\n');

  try {
    // Première tentative sans OTP
    await client.auth.login(email: 'user@example.com', password: 'password');
    print('✅ Connexion réussie sans 2FA\n');
  } on DirectusAuthException catch (e) {
    // Utiliser le helper isOtpRequired
    if (e.isOtpRequired) {
      print('🔐 2FA activée, code OTP requis');
      print('→ Demander le code OTP à l\'utilisateur\n');

      // Deuxième tentative avec OTP
      try {
        await client.auth.login(
          email: 'user@example.com',
          password: 'password',
          otp: '123456',
        );
        print('✅ Connexion 2FA réussie\n');
      } on DirectusAuthException catch (e2) {
        if (e2.isOtpRequired) {
          print('❌ Code OTP invalide ou expiré\n');
        }
      }
    } else if (e.isInvalidCredentials) {
      print('❌ Email ou mot de passe incorrect\n');
    }
  }
}

/// Exemple 2 : Flux d'authentification complet avec classe dédiée
Future<void> example2CompleteAuthFlow(DirectusClient client) async {
  print('=== Exemple 2 : Flux d\'authentification complet ===\n');

  final authFlow = AuthenticationFlow(client);

  // Tentative de connexion
  final result = await authFlow.login('user@example.com', 'password');

  switch (result.status) {
    case LoginStatus.success:
      print('✅ Connexion réussie');
      print('Token: ${result.accessToken}\n');
      break;

    case LoginStatus.otpRequired:
      print('🔐 OTP requis, nouvelle tentative avec code');

      // Simuler l'entrée de l'OTP
      final otpResult = await authFlow.login(
        'user@example.com',
        'password',
        otp: '123456',
      );

      if (otpResult.status == LoginStatus.success) {
        print('✅ Connexion 2FA réussie\n');
      } else if (otpResult.status == LoginStatus.invalidOtp) {
        print('❌ ${otpResult.errorMessage}\n');
      }
      break;

    case LoginStatus.invalidCredentials:
      print('❌ ${result.errorMessage}\n');
      break;

    case LoginStatus.invalidOtp:
      print('❌ ${result.errorMessage}\n');
      break;

    case LoginStatus.error:
      print('❌ Erreur: ${result.errorMessage}\n');
      break;
  }
}

/// Exemple 3 : Gestion d'erreur avec DirectusErrorCode
Future<void> example3ErrorHandling(DirectusClient client) async {
  print('=== Exemple 3 : Gestion d\'erreur avancée ===\n');

  try {
    await client.auth.login(
      email: 'user@example.com',
      password: 'password',
      otp: '123456',
    );
  } on DirectusAuthException catch (e) {
    print('Exception d\'authentification capturée:');
    print('- Message: ${e.message}');
    print('- Code HTTP: ${e.statusCode}');
    print('- Code erreur: ${e.errorCode}');

    // Méthode 1 : Utiliser les helpers (recommandé)
    print('\n📋 Détection avec helpers:');
    if (e.isOtpRequired) {
      print('  → OTP requis ou invalide');
    }
    if (e.isInvalidCredentials) {
      print('  → Credentials invalides');
    }
    if (e.isInvalidToken) {
      print('  → Token invalide ou expiré');
    }
    if (e.isUserSuspended) {
      print('  → Utilisateur suspendu');
    }

    // Méthode 2 : Utiliser hasErrorCode avec DirectusErrorCode
    print('\n📋 Détection avec DirectusErrorCode:');
    if (e.hasErrorCode(DirectusErrorCode.invalidOtp)) {
      print('  → INVALID_OTP détecté');
    }
    if (e.hasErrorCode(DirectusErrorCode.invalidCredentials)) {
      print('  → INVALID_CREDENTIALS détecté');
    }
    if (e.hasErrorCode(DirectusErrorCode.tokenExpired)) {
      print('  → TOKEN_EXPIRED détecté');
    }
    if (e.hasErrorCode(DirectusErrorCode.userSuspended)) {
      print('  → USER_SUSPENDED détecté');
    }

    // Message personnalisé pour l'utilisateur
    print('\n💬 Message utilisateur:');
    print('  ${getAuthErrorMessage(e)}\n');
  } on DirectusRateLimitException catch (e) {
    print('⏳ Rate limit: ${e.message}\n');
  } on DirectusServerException catch (e) {
    print('🔥 Erreur serveur: ${e.message}\n');
  } on DirectusException catch (e) {
    print('❌ Erreur Directus: ${e.message}\n');
  }
}

/// Classe pour gérer le flux d'authentification
class AuthenticationFlow {
  final DirectusClient directus;

  AuthenticationFlow(this.directus);

  Future<LoginResult> login(
    String email,
    String password, {
    String? otp,
  }) async {
    try {
      final response = await directus.auth.login(
        email: email,
        password: password,
        otp: otp,
      );

      return LoginResult.success(
        accessToken: response.accessToken,
        expiresIn: response.expiresIn,
      );
    } on DirectusAuthException catch (e) {
      // OTP requis
      if (otp == null && e.isOtpRequired) {
        return LoginResult.otpRequired();
      }

      // OTP invalide
      if (otp != null && e.isOtpRequired) {
        return LoginResult.invalidOtp();
      }

      // Credentials invalides
      if (e.isInvalidCredentials) {
        return LoginResult.invalidCredentials();
      }

      // Utilisateur suspendu
      if (e.isUserSuspended) {
        return LoginResult.error('Compte suspendu');
      }

      // Autre erreur
      return LoginResult.error(e.message);
    } catch (e) {
      return LoginResult.error(e.toString());
    }
  }
}

/// Résultat d'une tentative de login
class LoginResult {
  final LoginStatus status;
  final String? accessToken;
  final int? expiresIn;
  final String? errorMessage;

  LoginResult.success({required this.accessToken, required this.expiresIn})
    : status = LoginStatus.success,
      errorMessage = null;

  LoginResult.otpRequired()
    : status = LoginStatus.otpRequired,
      accessToken = null,
      expiresIn = null,
      errorMessage = null;

  LoginResult.invalidOtp()
    : status = LoginStatus.invalidOtp,
      accessToken = null,
      expiresIn = null,
      errorMessage = 'Code OTP invalide ou expiré';

  LoginResult.invalidCredentials()
    : status = LoginStatus.invalidCredentials,
      accessToken = null,
      expiresIn = null,
      errorMessage = 'Email ou mot de passe incorrect';

  LoginResult.error(this.errorMessage)
    : status = LoginStatus.error,
      accessToken = null,
      expiresIn = null;
}

enum LoginStatus { success, otpRequired, invalidOtp, invalidCredentials, error }

/// Fonction helper pour générer des messages d'erreur personnalisés
String getAuthErrorMessage(DirectusAuthException e, {bool hasOtp = false}) {
  // Utiliser les helpers pour une détection fiable
  if (e.isOtpRequired) {
    if (hasOtp) {
      return 'Le code 2FA est invalide ou a expiré. Veuillez réessayer.';
    } else {
      return 'Authentification à deux facteurs requise.';
    }
  }

  if (e.isInvalidCredentials) {
    return 'Email ou mot de passe incorrect.';
  }

  if (e.isInvalidToken) {
    return 'Votre session a expiré. Veuillez vous reconnecter.';
  }

  if (e.isUserSuspended) {
    return 'Votre compte a été suspendu. Contactez un administrateur.';
  }

  // Fallback
  return 'Erreur de connexion: ${e.message}';
}
