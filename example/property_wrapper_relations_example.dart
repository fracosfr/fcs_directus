import 'package:fcs_directus/fcs_directus.dart';

/// Exemple avancé des Property Wrappers avec relations DirectusModel
///
/// Montre comment utiliser modelValue<T>() et modelListValue<T>()
/// pour gérer les relations entre modèles.

/// Modèle Author (auteur)
class Author extends DirectusModel {
  @override
  String get itemName => 'authors';

  Author(super.data);
  Author.empty() : super.empty();

  late final name = stringValue('name');
  late final email = stringValue('email');
  late final bio = stringValue('bio');

  @override
  String toString() => 'Author(name: $name, email: $email)';
}

/// Modèle Tag
class Tag extends DirectusModel {
  @override
  String get itemName => 'tags';

  Tag(super.data);
  Tag.empty() : super.empty();

  late final name = stringValue('name');
  late final color = stringValue('color');

  @override
  String toString() => 'Tag($name)';
}

/// Modèle Comment
class Comment extends DirectusModel {
  @override
  String get itemName => 'comments';

  Comment(super.data);
  Comment.empty() : super.empty();

  late final content = stringValue('content');
  late final author = modelValue<Author>('author'); // 👈 Relation One-to-One
  late final createdAt = dateTimeValue('created_at');

  @override
  String toString() => 'Comment(by: ${author.value?.name ?? "unknown"})';
}

/// Modèle Article avec relations multiples
class Article extends DirectusModel {
  @override
  String get itemName => 'articles';

  Article(super.data);
  Article.empty() : super.empty();

  // Champs simples
  late final title = stringValue('title');
  late final content = stringValue('content');
  late final status = stringValue('status', defaultValue: 'draft');
  late final publishedAt = dateTimeValue('published_at');

  // Relations DirectusModel
  late final author = modelValue<Author>('author'); // 👈 One-to-One
  late final tags = modelListValue<Tag>('tags'); // 👈 Many-to-Many
  late final comments = modelListValue<Comment>('comments'); // 👈 One-to-Many

  @override
  String toString() => 'Article($title by ${author.value?.name ?? "unknown"})';
}

void main() {
  // Enregistrement des factories
  DirectusModel.registerFactory<Author>((data) => Author(data));
  DirectusModel.registerFactory<Tag>((data) => Tag(data));
  DirectusModel.registerFactory<Comment>((data) => Comment(data));
  DirectusModel.registerFactory<Article>((data) => Article(data));

  print('🎯 Property Wrappers avec Relations DirectusModel\n');

  // === 1. Relation One-to-One (Article → Author) ===
  print('📝 1. Relation One-to-One (Article → Author)');

  final article = Article({
    'id': '1',
    'title': 'Introduction à Directus',
    'content': 'Directus est un Headless CMS...',
    'status': 'published',
    'published_at': '2024-10-26T10:00:00Z',
    'author': {
      'id': '1',
      'name': 'John Doe',
      'email': 'john@example.com',
      'bio': 'Développeur passionné',
    },
  });

  print('✅ Article créé: ${article.title}');
  print('   Auteur: ${article.author}'); // toString() automatique
  print('   Nom de l\'auteur: ${article.author.value?.name}');
  print('   Email: ${article.author.value?.email}');
  print('   Bio: ${article.author.value?.bio}\n');

  // Accès aux métadonnées
  print('🔍 Métadonnées de la relation:');
  print('   Nom du champ: ${article.author.name}');
  print('   Existe: ${article.author.exists}');
  print('   Est null: ${article.author.value == null}\n');

  // === 2. Modifier une relation One-to-One ===
  print('✏️  2. Modifier une relation One-to-One');

  final newAuthor = Author({
    'id': '2',
    'name': 'Jane Smith',
    'email': 'jane@example.com',
    'bio': 'Expert Directus',
  });

  print('   Avant: ${article.author.value?.name}');
  article.author.set(newAuthor);
  print('   Après: ${article.author.value?.name}\n');

  // === 3. Relation Many-to-Many (Article → Tags) ===
  print('🏷️  3. Relation Many-to-Many (Article → Tags)');

  final articleWithTags = Article({
    'id': '2',
    'title': 'Guide Flutter',
    'content': 'Flutter permet...',
    'status': 'draft',
    'author': {'id': '1', 'name': 'John Doe', 'email': 'john@example.com'},
    'tags': [
      {'id': '1', 'name': 'Flutter', 'color': 'blue'},
      {'id': '2', 'name': 'Mobile', 'color': 'green'},
      {'id': '3', 'name': 'Tutorial', 'color': 'orange'},
    ],
  });

  print('✅ Article: ${articleWithTags.title}');
  print('   Nombre de tags: ${articleWithTags.tags.length}');
  print('   Tags:');
  for (final tag in articleWithTags.tags.value) {
    print('     - ${tag.name} (${tag.color})');
  }
  print('');

  // === 4. Manipuler une liste de relations ===
  print('🔧 4. Manipuler une liste de relations');

  // Ajouter un tag
  final newTag = Tag({'id': '4', 'name': 'Dart', 'color': 'teal'});
  articleWithTags.tags.add(newTag);
  print('   Après ajout: ${articleWithTags.tags.length} tags');

  // Vider les tags
  final oldLength = articleWithTags.tags.length;
  articleWithTags.tags.clear();
  print(
    '   Après clear(): ${articleWithTags.tags.length} tags (avant: $oldLength)',
  );

  // Remplacer tous les tags
  articleWithTags.tags.set([
    Tag({'id': '5', 'name': 'Backend', 'color': 'red'}),
    Tag({'id': '6', 'name': 'API', 'color': 'purple'}),
  ]);
  print('   Après set(): ${articleWithTags.tags.length} tags');
  for (final tag in articleWithTags.tags.value) {
    print('     - ${tag.name}');
  }
  print('');

  // === 5. Relation One-to-Many (Article → Comments) ===
  print('💬 5. Relation One-to-Many (Article → Comments)');

  final articleWithComments = Article({
    'id': '3',
    'title': 'Les bases de Directus',
    'content': 'Directus simplifie...',
    'status': 'published',
    'author': {'id': '1', 'name': 'John Doe', 'email': 'john@example.com'},
    'comments': [
      {
        'id': '1',
        'content': 'Excellent article !',
        'created_at': '2024-10-26T11:00:00Z',
        'author': {
          'id': '2',
          'name': 'Jane Smith',
          'email': 'jane@example.com',
        },
      },
      {
        'id': '2',
        'content': 'Très instructif',
        'created_at': '2024-10-26T12:00:00Z',
        'author': {'id': '3', 'name': 'Bob Wilson', 'email': 'bob@example.com'},
      },
    ],
  });

  print('✅ Article: ${articleWithComments.title}');
  print('   Commentaires: ${articleWithComments.comments.length}');
  for (final comment in articleWithComments.comments.value) {
    print('     ${comment.author.value?.name}: ${comment.content}');
    print('       (${comment.createdAt.value})');
  }
  print('');

  // === 6. Créer un article complet from scratch ===
  print('🚀 6. Créer un article complet from scratch');

  final newArticle = Article.empty();
  newArticle.id = '4';
  newArticle.title.set('Nouveau tutoriel');
  newArticle.content.set('Contenu du tutoriel...');
  newArticle.status.set('draft');

  // Définir l'auteur
  final articleAuthor = Author.empty();
  articleAuthor.id = '1';
  articleAuthor.name.set('John Doe');
  articleAuthor.email.set('john@example.com');
  newArticle.author.set(articleAuthor);

  // Ajouter des tags
  newArticle.tags.set([
    Tag({'id': '1', 'name': 'Tutorial', 'color': 'blue'}),
    Tag({'id': '2', 'name': 'Beginner', 'color': 'green'}),
  ]);

  print('✅ Nouvel article créé:');
  print('   Titre: ${newArticle.title}');
  print('   Auteur: ${newArticle.author.value?.name}');
  print('   Tags: ${newArticle.tags.length}');
  for (final tag in newArticle.tags.value) {
    print('     - ${tag.name}');
  }
  print('');

  // === 7. Vérifications et gestion des nulls ===
  print('🔍 7. Vérifications et gestion des nulls');

  final emptyArticle = Article.empty();
  print('   Article vide:');
  print('   author existe: ${emptyArticle.author.exists}');
  print('   author.value: ${emptyArticle.author.value}');
  print('   tags.length: ${emptyArticle.tags.length}');
  print('   tags.isEmpty: ${emptyArticle.tags.isEmpty}');
  print('');

  // valueOrThrow pour forcer une valeur
  try {
    final author = emptyArticle.author.valueOrThrow;
    print('   Author: $author');
  } catch (e) {
    print('   ❌ Exception (attendue): $e');
  }
  print('');

  // === 8. Sérialisation ===
  print('📤 8. Sérialisation en JSON');

  final json = articleWithComments.toJson();
  print('   JSON complet: ${json.keys.length} clés');
  print('   author: ${json['author']}');
  print('   tags: ${(json['tags'] as List?)?.length ?? 0} tags');
  print(
    '   comments: ${(json['comments'] as List?)?.length ?? 0} commentaires\n',
  );

  // === 9. Comparaison des syntaxes ===
  print('⚖️  9. Comparaison des syntaxes');
  print('   Syntaxe classique (getters/setters):');
  print('   Author get author => getDirectusModel<Author>("author");');
  print('   set author(Author value) => setDirectusModel("author", value);');
  print('   List<Tag> get tags => getDirectusModelList<Tag>("tags");');
  print('   set tags(List<Tag> value) => setDirectusModelList("tags", value);');
  print('');
  print('   Syntaxe property wrapper:');
  print('   late final author = modelValue<Author>("author");');
  print('   late final tags = modelListValue<Tag>("tags");');
  print('');
  print('   Utilisation:');
  print('   Classique: article.author = newAuthor');
  print('   Wrapper:   article.author.set(newAuthor)');
  print('   Bonus:     article.author.name → "author"');
  print('              article.author.exists → true');
  print('              article.author.valueOrThrow → Author ou exception');
  print('              article.tags.add(tag) → Ajoute un tag');
  print('              article.tags.length → Nombre de tags\n');

  // === 10. Avantages ===
  print('✨ Avantages des Property Wrappers pour les relations:');
  print('   ✅ Une seule ligne au lieu de 2-4');
  print('   ✅ Accès type-safe aux objets nested');
  print('   ✅ Méthodes utilitaires pour les listes (add, remove, clear)');
  print('   ✅ Gestion automatique de la sérialisation');
  print('   ✅ Vérification d\'existence (.exists)');
  print('   ✅ Accès sécurisé (.valueOrThrow)');
  print(
    '   ✅ Support complet des relations One-to-One, One-to-Many, Many-to-Many',
  );
  print('   ✅ Code plus lisible et maintenable');
}
