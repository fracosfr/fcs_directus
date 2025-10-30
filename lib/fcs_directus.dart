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
export 'src/services/roles_service.dart';
export 'src/services/policies_service.dart';
export 'src/services/activity_service.dart';
export 'src/services/assets_service.dart';
export 'src/services/comments_service.dart';
export 'src/services/dashboards_service.dart';
export 'src/services/extensions_service.dart';
export 'src/services/fields_service.dart';
export 'src/services/flows_service.dart';
export 'src/services/folders_service.dart';
export 'src/services/notifications_service.dart';
export 'src/services/permissions_service.dart';
export 'src/services/presets_service.dart';
export 'src/services/relations_service.dart';
export 'src/services/revisions_service.dart';
export 'src/services/operations_service.dart';
export 'src/services/panels_service.dart';
export 'src/services/metrics_service.dart';
export 'src/services/schema_service.dart';
export 'src/services/server_service.dart';
export 'src/services/settings_service.dart';
export 'src/services/shares_service.dart';
export 'src/services/translations_service.dart';
export 'src/services/utilities_service.dart';
export 'src/services/versions_service.dart';

// Exceptions
export 'src/exceptions/directus_exception.dart';

// Models
export 'src/models/directus_model.dart';
export 'src/models/directus_property.dart';
export 'src/models/directus_filter.dart';
export 'src/models/directus_deep.dart';
export 'src/models/directus_aggregate.dart';
export 'src/models/directus_functions.dart';
export 'src/models/directus_user.dart';
export 'src/models/directus_role.dart';
export 'src/models/directus_policy.dart';
export 'src/models/directus_activity.dart';
export 'src/models/directus_revision.dart';
export 'src/models/directus_comment.dart';
export 'src/models/directus_dashboard.dart';
export 'src/models/directus_panel.dart';
export 'src/models/directus_field.dart';
export 'src/models/directus_flow.dart';
export 'src/models/directus_operation.dart';
export 'src/models/directus_folder.dart';
export 'src/models/directus_notification.dart';
export 'src/models/directus_permission.dart';
export 'src/models/directus_preset.dart';
export 'src/models/directus_relation.dart';
export 'src/models/asset_transforms.dart';

// WebSocket
export 'src/websocket/directus_websocket_client.dart';
