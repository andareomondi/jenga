import 'package:flutter/material.dart';
import 'package:jenga/presentation/screens/home_screen.dart';
import 'package:jenga/presentation/screens/game_setup_screen.dart';
import 'package:jenga/presentation/screens/how_to_play_screen.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/widgets/toast.dart';
import 'package:jenga/repo/bluetooth_repository.dart';
import 'package:jenga/repo/player_repository.dart';
import 'package:jenga/services/bluetooth_scanner_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bluetoothRepo = BluetoothRepository();
  final playerRepo = PlayerRepository();
  await playerRepo.initialize();
  await bluetoothRepo.initialize();
  runApp(const JengaApp());
}

class JengaApp extends StatelessWidget {
  const JengaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jenga',
      debugShowCheckedModeBanner: false,
      theme: buildJengaTheme(),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late BluetoothRepository _bluetoothRepository;
  HomeConnectionState _connectionState = HomeConnectionState.off;
  bool _bluetoothAvailable = false;
  bool _bluetoothEnabled = false;

  @override
  void initState() {
    super.initState();
    _bluetoothRepository = BluetoothRepository();
    _initializeBluetoothState();
  }

  Future<void> _initializeBluetoothState() async {
    _bluetoothRepository.adapterStateStream.listen((state) async {
      if (mounted) {
        await _refreshBluetoothStatus();
      }
    });
    await _refreshBluetoothStatus();
  }

  Future<void> _refreshBluetoothStatus() async {
    final available = await _bluetoothRepository.checkBluetoothAvailable();
    final enabled = await _bluetoothRepository.checkBluetoothEnabled();

    if (mounted) {
      setState(() {
        _bluetoothAvailable = available;
        _bluetoothEnabled = enabled;
        _updateConnectionState();
      });
    }
  }

  void _updateConnectionState() {
    if (!_bluetoothAvailable) {
      _connectionState = HomeConnectionState.permissionRequired;
    } else if (!_bluetoothEnabled) {
      _connectionState = HomeConnectionState.off;
    } else {
      // Bluetooth is enabled, allow user to proceed to game setup
      _connectionState = HomeConnectionState.connected;
    }
  }

  Future<void> _handleTurnOnBluetooth() async {
    try {
      final scannerService = BluetoothScannerService();
      await scannerService.enableBluetooth();
    } catch (e) {
      if (mounted) {
        ToastUtility.showError(
          context,
          message: 'Failed to turn on Bluetooth: $e',
        );
      }
    }
  }

  void _handleStartGame() {
    debugPrint('[Home] Navigating to Game Setup Screen...');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      connectionState: _connectionState,
      onStartGame: _handleStartGame,
      onTurnOnBluetooth: _handleTurnOnBluetooth,
      onRetryScan: _handleStartGame,
      onOpenSettings: () {
        ToastUtility.showDevelopmentWarning(context);
      },
      onHowToPlay: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
        );
      },
    );
  }
}
