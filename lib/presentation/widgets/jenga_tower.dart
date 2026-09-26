import 'dart:math';
import 'package:flutter/material.dart';

/// The signature visual element of the app: a stylized stack of layers.
/// Dynamically calculates exact block layout based on [totalBlocks].
class JengaTower extends StatefulWidget {
  const JengaTower({
    super.key,
    required this.totalBlocks,
    this.blockWidth = 15,
    this.blockHeight = 46,
    this.gap = 3,
    this.wobble = false,
    this.isCollapsed = false,
    this.isRemoving = false, // Replaced positional RemovingBlock with a boolean
    this.placingOnTop = false, 
  });

  /// Total number of blocks currently in the tower (e.g., from Cubit state)
  final int totalBlocks;
  final double blockWidth;
  final double blockHeight;
  final double gap;
  final bool wobble;
  final bool isCollapsed;
  final bool isRemoving;
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
    // If placing on top, we visually simulate an extra block dropping in
    final int visibleBlocks = widget.placingOnTop ? widget.totalBlocks + 1 : widget.totalBlocks;
    final int totalLayerCount = (visibleBlocks / 3).ceil();
    final layers = List.generate(totalLayerCount, (i) => i);

    Widget stack = Column(
      mainAxisSize: MainAxisSize.min,
      verticalDirection: VerticalDirection.up, 
      children: [for (final i in layers) _buildLayer(i, totalLayerCount, visibleBlocks)],
    );

    if (widget.wobble) {
      stack = AnimatedBuilder(
        animation: _wobbleController,
        builder: (context, child) {
          final angle = sin(_wobbleController.value * pi * 2) * 0.015; 
          return Transform.rotate(
            angle: angle, 
            alignment: Alignment.bottomCenter,
            child: child,
          );
        },
        child: stack,
      );
    }

    return stack;
  }

  Widget _buildLayer(int layerIndex, int totalLayerCount, int visibleBlocks) {
    final isVertical = layerIndex.isEven; 
    
    // Determine how many blocks belong in this specific layer
    int blocksInThisLayer = 3;
    if (layerIndex == totalLayerCount - 1) {
      blocksInThisLayer = visibleBlocks % 3;
      if (blocksInThisLayer == 0) blocksInThisLayer = 3;
    }

    // Pick a pseudo-random stable block to slide out if a removal is happening
    int targetRemoveLayer = totalLayerCount - 3;
    if (targetRemoveLayer < 0) targetRemoveLayer = 0;
    const int targetRemoveBlock = 1; // Slide out the middle block

    Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      // Always generate 3 slots to maintain structural alignment when layer is incomplete
      children: List.generate(3, (blockIndex) {
        
        // Render an empty space for missing blocks
        if (blockIndex >= blocksInThisLayer) {
          return Padding(
             padding: EdgeInsets.symmetric(horizontal: widget.gap / 2),
             child: SizedBox(
               width: isVertical ? widget.blockWidth : widget.blockHeight,
               height: isVertical ? widget.blockHeight : widget.blockWidth,
             ),
          );
        }

        final isAnimateRemoving = widget.isRemoving &&
                                  layerIndex == targetRemoveLayer &&
                                  blockIndex == targetRemoveBlock;

        final isNewTopBlock = widget.placingOnTop && 
                              layerIndex == totalLayerCount - 1 && 
                              blockIndex == blocksInThisLayer - 1;

        Widget block = Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.gap / 2),
          child: _JengaBlock(
            width: isVertical ? widget.blockWidth : widget.blockHeight,
            height: isVertical ? widget.blockHeight : widget.blockWidth,
            ghost: false, 
            removing: isAnimateRemoving,
            isVerticalOrientation: isVertical,
          ),
        );

        // Animate ONLY the newly placed top block, not the entire layer
        if (isNewTopBlock) {
          block = TweenAnimationBuilder<double>(
            key: ValueKey('top_placement_block_$visibleBlocks'),
            tween: Tween(begin: -100, end: 0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.bounceOut,
            builder: (context, dy, child) =>
                Transform.translate(offset: Offset(0, dy), child: child),
            child: block,
          );
        }

        return block;
      }),
    );

    if (widget.isCollapsed) {
      final dx = (_rand.nextDouble() - 0.5) * 220;
      final dy = 300.0 + (_rand.nextDouble() * 100);
      final rot = (_rand.nextDouble() - 0.5) * 2.5;
      final delay = (totalLayerCount - layerIndex) * 0.04; 

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
            ? Offset(0, _translationAnimation.value) 
            : Offset(_translationAnimation.value, 0); 

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