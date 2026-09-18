package io.paratoner.tesseract_ocr

import android.graphics.BitmapFactory
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class TesseractOcrPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel

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
                extractText(call, result)
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
        try {
            val args = call.arguments as? Map<*, *>

            if (args == null) {
                result.error(
                    "INVALID_ARGUMENTS",
                    "Arguments are missing",
                    null
                )
                return
            }

            val imagePath = args["imagePath"] as? String
            val tessDataPath = args["tessData"] as? String
            val language = args["language"] as? String ?: "eng"

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

            val imageFile = File(imagePath)

            if (!imageFile.exists()) {
                result.error(
                    "IMAGE_NOT_FOUND",
                    "Image file does not exist: $imagePath",
                    null
                )
                return
            }

            val tessdataFolder = File(
                tessDataPath,
                "tessdata"
            )

            if (!tessdataFolder.exists()) {
                result.error(
                    "TESSDATA_NOT_FOUND",
                    "Tessdata folder does not exist: ${tessdataFolder.absolutePath}",
                    null
                )
                return
            }

            val bitmap = BitmapFactory.decodeFile(imagePath)

            if (bitmap == null) {
                result.error(
                    "IMAGE_DECODE_ERROR",
                    "Could not decode image",
                    null
                )
                return
            }

            val tessApi = TessBaseAPI()

            val initialized = tessApi.init(
                tessDataPath,
                language
            )

            if (!initialized) {
                bitmap.recycle()

                result.error(
                    "TESSERACT_INIT_FAILED",
                    "Could not initialize Tesseract with language: $language",
                    null
                )
                return
            }

            tessApi.setImage(bitmap)

            val text = tessApi.utF8Text ?: ""

            tessApi.clear()
            bitmap.recycle()

            result.success(text)

        } catch (e: Exception) {

            result.error(
                "OCR_ERROR",
                e.message ?: "Unknown OCR error",
                null
            )
        }
    }

    override fun onDetachedFromEngine(
        binding: FlutterPlugin.FlutterPluginBinding
    ) {
        channel.setMethodCallHandler(null)
    }
}