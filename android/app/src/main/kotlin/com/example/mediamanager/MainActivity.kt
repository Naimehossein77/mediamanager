package com.example.mediamanager

import io.flutter.embedding.android.FlutterActivity
import android.graphics.BitmapFactory
import android.graphics.Bitmap
import android.os.Environment
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
class MainActivity: FlutterActivity() {
        private val CHANNEL = "imageconverter"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "convertHeicToJpg") {
                val filePath = call.arguments as String
                val convertedPath = convertHeicToJpg(filePath)
                if (convertedPath != null) {
                    result.success(convertedPath)
                } else {
                    result.error("UNAVAILABLE", "Failed to convert the image.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun convertHeicToJpg(filePath: String): String? {
        val bitmap = BitmapFactory.decodeFile(filePath)
        val outputFile = File(getExternalFilesDir(Environment.DIRECTORY_PICTURES), "converted_image.jpg")
        FileOutputStream(outputFile).use { out ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, out) // Compress to JPEG
        }
        return outputFile.absolutePath
    }
}