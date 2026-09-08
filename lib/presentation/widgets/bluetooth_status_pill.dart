import 'package:flutter/material.dart';
import 'package:jenga/presentation/theme/theme.dart';

enum BluetoothPillVariant { connected, off, searching }

/// Small, non-dominant connection indicator shown on the Home screen.
/// Deliberately quiet — Bluetooth status should never compete with the
/// "New Game" call to action.
class BluetoothStatusPill extends StatefulWidget {
  const BluetoothStatusPill({super.key, required this.variant});

  final BluetoothPillVariant variant;

  @override
  State<BluetoothStatusPill> createState() => _BluetoothStatusPillState();
}

class _BluetoothStatusPillState extends State<BluetoothStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    late String label;
    Widget dot;

    switch (widget.variant) {
      case BluetoothPillVariant.connected:
        bg = AppColors.feltPale;
        fg = AppColors.felt;
        label = 'Bluetooth is on';
        dot = Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
        );
        break;
      case BluetoothPillVariant.off:
        bg = AppColors.coralPale;
        fg = AppColors.coral;
        label = 'Bluetooth is off';
        dot = Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
        );
        break;
      case BluetoothPillVariant.searching:
        bg = AppColors.amberPale;
        fg = AppColors.amberDeep;
        label = 'Searching';
        dot = FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.35).animate(_pulseController),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 7),
          Text(
            label,
            style: AppText.body(size: 12.5, weight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}
