package com.cloudflare.cloudflared_tunnel_android_x86

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * No-op Flutter plugin used only to make Flutter/Gradle include this package's
 * x86 and x86_64 JNI libraries in Android builds.
 */
class CloudflaredTunnelAndroidX86Plugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit
}