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
        super.configureFlutterEngine(
            flutterEngine
        )

        flutterEngine.plugins.add(
            TesseractOcrPlugin()
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHARE_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                // =====================================================
                // SHARE TO SPECIFIC APP
                // =====================================================

                "shareToApp" -> {

                    val filePath =
                        call.argument<String>(
                            "filePath"
                        )

                    val packageNames =
                        call.argument<List<String>>(
                            "packageNames"
                        )

                    val text =
                        call.argument<String>(
                            "text"
                        ) ?: "QR Code generated with Scanly"

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

                        val uri =
                            getQrUri(
                                filePath
                            )

                        var selectedPackage:
                            String? = null

                        for (
                            packageName
                            in packageNames
                        ) {

                            if (
                                isAppInstalled(
                                    packageName
                                )
                            ) {
                                selectedPackage =
                                    packageName

                                break
                            }
                        }

                        if (
                            selectedPackage ==
                            null
                        ) {
                            result.success(
                                false
                            )

                            return@setMethodCallHandler
                        }

                        val intent =
                            Intent(
                                Intent.ACTION_SEND
                            ).apply {

                                type =
                                    "image/png"

                                putExtra(
                                    Intent.EXTRA_STREAM,
                                    uri
                                )

                                putExtra(
                                    Intent.EXTRA_TEXT,
                                    text
                                )

                                setPackage(
                                    selectedPackage
                                )

                                addFlags(
                                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                                )
                            }

                        startActivity(
                            intent
                        )

                        result.success(
                            true
                        )

                    } catch (
                        e: ActivityNotFoundException
                    ) {

                        result.success(
                            false
                        )

                    } catch (
                        e: Exception
                    ) {

                        result.error(
                            "SHARE_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // =====================================================
                // SHARE MORE
                // =====================================================

                "shareMore" -> {

                    val filePath =
                        call.argument<String>(
                            "filePath"
                        )

                    val text =
                        call.argument<String>(
                            "text"
                        ) ?: "QR Code generated with Scanly"

                    if (
                        filePath == null
                    ) {
                        result.success(
                            false
                        )

                        return@setMethodCallHandler
                    }

                    try {

                        val uri =
                            getQrUri(
                                filePath
                            )

                        val intent =
                            Intent(
                                Intent.ACTION_SEND
                            ).apply {

                                type =
                                    "image/png"

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

                        startActivity(
                            chooser
                        )

                        result.success(
                            true
                        )

                    } catch (
                        e: Exception
                    ) {

                        result.error(
                            "SHARE_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // =====================================================
                // SAVE QR
                // =====================================================

                "saveQrToGallery" -> {

                    val filePath =
                        call.argument<String>(
                            "filePath"
                        )

                    val fileName =
                        call.argument<String>(
                            "fileName"
                        )
                            ?: "Scanly_QR_${System.currentTimeMillis()}.png"

                    if (
                        filePath == null
                    ) {

                        result.error(
                            "INVALID_DATA",
                            "Missing QR file path",
                            null
                        )

                        return@setMethodCallHandler
                    }

                    try {

                        val savedUri =
                            saveQrToScanlyFolder(
                                filePath,
                                fileName
                            )

                        result.success(
                            savedUri.toString()
                        )

                    } catch (
                        e: Exception
                    ) {

                        result.error(
                            "SAVE_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // =====================================================
                // SAVE ANY FILE TO:
                //
                // Documents/Scanly/<folder>/
                // =====================================================

                "saveFileToScanly" -> {

                    val filePath =
                        call.argument<String>(
                            "filePath"
                        )

                    val fileName =
                        call.argument<String>(
                            "fileName"
                        )

                    val mimeType =
                        call.argument<String>(
                            "mimeType"
                        )
                            ?: "application/octet-stream"

                    val folder =
                        call.argument<String>(
                            "folder"
                        )
                            ?: "Documents"

                    if (
                        filePath == null ||
                        fileName == null
                    ) {

                        result.error(
                            "INVALID_DATA",
                            "Missing file data",
                            null
                        )

                        return@setMethodCallHandler
                    }

                    try {

                        val savedUri =
                            saveFileToScanlyFolder(
                                filePath =
                                    filePath,
                                fileName =
                                    fileName,
                                mimeType =
                                    mimeType,
                                folder =
                                    folder
                            )

                        result.success(
                            savedUri.toString()
                        )

                    } catch (
                        e: Exception
                    ) {

                        result.error(
                            "SAVE_FILE_ERROR",
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

    // =========================================================
    // CHECK APP INSTALLED
    // =========================================================

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

    // =========================================================
    // GET FILE PROVIDER URI
    // =========================================================

    private fun getQrUri(
        filePath: String
    ): Uri {

        val file =
            File(filePath)

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

    // =========================================================
    // SAVE QR
    // =========================================================

    private fun saveQrToScanlyFolder(
        filePath: String,
        fileName: String
    ): Uri {

        return saveFileToScanlyFolder(
            filePath =
                filePath,
            fileName =
                fileName,
            mimeType =
                "image/png",
            folder =
                "QR Codes"
        )
    }

    // =========================================================
    // SAVE FILE TO:
    //
    // Documents/Scanly/<folder>/
    // =========================================================

    private fun saveFileToScanlyFolder(
        filePath: String,
        fileName: String,
        mimeType: String,
        folder: String
    ): Uri {

        val sourceFile =
            File(filePath)

        if (!sourceFile.exists()) {

            throw Exception(
                "Source file does not exist"
            )
        }

        val resolver =
            contentResolver

        // =====================================================
        // ANDROID 10+
        // =====================================================

        if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.Q
        ) {

            val safeFolder =
                folder
                    .trim()
                    .replace(
                        "/",
                        "_"
                    )

            val relativePath =
                "Documents/Scanly/$safeFolder/"

            val values =
                ContentValues().apply {

                    put(
                        MediaStore.Files.FileColumns.DISPLAY_NAME,
                        fileName
                    )

                    put(
                        MediaStore.Files.FileColumns.MIME_TYPE,
                        mimeType
                    )

                    put(
                        MediaStore.Files.FileColumns.RELATIVE_PATH,
                        relativePath
                    )

                    put(
                        MediaStore.Files.FileColumns.IS_PENDING,
                        1
                    )
                }

            val collection =
                MediaStore.Files.getContentUri(
                    MediaStore.VOLUME_EXTERNAL_PRIMARY
                )

            val uri =
                resolver.insert(
                    collection,
                    values
                )
                    ?: throw Exception(
                        "Could not create Scanly file"
                    )

            try {

                resolver
                    .openOutputStream(uri)
                    .use { outputStream ->

                        if (
                            outputStream ==
                            null
                        ) {

                            throw Exception(
                                "Could not open output stream"
                            )
                        }

                        sourceFile
                            .inputStream()
                            .use { inputStream ->

                                inputStream.copyTo(
                                    outputStream
                                )
                            }
                    }

                val completedValues =
                    ContentValues().apply {

                        put(
                            MediaStore.Files.FileColumns.IS_PENDING,
                            0
                        )
                    }

                resolver.update(
                    uri,
                    completedValues,
                    null,
                    null
                )

                return uri

            } catch (
                e: Exception
            ) {

                resolver.delete(
                    uri,
                    null,
                    null
                )

                throw e
            }
        }

        // =====================================================
        // ANDROID 9 AND BELOW
        // =====================================================

        val documentsDirectory =
            android.os.Environment
                .getExternalStoragePublicDirectory(
                    android.os.Environment
                        .DIRECTORY_DOCUMENTS
                )

        val scanlyDirectory =
            File(
                documentsDirectory,
                "Scanly/$folder"
            )

        if (
            !scanlyDirectory.exists()
        ) {

            scanlyDirectory.mkdirs()
        }

        val destinationFile =
            File(
                scanlyDirectory,
                fileName
            )

        sourceFile
            .inputStream()
            .use { inputStream ->

                destinationFile
                    .outputStream()
                    .use { outputStream ->

                        inputStream.copyTo(
                            outputStream
                        )
                    }
            }

        return Uri.fromFile(
            destinationFile
        )
    }
}