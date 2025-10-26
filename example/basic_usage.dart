import 'package:fcs_directus/fcs_directus.dart';

/// Exemple basique d'utilisation de la librairie fcs_directus
///
/// Cet exemple montre comment:
/// - Se connecter à Directus
/// - S'authentifier
/// - Effectuer des opérations CRUD sur une collection
void main() async {
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

    // 4. Lecture de données
    print('\n📖 Lecture des articles...');
    final articlesService = client.items('articles');

    // Récupérer tous les articles
    final response = await articlesService.readMany(
      query: QueryParameters(
        limit: 10,
        sort: ['-date_created'],
        fields: ['id', 'title', 'status'],
      ),
    );

    print('✅ ${response.data.length} articles trouvés');
    for (final article in response.data) {
      print('  - ${article['title']}');
    }

    // 5. Récupérer un article spécifique
    if (response.data.isNotEmpty) {
      final firstArticleId = response.data.first['id'].toString();
      print('\n📖 Lecture de l\'article $firstArticleId...');

      final article = await articlesService.readOne(firstArticleId);
      print('✅ Article récupéré: ${article['title']}');
    }

    // 6. Créer un nouvel article
    print('\n📝 Création d\'un nouvel article...');
    final newArticle = await articlesService.createOne({
      'title': 'Mon premier article via API',
      'content': 'Contenu de l\'article créé via fcs_directus',
      'status': 'draft',
    });
    print('✅ Article créé avec l\'ID: ${newArticle['id']}');

    // 7. Mettre à jour l'article
    print('\n✏️  Mise à jour de l\'article...');
    final updatedArticle = await articlesService.updateOne(
      newArticle['id'].toString(),
      {'title': 'Titre modifié', 'status': 'published'},
    );
    print('✅ Article mis à jour: ${updatedArticle['title']}');

    // 8. Recherche avec filtres
    print('\n🔍 Recherche d\'articles publiés...');
    final publishedArticles = await articlesService.readMany(
      query: QueryParameters(
        filter: {
          'status': {'_eq': 'published'},
        },
        limit: 5,
      ),
    );
    print('✅ ${publishedArticles.data.length} articles publiés trouvés');

    // 9. Supprimer l'article de test
    print('\n🗑️  Suppression de l\'article de test...');
    await articlesService.deleteOne(newArticle['id'].toString());
    print('✅ Article supprimé');

    // 10. Informations sur l'utilisateur connecté
    print('\n👤 Informations utilisateur...');
    final me = await client.users.me();
    print('✅ Connecté en tant que: ${me['email']}');

    // 11. Déconnexion
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
    // 12. Nettoyage
    client.dispose();
    print('\n🔌 Client fermé');
  }
}
