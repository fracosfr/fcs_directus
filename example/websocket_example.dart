import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation des WebSockets avec Directus
///
/// Cet exemple montre comment:
/// - Se connecter au WebSocket
/// - S'abonner aux événements d'une collection avec les méthodes helper
/// - S'abonner aux notifications système
/// - Recevoir des mises à jour en temps réel
void main() async {
  // 1. Configuration
  final config = DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    enableLogging: true,
  );

  final client = DirectusClient(config);

  try {
    // 2. Authentification
    print('📡 Connexion et authentification...');
    final authResponse = await client.auth.login(
      email: 'admin@example.com',
      password: 'password',
    );
    print('✅ Authentifié');

    // 3. Création du client WebSocket
    print('\n🔌 Connexion au WebSocket...');
    final wsClient = DirectusWebSocketClient(
      config,
      accessToken: authResponse.accessToken,
    );

    await wsClient.connect();
    print('✅ Connecté au WebSocket');

    // 4a. Abonnement aux notifications système (méthode helper)
    print('\n👂 Abonnement aux notifications...');

    final notifSubscriptionId = await wsClient.subscribeToNotifications(
      onMessage: (message) {
        print('\n🔔 Notification reçue:');
        print('   Event: ${message.event}');
        if (message.data != null) {
          print('   Subject: ${message.data!['subject']}');
          print('   Message: ${message.data!['message']}');
        }
      },
    );

    print('✅ Abonné aux notifications avec l\'ID: $notifSubscriptionId');

    // 4b. Abonnement uniquement aux créations d'articles (méthode helper)
    print('\n👂 Abonnement aux créations d\'articles...');

    final createSubscriptionId = await wsClient.subscribeToCreate(
      collection: 'articles',
      query: {
        'filter': {
          'status': {'_eq': 'published'},
        },
      },
      onMessage: (message) {
        print('\n📨 Nouvel article publié:');
        if (message.data != null) {
          print('   Titre: ${message.data!['title']}');
          print('   ID: ${message.data!['id']}');
        }
      },
    );

    print('✅ Abonné aux créations avec l\'ID: $createSubscriptionId');

    // 4c. Abonnement aux mises à jour (méthode helper)
    print('\n👂 Abonnement aux mises à jour d\'articles...');

    final updateSubscriptionId = await wsClient.subscribeToUpdate(
      collection: 'articles',
      onMessage: (message) {
        print('\n✏️  Article mis à jour:');
        if (message.data != null) {
          print('   ID: ${message.data!['id']}');
          print('   Status: ${message.data!['status']}');
        }
      },
    );

    print('✅ Abonné aux mises à jour avec l\'ID: $updateSubscriptionId');

    // 5. Créer un article pour tester les notifications en temps réel
    print('\n📝 Création d\'un article de test...');
    final newArticle = await client.items('articles').createOne({
      'title': 'Article WebSocket Test',
      'status': 'draft',
    });
    print('✅ Article créé (vous devriez recevoir une notification)');

    // 6. Attendre quelques secondes pour recevoir les événements
    print('\n⏳ En attente d\'événements (10 secondes)...');
    await Future.delayed(Duration(seconds: 10));

    // 7. Mettre à jour l'article
    print('\n✏️  Mise à jour de l\'article...');
    await client.items('articles').updateOne(newArticle['id'].toString(), {
      'status': 'published',
    });
    print('✅ Article mis à jour (vous devriez recevoir une notification)');

    // Attendre encore un peu
    await Future.delayed(Duration(seconds: 5));

    // 8. Se désabonner
    print('\n🔕 Désinscription...');
    await wsClient.unsubscribe(notifSubscriptionId);
    await wsClient.unsubscribe(createSubscriptionId);
    await wsClient.unsubscribe(updateSubscriptionId);
    print('✅ Désinscrit');

    // 9. Nettoyer - supprimer l'article de test
    print('\n🗑️  Suppression de l\'article de test...');
    await client.items('articles').deleteOne(newArticle['id'].toString());
    print('✅ Article supprimé');

    // 10. Fermer la connexion WebSocket
    print('\n🔌 Déconnexion du WebSocket...');
    await wsClient.disconnect();
    print('✅ WebSocket fermé');
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
