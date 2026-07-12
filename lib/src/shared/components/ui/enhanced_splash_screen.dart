// 🌟 Enhanced Splash Screen - iPoupei Mobile
//
// Abertura do app: logo real (sem fundo) sobre gradiente sutil,
// entrada suave e onda arco-íris — a assinatura da marca — como
// indicador de progresso.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class EnhancedSplashScreen extends StatefulWidget {
  final String message;
  final String? subtitle;
  final bool showProgress;

  const EnhancedSplashScreen({
    super.key,
    this.message = 'Carregando iPoupei...',
    this.subtitle,
    this.showProgress = true,
  });

  @override
  State<EnhancedSplashScreen> createState() => _EnhancedSplashScreenState();
}

class _EnhancedSplashScreenState extends State<EnhancedSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _breathController;
  late final AnimationController _waveController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<double> _breath;

  @override
  void initState() {
    super.initState();

    // Entrada única: logo surge com fade + leve crescimento,
    // textos chegam logo depois.
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..forward();

    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );

    // Respiração muito sutil do logo enquanto carrega
    _breathController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _breath = CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOut,
    );

    // Onda arco-íris desenhando-se em loop
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _breathController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF4FAF8),
              Color(0xFFEAF5F2),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _buildGlow(),
            SafeArea(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  /// Brilho radial teal muito suave atrás do logo
  Widget _buildGlow() {
    return Center(
      child: FadeTransition(
        opacity: _logoFade,
        child: Container(
          width: 440,
          height: 440,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.tealPrimary.withValues(alpha: 0.07),
                AppColors.tealPrimary.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        const Spacer(flex: 5),
        _buildLogo(),
        const SizedBox(height: 44),
        if (widget.showProgress)
          FadeTransition(
            opacity: _textFade,
            child: _RainbowWaveProgress(animation: _waveController),
          ),
        const SizedBox(height: 28),
        _buildTexts(),
        const Spacer(flex: 6),
      ],
    );
  }

  Widget _buildLogo() {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoWidth = math.min(screenWidth * 0.66, 320.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _breath]),
      builder: (context, child) {
        final breathScale = 1.0 + 0.012 * _breath.value;
        return Opacity(
          opacity: _logoFade.value,
          child: Transform.scale(
            scale: _logoScale.value * breathScale,
            child: child,
          ),
        );
      },
      child: Image.asset(
        'assets/images/logo_transparent.png',
        width: logoWidth,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildTexts() {
    return FadeTransition(
      opacity: _textFade,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          children: [
            Text(
              widget.message,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.tealPrimary,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Linha-onda com o gradiente arco-íris do logo, desenhando-se em loop.
/// Primeiro 70% do ciclo: o traço se desenha; 30% final: fade out.
class _RainbowWaveProgress extends StatelessWidget {
  final Animation<double> animation;

  const _RainbowWaveProgress({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(150, 26),
          painter: _RainbowWavePainter(cycle: animation.value),
        );
      },
    );
  }
}

class _RainbowWavePainter extends CustomPainter {
  final double cycle;

  _RainbowWavePainter({required this.cycle});

  static const _drawPhase = 0.7;

  @override
  void paint(Canvas canvas, Size size) {
    final double progress;
    final double opacity;
    if (cycle < _drawPhase) {
      progress = Curves.easeInOutCubic.transform(cycle / _drawPhase);
      opacity = 1.0;
    } else {
      progress = 1.0;
      opacity = 1.0 - Curves.easeOut.transform((cycle - _drawPhase) / (1 - _drawPhase));
    }
    if (opacity <= 0.01) return;

    final path = Path()..moveTo(0, size.height / 2);
    const waves = 1.5;
    final amplitude = size.height * 0.32;
    for (double x = 1; x <= size.width; x += 1) {
      final t = x / size.width;
      final y = size.height / 2 +
          amplitude * math.sin(t * waves * 2 * math.pi);
      path.lineTo(x, y);
    }

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final visible = metric.extractPath(0, metric.length * progress);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, 0),
        [
          const Color(0xFF7C3AED).withValues(alpha: opacity), // Roxo
          const Color(0xFFEC4899).withValues(alpha: opacity), // Magenta
          const Color(0xFFF59E0B).withValues(alpha: opacity), // Laranja
          const Color(0xFF22C55E).withValues(alpha: opacity), // Verde
          const Color(0xFF0EA5E9).withValues(alpha: opacity), // Azul
        ],
        const [0.0, 0.25, 0.50, 0.75, 1.0],
      );

    canvas.drawPath(visible, paint);
  }

  @override
  bool shouldRepaint(covariant _RainbowWavePainter oldDelegate) {
    return oldDelegate.cycle != cycle;
  }
}
