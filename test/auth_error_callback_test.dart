// ignore_for_file: non_constant_identifier_names, avoid_print, unused_local_variable
import 'package:fcs_directus/fcs_directus.dart';
import 'package:test/test.dart';

void main() {
  group('DirectusConfig onAuthError callback', () {
    test('should accept onAuthError callback in constructor', () {
      DirectusAuthException? capturedError;

      final config = DirectusConfig(
        baseUrl: 'https://directus.example.com',
        onAuthError: (exception) async {
          capturedError = exception;
        },
      );

      expect(config.onAuthError, isNotNull);
      expect(config.baseUrl, equals('https://directus.example.com'));
    });

    test('should include onAuthError in copyWith', () {
      DirectusAuthException? error1;
      DirectusAuthException? error2;

      final config1 = DirectusConfig(
        baseUrl: 'https://directus.example.com',
        onAuthError: (exception) async {
          error1 = exception;
        },
      );

      final config2 = config1.copyWith(
        onAuthError: (exception) async {
          error2 = exception;
        },
      );

      expect(config1.onAuthError, isNotNull);
      expect(config2.onAuthError, isNotNull);
      expect(config2.onAuthError, isNot(equals(config1.onAuthError)));
    });

    test('should preserve onAuthError when copying without it', () {
      DirectusAuthException? capturedError;

      final config1 = DirectusConfig(
        baseUrl: 'https://directus.example.com',
        onAuthError: (exception) async {
          capturedError = exception;
        },
      );

      final config2 = config1.copyWith(enableLogging: true);

      expect(config2.onAuthError, equals(config1.onAuthError));
      expect(config2.enableLogging, isTrue);
    });

    test('should allow null onAuthError', () {
      final config = DirectusConfig(
        baseUrl: 'https://directus.example.com',
        // onAuthError non fourni
      );

      expect(config.onAuthError, isNull);
    });

    test('should work alongside onTokenRefreshed callback', () {
      String? refreshedAccessToken;
      DirectusAuthException? authError;

      final config = DirectusConfig(
        baseUrl: 'https://directus.example.com',
        onTokenRefreshed: (accessToken, refreshToken) async {
          refreshedAccessToken = accessToken;
        },
        onAuthError: (exception) async {
          authError = exception;
        },
      );

      expect(config.onTokenRefreshed, isNotNull);
      expect(config.onAuthError, isNotNull);
    });

    test('callback should be callable with DirectusAuthException', () async {
      DirectusAuthException? capturedError;
      bool callbackCalled = false;

      final config = DirectusConfig(
        baseUrl: 'https://directus.example.com',
        onAuthError: (exception) async {
          capturedError = exception;
          callbackCalled = true;
        },
      );

      // Simuler l'appel du callback
      final testException = DirectusAuthException(
        message: 'Token refresh failed',
        errorCode: 'TOKEN_REFRESH_FAILED',
        statusCode: 401,
      );

      await config.onAuthError!(testException);

      expect(callbackCalled, isTrue);
      expect(capturedError, equals(testException));
      expect(capturedError?.errorCode, equals('TOKEN_REFRESH_FAILED'));
      expect(capturedError?.statusCode, equals(401));
    });

    test('callback should handle different error codes', () async {
      final errors = <String>[];

      final config = DirectusConfig(
        baseUrl: 'https://directus.example.com',
        onAuthError: (exception) async {
          errors.add(exception.errorCode ?? 'UNKNOWN');
        },
      );

      // Simuler plusieurs types d'erreurs
      await config.onAuthError!(
        DirectusAuthException(
          message: 'Invalid credentials',
          errorCode: 'INVALID_CREDENTIALS',
        ),
      );

      await config.onAuthError!(
        DirectusAuthException(
          message: 'Token expired',
          errorCode: 'TOKEN_EXPIRED',
        ),
      );

      await config.onAuthError!(
        DirectusAuthException(
          message: 'User suspended',
          errorCode: 'USER_SUSPENDED',
        ),
      );

      expect(errors, hasLength(3));
      expect(errors, contains('INVALID_CREDENTIALS'));
      expect(errors, contains('TOKEN_EXPIRED'));
      expect(errors, contains('USER_SUSPENDED'));
    });

    test('callback can be async', () async {
      bool asyncOperationCompleted = false;

      final config = DirectusConfig(
        baseUrl: 'https://directus.example.com',
        onAuthError: (exception) async {
          // Simuler une opération async (ex: navigation, storage)
          await Future.delayed(Duration(milliseconds: 10));
          asyncOperationCompleted = true;
        },
      );

      final exception = DirectusAuthException(
        message: 'Test error',
        errorCode: 'TEST_ERROR',
      );

      await config.onAuthError!(exception);

      expect(asyncOperationCompleted, isTrue);
    });
  });
}
