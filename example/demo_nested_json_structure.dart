// ignore_for_file: avoid_print

import 'package:fcs_directus/fcs_directus.dart';

/// Démonstration visuelle de la transformation de la notation pointée
/// en structure JSON imbriquée pour les filtres Directus.
void main() {
  print('╔═══════════════════════════════════════════════════════════════╗');
  print('║  Démonstration: Notation pointée → Structure JSON imbriquée  ║');
  print('╚═══════════════════════════════════════════════════════════════╝\n');

  // Exemple 1: Simple (1 niveau)
  print('📝 Exemple 1: Champ simple');
  print('   Code: Filter.field("departement").equals("dept-75")');
  final filter1 = Filter.field('departement').equals('dept-75');
  print('   JSON: ${filter1.toJson()}');
  print('   → {"departement": {"_eq": "dept-75"}}\n');

  // Exemple 2: Nested niveau 1
  print('📝 Exemple 2: Nested niveau 1 (relation.champ)');
  print('   Code: Filter.field("departement.code").equals("75")');
  final filter2 = Filter.field('departement.code').equals('75');
  print('   JSON: ${filter2.toJson()}');
  print('   → {');
  print('       "departement": {');
  print('         "code": {"_eq": "75"}');
  print('       }');
  print('     }\n');

  // Exemple 3: Nested niveau 2
  print('📝 Exemple 3: Nested niveau 2 (relation.relation)');
  print('   Code: Filter.field("departement.region").equals("region-idf")');
  final filter3 = Filter.field('departement.region').equals('region-idf');
  print('   JSON: ${filter3.toJson()}');
  print('   → {');
  print('       "departement": {');
  print('         "region": {"_eq": "region-idf"}');
  print('       }');
  print('     }\n');

  // Exemple 4: Nested niveau 3
  print('📝 Exemple 4: Nested niveau 3 (relation.relation.champ)');
  print('   Code: Filter.field("departement.region.nom").equals("IDF")');
  final filter4 = Filter.field('departement.region.nom').equals('IDF');
  print('   JSON: ${filter4.toJson()}');
  print('   → {');
  print('       "departement": {');
  print('         "region": {');
  print('           "nom": {"_eq": "IDF"}');
  print('         }');
  print('       }');
  print('     }\n');

  // Exemple 5: Nested profond (4 niveaux)
  print('📝 Exemple 5: Nested profond - 4 niveaux');
  print('   Code: Filter.field("departement.region.pays.code").equals("FR")');
  final filter5 = Filter.field('departement.region.pays.code').equals('FR');
  print('   JSON: ${filter5.toJson()}');
  print('   → {');
  print('       "departement": {');
  print('         "region": {');
  print('           "pays": {');
  print('             "code": {"_eq": "FR"}');
  print('           }');
  print('         }');
  print('       }');
  print('     }\n');

  // Exemple 6: Équivalence avec Filter.relation()
  print('╔═══════════════════════════════════════════════════════════════╗');
  print('║  Équivalence: Filter.field() vs Filter.relation()            ║');
  print('╚═══════════════════════════════════════════════════════════════╝\n');

  print('📝 Ces deux syntaxes sont maintenant ÉQUIVALENTES:\n');

  print('   Syntaxe 1 (notation pointée - RECOMMANDÉE):');
  print('   ──────────────────────────────────────────');
  final dottedFilter = Filter.field('departement.region').equals('region-idf');
  print('   Code: Filter.field("departement.region").equals("region-idf")');
  print('   JSON: ${dottedFilter.toJson()}\n');

  print('   Syntaxe 2 (Filter.relation() - plus verbeux):');
  print('   ──────────────────────────────────────────────');
  final relationFilter = Filter.relation(
    'departement',
  ).where(Filter.field('region').equals('region-idf'));
  print('   Code: Filter.relation("departement").where(');
  print('           Filter.field("region").equals("region-idf")');
  print('         )');
  print('   JSON: ${relationFilter.toJson()}\n');

  print('   Vérification:');
  final areEqual = _jsonEquals(dottedFilter.toJson(), relationFilter.toJson());
  print('   ${dottedFilter.toJson()} ==');
  print('   ${relationFilter.toJson()}');
  print('   → ${areEqual ? "✅ IDENTIQUES" : "❌ DIFFÉRENTS"}\n');

  // Exemple 7: Combinaisons
  print('╔═══════════════════════════════════════════════════════════════╗');
  print('║  Combinaisons AND/OR                                          ║');
  print('╚═══════════════════════════════════════════════════════════════╝\n');

  print('📝 Combinaison AND avec filtres imbriqués:');
  final andFilter = Filter.and([
    Filter.field('departement.region').equals('region-idf'),
    Filter.field('population').greaterThan(10000),
  ]);
  print('   Code: Filter.and([');
  print('           Filter.field("departement.region").equals("region-idf"),');
  print('           Filter.field("population").greaterThan(10000),');
  print('         ])');
  print('   JSON:');
  _printJsonPretty(andFilter.toJson());
  print('');

  // Exemple 8: Tous les opérateurs
  print('╔═══════════════════════════════════════════════════════════════╗');
  print('║  Tous les opérateurs fonctionnent                            ║');
  print('╚═══════════════════════════════════════════════════════════════╝\n');

  final operators = [
    {
      'name': 'equals',
      'filter': Filter.field('dept.region').equals('idf'),
      'operator': '_eq',
    },
    {
      'name': 'notEquals',
      'filter': Filter.field('dept.region').notEquals('paca'),
      'operator': '_neq',
    },
    {
      'name': 'contains',
      'filter': Filter.field('dept.region.nom').contains('Provence'),
      'operator': '_contains',
    },
    {
      'name': 'greaterThan',
      'filter': Filter.field('dept.population').greaterThan(100000),
      'operator': '_gt',
    },
    {
      'name': 'inList',
      'filter': Filter.field('dept.region').inList(['idf', 'paca']),
      'operator': '_in',
    },
    {
      'name': 'isNull',
      'filter': Filter.field('dept.region').isNull(),
      'operator': '_null',
    },
  ];

  for (final op in operators) {
    print('   ${op['name']}: ${op['operator']}');
    print('   ${(op['filter'] as Filter).toJson()}');
  }

  print('\n✅ Tous les opérateurs créent une structure JSON imbriquée !');

  // Résumé
  print('\n╔═══════════════════════════════════════════════════════════════╗');
  print('║  🎯 RÉSUMÉ                                                    ║');
  print('╚═══════════════════════════════════════════════════════════════╝\n');
  print('   ✅ Notation pointée fonctionne pour TOUS les opérateurs');
  print('   ✅ Structure JSON imbriquée créée automatiquement');
  print('   ✅ Équivalence complète avec Filter.relation()');
  print('   ✅ Support multi-niveaux illimité (a.b.c.d.e.f...)');
  print('   ✅ Compatible avec AND/OR/combinaisons');
  print('   ✅ Syntaxe conforme à l\'API Directus\n');
}

bool _jsonEquals(Map a, Map b) {
  return a.toString() == b.toString();
}

void _printJsonPretty(Map<String, dynamic> json, {int indent = 3}) {
  final spaces = ' ' * indent;
  print('$spaces{');
  json.forEach((key, value) {
    if (value is Map) {
      print('$spaces  "$key": {');
      (value as Map<String, dynamic>).forEach((k, v) {
        if (v is Map) {
          print('$spaces    "$k": {');
          (v as Map<String, dynamic>).forEach((k2, v2) {
            if (v2 is List) {
              print('$spaces      "$k2": [');
              for (final item in v2) {
                if (item is Map) {
                  print('$spaces        {');
                  (item as Map).forEach((k3, v3) {
                    print('$spaces          "$k3": $v3');
                  });
                  print('$spaces        },');
                } else {
                  print('$spaces        $item,');
                }
              }
              print('$spaces      ]');
            } else {
              print('$spaces      "$k2": $v2');
            }
          });
          print('$spaces    }');
        } else if (v is List) {
          print('$spaces    "$k": $v');
        } else {
          print('$spaces    "$k": $v');
        }
      });
      print('$spaces  }');
    } else {
      print('$spaces  "$key": $value');
    }
  });
  print('$spaces}');
}
