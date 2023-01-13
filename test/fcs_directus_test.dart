import 'package:fcs_directus/fcs_directus.dart';
import 'package:test/test.dart';

void main() {
  FcsDirectus directus =
      FcsDirectus(serverUrl: "https://sbbwpdpa.directus.app/");

  group('Authentification', () {
    //final awesome = Awesome();

    setUp(() {});

    test('Email/Password Authentification', () async {
      try {
        await directus.auth
            .login(login: "login@mail.com", password: "password");
      } catch (e) {
        print(e.toString());
      }
    });
  });

  group('Basic Items management', () {
    setUp(() {});

    test('Get ALLS Cars', () async {
      try {
        print((await directus.item("car").getMultiples()).length);
      } catch (e) {
        print(e.toString());
      }
    });
    test('Get Cars with HP > 120', () async {
      try {
        print((await directus.item("car").getMultiples(
          filter: {
            "hp": {DirectusFilter.greaterThan: 130}
          },
        ))
            .length);
      } catch (e) {
        print(e.toString());
      }
    });
  });
}
