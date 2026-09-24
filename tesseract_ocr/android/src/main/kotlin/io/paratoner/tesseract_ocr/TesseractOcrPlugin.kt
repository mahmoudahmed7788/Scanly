
package io.paratoner.tesseract_ocr

import android.graphics.BitmapFactory
import android.util.Log
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class TesseractOcrPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel

    companion object {
        private const val TAG = "SCANLY_TESSERACT"
    }

    override fun onAttachedToEngine(
        flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "tesseract_ocr"
        )

        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {

            "getPlatformVersion" -> {
                result.success(
                    "Android ${android.os.Build.VERSION.RELEASE}"
                )
            }

            "extractText" -> {
                extractText(
                    call,
                    result
                )
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun extractText(
        call: MethodCall,
        result: Result
    ) {
        var bitmap: android.graphics.Bitmap? = null
        var tessApi: TessBaseAPI? = null

        try {

            val args =
                call.arguments as? Map<*, *>

            if (args == null) {
                result.error(
                    "INVALID_ARGUMENTS",
                    "Arguments are missing",
                    null
                )
                return
            }

            val imagePath =
                args["imagePath"] as? String

            val tessDataPath =
                args["tessData"] as? String

            val language =
                args["language"] as? String
                    ?: "eng"

            Log.d(
                TAG,
                "========== OCR START =========="
            )

            Log.d(
                TAG,
                "Image: $imagePath"
            )

            Log.d(
                TAG,
                "Language: $language"
            )

            Log.d(
                TAG,
                "TessData: $tessDataPath"
            )

            if (imagePath.isNullOrEmpty()) {
                result.error(
                    "INVALID_IMAGE",
                    "Image path is missing",
                    null
                )
                return
            }

            if (tessDataPath.isNullOrEmpty()) {
                result.error(
                    "INVALID_TESSDATA",
                    "Tessdata path is missing",
                    null
                )
                return
            }

            val imageFile =
                File(imagePath)

            if (!imageFile.exists()) {
                result.error(
                    "IMAGE_NOT_FOUND",
                    "Image file does not exist: $imagePath",
                    null
                )
                return
            }

            val tessdataFolder =
                File(
                    tessDataPath,
                    "tessdata"
                )

            if (!tessdataFolder.exists()) {
                result.error(
                    "TESSDATA_NOT_FOUND",
                    "Tessdata folder does not exist: " +
                        tessdataFolder.absolutePath,
                    null
                )
                return
            }

            /*
             * Check every requested language.
             */

            val languages =
                language.split("+")

            for (lang in languages) {

                val cleanLanguage =
                    lang.trim()

                if (cleanLanguage.isEmpty()) {
                    continue
                }

                val trainedData =
                    File(
                        tessdataFolder,
                        "$cleanLanguage.traineddata"
                    )

                Log.d(
                    TAG,
                    "Language file: " +
                        trainedData.absolutePath
                )

                Log.d(
                    TAG,
                    "Exists: " +
                        trainedData.exists()
                )

                Log.d(
                    TAG,
                    "Size: " +
                        trainedData.length()
                )

                if (!trainedData.exists()) {
                    result.error(
                        "LANGUAGE_FILE_NOT_FOUND",
                        "Tesseract language file not found: " +
                            trainedData.absolutePath,
                        null
                    )
                    return
                }
            }

            /*
             * Decode image.
             */

            bitmap =
                BitmapFactory.decodeFile(
                    imagePath
                )

            if (bitmap == null) {
                result.error(
                    "IMAGE_DECODE_ERROR",
                    "Could not decode image",
                    null
                )
                return
            }

            Log.d(
                TAG,
                "Bitmap: " +
                    bitmap.width +
                    "x" +
                    bitmap.height
            )

            /*
             * Create Tesseract.
             */

            tessApi =
                TessBaseAPI()

            /*
             * IMPORTANT:
             *
             * tess-two 9.1.0:
             *
             * OEM_TESSERACT_ONLY = 0
             * OEM_CUBE_ONLY      = 1
             * OEM_DEFAULT        = 3
             *
             * We MUST use TESSERACT_ONLY
             * because the default mode checks
             * Cube files for Arabic.
             */

            Log.d(
                TAG,
                "Initializing with OEM_TESSERACT_ONLY"
            )

            val initialized =
                tessApi.init(
                    tessDataPath,
                    language,
                    TessBaseAPI.OEM_TESSERACT_ONLY
                )

            Log.d(
                TAG,
                "Tesseract initialized: $initialized"
            )

            if (!initialized) {

                result.error(
                    "TESSERACT_INIT_FAILED",
                    "Could not initialize Tesseract " +
                        "with language: $language",
                    null
                )

                return
            }

            /*
             * Set image.
             */

            tessApi.setImage(
                bitmap
            )

            /*
             * Extract text.
             */

            val text =
                tessApi.utF8Text ?: ""

            Log.d(
                TAG,
                "Extracted text length: " +
                    text.length
            )

            Log.d(
                TAG,
                "========== OCR SUCCESS =========="
            )

            result.success(
                text
            )

        } catch (e: Exception) {

            Log.e(
                TAG,
                "OCR ERROR",
                e
            )

            result.error(
                "OCR_ERROR",
                e.message
                    ?: "Unknown OCR error",
                null
            )

        } finally {

            try {
                tessApi?.clear()
            } catch (_: Exception) {
            }

            try {
                tessApi?.end()
            } catch (_: Exception) {
            }

            try {
                bitmap?.recycle()
            } catch (_: Exception) {
            }
        }
    }

    override fun onDetachedFromEngine(
        binding: FlutterPlugin.FlutterPluginBinding
    ) {
        channel.setMethodCallHandler(null)
    }
}
