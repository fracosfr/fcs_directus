import 'package:dio/dio.dart';
import 'package:fcs_directus/src/services/item_active_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fcs_directus/fcs_directus.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'item_active_service_test.mocks.dart';

// 1. Modèle de test
class TestModel extends DirectusModel {
  TestModel(super.data);
  TestModel.empty() : super.empty();

  @override
  String get itemName => 'test_items';

  String? get title => getString('title');
  set title(String? value) => setString('title', value ?? "");
}

// 2. Annotation pour générer le mock
@GenerateMocks([DirectusHttpClient])
void main() {
  late ItemActiveService<TestModel> service;
  late MockDirectusHttpClient mockHttpClient;

  setUp(() {
    // 3. Initialisation du mock et du service avant chaque test
    mockHttpClient = MockDirectusHttpClient();
    service = ItemActiveService<TestModel>(mockHttpClient, 'test_items');

    // 4. Enregistrement de la factory pour notre modèle de test
    DirectusModel.registerFactory<TestModel>((data) => TestModel(data));
  });

  tearDown(() {
    // 5. Nettoyage après chaque test
    DirectusModel.clearFactories();
  });

  group('ItemActiveService Tests', () {
    test('createOne doit appeler POST avec les bonnes données', () async {
      // Arrange
      final model = TestModel({'id': '1', 'title': 'Test'});
      final responsePayload = {
        'data': {'id': '1', 'title': 'Test'},
      };
      // Simuler une réponse réussie du client HTTP
      when(mockHttpClient.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: responsePayload,
          statusCode: 200,
        ),
      );

      // Act
      final result = await service.createOne(model);

      // Assert
      expect(result, isA<TestModel>());
      expect(result.id, '1');
      expect(result.title, 'Test');
      // Vérifier que la méthode post a été appelée avec les bonnes données
      verify(
        mockHttpClient.post('/items/test_items', data: model.toJson()),
      ).called(1);
    });

    test('updateOne doit appeler PATCH avec les bonnes données', () async {
      // Arrange
      final model = TestModel({'id': '1', 'title': 'Initial'});
      model.title = 'Updated'; // Modifier le modèle pour qu'il soit "dirty"
      final responsePayload = {
        'data': {'id': '1', 'title': 'Updated'},
      };
      when(mockHttpClient.patch(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: responsePayload,
          statusCode: 200,
        ),
      );

      // Act
      final result = await service.updateOne(model);

      // Assert
      expect(result.title, 'Updated');
      // Vérifier que la méthode patch a été appelée avec l'ID correct et les données "dirty"
      verify(
        mockHttpClient.patch('/items/test_items/1', data: model.toJsonDirty()),
      ).called(1);
    });

    test('deleteOne doit appeler DELETE avec le bon ID', () async {
      // Arrange
      final model = TestModel({'id': '1'});
      when(mockHttpClient.delete(any)).thenAnswer(
        (_) async =>
            Response(requestOptions: RequestOptions(path: ''), statusCode: 204),
      );

      // Act
      await service.deleteOne(model);

      // Assert
      // Vérifier que la méthode delete a été appelée avec le bon chemin
      verify(mockHttpClient.delete('/items/test_items/1')).called(1);
    });

    test('readOne doit appeler GET avec le bon ID', () async {
      // Arrange
      final responsePayload = {
        'data': {'id': '1', 'title': 'Test'}
      };
      when(mockHttpClient.get(any)).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: ''), data: responsePayload, statusCode: 200),
      );

      // Act
      final result = await service.readOne('1');

      // Assert
      expect(result, isA<TestModel>());
      expect(result.id, '1');
      expect(result.title, 'Test');
      verify(mockHttpClient.get('/items/test_items/1')).called(1);
    });

    test('readMany doit appeler GET et retourner une liste de modèles', () async {
      // Arrange
      final responsePayload = {
        'data': [
          {'id': '1', 'title': 'Test 1'},
          {'id': '2', 'title': 'Test 2'},
        ],
        'meta': {'total_count': 2}
      };
      when(mockHttpClient.get(any, queryParameters: anyNamed('queryParameters'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: ''), data: responsePayload, statusCode: 200),
      );

      // Act
      final result = await service.readMany(query: QueryParameters(limit: 2));

      // Assert
      expect(result.data, hasLength(2));
      expect(result.data.first, isA<TestModel>());
      expect(result.data.first.title, 'Test 1');
      expect(result.meta?.totalCount, 2);
      verify(mockHttpClient.get('/items/test_items', queryParameters: anyNamed('queryParameters'))).called(1);
    });
  });
}
