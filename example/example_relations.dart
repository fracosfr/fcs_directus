// ignore_for_file: avoid_print
// ignore_for_file: unused_local_variable

import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation des Deep queries (relations) avec fcs_directus.
///
/// Démontre :
/// - Chargement de relations simples
/// - Relations multiples
/// - Relations imbriquées (nested)
/// - Filtres sur relations
/// - Limite et tri des relations
void main() async {
  final config = DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    enableLogging: true,
  );

  final client = DirectusClient(config);

  // Authentification
  await client.auth.login(email: 'user@example.com', password: 'your-password');

  // ============================================================================
  // RELATION SIMPLE (Many-to-One)
  // ============================================================================

  print('📌 Relation simple (auteur)\n');

  var query = QueryParameters(
    deep: Deep({
      'author': DeepQuery().fields(['id', 'first_name', 'last_name', 'email']),
    }),
    limit: 5,
  );

  print('Articles avec auteur:');
  var articles = await client.items('articles').readMany(query: query);
  print('  → ${articles.data.length} articles chargés');
  print('  → Chaque article inclut les détails de l\'auteur\n');

  // ============================================================================
  // RELATIONS MULTIPLES
  // ============================================================================

  print('📌 Relations multiples\n');

  query = QueryParameters(
    deep: Deep({
      'author': DeepQuery().fields(['id', 'first_name', 'last_name', 'avatar']),
      'category': DeepQuery().fields(['id', 'name', 'slug']),
      'tags': DeepQuery().fields(['id', 'name']),
    }),
    limit: 5,
  );

  print('Articles avec auteur, catégorie et tags:');
  articles = await client.items('articles').readMany(query: query);
  print('  → ${articles.data.length} articles chargés');
  print('  → Inclut: auteur + catégorie + tags\n');

  // ============================================================================
  // FILTRER LES RELATIONS
  // ============================================================================

  print('📌 Filtrer les relations\n');

  query = QueryParameters(
    deep: Deep({
      'comments': DeepQuery()
          .fields(['id', 'content', 'user_created', 'date_created'])
          .filter(
            Filter.and([
              Filter.field('status').equals('approved'),
              Filter.field('deleted_at').isNull(),
            ]),
          ),
    }),
    limit: 5,
  );

  print('Articles avec commentaires approuvés uniquement:');
  articles = await client.items('articles').readMany(query: query);
  print('  → ${articles.data.length} articles chargés');
  print('  → Seuls les commentaires approuvés sont inclus\n');

  // ============================================================================
  // LIMITER ET TRIER LES RELATIONS
  // ============================================================================

  print('📌 Limiter et trier les relations\n');

  query = QueryParameters(
    deep: Deep({
      'comments': DeepQuery()
          .fields(['id', 'content', 'date_created'])
          .limit(3) // Seulement 3 commentaires par article
          .sort('-date_created'), // Plus récents en premier
    }),
    limit: 5,
  );

  print('Articles avec les 3 derniers commentaires:');
  articles = await client.items('articles').readMany(query: query);
  print('  → ${articles.data.length} articles chargés');
  print('  → Maximum 3 commentaires par article, triés par date\n');

  // ============================================================================
  // RELATIONS IMBRIQUÉES (Nested)
  // ============================================================================

  print('📌 Relations imbriquées (nested)\n');

  query = QueryParameters(
    deep: Deep({
      'author': DeepQuery().fields(['id', 'first_name', 'last_name']).deep({
        'avatar': DeepQuery().fields(['id', 'filename_download', 'type']),
        'role': DeepQuery().fields(['id', 'name', 'description']),
      }),
    }),
    limit: 5,
  );

  print('Articles avec auteur, avatar et rôle de l\'auteur:');
  articles = await client.items('articles').readMany(query: query);
  print('  → ${articles.data.length} articles chargés');
  print('  → Inclut: auteur → (avatar + rôle)\n');

  // ============================================================================
  // RELATIONS COMPLEXES IMBRIQUÉES
  // ============================================================================

  print('📌 Relations complexes imbriquées\n');

  query = QueryParameters(
    deep: Deep({
      'author': DeepQuery().fields(['id', 'first_name', 'last_name']).deep({
        'avatar': DeepQuery().fields(['id', 'filename_download']),
      }),
      'category': DeepQuery().fields(['id', 'name']).deep({
        'parent': DeepQuery().fields(['id', 'name']),
      }),
      'comments': DeepQuery()
          .fields(['id', 'content', 'date_created'])
          .filter(Filter.field('status').equals('approved'))
          .limit(5)
          .sort('-date_created')
          .deep({
            'user_created': DeepQuery().fields(['id', 'first_name', 'avatar']),
          }),
    }),
    limit: 3,
  );

  print('Articles avec relations complexes:');
  print('  - Auteur + avatar');
  print('  - Catégorie + catégorie parente');
  print('  - Commentaires approuvés + utilisateurs');
  articles = await client.items('articles').readMany(query: query);
  print('  → ${articles.data.length} articles chargés\n');

  // ============================================================================
  // RELATIONS ONE-TO-MANY AVEC FILTRES
  // ============================================================================

  print('📌 Relations One-to-Many avec filtres\n');

  query = QueryParameters(
    deep: Deep({
      'products': DeepQuery()
          .fields(['id', 'name', 'price', 'stock'])
          .filter(
            Filter.and([
              Filter.field('status').equals('published'),
              Filter.field('stock').greaterThan(0),
              Filter.field('price').lessThan(1000),
            ]),
          )
          .sort('price')
          .limit(10),
    }),
    limit: 5,
  );

  print('Catégories avec produits filtrés:');
  var categories = await client.items('categories').readMany(query: query);
  print('  → ${categories.data.length} catégories chargées');
  print('  → Produits: publiés, en stock, < 1000€\n');

  // ============================================================================
  // RELATIONS MANY-TO-MANY
  // ============================================================================

  print('📌 Relations Many-to-Many\n');

  query = QueryParameters(
    deep: Deep({
      'categories': DeepQuery().fields(['id']).deep({
        'categories_id': DeepQuery().fields(['id', 'name', 'slug']),
      }),
      'tags': DeepQuery().fields(['id']).deep({
        'tags_id': DeepQuery().fields(['id', 'name']),
      }),
    }),
    limit: 5,
  );

  print('Articles avec relations M2M (catégories et tags):');
  articles = await client.items('articles').readMany(query: query);
  print('  → ${articles.data.length} articles chargés');
  print('  → Inclut: catégories + tags via jonctions\n');

  // ============================================================================
  // EXEMPLE COMPLET : BLOG POST
  // ============================================================================

  print('📌 Exemple complet : Article de blog\n');

  query = QueryParameters(
    filter: Filter.and([
      Filter.field('status').equals('published'),
      Filter.field('date_published').isNotNull(),
    ]),
    deep: Deep({
      // Auteur avec avatar et rôle
      'author': DeepQuery()
          .fields(['id', 'first_name', 'last_name', 'email', 'title'])
          .deep({
            'avatar': DeepQuery().fields([
              'id',
              'filename_download',
              'type',
              'width',
              'height',
            ]),
            'role': DeepQuery().fields(['id', 'name', 'icon']),
          }),

      // Image principale
      'featured_image': DeepQuery().fields([
        'id',
        'filename_download',
        'title',
        'description',
        'width',
        'height',
      ]),

      // Catégorie avec parent
      'category': DeepQuery()
          .fields(['id', 'name', 'slug', 'description'])
          .deep({
            'parent': DeepQuery().fields(['id', 'name', 'slug']),
          }),

      // Tags
      'tags': DeepQuery().fields(['id']).deep({
        'tags_id': DeepQuery().fields(['id', 'name', 'slug', 'color']),
      }),

      // Commentaires approuvés avec utilisateurs
      'comments': DeepQuery()
          .fields(['id', 'content', 'date_created', 'rating'])
          .filter(
            Filter.and([
              Filter.field('status').equals('approved'),
              Filter.field('deleted').equals(false),
            ]),
          )
          .sort('-date_created')
          .limit(10)
          .deep({
            'user_created': DeepQuery()
                .fields(['id', 'first_name', 'last_name'])
                .deep({
                  'avatar': DeepQuery().fields(['id', 'filename_download']),
                }),
          }),

      // Articles liés
      'related_articles': DeepQuery().fields(['id']).deep({
        'related_articles_id': DeepQuery()
            .fields(['id', 'title', 'slug', 'summary', 'date_published'])
            .filter(Filter.field('status').equals('published'))
            .limit(3),
      }),
    }),
    fields: [
      'id',
      'title',
      'slug',
      'summary',
      'content',
      'status',
      'date_published',
      'date_updated',
      'view_count',
      'reading_time',
    ],
    sort: ['-date_published'],
    limit: 1,
  );

  print('Chargement d\'un article complet:');
  print('  - Auteur (avatar, rôle)');
  print('  - Image principale');
  print('  - Catégorie (parent)');
  print('  - Tags');
  print('  - Commentaires (utilisateurs)');
  print('  - Articles liés');

  articles = await client.items('articles').readMany(query: query);

  if (articles.data.isNotEmpty) {
    final article = articles.data.first;
    print('\n✅ Article chargé: ${article['title']}');
    print('   Slug: ${article['slug']}');
    print('   Date: ${article['date_published']}');
    print('   Vues: ${article['view_count']}');

    if (article['author'] != null) {
      final author = article['author'] as Map<String, dynamic>;
      print('   Auteur: ${author['first_name']} ${author['last_name']}');
    }

    if (article['category'] != null) {
      final category = article['category'] as Map<String, dynamic>;
      print('   Catégorie: ${category['name']}');
    }

    if (article['comments'] != null) {
      final comments = article['comments'] as List;
      print('   Commentaires: ${comments.length}');
    }
  }

  // ============================================================================
  // DEEP AVEC PROFONDEUR MAXIMALE
  // ============================================================================

  print('\n📌 Deep avec profondeur maximale\n');

  query = QueryParameters(
    deep: Deep.maxDepth(3), // Charge toutes les relations jusqu'à 3 niveaux
    limit: 1,
  );

  print('Article avec toutes les relations (profondeur 3):');
  articles = await client.items('articles').readMany(query: query);
  print('  → ${articles.data.length} article chargé');
  print('  → Toutes les relations jusqu\'à 3 niveaux de profondeur\n');

  // ============================================================================
  // NETTOYAGE
  // ============================================================================

  await client.auth.logout();
  client.dispose();
  print('✅ Terminé !');
}
