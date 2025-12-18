// 🎯 Sistema de Loading Personalizado iPoupei Mobile
//
// Sistema completo de loading states com identidade visual própria
// Inspirado no Santander com logo iPoupei animado
//
// Componentes:
// - IPoupeiButtonLoading: Para botões e ações rápidas
// - IPoupeiSavingState: Estado específico para salvamento
// - IPoupeiMicroLoading: Loading compacto para cards
// - IPoupeiProcessingOverlay: Overlay para operações complexas

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'ipoupei_drawing_loader.dart';

/// Tipos de contexto para loading states
enum IPoupeiLoadingContext {
  defaultState, // Azul iPoupei padrão (renamed from 'default')
  saving,       // Verde para salvamento
  processing,   // Laranja para processamento
  financial,    // Verde para operações financeiras
  error,        // Vermelho para erros
  sync,         // Azul para sincronização
}

/// Tamanhos disponíveis para loading
enum IPoupeiLoadingSize {
  micro(16),    // 16px - Para badges, mini cards
  small(24),    // 24px - Para botões pequenos
  medium(40),   // 40px - Para cards, loading padrão
  large(60),    // 60px - Para loading de tela
  xlarge(100);  // 100px - Para splash, overlays

  const IPoupeiLoadingSize(this.value);
  final double value;
}

/// Sistema principal de loading do iPoupei
class IPoupeiLoadingSystem {

  /// Obtém a cor baseada no contexto
  static Color getContextColor(IPoupeiLoadingContext context) {
    switch (context) {
      case IPoupeiLoadingContext.defaultState:
        return AppColors.tealPrimary;
      case IPoupeiLoadingContext.saving:
        return AppColors.verdeSucesso;
      case IPoupeiLoadingContext.processing:
        return AppColors.laranjaAlerta;
      case IPoupeiLoadingContext.financial:
        return AppColors.verdeSucesso;
      case IPoupeiLoadingContext.error:
        return AppColors.vermelhoErro;
      case IPoupeiLoadingContext.sync:
        return AppColors.azulHeader;
    }
  }

  /// Obtém mensagem padrão baseada no contexto
  static String getContextMessage(IPoupeiLoadingContext context) {
    switch (context) {
      case IPoupeiLoadingContext.defaultState:
        return 'Carregando...';
      case IPoupeiLoadingContext.saving:
        return 'Salvando...';
      case IPoupeiLoadingContext.processing:
        return 'Processando...';
      case IPoupeiLoadingContext.financial:
        return 'Processando operação...';
      case IPoupeiLoadingContext.error:
        return 'Verificando...';
      case IPoupeiLoadingContext.sync:
        return 'Sincronizando...';
    }
  }
}

/// Widget base para loading com logo iPoupei animado
class IPoupeiBaseLoading extends StatefulWidget {
  final IPoupeiLoadingSize size;
  final IPoupeiLoadingContext context;
  final String? customMessage;
  final bool showMessage;
  final bool showLogo;
  final Widget? customChild;

  const IPoupeiBaseLoading({
    super.key,
    this.size = IPoupeiLoadingSize.medium,
    this.context = IPoupeiLoadingContext.defaultState,
    this.customMessage,
    this.showMessage = false,
    this.showLogo = true,
    this.customChild,
  });

  @override
  State<IPoupeiBaseLoading> createState() => _IPoupeiBaseLoadingState();
}

class _IPoupeiBaseLoadingState extends State<IPoupeiBaseLoading> {
  // ✨ DrawingLoader agora tem sua própria animação - controllers antigos removidos

  @override
  Widget build(BuildContext context) {
    final color = IPoupeiLoadingSystem.getContextColor(widget.context);
    final message = widget.customMessage ??
                   IPoupeiLoadingSystem.getContextMessage(widget.context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo animado ou loading customizado
        if (widget.showLogo)
          _buildAnimatedLogo(color)
        else if (widget.customChild != null)
          widget.customChild!,

        // Mensagem opcional
        if (widget.showMessage) ...[
          SizedBox(height: widget.size.value * 0.3),
          _buildMessage(message, color),
        ],
      ],
    );
  }

  Widget _buildAnimatedLogo(Color color) {
    // ✨ NOVO: Logo sendo desenhado progressivamente como o Santander
    return Container(
      width: widget.size.value,
      height: widget.size.value,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: widget.size.value * 0.15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: IPoupeiDrawingLoader(
          size: widget.size.value * 0.8,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMessage(String message, Color color) {
    final fontSize = widget.size.value < 30 ? 12.0 : 14.0;

    return Text(
      message,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Loading para botões - substitui CircularProgressIndicator
class IPoupeiButtonLoading extends StatelessWidget {
  final IPoupeiLoadingContext context;
  final double? size;

  const IPoupeiButtonLoading({
    super.key,
    this.context = IPoupeiLoadingContext.defaultState,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final loadingSize = size != null
        ? IPoupeiLoadingSize.values.firstWhere(
            (s) => s.value >= size!,
            orElse: () => IPoupeiLoadingSize.small,
          )
        : IPoupeiLoadingSize.small;

    return IPoupeiBaseLoading(
      size: loadingSize,
      context: this.context,
      showMessage: false,
      showLogo: true,
    );
  }
}

/// Loading com estado específico para salvamento - Design simplificado e elegante
class IPoupeiSavingState extends StatefulWidget {
  final String? customMessage;
  final bool showBackground;
  final Color? logoColor;

  const IPoupeiSavingState({
    super.key,
    this.customMessage,
    this.showBackground = true,
    this.logoColor,
  });

  @override
  State<IPoupeiSavingState> createState() => _IPoupeiSavingStateState();
}

class _IPoupeiSavingStateState extends State<IPoupeiSavingState>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.customMessage ?? 'Salvando...';
    final primaryColor = widget.logoColor ?? AppColors.tealPrimary;

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      constraints: const BoxConstraints(
        minWidth: 220,
        maxWidth: 300,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo iPoupei com animação suave
          AnimatedBuilder(
            animation: _opacityAnimation,
            builder: (context, child) {
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: _opacityAnimation.value),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.savings,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 16),

          // Texto estático (mais estável)
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.cinzaEscuro,
              ),
              textAlign: TextAlign.left,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (widget.showBackground) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: content,
      );
    }

    return content;
  }
}

/// Loading compacto para cards e widgets pequenos
class IPoupeiMicroLoading extends StatelessWidget {
  final IPoupeiLoadingContext context;
  final String? message;

  const IPoupeiMicroLoading({
    super.key,
    this.context = IPoupeiLoadingContext.defaultState,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return IPoupeiBaseLoading(
      size: IPoupeiLoadingSize.micro,
      context: this.context,
      customMessage: message,
      showMessage: message != null,
      showLogo: true,
    );
  }
}

/// Overlay completo para operações complexas
class IPoupeiProcessingOverlay extends StatelessWidget {
  final Widget child;
  final bool isProcessing;
  final IPoupeiLoadingContext context;
  final String? message;

  const IPoupeiProcessingOverlay({
    super.key,
    required this.child,
    required this.isProcessing,
    this.context = IPoupeiLoadingContext.processing,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        if (isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.6),
            child: Center(
              child: IPoupeiSavingState(
                customMessage: message,
                showBackground: true,
              ),
            ),
          ),
      ],
    );
  }
}