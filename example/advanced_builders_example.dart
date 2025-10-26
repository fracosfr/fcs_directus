import 'package:fcs_directus/fcs_directus.dart';

/// Exemple avancé montrant l'utilisation des builders pour des modèles complexes
///
/// Cet exemple démontre:
/// - DirectusModelBuilder pour parser différents types de données
/// - DirectusMapBuilder pour construire des Map complexes
/// - Gestion des relations
/// - Gestion des listes
/// - Gestion des champs calculés

/// Modèle User simple
class User extends DirectusModel {
  final String firstName;
  final String lastName;
  final String email;

  User._({
    super.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    super.dateCreated,
  });

  factory User({
    String? id,
    required String firstName,
    required String lastName,
    required String email,
    DateTime? dateCreated,
  }) {
    return User._(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      dateCreated: dateCreated,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    return User._(
      id: builder.id,
      firstName: builder.getString('first_name'),
      lastName: builder.getString('last_name'),
      email: builder.getString('email'),
      dateCreated: builder.dateCreated,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return DirectusMapBuilder()
        .add('first_name', firstName)
        .add('last_name', lastName)
        .add('email', email)
        .build();
  }

  String get fullName => '$firstName $lastName';

  @override
  String toString() => 'User($fullName)';
}

/// Modèle Product avec relations et types variés
class Product extends DirectusModel {
  final String name;
  final String? description;
  final double price;
  final int stock;
  final bool available;
  final List<String> tags;
  final User? createdBy;
  final DateTime? publishDate;

  Product._({
    super.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.available,
    required this.tags,
    this.createdBy,
    this.publishDate,
    super.dateCreated,
    super.dateUpdated,
  });

  factory Product({
    String? id,
    required String name,
    String? description,
    required double price,
    int stock = 0,
    bool available = true,
    List<String> tags = const [],
    User? createdBy,
    DateTime? publishDate,
    DateTime? dateCreated,
    DateTime? dateUpdated,
  }) {
    return Product._(
      id: id,
      name: name,
      description: description,
      price: price,
      stock: stock,
      available: available,
      tags: tags,
      createdBy: createdBy,
      publishDate: publishDate,
      dateCreated: dateCreated,
      dateUpdated: dateUpdated,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    return Product._(
      id: builder.id,
      name: builder.getString('name'),
      description: builder.getStringOrNull('description'),
      price: builder.getDouble('price'),
      stock: builder.getInt('stock', defaultValue: 0),
      available: builder.getBool('available', defaultValue: true),
      tags: builder.getList<String>(
        'tags',
        (item) => item.toString(),
        defaultValue: [],
      ),
      createdBy: builder.getObjectOrNull('created_by', User.fromJson),
      publishDate: builder.getDateTimeOrNull('publish_date'),
      dateCreated: builder.dateCreated,
      dateUpdated: builder.dateUpdated,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return DirectusMapBuilder()
        .add('name', name)
        .addIfNotNull('description', description)
        .add('price', price)
        .add('stock', stock)
        .add('available', available)
        .addIf(tags.isNotEmpty, 'tags', tags)
        .addRelation('created_by', createdBy)
        .addIfNotNull('publish_date', publishDate?.toIso8601String())
        .build();
  }

  /// Champ calculé - Prix avec TVA
  double get priceWithTax => price * 1.20;

  /// Champ calculé - Statut
  String get status {
    if (!available) return 'Indisponible';
    if (stock == 0) return 'Rupture de stock';
    if (stock < 5) return 'Stock faible';
    return 'En stock';
  }

  @override
  String toString() => 'Product($name, ${price}€, stock: $stock)';
}

void main() async {
  final config = DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    enableLogging: true,
  );

  final client = DirectusClient(config);

  try {
    print('📡 Connexion...');
    await client.auth.login(email: 'admin@example.com', password: 'password');
    print('✅ Authentifié\n');

    // Enregistrer les factories dans le registry
    DirectusModelRegistry.register<Product>((json) => Product.fromJson(json));
    DirectusModelRegistry.register<User>((json) => User.fromJson(json));

    final productsService = client.items<Product>('products');

    // 1. Créer un produit complexe
    print('📦 Création d\'un produit...');
    final product = Product(
      name: 'MacBook Pro M3',
      description: 'Ordinateur portable haute performance',
      price: 2499.99,
      stock: 15,
      available: true,
      tags: ['laptop', 'apple', 'pro'],
      publishDate: DateTime.now(),
    );

    print('   Données à envoyer:');
    print('   ${product.toJson()}');

    final createdProduct =
        await productsService.createOne(
              product.toJson(),
              fromJson: Product.fromJson,
            )
            as Product;

    print('✅ Produit créé: $createdProduct');
    print('   Prix TTC: ${createdProduct.priceWithTax}€');
    print('   Statut: ${createdProduct.status}');
    print('   Tags: ${createdProduct.tags.join(", ")}\n');

    // 2. Récupérer et afficher les détails
    print('📖 Récupération du produit...');
    final fetchedProduct =
        await productsService.readOne(
              createdProduct.id!,
              fromJson: Product.fromJson,
            )
            as Product;

    print('✅ Produit récupéré:');
    print('   Nom: ${fetchedProduct.name}');
    print('   Prix: ${fetchedProduct.price}€');
    print('   Stock: ${fetchedProduct.stock}');
    print('   Disponible: ${fetchedProduct.available}');
    print('   Créé le: ${fetchedProduct.dateCreated}');
    if (fetchedProduct.createdBy != null) {
      print('   Créé par: ${fetchedProduct.createdBy!.fullName}');
    }
    print('');

    // 3. Mettre à jour avec le builder
    print('📝 Mise à jour du stock...');
    final updateData = DirectusMapBuilder()
        .add('stock', fetchedProduct.stock - 3)
        .addIf(fetchedProduct.stock - 3 < 5, 'available', false)
        .build();

    print('   Données de mise à jour: $updateData');

    final updatedProduct =
        await productsService.updateOne(
              fetchedProduct.id!,
              updateData,
              fromJson: Product.fromJson,
            )
            as Product;

    print('✅ Produit mis à jour:');
    print('   Stock: ${updatedProduct.stock}');
    print('   Statut: ${updatedProduct.status}\n');

    // 4. Liste avec filtres utilisant le builder
    print('📚 Recherche de produits disponibles...');
    final response = await productsService.readMany(
      query: QueryParameters(
        filter: {
          'available': {'_eq': true},
          'price': {'_gte': 1000},
        },
        limit: 10,
      ),
      fromJson: Product.fromJson,
    );

    print('✅ ${response.data.length} produits trouvés:');
    for (final p in response.data) {
      final product = p as Product;
      print('   - $product');
      print('     Statut: ${product.status}');
      print('     Prix TTC: ${product.priceWithTax}€');
    }
    print('');

    // 5. Utilisation du registry
    print('🔧 Test du DirectusModelRegistry...');
    final jsonData = {
      'id': '999',
      'name': 'Test Product',
      'price': 99.99,
      'stock': 100,
      'available': true,
      'tags': ['test'],
    };

    final productFromRegistry = DirectusModelRegistry.create<Product>(jsonData);
    print('✅ Produit créé via Registry: $productFromRegistry\n');

    // 6. Nettoyage
    print('🗑️  Suppression du produit de test...');
    await productsService.deleteOne(createdProduct.id!);
    print('✅ Nettoyage terminé');

    // 7. Démonstration des helpers du builder
    print('\n💡 Démo des helpers DirectusModelBuilder:');
    final testJson = {
      'id': 123,
      'name': 'Test',
      'price': '99.99',
      'stock': '50',
      'available': 'true',
      'date_created': '2024-01-01T10:00:00.000Z',
    };
    final testBuilder = DirectusModelBuilder(testJson);
    print('   getString("name"): ${testBuilder.getString("name")}');
    print('   getDouble("price"): ${testBuilder.getDouble("price")}');
    print('   getInt("stock"): ${testBuilder.getInt("stock")}');
    print('   getBool("available"): ${testBuilder.getBool("available")}');
    print('   dateCreated: ${testBuilder.dateCreated}');
  } catch (e) {
    if (e is DirectusException) {
      print('❌ Erreur Directus: ${e.message}');
    } else {
      print('❌ Erreur: $e');
    }
  } finally {
    DirectusModelRegistry.clear();
    client.dispose();
    print('\n✨ Terminé');
  }
}
