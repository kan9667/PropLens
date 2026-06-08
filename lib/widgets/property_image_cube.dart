import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../data/properties.dart';

/// Animated 3D Rubik's-cube style grid — each sticker shows a property photo.
class PropertyImageCube extends StatefulWidget {
  final double size;

  const PropertyImageCube({super.key, this.size = 240});

  @override
  State<PropertyImageCube> createState() => _PropertyImageCubeState();
}

class _PropertyImageCubeState extends State<PropertyImageCube> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  List<String> get _images => mockProperties.map((p) => p.imageUrl).toList();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _sticker(String url) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.primaryLight,
            alignment: Alignment.center,
            child: const Icon(Icons.home_work_rounded, color: AppColors.primary, size: 16),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: AppColors.surface,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _faceGrid(int imageOffset, Color tint) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
          boxShadow: const [AppColors.cardShadow],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: List.generate(3, (row) {
              return Expanded(
                child: Row(
                  children: List.generate(3, (col) {
                    final index = row * 3 + col;
                    final url = _images[(imageOffset + index) % _images.length];
                    return Expanded(child: _sticker(url));
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _cubeFace({
    required int imageOffset,
    required Color tint,
    required Matrix4 matrix,
  }) {
    return Center(
      child: Transform(
        transform: matrix,
        alignment: Alignment.center,
        transformHitTests: false,
        child: _faceGrid(imageOffset, tint),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final half = widget.size / 2;
    final outer = widget.size * 1.75;

    return SizedBox(
      width: outer,
      height: outer,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value * 2 * math.pi;
          final rotY = t * 0.55;
          final rotX = math.sin(t * 0.35) * 0.25;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(rotY)
              ..rotateX(rotX),
            child: child,
          );
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              _cubeFace(
                imageOffset: 0,
                tint: const Color(0xFF00C37A),
                matrix: Matrix4.translationValues(0, 0, half),
              ),
              _cubeFace(
                imageOffset: 9,
                tint: const Color(0xFF1A6B4A),
                matrix: Matrix4.translationValues(half, 0, 0)..rotateY(math.pi / 2),
              ),
              _cubeFace(
                imageOffset: 18,
                tint: const Color(0xFFF5A623),
                matrix: Matrix4.translationValues(0, -half, 0)..rotateX(math.pi / 2),
              ),
              _cubeFace(
                imageOffset: 3,
                tint: const Color(0xFF2E86AB),
                matrix: Matrix4.translationValues(-half, 0, 0)..rotateY(-math.pi / 2),
              ),
              _cubeFace(
                imageOffset: 12,
                tint: const Color(0xFFE85D04),
                matrix: Matrix4.translationValues(0, half, 0)..rotateX(-math.pi / 2),
              ),
              _cubeFace(
                imageOffset: 6,
                tint: const Color(0xFF6A4C93),
                matrix: Matrix4.translationValues(0, 0, -half)..rotateY(math.pi),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
