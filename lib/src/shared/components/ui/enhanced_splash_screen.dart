// 🌟 Enhanced Splash Screen - iPoupei Mobile
//
// Tela de loading premium inspirada nos efeitos dos cartões
// Múltiplas animações simultâneas para experiência sofisticada
//
// Elementos:
// - Background gradiente animado
// - Logo com múltiplos efeitos visuais
// - Partículas flutuantes
// - Loading indicator personalizado
// - Textos animados contextuais

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../loading/ipoupei_wave_loader.dart';
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
  late AnimationController _gradientController;
  late AnimationController _logoController;
  late AnimationController _particlesController;
  late AnimationController _textController;

  late Animation<double> _gradientAnimation;
  late Animation<double> _logoRotation;
  late Animation<double> _logoScale;
  late Animation<double> _logoGlow;
  late Animation<double> _particleOffset;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    // Animação do gradiente de fundo
    _gradientController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Animação principal do logo
    _logoController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Animação das partículas
    _particlesController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Animação dos textos
    _textController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _setupAnimations();
  }

  void _setupAnimations() {
    // Gradiente animado
    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );

    // Logo: rotação suave
    _logoRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.linear));

    // Logo: breathing effect
    _logoScale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Logo: glow pulsante
    _logoGlow = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Partículas flutuantes
    _particleOffset = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _particlesController, curve: Curves.linear),
    );

    // Fade dos textos
    _textFade = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _logoController.dispose();
    _particlesController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradiente animado
          _buildAnimatedBackground(),

          // Partículas flutuantes
          _buildFloatingParticles(),

          // Conteúdo principal
          _buildMainContent(),
        ],
      ),
    );
  }

  /// Background com gradiente animado inspirado nos cartões
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _gradientAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  Colors.grey.shade50,
                  AppColors.tealPrimary.withValues(alpha: 0.1),
                  _gradientAnimation.value * 0.3,
                )!,
                Color.lerp(
                  Colors.grey.shade100,
                  AppColors.tealPrimary.withValues(alpha: 0.05),
                  _gradientAnimation.value * 0.2,
                )!,
                Color.lerp(
                  Colors.white,
                  Colors.grey.shade50,
                  _gradientAnimation.value * 0.1,
                )!,
              ],
              stops: [0.0, 0.5 + (_gradientAnimation.value * 0.2), 1.0],
            ),
          ),
        );
      },
    );
  }

  /// Partículas flutuantes para efeito sofisticado
  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particleOffset,
      builder: (context, child) {
        return Stack(
          children: List.generate(12, (index) {
            final angle =
                (index * 30.0) + (_particleOffset.value * 180 / math.pi);
            final radius = 100 + (index * 20);
            final size = 4.0 + (index % 3);

            final x =
                MediaQuery.of(context).size.width / 2 +
                radius * math.cos(angle * math.pi / 180);
            final y =
                MediaQuery.of(context).size.height / 2 +
                radius * math.sin(angle * math.pi / 180) * 0.6;

            return Positioned(
              left: x,
              top: y,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: [
                    AppColors.tealPrimary.withValues(alpha: 0.3),
                    AppColors.verdeSucesso.withValues(alpha: 0.2),
                    AppColors.azul.withValues(alpha: 0.25),
                  ][index % 3],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Conteúdo principal com logo e indicadores
  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.showProgress) _buildEnhancedLogo(),

          if (widget.showProgress) const SizedBox(height: 24),

          // Textos animados
          _buildAnimatedTexts(),
        ],
      ),
    );
  }

  /// Logo com múltiplos efeitos simultâneos
  Widget _buildEnhancedLogo() {
    final screenWidth = MediaQuery.of(context).size.width;
    final loaderWidth = math.min(screenWidth * 0.9, 360.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_logoRotation, _logoScale, _logoGlow]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Transform.rotate(
            angle: _logoRotation.value * 0.05,
            child: Opacity(
              opacity: _logoGlow.value.clamp(0.6, 1.0),
              child: IPoupeiWaveLoader(width: loaderWidth, height: 240),
            ),
          ),
        );
      },
    );
  }

  /// Textos com animação de fade
  Widget _buildAnimatedTexts() {
    return AnimatedBuilder(
      animation: _textFade,
      builder: (context, child) {
        return Opacity(
          opacity: _textFade.value,
          child: Column(
            children: [
              Text(
                widget.message,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tealPrimary,
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              if (widget.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
