// ignore_for_file: avoid_print

/// Exemple : Différence entre Token Statique et Refresh Token
///
/// Ce fichier démontre clairement la différence entre :
/// - loginWithToken() pour les tokens statiques
/// - restoreSession() / refresh() pour les refresh tokens
library;

import 'package:fcs_directus/fcs_directus.dart';

void main() async {
  print('╔════════════════════════════════════════════════════════╗');
  print('║  Différence : Token Statique vs Refresh Token         ║');
  print('╚════════════════════════════════════════════════════════╝\n');

  await example1StaticToken();
  print('\n${'=' * 60}\n');
  await example2RefreshToken();
  print('\n${'=' * 60}\n');
  await example3RestoreSession();
}

/// Exemple 1 : Token statique (Access Token permanent)
///
/// Les tokens statiques sont générés manuellement dans Directus
/// et sont utilisés pour les services backend, scripts, etc.
Future<void> example1StaticToken() async {
  print('📌 Exemple 1 : Token Statique (Access Token permanent)\n');

  final client = DirectusClient(
    DirectusConfig(baseUrl: 'https://directus.example.com'),
  );

  // ✅ Token statique = Access Token permanent
  const staticToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

  try {
    // Utiliser loginWithToken pour les tokens STATIQUES uniquement
    await client.auth.loginWithToken(staticToken);
    print('✅ Connecté avec token statique');
    print('   Type : Access Token permanent');
    print('   Génération : Manuel via Directus Admin');
    print('   Expiration : Configurable ou permanente');
    print('   Refresh : Non applicable\n');

    // Ce token donne accès direct à l'API
    final articles = await client
        .items('articles')
        .readMany(query: QueryParameters(limit: 3));
    print('📄 ${articles.data.length} articles récupérés avec token statique');

    print('\n⚠️  Points importants :');
    print('   • Ne peut PAS être rafraîchi');
    print('   • Si compromis, doit être révoqué manuellement');
    print('   • Idéal pour : backend, scripts, cron jobs');
    print('   • À éviter pour : applications utilisateur');
  } on DirectusException catch (e) {
    print('❌ Erreur : ${e.message}');
  } finally {
    await client.dispose();
  }
}

/// Exemple 2 : Refresh Token (obtenu via login)
///
/// Les refresh tokens sont obtenus lors d'un login email/password
/// et permettent d'obtenir de nouveaux access tokens.
Future<void> example2RefreshToken() async {
  print('📌 Exemple 2 : Refresh Token (Login email/password)\n');

  final client = DirectusClient(
    DirectusConfig(baseUrl: 'https://directus.example.com'),
  );

  try {
    // Login standard pour obtenir les tokens
    print('🔐 Login avec email/password...');
    final authResponse = await client.auth.login(
      email: 'user@example.com',
      password: 'password',
    );

    print('✅ Connecté avec succès !');
    print('   Access Token : ${authResponse.accessToken.substring(0, 30)}...');
    print('   Expire dans : ${authResponse.expiresIn} secondes');
    print(
      '   Refresh Token : ${authResponse.refreshToken?.substring(0, 30)}...\n',
    );

    // ❌ ERREUR COMMUNE : Essayer d'utiliser le refresh token comme access token
    print('❌ ERREUR COMMUNE À ÉVITER :');
    print('   await client.auth.loginWithToken(refreshToken);');
    print(
      '   → Ne fonctionne PAS ! Le refresh token ne donne pas accès direct.\n',
    );

    // ✅ CORRECT : Utiliser refresh() pour obtenir un nouveau access token
    print('✅ UTILISATION CORRECTE :');
    print('   Attendre que l\'access token expire...');

    // Simuler l'attente (en production, cela arrive naturellement)
    // await Future.delayed(Duration(seconds: authResponse.expiresIn));

    // Rafraîchir le token
    print('   Rafraîchissement du token...');
    final newAuth = await client.auth.refresh();

    print('   ✅ Token rafraîchi !');
    print(
      '   Nouveau Access Token : ${newAuth.accessToken.substring(0, 30)}...',
    );
    print('   Expire dans : ${newAuth.expiresIn} secondes\n');

    print('💡 Points clés :');
    print('   • Refresh Token ≠ Access Token');
    print('   • Le refresh token ne donne PAS accès direct à l\'API');
    print('   • Utilisez auth.refresh() pour obtenir un nouveau access token');
    print('   • Le refresh est AUTOMATIQUE en cas d\'expiration');
  } on DirectusException catch (e) {
    print('❌ Erreur : ${e.message}');
  } finally {
    await client.dispose();
  }
}

/// Exemple 3 : Restaurer une session avec restoreSession()
///
/// Cas d'usage : Sauvegarder le refresh token et restaurer la session
/// après un redémarrage de l'application.
Future<void> example3RestoreSession() async {
  print('📌 Exemple 3 : Restaurer une session avec restoreSession()\n');

  final client = DirectusClient(
    DirectusConfig(baseUrl: 'https://directus.example.com'),
  );

  try {
    // Étape 1 : Login initial et sauvegarde du refresh token
    print('Étape 1 : Login initial');
    print('─' * 40);
    final initialAuth = await client.auth.login(
      email: 'user@example.com',
      password: 'password',
    );

    // Sauvegarder le refresh token (ex: SharedPreferences, SecureStorage)
    final savedRefreshToken = initialAuth.refreshToken!;
    print('✅ Login réussi');
    print(
      '📦 Refresh token sauvegardé : ${savedRefreshToken.substring(0, 30)}...\n',
    );

    // Simuler la fermeture de l'application
    await client.dispose();
    print('🔚 Application fermée\n');

    // Étape 2 : Redémarrage et restauration de la session
    print('Étape 2 : Redémarrage de l\'application');
    print('─' * 40);

    final newClient = DirectusClient(
      DirectusConfig(baseUrl: 'https://directus.example.com'),
    );

    // ✅ CORRECT : Utiliser restoreSession() avec le refresh token sauvegardé
    print('📦 Chargement du refresh token sauvegardé...');
    final restoredAuth = await newClient.auth.restoreSession(savedRefreshToken);

    print('✅ Session restaurée !');
    print(
      '   Nouveau Access Token : ${restoredAuth.accessToken.substring(0, 30)}...',
    );
    print('   Expire dans : ${restoredAuth.expiresIn} secondes');
    print(
      '   Refresh Token : ${restoredAuth.refreshToken?.substring(0, 30) ?? "même qu'avant"}...\n',
    );

    // Vérifier que la session fonctionne
    final user = await newClient.users.me();
    print('✅ Session active pour : ${user?.email}\n');

    print('💡 Workflow complet :');
    print('   1. Login → Obtenir refresh token');
    print('   2. Sauvegarder le refresh token (SecureStorage)');
    print('   3. À la réouverture : restoreSession(refreshToken)');
    print('   4. Profit ! Session restaurée sans re-login');

    await newClient.dispose();
  } on DirectusException catch (e) {
    print('❌ Erreur : ${e.message}');
  }
}

/// Tableau comparatif
void printComparisonTable() {
  print('\n╔════════════════════════════════════════════════════════════════╗');
  print('║                    TABLEAU COMPARATIF                          ║');
  print('╠════════════════════════════════════════════════════════════════╣');
  print('║                                                                ║');
  print('║  Caractéristique      │ Token Statique    │ Refresh Token    ║');
  print('║  ────────────────────────────────────────────────────────────  ║');
  print('║  Génération           │ Manuel (Admin)    │ Auto (Login)     ║');
  print('║  Type                 │ Access Token      │ Refresh Token    ║');
  print('║  Durée de vie         │ Longue/Permanente │ Moyenne (7j)     ║');
  print('║  Accès direct API     │ ✅ Oui            │ ❌ Non           ║');
  print('║  Peut être rafraîchi  │ ❌ Non            │ ✅ Oui           ║');
  print('║  Méthode à utiliser   │ loginWithToken()  │ restoreSession() ║');
  print('║  Cas d\'usage          │ Backend/Scripts   │ Apps utilisateur ║');
  print('║  Sécurité révocation  │ Manuel            │ Automatique      ║');
  print('║                                                                ║');
  print('╚════════════════════════════════════════════════════════════════╝');
}

/// Exemple de classe utilitaire pour gérer la persistance
class TokenPersistence {
  // Exemple avec SharedPreferences (à adapter selon votre projet)

  /// Sauvegarder les tokens après login
  static Future<void> saveTokens(AuthResponse auth) async {
    // await prefs.setString('access_token', auth.accessToken);
    // await prefs.setString('refresh_token', auth.refreshToken!);
    print('💾 Tokens sauvegardés (exemple)');
  }

  /// Charger et restaurer la session
  static Future<AuthResponse?> restoreSession(DirectusClient client) async {
    try {
      // En production, charger depuis le stockage :
      // final refreshToken = await prefs.getString('refresh_token');

      // Simuler un chargement depuis le storage (peut retourner null en pratique)
      final String? refreshToken = _loadTokenFromStorage();

      if (refreshToken == null || refreshToken.isEmpty) {
        print('⚠️  Aucun refresh token sauvegardé');
        return null;
      }

      // Restaurer la session
      final auth = await client.auth.restoreSession(refreshToken);
      print('✅ Session restaurée depuis le stockage');
      return auth;
    } catch (e) {
      print('❌ Impossible de restaurer la session : $e');
      return null;
    }
  }

  /// Simuler le chargement depuis un storage
  static String? _loadTokenFromStorage() {
    // En production : return await prefs.getString('refresh_token');
    // Pour l'exemple, retourner un token fictif
    return 'saved-refresh-token';
  }

  /// Effacer les tokens (lors du logout)
  static Future<void> clearTokens() async {
    // await prefs.remove('access_token');
    // await prefs.remove('refresh_token');
    print('🗑️  Tokens supprimés');
  }
}

/// Documentation des erreurs communes
class CommonMistakes {
  /// ❌ ERREUR 1 : Utiliser loginWithToken avec un refresh token
  static void mistake1() {
    print('❌ ERREUR COMMUNE #1 :');
    print('');
    print('// INCORRECT :');
    print('final refreshToken = authResponse.refreshToken;');
    print(
      'await client.auth.loginWithToken(refreshToken); // ❌ Ne marche pas !',
    );
    print('');
    print('// CORRECT :');
    print('await client.auth.restoreSession(refreshToken); // ✅');
  }

  /// ❌ ERREUR 2 : Confondre access token et refresh token
  static void mistake2() {
    print('❌ ERREUR COMMUNE #2 :');
    print('');
    print('// Le refresh token ne donne PAS accès direct à l\'API');
    print('// Il sert uniquement à obtenir un nouveau access token');
    print('');
    print('// INCORRECT :');
    print('headers["Authorization"] = "Bearer \$refreshToken"; // ❌');
    print('');
    print('// CORRECT :');
    print(
      'final auth = await client.auth.refresh(refreshToken: refreshToken);',
    );
    print('headers["Authorization"] = "Bearer \${auth.accessToken}"; // ✅');
  }

  /// ❌ ERREUR 3 : Sauvegarder l'access token au lieu du refresh token
  static void mistake3() {
    print('❌ ERREUR COMMUNE #3 :');
    print('');
    print('// INCORRECT :');
    print('await storage.save(\'token\', authResponse.accessToken); // ❌');
    print('// L\'access token expire rapidement (15-30 min)');
    print('');
    print('// CORRECT :');
    print('await storage.save(\'token\', authResponse.refreshToken); // ✅');
    print('// Le refresh token dure plus longtemps (7 jours+)');
  }
}
