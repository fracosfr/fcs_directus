import 'package:flutter_test/flutter_test.dart';
import 'package:fcs_directus/fcs_directus.dart';

void main() {
  group('Filter', () {
    group('Opérateurs de comparaison', () {
      test('equals génère le bon JSON', () {
        final filter = Filter.field('status').equals('active');
        expect(filter.toJson(), {
          'status': {'_eq': 'active'},
        });
      });

      test('notEquals génère le bon JSON', () {
        final filter = Filter.field('status').notEquals('archived');
        expect(filter.toJson(), {
          'status': {'_neq': 'archived'},
        });
      });

      test('lessThan génère le bon JSON', () {
        final filter = Filter.field('price').lessThan(100);
        expect(filter.toJson(), {
          'price': {'_lt': 100},
        });
      });

      test('greaterThan génère le bon JSON', () {
        final filter = Filter.field('stock').greaterThan(0);
        expect(filter.toJson(), {
          'stock': {'_gt': 0},
        });
      });

      test('between génère le bon JSON', () {
        final filter = Filter.field('price').between(50, 200);
        expect(filter.toJson(), {
          'price': {
            '_between': [50, 200],
          },
        });
      });
    });

    group('Opérateurs de chaîne', () {
      test('contains génère le bon JSON', () {
        final filter = Filter.field('title').contains('laptop');
        expect(filter.toJson(), {
          'title': {'_contains': 'laptop'},
        });
      });

      test('startsWith génère le bon JSON', () {
        final filter = Filter.field('name').startsWith('Apple');
        expect(filter.toJson(), {
          'name': {'_starts_with': 'Apple'},
        });
      });

      test('endsWith génère le bon JSON', () {
        final filter = Filter.field('email').endsWith('@example.com');
        expect(filter.toJson(), {
          'email': {'_ends_with': '@example.com'},
        });
      });
    });

    group('Opérateurs de liste', () {
      test('inList génère le bon JSON', () {
        final filter = Filter.field(
          'category',
        ).inList(['electronics', 'computers']);
        expect(filter.toJson(), {
          'category': {
            '_in': ['electronics', 'computers'],
          },
        });
      });

      test('notInList génère le bon JSON', () {
        final filter = Filter.field(
          'status',
        ).notInList(['archived', 'deleted']);
        expect(filter.toJson(), {
          'status': {
            '_nin': ['archived', 'deleted'],
          },
        });
      });
    });

    group('Opérateurs NULL', () {
      test('isNull génère le bon JSON', () {
        final filter = Filter.field('deleted_at').isNull();
        expect(filter.toJson(), {
          'deleted_at': {'_null': true},
        });
      });

      test('isNotNull génère le bon JSON', () {
        final filter = Filter.field('description').isNotNull();
        expect(filter.toJson(), {
          'description': {'_nnull': true},
        });
      });

      test('isEmpty génère le bon JSON', () {
        final filter = Filter.field('notes').isEmpty();
        expect(filter.toJson(), {
          'notes': {'_empty': true},
        });
      });

      test('isNotEmpty génère le bon JSON', () {
        final filter = Filter.field('content').isNotEmpty();
        expect(filter.toJson(), {
          'content': {'_nempty': true},
        });
      });
    });

    group('Combinaisons logiques', () {
      test('and génère le bon JSON', () {
        final filter = Filter.and([
          Filter.field('status').equals('active'),
          Filter.field('stock').greaterThan(0),
        ]);

        expect(filter.toJson(), {
          '_and': [
            {
              'status': {'_eq': 'active'},
            },
            {
              'stock': {'_gt': 0},
            },
          ],
        });
      });

      test('or génère le bon JSON', () {
        final filter = Filter.or([
          Filter.field('featured').equals(true),
          Filter.field('on_sale').equals(true),
        ]);

        expect(filter.toJson(), {
          '_or': [
            {
              'featured': {'_eq': true},
            },
            {
              'on_sale': {'_eq': true},
            },
          ],
        });
      });

      test('and/or imbriqués génèrent le bon JSON', () {
        final filter = Filter.or([
          Filter.and([
            Filter.field('category').equals('electronics'),
            Filter.field('price').lessThan(500),
          ]),
          Filter.field('featured').equals(true),
        ]);

        expect(filter.toJson(), {
          '_or': [
            {
              '_and': [
                {
                  'category': {'_eq': 'electronics'},
                },
                {
                  'price': {'_lt': 500},
                },
              ],
            },
            {
              'featured': {'_eq': true},
            },
          ],
        });
      });
    });

    group('Filtres sur relations', () {
      test('relation simple génère le bon JSON', () {
        final filter = Filter.relation(
          'category',
        ).where(Filter.field('name').equals('Premium'));

        expect(filter.toJson(), {
          'category': {
            'name': {'_eq': 'Premium'},
          },
        });
      });

      test('relation avec AND génère le bon JSON', () {
        final filter = Filter.relation('category').where(
          Filter.and([
            Filter.field('active').equals(true),
            Filter.field('type').equals('main'),
          ]),
        );

        expect(filter.toJson(), {
          'category': {
            '_and': [
              {
                'active': {'_eq': true},
              },
              {
                'type': {'_eq': 'main'},
              },
            ],
          },
        });
      });
    });

    group('Filtre vide', () {
      test('empty génère un objet vide', () {
        final filter = Filter.empty();
        expect(filter.toJson(), {});
      });
    });

    group('QueryParameters avec Filter', () {
      test('accepte un objet Filter', () {
        final params = QueryParameters(
          filter: Filter.field('status').equals('active'),
          limit: 10,
        );

        final query = params.toQueryParameters();
        expect(query['filter'], {
          'status': {'_eq': 'active'},
        });
        expect(query['limit'], 10);
      });

      test('accepte toujours un Map pour compatibilité', () {
        final params = QueryParameters(
          filter: {
            'status': {'_eq': 'active'},
          },
          limit: 10,
        );

        final query = params.toQueryParameters();
        expect(query['filter'], {
          'status': {'_eq': 'active'},
        });
        expect(query['limit'], 10);
      });

      test('gère null correctement', () {
        final params = QueryParameters(filter: null, limit: 10);

        final query = params.toQueryParameters();
        expect(query.containsKey('filter'), false);
        expect(query['limit'], 10);
      });
    });

    group('Cas d\'usage complexes', () {
      test('recherche e-commerce complexe', () {
        final filter = Filter.and([
          Filter.field('status').equals('active'),
          Filter.field('stock').greaterThan(0),
          Filter.field('price').between(20, 500),
          Filter.or([
            Filter.field('category').equals('electronics'),
            Filter.field('category').equals('computers'),
          ]),
          Filter.field('image').isNotNull(),
        ]);

        final json = filter.toJson();
        expect(json['_and'], isA<List>());
        expect((json['_and'] as List).length, 5);
      });

      test('recherche texte multi-champs', () {
        final searchTerm = 'laptop';
        final filter = Filter.or([
          Filter.field('name').contains(searchTerm),
          Filter.field('description').contains(searchTerm),
          Filter.field('tags').contains(searchTerm),
        ]);

        expect(filter.toJson(), {
          '_or': [
            {
              'name': {'_contains': 'laptop'},
            },
            {
              'description': {'_contains': 'laptop'},
            },
            {
              'tags': {'_contains': 'laptop'},
            },
          ],
        });
      });
    });
  });
}
