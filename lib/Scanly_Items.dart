class ScanlyItem {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final String route;
  final String? data;
  final int createdAt;

  const ScanlyItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.route,
    this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'type': type,
      'route': route,
      'data': data,
      'createdAt': createdAt,
    };
  }

  factory ScanlyItem.fromJson(Map<String, dynamic> json) {
    return ScanlyItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      route: json['route'] as String? ?? '/',
      data: json['data'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
    );
  }
}