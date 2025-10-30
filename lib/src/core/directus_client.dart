import 'directus_config.dart';
import 'directus_http_client.dart';
import '../services/auth_service.dart';
import '../services/items_service.dart';
import '../services/collections_service.dart';
import '../services/users_service.dart';
import '../services/files_service.dart';
import '../services/activity_service.dart';
import '../services/assets_service.dart';
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
