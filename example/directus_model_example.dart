import 'package:fcs_directus/fcs_directus.dart';

/// Exemple montrant comment créer des modèles personnalisés
/// en héritant de DirectusModel et en utilisant les Builders.
///
/// Les Builders (DirectusModelBuilder et DirectusMapBuilder) permettent
/// d'éliminer complètement le code JSON des classes de modèles.
///
/// ALTERNATIVE: Pour une approche encore plus simple, vous pouvez utiliser
/// le DirectusModelRegistry qui centralise toute la logique de sérialisation.
/// Voir la fonction setupRegistry() ci-dessous.

/// Modèle simple d'un produit
class Product extends DirectusModel {
  final String name;
  final double price;
  final String? description;
  final int stock;

  Product._({
    super.id,
    required this.name,
    required this.price,
    this.description,
    required this.stock,
    super.dateCreated,
    super.dateUpdated,
  });

  factory Product({
    String? id,
    required String name,
    required double price,
    String? description,
    int stock = 0,
    DateTime? dateCreated,
    DateTime? dateUpdated,
  }) => Product._(
    id: id,
    name: name,
    price: price,
    description: description,
    stock: stock,
    dateCreated: dateCreated,
    dateUpdated: dateUpdated,
  );

  factory Product.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    return Product._(
      id: builder.id,
      name: builder.getString('name'),
      price: builder.getDouble('price'),
      description: builder.getStringOrNull('description'),
      stock: builder.getInt('stock', defaultValue: 0),
      dateCreated: builder.dateCreated,
      dateUpdated: builder.dateUpdated,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return DirectusMapBuilder()
        .add('name', name)
        .add('price', price)
        .addIfNotNull('description', description)
        .add('stock', stock)
        .build();
  }

  @override
  String toString() => 'Product(name: $name, price: $price€, stock: $stock)';
}

/// Modèle d'une catégorie
class Category extends DirectusModel {
  final String name;
  final String? icon;

  Category._({
    super.id,
    required this.name,
    this.icon,
    super.dateCreated,
    super.dateUpdated,
  });

  factory Category({
    String? id,
    required String name,
    String? icon,
    DateTime? dateCreated,
    DateTime? dateUpdated,
  }) => Category._(
    id: id,
    name: name,
    icon: icon,
    dateCreated: dateCreated,
    dateUpdated: dateUpdated,
  );

  factory Category.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    return Category._(
      id: builder.id,
      name: builder.getString('name'),
      icon: builder.getStringOrNull('icon'),
      dateCreated: builder.dateCreated,
      dateUpdated: builder.dateUpdated,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return DirectusMapBuilder()
        .add('name', name)
        .addIfNotNull('icon', icon)
        .build();
  }

  @override
  String toString() => 'Category(name: $name)';
}

/// Configure le Registry une seule fois au démarrage de l'application.
/// Après cet appel, vous n'avez plus besoin de passer fromJson à chaque appel.
void setupRegistry() {
  DirectusModelRegistry.register<Product>(Product.fromJson);
  DirectusModelRegistry.register<Category>(Category.fromJson);
}

void main() async {
  // 1. Enregistrer les modèles UNE SEULE FOIS
  setupRegistry();

  final config = DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    enableLogging: true,
  );

  final client = DirectusClient(config);

  try {
    print('📡 Connexion...');
    await client.auth.login(email: 'admin@example.com', password: 'password');
    print('✅ Authentifié\n');

    // Service pour les produits
    final productsService = client.items<Product>('products');

    // 1. Créer un produit avec le modèle
    print('📦 Création d\'un produit...');
    final newProduct = Product(
      name: 'Laptop HP',
      price: 899.99,
      description: 'Ordinateur portable performant',
      stock: 15,
    );

    final createdProduct =
        await productsService.createOne(
              newProduct.toJson(),
              fromJson: Product.fromJson,
            )
            as Product;

    print('✅ Produit créé: $createdProduct');
    print('   ID: ${createdProduct.id}');
    print('   Créé le: ${createdProduct.dateCreated}\n');

    // 2. Récupérer tous les produits
    print('📚 Récupération des produits...');
    final response = await productsService.readMany(
      query: QueryParameters(limit: 10, sort: ['name']),
      fromJson: Product.fromJson,
    );

    print('✅ ${response.data.length} produits trouvés:');
    for (final product in response.data) {
      final p = product as Product;
      print('   - $p');
    }
    print('');

    // 3. Mettre à jour le stock
    print('📝 Mise à jour du stock...');
    final updatedProduct =
        await productsService.updateOne(createdProduct.id!, {
              'stock': createdProduct.stock + 5,
            }, fromJson: Product.fromJson)
            as Product;

    print('✅ Stock mis à jour: ${updatedProduct.stock} unités\n');

    // 4. Travailler avec les catégories
    print('🏷️  Création d\'une catégorie...');
    final categoriesService = client.items<Category>('categories');

    final category = Category(name: 'Électronique', icon: 'laptop');

    final createdCategory =
        await categoriesService.createOne(
              category.toJson(),
              fromJson: Category.fromJson,
            )
            as Category;

    print('✅ Catégorie créée: $createdCategory\n');

    // 5. Nettoyage
    print('🗑️  Suppression des données de test...');
    await productsService.deleteOne(createdProduct.id!);
    await categoriesService.deleteOne(createdCategory.id!);
    print('✅ Nettoyage terminé');

    // Démo des helpers de DirectusModel
    print('\n💡 Démo des helpers:');
    print(
      '   parseDate("2024-01-01"): ${DirectusModel.parseDate("2024-01-01")}',
    );
    print('   parseId(123): ${DirectusModel.parseId(123)}');
    print('   parseId(null): ${DirectusModel.parseId(null)}');
  } catch (e) {
    if (e is DirectusException) {
      print('❌ Erreur Directus: ${e.message}');
    } else {
      print('❌ Erreur: $e');
    }
  } finally {
    client.dispose();
    print('\n✨ Terminé');
  }
}
