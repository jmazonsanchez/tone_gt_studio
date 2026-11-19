package com.example.tone_gt_studio

import android.content.Context
import android.media.midi.MidiDevice
import android.media.midi.MidiDeviceInfo
import android.media.midi.MidiInputPort
import android.media.midi.MidiManager
import android.media.midi.MidiOutputPort
import android.media.midi.MidiReceiver
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methodChannelName = "com.example.tone_gt_studio/midi"
    private val eventChannelName = "com.example.tone_gt_studio/midi_events"

    private var midiManager: MidiManager? = null
    private var openMidiDevice: MidiDevice? = null
    private var inputPort: MidiInputPort? = null
    private var outputPort: MidiOutputPort? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            midiManager = getSystemService(Context.MIDI_SERVICE) as? MidiManager
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result -> handleMethodCall(call, result) }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> result.success(midiManager != null)
            "getDevices" -> result.success(getMidiDeviceNames())
            "connect" -> connectToDevice(call.argument<String?>("deviceName"), result)
            "disconnect" -> {
                disconnectDevice()
                result.success(true)
            }
            "send" -> handleSend(call.argument<ByteArray>("data"), result)
            else -> result.notImplemented()
        }
    }

    private fun handleSend(data: ByteArray?, result: MethodChannel.Result) {
        val port = inputPort
        if (data == null || port == null) {
            result.success(false)
            return
        }
        try {
            port.send(data, 0, data.size)
            result.success(true)
        } catch (_: Exception) {
            result.success(false)
        }
    }

    private fun getDeviceDisplayName(info: MidiDeviceInfo): String {
        return info.properties.getString(MidiDeviceInfo.PROPERTY_NAME)
            ?: info.properties.getString(MidiDeviceInfo.PROPERTY_PRODUCT)
            ?: "MIDI Device #${info.id}"
    }

    private fun getMidiDeviceNames(): List<String> {
        val mm = midiManager ?: return emptyList()
        return mm.devices.map { getDeviceDisplayName(it) }
    }

    private fun findTargetDevice(devices: Array<MidiDeviceInfo>, targetName: String?): MidiDeviceInfo? {
        if (!targetName.isNullOrEmpty()) {
            val matched = devices.find { getDeviceDisplayName(it).contains(targetName, ignoreCase = true) }
            if (matched != null) return matched
        }
        return devices.find {
            val name = getDeviceDisplayName(it)
            name.contains("Boss", ignoreCase = true) || name.contains("GT-1", ignoreCase = true)
        } ?: devices.firstOrNull()
    }

    private fun connectToDevice(targetName: String?, result: MethodChannel.Result) {
        val mm = midiManager
        val devices = mm?.devices
        if (devices == null || devices.isEmpty()) {
            result.success(false)
            return
        }

        val target = findTargetDevice(devices, targetName)
        if (target == null) {
            result.success(false)
            return
        }

        disconnectDevice()
        mm.openDevice(target, { device ->
            setupOpenedDevice(device, target, result)
        }, Handler(Looper.getMainLooper()))
    }

    private fun setupOpenedDevice(device: MidiDevice?, target: MidiDeviceInfo, result: MethodChannel.Result) {
        if (device == null) {
            runOnUiThread { result.success(false) }
            return
        }
        openMidiDevice = device
        setupPorts(device)

        val connected = inputPort != null || outputPort != null
        val devName = getDeviceDisplayName(target)

        runOnUiThread {
            result.success(mapOf("success" to connected, "name" to devName))
        }
    }

    private fun setupPorts(device: MidiDevice) {
        val info = device.info
        if (info.inputPortCount > 0) {
            inputPort = device.openInputPort(0)
        }
        if (info.outputPortCount > 0) {
            val out = device.openOutputPort(0)
            outputPort = out
            out?.connect(object : MidiReceiver() {
                override fun onSend(msg: ByteArray?, offset: Int, count: Int, timestamp: Long) {
                    forwardIncomingMidi(msg, offset, count)
                }
            })
        }
    }

    private fun forwardIncomingMidi(msg: ByteArray?, offset: Int, count: Int) {
        if (msg == null || count <= 0) return
        val copy = msg.copyOfRange(offset, offset + count)
        runOnUiThread {
            eventSink?.success(copy)
        }
    }

    private fun disconnectDevice() {
        try { inputPort?.close() } catch (_: Exception) {}
        inputPort = null

        try { outputPort?.close() } catch (_: Exception) {}
        outputPort = null

        try { openMidiDevice?.close() } catch (_: Exception) {}
        openMidiDevice = null
    }

    override fun onDestroy() {
        disconnectDevice()
        super.onDestroy()
    }
}
