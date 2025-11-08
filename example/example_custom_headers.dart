// ignore_for_file: avoid_print

import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation de headers personnalisés avec DirectusClient.
///
/// Les headers personnalisés sont utiles dans plusieurs cas :
/// - Directus derrière un reverse proxy (nginx, Apache, etc.)
/// - API Gateway nécessitant des headers spécifiques
/// - Headers de routing ou de tenant
/// - Headers de traçabilité/debugging
void main() async {
  print('╔═══════════════════════════════════════════════════════════════╗');
  print('║  Exemple: Headers personnalisés                              ║');
  print('╚═══════════════════════════════════════════════════════════════╝\n');

  // ===================================================================
  // Exemple 1: Reverse Proxy (nginx, Apache)
  // ===================================================================
  print('📝 Exemple 1: Directus derrière un reverse proxy\n');

  final clientWithProxy = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://api.example.com',
      headers: {
        // Headers nécessaires pour le reverse proxy
        'X-Forwarded-Host': 'api.example.com',
        'X-Forwarded-Proto': 'https',
        'X-Real-IP': '192.168.1.1',

        // Ces headers seront inclus dans TOUTES les requêtes,
        // y compris le refresh automatique du token
      },
      enableLogging: true,
    ),
  );

  print('   Configuration:');
  print('   - Base URL: https://api.example.com');
  print('   - Headers: X-Forwarded-Host, X-Forwarded-Proto, X-Real-IP');
  print('   ✅ Le refresh du token inclura automatiquement ces headers\n');

  await clientWithProxy.dispose();

  // ===================================================================
  // Exemple 2: API Gateway
  // ===================================================================
  print('📝 Exemple 2: Directus derrière une API Gateway\n');

  final clientWithGateway = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://gateway.example.com/directus',
      headers: {
        // Headers pour l'API Gateway
        'X-API-Key': 'your-gateway-api-key-here',
        'X-Client-ID': 'your-client-id',
        'X-Client-Version': '1.0.0',

        // Ces headers permettent au Gateway d'identifier et router la requête
      },
      enableLogging: true,
    ),
  );

  print('   Configuration:');
  print('   - Base URL: https://gateway.example.com/directus');
  print('   - Headers: X-API-Key, X-Client-ID, X-Client-Version');
  print('   ✅ Le refresh du token passera par le Gateway avec ces headers\n');

  await clientWithGateway.dispose();

  // ===================================================================
  // Exemple 3: Multi-tenant avec headers
  // ===================================================================
  print('📝 Exemple 3: Application multi-tenant\n');

  final clientMultiTenant = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://api.example.com',
      headers: {
        // Headers pour identifier le tenant
        'X-Tenant-ID': 'tenant-abc-123',
        'X-Environment': 'production',
        'X-Region': 'eu-west-1',

        // Le serveur utilisera ces headers pour router vers la bonne base de données
      },
      enableLogging: true,
    ),
  );

  print('   Configuration:');
  print('   - Base URL: https://api.example.com');
  print('   - Headers: X-Tenant-ID, X-Environment, X-Region');
  print('   ✅ Le refresh du token utilisera le même tenant\n');

  await clientMultiTenant.dispose();

  // ===================================================================
  // Exemple 4: Headers de debugging/traçabilité
  // ===================================================================
  print('📝 Exemple 4: Traçabilité et debugging\n');

  final clientWithTracing = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://api.example.com',
      headers: {
        // Headers pour tracer les requêtes
        'X-Request-ID': 'req-${DateTime.now().millisecondsSinceEpoch}',
        'X-Client-Platform': 'flutter',
        'X-Client-OS': 'android',
        'X-App-Version': '2.1.0',

        // Utile pour le debugging et les logs serveur
      },
      enableLogging: true,
    ),
  );

  print('   Configuration:');
  print('   - Base URL: https://api.example.com');
  print('   - Headers: X-Request-ID, X-Client-Platform, X-Client-OS');
  print('   ✅ Toutes les requêtes sont tracées, y compris le refresh\n');

  await clientWithTracing.dispose();

  // ===================================================================
  // Exemple 5: Utilisation réelle avec authentification
  // ===================================================================
  print('📝 Exemple 5: Cas d\'usage complet avec authentification\n');

  final client = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://api.blue.fracos.fr',
      headers: {
        // Vos headers personnalisés ici
        'X-Client-Version': '1.0.0',
        'X-Platform': 'flutter-mobile',
      },
      enableLogging: true,
      onTokenRefreshed: (accessToken, refreshToken) async {
        print('   🔄 Token refreshed automatically!');
        print('      New access token: ${accessToken.substring(0, 20)}...');

        // Sauvegarder les nouveaux tokens
        // await storage.save('access_token', accessToken);
        // if (refreshToken != null) {
        //   await storage.save('refresh_token', refreshToken);
        // }
      },
    ),
  );

  try {
    print('   Tentative de connexion...');

    // Login (REMPLACEZ avec vos vraies credentials pour tester)
    // await client.auth.login(
    //   email: 'user@example.com',
    //   password: 'your-password',
    // );
    // print('   ✅ Authentification réussie\n');

    // // Faire une requête
    // final items = await client.items('your_collection').readMany();
    // print('   ✅ ${items.data.length} items récupérés\n');

    // // Si le token expire, il sera automatiquement refreshé
    // // avec les headers personnalisés inclus

    print(
      '   ℹ️  Décommentez le code pour tester avec de vraies credentials\n',
    );
  } catch (e) {
    print('   ❌ Erreur: $e\n');
  } finally {
    await client.dispose();
  }

  // ===================================================================
  // Résumé
  // ===================================================================
  print('╔═══════════════════════════════════════════════════════════════╗');
  print('║  🎯 Points clés                                               ║');
  print('╚═══════════════════════════════════════════════════════════════╝\n');
  print('   ✅ Les headers personnalisés sont définis dans DirectusConfig');
  print('   ✅ Ils sont inclus dans TOUTES les requêtes HTTP');
  print('   ✅ Ils sont AUSSI inclus dans le refresh automatique du token');
  print('   ✅ Ceci résout les erreurs 404 avec reverse proxies/gateways');
  print('   ✅ Parfait pour multi-tenant, traçabilité, debugging\n');

  print('📚 Documentation:');
  print('   - docs/FIX_404_REFRESH_TOKEN.md');
  print('   - docs/REFRESH_TOKEN_FIX.md');
  print('   - example/example_token_refresh_handling.dart\n');
}
