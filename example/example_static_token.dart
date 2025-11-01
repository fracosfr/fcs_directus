// ignore_for_file: avoid_print

/// Exemple d'utilisation de l'authentification par token statique
///
/// Les tokens statiques sont utiles pour :
/// - Scripts automatisés et tâches planifiées (cron jobs)
/// - Services backend server-to-server
/// - Intégrations avec des systèmes externes
/// - Applications sans interface utilisateur
library;

import 'package:fcs_directus/fcs_directus.dart';

void main() async {
  await exampleStaticTokenBasic();
  print('\n${'=' * 60}\n');
  await exampleStaticTokenWithValidation();
  print('\n${'=' * 60}\n');
  await exampleBackendService();
}

/// Exemple 1 : Utilisation basique d'un token statique
Future<void> exampleStaticTokenBasic() async {
  print('=== Exemple 1 : Authentification avec token statique ===\n');

  // Configuration du client
  final directus = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://your-directus-instance.com',
      enableLogging: true,
    ),
  );

  try {
    // Authentification avec un token statique
    // ⚠️ Ne jamais hardcoder le token en production !
    // Utilisez des variables d'environnement ou un secrets manager
    const staticToken = 'your-static-token-here';

    await directus.auth.loginWithToken(staticToken);
    print('✅ Authentifié avec token statique\n');

    // Vérifier que l'authentification a fonctionné
    if (directus.auth.isAuthenticated) {
      print('✅ Client authentifié');
      print(
        'Token actuel : ${directus.auth.accessToken?.substring(0, 20)}...\n',
      );
    }

    // Utiliser les services normalement
    final articles = await directus
        .items('articles')
        .readMany(
          query: QueryParameters(limit: 5, fields: ['id', 'title', 'status']),
        );

    print('📄 ${articles.data.length} articles trouvés:');
    for (final article in articles.data) {
      print('  - ${article['title']} (${article['status']})');
    }
  } on DirectusException catch (e) {
    print('❌ Erreur: ${e.message}');
  } finally {
    directus.dispose();
  }
}

/// Exemple 2 : Validation du token avant utilisation
Future<void> exampleStaticTokenWithValidation() async {
  print('=== Exemple 2 : Validation du token statique ===\n');

  final directus = DirectusClient(
    DirectusConfig(baseUrl: 'https://your-directus-instance.com'),
  );

  const token = 'your-static-token-here';

  try {
    // Authentifier
    await directus.auth.loginWithToken(token);
    print('✅ Token appliqué\n');

    // Valider en récupérant les informations de l'utilisateur
    print('Validation du token...');
    final user = await directus.users.me();

    print('✅ Token valide !');
    print('Utilisateur : ${user?.firstName} ${user?.lastName}');
    print('Email : ${user?.email}');
    print('Rôle ID : ${user?.role}\n');

    // Vérifier les informations de l'utilisateur
    print('Informations utilisateur :');
    print('  Statut : ${user?.status}');
    print('  Langue : ${user?.language}');
  } on DirectusAuthException catch (e) {
    print('❌ Token invalide: ${e.message}');
    print('Vérifiez que :');
    print('  1. Le token est correct');
    print('  2. Le token n\'a pas expiré');
    print('  3. L\'utilisateur associé existe toujours');
    print('  4. Les permissions sont correctement configurées');
  } on DirectusException catch (e) {
    print('❌ Erreur Directus: ${e.message}');
  } finally {
    directus.dispose();
  }
}

/// Exemple 3 : Service backend avec gestion d'erreurs complète
Future<void> exampleBackendService() async {
  print('=== Exemple 3 : Service backend avec token statique ===\n');

  // En production, charger depuis les variables d'environnement :
  // final token = Platform.environment['DIRECTUS_TOKEN'];
  // final baseUrl = Platform.environment['DIRECTUS_URL'];

  final directus = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://your-directus-instance.com',
      timeout: Duration(
        seconds: 60,
      ), // Timeout plus long pour les traitements batch
    ),
  );

  const token = 'your-static-token-here';

  try {
    // Authentification
    print('Authentification du service...');
    await directus.auth.loginWithToken(token);
    print('✅ Service authentifié\n');

    // Exemple : Synchronisation de données
    print('Début de la synchronisation des données...');

    // 1. Récupérer les nouveaux articles
    final newArticles = await directus
        .items('articles')
        .readMany(
          query: QueryParameters(
            filter: Filter.field('status').equals('published'),
            sort: ['-date_created'],
            limit: 10,
          ),
        );

    print('📄 ${newArticles.data.length} nouveaux articles trouvés');

    // 2. Traiter chaque article
    for (final article in newArticles.data) {
      print('  Traitement: ${article['title']}');

      // Exemple de traitement
      await Future.delayed(Duration(milliseconds: 100));

      // Mettre à jour un champ (ex: marquer comme synchronisé)
      await directus.items('articles').updateOne(article['id'].toString(), {
        'last_sync': DateTime.now().toIso8601String(),
      });
    }

    print('✅ Synchronisation terminée\n');

    // 3. Créer un log d'activité
    await directus.items('sync_logs').createOne({
      'timestamp': DateTime.now().toIso8601String(),
      'items_processed': newArticles.data.length,
      'status': 'success',
    });

    print('✅ Log créé');
  } on DirectusNetworkException catch (e) {
    print('❌ Erreur réseau: ${e.message}');
    print('Vérifiez votre connexion internet et l\'URL de Directus');
  } on DirectusAuthException catch (e) {
    print('❌ Erreur d\'authentification: ${e.message}');
    print('Le token est peut-être invalide ou expiré');
    // En production : envoyer une alerte pour renouveler le token
  } on DirectusPermissionException catch (e) {
    print('❌ Permission refusée: ${e.message}');
    print('Vérifiez les permissions du token dans Directus');
  } on DirectusException catch (e) {
    print('❌ Erreur Directus: ${e.message}');
    print('Code: ${e.statusCode}');
    if (e.extensions != null) {
      print('Extensions: ${e.extensions}');
    }
  } catch (e) {
    print('❌ Erreur inattendue: $e');
  } finally {
    directus.dispose();
    print('\nService arrêté');
  }
}

/// Exemple 4 : Bonnes pratiques pour la gestion des tokens
class SecureTokenManager {
  /// Chargement sécurisé du token depuis l'environnement
  static String? getTokenFromEnvironment() {
    // En production, utilisez :
    // - Variables d'environnement (dotenv)
    // - Secrets manager (AWS Secrets Manager, Azure Key Vault, etc.)
    // - Configuration chiffrée

    // Exemple avec dotenv :
    // await dotenv.load();
    // return dotenv.env['DIRECTUS_STATIC_TOKEN'];

    return null; // Placeholder
  }

  /// Validation du format du token
  static bool isValidTokenFormat(String token) {
    // Les tokens Directus sont généralement des chaînes alphanumériques
    // Cette validation peut être adaptée selon votre configuration
    return token.isNotEmpty && token.length >= 32;
  }

  /// Test de connexion avec retry
  static Future<bool> testConnection(
    DirectusClient directus,
    String token, {
    int maxRetries = 3,
  }) async {
    for (var i = 0; i < maxRetries; i++) {
      try {
        await directus.auth.loginWithToken(token);
        await directus.users.me();
        return true;
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: 2 * (i + 1)));
      }
    }
    return false;
  }
}

/// Exemple 5 : Service avec rotation de token
class TokenRotationService {
  final DirectusClient directus;
  final Duration tokenCheckInterval;
  String? currentToken;

  TokenRotationService({
    required this.directus,
    this.tokenCheckInterval = const Duration(hours: 1),
  });

  /// Démarrer le service avec vérification périodique
  Future<void> start(String initialToken) async {
    currentToken = initialToken;
    await directus.auth.loginWithToken(initialToken);

    // En production, implémenter une vérification périodique
    // et une rotation automatique si nécessaire
    print('Service démarré avec token: ${initialToken.substring(0, 10)}...');
  }

  /// Vérifier la validité du token
  Future<bool> checkTokenValidity() async {
    try {
      await directus.users.me();
      return true;
    } on DirectusAuthException {
      return false;
    }
  }

  /// Renouveler le token (si expiré)
  Future<void> rotateToken(String newToken) async {
    print('Rotation du token en cours...');
    await directus.auth.loginWithToken(newToken);
    currentToken = newToken;
    print('✅ Token renouvelé');
  }
}
