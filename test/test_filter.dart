import 'package:fcs_directus/src/request/directus_filter.dart';
import 'package:test/test.dart';

void testFilter() {
  group('Simple Filter', () {
    test('equal int', () {
      print(DirectusFilter("colName", FilterKey.equal, 1));
    });
    test('equal String', () {
      print(DirectusFilter("colName", FilterKey.equal, "toto"));
    });
  });

  group('And Filter', () {
    test('2 test', () {
      print(FilterAnd([
        DirectusFilter("colName", FilterKey.equal, "toto"),
        DirectusFilter("colName", FilterKey.equal, "titi"),
      ]));
    });
  });
}
