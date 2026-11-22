package id.jejakpos.jejakpos

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        SiftVision.register(this, flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "id.jejakpos/photo_gallery")
            .setMethodCallHandler { call, result ->
                if (call.method != "savePng") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                val name = call.argument<String>("name")
                if (bytes == null || bytes.isEmpty() || name == null ||
                    !Regex("JejakPOS_[0-9]+\\.png").matches(name)) {
                    result.error("invalid_photo", "Data foto tidak valid.", null)
                    return@setMethodCallHandler
                }
                Thread {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val resolver = contentResolver
                            val values = ContentValues().apply {
                                put(MediaStore.Images.Media.DISPLAY_NAME, name)
                                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                                put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/JejakPOS")
                                put(MediaStore.Images.Media.IS_PENDING, 1)
                            }
                            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                                ?: error("Tidak dapat membuat file di galeri.")
                            try {
                                val stream = resolver.openOutputStream(uri)
                                    ?: error("Tidak dapat menulis foto.")
                                stream.use { it.write(bytes); it.flush() }
                                val published = resolver.update(uri, ContentValues().apply {
                                    put(MediaStore.Images.Media.IS_PENDING, 0)
                                }, null, null)
                                check(published > 0) { "Foto belum diterbitkan di galeri." }
                                runOnUiThread { result.success(uri.toString()) }
                            } catch (e: Exception) {
                                resolver.delete(uri, null, null)
                                throw e
                            }
                        } else {
                            @Suppress("DEPRECATION")
                            val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "JejakPOS")
                            check(dir.isDirectory || dir.mkdirs()) { "Album tidak dapat dibuat." }
                            val file = File(dir, name)
                            file.outputStream().use { it.write(bytes); it.flush() }
                            MediaScannerConnection.scanFile(this, arrayOf(file.absolutePath), arrayOf("image/png")) { _, uri ->
                                runOnUiThread {
                                    if (uri != null) result.success(uri.toString())
                                    else result.error("scan_failed", "Foto belum terdaftar di galeri.", null)
                                }
                            }
                        }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("save_failed", e.message, null) }
                    }
                }.start()
            }
    }
}
