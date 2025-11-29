# Authentification

Ce guide détaille toutes les méthodes d'authentification supportées par la librairie.

## Modes d'authentification

La librairie supporte plusieurs modes d'authentification :

| Mode | Description | Cas d'utilisation |
|------|-------------|-------------------|
| Email/Password | Authentification classique avec JWT | Applications utilisateur |
| Token statique | Token API sans expiration | Scripts, backends |
| OAuth/SSO | Authentification via providers externes | Google, GitHub, etc. |
| Session | Restauration d'une session existante | Persistance de login |

## Login email/password

### Authentification basique

```dart
final response = await client.auth.login(
  email: 'user@example.com',
  password: 'your-password',
);

// AuthResponse contient :
print(response.accessToken);   // JWT pour les requêtes
print(response.refreshToken);  // Token pour rafraîchir
print(response.expiresIn);     // Durée de validité (secondes)
```

### Avec Two-Factor Authentication (2FA)

Si l'utilisateur a activé le 2FA, un code OTP est requis :

```dart
try {
  final response = await client.auth.login(
    email: 'user@example.com',
    password: 'your-password',
  );
} on DirectusAuthException catch (e) {
  if (e.isOtpRequired) {
    // Demander le code à l'utilisateur
    final otp = await showOtpDialog();
    
    // Retenter avec le code OTP
    final response = await client.auth.login(
      email: 'user@example.com',
      password: 'your-password',
      otp: otp,
    );
  }
}
```

### Mode d'authentification

Vous pouvez spécifier le mode d'authentification :

```dart
// Mode session (stockage côté serveur)
final response = await client.auth.login(
  email: 'user@example.com',
  password: 'your-password',
  mode: AuthMode.session,
);

// Mode JSON (défaut, stockage côté client)
final response = await client.auth.login(
  email: 'user@example.com',
  password: 'your-password',
  mode: AuthMode.json,
);
```

## Token statique

Pour les scripts ou applications backend qui n'ont pas besoin de refresh :

```dart
await client.auth.loginWithToken('votre-token-statique');

// Vérifier que le token est configuré
print(client.auth.accessToken); // 'votre-token-statique'

// Le client utilisera ce token pour toutes les requêtes
final users = await client.users.getUsers();
```

> **Note** : Les tokens statiques n'expirent pas et ne peuvent pas être rafraîchis.

## OAuth / SSO

### Lister les providers disponibles

```dart
final providers = await client.auth.listOAuthProviders();

for (final provider in providers) {
  print('Provider: ${provider.name}');
  print('Icon: ${provider.icon}');
}
// Exemple: google, github, microsoft, etc.
```

### Obtenir l'URL d'authentification

```dart
final authUrl = client.auth.getOAuthUrl(
  'google',
  redirect: 'myapp://oauth-callback', // URI de callback de votre app
);

// Ouvrir dans un navigateur ou WebView
await launchUrl(authUrl);
```

### Gérer le callback OAuth

```dart
// Dans votre handler de deep link / callback
void handleOAuthCallback(Uri uri) async {
  // L'URI contient les tokens dans les paramètres
  final accessToken = uri.queryParameters['access_token'];
  final refreshToken = uri.queryParameters['refresh_token'];
  
  if (accessToken != null) {
    // Configurer manuellement les tokens
    client.auth.setTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
```

## Gestion de session

### Refresh automatique

Le client gère automatiquement le refresh des tokens expirés. Aucune action n'est requise de votre part.

Vous pouvez être notifié lors des refresh via le callback :

```dart
final config = DirectusConfig(
  baseUrl: 'https://your-directus-instance.com',
  onTokenRefreshed: (accessToken, refreshToken) async {
    // Persister les nouveaux tokens
    await secureStorage.write(key: 'access_token', value: accessToken);
    if (refreshToken != null) {
      await secureStorage.write(key: 'refresh_token', value: refreshToken);
    }
  },
);
```

### Refresh manuel

Si vous voulez forcer un refresh :

```dart
await client.auth.refresh();
```

### Restaurer une session

Au redémarrage de l'application, restaurez la session :

```dart
// Récupérer le token persisté
final savedRefreshToken = await secureStorage.read(key: 'refresh_token');

if (savedRefreshToken != null) {
  try {
    await client.auth.restoreSession(savedRefreshToken);
    print('Session restaurée');
  } on DirectusAuthException catch (e) {
    print('Session expirée, reconnexion requise');
    await secureStorage.deleteAll();
  }
}
```

## Gestion des erreurs d'authentification

### Callback d'erreur

Configurez un callback pour gérer les erreurs d'authentification globalement :

```dart
final config = DirectusConfig(
  baseUrl: 'https://your-directus-instance.com',
  onAuthError: (exception) async {
    // Erreur de refresh impossible
    if (exception.errorCode == 'TOKEN_REFRESH_FAILED') {
      await secureStorage.deleteAll();
      navigateToLogin();
    }
    
    // Token expiré
    if (exception.isInvalidToken) {
      navigateToLogin();
    }
    
    // Compte suspendu
    if (exception.isUserSuspended) {
      showSuspendedDialog();
    }
  },
);
```

### Gestion locale

```dart
try {
  await client.auth.login(email: email, password: password);
} on DirectusAuthException catch (e) {
  if (e.isInvalidCredentials) {
    showError('Email ou mot de passe incorrect');
  } else if (e.isOtpRequired) {
    showOtpScreen();
  } else if (e.isUserSuspended) {
    showError('Votre compte est suspendu');
  } else if (e.isInvalidOtp) {
    showError('Code 2FA incorrect');
  } else {
    showError(e.message);
  }
}
```

## Déconnexion

```dart
await client.auth.logout();

// Nettoyer les tokens persistés
await secureStorage.deleteAll();
```

## Vérifier l'état d'authentification

```dart
// Token actuel
final token = client.auth.accessToken;
final isLoggedIn = token != null && token.isNotEmpty;

// Refresh token
final refreshToken = client.auth.refreshToken;

// Nettoyer manuellement (sans appel API)
client.clearTokens();
```

## Two-Factor Authentication (2FA)

### Générer un secret 2FA

Pour un utilisateur qui veut activer le 2FA :

```dart
final tfaSecret = await client.users.generateTwoFactorSecret('user-password');

if (tfaSecret != null) {
  print('Secret: ${tfaSecret.secret}');      // Pour les apps TOTP
  print('QR Code: ${tfaSecret.qrCodeUrl}');  // URL data: pour affichage
  
  // Afficher le QR code à l'utilisateur
  // Il doit le scanner avec son app d'authentification
}
```

### Activer le 2FA

Après que l'utilisateur ait scanné le QR code :

```dart
// L'utilisateur entre le code de son app
final otp = '123456';

await client.users.enableTwoFactor(
  secret: tfaSecret.secret,
  otp: otp,
);

print('2FA activé !');
```

### Désactiver le 2FA

```dart
await client.users.disableTwoFactor('123456'); // Code OTP requis
```

## Inscription et vérification email

### Inscription publique

Si l'inscription publique est activée sur Directus :

```dart
await client.users.register(
  email: 'new@example.com',
  password: 'secure-password',
  firstName: 'John',
  lastName: 'Doe',
);

// Un email de vérification est envoyé
print('Vérifiez votre email');
```

### Vérifier l'email

```dart
// Le token est dans le lien de l'email
await client.users.verifyEmail('verification-token');
```

## Réinitialisation de mot de passe

### Demander une réinitialisation

```dart
await client.auth.requestPasswordReset(
  email: 'user@example.com',
  resetUrl: 'https://your-app.com/reset-password', // Optionnel
);

// Un email est envoyé avec le lien
```

### Réinitialiser le mot de passe

```dart
// Le token est dans le lien de l'email
await client.auth.resetPassword(
  token: 'reset-token-from-email',
  password: 'new-secure-password',
);
```

## Bonnes pratiques

### 1. Toujours persister les tokens

```dart
onTokenRefreshed: (accessToken, refreshToken) async {
  await FlutterSecureStorage().write(key: 'refresh_token', value: refreshToken);
},
```

### 2. Restaurer au démarrage

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final client = DirectusClient(config);
  final token = await storage.read(key: 'refresh_token');
  
  if (token != null) {
    try {
      await client.auth.restoreSession(token);
    } catch (e) {
      // Session invalide
    }
  }
  
  runApp(MyApp(client: client));
}
```

### 3. Gérer les erreurs centralement

Utilisez `onAuthError` pour une gestion cohérente des erreurs d'authentification dans toute l'application.

### 4. Nettoyer à la déconnexion

```dart
Future<void> logout() async {
  await client.auth.logout();
  await storage.deleteAll();
  client.clearTokens();
}
```
