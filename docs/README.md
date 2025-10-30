# Documentation fcs_directus

Bienvenue dans la documentation de la librairie **fcs_directus** !

## 📚 Guides disponibles

### Pour commencer
- 📘 [**README.md**](../README.md) - Documentation principale et quick start
- 📊 [**PROJECT_STATUS.md**](PROJECT_STATUS.md) - État actuel du projet

### Architecture et design
- 🏗️ [**ARCHITECTURE.md**](ARCHITECTURE.md) - Structure et design patterns de la librairie
  - Core components
  - Services REST API
  - WebSocket
  - Exception handling
  - Patterns utilisés

### Modèles et sérialisation
- 📗 [**MODELS_GUIDE.md**](MODELS_GUIDE.md) - Guide complet des modèles ⭐ **Recommandé**
  - Introduction aux modèles
  - DirectusModelBuilder (parsing JSON type-safe)
  - DirectusMapBuilder (construction fluide de Maps)
  - Exemples avancés (relations, champs calculés, validation)
  - Registry Pattern
  - Annotations
  - Bonnes pratiques

- 🎯 [**MODEL_SIMPLIFICATION.md**](MODEL_SIMPLIFICATION.md) - Pourquoi pas complètement automatique ? ⭐ **Important**
  - Limitations techniques Dart/Flutter
  - Comparaison des approches (Builders vs build_runner vs réflexion)
  - Pourquoi les Builders sont le meilleur choix
  - Exemples de simplification maximale
  - Service wrapper pour abstraction complète

- 📙 [**DIRECTUS_MODEL.md**](DIRECTUS_MODEL.md) - Classe de base DirectusModel
  - Héritage et méthodes
  - Helpers de parsing
  - Gestion automatique des champs standards

### Migration
- 🔄 [**MIGRATION_BUILDERS.md**](MIGRATION_BUILDERS.md) - Guide de migration v0.1.0 → v0.2.0
  - Pourquoi migrer
  - Étapes détaillées
  - Exemples de migration (simple, relations, types complexes)
  - Cas particuliers
  - Checklist de migration

### Contribution
- 🤝 [**CONTRIBUTING.md**](CONTRIBUTING.md) - Comment contribuer au projet
  - Standards de code
  - Processus de développement
  - Tests
  - Documentation

### Release notes
- 🎉 [**RELEASE_0.2.0.md**](RELEASE_0.2.0.md) - Nouveautés de la version 0.2.0
  - Builder Pattern
  - Statistiques
  - Impact sur le code
  - Exemples d'usage

## 🎯 Parcours recommandé

### Débutant
1. Lire le [README.md](../README.md) pour comprendre les bases
2. Parcourir le [MODELS_GUIDE.md](MODELS_GUIDE.md) section "Introduction"
3. Tester les exemples dans `example/`

### Intermédiaire
1. Lire [ARCHITECTURE.md](ARCHITECTURE.md) pour comprendre la structure
2. Étudier [MODELS_GUIDE.md](MODELS_GUIDE.md) en détail
3. Créer vos propres modèles avec les Builders

### Avancé
1. Lire [DIRECTUS_MODEL.md](DIRECTUS_MODEL.md) pour les détails internes
2. Consulter [CONTRIBUTING.md](CONTRIBUTING.md) pour contribuer
3. Proposer des améliorations via Pull Request

### Migration depuis v0.1.0
1. Lire [RELEASE_0.2.0.md](RELEASE_0.2.0.md) pour voir les nouveautés
2. Suivre [MIGRATION_BUILDERS.md](MIGRATION_BUILDERS.md) étape par étape
3. Tester la migration sur un modèle simple d'abord

## 📖 Par sujet

### Authentification
- [README.md](../README.md) - Section "Authentification"
- `example/authentication_example.dart`

### CRUD sur collections
- [README.md](../README.md) - Section "Opérations CRUD"
- [MODELS_GUIDE.md](MODELS_GUIDE.md) - Section "Builders"
- `example/items_crud_example.dart`
- `example/custom_model.dart`

### Modèles personnalisés
- [MODELS_GUIDE.md](MODELS_GUIDE.md) - **Guide complet** ⭐
- [DIRECTUS_MODEL.md](DIRECTUS_MODEL.md) - Détails de la classe de base
- `example/custom_model.dart`
- `example/advanced_builders_example.dart`

### Relations
- [MODELS_GUIDE.md](MODELS_GUIDE.md) - Section "Exemples avancés"
- `example/advanced_builders_example.dart`

### WebSocket et temps réel
- **[WEBSOCKET_GUIDE.md](WEBSOCKET_GUIDE.md)** - 📚 Guide complet WebSocket
  - 18 méthodes helper pour collections système
  - Patterns avancés (chat, notifications, dashboards)
  - Exemples de filtrage et gestion d'erreurs
  - Bonnes pratiques et limitations
- [README.md](../README.md) - Section "WebSocket"
- [ARCHITECTURE.md](ARCHITECTURE.md) - Section "WebSocket"
- `example/websocket_example.dart` - Exemples pratiques

### Tests
- [CONTRIBUTING.md](CONTRIBUTING.md) - Section "Tests"
- `test/` - Tests existants

### Upload de fichiers
- [README.md](../README.md) - Section "Gestion des fichiers"
- [ARCHITECTURE.md](ARCHITECTURE.md) - Section "FilesService"

## 🔍 Recherche rapide

### Je veux...

#### ...créer un modèle simple
→ [MODELS_GUIDE.md](MODELS_GUIDE.md) - Section "DirectusModelBuilder"

#### ...comprendre pourquoi ce n'est pas complètement automatique
→ [MODEL_SIMPLIFICATION.md](MODEL_SIMPLIFICATION.md) ⭐

#### ...parser du JSON complexe
→ [MODELS_GUIDE.md](MODELS_GUIDE.md) - Section "Getters typés"

#### ...construire une Map sans boilerplate
→ [MODELS_GUIDE.md](MODELS_GUIDE.md) - Section "DirectusMapBuilder"

#### ...gérer des relations
→ [MODELS_GUIDE.md](MODELS_GUIDE.md) - Section "Relations many-to-one"

#### ...ajouter des champs calculés
→ [MODELS_GUIDE.md](MODELS_GUIDE.md) - Section "Champs calculés"

#### ...migrer mon code existant
→ [MIGRATION_BUILDERS.md](MIGRATION_BUILDERS.md)

#### ...comprendre l'architecture
→ [ARCHITECTURE.md](ARCHITECTURE.md)

#### ...contribuer au projet
→ [CONTRIBUTING.md](CONTRIBUTING.md)

## 🎓 Ressources externes

- 📚 [Documentation Directus officielle](https://docs.directus.io/)
- 📚 [API Reference Directus](https://docs.directus.io/reference/api/)
- 🐦 [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- 🎨 [Flutter Documentation](https://flutter.dev/docs)

## 💡 Conseils

### Pour la lecture
- Les sections marquées ⭐ sont **recommandées**
- Commencez toujours par le README
- Les exemples sont dans `example/`
- Les tests montrent tous les cas d'usage

### Pour le développement
- Utilisez **toujours** les Builders (DirectusModelBuilder, DirectusMapBuilder)
- Suivez les bonnes pratiques du [MODELS_GUIDE.md](MODELS_GUIDE.md)
- Testez vos modèles avec des round-trips JSON
- Documentez votre code avec dartdoc

### Pour la contribution
- Lisez [CONTRIBUTING.md](CONTRIBUTING.md) en premier
- Regardez les issues GitHub
- Proposez d'abord dans une issue avant un gros PR
- Ajoutez des tests pour toute nouvelle fonctionnalité

## 📝 Changelog

Consultez [../CHANGELOG.md](../CHANGELOG.md) pour l'historique complet des versions.

## ❓ Questions / Support

- **Issues GitHub :** [À configurer]
- **Discussions :** [À configurer]
- **Email :** [À configurer]

---

**fcs_directus** - Documentation complète 📚

Dernière mise à jour : 2024-01-15  
Version : 0.2.0
