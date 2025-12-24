import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:xml/xml.dart';

import '../../theme/app_colors.dart';

/// Loader que desenha o SVG real do logo com stroke animado.
class IPoupeiSvgStrokeLoader extends StatefulWidget {
  final String assetPath;
  final double width;
  final double height;
  final double strokeWidth;
  final bool showLabel;
  final String label;

  const IPoupeiSvgStrokeLoader({
    super.key,
    this.assetPath = 'assets/images/Ipoupei-Logo_sfundo.svg',
    this.width = 320,
    this.height = 240,
    this.strokeWidth = 8,
    this.showLabel = true,
    this.label = 'iPoupei',
  });

  @override
  State<IPoupeiSvgStrokeLoader> createState() => _IPoupeiSvgStrokeLoaderState();
}

class _IPoupeiSvgStrokeLoaderState extends State<IPoupeiSvgStrokeLoader>
    with TickerProviderStateMixin {
  late AnimationController _strokeController;
  late AnimationController _scaleController;

  late Animation<double> _progress;
  late Animation<double> _scale;

  Path? _logoPath;
  Size _viewBox = Size.zero;
  bool _error = false;

  @override
  void initState() {
    super.initState();

    _strokeController =
        AnimationController(
          duration: const Duration(milliseconds: 2200),
          vsync: this,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) _strokeController.forward(from: 0);
            });
          }
        });

    _progress = CurvedAnimation(
      parent: _strokeController,
      curve: Curves.easeInOutCubic,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.94, end: 1.04).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _loadPath();
  }

  Future<void> _loadPath() async {
    try {
      final raw = await rootBundle.loadString(widget.assetPath);
      final doc = XmlDocument.parse(raw);

      final svg = doc.findElements('svg').first;
      final viewBoxAttr = svg.getAttribute('viewBox');
      if (viewBoxAttr != null) {
        final parts = viewBoxAttr
            .split(RegExp(r'[ ,]+'))
            .map((e) => double.tryParse(e) ?? 0)
            .toList();
        if (parts.length >= 4) {
          _viewBox = Size(parts[2], parts[3]);
        }
      }

      Matrix4 groupTransform = Matrix4.identity();
      final firstGroupWithTransform = svg
          .findAllElements('g')
          .firstWhere(
            (g) => g.getAttribute('transform') != null,
            orElse: () => XmlElement(XmlName('g')),
          );
      final groupTransformAttr = firstGroupWithTransform.getAttribute(
        'transform',
      );
      if (groupTransformAttr != null) {
        groupTransform = _parseTransform(groupTransformAttr);
      }

      Path combined = Path();
      for (final node in doc.findAllElements('path')) {
        final d = node.getAttribute('d');
        if (d == null) continue;
        final fill = node.getAttribute('fill');
        if (fill != null && fill.toLowerCase() == 'none') {
          continue;
        }
        Matrix4 pathTransform = groupTransform;
        final pathTransformAttr = node.getAttribute('transform');
        if (pathTransformAttr != null) {
          pathTransform = pathTransform * _parseTransform(pathTransformAttr);
        }

        final parsed = parseSvgPathData(d).transform(pathTransform.storage);
        combined.addPath(parsed, Offset.zero);
      }

      if (combined.computeMetrics().isEmpty) {
        setState(() {
          _error = true;
        });
        return;
      }

      setState(() {
        _logoPath = combined;
      });
      _strokeController.forward();
    } catch (e) {
      debugPrint('Erro ao carregar SVG: $e');
      setState(() => _error = true);
    }
  }

  vm.Matrix4 _parseTransform(String raw) {
    vm.Matrix4 matrix = vm.Matrix4.identity();
    final reg = RegExp(r'(translate|scale)\s*\(([^)]*)\)');
    for (final match in reg.allMatches(raw)) {
      final type = match.group(1);
      final values =
          match
              .group(2)
              ?.split(RegExp(r'[ ,]+'))
              .map((e) => double.tryParse(e) ?? 0)
              .toList() ??
          [];

      if (type == 'translate') {
        final dx = values.isNotEmpty ? values[0] : 0.0;
        final dy = values.length > 1 ? values[1] : 0.0;
        matrix = matrix * vm.Matrix4.translationValues(dx, dy, 0);
      } else if (type == 'scale') {
        final sx = values.isNotEmpty ? values[0] : 1.0;
        final sy = values.length > 1 ? values[1] : sx;
        matrix = matrix * vm.Matrix4.diagonal3Values(sx, sy, 1);
      }
    }
    return matrix;
  }

  @override
  void dispose() {
    _strokeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _error
          ? const Center(child: Text('Erro ao carregar SVG'))
          : (_logoPath == null || _viewBox == Size.zero)
          ? const Center(child: CircularProgressIndicator())
          : AnimatedBuilder(
              animation: Listenable.merge([_progress, _scale]),
              builder: (context, child) {
                return Stack(
                  children: [
                    Center(
                      child: Transform.scale(
                        scale: _scale.value,
                        child: CustomPaint(
                          painter: _SvgStrokePainter(
                            path: _logoPath!,
                            viewBox: _viewBox,
                            progress: _progress.value,
                            strokeWidth: widget.strokeWidth,
                          ),
                          size: Size(widget.width, widget.height * 0.85),
                        ),
                      ),
                    ),
                    if (widget.showLabel)
                      Positioned(
                        bottom: 4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            widget.label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tealPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _SvgStrokePainter extends CustomPainter {
  final Path path;
  final Size viewBox;
  final double progress;
  final double strokeWidth;

  _SvgStrokePainter({
    required this.path,
    required this.viewBox,
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaled = _transformPath(path, viewBox, size);
    final trimmed = _trimPath(scaled, progress);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.tealPrimary.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    final gradient = ui.Gradient.linear(
      Offset(0, size.height),
      Offset(size.width, 0),
      const [
        Color(0xFF7C3AED),
        Color(0xFFEC4899),
        Color(0xFFF59E0B),
        Color(0xFF22C55E),
        Color(0xFF0EA5E9),
      ],
      const [0.0, 0.23, 0.46, 0.74, 1.0],
    );

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = gradient;

    canvas.drawPath(trimmed, glowPaint);
    canvas.drawPath(trimmed, strokePaint);
  }

  Path _transformPath(Path original, Size viewBox, Size size) {
    final boxWidth = viewBox.width == 0
        ? original.getBounds().width
        : viewBox.width;
    final boxHeight = viewBox.height == 0
        ? original.getBounds().height
        : viewBox.height;

    final scale = math.min(size.width / boxWidth, size.height / boxHeight);

    final scaledWidth = boxWidth * scale;
    final scaledHeight = boxHeight * scale;

    final dx = (size.width - scaledWidth) / 2 / scale;
    final dy = (size.height - scaledHeight) / 2 / scale;

    final matrix = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale, scale);

    return original.transform(matrix.storage);
  }

  Path _trimPath(Path path, double progress) {
    final target =
        path.computeMetrics().fold<double>(
          0,
          (sum, metric) => sum + metric.length,
        ) *
        progress.clamp(0.0, 1.0);

    double current = 0;
    final out = Path();

    for (final metric in path.computeMetrics()) {
      final next = current + metric.length;
      if (target >= next) {
        out.addPath(metric.extractPath(0, metric.length), Offset.zero);
        current = next;
        continue;
      }

      if (target > current) {
        final remaining = target - current;
        out.addPath(metric.extractPath(0, remaining), Offset.zero);
      }
      break;
    }

    return out;
  }

  @override
  bool shouldRepaint(covariant _SvgStrokePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
