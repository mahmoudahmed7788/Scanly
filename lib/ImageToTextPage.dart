import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scanly/DocumentModel.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';

class ImageToTextPage extends StatefulWidget {
  const ImageToTextPage({super.key});

  @override
  State<ImageToTextPage> createState() =>
      _ImageToTextPageState();
}

class _ImageToTextPageState
    extends State<ImageToTextPage> {
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _textController =
      TextEditingController();

  XFile? _selectedImage;

  bool _isExtracting = false;
  bool _isSpeaking = false;

  String _selectedLanguage = 'ara+eng';

  final List<Map<String, String>> _languages = [
    {
      'name': 'Arabic + English',
      'code': 'ara+eng',
    },
    {
      'name': 'Arabic',
      'code': 'ara',
    },
    {
      'name': 'English',
      'code': 'eng',
    },
    {
      'name': 'French',
      'code': 'fra',
    },
    {
      'name': 'German',
      'code': 'deu',
    },
    {
      'name': 'Spanish',
      'code': 'spa',
    },
  ];

  @override
  void initState() {
    super.initState();

    _initializeTts();
  }

  @override
  void dispose() {
    _textController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);

    _flutterTts.setStartHandler(() {
      if (!mounted) return;

      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setCancelHandler(() {
      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setErrorHandler((message) {
      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null) return;

      await _flutterTts.stop();

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _textController.clear();
        _isSpeaking = false;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to select image.',
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image == null) return;

      await _flutterTts.stop();

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _textController.clear();
        _isSpeaking = false;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to take photo.',
      );
    }
  }

  Future<void> _extractText() async {
    if (_selectedImage == null) {
      _showMessage(
        'Please select an image first.',
      );
      return;
    }

    if (_isExtracting) {
      return;
    }

    FocusScope.of(context).unfocus();

    await _flutterTts.stop();

    if (!mounted) return;

    setState(() {
      _isExtracting = true;
      _isSpeaking = false;
    });

    try {
      final result =
          await TesseractOcr.extractText(
        _selectedImage!.path,
        language:
            _selectedLanguage,
      );

      final text = result.trim();

      if (!mounted) return;

      setState(() {
        _textController.text = text;
      });

      if (text.isEmpty) {
        _showMessage(
          'No text was detected in this image.',
        );
        return;
      }

      await _saveOcrDocument(text);

      if (!mounted) return;

      _showMessage(
        'Text extracted and saved to Documents.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to extract text from this image.',
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isExtracting = false;
      });
    }
  }

  Future<void> _saveOcrDocument(
    String text,
  ) async {
    final documentsDirectory =
        await DocumentStorage
            .getDocumentsDirectory();

    final timestamp =
        DateTime.now()
            .millisecondsSinceEpoch;

    final fileName =
        'OCR_$timestamp.txt';

    final filePath =
        '${documentsDirectory.path}/$fileName';

    final file = File(filePath);

    await file.writeAsString(
      text,
      flush: true,
    );

    final document = DocumentModel(
      id: filePath.hashCode.toString(),
      title: 'OCR $timestamp',
      date: DateTime.now()
          .toIso8601String(),
      type: 'text',
      filePath: filePath,
    );

    await DocumentStorage.saveDocument(
      document,
    );
  }

  Future<void> _copyText() async {
    final text =
        _textController.text.trim();

    if (text.isEmpty) {
      _showMessage(
        'There is no text to copy.',
      );
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: text,
      ),
    );

    if (!mounted) return;

    _showMessage(
      'Text copied to clipboard.',
    );
  }

  Future<void> _toggleSpeech() async {
    final text =
        _textController.text.trim();

    if (text.isEmpty) {
      _showMessage(
        'There is no text to read.',
      );
      return;
    }

    if (_isSpeaking) {
      await _flutterTts.stop();

      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });

      return;
    }

    try {
      if (_selectedLanguage == 'ara' ||
          _selectedLanguage == 'ara+eng') {
        await _flutterTts.setLanguage(
          'ar-SA',
        );
      } else {
        await _flutterTts.setLanguage(
          'en-US',
        );
      }

      await _flutterTts.speak(text);
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to read the text aloud.',
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  String _languageName() {
    final language = _languages.firstWhere(
      (item) =>
          item['code'] == _selectedLanguage,
      orElse: () => {
        'name': 'Arabic + English',
        'code': 'ara+eng',
      },
    );

    return language['name'] ?? 'Arabic + English';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Text & Voice',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),

              const SizedBox(height: 22),

              _buildImageSection(theme),

              const SizedBox(height: 20),

              _buildLanguageSection(theme),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      _isExtracting
                          ? null
                          : _extractText,
                  icon: _isExtracting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .document_scanner_outlined,
                        ),
                  label: Text(
                    _isExtracting
                        ? 'Extracting...'
                        : 'Extract Text',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _buildTextSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            const Color(0xFF7C5CFC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.text_fields,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(height: 14),
          Text(
            'Turn images into text',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Extract text from your images, save it as a document, copy it, or listen to it.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Image',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color:
                theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 12),

        if (_selectedImage == null)
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: theme
                  .colorScheme
                  .surface,
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color: theme
                    .colorScheme
                    .primary
                    .withOpacity(0.15),
              ),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons
                      .image_outlined,
                  size: 58,
                  color: theme
                      .colorScheme
                      .primary
                      .withOpacity(0.6),
                ),
                const SizedBox(height: 14),
                Text(
                  'No image selected',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    color: theme
                        .colorScheme
                        .onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select an image or take a photo',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme
                        .colorScheme
                        .onSurface
                        .withOpacity(
                          0.55,
                        ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                          _pickImage,
                      icon: const Icon(
                        Icons.photo_library_outlined,
                      ),
                      label: const Text(
                        'Gallery',
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed:
                          _takePhoto,
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                      ),
                      label: const Text(
                        'Camera',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  constraints:
                      const BoxConstraints(
                    minHeight: 220,
                    maxHeight: 420,
                  ),
                  color: Colors.black12,
                  child: Image.file(
                    File(
                      _selectedImage!.path,
                    ),
                    fit: BoxFit.contain,
                  ),
                ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _imageActionButton(
                        icon:
                            Icons.photo_library_outlined,
                        onPressed:
                            _pickImage,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      _imageActionButton(
                        icon:
                            Icons.camera_alt_outlined,
                        onPressed:
                            _takePhoto,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _imageActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.black54,
      borderRadius:
          BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSection(
    ThemeData theme,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surface,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.language,
            color:
                theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child:
                  DropdownButton<String>(
                value: _selectedLanguage,
                isExpanded: true,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                hint: const Text(
                  'Select language',
                ),
                items:
                    _languages.map(
                  (language) {
                    return DropdownMenuItem<
                        String>(
                      value:
                          language['code'],
                      child: Text(
                        language['name'] ??
                            '',
                      ),
                    );
                  },
                ).toList(),
                onChanged: (value) async {
                  if (value == null) {
                    return;
                  }

                  await _flutterTts.stop();

                  if (!mounted) return;

                  setState(() {
                    _selectedLanguage =
                        value;
                    _isSpeaking = false;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSection(
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Extracted Text',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                  color: theme
                      .colorScheme
                      .onSurface,
                ),
              ),
            ),
            if (_textController
                .text
                .isNotEmpty)
              Text(
                _languageName(),
                style: TextStyle(
                  fontSize: 12,
                  color: theme
                      .colorScheme
                      .primary,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          constraints:
              const BoxConstraints(
            minHeight: 220,
          ),
          decoration: BoxDecoration(
            color:
                theme.colorScheme.surface,
            borderRadius:
                BorderRadius.circular(20),
          ),
          padding:
              const EdgeInsets.all(16),
          child: TextField(
            controller:
                _textController,
            minLines: 8,
            maxLines: null,
            keyboardType:
                TextInputType.multiline,
            textAlignVertical:
                TextAlignVertical.top,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
            decoration:
                const InputDecoration(
              border: InputBorder.none,
              hintText:
                  'Extracted text will appear here...',
            ),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _copyText,
                icon: const Icon(
                  Icons.copy_outlined,
                ),
                label:
                    const Text('Copy'),
                style:
                    OutlinedButton.styleFrom(
                  minimumSize:
                      const Size(
                    double.infinity,
                    50,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _toggleSpeech,
                icon: Icon(
                  _isSpeaking
                      ? Icons.stop
                      : Icons.volume_up_outlined,
                ),
                label: Text(
                  _isSpeaking
                      ? 'Stop'
                      : 'Read Aloud',
                ),
                style:
                    ElevatedButton.styleFrom(
                  minimumSize:
                      const Size(
                    double.infinity,
                    50,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}