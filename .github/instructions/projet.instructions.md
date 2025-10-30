---
applyTo: '**'
---
Ce projet est une librairie DART destinée à être utilisée dans des applications Flutter. Elle fournit des fonctionnalités pour dialoguer avec un serveur Directus via des requêtes HTTP.
La liste des entrées API de Directus est disponible ici : https://docs.directus.io/reference/api/.
Dans le dossier openapi, vous trouverez tous les fichiers de point d'entrée de l'API Directus au format OpenAPI.

## Fonctionnalités
La librairie Directus doit permettre de gérer toutes les fonctionnalités principales de Directus et également en WebSocket.

In fine dans une application Flutter, pour utiliser cette librairie, il faudra créer des classes de modèles Dart pour représenter les entités Directus, et utiliser les services fournis par la librairie pour effectuer des opérations CRUD (Create, Read, Update, Delete) sur ces entités.

Les classes de modèle darts seront définies par le développeur en fonction des collections Directus utilisées dans son projet. La création de ces classes doit être simple et intuitive et permettre de mapper facilement les données JSON reçues de Directus vers des objets Dart.

## Exigences techniques
- Utilisation au maximum des objets (classes, interfaces, etc.) pour structurer le code.
- Utilisation de la programmation asynchrone pour gérer les requêtes HTTP.
- Gestion des erreurs et des exceptions de manière appropriée.
- Documentation claire et concise pour chaque méthode et classe.
- Tests unitaires pour valider le bon fonctionnement des différentes fonctionnalités.
- Utilisation de packages Dart/Flutter populaires et bien maintenus pour les requêtes HTTP (comme `http` ou `dio`), la sérialisation JSON (comme `json_serializable`), et la gestion des WebSockets (comme `web_socket_channel`).
- Respect des bonnes pratiques de développement Dart/Flutter.
- Aucun code JSON manuel dans les classes métiers (cf Filter).