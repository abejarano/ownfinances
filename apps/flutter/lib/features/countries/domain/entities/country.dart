class Country {
  final String id;
  final String code;
  final String name;

  Country({
    required this.id,
    required this.code,
    required this.name,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json["countryId"] ?? json["id"],
      code: json["code"],
      name: json["name"],
    );
  }
}
