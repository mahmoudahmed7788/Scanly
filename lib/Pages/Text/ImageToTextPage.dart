import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanly/Service/OCR/ImageTextRecognizerService.dart';
import 'package:scanly/Widgets/Text/ExtractTextButton.dart';
import 'package:scanly/Widgets/Text/ExtractedTextCard.dart';
import 'package:scanly/Widgets/Text/ImagePickerSheet.dart';
import 'package:scanly/Widgets/Text/ImageToTextEmptyState.dart';
import 'package:scanly/Widgets/Text/ImageToTextLanguageDropdown.dart';



class ImageToTextPage extends StatefulWidget {
  const ImageToTextPage({
    super.key,
  });

  @override
  State<ImageToTextPage> createState() =>
      _ImageToTextPageState();
}

class _ImageToTextPageState
    extends State<ImageToTextPage> {
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();

  File? _selectedImage;

  String _extractedText = '';

  bool _isExtracting = false;
  bool _isSpeaking = false;

  String _selectedLanguage = 'eng';

  final List<Map<String, String>> _languages = [
    {
      'code': 'eng',
      'name': 'English',
    },
  ];

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  // =========================================================
  // PICK IMAGE
  // =========================================================

  Future<void> _pickImage(
    ImageSource source,
  ) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image == null) {
        return;
      }

      setState(() {
        _selectedImage = File(image.path);
        _extractedText = '';
      });
    } catch (e) {
      _showMessage(
        'Could not select image: $e',
      );
    }
  }

  // =========================================================
  // SHOW IMAGE OPTIONS
  // =========================================================

  void _showImagePickerOptions() {
    ImagePickerSheet.show(
      context: context,
      onCamera: () {
        _pickImage(ImageSource.camera);
      },
      onGallery: () {
        _pickImage(ImageSource.gallery);
      },
    );
  }

  // =========================================================
  // EXTRACT TEXT
  // =========================================================

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

    setState(() {
      _isExtracting = true;
      _extractedText = '';
    });

    try {
      debugPrint(
        '==============================================',
      );
      debugPrint('ML KIT OCR START');
      debugPrint(
        'Image: ${_selectedImage!.path}',
      );
      debugPrint(
        'Language: $_selectedLanguage',
      );

      final String result =
          await ImageTextRecognizerService.extractText(
        _selectedImage!.path,
      );

      debugPrint(
        'Extracted text length: ${result.length}',
      );

      debugPrint('Extracted text:');
      debugPrint(result);

      debugPrint('ML KIT OCR SUCCESS');

      debugPrint(
        '==============================================',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _extractedText = result;
      });

      if (result.isEmpty) {
        _showMessage(
          'No text was detected in this image.',
        );
      } else {
        _showMessage(
          'Text extracted successfully.',
        );
      }
    } on PlatformException catch (e) {
      debugPrint(
        '==============================================',
      );
      debugPrint('ML KIT OCR ERROR');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('Details: ${e.details}');
      debugPrint(
        '==============================================',
      );

      if (mounted) {
        _showMessage(
          e.message ??
              'Unable to extract text from this image.',
        );
      }
    } catch (e) {
      debugPrint(
        '==============================================',
      );
      debugPrint('ML KIT OCR ERROR');
      debugPrint(e.toString());
      debugPrint(
        '==============================================',
      );

      if (mounted) {
        _showMessage(
          'Unable to extract text from this image.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExtracting = false;
        });
      }
    }
  }

  // =========================================================
  // COPY TEXT
  // =========================================================

  Future<void> _copyText() async {
    if (_extractedText.trim().isEmpty) {
      _showMessage(
        'There is no text to copy.',
      );
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: _extractedText,
      ),
    );

    _showMessage(
      'Text copied to clipboard.',
    );
  }

  // =========================================================
  // TEXT TO SPEECH
  // =========================================================

  Future<void> _toggleSpeech() async {
    if (_extractedText.trim().isEmpty) {
      _showMessage(
        'There is no text to read.',
      );
      return;
    }

    try {
      if (_isSpeaking) {
        await _flutterTts.stop();

        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }

        return;
      }

      await _flutterTts.setLanguage(
        'en-US',
      );

      await _flutterTts.setSpeechRate(
        0.5,
      );

      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      await _flutterTts.speak(
        _extractedText,
      );

      if (mounted) {
        setState(() {
          _isSpeaking = true;
        });
      }
    } catch (e) {
      _showMessage(
        'Unable to read text: $e',
      );
    }
  }

  // =========================================================
  // CLEAR
  // =========================================================

  void _clearAll() {
    setState(() {
      _selectedImage = null;
      _extractedText = '';
      _isSpeaking = false;
    });

    _flutterTts.stop();
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(
            seconds: 2,
          ),
        ),
      );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B5FEF),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Image to Text',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_selectedImage != null)
            IconButton(
              onPressed: _clearAll,
              icon: const Icon(
                Icons.delete_outline,
              ),
              tooltip: 'Clear',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              // IMAGE
              _selectedImage == null
                  ? GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Container(
                        height: 280,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(
                                0.05,
                              ),
                              blurRadius: 12,
                              offset:
                                  const Offset(0, 5),
                            ),
                          ],
                        ),
                        child:
                            const ImageToTextEmptyState(),
                      ),
                    )
                  : ImagePreviewCard(
                      image: _selectedImage,
                      onTap: _showImagePickerOptions,
                    ),

              const SizedBox(height: 20),

              // LANGUAGE
              ImageToTextLanguageDropdown(
                selectedLanguage:
                    _selectedLanguage,
                languages: _languages,
                disabled: _isExtracting,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedLanguage = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // EXTRACT
              ExtractTextButton(
                isExtracting: _isExtracting,
                onPressed: _extractText,
              ),

              const SizedBox(height: 24),

              // RESULT
              if (_extractedText.isNotEmpty)
                ExtractedTextCard(
                  text: _extractedText,
                  isSpeaking: _isSpeaking,
                  onCopy: _copyText,
                  onSpeech: _toggleSpeech,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on _ImageToTextPageState {
  ImagePreviewCard({File? image, required void Function() onTap}) {}
}