import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'approche ULTRA-SIMPLIFIÉE pour les modèles Directus.
///
/// Cette approche montre comment minimiser au maximum le code nécessaire
/// dans vos classes de modèles en utilisant des mixins et des helpers.

/// Mixin pour automatiser fromJson avec DirectusModelBuilder
mixin AutoSerializable<T extends DirectusModel> on DirectusModel {
  /// Méthode template pour définir les champs du modèle
  /// À surcharger dans les classes enfants
  Map<String, dynamic> get fields;

  /// Méthode template pour parser depuis le builder
  /// À surcharger dans les classes enfants
  T fromBuilder(DirectusModelBuilder builder);
}

/// Modèle Product ultra-simplifié
class SimpleProduct extends DirectusModel {
  final String name;
  final double price;
  final String? description;
  final int stock;

  SimpleProduct._({
    super.id,
    required this.name,
    required this.price,
    this.description,
    required this.stock,
    super.dateCreated,
    super.dateUpdated,
  });

  /// Factory simplifié - toute la logique de parsing dans le builder
  factory SimpleProduct.fromJson(Map<String, dynamic> json) {
    final b = DirectusModelBuilder(json);
    return SimpleProduct._(
      id: b.id,
      name: b.getString('name'),
      price: b.getDouble('price'),
      description: b.getStringOrNull('description'),
      stock: b.getInt('stock', defaultValue: 0),
      dateCreated: b.dateCreated,
      dateUpdated: b.dateUpdated,
    );
  }

  /// toMap simplifié - toute la logique dans le builder
  @override
  Map<String, dynamic> toMap() => DirectusMapBuilder()
      .add('name', name)
      .add('price', price)
      .addIfNotNull('description', description)
      .add('stock', stock)
      .build();

  @override
  String toString() => 'Product($name, $price€)';
}

/// Version encore plus simple : Classe avec le strict minimum
/// Utilise une approche "convention over configuration"
class MinimalProduct extends DirectusModel {
  final String name;
  final double price;

  MinimalProduct._({
    super.id,
    required this.name,
    required this.price,
    super.dateCreated,
    super.dateUpdated,
  });

  /// Parsing en UNE ligne avec le builder
  factory MinimalProduct.fromJson(Map<String, dynamic> json) {
    final b = DirectusModelBuilder(json);
    return MinimalProduct._(
      id: b.id,
      name: b.getString('name'),
      price: b.getDouble('price'),
      dateCreated: b.dateCreated,
      dateUpdated: b.dateUpdated,
    );
  }

  /// Sérialisation en UNE ligne avec le builder
  @override
  Map<String, dynamic> toMap() =>
      DirectusMapBuilder().add('name', name).add('price', price).build();

  @override
  String toString() => 'Product($name)';
}

/// Helper pour créer des services typés avec Registry pré-configuré
class DirectusService<T extends DirectusModel> {
  final DirectusClient client;
  final String collection;
  final T Function(Map<String, dynamic>) fromJson;

  DirectusService(this.client, this.collection, this.fromJson) {
    // Auto-enregistrement dans le Registry
    DirectusModelRegistry.register<T>(fromJson);
  }

  /// Récupère un item par ID
  Future<T?> getById(String id) async {
    return await client.items(collection).readOne(id, fromJson: fromJson) as T?;
  }

  /// Récupère tous les items
  Future<List<T>> getAll({QueryParameters? query}) async {
    final response = await client
        .items(collection)
        .readMany(query: query, fromJson: fromJson);
    return response.data.cast<T>();
  }

  /// Crée un nouvel item
  Future<T> create(T item) async {
    return await client
            .items(collection)
            .createOne(item.toJson(), fromJson: fromJson)
        as T;
  }

  /// Met à jour un item
  Future<T?> update(String id, Map<String, dynamic> data) async {
    return await client
            .items(collection)
            .updateOne(id, data, fromJson: fromJson)
        as T?;
  }

  /// Supprime un item
  Future<void> delete(String id) async {
    await client.items(collection).deleteOne(id);
  }
}

void main() async {
  final config = DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    enableLogging: true,
  );

  final client = DirectusClient(config);

  try {
    print('🚀 Exemple d\'approche ultra-simplifiée\n');

    await client.auth.login(email: 'admin@example.com', password: 'password');

    // Approche 1: Service wrapper avec auto-registration
    print('📦 Approche 1: Service wrapper');
    DirectusService<SimpleProduct>(client, 'products', SimpleProduct.fromJson);

    final product = SimpleProduct.fromJson({
      'id': '1',
      'name': 'Laptop',
      'price': 999.99,
      'description': 'Powerful laptop',
      'stock': 10,
    });

    print('✅ Produit créé en mémoire: $product');
    print('   JSON: ${product.toJson()}\n');

    // Approche 2: Modèle minimal
    print('📦 Approche 2: Modèle minimal');
    final minimalProduct = MinimalProduct.fromJson({
      'id': '2',
      'name': 'Mouse',
      'price': 29.99,
    });

    print('✅ Produit minimal: $minimalProduct');
    print('   JSON: ${minimalProduct.toJson()}\n');

    // Approche 3: Registry centralisé
    print('📦 Approche 3: Registry centralisé');
    DirectusModelRegistry.register<MinimalProduct>(MinimalProduct.fromJson);

    final fromRegistry = DirectusModelRegistry.create<MinimalProduct>({
      'id': '3',
      'name': 'Keyboard',
      'price': 79.99,
    });

    print('✅ Créé depuis Registry: $fromRegistry');
    print('   JSON: ${fromRegistry.toJson()}\n');

    // Comparaison des approches
    print('💡 Comparaison:');
    print('   SimpleProduct    : ~20 lignes (avec helpers builder)');
    print('   MinimalProduct   : ~15 lignes (version minimale)');
    print('   DirectusService  : Réutilisable pour tous les modèles');
    print('   Registry Pattern : Configuration centralisée\n');

    print('✅ Avantages de cette approche:');
    print('   1. Minimum de code dans les classes de modèles');
    print('   2. Builders cachent toute la complexité JSON');
    print('   3. Service wrapper réutilisable');
    print('   4. Registry évite de passer fromJson partout');
    print('   5. Type-safe avec conversions automatiques\n');
  } catch (e) {
    print('❌ Erreur: $e');
  } finally {
    client.dispose();
    print('✨ Terminé');
  }
}
