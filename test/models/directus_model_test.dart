import 'package:flutter_test/flutter_test.dart';
import 'package:fcs_directus/fcs_directus.dart';

// Classe de test concrète héritant de DirectusModel
class TestModel extends DirectusModel {
  final String name;
  final int? age;

  TestModel({
    super.id,
    required this.name,
    this.age,
    super.dateCreated,
    super.dateUpdated,
  });

  @override
  Map<String, dynamic> toMap() {
    return {'name': name, if (age != null) 'age': age};
  }

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: DirectusModel.parseId(json['id']),
      name: json['name'] as String,
      age: json['age'] as int?,
      dateCreated: DirectusModel.parseDate(json['date_created']),
      dateUpdated: DirectusModel.parseDate(json['date_updated']),
    );
  }
}

void main() {
  group('DirectusModel', () {
    test('crée un modèle avec tous les champs', () {
      final model = TestModel(
        id: '123',
        name: 'Test',
        age: 25,
        dateCreated: DateTime(2024, 1, 1),
        dateUpdated: DateTime(2024, 1, 2),
      );

      expect(model.id, equals('123'));
      expect(model.name, equals('Test'));
      expect(model.age, equals(25));
      expect(model.dateCreated, equals(DateTime(2024, 1, 1)));
      expect(model.dateUpdated, equals(DateTime(2024, 1, 2)));
    });

    test('crée un modèle avec champs optionnels nulls', () {
      final model = TestModel(name: 'Test');

      expect(model.id, isNull);
      expect(model.age, isNull);
      expect(model.dateCreated, isNull);
      expect(model.dateUpdated, isNull);
    });

    test('toJson inclut tous les champs non-null', () {
      final model = TestModel(
        id: '123',
        name: 'Test',
        age: 25,
        dateCreated: DateTime(2024, 1, 1),
      );

      final json = model.toJson();

      expect(json['id'], equals('123'));
      expect(json['name'], equals('Test'));
      expect(json['age'], equals(25));
      expect(json['date_created'], equals('2024-01-01T00:00:00.000'));
      expect(json.containsKey('date_updated'), isFalse);
    });

    test('toJson exclut les champs null', () {
      final model = TestModel(name: 'Test');
      final json = model.toJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('age'), isFalse);
      expect(json.containsKey('date_created'), isFalse);
      expect(json.containsKey('date_updated'), isFalse);
      expect(json['name'], equals('Test'));
    });

    test('fromJson parse correctement', () {
      final json = {
        'id': 456,
        'name': 'Test',
        'age': 30,
        'date_created': '2024-01-01T10:00:00.000Z',
        'date_updated': '2024-01-02T15:30:00.000Z',
      };

      final model = TestModel.fromJson(json);

      expect(model.id, equals('456'));
      expect(model.name, equals('Test'));
      expect(model.age, equals(30));
      expect(model.dateCreated, isNotNull);
      expect(model.dateUpdated, isNotNull);
    });

    test('parseDate gère différents types', () {
      expect(DirectusModel.parseDate(null), isNull);
      expect(DirectusModel.parseDate('2024-01-01'), isNotNull);
      expect(
        DirectusModel.parseDate(DateTime(2024, 1, 1)),
        equals(DateTime(2024, 1, 1)),
      );
      expect(DirectusModel.parseDate('invalid'), isNull);
    });

    test('parseId convertit différents types en String', () {
      expect(DirectusModel.parseId(null), isNull);
      expect(DirectusModel.parseId(123), equals('123'));
      expect(DirectusModel.parseId('abc'), equals('abc'));
      expect(DirectusModel.parseId(true), equals('true'));
    });

    test('toString retourne le type et l\'id', () {
      final model = TestModel(id: '123', name: 'Test');
      expect(model.toString(), equals('TestModel(id: 123)'));
    });

    test('equality fonctionne correctement', () {
      final model1 = TestModel(id: '123', name: 'Test');
      final model2 = TestModel(id: '123', name: 'Test');
      final model3 = TestModel(id: '456', name: 'Test');

      expect(model1 == model2, isTrue);
      expect(model1 == model3, isFalse);
    });

    test('hashCode est basé sur id et type', () {
      final model1 = TestModel(id: '123', name: 'Test');
      final model2 = TestModel(id: '123', name: 'Different');

      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('round-trip JSON fonctionne', () {
      final original = TestModel(
        id: '999',
        name: 'Original',
        age: 42,
        dateCreated: DateTime(2024, 6, 15),
      );

      final json = original.toJson();
      final restored = TestModel.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.age, equals(original.age));
      expect(
        restored.dateCreated?.toIso8601String(),
        equals(original.dateCreated?.toIso8601String()),
      );
    });
  });
}
