# Correction: Notation pointée dans les filtres

## 🔧 Changement important

La notation pointée dans `Filter.field()` **crée maintenant automatiquement une structure JSON imbriquée** conforme à la syntaxe Directus.

## ✅ Avant vs Après

### ❌ Avant (incorrect)

```dart
Filter.field('departement.region').equals('region-idf')
```

Générait (INCORRECT pour Directus) :
```json
{
  "departement.region": {
    "_eq": "region-idf"
  }
}
```

### ✅ Après (correct)

```dart
Filter.field('departement.region').equals('region-idf')
```

Génère maintenant (CORRECT pour Directus) :
```json
{
  "departement": {
    "region": {
      "_eq": "region-idf"
    }
  }
}
```

## 🎯 Pourquoi ce changement ?

Directus nécessite une **structure JSON imbriquée** pour filtrer correctement sur les relations. La notation pointée `"departement.region"` comme clé directe ne fonctionnait pas avec les permissions et les relations.

## 📝 Équivalence avec Filter.relation()

Ces deux syntaxes sont maintenant **strictement équivalentes** :

```dart
// Notation pointée (recommandée - concise)
Filter.field('departement.region').equals('region-idf')

// Filter.relation() (plus verbeux)
Filter.relation('departement').where(
  Filter.field('region').equals('region-idf')
)
```

Les deux génèrent exactement le même JSON :
```json
{
  "departement": {
    "region": {
      "_eq": "region-idf"
    }
  }
}
```

## 🔍 Détails techniques

### Implementation

La classe `OperatorFilter` détecte maintenant la présence de `.` dans le nom du champ et construit récursivement une structure JSON imbriquée :

```dart
class OperatorFilter extends Filter {
  @override
  Map<String, dynamic> toJson() {
    // Si le nom du champ contient un point (notation imbriquée),
    // on crée une structure JSON imbriquée pour les filtres sur relations
    if (_fieldName.contains('.')) {
      return _buildNestedFilter(_fieldName.split('.'), _operator, _value);
    }

    return {
      _fieldName: {_operator: _value},
    };
  }

  Map<String, dynamic> _buildNestedFilter(
    List<String> parts,
    String operator,
    dynamic value,
  ) {
    if (parts.length == 1) {
      return {
        parts[0]: {operator: value}
      };
    }

    final firstPart = parts.first;
    final remainingParts = parts.sublist(1);

    return {
      firstPart: _buildNestedFilter(remainingParts, operator, value),
    };
  }
}
```

### Exemples de transformation

| Code Dart | Structure JSON générée |
|-----------|----------------------|
| `Filter.field('dept').equals('75')` | `{"dept": {"_eq": "75"}}` |
| `Filter.field('dept.code').equals('75')` | `{"dept": {"code": {"_eq": "75"}}}` |
| `Filter.field('dept.region').equals('idf')` | `{"dept": {"region": {"_eq": "idf"}}}` |
| `Filter.field('dept.region.nom').equals('IDF')` | `{"dept": {"region": {"nom": {"_eq": "IDF"}}}}` |
| `Filter.field('a.b.c.d').equals('x')` | `{"a": {"b": {"c": {"d": {"_eq": "x"}}}}}` |

## ✅ Tests

Tous les tests ont été mis à jour et passent :
- 18 tests de filtres imbriqués
- Vérification de la structure JSON pour tous les opérateurs
- Équivalence entre notation pointée et `Filter.relation()`

```bash
flutter test test/nested_field_filters_test.dart
# 00:01 +18: All tests passed!
```

## 🐛 Résolution du problème de permissions

Ce changement résout l'erreur courante :

```
DirectusPermissionException [FORBIDDEN]: 
You don't have permission to access field "departement.region" 
in collection "brigade" or it does not exist.
```

**Cause** : Directus ne reconnaissait pas `"departement.region"` comme clé de filtre et le rejetait.

**Solution** : La structure imbriquée `{"departement": {"region": {...}}}` est correctement interprétée par Directus qui vérifie alors les permissions au bon niveau (collection `region`).

## 📚 Documentation mise à jour

- ✅ `docs/nested-field-filters.md` - Guide complet
- ✅ `docs/troubleshooting-permissions.md` - Diagnostic des erreurs
- ✅ `example/example_nested_field_filters.dart` - Exemples pratiques
- ✅ `test/nested_field_filters_test.dart` - Tests complets

## 🚀 Impact sur votre code

### ✅ Pas de changement nécessaire

Si vous utilisiez déjà la notation pointée, **votre code continue de fonctionner** - il va juste maintenant générer le JSON correct !

```dart
// Votre code existant
Filter.field('departement.region').equals(regionId)

// Fonctionne maintenant correctement avec Directus !
```

### ⚠️ Si vous aviez des workarounds

Si vous aviez créé des workarounds pour contourner le problème, vous pouvez maintenant les supprimer et utiliser simplement la notation pointée.

## 📞 Besoin d'aide ?

Consultez :
- `docs/troubleshooting-permissions.md` pour les erreurs de permissions
- `docs/nested-field-filters.md` pour le guide complet
- `example/debug_permissions.dart` pour diagnostiquer les problèmes
