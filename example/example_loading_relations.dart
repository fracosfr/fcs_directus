// ignore_for_file: avoid_print

/// Exemple : Chargement des relations (role et policies)
///
/// Cet exemple démontre comment les relations ne sont pas chargées automatiquement
/// et comment les charger explicitement avec le paramètre `fields`.
library;

import 'package:fcs_directus/fcs_directus.dart';

void main() async {
  print('╔════════════════════════════════════════════════════════╗');
  print('║       Chargement des relations Users/Roles/Policies   ║');
  print('╚════════════════════════════════════════════════════════╝\n');

  await example1_DefaultBehavior();
  print('\n${'=' * 60}\n');
  await example2_LoadingRelations();
  print('\n${'=' * 60}\n');
  await example3_SelectiveLoading();
  print('\n${'=' * 60}\n');
  await example4_GetAllPolicies();
}

/// Exemple 1 : Comportement par défaut (relations non chargées)
Future<void> example1_DefaultBehavior() async {
  print('📌 Exemple 1 : Comportement par défaut (IDs uniquement)\n');

  final client = DirectusClient(
    DirectusConfig(baseUrl: 'https://directus.example.com'),
  );

  try {
    // Login
    await client.auth.login(email: 'user@example.com', password: 'password');

    // ❌ Récupérer l'utilisateur SANS spécifier les champs
    print('📝 Récupération de l\'utilisateur SANS relations...');
    final me = await client.users.me();

    print('✅ Utilisateur récupéré');
    print('   Email: ${me?.email.value}');
    print('   Nom: ${me?.fullName ?? "N/A"}');
    print('   Statut: ${me?.status.value}\n');

    // Vérifier le rôle
    print('🔍 Analyse du rôle...');
    final roleValue = me?.role.value;
    if (roleValue == null) {
      print('   ⚠️  Pas de rôle assigné');
    } else if (roleValue is String) {
      print('   ⚠️  Rôle retourné comme ID uniquement : $roleValue');
      print('   ℹ️  Pour avoir l\'objet complet, utilisez fields');
    } else {
      // Ce cas ne devrait pas arriver sans fields
      print('   ✅ Rôle chargé : ${roleValue.name.value}');
    }

    // Vérifier les politiques
    print('\n🔍 Analyse des politiques...');
    final policies = me?.policies.value ?? [];
    print('   Nombre de politiques: ${policies.length}');
    if (policies.isNotEmpty) {
      print(
        '   ⚠️  Les politiques sont retournées comme IDs ou objets partiels',
      );
      print('   ℹ️  Pour avoir les objets complets, utilisez fields');
    }

    print('\n💡 Conclusion :');
    print(
      '   Sans spécifier fields, seules les données basiques sont chargées.',
    );
    print('   Les relations (role, policies) sont retournées comme IDs.');
  } on DirectusException catch (e) {
    print('❌ Erreur : ${e.message}');
  } finally {
    await client.dispose();
  }
}

/// Exemple 2 : Chargement des relations complètes
Future<void> example2_LoadingRelations() async {
  print('📌 Exemple 2 : Chargement des relations complètes\n');

  final client = DirectusClient(
    DirectusConfig(baseUrl: 'https://directus.example.com'),
  );

  try {
    await client.auth.login(email: 'user@example.com', password: 'password');

    // ✅ Récupérer l'utilisateur AVEC les relations
    print('📝 Récupération de l\'utilisateur AVEC relations...');
    final me = await client.users.me(
      query: QueryParameters(fields: ['*', 'role.*', 'policies.*']),
    );

    print('✅ Utilisateur récupéré avec relations');
    print('   Email: ${me?.email.value}');
    print('   Nom: ${me?.fullName ?? "N/A"}');
    print('   Statut: ${me?.status.value}\n');

    // Vérifier le rôle (objet complet)
    print('🔍 Analyse du rôle...');
    final role = me?.role.value;
    if (role != null) {
      print('   ✅ Rôle chargé complet :');
      print('      Nom: ${role.name.value}');
      print('      Icône: ${role.icon.valueOrNull ?? "N/A"}');
      print('      Description: ${role.description.valueOrNull ?? "N/A"}');
    } else {
      print('   ⚠️  Pas de rôle assigné');
    }

    // Vérifier les politiques (objets complets)
    print('\n🔍 Analyse des politiques...');
    final policies = me?.policies.value ?? [];
    print('   Nombre de politiques: ${policies.length}');
    for (final policy in policies) {
      print('   ✅ ${policy.name.value}');
      print('      Admin: ${policy.isAdminPolicy}');
      print('      App: ${policy.hasAppAccess}');
      print('      2FA: ${policy.requiresTwoFactor}');
    }

    print('\n💡 Conclusion :');
    print('   Avec fields = [\'*\', \'role.*\', \'policies.*\'],');
    print('   toutes les relations sont chargées comme objets complets.');
  } on DirectusException catch (e) {
    print('❌ Erreur : ${e.message}');
  } finally {
    await client.dispose();
  }
}

/// Exemple 3 : Chargement sélectif (optimisation)
Future<void> example3_SelectiveLoading() async {
  print('📌 Exemple 3 : Chargement sélectif des champs\n');

  final client = DirectusClient(
    DirectusConfig(baseUrl: 'https://directus.example.com'),
  );

  try {
    await client.auth.login(email: 'user@example.com', password: 'password');

    // ✅ Récupérer uniquement les champs nécessaires
    print('📝 Récupération OPTIMISÉE avec champs sélectifs...');
    final me = await client.users.me(
      query: QueryParameters(
        fields: [
          'id',
          'email',
          'first_name',
          'last_name',
          'status',
          'role.name', // Seulement le nom du rôle
          'role.icon',
          'policies.name', // Seulement les noms des politiques
          'policies.admin_access',
        ],
      ),
    );

    print('✅ Utilisateur récupéré (champs sélectifs)');
    print('   Email: ${me?.email.value}');
    print('   Nom: ${me?.fullName ?? "N/A"}');
    print('   Statut: ${me?.status.value}\n');

    // Rôle (champs sélectifs)
    print('🔍 Rôle (champs sélectifs) :');
    final role = me?.role.value;
    if (role != null) {
      print('   Nom: ${role.name.value}');
      print('   Icône: ${role.icon.valueOrNull ?? "N/A"}');
      // Description n'est pas disponible car non demandée
    }

    // Politiques (champs sélectifs)
    print('\n🔍 Politiques (champs sélectifs) :');
    final policies = me?.policies.value ?? [];
    for (final policy in policies) {
      print('   ${policy.name.value} (Admin: ${policy.adminAccess.value})');
      // Autres champs non disponibles car non demandés
    }

    print('\n💡 Conclusion :');
    print('   En sélectionnant uniquement les champs nécessaires,');
    print('   vous optimisez les performances et réduisez le trafic réseau.');
  } on DirectusException catch (e) {
    print('❌ Erreur : ${e.message}');
  } finally {
    await client.dispose();
  }
}

/// Exemple 4 : Utilisation de getAllPolicies()
Future<void> example4_GetAllPolicies() async {
  print('📌 Exemple 4 : Utilisation de getAllPolicies()\n');

  final client = DirectusClient(
    DirectusConfig(baseUrl: 'https://directus.example.com'),
  );

  try {
    await client.auth.login(email: 'user@example.com', password: 'password');

    // ⚠️ Pour getAllPolicies(), TOUTES les relations doivent être chargées
    print('📝 Récupération pour getAllPolicies()...');
    final me = await client.users.me(
      query: QueryParameters(
        fields: [
          '*',
          'policies.*', // Politiques directes
          'role.policies.*', // Politiques du rôle
        ],
      ),
    );

    print('✅ Utilisateur récupéré avec toutes les politiques\n');

    // Utiliser getAllPolicies()
    print('🔍 Analyse de TOUTES les politiques (directes + rôle)...');
    final allPolicies = me?.getAllPolicies() ?? [];
    print('   Total de politiques effectives: ${allPolicies.length}\n');

    // Compteurs
    int adminCount = 0;
    int appCount = 0;
    int tfaCount = 0;
    int ipRestrictedCount = 0;

    for (final policy in allPolicies) {
      print('   📋 ${policy.name.value}');
      if (policy.isAdminPolicy) {
        print('      ✅ Accès administrateur');
        adminCount++;
      }
      if (policy.hasAppAccess) {
        print('      ✅ Accès à l\'application');
        appCount++;
      }
      if (policy.requiresTwoFactor) {
        print('      ✅ 2FA obligatoire');
        tfaCount++;
      }
      if (policy.hasIpRestrictions) {
        print('      ✅ Restrictions IP : ${policy.getIpList().join(", ")}');
        ipRestrictedCount++;
      }
    }

    print('\n📊 Statistiques :');
    print('   Politiques admin: $adminCount');
    print('   Politiques avec accès app: $appCount');
    print('   Politiques avec 2FA: $tfaCount');
    print('   Politiques avec restrictions IP: $ipRestrictedCount');

    // Vérification globale
    print('\n🔐 Permissions globales :');
    print(
      '   Est admin ? ${allPolicies.any((p) => p.isAdminPolicy) ? "✅ OUI" : "❌ NON"}',
    );
    print(
      '   Accès app ? ${allPolicies.any((p) => p.hasAppAccess) ? "✅ OUI" : "❌ NON"}',
    );
    print(
      '   2FA requis ? ${allPolicies.any((p) => p.requiresTwoFactor) ? "✅ OUI" : "❌ NON"}',
    );

    print('\n💡 Conclusion :');
    print('   getAllPolicies() combine intelligemment :');
    print('   - Les politiques directes de l\'utilisateur');
    print('   - Les politiques héritées du rôle');
    print('   en éliminant les doublons.');
  } on DirectusException catch (e) {
    print('❌ Erreur : ${e.message}');
  } finally {
    await client.dispose();
  }
}

// ═══════════════════════════════════════════════════════════
// Guide de référence
// ═══════════════════════════════════════════════════════════

void printGuide() {
  print('''
╔════════════════════════════════════════════════════════════╗
║               GUIDE DE RÉFÉRENCE                           ║
╚════════════════════════════════════════════════════════════╝

1️⃣ COMPORTEMENT PAR DÉFAUT
   Les relations ne sont JAMAIS chargées automatiquement.
   Seuls les IDs sont retournés.

2️⃣ CHARGER LES RELATIONS
   Utilisez le paramètre fields dans QueryParameters :
   
   query: QueryParameters()..fields = ['*', 'role.*', 'policies.*']

3️⃣ OPTIMISATION
   Chargez uniquement les champs nécessaires :
   
   ..fields = ['id', 'email', 'role.name', 'policies.name']

4️⃣ POUR getAllPolicies()
   Chargez obligatoirement :
   
   ..fields = ['*', 'policies.*', 'role.policies.*']

5️⃣ EXEMPLES DE CHAMPS

   Tous les champs de l'utilisateur :
   ['*']

   Utilisateur + rôle complet :
   ['*', 'role.*']

   Utilisateur + politiques complètes :
   ['*', 'policies.*']

   Utilisateur + tout (rôle + politiques + politiques du rôle) :
   ['*', 'role.*', 'role.policies.*', 'policies.*']

   Sélection précise :
   ['id', 'email', 'first_name', 'role.name']

6️⃣ RÈGLE D'OR
   ✅ Chargez uniquement ce dont vous avez besoin
   ✅ Spécifiez toujours fields pour les relations
   ❌ N'utilisez pas ['*', 'role.*', 'policies.*'] partout
      (sauf si vraiment nécessaire)

╔════════════════════════════════════════════════════════════╗
║                    COMPARAISON                             ║
╚════════════════════════════════════════════════════════════╝

Sans fields (par défaut) :
  - Taille réponse : ~1 KB
  - Temps : ~50 ms
  - Données : IDs uniquement
  - Utilisation : Lister des utilisateurs

Avec fields complets :
  - Taille réponse : ~5-10 KB
  - Temps : ~100-200 ms
  - Données : Objets complets
  - Utilisation : Vérifier permissions

Avec fields sélectifs :
  - Taille réponse : ~2-3 KB
  - Temps : ~70-100 ms
  - Données : Champs sélectionnés
  - Utilisation : Afficher infos spécifiques
  ''');
}
