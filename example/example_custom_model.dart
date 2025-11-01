// ignore_for_file: unused_local_variable

import 'package:fcs_directus/fcs_directus.dart';

/// Exemple de création de modèles personnalisés avec fcs_directus.
///
/// Démontre :
/// - Création de classes de modèles
/// - Property wrappers
/// - Relations
/// - Getters/Setters personnalisés
/// - Factory registration
/// - Utilisation avec les services
void main() async {
  final config = DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    enableLogging: true,
  );

  final client = DirectusClient(config);

  // Authentification
  await client.auth.login(email: 'user@example.com', password: 'your-password');

  // ============================================================================
  // ENREGISTRER LES FACTORIES
  // ============================================================================

  print('📦 Enregistrement des factories de modèles...\n');

  DirectusModel.registerFactory<Article>((data) => Article(data));
  DirectusModel.registerFactory<Product>((data) => Product(data));
  DirectusModel.registerFactory<Category>((data) => Category(data));
  DirectusModel.registerFactory<Author>((data) => Author(data));

  print('✅ Factories enregistrées\n');

  // ============================================================================
  // UTILISER LES MODÈLES AVEC LE SERVICE
  // ============================================================================

  print('📚 Récupération d\'articles typés...\n');

  final articlesResponse = await client.itemsOf<Article>().readMany(
    query: QueryParameters(
      filter: Filter.field('status').equals('published'),
      limit: 5,
    ),
  );

  print('✅ ${articlesResponse.data.length} articles récupérés\n');

  // Accès type-safe aux propriétés
  for (final article in articlesResponse.data) {
    print('Article: ${article.title}');
    print('  Status: ${article.status}');
    print('  Vues: ${article.viewCount}');
    print('  Publié: ${article.isPublished}');
    print('  Slug: ${article.slug}');
    print('');
  }

  // ============================================================================
  // CRÉER UN ARTICLE AVEC LE MODÈLE
  // ============================================================================

  print('\n📝 Création d\'un nouvel article...\n');

  final newArticle = Article.empty()
    ..title.set('Mon super article')
    ..content.set('Contenu intéressant de l\'article')
    ..status.set('draft')
    ..viewCount.set(0)
    ..featured.set(false);

  // Sauvegarder
  final savedArticle = await client.itemsOf<Article>().createOne(newArticle);

  print('✅ Article créé:');
  print('  ID: ${savedArticle?.id}');
  print('  Titre: ${savedArticle?.title.value}');
  print('  Status: ${savedArticle?.status.value}');
  print('');

  // ============================================================================
  // METTRE À JOUR UN ARTICLE
  // ============================================================================

  print('✏️ Mise à jour de l\'article...\n');

  savedArticle?.title.set('Titre modifié');
  savedArticle?.status.set('published');
  savedArticle?.viewCount.incrementBy(10);

  if (savedArticle != null) {
    // Sauvegarder seulement les champs modifiés
    final updatedArticle = await client.itemsOf<Article>().updateOne(
      savedArticle,
    );

    print('✅ Article mis à jour:');
    print('  Titre: ${updatedArticle?.title.value}');
    print('  Status: ${updatedArticle?.status.value}');
    print('');

    // ============================================================================
    // SUPPRIMER UN ARTICLE
    // ============================================================================

    print('\n🗑️ Suppression de l\'article...\n');

    if (updatedArticle != null) {
      await client.itemsOf<Article>().deleteOne(updatedArticle);
    }

    print('✅ Article supprimé: ${updatedArticle?.id}');
    print('');
  }

  // ============================================================================
  // UTILISER LES PRODUITS AVEC PROPERTY WRAPPERS
  // ============================================================================

  print('\n🛍️ Gestion des produits...\n');

  final productsResponse = await client.itemsOf<Product>().readMany(
    query: QueryParameters(
      filter: Filter.and([
        Filter.field('status').equals('active'),
        Filter.field('stock').greaterThan(0),
      ]),
      limit: 5,
    ),
  );

  print('✅ ${productsResponse.data.length} produits trouvés\n');

  for (final product in productsResponse.data) {
    print('Produit: ${product.name}');
    print('  Prix: ${product.price.toStringAsFixed(2)}€');
    print('  Stock: ${product.stock}');
    print('  Active: ${product.active}');

    // Calculer le prix avec remise
    if (product.hasDiscount) {
      final discountedPrice = product.discountedPrice;
      print('  Prix soldé: ${discountedPrice.toStringAsFixed(2)}€');
      print(
        '  Économie: ${(product.price.value - discountedPrice).toStringAsFixed(2)}€',
      );
    }

    print('');
  }

  // ============================================================================
  // CRÉER UN PRODUIT
  // ============================================================================

  print('📦 Création d\'un nouveau produit...\n');

  final newProduct = Product.empty()
    ..name.set('Nouveau Laptop')
    ..price.set(999.99)
    ..stock.set(50)
    ..active.set(true)
    ..discount.set(10); // 10% de remise

  final createdProduct = await client.itemsOf<Product>().createOne(newProduct);

  print('✅ Produit créé: ${createdProduct?.name.value}');
  print('  Prix: ${createdProduct?.price.value}€');
  print('');

  // ============================================================================
  // GESTION DES CATÉGORIES AVEC PARENT
  // ============================================================================

  print('\n📂 Gestion des catégories...\n');

  final categoriesResponse = await client.itemsOf<Category>().readMany();

  for (final category in categoriesResponse.data) {
    print('Catégorie: ${category.name}');
    print('  Slug: ${category.slug}');
    print('  Produits: ${category.productCount}');
    print('  Niveau: ${category.level}');
    print('');
  }

  // ============================================================================
  // AUTEUR AVEC INFORMATIONS DÉRIVÉES
  // ============================================================================

  print('\n✍️ Gestion des auteurs...\n');

  final authorsResponse = await client.itemsOf<Author>().readMany(
    query: QueryParameters(
      filter: Filter.field('status').equals('active'),
      limit: 5,
    ),
  );

  for (final author in authorsResponse.data) {
    print('Auteur: ${author.fullName}');
    print('  Email: ${author.email}');
    print('  Initiales: ${author.initials}');
    print('  Articles: ${author.articleCount}');
    print('  Bio courte: ${author.shortBio}');
    print('');
  }

  // ============================================================================
  // MODIFICATION EN MASSE
  // ============================================================================

  print('\n🔄 Modification en masse...\n');

  // Récupérer des articles
  final articlesToUpdate = await client.itemsOf<Article>().readMany(
    query: QueryParameters(
      filter: Filter.field('status').equals('draft'),
      limit: 10,
    ),
  );

  print('${articlesToUpdate.data.length} articles en brouillon trouvés');

  // Modifier et préparer pour la mise à jour
  final ids = <String>[];
  for (final article in articlesToUpdate.data) {
    if (article.id != null) {
      article.status.set('review');
      ids.add(article.id!);
    }
  }

  // Mettre à jour en masse avec les mêmes données
  if (ids.isNotEmpty) {
    await client.items('articles').updateMany(ids, {'status': 'review'});
    print('✅ ${ids.length} articles mis en révision');
  }

  // ============================================================================
  // VALIDATION ET MÉTADONNÉES
  // ============================================================================

  print('\n🔍 Métadonnées et validation...\n');

  final article = articlesResponse.data.first;

  print('Article: ${article.title}');
  print('  Créé le: ${article.dateCreated}');
  print('  Modifié le: ${article.dateUpdated}');
  print('  Créé par: ${article.userCreated}');
  print('  Modifié par: ${article.userUpdated}');
  print('  Champs modifiés: ${article.dirtyFields}');
  print('  Est modifié: ${article.isDirty}');
  print('');

  // ============================================================================
  // NETTOYAGE
  // ============================================================================

  await client.auth.logout();
  client.dispose();
  print('✅ Terminé !');
}

// =============================================================================
// MODÈLES PERSONNALISÉS
// =============================================================================

/// Modèle Article avec property wrappers
class Article extends DirectusModel {
  Article(super.data);
  Article.empty() : super.empty();

  @override
  String get itemName => 'articles';

  // Property wrappers
  late final title = stringValue('title');
  late final content = stringValue('content');
  late final status = stringValue('status', defaultValue: 'draft');
  late final slug = stringValue('slug');
  late final summary = stringValue('summary');
  late final viewCount = intValue('view_count');
  late final featured = boolValue('featured');
  late final readingTime = intValue('reading_time');

  // Relations
  late final authorId = stringValue('author');
  late final categoryId = stringValue('category');

  // Getters dérivés
  bool get isPublished => status.value == 'published';
  bool get isDraft => status.value == 'draft';

  /// Retourne le début du contenu (100 premiers caractères)
  String get excerpt {
    final text = content.value;
    if (text.length <= 100) return text;
    return '${text.substring(0, 100)}...';
  }
}

/// Modèle Product avec logique métier
class Product extends DirectusModel {
  Product(super.data);
  Product.empty() : super.empty();

  @override
  String get itemName => 'products';

  late final name = stringValue('name');
  late final description = stringValue('description');
  late final price = doubleValue('price');
  late final stock = intValue('stock');
  late final sku = stringValue('sku');
  late final active = boolValue('active');
  late final discount = doubleValue('discount'); // Pourcentage
  late final categoryId = stringValue('category');

  // Logique métier
  bool get hasDiscount => discount.value > 0;

  bool get inStock => stock.value > 0;

  double get discountedPrice {
    if (!hasDiscount) return price.value;
    return price.value * (1 - discount.value / 100);
  }

  /// Vérifie si le produit est en rupture de stock
  bool get isOutOfStock => stock.value == 0;

  /// Vérifie si le stock est faible (< 10)
  bool get isLowStock => stock.value > 0 && stock.value < 10;
}

/// Modèle Category avec hiérarchie
class Category extends DirectusModel {
  Category(super.data);
  Category.empty() : super.empty();

  @override
  String get itemName => 'categories';

  late final name = stringValue('name');
  late final slug = stringValue('slug');
  late final description = stringValue('description');
  late final parentId = stringValue('parent');
  late final order = intValue('order');
  late final productCount = intValue('product_count');
  late final level = intValue('level');

  // Getters
  bool get isRootCategory => parentId.value.isEmpty;
  bool get hasProducts => productCount.value > 0;
}

/// Modèle Author avec informations dérivées
class Author extends DirectusModel {
  Author(super.data);
  Author.empty() : super.empty();

  @override
  String get itemName => 'authors';

  late final firstName = stringValue('first_name');
  late final lastName = stringValue('last_name');
  late final email = stringValue('email');
  late final bio = stringValue('bio');
  late final website = stringValue('website');
  late final avatarId = stringValue('avatar');
  late final status = stringValue('status');
  late final articleCount = intValue('article_count');

  // Propriétés calculées
  String get fullName => '${firstName.value} ${lastName.value}';

  String get initials {
    final first = firstName.value.isNotEmpty ? firstName.value[0] : '';
    final last = lastName.value.isNotEmpty ? lastName.value[0] : '';
    return '$first$last'.toUpperCase();
  }

  String get shortBio {
    final text = bio.value;
    if (text.length <= 150) return text;
    return '${text.substring(0, 150)}...';
  }

  bool get hasWebsite => website.value.isNotEmpty;
  bool get hasAvatar => avatarId.value.isNotEmpty;
  bool get isActive => status.value == 'active';
}
