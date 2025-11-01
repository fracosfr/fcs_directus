// ignore_for_file: unused_local_variable

import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation basique de la librairie fcs_directus.
///
/// Démontre :
/// - Configuration du client
/// - Authentification
/// - Opérations CRUD
/// - Gestion des erreurs
void main() async {
  // ============================================================================
  // CONFIGURATION
  // ============================================================================

  final config = DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    timeout: const Duration(seconds: 30),
    enableLogging: true,
  );

  final client = DirectusClient(config);

  // ============================================================================
  // AUTHENTIFICATION
  // ============================================================================

  try {
    print('🔐 Authentification...');
    final authResponse = await client.auth.login(
      email: 'user@example.com',
      password: 'your-password',
    );

    print('✅ Connecté avec succès !');
    print('   Token: ${authResponse.accessToken.substring(0, 20)}...');
    print('   Expire dans: ${authResponse.expiresIn} secondes');
  } on DirectusAuthException catch (e) {
    print('❌ Erreur d\'authentification: ${e.message}');
    return;
  } on DirectusException catch (e) {
    print('❌ Erreur Directus: ${e.message}');
    return;
  }

  // ============================================================================
  // CREATE - Créer un nouvel item
  // ============================================================================

  try {
    print('\n📝 Création d\'un article...');
    final newArticle = await client.items('articles').createOne({
      'title': 'Mon premier article',
      'content': 'Ceci est le contenu de mon article.',
      'status': 'draft',
      'author': 'user-uuid',
    });

    print('✅ Article créé avec l\'ID: ${newArticle['id']}');
  } on DirectusValidationException catch (e) {
    print('❌ Erreur de validation: ${e.message}');
    if (e.fieldErrors != null) {
      print('   Erreurs: ${e.fieldErrors}');
    }
  } on DirectusException catch (e) {
    print('❌ Erreur lors de la création: ${e.message}');
  }

  // ============================================================================
  // READ - Lire plusieurs items
  // ============================================================================

  try {
    print('\n📖 Lecture des articles...');
    final articlesResponse = await client
        .items('articles')
        .readMany(
          query: QueryParameters(
            limit: 10,
            sort: ['-date_created'],
            fields: ['id', 'title', 'status', 'date_created'],
          ),
        );

    print('✅ ${articlesResponse.data.length} articles trouvés');

    if (articlesResponse.meta != null) {
      print(
        '   Total dans la base: ${articlesResponse.meta!.totalCount ?? 'N/A'}',
      );
    }

    for (final article in articlesResponse.data) {
      print('   - ${article['title']} (${article['status']})');
    }
  } on DirectusException catch (e) {
    print('❌ Erreur lors de la lecture: ${e.message}');
  }

  // ============================================================================
  // READ ONE - Lire un item spécifique
  // ============================================================================

  try {
    print('\n📖 Lecture d\'un article spécifique...');
    final article = await client
        .items('articles')
        .readOne(
          '1',
          query: QueryParameters(fields: ['id', 'title', 'content', 'status']),
        );

    print('✅ Article récupéré:');
    print('   Titre: ${article['title']}');
    print('   Status: ${article['status']}');
  } on DirectusNotFoundException catch (e) {
    print('❌ Article non trouvé: ${e.message}');
  } on DirectusException catch (e) {
    print('❌ Erreur lors de la lecture: ${e.message}');
  }

  // ============================================================================
  // UPDATE - Mettre à jour un item
  // ============================================================================

  try {
    print('\n✏️ Mise à jour d\'un article...');
    final updatedArticle = await client.items('articles').updateOne('1', {
      'title': 'Titre mis à jour',
      'status': 'published',
    });

    print('✅ Article mis à jour:');
    print('   Nouveau titre: ${updatedArticle['title']}');
    print('   Nouveau status: ${updatedArticle['status']}');
  } on DirectusNotFoundException catch (e) {
    print('❌ Article non trouvé: ${e.message}');
  } on DirectusValidationException catch (e) {
    print('❌ Erreur de validation: ${e.message}');
  } on DirectusException catch (e) {
    print('❌ Erreur lors de la mise à jour: ${e.message}');
  }

  // ============================================================================
  // DELETE - Supprimer un item
  // ============================================================================

  try {
    print('\n🗑️ Suppression d\'un article...');
    await client.items('articles').deleteOne('999');
    print('✅ Article supprimé avec succès');
  } on DirectusNotFoundException catch (e) {
    print('❌ Article non trouvé: ${e.message}');
  } on DirectusException catch (e) {
    print('❌ Erreur lors de la suppression: ${e.message}');
  }

  // ============================================================================
  // BATCH OPERATIONS - Opérations en masse
  // ============================================================================

  try {
    print('\n📦 Création de plusieurs articles...');
    final articles = await client.items('articles').createMany([
      {'title': 'Article 1', 'content': 'Contenu 1', 'status': 'draft'},
      {'title': 'Article 2', 'content': 'Contenu 2', 'status': 'draft'},
      {'title': 'Article 3', 'content': 'Contenu 3', 'status': 'draft'},
    ]);

    print('✅ ${articles.length} articles créés');
  } on DirectusException catch (e) {
    print('❌ Erreur lors de la création en masse: ${e.message}');
  }

  // ============================================================================
  // UTILISATEUR COURANT
  // ============================================================================

  try {
    print('\n👤 Récupération de l\'utilisateur courant...');
    final currentUser = await client.users.me();

    print('✅ Utilisateur connecté:');
    print('   Email: ${currentUser?.email}');
    print('   Nom: ${currentUser?.firstName} ${currentUser?.lastName}');
  } on DirectusException catch (e) {
    print('❌ Erreur: ${e.message}');
  }

  // ============================================================================
  // DÉCONNEXION
  // ============================================================================

  try {
    print('\n🚪 Déconnexion...');
    await client.auth.logout();
    print('✅ Déconnecté avec succès');
  } on DirectusException catch (e) {
    print('❌ Erreur lors de la déconnexion: ${e.message}');
  }

  // ============================================================================
  // NETTOYAGE
  // ============================================================================

  print('\n🧹 Nettoyage...');
  client.dispose();
  print('✅ Client fermé');
}
