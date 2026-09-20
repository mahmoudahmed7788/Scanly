package com.example.scanly

import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.paratoner.tesseract_ocr.TesseractOcrPlugin
import java.io.File

class MainActivity : FlutterActivity() {

    private val SHARE_CHANNEL = "scanly/share"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        // Register Tesseract OCR plugin
        flutterEngine.plugins.add(
            TesseractOcrPlugin()
        )

        // Scanly Share Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHARE_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "shareToApp" -> {

                    val filePath =
                        call.argument<String>("filePath")

                    val packageNames =
                        call.argument<List<String>>("packageNames")

                    val text =
                        call.argument<String>("text")
                            ?: "QR Code generated with Scanly"

                    if (
                        filePath == null ||
                        packageNames == null
                    ) {
                        result.error(
                            "INVALID_DATA",
                            "Missing share data",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    try {

                        val uri = getQrUri(filePath)

                        var selectedPackage: String? = null

                        for (packageName in packageNames) {

                            if (isAppInstalled(packageName)) {
                                selectedPackage = packageName
                                break
                            }
                        }

                        if (selectedPackage == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        val intent = Intent(
                            Intent.ACTION_SEND
                        ).apply {

                            type = "image/png"

                            putExtra(
                                Intent.EXTRA_STREAM,
                                uri
                            )

                            putExtra(
                                Intent.EXTRA_TEXT,
                                text
                            )

                            setPackage(selectedPackage)

                            addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION
                            )
                        }

                        startActivity(intent)

                        result.success(true)

                    } catch (
                        e: ActivityNotFoundException
                    ) {

                        result.success(false)

                    } catch (e: Exception) {

                        result.error(
                            "SHARE_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                "shareMore" -> {

                    val filePath =
                        call.argument<String>("filePath")

                    val text =
                        call.argument<String>("text")
                            ?: "QR Code generated with Scanly"

                    if (filePath == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }

                    try {

                        val uri = getQrUri(filePath)

                        val intent = Intent(
                            Intent.ACTION_SEND
                        ).apply {

                            type = "image/png"

                            putExtra(
                                Intent.EXTRA_STREAM,
                                uri
                            )

                            putExtra(
                                Intent.EXTRA_TEXT,
                                text
                            )

                            addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION
                            )
                        }

                        val chooser =
                            Intent.createChooser(
                                intent,
                                "Share QR Code"
                            )

                        startActivity(chooser)

                        result.success(true)

                    } catch (e: Exception) {

                        result.error(
                            "SHARE_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                "saveQrToGallery" -> {

                    val filePath =
                        call.argument<String>("filePath")

                    val fileName =
                        call.argument<String>("fileName")
                            ?: "Scanly_QR_${System.currentTimeMillis()}.png"

                    if (filePath == null) {
                        result.error(
                            "INVALID_DATA",
                            "Missing QR file path",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    try {

                        val savedUri =
                            saveQrToGallery(
                                filePath,
                                fileName
                            )

                        result.success(
                            savedUri.toString()
                        )

                    } catch (e: Exception) {

                        result.error(
                            "SAVE_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isAppInstalled(
        packageName: String
    ): Boolean {

        return try {

            packageManager.getPackageInfo(
                packageName,
                0
            )

            true

        } catch (
            e: Exception
        ) {

            false
        }
    }

    private fun getQrUri(
        filePath: String
    ): Uri {

        val file = File(filePath)

        if (!file.exists()) {
            throw Exception(
                "QR image file does not exist"
            )
        }

        return FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            file
        )
    }

    private fun saveQrToGallery(
        filePath: String,
        fileName: String
    ): Uri {

        val sourceFile = File(filePath)

        if (!sourceFile.exists()) {
            throw Exception(
                "QR image file does not exist"
            )
        }

        val resolver = contentResolver

        val values = ContentValues().apply {

            put(
                MediaStore.Images.Media.DISPLAY_NAME,
                fileName
            )

            put(
                MediaStore.Images.Media.MIME_TYPE,
                "image/png"
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {

                put(
                    MediaStore.Images.Media.RELATIVE_PATH,
                    "Pictures/Scanly Images"
                )

                put(
                    MediaStore.Images.Media.IS_PENDING,
                    1
                )
            }
        }

        val uri =
            resolver.insert(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                values
            )
                ?: throw Exception(
                    "Could not create gallery file"
                )

        try {

            resolver.openOutputStream(uri).use { outputStream ->

                if (outputStream == null) {
                    throw Exception(
                        "Could not open gallery output stream"
                    )
                }

                sourceFile.inputStream().use { inputStream ->

                    inputStream.copyTo(
                        outputStream
                    )
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {

                val completedValues =
                    ContentValues().apply {

                        put(
                            MediaStore.Images.Media.IS_PENDING,
                            0
                        )
                    }

                resolver.update(
                    uri,
                    completedValues,
                    null,
                    null
                )
            }

            return uri

        } catch (e: Exception) {

            resolver.delete(
                uri,
                null,
                null
            )

            throw e
        }
    }
}