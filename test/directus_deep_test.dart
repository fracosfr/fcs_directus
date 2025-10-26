import 'package:fcs_directus/fcs_directus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Deep System Tests', () {
    group('DeepQuery', () {
      test('creates empty query', () {
        final query = DeepQuery();
        expect(query.toJson(), equals({}));
      });

      test('adds fields', () {
        final query = DeepQuery().fields(['id', 'name', 'email']);
        expect(
          query.toJson(),
          equals({
            '_fields': ['id', 'name', 'email'],
          }),
        );
      });

      test('adds limit', () {
        final query = DeepQuery().limit(10);
        expect(query.toJson(), equals({'_limit': 10}));
      });

      test('adds single sort string', () {
        final query = DeepQuery().sort('name');
        expect(
          query.toJson(),
          equals({
            '_sort': ['name'],
          }),
        );
      });

      test('adds multiple sort fields', () {
        final query = DeepQuery().sort(['name', '-created_at']);
        expect(
          query.toJson(),
          equals({
            '_sort': ['name', '-created_at'],
          }),
        );
      });

      test('adds filter from Map', () {
        final query = DeepQuery().filter({
          '_eq': {'status': 'published'},
        });
        expect(
          query.toJson(),
          equals({
            '_filter': {
              '_eq': {'status': 'published'},
            },
          }),
        );
      });

      test('adds filter from Filter object', () {
        final query = DeepQuery().filter(
          Filter.field('status').equals('published'),
        );
        expect(
          query.toJson(),
          equals({
            '_filter': {
              'status': {'_eq': 'published'},
            },
          }),
        );
      });

      test('adds nested deep queries', () {
        final query = DeepQuery().deep({
          'author': DeepQuery().fields(['id', 'name']),
        });

        final json = query.toJson();
        expect(
          json['author'],
          equals({
            '_fields': ['id', 'name'],
          }),
        );
      });

      test('chains multiple operations', () {
        final query = DeepQuery()
            .fields(['id', 'title', 'content'])
            .limit(5)
            .sort('-created_at')
            .filter(Filter.field('status').equals('published'));

        expect(
          query.toJson(),
          equals({
            '_fields': ['id', 'title', 'content'],
            '_limit': 5,
            '_sort': ['-created_at'],
            '_filter': {
              'status': {'_eq': 'published'},
            },
          }),
        );
      });
    });

    group('DeepQuery Extensions', () {
      test('allFields() adds wildcard', () {
        final query = DeepQuery().allFields();
        expect(
          query.toJson(),
          equals({
            '_fields': ['*'],
          }),
        );
      });

      test('sortAsc() adds ascending sort', () {
        final query = DeepQuery().sortAsc('name');
        expect(
          query.toJson(),
          equals({
            '_sort': ['name'],
          }),
        );
      });

      test('sortDesc() adds descending sort', () {
        final query = DeepQuery().sortDesc('created_at');
        expect(
          query.toJson(),
          equals({
            '_sort': ['-created_at'],
          }),
        );
      });

      test('first() sets limit', () {
        final query = DeepQuery().first(3);
        expect(query.toJson(), equals({'_limit': 3}));
      });
    });

    group('Deep (DeepFields)', () {
      test('creates deep with single field query', () {
        final deep = Deep({
          'author': DeepQuery().fields(['id', 'name']),
        });

        expect(
          deep.toJson(),
          equals({
            'author': {
              '_fields': ['id', 'name'],
            },
          }),
        );
      });

      test('creates deep with multiple field queries', () {
        final deep = Deep({
          'author': DeepQuery().fields(['id', 'name']),
          'categories': DeepQuery().limit(5),
        });

        expect(
          deep.toJson(),
          equals({
            'author': {
              '_fields': ['id', 'name'],
            },
            'categories': {'_limit': 5},
          }),
        );
      });

      test('creates nested deep queries', () {
        final deep = Deep({
          'author': DeepQuery().fields(['id', 'name', 'avatar']).deep({
            'avatar': DeepQuery().fields(['id', 'filename_disk']),
          }),
        });

        final json = deep.toJson();
        expect(json['author']['_fields'], equals(['id', 'name', 'avatar']));
        expect(
          json['author']['avatar'],
          equals({
            '_fields': ['id', 'filename_disk'],
          }),
        );
      });

      test('creates complex multi-level deep', () {
        final deep = Deep({
          'items': DeepQuery().fields(['id', 'quantity', 'product']).deep({
            'product': DeepQuery().fields(['id', 'name', 'category']).deep({
              'category': DeepQuery().fields(['id', 'name']),
            }),
          }),
        });

        final json = deep.toJson();
        expect(json['items']['_fields'], equals(['id', 'quantity', 'product']));
        expect(
          json['items']['product']['_fields'],
          equals(['id', 'name', 'category']),
        );
        expect(
          json['items']['product']['category'],
          equals({
            '_fields': ['id', 'name'],
          }),
        );
      });
    });

    group('DeepMaxDepth', () {
      test('creates deep with max depth', () {
        final deep = Deep.maxDepth(3);
        expect(deep.toJson(), equals({'_limit': 3}));
      });

      test('creates deep with depth 1', () {
        final deep = Deep.maxDepth(1);
        expect(deep.toJson(), equals({'_limit': 1}));
      });
    });

    group('Integration with QueryParameters', () {
      test('accepts Deep object', () {
        final params = QueryParameters(
          deep: Deep({
            'author': DeepQuery().fields(['id', 'name']),
          }),
        );

        final json = params.toQueryParameters();
        expect(
          json['deep'],
          equals({
            'author': {
              '_fields': ['id', 'name'],
            },
          }),
        );
      });

      test('accepts Map for backward compatibility', () {
        final params = QueryParameters(
          deep: {
            'author': {
              '_fields': ['id', 'name'],
            },
          },
        );

        final json = params.toQueryParameters();
        expect(
          json['deep'],
          equals({
            'author': {
              '_fields': ['id', 'name'],
            },
          }),
        );
      });

      test('combines with other query parameters', () {
        final params = QueryParameters(
          filter: Filter.field('status').equals('published'),
          fields: ['id', 'title'],
          limit: 10,
          sort: ['-created_at'],
          deep: Deep({
            'author': DeepQuery().fields(['id', 'name']),
          }),
        );

        final json = params.toQueryParameters();
        expect(json['filter'], isNotNull);
        expect(
          json['fields'],
          equals('id,title'),
        ); // fields are joined with comma
        expect(json['limit'], equals(10));
        expect(
          json['sort'],
          equals('-created_at'),
        ); // sort are joined with comma
        expect(
          json['deep'],
          equals({
            'author': {
              '_fields': ['id', 'name'],
            },
          }),
        );
      });
    });

    group('Complex Real-World Scenarios', () {
      test('blog post with filtered comments and author', () {
        final params = QueryParameters(
          deep: Deep({
            'author': DeepQuery().fields(['id', 'name', 'avatar']).deep({
              'avatar': DeepQuery().fields(['id', 'filename_disk']),
            }),
            'comments': DeepQuery()
                .filter(
                  Filter.and([
                    Filter.field('status').equals('approved'),
                    Filter.field('spam').equals(false),
                  ]),
                )
                .sortDesc('created_at')
                .limit(10)
                .fields(['id', 'content', 'created_at', 'user'])
                .deep({
                  'user': DeepQuery().fields(['id', 'name']),
                }),
          }),
        );

        final json = params.toQueryParameters();
        expect(
          json['deep']['author']['_fields'],
          equals(['id', 'name', 'avatar']),
        );
        expect(
          json['deep']['author']['avatar'],
          equals({
            '_fields': ['id', 'filename_disk'],
          }),
        );
        expect(json['deep']['comments']['_limit'], equals(10));
        expect(json['deep']['comments']['_sort'], equals(['-created_at']));
      });

      test('e-commerce order with nested products and customer', () {
        final params = QueryParameters(
          deep: Deep({
            'items': DeepQuery()
                .fields(['id', 'quantity', 'price', 'product'])
                .deep({
                  'product': DeepQuery().fields(['id', 'name', 'image']).deep({
                    'image': DeepQuery().fields(['id', 'filename_disk']),
                  }),
                }),
            'customer': DeepQuery().fields([
              'id',
              'first_name',
              'last_name',
              'email',
            ]),
          }),
        );

        final json = params.toQueryParameters();
        expect(
          json['deep']['items']['_fields'],
          equals(['id', 'quantity', 'price', 'product']),
        );
        expect(
          json['deep']['items']['product']['_fields'],
          equals(['id', 'name', 'image']),
        );
        expect(
          json['deep']['customer']['_fields'],
          equals(['id', 'first_name', 'last_name', 'email']),
        );
      });

      test('many-to-many with junction table filter', () {
        final params = QueryParameters(
          deep: Deep({
            'movie_actors': DeepQuery()
                .filter(Filter.field('role').equals('lead'))
                .deep({
                  'actors': DeepQuery().fields(['id', 'name', 'photo']).deep({
                    'photo': DeepQuery().fields(['id', 'filename_disk']),
                  }),
                }),
          }),
        );

        final json = params.toQueryParameters();
        expect(json['deep']['movie_actors']['_filter'], isNotNull);
        expect(
          json['deep']['movie_actors']['actors']['_fields'],
          equals(['id', 'name', 'photo']),
        );
      });
    });
  });
}
