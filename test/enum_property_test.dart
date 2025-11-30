import 'package:fcs_directus/fcs_directus.dart';
import 'package:test/test.dart';

enum TestStatus { draft, published, archived }

enum Priority { low, medium, high }

enum TaskStatus { todo, inProgress, done }

class TestModel extends DirectusModel {
  TestModel(super.data);
  TestModel.empty() : super.empty();

  @override
  String get itemName => 'test_items';

  late final status = enumValue<TestStatus>(
    'status',
    TestStatus.draft,
    TestStatus.values,
  );
  late final priority = enumValue<Priority>(
    'priority',
    Priority.medium,
    Priority.values,
  );
}

class TaskModel extends DirectusModel {
  TaskModel(super.data);

  @override
  String get itemName => 'tasks';

  late final status = enumValue<TaskStatus>(
    'status',
    TaskStatus.todo,
    TaskStatus.values,
  );
}

void main() {
  group('EnumProperty', () {
    test('devrait convertir String en Enum correctement', () {
      final model = TestModel({'status': 'published'});

      expect(model.status.value, equals(TestStatus.published));
      expect(model.status.asString, equals('published'));
    });

    test('devrait utiliser la valeur par défaut pour valeur invalide', () {
      final model = TestModel({'status': 'invalid_value'});

      expect(model.status.value, equals(TestStatus.draft));
    });

    test('devrait utiliser la valeur par défaut pour valeur absente', () {
      final model = TestModel({});

      expect(model.status.value, equals(TestStatus.draft));
    });

    test('devrait être insensible à la casse', () {
      final model1 = TestModel({'status': 'PUBLISHED'});
      final model2 = TestModel({'status': 'Published'});
      final model3 = TestModel({'status': 'published'});

      expect(model1.status.value, equals(TestStatus.published));
      expect(model2.status.value, equals(TestStatus.published));
      expect(model3.status.value, equals(TestStatus.published));
    });

    test('devrait définir la valeur correctement', () {
      final model = TestModel.empty();

      model.status.set(TestStatus.archived);

      expect(model.status.value, equals(TestStatus.archived));
      expect(model.status.asString, equals('archived'));
    });

    test('devrait stocker la valeur en tant que String dans _data', () {
      final model = TestModel.empty();

      model.status.set(TestStatus.published);

      final json = model.toJson();
      expect(json['status'], equals('published'));
      expect(json['status'], isA<String>());
    });

    test('setFromString devrait convertir correctement', () {
      final model = TestModel.empty();

      model.status.setFromString('archived');

      expect(model.status.value, equals(TestStatus.archived));
    });

    test('setFromString devrait utiliser la valeur par défaut si invalide', () {
      final model = TestModel.empty();
      model.status.set(TestStatus.published); // Définir une valeur initiale

      model.status.setFromString('invalid');

      expect(model.status.value, equals(TestStatus.draft));
    });

    test('is_ devrait vérifier la valeur correctement', () {
      final model = TestModel({'status': 'published'});

      expect(model.status.is_(TestStatus.published), isTrue);
      expect(model.status.is_(TestStatus.draft), isFalse);
      expect(model.status.is_(TestStatus.archived), isFalse);
    });

    test('isOneOf devrait vérifier plusieurs valeurs', () {
      final model = TestModel({'status': 'published'});

      expect(
        model.status.isOneOf([TestStatus.published, TestStatus.archived]),
        isTrue,
      );
      expect(
        model.status.isOneOf([TestStatus.draft, TestStatus.archived]),
        isFalse,
      );
    });

    test('allValues devrait retourner toutes les valeurs possibles', () {
      final model = TestModel.empty();

      final allValues = model.status.allValues;

      expect(allValues, contains(TestStatus.draft));
      expect(allValues, contains(TestStatus.published));
      expect(allValues, contains(TestStatus.archived));
      expect(allValues.length, equals(3));
    });

    test('reset devrait remettre à la valeur par défaut', () {
      final model = TestModel.empty();
      model.status.set(TestStatus.published);

      model.status.reset();

      expect(model.status.value, equals(TestStatus.draft));
    });

    test('devrait fonctionner avec plusieurs enums dans le même modèle', () {
      final model = TestModel({'status': 'published', 'priority': 'high'});

      expect(model.status.value, equals(TestStatus.published));
      expect(model.priority.value, equals(Priority.high));
    });

    test('devrait supporter le dirty tracking', () {
      final model = TestModel({'status': 'draft'});

      expect(model.isDirty, isFalse);

      model.status.set(TestStatus.published);

      expect(model.isDirty, isTrue);
      expect(model.dirtyFields, contains('status'));
    });

    test('toJsonDirty devrait inclure les enums modifiés', () {
      final model = TestModel({'status': 'draft', 'priority': 'low'});
      model.markClean();

      model.status.set(TestStatus.published);

      final dirty = model.toJsonDirty();

      expect(dirty, containsPair('status', 'published'));
      expect(dirty.containsKey('priority'), isFalse); // Pas modifié
    });

    test('exists devrait retourner true si la clé existe', () {
      final model = TestModel({'status': 'published'});

      expect(model.status.exists, isTrue);
    });

    test('exists devrait retourner false si la clé n\'existe pas', () {
      final model = TestModel({});

      expect(model.status.exists, isFalse);
    });

    test('remove devrait supprimer le champ', () {
      final model = TestModel({'status': 'published'});

      model.status.remove();

      expect(model.status.exists, isFalse);
      expect(model.status.value, equals(TestStatus.draft)); // Valeur par défaut
    });

    test('toString devrait retourner la représentation String de l\'enum', () {
      final model = TestModel({'status': 'published'});

      expect(model.status.toString(), contains('published'));
    });

    test('devrait gérer les enums avec camelCase', () {
      // Exemple: inProgress dans TaskStatus
      // Le String Directus pourrait être "inProgress" ou "in_progress"
      // On teste que ça fonctionne avec le nom exact de l'enum

      // Test avec le nom exact
      final model1 = TaskModel({'status': 'inProgress'});
      expect(model1.status.value, equals(TaskStatus.inProgress));

      // Test avec majuscules différentes
      final model2 = TaskModel({'status': 'INPROGRESS'});
      expect(model2.status.value, equals(TaskStatus.inProgress));

      // Test avec underscore (ne devrait PAS matcher)
      final model3 = TaskModel({'status': 'in_progress'});
      expect(model3.status.value, equals(TaskStatus.todo)); // Fallback
    });

    test('devrait supporter la sérialisation complète', () {
      final model = TestModel({
        'id': '123',
        'status': 'published',
        'priority': 'high',
      });

      final json = model.toJson();

      expect(json['id'], equals('123'));
      expect(json['status'], equals('published'));
      expect(json['priority'], equals('high'));

      // Recréer depuis JSON
      final model2 = TestModel(json);

      expect(model2.status.value, equals(TestStatus.published));
      expect(model2.priority.value, equals(Priority.high));
    });
  });
}
