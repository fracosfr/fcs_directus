import 'package:fcs_directus/src/models/directus_active_model.dart';

/// Exemple d'utilisation de DirectusActiveModel
///
/// Cette approche stocke le JSON directement dans l'objet et fournit
/// des getters/setters typés pour y accéder. AUCUN code de sérialisation
/// à écrire - tout est géré par la classe parente !

/// Modèle Product avec Active Record pattern
class ActiveProduct extends DirectusActiveModel {
  /// Constructeur depuis JSON - une seule ligne !
  ActiveProduct(super.data);

  /// Constructeur vide
  ActiveProduct.empty() : super.empty();

  // === Getters typés - lecture des données ===

  String get name => getString('name');
  String? get description => getStringOrNull('description');
  double get price => getDouble('price');
  int get stock => getInt('stock');
  bool get active => getBool('active', defaultValue: true);
  List<String> get tags => getList<String>('tags');
  DateTime? get publishedAt => getDateTime('published_at');

  // === Setters typés - modification des données ===

  set name(String value) => setString('name', value);
  set description(String? value) => setStringOrNull('description', value);
  set price(double value) => setDouble('price', value);
  set stock(int value) => setInt('stock', value);
  set active(bool value) => setBool('active', value);
  set tags(List<String> value) => setList('tags', value);
  set publishedAt(DateTime? value) => setDateTimeOrNull('published_at', value);

  // === Champs calculés (optionnel) ===

  double get priceWithTax => price * 1.20;

  String get status {
    if (stock == 0) return 'out_of_stock';
    if (stock < 10) return 'low_stock';
    return 'in_stock';
  }

  bool get isPublished =>
      publishedAt != null && publishedAt!.isBefore(DateTime.now());

  // === Méthodes métier (optionnel) ===

  void addStock(int quantity) {
    stock = stock + quantity;
  }

  void removeStock(int quantity) {
    stock = (stock - quantity).clamp(0, double.infinity).toInt();
  }

  void applyDiscount(double percentage) {
    price = price * (1 - percentage / 100);
  }

  @override
  String toString() => 'Product(name: $name, price: €$price, stock: $stock)';
}

/// Modèle Category simplifié
class ActiveCategory extends DirectusActiveModel {
  ActiveCategory(super.data);
  ActiveCategory.empty() : super.empty();

  String get name => getString('name');
  String? get icon => getStringOrNull('icon');

  set name(String value) => setString('name', value);
  set icon(String? value) => setStringOrNull('icon', value);

  @override
  String toString() => 'Category(name: $name)';
}

/// Modèle User avec relations
class ActiveUser extends DirectusActiveModel {
  ActiveUser(super.data);
  ActiveUser.empty() : super.empty();

  String get firstName => getString('first_name');
  String get lastName => getString('last_name');
  String get email => getString('email');
  String? get avatar => getStringOrNull('avatar');
  ActiveCategory get category => getDirectusModel<ActiveCategory>('category');

  set firstName(String value) => setString('first_name', value);
  set lastName(String value) => setString('last_name', value);
  set email(String value) => setString('email', value);
  set avatar(String? value) => setStringOrNull('avatar', value);
  set category(ActiveCategory value) => setDirectusModel('category', value);

  String get fullName => '$firstName $lastName';

  @override
  String toString() => 'User($fullName)';
}

/// Modèle Order avec une liste de produits
class ActiveOrder extends DirectusActiveModel {
  ActiveOrder(super.data);
  ActiveOrder.empty() : super.empty();

  String get orderNumber => getString('order_number');
  List<ActiveProduct> get products =>
      getDirectusModelList<ActiveProduct>('products');

  set orderNumber(String value) => setString('order_number', value);
  set products(List<ActiveProduct> value) =>
      setDirectusModelList('products', value);

  double get totalAmount => products.fold(0.0, (sum, p) => sum + p.price);

  @override
  String toString() => 'Order($orderNumber, ${products.length} products)';
}

void main() {
  // Enregistrement des factories pour les relations
  DirectusActiveModel.registerFactory<ActiveCategory>(
    (data) => ActiveCategory(data),
  );
  DirectusActiveModel.registerFactory<ActiveProduct>(
    (data) => ActiveProduct(data),
  );
  DirectusActiveModel.registerFactory<ActiveUser>((data) => ActiveUser(data));

  print('🎯 Exemple DirectusActiveModel - Active Record Pattern\n');

  // === 1. Création depuis JSON ===
  print('📦 1. Création depuis JSON');
  final product = ActiveProduct({
    'id': '1',
    'name': 'Laptop HP',
    'description': 'Ordinateur portable performant',
    'price': 999.99,
    'stock': 15,
    'active': true,
    'tags': ['electronics', 'computers', 'hp'],
    'published_at': '2024-01-15T10:00:00Z',
    'date_created': '2024-01-01T00:00:00Z',
    'date_updated': '2024-01-15T00:00:00Z',
  });

  print('✅ Produit créé: $product');
  print('   ID: ${product.id}');
  print('   Nom: ${product.name}');
  print('   Prix: €${product.price}');
  print('   Stock: ${product.stock}');
  print('   Tags: ${product.tags}');
  print('   Status: ${product.status}');
  print('   Prix TTC: €${product.priceWithTax.toStringAsFixed(2)}');
  print('   Publié: ${product.isPublished}\n');

  // === 2. Modification des données ===
  print('✏️  2. Modification des données');
  product.name = 'Laptop HP Elite';
  product.price = 1299.99;
  product.addStock(5);
  product.tags = [...product.tags, 'premium'];

  print('✅ Après modification:');
  print('   Nom: ${product.name}');
  print('   Prix: €${product.price}');
  print('   Stock: ${product.stock}');
  print('   Tags: ${product.tags}\n');

  // === 3. Sérialisation JSON ===
  print('📤 3. Sérialisation JSON');
  final json = product.toJson();
  print('✅ JSON complet:');
  print('   ${json.keys.length} champs');
  print('   name: ${json['name']}');
  print('   price: ${json['price']}');
  print('   stock: ${json['stock']}\n');

  final mapOnly = product.toMap();
  print('✅ toMap() (sans champs système):');
  print('   ${mapOnly.keys.length} champs');
  print('   Champs exclus: id, dates, users\n');

  // === 4. Création vide et remplissage ===
  print('📝 4. Création vide et remplissage');
  final newProduct = ActiveProduct.empty();
  newProduct.id = '2';
  newProduct.name = 'Mouse Logitech';
  newProduct.price = 29.99;
  newProduct.stock = 50;
  newProduct.active = true;
  newProduct.tags = ['electronics', 'accessories'];

  print('✅ Nouveau produit: $newProduct');
  print('   JSON: ${newProduct.toJson()}\n');

  // === 5. Méthodes métier ===
  print('🔧 5. Méthodes métier');
  print('   Stock avant: ${newProduct.stock}');
  newProduct.removeStock(10);
  print('   Après vente de 10: ${newProduct.stock}');

  print('   Prix avant: €${newProduct.price}');
  newProduct.applyDiscount(20);
  print('   Après -20%: €${newProduct.price.toStringAsFixed(2)}\n');

  // === 6. Relations ===
  print('👤 6. Modèle avec relations');

  // Créer une catégorie
  final category = ActiveCategory({
    'id': '1',
    'name': 'Premium',
    'icon': 'star',
  });

  // Créer un user avec relation
  final user = ActiveUser({
    'id': '1',
    'first_name': 'John',
    'last_name': 'Doe',
    'email': 'john@example.com',
    'avatar': 'avatar.jpg',
    'category': category.toJson(), // Relation nested
  });

  print('✅ User: $user');
  print('   Full name: ${user.fullName}');
  print('   Email: ${user.email}');
  print('   Category: ${user.category.name} (${user.category.icon})');

  user.firstName = 'Jane';
  print('✅ Après modification nom: ${user.fullName}');

  // Modifier la catégorie via setter
  final newCategory = ActiveCategory({
    'id': '2',
    'name': 'VIP',
    'icon': 'crown',
  });
  user.category = newCategory;
  print(
    '✅ Après modification category: ${user.category.name} (${user.category.icon})\n',
  );

  // === 7. Listes de modèles (relations many) ===
  print('📋 7. Listes de modèles DirectusActiveModel');

  // Enregistrer la factory pour Order
  DirectusActiveModel.registerFactory<ActiveOrder>((data) => ActiveOrder(data));

  // Créer une commande avec des produits
  final order = ActiveOrder({
    'id': '1',
    'order_number': 'ORD-2024-001',
    'products': [
      {
        'id': '1',
        'name': 'Laptop HP',
        'price': 999.99,
        'stock': 15,
        'active': true,
        'tags': ['electronics'],
      },
      {
        'id': '2',
        'name': 'Mouse Logitech',
        'price': 29.99,
        'stock': 50,
        'active': true,
        'tags': ['accessories'],
      },
    ],
  });

  print('✅ Commande: ${order.orderNumber}');
  print('   Nombre de produits: ${order.products.length}');
  for (var i = 0; i < order.products.length; i++) {
    final p = order.products[i];
    print('   Produit ${i + 1}: ${p.name} - €${p.price}');
  }

  // Modifier la liste de produits
  final newProducts = order.products.toList();
  newProducts.add(
    ActiveProduct({
      'id': '3',
      'name': 'Keyboard Mechanical',
      'price': 149.99,
      'stock': 25,
      'active': true,
      'tags': ['accessories', 'gaming'],
    }),
  );
  order.products = newProducts;

  print('✅ Après ajout d\'un produit:');
  print('   Nombre de produits: ${order.products.length}');
  print('   Nouveau produit: ${order.products.last.name}\n');

  // === 8. Vérification existence ===
  print('🔍 8. Vérification de champs');
  print('   has("name"): ${product.has('name')}');
  print('   has("unknown"): ${product.has('unknown')}');

  product.remove('description');
  print('   Après remove("description"):');
  print('   has("description"): ${product.has('description')}\n');

  // === 9. Champs standards Directus ===
  print('📅 9. Champs standards Directus');
  print('   ID: ${product.id}');
  print('   Date création: ${product.dateCreated}');
  print('   Date modification: ${product.dateUpdated}');
  print('   User créateur: ${product.userCreated}');
  print('   User modificateur: ${product.userUpdated}\n');

  // === 9. Comparaison ===
  print('⚖️  9. Comparaison du code');
  print('   Classe ActiveProduct:');
  print('   - 0 ligne de fromJson (géré par DirectusActiveModel)');
  print('   - 0 ligne de toMap (géré par DirectusActiveModel)');
  print('   - 7 getters (une ligne chacun)');
  print('   - 7 setters (une ligne chacun)');
  print('   - Total: ~20 lignes');
  print('');
  print('   Vs classe traditionnelle:');
  print('   - 15 lignes de fromJson');
  print('   - 10 lignes de toMap');
  print('   - Champs déclarés');
  print('   - Total: ~40 lignes');
  print('');
  print('   Réduction: 50% de code !');
  print('');
  print('✨ Avantages de DirectusActiveModel:');
  print('   ✅ Pas de fromJson à écrire');
  print('   ✅ Pas de toMap à écrire');
  print('   ✅ Getters/setters simples (1 ligne)');
  print('   ✅ Type-safe avec conversions auto');
  print('   ✅ Modification directe des données');
  print('   ✅ Champs calculés possibles');
  print('   ✅ Méthodes métier intégrées');
}
