import 'package:fcs_directus/fcs_directus.dart';

/// Exemple des méthodes utilitaires des Property Wrappers
///
/// Démontre toutes les méthodes sympas ajoutées à chaque type de wrapper

class Product extends DirectusModel {
  @override
  String get itemName => 'products';

  Product(super.data);
  Product.empty() : super.empty();

  late final name = stringValue('name');
  late final description = stringValue('description');
  late final price = doubleValue('price');
  late final stock = intValue('stock');
  late final discount = doubleValue('discount');
  late final active = boolValue('active', defaultValue: true);
  late final featured = boolValue('featured');
  late final publishedAt = dateTimeValue('published_at');
  late final tags = listValue<String>('tags');

  @override
  String toString() => 'Product($name, €${price.toStringAsFixed(2)})';
}

void main() {
  DirectusModel.registerFactory<Product>((data) => Product(data));

  print('🎯 Méthodes Utilitaires des Property Wrappers\n');

  // === 1. StringProperty ===
  print('📝 1. StringProperty - Méthodes utilitaires');

  final product = Product({
    'id': '1',
    'name': '  laptop hp  ',
    'description': 'Un ordinateur portable',
    'price': 999.99,
    'stock': 10,
    'discount': 0.15,
    'active': true,
    'featured': false,
    'tags': ['electronics', 'computers'],
  });

  print('   Nom initial: "${product.name}"');
  print('   Length: ${product.name.length}');
  print('   isEmpty: ${product.name.isEmpty}');

  // Trim
  product.name.trim();
  print('   Après trim(): "${product.name}"');

  // Uppercase/Lowercase
  product.name.toUpperCase();
  print('   Après toUpperCase(): "${product.name}"');

  product.name.toLowerCase();
  print('   Après toLowerCase(): "${product.name}"');

  // Capitalize
  product.name.capitalize();
  print('   Après capitalize(): "${product.name}"');

  // Append/Prepend
  product.name.append(' Elite');
  print('   Après append(" Elite"): "${product.name}"');

  product.name.prepend('Super ');
  print('   Après prepend("Super "): "${product.name}"');

  // Replace
  product.name.replace('Super', 'Mega');
  print('   Après replace("Super", "Mega"): "${product.name}"');

  // Contains
  print('   Contains "Elite": ${product.name.contains("Elite")}');

  // Clear
  product.name.clear();
  print(
    '   Après clear(): "${product.name}" (isEmpty: ${product.name.isEmpty})\n',
  );

  // === 2. IntProperty ===
  print('🔢 2. IntProperty - Méthodes utilitaires');

  product.name.set('Laptop');
  print('   Stock initial: ${product.stock}');

  // Increment/Decrement
  product.stock.increment();
  print('   Après increment(): ${product.stock}');

  product.stock.decrement();
  print('   Après decrement(): ${product.stock}');

  product.stock.incrementBy(5);
  print('   Après incrementBy(5): ${product.stock}');

  product.stock.decrementBy(3);
  print('   Après decrementBy(3): ${product.stock}');

  // Multiply/Divide
  product.stock.multiplyBy(2);
  print('   Après multiplyBy(2): ${product.stock}');

  product.stock.divideBy(3);
  print('   Après divideBy(3): ${product.stock}');

  // Clamp
  product.stock.set(-5);
  print('   Stock négatif: ${product.stock}');
  product.stock.clampMin(0);
  print('   Après clampMin(0): ${product.stock}');

  product.stock.set(150);
  product.stock.clampMax(100);
  print('   Après clampMax(100): ${product.stock}');

  product.stock.set(-10);
  product.stock.clamp(0, 50);
  print('   Après clamp(0, 50) avec -10: ${product.stock}');

  // Checks
  product.stock.set(10);
  print('   isPositive: ${product.stock.isPositive}');
  print('   isNegative: ${product.stock.isNegative}');
  print('   isZero: ${product.stock.isZero}');

  // Abs
  product.stock.set(-15);
  product.stock.abs();
  print('   Après abs() sur -15: ${product.stock}');

  // Reset
  product.stock.reset();
  print('   Après reset(): ${product.stock} (valeur par défaut)\n');

  // === 3. DoubleProperty ===
  print('💰 3. DoubleProperty - Méthodes utilitaires');

  print('   Prix initial: ${product.price}');

  // Increment/Decrement
  product.price.increment();
  print('   Après increment(): ${product.price}');

  product.price.decrementBy(50.5);
  print('   Après decrementBy(50.5): ${product.price}');

  // Multiply/Divide
  product.price.multiplyBy(1.2);
  print('   Après multiplyBy(1.2): ${product.price}');

  product.price.divideBy(2);
  print('   Après divideBy(2): ${product.price}');

  // Round operations
  product.price.set(123.456);
  print('   Prix avec décimales: ${product.price}');

  final priceCopy = product.price.value;
  product.price.round();
  print('   Après round(): ${product.price}');

  product.price.set(priceCopy);
  product.price.ceil();
  print('   Après ceil(): ${product.price}');

  product.price.set(priceCopy);
  product.price.floor();
  print('   Après floor(): ${product.price}');

  product.price.set(priceCopy);
  product.price.truncate();
  print('   Après truncate(): ${product.price}');

  // Formatting
  product.price.set(999.99);
  print('   Format 2 décimales: ${product.price.toStringAsFixed(2)}');
  print('   Format 0 décimale: ${product.price.toStringAsFixed(0)}');

  // Clamp
  product.price.set(5000);
  product.price.clamp(100, 2000);
  print('   Après clamp(100, 2000) sur 5000: ${product.price}');

  // Checks
  print('   isPositive: ${product.price.isPositive}');

  // Abs
  product.price.set(-50);
  product.price.abs();
  print('   Après abs() sur -50: ${product.price}\n');

  // === 4. BoolProperty ===
  print('🔘 4. BoolProperty - Méthodes utilitaires');

  print('   Active initial: ${product.active}');
  print('   Featured initial: ${product.featured}');

  // SetTrue/SetFalse
  product.active.setFalse();
  print('   Après active.setFalse(): ${product.active}');

  product.active.setTrue();
  print('   Après active.setTrue(): ${product.active}');

  // Toggle
  product.featured.toggle();
  print('   Après featured.toggle() (était false): ${product.featured}');

  product.featured.toggle();
  print('   Après featured.toggle() (était true): ${product.featured}');

  // Reset
  product.active.set(false);
  product.active.reset();
  print(
    '   Après active.reset(): ${product.active} (valeur par défaut: true)\n',
  );

  // === 5. DateTimeProperty ===
  print('📅 5. DateTimeProperty - Méthodes utilitaires');

  // SetNow
  product.publishedAt.setNow();
  print('   Après setNow(): ${product.publishedAt}');

  // SetToday
  product.publishedAt.setToday();
  print('   Après setToday(): ${product.publishedAt}');

  // Add operations
  product.publishedAt.addDays(7);
  print('   Après addDays(7): ${product.publishedAt}');

  product.publishedAt.addHours(-2);
  print('   Après addHours(-2): ${product.publishedAt}');

  product.publishedAt.addMinutes(30);
  print('   Après addMinutes(30): ${product.publishedAt}');

  // Checks
  product.publishedAt.set(DateTime(2024, 1, 1));
  print('   Date: ${product.publishedAt}');
  print('   isPast: ${product.publishedAt.isPast}');
  print('   isFuture: ${product.publishedAt.isFuture}');
  print('   isToday: ${product.publishedAt.isToday}');

  product.publishedAt.setToday();
  print('   Après setToday() → isToday: ${product.publishedAt.isToday}\n');

  // === 6. ListProperty ===
  print('📋 6. ListProperty - Méthodes utilitaires (déjà existantes)');

  print('   Tags: ${product.tags}');
  print('   Length: ${product.tags.length}');
  print('   isEmpty: ${product.tags.isEmpty}');

  product.tags.add('promotion');
  print('   Après add("promotion"): ${product.tags}');

  product.tags.removeItem('computers');
  print('   Après removeItem("computers"): ${product.tags}');

  product.tags.clear();
  print(
    '   Après clear(): ${product.tags} (isEmpty: ${product.tags.isEmpty})\n',
  );

  // === 7. Résumé ===
  print('✨ Résumé des méthodes utilitaires:');
  print('');
  print('   StringProperty:');
  print('   • clear(), isEmpty, isNotEmpty, length');
  print('   • append(), prepend(), trim()');
  print('   • toUpperCase(), toLowerCase(), capitalize()');
  print('   • contains(), replace()');
  print('');
  print('   IntProperty:');
  print('   • increment(), decrement(), incrementBy(), decrementBy()');
  print('   • multiplyBy(), divideBy()');
  print('   • clamp(), clampMin(), clampMax()');
  print('   • isPositive, isNegative, isZero');
  print('   • abs(), reset()');
  print('');
  print('   DoubleProperty:');
  print('   • increment(), decrement(), incrementBy(), decrementBy()');
  print('   • multiplyBy(), divideBy()');
  print('   • round(), ceil(), floor(), truncate()');
  print('   • clamp(), abs()');
  print('   • toStringAsFixed()');
  print('   • isPositive, isNegative, isZero');
  print('');
  print('   BoolProperty:');
  print('   • setTrue(), setFalse()');
  print('   • toggle()');
  print('   • reset()');
  print('');
  print('   DateTimeProperty:');
  print('   • setNow(), setToday()');
  print('   • addDays(), addHours(), addMinutes()');
  print('   • isPast, isFuture, isToday');
  print('   • format()');
  print('');
  print('   ListProperty:');
  print('   • add(), removeItem(), clear()');
  print('   • length, isEmpty, isNotEmpty');
}
