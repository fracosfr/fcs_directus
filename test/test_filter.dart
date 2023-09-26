import 'package:fcs_directus/src/request/directus_filter.dart';
import 'package:test/test.dart';

void testFilter() {
  group('Simple Filter', () {
    test('equal int', () {
      print(Filter.equal("colName", 1));
    });
    test('equal String', () {
      print(Filter.equal("colName", "toto"));
    });
  });

  group('And Filter', () {
    test('2 test', () {
      print(Filter.and([
        Filter.equal("colName", "toto"),
        Filter.equal("colName", "titi"),
        Filter.or([
          Filter.equal("colName", "A"),
          Filter.equal("colName", "B"),
        ])
      ]));
    });
  });

  group('Sub columns', () {
    test('3 levels equal true', () {
      print(Filter.equal("colA.subA.subsubA", true));
    });
  });
}
