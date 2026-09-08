import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/widgets/buttons.dart';
import 'package:jenga/repo/bluetooth_repository.dart';

Future<BluetoothDevice?> showBluetoothScannerBottomSheet(
  BuildContext context, {
  required VoidCallback onDeviceSelected,
}) {
  return showModalBottomSheet<BluetoothDevice?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false,
    builder: (_) =>
        BluetoothScannerBottomSheet(onDeviceSelected: onDeviceSelected),
  );
}

class BluetoothScannerBottomSheet extends StatefulWidget {
  const BluetoothScannerBottomSheet({
    super.key,
    required this.onDeviceSelected,
  });
  final VoidCallback onDeviceSelected;
  @override
  State<BluetoothScannerBottomSheet> createState() =>
      _BluetoothScannerBottomSheetState();
}

class _BluetoothScannerBottomSheetState
    extends State<BluetoothScannerBottomSheet> {
  late BluetoothRepository _repository;
  final List<BluetoothDevice> _discoveredDevices = [];
  bool _isScanning = false;
  String? _selectedDeviceMac;
  StreamSubscription<BluetoothDevice>? _scanSubscription;
  @override
  void initState() {
    super.initState();
    _repository = BluetoothRepository();
    _startScan();
  }

  Future<void> _startScan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
    });
    try {
      final scanStream = await _repository.scanForDevices();
      _scanSubscription = scanStream.listen(
        (device) {
          if (mounted) {
            setState(() {
              if (!_discoveredDevices.any((d) => d.address == device.address)) {
                _discoveredDevices.add(device);
              }
            });
          }
        },
        onError: (error) {
          debugPrint('[Scanner] Scan error: $error');
          if (mounted) {
            setState(() => _isScanning = false);
          }
        },
        onDone: () {
          if (mounted) {
            setState(() => _isScanning = false);
          }
        },
      );
      await Future.delayed(const Duration(seconds: 15));
      if (mounted && _isScanning) {
        await _stopScan();
      }
    } catch (e) {
      debugPrint('[Scanner] Error starting scan: $e');
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _stopScan() async {
    try {
      await _scanSubscription?.cancel();
      await _repository.stopScan();
      if (mounted) {
        setState(() => _isScanning = false);
      }
    } catch (e) {
      debugPrint('[Scanner] Error stopping scan: $e');
    }
  }

  Future<void> _selectDevice(BluetoothDevice device) async {
    setState(() => _selectedDeviceMac = device.address);
    try {
      await _stopScan();
      await _repository.connectAndSaveDevice(device);
      if (mounted) {
        widget.onDeviceSelected();
        Navigator.pop(context, device);
      }
    } catch (e) {
      debugPrint('[Scanner] Error selecting device: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: AppColors.coral,
          ),
        );
        setState(() => _selectedDeviceMac = null);
      }
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _repository.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.walnut.withOpacity(0.18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Connect to Jenga Tower',
              style: AppText.display(size: 22),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _isScanning ? 'Scanning for devices...' : 'Select a device',
              style: AppText.body(size: 14, color: AppColors.walnutSoft),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _discoveredDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isScanning
                              ? Icons.bluetooth_searching
                              : Icons.bluetooth_disabled,
                          size: 48,
                          color: AppColors.walnutSoft,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isScanning
                              ? 'Scanning for devices...'
                              : 'No devices found',
                          style: AppText.body(
                            size: 16,
                            color: AppColors.walnutSoft,
                          ),
                        ),
                        if (!_isScanning) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Make sure your tower is powered on\nand nearby',
                            style: AppText.body(
                              size: 13,
                              color: AppColors.walnutSoft,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _discoveredDevices.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0x0F2E2019)),
                    itemBuilder: (context, index) {
                      final device = _discoveredDevices[index];
                      final isSelected = _selectedDeviceMac == device.address;
                      final isConnecting =
                          _selectedDeviceMac == device.address && isSelected;
                      return Material(
                        color: Colors.white,
                        child: InkWell(
                          onTap: isConnecting
                              ? null
                              : () => _selectDevice(device),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.bluetooth,
                                  size: 20,
                                  color: AppColors.amber,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        device.name ?? 'Unknown',
                                        style: AppText.body(
                                          size: 15,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        device.address,
                                        style: AppText.body(
                                          size: 12,
                                          color: AppColors.walnutSoft,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: isConnecting
                                        ? const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.felt,
                                          )
                                        : const Icon(
                                            Icons.check_circle,
                                            color: AppColors.felt,
                                            size: 20,
                                          ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          if (_isScanning)
            SecondaryButton(label: 'Stop Scanning', onPressed: _stopScan)
          else
            Column(
              children: [
                SecondaryButton(label: 'Scan Again', onPressed: _startScan),
                const SizedBox(height: 10),
                GhostTextButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
