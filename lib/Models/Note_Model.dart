class NotePageModel {
  final String id;
  List<dynamic> quillData;
  bool isLandscape;

  NotePageModel({
    required this.id,
    required this.quillData,
    this.isLandscape = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quillData': quillData,
      'isLandscape': isLandscape,
    };
  }

  factory NotePageModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return NotePageModel(
      id: json['id'] as String? ??
          DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
      quillData: List<dynamic>.from(
        json['quillData'] ?? [],
      ),
      isLandscape:
          json['isLandscape'] as bool? ?? false,
    );
  }
}

class NoteModel {
  final String id;
  String title;
  List<dynamic> quillData;
  List<NotePageModel> pages;
  bool isPinned;
  int colorValue;
  List<String> imagePaths;
  List<PdfAttachment> pdfs;
  DateTime createdAt;
  DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.quillData,
    List<NotePageModel>? pages,
    this.isPinned = false,
    this.colorValue = 0xFFFFF4E6,
    this.imagePaths = const [],
    this.pdfs = const [],
    required this.createdAt,
    required this.updatedAt,
  }) : pages = pages ??
            [
              NotePageModel(
                id: DateTime.now()
                    .microsecondsSinceEpoch
                    .toString(),
                quillData: quillData,
              ),
            ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'quillData': quillData,
      'pages': pages
          .map((page) => page.toJson())
          .toList(),
      'isPinned': isPinned,
      'colorValue': colorValue,
      'imagePaths': imagePaths,
      'pdfs': pdfs
          .map((pdf) => pdf.toJson())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NoteModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final oldQuillData = List<dynamic>.from(
      json['quillData'] ?? [],
    );

    final rawPages = json['pages'];

    List<NotePageModel> loadedPages;

    if (rawPages is List &&
        rawPages.isNotEmpty) {
      loadedPages = rawPages
          .map(
            (page) => NotePageModel.fromJson(
              Map<String, dynamic>.from(page),
            ),
          )
          .toList();
    } else {
      loadedPages = [
        NotePageModel(
          id: DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
          quillData: oldQuillData,
        ),
      ];
    }

    final firstPageData =
        loadedPages.first.quillData;

    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      quillData: firstPageData.isNotEmpty
          ? firstPageData
          : oldQuillData,
      pages: loadedPages,
      isPinned:
          json['isPinned'] as bool? ?? false,
      colorValue:
          json['colorValue'] as int? ??
              0xFFFFF4E6,
      imagePaths: List<String>.from(
        json['imagePaths'] ?? [],
      ),
      pdfs: (json['pdfs'] as List? ?? [])
          .map(
            (pdf) => PdfAttachment.fromJson(
              Map<String, dynamic>.from(pdf),
            ),
          )
          .toList(),
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String,
      ),
    );
  }
}

class PdfAttachment {
  final String path;
  final String name;
  final int size;

  PdfAttachment({
    required this.path,
    required this.name,
    required this.size,
  });

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'size': size,
    };
  }

  factory PdfAttachment.fromJson(
    Map<String, dynamic> json,
  ) {
    return PdfAttachment(
      path: json['path'] as String? ?? '',
      name: json['name'] as String? ?? '',
      size: json['size'] as int? ?? 0,
    );
  }
}
