import '../core/directus_http_client.dart';
import 'items_service.dart';

/// Service pour gérer les utilisateurs Directus.
///
/// Permet de gérer les utilisateurs du système.
class UsersService {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  UsersService(this._httpClient) {
    _itemsService = ItemsService(_httpClient, 'directus_users');
  }

  /// Récupère la liste des utilisateurs
  Future<DirectusResponse<dynamic>> getUsers({QueryParameters? query}) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère un utilisateur par son ID
  Future<Map<String, dynamic>> getUser(
    String id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id, query: query);
  }

  /// Récupère l'utilisateur actuellement connecté
  Future<Map<String, dynamic>> me({QueryParameters? query}) async {
    final response = await _httpClient.get(
      '/users/me',
      queryParameters: query?.toQueryParameters(),
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Crée un nouvel utilisateur
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    return await _itemsService.createOne(data);
  }

  /// Met à jour un utilisateur
  Future<Map<String, dynamic>> updateUser(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateOne(id, data);
  }

  /// Met à jour l'utilisateur connecté
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async {
    final response = await _httpClient.patch('/users/me', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Supprime un utilisateur
  Future<void> deleteUser(String id) async {
    await _itemsService.deleteOne(id);
  }

  /// Invite un ou plusieurs utilisateurs
  ///
  /// [emails] Liste des emails à inviter
  /// [roleId] ID du rôle à assigner
  Future<void> inviteUsers({
    required List<String> emails,
    required String roleId,
  }) async {
    await _httpClient.post(
      '/users/invite',
      data: {'email': emails, 'role': roleId},
    );
  }

  /// Accepte une invitation utilisateur
  ///
  /// [token] Token d'invitation
  /// [password] Mot de passe choisi par l'utilisateur
  Future<void> acceptInvite({
    required String token,
    required String password,
  }) async {
    await _httpClient.post(
      '/users/invite/accept',
      data: {'token': token, 'password': password},
    );
  }
}
