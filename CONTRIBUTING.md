# Guide de contribution

Merci de votre intérêt pour contribuer à fcs_directus ! Ce guide vous aidera à démarrer.

## 🚀 Démarrage rapide

### Prérequis

- Dart SDK ≥ 3.9.2
- Flutter ≥ 1.17.0
- Un IDE (VS Code, Android Studio, IntelliJ IDEA)

### Installation du projet

```bash
# Cloner le repository
git clone https://github.com/fracosfr/fcs_directus.git
cd fcs_directus

# Installer les dépendances
flutter pub get
```

## 📝 Standards de code

### Documentation

Tous les éléments publics doivent être documentés avec des commentaires Dart :

```dart
/// Brève description de la classe/méthode.
///
/// Description détaillée si nécessaire avec des exemples d'utilisation.
///
/// Exemple :
/// ```dart
/// final client = DirectusClient(config);
/// await client.auth.login(email: 'user@example.com', password: 'pass');
/// ```
class MyClass {
  /// Description du paramètre.
  final String myParameter;
  
  /// Crée une nouvelle instance de [MyClass].
  ///
  /// Le paramètre [myParameter] est obligatoire.
  MyClass(this.myParameter);
}
```

### Conventions de nommage

- **Classes** : PascalCase (`DirectusClient`, `QueryParameters`)
- **Méthodes/Fonctions** : camelCase (`createOne`, `readMany`)
- **Variables/Propriétés** : camelCase (`accessToken`, `baseUrl`)
- **Constantes** : lowerCamelCase (`defaultTimeout`)
- **Fichiers** : snake_case (`directus_client.dart`)

### Structure du code

```
lib/
├── src/
│   ├── core/           # Client HTTP, configuration
│   ├── exceptions/     # Gestion des erreurs
│   ├── models/         # Modèles de données
│   ├── services/       # Services API
│   ├── utils/          # Utilitaires
│   └── websocket/      # Client WebSocket
└── fcs_directus.dart   # Point d'entrée public
```

## 🧪 Tests

### Exécuter les tests

```bash
# Tous les tests
flutter test

# Tests spécifiques
flutter test test/directus_filter_test.dart

# Avec couverture
flutter test --coverage
```

### Écrire des tests

Créez des tests pour toute nouvelle fonctionnalité :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fcs_directus/fcs_directus.dart';

void main() {
  group('MaFonctionnalité', () {
    test('doit faire quelque chose', () {
      // Arrange
      final instance = MaClasse();
      
      // Act
      final result = instance.maMethode();
      
      // Assert
      expect(result, equals(expectedValue));
    });
  });
}
```

## 📚 Générer la documentation

```bash
# Générer la documentation API
dart doc

# Ouvrir la documentation
open doc/api/index.html  # macOS
xdg-open doc/api/index.html  # Linux
start doc/api/index.html  # Windows
```

## 🔄 Workflow de contribution

1. **Fork** le repository
2. **Créer une branche** pour votre fonctionnalité :
   ```bash
   git checkout -b feature/ma-super-feature
   ```
3. **Faire vos modifications** en suivant les standards
4. **Écrire des tests** pour votre code
5. **Vérifier** que tout fonctionne :
   ```bash
   flutter test
   dart analyze
   dart format .
   ```
6. **Commit** vos changements :
   ```bash
   git commit -m "feat: ajout de ma super feature"
   ```
7. **Push** vers votre fork :
   ```bash
   git push origin feature/ma-super-feature
   ```
8. **Ouvrir une Pull Request** sur GitHub

## 💬 Messages de commit

Utilisez [Conventional Commits](https://www.conventionalcommits.org/) :

- `feat:` - Nouvelle fonctionnalité
- `fix:` - Correction de bug
- `docs:` - Documentation uniquement
- `style:` - Formatage, point-virgules manquants, etc.
- `refactor:` - Refactoring de code
- `test:` - Ajout de tests
- `chore:` - Maintenance, dépendances

Exemples :
```
feat: ajout du support des webhooks
fix: correction de la pagination dans ItemsService
docs: mise à jour du README avec exemples WebSocket
```

## 🎯 Priorités de contribution

### Fonctionnalités souhaitées

- [ ] Tests d'intégration avec une instance Directus réelle
- [ ] Support des GraphQL subscriptions
- [ ] Cache avancé avec stratégies configurables
- [ ] Retry logic automatique pour les requêtes
- [ ] Migration utility (schema migrations)
- [ ] CLI tool pour la génération de modèles
- [ ] Support des extensions Directus
- [ ] Offline-first avec sync

### Améliorations

- [ ] Augmenter la couverture de tests (objectif : 90%+)
- [ ] Performance benchmarks
- [ ] Documentation vidéo
- [ ] Plus d'exemples pratiques
- [ ] Support multi-plateforme testé (Web, Mobile, Desktop)

## 📋 Checklist avant Pull Request

- [ ] Le code compile sans erreur ni warning
- [ ] Tous les tests passent
- [ ] Le code est formaté (`dart format .`)
- [ ] L'analyse statique ne retourne pas d'erreur (`dart analyze`)
- [ ] La documentation est à jour
- [ ] Les nouveaux éléments publics sont documentés
- [ ] Des exemples sont fournis si nécessaire
- [ ] Le CHANGELOG est mis à jour

## ❓ Questions

Si vous avez des questions :

- Ouvrez une [issue](https://github.com/fracosfr/fcs_directus/issues)
- Consultez la [documentation Directus](https://docs.directus.io/)
- Regardez les [exemples](example/)

## 📄 Licence

En contribuant, vous acceptez que vos contributions soient sous licence MIT.

Merci pour votre contribution ! 🎉
