import 'package:fcs_directus/fcs_directus.dart';

/// Exemple de création et utilisation d'un modèle personnalisé
/// avec DirectusModelBuilder et DirectusMapBuilder
///
/// Cet exemple montre comment:
/// - Utiliser DirectusModelBuilder pour simplifier fromJson
/// - Utiliser DirectusMapBuilder pour simplifier toMap
/// - Éliminer tout le code boilerplate de sérialisation

/// Modèle Article utilisant les builders
class Article extends DirectusModel {
  final String title;
  final String? content;
  final String status;
  final String? author;

  Article._({
    super.id,
    required this.title,
    this.content,
    required this.status,
    super.dateCreated,
    super.dateUpdated,
    this.author,
  });

  /// Constructeur public pour créer de nouveaux articles
  factory Article({
    String? id,
    required String title,
    String? content,
    String status = 'draft',
    DateTime? dateCreated,
    DateTime? dateUpdated,
    String? author,
  }) {
    return Article._(
      id: id,
      title: title,
      content: content,
      status: status,
      dateCreated: dateCreated,
      dateUpdated: dateUpdated,
      author: author,
    );
  }

  /// Construction depuis JSON avec DirectusModelBuilder
  factory Article.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    return Article._(
      id: builder.id,
      title: builder.getString('title'),
      content: builder.getStringOrNull('content'),
      status: builder.getString('status', defaultValue: 'draft'),
      dateCreated: builder.dateCreated,
      dateUpdated: builder.dateUpdated,
      author: builder.getStringOrNull('author'),
    );
  }

  /// Construction de Map avec DirectusMapBuilder
  @override
  Map<String, dynamic> toMap() {
    return DirectusMapBuilder()
        .add('title', title)
        .addIfNotNull('content', content)
        .add('status', status)
        .addIfNotNull('author', author)
        .build();
  }

  @override
  String toString() => 'Article(id: $id, title: $title, status: $status)';
}

void main() async {
  final config = DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    enableLogging: true,
  );

  final client = DirectusClient(config);

  try {
    // Authentification
    print('📡 Connexion...');
    await client.auth.login(email: 'admin@example.com', password: 'password');
    print('✅ Authentifié');

    final articlesService = client.items<Article>('articles');

    // 1. Créer un article avec le modèle
    print('\n📝 Création d\'un article...');
    final newArticle = Article(
      title: 'Article avec modèle personnalisé',
      content: 'Ceci est un exemple d\'utilisation de modèle Dart',
      status: 'draft',
    );

    final createdData = await articlesService.createOne(
      newArticle.toJson(),
      fromJson: Article.fromJson,
    );

    final createdArticle = createdData as Article;
    print('✅ Article créé: $createdArticle');

    // 2. Récupérer l'article avec le modèle
    print('\n📖 Lecture de l\'article...');
    final fetchedArticle =
        await articlesService.readOne(
              createdArticle.id!,
              fromJson: Article.fromJson,
            )
            as Article;

    print('✅ Article récupéré: $fetchedArticle');
    print('   Titre: ${fetchedArticle.title}');
    print('   Status: ${fetchedArticle.status}');
    print('   Créé le: ${fetchedArticle.dateCreated}');

    // 3. Récupérer plusieurs articles
    print('\n📚 Récupération de tous les articles...');
    final response = await articlesService.readMany(
      query: QueryParameters(limit: 10),
      fromJson: Article.fromJson,
    );

    print('✅ ${response.data.length} articles trouvés:');
    for (final article in response.data) {
      final typedArticle = article as Article;
      print('   - ${typedArticle.title} (${typedArticle.status})');
    }

    // 4. Mettre à jour l'article
    print('\n✏️  Mise à jour de l\'article...');
    final updatedData = await articlesService.updateOne(createdArticle.id!, {
      'title': 'Titre modifié via modèle',
      'status': 'published',
    }, fromJson: Article.fromJson);

    final updatedArticle = updatedData as Article;
    print('✅ Article mis à jour: $updatedArticle');

    // 5. Recherche avec filtre
    print('\n🔍 Recherche d\'articles publiés...');
    final publishedResponse = await articlesService.readMany(
      query: QueryParameters(
        filter: {
          'status': {'_eq': 'published'},
        },
      ),
      fromJson: Article.fromJson,
    );

    print('✅ ${publishedResponse.data.length} articles publiés:');
    for (final article in publishedResponse.data) {
      final typedArticle = article as Article;
      print('   - ${typedArticle.title}');
    }

    // 6. Supprimer l'article de test
    print('\n🗑️  Suppression de l\'article...');
    await articlesService.deleteOne(createdArticle.id!);
    print('✅ Article supprimé');
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
