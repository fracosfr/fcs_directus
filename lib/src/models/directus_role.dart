import 'directus_model.dart';
import 'directus_policy.dart';

/// Représente un rôle Directus avec toutes les propriétés système.
///
/// Les rôles sont la structure organisationnelle principale pour les utilisateurs
/// au sein de la plateforme.
///
/// Exemple d'utilisation :
/// ```dart
/// final role = DirectusRole(data);
///
/// // Obtenir le nom du rôle
/// print('Rôle : ${role.name.value}');
///
/// // Vérifier si le rôle a des enfants (sous-rôles)
/// if (role.hasChildren) {
///   print('Ce rôle a ${role.children.length} sous-rôle(s)');
/// }
///
/// // Vérifier les politiques du rôle
/// if (role.hasPolicies) {
///   print('${role.policies.length} politique(s) associée(s)');
/// }
///
/// // Vérifier si le rôle a un parent
/// if (role.hasParent) {
///   print('Ce rôle hérite de : ${role.parent.value}');
/// }
/// ```
class DirectusRole extends DirectusModel {
  /// Nom du rôle
  late final name = stringValue('name');

  /// Icône du rôle
  late final icon = stringValue('icon');

  /// Description du rôle
  late final description = stringValue('description');

  /// Rôle parent optionnel dont ce rôle hérite les permissions
  /// Many-to-one vers roles
  late final parent = stringValue('parent');

  /// Rôles enfants imbriqués qui héritent des permissions de ce rôle
  /// One-to-many vers roles
  late final children = listValue<String>('children');

  /// Les politiques dans ce rôle
  /// Many-to-many vers policies
  /// Note: Peut contenir des IDs (String) ou des objets complets (DirectusPolicy)
  /// selon les champs demandés dans la requête
  late final policies = modelListValue<DirectusPolicy>('policies');

  /// Les utilisateurs dans ce rôle
  /// One-to-many vers users
  late final users = listValue<String>('users');

  DirectusRole(super.data);
  DirectusRole.empty() : super.empty();

  @override
  String get itemName => 'directus_roles';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusRole factory(Map<String, dynamic> data) => DirectusRole(data);

  /// Vérifie si le rôle a un parent
  bool get hasParent => parent.isNotEmpty;

  /// Vérifie si le rôle a des enfants (sous-rôles)
  bool get hasChildren => children.isNotEmpty;

  /// Vérifie si le rôle a des politiques associées
  bool get hasPolicies => policies.isNotEmpty;

  /// Vérifie si le rôle a des utilisateurs assignés
  bool get hasUsers => users.isNotEmpty;

  /// Nombre de sous-rôles
  int get childrenCount => children.length;

  /// Nombre de politiques associées
  int get policiesCount => policies.length;

  /// Nombre d'utilisateurs assignés
  int get usersCount => users.length;

  /// Définit le rôle parent
  void setParent(String? parentId) {
    if (parentId == null) {
      parent.clear();
    } else {
      parent.set(parentId);
    }
  }

  /// Ajoute une politique au rôle
  /// [policy] peut être soit un DirectusPolicy complet, soit son ID
  void addPolicy(dynamic policy) {
    final policyToAdd = policy is DirectusPolicy
        ? policy
        : DirectusPolicy({'id': policy});
    final current = policies.value;

    // Vérifier que la politique n'existe pas déjà
    final policyId = policyToAdd.id;
    if (policyId == null) return;

    final alreadyExists = current.any((p) => p.id == policyId);

    if (!alreadyExists) {
      policies.set([...current, policyToAdd]);
    }
  }

  /// Retire une politique du rôle par son ID
  void removePolicy(String policyId) {
    final current = policies.value;
    policies.set(current.where((p) => p.id != policyId).toList());
  }

  /// Ajoute un utilisateur au rôle
  void addUser(String userId) {
    if (!users.value.contains(userId)) {
      final current = users.value;
      users.set([...current, userId]);
    }
  }

  /// Retire un utilisateur du rôle
  void removeUser(String userId) {
    final current = users.value;
    users.set(current.where((id) => id != userId).toList());
  }
}
