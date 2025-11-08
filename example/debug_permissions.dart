// ignore_for_file: avoid_print

import 'package:fcs_directus/fcs_directus.dart';

/// Script de débogage pour diagnostiquer les problèmes de permissions
/// sur les relations imbriquées dans Directus.
///
/// Erreur typique :
/// "You don't have permission to access field "departement.region"
///  in collection "brigade" or it does not exist."
///
/// Ce script teste progressivement chaque niveau de permission
/// pour identifier exactement où se situe le problème.
void main() async {
  // ⚠️ Configurez vos paramètres de connexion
  const String baseUrl = 'https://api.blue.fracos.fr';
  const String email = 'user@example.com';
  const String password = 'your-password';

  final client = DirectusClient(
    DirectusConfig(
      baseUrl: baseUrl,
      enableLogging: true, // Active les logs détaillés
    ),
  );

  try {
    print('=== Démarrage du diagnostic des permissions ===\n');

    // Étape 1: Authentification
    print('1️⃣  Test d\'authentification...');
    await client.auth.login(email: email, password: password);
    print('   ✅ Authentification réussie\n');

    // Étape 2: Test lecture brigade simple
    print('2️⃣  Test lecture collection "brigade" (sans relation)...');
    try {
      final brigades = await client
          .items('brigade')
          .readMany(query: QueryParameters(fields: ['id', 'nom'], limit: 1));
      print('   ✅ Lecture brigade OK (${brigades.data.length} résultat)');
    } catch (e) {
      print('   ❌ ERREUR: Impossible de lire la collection brigade');
      print('   → Vérifiez les permissions READ sur "brigade"');
      print('   → Erreur: $e');
      return;
    }
    print('');

    // Étape 3: Test lecture brigade avec departement
    print('3️⃣  Test lecture "brigade" avec relation "departement"...');
    try {
      final brigades = await client
          .items('brigade')
          .readMany(
            query: QueryParameters(
              fields: ['id', 'nom', 'departement.id', 'departement.nom'],
              limit: 1,
            ),
          );
      print('   ✅ Lecture brigade.departement OK');
    } catch (e) {
      print('   ❌ ERREUR: Impossible de lire brigade.departement');
      print('   → Vérifiez les permissions READ sur "departement"');
      print('   → Vérifiez que le champ "departement" existe dans "brigade"');
      print('   → Erreur: $e');
      return;
    }
    print('');

    // Étape 4: Test lecture directe de region
    print('4️⃣  Test lecture directe de la collection "region"...');
    try {
      final regions = await client
          .items('region')
          .readMany(query: QueryParameters(fields: ['id', 'nom'], limit: 1));
      print('   ✅ Lecture region OK (${regions.data.length} résultat)');
    } catch (e) {
      print('   ❌ ERREUR: Impossible de lire la collection region');
      print('   → C\'EST PROBABLEMENT ICI LE PROBLÈME !');
      print('   → Solution: Dans l\'admin Directus:');
      print('      1. Allez dans Paramètres > Rôles et permissions');
      print('      2. Sélectionnez votre rôle');
      print('      3. Trouvez la collection "region"');
      print('      4. Activez la permission READ');
      print('      5. Cochez "All Fields"');
      print('   → Erreur: $e');
      return;
    }
    print('');

    // Étape 5: Test lecture brigade.departement.region
    print('5️⃣  Test lecture "brigade" avec relation "departement.region"...');
    try {
      final brigades = await client
          .items('brigade')
          .readMany(
            query: QueryParameters(
              fields: [
                'id',
                'nom',
                'departement.id',
                'departement.nom',
                'departement.region.id',
                'departement.region.nom',
              ],
              limit: 1,
            ),
          );
      print('   ✅ Lecture brigade.departement.region OK');

      // Afficher un exemple de résultat
      if (brigades.data.isNotEmpty) {
        final brigade = brigades.data.first;
        print('   📋 Exemple de données récupérées:');
        print('      Brigade: ${brigade['nom']}');
        if (brigade['departement'] is Map) {
          final dept = brigade['departement'] as Map;
          print('      Département: ${dept['nom']}');
          if (dept['region'] is Map) {
            final region = dept['region'] as Map;
            print('      Région: ${region['nom']}');
          }
        }
      }
    } catch (e) {
      print('   ❌ ERREUR: Impossible de lire brigade.departement.region');
      print('   → Vérifiez que le champ "region" existe dans "departement"');
      print('   → Vérifiez les permissions sur les champs de "departement"');
      print('   → Erreur: $e');
      return;
    }
    print('');

    // Étape 6: Test filtre sur departement
    print('6️⃣  Test filtre sur champ "departement"...');
    try {
      final brigades = await client
          .items('brigade')
          .readMany(
            query: QueryParameters(
              filter: Filter.field('departement').isNotNull(),
              fields: ['id', 'nom'],
              limit: 1,
            ),
          );
      print('   ✅ Filtre sur departement OK');
    } catch (e) {
      print('   ❌ ERREUR: Impossible de filtrer sur departement');
      print('   → Erreur: $e');
      return;
    }
    print('');

    // Étape 7: Test filtre sur departement.region (PROBLÈME INITIAL)
    print('7️⃣  Test filtre sur champ "departement.region"...');
    try {
      final brigades = await client
          .items('brigade')
          .readMany(
            query: QueryParameters(
              filter: Filter.field('departement.region').isNotNull(),
              fields: ['id', 'nom', 'departement.region.*'],
              limit: 1,
            ),
          );
      print('   ✅ Filtre sur departement.region OK !');
      print('   🎉 LE PROBLÈME EST RÉSOLU !');
    } catch (e) {
      print('   ❌ ERREUR: Impossible de filtrer sur departement.region');
      print('   → C\'est l\'erreur que vous rencontrez');
      print('   → Erreur détaillée: $e');

      if (e is DirectusPermissionException) {
        print('\n   📋 Diagnostic détaillé:');
        print('      - Code erreur: ${e.errorCode}');
        print('      - Message: ${e.message}');
        print('      - Status code: ${e.statusCode}');
        print('\n   💡 Solution recommandée:');
        print('      1. Vérifiez les permissions READ sur "region"');
        print(
          '      2. Vérifiez les permissions sur le champ "region" de "departement"',
        );
        print('      3. Testez avec un compte Admin pour confirmer');
      }
      return;
    }
    print('');

    // Si on arrive ici, tout fonctionne !
    print('🎉 === Tous les tests sont passés avec succès ! ===');
    print('');
    print('✅ Permissions validées:');
    print('   - brigade (lecture)');
    print('   - brigade.departement (lecture et relation)');
    print('   - departement (lecture)');
    print('   - departement.region (lecture et relation)');
    print('   - region (lecture)');
    print('   - Filtres sur champs imbriqués');
    print('');
    print('👍 Vous pouvez maintenant utiliser:');
    print('   Filter.field("departement.region").equals(regionId)');
  } catch (e) {
    print('\n❌ === Erreur inattendue ===');
    print('Type: ${e.runtimeType}');
    print('Message: $e');

    if (e is DirectusException) {
      print('Code erreur Directus: ${e.errorCode}');
      print('Status code: ${e.statusCode}');
    }
  } finally {
    await client.dispose();
  }
}

/// Test supplémentaire: Vérifier les permissions avec différentes méthodes
Future<void> testAlternativeMethods(DirectusClient client) async {
  print('\n=== Tests de méthodes alternatives ===\n');

  // Méthode 1: Filter.relation() au lieu de notation pointée
  print('Test 1: Utilisation de Filter.relation()');
  try {
    final brigades = await client
        .items('brigade')
        .readMany(
          query: QueryParameters(
            filter: Filter.relation(
              'departement',
            ).where(Filter.field('region').isNotNull()),
            fields: ['id', 'nom'],
            limit: 1,
          ),
        );
    print('  ✅ Filter.relation() fonctionne');
  } catch (e) {
    print('  ❌ Filter.relation() échoue: $e');
  }

  // Méthode 2: Charger toutes les relations d'un coup
  print('\nTest 2: Chargement complet des relations');
  try {
    final brigades = await client
        .items('brigade')
        .readMany(
          query: QueryParameters(
            fields: ['*', 'departement.*', 'departement.region.*'],
            limit: 1,
          ),
        );
    print('  ✅ Chargement complet fonctionne');
  } catch (e) {
    print('  ❌ Chargement complet échoue: $e');
  }

  // Méthode 3: Deep query avec deep parameter
  print('\nTest 3: Deep query');
  try {
    final brigades = await client
        .items('brigade')
        .readMany(
          query: QueryParameters(
            fields: ['*'],
            deep: {
              'departement': {'_filter': {}, '_limit': -1},
            },
            limit: 1,
          ),
        );
    print('  ✅ Deep query fonctionne');
  } catch (e) {
    print('  ❌ Deep query échoue: $e');
  }
}
