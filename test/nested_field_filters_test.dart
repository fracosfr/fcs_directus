import 'package:fcs_directus/fcs_directus.dart';
import 'package:test/test.dart';

void main() {
  group('Nested Field Filters', () {
    test('Filter sur champ de relation simple', () {
      final filter = Filter.field('departement').equals('dept-75');

      expect(filter.toJson(), {
        'departement': {'_eq': 'dept-75'},
      });
    });

    test('Filter sur champ nested niveau 1', () {
      final filter = Filter.field('departement.code').equals('75');

      expect(filter.toJson(), {
        'departement': {
          'code': {'_eq': '75'},
        },
      });
    });

    test('Filter sur champ nested niveau 2', () {
      final filter = Filter.field('departement.region').equals('region-idf');

      expect(filter.toJson(), {
        'departement': {
          'region': {'_eq': 'region-idf'},
        },
      });
    });

    test('Filter sur champ nested niveau 3', () {
      final filter = Filter.field(
        'departement.region.nom',
      ).contains('Île-de-France');

      expect(filter.toJson(), {
        'departement': {
          'region': {
            'nom': {'_contains': 'Île-de-France'},
          },
        },
      });
    });

    test('Filter sur champ profondément imbriqué', () {
      final filter = Filter.field('departement.region.pays.code').equals('FR');

      expect(filter.toJson(), {
        'departement': {
          'region': {
            'pays': {
              'code': {'_eq': 'FR'},
            },
          },
        },
      });
    });

    test('Tous les opérateurs fonctionnent avec notation pointée', () {
      // Comparaisons
      expect(Filter.field('dept.population').greaterThan(100000).toJson(), {
        'dept': {
          'population': {'_gt': 100000},
        },
      });

      expect(Filter.field('dept.code').lessThanOrEqual('99').toJson(), {
        'dept': {
          'code': {'_lte': '99'},
        },
      });

      // Collections
      expect(Filter.field('dept.code').inList(['75', '92']).toJson(), {
        'dept': {
          'code': {
            '_in': ['75', '92'],
          },
        },
      });

      // Chaînes
      expect(Filter.field('dept.region.nom').contains('Provence').toJson(), {
        'dept': {
          'region': {
            'nom': {'_contains': 'Provence'},
          },
        },
      });

      expect(Filter.field('dept.nom').startsWith('Paris').toJson(), {
        'dept': {
          'nom': {'_starts_with': 'Paris'},
        },
      });

      // Insensible à la casse
      expect(
        Filter.field('dept.region.nom').containsInsensitive('île').toJson(),
        {
          'dept': {
            'region': {
              'nom': {'_icontains': 'île'},
            },
          },
        },
      );

      // Null checks
      expect(Filter.field('dept.region').isNotNull().toJson(), {
        'dept': {
          'region': {'_nnull': true},
        },
      });
    });

    test('Combinaison de filtres avec champs imbriqués', () {
      final filter = Filter.and([
        Filter.field('departement.region').equals('region-idf'),
        Filter.field('population').greaterThan(10000),
        Filter.field('active').equals(true),
      ]);

      expect(filter.toJson(), {
        '_and': [
          {
            'departement': {
              'region': {'_eq': 'region-idf'},
            },
          },
          {
            'population': {'_gt': 10000},
          },
          {
            'active': {'_eq': true},
          },
        ],
      });
    });

    test('Filtres OR avec champs imbriqués', () {
      final filter = Filter.or([
        Filter.field('departement.region').equals('region-idf'),
        Filter.field('departement.code').equals('13'),
      ]);

      expect(filter.toJson(), {
        '_or': [
          {
            'departement': {
              'region': {'_eq': 'region-idf'},
            },
          },
          {
            'departement': {
              'code': {'_eq': '13'},
            },
          },
        ],
      });
    });

    test('Filtre complexe avec imbrication multiple', () {
      final filter = Filter.and([
        Filter.field('departement.region.nom').contains('Provence'),
        Filter.or([
          Filter.field('population').greaterThan(50000),
          Filter.field('tourisme').equals(true),
        ]),
      ]);

      expect(filter.toJson(), {
        '_and': [
          {
            'departement': {
              'region': {
                'nom': {'_contains': 'Provence'},
              },
            },
          },
          {
            '_or': [
              {
                'population': {'_gt': 50000},
              },
              {
                'tourisme': {'_eq': true},
              },
            ],
          },
        ],
      });
    });

    test('Filtre avec between sur champ imbriqué', () {
      final filter = Filter.field(
        'departement.superficie',
      ).between(1000, 10000);

      expect(filter.toJson(), {
        'departement': {
          'superficie': {
            '_between': [1000, 10000],
          },
        },
      });
    });

    test('Filtre avec regex sur champ imbriqué', () {
      final filter = Filter.field('departement.code').regex(r'^[0-9]{2}$');

      expect(filter.toJson(), {
        'departement': {
          'code': {'_regex': r'^[0-9]{2}$'},
        },
      });
    });

    test('Filtre avec startsWithInsensitive sur champ imbriqué', () {
      final filter = Filter.field(
        'departement.region.nom',
      ).startsWithInsensitive('île');

      expect(filter.toJson(), {
        'departement': {
          'region': {
            'nom': {'_istarts_with': 'île'},
          },
        },
      });
    });

    test('Filtre avec isEmpty sur champ imbriqué profond', () {
      final filter = Filter.field('departement.region.description').isEmpty();

      expect(filter.toJson(), {
        'departement': {
          'region': {
            'description': {'_empty': true},
          },
        },
      });
    });
  });

  group('Filter.relation() vs notation pointée', () {
    test(
      'Filter.relation() produit la même structure que la notation pointée',
      () {
        // Avec notation pointée
        final dottedFilter = Filter.field(
          'departement.region',
        ).equals('region-idf');

        // Avec Filter.relation()
        final relationFilter = Filter.relation(
          'departement',
        ).where(Filter.field('region').equals('region-idf'));

        // Les deux doivent produire la même structure JSON
        expect(dottedFilter.toJson(), {
          'departement': {
            'region': {'_eq': 'region-idf'},
          },
        });

        expect(relationFilter.toJson(), {
          'departement': {
            'region': {'_eq': 'region-idf'},
          },
        });

        // Vérification: les deux sont identiques
        expect(dottedFilter.toJson(), equals(relationFilter.toJson()));
      },
    );

    test('Relation imbriquée à plusieurs niveaux', () {
      // Avec notation pointée (plus simple)
      final dottedFilter = Filter.field(
        'departement.region.nom',
      ).equals('Île-de-France');

      // Avec Filter.relation() (plus verbeux)
      final relationFilter = Filter.relation('departement').where(
        Filter.relation(
          'region',
        ).where(Filter.field('nom').equals('Île-de-France')),
      );

      final expectedJson = {
        'departement': {
          'region': {
            'nom': {'_eq': 'Île-de-France'},
          },
        },
      };

      expect(dottedFilter.toJson(), expectedJson);
      expect(relationFilter.toJson(), expectedJson);
      expect(dottedFilter.toJson(), equals(relationFilter.toJson()));
    });

    test('Combinaison de filtres complexes', () {
      // Avec notation pointée
      final dottedFilter = Filter.and([
        Filter.field('departement.region').equals('region-idf'),
        Filter.field('population').greaterThan(10000),
      ]);

      // Avec Filter.relation()
      final relationFilter = Filter.and([
        Filter.relation(
          'departement',
        ).where(Filter.field('region').equals('region-idf')),
        Filter.field('population').greaterThan(10000),
      ]);

      final expectedJson = {
        '_and': [
          {
            'departement': {
              'region': {'_eq': 'region-idf'},
            },
          },
          {
            'population': {'_gt': 10000},
          },
        ],
      };

      expect(dottedFilter.toJson(), expectedJson);
      expect(relationFilter.toJson(), expectedJson);
    });
  });

  group('Helpers GeoFilters', () {
    test('Helper byRegion utilise la notation pointée', () {
      final filter = GeoFilters.byRegion('region-idf');

      expect(filter.toJson(), {
        'departement': {
          'region': {'_eq': 'region-idf'},
        },
      });
    });

    test('Helper byRegionNom utilise la notation pointée', () {
      final filter = GeoFilters.byRegionNom('Île-de-France');

      expect(filter.toJson(), {
        'departement': {
          'region': {
            'nom': {'_eq': 'Île-de-France'},
          },
        },
      });
    });
  });
}

/// Classe helper pour démontrer l'utilisation pratique
class GeoFilters {
  /// Filtre par ID de région
  static Filter byRegion(String regionId) {
    return Filter.field('departement.region').equals(regionId);
  }

  /// Filtre par nom de région
  static Filter byRegionNom(String nomRegion) {
    return Filter.field('departement.region.nom').equals(nomRegion);
  }
}
