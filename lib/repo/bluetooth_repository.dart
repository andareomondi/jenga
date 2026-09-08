import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jenga/models/tower_event.dart';
import 'package:jenga/services/bluetooth_scanner_service.dart';

class BluetoothRepository {
  static final BluetoothRepository _instance = BluetoothRepository._internal();
  factory BluetoothRepository() => _instance;
  BluetoothRepository._internal();

  final BluetoothScannerService _scannerService = BluetoothScannerService();
  late SharedPreferences _prefs;

  final List<BluetoothDevice> _discoveredDevices = [];
  List<BluetoothDevice> get discoveredDevices => _discoveredDevices;

  final List<BluetoothDevice> _bondedDevices = [];
  List<BluetoothDevice> get bondedDevices => _bondedDevices;

  // Single active subscription to the hardware
  StreamSubscription<Uint8List>? _rawStreamSubscription;

  // Broadcast Controller so multiple Cubits/Screens can listen simultaneously
  final StreamController<TowerEvent> _towerEventController =
      StreamController<TowerEvent>.broadcast();

  /// Public broadcast stream that safely accepts multiple listeners
  Stream<TowerEvent> get towerEventStream => _towerEventController.stream;

  static const String _lastDeviceMacKey = 'last_device_mac';
  static const String _lastDeviceNameKey = 'last_device_name';

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadBondedDevices();
      debugPrint('[BT-Repo] Repository initialized');
    } catch (e) {
      debugPrint('[BT-Repo] Error initializing repository: $e');
      rethrow;
    }
  }

  Future<void> _loadBondedDevices() async {
    try {
      _bondedDevices.clear();
      final devices = await _scannerService.getBondedDevices();
      _bondedDevices.addAll(devices);
      debugPrint('[BT-Repo] Loaded ${_bondedDevices.length} bonded devices');
    } catch (e) {
      debugPrint('[BT-Repo] Error loading bonded devices: $e');
    }
  }

  Future<Stream<BluetoothDevice>> scanForDevices({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      _discoveredDevices.clear();
      debugPrint('[BT-Repo] Starting device scan...');

      await _scannerService.startScan(timeout: timeout);

      return _scannerService.scanResults.map((device) {
        if (!_discoveredDevices.any((d) => d.address == device.address)) {
          _discoveredDevices.add(device);
          debugPrint(
            '[BT-Repo] Added device: ${device.name} (${device.address})',
          );
        }
        return device;
      });
    } catch (e) {
      debugPrint('[BT-Repo] Error scanning: $e');
      rethrow;
    }
  }

  Future<void> stopScan() async {
    try {
      await _scannerService.stopScan();
      debugPrint('[BT-Repo] Scan stopped');
    } catch (e) {
      debugPrint('[BT-Repo] Error stopping scan: $e');
      rethrow;
    }
  }

  Future<void> connectAndSaveDevice(BluetoothDevice device) async {
    try {
      debugPrint(
        '[BT-Repo] Connecting to device: ${device.name} (${device.address})',
      );
      await _scannerService.connect(device);

      await _prefs.setString(_lastDeviceMacKey, device.address);
      await _prefs.setString(_lastDeviceNameKey, device.name ?? 'Unknown');
      debugPrint('[BT-Repo] Device saved: ${device.name} (${device.address})');

      // Start the single stream pipeline
      _startDataStreamPipeline();
    } catch (e) {
      debugPrint('[BT-Repo] Error connecting and saving: $e');
      rethrow;
    }
  }

  /// Single internal subscription that logs AND broadcasts parsed events
  void _startDataStreamPipeline() {
    _rawStreamSubscription?.cancel();
    try {
      _rawStreamSubscription = _scannerService.getInputStream().listen(
        (data) {
          final decodedString = utf8.decode(data, allowMalformed: true);
          debugPrint(
            '[BT-Repo] 📥 Incoming message from device: $decodedString',
          );

          // Parse and emit via the broadcast controller
          final events = TowerEvent.parseStreamChunk(decodedString);
          for (final event in events) {
            _towerEventController.add(event);
          }
        },
        onError: (error) {
          debugPrint('[BT-Repo] ❌ Data stream error: $error');
          _towerEventController.addError(error);
        },
      );
    } catch (e) {
      debugPrint('[BT-Repo] ⚠️ Could not start data stream pipeline: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      await _rawStreamSubscription?.cancel();
      _rawStreamSubscription = null;
      await _scannerService.disconnect();
      debugPrint('[BT-Repo] Disconnected from device');
    } catch (e) {
      debugPrint('[BT-Repo] Error disconnecting: $e');
      rethrow;
    }
  }

  String? getLastDeviceMac() => _prefs.getString(_lastDeviceMacKey);
  String? getLastDeviceName() => _prefs.getString(_lastDeviceNameKey);

  Future<void> clearLastDevice() async {
    try {
      await _prefs.remove(_lastDeviceMacKey);
      await _prefs.remove(_lastDeviceNameKey);
      debugPrint('[BT-Repo] Last device cleared');
    } catch (e) {
      debugPrint('[BT-Repo] Error clearing device: $e');
      rethrow;
    }
  }

  bool hasLastDevice() => _prefs.getString(_lastDeviceMacKey) != null;

  BluetoothDevice? getDeviceByMac(String mac) {
    try {
      return _discoveredDevices.firstWhere(
        (device) => device.address == mac,
        orElse: () => throw Exception('Device not found'),
      );
    } catch (e) {
      debugPrint('[BT-Repo] Device not found: $mac');
      return null;
    }
  }

  List<BluetoothDevice> getAllDevices() {
    final allDevices = <BluetoothDevice>[];
    allDevices.addAll(_bondedDevices);
    for (final device in _discoveredDevices) {
      if (!allDevices.any((d) => d.address == device.address)) {
        allDevices.add(device);
      }
    }
    return allDevices;
  }

  Stream<Uint8List> getDataStream() => _scannerService.getInputStream();

  Future<void> sendData(String data) async {
    try {
      await _scannerService.sendString(data);
      debugPrint('[BT-Repo] 📤 Sent message to device: $data');
    } catch (e) {
      debugPrint('[BT-Repo] Error sending data: $e');
      rethrow;
    }
  }

  Future<bool> isConnected() async => await _scannerService.isConnected();
  BluetoothDevice? getConnectedDevice() => _scannerService.connectedDevice;
  Stream<bool> get isScanningStream => _scannerService.isScanningStream;
  Stream<BluetoothAdapterState> get adapterStateStream =>
      _scannerService.adapterState;
  Future<bool> checkBluetoothAvailable() async =>
      await _scannerService.checkAvailability();
  Future<bool> checkBluetoothEnabled() async =>
      await _scannerService.checkBluetoothEnabled();
}
