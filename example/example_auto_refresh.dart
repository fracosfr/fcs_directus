// ignore_for_file: non_constant_identifier_names, avoid_print, unused_local_variable
import 'package:fcs_directus/fcs_directus.dart';

/// Exemple démontrant le refresh automatique des tokens
///
/// Lorsqu'un token expire pendant une requête, le client tente automatiquement
/// de le rafraîchir et de rejouer la requête.
void main() async {
  final client = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://directus.example.com',
      enableLogging: true, // Activé pour voir les logs de refresh
    ),
  );

  try {
    // 1. Authentification initiale
    print('🔐 Connexion...');
    final authResponse = await client.auth.login(
      email: 'user@example.com',
      password: 'password',
    );
    print('✅ Connecté !');
    print('   Access token expire dans: ${authResponse.expiresIn}s');
    print(
      '   Refresh token: ${authResponse.refreshToken != null ? "présent" : "absent"}',
    );

    // 2. Effectuer des requêtes normalement
    print('\n📝 Lecture des articles...');
    final articles = await client.items('articles').readMany();
    print('✅ ${articles.data.length} articles récupérés');

    // 3. Simuler l'expiration du token (en production, cela arriverait naturellement)
    print('\n⏰ Simulation de l\'expiration du token...');
    print('   (En production, attendez simplement ${authResponse.expiresIn}s)');

    // Pour tester, vous pouvez forcer un token invalide :
    // client._httpClient.setTokens(
    //   accessToken: 'expired_token',
    //   refreshToken: authResponse.refreshToken,
    // );

    // 4. La prochaine requête déclenchera automatiquement un refresh
    print(
      '\n🔄 Tentative de requête (devrait déclencher auto-refresh si expiré)...',
    );

    try {
      final moreArticles = await client
          .items('articles')
          .readMany(query: QueryParameters(limit: 5));
      print('✅ ${moreArticles.data.length} articles récupérés');
      print(
        '   → Le refresh automatique a fonctionné si le token était expiré !',
      );
    } catch (e) {
      print('❌ Erreur: $e');
    }

    // 5. Démonstration avec plusieurs requêtes parallèles
    print('\n🔀 Test avec requêtes parallèles...');
    print('   Si le token expire, un seul refresh sera effectué pour toutes.');

    final futures = [
      client.items('articles').readMany(query: QueryParameters(limit: 1)),
      client.items('pages').readMany(query: QueryParameters(limit: 1)),
      client.items('categories').readMany(query: QueryParameters(limit: 1)),
    ];

    final results = await Future.wait(futures);
    print('✅ ${results.length} requêtes parallèles réussies');
    print('   → Un seul refresh pour toutes les requêtes !');
  } on DirectusAuthException catch (e) {
    print('\n❌ Erreur d\'authentification: ${e.message}');
    print('   Code: ${e.errorCode}');

    if (e.errorCode == 'TOKEN_EXPIRED') {
      print('\n⚠️  Le refresh automatique a échoué.');
      print('   Causes possibles:');
      print('   - Le refresh token a expiré');
      print('   - Le refresh token est invalide');
      print('   - L\'utilisateur a été déconnecté côté serveur');
      print('\n💡 Solution: Demander à l\'utilisateur de se reconnecter');
    }
  } on DirectusException catch (e) {
    print('\n❌ Erreur Directus: ${e.message}');
  } finally {
    await client.dispose();
  }
}

/// Exemple d'utilisation dans une application réelle
class ApiService {
  final DirectusClient _client;

  ApiService(this._client);

  /// Récupère des articles - le refresh est automatique !
  Future<List<dynamic>> getArticles() async {
    try {
      // Pas besoin de gérer TOKEN_EXPIRED manuellement
      // Le client le fait automatiquement
      final response = await _client.items('articles').readMany();
      return response.data;
    } on DirectusAuthException catch (e) {
      // Si on arrive ici, c'est que le refresh a échoué
      // → L'utilisateur doit se reconnecter
      if (e.errorCode == 'TOKEN_EXPIRED') {
        print('Session expirée, redirection vers login...');
        // Rediriger vers la page de connexion
      }
      rethrow;
    }
  }

  /// Crée un article
  Future<dynamic> createArticle(Map<String, dynamic> data) async {
    try {
      // Le refresh automatique fonctionne aussi pour POST, PATCH, DELETE
      return await _client.items('articles').createOne(data);
    } on DirectusAuthException catch (e) {
      if (e.errorCode == 'TOKEN_EXPIRED') {
        print('Session expirée, redirection vers login...');
      }
      rethrow;
    }
  }

  /// Rafraîchir manuellement si besoin
  Future<void> refreshTokenManually() async {
    try {
      await _client.auth.refresh();
      print('Token rafraîchi manuellement');
    } catch (e) {
      print('Échec du refresh manuel: $e');
      rethrow;
    }
  }
}

/// Démonstration de la gestion d'erreur
void demonstrateErrorHandling() async {
  final client = DirectusClient(
    DirectusConfig(baseUrl: 'https://directus.example.com'),
  );

  try {
    await client.items('articles').readMany();
  } on DirectusAuthException catch (e) {
    // Cette exception est levée uniquement si :
    // 1. Le refresh automatique a échoué
    // 2. L'utilisateur n'a pas de refresh token
    // 3. Le refresh token est invalide/expiré

    if (e.errorCode == 'TOKEN_EXPIRED') {
      print('🔒 Session expirée définitivement');
      print('   → Reconnexion nécessaire');

      // Rediriger vers login
      // Navigator.pushReplacementNamed(context, '/login');
    } else if (e.errorCode == 'INVALID_TOKEN') {
      print('🔒 Token invalide');
      print('   → Reconnexion nécessaire');
    }
  } on DirectusNetworkException catch (e) {
    print('📡 Problème réseau: ${e.message}');
    print('   → Vérifier la connexion internet');
  } on DirectusException catch (e) {
    print('❌ Erreur: ${e.message}');
  } finally {
    await client.dispose();
  }
}

/// Bonnes pratiques
void bestPractices() {
  print('''
📚 Bonnes pratiques pour le refresh automatique:

1. ✅ Laisser faire le client
   → Pas besoin de gérer TOKEN_EXPIRED dans chaque requête
   → Le refresh est automatique et transparent

2. ✅ Gérer uniquement les échecs de refresh
   → Si DirectusAuthException arrive, c'est que le refresh a échoué
   → Rediriger l'utilisateur vers la page de connexion

3. ✅ Activer les logs en développement
   → enableLogging: true pour voir les refresh en action
   → Désactiver en production pour les performances

4. ✅ Gérer les requêtes parallèles
   → Le client ne fait qu'un seul refresh même pour plusieurs requêtes
   → Pas de surcharge réseau

5. ⚠️ Ne pas faire de boucle infinie
   → Le client évite automatiquement les boucles de retry
   → Si une requête échoue 2 fois, l'erreur est propagée

6. 💡 Refresh manuel si besoin
   → await client.auth.refresh() pour forcer un refresh
   → Utile avant une opération critique

7. 🔒 Sécurité
   → Les tokens sont toujours en mémoire uniquement
   → Persistez le refresh token de manière sécurisée si besoin
  ''');
}
