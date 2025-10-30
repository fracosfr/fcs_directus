/// Exemples d'utilisation complète de l'authentification Directus
///
/// Ce fichier démontre toutes les fonctionnalités d'authentification disponibles
/// dans la librairie fcs_directus selon la documentation officielle Directus.

import 'package:fcs_directus/fcs_directus.dart';

void main() async {
  print('=== Exemples d\'authentification Directus ===\n');

  // Configuration du client
  final config = DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    enableLogging: true,
  );

  final client = DirectusClient(config);

  try {
    // ============================================================================
    // 1. AUTHENTIFICATION PAR EMAIL/PASSWORD (mode JSON - par défaut)
    // ============================================================================
    print('1. Connexion classique (mode JSON)');
    print('-----------------------------------');

    try {
      final authResponse = await client.auth.login(
        email: 'user@example.com',
        password: 'password123',
      );

      print('✓ Connexion réussie !');
      print('  Access Token: ${authResponse.accessToken.substring(0, 20)}...');
      print('  Expires in: ${authResponse.expiresIn}ms');
      print(
        '  Refresh Token: ${authResponse.refreshToken?.substring(0, 20)}...',
      );
      print('');
    } catch (e) {
      print('✗ Erreur de connexion: $e\n');
    }

    // ============================================================================
    // 2. AUTHENTIFICATION AVEC OTP (Two-Factor Authentication)
    // ============================================================================
    print('2. Connexion avec OTP (2FA)');
    print('----------------------------');

    try {
      final authResponseOtp = await client.auth.login(
        email: 'user@example.com',
        password: 'password123',
        otp: '123456', // Code OTP à 6 chiffres
      );

      print('✓ Connexion 2FA réussie !');
      print(
        '  Access Token: ${authResponseOtp.accessToken.substring(0, 20)}...',
      );
      print('');
    } catch (e) {
      print('✗ Erreur de connexion 2FA: $e\n');
    }

    // ============================================================================
    // 3. AUTHENTIFICATION EN MODE COOKIE
    // ============================================================================
    print('3. Connexion en mode cookie (httpOnly)');
    print('----------------------------------------');

    try {
      final authResponseCookie = await client.auth.login(
        email: 'user@example.com',
        password: 'password123',
        mode: AuthMode.cookie,
      );

      print('✓ Connexion en mode cookie réussie !');
      print(
        '  Access Token: ${authResponseCookie.accessToken.substring(0, 20)}...',
      );
      print('  Refresh Token stocké dans un cookie httpOnly');
      print('');
    } catch (e) {
      print('✗ Erreur de connexion cookie: $e\n');
    }

    // ============================================================================
    // 4. AUTHENTIFICATION EN MODE SESSION
    // ============================================================================
    print('4. Connexion en mode session (tous les tokens en cookies)');
    print('----------------------------------------------------------');

    try {
      await client.auth.login(
        email: 'user@example.com',
        password: 'password123',
        mode: AuthMode.session,
      );

      print('✓ Connexion en mode session réussie !');
      print('  Tous les tokens stockés dans des cookies httpOnly');
      print('');
    } catch (e) {
      print('✗ Erreur de connexion session: $e\n');
    }

    // ============================================================================
    // 5. AUTHENTIFICATION PAR TOKEN STATIQUE
    // ============================================================================
    print('5. Connexion avec un token statique');
    print('------------------------------------');

    try {
      await client.auth.loginWithToken(
        'your-static-token-generated-from-directus',
      );

      print('✓ Connexion par token statique réussie !');
      print('  Token configuré dans le client');
      print('');
    } catch (e) {
      print('✗ Erreur de connexion token: $e\n');
    }

    // ============================================================================
    // 6. RAFRAÎCHISSEMENT DU TOKEN (mode JSON)
    // ============================================================================
    print('6. Rafraîchissement du token d\'accès');
    print('---------------------------------------');

    try {
      final refreshResponse = await client.auth.refresh();

      print('✓ Token rafraîchi !');
      print(
        '  New Access Token: ${refreshResponse.accessToken.substring(0, 20)}...',
      );
      print('  Expires in: ${refreshResponse.expiresIn}ms');
      print('');
    } catch (e) {
      print('✗ Erreur de rafraîchissement: $e\n');
    }

    // ============================================================================
    // 7. RAFRAÎCHISSEMENT DU TOKEN AVEC UN REFRESH TOKEN SPÉCIFIQUE
    // ============================================================================
    print('7. Rafraîchissement avec un refresh token spécifique');
    print('-----------------------------------------------------');

    try {
      final refreshResponse = await client.auth.refresh(
        refreshToken: 'specific-refresh-token',
      );

      print('✓ Token rafraîchi avec token spécifique !');
      print(
        '  New Access Token: ${refreshResponse.accessToken.substring(0, 20)}...',
      );
      print('');
    } catch (e) {
      print('✗ Erreur de rafraîchissement: $e\n');
    }

    // ============================================================================
    // 8. RAFRAÎCHISSEMENT EN MODE COOKIE
    // ============================================================================
    print('8. Rafraîchissement en mode cookie');
    print('-----------------------------------');

    try {
      final refreshResponse = await client.auth.refresh(mode: AuthMode.cookie);

      print('✓ Token rafraîchi en mode cookie !');
      print(
        '  New Access Token: ${refreshResponse.accessToken.substring(0, 20)}...',
      );
      print('  Refresh Token mis à jour dans le cookie');
      print('');
    } catch (e) {
      print('✗ Erreur de rafraîchissement cookie: $e\n');
    }

    // ============================================================================
    // 9. DEMANDE DE RÉINITIALISATION DE MOT DE PASSE
    // ============================================================================
    print('9. Demande de réinitialisation de mot de passe');
    print('------------------------------------------------');

    try {
      await client.auth.requestPasswordReset('user@example.com');

      print('✓ Email de réinitialisation envoyé !');
      print(
        '  L\'utilisateur recevra un email avec un lien de réinitialisation',
      );
      print('');
    } catch (e) {
      print('✗ Erreur de demande de réinitialisation: $e\n');
    }

    // ============================================================================
    // 10. DEMANDE DE RÉINITIALISATION AVEC URL PERSONNALISÉE
    // ============================================================================
    print('10. Réinitialisation avec URL personnalisée');
    print('-------------------------------------------');

    try {
      await client.auth.requestPasswordReset(
        'user@example.com',
        resetUrl: 'https://myapp.com/reset-password',
      );

      print('✓ Email de réinitialisation avec URL personnalisée envoyé !');
      print('  L\'URL doit être dans PASSWORD_RESET_URL_ALLOW_LIST');
      print('');
    } catch (e) {
      print('✗ Erreur de demande: $e\n');
    }

    // ============================================================================
    // 11. RÉINITIALISATION DU MOT DE PASSE
    // ============================================================================
    print('11. Réinitialisation du mot de passe');
    print('-------------------------------------');

    try {
      await client.auth.resetPassword(
        token: 'token-received-from-email',
        password: 'new-secure-password',
      );

      print('✓ Mot de passe réinitialisé !');
      print(
        '  L\'utilisateur peut maintenant se connecter avec le nouveau mot de passe',
      );
      print('');
    } catch (e) {
      print('✗ Erreur de réinitialisation: $e\n');
    }

    // ============================================================================
    // 12. LISTE DES FOURNISSEURS OAUTH
    // ============================================================================
    print('12. Liste des fournisseurs OAuth disponibles');
    print('----------------------------------------------');

    try {
      final providers = await client.auth.listOAuthProviders();

      print('✓ Fournisseurs OAuth récupérés !');
      print('  Nombre de providers: ${providers.length}');

      for (var provider in providers) {
        print('  - ${provider.name}');
        if (provider.icon != null) {
          print('    Icon: ${provider.icon}');
        }
      }
      print('');
    } catch (e) {
      print('✗ Erreur de récupération des providers: $e\n');
    }

    // ============================================================================
    // 13. GÉNÉRATION D'URL OAUTH
    // ============================================================================
    print('13. Génération d\'URL OAuth pour Google');
    print('----------------------------------------');

    try {
      final oauthUrl = client.auth.getOAuthUrl('google');

      print('✓ URL OAuth générée !');
      print('  URL: $oauthUrl');
      print(
        '  Rediriger l\'utilisateur vers cette URL pour initier le flow OAuth',
      );
      print('');
    } catch (e) {
      print('✗ Erreur de génération d\'URL: $e\n');
    }

    // ============================================================================
    // 14. GÉNÉRATION D'URL OAUTH AVEC REDIRECTION PERSONNALISÉE
    // ============================================================================
    print('14. URL OAuth avec redirection personnalisée');
    print('--------------------------------------------');

    try {
      final oauthUrl = client.auth.getOAuthUrl(
        'github',
        redirect: 'https://myapp.com/auth/callback',
      );

      print('✓ URL OAuth avec redirection générée !');
      print('  URL: $oauthUrl');
      print(
        '  Après authentification, l\'utilisateur sera redirigé vers myapp.com',
      );
      print('');
    } catch (e) {
      print('✗ Erreur de génération d\'URL: $e\n');
    }

    // ============================================================================
    // 15. CONNEXION OAUTH (après redirection)
    // ============================================================================
    print('15. Connexion OAuth après redirection');
    print('--------------------------------------');

    try {
      // Cette méthode doit être appelée après que l'utilisateur a été redirigé
      // depuis le fournisseur OAuth vers votre application
      final oauthResponse = await client.auth.loginWithOAuth(
        provider: 'google',
        code: 'authorization-code-from-oauth-redirect',
      );

      print('✓ Connexion OAuth réussie !');
      print('  Access Token: ${oauthResponse.accessToken.substring(0, 20)}...');
      print('  Expires in: ${oauthResponse.expiresIn}ms');
      print('');
    } catch (e) {
      print('✗ Erreur de connexion OAuth: $e\n');
    }

    // ============================================================================
    // 16. CONNEXION OAUTH EN MODE COOKIE
    // ============================================================================
    print('16. Connexion OAuth en mode cookie');
    print('-----------------------------------');

    try {
      final oauthResponse = await client.auth.loginWithOAuth(
        provider: 'github',
        code: 'authorization-code-from-oauth-redirect',
        mode: AuthMode.cookie,
      );

      print('✓ Connexion OAuth en mode cookie réussie !');
      print('  Access Token: ${oauthResponse.accessToken.substring(0, 20)}...');
      print('  Refresh Token stocké dans un cookie httpOnly');
      print('');
    } catch (e) {
      print('✗ Erreur de connexion OAuth cookie: $e\n');
    }

    // ============================================================================
    // 17. CONNEXION OAUTH AVEC STATE (pour la sécurité)
    // ============================================================================
    print('17. Connexion OAuth avec state parameter');
    print('-----------------------------------------');

    try {
      final oauthResponse = await client.auth.loginWithOAuth(
        provider: 'facebook',
        code: 'authorization-code-from-oauth-redirect',
        state: 'random-state-string-for-security',
      );

      print('✓ Connexion OAuth avec state réussie !');
      print('  Access Token: ${oauthResponse.accessToken.substring(0, 20)}...');
      print('  State parameter vérifié pour la sécurité');
      print('');
    } catch (e) {
      print('✗ Erreur de connexion OAuth state: $e\n');
    }

    // ============================================================================
    // 18. VÉRIFICATION DE L'ÉTAT D'AUTHENTIFICATION
    // ============================================================================
    print('18. Vérification de l\'authentification');
    print('----------------------------------------');

    final isAuth = client.auth.isAuthenticated;
    print(
      'État d\'authentification: ${isAuth ? "✓ Authentifié" : "✗ Non authentifié"}',
    );

    if (isAuth) {
      final token = client.auth.accessToken;
      print('Access Token actuel: ${token?.substring(0, 20)}...');
    }
    print('');

    // ============================================================================
    // 19. DÉCONNEXION (mode JSON)
    // ============================================================================
    print('19. Déconnexion classique');
    print('-------------------------');

    try {
      await client.auth.logout();

      print('✓ Déconnexion réussie !');
      print('  Tokens invalidés sur le serveur et supprimés localement');
      print('');
    } catch (e) {
      print('✗ Erreur de déconnexion: $e\n');
    }

    // ============================================================================
    // 20. DÉCONNEXION EN MODE COOKIE
    // ============================================================================
    print('20. Déconnexion en mode cookie');
    print('-------------------------------');

    try {
      await client.auth.logout(mode: AuthMode.cookie);

      print('✓ Déconnexion en mode cookie réussie !');
      print('  Cookies httpOnly supprimés');
      print('');
    } catch (e) {
      print('✗ Erreur de déconnexion cookie: $e\n');
    }

    // ============================================================================
    // RÉSUMÉ DES MODES D'AUTHENTIFICATION
    // ============================================================================
    print('\n📋 RÉSUMÉ DES MODES D\'AUTHENTIFICATION');
    print('=========================================\n');

    print('AuthMode.json (par défaut):');
    print('  - Les tokens sont retournés dans la réponse JSON');
    print('  - L\'application gère le stockage des tokens');
    print('  - Idéal pour les applications mobiles et SPAs\n');

    print('AuthMode.cookie:');
    print('  - Le refresh token est stocké dans un cookie httpOnly');
    print('  - L\'access token est retourné en JSON');
    print('  - Sécurité renforcée contre les attaques XSS\n');

    print('AuthMode.session:');
    print('  - Tous les tokens sont stockés dans des cookies httpOnly');
    print('  - Aucun token exposé au JavaScript');
    print('  - Sécurité maximale, idéal pour les applications web SSR\n');

    // ============================================================================
    // BONNES PRATIQUES
    // ============================================================================
    print('\n💡 BONNES PRATIQUES');
    print('===================\n');

    print('1. Sécurité:');
    print('   - Utilisez HTTPS en production');
    print('   - Activez 2FA (OTP) pour les comptes sensibles');
    print(
      '   - Utilisez AuthMode.cookie ou .session pour les applications web\n',
    );

    print('2. Gestion des tokens:');
    print('   - Rafraîchissez les tokens avant expiration');
    print(
      '   - Stockez les tokens de manière sécurisée (keychain, secure storage)',
    );
    print('   - Ne loggez jamais les tokens complets\n');

    print('3. OAuth:');
    print('   - Utilisez le paramètre state pour éviter les attaques CSRF');
    print('   - Vérifiez que l\'URL de redirection est dans la whitelist');
    print('   - Gérez les erreurs de redirection OAuth correctement\n');

    print('4. Réinitialisation de mot de passe:');
    print('   - Configurez PASSWORD_RESET_URL_ALLOW_LIST sur le serveur');
    print('   - Utilisez des URLs HTTPS pour les liens de réinitialisation');
    print('   - Les tokens de réinitialisation expirent rapidement\n');
  } catch (e) {
    print('Erreur globale: $e');
  } finally {
    // Nettoyage
    client.dispose();
  }
}
