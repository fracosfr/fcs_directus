import 'package:fcs_directus/fcs_directus.dart';

/// Exemple basique d'utilisation de la librairie fcs_directus
///
/// Cet exemple montre comment:
/// - Se connecter à Directus
/// - S'authentifier
/// - Effectuer des opérations CRUD sur une collection
/// - Utiliser DirectusModel pour des modèles typés
/// - Utiliser la méthode itemsOf() pour un accès type-safe

// Modèle Article avec DirectusModel
class Article extends DirectusModel {
  @override
  String get itemName => 'articles';
  static const String collectionName = "articles";

  Article(super.data);
  Article.empty() : super.empty();

  // Getters
  String get title => getString('title');
  String? get content => getStringOrNull('content');
  String get status => getString('status', defaultValue: 'draft');
  @override
  DateTime? get dateCreated => getDateTime('date_created');

  // Setters
  set title(String value) => setString('title', value);
  set content(String? value) => setStringOrNull('content', value);
  set status(String value) => setString('status', value);

  @override
  String toString() => 'Article(id: $id, title: $title, status: $status)';
}

void main() async {
  // Enregistrer la factory pour Article
  DirectusModel.registerFactory<Article>((data) => Article(data));
  // 1. Configuration
  final config = DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    enableLogging: true, // Active les logs pour le debug
  );

  // 2. Création du client
  final client = DirectusClient(config);

  try {
    // 3. Authentification
    print('📡 Connexion à Directus...');
    await client.auth.login(email: 'admin@example.com', password: 'password');
    print('✅ Authentifié avec succès!');

    // 4. Lecture de données - Méthode 1: Traditionnelle avec Map
    print('\n📖 Méthode 1: Lecture avec items() (Map)...');
    final articlesService = client.items(Article.collectionName);

    var response = await articlesService.readMany(
      query: QueryParameters(
        limit: 5,
        sort: ['-date_created'],
        fields: ['id', 'title', 'status'],
        filter: Filter.field('status').notEquals('archived'),
      ),
    );

    print('✅ ${response.data.length} articles trouvés (Map)');
    for (final article in response.data) {
      print('  - ${article['title']} [${article['status']}]');
    }

    // 4b. Lecture de données - Méthode 2: Type-safe avec itemsOf<T>()
    print('\n📖 Méthode 2: Lecture avec itemsOf<Article>() (Type-safe)...');
    final articlesTyped = client.itemsOf<Article>();

    final typedResponse = await articlesTyped.readMany(
      query: QueryParameters(
        limit: 5,
        sort: ['-date_created'],
        filter: Filter.field('status').notEquals('archived'),
      ),
    );

    print('✅ ${typedResponse.data.length} articles trouvés (typés)');
    for (final article in typedResponse.data) {
      // article est de type Article, pas Map!
      print('  - ${article.title} [${article.status}]');
      print('    Créé le: ${article.dateCreated ?? "date inconnue"}');
    }

    // 5. Récupérer un article spécifique (type-safe)
    if (typedResponse.data.isNotEmpty) {
      final firstArticle = typedResponse.data.first;
      print('\n📖 Lecture de l\'article ${firstArticle.id}...');

      final article = await articlesTyped.readOne(firstArticle.id!);
      print('✅ Article récupéré: ${article.title}');
      print('   Contenu: ${article.content ?? "pas de contenu"}');
    }

    // 6. Créer un nouvel article (avec DirectusModel)
    print('\n📝 Création d\'un nouvel article (type-safe)...');

    // Créer un objet Article
    final articleToCreate = Article.empty();
    articleToCreate.title = 'Mon premier article via API';
    articleToCreate.content = 'Contenu de l\'article créé avec DirectusModel';
    articleToCreate.status = 'draft';

    final newArticle = await articlesTyped.createOne(articleToCreate.toMap());
    print('✅ Article créé: $newArticle');

    // 7. Mettre à jour l'article (avec DirectusModel)
    print('\n✏️  Mise à jour de l\'article...');

    // Modifier l'objet Article
    newArticle.title = 'Titre modifié via DirectusModel';
    newArticle.status = 'published';

    final updatedArticle = await articlesTyped.updateOne(
      newArticle.id!,
      newArticle.toMap(),
    );
    print('✅ Article mis à jour: $updatedArticle');

    // 8. Recherche avec filtres complexes
    print('\n🔍 Recherche d\'articles publiés (avec Filter)...');
    final publishedArticles = await articlesTyped.readMany(
      query: QueryParameters(
        filter: Filter.and([
          Filter.field('status').equals('published'),
          Filter.field('title').contains('API'),
        ]),
        sort: ['-date_created'],
        limit: 5,
      ),
    );
    print('✅ ${publishedArticles.data.length} articles publiés trouvés');
    for (final article in publishedArticles.data) {
      print('  - ${article.title}');
    }

    // 9. Utilisation avec objets DirectusModel
    print('\n🎯 Utilisation avancée avec DirectusModel...');

    // Créer un objet, le modifier, puis l'envoyer
    final quickArticle = Article.empty();
    quickArticle.title = 'Article créé avec DirectusModel';
    quickArticle.status = 'draft';
    quickArticle.content = 'Contenu généré programmatiquement';

    final created = await articlesTyped.createOne(quickArticle.toMap());
    print('✅ Article créé: ${created.title}');

    // Modifier l'objet reçu
    created.title = 'Titre modifié';
    created.status = 'published';

    final updated = await articlesTyped.updateOne(created.id!, created.toMap());
    print('✅ Article mis à jour: ${updated.title}');

    // Supprimer
    await articlesTyped.deleteOne(updated.id!);
    print('✅ Article supprimé');

    // 10. Supprimer l'article de test principal
    print('\n🗑️  Suppression de l\'article de test...');
    await articlesTyped.deleteOne(newArticle.id!);
    print('✅ Article supprimé');

    // 11. Comparaison des deux approches
    print('\n⚖️  Comparaison des approches:');
    print('   Méthode 1 - items("articles"):');
    print('   ✅ Flexible, pas de modèle requis');
    print('   ✅ Bon pour du code rapide/prototyping');
    print('   ❌ Pas de type-safety');
    print('   ❌ Accès par clés string: article["title"]');
    print('');
    print('   Méthode 2 - itemsOf<Article>():');
    print('   ✅ Type-safe, erreurs à la compilation');
    print('   ✅ Auto-complétion IDE');
    print('   ✅ Accès typé: article.title');
    print('   ✅ Modèles réutilisables et maintenables');
    print('   ❌ Nécessite de définir un modèle');

    // 12. Informations sur l'utilisateur connecté
    print('\n👤 Informations utilisateur...');
    final me = await client.users.me();
    print('✅ Connecté en tant que: ${me['email']}');

    // 13. Déconnexion
    print('\n🔒 Déconnexion...');
    await client.auth.logout();
    print('✅ Déconnecté');
  } catch (e) {
    if (e is DirectusException) {
      print('❌ Erreur Directus: ${e.message}');
      if (e.statusCode != null) {
        print('   Code HTTP: ${e.statusCode}');
      }
    } else {
      print('❌ Erreur: $e');
    }
  } finally {
    // 14. Nettoyage
    client.dispose();
    print('\n🔌 Client fermé');
  }

  print('\n📚 Résumé:');
  print('   ✅ items("collection") → Retourne Map');
  print('   ✅ itemsOf() → Retourne Model extends DirectusModel');
  print('   ✅ Filter pour des requêtes complexes');
  print('   ✅ DirectusModel pour CRUD type-safe');
  print('   ✅ Getters/setters typés avec validation');
}
