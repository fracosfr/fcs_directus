import 'directus_config.dart';
import 'directus_http_client.dart';
import '../services/auth_service.dart';
import '../services/items_service.dart';
import '../services/collections_service.dart';
import '../services/users_service.dart';
import '../services/files_service.dart';

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
/// // Récupérer des items
/// final items = await client.items('articles').readMany();
/// ```
class DirectusClient {
  final DirectusConfig config;
  late final DirectusHttpClient _httpClient;

  // Services
  late final AuthService auth;
  late final CollectionsService collections;
  late final UsersService users;
  late final FilesService files;

  /// Crée un nouveau client Directus
  DirectusClient(this.config) {
    _httpClient = DirectusHttpClient(config);

    // Initialisation des services
    auth = AuthService(_httpClient);
    collections = CollectionsService(_httpClient);
    users = UsersService(_httpClient);
    files = FilesService(_httpClient);
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

  /// Ferme le client et libère les ressources
  void dispose() {
    _httpClient.close();
  }
}
