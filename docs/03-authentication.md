# Authentication

Guide complet de l'authentification avec fcs_directus.

## 🔐 Modes d'authentification

fcs_directus supporte trois modes d'authentification correspondant aux modes de l'API Directus :

| Mode | Description | Usage |
|------|-------------|-------|
| **JSON** | Tokens retournés dans la réponse JSON | Applications mobiles, SPAs |
| **Cookie** | Refresh token dans cookie httpOnly, access token en JSON | Applications web sécurisées |
| **Session** | Les deux tokens dans cookies httpOnly | Applications web avec sessions |
| **Static Token** | Token permanent généré dans Directus | Services backend, scripts |

## 📋 Configuration

### Mode JSON (défaut)

```dart
final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    authMode: AuthMode.json, // Mode par défaut
  ),
);
```

### Mode Cookie

```dart
final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    authMode: AuthMode.cookie,
  ),
);
```

### Mode Static Token

```dart
final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    authMode: AuthMode.staticToken,
    staticToken: 'your-static-admin-token',
  ),
);
```

## 🔑 Login avec email/password

### Login basique

```dart
try {
  final response = await directus.auth.login(
    email: 'admin@example.com',
    password: 'your-password',
  );
  
  print('✅ Connecté');
  print('Access token: ${response.accessToken}');
  print('Expire dans: ${response.expiresIn} ms');
  print('Refresh token: ${response.refreshToken}');
  
} on DirectusAuthException catch (e) {
  print('❌ Erreur d\'authentification: ${e.message}');
  
  // Gérer les erreurs spécifiques
  if (e.code == 401) {
    print('Email ou mot de passe incorrect');
  }
}
```

### Login avec OTP (Two-Factor Authentication)

Si l'utilisateur a activé la 2FA :

```dart
try {
  final response = await directus.auth.login(
    email: 'admin@example.com',
    password: 'your-password',
    otp: '123456', // Code OTP à 6 chiffres
  );
  
  print('✅ Connecté avec 2FA');
  
} on DirectusAuthException catch (e) {
  if (e.message.contains('OTP')) {
    print('Code OTP invalide ou expiré');
  }
}
```

### Login avec mode spécifique

```dart
// Mode cookie: refresh token dans httpOnly cookie
await directus.auth.login(
  email: 'admin@example.com',
  password: 'your-password',
  mode: AuthMode.cookie,
);
```

## 🎫 Login avec token statique

### Méthode 1 : Configuration initiale

```dart
final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    authMode: AuthMode.staticToken,
    staticToken: 'your-static-token',
  ),
);

// Pas besoin de login, le token est déjà configuré
final items = await directus.items('articles').readMany();
```

### Méthode 2 : Login programmatique

```dart
final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
  ),
);

// Login avec token statique
await directus.auth.loginWithToken('your-static-token');

// Utiliser les services
final items = await directus.items('articles').readMany();
```

### Générer un token statique

1. Connectez-vous à votre instance Directus
2. Allez dans **Settings** → **Access Tokens**
3. Cliquez sur **Create Token**
4. Définissez les permissions et copiez le token généré

⚠️ **Attention** : Les tokens statiques ne peuvent pas être révoqués facilement. Utilisez-les avec précaution et limitez leurs permissions.

## 🔄 Refresh tokens

### Refresh automatique

Par défaut, le client rafraîchit automatiquement l'access token quand il expire :

```dart
// Rien à faire, le refresh est automatique !
final items = await directus.items('articles').readMany();
// Si le token est expiré, il sera automatiquement rafraîchi
```

### Refresh manuel

Si vous devez rafraîchir manuellement :

```dart
try {
  final response = await directus.auth.refresh();
  
  print('Nouveau token: ${response.accessToken}');
  print('Expire dans: ${response.expiresIn} ms');
  
} on DirectusAuthException catch (e) {
  print('Impossible de rafraîchir le token: ${e.message}');
  // L'utilisateur doit se reconnecter
  await directus.auth.login(email: '...', password: '...');
}
```

### Refresh avec token spécifique

```dart
final response = await directus.auth.refresh(
  refreshToken: 'specific-refresh-token',
);
```

## 🚪 Logout

### Logout simple

```dart
await directus.auth.logout();
print('✅ Déconnecté');

// Les tokens sont supprimés, les requêtes suivantes échoueront
try {
  await directus.items('articles').readMany();
} on DirectusAuthException catch (e) {
  print('Non authentifié'); // Attendu après logout
}
```

### Logout avec refresh token

Si vous voulez invalider un refresh token spécifique :

```dart
await directus.auth.logout(
  refreshToken: 'specific-refresh-token',
);
```

## ✅ Vérifier l'état d'authentification

### Méthode 1 : isAuthenticated()

```dart
final isAuth = await directus.auth.isAuthenticated();

if (isAuth) {
  print('✅ Utilisateur connecté');
} else {
  print('❌ Utilisateur non connecté');
}
```

### Méthode 2 : Récupérer l'utilisateur actuel

```dart
try {
  final user = await directus.users.me();
  print('Connecté en tant que: ${user.data?['email']}');
} on DirectusAuthException catch (e) {
  print('Non authentifié');
}
```

## 🔒 Gestion des tokens

### Accéder aux tokens

```dart
// Access token actuel
final accessToken = directus.auth.accessToken;
print('Token: $accessToken');

// Vérifier si un token existe
if (directus.auth.hasAccessToken) {
  print('Token présent');
}
```

### Stocker les tokens

Pour persister les tokens entre les sessions (ex: dans SharedPreferences) :

```dart
import 'package:shared_preferences/shared_preferences.dart';

// Sauvegarder après login
final response = await directus.auth.login(
  email: 'user@example.com',
  password: 'password',
);

final prefs = await SharedPreferences.getInstance();
await prefs.setString('access_token', response.accessToken);
if (response.refreshToken != null) {
  await prefs.setString('refresh_token', response.refreshToken!);
}

// Restaurer au démarrage de l'app
final prefs = await SharedPreferences.getInstance();
final accessToken = prefs.getString('access_token');
final refreshToken = prefs.getString('refresh_token');

if (accessToken != null) {
  await directus.auth.loginWithToken(accessToken);
  // Optionnel: stocker aussi le refresh token dans le client
}
```

### Supprimer les tokens

```dart
await directus.auth.logout();

// Nettoyer aussi le stockage local
final prefs = await SharedPreferences.getInstance();
await prefs.remove('access_token');
await prefs.remove('refresh_token');
```

## 👤 OAuth (Google, GitHub, etc.)

### Lister les providers disponibles

```dart
final providers = await directus.auth.providers();

for (final provider in providers) {
  print('Provider: ${provider.name}');
  print('Icon: ${provider.icon}');
}
// Exemple: ['google', 'github', 'facebook']
```

### Initier le flux OAuth

```dart
// 1. Obtenir l'URL d'authentification
final authUrl = directus.auth.getOAuthUrl(
  provider: 'google',
  redirectUrl: 'https://your-app.com/oauth/callback',
);

// 2. Ouvrir dans un navigateur ou WebView
// (dépend de votre plateforme)
await launchUrl(Uri.parse(authUrl));

// 3. Après redirection, récupérer le code
// Le code est dans les query parameters de l'URL de callback

// 4. Échanger le code contre des tokens
final response = await directus.auth.oauthCallback(
  provider: 'google',
  code: 'authorization-code-from-callback',
);

print('✅ Authentifié via OAuth');
```

## 🔐 Permissions et rôles

### Vérifier les permissions de l'utilisateur

```dart
final user = await directus.users.me();
final roleId = user.data?['role'];

// Obtenir les permissions du rôle
final permissions = await directus.permissions.readMany(
  query: QueryParameters(
    filter: {'role': {'_eq': roleId}},
  ),
);

print('${permissions.data?.length} permissions');
```

### Gérer les erreurs de permissions

```dart
try {
  await directus.items('admin_only_collection').readMany();
} on DirectusAuthException catch (e) {
  if (e.code == 403) {
    print('❌ Vous n\'avez pas la permission d\'accéder à cette ressource');
  }
}
```

## 🔧 Authentification dans une app Flutter

### Provider pattern

```dart
class AuthProvider extends ChangeNotifier {
  final DirectusClient _directus;
  bool _isAuthenticated = false;
  
  AuthProvider(this._directus);
  
  bool get isAuthenticated => _isAuthenticated;
  
  Future<void> login(String email, String password) async {
    try {
      await _directus.auth.login(email: email, password: password);
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> logout() async {
    await _directus.auth.logout();
    _isAuthenticated = false;
    notifyListeners();
  }
  
  Future<void> checkAuth() async {
    _isAuthenticated = await _directus.auth.isAuthenticated();
    notifyListeners();
  }
}
```

### Utilisation avec Provider

```dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      body: authProvider.isAuthenticated
        ? HomeScreen()
        : LoginForm(),
    );
  }
}
```

## 💡 Bonnes pratiques

### 1. Ne jamais hardcoder les credentials

❌ **À éviter** :
```dart
await directus.auth.login(
  email: 'admin@example.com',
  password: 'hardcoded-password',
);
```

✅ **Bon** :
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

await directus.auth.login(
  email: dotenv.env['DIRECTUS_EMAIL']!,
  password: dotenv.env['DIRECTUS_PASSWORD']!,
);
```

### 2. Gérer l'expiration des tokens

```dart
try {
  final items = await directus.items('articles').readMany();
} on DirectusAuthException catch (e) {
  if (e.code == 401) {
    // Token expiré, rafraîchir ou reconnecter
    try {
      await directus.auth.refresh();
      // Réessayer la requête
      final items = await directus.items('articles').readMany();
    } catch (_) {
      // Impossible de rafraîchir, demander reconnexion
      await navigateToLogin();
    }
  }
}
```

### 3. Sécuriser le stockage des tokens

```dart
// Utiliser flutter_secure_storage pour les données sensibles
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

// Sauvegarder
await storage.write(key: 'access_token', value: response.accessToken);

// Lire
final token = await storage.read(key: 'access_token');
```

### 4. Implémenter un timeout de session

```dart
class SessionManager {
  Timer? _sessionTimer;
  final Duration sessionTimeout = Duration(minutes: 30);
  
  void startSession() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(sessionTimeout, () async {
      await directus.auth.logout();
      showSessionExpiredDialog();
    });
  }
  
  void resetTimer() {
    startSession(); // Reset à chaque activité
  }
}
```

## ⚠️ Sécurité

- ✅ Toujours utiliser HTTPS en production
- ✅ Stocker les tokens de manière sécurisée
- ✅ Ne jamais exposer les tokens dans les logs
- ✅ Implémenter un timeout de session
- ✅ Valider les permissions côté serveur (Directus)
- ✅ Utiliser 2FA pour les comptes sensibles
- ⚠️ Limiter les permissions des tokens statiques
- ⚠️ Révoquer les tokens compromis immédiatement

## 🔗 Ressources

- [AuthService API Reference](api-reference/services/auth-service.md)
- [UsersService](api-reference/services/users-service.md)
- [Directus Auth Documentation](https://docs.directus.io/reference/authentication.html)
- [Error Handling](11-error-handling.md)
