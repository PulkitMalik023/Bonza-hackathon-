class PuzzleContent {
  const PuzzleContent({
    required this.id,
    required this.category,
    required this.words,
    this.enabled = true,
  });

  final int id;
  final String category;
  final List<String> words;
  final bool enabled;

  factory PuzzleContent.fromJson(Map<String, dynamic> json) {
    final wordsJson = json['words'];
    if (wordsJson is! List) {
      throw FormatException('Expected "words" to be a list for puzzle ${json['id']}');
    }

    final rawId = json['id'];
    final id = switch (rawId) {
      int value => value,
      String value => int.tryParse(value) ??
          (throw FormatException('Invalid puzzle id: $value')),
      _ => throw FormatException('Invalid puzzle id type for puzzle $rawId'),
    };

    return PuzzleContent(
      id: id,
      category: json['category'] as String,
      words: wordsJson.map((word) => word as String).toList(),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
