import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation du EnumProperty pour gérer les enums avec Directus
///
/// Démontre :
/// - Conversion automatique String ↔ Enum
/// - Gestion des valeurs invalides avec fallback
/// - Méthodes utilitaires pour les enums
void main() {
  // Enregistrer les factories
  DirectusModel.registerFactory<Article>((data) => Article(data));
  DirectusModel.registerFactory<Product>((data) => Product(data));
  DirectusModel.registerFactory<Task>((data) => Task(data));

  example1_BasicEnumUsage();
  example2_InvalidValues();
  example3_EnumUtilities();
  example4_ComplexEnums();
  example5_DirtyTracking();
}

// ============================================================================
// DÉFINITION DES ENUMS
// ============================================================================

/// Statut d'un article
enum ArticleStatus { draft, review, published, archived }

/// Visibilité d'un article
enum Visibility { public, private, protected }

/// Statut d'un produit
enum ProductStatus { active, inactive, outOfStock, discontinued }

/// Priorité d'une tâche
enum Priority { low, medium, high, urgent }

/// Statut d'une tâche
enum TaskStatus { todo, inProgress, done, cancelled }

// ============================================================================
// EXEMPLE 1 : Utilisation basique
// ============================================================================

void example1_BasicEnumUsage() {
  print('=== Exemple 1 : Utilisation basique ===\n');

  // Créer un article avec un statut
  final article = Article({
    'id': '1',
    'title': 'Mon premier article',
    'status': 'published', // String venant de Directus
  });

  // Accéder au statut en tant qu'enum
  print('Statut: ${article.status.value}'); // ArticleStatus.published
  print('Statut (string): ${article.status.asString}'); // "published"

  // Modifier le statut
  article.status.set(ArticleStatus.draft);
  print('Nouveau statut: ${article.status.value}'); // ArticleStatus.draft
  print('Nouveau statut (string): ${article.status.asString}'); // "draft"

  // Vérifier le statut
  if (article.status.is_(ArticleStatus.draft)) {
    print('✓ L\'article est en brouillon');
  }

  print('');
}

// ============================================================================
// EXEMPLE 2 : Gestion des valeurs invalides
// ============================================================================

void example2_InvalidValues() {
  print('=== Exemple 2 : Valeurs invalides ===\n');

  // Cas 1 : Valeur invalide dans les données
  final article1 = Article({
    'id': '2',
    'title': 'Article avec statut invalide',
    'status': 'unknown_status', // Valeur qui n'existe pas dans l'enum
  });

  print('Statut (valeur invalide): ${article1.status.value}');
  // Résultat: ArticleStatus.draft (valeur par défaut)
  print('→ Fallback vers la valeur par défaut\n');

  // Cas 2 : Valeur null ou absente
  final article2 = Article({
    'id': '3',
    'title': 'Article sans statut',
    // Pas de champ 'status'
  });

  print('Statut (valeur absente): ${article2.status.value}');
  // Résultat: ArticleStatus.draft (valeur par défaut)
  print('→ Fallback vers la valeur par défaut\n');

  // Cas 3 : Définir depuis un String invalide
  article1.status.setFromString('invalid_value');
  print('Statut après setFromString invalide: ${article1.status.value}');
  // Résultat: ArticleStatus.draft (valeur par défaut)
  print('→ Fallback vers la valeur par défaut\n');

  // Cas 4 : Insensibilité à la casse
  final article3 = Article({
    'id': '4',
    'title': 'Article avec casse différente',
    'status': 'PUBLISHED', // Majuscules
  });

  print('Statut (PUBLISHED): ${article3.status.value}');
  // Résultat: ArticleStatus.published
  print('→ Conversion insensible à la casse ✓\n');

  print('');
}

// ============================================================================
// EXEMPLE 3 : Méthodes utilitaires
// ============================================================================

void example3_EnumUtilities() {
  print('=== Exemple 3 : Méthodes utilitaires ===\n');

  final article = Article({
    'id': '5',
    'title': 'Article de test',
    'status': 'published',
    'visibility': 'public',
  });

  // Vérifier si c'est une valeur spécifique
  print('Est publié? ${article.status.is_(ArticleStatus.published)}'); // true
  print('Est brouillon? ${article.status.is_(ArticleStatus.draft)}'); // false

  // Vérifier si c'est l'une des valeurs
  final isEditable = article.status.isOneOf([
    ArticleStatus.draft,
    ArticleStatus.review,
  ]);
  print('Est éditable? $isEditable'); // false

  final isVisible = article.visibility.isOneOf([
    Visibility.public,
    Visibility.protected,
  ]);
  print('Est visible? $isVisible'); // true

  // Obtenir toutes les valeurs possibles
  print('\nToutes les valeurs possibles de ArticleStatus:');
  for (final status in article.status.allValues) {
    print('  - $status');
  }

  // Reset à la valeur par défaut
  article.status.reset();
  print('\nAprès reset: ${article.status.value}'); // ArticleStatus.draft

  print('');
}

// ============================================================================
// EXEMPLE 4 : Enums complexes
// ============================================================================

void example4_ComplexEnums() {
  print('=== Exemple 4 : Enums complexes ===\n');

  final product = Product({
    'id': 'prod-1',
    'name': 'Laptop',
    'status': 'active',
  });

  print('Produit: ${product.name.value}');
  print('Statut: ${product.status.value}');

  // Logique métier basée sur l'enum
  if (product.status.is_(ProductStatus.active)) {
    print('→ Produit disponible à la vente');
  } else if (product.status.is_(ProductStatus.outOfStock)) {
    print('→ Produit en rupture de stock');
  } else if (product.status.is_(ProductStatus.discontinued)) {
    print('→ Produit arrêté');
  }

  // Tâche avec plusieurs enums
  final task = Task({
    'id': 'task-1',
    'title': 'Corriger le bug critique',
    'status': 'inProgress',
    'priority': 'urgent',
  });

  print('\nTâche: ${task.title.value}');
  print('Statut: ${task.status.value}');
  print('Priorité: ${task.priority.value}');

  // Logique combinée
  if (task.status.is_(TaskStatus.inProgress) &&
      task.priority.is_(Priority.urgent)) {
    print('⚠️ Tâche urgente en cours !');
  }

  // Progression de la tâche
  task.status.set(TaskStatus.done);
  print('\n✓ Tâche terminée: ${task.status.value}');

  print('');
}

// ============================================================================
// EXEMPLE 5 : Dirty tracking avec les enums
// ============================================================================

void example5_DirtyTracking() {
  print('=== Exemple 5 : Dirty tracking ===\n');

  final article = Article({
    'id': '6',
    'title': 'Article initial',
    'status': 'draft',
    'visibility': 'private',
  });

  print('État initial:');
  print('  Statut: ${article.status.value}');
  print('  Visibilité: ${article.visibility.value}');
  print('  isDirty: ${article.isDirty}');
  print('  dirtyFields: ${article.dirtyFields}');

  // Modifier le statut
  article.status.set(ArticleStatus.published);
  article.visibility.set(Visibility.public);

  print('\nAprès modifications:');
  print('  Statut: ${article.status.value}');
  print('  Visibilité: ${article.visibility.value}');
  print('  isDirty: ${article.isDirty}');
  print('  dirtyFields: ${article.dirtyFields}');

  // Voir les données à envoyer à Directus
  final dirtyData = article.toJsonDirty();
  print('\nDonnées à envoyer (toJsonDirty):');
  print('  $dirtyData');
  // Résultat: {"status": "published", "visibility": "public"}

  // Marquer comme propre après sauvegarde
  article.markClean();
  print('\nAprès markClean:');
  print('  isDirty: ${article.isDirty}');
  print('  dirtyFields: ${article.dirtyFields}');

  print('');
}

// ============================================================================
// DÉFINITION DES MODÈLES
// ============================================================================

/// Modèle Article avec enums
class Article extends DirectusModel {
  Article(super.data);
  Article.empty() : super.empty();

  @override
  String get itemName => 'articles';

  late final title = stringValue('title');
  late final content = stringValue('content');

  // Enums avec valeurs par défaut
  late final status = enumValue<ArticleStatus>(
    'status',
    ArticleStatus.draft,
    ArticleStatus.values,
  );
  late final visibility = enumValue<Visibility>(
    'visibility',
    Visibility.private,
    Visibility.values,
  );

  // Getters dérivés utilisant les enums
  bool get isPublished => status.is_(ArticleStatus.published);
  bool get isDraft => status.is_(ArticleStatus.draft);
  bool get isPublic => visibility.is_(Visibility.public);

  bool get canEdit =>
      status.isOneOf([ArticleStatus.draft, ArticleStatus.review]);
}

/// Modèle Product avec enum de statut
class Product extends DirectusModel {
  Product(super.data);
  Product.empty() : super.empty();

  @override
  String get itemName => 'products';

  late final name = stringValue('name');
  late final description = stringValue('description');
  late final price = doubleValue('price');

  late final status = enumValue<ProductStatus>(
    'status',
    ProductStatus.active,
    ProductStatus.values,
  );

  // Getters basés sur l'enum
  bool get isAvailable => status.is_(ProductStatus.active);
  bool get isOutOfStock => status.is_(ProductStatus.outOfStock);
  bool get isDiscontinued => status.is_(ProductStatus.discontinued);
}

/// Modèle Task avec plusieurs enums
class Task extends DirectusModel {
  Task(super.data);
  Task.empty() : super.empty();

  @override
  String get itemName => 'tasks';

  late final title = stringValue('title');
  late final description = stringValue('description');

  late final status = enumValue<TaskStatus>(
    'status',
    TaskStatus.todo,
    TaskStatus.values,
  );
  late final priority = enumValue<Priority>(
    'priority',
    Priority.medium,
    Priority.values,
  );

  // Getters dérivés
  bool get isCompleted => status.is_(TaskStatus.done);
  bool get isCancelled => status.is_(TaskStatus.cancelled);
  bool get isActive => status.isOneOf([TaskStatus.todo, TaskStatus.inProgress]);

  bool get isUrgent => priority.is_(Priority.urgent);
  bool get isHighPriority => priority.isOneOf([Priority.high, Priority.urgent]);
}
