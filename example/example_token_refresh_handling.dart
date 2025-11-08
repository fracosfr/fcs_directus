// ignore_for_file: avoid_print

import 'package:fcs_directus/fcs_directus.dart';

/// Exemple de gestion correcte du refresh token et des erreurs d'authentification
///
/// Cet exemple montre comment :
/// 1. Configurer le callback onTokenRefreshed pour persister les tokens
/// 2. Gérer les erreurs de refresh token
/// 3. Nettoyer les tokens en cas d'échec permanent
void main() async {
  await example1_BasicRefreshHandling();
  await example2_RefreshErrorHandling();
  await example3_PersistentStorageIntegration();
}

/// Exemple 1: Configuration de base du refresh token
Future<void> example1_BasicRefreshHandling() async {
  print('\n=== Exemple 1: Configuration de base ===\n');

  final client = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://your-directus-instance.com',

      // Le callback onTokenRefreshed est appelé automatiquement
      // quand le token est rafraîchi avec succès
      onTokenRefreshed: (accessToken, refreshToken) async {
        print('✓ Tokens rafraîchis automatiquement!');
        print('  - Access token: ${accessToken.substring(0, 20)}...');
        print('  - Refresh token: ${refreshToken?.substring(0, 20)}...');

        // IMPORTANT: Sauvegarder les nouveaux tokens dans votre stockage
        // (SharedPreferences, Hive, SecureStorage, etc.)
        // await storage.saveTokens(accessToken, refreshToken);
      },
    ),
  );

  try {
    // Se connecter
    await client.auth.login(email: 'user@example.com', password: 'password');

    print('✓ Connexion réussie');

    // Les requêtes suivantes utiliseront automatiquement le token
    // et le rafraîchiront si nécessaire
    final response = await client.items('articles').readMany();
    print('✓ Récupération de ${response.data.length} articles');

    // Si le token expire, la librairie le rafraîchit automatiquement
    // et réessaie la requête - transparent pour l'utilisateur!
  } catch (e) {
    print('✗ Erreur: $e');
  } finally {
    await client.dispose();
  }
}

/// Exemple 2: Gestion des erreurs de refresh token
Future<void> example2_RefreshErrorHandling() async {
  print('\n=== Exemple 2: Gestion des erreurs de refresh ===\n');

  final client = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://your-directus-instance.com',
      onTokenRefreshed: (accessToken, refreshToken) async {
        // Sauvegarder les tokens
        print('✓ Tokens sauvegardés');
      },
    ),
  );

  try {
    // Simuler une restauration de session avec un refresh token invalide
    client.auth.setTokens(
      accessToken: 'expired_access_token',
      refreshToken: 'invalid_refresh_token',
    );

    // Tenter une requête - le token access étant expiré,
    // la librairie tentera de le rafraîchir
    final response = await client.items('articles').readMany();
    print('✓ Récupération de ${response.data.length} articles');
  } on DirectusAuthException catch (e) {
    print('✗ Erreur d\'authentification: ${e.message}');
    print('  Code: ${e.errorCode}');

    // Si le refresh token est invalide/expiré
    if (e.errorCode == 'TOKEN_REFRESH_FAILED') {
      print('\n⚠️  Le refresh token est invalide ou expiré');
      print('   Actions recommandées:');
      print('   1. Effacer les tokens stockés');
      print('   2. Rediriger l\'utilisateur vers la page de login');

      // Nettoyer les tokens
      client.clearTokens();

      // Effacer aussi du stockage local
      // await storage.clearTokens();

      // Rediriger vers login
      // Navigator.pushReplacementNamed(context, '/login');
    }
  } catch (e) {
    print('✗ Erreur inattendue: $e');
  } finally {
    await client.dispose();
  }
}

/// Exemple 3: Intégration avec stockage persistant
Future<void> example3_PersistentStorageIntegration() async {
  print('\n=== Exemple 3: Stockage persistant ===\n');

  // Simuler un service de stockage
  final tokenStorage = TokenStorage();

  final client = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://your-directus-instance.com',
      onTokenRefreshed: (accessToken, refreshToken) async {
        // Sauvegarder les tokens dans le stockage persistant
        await tokenStorage.saveTokens(accessToken, refreshToken);
        print('✓ Tokens sauvegardés dans le stockage persistant');
      },
    ),
  );

  try {
    // Au démarrage de l'app, restaurer les tokens si disponibles
    final savedTokens = await tokenStorage.loadTokens();

    if (savedTokens != null) {
      print('✓ Tokens restaurés depuis le stockage');
      client.auth.setTokens(
        accessToken: savedTokens['accessToken'],
        refreshToken: savedTokens['refreshToken'],
      );

      // Vérifier que la session est toujours valide
      try {
        final me = await client.users.me();
        print('✓ Session restaurée pour: ${me?.email}');
      } on DirectusAuthException catch (e) {
        print('✗ Session invalide: ${e.message}');

        // Nettoyer les tokens invalides
        client.clearTokens();
        await tokenStorage.clearTokens();

        // Forcer une nouvelle connexion
        print('→ Nouvelle connexion requise');
      }
    } else {
      print('→ Aucun token sauvegardé, connexion requise');

      // Se connecter
      await client.auth.login(email: 'user@example.com', password: 'password');
      print('✓ Connexion réussie');
    }

    // Utiliser l'API normalement
    final response = await client.items('articles').readMany();
    print('✓ ${response.data.length} articles récupérés');
  } catch (e) {
    print('✗ Erreur: $e');
  } finally {
    await client.dispose();
  }
}

/// Service de stockage de tokens (exemple simplifié)
///
/// En production, utilisez:
/// - shared_preferences pour une persistence simple
/// - flutter_secure_storage pour une sécurité renforcée
/// - hive pour une base de données locale
class TokenStorage {
  // Simuler un stockage en mémoire
  Map<String, String>? _tokens;

  Future<void> saveTokens(String? accessToken, String? refreshToken) async {
    _tokens = {
      if (accessToken != null) 'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
    };
    // En production:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('access_token', accessToken);
    // await prefs.setString('refresh_token', refreshToken);
  }

  Future<Map<String, String>?> loadTokens() async {
    // En production:
    // final prefs = await SharedPreferences.getInstance();
    // final accessToken = prefs.getString('access_token');
    // final refreshToken = prefs.getString('refresh_token');
    // if (accessToken != null && refreshToken != null) {
    //   return {'accessToken': accessToken, 'refreshToken': refreshToken};
    // }
    return _tokens;
  }

  Future<void> clearTokens() async {
    _tokens = null;
    // En production:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.remove('access_token');
    // await prefs.remove('refresh_token');
  }
}
