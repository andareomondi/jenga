import 'dart:async';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:flutter/foundation.dart';

class BluetoothScannerService {
  static final BluetoothScannerService _instance =
      BluetoothScannerService._internal();
  factory BluetoothScannerService() {
    return _instance;
  }
  BluetoothScannerService._internal();
  final FlutterBlueClassic _bluetoothClassic = FlutterBlueClassic();
  BluetoothConnection? _connection;
  Stream<BluetoothAdapterState> get adapterState =>
      _bluetoothClassic.adapterState;
  Stream<bool> get isScanningStream => _bluetoothClassic.isScanning;
  Stream<BluetoothDevice> get scanResults => _bluetoothClassic.scanResults;
  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  Future<bool> get isScanning => _bluetoothClassic.isScanningNow;
  Future<bool> checkAvailability() async {
    try {
      final bool available = await _bluetoothClassic.isSupported;
      debugPrint('[BT] Bluetooth availability: $available');
      return available;
    } catch (e) {
      debugPrint('[BT] Error checking availability: $e');
      return false;
    }
  }

  Future<bool> checkBluetoothEnabled() async {
    try {
      final enabled = await _bluetoothClassic.isEnabled;
      debugPrint('[BT] Bluetooth enabled: $enabled');
      return enabled;
    } catch (e) {
      debugPrint('[BT] Error checking Bluetooth state: $e');
      return false;
    }
  }

  Future<void> enableBluetooth() async {
    try {
      await _bluetoothClassic.turnOn();
      debugPrint('[BT] Bluetooth enable requested');
    } catch (e) {
      debugPrint('[BT] Error enabling Bluetooth: $e');
      rethrow;
    }
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      debugPrint('[BT] Starting device scan...');
      _bluetoothClassic.startScan();
      debugPrint('[BT] Started device scan');
      Future.delayed(timeout, () async {
        if (await _bluetoothClassic.isScanningNow) {
          await stopScan();
          debugPrint('[BT] Scan timeout after ${timeout.inSeconds}s');
        }
      });
    } catch (e) {
      debugPrint('[BT] Error starting scan: $e');
      rethrow;
    }
  }

  Future<void> stopScan() async {
    try {
      _bluetoothClassic.stopScan();
      debugPrint('[BT] Scan cancelled');
    } catch (e) {
      debugPrint('[BT] Error stopping scan: $e');
      rethrow;
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      debugPrint('[BT] Connecting to ${device.name} (${device.address})...');
      _connection = await _bluetoothClassic.connect(device.address);
      _connectedDevice = device;
      debugPrint('[BT] Connected to ${device.name}');
    } catch (e) {
      debugPrint('[BT] Error connecting: $e');
      _connectedDevice = null;
      _connection = null;
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      if (_connection == null) {
        debugPrint('[BT] No device connected');
        return;
      }
      debugPrint('[BT] Disconnecting from ${_connectedDevice?.name}...');
      _connection!.close();
      _connectedDevice = null;
      _connection = null;
      debugPrint('[BT] Disconnected');
    } catch (e) {
      debugPrint('[BT] Error disconnecting: $e');
      rethrow;
    }
  }

  Stream<Uint8List> getInputStream() {
    if (_connection == null || _connection!.input == null) {
      throw Exception('No device connected or input stream is unavailable');
    }
    return _connection!.input!;
  }

  Future<void> sendData(Uint8List data) async {
    try {
      if (_connection == null) {
        throw Exception('No device connected');
      }
      _connection!.output.add(data);
      debugPrint('[BT] Data sent');
    } catch (e) {
      debugPrint('[BT] Error sending data: $e');
      rethrow;
    }
  }

  Future<void> sendString(String text) async {
    try {
      if (_connection == null) {
        throw Exception('No device connected');
      }
      _connection!.writeString(text);
      debugPrint('[BT] String sent: $text');
    } catch (e) {
      debugPrint('[BT] Error sending string: $e');
      rethrow;
    }
  }

  Future<bool> isConnected() async {
    try {
      return _connection?.isConnected ?? false;
    } catch (e) {
      debugPrint('[BT] Error checking connection: $e');
      return false;
    }
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final devices = await _bluetoothClassic.bondedDevices;
      debugPrint('[BT] Found ${devices?.length ?? 0} bonded devices');
      return devices?.toList() ?? [];
    } catch (e) {
      debugPrint('[BT] Error getting bonded devices: $e');
      return [];
    }
  }
}
