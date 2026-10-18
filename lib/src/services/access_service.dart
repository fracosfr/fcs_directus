import '../core/directus_http_client.dart';
import '../models/directus_access.dart';
import 'system_items_service.dart';

/// Service des attributions de policies (`/access`, collection `directus_access`).
///
/// Une entrée relie une policy soit à un rôle, soit à un utilisateur.
///
/// ```dart
/// // Donner une policy à un utilisateur
/// await client.access.assignToUser(userId: 'user-id', policyId: 'policy-id');
///
/// // Lister les policies d'un rôle
/// final links = await client.access.readMany(
///   query: QueryParameters(filter: Filter.field('role').equals('role-id')),
/// );
/// ```
class AccessService extends DirectusSystemService<DirectusAccess> {
  AccessService(DirectusHttpClient httpClient)
    : super(httpClient, 'directus_access', DirectusAccess.factory);

  /// Attribue une policy à un rôle.
  Future<DirectusAccess?> assignToRole({
    required String roleId,
    required String policyId,
  }) => createOne(
    DirectusAccess.empty()
      ..role.set(roleId)
      ..policy.set(policyId),
  );

  /// Attribue une policy à un utilisateur.
  Future<DirectusAccess?> assignToUser({
    required String userId,
    required String policyId,
  }) => createOne(
    DirectusAccess.empty()
      ..user.set(userId)
      ..policy.set(policyId),
  );
}
