package com.ecoimpact.itiwi

import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.ByteArrayOutputStream
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.Executors
import javax.net.ssl.HttpsURLConnection

/** Website-distributed APK updates; Android retains control of installation. */
class AppUpdates(private val activity: FlutterActivity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "com.ecoimpact.itiwi/app_updates")
    private val worker = Executors.newSingleThreadExecutor()
    private val directory = File(activity.cacheDir, "app_updates")
    private var readyApk: File? = null
    @Volatile private var closed = false

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method == "install") {
                try { result.success(install()) }
                catch (error: Exception) { result.error("install_failed", error.message, null) }
            } else if (call.method == "check" || call.method == "download") {
                worker.execute {
                    try {
                        val response: Any? = if (call.method == "check") {
                            val connection = connect("https://www.itiwi.online/app-release.json")
                            val manifest = try {
                                connection.inputStream.use { input ->
                                    val bytes = ByteArrayOutputStream()
                                    val buffer = ByteArray(4096)
                                    while (true) {
                                        val count = input.read(buffer)
                                        if (count < 0) break
                                        require(bytes.size() + count <= 65536) { "Release metadata too large" }
                                        bytes.write(buffer, 0, count)
                                    }
                                    bytes.toString("UTF-8")
                                }
                            } finally { connection.disconnect() }
                            mapOf("manifest" to manifest, "installedBuild" to version(installed()))
                        } else {
                            download(
                                requireNotNull(call.argument<String>("apkUrl")),
                                requireNotNull(call.argument<Number>("buildNumber")).toLong(),
                                requireNotNull(call.argument<String>("sha256"))
                            )
                            null
                        }
                        activity.runOnUiThread { if (!closed) result.success(response) }
                    } catch (error: Exception) {
                        activity.runOnUiThread {
                            if (!closed) result.error("update_failed", error.message, null)
                        }
                    }
                }
            } else result.notImplemented()
        }
    }

    private fun connect(address: String, redirects: Int = 0): HttpsURLConnection {
        val url = URL(address)
        require(url.protocol == "https" && url.host in setOf("www.itiwi.online", "itiwi.online") &&
            (url.port == -1 || url.port == 443) && url.userInfo == null) { "Untrusted update URL" }
        val connection = url.openConnection() as HttpsURLConnection
        connection.connectTimeout = 15000
        connection.readTimeout = 30000
        connection.instanceFollowRedirects = false
        connection.useCaches = false
        connection.setRequestProperty("Cache-Control", "no-cache")
        connection.setRequestProperty("Accept-Encoding", "identity")
        try {
            val status = connection.responseCode
            if (status in setOf(301, 302, 303, 307, 308)) {
                require(redirects < 3) { "Too many redirects" }
                val next = URL(url, requireNotNull(connection.getHeaderField("Location"))).toString()
                connection.disconnect()
                return connect(next, redirects + 1)
            }
            require(status == 200) { "Update server returned $status" }
            return connection
        } catch (error: Exception) {
            connection.disconnect()
            throw error
        }
    }

    @Suppress("DEPRECATION")
    private fun installed(): PackageInfo = activity.packageManager.getPackageInfo(
        activity.packageName, signatureFlags())

    private fun signatureFlags(): Int = if (Build.VERSION.SDK_INT >= 28)
        PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES

    @Suppress("DEPRECATION")
    private fun version(info: PackageInfo): Long = if (Build.VERSION.SDK_INT >= 28)
        info.longVersionCode else info.versionCode.toLong()

    @Suppress("DEPRECATION")
    private fun signers(info: PackageInfo): Set<String> {
        val certificates = if (Build.VERSION.SDK_INT >= 28)
            info.signingInfo?.apkContentsSigners else info.signatures
        return certificates.orEmpty().map { signature ->
            MessageDigest.getInstance("SHA-256").digest(signature.toByteArray()).toHex()
        }.toSet()
    }

    private fun ByteArray.toHex() = joinToString("") { "%02x".format(it) }

    @Suppress("DEPRECATION")
    private fun download(address: String, expectedBuild: Long, expectedHash: String) {
        require(expectedHash.matches(Regex("[a-fA-F0-9]{64}")))
        require(expectedBuild > version(installed())) { "Update is not newer" }
        readyApk = null
        directory.mkdirs()
        val file = File(directory, "update.apk")
        file.delete()
        val connection = connect(address)
        try {
            val size = connection.contentLengthLong
            val maximumSize = 300L * 1024 * 1024
            require(size <= maximumSize) { "APK too large" }
            val digest = MessageDigest.getInstance("SHA-256")
            var received = 0L
            var lastProgress = 0L
            val started = System.nanoTime()
            connection.inputStream.use { input ->
                file.outputStream().use { output ->
                    val buffer = ByteArray(65536)
                    while (true) {
                        check(!closed && !Thread.currentThread().isInterrupted) { "Download stopped" }
                        check(System.nanoTime() - started < 15L * 60 * 1000000000) { "Download timed out" }
                        val count = input.read(buffer)
                        if (count < 0) break
                        received += count
                        require(received <= maximumSize) { "APK too large" }
                        output.write(buffer, 0, count)
                        digest.update(buffer, 0, count)
                        val now = System.currentTimeMillis()
                        if (now - lastProgress >= 250) {
                            lastProgress = now
                            val progress = if (size > 0) (received.toDouble() / size).coerceIn(0.0, 1.0) else null
                            activity.runOnUiThread { if (!closed) channel.invokeMethod("progress", progress) }
                        }
                    }
                }
            }
            require(size < 0 || received == size) { "Incomplete APK" }
            require(digest.digest().toHex().equals(expectedHash, ignoreCase = true)) { "APK checksum mismatch" }
            val archive = requireNotNull(activity.packageManager.getPackageArchiveInfo(file.path, signatureFlags()))
            require(archive.packageName == activity.packageName && version(archive) == expectedBuild) {
                "APK does not match release"
            }
            val trustedSigners = signers(installed())
            require(trustedSigners.isNotEmpty() && signers(archive) == trustedSigners) { "APK signing certificate mismatch" }
            readyApk = file
        } catch (error: Exception) {
            file.delete()
            throw error
        } finally { connection.disconnect() }
    }

    private fun install(): String {
        val file = requireNotNull(readyApk) { "Download the update first" }
        require(file.exists()) { "Download the update again" }
        if (Build.VERSION.SDK_INT >= 26 && !activity.packageManager.canRequestPackageInstalls()) {
            activity.startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:${activity.packageName}")))
            return "permission"
        }
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.updates", file)
        activity.startActivity(Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        })
        return "opened"
    }

    fun close() {
        closed = true
        channel.setMethodCallHandler(null)
        worker.shutdownNow()
    }
}
