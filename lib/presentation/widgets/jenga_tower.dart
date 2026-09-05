import 'dart:math';
import 'package:flutter/material.dart';

/// Which block (if any) is currently mid-removal-animation.
class RemovingBlock {
  const RemovingBlock({required this.layerIndex, required this.blockIndex});
  final int layerIndex;
  final int blockIndex;
}

/// The signature visual element of the app: a stylized stack of 14 layers
/// (54 blocks total, minus 2 removed = one full tower). Communicates layer
/// count, orientation alternation, and — through [wobble]/[isCollapsed] —
/// rising tension as the physical game progresses.
class JengaTower extends StatefulWidget {
  const JengaTower({
    super.key,
    required this.fullLayers,
    this.blockWidth = 15,
    this.blockHeight = 46,
    this.gap = 3,
    this.wobble = false,
    this.isCollapsed = false,
    this.removing,
    this.placingTopLayer = false,
  });

  /// Number of intact layers remaining (0–14). 14 = full tower (54 blocks).
  final int fullLayers;
  final double blockWidth;
  final double blockHeight;
  final double gap;

  /// Subtle shake — shown when the tower is getting unstable.
  final bool wobble;

  /// Plays the toppling animation. Used for the game-over moment.
  final bool isCollapsed;

  /// If set, animates that specific block sliding out (block-removed state).
  final RemovingBlock? removing;

  /// If true, animates a new block dropping onto the top layer (placement state).
  final bool placingTopLayer;

  static const int totalLayers = 14;

  @override
  State<JengaTower> createState() => _JengaTowerState();
}

class _JengaTowerState extends State<JengaTower> with TickerProviderStateMixin {
  late final AnimationController _wobbleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..repeat(reverse: true);

  late final AnimationController _collapseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  final _rand = Random(7);

  @override
  void didUpdateWidget(covariant JengaTower old) {
    super.didUpdateWidget(old);
    if (widget.isCollapsed && !old.isCollapsed) {
      _collapseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _collapseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layers = List.generate(JengaTower.totalLayers, (i) => i);

    Widget stack = Column(
      mainAxisSize: MainAxisSize.min,
      verticalDirection:
          VerticalDirection.up, // bottom layer first, stack grows up
      children: [for (final i in layers) _buildLayer(i)],
    );

    if (widget.wobble) {
      stack = AnimatedBuilder(
        animation: _wobbleController,
        builder: (context, child) {
          final angle = (_wobbleController.value - 0.5) * 0.02; // ~±0.6deg
          return Transform.rotate(angle: angle, child: child);
        },
        child: stack,
      );
    }

    return stack;
  }

  Widget _buildLayer(int layerIndex) {
    final isGhost = layerIndex >= widget.fullLayers;
    final isVertical =
        layerIndex.isEven; // alternate orientation between layers
    final isTopIntactLayer = layerIndex == widget.fullLayers - 1;

    Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (blockIndex) {
        final isRemoving =
            widget.removing?.layerIndex == layerIndex &&
            widget.removing?.blockIndex == blockIndex;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.gap / 2),
          child: _JengaBlock(
            width: isVertical ? widget.blockWidth : widget.blockHeight,
            height: isVertical ? widget.blockHeight : widget.blockWidth,
            ghost: isGhost,
            removing: isRemoving,
          ),
        );
      }),
    );

    if (widget.placingTopLayer && isTopIntactLayer) {
      row = TweenAnimationBuilder<double>(
        tween: Tween(begin: -70, end: 0),
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutBack,
        builder: (context, dy, child) =>
            Transform.translate(offset: Offset(0, dy), child: child),
        child: row,
      );
    }

    if (widget.isCollapsed) {
      final dx = (_rand.nextDouble() - 0.5) * 160;
      final rot = (_rand.nextDouble() - 0.5) * 1.2;
      final delay = layerIndex * 0.03;
      return AnimatedBuilder(
        animation: _collapseController,
        builder: (context, child) {
          final t = ((_collapseController.value - delay).clamp(0.0, 1.0));
          final curved = Curves.easeIn.transform(t);
          return Opacity(
            opacity: 1 - curved,
            child: Transform.translate(
              offset: Offset(dx * curved, 260 * curved),
              child: Transform.rotate(angle: rot * curved, child: child),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: row,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: row,
    );
  }
}

class _JengaBlock extends StatelessWidget {
  const _JengaBlock({
    required this.width,
    required this.height,
    this.ghost = false,
    this.removing = false,
  });

  final double width;
  final double height;
  final bool ghost;
  final bool removing;

  @override
  Widget build(BuildContext context) {
    final block = AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD9A768), Color(0xFFC17F3E), Color(0xFFA2652C)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E2E2019),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(opacity: ghost ? 0.16 : 1),
    );

    if (!removing) return block;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeIn,
      builder: (context, t, child) {
        return Opacity(
          opacity: 1 - t,
          child: Transform.translate(
            offset: Offset(120 * t, 0),
            child: Transform.rotate(angle: 0.25 * t, child: child),
          ),
        );
      },
      child: block,
    );
  }
}
