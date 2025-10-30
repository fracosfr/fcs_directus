import 'directus_config.dart';
import 'directus_http_client.dart';
import '../services/auth_service.dart';
import '../services/items_service.dart';
import '../services/collections_service.dart';
import '../services/users_service.dart';
import '../services/files_service.dart';
import '../services/activity_service.dart';
import '../services/assets_service.dart';
import '../services/comments_service.dart';
import '../services/dashboards_service.dart';
import '../services/extensions_service.dart';
import '../services/fields_service.dart';
import '../services/flows_service.dart';
import '../services/folders_service.dart';
import '../services/notifications_service.dart';
import '../services/permissions_service.dart';
import '../services/presets_service.dart';
import '../services/relations_service.dart';
import '../services/revisions_service.dart';
import '../services/roles_service.dart';
import '../services/policies_service.dart';
import '../services/operations_service.dart';
import '../services/panels_service.dart';
import '../services/metrics_service.dart';
import '../services/schema_service.dart';
import '../services/server_service.dart';
import '../services/settings_service.dart';
import '../services/shares_service.dart';
import '../services/translations_service.dart';
import '../services/utilities_service.dart';
import '../services/versions_service.dart';
import '../models/directus_model.dart';

/// Client principal pour interagir avec l'API Directus.
///
/// Ce client fournit un accès à tous les services Directus disponibles.
///
/// Exemple d'utilisation:
/// ```dart
/// final client = DirectusClient(
///   DirectusConfig(baseUrl: 'https://directus.example.com'),
/// );
///
/// // Authentification
/// await client.auth.login(
///   email: 'user@example.com',
///   password: 'password',
/// );
///
/// // Récupérer des items avec le nom de collection
/// final items = await client.items('articles').readMany();
///
/// // Ou utiliser directement un modèle DirectusModel
/// final items = await client.itemsOf<Product>().readMany();
/// ```
class DirectusClient {
  final DirectusConfig config;
  late final DirectusHttpClient _httpClient;

  // Services
  late final AuthService auth;
  late final CollectionsService collections;
  late final UsersService users;
  late final FilesService files;
  late final ActivityService activity;
  late final AssetsService assets;
  late final CommentsService comments;
  late final DashboardsService dashboards;
  late final ExtensionsService extensions;
  late final FieldsService fields;
  late final FlowsService flows;
  late final FoldersService folders;
  late final NotificationsService notifications;
  late final PermissionsService permissions;
  late final PresetsService presets;
  late final RelationsService relations;
  late final RevisionsService revisions;
  late final RolesService roles;
  late final PoliciesService policies;
  late final OperationsService operations;
  late final PanelsService panels;
  late final MetricsService metrics;
  late final SchemaService schema;
  late final ServerService server;
  late final SettingsService settings;
  late final SharesService shares;
  late final TranslationsService translations;
  late final UtilitiesService utilities;
  late final VersionsService versions;

  /// Crée un nouveau client Directus
  DirectusClient(this.config) {
    _httpClient = DirectusHttpClient(config);

    // Initialisation des services
    auth = AuthService(_httpClient);
    collections = CollectionsService(_httpClient);
    users = UsersService(_httpClient);
    files = FilesService(_httpClient);
    activity = ActivityService(_httpClient);
    assets = AssetsService(_httpClient);
    comments = CommentsService(_httpClient);
    dashboards = DashboardsService(_httpClient);
    extensions = ExtensionsService(_httpClient);
    fields = FieldsService(_httpClient);
    flows = FlowsService(_httpClient);
    folders = FoldersService(_httpClient);
    notifications = NotificationsService(_httpClient);
    permissions = PermissionsService(_httpClient);
    presets = PresetsService(_httpClient);
    relations = RelationsService(_httpClient);
    revisions = RevisionsService(_httpClient);
    roles = RolesService(_httpClient);
    policies = PoliciesService(_httpClient);
    operations = OperationsService(_httpClient);
    panels = PanelsService(_httpClient);
    metrics = MetricsService(_httpClient);
    schema = SchemaService(_httpClient);
    server = ServerService(_httpClient);
    settings = SettingsService(_httpClient);
    shares = SharesService(_httpClient);
    translations = TranslationsService(_httpClient);
    utilities = UtilitiesService(_httpClient);
    versions = VersionsService(_httpClient);
  }

  /// Crée un service pour accéder aux items d'une collection spécifique
  ///
  /// [collection] Le nom de la collection
  ///
  /// Exemple:
  /// ```dart
  /// final articles = client.items('articles');
  /// final data = await articles.readMany();
  /// ```
  ItemsService<T> items<T>(String collection) {
    return ItemsService<T>(_httpClient, collection);
  }

  /// Crée un service pour accéder aux items d'une collection en utilisant un DirectusModel
  ///
  /// Le nom de la collection est automatiquement récupéré depuis le modèle via le getter `itemName`.
  ///
  /// Exemple:
  /// ```dart
  /// class Product extends DirectusModel {
  ///   @override
  ///   String get itemName => 'products';
  ///
  ///   Product(super.data);
  ///   // ...
  /// }
  ///
  /// // Utilisation
  /// final products = client.itemsOf<Product>();
  /// final allProducts = await products.readMany();
  /// ```
  ItemsService<T> itemsOf<T extends DirectusModel>() {
    // Récupérer le itemName depuis une instance du modèle
    // Note: Dart ne permet pas d'accéder directement aux membres statiques via les types génériques
    // On doit donc créer une instance temporaire via la factory
    final factory = DirectusModel.getFactory<T>();
    if (factory == null) {
      throw StateError(
        'No factory registered for type $T. '
        'Please register a factory using DirectusModel.registerFactory<$T>(...)',
      );
    }

    // Créer une instance temporaire avec un objet vide pour obtenir le itemName
    final tempInstance = factory({}) as T;
    final collection = tempInstance.itemName;

    return ItemsService<T>(_httpClient, collection);
  }

  /// Ferme le client et libère les ressources
  void dispose() {
    _httpClient.close();
  }
}
