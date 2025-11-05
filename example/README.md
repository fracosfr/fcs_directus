# Exemples d'utilisation de fcs_directus

Ce dossier contient des exemples pratiques pour comprendre et utiliser la librairie `fcs_directus`.

## 📚 Liste des exemples

### 🚀 Bases

| Fichier | Description | Difficulté |
|---------|-------------|------------|
| [`example_basic.dart`](./example_basic.dart) | Utilisation basique : CRUD simple | ⭐ Débutant |
| [`example_custom_model.dart`](./example_custom_model.dart) | Créer des modèles personnalisés | ⭐⭐ Intermédiaire |
| [`example_filters.dart`](./example_filters.dart) | Filtres et requêtes avancées | ⭐⭐ Intermédiaire |
| [`example_relations.dart`](./example_relations.dart) | Gérer les relations entre collections | ⭐⭐⭐ Avancé |

### 🔐 Authentification et tokens

| Fichier | Description | Difficulté |
|---------|-------------|------------|
| [`example_token_types.dart`](./example_token_types.dart) | Différences entre static token et refresh token | ⭐ Débutant |
| [`example_auto_refresh.dart`](./example_auto_refresh.dart) | Refresh automatique des tokens | ⭐⭐ Intermédiaire |
| [`example_token_refresh_callback.dart`](./example_token_refresh_callback.dart) | Notification et persistance lors du refresh | ⭐⭐⭐ Avancé |

## 🎯 Parcours d'apprentissage recommandé

### Niveau 1 : Débuter avec fcs_directus

1. **`example_basic.dart`** - Comprendre les opérations CRUD de base
   - Connexion à Directus
   - Lecture, création, mise à jour, suppression d'items
   - Utilisation des services

2. **`example_token_types.dart`** - Comprendre les types de tokens
   - Static token vs Refresh token
   - Quand utiliser chaque type
   - Différences de sécurité

### Niveau 2 : Maîtriser les fonctionnalités

3. **`example_custom_model.dart`** - Créer vos propres modèles
   - Définir des classes Dart pour vos collections
   - Mapper JSON ↔ Objets Dart
   - Utiliser fromJson et toJson

4. **`example_filters.dart`** - Interroger vos données
   - Filtres simples et complexes
   - Opérateurs logiques (AND, OR)
   - Tri, pagination, limitation

5. **`example_relations.dart`** - Gérer les relations
   - Relations one-to-many, many-to-one
   - Deep queries avec fields
   - Optimiser les requêtes

### Niveau 3 : Fonctionnalités avancées

6. **`example_auto_refresh.dart`** - Refresh automatique
   - Comment fonctionne le refresh automatique
   - Protection contre les boucles infinies
   - Gestion des requêtes parallèles

7. **`example_token_refresh_callback.dart`** - Persistance des tokens
   - Être notifié lors du refresh
   - Sauvegarder les tokens automatiquement
   - Workflow complet avec storage

## 🔧 Comment exécuter les exemples

### Prérequis

1. **Serveur Directus configuré**
   ```bash
   # Variables d'environnement dans votre .env
   PUBLIC_URL="https://directus.example.com"
   ACCESS_TOKEN_TTL="15m"
   REFRESH_TOKEN_TTL="7d"
   ```

2. **Collections de test**
   - `articles` : Collection avec titre, contenu, auteur
   - `users` : Collection utilisateurs Directus

### Exécution

```bash
# Exemple basique
dart run example/example_basic.dart

# Exemple des filtres
dart run example/example_filters.dart

# Exemple refresh automatique
dart run example/example_auto_refresh.dart

# Tous les exemples de tokens
dart run example/example_token_types.dart
dart run example/example_auto_refresh.dart
dart run example/example_token_refresh_callback.dart
```

### Adapter les exemples

Modifiez les constantes au début de chaque fichier :

```dart
// Dans chaque exemple
const baseUrl = 'https://directus.example.com'; // ← Votre URL
const email = 'user@example.com';               // ← Votre email
const password = 'password';                    // ← Votre mot de passe
```

## 📖 Documentation complémentaire

### Documentation principale

- [Getting Started](../docs/01-getting-started.md) - Premier pas avec fcs_directus
- [Core Concepts](../docs/02-core-concepts.md) - Concepts fondamentaux
- [Authentication](../docs/03-authentication.md) - Authentification détaillée
- [Queries](../docs/05-queries.md) - Requêtes et filtres
- [Relationships](../docs/06-relationships.md) - Relations entre collections

### Documentation avancée

- [AUTO_REFRESH.md](../docs/AUTO_REFRESH.md) - Refresh automatique (analyse technique)
- [AUTHENTICATION_AND_REQUESTS.md](../docs/AUTHENTICATION_AND_REQUESTS.md) - Analyse complète du système d'auth
- [Error Handling](../docs/11-error-handling.md) - Gestion des erreurs

### API Reference

- [Documentation API complète](../doc/api/) - Référence de toutes les classes et méthodes

## 🎓 Exemples par cas d'usage

### Cas d'usage 1 : Application mobile avec login

```dart
// 1. Utiliser example_basic.dart pour comprendre la connexion
// 2. Suivre example_token_refresh_callback.dart pour la persistance
// 3. Implémenter le workflow complet dans votre app Flutter
```

**Fichiers pertinents :**
- `example_basic.dart` - Base de la connexion
- `example_token_refresh_callback.dart` - Persistance des tokens
- `docs/03-authentication.md` - Guide complet

### Cas d'usage 2 : Backend service (script Dart)

```dart
// Utiliser un static token permanent
// Voir example_token_types.dart section "Static Token"
```

**Fichiers pertinents :**
- `example_token_types.dart` - Utilisation des static tokens
- `example_basic.dart` - Opérations CRUD de base

### Cas d'usage 3 : Application avec données relationnelles

```dart
// 1. Comprendre les modèles : example_custom_model.dart
// 2. Gérer les relations : example_relations.dart
// 3. Optimiser les requêtes : example_filters.dart
```

**Fichiers pertinents :**
- `example_custom_model.dart` - Modélisation des données
- `example_relations.dart` - Relations et deep queries
- `example_filters.dart` - Filtrage et optimisation

### Cas d'usage 4 : Application avec authentification automatique

```dart
// Workflow complet avec refresh automatique et persistance
// Voir example_token_refresh_callback.dart - Exemple 3
```

**Fichiers pertinents :**
- `example_token_refresh_callback.dart` - Workflow complet
- `example_auto_refresh.dart` - Mécanisme de refresh
- `docs/AUTO_REFRESH.md` - Documentation technique

## 🐛 Résolution de problèmes

### Erreur : "Connection refused"

```dart
// ❌ Problème
const baseUrl = 'http://localhost:8055';

// ✅ Solution : Utiliser l'URL complète
const baseUrl = 'http://192.168.1.10:8055'; // IP du serveur
```

### Erreur : "TOKEN_EXPIRED" immédiate

```dart
// Vérifier que ACCESS_TOKEN_TTL n'est pas trop court
// Dans .env du serveur Directus :
ACCESS_TOKEN_TTL="15m"  // ✅ BON
ACCESS_TOKEN_TTL="10s"  // ❌ Trop court (pour tests uniquement)
```

### Erreur : "Invalid credentials"

```dart
// Vérifier email/password
// Vérifier que l'utilisateur existe dans Directus
// Vérifier les permissions de l'utilisateur
```

### Callback onTokenRefreshed non appelé

```dart
// Le callback est appelé uniquement lors du refresh AUTOMATIQUE
// Pas lors de :
// - Login initial : await client.auth.login()
// - Refresh manuel : await client.auth.refresh()
// - Restore session : await client.auth.restoreSession()

// Seulement lors d'une requête qui déclenche un refresh automatique
```

## 🤝 Contribution

Pour ajouter un nouvel exemple :

1. Créer un fichier `example_[nom].dart`
2. Suivre la structure des exemples existants :
   - Documentation en haut avec `///`
   - Fonction `main()` avec menu
   - Exemples numérotés : `example1_`, `example2_`, etc.
   - Commentaires explicatifs
3. Ajouter l'exemple dans ce README
4. Tester l'exemple : `dart run example/example_[nom].dart`

## 📝 Licence

Voir [LICENSE](../LICENSE) dans le dossier racine.

---

**Besoin d'aide ?**
- 📖 Consultez la [documentation complète](../docs/)
- 🐛 Signalez un problème sur [GitHub Issues](https://github.com/votreOrganisation/fcs_directus/issues)
- 💬 Rejoignez la communauté Directus sur [Discord](https://directus.chat)
