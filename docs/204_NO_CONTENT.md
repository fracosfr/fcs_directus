# Gestion des réponses 204 No Content

## Comportement de Directus

Directus peut retourner un code HTTP **204 No Content** dans certaines situations, notamment lors de certaines opérations `create` et `update`. Dans ce cas, la réponse ne contient pas de body (pas de JSON), donc `response.data` est `null`.

## Cas d'usage

### Exemples de situations où Directus retourne 204

1. **Mise à jour sans retour de données** : Quand la configuration Directus ne retourne pas l'objet modifié
2. **Création avec auto-génération** : Certaines configurations peuvent ne pas retourner l'objet créé
3. **Opérations batch** : Certaines opérations groupées peuvent ne pas retourner de données

## Impact sur la librairie

Avant la correction, le code suivant générait une erreur :

```dart
// ❌ AVANT - Erreur NoSuchMethodError
final item = await client.items('products').createOne({
  'name': 'Product',
  'price': 99.99,
});
// Si Directus retourne 204, response.data est null
// L'accès à response.data['data'] provoque : NoSuchMethodError: The method '[]' was called on null.
```

## Solution implémentée

### 1. Dans ItemsService

Les méthodes `createOne` et `updateOne` vérifient maintenant si `response.data` est null :

```dart
Future<dynamic> createOne(
  Map<String, dynamic> data, {
  T Function(Map<String, dynamic>)? fromJson,
}) async {
  final response = await _httpClient.post('/items/$collection', data: data);

  // ✅ Vérification ajoutée
  if (response.data == null || !response.data!.containsKey('data')) {
    return null;  // Retourne null au lieu de planter
  }

  final responseData = response.data!['data'] as Map<String, dynamic>;
  return fromJson != null ? fromJson(responseData) : responseData;
}
```

### 2. Dans ItemActiveService

Les méthodes `createOne` et `updateOne` retournent maintenant `T?` (nullable) :

```dart
Future<T?> createOne(T model) async {
  final response = await _httpClient.post(
    '/items/$collection',
    data: model.toJson(),
  );

  // ✅ Vérification ajoutée
  if (response.data == null || !response.data!.containsKey('data')) {
    return null;
  }

  final responseData = response.data!['data'] as Map<String, dynamic>;
  final T Function(Map<String, dynamic>) resolvedFactory = _getModelFactory();
  return resolvedFactory(responseData);
}
```

### 3. Dans UsersService

Les méthodes `me` et `updateMe` vérifient également la présence de données :

```dart
Future<T?> me<T extends DirectusUser>({QueryParameters? query}) async {
  final response = await _httpClient.get(
    '/users/me',
    queryParameters: query?.toQueryParameters(),
  );

  // ✅ Vérification ajoutée
  if (response.data == null || !response.data.containsKey('data')) {
    return null;
  }

  final data = response.data['data'] as Map<String, dynamic>;
  // ... reste du code
}
```

## Utilisation dans votre code

### Cas 1 : ItemsService (retourne dynamic)

```dart
final item = await client.items('products').createOne({
  'name': 'Product',
  'price': 99.99,
});

if (item == null) {
  // Directus n'a pas retourné de données (204)
  print('Item créé mais données non retournées');
} else {
  // Données retournées normalement
  print('Item créé : ${item['id']}');
}
```

### Cas 2 : ItemActiveService (retourne T?)

```dart
class Product extends DirectusModel {
  late final name = stringValue('name');
  late final price = doubleValue('price');
  
  Product(super.data);
  Product.empty() : super.empty();
  
  @override
  String get itemName => 'products';
}

// Création
final newProduct = Product.empty()
  ..name.set('Product')
  ..price.set(99.99);

final created = await client.itemsOf<Product>().createOne(newProduct);

if (created == null) {
  // Directus n'a pas retourné de données (204)
  print('Produit créé mais données non retournées');
  // Vous devrez peut-être faire un readOne pour récupérer l'objet
} else {
  // Données retournées normalement
  print('Produit créé : ${created.id}');
}
```

### Cas 3 : Gestion avec fallback

Si vous avez besoin de l'objet créé/modifié dans tous les cas :

```dart
Future<Product> createProductWithFallback(Product product) async {
  final created = await client.itemsOf<Product>().createOne(product);
  
  if (created == null) {
    // Si 204, on suppose que la création a réussi
    // On retourne le modèle original (qui pourrait avoir un ID généré par le client)
    return product;
    
    // Ou on fait un readOne si on a un ID
    // if (product.id != null) {
    //   return await client.itemsOf<Product>().readOne(product.id!);
    // }
  }
  
  return created;
}
```

## Configuration Directus

Pour éviter les réponses 204, vous pouvez configurer Directus pour toujours retourner les objets créés/modifiés :

### Dans les permissions

1. Allez dans **Settings** > **Roles & Permissions**
2. Sélectionnez le rôle concerné
3. Pour chaque collection, assurez-vous que les permissions `create` et `update` ont :
   - ✅ **Return data** activé

### Dans les hooks

Si vous utilisez des hooks Directus, assurez-vous qu'ils ne modifient pas le comportement de retour des données.

## Bonnes pratiques

1. **Toujours vérifier le retour** : Après un `createOne` ou `updateOne`, vérifiez si le résultat est `null`
2. **Utiliser des fallbacks** : Prévoyez un plan B si les données ne sont pas retournées
3. **Logger les 204** : En développement, loggez quand vous recevez un 204 pour identifier les cas problématiques
4. **Configurer Directus** : Si possible, configurez Directus pour toujours retourner les données

## Codes de statut HTTP

| Code | Signification | Comportement `fcs_directus` |
|------|---------------|------------------------------|
| 200 OK | Succès avec données | Retourne l'objet désérialisé |
| 201 Created | Création avec données | Retourne l'objet créé |
| 204 No Content | Succès sans données | Retourne `null` |
| 4xx/5xx | Erreur | Lance une `DirectusException` |

## Exemple complet

```dart
import 'package:fcs_directus/fcs_directus.dart';

void main() async {
  final client = DirectusClient(
    DirectusConfig(baseUrl: 'https://directus.example.com'),
  );

  await client.auth.login(
    email: 'admin@example.com',
    password: 'password',
  );

  // Création d'un produit
  final product = await client.items('products').createOne({
    'name': 'Nouveau produit',
    'price': 49.99,
  });

  if (product == null) {
    print('✓ Produit créé (204 - pas de données retournées)');
    // Vous pourriez faire un readMany pour retrouver le produit
  } else {
    print('✓ Produit créé avec ID : ${product['id']}');
  }

  // Mise à jour
  if (product != null) {
    final updated = await client.items('products').updateOne(
      product['id'],
      {'price': 59.99},
    );

    if (updated == null) {
      print('✓ Produit mis à jour (204 - pas de données retournées)');
    } else {
      print('✓ Produit mis à jour : ${updated['price']}');
    }
  }
}
```

## Ressources

- [Documentation Directus - API Status Codes](https://docs.directus.io/reference/introduction.html#http-status-codes)
- [RFC 7231 - 204 No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)
