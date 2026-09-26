import 'package:flutter/material.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/widgets/bluetooth_status_pill.dart';
import 'package:jenga/presentation/widgets/buttons.dart';
import 'package:jenga/presentation/widgets/jenga_tower.dart';
import 'package:jenga/presentation/screens/settings_screen.dart'; // Import

/// Home screen states — all variants of a single Home experience
enum HomeConnectionState {
  connected,
  off,
  permissionRequired,
  searching,
  notFound,
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.connectionState = HomeConnectionState.connected,
    required this.onStartGame,
    this.onOpenSettings,
    this.onHowToPlay,
    this.onTurnOnBluetooth,
    this.onOpenPermissions,
    this.onCancelScan,
    this.onRetryScan,
  });

  final HomeConnectionState connectionState;
  final VoidCallback onStartGame;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onHowToPlay;
  final VoidCallback? onTurnOnBluetooth;
  final VoidCallback? onOpenPermissions;
  final VoidCallback? onCancelScan;
  final VoidCallback? onRetryScan;

  bool get _isConnected => connectionState == HomeConnectionState.connected;

  void _handleOpenSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text('Jenga', style: AppText.display(size: 36)),
              const SizedBox(height: 6),
              Text(
                _subtitle,
                style: AppText.body(size: 14.5, color: AppColors.walnutSoft),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              _statusPill(),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Opacity(
                    opacity: _isConnected ? 1 : 0.35,
                    child: JengaTower(
  wobble: _isConnected ? false : true,
  totalBlocks: 54, // 54 blocks = 18 full layers
  blockWidth: 15,
  blockHeight: 44,
),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              _actions(context),
            ],
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    switch (connectionState) {
      case HomeConnectionState.connected:
        return 'Your companion for the physical game';
      case HomeConnectionState.off:
        return 'Turn on Bluetooth to connect to\nyour Jenga tower.';
      case HomeConnectionState.permissionRequired:
        return 'Jenga needs Bluetooth access to\nfind and connect to your tower.';
      case HomeConnectionState.searching:
        return 'Make sure the tower module is powered on.';
      case HomeConnectionState.notFound:
        return "Check that it's powered on and nearby,\nthen try again.";
    }
  }

  Widget _statusPill() {
    switch (connectionState) {
      case HomeConnectionState.connected:
        return const BluetoothStatusPill(
          variant: BluetoothPillVariant.connected,
        );
      case HomeConnectionState.off:
        return const BluetoothStatusPill(variant: BluetoothPillVariant.off);
      case HomeConnectionState.searching:
        return const BluetoothStatusPill(
          variant: BluetoothPillVariant.searching,
        );
      case HomeConnectionState.permissionRequired:
      case HomeConnectionState.notFound:
        return const SizedBox(height: 0);
    }
  }

  Widget _actions(BuildContext context) {
    switch (connectionState) {
      case HomeConnectionState.connected:
        return Column(
          children: [
            PrimaryButton(label: 'New Game', onPressed: onStartGame),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GhostTextButton(label: 'How to Play', onPressed: onHowToPlay),
                const SizedBox(width: 8),
                GhostTextButton(
                  label: 'Settings',
                  onPressed: () => _handleOpenSettings(context),
                ),
              ],
            ),
          ],
        );
      case HomeConnectionState.off:
        return Column(
          children: [
            PrimaryButton(
              label: 'Turn On Bluetooth',
              onPressed: onTurnOnBluetooth,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GhostTextButton(label: 'How to Play', onPressed: onHowToPlay),
                const SizedBox(width: 8),
                GhostTextButton(
                  label: 'Settings',
                  onPressed: () => _handleOpenSettings(context),
                ),
              ],
            ),
          ],
        );
      case HomeConnectionState.permissionRequired:
        return PrimaryButton(
          label: 'Open Settings',
          onPressed: onOpenPermissions,
        );
      case HomeConnectionState.searching:
        return SecondaryButton(label: 'Cancel', onPressed: onCancelScan);
      case HomeConnectionState.notFound:
        return Column(
          children: [
            PrimaryButton(
              label: 'Try Again',
              onPressed: onRetryScan ?? onStartGame,
            ),
            const SizedBox(height: 6),
            GhostTextButton(
              label: 'Settings',
              onPressed: () => _handleOpenSettings(context),
            ),
          ],
        );
    }
  }
}
