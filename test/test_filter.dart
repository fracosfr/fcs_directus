import 'package:fcs_directus/src/request/directus_filter.dart';
import 'package:test/test.dart';

void testFilter() {
  group('Simple Filter', () {
    test('equal int', () {
      print(Filter("colName", FilterKey.equal, 1));
    });
    test('equal String', () {
      print(Filter("colName", FilterKey.equal, "toto"));
    });
  });

  group('And Filter', () {
    test('2 test', () {
      print(FilterAnd([
        Filter("colName", FilterKey.equal, "toto"),
        Filter("colName", FilterKey.equal, "titi"),
      ]));
    });
  });
}
