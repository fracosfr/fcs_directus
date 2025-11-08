# Diagnostic erreur FORBIDDEN sur champ de relation Directus

## ❌ Erreur rencontrée

```
DirectusPermissionException [FORBIDDEN]: 
You don't have permission to access field "departement.region" 
in collection "brigade" or it does not exist. 
Queried in root.
```

## 🔍 Causes possibles et solutions

### 1. Permissions insuffisantes (CAUSE LA PLUS FRÉQUENTE)

#### Diagnostic
Directus vérifie les permissions **à chaque niveau** de la chaîne de relations :
- `brigade` → OK
- `brigade.departement` → OK
- `brigade.departement.region` → ❌ PROBLÈME ICI

#### Solution
Dans l'admin Directus :

1. **Allez dans** : `Paramètres > Rôles et permissions > [Votre rôle]`

2. **Vérifiez les permissions** sur ces 3 collections :

   **Collection `brigade`** :
   - ✅ Permission READ
   - ✅ Accès au champ `departement` (ou à tous les champs)

   **Collection `departement`** :
   - ✅ Permission READ
   - ✅ Accès au champ `region` (ou à tous les champs)
   - ⚠️ Si ce n'est pas coché : AJOUTER la permission

   **Collection `region`** :
   - ✅ Permission READ  
   - ✅ Accès aux champs que vous interrogez
   - ⚠️ Si ce n'est pas coché : AJOUTER la permission

3. **Testez** après modification

#### Screenshot des permissions attendues
```
✓ brigade
  ├─ READ: All fields (ou au moins "departement")
  
✓ departement  
  ├─ READ: All fields (ou au moins "region")
  
✓ region
  ├─ READ: All fields
```

---

### 2. Champ ou relation inexistant

#### Diagnostic
Le champ `region` n'existe pas dans la collection `departement`, ou la relation n'est pas configurée.

#### Vérification
1. **Allez dans** : `Paramètres > Modèle de données > departement`
2. **Recherchez** le champ `region`
3. **Vérifiez** :
   - ✅ Le champ existe
   - ✅ C'est bien une relation (Many-to-One vers `region`)
   - ✅ L'interface est "Relation" ou "Related Values"

#### Solution si le champ n'existe pas
Créez la relation :
```
1. Ouvrez la collection "departement"
2. Créez un nouveau champ de type "Many to One"
3. Nom du champ: "region"
4. Collection liée: "region"
```

---

### 3. Différence entre Filter et Fields

#### ⚠️ Attention à la syntaxe

**Pour FILTRER sur une relation** :
```dart
## 3. Syntaxe des filtres vs fields

⚠️ **Important** : Il y a une différence subtile entre la syntaxe des `fields` et des `filter`.

### Fields (récupération de données)

Pour **récupérer** des champs de relations, on utilise la notation pointée directe :

```dart
QueryParameters(
  fields: ['id', 'nom', 'departement.region.nom'],
  // Ceci récupère les données : OK avec la notation pointée
)
```

### Filter (filtrage)

Pour **filtrer** sur des relations, la librairie transforme automatiquement la notation pointée en structure imbriquée :

```dart
// Code Dart
Filter.field('departement.region').equals(regionId)

// Devient le JSON suivant (structure imbriquée)
{
  "departement": {
    "region": {
      "_eq": "region-idf"
    }
  }
}
```

✅ **La librairie gère cette transformation automatiquement** - vous n'avez qu'à utiliser la notation pointée et elle créera la bonne structure JSON.

### Erreur courante

Si vous voyez l'erreur `"You don't have permission to access field 'departement.region'"`, cela signifie généralement qu'il manque la permission **READ** sur la collection `region`, pas sur le champ `departement.region` lui-même.
```

**Pour CHARGER les données de la relation** :
```dart
// ✅ CORRECT - Inclure dans fields
query: QueryParameters(
  fields: ['*', 'departement.*', 'departement.region.*'],
)
```

#### Exemple complet correct
```dart
final brigades = await client.items('brigade').readMany(
  query: QueryParameters(
    // Filtre sur la relation
    filter: Filter.field('departement.region').equals(regionId),
    
    // Charger les données des relations
    fields: ['*', 'departement.*', 'departement.region.*'],
  ),
);
```

---

### 4. Utilisation de RelationFilter pour les relations complexes

Si le filtre simple ne fonctionne pas, essayez avec `Filter.relation()` :

```dart
## 4. Alternative: Filter.relation()

Si vous préférez une syntaxe plus explicite, `Filter.relation()` produit exactement la même structure JSON que la notation pointée :

```dart
// Ces deux syntaxes sont équivalentes et produisent le même JSON :

// Notation pointée (recommandée - plus concise)
Filter.field('departement.region').equals(regionId)

// Filter.relation() (plus verbeux mais plus explicite)
Filter.relation('departement').where(
  Filter.field('region').equals(regionId)
)

// Les deux génèrent :
{
  "departement": {
    "region": {
      "_eq": "region-id"
    }
  }
}
```

✅ **Utilisez la notation pointée** - elle est plus simple et génère automatiquement la bonne structure.
```

---

### 5. Token d'authentification expiré ou invalide

#### Diagnostic
Le token utilisé n'a plus les permissions nécessaires.

#### Solution
```dart
// Reconnecter
await client.auth.login(
  email: 'user@example.com',
  password: 'password',
);

// Ou rafraîchir le token
await client.auth.refresh();
```

---

### 6. Permissions basées sur des règles (Custom Permissions)

#### Diagnostic
Vos permissions incluent des règles conditionnelles qui bloquent l'accès.

#### Vérification
Dans `Paramètres > Rôles et permissions > [Votre rôle] > region` :
- Vérifiez s'il y a des **"Custom Permissions"**
- Vérifiez les **"Item Permissions"** (filtres sur les éléments)
- Vérifiez les **"Field Permissions"** (restrictions sur certains champs)

#### Solution
Ajustez ou supprimez les règles restrictives si nécessaire.

---

## 🔧 Débogage étape par étape

### Étape 1: Vérifier les permissions de base

```dart
try {
  // Test 1: Lire brigade sans relation
  final brigades = await client.items('brigade').readMany(
    query: QueryParameters(
      fields: ['id', 'nom'],
      limit: 1,
    ),
  );
  print('✓ Lecture brigade OK');
  
  // Test 2: Lire brigade avec departement
  final brigadesWithDept = await client.items('brigade').readMany(
    query: QueryParameters(
      fields: ['id', 'nom', 'departement.nom'],
      limit: 1,
    ),
  );
  print('✓ Lecture brigade.departement OK');
  
  // Test 3: Lire brigade avec departement.region
  final brigadesWithRegion = await client.items('brigade').readMany(
    query: QueryParameters(
      fields: ['id', 'nom', 'departement.region.nom'],
      limit: 1,
    ),
  );
  print('✓ Lecture brigade.departement.region OK');
  
} catch (e) {
  print('✗ Erreur à l\'étape: $e');
  // L'erreur vous indiquera exactement où se situe le problème
}
```

### Étape 2: Tester les permissions directes

```dart
try {
  // Test direct sur la collection region
  final regions = await client.items('region').readMany(
    query: QueryParameters(limit: 1),
  );
  print('✓ Lecture region directe OK');
} catch (e) {
  print('✗ Pas de permission sur region: $e');
  print('→ Ajoutez la permission READ sur la collection region');
}
```

### Étape 3: Vérifier le filtre

```dart
try {
  // Sans filtre
  final test1 = await client.items('brigade').readMany(
    query: QueryParameters(
      fields: ['*'],
      limit: 1,
    ),
  );
  print('✓ Sans filtre: OK');
  
  // Avec filtre sur departement.region
  final test2 = await client.items('brigade').readMany(
    query: QueryParameters(
      filter: Filter.field('departement.region').equals('region-id'),
      fields: ['*'],
      limit: 1,
    ),
  );
  print('✓ Avec filtre: OK');
  
} catch (e) {
  print('✗ Erreur avec filtre: $e');
}
```

---

## ✅ Checklist de résolution

- [ ] Vérifier les permissions READ sur `region`
- [ ] Vérifier les permissions READ sur `departement` (champ `region`)
- [ ] Vérifier que la relation `departement.region` existe
- [ ] Tester la lecture directe de `region`
- [ ] Tester la lecture de `brigade` avec `departement.region.*` dans fields
- [ ] Vérifier le token d'authentification
- [ ] Vérifier les custom permissions / règles conditionnelles
- [ ] Tester avec un rôle Admin pour confirmer que c'est un problème de permissions

---

## 🎯 Solution rapide (la plus probable)

**Dans 90% des cas, le problème est :**

1. Allez dans **Paramètres > Rôles et permissions**
2. Sélectionnez votre rôle
3. Trouvez la collection **`region`**
4. Activez la permission **READ** (lecture)
5. Cochez **"All Fields"** ou au moins les champs que vous interrogez
6. **Enregistrez**
7. **Testez à nouveau**

---

## 📞 Si le problème persiste

Vérifiez dans les logs Directus (côté serveur) pour plus de détails :
```bash
docker logs directus  # ou le nom de votre conteneur
```

Ou activez le mode debug dans votre client :
```dart
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://api.blue.fracos.fr',
    enableLogging: true,  // ← Active les logs détaillés
  ),
);
```
