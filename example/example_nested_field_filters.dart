// ignore_for_file: non_constant_identifier_names, avoid_print, unused_local_variable

import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation des filtres sur champs imbriqués (nested fields)
///
/// Directus supporte la notation pointée pour accéder aux champs des relations.
/// La librairie fcs_directus transmet cette notation directement à l'API.
///
/// Cet exemple montre comment filtrer sur :
/// - Des champs directs
/// - Des champs de relations Many-to-One
/// - Des champs profondément imbriqués
void main() async {
  await example1SimpleNestedField();
  await example2DeepNestedFields();
  await example3CombinedFilters();
  await example4_RealWorldExample();
}

/// Exemple 1: Filtrage sur un champ de relation simple
Future<void> example1SimpleNestedField() async {
  print('\n=== Exemple 1: Champ de relation simple ===\n');

  final client = DirectusClient(
    DirectusConfig(baseUrl: 'https://your-directus.com'),
  );

  try {
    // Scénario: Filtrer les communes par département
    //
    // Structure:
    // Commune {
    //   id: string
    //   nom: string
    //   departement: Departement {  // Relation Many-to-One
    //     id: string
    //     nom: string
    //     code: string
    //   }
    // }

    // ✅ Filtrer les communes d'un département spécifique
    final communesFilter = Filter.field('departement').equals('dept-123');

    final communes = await client
        .items('commune')
        .readMany(
          query: QueryParameters(
            filter: communesFilter,
            fields: ['*', 'departement.*'],
          ),
        );

    print('✓ Communes du département dept-123: ${communes.data.length}');
    print('  Filtre JSON: ${communesFilter.toJson()}');
    // {"departement": {"_eq": "dept-123"}}

    // ✅ Filtrer les communes par CODE de département (champ nested)
    final communesByCodeFilter = Filter.field('departement.code').equals('75');

    final communesParis = await client
        .items('commune')
        .readMany(
          query: QueryParameters(
            filter: communesByCodeFilter,
            fields: ['*', 'departement.*'],
          ),
        );

    print('✓ Communes avec code département 75: ${communesParis.data.length}');
    print('  Filtre JSON: ${communesByCodeFilter.toJson()}');
    // {"departement.code": {"_eq": "75"}}
  } catch (e) {
    print('✗ Erreur: $e');
  } finally {
    await client.dispose();
  }
}

/// Exemple 2: Filtrage sur des champs profondément imbriqués
Future<void> example2DeepNestedFields() async {
  print('\n=== Exemple 2: Champs profondément imbriqués ===\n');

  final client = DirectusClient(
    DirectusConfig(baseUrl: 'https://your-directus.com'),
  );

  try {
    // Scénario: Filtrer par région via département
    //
    // Structure:
    // Commune {
    //   departement: Departement {
    //     region: Region {
    //       id: string
    //       nom: string
    //       code: string
    //     }
    //   }
    // }

    // ✅ Filtrer les communes par région (via département)
    final filter = Filter.field('departement.region').equals('region-idf');

    final communes = await client
        .items('commune')
        .readMany(
          query: QueryParameters(
            filter: filter,
            fields: ['*', 'departement.region.*'],
          ),
        );

    print('✓ Communes de la région region-idf: ${communes.data.length}');
    print('  Filtre JSON: ${filter.toJson()}');
    // {"departement": {"region": {"_eq": "region-idf"}}}

    // ✅ Filtrer par nom de région (champ nested level 2)
    final filterByRegionName = Filter.field(
      'departement.region.nom',
    ).contains('Île-de-France');

    print('  Filtre par nom de région: ${filterByRegionName.toJson()}');
    // {"departement": {"region": {"nom": {"_contains": "Île-de-France"}}}}

    // ✅ Vous pouvez aller encore plus loin si nécessaire
    // Exemple: Commune -> Département -> Région -> Pays
    final filterByCountry = Filter.field(
      'departement.region.pays.code',
    ).equals('FR');

    print('  Filtre par pays: ${filterByCountry.toJson()}');
    // {"departement": {"region": {"pays": {"code": {"_eq": "FR"}}}}}
  } catch (e) {
    print('✗ Erreur: $e');
  } finally {
    await client.dispose();
  }
}

/// Exemple 3: Combinaison de filtres sur champs imbriqués
Future<void> example3CombinedFilters() async {
  print('\n=== Exemple 3: Filtres combinés ===\n');

  final client = DirectusClient(
    DirectusConfig(baseUrl: 'https://your-directus.com'),
  );

  try {
    // ✅ Filtrer les communes par département ET population
    final filter = Filter.and([
      Filter.field('departement').equals('dept-75'),
      Filter.field('population').greaterThan(10000),
    ]);

    print('Filtre: Département 75 ET population > 10000');
    print('  JSON: ${filter.toJson()}');
    // {
    //   "_and": [
    //     {"departement": {"_eq": "dept-75"}},
    //     {"population": {"_gt": 10000}}
    //   ]
    // }

    // ✅ Filtrer par région OU département spécifique
    final filterOr = Filter.or([
      Filter.field('departement.region').equals('region-idf'),
      Filter.field('departement').equals('dept-13'),
    ]);

    print('\nFiltre: Région IDF OU Département 13');
    print('  JSON: ${filterOr.toJson()}');
    // {
    //   "_or": [
    //     {"departement": {"region": {"_eq": "region-idf"}}},
    //     {"departement": {"_eq": "dept-13"}}
    //   ]
    // }

    // ✅ Filtre complexe avec imbrication
    final filterComplex = Filter.and([
      Filter.field('departement.region.nom').contains('Provence'),
      Filter.or([
        Filter.field('population').greaterThan(50000),
        Filter.field('tourisme').equals(true),
      ]),
    ]);

    print('\nFiltre complexe:');
    print('  Région contient "Provence"');
    print('  ET (Population > 50000 OU Tourisme actif)');
    print('  JSON: ${filterComplex.toJson()}');
  } catch (e) {
    print('✗ Erreur: $e');
  } finally {
    await client.dispose();
  }
}

/// Exemple 4: Cas d'usage réel complet
Future<void> example4_RealWorldExample() async {
  print('\n=== Exemple 4: Cas d\'usage réel ===\n');

  final client = DirectusClient(
    DirectusConfig(baseUrl: 'https://api.directus'),
  );

  try {
    // Scénario: Rechercher des brigades dans une région spécifique
    // avec recherche textuelle

    const String regionId = 'region-idf';
    const String searchText = 'central';

    final filter = Filter.and([
      // Filtrer par région via le département
      Filter.field('departement.region').equals(regionId),
      // Recherche textuelle dans le nom
      Filter.field('nom').containsInsensitive(searchText),
      // Seulement les brigades actives
      Filter.field('active').equals(true),
    ]);

    final brigades = await client
        .items('brigade')
        .readMany(
          query: QueryParameters(
            filter: filter,
            fields: ['*', 'departement.*', 'departement.region.*'],
            limit: 50,
          ),
        );

    print('✓ Résultat de la recherche:');
    print('  - Région: $regionId');
    print('  - Texte recherché: "$searchText"');
    print('  - Brigades trouvées: ${brigades.data.length}');
    print('\nFiltre JSON généré:');
    print('  ${filter.toJson()}');

    // Afficher quelques résultats
    if (brigades.data.isNotEmpty) {
      print('\nExemples de résultats:');
      for (var i = 0; i < brigades.data.length && i < 3; i++) {
        final brigade = brigades.data[i];
        print('  ${i + 1}. ${brigade['nom']}');
        if (brigade['departement'] is Map) {
          print('     Département: ${(brigade['departement'] as Map)['nom']}');
        }
      }
    }

    // ✅ Autre exemple: Rechercher des commissariats dans plusieurs départements
    final filterMultipleDept = Filter.and([
      Filter.field('departement.code').inList(['75', '92', '93', '94']),
      Filter.field('type').equals('commissariat'),
    ]);

    print('\n\nFiltre: Commissariats dans les départements 75, 92, 93, 94');
    print('  JSON: ${filterMultipleDept.toJson()}');
    // {
    //   "_and": [
    //     {"departement.code": {"_in": ["75", "92", "93", "94"]}},
    //     {"type": {"_eq": "commissariat"}}
    //   ]
    // }
  } catch (e) {
    print('✗ Erreur: $e');
  } finally {
    await client.dispose();
  }
}

/// Bonus: Fonction helper pour créer des filtres géographiques réutilisables
class GeoFilters {
  /// Filtre les items par département
  static Filter byDepartement(String departementId) {
    return Filter.field('departement').equals(departementId);
  }

  /// Filtre les items par code département
  static Filter byDepartementCode(String code) {
    return Filter.field('departement.code').equals(code);
  }

  /// Filtre les items par région
  static Filter byRegion(String regionId) {
    return Filter.field('departement.region').equals(regionId);
  }

  /// Filtre les items par nom de région
  static Filter byRegionName(String nomRegion) {
    return Filter.field('departement.region.nom').equals(nomRegion);
  }

  /// Filtre les items par plusieurs départements
  static Filter byDepartements(List<String> departementIds) {
    return Filter.field('departement').inList(departementIds);
  }

  /// Filtre les items par plusieurs codes départements
  static Filter byDepartementCodes(List<String> codes) {
    return Filter.field('departement.code').inList(codes);
  }

  /// Exemple d'utilisation des helpers:
  static void showExamples() {
    print('\n=== Exemples avec helpers ===\n');

    // Simple et lisible
    final filter1 = GeoFilters.byRegion('region-idf');
    print('Par région: ${filter1.toJson()}');

    final filter2 = GeoFilters.byDepartementCodes(['75', '92', '93']);
    print('Par codes: ${filter2.toJson()}');

    // Combinaison facile
    final filterCombined = Filter.and([
      GeoFilters.byRegion('region-idf'),
      Filter.field('active').equals(true),
    ]);
    print('Combiné: ${filterCombined.toJson()}');
  }
}
