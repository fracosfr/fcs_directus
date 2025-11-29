// ignore_for_file: non_constant_identifier_names, avoid_print, unused_local_variable

import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation du callback onAuthError
///
/// Ce callback est appelé dans les situations suivantes :
/// - Échec de l'auto-refresh du token (refresh token expiré/invalide)
/// - Erreurs d'authentification DirectusAuthException
///
/// Il permet à l'application de réagir aux erreurs d'authentification,
/// par exemple en redirigeant vers l'écran de connexion.
void main() async {
  // Simuler un système de stockage
  final storage = InMemoryStorage();

  // Exemple 1 : Configuration avec callback onAuthError
  print('=== Exemple 1: Callback onAuthError ===\n');

  final client = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://directus.example.com',
      enableLogging: true,

      // Callback pour sauvegarder les tokens après un refresh réussi
      onTokenRefreshed: (accessToken, refreshToken) async {
        print('✅ Tokens rafraîchis avec succès');
        await storage.saveTokens(accessToken, refreshToken);
      },

      // Callback pour gérer les erreurs d'authentification
      onAuthError: (exception) async {
        print('❌ Erreur d\'authentification détectée:');
        print('   Code: ${exception.errorCode}');
        print('   Message: ${exception.message}');
        print('   Status: ${exception.statusCode}');

        // Gérer différents types d'erreurs
        switch (exception.errorCode) {
          case 'TOKEN_REFRESH_FAILED':
          case 'INVALID_TOKEN':
          case 'TOKEN_EXPIRED':
            print('   Action: Redirection vers login');
            await storage.clearTokens();
            // await navigateToLogin(); // Dans une vraie app Flutter
            break;

          case 'INVALID_CREDENTIALS':
            print('   Action: Afficher message d\'erreur utilisateur');
            // await showErrorDialog('Identifiants incorrects');
            break;

          case 'USER_SUSPENDED':
            print('   Action: Compte suspendu');
            // await showErrorDialog('Votre compte a été suspendu');
            break;

          default:
            print('   Action: Erreur générique');
        }
      },
    ),
  );

  print('\n=== Exemple 2: Scénario d\'échec de refresh ===\n');

  // Simuler un scénario où le refresh token expire
  try {
    // Login initial
    print('1. Login initial...');
    // await client.auth.login(email: 'user@example.com', password: 'password');

    // Simuler des tokens expirés
    print('2. Simulation: les tokens expirent...');

    // La prochaine requête va tenter un auto-refresh
    // Si le refresh token est aussi expiré, onAuthError sera appelé
    print('3. Requête avec token expiré...');
    // await client.items('articles').readMany();

    // ❌ Le callback onAuthError sera automatiquement appelé
    // avec une DirectusAuthException(errorCode: 'TOKEN_REFRESH_FAILED')
  } catch (e) {
    print('Exception capturée: $e');
    // L'erreur a déjà été gérée par le callback onAuthError
    // Mais vous pouvez aussi la gérer ici si nécessaire
  }

  print('\n=== Exemple 3: Login avec mauvais identifiants ===\n');

  try {
    print('Tentative de login avec mauvais identifiants...');
    await client.auth.login(
      email: 'wrong@example.com',
      password: 'wrongpassword',
    );
  } on DirectusAuthException catch (e) {
    // Le callback onAuthError a déjà été appelé
    print('\nException capturée après callback:');
    print('  Code: ${e.errorCode}');
    print('  Message: ${e.message}');

    // Vérification spécifique
    if (e.isInvalidCredentials) {
      print('  ⚠️  Identifiants incorrects confirmés');
    }
  }

  print('\n=== Exemple 4: Gestion combinée des callbacks ===\n');

  final clientWithBothCallbacks = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://directus.example.com',

      // Succès: sauvegarder les nouveaux tokens
      onTokenRefreshed: (accessToken, refreshToken) async {
        print('✅ Tokens sauvegardés');
        await storage.saveTokens(accessToken, refreshToken);
      },

      // Échec: nettoyer et rediriger
      onAuthError: (exception) async {
        print('❌ Échec authentification: ${exception.errorCode}');
        await storage.clearTokens();
        // await navigateToLogin();
      },
    ),
  );

  print('Client configuré avec les deux callbacks');
  print('  - onTokenRefreshed: gère les refresh réussis');
  print('  - onAuthError: gère les échecs d\'authentification');

  print('\n=== Exemple 5: Pattern de gestion d\'état ===\n');

  // État de l'authentification
  var isAuthenticated = false;

  final stateClient = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://directus.example.com',

      onTokenRefreshed: (accessToken, refreshToken) async {
        print('✅ Refresh réussi, état reste: authenticated');
        isAuthenticated = true;
        await storage.saveTokens(accessToken, refreshToken);
      },

      onAuthError: (exception) async {
        print('❌ Erreur auth, changement état: unauthenticated');
        isAuthenticated = false;
        await storage.clearTokens();

        // Émettre un événement pour l'UI
        // authStateStream.add(AuthState.unauthenticated);
      },
    ),
  );

  print(
    'État initial: ${isAuthenticated ? "authenticated" : "unauthenticated"}',
  );
  print('Le callback onAuthError mettra à jour l\'état automatiquement');
}

/// Classe utilitaire pour simuler un stockage
class InMemoryStorage {
  String? _accessToken;
  String? _refreshToken;

  Future<void> saveTokens(String accessToken, String? refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    print('   💾 Tokens sauvegardés en mémoire');
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    print('   🗑️  Tokens supprimés');
  }

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
}
