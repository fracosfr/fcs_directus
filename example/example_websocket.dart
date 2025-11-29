// ignore_for_file: avoid_print
import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation du WebSocket pour les mises à jour en temps réel
void main() async {
  // Configuration du client
  final directus = DirectusClient(
    DirectusConfig(baseUrl: 'https://your-directus-url.com'),
  );

  // Authentification (requise pour WebSocket)
  await directus.auth.login(email: 'user@example.com', password: 'password');

  // Exemple 1 : Connexion de base
  await example1BasicConnection(directus);

  // Exemple 2 : S'abonner à une collection
  await example2SubscribeToCollection(directus);

  // Exemple 3 : Filtrer par événement
  await example3FilterByEvent(directus);

  // Exemple 4 : Utiliser les helpers pour collections système
  await example4SystemCollections(directus);

  // Exemple 5 : Gestion complète d'une application temps réel
  await example5RealtimeApp(directus);
}

/// Exemple 1 : Connexion de base au WebSocket
Future<void> example1BasicConnection(DirectusClient directus) async {
  print('=== Exemple 1 : Connexion de base ===\n');

  try {
    // Se connecter au WebSocket
    await directus.websocket.connect();
    print('✓ Connecté au WebSocket');
    print('Status: ${directus.websocket.isConnected}');

    // Attendre un peu
    await Future.delayed(Duration(seconds: 2));

    // Se déconnecter
    await directus.websocket.disconnect();
    print('✓ Déconnecté');
  } catch (e) {
    print('Erreur: $e');
  }

  print('');
}

/// Exemple 2 : S'abonner à une collection
Future<void> example2SubscribeToCollection(DirectusClient directus) async {
  print('=== Exemple 2 : S\'abonner à une collection ===\n');

  try {
    await directus.websocket.connect();

    // S'abonner aux modifications d'articles
    final subscriptionId = await directus.websocket.subscribe(
      collection: 'articles',
      onMessage: (message) {
        print('📬 Message reçu:');
        print('  Type: ${message.type}');
        print('  Event: ${message.event?.name}');
        print('  Data: ${message.data}');
      },
    );

    print('✓ Abonné aux articles (UID: $subscriptionId)');

    // Attendre les messages pendant 30 secondes
    print('En attente de messages pendant 30 secondes...');
    await Future.delayed(Duration(seconds: 30));

    // Se désabonner
    await directus.websocket.unsubscribe(subscriptionId);
    print('✓ Désabonné des articles');

    await directus.websocket.disconnect();
  } catch (e) {
    print('Erreur: $e');
  }

  print('');
}

/// Exemple 3 : Filtrer par événement spécifique
Future<void> example3FilterByEvent(DirectusClient directus) async {
  print('=== Exemple 3 : Filtrer par événement ===\n');

  try {
    await directus.websocket.connect();

    // S'abonner uniquement aux créations
    final createSub = await directus.websocket.subscribe(
      collection: 'articles',
      event: DirectusItemEvent.create,
      onMessage: (message) {
        print('✨ Nouvel article créé:');
        print('  ${message.data}');
      },
    );

    // S'abonner uniquement aux modifications
    final updateSub = await directus.websocket.subscribe(
      collection: 'articles',
      event: DirectusItemEvent.update,
      onMessage: (message) {
        print('📝 Article modifié:');
        print('  ${message.data}');
      },
    );

    // S'abonner uniquement aux suppressions
    final deleteSub = await directus.websocket.subscribe(
      collection: 'articles',
      event: DirectusItemEvent.delete,
      onMessage: (message) {
        print('🗑️  Article supprimé:');
        print('  ${message.data}');
      },
    );

    print('✓ Abonné aux 3 types d\'événements');
    print('En attente de messages pendant 30 secondes...');
    await Future.delayed(Duration(seconds: 30));

    // Se désabonner de tout
    await directus.websocket.unsubscribe(createSub);
    await directus.websocket.unsubscribe(updateSub);
    await directus.websocket.unsubscribe(deleteSub);

    await directus.websocket.disconnect();
  } catch (e) {
    print('Erreur: $e');
  }

  print('');
}

/// Exemple 4 : Utiliser les helpers pour collections système
Future<void> example4SystemCollections(DirectusClient directus) async {
  print('=== Exemple 4 : Collections système ===\n');

  try {
    await directus.websocket.connect();

    // S'abonner aux notifications de l'utilisateur courant
    final notifSub = await directus.websocket.subscribeToNotifications(
      onMessage: (message) {
        print('🔔 Nouvelle notification:');
        print('  ${message.data}');
      },
    );

    // S'abonner aux nouveaux fichiers uploadés
    final filesSub = await directus.websocket.subscribeToFiles(
      event: DirectusItemEvent.create,
      onMessage: (message) {
        print('📎 Nouveau fichier uploadé:');
        print('  ${message.data}');
      },
    );

    // S'abonner à l'activité système
    final activitySub = await directus.websocket.subscribeToActivity(
      onMessage: (message) {
        print('📊 Activité système:');
        print('  ${message.data}');
      },
    );

    print('✓ Abonné à plusieurs collections système');
    print('En attente de messages pendant 30 secondes...');
    await Future.delayed(Duration(seconds: 30));

    // Nettoyage
    await directus.websocket.unsubscribe(notifSub);
    await directus.websocket.unsubscribe(filesSub);
    await directus.websocket.unsubscribe(activitySub);

    await directus.websocket.disconnect();
  } catch (e) {
    print('Erreur: $e');
  }

  print('');
}

/// Exemple 5 : Gestion complète d'une application temps réel
Future<void> example5RealtimeApp(DirectusClient directus) async {
  print('=== Exemple 5 : Application temps réel complète ===\n');

  try {
    // État de l'application
    final articles = <Map<String, dynamic>>[];

    await directus.websocket.connect();
    print('✓ Application temps réel démarrée');

    // S'abonner aux événements
    await directus.websocket.subscribe(
      collection: 'articles',
      onMessage: (message) {
        switch (message.event) {
          case DirectusItemEvent.create:
            // Ajouter le nouvel article
            final newArticle = message.data!;
            articles.add(newArticle);
            print('✨ Article ajouté: ${newArticle['title']}');
            print('  Total articles: ${articles.length}');
            break;

          case DirectusItemEvent.update:
            // Mettre à jour l'article existant
            final updatedArticle = message.data!;
            final id = updatedArticle['id'];
            final index = articles.indexWhere((a) => a['id'] == id);
            if (index != -1) {
              articles[index] = updatedArticle;
              print('📝 Article modifié: ${updatedArticle['title']}');
            }
            break;

          case DirectusItemEvent.delete:
            // Supprimer l'article
            final deletedData = message.data!;
            final id = deletedData['id'];
            articles.removeWhere((a) => a['id'] == id);
            print('🗑️  Article supprimé (ID: $id)');
            print('  Total articles: ${articles.length}');
            break;

          default:
            print('📬 Message: ${message.type}');
        }
      },
    );

    // Charger les articles initiaux
    final initialArticles = await directus.items('articles').readMany();
    articles.addAll(initialArticles.data.cast<Map<String, dynamic>>());
    print('📦 Articles initiaux chargés: ${articles.length}');

    print('\n🔴 Application en écoute...');
    print('Créez, modifiez ou supprimez des articles dans Directus');
    print('pour voir les mises à jour en temps réel !\n');

    // Boucle principale (simulée)
    for (var i = 0; i < 60; i++) {
      await Future.delayed(Duration(seconds: 1));

      // Afficher un statut toutes les 10 secondes
      if (i % 10 == 0 && i > 0) {
        print('⏱️  Statut: ${articles.length} articles, connecté');
      }
    }

    // Nettoyage
    await directus.websocket.disconnect();
    print('\n✓ Application arrêtée proprement');
  } catch (e) {
    print('❌ Erreur: $e');
  }

  print('');
}

/// Classe helper pour gérer l'état de l'application
class RealtimeArticleManager {
  final DirectusClient _directus;
  final List<Map<String, dynamic>> _articles = [];
  String? _subscriptionId;

  RealtimeArticleManager(this._directus);

  /// Démarre l'écoute temps réel
  Future<void> start() async {
    await _directus.websocket.connect();

    _subscriptionId = await _directus.websocket.subscribe(
      collection: 'articles',
      onMessage: _handleMessage,
    );

    // Charger les données initiales
    await _loadInitialData();
  }

  /// Charge les articles initiaux
  Future<void> _loadInitialData() async {
    final response = await _directus.items('articles').readMany();
    _articles.addAll(response.data.cast<Map<String, dynamic>>());
  }

  /// Gère les messages WebSocket
  void _handleMessage(DirectusWebSocketMessage message) {
    switch (message.event) {
      case DirectusItemEvent.create:
        _articles.add(message.data!);
        break;
      case DirectusItemEvent.update:
        final id = message.data!['id'];
        final index = _articles.indexWhere((a) => a['id'] == id);
        if (index != -1) _articles[index] = message.data!;
        break;
      case DirectusItemEvent.delete:
        final id = message.data!['id'];
        _articles.removeWhere((a) => a['id'] == id);
        break;
      default:
        break;
    }
  }

  /// Arrête l'écoute
  Future<void> stop() async {
    if (_subscriptionId != null) {
      await _directus.websocket.unsubscribe(_subscriptionId!);
    }
    await _directus.websocket.disconnect();
  }

  /// Récupère tous les articles
  List<Map<String, dynamic>> get articles => List.unmodifiable(_articles);

  /// Nombre d'articles
  int get count => _articles.length;
}
