import 'package:fcs_directus/fcs_directus.dart';

/// Exemples d'utilisation des agrégations et fonctions Directus
///
/// Ce fichier démontre 10 scénarios d'utilisation:
///
/// 1. Agrégations simples (count, sum, avg)
/// 2. Agrégations avec groupBy
/// 3. Fonctions de date dans les filtres
/// 4. Fonctions de date dans groupBy
/// 5. Variables dynamiques ($NOW, $CURRENT_USER)
/// 6. Statistiques par période
/// 7. Analyse des ventes par catégorie
/// 8. Comptage distinct
/// 9. Filtrage par heure/jour de la semaine
/// 10. Combinaison de tout
void main() async {
  final config = DirectusConfig(baseUrl: 'https://your-directus-instance.com');
  final client = DirectusClient(config);

  try {
    await client.auth.login(email: 'admin@example.com', password: 'password');

    print('🎯 Exemples d\'agrégations et fonctions Directus\n');

    // === 1. Agrégations simples ===
    print('📌 1. Agrégations simples\n');

    print('   Nombre total de produits:');
    var response = await client.items('products').readMany(
      query: QueryParameters(
        aggregate: Aggregate()..countAll(),
      ),
    );
    print('   → Résultat: ${response.data}\n');

    print('   Statistiques des prix:');
    response = await client.items('products').readMany(
      query: QueryParameters(
        aggregate: Aggregate()
          ..count(['*'])
          ..sum(['price'])
          ..avg(['price'])
          ..min(['price'])
          ..max(['price']),
      ),
    );
    print('   → Résultat: ${response.data}\n');

    // === 2. Agrégations avec groupBy ===
    print('📌 2. Agrégations avec regroupement\n');

    print('   Nombre de produits par catégorie:');
    response = await client.items('products').readMany(
      query: QueryParameters(
        aggregate: Aggregate()..count(['*']),
        groupBy: GroupBy.fields(['category']),
      ),
    );
    print('   → ${response.data.length} catégories\n');

    print('   Total des ventes par vendeur:');
    response = await client.items('orders').readMany(
      query: QueryParameters(
        aggregate: Aggregate()
          ..count(['*'])
          ..sum(['amount']),
        groupBy: GroupBy.fields(['seller_id']),
        sort: ['-sum.amount'], // Trier par montant total décroissant
      ),
    );
    print('   → ${response.data.length} vendeurs\n');

    // === 3. Fonctions de date dans les filtres ===
    print('📌 3. Filtres avec fonctions de date\n');

    print('   Articles publiés en 2024:');
    response = await client.items('articles').readMany(
      query: QueryParameters(
        filter: Filter.field(Func.year('published_at')).equals(2024),
        limit: 10,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    print('   Événements en décembre:');
    response = await client.items('events').readMany(
      query: QueryParameters(
        filter: Filter.field(Func.month('event_date')).equals(12),
        limit: 10,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    print('   Activité pendant les heures de bureau (9h-17h):');
    response = await client.items('activities').readMany(
      query: QueryParameters(
        filter: Filter.and([
          Filter.field(Func.hour('created_at')).greaterThanOrEqual(9),
          Filter.field(Func.hour('created_at')).lessThan(17),
        ]),
        limit: 10,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    // === 4. Fonctions de date dans groupBy ===
    print('📌 4. Regroupement par périodes\n');

    print('   Ventes par année:');
    response = await client.items('orders').readMany(
      query: QueryParameters(
        aggregate: Aggregate()
          ..count(['*'])
          ..sum(['amount']),
        groupBy: GroupBy.fields([Func.year('created_at')]),
        sort: [Func.year('created_at')],
      ),
    );
    print('   → ${response.data.length} années\n');

    print('   Inscriptions par mois (année en cours):');
    response = await client.items('users').readMany(
      query: QueryParameters(
        filter: Filter.field(Func.year('date_created')).equals(2024),
        aggregate: Aggregate()..count(['*']),
        groupBy: GroupBy.fields([Func.month('date_created')]),
        sort: [Func.month('date_created')],
      ),
    );
    print('   → ${response.data.length} mois avec inscriptions\n');

    print('   Activité par jour de la semaine:');
    response = await client.items('events').readMany(
      query: QueryParameters(
        aggregate: Aggregate()..count(['*']),
        groupBy: GroupBy.fields([Func.weekday('event_date')]),
        sort: [Func.weekday('event_date')],
      ),
    );
    print('   → Répartition sur ${response.data.length} jours\n');

    // === 5. Variables dynamiques ===
    print('📌 5. Utilisation des variables dynamiques\n');

    print('   Mes tâches non expirées:');
    response = await client.items('tasks').readMany(
      query: QueryParameters(
        filter: Filter.and([
          Filter.field('assigned_to').equals(DynamicVar.currentUser),
          Filter.field('due_date').greaterThan(DynamicVar.now),
        ]),
        limit: 10,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    print('   Documents accessibles à mon rôle:');
    response = await client.items('documents').readMany(
      query: QueryParameters(
        filter: Filter.field('required_role').equals(DynamicVar.currentRole),
        limit: 10,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    // === 6. Statistiques par période ===
    print('📌 6. Analyse temporelle des données\n');

    print('   Ventes du mois en cours (agrégées):');
    response = await client.items('orders').readMany(
      query: QueryParameters(
        filter: Filter.and([
          Filter.field(Func.year('created_at')).equals(2024),
          Filter.field(Func.month('created_at')).equals(10),
        ]),
        aggregate: Aggregate()
          ..count(['*'])
          ..sum(['amount'])
          ..avg(['amount'])
          ..min(['amount'])
          ..max(['amount']),
      ),
    );
    print('   → Statistiques: ${response.data}\n');

    print('   Articles publiés par trimestre:');
    response = await client.items('articles').readMany(
      query: QueryParameters(
        filter: Filter.field(Func.year('published_at')).equals(2024),
        aggregate: Aggregate()..count(['*']),
        // Regrouper par mois puis analyser les trimestres
        groupBy: GroupBy.fields([
          Func.year('published_at'),
          Func.month('published_at'),
        ]),
      ),
    );
    print('   → ${response.data.length} périodes\n');

    // === 7. Analyse des ventes par catégorie ===
    print('📌 7. Statistiques commerciales avancées\n');

    print('   Top 5 catégories par chiffre d\'affaires:');
    response = await client.items('orders').readMany(
      query: QueryParameters(
        aggregate: Aggregate()
          ..count(['*'])
          ..sum(['amount'])
          ..avg(['amount']),
        groupBy: GroupBy.fields(['product_category']),
        sort: ['-sum.amount'],
        limit: 5,
      ),
    );
    print('   → ${response.data.length} catégories\n');

    print('   Panier moyen par vendeur:');
    response = await client.items('orders').readMany(
      query: QueryParameters(
        aggregate: Aggregate()
          ..count(['*'])
          ..sum(['amount'])
          ..avg(['amount']),
        groupBy: GroupBy.fields(['seller_id']),
        sort: ['-avg.amount'],
        limit: 10,
      ),
    );
    print('   → ${response.data.length} vendeurs\n');

    // === 8. Comptage distinct ===
    print('📌 8. Analyses avec valeurs distinctes\n');

    print('   Nombre de clients uniques ayant commandé:');
    response = await client.items('orders').readMany(
      query: QueryParameters(
        aggregate: Aggregate()..countDistinct(['customer_id']),
      ),
    );
    print('   → Résultat: ${response.data}\n');

    print('   Nombre de catégories uniques utilisées:');
    response = await client.items('products').readMany(
      query: QueryParameters(
        aggregate: Aggregate()..countDistinct(['category']),
      ),
    );
    print('   → Résultat: ${response.data}\n');

    // === 9. Filtrage par heure/jour de la semaine ===
    print('📌 9. Filtrage temporel avancé\n');

    print('   Activité du week-end (samedi=6, dimanche=0):');
    response = await client.items('events').readMany(
      query: QueryParameters(
        filter: Filter.or([
          Filter.field(Func.weekday('event_date')).equals(0),
          Filter.field(Func.weekday('event_date')).equals(6),
        ]),
        limit: 10,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    print('   Commandes nocturnes (22h-6h):');
    response = await client.items('orders').readMany(
      query: QueryParameters(
        filter: Filter.or([
          Filter.field(Func.hour('created_at')).greaterThanOrEqual(22),
          Filter.field(Func.hour('created_at')).lessThan(6),
        ]),
        limit: 10,
      ),
    );
    print('   → ${response.data.length} résultats\n');

    // === 10. Combinaison complexe ===
    print('📌 10. Analyse complexe multi-critères\n');

    print('   Ventes 2024 par catégorie et mois, uniquement clients actifs:');
    response = await client.items('orders').readMany(
      query: QueryParameters(
        filter: Filter.and([
          Filter.field(Func.year('created_at')).equals(2024),
          Filter.relation('customer').where(
            Filter.field('status').equals('active'),
          ),
        ]),
        aggregate: Aggregate()
          ..count(['*'])
          ..sum(['amount'])
          ..avg(['amount'])
          ..countDistinct(['customer_id']),
        groupBy: GroupBy.fields([
          'product_category',
          Func.month('created_at'),
        ]),
        sort: ['product_category', Func.month('created_at')],
        limit: 50,
      ),
    );
    print('   → ${response.data.length} groupes d\'analyse\n');

    print('\n✅ Tous les exemples exécutés avec succès!');

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
