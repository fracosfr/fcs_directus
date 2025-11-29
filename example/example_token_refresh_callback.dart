// ignore_for_file: non_constant_identifier_names, avoid_print, unused_local_variable

/// Exemple : Notification et sauvegarde automatique lors du refresh de tokens
///
/// Cet exemple démontre comment utiliser le callback onTokenRefreshed
/// pour sauvegarder automatiquement les tokens lors d'un refresh automatique.
library;

import 'package:fcs_directus/fcs_directus.dart';

void main() async {
  print('╔════════════════════════════════════════════════════════╗');
  print('║  Notification automatique lors du refresh de tokens   ║');
  print('╚════════════════════════════════════════════════════════╝\n');

  await example1_BasicCallback();
  print('\n${'=' * 60}\n');
  await example2_WithStorage();
  print('\n${'=' * 60}\n');
  await example3_CompleteWorkflow();
}

/// Exemple 1 : Callback basique
Future<void> example1_BasicCallback() async {
  print('📌 Exemple 1 : Callback basique pour notifier du refresh\n');

  // Configuration avec callback
  final client = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://directus.example.com',
      enableLogging: true,
      // 🔔 Callback appelé lors du refresh automatique
      onTokenRefreshed: (accessToken, refreshToken) async {
        print('\n🔔 NOTIFICATION : Tokens rafraîchis !');
        print('   Nouvel access token : ${accessToken.substring(0, 30)}...');
        print(
          '   Nouveau refresh token : ${refreshToken?.substring(0, 30) ?? "inchangé"}...',
        );
        print('   Timestamp : ${DateTime.now()}\n');
      },
    ),
  );

  try {
    // Login initial
    print('🔐 Login initial...');
    final auth = await client.auth.login(
      email: 'user@example.com',
      password: 'password',
    );
    print('✅ Connecté !');
    print('   Token expire dans : ${auth.expiresIn}s\n');

    // Faire des requêtes normalement
    print('📝 Requête 1...');
    await client.items('articles').readMany(query: QueryParameters(limit: 1));
    print('✅ Requête 1 réussie\n');

    // Attendre que le token expire (en production, cela arrive naturellement)
    print('⏰ Attente de l\'expiration du token...');
    print('   (En production, continuez simplement à utiliser le client)\n');

    // Simuler une requête après expiration
    // Le refresh automatique se déclenchera et le callback sera appelé
    print('📝 Requête 2 (après expiration simulée)...');
    await client.items('articles').readMany(query: QueryParameters(limit: 1));
    print('✅ Requête 2 réussie (le callback a été appelé !)\n');

    print('💡 Le callback a été automatiquement appelé lors du refresh !');
  } on DirectusException catch (e) {
    print('❌ Erreur : ${e.message}');
  } finally {
    await client.dispose();
  }
}

/// Exemple 2 : Avec sauvegarde dans un storage
Future<void> example2_WithStorage() async {
  print('📌 Exemple 2 : Sauvegarde automatique dans un storage\n');

  // Simuler un storage (en production : SharedPreferences, SecureStorage, etc.)
  final storage = TokenStorage();

  final client = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://directus.example.com',
      enableLogging: true,
      // 💾 Sauvegarder automatiquement les nouveaux tokens
      onTokenRefreshed: (accessToken, refreshToken) async {
        print('💾 Sauvegarde automatique des nouveaux tokens...');
        await storage.saveAccessToken(accessToken);
        if (refreshToken != null) {
          await storage.saveRefreshToken(refreshToken);
        }
        print('✅ Tokens sauvegardés automatiquement !\n');
      },
    ),
  );

  try {
    // Login et sauvegarde initiale
    print('🔐 Login initial...');
    final auth = await client.auth.login(
      email: 'user@example.com',
      password: 'password',
    );

    // Sauvegarder manuellement la première fois
    await storage.saveAccessToken(auth.accessToken);
    if (auth.refreshToken != null) {
      await storage.saveRefreshToken(auth.refreshToken!);
    }
    print('✅ Tokens initiaux sauvegardés\n');

    // Utiliser normalement
    print('📝 Effectuer des opérations...');
    for (var i = 1; i <= 5; i++) {
      await client.items('articles').readMany(query: QueryParameters(limit: 1));
      print('   Opération $i/5 réussie');
      await Future.delayed(Duration(milliseconds: 100));
    }

    print('\n💡 Si le token expire pendant ces opérations :');
    print('   → Le refresh est automatique');
    print('   → Les nouveaux tokens sont sauvegardés automatiquement');
    print('   → Aucune intervention nécessaire !');
  } on DirectusException catch (e) {
    print('❌ Erreur : ${e.message}');
  } finally {
    await client.dispose();
  }
}

/// Exemple 3 : Workflow complet avec restauration
Future<void> example3_CompleteWorkflow() async {
  print(
    '📌 Exemple 3 : Workflow complet (Login → Utilisation → Fermeture → Restauration)\n',
  );

  final storage = TokenStorage();

  // ─────────────────────────────────────────────────────────
  // PHASE 1 : Première utilisation
  // ─────────────────────────────────────────────────────────
  print('PHASE 1 : Première utilisation');
  print('─' * 60);

  var client = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://directus.example.com',
      onTokenRefreshed: storage.onTokensRefreshed,
    ),
  );

  print('🔐 Login...');
  var auth = await client.auth.login(
    email: 'user@example.com',
    password: 'password',
  );

  // Sauvegarder les tokens initiaux
  await storage.saveAccessToken(auth.accessToken);
  if (auth.refreshToken != null) {
    await storage.saveRefreshToken(auth.refreshToken!);
  }
  print('✅ Login réussi et tokens sauvegardés\n');

  // Utiliser l'application
  print('📝 Utilisation de l\'application...');
  await client.items('articles').readMany(query: QueryParameters(limit: 1));
  print('✅ Opérations effectuées\n');

  // Fermer l'application
  print('🔚 Fermeture de l\'application');
  await client.dispose();
  print('✅ Application fermée (tokens sauvegardés)\n\n');

  // ─────────────────────────────────────────────────────────
  // PHASE 2 : Redémarrage et restauration
  // ─────────────────────────────────────────────────────────
  print('PHASE 2 : Redémarrage de l\'application');
  print('─' * 60);

  // Nouvelle instance du client avec le même callback
  client = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://directus.example.com',
      onTokenRefreshed: storage.onTokensRefreshed,
    ),
  );

  print('📦 Chargement des tokens sauvegardés...');
  final savedRefreshToken = await storage.loadRefreshToken();

  if (savedRefreshToken != null) {
    print('✅ Refresh token trouvé');
    print('🔄 Restauration de la session...');

    auth = await client.auth.restoreSession(savedRefreshToken);
    print('✅ Session restaurée automatiquement !');
    print('   Nouvel access token obtenu');
    print('   Expire dans : ${auth.expiresIn}s\n');

    // Les tokens ont été automatiquement sauvegardés via le callback !
    print('💡 Les nouveaux tokens sont déjà sauvegardés (via callback) !');

    // Continuer à utiliser normalement
    print('\n📝 Utilisation normale...');
    await client.items('articles').readMany(query: QueryParameters(limit: 1));
    print('✅ Tout fonctionne !\n');

    print('🎯 Avantages :');
    print('   ✅ Pas de re-login nécessaire');
    print('   ✅ Sauvegarde automatique à chaque refresh');
    print('   ✅ Expérience utilisateur transparente');
  } else {
    print('⚠️  Aucun token sauvegardé, login nécessaire');
  }

  await client.dispose();
}

// ═══════════════════════════════════════════════════════════
// Classes utilitaires
// ═══════════════════════════════════════════════════════════

/// Simulateur de storage persistant
/// En production, utilisez SharedPreferences, SecureStorage, etc.
class TokenStorage {
  String? _accessToken;
  String? _refreshToken;
  int _saveCount = 0;

  /// Sauvegarder l'access token
  Future<void> saveAccessToken(String token) async {
    _accessToken = token;
    _saveCount++;
    print('💾 Access token sauvegardé (sauvegarde #$_saveCount)');
  }

  /// Sauvegarder le refresh token
  Future<void> saveRefreshToken(String token) async {
    _refreshToken = token;
    print('💾 Refresh token sauvegardé');
  }

  /// Charger le refresh token
  Future<String?> loadRefreshToken() async {
    return _refreshToken;
  }

  /// Charger l'access token
  Future<String?> loadAccessToken() async {
    return _accessToken;
  }

  /// Callback pour le refresh automatique
  Future<void> onTokensRefreshed(
    String accessToken,
    String? refreshToken,
  ) async {
    print('\n🔔 CALLBACK : Refresh automatique détecté !');
    await saveAccessToken(accessToken);
    if (refreshToken != null) {
      await saveRefreshToken(refreshToken);
    }
    print('✅ Nouveaux tokens sauvegardés automatiquement');
  }

  /// Effacer tous les tokens
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _saveCount = 0;
    print('🗑️  Tokens supprimés');
  }

  /// Statistiques
  void printStats() {
    print('\n📊 Statistiques du storage :');
    print('   Nombre de sauvegardes : $_saveCount');
    print('   Access token : ${_accessToken != null ? "présent" : "absent"}');
    print('   Refresh token : ${_refreshToken != null ? "présent" : "absent"}');
  }
}

/// Exemple avec SharedPreferences (production)
class SharedPreferencesTokenStorage {
  // Exemple conceptuel - nécessite le package shared_preferences

  Future<void> onTokensRefreshed(
    String accessToken,
    String? refreshToken,
  ) async {
    // En production :
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('access_token', accessToken);
    // if (refreshToken != null) {
    //   await prefs.setString('refresh_token', refreshToken);
    // }

    print('💾 Tokens sauvegardés dans SharedPreferences');
  }

  Future<String?> loadRefreshToken() async {
    // En production :
    // final prefs = await SharedPreferences.getInstance();
    // return prefs.getString('refresh_token');

    return null;
  }
}

/// Exemple avec SecureStorage (production)
class SecureStorageTokenStorage {
  // Exemple conceptuel - nécessite le package flutter_secure_storage

  Future<void> onTokensRefreshed(
    String accessToken,
    String? refreshToken,
  ) async {
    // En production :
    // final storage = FlutterSecureStorage();
    // await storage.write(key: 'access_token', value: accessToken);
    // if (refreshToken != null) {
    //   await storage.write(key: 'refresh_token', value: refreshToken);
    // }

    print('🔒 Tokens sauvegardés dans SecureStorage');
  }

  Future<String?> loadRefreshToken() async {
    // En production :
    // final storage = FlutterSecureStorage();
    // return await storage.read(key: 'refresh_token');

    return null;
  }
}

// ═══════════════════════════════════════════════════════════
// Bonnes pratiques
// ═══════════════════════════════════════════════════════════

void printBestPractices() {
  print('''
╔════════════════════════════════════════════════════════════╗
║                    BONNES PRATIQUES                        ║
╚════════════════════════════════════════════════════════════╝

1. 💾 Toujours sauvegarder le refresh token (pas l'access token)
   → L'access token expire vite (15-30 min)
   → Le refresh token dure longtemps (7 jours+)

2. 🔔 Utiliser onTokenRefreshed pour la sauvegarde automatique
   → Évite d'oublier de sauvegarder après chaque refresh
   → Garantit que les tokens sont toujours à jour

3. 🔒 Utiliser un stockage sécurisé
   ✅ FlutterSecureStorage (recommandé)
   ✅ EncryptedSharedPreferences
   ❌ SharedPreferences simple (pas chiffré)

4. 🎯 Workflow recommandé :
   a. Login → Sauvegarder refresh token
   b. Utiliser normalement (refresh automatique)
   c. Au redémarrage → Restaurer avec refresh token
   d. Les nouveaux tokens sont sauvegardés automatiquement

5. ⚠️  Gestion d'erreur dans le callback
   → Ne jamais faire échouer le refresh si le callback échoue
   → Logger les erreurs du callback pour debugging

6. 🔄 Tester le workflow complet
   → Login → Fermeture app → Réouverture → Doit fonctionner
   → Pas de re-login nécessaire

7. 🗑️  Effacer les tokens au logout
   → Appeler storage.clear() lors du logout
   → Sécurité et confidentialité

╔════════════════════════════════════════════════════════════╗
║                  EXEMPLES DE CODE                          ║
╚════════════════════════════════════════════════════════════╝

// Configuration recommandée :
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://directus.example.com',
    onTokenRefreshed: (accessToken, refreshToken) async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'access_token', value: accessToken);
      if (refreshToken != null) {
        await storage.write(key: 'refresh_token', value: refreshToken);
      }
    },
  ),
);

// Restauration au démarrage :
final storage = FlutterSecureStorage();
final refreshToken = await storage.read(key: 'refresh_token');
if (refreshToken != null) {
  await client.auth.restoreSession(refreshToken);
}
  ''');
}
