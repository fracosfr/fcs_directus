import 'package:fcs_directus/fcs_directus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    // Enregistrer une factory pour DynamicModel
    DirectusModel.registerFactory<DynamicModel>(
      (data) => DynamicModel(data, itemName: 'test'),
    );
  });

  group('BoolProperty diagnostic tests', () {
    test('should return true when value is explicitly true', () {
      final model = DynamicModel({'active': true}, itemName: 'test');
      final prop = model.boolValue('active');

      print('Test 1 - true explicite:');
      print('  Valeur dans _data: ${model.toJson()['active']}');
      print('  getBool retourne: ${model.getBool('active')}');
      print('  prop.value retourne: ${prop.value}');

      expect(
        model.getBool('active'),
        isTrue,
        reason: 'getBool should return true',
      );
      expect(
        prop.value,
        isTrue,
        reason: 'BoolProperty.value should return true',
      );
    });

    test('should return false when value is explicitly false', () {
      final model = DynamicModel({'active': false}, itemName: 'test');
      final prop = model.boolValue('active');

      print('Test 2 - false explicite:');
      print('  Valeur dans _data: ${model.toJson()['active']}');
      print('  getBool retourne: ${model.getBool('active')}');
      print('  prop.value retourne: ${prop.value}');

      expect(
        model.getBool('active'),
        isFalse,
        reason: 'getBool should return false',
      );
      expect(
        prop.value,
        isFalse,
        reason: 'BoolProperty.value should return false',
      );
    });

    test('should return defaultValue (false) when value is absent', () {
      final model = DynamicModel({}, itemName: 'test');
      final prop = model.boolValue('active');

      print('Test 3 - valeur absente:');
      print('  Valeur dans _data: ${model.toJson()['active']}');
      print('  getBool retourne: ${model.getBool('active')}');
      print('  prop.value retourne: ${prop.value}');

      expect(
        model.getBool('active'),
        isFalse,
        reason: 'getBool should return defaultValue (false)',
      );
      expect(
        prop.value,
        isFalse,
        reason: 'BoolProperty.value should return defaultValue (false)',
      );
    });

    test('should convert int 1 to true', () {
      final model = DynamicModel({'active': 1}, itemName: 'test');
      final prop = model.boolValue('active');

      print('Test 4 - valeur int 1:');
      print('  Valeur dans _data: ${model.toJson()['active']}');
      print('  getBool retourne: ${model.getBool('active')}');
      print('  prop.value retourne: ${prop.value}');

      expect(
        model.getBool('active'),
        isTrue,
        reason: 'getBool should convert 1 to true',
      );
      expect(
        prop.value,
        isTrue,
        reason: 'BoolProperty.value should convert 1 to true',
      );
    });

    test('should convert int 0 to false', () {
      final model = DynamicModel({'active': 0}, itemName: 'test');
      final prop = model.boolValue('active');

      print('Test 5 - valeur int 0:');
      print('  Valeur dans _data: ${model.toJson()['active']}');
      print('  getBool retourne: ${model.getBool('active')}');
      print('  prop.value retourne: ${prop.value}');

      expect(
        model.getBool('active'),
        isFalse,
        reason: 'getBool should convert 0 to false',
      );
      expect(
        prop.value,
        isFalse,
        reason: 'BoolProperty.value should convert 0 to false',
      );
    });

    test('should convert string "true" to true', () {
      final model = DynamicModel({'active': 'true'}, itemName: 'test');
      final prop = model.boolValue('active');

      print('Test 6 - string "true":');
      print('  Valeur dans _data: ${model.toJson()['active']}');
      print('  getBool retourne: ${model.getBool('active')}');
      print('  prop.value retourne: ${prop.value}');

      expect(
        model.getBool('active'),
        isTrue,
        reason: 'getBool should convert "true" to true',
      );
      expect(
        prop.value,
        isTrue,
        reason: 'BoolProperty.value should convert "true" to true',
      );
    });

    test('should convert string "false" to false', () {
      final model = DynamicModel({'active': 'false'}, itemName: 'test');
      final prop = model.boolValue('active');

      print('Test 7 - string "false":');
      print('  Valeur dans _data: ${model.toJson()['active']}');
      print('  getBool retourne: ${model.getBool('active')}');
      print('  prop.value retourne: ${prop.value}');

      expect(
        model.getBool('active'),
        isFalse,
        reason: 'getBool should convert "false" to false',
      );
      expect(
        prop.value,
        isFalse,
        reason: 'BoolProperty.value should convert "false" to false',
      );
    });

    test('should use custom defaultValue when specified', () {
      final model = DynamicModel({}, itemName: 'test');
      final prop = model.boolValue('active', defaultValue: true);

      print('Test 8 - defaultValue = true:');
      print('  Valeur dans _data: ${model.toJson()['active']}');
      print(
        '  getBool(defaultValue: true) retourne: ${model.getBool('active', defaultValue: true)}',
      );
      print('  prop.value retourne: ${prop.value}');

      expect(
        model.getBool('active', defaultValue: true),
        isTrue,
        reason: 'getBool should return custom defaultValue (true)',
      );
      expect(
        prop.value,
        isTrue,
        reason: 'BoolProperty.value should return custom defaultValue (true)',
      );
    });
  });
}
