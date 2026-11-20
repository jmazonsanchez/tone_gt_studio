package com.example.tone_gt_studio

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import java.io.ByteArrayOutputStream

data class UsbEndpointPair(
    val usbInterface: UsbInterface,
    val inEndpoint: UsbEndpoint,
    val outEndpoint: UsbEndpoint
)

class UsbMidiDriver(
    private val context: Context,
    private val onDataReceived: (ByteArray) -> Unit
) {
    companion object {
        const val ACTION_USB_PERMISSION = "com.example.tone_gt_studio.USB_PERMISSION"
        const val ROLAND_VENDOR_ID = 1410 // 0x0582
    }

    private val usbManager = context.getSystemService(Context.USB_SERVICE) as? UsbManager
    private var connection: UsbDeviceConnection? = null
    private var claimedInterface: UsbInterface? = null
    private var endpointPair: UsbEndpointPair? = null
    private var isReading = false
    private var readerThread: Thread? = null
    private var pendingConnectCallback: ((Boolean, String) -> Unit)? = null
    var onDisconnectedCallback: (() -> Unit)? = null

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            if (intent?.action == ACTION_USB_PERMISSION) {
                val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                }
                handlePermissionResult(device, granted)
            } else if (intent?.action == UsbManager.ACTION_USB_DEVICE_DETACHED) {
                if (connection != null) {
                    disconnect()
                    Handler(Looper.getMainLooper()).post {
                        onDisconnectedCallback?.invoke()
                    }
                }
            }
        }
    }

    init {
        val filter = IntentFilter().apply {
            addAction(ACTION_USB_PERMISSION)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(usbReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(usbReceiver, filter)
        }
    }

    fun isDeviceConnected(): Boolean = connection != null

    fun getDeviceNames(): List<String> {
        val mgr = usbManager ?: return emptyList()
        val names = mutableListOf<String>()
        for (device in mgr.deviceList.values) {
            if (isMidiOrRolandDevice(device)) {
                names.add(getDeviceDisplayName(device))
            }
        }
        return names
    }

    fun connect(targetName: String?, onResult: (Boolean, String) -> Unit) {
        val mgr = usbManager
        if (mgr == null) {
            onResult(false, "")
            return
        }

        val target = findTargetDevice(mgr.deviceList.values.toList(), targetName)
        if (target == null) {
            onResult(false, "")
            return
        }

        if (!mgr.hasPermission(target)) {
            pendingConnectCallback = onResult
            requestUsbPermission(mgr, target)
            return
        }

        val success = openDeviceAndStart(mgr, target)
        val devName = getDeviceDisplayName(target)
        onResult(success, if (success) devName else "")
    }

    fun send(midiBytes: ByteArray): Boolean {
        val conn = connection ?: return false
        val outEp = endpointPair?.outEndpoint ?: return false

        val usbPackets = encodeUsbMidi(midiBytes)
        val sent = conn.bulkTransfer(outEp, usbPackets, usbPackets.size, 1000)
        return sent >= 0
    }

    fun disconnect() {
        isReading = false
        readerThread?.interrupt()
        readerThread = null

        val conn = connection
        val intf = claimedInterface
        if (conn != null && intf != null) {
            try { conn.releaseInterface(intf) } catch (_: Exception) {}
        }
        try { conn?.close() } catch (_: Exception) {}

        connection = null
        claimedInterface = null
        endpointPair = null
    }

    fun dispose() {
        disconnect()
        try {
            context.unregisterReceiver(usbReceiver)
        } catch (_: Exception) {}
    }

    private fun handlePermissionResult(device: UsbDevice?, granted: Boolean) {
        val cb = pendingConnectCallback
        pendingConnectCallback = null
        val mgr = usbManager
        val targetDev = device ?: mgr?.let { findTargetDevice(it.deviceList.values.toList(), null) }
        if (targetDev != null && granted && mgr != null) {
            val success = openDeviceAndStart(mgr, targetDev)
            val name = getDeviceDisplayName(targetDev)
            Handler(Looper.getMainLooper()).post { cb?.invoke(success, name) }
        } else {
            Handler(Looper.getMainLooper()).post { cb?.invoke(false, "") }
        }
    }

    private fun requestUsbPermission(mgr: UsbManager, device: UsbDevice) {
        val intent = Intent(ACTION_USB_PERMISSION).apply {
            setPackage(context.packageName)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pIntent = PendingIntent.getBroadcast(context, 0, intent, flags)
        mgr.requestPermission(device, pIntent)
    }

    private fun openDeviceAndStart(mgr: UsbManager, device: UsbDevice): Boolean {
        disconnect()

        val pair = findEndpoints(device) ?: return false
        val conn = mgr.openDevice(device) ?: return false

        if (!conn.claimInterface(pair.usbInterface, true)) {
            try { conn.close() } catch (_: Exception) {}
            return false
        }

        connection = conn
        claimedInterface = pair.usbInterface
        endpointPair = pair

        startReaderThread(conn, pair.inEndpoint)
        return true
    }

    private fun handleReadError(): Boolean {
        val mgr = usbManager
        if (mgr == null || mgr.deviceList.values.none { it.vendorId == ROLAND_VENDOR_ID }) {
            isReading = false
            Handler(Looper.getMainLooper()).post {
                disconnect()
                onDisconnectedCallback?.invoke()
            }
            return true
        }
        return false
    }

    private fun startReaderThread(conn: UsbDeviceConnection, inEp: UsbEndpoint) {
        isReading = true
        val buffer = ByteArray(inEp.maxPacketSize.coerceAtLeast(64))
        val output = ByteArrayOutputStream()

        readerThread = Thread({
            while (isReading && !Thread.currentThread().isInterrupted) {
                val read = conn.bulkTransfer(inEp, buffer, buffer.size, 200)
                if (read > 0) {
                    processIncomingBytes(buffer, read, output)
                } else if (read < 0 && handleReadError()) {
                    break
                }
            }
        }, "UsbMidiReader").apply { start() }
    }

    private fun processIncomingBytes(buffer: ByteArray, count: Int, output: ByteArrayOutputStream) {
        if ((buffer[0].toInt() and 0xFF) == 0xF0) {
            onDataReceived(buffer.copyOf(count))
            return
        }

        output.reset()
        decodeUsbMidi(buffer, count, output)
        val decoded = output.toByteArray()
        if (decoded.isNotEmpty()) {
            onDataReceived(decoded)
        }
    }

    private fun isMidiOrRolandDevice(device: UsbDevice): Boolean {
        if (device.vendorId == ROLAND_VENDOR_ID) return true
        return findEndpoints(device) != null
    }

    private fun getDeviceDisplayName(device: UsbDevice): String {
        val prod = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) device.productName else null
        if (!prod.isNullOrEmpty()) return prod
        if (device.vendorId == ROLAND_VENDOR_ID) {
            return when (device.productId) {
                499, 500 -> "Boss GT-1B"
                485, 470 -> "Boss GT-1"
                else -> "Boss / Roland Device"
            }
        }
        return "USB MIDI Device #${device.deviceId}"
    }

    private fun findTargetDevice(devices: List<UsbDevice>, targetName: String?): UsbDevice? {
        if (!targetName.isNullOrEmpty()) {
            val matched = devices.find { getDeviceDisplayName(it).contains(targetName, ignoreCase = true) }
            if (matched != null) return matched
        }
        return devices.find { it.vendorId == ROLAND_VENDOR_ID }
            ?: devices.find {
                val name = getDeviceDisplayName(it)
                (name.contains("Boss", ignoreCase = true) || name.contains("GT-1", ignoreCase = true)) && findEndpoints(it) != null
            }
    }

    private fun findEndpoints(device: UsbDevice): UsbEndpointPair? {
        for (i in 0 until device.interfaceCount) {
            val intf = device.getInterface(i)
            val pair = findBulkEndpointsInInterface(intf)
            if (pair != null) {
                return UsbEndpointPair(intf, pair.first, pair.second)
            }
        }
        return null
    }

    private fun findBulkEndpointsInInterface(intf: UsbInterface): Pair<UsbEndpoint, UsbEndpoint>? {
        var inEp: UsbEndpoint? = null
        var outEp: UsbEndpoint? = null

        for (e in 0 until intf.endpointCount) {
            val ep = intf.getEndpoint(e)
            if (ep.type != UsbConstants.USB_ENDPOINT_XFER_BULK) continue
            if (ep.direction == UsbConstants.USB_DIR_IN && inEp == null) {
                inEp = ep
            } else if (ep.direction == UsbConstants.USB_DIR_OUT && outEp == null) {
                outEp = ep
            }
        }

        return if (inEp != null && outEp != null) Pair(inEp, outEp) else null
    }

    private fun encodeUsbMidi(midiBytes: ByteArray): ByteArray {
        val out = ByteArrayOutputStream()
        var i = 0
        while (i < midiBytes.size) {
            val b0 = midiBytes[i].toInt() and 0xFF
            if (b0 == 0xF0) {
                i = encodeSysEx(midiBytes, i, out)
            } else {
                i += encodeChannelVoice(midiBytes, i, out)
            }
        }
        return out.toByteArray()
    }

    private fun encodeSysEx(data: ByteArray, start: Int, out: ByteArrayOutputStream): Int {
        var p = start
        while (p < data.size) {
            val (nextP, isDone) = encodeSysExChunk(data, p, out)
            p = nextP
            if (isDone) break
        }
        return p
    }

    private fun encodeSysExChunk(data: ByteArray, p: Int, out: ByteArrayOutputStream): Pair<Int, Boolean> {
        val rem = data.size - p
        if (rem >= 3) {
            val isEnd = (data[p + 2].toInt() and 0xFF) == 0xF7
            writeSysExPacket(out, if (isEnd) 0x07 else 0x04, data, p, 3)
            return Pair(p + 3, isEnd)
        }
        val cin = if (rem == 2) 0x06 else 0x05
        writeSysExPacket(out, cin, data, p, rem)
        return Pair(p + rem, true)
    }

    private fun writeSysExPacket(out: ByteArrayOutputStream, cin: Int, data: ByteArray, offset: Int, count: Int) {
        out.write(cin)
        for (k in 0 until 3) {
            val b = if (k < count) data[offset + k].toInt() and 0xFF else 0
            out.write(b)
        }
    }

    private fun encodeChannelVoice(data: ByteArray, offset: Int, out: ByteArrayOutputStream): Int {
        val b0 = data[offset].toInt() and 0xFF
        val status = b0 and 0xF0
        val len = data.size - offset

        return when (status) {
            0x80, 0x90, 0xA0, 0xB0, 0xE0 -> {
                out.write((status shr 4) and 0x0F)
                out.write(b0)
                out.write(if (len > 1) data[offset + 1].toInt() and 0xFF else 0)
                out.write(if (len > 2) data[offset + 2].toInt() and 0xFF else 0)
                minOf(3, len)
            }
            0xC0, 0xD0 -> {
                out.write((status shr 4) and 0x0F)
                out.write(b0)
                out.write(if (len > 1) data[offset + 1].toInt() and 0xFF else 0)
                out.write(0)
                minOf(2, len)
            }
            else -> {
                out.write(0x0F)
                out.write(b0)
                out.write(0)
                out.write(0)
                1
            }
        }
    }

    private fun decodeUsbMidi(buf: ByteArray, count: Int, out: ByteArrayOutputStream) {
        var p = 0
        while (p + 3 < count) {
            val cin = buf[p].toInt() and 0x0F
            val b1 = buf[p + 1].toInt() and 0xFF
            val b2 = buf[p + 2].toInt() and 0xFF
            val b3 = buf[p + 3].toInt() and 0xFF

            when (cin) {
                0x04, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0E -> {
                    out.write(b1)
                    out.write(b2)
                    out.write(b3)
                }
                0x06, 0x0C, 0x0D -> {
                    out.write(b1)
                    out.write(b2)
                }
                0x05, 0x0F -> {
                    out.write(b1)
                }
            }
            p += 4
        }
    }
}
