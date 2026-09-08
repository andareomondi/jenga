import 'package:flutter/foundation.dart';
import 'package:jenga/models/bluetooth_device_model.dart';
import 'dart:async';

import 'package:jenga/repo/bluetooth_repository.dart';

/// Service for handling data streams from Bluetooth devices
class BluetoothDataStreamService {
  static final BluetoothDataStreamService _instance =
      BluetoothDataStreamService._internal();

  factory BluetoothDataStreamService() {
    return _instance;
  }

  BluetoothDataStreamService._internal();

  final BluetoothRepository _repository = BluetoothRepository();
  StreamSubscription<Uint8List>? _dataSubscription;
  final StreamController<BluetoothDataModel> _dataStreamController =
      StreamController<BluetoothDataModel>.broadcast();

  /// Get stream of data received from the device
  Stream<BluetoothDataModel> get dataStream => _dataStreamController.stream;

  /// Start listening to data from the connected device
  void startListening() {
    try {
      // Cancel any existing subscription
      _dataSubscription?.cancel();

      final inputStream = _repository.getDataStream();

      _dataSubscription = inputStream.listen(
        (data) {
          final dataModel = BluetoothDataModel.fromBytes(data);
          debugPrint('[BT-Stream] Received: ${dataModel.data}');
          _dataStreamController.add(dataModel);
        },
        onError: (error) {
          debugPrint('[BT-Stream] Error receiving data: $error');
          final errorModel = BluetoothDataModel(
            data: 'Error: $error',
            timestamp: DateTime.now(),
            isError: true,
          );
          _dataStreamController.add(errorModel);
        },
        onDone: () {
          debugPrint('[BT-Stream] Data stream closed');
        },
      );

      debugPrint('[BT-Stream] Started listening for data');
    } catch (e) {
      debugPrint('[BT-Stream] Error starting listener: $e');
    }
  }

  /// Stop listening to data
  void stopListening() {
    try {
      _dataSubscription?.cancel();
      _dataSubscription = null;
      debugPrint('[BT-Stream] Stopped listening');
    } catch (e) {
      debugPrint('[BT-Stream] Error stopping listener: $e');
    }
  }

  /// Send data to the device
  Future<void> sendData(String data) async {
    try {
      await _repository.sendData(data);
      debugPrint('[BT-Stream] Sent: $data');
    } catch (e) {
      debugPrint('[BT-Stream] Error sending data: $e');
      rethrow;
    }
  }

  /// Parse block removal event from device data
  /// Expected format: "BLOCK_REMOVED:layer:position"
  /// Returns null if format is invalid
  BlockRemovedEvent? parseBlockRemovedEvent(String data) {
    try {
      if (!data.startsWith('BLOCK_REMOVED:')) return null;

      final parts = data.split(':');
      if (parts.length != 3) return null;

      final layer = int.parse(parts[1]);
      final position = int.parse(parts[2]);

      return BlockRemovedEvent(layer: layer, position: position);
    } catch (e) {
      debugPrint('[BT-Stream] Error parsing block event: $e');
      return null;
    }
  }

  /// Parse tower collapse event from device data
  /// Expected format: "TOWER_COLLAPSE"
  bool parseTowerCollapseEvent(String data) {
    return data == 'TOWER_COLLAPSE';
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _dataStreamController.close();
    debugPrint('[BT-Stream] Service disposed');
  }
}

/// Event model for block removal
class BlockRemovedEvent {
  final int layer; // 0-13
  final int position; // 0-2

  BlockRemovedEvent({required this.layer, required this.position});

  @override
  String toString() => 'BlockRemovedEvent(layer: $layer, pos: $position)';
}

/// Event model for tower collapse
class TowerCollapseEvent {
  final DateTime timestamp;

  TowerCollapseEvent({DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'TowerCollapseEvent(time: $timestamp)';
}
