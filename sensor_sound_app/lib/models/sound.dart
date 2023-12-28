class Sound {
  final int id; // Adjust based on actual API response properties
  final String name;
  final String username;
  final List tags;

  Sound(
      {required this.id,
      required this.name,
      required this.username,
      required this.tags}); // Adjust constructor accordingly

  factory Sound.fromJson(Map<String, dynamic> json) {
    return Sound(
        id: json['id'],
        name: json['name'],
        username: json['username'],
        tags: json['tags']);
  }
}