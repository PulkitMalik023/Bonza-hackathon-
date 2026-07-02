class PuzzleDefinition {
  const PuzzleDefinition({
    required this.id,
    required this.category,
    required this.words,
  });

  final String id;
  final String category;
  final List<String> words;

  factory PuzzleDefinition.fromJson(Map<String, dynamic> json) {
    final wordsJson = json['words'];
    if (wordsJson is! List) {
      throw FormatException('Expected "words" to be a list for puzzle ${json['id']}');
    }

    return PuzzleDefinition(
      id: json['id'] as String,
      category: json['category'] as String,
      words: wordsJson.map((word) => word as String).toList(),
    );
  }
}
