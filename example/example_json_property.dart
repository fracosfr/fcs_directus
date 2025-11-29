// ignore_for_file: non_constant_identifier_names, avoid_print, unused_local_variable
import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation du JsonProperty pour stocker des valeurs JSON dynamiques
void main() {
  // Exemple 1 : Settings avec configuration JSON
  example1Settings();

  // Exemple 2 : Product avec metadata JSON
  example2Product();

  // Exemple 3 : User avec preferences JSON
  example3UserPreferences();

  // Exemple 4 : Analytics avec data dynamique
  example4Analytics();
}

/// Exemple 1 : Settings avec configuration complexe
void example1Settings() {
  print('=== Exemple 1 : Settings ===\n');

  final settings = AppSettings.empty();

  // Stocker une configuration JSON complexe
  settings.config.set({
    'theme': 'dark',
    'language': 'fr',
    'notifications': {'email': true, 'push': false, 'sms': true},
    'display': {'fontSize': 14, 'lineHeight': 1.5},
  });

  // Accéder aux valeurs
  print('Theme: ${settings.config.asMap()?['theme']}');
  print('Language: ${settings.config.asMap()?['language']}');
  print('Config complet: ${settings.config.value}');

  // Vérifier le type
  print('Est une Map? ${settings.config.isMap}');

  // Cast sécurisé
  final config = settings.config.asMapOrEmpty();
  final notifications = config['notifications'] as Map?;
  print('Email notifications: ${notifications?['email']}\n');
}

/// Exemple 2 : Product avec metadata JSON
void example2Product() {
  print('=== Exemple 2 : Product Metadata ===\n');

  final product = Product.empty();

  product.name.set('Laptop Gaming');
  product.price.set(1299.99);

  // Metadata sous forme de Map
  product.metadata.set({
    'brand': 'TechBrand',
    'model': 'X500',
    'year': 2024,
    'specs': {'cpu': 'Intel i7', 'ram': 16, 'storage': 512},
    'tags': ['gaming', 'portable', 'high-performance'],
  });

  // Accéder aux metadata
  print('Product: ${product.name}');
  print('Price: \$${product.price}');
  print('Brand: ${product.metadata.asMap()?['brand']}');
  print('Year: ${product.metadata.asMap()?['year']}');

  final specs = (product.metadata.asMap()?['specs'] as Map?);
  print('CPU: ${specs?['cpu']}');
  print('RAM: ${specs?['ram']} GB');

  final tags = product.metadata.asMap()?['tags'] as List?;
  print('Tags: ${tags?.join(', ')}\n');
}

/// Exemple 3 : User avec preferences JSON
void example3UserPreferences() {
  print('=== Exemple 3 : User Preferences ===\n');

  final user = UserProfile.empty();

  user.email.set('user@example.com');

  // Preferences peut être n'importe quel type JSON
  user.preferences.set({
    'dashboard': {
      'layout': 'grid',
      'widgets': ['calendar', 'tasks', 'notifications'],
    },
    'privacy': {'profileVisible': true, 'showEmail': false},
    'shortcuts': ['Ctrl+S', 'Ctrl+N', 'Ctrl+F'],
  });

  print('Email: ${user.email}');
  print('Preferences: ${user.preferences.value}');

  // Accéder à des valeurs imbriquées
  final prefs = user.preferences.asMapOrEmpty();
  final dashboard = prefs['dashboard'] as Map?;
  final widgets = dashboard?['widgets'] as List?;
  print('Dashboard layout: ${dashboard?['layout']}');
  print('Widgets: ${widgets?.join(', ')}');

  // Modifier les preferences
  final updatedPrefs = user.preferences.asMapOrEmpty();
  (updatedPrefs['privacy'] as Map)['profileVisible'] = false;
  user.preferences.set(updatedPrefs);

  print(
    'Profile visible: ${(user.preferences.asMap()?['privacy'] as Map)['profileVisible']}\n',
  );
}

/// Exemple 4 : Analytics avec data dynamique
void example4Analytics() {
  print('=== Exemple 4 : Analytics Data ===\n');

  final analytics = AnalyticsEvent.empty();

  analytics.eventName.set('page_view');

  // Data peut être List, Map, ou primitives
  analytics.data.set({
    'page': '/dashboard',
    'duration': 45.3,
    'interactions': 12,
    'clicks': [
      {'element': 'button', 'count': 5},
      {'element': 'link', 'count': 7},
    ],
  });

  print('Event: ${analytics.eventName}');
  print('Data type: ${analytics.data.isMap ? 'Map' : 'Other'}');
  print('Data: ${analytics.data.value}');

  // Cast en Map
  final data = analytics.data.asMapOrEmpty();
  print('Page: ${data['page']}');
  print('Duration: ${data['duration']}s');
  print('Interactions: ${data['interactions']}');

  // Accéder aux clicks
  final clicks = data['clicks'] as List?;
  if (clicks != null) {
    print('Clicks breakdown:');
    for (final click in clicks) {
      final clickMap = click as Map;
      print('  - ${clickMap['element']}: ${clickMap['count']}');
    }
  }

  // Changer le type de data (List au lieu de Map)
  analytics.data.set(['event1', 'event2', 'event3']);
  print('\nData as list: ${analytics.data.asList()}');
  print('Is List? ${analytics.data.isList}\n');
}

// === Modèles d'exemple ===

class AppSettings extends DirectusModel {
  AppSettings(super.data);
  AppSettings.empty() : super.empty();

  @override
  String get itemName => 'app_settings';

  late final config = jsonValue('config');
  late final metadata = jsonValue('metadata');
}

class Product extends DirectusModel {
  Product(super.data);
  Product.empty() : super.empty();

  @override
  String get itemName => 'products';

  late final name = stringValue('name');
  late final price = doubleValue('price');
  late final metadata = jsonValue('metadata');
}

class UserProfile extends DirectusModel {
  UserProfile(super.data);
  UserProfile.empty() : super.empty();

  @override
  String get itemName => 'user_profiles';

  late final email = stringValue('email');
  late final preferences = jsonValue('preferences');
  late final settings = jsonValue('settings');
}

class AnalyticsEvent extends DirectusModel {
  AnalyticsEvent(super.data);
  AnalyticsEvent.empty() : super.empty();

  @override
  String get itemName => 'analytics_events';

  late final eventName = stringValue('event_name');
  late final data = jsonValue('data');
  late final timestamp = dateTimeValue('timestamp');
}
