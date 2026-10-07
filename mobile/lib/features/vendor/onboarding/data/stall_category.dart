import '../../../../core/localization/l10n.dart';

/// One food category from `GET /categories`. [slug] is what stall creation accepts.
class StallCategory {
  const StallCategory({required this.slug, required this.name});

  final String slug;
  final String name;

  factory StallCategory.fromJson(Map<String, dynamic> json) {
    return StallCategory(slug: json['slug'] as String, name: json['name'] as String);
  }

  /// The name to show. The server sends English names, so the categories the
  /// app knows are named from the translations by slug; a category the backend
  /// adds later falls back to the server's own name.
  String get label => switch (slug) {
        'kottu' => l10n.categoryKottu,
        'short-eats' => l10n.categoryShortEats,
        'fresh-juice' => l10n.categoryFreshJuice,
        'hoppers' => l10n.categoryHoppers,
        'rice-and-curry' => l10n.categoryRiceAndCurry,
        'bbq-seafood' => l10n.categoryBbqSeafood,
        _ => name,
      };

  /// The emoji beside the name. Only the categories the design shows have one;
  /// anything the backend adds later gets a generic plate rather than a guess.
  String get emoji => _emojiBySlug[slug] ?? '🍽️';

  static const _emojiBySlug = {
    'kottu': '🫓',
    'short-eats': '🥟',
    'fresh-juice': '🥤',
    'hoppers': '🍳',
    'rice-and-curry': '🍛',
    'bbq-seafood': '🍤',
  };
}
