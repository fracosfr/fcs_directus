/// Librairie Dart/Flutter pour interagir avec l'API Directus.
///
/// Cette librairie fournit une interface complète pour communiquer avec
/// un serveur Directus via REST et WebSocket.
///
/// ## Utilisation de base
///
/// ```dart
/// import 'package:fcs_directus/fcs_directus.dart';
///
/// // Configuration
/// final config = DirectusConfig(
///   baseUrl: 'https://directus.example.com',
/// );
///
/// // Création du client
/// final client = DirectusClient(config);
///
/// // Authentification
/// await client.auth.login(
///   email: 'user@example.com',
///   password: 'password',
/// );
///
/// // Récupération de données
/// final articles = await client.items('articles').readMany();
///
/// // Libération des ressources
/// client.dispose();
/// ```
library;

// Core
export 'src/core/directus_client.dart';
export 'src/core/directus_config.dart';
export 'src/core/directus_http_client.dart';

// Services
export 'src/services/auth_service.dart';
export 'src/services/items_service.dart';
export 'src/services/collections_service.dart';
export 'src/services/users_service.dart';
export 'src/services/files_service.dart';

// Exceptions
export 'src/exceptions/directus_exception.dart';

// Models
export 'src/models/directus_model.dart';
export 'src/models/directus_filter.dart';
export 'src/models/directus_deep.dart';
export 'src/models/directus_aggregate.dart';
export 'src/models/directus_functions.dart';

// WebSocket
export 'src/websocket/directus_websocket_client.dart';
