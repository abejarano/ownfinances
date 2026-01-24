class Bank {
  final String id;
  final String name;
  final String code;
  final String country;
  final String? logoUrl;

  Bank({
    required this.id,
    required this.name,
    required this.code,
    required this.country,
    this.logoUrl,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['bankId'] ?? json['id'],
      name: json['name'],
      code: json['code'],
      country: json['country'],
      logoUrl: json['logoUrl'],
    );
  }
}
