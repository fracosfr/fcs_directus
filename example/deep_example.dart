/// Exemples d'utilisation du système Deep pour les relations imbriquées
///
/// Ce fichier montre comment utiliser le système Deep de manière intuitive
/// pour charger des relations imbriquées dans Directus.

import 'package:fcs_directus/fcs_directus.dart';

void main() async {
  // Configuration et initialisation
  final config = DirectusConfig(baseUrl: 'https://directus.example.com');
  final client = DirectusClient(config);

  // Authentification
  await client.auth.login(email: 'user@example.com', password: 'password');

  // ============================================================================
  // Exemple 1: Deep simple avec sélection de champs
  // ============================================================================
  print('=== Exemple 1: Deep simple ===');

  // Nouvelle méthode avec Deep - plus intuitive !
  final queryNew1 = QueryParameters(
    deep: Deep({
      'author': DeepQuery().fields(['id', 'name', 'email']),
    }),
  );

  final articles1 = await client.items('articles').readMany(query: queryNew1);
  print('Articles avec auteur: $articles1');

  // Ancienne méthode avec Map (toujours supportée pour compatibilité)
  // final queryOld1 = QueryParameters(
  //   deep: {
  //     'author': {
  //       '_fields': ['id', 'name', 'email'],
  //     },
  //   },
  // );

  // ============================================================================
  // Exemple 2: Deep avec limite et tri
  // ============================================================================
  print('\n=== Exemple 2: Deep avec limite et tri ===');

  final query2 = QueryParameters(
    deep: Deep({
      'comments': DeepQuery()
          .limit(5)
          .sort('-created_at') // Tri décroissant par date
          .fields(['id', 'content', 'created_at', 'user']),
    }),
  );

  final articles2 = await client.items('articles').readMany(query: query2);
  print('Articles avec 5 derniers commentaires: $articles2');

  // ============================================================================
  // Exemple 3: Deep avec filtres
  // ============================================================================
  print('\n=== Exemple 3: Deep avec filtres ===');

  final query3 = QueryParameters(
    deep: Deep({
      'categories': DeepQuery()
          .filter(Filter.field('status').equals('published'))
          .sort('name'),
    }),
  );

  final articles3 = await client.items('articles').readMany(query: query3);
  print('Articles avec catégories publiées: $articles3');

  // ============================================================================
  // Exemple 4: Deep imbriqué (relations dans des relations)
  // ============================================================================
  print('\n=== Exemple 4: Deep imbriqué ===');

  final query4 = QueryParameters(
    deep: Deep({
      'author': DeepQuery().fields(['id', 'name', 'avatar']).deep({
        'avatar': DeepQuery().fields(['id', 'filename_disk', 'title']),
      }),
    }),
  );

  final articles4 = await client.items('articles').readMany(query: query4);
  print('Articles avec auteur et son avatar: $articles4');

  // ============================================================================
  // Exemple 5: Deep multiple (plusieurs relations)
  // ============================================================================
  print('\n=== Exemple 5: Deep multiple ===');

  final query5 = QueryParameters(
    deep: Deep({
      'author': DeepQuery().fields(['name', 'email']),
      'categories': DeepQuery().limit(10).sort('name'),
      'featured_image': DeepQuery().fields([
        'id',
        'filename_disk',
        'width',
        'height',
      ]),
    }),
  );

  final articles5 = await client.items('articles').readMany(query: query5);
  print('Articles avec auteur, catégories et image: $articles5');

  // ============================================================================
  // Exemple 6: E-commerce avec deep complexe
  // ============================================================================
  print('\n=== Exemple 6: E-commerce avec deep complexe ===');

  final query6 = QueryParameters(
    deep: Deep({
      'items': DeepQuery().fields(['id', 'quantity', 'price', 'product']).deep({
        'product': DeepQuery().fields(['id', 'name', 'image', 'category']).deep(
          {
            'image': DeepQuery().fields(['id', 'filename_disk']),
            'category': DeepQuery().fields(['id', 'name']),
          },
        ),
      }),
      'customer': DeepQuery()
          .fields(['id', 'first_name', 'last_name', 'email', 'avatar'])
          .deep({
            'avatar': DeepQuery().fields(['id', 'filename_disk']),
          }),
      'shipping_address': DeepQuery().allFields(),
    }),
  );

  final orders = await client.items('orders').readMany(query: query6);
  print('Commandes complètes avec produits et clients: $orders');

  // ============================================================================
  // Exemple 7: Utilisation des extensions (méthodes utilitaires)
  // ============================================================================
  print('\n=== Exemple 7: Extensions utilitaires ===');

  final query7 = QueryParameters(
    deep: Deep({
      'products': DeepQuery()
          .allFields() // Tous les champs
          .sortDesc('created_at') // Tri décroissant
          .first(3), // 3 premiers seulement
    }),
  );

  final categories = await client.items('categories').readMany(query: query7);
  print('Catégories avec 3 produits récents: $categories');

  // ============================================================================
  // Exemple 8: Blog avec commentaires filtrés
  // ============================================================================
  print('\n=== Exemple 8: Blog avec commentaires filtrés ===');

  final query8 = QueryParameters(
    deep: Deep({
      'comments': DeepQuery()
          .filter(
            Filter.and([
              Filter.field('status').equals('approved'),
              Filter.field('spam').equals(false),
            ]),
          )
          .sortDesc('created_at')
          .limit(10)
          .fields(['id', 'content', 'created_at', 'user'])
          .deep({
            'user': DeepQuery().fields(['id', 'name', 'avatar']),
          }),
    }),
  );

  final posts = await client.items('posts').readMany(query: query8);
  print('Articles avec commentaires approuvés: $posts');

  // ============================================================================
  // Exemple 9: Many-to-Many avec filtre sur la jonction
  // ============================================================================
  print('\n=== Exemple 9: Many-to-Many avec filtre ===');

  final query9 = QueryParameters(
    deep: Deep({
      'movie_actors': DeepQuery()
          .filter(Filter.field('role').equals('lead'))
          .deep({
            'actors': DeepQuery().fields(['id', 'name', 'photo']).deep({
              'photo': DeepQuery().fields(['id', 'filename_disk']),
            }),
          }),
    }),
  );

  final movies = await client.items('movies').readMany(query: query9);
  print('Films avec acteurs principaux: $movies');

  // ============================================================================
  // Exemple 10: Combinaison Filter + Deep
  // ============================================================================
  print('\n=== Exemple 10: Combinaison Filter + Deep ===');

  final query10 = QueryParameters(
    // Filtre sur l'article principal
    filter: Filter.and([
      Filter.field('status').equals('published'),
      Filter.field('featured').equals(true),
    ]),
    // Deep pour les relations
    deep: Deep({
      'author': DeepQuery().fields(['id', 'name', 'bio', 'avatar']).deep({
        'avatar': DeepQuery().fields(['id', 'filename_disk']),
      }),
      'categories': DeepQuery()
          .filter(Filter.field('featured').equals(true))
          .sortAsc('name'),
    }),
    // Autres paramètres
    limit: 10,
    sort: ['-published_at'],
  );

  final featuredArticles = await client
      .items('articles')
      .readMany(query: query10);
  print('Articles en vedette avec détails complets: $featuredArticles');

  // ============================================================================
  // Exemple 11: Deep avec profondeur maximale (approche simple)
  // ============================================================================
  print('\n=== Exemple 11: Deep avec profondeur maximale ===');

  // Pour des cas simples, vous pouvez utiliser maxDepth
  final query11 = QueryParameters(
    deep: Deep.maxDepth(3), // Charge jusqu'à 3 niveaux de profondeur
  );

  final items = await client.items('items').readMany(query: query11);
  print('Items avec relations jusqu\'à 3 niveaux: $items');

  // Déconnexion
  await client.auth.logout();
}
