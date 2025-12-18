// 🎨 iPoupei Drawing Loader - iPoupei Mobile
//
// Loading sofisticado inspirado no Santander
// Logo sendo desenhado progressivamente em fases
//
// Baseado em: CustomPainter + Path Animation

import 'package:flutter/material.dart';
import 'dart:math' as math;

class IPoupeiDrawingLoader extends StatefulWidget {
  final double size;
  final Color color;

  const IPoupeiDrawingLoader({
    super.key,
    this.size = 80.0,
    this.color = const Color(0xFF17a2a2),
  });

  @override
  State<IPoupeiDrawingLoader> createState() => _IPoupeiDrawingLoaderState();
}

class _IPoupeiDrawingLoaderState extends State<IPoupeiDrawingLoader>
    with TickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _drawingAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _drawingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Inicia animação em loop
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drawingAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: IPoupeiLogoPainter(
            progress: _drawingAnimation.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

/// CustomPainter para desenhar o logo iPoupei progressivamente
class IPoupeiLogoPainter extends CustomPainter {
  final double progress;
  final Color color;

  IPoupeiLogoPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final logoSize = size.width * 0.8;

    // Fase 1 (0.0 - 0.25): Background do "i"
    if (progress >= 0.0) {
      _drawIBackground(canvas, center, logoSize, (progress * 4).clamp(0.0, 1.0));
    }

    // Fase 2 (0.25 - 0.5): Letra "i" e início do texto
    if (progress >= 0.25) {
      _drawILetter(canvas, center, logoSize, ((progress - 0.25) * 4).clamp(0.0, 1.0));
    }

    // Fase 3 (0.5 - 0.75): Texto "Poupei" e seta
    if (progress >= 0.5) {
      _drawPoupeiText(canvas, center, logoSize, ((progress - 0.5) * 4).clamp(0.0, 1.0));
    }

    // Fase 4 (0.75 - 1.0): Linha ondulada colorida
    if (progress >= 0.75) {
      _drawColorfulWave(canvas, center, logoSize, ((progress - 0.75) * 4).clamp(0.0, 1.0));
    }
  }

  /// Desenha o background retangular do "i"
  void _drawIBackground(Canvas canvas, Offset center, double logoSize, double phaseProgress) {
    final paint = Paint()
      ..color = color.withValues(alpha: phaseProgress)
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx - logoSize * 0.3, center.dy - logoSize * 0.1),
        width: logoSize * 0.25 * phaseProgress,
        height: logoSize * 0.6 * phaseProgress,
      ),
      Radius.circular(logoSize * 0.06),
    );

    canvas.drawRRect(rect, paint);
  }

  /// Desenha a letra "i" branca
  void _drawILetter(Canvas canvas, Offset center, double logoSize, double phaseProgress) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: phaseProgress)
      ..style = PaintingStyle.fill;

    // Ponto do "i"
    canvas.drawCircle(
      Offset(center.dx - logoSize * 0.3, center.dy - logoSize * 0.25),
      logoSize * 0.04 * phaseProgress,
      paint,
    );

    // Corpo do "i"
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx - logoSize * 0.3, center.dy + logoSize * 0.05),
        width: logoSize * 0.08 * phaseProgress,
        height: logoSize * 0.35 * phaseProgress,
      ),
      Radius.circular(logoSize * 0.02),
    );

    canvas.drawRRect(bodyRect, paint);
  }

  /// Desenha o texto "Poupei" e a seta
  void _drawPoupeiText(Canvas canvas, Offset center, double logoSize, double phaseProgress) {
    // Simula o texto "Poupei" com formas simples
    final paint = Paint()
      ..color = color.withValues(alpha: phaseProgress)
      ..style = PaintingStyle.fill;

    // "P" simplificado
    _drawLetterP(canvas, center.translate(logoSize * -0.05, logoSize * -0.1), logoSize * 0.15, paint, phaseProgress);

    // "o" simplificado
    canvas.drawCircle(
      center.translate(logoSize * 0.08, logoSize * -0.05),
      logoSize * 0.06 * phaseProgress,
      paint..style = PaintingStyle.stroke..strokeWidth = logoSize * 0.02,
    );

    // Seta para cima
    if (phaseProgress > 0.7) {
      _drawArrow(canvas, center.translate(logoSize * 0.35, logoSize * -0.15), logoSize * 0.1, paint, phaseProgress);
    }
  }

  /// Desenha uma letra "P" simplificada
  void _drawLetterP(Canvas canvas, Offset position, double letterSize, Paint paint, double progress) {
    final path = Path();

    // Linha vertical esquerda
    path.moveTo(position.dx, position.dy);
    path.lineTo(position.dx, position.dy + letterSize * progress);

    // Parte superior horizontal
    if (progress > 0.3) {
      path.moveTo(position.dx, position.dy);
      path.lineTo(position.dx + letterSize * 0.6 * (progress - 0.3) / 0.7, position.dy);
    }

    // Parte horizontal do meio
    if (progress > 0.6) {
      path.moveTo(position.dx, position.dy + letterSize * 0.5);
      path.lineTo(position.dx + letterSize * 0.6 * (progress - 0.6) / 0.4, position.dy + letterSize * 0.5);
    }

    canvas.drawPath(path, paint..style = PaintingStyle.stroke..strokeWidth = letterSize * 0.1);
  }

  /// Desenha seta para cima
  void _drawArrow(Canvas canvas, Offset position, double arrowSize, Paint paint, double progress) {
    final path = Path();

    // Linha principal da seta
    path.moveTo(position.dx, position.dy + arrowSize);
    path.lineTo(position.dx, position.dy + arrowSize * (1 - progress));

    // Ponta esquerda
    if (progress > 0.5) {
      path.moveTo(position.dx, position.dy);
      path.lineTo(position.dx - arrowSize * 0.3, position.dy + arrowSize * 0.3);
    }

    // Ponta direita
    if (progress > 0.7) {
      path.moveTo(position.dx, position.dy);
      path.lineTo(position.dx + arrowSize * 0.3, position.dy + arrowSize * 0.3);
    }

    canvas.drawPath(path, paint..style = PaintingStyle.stroke..strokeWidth = arrowSize * 0.1);
  }

  /// Desenha a linha ondulada colorida
  void _drawColorfulWave(Canvas canvas, Offset center, double logoSize, double phaseProgress) {
    final path = Path();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = logoSize * 0.03
      ..strokeCap = StrokeCap.round;

    // Cria gradiente colorido
    final gradientColors = [
      const Color(0xFF8B5CF6), // Roxo
      const Color(0xFFEF4444), // Vermelho
      const Color(0xFFF59E0B), // Amarelo
      const Color(0xFF10B981), // Verde
      const Color(0xFF3B82F6), // Azul
    ];

    // Linha ondulada do bottom esquerdo ao bottom direito
    final startX = center.dx - logoSize * 0.35;
    final endX = center.dx + logoSize * 0.35;
    final waveY = center.dy + logoSize * 0.25;

    path.moveTo(startX, waveY);

    // Cria ondulações suaves
    final waveLength = (endX - startX) * phaseProgress;
    final segments = 20;

    for (int i = 1; i <= segments; i++) {
      final x = startX + (waveLength / segments) * i;
      final frequency = 4.0; // Número de ondas
      final amplitude = logoSize * 0.02; // Altura das ondas

      final y = waveY + amplitude * math.sin((x - startX) * frequency * 2 * math.pi / waveLength);

      if (x <= startX + waveLength) {
        path.lineTo(x, y);
      }
    }

    // Aplica gradiente baseado no progresso
    final gradientIndex = (phaseProgress * (gradientColors.length - 1)).floor();
    final gradientProgress = (phaseProgress * (gradientColors.length - 1)) % 1.0;

    Color waveColor;
    if (gradientIndex >= gradientColors.length - 1) {
      waveColor = gradientColors.last;
    } else {
      waveColor = Color.lerp(gradientColors[gradientIndex], gradientColors[gradientIndex + 1], gradientProgress)!;
    }

    paint.color = waveColor.withValues(alpha: phaseProgress);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(IPoupeiLogoPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}