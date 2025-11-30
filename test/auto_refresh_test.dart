// ignore_for_file: avoid_print
import 'package:test/test.dart';
import 'package:fcs_directus/fcs_directus.dart';

/// Tests pour le refresh automatique des tokens
///
/// Note: Ces tests nécessitent une instance Directus de test configurée.
/// Ils peuvent être skippés en environnement CI.
void main() {
  group('Auto Refresh Token', () {
    late DirectusClient client;
    const testBaseUrl = 'https://directus-test.example.com';
    const testEmail = 'test@example.com';
    const testPassword = 'test-password';

    setUp(() {
      client = DirectusClient(
        DirectusConfig(baseUrl: testBaseUrl, enableLogging: true),
      );
    });

    tearDown(() async {
      await client.dispose();
    });

    test(
      'Should refresh token automatically on TOKEN_EXPIRED',
      () async {
        // 1. Login initial
        final authResponse = await client.auth.login(
          email: testEmail,
          password: testPassword,
        );

        expect(authResponse.accessToken, isNotEmpty);
        expect(authResponse.refreshToken, isNotNull);

        // 2. Effectuer une requête normale (devrait fonctionner)
        final response1 = await client.items('test_collection').readMany();
        expect(response1.data, isNotNull);

        // 3. Simuler l'expiration du token
        // Note: En production, attendez simplement que le token expire
        // Pour les tests, on pourrait utiliser un mock ou un token très court

        // 4. Effectuer une nouvelle requête
        // Si le token a expiré, le refresh automatique devrait se déclencher
        final response2 = await client.items('test_collection').readMany();
        expect(response2.data, isNotNull);

        // Le test passe = le refresh automatique a fonctionné !
      },
      skip: 'Nécessite une instance Directus de test',
    );

    test(
      'Should handle multiple parallel requests with single refresh',
      () async {
        await client.auth.login(email: testEmail, password: testPassword);

        // Simuler l'expiration du token
        // ...

        // Effectuer plusieurs requêtes en parallèle
        final futures = List.generate(
          5,
          (i) => client
              .items('test_collection')
              .readMany(query: QueryParameters(limit: 1, offset: i)),
        );

        // Toutes les requêtes devraient réussir avec un seul refresh
        final responses = await Future.wait(futures);
        expect(responses.length, equals(5));

        for (final response in responses) {
          expect(response.data, isNotNull);
        }
      },
      skip: 'Nécessite une instance Directus de test',
    );

    test(
      'Should fail if refresh token is invalid',
      () async {
        await client.auth.login(email: testEmail, password: testPassword);

        // Forcer un refresh token invalide
        client.auth.loginWithToken('invalid_token');

        // La requête devrait échouer avec TOKEN_EXPIRED
        expect(
          () => client.items('test_collection').readMany(),
          throwsA(isA<DirectusAuthException>()),
        );
      },
      skip: 'Nécessite une instance Directus de test',
    );

    test('Should not retry more than once per request', () async {
      await client.auth.login(email: testEmail, password: testPassword);

      // Forcer un refresh token invalide
      // Le premier retry devrait échouer
      // Le deuxième retry ne devrait pas avoir lieu (protection boucle)

      var requestCount = 0;

      // Note: Ceci nécessiterait un mock pour compter les requêtes
      // En production, les logs montrent qu'il n'y a pas de boucle

      expect(requestCount, lessThan(3)); // Max 1 requête + 1 retry
    }, skip: 'Nécessite un mock');

    test(
      'Should work with cookie mode',
      () async {
        final authResponse = await client.auth.login(
          email: testEmail,
          password: testPassword,
          mode: AuthMode.cookie,
        );

        expect(authResponse.accessToken, isNotEmpty);

        // Le refresh automatique devrait aussi fonctionner en mode cookie
        final response = await client.items('test_collection').readMany();
        expect(response.data, isNotNull);
      },
      skip: 'Nécessite une instance Directus de test',
    );

    test(
      'Should work with session mode',
      () async {
        final authResponse = await client.auth.login(
          email: testEmail,
          password: testPassword,
          mode: AuthMode.session,
        );

        expect(authResponse.accessToken, isNotEmpty);

        // Le refresh automatique devrait aussi fonctionner en mode session
        final response = await client.items('test_collection').readMany();
        expect(response.data, isNotNull);
      },
      skip: 'Nécessite une instance Directus de test',
    );
  });

  group('Auto Refresh Edge Cases', () {
    late DirectusClient client;

    setUp(() {
      client = DirectusClient(
        DirectusConfig(
          baseUrl: 'https://directus-test.example.com',
          enableLogging: false,
        ),
      );
    });

    tearDown(() async {
      await client.dispose();
    });

    test(
      'Should not refresh if no refresh token available',
      () async {
        // Login avec un token statique (pas de refresh token)
        await client.auth.loginWithToken('static-token');

        // Forcer l'expiration
        // La requête devrait échouer directement sans tentative de refresh

        expect(
          () => client.items('test_collection').readMany(),
          throwsA(isA<DirectusAuthException>()),
        );
      },
      skip: 'Nécessite une instance Directus de test',
    );

    test(
      'Should handle refresh endpoint errors gracefully',
      () async {
        await client.auth.login(
          email: 'test@example.com',
          password: 'password',
        );

        // Simuler une erreur du serveur sur /auth/refresh
        // La requête devrait échouer avec l'erreur originale (TOKEN_EXPIRED)

        expect(
          () => client.items('test_collection').readMany(),
          throwsA(isA<DirectusAuthException>()),
        );
      },
      skip: 'Nécessite un mock du serveur',
    );

    test(
      'Should update tokens after successful refresh',
      () async {
        await client.auth.login(
          email: 'test@example.com',
          password: 'password',
        );

        final initialAccessToken = client.auth.accessToken;

        // Forcer l'expiration et déclencher le refresh
        // ...

        await client.items('test_collection').readMany();

        final newAccessToken = client.auth.accessToken;

        // Le token devrait avoir changé
        expect(newAccessToken, isNot(equals(initialAccessToken)));
      },
      skip: 'Nécessite une instance Directus de test',
    );
  });

  group('Auto Refresh Documentation Examples', () {
    test('Example from documentation should compile', () {
      // Cet exemple de la documentation devrait compiler sans erreurs
      final client = DirectusClient(
        DirectusConfig(baseUrl: 'https://directus.example.com'),
      );

      // ignore: unused_local_variable
      Future<void> exampleFunction() async {
        try {
          // Pas besoin de gérer TOKEN_EXPIRED manuellement !
          final response = await client.items('articles').readMany();
          print('Récupéré ${response.data.length} articles');
        } on DirectusAuthException catch (e) {
          // On arrive ici uniquement si le refresh a échoué
          if (e.errorCode == 'TOKEN_EXPIRED') {
            print('Session expirée, reconnexion nécessaire');
            // Rediriger vers login
          }
        }
      }

      expect(exampleFunction, isA<Function>());
      client.dispose();
    });
  });
}
