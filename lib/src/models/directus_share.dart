import 'directus_model.dart';

/// Représente un partage (`directus_shares`) : accès public à un item.
///
/// ```dart
/// final share = DirectusShare.empty()
///   ..name.set('Relecture client')
///   ..collection.set('articles')
///   ..item.set('15')
///   ..maxUses.set(10);
/// final created = await client.shares.createOne(share);
/// ```
class DirectusShare extends DirectusModel {
  /// Nom du partage
  late final name = stringValue('name');

  /// Collection de l'item partagé
  late final collection = stringValue('collection');

  /// Identifiant de l'item partagé
  late final item = stringValue('item');

  /// Rôle dont les permissions s'appliquent au partage
  late final role = stringValue('role');

  /// Mot de passe (écriture seule ; masqué en lecture)
  late final password = stringValue('password');

  /// Début de validité
  late final dateStart = dateTimeValue('date_start');

  /// Fin de validité
  late final dateEnd = dateTimeValue('date_end');

  /// Nombre d'utilisations
  late final timesUsed = intValue('times_used');

  /// Nombre maximal d'utilisations
  late final maxUses = intValue('max_uses');

  DirectusShare(super.data);
  DirectusShare.empty() : super.empty();

  @override
  String get itemName => 'directus_shares';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusShare factory(Map<String, dynamic> data) =>
      DirectusShare(data);

  /// Vrai si la limite d'utilisations est atteinte
  bool get isExhausted =>
      maxUses.valueOrNull != null && timesUsed.value >= maxUses.value;
}
