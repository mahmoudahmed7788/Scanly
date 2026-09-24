class DocumentModel {
  String id;
  String title;
  String date;
  String type;
  String? filePath;
  bool isFavorite;
  String? lastOpened;
  String? storagePath;

  // Original page images used to create/edit the PDF.
  List<String> imagePaths;

  DocumentModel({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.filePath,
    this.isFavorite = false,
    this.lastOpened,
    this.storagePath,
    this.imagePaths = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'type': type,
      'filePath': filePath,
      'isFavorite': isFavorite,
      'lastOpened': lastOpened,
      'storagePath': storagePath,
      'imagePaths': imagePaths,
    };
  }

  factory DocumentModel.fromMap(Map map) {
    final rawImagePaths = map['imagePaths'];

    List<String> parsedImagePaths = [];

    if (rawImagePaths is List) {
      parsedImagePaths = rawImagePaths
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return DocumentModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled Document',
      date: map['date']?.toString() ?? '',
      type: map['type']?.toString() ?? 'pdf',
      filePath: map['filePath']?.toString(),
      isFavorite: map['isFavorite'] == true,
      lastOpened: map['lastOpened']?.toString(),
      storagePath: map['storagePath']?.toString(),
      imagePaths: parsedImagePaths,
    );
  }
}