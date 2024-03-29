package com.tatapowersed.spider.signalr

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** SignalR1FlutterPlugin */
public class SignalR1FlutterPlugin : FlutterPlugin, MethodCallHandler {
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "signalR1")
        channel.setMethodCallHandler(this);
    }

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    companion object {
        lateinit var channel: MethodChannel

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "signalR1")
            channel.setMethodCallHandler(SignalR1FlutterPlugin())
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            CallMethod.ConnectToServer.value -> {
                val arguments = call.arguments as Map<*, *>
                @Suppress("UNCHECKED_CAST")
                SignalR1.connectToServer(
                        arguments["baseUrl"] as String,
                        arguments["hubName"] as String,
                        arguments["queryString"] as String,
                        arguments["headers"] as? Map<String, String> ?: emptyMap(),
                        arguments["transport"] as Int,
                        arguments["hubMethods"] as? List<String> ?: emptyList(),
                        result)
            }
            CallMethod.Reconnect.value -> {
                SignalR1.reconnect(result)
            }
            CallMethod.Stop.value -> {
                SignalR1.stop(result)
            }
            CallMethod.ListenToHubMethod.value -> {
                if (call.arguments is String) {
                    val methodName = call.arguments as String
                    SignalR1.listenToHubMethod(methodName, result)
                } else {
                    result.error("Error", "Cast to String Failed", "")
                }
            }
            CallMethod.InvokeServerMethod.value -> {
                val arguments = call.arguments as Map<*, *>
                @Suppress("UNCHECKED_CAST")
                SignalR1.invokeServerMethod(arguments["methodName"] as String, arguments["arguments"] as? List<Any>
                        ?: emptyList(), result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
