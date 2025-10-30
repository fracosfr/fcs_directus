import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation de l'API Activity de Directus
///
/// L'API Activity permet de consulter l'historique de toutes les actions
/// effectuées dans Directus (création, modification, suppression, connexions).

void main() async {
  // Configuration du client
  final config = DirectusConfig(baseUrl: 'https://directus.example.com');
  final client = DirectusClient(config);

  // Authentification
  await client.auth.login(email: 'admin@example.com', password: 'password');

  print('=== EXEMPLES D\'UTILISATION DE L\'API ACTIVITY ===\n');

  // ========================================
  // 1. RÉCUPÉRER LES ACTIVITÉS RÉCENTES
  // ========================================
  print('1. ACTIVITÉS RÉCENTES (dernières 24h)');
  print('-' * 50);

  final recentActivities = await client.activity.getRecentActivities(limit: 10);

  print('Nombre d\'activités: ${recentActivities.data.length}');
  if (recentActivities.data.isNotEmpty) {
    final firstActivity = DirectusActivity(recentActivities.data.first);
    print('Dernière activité:');
    print('  - Action: ${firstActivity.action.value}');
    print('  - Collection: ${firstActivity.collection.value}');
    print('  - Timestamp: ${firstActivity.formattedTimestamp}');
    print('  - Description: ${firstActivity.actionDescription}');
  }
  print('\n');

  // ========================================
  // 2. FILTRER PAR TYPE D'ACTION
  // ========================================
  print('2. TOUTES LES CRÉATIONS RÉCENTES');
  print('-' * 50);

  final creates = await client.activity.getActivitiesByAction(
    'create',
    limit: 20,
  );

  print('Nombre de créations: ${creates.data.length}');
  for (var i = 0; i < creates.data.take(5).length; i++) {
    final activity = DirectusActivity(creates.data[i]);
    print(
      '  ${i + 1}. ${activity.collection.value} (${activity.item.value}) - ${activity.formattedTimestamp}',
    );
  }
  print('\n');

  // ========================================
  // 3. CONNEXIONS RÉCENTES
  // ========================================
  print('3. CONNEXIONS RÉCENTES');
  print('-' * 50);

  final logins = await client.activity.getActivitiesByAction(
    'login',
    limit: 10,
  );

  print('Nombre de connexions: ${logins.data.length}');
  for (var item in logins.data.take(5)) {
    final activity = DirectusActivity(item);
    print('  - IP: ${activity.ip.value} - ${activity.formattedTimestamp}');
  }
  print('\n');

  // ========================================
  // 4. ACTIVITÉS D'UNE COLLECTION
  // ========================================
  print('4. ACTIVITÉS D\'UNE COLLECTION SPÉCIFIQUE');
  print('-' * 50);

  final articlesActivity = await client.activity.getCollectionActivities(
    'articles',
    limit: 15,
  );

  print(
    'Activités sur la collection "articles": ${articlesActivity.data.length}',
  );
  for (var item in articlesActivity.data.take(5)) {
    final activity = DirectusActivity(item);
    print(
      '  - ${activity.action.value.toUpperCase()} sur item ${activity.item.value}',
    );
  }
  print('\n');

  // ========================================
  // 5. HISTORIQUE D'UN ITEM SPÉCIFIQUE
  // ========================================
  print('5. HISTORIQUE D\'UN ITEM');
  print('-' * 50);

  final itemHistory = await client.activity.getItemActivities(
    'article-123',
    collection: 'articles',
  );

  print('Historique de l\'article article-123:');
  for (var item in itemHistory.data) {
    final activity = DirectusActivity(item);
    print('  - ${activity.action.value} - ${activity.formattedTimestamp}');
    if (activity.hasComment) {
      print('    Commentaire: ${activity.comment.value}');
    }
  }
  print('\n');

  // ========================================
  // 6. ACTIVITÉS D'UN UTILISATEUR
  // ========================================
  print('6. ACTIVITÉS D\'UN UTILISATEUR');
  print('-' * 50);

  final userActivities = await client.activity.getUserActivities(
    'user-id-123',
    limit: 20,
  );

  print('Activités de l\'utilisateur: ${userActivities.data.length}');
  for (var item in userActivities.data.take(5)) {
    final activity = DirectusActivity(item);
    print('  - ${activity.actionDescription}');
  }
  print('\n');

  // ========================================
  // 7. FILTRES PERSONNALISÉS AVANCÉS
  // ========================================
  print('7. FILTRES AVANCÉS');
  print('-' * 50);

  // Créations et modifications des 7 derniers jours
  final weekActivity = await client.activity.getActivities(
    query: QueryParameters(
      filter: Filter.and([
        Filter.or([
          Filter.field('action').equals('create'),
          Filter.field('action').equals('update'),
        ]),
        Filter.field('timestamp').greaterThan(
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        ),
      ]),
      sort: ['-timestamp'],
      limit: 50,
    ),
  );

  print(
    'Créations/modifications (7 derniers jours): ${weekActivity.data.length}',
  );
  print('\n');

  // ========================================
  // 8. ACTIVITÉS AVEC DÉTAILS UTILISATEUR (Deep)
  // ========================================
  print('8. ACTIVITÉS AVEC DÉTAILS UTILISATEUR');
  print('-' * 50);

  final activitiesWithUser = await client.activity.getActivities(
    query: QueryParameters(
      limit: 10,
      sort: ['-timestamp'],
      deep: Deep({
        'user': DeepQuery().fields(['id', 'first_name', 'last_name', 'email']),
      }),
    ),
  );

  print('Activités avec utilisateurs:');
  for (var item in activitiesWithUser.data.take(5)) {
    final activity = DirectusActivity(item);
    print(
      '  - ${activity.actorName ?? activity.actorEmail ?? "Utilisateur inconnu"}',
    );
    print('    ${activity.actionDescription}');
  }
  print('\n');

  // ========================================
  // 9. RÉCUPÉRER UNE ACTIVITÉ PAR ID
  // ========================================
  print('9. DÉTAILS D\'UNE ACTIVITÉ SPÉCIFIQUE');
  print('-' * 50);

  if (recentActivities.data.isNotEmpty) {
    final activityId = recentActivities.data.first['id'].toString();

    final singleActivity = await client.activity.getActivity(
      activityId,
      query: QueryParameters(
        deep: Deep({
          'user': DeepQuery().fields(['first_name', 'last_name', 'email']),
          'revisions': DeepQuery().allFields(),
        }),
      ),
    );

    final activity = DirectusActivity(singleActivity);
    print('Activité ID: ${activity.id}');
    print('Action: ${activity.action.value}');
    print('Collection: ${activity.collection.value}');
    print('Item: ${activity.item.value}');
    print('IP: ${activity.ip.value}');
    print('User Agent: ${activity.userAgent.value}');
    print('Timestamp: ${activity.formattedTimestamp}');
    if (activity.hasRevisions) {
      print('Révisions: ${activity.revisions.length} changement(s)');
    }
  }
  print('\n');

  // ========================================
  // 10. STATISTIQUES PERSONNALISÉES
  // ========================================
  print('10. STATISTIQUES');
  print('-' * 50);

  // Compter les activités par type
  final actionTypes = ['create', 'update', 'delete', 'login'];
  print('Activités par type (dernières 24h):');
  for (final actionType in actionTypes) {
    final count = await client.activity.getActivitiesByAction(
      actionType,
      additionalQuery: QueryParameters(
        filter: Filter.field('timestamp').greaterThan(
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        ),
      ),
    );
    print('  - $actionType: ${count.meta?.totalCount ?? count.data.length}');
  }
  print('\n');

  // ========================================
  // 11. SURVEILLANCE EN TEMPS RÉEL
  // ========================================
  print('11. SURVEILLANCE (dernières minutes)');
  print('-' * 50);

  final last5Minutes = await client.activity.getRecentActivities(
    since: DateTime.now().subtract(const Duration(minutes: 5)),
    limit: 100,
  );

  print('Activités des 5 dernières minutes: ${last5Minutes.data.length}');
  if (last5Minutes.data.isNotEmpty) {
    print('Résumé:');
    for (var item in last5Minutes.data.take(10)) {
      final activity = DirectusActivity(item);
      print('  - ${activity.summary}');
    }
  }
  print('\n');

  // ========================================
  // 12. AUDIT D'UNE COLLECTION
  // ========================================
  print('12. AUDIT COMPLET D\'UNE COLLECTION');
  print('-' * 50);

  // Toutes les suppressions sur une collection
  final deletions = await client.activity.getCollectionActivities(
    'articles',
    actionType: 'delete',
  );

  print('Suppressions dans articles: ${deletions.data.length}');
  for (var item in deletions.data) {
    final activity = DirectusActivity(item);
    print(
      '  - Item ${activity.item.value} supprimé par ${activity.actorName ?? "Inconnu"}',
    );
    print('    Date: ${activity.formattedTimestamp}');
  }

  print('\n=== FIN DES EXEMPLES ===');

  client.dispose();
}
