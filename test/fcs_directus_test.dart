import 'package:test/test.dart';
import 'package:fcs_directus/fcs_directus.dart';

class _TestModel extends DirectusModel {
  _TestModel(super.data);
  @override
  String get itemName => 'test_items';
}

void main() {
  group('DirectusConfig', () {
    test('crée une configuration valide', () {
      final config = DirectusConfig(
        baseUrl: 'https://directus.example.com',
        timeout: Duration(seconds: 30),
        enableLogging: false,
      );

      expect(config.baseUrl, equals('https://directus.example.com'));
      expect(config.timeout, equals(Duration(seconds: 30)));
      expect(config.enableLogging, isFalse);
    });

    test('rejette une URL invalide', () {
      expect(
        () => DirectusConfig(baseUrl: 'invalid-url'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('copyWith fonctionne correctement', () {
      final config = DirectusConfig(baseUrl: 'https://directus.example.com');

      final newConfig = config.copyWith(
        baseUrl: 'https://new.example.com',
        enableLogging: true,
      );

      expect(newConfig.baseUrl, equals('https://new.example.com'));
      expect(newConfig.enableLogging, isTrue);
      expect(newConfig.timeout, equals(config.timeout));
    });
  });

  group('DirectusClient', () {
    late DirectusClient client;

    setUp(() {
      final config = DirectusConfig(baseUrl: 'https://directus.example.com');
      client = DirectusClient(config);
    });

    tearDown(() {
      client.dispose();
    });

    test('initialise correctement', () {
      expect(client, isNotNull);
      expect(client.auth, isNotNull);
      expect(client.collections, isNotNull);
      expect(client.users, isNotNull);
      expect(client.files, isNotNull);
    });

    test('crée un service items', () {
      final articlesService = client.items('articles');
      expect(articlesService, isNotNull);
      expect(articlesService.collection, equals('articles'));
    });

    test('crée un service items typé', () {
      final articlesService = client.items<Map<String, dynamic>>('articles');
      expect(articlesService, isNotNull);
    });

    test('crée un service itemsOf typé', () {
      // Register factory for the test model
      DirectusModel.registerFactory<_TestModel>((data) => _TestModel(data));

      final itemActiveService = client.itemsOf<_TestModel>();
      expect(itemActiveService, isNotNull);
      expect(itemActiveService, isA<ItemActiveService<_TestModel>>());
      expect(itemActiveService.collection, equals('test_items'));

      // Clean up
      DirectusModel.unregisterFactory<_TestModel>();
    });
  });

  group('QueryParameters', () {
    test('convertit correctement en query parameters', () {
      final query = QueryParameters(
        filter: {
          'status': {'_eq': 'published'},
        },
        fields: ['id', 'title', 'content'],
        sort: ['-date_created', 'title'],
        limit: 10,
        offset: 20,
        search: 'test',
      );

      final params = query.toQueryParameters();

      expect(
        params['filter'],
        equals({
          'status': {'_eq': 'published'},
        }),
      );
      expect(params['fields'], equals('id,title,content'));
      expect(params['sort'], equals('-date_created,title'));
      expect(params['limit'], equals(10));
      expect(params['offset'], equals(20));
      expect(params['search'], equals('test'));
    });

    test('gère les paramètres vides', () {
      final query = QueryParameters();
      final params = query.toQueryParameters();

      expect(params, isEmpty);
    });
  });

  group('DirectusException', () {
    test('crée une exception basique', () {
      final exception = DirectusException(
        message: 'Erreur test',
        statusCode: 400,
      );

      expect(exception.message, equals('Erreur test'));
      expect(exception.statusCode, equals(400));
      expect(exception.toString(), contains('DirectusException'));
      expect(exception.toString(), contains('400'));
    });

    test('crée une exception d\'authentification', () {
      final exception = DirectusAuthException(
        message: 'Non autorisé',
        statusCode: 401,
      );

      expect(exception, isA<DirectusException>());
      expect(exception.toString(), contains('DirectusAuthException'));
    });

    test('crée une exception de validation', () {
      final exception = DirectusValidationException(
        message: 'Validation échouée',
        statusCode: 400,
        extensions: {
          'field_errors': {
            'email': ['Email invalide'],
            'password': ['Trop court'],
          },
        },
      );

      expect(exception.fieldErrors, isNotNull);
      expect(exception.fieldErrors!['email'], contains('Email invalide'));
      expect(exception.toString(), contains('email'));
    });

    test('crée une exception not found', () {
      final exception = DirectusNotFoundException(message: 'Item non trouvé');

      expect(exception.statusCode, equals(404));
      expect(exception, isA<DirectusException>());
    });
  });

  group('AuthResponse', () {
    test('parse correctement depuis JSON', () {
      final json = {
        'access_token': 'test-token',
        'expires': 900000,
        'refresh_token': 'refresh-token',
      };

      final response = AuthResponse.fromJson(json);

      expect(response.accessToken, equals('test-token'));
      expect(response.expiresIn, equals(900000));
      expect(response.refreshToken, equals('refresh-token'));
    });

    test('gère l\'absence de refresh token', () {
      final json = {'access_token': 'test-token', 'expires': 900000};

      final response = AuthResponse.fromJson(json);

      expect(response.accessToken, equals('test-token'));
      expect(response.refreshToken, isNull);
    });
  });

  group('DirectusMeta', () {
    test('parse correctement depuis JSON', () {
      final json = {'total_count': 100, 'filter_count': 50};

      final meta = DirectusMeta.fromJson(json);

      expect(meta.totalCount, equals(100));
      expect(meta.filterCount, equals(50));
    });

    test('gère les valeurs nulles', () {
      final json = <String, dynamic>{};
      final meta = DirectusMeta.fromJson(json);

      expect(meta.totalCount, isNull);
      expect(meta.filterCount, isNull);
    });
  });

  group('DirectusWebSocketMessage', () {
    test('convertit de/vers JSON', () {
      final message = DirectusWebSocketMessage(
        type: 'subscribe',
        data: {'collection': 'articles'},
        uid: 'sub_1',
        event: DirectusItemEvent.create,
      );

      final json = message.toJson();
      expect(json['type'], equals('subscribe'));
      expect(json['data'], equals({'collection': 'articles'}));
      expect(json['uid'], equals('sub_1'));
      expect(json['event'], equals('create'));

      final parsed = DirectusWebSocketMessage.fromJson(json);
      expect(parsed.type, equals(message.type));
      expect(parsed.data, equals(message.data));
      expect(parsed.uid, equals(message.uid));
      expect(parsed.event, equals(message.event));
    });

    test('gère les champs optionnels', () {
      final message = DirectusWebSocketMessage(type: 'ping');
      final json = message.toJson();

      expect(json['type'], equals('ping'));
      expect(json.containsKey('data'), isFalse);
      expect(json.containsKey('uid'), isFalse);
      expect(json.containsKey('event'), isFalse);
    });
  });
}
