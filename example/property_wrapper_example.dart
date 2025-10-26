import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation des Property Wrappers
///
/// Cette approche simplifie la définition des modèles en utilisant
/// des property wrappers qui encapsulent la lecture et l'écriture.

/// Modèle Product avec property wrappers
class Product extends DirectusModel {
  @override
  String get itemName => 'products';

  Product(super.data);
  Product.empty() : super.empty();

  // === Property Wrappers ===
  // Une seule ligne par propriété au lieu de 2 (getter + setter) !

  late final name = stringValue('name');
  late final description = stringValue('description');
  late final price = doubleValue('price');
  late final stock = intValue('stock');
  late final active = boolValue('active', defaultValue: true);
  late final tags = listValue<String>('tags');
  late final publishedAt = dateTimeValue('published_at');

  // === Champs calculés (optionnel) ===

  double get priceWithTax => price.value * 1.20;

  String get status {
    if (stock.value == 0) return 'out_of_stock';
    if (stock.value < 10) return 'low_stock';
    return 'in_stock';
  }

  bool get isPublished {
    final date = publishedAt.value;
    return date != null && date.isBefore(DateTime.now());
  }

  // === Méthodes métier (optionnel) ===

  void addStock(int quantity) {
    stock.set(stock.value + quantity);
  }

  void removeStock(int quantity) {
    stock.set((stock.value - quantity).clamp(0, double.infinity).toInt());
  }

  void applyDiscount(double percentage) {
    price.set(price.value * (1 - percentage / 100));
  }

  @override
  String toString() =>
      'Product(name: $name, price: €${price.value}, stock: ${stock.value})';
}

/// Modèle Category avec property wrappers
class Category extends DirectusModel {
  @override
  String get itemName => 'categories';

  Category(super.data);
  Category.empty() : super.empty();

  late final name = stringValue('name');
  late final icon = stringValue('icon');

  @override
  String toString() => 'Category(name: $name)';
}

/// Modèle User avec relations
class User extends DirectusModel {
  @override
  String get itemName => 'users';

  User(super.data);
  User.empty() : super.empty();

  late final firstName = stringValue('first_name');
  late final lastName = stringValue('last_name');
  late final email = stringValue('email');
  late final avatar = stringValue('avatar');
  late final category = modelValue<Category>('category');

  String get fullName => '${firstName.value} ${lastName.value}';

  @override
  String toString() => 'User($fullName)';
}

/// Modèle Order avec liste de produits
class Order extends DirectusModel {
  @override
  String get itemName => 'orders';

  Order(super.data);
  Order.empty() : super.empty();

  late final orderNumber = stringValue('order_number');
  late final products = modelListValue<Product>('products');

  double get totalAmount =>
      products.value.fold(0.0, (sum, p) => sum + p.price.value);

  @override
  String toString() => 'Order($orderNumber, ${products.length} products)';
}

void main() {
  // Enregistrement des factories pour les relations
  DirectusModel.registerFactory<Category>((data) => Category(data));
  DirectusModel.registerFactory<Product>((data) => Product(data));
  DirectusModel.registerFactory<User>((data) => User(data));
  DirectusModel.registerFactory<Order>((data) => Order(data));

  print('🎯 Exemple Property Wrappers - Syntaxe simplifiée\n');

  // === 1. Création depuis JSON ===
  print('📦 1. Création depuis JSON');
  final product = Product({
    'id': '1',
    'name': 'Laptop HP',
    'description': 'Ordinateur portable performant',
    'price': 999.99,
    'stock': 15,
    'active': true,
    'tags': ['electronics', 'computers', 'hp'],
    'published_at': '2024-01-15T10:00:00Z',
  });

  print('✅ Produit créé: $product');
  print('   ID: ${product.id}');
  print('   Nom: ${product.name}'); // Lecture directe !
  print('   Prix: €${product.price}');
  print('   Stock: ${product.stock}');
  print('   Tags: ${product.tags}');
  print('   Status: ${product.status}');
  print('   Prix TTC: €${product.priceWithTax.toStringAsFixed(2)}');
  print('   Publié: ${product.isPublished}\n');

  // === 2. Modification des données ===
  print('✏️  2. Modification avec .set()');
  product.name.set('Laptop HP Elite');
  product.price.set(1299.99);
  product.addStock(5);

  // Modifier une liste
  final newTags = product.tags.value.toList();
  newTags.add('premium');
  product.tags.set(newTags);

  print('✅ Après modification:');
  print('   Nom: ${product.name}');
  print('   Prix: €${product.price}');
  print('   Stock: ${product.stock}');
  print('   Tags: ${product.tags}\n');

  // === 3. Accès au nom de la propriété ===
  print('🔍 3. Accès aux métadonnées');
  print('   Nom de la propriété: ${product.name.name}');
  print('   Existe: ${product.name.exists}');
  print('   Valeur: ${product.name.value}');
  print('   Valeur nullable: ${product.description.valueOrNull}\n');

  // === 4. Création vide et remplissage ===
  print('📝 4. Création vide et remplissage');
  final newProduct = Product.empty();
  newProduct.id = '2';
  newProduct.name.set('Mouse Logitech');
  newProduct.price.set(29.99);
  newProduct.stock.set(50);
  newProduct.active.set(true);
  newProduct.tags.set(['electronics', 'accessories']);

  print('✅ Nouveau produit: $newProduct\n');

  // === 5. Méthodes métier ===
  print('🔧 5. Méthodes métier');
  print('   Stock avant: ${newProduct.stock}');
  newProduct.removeStock(10);
  print('   Après vente de 10: ${newProduct.stock}');

  print('   Prix avant: €${newProduct.price}');
  newProduct.applyDiscount(20);
  print('   Après -20%: €${newProduct.price.value.toStringAsFixed(2)}\n');

  // === 6. Relations ===
  print('👤 6. Modèle avec relations');

  final category = Category({'id': '1', 'name': 'Premium', 'icon': 'star'});

  final user = User({
    'id': '1',
    'first_name': 'John',
    'last_name': 'Doe',
    'email': 'john@example.com',
    'avatar': 'avatar.jpg',
    'category': category.toJson(),
  });

  print('✅ User: $user');
  print('   Full name: ${user.fullName}');
  print('   Email: ${user.email}');
  print(
    '   Category: ${user.category.value?.name} (${user.category.value?.icon})',
  );

  user.firstName.set('Jane');
  print('✅ Après modification nom: ${user.fullName}');

  // Modifier la catégorie
  final newCategory = Category({'id': '2', 'name': 'VIP', 'icon': 'crown'});
  user.category.set(newCategory);
  print('✅ Après modification category: ${user.category.value?.name}\n');

  // === 7. Listes de modèles ===
  print('📋 7. Listes de modèles DirectusModel');

  final order = Order({
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
  for (var i = 0; i < order.products.value.length; i++) {
    final p = order.products.value[i];
    print('   Produit ${i + 1}: ${p.name} - €${p.price}');
  }

  // Utiliser les méthodes de liste
  order.products.add(
    Product({
      'id': '3',
      'name': 'Keyboard Mechanical',
      'price': 149.99,
      'stock': 25,
      'active': true,
      'tags': ['accessories', 'gaming'],
    }),
  );

  print('✅ Après ajout d\'un produit:');
  print('   Nombre de produits: ${order.products.length}');
  print('   Nouveau produit: ${order.products.value.last.name}\n');

  // === 8. Vérification existence ===
  print('🔍 8. Vérification de champs');
  print('   name existe: ${product.name.exists}');
  print('   description existe: ${product.description.exists}');

  product.description.remove();
  print('   Après remove("description"):');
  print('   description existe: ${product.description.exists}\n');

  // === 9. Comparaison des syntaxes ===
  print('⚖️  9. Comparaison des syntaxes');
  print('   Syntaxe classique (2 lignes):');
  print('   String get name => getString("name");');
  print('   set name(String value) => setString("name", value);');
  print('');
  print('   Syntaxe property wrapper (1 ligne):');
  print('   late final name = stringValue("name");');
  print('');
  print('   Utilisation:');
  print('   Classique: product.name = "Laptop"');
  print('   Wrapper:   product.name.set("Laptop")');
  print('   Bonus:     product.name.name → "name"');
  print('             product.name.exists → true\n');

  // === 10. Avantages ===
  print('✨ Avantages des Property Wrappers:');
  print('   ✅ Une seule ligne au lieu de 2 (getter + setter)');
  print('   ✅ Accès au nom de la propriété (.name)');
  print('   ✅ Vérification d\'existence (.exists)');
  print('   ✅ Suppression facile (.remove())');
  print('   ✅ Méthodes utilitaires (ex: .add() pour les listes)');
  print('   ✅ Valeurs nullable (.valueOrNull)');
  print('   ✅ Moins de code répétitif');
  print('   ✅ toString() automatique pour le print');
}
