# Guide de contribution

Merci de votre intérêt pour contribuer à fcs_directus ! 🎉

## 🚀 Comment contribuer

### Rapporter un bug

Si vous trouvez un bug, veuillez ouvrir une issue avec:
- Une description claire du problème
- Les étapes pour reproduire le bug
- Le comportement attendu vs le comportement actuel
- Votre version de Dart/Flutter
- Des logs ou captures d'écran si pertinent

### Proposer une fonctionnalité

Pour proposer une nouvelle fonctionnalité:
1. Vérifiez qu'elle n'existe pas déjà dans les issues
2. Ouvrez une issue décrivant la fonctionnalité
3. Expliquez le cas d'usage et pourquoi c'est utile
4. Attendez les retours avant de commencer le développement

### Soumettre une Pull Request

1. **Forkez le projet**
   ```bash
   git clone https://github.com/votre-username/fcs_directus.git
   cd fcs_directus
   ```

2. **Créez une branche**
   ```bash
   git checkout -b feature/ma-super-fonctionnalite
   # ou
   git checkout -b fix/correction-bug
   ```

3. **Installez les dépendances**
   ```bash
   flutter pub get
   ```

4. **Effectuez vos modifications**
   - Suivez le style de code existant
   - Ajoutez des tests pour votre code
   - Documentez votre code avec Dartdoc
   - Mettez à jour le README si nécessaire

5. **Exécutez les tests**
   ```bash
   flutter test
   ```

6. **Vérifiez le formatage**
   ```bash
   dart format lib test example
   ```

7. **Vérifiez l'analyse statique**
   ```bash
   flutter analyze
   ```

8. **Commitez vos changements**
   ```bash
   git add .
   git commit -m "feat: ajoute support pour XYZ"
   ```

   Utilisez les préfixes de commit conventionnels:
   - `feat:` - Nouvelle fonctionnalité
   - `fix:` - Correction de bug
   - `docs:` - Documentation uniquement
   - `style:` - Formatage, point-virgules manquants, etc.
   - `refactor:` - Refactoring de code
   - `test:` - Ajout de tests
   - `chore:` - Mise à jour des dépendances, etc.

9. **Poussez vers votre fork**
   ```bash
   git push origin feature/ma-super-fonctionnalite
   ```

10. **Ouvrez une Pull Request**
    - Donnez un titre clair
    - Décrivez vos changements
    - Référencez les issues liées
    - Attendez la review

## 📝 Standards de code

### Style

- Suivez les [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Utilisez `dart format` avant de commiter
- Limitez les lignes à 80 caractères quand possible

### Documentation

Documentez toutes les classes et méthodes publiques:

```dart
/// Courte description sur une ligne.
///
/// Description plus détaillée sur plusieurs paragraphes
/// si nécessaire.
///
/// Exemple d'utilisation:
/// ```dart
/// final result = maFonction(param);
/// ```
///
/// [param] Description du paramètre
///
/// Retourne une description du résultat
Future<Result> maFonction(String param) async {
  // ...
}
```

### Tests

- Ajoutez des tests pour toute nouvelle fonctionnalité
- Maintenez la couverture de code élevée
- Les tests doivent être clairs et lisibles
- Utilisez des noms descriptifs pour les tests

```dart
test('devrait retourner une erreur si le paramètre est invalide', () {
  expect(() => maFonction(null), throwsA(isA<ArgumentError>()));
});
```

### Structure des commits

```
type(scope): sujet

corps du commit si nécessaire

footer si nécessaire (breaking changes, références)
```

Exemple:
```
feat(auth): ajoute support OAuth2

Implémente le flow OAuth2 complet avec:
- Authorization code flow
- Refresh token
- PKCE

Closes #123
```

## 🧪 Exécuter les tests

```bash
# Tous les tests
flutter test

# Tests spécifiques
flutter test test/fcs_directus_test.dart

# Avec couverture
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 📖 Générer la documentation

```bash
dart doc
open doc/api/index.html
```

## 🏗️ Architecture

Consultez [ARCHITECTURE.md](ARCHITECTURE.md) pour comprendre l'organisation du code.

## ❓ Questions

Si vous avez des questions:
- Ouvrez une issue avec le label `question`
- Consultez les issues existantes
- Lisez la documentation

## 📜 Code de conduite

Soyez respectueux et constructif dans vos échanges. Ce projet suit le [Contributor Covenant](https://www.contributor-covenant.org/).

## 🙏 Merci

Merci à tous les contributeurs qui aident à améliorer fcs_directus !
