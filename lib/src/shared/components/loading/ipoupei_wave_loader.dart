import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Loader principal do iPoupei com a onda colorida sendo desenhada e
/// o logo crescendo suavemente.
class IPoupeiWaveLoader extends StatefulWidget {
  final double width;
  final double height;
  final bool showLabel;
  final String label;

  const IPoupeiWaveLoader({
    super.key,
    this.width = 320,
    this.height = 240,
    this.showLabel = true,
    this.label = 'iPoupei',
  });

  @override
  State<IPoupeiWaveLoader> createState() => _IPoupeiWaveLoaderState();
}

class _IPoupeiWaveLoaderState extends State<IPoupeiWaveLoader>
    with TickerProviderStateMixin {
  late AnimationController _pathController;
  late AnimationController _logoController;

  late Animation<double> _pathProgress;
  late Animation<double> _logoScale;

  bool _labelVisible = false;

  @override
  void initState() {
    super.initState();

    _pathController =
        AnimationController(
          duration: const Duration(milliseconds: 1800),
          vsync: this,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            if (!_labelVisible && mounted) {
              setState(() => _labelVisible = true);
            }

            // Pausa de 200ms antes de reiniciar
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) _pathController.forward(from: 0);
            });
          }
        });

    _pathProgress = CurvedAnimation(
      parent: _pathController,
      curve: Curves.easeInOutCubic,
    );

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _pathController.forward();
  }

  @override
  void dispose() {
    _pathController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pathProgress, _logoScale]),
        builder: (context, child) {
          final canvasHeight = widget.height * 0.78;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: CustomPaint(
                  painter: _IPoupeiWavePainter(progress: _pathProgress.value),
                  size: Size(widget.width, canvasHeight),
                ),
              ),
              Align(
                alignment: const Alignment(-0.65, -0.2),
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: _buildLogoCard(),
                ),
              ),
              if (widget.showLabel)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _labelVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 450),
                    child: _buildLabel(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealPrimary.withValues(alpha: 0.20),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 6,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/Logo.png',
        width: 86,
        height: 86,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildLabel() {
    return Center(
      child: ShaderMask(
        shaderCallback: (rect) => ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          [AppColors.azulHeader, AppColors.tealPrimary, AppColors.verdeSucesso],
        ),
        child: Text(
          widget.label,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _IPoupeiWavePainter extends CustomPainter {
  final double progress;

  _IPoupeiWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    final start = Offset(size.width * 0.05, size.height * 0.78);
    final bendOne = Offset(size.width * 0.24, size.height * 0.58);
    final bendTwo = Offset(size.width * 0.42, size.height * 0.82);
    final bendThree = Offset(size.width * 0.62, size.height * 1.05);
    final riseStart = Offset(size.width * 0.74, size.height * 0.62);
    final arrowTop = Offset(size.width * 0.82, size.height * 0.12);

    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(bendOne.dx, bendOne.dy, bendTwo.dx, bendTwo.dy);
    path.quadraticBezierTo(
      bendThree.dx,
      bendThree.dy,
      riseStart.dx,
      riseStart.dy,
    );
    path.quadraticBezierTo(
      size.width * 0.77,
      size.height * 0.40,
      arrowTop.dx,
      arrowTop.dy,
    );

    final metrics = path.computeMetrics();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final drawLength = metric.length * progress.clamp(0.0, 1.0);

    final visiblePath = metric.extractPath(0, math.max(0.0, drawLength));

    final strokeWidth = size.height * 0.085;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.35
      ..strokeCap = StrokeCap.round
      ..color = AppColors.tealPrimary.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.9),
        Offset(size.width, size.height * 0.05),
        const [
          Color(0xFF7C3AED), // Roxo
          Color(0xFFEC4899), // Magenta
          Color(0xFFF59E0B), // Laranja
          Color(0xFF22C55E), // Verde
          Color(0xFF0EA5E9), // Azul
        ],
        const [0.0, 0.25, 0.50, 0.75, 1.0],
      );

    canvas.drawPath(visiblePath, glowPaint);
    canvas.drawPath(visiblePath, gradientPaint);

    _drawArrowHead(canvas, arrowTop, strokeWidth, gradientPaint.color);
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    double strokeWidth,
    Color color,
  ) {
    if (progress < 0.85) return;

    final arrowProgress = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.65
      ..strokeCap = StrokeCap.round;

    final left = Offset(tip.dx - strokeWidth, tip.dy + strokeWidth * 0.9);

    final right = Offset(tip.dx + strokeWidth, tip.dy + strokeWidth * 0.9);

    canvas.drawLine(tip, Offset.lerp(tip, left, arrowProgress)!, arrowPaint);
    canvas.drawLine(tip, Offset.lerp(tip, right, arrowProgress)!, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _IPoupeiWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
