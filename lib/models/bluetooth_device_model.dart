import 'package:flutter_blue_classic/flutter_blue_classic.dart';

/// Represents a Bluetooth device with additional metadata
class BluetoothDeviceModel {
  final BluetoothDevice device;
  final String name;
  final String address;
  final bool isBonded;
  final bool isConnected;

  BluetoothDeviceModel({
    required this.device,
    required this.name,
    required this.address,
    required this.isBonded,
    this.isConnected = false,
  });

  /// Create from BluetoothDevice
  factory BluetoothDeviceModel.fromDevice(
    BluetoothDevice device, {
    bool isConnected = false,
  }) {
    return BluetoothDeviceModel(
      device: device,
      name: device.name ?? 'Unknown',
      address: device.address,
      isBonded: device.bondState == BluetoothBondState.bonded,
      isConnected: isConnected,
    );
  }

  /// Copy with modifications
  BluetoothDeviceModel copyWith({
    BluetoothDevice? device,
    String? name,
    String? address,
    bool? isBonded,
    bool? isConnected,
  }) {
    return BluetoothDeviceModel(
      device: device ?? this.device,
      name: name ?? this.name,
      address: address ?? this.address,
      isBonded: isBonded ?? this.isBonded,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  String toString() =>
      'BluetoothDeviceModel(name: $name, address: $address, bonded: $isBonded)';
}

/// Enum for Bluetooth connection states
enum BluetoothConnectionStatus {
  /// Bluetooth is not available on the device
  unavailable,

  /// Bluetooth is available but disabled
  disabled,

  /// Bluetooth is enabled but requires permission
  permissionRequired,

  /// Currently scanning for devices
  scanning,

  /// No devices found during scan
  notFound,

  /// Successfully connected to a device
  connected,

  /// Failed to connect to device
  connectionFailed,

  /// Disconnected from device
  disconnected,
}

/// Model for data received from Bluetooth device
class BluetoothDataModel {
  final String data;
  final DateTime timestamp;
  final bool isError;

  BluetoothDataModel({
    required this.data,
    required this.timestamp,
    this.isError = false,
  });

  /// Create from raw bytes
  factory BluetoothDataModel.fromBytes(List<int> bytes) {
    return BluetoothDataModel(
      data: String.fromCharCodes(bytes),
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() => 'BluetoothDataModel(data: $data, time: $timestamp)';
}
