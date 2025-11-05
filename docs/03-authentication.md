# Authentication

Guide complet de l'authentification avec fcs_directus.

## 🔐 Modes d'authentification

fcs_directus supporte trois modes d'authentification correspondant aux modes de l'API Directus :

| Mode | Description | Usage |
|------|-------------|-------|
| **JSON** (défaut) | Tokens retournés dans la réponse JSON | Applications mobiles, SPAs |
| **Cookie** | Refresh token dans cookie httpOnly, access token en JSON | Applications web sécurisées |
| **Session** | Les deux tokens dans cookies httpOnly | Applications web avec sessions |

⚠️ **Note** : Le mode par défaut est `json`. Le mode est spécifié **lors du login**, pas dans la configuration du client.

## 📋 Configuration

La configuration du client ne nécessite pas de spécifier le mode d'authentification :

```dart
final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
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
  
  // Gérer les erreurs spécifiques avec helpers
  if (e.isInvalidCredentials) {
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

### Login en 2 étapes avec détection OTP

Pour une meilleure expérience utilisateur, vous pouvez implémenter un flux en 2 étapes qui détecte automatiquement si l'OTP est requis :

#### Étape 1 : Première tentative de connexion

```dart
Future<bool> attemptLogin(String email, String password) async {
  try {
    // Tentative de connexion sans OTP
    final response = await directus.auth.login(
      email: email,
      password: password,
    );
    
    print('✅ Connexion réussie sans 2FA');
    return true; // Login réussi
    
  } on DirectusAuthException catch (e) {
    // Vérifier si l'erreur indique qu'un OTP est requis
    if (e.isOtpRequired) {
      print('🔐 2FA activée, code OTP requis');
      return false; // OTP requis, passer à l'étape 2
    }
    
    // Autre erreur d'authentification
    print('❌ Erreur: ${e.message}');
    if (e.isInvalidCredentials) {
      throw Exception('Email ou mot de passe incorrect');
    }
    rethrow;
  }
}
```

#### Étape 2 : Connexion avec OTP

```dart
Future<void> loginWithOtp(String email, String password, String otp) async {
  try {
    final response = await directus.auth.login(
      email: email,
      password: password,
      otp: otp,
    );
    
    print('✅ Connexion 2FA réussie');
    
  } on DirectusAuthException catch (e) {
    // Gérer les erreurs spécifiques à l'OTP
    if (e.isOtpRequired) {
      throw Exception('Code OTP invalide ou expiré');
    } else if (e.isInvalidCredentials) {
      throw Exception('Email ou mot de passe incorrect');
    }
    
    print('❌ Erreur lors de la connexion: ${e.message}');
    rethrow;
  }
}
```

#### Exemple complet : Flux d'authentification

```dart
class AuthenticationFlow {
  final DirectusClient directus;
  
  AuthenticationFlow(this.directus);
  
  /// Tente de se connecter et retourne true si OTP est requis
  Future<LoginResult> login(String email, String password, {String? otp}) async {
    try {
      final response = await directus.auth.login(
        email: email,
        password: password,
        otp: otp,
      );
      
      return LoginResult.success(
        accessToken: response.accessToken,
        expiresIn: response.expiresIn,
      );
      
    } on DirectusAuthException catch (e) {
      // OTP requis
      if (otp == null && e.isOtpRequired) {
        return LoginResult.otpRequired();
      }
      
      // OTP invalide
      if (otp != null && e.isOtpRequired) {
        return LoginResult.invalidOtp();
      }
      
      // Credentials invalides
      if (e.isInvalidCredentials) {
        return LoginResult.invalidCredentials();
      }
      
      // Autre erreur
      return LoginResult.error(e.message);
    } catch (e) {
      return LoginResult.error(e.toString());
    }
  }
}

/// Résultat d'une tentative de login
class LoginResult {
  final LoginStatus status;
  final String? accessToken;
  final int? expiresIn;
  final String? errorMessage;
  
  LoginResult.success({required this.accessToken, required this.expiresIn})
    : status = LoginStatus.success,
      errorMessage = null;
  
  LoginResult.otpRequired()
    : status = LoginStatus.otpRequired,
      accessToken = null,
      expiresIn = null,
      errorMessage = null;
  
  LoginResult.invalidOtp()
    : status = LoginStatus.invalidOtp,
      accessToken = null,
      expiresIn = null,
      errorMessage = 'Code OTP invalide ou expiré';
  
  LoginResult.invalidCredentials()
    : status = LoginStatus.invalidCredentials,
      accessToken = null,
      expiresIn = null,
      errorMessage = 'Email ou mot de passe incorrect';
  
  LoginResult.error(this.errorMessage)
    : status = LoginStatus.error,
      accessToken = null,
      expiresIn = null;
}

enum LoginStatus {
  success,
  otpRequired,
  invalidOtp,
  invalidCredentials,
  error,
}
```

#### Utilisation dans une interface Flutter

```dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _showOtpField = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  late final AuthenticationFlow _authFlow;
  
  @override
  void initState() {
    super.initState();
    _authFlow = AuthenticationFlow(directus);
  }
  
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final result = await _authFlow.login(
      _emailController.text,
      _passwordController.text,
      otp: _showOtpField ? _otpController.text : null,
    );
    
    setState(() {
      _isLoading = false;
    });
    
    switch (result.status) {
      case LoginStatus.success:
        // Naviguer vers l'écran principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
        break;
        
      case LoginStatus.otpRequired:
        setState(() {
          _showOtpField = true;
          _errorMessage = 'Entrez votre code 2FA';
        });
        break;
        
      case LoginStatus.invalidOtp:
        setState(() {
          _errorMessage = 'Code OTP invalide ou expiré';
          _otpController.clear();
        });
        break;
        
      case LoginStatus.invalidCredentials:
        setState(() {
          _errorMessage = 'Email ou mot de passe incorrect';
          _showOtpField = false;
          _otpController.clear();
        });
        break;
        
      case LoginStatus.error:
        setState(() {
          _errorMessage = result.errorMessage ?? 'Erreur de connexion';
        });
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connexion')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _errorMessage,
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_showOtpField, // Désactiver si OTP demandé
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
              enabled: !_showOtpField, // Désactiver si OTP demandé
            ),
            
            // Champ OTP (visible uniquement si requis)
            if (_showOtpField) ...[
              SizedBox(height: 16),
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'Code 2FA (6 chiffres)',
                  hintText: '123456',
                  prefixIcon: Icon(Icons.security),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showOtpField = false;
                    _otpController.clear();
                    _errorMessage = null;
                  });
                },
                child: Text('Modifier email/mot de passe'),
              ),
            ],
            
            SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                ? CircularProgressIndicator()
                : Text(_showOtpField ? 'Valider le code' : 'Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Détection d'erreur : Types d'erreurs possibles

```dart
try {
  await directus.auth.login(
    email: email,
    password: password,
    otp: otp,
  );
} on DirectusAuthException catch (e) {
  // Utiliser les helpers de DirectusAuthException
  if (e.isOtpRequired) {
    print('❌ Code OTP invalide ou expiré');
    // Demander à l'utilisateur de réessayer
  } else if (e.isInvalidCredentials) {
    print('❌ Email ou mot de passe incorrect');
    // Effacer les champs de connexion
  } else if (e.isInvalidToken) {
    print('❌ Token invalide ou expiré');
    // Demander une reconnexion
  } else if (e.isUserSuspended) {
    print('❌ Compte utilisateur suspendu');
    // Afficher un message approprié
  }
} on DirectusRateLimitException catch (e) {
  print('⏳ Trop de tentatives, veuillez réessayer plus tard');
  // Bloquer temporairement les tentatives
} on DirectusServerException catch (e) {
  print('🔥 Erreur serveur, veuillez réessayer');
} on DirectusException catch (e) {
  print('❌ Erreur: ${e.message}');
  
  // Vérifier un code d'erreur spécifique
  if (e.errorCode == DirectusErrorCode.invalidOtp.code) {
    print('Code OTP invalide');
  }
  
  // Informations supplémentaires dans extensions
  if (e.extensions != null) {
    print('Code erreur: ${e.extensions!['code']}');
    print('Détails: ${e.extensions!['reason']}');
  }
}
```

### Utilisation de DirectusErrorCode

La librairie fournit des helpers pour vérifier facilement les types d'erreurs :

```dart
try {
  await directus.auth.login(email: email, password: password);
} on DirectusAuthException catch (e) {
  // Utiliser les propriétés helpers (recommandé)
  if (e.isOtpRequired) {
    print('OTP requis');
  }
  
  if (e.isInvalidCredentials) {
    print('Identifiants invalides');
  }
  
  if (e.isInvalidToken) {
    print('Token invalide ou expiré');
  }
  
  if (e.isUserSuspended) {
    print('Utilisateur suspendu');
  }
  
  // Ou vérifier directement avec DirectusErrorCode
  if (e.hasErrorCode(DirectusErrorCode.invalidOtp)) {
    print('Code OTP invalide');
  }
  
  if (e.hasErrorCode(DirectusErrorCode.invalidCredentials)) {
    print('Credentials invalides');
  }
  
  if (e.hasErrorCode(DirectusErrorCode.tokenExpired)) {
    print('Token expiré');
  }
}
```

### Codes d'erreur d'authentification disponibles

| Helper | DirectusErrorCode | Description |
|--------|-------------------|-------------|
| `isOtpRequired` | `invalidOtp` | OTP requis ou invalide (2FA) |
| `isInvalidCredentials` | `invalidCredentials` | Email/mot de passe incorrect |
| `isInvalidToken` | `invalidToken`, `tokenExpired` | Token invalide ou expiré |
| `isUserSuspended` | `userSuspended` | Compte utilisateur suspendu |


### Messages d'erreur personnalisés

```dart
String getAuthErrorMessage(DirectusAuthException e, {bool hasOtp = false}) {
  // Utiliser les helpers pour une détection plus fiable
  if (e.isOtpRequired) {
    if (hasOtp) {
      return 'Le code 2FA est invalide ou a expiré. Veuillez réessayer.';
    } else {
      return 'Authentification à deux facteurs requise.';
    }
  }
  
  if (e.isInvalidCredentials) {
    return 'Email ou mot de passe incorrect.';
  }
  
  if (e.isInvalidToken) {
    return 'Votre session a expiré. Veuillez vous reconnecter.';
  }
  
  if (e.isUserSuspended) {
    return 'Votre compte a été suspendu. Contactez un administrateur.';
  }
  
  // Fallback sur le message d'origine
  return 'Erreur de connexion: ${e.message}';
}

// Utilisation
try {
  await directus.auth.login(email: email, password: password, otp: otp);
} on DirectusAuthException catch (e) {
  final message = getAuthErrorMessage(e, hasOtp: otp != null);
  showErrorDialog(context, message);
} on DirectusRateLimitException catch (e) {
  showErrorDialog(context, 
    'Trop de tentatives de connexion. Veuillez patienter quelques minutes.');
} on DirectusServerException catch (e) {
  showErrorDialog(context, 
    'Erreur serveur. Veuillez réessayer ultérieurement.');
}
```

### Login avec mode spécifique

Par défaut, le mode `json` est utilisé (tokens dans la réponse JSON). Vous pouvez spécifier un autre mode :

```dart
// Mode JSON (défaut) : tokens dans la réponse JSON
await directus.auth.login(
  email: 'admin@example.com',
  password: 'your-password',
  mode: AuthMode.json, // Optionnel, c'est la valeur par défaut
);

// Mode cookie : refresh token dans httpOnly cookie
await directus.auth.login(
  email: 'admin@example.com',
  password: 'your-password',
  mode: AuthMode.cookie,
);

// Mode session : les deux tokens dans des cookies httpOnly
await directus.auth.login(
  email: 'admin@example.com',
  password: 'your-password',
  mode: AuthMode.session,
);
```

## 🎫 Login avec token statique

Les tokens statiques sont utiles pour :
- Scripts automatisés et tâches planifiées (cron jobs)
- Services backend server-to-server
- Intégrations avec des systèmes externes
- Applications qui n'ont pas d'interface utilisateur

### Utilisation d'un token statique

```dart
final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
  ),
);

// Login avec token statique
await directus.auth.loginWithToken('your-static-token');

// Utiliser les services normalement
final items = await directus.items('articles').readMany();
```

### Générer un token statique dans Directus

#### Via l'interface admin

1. Connectez-vous à votre instance Directus (interface admin)
2. Allez dans **Settings** (⚙️) → **Access Tokens**
3. Cliquez sur **Create Token** (+)
4. Configurez le token :
   - **Name** : Nom descriptif (ex: "API Backend Service")
   - **Policy** : Sélectionnez la politique de permissions appropriée
   - **Expiration** : Définissez une date d'expiration (optionnel mais recommandé)
5. Cliquez sur **Save**
6. **Copiez immédiatement le token** : Il ne sera plus visible après cette étape
7. Stockez-le de manière sécurisée (variables d'environnement, secrets manager)

#### Via l'API Directus

Vous pouvez aussi créer un token via l'API après vous être authentifié en tant qu'admin :

```dart
// 1. Se connecter en tant qu'admin
await directus.auth.login(
  email: 'admin@example.com',
  password: 'admin-password',
);

// 2. Créer un utilisateur système ou utiliser un utilisateur existant
// 3. Créer une politique avec les bonnes permissions
// 4. Générer un token pour cet utilisateur

// Note: Cette approche nécessite des droits d'administration
```

### Cas d'usage : Service backend

```dart
import 'package:fcs_directus/fcs_directus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> syncData() async {
  // Charger le token depuis les variables d'environnement
  final token = dotenv.env['DIRECTUS_STATIC_TOKEN']!;
  
  final directus = DirectusClient(
    DirectusConfig(
      baseUrl: dotenv.env['DIRECTUS_URL']!,
    ),
  );
  
  // Authentification avec le token statique
  await directus.auth.loginWithToken(token);
  
  // Effectuer des opérations
  final articles = await directus.items('articles').readMany(
    query: QueryParameters(
      filter: Filter.eq('status', 'published'),
    ),
  );
  
  print('${articles.data?.length} articles synchronisés');
  
  directus.dispose();
}
```

### Vérifier si le token est valide

```dart
try {
  await directus.auth.loginWithToken('your-token');
  
  // Tester avec une requête simple
  await directus.users.me();
  
  print('✅ Token valide');
} on DirectusAuthException catch (e) {
  print('❌ Token invalide: ${e.message}');
}
```

### Bonnes pratiques pour les tokens statiques

✅ **À faire** :
- Stocker les tokens dans des variables d'environnement (`.env`)
- Utiliser un secrets manager en production (AWS Secrets Manager, Azure Key Vault, etc.)
- Définir des permissions minimales (principe du moindre privilège)
- Définir une date d'expiration raisonnable
- Utiliser des noms descriptifs pour identifier l'usage du token
- Révoquer immédiatement les tokens compromis
- Faire une rotation régulière des tokens (tous les 3-6 mois)

❌ **À éviter** :
- Hardcoder les tokens dans le code source
- Commiter les tokens dans le contrôle de version (Git)
- Donner des permissions administrateur complètes
- Partager les tokens par email ou chat non sécurisé
- Réutiliser le même token pour plusieurs services
- Utiliser des tokens sans expiration en production

### Différence token statique vs session token

| Caractéristique | Token statique | Session token (login) |
|----------------|----------------|----------------------|
| **Génération** | Manuellement via admin | Automatiquement au login |
| **Expiration** | Optionnelle, configurable | Courte durée (15-30 min) |
| **Refresh** | Non applicable | Refresh token disponible |
| **Révocation** | Manuel via admin | Logout automatique |
| **Usage** | Services backend, scripts | Applications utilisateur |
| **Sécurité** | Permanence = risque élevé | Rotation automatique |

⚠️ **Important** : Les tokens statiques ne peuvent pas être révoqués automatiquement. Si un token est compromis, vous devez :
1. Le supprimer manuellement dans Directus (Settings → Access Tokens)
2. Générer un nouveau token
3. Mettre à jour votre application avec le nouveau token

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
// ⚠️ IMPORTANT : Sauvegarder le REFRESH token, pas l'access token
// L'access token expire rapidement (15-30 min)
// Le refresh token dure plus longtemps (7 jours+)
if (response.refreshToken != null) {
  await prefs.setString('refresh_token', response.refreshToken!);
}

// Restaurer au démarrage de l'app
final prefs = await SharedPreferences.getInstance();
final refreshToken = prefs.getString('refresh_token');

if (refreshToken != null) {
  // ✅ CORRECT : Utiliser restoreSession() pour restaurer avec un refresh token
  final auth = await directus.auth.restoreSession(refreshToken);
  print('Session restaurée, expire dans ${auth.expiresIn}s');
}
```

**Différence importante** :
- `loginWithToken(token)` → Pour les **tokens statiques** uniquement (access tokens permanents)
- `restoreSession(refreshToken)` → Pour restaurer une session avec un **refresh token**

```dart
// ❌ INCORRECT : Utiliser loginWithToken avec un refresh token
await directus.auth.loginWithToken(response.refreshToken); // Ne fonctionne PAS

// ✅ CORRECT : Utiliser restoreSession pour restaurer une session
await directus.auth.restoreSession(response.refreshToken);
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
} on DirectusPermissionException catch (e) {
  print('❌ Vous n\'avez pas la permission d\'accéder à cette ressource');
  print('Code: ${e.statusCode}'); // 403
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
  if (e.isInvalidToken) {
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
