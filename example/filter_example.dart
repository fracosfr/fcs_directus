import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation du système de filtres type-safe
///
/// Ce fichier démontre 13 scénarios d'utilisation des filtres:
///
/// 1. Filtres simples (égalité, comparaisons)
/// 2. Opérateurs de comparaison (gt, gte, lt, lte)
/// 3. Opérateurs de chaînes (contains, starts_with, ends_with)
/// 4. Opérateurs de listes (in, between)
/// 5. Opérateurs null et empty
/// 6. Combinaisons logiques (and, or)
/// 7. Négation (not)
/// 8. Filtres complexes imbriqués
/// 9. Filtres sur relations
/// 10. Recherche insensible à la casse
/// 11. Filtres O2M (some/none)
/// 12. Validation avec regex
/// 13. Comparaison ancien vs nouveau système
void main() async {
  final config = DirectusConfig(baseUrl: 'https://your-directus-instance.com');
  final client = DirectusClient(config);

  try {
    await client.auth.login(email: 'admin@example.com', password: 'password');

    final productsService = client.items('products');

    print('🎯 Exemples de filtres Directus\n');

    // === 1. Filtres simples ===
    print('📌 1. Filtres de comparaison simples\n');

    // Égalité
    print('   Produits actifs:');
    var response = await productsService.readMany(
      query: QueryParameters(
        filter: Filter.field('status').equals('active'),
        limit: 5,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    // Différent de
    print('   Produits non archivés:');
    response = await productsService.readMany(
      query: QueryParameters(
        filter: Filter.field('status').notEquals('archived'),
        limit: 5,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    // Comparaisons numériques
    print('   Produits > 100€:');
    response = await productsService.readMany(
      query: QueryParameters(
        filter: Filter.field('price').greaterThan(100),
        limit: 5,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    print('   Produits entre 50€ et 200€:');
    response = await productsService.readMany(
      query: QueryParameters(
        filter: Filter.field('price').between(50, 200),
        limit: 5,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    // === 2. Filtres de chaîne ===
    print('📌 2. Filtres sur les chaînes de caractères\n');

    print('   Produits contenant "laptop":');
    response = await productsService.readMany(
      query: QueryParameters(
        filter: Filter.field('name').contains('laptop'),
        limit: 5,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    print('   Produits commençant par "Apple":');
    response = await productsService.readMany(
      query: QueryParameters(
        filter: Filter.field('name').startsWith('Apple'),
        limit: 5,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    // === 3. Filtres sur les listes ===
    print('📌 3. Filtres sur les listes\n');

    print('   Produits avec catégorie electronics, computers ou phones:');
    response = await productsService.readMany(
      query: QueryParameters(
        filter: Filter.field(
          'category',
        ).inList(['electronics', 'computers', 'phones']),
        limit: 5,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    // === 4. Filtres NULL ===
    print('📌 4. Filtres NULL\n');

    print('   Produits avec description:');
    response = await productsService.readMany(
      query: QueryParameters(
        filter: Filter.field('description').isNotNull(),
        limit: 5,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    // === 5. Combinaisons AND ===
    print('📌 5. Combinaisons de filtres (AND)\n');

    print('   Produits actifs ET en stock ET > 100€:');
    response = await productsService.readMany(
      query: QueryParameters(
        filter: Filter.and([
          Filter.field('status').equals('active'),
          Filter.field('stock').greaterThan(0),
          Filter.field('price').greaterThan(100),
        ]),
        limit: 5,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    // === 6. Combinaisons OR ===
    print('📌 6. Combinaisons de filtres (OR)\n');

    print('   Produits en promo OU en vedette:');
    response = await productsService.readMany(
      query: QueryParameters(
        filter: Filter.or([
          Filter.field('on_sale').equals(true),
          Filter.field('featured').equals(true),
        ]),
        limit: 5,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    // === 7. Filtres imbriqués complexes ===
    print('📌 7. Filtres imbriqués complexes\n');

    print('   Produits:');
    print('   - (catégorie electronics ET prix < 500€)');
    print('   - OU en vedette');
    response = await productsService.readMany(
      query: QueryParameters(
        filter: Filter.or([
          Filter.and([
            Filter.field('category').equals('electronics'),
            Filter.field('price').lessThan(500),
          ]),
          Filter.field('featured').equals(true),
        ]),
        limit: 5,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    // === 8. Filtres sur les relations ===
    print('📌 8. Filtres sur les relations\n');

    print('   Produits avec catégorie "Premium":');
    response = await productsService.readMany(
      query: QueryParameters(
        filter: Filter.relation(
          'category',
        ).where(Filter.field('name').equals('Premium')),
        limit: 5,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    // === 9. Exemple complexe réaliste ===
    print('📌 9. Exemple complexe réaliste\n');

    print('   Recherche produits pour marketplace:');
    print('   - Actifs et en stock');
    print('   - Prix entre 20€ et 1000€');
    print('   - Catégorie electronics OU computers');
    print('   - Avec images');

    response = await productsService.readMany(
      query: QueryParameters(
        filter: Filter.and([
          // Statut et stock
          Filter.field('status').equals('active'),
          Filter.field('stock').greaterThan(0),
          // Fourchette de prix
          Filter.field('price').between(20, 1000),
          // Catégories
          Filter.or([
            Filter.field('category').equals('electronics'),
            Filter.field('category').equals('computers'),
          ]),
          // Doit avoir des images
          Filter.field('images').isNotEmpty(),
        ]),
        fields: ['id', 'name', 'price', 'stock', 'category'],
        sort: ['price'],
        limit: 10,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    // === 10. Recherche insensible à la casse ===
    print('📌 10. Recherche insensible à la casse\n');

    print('   Produits contenant "laptop" (insensible):');
    response = await productsService.readMany(
      query: QueryParameters(
        filter: Filter.field('name').containsInsensitive('LAPTOP'),
        limit: 5,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    print('   Emails se terminant par ".com" (insensible):');
    response = await client
        .items('users')
        .readMany(
          query: QueryParameters(
            filter: Filter.field('email').endsWithInsensitive('.COM'),
            limit: 5,
          ),
        );
    print('   → ${response.data.length} résultats\n');

    // === 11. Filtres O2M (some/none) ===
    print('📌 11. Filtres sur relations One-to-Many\n');

    print('   Auteurs avec AU MOINS un article publié:');
    response = await client
        .items('authors')
        .readMany(
          query: QueryParameters(
            filter: Filter.some(
              'articles',
            ).where(Filter.field('status').equals('published')),
            limit: 5,
          ),
        );
    print('   → ${response.data.length} résultats\n');

    print('   Utilisateurs SANS violations critiques:');
    response = await client
        .items('users')
        .readMany(
          query: QueryParameters(
            filter: Filter.none(
              'violations',
            ).where(Filter.field('severity').equals('critical')),
            limit: 5,
          ),
        );
    print('   → ${response.data.length} résultats\n');

    // === 12. Validation avec regex ===
    print('📌 12. Validation avec expressions régulières\n');

    print('   Emails valides:');
    response = await client
        .items('users')
        .readMany(
          query: QueryParameters(
            filter: Filter.field(
              'email',
            ).regex(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'),
            limit: 5,
          ),
        );
    print('   → ${response.data.length} résultats\n');

    // === 13. Comparaison ancien vs nouveau ===
    print('📌 13. Comparaison ancien vs nouveau système\n');

    print('   ❌ ANCIEN (Map manuel):');
    print('   filter: {');
    print('     "_and": [');
    print('       {"status": {"_eq": "active"}},');
    print('       {"price": {"_gte": 100}},');
    print('       {"stock": {"_gt": 0}}');
    print('     ]');
    print('   }\n');

    print('   ✅ NOUVEAU (API fluide):');
    print('   filter: Filter.and([');
    print('     Filter.field("status").equals("active"),');
    print('     Filter.field("price").greaterThanOrEqual(100),');
    print('     Filter.field("stock").greaterThan(0),');
    print('   ])\n');

    print('   Avantages:');
    print('   ✅ Type-safe et autocomplétion');
    print('   ✅ Plus lisible et maintenable');
    print('   ✅ Pas besoin de connaître les opérateurs Directus');
    print('   ✅ Erreurs à la compilation au lieu du runtime');

    await client.auth.logout();
  } catch (e) {
    if (e is DirectusException) {
      print('❌ Erreur: ${e.message}');
    } else {
      print('❌ Erreur: $e');
    }
  } finally {
    client.dispose();
  }
}
