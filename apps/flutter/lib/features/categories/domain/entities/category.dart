class Category {
  final String id;
  final String name;
  final String kind;
  final String? parentId;
  final String? color;
  final String? icon;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.parentId,
    required this.color,
    required this.icon,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json["categoryId"] ?? json["id"]) as String,
      name: json["name"] as String,
      kind: json["kind"] as String,
      parentId: json["parentId"] as String?,
      color: json["color"] as String?,
      icon: json["icon"] as String?,
      isActive: json["isActive"] as bool? ?? true,
    );
  }
}
