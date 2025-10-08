import 'dart:async';
import 'package:flutter/material.dart';

/// Status de uma operação de transação
enum StatusOperacao {
  preparando,
  analisando,
  executandoLocal,
  executandoRemoto,
  sincronizando,
  concluido,
  erro,
}

/// Widget de feedback visual para operações de transação
class OperacaoFeedbackWidget extends StatefulWidget {
  final StatusOperacao status;
  final String? mensagem;
  final String? detalhes;
  final int? totalItens;
  final int? itensProcessados;
  final bool requerConexao;
  final VoidCallback? onCancelar;

  const OperacaoFeedbackWidget({
    Key? key,
    required this.status,
    this.mensagem,
    this.detalhes,
    this.totalItens,
    this.itensProcessados,
    this.requerConexao = false,
    this.onCancelar,
  }) : super(key: key);

  @override
  State<OperacaoFeedbackWidget> createState() => _OperacaoFeedbackWidgetState();
}

class _OperacaoFeedbackWidgetState extends State<OperacaoFeedbackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (_precisaAnimacao()) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(OperacaoFeedbackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      if (_precisaAnimacao()) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _precisaAnimacao() {
    return widget.status == StatusOperacao.preparando ||
           widget.status == StatusOperacao.analisando ||
           widget.status == StatusOperacao.executandoLocal ||
           widget.status == StatusOperacao.executandoRemoto ||
           widget.status == StatusOperacao.sincronizando;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// ✅ ÍCONE E STATUS
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _precisaAnimacao() ? _pulseAnimation.value : 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusText(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.mensagem != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.mensagem!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.requerConexao) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.wifi,
                  color: Colors.orange[700],
                  size: 20,
                ),
              ],
            ],
          ),

          /// ✅ PROGRESSO
          if (widget.totalItens != null && widget.itensProcessados != null) ...[
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progresso',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${widget.itensProcessados}/${widget.totalItens}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: widget.totalItens! > 0
                      ? widget.itensProcessados! / widget.totalItens!
                      : 0.0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(_getStatusColor()),
                ),
              ],
            ),
          ],

          /// ✅ DETALHES
          if (widget.detalhes != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.detalhes!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],

          /// ✅ BOTÃO CANCELAR
          if (widget.onCancelar != null && _podeSerCancelado()) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onCancelar,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case StatusOperacao.preparando:
      case StatusOperacao.analisando:
        return Colors.blue;
      case StatusOperacao.executandoLocal:
        return Colors.green;
      case StatusOperacao.executandoRemoto:
        return Colors.orange;
      case StatusOperacao.sincronizando:
        return Colors.purple;
      case StatusOperacao.concluido:
        return Colors.green;
      case StatusOperacao.erro:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case StatusOperacao.preparando:
        return Icons.hourglass_empty;
      case StatusOperacao.analisando:
        return Icons.search;
      case StatusOperacao.executandoLocal:
        return Icons.phone_android;
      case StatusOperacao.executandoRemoto:
        return Icons.cloud_sync;
      case StatusOperacao.sincronizando:
        return Icons.sync;
      case StatusOperacao.concluido:
        return Icons.check_circle;
      case StatusOperacao.erro:
        return Icons.error;
    }
  }

  String _getStatusText() {
    switch (widget.status) {
      case StatusOperacao.preparando:
        return 'Preparando operação...';
      case StatusOperacao.analisando:
        return 'Analisando transações...';
      case StatusOperacao.executandoLocal:
        return 'Processando localmente';
      case StatusOperacao.executandoRemoto:
        return 'Processando online';
      case StatusOperacao.sincronizando:
        return 'Sincronizando dados...';
      case StatusOperacao.concluido:
        return 'Operação concluída';
      case StatusOperacao.erro:
        return 'Erro na operação';
    }
  }

  bool _podeSerCancelado() {
    return widget.status == StatusOperacao.preparando ||
           widget.status == StatusOperacao.analisando;
  }
}

/// Dialog para mostrar feedback de operação
class OperacaoFeedbackDialog extends StatefulWidget {
  final String titulo;
  final Stream<OperacaoFeedbackState> stream;
  final VoidCallback? onCancelar;

  const OperacaoFeedbackDialog({
    Key? key,
    required this.titulo,
    required this.stream,
    this.onCancelar,
  }) : super(key: key);

  @override
  State<OperacaoFeedbackDialog> createState() => _OperacaoFeedbackDialogState();

  /// Mostra o dialog de feedback
  static Future<T?> mostrar<T>({
    required BuildContext context,
    required String titulo,
    required Stream<OperacaoFeedbackState> stream,
    VoidCallback? onCancelar,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OperacaoFeedbackDialog(
        titulo: titulo,
        stream: stream,
        onCancelar: onCancelar,
      ),
    );
  }
}

class _OperacaoFeedbackDialogState extends State<OperacaoFeedbackDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// ✅ HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text(
              widget.titulo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          /// ✅ CONTEÚDO
          StreamBuilder<OperacaoFeedbackState>(
            stream: widget.stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return OperacaoFeedbackWidget(
                  status: StatusOperacao.preparando,
                  onCancelar: widget.onCancelar,
                );
              }

              final state = snapshot.data!;

              // Fechar dialog automaticamente quando concluído
              if (state.status == StatusOperacao.concluido) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.of(context).pop(true);
                  }
                });
              }

              // Fechar dialog em caso de erro
              if (state.status == StatusOperacao.erro) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.of(context).pop(false);
                  }
                });
              }

              return OperacaoFeedbackWidget(
                status: state.status,
                mensagem: state.mensagem,
                detalhes: state.detalhes,
                totalItens: state.totalItens,
                itensProcessados: state.itensProcessados,
                requerConexao: state.requerConexao,
                onCancelar: widget.onCancelar,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Estado do feedback de operação
class OperacaoFeedbackState {
  final StatusOperacao status;
  final String? mensagem;
  final String? detalhes;
  final int? totalItens;
  final int? itensProcessados;
  final bool requerConexao;

  const OperacaoFeedbackState({
    required this.status,
    this.mensagem,
    this.detalhes,
    this.totalItens,
    this.itensProcessados,
    this.requerConexao = false,
  });

  OperacaoFeedbackState copyWith({
    StatusOperacao? status,
    String? mensagem,
    String? detalhes,
    int? totalItens,
    int? itensProcessados,
    bool? requerConexao,
  }) {
    return OperacaoFeedbackState(
      status: status ?? this.status,
      mensagem: mensagem ?? this.mensagem,
      detalhes: detalhes ?? this.detalhes,
      totalItens: totalItens ?? this.totalItens,
      itensProcessados: itensProcessados ?? this.itensProcessados,
      requerConexao: requerConexao ?? this.requerConexao,
    );
  }
}

/// Controller para gerenciar o feedback de operação
class OperacaoFeedbackController {
  final StreamController<OperacaoFeedbackState> _controller =
      StreamController<OperacaoFeedbackState>.broadcast();

  Stream<OperacaoFeedbackState> get stream => _controller.stream;

  OperacaoFeedbackState? _currentState;

  /// Atualiza o estado atual
  void atualizarEstado(OperacaoFeedbackState novoEstado) {
    _currentState = novoEstado;
    _controller.add(novoEstado);
  }

  /// Métodos de conveniência para diferentes estados
  void preparando([String? mensagem]) {
    atualizarEstado(OperacaoFeedbackState(
      status: StatusOperacao.preparando,
      mensagem: mensagem ?? 'Preparando operação...',
    ));
  }

  void analisando([String? mensagem]) {
    atualizarEstado(OperacaoFeedbackState(
      status: StatusOperacao.analisando,
      mensagem: mensagem ?? 'Analisando transações...',
    ));
  }

  void executandoLocal(String mensagem, {int? total, int? processados}) {
    atualizarEstado(OperacaoFeedbackState(
      status: StatusOperacao.executandoLocal,
      mensagem: mensagem,
      totalItens: total,
      itensProcessados: processados,
      requerConexao: false,
    ));
  }

  void executandoRemoto(String mensagem, {int? total, int? processados}) {
    atualizarEstado(OperacaoFeedbackState(
      status: StatusOperacao.executandoRemoto,
      mensagem: mensagem,
      totalItens: total,
      itensProcessados: processados,
      requerConexao: true,
    ));
  }

  void sincronizando([String? mensagem]) {
    atualizarEstado(OperacaoFeedbackState(
      status: StatusOperacao.sincronizando,
      mensagem: mensagem ?? 'Sincronizando dados...',
    ));
  }

  void concluido(String mensagem) {
    atualizarEstado(OperacaoFeedbackState(
      status: StatusOperacao.concluido,
      mensagem: mensagem,
    ));
  }

  void erro(String mensagem, [String? detalhes]) {
    atualizarEstado(OperacaoFeedbackState(
      status: StatusOperacao.erro,
      mensagem: mensagem,
      detalhes: detalhes,
    ));
  }

  /// Fecha o controller
  void dispose() {
    _controller.close();
  }
}