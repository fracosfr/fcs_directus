import 'package:flutter_test/flutter_test.dart';
import 'package:fcs_directus/fcs_directus.dart';

// Classe de test
class TestModel extends DirectusModel {
  final String name;
  final int? age;

  TestModel._({super.id, required this.name, this.age, super.dateCreated});

  factory TestModel.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    return TestModel._(
      id: builder.id,
      name: builder.getString('name'),
      age: builder.getIntOrNull('age'),
      dateCreated: builder.dateCreated,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return DirectusMapBuilder()
        .add('name', name)
        .addIfNotNull('age', age)
        .build();
  }
}

void main() {
  group('DirectusModelBuilder', () {
    test('récupère les champs de base', () {
      final json = {
        'id': '123',
        'date_created': '2024-01-01T00:00:00.000Z',
        'date_updated': '2024-01-02T00:00:00.000Z',
      };

      final builder = DirectusModelBuilder(json);

      expect(builder.id, equals('123'));
      expect(builder.dateCreated, isNotNull);
      expect(builder.dateUpdated, isNotNull);
    });

    test('getString fonctionne correctement', () {
      final builder = DirectusModelBuilder({'name': 'Test'});
      expect(builder.getString('name'), equals('Test'));
    });

    test('getString avec defaultValue', () {
      final builder = DirectusModelBuilder({});
      expect(
        builder.getString('missing', defaultValue: 'default'),
        equals('default'),
      );
    });

    test('getString lance une exception si le champ manque', () {
      final builder = DirectusModelBuilder({});
      expect(() => builder.getString('missing'), throwsException);
    });

    test('getStringOrNull retourne null pour champ manquant', () {
      final builder = DirectusModelBuilder({});
      expect(builder.getStringOrNull('missing'), isNull);
    });

    test('getInt parse différents types', () {
      final builder = DirectusModelBuilder({
        'int': 42,
        'double': 42.7,
        'string': '42',
      });

      expect(builder.getInt('int'), equals(42));
      expect(builder.getInt('double'), equals(42));
      expect(builder.getInt('string'), equals(42));
    });

    test('getIntOrNull retourne null pour champ manquant', () {
      final builder = DirectusModelBuilder({});
      expect(builder.getIntOrNull('missing'), isNull);
    });

    test('getDouble parse différents types', () {
      final builder = DirectusModelBuilder({
        'int': 42,
        'double': 42.5,
        'string': '42.5',
      });

      expect(builder.getDouble('int'), equals(42.0));
      expect(builder.getDouble('double'), equals(42.5));
      expect(builder.getDouble('string'), equals(42.5));
    });

    test('getBool parse différents types', () {
      final builder = DirectusModelBuilder({
        'bool': true,
        'int1': 1,
        'int0': 0,
        'stringTrue': 'true',
        'stringFalse': 'false',
      });

      expect(builder.getBool('bool'), isTrue);
      expect(builder.getBool('int1'), isTrue);
      expect(builder.getBool('int0'), isFalse);
      expect(builder.getBool('stringTrue'), isTrue);
      expect(builder.getBool('stringFalse'), isFalse);
    });

    test('getDateTime parse les dates', () {
      final builder = DirectusModelBuilder({
        'date': '2024-01-01T10:00:00.000Z',
      });

      final date = builder.getDateTime('date');
      expect(date, isNotNull);
      expect(date.year, equals(2024));
    });

    test('getList parse les listes', () {
      final builder = DirectusModelBuilder({
        'tags': ['tag1', 'tag2', 'tag3'],
      });

      final tags = builder.getList<String>('tags', (item) => item.toString());
      expect(tags, hasLength(3));
      expect(tags, contains('tag1'));
    });

    test('getObject parse les objets nested', () {
      final builder = DirectusModelBuilder({
        'author': {'id': '999', 'name': 'John'},
      });

      final author = builder.getObject('author', (json) {
        return {'id': json['id'], 'name': json['name']};
      });

      expect(author['id'], equals('999'));
      expect(author['name'], equals('John'));
    });

    test('has vérifie l\'existence d\'un champ', () {
      final builder = DirectusModelBuilder({'name': 'Test'});
      expect(builder.has('name'), isTrue);
      expect(builder.has('missing'), isFalse);
    });
  });

  group('DirectusMapBuilder', () {
    test('add ajoute des champs', () {
      final map = DirectusMapBuilder()
          .add('name', 'Test')
          .add('age', 25)
          .build();

      expect(map['name'], equals('Test'));
      expect(map['age'], equals(25));
    });

    test('addIfNotNull exclut les null', () {
      final map = DirectusMapBuilder()
          .add('name', 'Test')
          .addIfNotNull('age', null)
          .addIfNotNull('city', 'Paris')
          .build();

      expect(map.containsKey('age'), isFalse);
      expect(map['city'], equals('Paris'));
    });

    test('addIf ajoute conditionnellement', () {
      final map = DirectusMapBuilder()
          .addIf(true, 'field1', 'value1')
          .addIf(false, 'field2', 'value2')
          .build();

      expect(map.containsKey('field1'), isTrue);
      expect(map.containsKey('field2'), isFalse);
    });

    test('addAll fusionne des maps', () {
      final map = DirectusMapBuilder().add('name', 'Test').addAll({
        'age': 25,
        'city': 'Paris',
      }).build();

      expect(map['name'], equals('Test'));
      expect(map['age'], equals(25));
      expect(map['city'], equals('Paris'));
    });

    test('addRelation ajoute seulement l\'ID', () {
      final author = TestModel.fromJson({'id': '123', 'name': 'John'});

      final map = DirectusMapBuilder()
          .add('title', 'Test')
          .addRelation('author', author)
          .build();

      expect(map['author'], equals('123'));
    });

    test('addRelation ignore les null', () {
      final map = DirectusMapBuilder()
          .add('title', 'Test')
          .addRelation('author', null)
          .build();

      expect(map.containsKey('author'), isFalse);
    });
  });

  group('DirectusModelRegistry', () {
    tearDown(() {
      DirectusModelRegistry.clear();
    });

    test('enregistre et crée des modèles', () {
      DirectusModelRegistry.register<TestModel>(
        (json) => TestModel.fromJson(json),
      );

      final model = DirectusModelRegistry.create<TestModel>({
        'id': '123',
        'name': 'Test',
      });

      expect(model.id, equals('123'));
      expect(model.name, equals('Test'));
    });

    test('createList crée une liste de modèles', () {
      DirectusModelRegistry.register<TestModel>(
        (json) => TestModel.fromJson(json),
      );

      final models = DirectusModelRegistry.createList<TestModel>([
        {'id': '1', 'name': 'Test1'},
        {'id': '2', 'name': 'Test2'},
      ]);

      expect(models, hasLength(2));
      expect(models[0].name, equals('Test1'));
      expect(models[1].name, equals('Test2'));
    });

    test('isRegistered vérifie l\'enregistrement', () {
      expect(DirectusModelRegistry.isRegistered<TestModel>(), isFalse);

      DirectusModelRegistry.register<TestModel>(
        (json) => TestModel.fromJson(json),
      );

      expect(DirectusModelRegistry.isRegistered<TestModel>(), isTrue);
    });

    test('unregister supprime une factory', () {
      DirectusModelRegistry.register<TestModel>(
        (json) => TestModel.fromJson(json),
      );
      expect(DirectusModelRegistry.isRegistered<TestModel>(), isTrue);

      DirectusModelRegistry.unregister<TestModel>();
      expect(DirectusModelRegistry.isRegistered<TestModel>(), isFalse);
    });

    test('clear supprime toutes les factories', () {
      DirectusModelRegistry.register<TestModel>(
        (json) => TestModel.fromJson(json),
      );
      expect(DirectusModelRegistry.isRegistered<TestModel>(), isTrue);

      DirectusModelRegistry.clear();
      expect(DirectusModelRegistry.isRegistered<TestModel>(), isFalse);
    });

    test('create lance une exception si pas de factory', () {
      expect(
        () => DirectusModelRegistry.create<TestModel>({'name': 'Test'}),
        throwsException,
      );
    });
  });

  group('Integration with DirectusModel', () {
    test('fromJson avec builder fonctionne', () {
      final json = {
        'id': '456',
        'name': 'Test Model',
        'age': 30,
        'date_created': '2024-01-01T00:00:00.000Z',
      };

      final model = TestModel.fromJson(json);

      expect(model.id, equals('456'));
      expect(model.name, equals('Test Model'));
      expect(model.age, equals(30));
      expect(model.dateCreated, isNotNull);
    });

    test('toMap avec builder fonctionne', () {
      final model = TestModel.fromJson({
        'id': '123',
        'name': 'Test',
        'age': 25,
      });

      final map = model.toMap();

      expect(map['name'], equals('Test'));
      expect(map['age'], equals(25));
      expect(map.containsKey('id'), isFalse); // id géré par toJson()
    });

    test('toJson combine toMap et champs de base', () {
      final model = TestModel.fromJson({
        'id': '123',
        'name': 'Test',
        'age': 25,
        'date_created': '2024-01-01T00:00:00.000Z',
      });

      final json = model.toJson();

      expect(json['id'], equals('123'));
      expect(json['name'], equals('Test'));
      expect(json['age'], equals(25));
      expect(json['date_created'], isNotNull);
    });
  });
}
