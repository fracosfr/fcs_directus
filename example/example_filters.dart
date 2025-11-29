// ignore_for_file: non_constant_identifier_names, avoid_print, unused_local_variable

import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation avancée des filtres avec fcs_directus.
///
/// Démontre :
/// - Filtres simples et combinés
/// - Opérateurs de comparaison
/// - Opérateurs de chaîne
/// - Filtres sur relations
/// - Filtres NULL et booléens
void main() async {
  final config = DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    enableLogging: true,
  );

  final client = DirectusClient(config);

  // Authentification
  await client.auth.login(email: 'user@example.com', password: 'your-password');

  // ============================================================================
  // FILTRES SIMPLES
  // ============================================================================

  print('📌 Filtres simples\n');

  // Égalité
  var query = QueryParameters(
    filter: Filter.field('status').equals('published'),
  );
  print('Produits publiés:');
  var products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats\n');

  // Comparaison numérique
  query = QueryParameters(filter: Filter.field('price').greaterThan(100));
  print('Produits > 100€:');
  products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats\n');

  // Entre deux valeurs
  query = QueryParameters(filter: Filter.field('price').between(50, 200));
  print('Produits entre 50€ et 200€:');
  products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats\n');

  // ============================================================================
  // OPÉRATEURS DE CHAÎNE
  // ============================================================================

  print('📌 Opérateurs de chaîne\n');

  // Contient
  query = QueryParameters(filter: Filter.field('name').contains('laptop'));
  print('Produits contenant "laptop":');
  products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats\n');

  // Commence par
  query = QueryParameters(filter: Filter.field('name').startsWith('Apple'));
  print('Produits commençant par "Apple":');
  products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats\n');

  // Se termine par
  query = QueryParameters(
    filter: Filter.field('email').endsWith('@example.com'),
  );
  print('Emails @example.com:');
  var users = await client.items('users').readMany(query: query);
  print('  → ${users.data.length} résultats\n');

  // Insensible à la casse
  query = QueryParameters(
    filter: Filter.field('name').containsInsensitive('LAPTOP'),
  );
  print('Produits contenant "LAPTOP" (insensible):');
  products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats\n');

  // ============================================================================
  // OPÉRATEURS DE LISTE
  // ============================================================================

  print('📌 Opérateurs de liste\n');

  // Dans la liste
  query = QueryParameters(
    filter: Filter.field('category').inList(['electronics', 'computers']),
  );
  print('Produits dans electronics ou computers:');
  products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats\n');

  // Pas dans la liste
  query = QueryParameters(
    filter: Filter.field('status').notInList(['archived', 'deleted']),
  );
  print('Produits non archivés/supprimés:');
  products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats\n');

  // ============================================================================
  // FILTRES NULL ET BOOLÉENS
  // ============================================================================

  print('📌 Filtres NULL et booléens\n');

  // NULL
  query = QueryParameters(filter: Filter.field('deleted_at').isNull());
  print('Produits non supprimés (deleted_at est NULL):');
  products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats\n');

  // NOT NULL
  query = QueryParameters(filter: Filter.field('description').isNotNull());
  print('Produits avec description:');
  products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats\n');

  // Booléen
  query = QueryParameters(filter: Filter.field('featured').equals(true));
  print('Produits en vedette:');
  products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats\n');

  // ============================================================================
  // FILTRES COMBINÉS AVEC AND
  // ============================================================================

  print('📌 Filtres combinés avec AND\n');

  query = QueryParameters(
    filter: Filter.and([
      Filter.field('status').equals('published'),
      Filter.field('price').greaterThan(50),
      Filter.field('stock').greaterThan(0),
    ]),
  );
  print('Produits publiés, > 50€ et en stock:');
  products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats\n');

  // ============================================================================
  // FILTRES COMBINÉS AVEC OR
  // ============================================================================

  print('📌 Filtres combinés avec OR\n');

  query = QueryParameters(
    filter: Filter.or([
      Filter.field('featured').equals(true),
      Filter.field('price').lessThan(50),
    ]),
  );
  print('Produits en vedette OU < 50€:');
  products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats\n');

  // ============================================================================
  // FILTRES IMBRIQUÉS COMPLEXES
  // ============================================================================

  print('📌 Filtres imbriqués complexes\n');

  query = QueryParameters(
    filter: Filter.and([
      Filter.field('status').equals('published'),
      Filter.or([
        Filter.and([
          Filter.field('category').equals('electronics'),
          Filter.field('price').lessThan(500),
        ]),
        Filter.field('featured').equals(true),
      ]),
      Filter.field('stock').greaterThan(0),
    ]),
  );
  print('Produits complexes:');
  print('  - Publiés ET en stock');
  print('  - ET (électronique < 500€ OU en vedette)');
  products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats\n');

  // ============================================================================
  // FILTRES SUR RELATIONS
  // ============================================================================

  print('📌 Filtres sur relations\n');

  // Filtre sur une relation Many-to-One
  query = QueryParameters(
    filter: Filter.relation(
      'author',
    ).where(Filter.field('status').equals('active')),
  );
  print('Articles dont l\'auteur est actif:');
  var articles = await client.items('articles').readMany(query: query);
  print('  → ${articles.data.length} résultats\n');

  // Filtre "some" sur une relation One-to-Many
  // Au moins une catégorie correspond
  query = QueryParameters(
    filter: Filter.some(
      'categories',
    ).where(Filter.field('name').equals('Technology')),
  );
  print('Articles avec au moins une catégorie "Technology":');
  articles = await client.items('articles').readMany(query: query);
  print('  → ${articles.data.length} résultats\n');

  // Filtre "none" sur une relation One-to-Many
  // Aucune catégorie ne correspond
  query = QueryParameters(
    filter: Filter.none('tags').where(Filter.field('name').equals('draft')),
  );
  print('Articles sans le tag "draft":');
  articles = await client.items('articles').readMany(query: query);
  print('  → ${articles.data.length} résultats\n');

  // ============================================================================
  // FILTRES AVEC RECHERCHE ET PAGINATION
  // ============================================================================

  print('📌 Filtres avec recherche et pagination\n');

  query = QueryParameters(
    filter: Filter.and([
      Filter.field('status').equals('published'),
      Filter.field('price').between(50, 500),
    ]),
    search: 'laptop',
    sort: ['-date_created', 'price'],
    limit: 10,
    offset: 0,
  );
  print('Produits publiés, 50-500€, contenant "laptop":');
  print('  - Triés par date (desc) puis prix (asc)');
  print('  - Page 1 (10 items)');
  products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats');
  if (products.meta?.totalCount != null) {
    print('  → ${products.meta!.totalCount} au total\n');
  }

  // ============================================================================
  // FILTRES AVEC SÉLECTION DE CHAMPS
  // ============================================================================

  print('📌 Filtres avec sélection de champs\n');

  query = QueryParameters(
    filter: Filter.field('status').equals('published'),
    fields: ['id', 'name', 'price', 'status'],
    limit: 5,
  );
  print('Produits publiés (champs limités):');
  products = await client.items('products').readMany(query: query);
  print('  → ${products.data.length} résultats');
  if (products.data.isNotEmpty) {
    print('  → Champs: ${products.data.first.keys.join(", ")}\n');
  }

  // ============================================================================
  // EXEMPLE COMPLET : RECHERCHE MULTI-CRITÈRES
  // ============================================================================

  print('📌 Exemple complet : Recherche multi-critères\n');

  query = QueryParameters(
    filter: Filter.and([
      // Statut publié
      Filter.field('status').equals('published'),
      // En stock
      Filter.field('stock').greaterThan(0),
      // Prix entre 100 et 1000
      Filter.field('price').between(100, 1000),
      // Catégorie dans electronics ou computers
      Filter.field('category').inList(['electronics', 'computers']),
      // Pas supprimé
      Filter.field('deleted_at').isNull(),
      // Soit en vedette, soit bien noté
      Filter.or([
        Filter.field('featured').equals(true),
        Filter.field('rating').greaterThanOrEqual(4.5),
      ]),
    ]),
    search: 'pro',
    sort: ['-featured', '-rating', 'price'],
    fields: ['id', 'name', 'price', 'rating', 'featured', 'stock'],
    limit: 20,
  );

  print('Critères de recherche:');
  print('  - Publié et en stock');
  print('  - Prix: 100-1000€');
  print('  - Catégorie: electronics ou computers');
  print('  - Non supprimé');
  print('  - En vedette OU note ≥ 4.5');
  print('  - Contenant "pro"');
  print('  - Tri: vedette, note, prix');
  print('  - Limité à 20 résultats');

  products = await client.items('products').readMany(query: query);
  print('\n✅ ${products.data.length} produits trouvés');

  // Afficher les résultats
  for (var i = 0; i < products.data.length && i < 5; i++) {
    final product = products.data[i];
    print('  ${i + 1}. ${product['name']}');
    print(
      '     Prix: ${product['price']}€ | Note: ${product['rating']} | '
      'Stock: ${product['stock']}',
    );
  }

  // ============================================================================
  // NETTOYAGE
  // ============================================================================

  await client.auth.logout();
  client.dispose();
  print('\n✅ Terminé !');
}
