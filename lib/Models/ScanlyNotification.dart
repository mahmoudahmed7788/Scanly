// ============================================================
// SCANLY NOTIFICATION MODEL
// ============================================================

class ScanlyNotification {
  final String id;
  final String title;
  final String body;
  final String date;
  bool isRead;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  ScanlyNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.isRead = false,
  });

  // ==========================================================
  // TO MAP
  // ==========================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'date': date,
      'isRead': isRead,
    };
  }

  // ==========================================================
  // FROM MAP
  // ==========================================================

  factory ScanlyNotification.fromMap(
    Map<String, dynamic> map,
  ) {
    return ScanlyNotification(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Scanly',
      body: map['body']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      isRead: map['isRead'] == true,
    );
  }
}