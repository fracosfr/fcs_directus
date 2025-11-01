import '../core/directus_http_client.dart';
import 'item_active_service.dart';
// ...existing code...
import '../models/directus_user.dart';
import '../models/directus_model.dart';
import 'items_service.dart';

/// Service pour gérer les utilisateurs Directus.
///
/// Permet de gérer tous les aspects des utilisateurs :
/// - CRUD (Create, Read, Update, Delete)
/// - Opérations sur l'utilisateur courant (/me)
/// - Invitations et enregistrement
/// - Two-Factor Authentication (2FA)
/// - Gestion des sessions et préférences
///
/// Exemple d'utilisation :
/// ```dart
/// final users = client.users;
///
/// // Récupérer tous les utilisateurs
/// final allUsers = await users.getUsers();
///
/// // Récupérer l'utilisateur courant
/// final me = await users.me();
///
/// // Créer un nouvel utilisateur
/// final newUser = await users.createUser(DirectusUser.empty()
///   ..email.set('user@example.com')
///   ..password.set('secure123')
///   ..firstName.set('John')
///   ..role.set('role-id'));
///
/// // Inviter des utilisateurs
/// await users.inviteUsers(
///   emails: ['user1@example.com', 'user2@example.com'],
///   roleId: 'role-id',
/// );
///
/// // Activer la 2FA
/// final tfa = await users.generateTwoFactorSecret();
/// await users.enableTwoFactor(secret: tfa['secret'], otp: '123456');
/// ```
class UsersService {
  final DirectusHttpClient _httpClient;
  // ...existing code...
  UsersService(this._httpClient);

  ItemActiveService<T> _activeService<T extends DirectusModel>() =>
      ItemActiveService<T>(_httpClient, 'directus_users');

  // ========================================
  // Opérations CRUD de base
  // ========================================

  /// Récupère la liste des utilisateurs typés
  ///
  /// Supporte tous les paramètres de query (filter, sort, fields, etc.)
  Future<DirectusResponse<T>> getUsers<T extends DirectusUser>({
    QueryParameters? query,
  }) async {
    return await _activeService<T>().readMany(query: query);
  }

  /// Récupère un utilisateur par son ID typé
  Future<T> getUser<T extends DirectusUser>(
    String id, {
    QueryParameters? query,
  }) async {
    return await _activeService<T>().readOne(id, query: query);
  }

  /// Crée un nouvel utilisateur typé
  Future<T> createUser<T extends DirectusUser>(
    T user, {
    QueryParameters? query,
  }) async {
    final response = await _httpClient.post(
      '/users',
      data: user.toJson(),
      queryParameters: query?.toQueryParameters(),
    );

    final factory =
        DirectusModel.getFactory<T>() ??
        DirectusUser.factory as T Function(Map<String, dynamic>);
    return factory((response.data?['data'] ?? {}) as Map<String, dynamic>) as T;
  }

  /// Crée plusieurs utilisateurs typés en une seule requête
  Future<List<T>> createUsers<T extends DirectusUser>(
    List<T> users, {
    QueryParameters? query,
  }) async {
    final response = await _httpClient.post(
      '/users',
      data: users.map((u) => u.toJson()).toList(),
      queryParameters: query?.toQueryParameters(),
    );
    final factory =
        DirectusModel.getFactory<T>() ??
        DirectusUser.factory as T Function(Map<String, dynamic>);
    final data = (response.data?['data']) ?? [];
    if (data is List) {
      return data
          .map<T>((item) => factory(item as Map<String, dynamic>) as T)
          .toList();
    }
    return [factory(data as Map<String, dynamic>) as T];
  }

  /// Met à jour un utilisateur typé
  Future<T> updateUser<T extends DirectusUser>(
    T user, {
    QueryParameters? query,
  }) async {
    if (user.id == null) {
      throw ArgumentError(
        'L\'utilisateur doit avoir un id pour être mis à jour.',
      );
    }
    final response = await _httpClient.patch(
      '/users/${user.id}',
      data: user.toJsonDirty(),
      queryParameters: query?.toQueryParameters(),
    );
    final factory =
        DirectusModel.getFactory<T>() ??
        DirectusUser.factory as T Function(Map<String, dynamic>);
    return factory(response.data?['data'] ?? {} as Map<String, dynamic>) as T;
  }

  /// Met à jour plusieurs utilisateurs typés
  Future<List<T>> updateUsers<T extends DirectusUser>(
    List<T> users, {
    QueryParameters? query,
  }) async {
    final ids = users.map((u) => u.id).whereType<String>().toList();
    if (ids.length != users.length) {
      throw ArgumentError(
        'Tous les utilisateurs doivent avoir un id pour être mis à jour.',
      );
    }
    final payload = users.map((u) {
      final dirty = u.toJsonDirty();
      dirty['id'] = u.id;
      return dirty;
    }).toList();
    final response = await _httpClient.patch(
      '/users',
      data: payload,
      queryParameters: query?.toQueryParameters(),
    );
    final factory =
        DirectusModel.getFactory<T>() ??
        DirectusUser.factory as T Function(Map<String, dynamic>);
    final responseData = response.data?['data'] ?? [];
    if (responseData is List) {
      return responseData
          .map<T>((item) => factory(item as Map<String, dynamic>) as T)
          .toList();
    }
    return [factory(responseData as Map<String, dynamic>) as T];
  }

  /// Supprime un utilisateur typé
  Future<void> deleteUser<T extends DirectusUser>(T user) async {
    if (user.id == null) {
      throw ArgumentError(
        'L\'utilisateur doit avoir un id pour être supprimé.',
      );
    }
    await _httpClient.delete('/users/${user.id}');
  }

  /// Supprime plusieurs utilisateurs typés
  Future<void> deleteUsers<T extends DirectusUser>(List<T> users) async {
    final ids = users.map((u) => u.id).whereType<String>().toList();
    if (ids.length != users.length) {
      throw ArgumentError(
        'Tous les utilisateurs doivent avoir un id pour être supprimés.',
      );
    }
    await _httpClient.delete('/users', data: ids);
  }

  // ========================================
  // Opérations sur l'utilisateur courant (/me)
  // ========================================

  /// Récupère l'utilisateur actuellement connecté
  ///
  /// Retourne un [DirectusUser] ou une sous-classe si une factory est enregistrée.
  ///
  /// Exemple avec DirectusUser par défaut :
  /// ```dart
  /// final me = await users.me();
  /// print(me.email);
  /// print(me.fullName);
  /// ```
  ///
  /// Exemple avec classe personnalisée :
  /// ```dart
  /// class MyUser extends DirectusUser {
  ///   late final department = stringValue('department');
  ///   MyUser(super.data);
  ///   static MyUser factory(Map<String, dynamic> data) => MyUser(data);
  /// }
  ///
  /// // Enregistrer la factory
  /// DirectusModel.registerFactory<MyUser>(MyUser.factory);
  ///
  /// // Utiliser avec type personnalisé
  /// final me = await users.me<MyUser>();
  /// print(me.department);
  /// ```
  Future<T?> me<T extends DirectusUser>({QueryParameters? query}) async {
    final response = await _httpClient.get(
      '/users/me',
      queryParameters: query?.toQueryParameters(),
    );

    // Directus peut retourner 204 No Content sans body
    if (response.data == null || !response.data.containsKey('data')) {
      return null;
    }

    final data = response.data['data'] as Map<String, dynamic>;

    // Si un type spécifique est demandé, utiliser la factory
    if (T != DirectusUser) {
      final factory = DirectusModel.getFactory<T>();
      if (factory == null) {
        throw StateError(
          'No factory registered for type $T. '
          'Please register a factory using DirectusModel.registerFactory<$T>(...)',
        );
      }
      return factory(data) as T;
    }

    // Sinon retourner DirectusUser par défaut
    return DirectusUser(data) as T;
  }

  /// Met à jour l'utilisateur connecté
  ///
  /// Retourne l'utilisateur mis à jour en tant que [DirectusUser] ou sous-classe.
  Future<T?> updateMe<T extends DirectusUser>(
    Map<String, dynamic> data, {
    QueryParameters? query,
  }) async {
    final response = await _httpClient.patch(
      '/users/me',
      data: data,
      queryParameters: query?.toQueryParameters(),
    );

    // Directus peut retourner 204 No Content sans body
    if (response.data == null || !response.data.containsKey('data')) {
      return null;
    }

    final responseData = response.data['data'] as Map<String, dynamic>;

    // Si un type spécifique est demandé, utiliser la factory
    if (T != DirectusUser) {
      final factory = DirectusModel.getFactory<T>();
      if (factory == null) {
        throw StateError(
          'No factory registered for type $T. '
          'Please register a factory using DirectusModel.registerFactory<$T>(...)',
        );
      }
      return factory(responseData) as T;
    }

    // Sinon retourner DirectusUser par défaut
    return DirectusUser(responseData) as T;
  }

  // ========================================
  // Invitations
  // ========================================

  /// Invite un ou plusieurs utilisateurs
  ///
  /// Crée des utilisateurs avec le statut "invited" et envoie un email
  /// avec un lien pour activer leur compte.
  ///
  /// [email] Email ou liste d'emails à inviter
  /// [roleId] ID du rôle à assigner
  /// [inviteUrl] URL personnalisée pour le lien d'invitation (optionnel)
  ///             Nécessite la variable d'environnement USER_INVITE_URL_ALLOW_LIST
  Future<void> inviteUsers({
    required dynamic email, // String ou List<String>
    required String roleId,
    String? inviteUrl,
  }) async {
    final data = <String, dynamic>{'email': email, 'role': roleId};
    if (inviteUrl != null) {
      data['invite_url'] = inviteUrl;
    }
    await _httpClient.post('/users/invite', data: data);
  }

  /// Accepte une invitation utilisateur
  ///
  /// [token] Token d'invitation reçu par email
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

  // ========================================
  // Enregistrement public
  // ========================================

  /// Enregistre un nouvel utilisateur (inscription publique)
  ///
  /// Cette fonctionnalité doit être activée dans les paramètres du projet.
  /// L'utilisateur recevra le rôle configuré dans les paramètres.
  ///
  /// [email] Email de l'utilisateur
  /// [password] Mot de passe de l'utilisateur
  /// [firstName] Prénom (optionnel)
  /// [lastName] Nom (optionnel)
  /// [verificationUrl] URL personnalisée pour la vérification (optionnel)
  ///                   Nécessite USER_REGISTER_URL_ALLOW_LIST
  ///
  /// Note: Directus retourne toujours 204 (succès ou échec) pour éviter
  /// de divulguer l'existence d'utilisateurs enregistrés.
  Future<void> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? verificationUrl,
  }) async {
    final data = <String, dynamic>{'email': email, 'password': password};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (verificationUrl != null) data['verification_url'] = verificationUrl;

    await _httpClient.post('/users/register', data: data);
  }

  /// Vérifie l'email d'un utilisateur enregistré
  ///
  /// [token] Token de vérification reçu par email
  Future<void> verifyEmail(String token) async {
    await _httpClient.get('/users/register/verify-email/$token');
  }

  // ========================================
  // Two-Factor Authentication (2FA)
  // ========================================

  /// Génère un secret 2FA pour l'utilisateur connecté
  ///
  /// Retourne :
  /// - `secret` : Le secret OTP à sauvegarder dans l'app d'authentification
  /// - `otpauth_url` : URL formatée pour générer un QR code
  ///
  /// Exemple :
  /// ```dart
  /// final tfa = await users.generateTwoFactorSecret();
  /// print('Secret: ${tfa['secret']}');
  /// print('QR Code URL: ${tfa['otpauth_url']}');
  /// // Afficher le QR code à l'utilisateur
  /// // Puis valider avec enableTwoFactor()
  /// ```
  Future<Map<String, dynamic>> generateTwoFactorSecret() async {
    final response = await _httpClient.post('/users/me/tfa/generate', data: '');
    return response.data as Map<String, dynamic>;
  }

  /// Active la 2FA pour l'utilisateur connecté
  ///
  /// [secret] Le secret obtenu via generateTwoFactorSecret()
  /// [otp] Code OTP généré avec le secret pour vérifier la configuration
  Future<void> enableTwoFactor({
    required String secret,
    required String otp,
  }) async {
    await _httpClient.post(
      '/users/me/tfa/enable',
      data: {'secret': secret, 'otp': otp},
    );
  }

  /// Désactive la 2FA pour l'utilisateur connecté
  ///
  /// [otp] Code OTP actuel pour confirmer la désactivation
  Future<void> disableTwoFactor(String otp) async {
    await _httpClient.post('/users/me/tfa/disable', data: {'otp': otp});
  }

  // ========================================
  // Suivi et préférences
  // ========================================

  /// Met à jour la dernière page visitée par l'utilisateur
  ///
  /// Utilisé en interne par Directus pour réouvrir la dernière page
  /// visitée dans l'interface d'administration.
  Future<void> updateLastPage(String lastPage) async {
    await _httpClient.patch(
      '/users/me/track/page',
      data: {'last_page': lastPage},
    );
  }
}
