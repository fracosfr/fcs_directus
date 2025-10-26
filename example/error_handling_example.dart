/// Exemple d'utilisation de la gestion complète des erreurs Directus
///
/// Cet exemple montre comment gérer tous les types d'erreurs Directus
/// avec les 31 codes d'erreur officiels implémentés.

import 'package:fcs_directus/fcs_directus.dart';

void main() async {
  final directus = DirectusClient(
    DirectusConfig(baseUrl: 'https://your-directus-instance.com'),
  );

  // Exemple 1: Gestion spécifique par type d'exception
  print('\n--- Exemple 1: Gestion par type ---');
  await handleSpecificErrors(directus);

  // Exemple 2: Utilisation de l'enum DirectusErrorCode
  print('\n--- Exemple 2: Utilisation de DirectusErrorCode ---');
  await handleWithErrorCodes(directus);

  // Exemple 3: Accès aux extensions d'erreur
  print('\n--- Exemple 3: Accès aux extensions ---');
  await handleWithExtensions(directus);

  // Exemple 4: Gestion globale des erreurs
  print('\n--- Exemple 4: Gestion globale ---');
  await globalErrorHandler(directus);

  // Exemple 5: Retry automatique pour rate limiting
  print('\n--- Exemple 5: Retry automatique ---');
  await retryOnRateLimit(directus);

  // Exemple 6: Gestion d'erreurs d'authentification
  print('\n--- Exemple 6: Erreurs d\'authentification ---');
  await handleAuthErrors(directus);

  // Exemple 7: Gestion d'erreurs de validation
  print('\n--- Exemple 7: Erreurs de validation ---');
  await handleValidationErrors(directus);

  // Exemple 8: Gestion d'erreurs de base de données
  print('\n--- Exemple 8: Erreurs de base de données ---');
  await handleDatabaseErrors(directus);
}

/// Exemple 1: Gestion spécifique par type d'exception
Future<void> handleSpecificErrors(DirectusClient directus) async {
  try {
    await directus.items('articles').readOne('invalid-id');
  } on DirectusNotFoundException catch (e) {
    // ROUTE_NOT_FOUND
    print('✗ Article non trouvé: ${e.message}');
    print('  Code: ${e.errorCode}');
  } on DirectusAuthException catch (e) {
    // INVALID_CREDENTIALS, TOKEN_EXPIRED, INVALID_OTP, USER_SUSPENDED
    print('✗ Erreur d\'authentification: ${e.message}');
    print('  Code: ${e.errorCode}');
  } on DirectusValidationException catch (e) {
    // INVALID_PAYLOAD, INVALID_QUERY, VALUE_TOO_LONG, etc.
    print('✗ Erreur de validation: ${e.message}');
    if (e.fieldErrors != null) {
      e.fieldErrors!.forEach((field, errors) {
        print('  $field: ${errors.join(", ")}');
      });
    }
  } on DirectusPermissionException catch (e) {
    // FORBIDDEN
    print('✗ Accès refusé: ${e.message}');
    print('  Vous n\'avez pas les permissions nécessaires');
  } on DirectusRateLimitException catch (e) {
    // REQUESTS_EXCEEDED, EMAIL_LIMIT_EXCEEDED, LIMIT_EXCEEDED
    print('✗ Trop de requêtes: ${e.message}');
    print('  Veuillez réessayer dans quelques minutes');
  } on DirectusNetworkException catch (e) {
    print('✗ Erreur réseau: ${e.message}');
    print('  Vérifiez votre connexion internet');
  } on DirectusServerException catch (e) {
    // INTERNAL_SERVER_ERROR, SERVICE_UNAVAILABLE, OUT_OF_DATE
    print('✗ Erreur serveur: ${e.message}');
    print('  Code: ${e.errorCode}, Status: ${e.statusCode}');
  } on DirectusException catch (e) {
    // Toutes les autres erreurs
    print('✗ Erreur Directus: ${e.message}');
    print('  Code: ${e.errorCode}, Status: ${e.statusCode}');
  }
}

/// Exemple 2: Utilisation de l'enum DirectusErrorCode
Future<void> handleWithErrorCodes(DirectusClient directus) async {
  try {
    // Tentative de connexion avec un token expiré
    await directus.auth.refresh();
  } on DirectusException catch (e) {
    if (e.errorCode == DirectusErrorCode.tokenExpired.code) {
      print('✗ Token expiré, reconnexion nécessaire');
      // Rediriger vers la page de connexion
      // navigateToLogin();
    } else if (e.errorCode == DirectusErrorCode.invalidToken.code) {
      print('✗ Token invalide');
    } else if (e.errorCode == DirectusErrorCode.userSuspended.code) {
      print('✗ Compte suspendu');
      // Afficher un message spécifique
    } else {
      print('✗ Erreur d\'authentification: ${e.message}');
    }
  }
}

/// Exemple 3: Accès aux extensions d'erreur
Future<void> handleWithExtensions(DirectusClient directus) async {
  try {
    // Tentative de création d'un doublon
    await directus.items('users').createOne({'email': 'existing@example.com'});
  } on DirectusDatabaseException catch (e) {
    if (e.errorCode == DirectusErrorCode.recordNotUnique.code) {
      print('✗ Enregistrement en double');
      print('  Collection: ${e.collection}');
      print('  Champ: ${e.field}');
      print('  Message: ${e.message}');
    }
  } on DirectusException catch (e) {
    print('✗ Erreur: ${e.message}');
    // Accès direct aux extensions
    if (e.extensions != null) {
      print('  Extensions: ${e.extensions}');
    }
  }
}

/// Exemple 4: Gestion globale des erreurs
Future<void> globalErrorHandler(DirectusClient directus) async {
  try {
    await directus.items('products').readMany();
  } catch (e) {
    handleGlobalError(e);
  }
}

void handleGlobalError(dynamic error) {
  if (error is DirectusAuthException) {
    // Erreurs d'authentification -> Rediriger vers login
    print('→ Redirection vers la page de connexion');
  } else if (error is DirectusPermissionException) {
    // Erreurs de permission -> Page d'accès refusé
    print('→ Afficher page d\'accès refusé');
  } else if (error is DirectusValidationException) {
    // Erreurs de validation -> Afficher les erreurs de formulaire
    print('→ Afficher les erreurs de validation');
    if (error.fieldErrors != null) {
      error.fieldErrors!.forEach((field, errors) {
        print('  $field: ${errors.join(", ")}');
      });
    }
  } else if (error is DirectusNetworkException) {
    // Erreurs réseau -> Afficher notification offline
    print('→ Mode hors ligne activé');
  } else if (error is DirectusServerException) {
    // Erreurs serveur -> Afficher message maintenance
    print('→ Le service est temporairement indisponible');
  } else if (error is DirectusRateLimitException) {
    // Rate limit -> Afficher message d'attente
    print('→ Trop de requêtes, veuillez patienter');
  } else if (error is DirectusException) {
    // Autres erreurs Directus
    print('→ Erreur: ${error.message}');
  } else {
    // Erreurs non-Directus
    print('→ Erreur inattendue: $error');
  }
}

/// Exemple 5: Retry automatique pour rate limiting
Future<T> retryOnRateLimit<T>(
  DirectusClient directus, {
  int maxRetries = 3,
  Duration initialDelay = const Duration(seconds: 30),
}) async {
  int attempts = 0;
  Duration delay = initialDelay;

  while (attempts < maxRetries) {
    try {
      // Exemple d'opération
      return await directus.items('articles').readMany() as T;
    } on DirectusRateLimitException catch (e) {
      attempts++;
      if (attempts >= maxRetries) {
        print('✗ Nombre maximum de tentatives atteint');
        rethrow;
      }
      print('⏱ Rate limit atteint, attente de ${delay.inSeconds}s...');
      print('  Code: ${e.errorCode}');
      await Future.delayed(delay);
      delay = delay * 2; // Backoff exponentiel
    }
  }

  throw Exception('Opération échouée après $maxRetries tentatives');
}

/// Exemple 6: Gestion d'erreurs d'authentification
Future<void> handleAuthErrors(DirectusClient directus) async {
  try {
    await directus.auth.login(
      email: 'user@example.com',
      password: 'wrong_password',
    );
  } on DirectusAuthException catch (e) {
    switch (e.errorCode) {
      case 'INVALID_CREDENTIALS':
        print('✗ Email ou mot de passe incorrect');
        print('  Veuillez vérifier vos identifiants');
        break;
      case 'USER_SUSPENDED':
        print('✗ Compte suspendu');
        print('  Contactez l\'administrateur');
        break;
      case 'INVALID_OTP':
        print('✗ Code d\'authentification à deux facteurs invalide');
        print('  Veuillez réessayer');
        break;
      case 'TOKEN_EXPIRED':
        print('✗ Session expirée');
        print('  Reconnexion nécessaire');
        // Auto-refresh si possible
        try {
          await directus.auth.refresh();
          print('✓ Session rafraîchie avec succès');
        } catch (refreshError) {
          print('✗ Impossible de rafraîchir la session');
          // Rediriger vers login
        }
        break;
      default:
        print('✗ Erreur d\'authentification: ${e.message}');
    }
  }
}

/// Exemple 7: Gestion d'erreurs de validation
Future<void> handleValidationErrors(DirectusClient directus) async {
  try {
    await directus.items('products').createOne({
      'name': '', // Vide
      'price': -10, // Négatif
      'email': 'invalid-email', // Email invalide
    });
  } on DirectusValidationException catch (e) {
    print('✗ Erreurs de validation détectées:');
    print('  Message: ${e.message}');
    print('  Code: ${e.errorCode}');

    // Afficher les erreurs par champ
    if (e.fieldErrors != null && e.fieldErrors!.isNotEmpty) {
      print('\n  Erreurs par champ:');
      e.fieldErrors!.forEach((field, errors) {
        print('    • $field:');
        for (var error in errors) {
          print('      - $error');
        }
      });
    }

    // Mapper les codes d'erreur vers des messages utilisateur
    switch (e.errorCode) {
      case 'INVALID_PAYLOAD':
        print('\n  → Données invalides envoyées au serveur');
        break;
      case 'VALUE_TOO_LONG':
        print('\n  → Une ou plusieurs valeurs sont trop longues');
        break;
      case 'VALUE_OUT_OF_RANGE':
        print('\n  → Une ou plusieurs valeurs sont hors limites');
        break;
      case 'NOT_NULL_VIOLATION':
        print('\n  → Un champ obligatoire est manquant');
        break;
      case 'CONTAINS_NULL_VALUES':
        print('\n  → Des valeurs nulles ne sont pas autorisées');
        break;
    }
  }
}

/// Exemple 8: Gestion d'erreurs de base de données
Future<void> handleDatabaseErrors(DirectusClient directus) async {
  try {
    await directus.items('orders').createOne({
      'product_id': 'non-existent-id',
      'customer_email': 'duplicate@example.com',
    });
  } on DirectusDatabaseException catch (e) {
    print('✗ Erreur de base de données:');
    print('  Code: ${e.errorCode}');
    print('  Message: ${e.message}');

    switch (e.errorCode) {
      case 'INVALID_FOREIGN_KEY':
        print('\n  Détails:');
        print('    Collection: ${e.collection}');
        print('    Champ: ${e.field}');
        print('    → La référence n\'existe pas');
        print('    → Vérifiez que l\'ID référencé est valide');
        break;

      case 'RECORD_NOT_UNIQUE':
        print('\n  Détails:');
        print('    Collection: ${e.collection}');
        print('    Champ: ${e.field}');
        print('    → Cette valeur est déjà utilisée');
        print('    → Utilisez une valeur unique');
        break;
    }
  } on DirectusValidationException catch (e) {
    // Les contraintes de base de données peuvent aussi générer
    // des erreurs de validation
    print('✗ Contrainte de validation:');
    print('  Code: ${e.errorCode}');
    print('  Message: ${e.message}');
  }
}

/// Exemple bonus: Wrapper de fonction avec gestion d'erreur
Future<T?> safeExecute<T>({
  required Future<T> Function() operation,
  required void Function(DirectusException) onError,
  T? Function()? onNetworkError,
}) async {
  try {
    return await operation();
  } on DirectusNetworkException catch (e) {
    print('⚠ Erreur réseau: ${e.message}');
    return onNetworkError?.call();
  } on DirectusException catch (e) {
    onError(e);
    return null;
  }
}

/// Exemple d'utilisation du wrapper
Future<void> useSafeExecute(DirectusClient directus) async {
  final result = await safeExecute<Map<String, dynamic>>(
    operation: () async {
      final data = await directus.items('articles').readOne('some-id');
      return data as Map<String, dynamic>;
    },
    onError: (e) {
      print('Erreur lors de la récupération: ${e.message}');
      // Logger, afficher notification, etc.
    },
    onNetworkError: () {
      print('Mode hors ligne - utilisation du cache');
      // Retourner des données en cache
      return {'id': 'cached', 'title': 'Article en cache'};
    },
  );

  if (result != null) {
    print('Article récupéré: ${result['title']}');
  }
}
