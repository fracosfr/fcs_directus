import 'dart:math';

import 'package:fcs_directus/fcs_directus.dart';
import 'package:test/test.dart';

import 'brand_object.dart';
import 'car_object.dart';

void testApi() {
  FcsDirectus directus =
      FcsDirectus(serverUrl: "https://sbbwpdpa.directus.app/");

  group('Authentification', () {
    //directus.debug = true;
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

  group('Items', () {
    setUp(() {});

    test('Get ALLS Cars', () async {
      try {
        print((await directus.item("car").readMany()).length);
      } catch (e) {
        print(e.toString());
      }
    });
    test('Get Cars with HP > 120', () async {
      try {
        print((await directus.item("car").readMany(
                  params: DirectusParams(filter: {
                    "hp": {DirectusFilterVar.greaterThan: 130}
                  }),
                ))
            .length);
      } catch (e) {
        print(e.toString());
      }
    });

    test('Get 3 first Cars', () async {
      try {
        print((await directus
                .item("car")
                .readMany(params: DirectusParams(limit: 3)))
            .length);
      } catch (e) {
        print(e.toString());
      }
    });
    test('Search 08', () async {
      try {
        print((await directus
                .item("car")
                .readMany(params: DirectusParams(search: "08")))
            .length);
      } catch (e) {
        print(e.toString());
      }
    });
    test('Total car by brand', () async {
      try {
        print((await directus.item("car").readMany(
                    params: DirectusParams(
                  aggregate: DirectusParamsAggregate(
                    type: DirectusAggregateType.count,
                    field: "id",
                    groupBy: ["brand"],
                  ),
                )))
            .length);
      } catch (e) {
        print(e.toString());
      }
    });

    test('Read 508 (by ID)', () async {
      try {
        print((await directus
                .item("car")
                .readOne("cd512cc6-6951-45d1-86af-8bc468c23b0b"))
            .length);
      } catch (e) {
        print(e.toString());
      }
    });
  }, skip: true);

  group("Server", () {
    test("PING", () async {
      try {
        print(await directus.server.ping());
      } catch (e) {
        print(e.toString());
      }
    });

    test("Server info", () async {
      try {
        print((await directus.server.info()).projecName);
      } catch (e) {
        print(e.toString());
      }
    });

    test("Server health", () async {
      try {
        print((await directus.server.health()).status);
      } catch (e) {
        print(e.toString());
      }
    });
  }, skip: true);

  group("creation/update/delete item", () {
    test("Create one item", () async {
      try {
        print(await directus.item("test").createOne({
          "name": "Un item test ${DateTime.now().toString()}",
          "textarea": "Du texte dans une textarea\nSur 2 lignes pour le fun.",
          "bool_value": true,
        }));
      } catch (e) {
        print(e.toString());
      }
    });

    test("Create many item", () async {
      try {
        print(await directus.item("test").createMany(
          [
            {"name": "Un item 1", "textarea": "Du texte..."},
            {
              "name": "Un item 2",
              "textarea": "Encore du texte...",
              "bool_value": true,
            },
            {
              "name": "Un dernier item",
              "textarea": "Toujours duu texte...",
              "bool_value": true
            },
          ],
        ));
      } catch (e) {
        print(e.toString());
      }
    });

    test("Update one item", () async {
      try {
        final item = await directus
            .item("test")
            .readOne("727b9580-26ad-4f19-bfe0-ecbedc25d7af");

        print(await directus.item("test").updateOne(
          "727b9580-26ad-4f19-bfe0-ecbedc25d7af",
          {
            "textarea": DateTime.now().toString(),
            "bool_value": !(item["bool_value"] ?? false),
          },
        ));
      } catch (e) {
        print(e.toString());
      }
    }, skip: true);

    test("Update many items", () async {
      try {
        final item = await directus
            .item("test")
            .readOne("fe56053b-ebef-4373-8042-45701c90ae2a");

        print(await directus.item("test").updateMany(
          [
            "e894e891-9420-4cce-b5e2-282033c46a98",
            "fe56053b-ebef-4373-8042-45701c90ae2a",
            "cee670df-6216-4d00-858d-4a83eed5a6de",
          ],
          {
            "textarea": DateTime.now().toString(),
            "bool_value": !(item["bool_value"] ?? false),
          },
        ));
      } catch (e) {
        print(e.toString());
      }
    });

    test("Delete one item", () async {
      try {
        final items = await directus
            .item("test")
            .readMany(params: DirectusParams(search: "dernier"));

        if (items.isNotEmpty) {
          await directus.item("test").deleteOne(items.first["id"]);
        }
      } catch (e) {
        print(e.toString());
      }
    });

    test("Delete many item", () async {
      try {
        final items = await directus
            .item("test")
            .readMany(params: DirectusParams(search: "Un item "));

        final List<String> ids = [];
        for (final item in items) {
          ids.add(item["id"]);
        }

        if (items.isNotEmpty) {
          await directus.item("test").deleteMany(ids);
        }
      } catch (e) {
        print(e.toString());
      }
    });
  }, skip: true);

  group("Object management", () {
    test("get One by ID", () async {
      CarObject? car = await directus.object.getById(
        id: "cd512cc6-6951-45d1-86af-8bc468c23b0b",
        itemCreator: CarObject.creator,
      );

      if (car == null) return;

      print("${car.identifier} : ${car.name}");
      print("Brand = (${car.brandId}) ${car.brandObject.name}");

      car.name = "F150";
      car.brandObject.name = "Ford";

      print("${car.identifier} : ${car.name}");
      print("Brand = (${car.brandId}) ${car.brandObject.name}");
    });

    test("Get many cars", () async {
      List<CarObject> cars = await directus.object.getMany(
          itemCreator: CarObject.creator,
          params: DirectusParams(filter: {
            "hp": {DirectusFilterVar.lessThan: 200}
          }));

      for (final car in cars) {
        print("${car.name} (${car.brandObject.name})");
      }
    });

    test("Create a car", () async {
      CarObject myCar = CarObject(
          name: "XC90",
          doors: 5,
          brandId: "dd95329d-e6cf-4cd5-92f2-f8dac41bf178");
      myCar = await directus.object.createOne(myCar);
    });

    test("Create a car with existing brand", () async {
      BrandObject? brand = await directus.object.getOne(
          itemCreator: BrandObject.creator,
          params: DirectusParams(filter: {
            "name": {DirectusFilterVar.equals: "Peugeot"}
          }));

      if (brand == null) return;

      CarObject car = CarObject(name: "306", doors: 3);
      car.brandObject = brand;

      //car = await directus.object.createOne(car);
    });

    test("Create many cars", () async {
      final brand = await directus.object.getOne(
          itemCreator: BrandObject.creator,
          params: DirectusParams(filter: {
            "name": {DirectusFilterVar.equals: "Ford"}
          }));

      if (brand == null) return;

      final myCars = [
        CarObject(name: "Fiesta", doors: 5, brandId: brand.identifier),
        CarObject(name: "Focus", doors: 5, brandId: brand.identifier),
        CarObject(name: "F150", doors: 5, brandId: brand.identifier),
      ];

      final res = await directus.object.createMany(
        objects: myCars,
        itemCreator: CarObject.creator,
      );
    });

    test("Update one car", () async {
      final car = await directus.object.getOne(
        itemCreator: CarObject.creator,
        params: DirectusParams(
          filter: {
            "name": {DirectusFilterVar.equals: "Berlingo"}
          },
        ),
      );

      if (car == null) return;

      car.doors++;

      final updatedCar = await directus.object.updateOne(car);
      print(updatedCar.doors);
    });

    test("Update many cars", () async {
      final cars = await directus.object.getMany(
        itemCreator: CarObject.creator,
        params: DirectusParams(
          filter: {
            "brand": {
              "name": {DirectusFilterVar.equals: "Peugeot"}
            }
          },
        ),
      );

      CarObject carData = CarObject.empty();
      carData.doors = Random().nextInt(9) + 1;

      final updatedCars = await directus.object.updateMany(
          objects: cars, itemCreator: CarObject.creator, sourceObject: carData);

      for (final car in updatedCars) {
        print("${car.name} : ${car.doors} doors !");
      }
    });

    test("Delete One car", () async {
      final car = await directus.object.getOne(
        itemCreator: CarObject.creator,
        params: DirectusParams(
          filter: {
            "brand": {
              "name": {DirectusFilterVar.equals: "Volvo"}
            }
          },
        ),
      );
      if (car == null) return;
      print(await directus.object.deleteOne(car));
    });

    test("Delete many cars", () async {
      final cars = await directus.object.getMany(
        itemCreator: CarObject.creator,
        params: DirectusParams(
          filter: {
            "brand": {
              "name": {DirectusFilterVar.equals: "Ford"}
            }
          },
        ),
      );

      print(await directus.object.deleteMany(cars));
    });
  });
}
