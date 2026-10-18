import 'package:dio/dio.dart';
import 'package:fcs_directus/fcs_directus.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'item_active_service_test.mocks.dart';

/// Vérifie que les services appellent les routes de l'API Directus 12.
void main() {
  late MockDirectusHttpClient http;

  Response<dynamic> ok(dynamic data) => Response(
    requestOptions: RequestOptions(path: ''),
    data: data,
    statusCode: 200,
  );

  setUp(() {
    http = MockDirectusHttpClient();
    when(
      http.get(
        any,
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      ),
    ).thenAnswer((_) async => ok({'data': <dynamic>[]}));
    when(
      http.post(
        any,
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      ),
    ).thenAnswer((_) async => ok({'data': <String, dynamic>{}}));
  });

  tearDown(DirectusModel.clearFactories);

  String lastGet() =>
      verify(
            http.get(
              captureAny,
              queryParameters: anyNamed('queryParameters'),
              options: anyNamed('options'),
            ),
          ).captured.last
          as String;

  String lastPost() =>
      verify(
            http.post(
              captureAny,
              data: anyNamed('data'),
              queryParameters: anyNamed('queryParameters'),
              options: anyNamed('options'),
            ),
          ).captured.last
          as String;

  group('directusCollectionPath', () {
    test('collections utilisateur → /items', () {
      expect(directusCollectionPath('articles'), '/items/articles');
    });
    test('collections système → endpoint dédié', () {
      expect(directusCollectionPath('directus_comments'), '/comments');
      expect(directusCollectionPath('directus_users'), '/users');
      expect(directusCollectionPath('directus_access'), '/access');
    });
  });

  group('services système typés', () {
    test(
      'comments.readMany appelle /comments et retourne des modèles',
      () async {
        when(
          http.get(
            '/comments',
            queryParameters: anyNamed('queryParameters'),
            options: anyNamed('options'),
          ),
        ).thenAnswer(
          (_) async => ok({
            'data': [
              {'id': 'c1', 'comment': 'Bonjour', 'collection': 'articles'},
            ],
          }),
        );
        final page = await CommentsService(http).readMany();
        expect(lastGet(), '/comments');
        expect(page.data.single, isA<DirectusComment>());
        expect(page.data.single.comment.value, 'Bonjour');
      },
    );

    test('anciennes méthodes Map routées vers /folders', () async {
      await FoldersService(http).getFolders();
      expect(lastGet(), '/folders');
    });

    test('itemsOf<DirectusComment>() utilise /comments', () async {
      final client = DirectusClient(
        DirectusConfig(baseUrl: 'https://example.com'),
      );
      final service = client.itemsOf<DirectusComment>();
      expect(service.path, '/comments');
    });
  });

  group('routes corrigées', () {
    test('relations par collection/champ', () async {
      when(
        http.get(
          '/relations/articles/author',
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => ok({
          'data': {
            'collection': 'articles',
            'field': 'author',
            'related_collection': 'directus_users',
            'meta': {'one_field': null, 'junction_field': null},
          },
        }),
      );
      final relation = await RelationsService(
        http,
      ).readOne('articles', 'author');
      expect(relation.relatedCollection.value, 'directus_users');
      expect(relation.relationType, 'Many-to-One');
    });

    test('versions compare / save / promote', () async {
      when(
        http.get(
          '/versions/v1/compare',
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => ok({
          'data': {'outdated': false},
        }),
      );
      final versions = VersionsService(http);
      expect((await versions.compare('v1'))['outdated'], isFalse);
      expect(lastGet(), '/versions/v1/compare');
      await versions.save('v1', {'title': 'x'});
      expect(lastPost(), '/versions/v1/save');
      await versions.promote('v1', mainHash: 'h');
      expect(lastPost(), '/versions/v1/promote');
    });

    test('export en POST avec query et format', () async {
      await UtilitiesService(http).export(
        'articles',
        format: DirectusExportFormat.csv,
        query: QueryParameters(filter: Filter.field('status').equals('draft')),
      );
      final captured =
          verify(
                http.post(
                  '/utils/export/articles',
                  data: captureAnyNamed('data'),
                  queryParameters: anyNamed('queryParameters'),
                  options: anyNamed('options'),
                ),
              ).captured.single
              as Map;
      expect(captured['format'], 'csv');
      expect(captured['query']['filter'], {
        'status': {'_eq': 'draft'},
      });
    });

    test('vérification email via ?token=', () async {
      await UsersService(http).verifyEmail('abc');
      final params = verify(
        http.get(
          '/users/register/verify-email',
          queryParameters: captureAnyNamed('queryParameters'),
          options: anyNamed('options'),
        ),
      ).captured.single;
      expect(params, {'token': 'abc'});
    });

    test('fournisseurs SSO via GET /auth', () async {
      await AuthService(http).listOAuthProviders();
      expect(lastGet(), '/auth');
    });
  });

  group('QueryParameters', () {
    test('meta, version et backlink', () {
      final params = QueryParameters(
        meta: ['total_count', 'filter_count'],
        version: 'draft',
        backlink: false,
      ).toQueryParameters();
      expect(params['meta'], 'total_count,filter_count');
      expect(params['version'], 'draft');
      expect(params['backlink'], false);
    });

    test('toJsonBody garde filtre et champs en objets', () {
      final body = QueryParameters(
        fields: ['id', 'title'],
        filter: Filter.field('id').equals(1),
      ).toJsonBody();
      expect(body['fields'], ['id', 'title']);
      expect(body['filter'], {
        'id': {'_eq': 1},
      });
    });
  });

  group('codes d\'erreur Directus 12', () {
    test('COLLECTION_INACTIVE → permission, avec statusCode', () {
      final e = DirectusException.fromJson({
        'message': 'inactive',
        'extensions': {'code': 'COLLECTION_INACTIVE'},
      }, statusCode: 403);
      expect(e, isA<DirectusPermissionException>());
      expect(e.statusCode, 403);
    });

    test('LICENSE_INVALID → configuration', () {
      final e = DirectusException.fromJson({
        'message': 'license',
        'extensions': {'code': 'LICENSE_INVALID'},
      });
      expect(e, isA<DirectusConfigException>());
    });
  });
}
