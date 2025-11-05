import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation de `modelListValueM2M` pour les relations Many-to-Many
///
/// Démontre comment utiliser le property wrapper M2M pour accéder directement
/// aux modèles cibles sans manipuler manuellement la table de jonction.
void main() {
  example1_DefiningM2MProperty();
  example2_UsingM2MProperty();
  example3_SettingM2MRelations();
  example4_ComparingApproaches();
}

/// ============================================================================
/// EXEMPLE 1 : Définir un property M2M dans un modèle personnalisé
/// ============================================================================

void example1_DefiningM2MProperty() {
  print('\n=== Exemple 1 : Définir un property M2M ===\n');

  // Définir un modèle avec une relation M2M
  // Exemple: Article avec plusieurs tags
  print('''
class Article extends DirectusModel {
  Article(super.data);

  @override
  String get itemName => 'articles';

  late final title = stringValue('title');
  late final content = stringValue('content');

  // ✅ Property M2M : accède directement aux Tag
  late final tags = modelListValueM2M<Tag>(
    'tags',              // Nom du champ de relation
    'tags_id'            // Nom du champ dans la table de jonction
  );
}

class Tag extends DirectusModel {
  Tag(super.data);

  @override
  String get itemName => 'tags';

  late final name = stringValue('name');
  late final color = stringValue('color');
}
''');

  print('La structure de la table de jonction sera:');
  print('{');
  print('  "tags": [');
  print('    {');
  print('      "articles_id": "article-123",');
  print('      "tags_id": {          // ← On extrait automatiquement ce champ');
  print('        "id": "tag-1",');
  print('        "name": "Flutter",');
  print('        "color": "blue"');
  print('      }');
  print('    },');
  print('    ...');
  print('  ]');
  print('}');
}

/// ============================================================================
/// EXEMPLE 2 : Utiliser le property M2M
/// ============================================================================

void example2_UsingM2MProperty() {
  print('\n=== Exemple 2 : Utiliser le property M2M ===\n');

  // Enregistrer les factories
  DirectusModel.registerFactory<Tag>((data) => Tag(data));

  // Simuler des données d'article avec tags (comme retourné par Directus)
  final articleData = {
    'id': 'article-123',
    'title': 'Introduction à Flutter',
    'content': 'Flutter est un framework...',
    'tags': [
      {
        'articles_id': 'article-123',
        'tags_id': {
          'id': 'tag-1',
          'name': 'Flutter',
          'color': 'blue',
        },
      },
      {
        'articles_id': 'article-123',
        'tags_id': {
          'id': 'tag-2',
          'name': 'Dart',
          'color': 'green',
        },
      },
      {
        'articles_id': 'article-123',
        'tags_id': {
          'id': 'tag-3',
          'name': 'Mobile',
          'color': 'orange',
        },
      },
    ],
  };

  final article = Article(articleData);

  // Accéder directement aux tags (pas de manipulation de la table de jonction!)
  final tags = article.tags.value;

  print('Article: ${article.title.value}');
  print('Nombre de tags: ${tags.length}');
  print('\nTags:');
  for (final tag in tags) {
    print('  - ${tag.name.value} (${tag.color.value})');
  }

  // Méthodes utiles
  print('\nPremier tag: ${article.tags.first.name.value}');
  print('Dernier tag: ${article.tags.last.name.value}');
  print('Est vide: ${article.tags.isEmpty}');
}

/// ============================================================================
/// EXEMPLE 3 : Définir des relations M2M
/// ============================================================================

void example3_SettingM2MRelations() {
  print('\n=== Exemple 3 : Définir des relations M2M ===\n');

  DirectusModel.registerFactory<Tag>((data) => Tag(data));

  final article = Article({
    'id': 'article-456',
    'title': 'Nouveau tutoriel',
  });

  print('1. Définir par IDs (le plus simple):');
  article.tags.setByIds(['tag-1', 'tag-2', 'tag-3']);
  print(article.toJsonDirty());
  // Résultat: {"tags": [{"tags_id": "tag-1"}, {"tags_id": "tag-2"}, ...]}

  print('\n2. Définir avec des modèles complets:');
  final tags = [
    Tag({'id': 'tag-1', 'name': 'Flutter', 'color': 'blue'}),
    Tag({'id': 'tag-2', 'name': 'Dart', 'color': 'green'}),
  ];
  article.tags.set(tags);

  print('Nombre de tags: ${article.tags.length}');

  print('\n3. Ajouter/Supprimer individuellement:');
  final newTag = Tag({'id': 'tag-4', 'name': 'Tutorial', 'color': 'red'});
  article.tags.add(newTag);
  print('Après ajout: ${article.tags.length} tags');

  article.tags.removeItem(newTag);
  print('Après suppression: ${article.tags.length} tags');

  article.tags.clear();
  print('Après clear: ${article.tags.length} tags');
}

/// ============================================================================
/// EXEMPLE 4 : Comparaison des approches
/// ============================================================================

void example4_ComparingApproaches() {
  print('\n=== Exemple 4 : Comparaison des approches ===\n');

  DirectusModel.registerFactory<Tag>((data) => Tag(data));

  final articleData = {
    'id': 'article-789',
    'tags': [
      {
        'articles_id': 'article-789',
        'tags_id': {'id': 'tag-1', 'name': 'Flutter', 'color': 'blue'},
      },
      {
        'articles_id': 'article-789',
        'tags_id': {'id': 'tag-2', 'name': 'Dart', 'color': 'green'},
      },
    ],
  };

  print('❌ APPROCHE MANUELLE (sans modelListValueM2M):\n');
  print('''
// Récupérer la table de jonction
final junctionItems = article.getList<Map<String, dynamic>>('tags');

// Extraire manuellement chaque tag
final tagsManual = <Tag>[];
for (final item in junctionItems) {
  final tagData = item['tags_id'];
  if (tagData is Map<String, dynamic>) {
    tagsManual.add(Tag(tagData));
  }
}

print('Tags: \${tagsManual.length}');
''');
  print('Lignes de code: 8-10');
  print('Complexité: Élevée');
  print('Risque d\'erreurs: Oui');

  print('\n✅ AVEC modelListValueM2M:\n');
  print('''
final tags = article.tags.value;
print('Tags: \${tags.length}');
''');
  print('Lignes de code: 1');
  print('Complexité: Faible');
  print('Risque d\'erreurs: Non');

  // Démonstration réelle
  final article = Article(articleData);
  final tags = article.tags.value;

  print('\n--- Résultat ---');
  print('Tags trouvés: ${tags.length}');
  for (final tag in tags) {
    print('  - ${tag.name.value}');
  }
}

/// ============================================================================
/// DÉFINITION DES MODÈLES
/// ============================================================================

class Article extends DirectusModel {
  Article(super.data);

  @override
  String get itemName => 'articles';

  late final title = stringValue('title');
  late final content = stringValue('content');

  // Property M2M pour accéder directement aux tags
  late final tags = modelListValueM2M<Tag>(
    'tags',     // Nom du champ de relation
    'tags_id',  // Nom du champ dans la table de jonction
  );
}

class Tag extends DirectusModel {
  Tag(super.data);

  @override
  String get itemName => 'tags';

  late final name = stringValue('name');
  late final color = stringValue('color');
}

/// ============================================================================
/// GUIDE DE RÉFÉRENCE
/// ============================================================================

/*
┌─────────────────────────────────────────────────────────────────────────────┐
│                    RELATIONS MANY-TO-MANY DANS DIRECTUS                     │
└─────────────────────────────────────────────────────────────────────────────┘

1. STRUCTURE DE LA RELATION M2M
   ───────────────────────────────

   articles                     articles_tags                    tags
   ┌──────────┐                 ┌───────────────┐               ┌────────┐
   │ id       │────┐            │ articles_id   │          ┌────│ id     │
   │ title    │    └───────────>│ tags_id       │<─────────┘    │ name   │
   │ content  │                 └───────────────┘               │ color  │
   └──────────┘                 Table de jonction               └────────┘

2. DONNÉES CHARGÉES DEPUIS DIRECTUS
   ─────────────────────────────────

   GET /items/articles/123?fields=*,tags.tags_id.*

   Réponse:
   {
     "id": "article-123",
     "title": "Mon article",
     "tags": [                        ← Table de jonction
       {
         "articles_id": "article-123",
         "tags_id": {                 ← Modèle Tag complet
           "id": "tag-1",
           "name": "Flutter",
           "color": "blue"
         }
       },
       ...
     ]
   }

3. UTILISATION DE modelListValueM2M
   ─────────────────────────────────

   // Définition
   late final tags = modelListValueM2M<Tag>(
     'tags',     // Champ de la relation
     'tags_id',  // Champ dans la table de jonction
   );

   // Lecture
   List<Tag> tags = article.tags.value;
   Tag firstTag = article.tags.first;
   bool hasAny = article.tags.isNotEmpty;
   int count = article.tags.length;

   // Écriture
   article.tags.setByIds(['tag-1', 'tag-2']);
   article.tags.set([tag1, tag2]);
   article.tags.add(newTag);
   article.tags.removeItem(oldTag);
   article.tags.clear();

4. AVANTAGES
   ──────────

   ✅ Simplifie le code (1 ligne au lieu de 8+)
   ✅ Type-safe avec génériques
   ✅ Évite les erreurs manuelles
   ✅ Cohérent avec les autres property wrappers
   ✅ Facilite la maintenance

5. AUTRES CAS D'USAGE M2M
   ──────────────────────

   - Articles ↔ Tags (exemple ci-dessus)
   - Produits ↔ Catégories
   - Utilisateurs ↔ Groupes
   - Projets ↔ Membres
   - Cours ↔ Étudiants
   - Films ↔ Acteurs
   - Utilisateurs ↔ Policies (Directus)

6. REQUÊTE POUR CHARGER LES DONNÉES
   ────────────────────────────────

   // Dans une application réelle avec DirectusClient:
   final article = await client.items('articles').getItem(
     articleId,
     query: QueryParameters(
       fields: [
         '*',              // Tous les champs de l'article
         'tags.tags_id.*'  // Charger les tags via la table de jonction
       ]
     )
   );

7. COMPARAISON
   ───────────

   Sans M2M wrapper:                  Avec M2M wrapper:
   ┌─────────────────────────────┐   ┌──────────────────┐
   │ 8-10 lignes de code         │   │ 1 ligne de code  │
   │ Risque d'erreurs            │   │ Type-safe        │
   │ Difficile à maintenir       │   │ Facile à lire    │
   │ Complexité élevée           │   │ Simple           │
   └─────────────────────────────┘   └──────────────────┘

└─────────────────────────────────────────────────────────────────────────────┘
*/
