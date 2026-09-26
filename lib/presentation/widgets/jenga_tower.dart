import 'dart:math';
import 'package:flutter/material.dart';

/// Which block (if any) is currently mid-removal-animation.
class RemovingBlock {
  const RemovingBlock({required this.layerIndex, required this.blockIndex});
  final int layerIndex;
  final int blockIndex;
}

/// The signature visual element of the app: a stylized stack of layers
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
    this.placingOnTop = false, // Replaced placingTopLayer with placingOnTop
  });

  /// Base number of intact layers remaining (0–14). 14 = full tower (54 blocks).
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

  /// If true, builds an extra dynamic layer on top of the current tower 
  /// and animates it dropping into place.
  final bool placingOnTop;

  @override
  State<JengaTower> createState() => _JengaTowerState();
}

class _JengaTowerState extends State<JengaTower> with TickerProviderStateMixin {
  late final AnimationController _wobbleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..repeat(reverse: true);

  late final AnimationController _collapseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
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
    // Determine total layers to draw. If placingOnTop is active, we expand the 
    // list count by one to accommodate the newly built row.
    final visibleLayerCount = widget.placingOnTop ? widget.fullLayers + 1 : widget.fullLayers;
    final layers = List.generate(visibleLayerCount, (i) => i);

    Widget stack = Column(
      mainAxisSize: MainAxisSize.min,
      verticalDirection: VerticalDirection.up, // bottom layer first, stack grows up
      children: [for (final i in layers) _buildLayer(i, visibleLayerCount)],
    );

    if (widget.wobble) {
      stack = AnimatedBuilder(
        animation: _wobbleController,
        builder: (context, child) {
          final angle = sin(_wobbleController.value * pi * 2) * 0.015; 
          return Transform.rotate(
            angle: angle, 
            alignment: Alignment.bottomCenter, // Wobbles realistically from its root base
            child: child,
          );
        },
        child: stack,
      );
    }

    return stack;
  }

  Widget _buildLayer(int layerIndex, int totalLayerCount) {
    final isVertical = layerIndex.isEven; // alternate orientation based on the layer count index
    final isNewTopLayer = widget.placingOnTop && (layerIndex == totalLayerCount - 1);

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
            ghost: false, // The dynamic topmost layers are active pieces, not transparent placeholders
            removing: isRemoving,
            isVerticalOrientation: isVertical,
          ),
        );
      }),
    );

    // If this specific layer is the freshly added top layer, animate its arrival drop
    if (isNewTopLayer) {
      row = TweenAnimationBuilder<double>(
        // Explicit unique key forces the animation to play fresh whenever a new layer triggers it
        key: ValueKey('top_placement_layer_$layerIndex'),
        tween: Tween(begin: -100, end: 0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.bounceOut, // Tactile bouncing drop feedback onto the stack
        builder: (context, dy, child) =>
            Transform.translate(offset: Offset(0, dy), child: child),
        child: row,
      );
    }

    if (widget.isCollapsed) {
      final dx = (_rand.nextDouble() - 0.5) * 220;
      final dy = 300.0 + (_rand.nextDouble() * 100);
      final rot = (_rand.nextDouble() - 0.5) * 2.5;
      final delay = (totalLayerCount - layerIndex) * 0.04; // Tops collapse first!

      return AnimatedBuilder(
        animation: _collapseController,
        builder: (context, child) {
          final t = ((_collapseController.value - delay).clamp(0.0, 1.0));
          final curved = Curves.easeInQuad.transform(t);
          return Opacity(
            opacity: (1 - (t * 1.5)).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(dx * curved, dy * curved),
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

class _JengaBlock extends StatefulWidget {
  const _JengaBlock({
    required this.width,
    required this.height,
    required this.isVerticalOrientation,
    this.ghost = false,
    this.removing = false,
  });

  final double width;
  final double height;
  final bool ghost;
  final bool removing;
  final bool isVerticalOrientation;

  @override
  State<_JengaBlock> createState() => _JengaBlockState();
}

class _JengaBlockState extends State<_JengaBlock> with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<double> _translationAnimation;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _translationAnimation = Tween<double>(begin: 0.0, end: 140.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInCubic),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.35).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );

    if (widget.removing) {
      _slideController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _JengaBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.removing && !oldWidget.removing) {
      _slideController.forward(from: 0.0);
    } else if (!widget.removing && oldWidget.removing) {
      _slideController.reverse();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        final translationOffset = widget.isVerticalOrientation
            ? Offset(0, _translationAnimation.value) // Slides out along Y axis
            : Offset(_translationAnimation.value, 0); // Slides out along X axis

        return Opacity(
          opacity: widget.ghost ? 0.16 : _fadeAnimation.value,
          child: Transform.translate(
            offset: translationOffset,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
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
      ),
    );
  }
}
