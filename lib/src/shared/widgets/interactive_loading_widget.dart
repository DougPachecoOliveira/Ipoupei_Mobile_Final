// 🎨 Interactive Loading Widget - iPoupei Mobile
//
// Widget de loading interativo com animações e progresso detalhado
// Usado durante o Hard Reset para mostrar progresso em tempo real
//
// Características:
// - Progress bar animado com percentual
// - Cards de status por módulo
// - Dicas financeiras rotativas
// - Animações suaves
// - Timeout visual

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../database/hard_reset_service.dart';

class InteractiveLoadingWidget extends StatefulWidget {
  final Stream<ResetProgress> progressStream;
  final VoidCallback? onTimeoutReached;
  final VoidCallback? onCompleted;

  const InteractiveLoadingWidget({
    super.key,
    required this.progressStream,
    this.onTimeoutReached,
    this.onCompleted,
  });

  @override
  State<InteractiveLoadingWidget> createState() => _InteractiveLoadingWidgetState();
}

class _InteractiveLoadingWidgetState extends State<InteractiveLoadingWidget>
    with TickerProviderStateMixin {

  late AnimationController _progressController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  ResetProgress? _currentProgress;
  Timer? _tipTimer;
  int _currentTipIndex = 0;

  // 💡 Dicas financeiras para mostrar durante o loading
  final List<String> _financialTips = [
    '💰 Organizando suas transações...',
    '📊 Calculando saldos atualizados...',
    '🏦 Sincronizando contas bancárias...',
    '💳 Verificando faturas de cartão...',
    '📈 Analisando investimentos...',
    '💸 Categorizando gastos...',
    '🎯 Preparando relatórios...',
    '⚡ Otimizando performance...',
    '🔐 Garantindo segurança dos dados...',
    '🌟 Finalizando configurações...',
  ];

  @override
  void initState() {
    super.initState();

    // Configurar animações
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(_rotationController);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Escutar mudanças de progresso
    widget.progressStream.listen(_onProgressUpdate);

    // Timer para trocar dicas
    _tipTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _financialTips.length;
        });
      }
    });
  }

  void _onProgressUpdate(ResetProgress progress) {
    if (!mounted) return;

    setState(() {
      _currentProgress = progress;
    });

    // Animar progress bar
    _progressController.animateTo(progress.progress);

    // Verificar se completou
    if (progress.isCompleted && widget.onCompleted != null) {
      widget.onCompleted!();
    }

    // Verificar se teve erro
    if (progress.phase == ResetPhase.error) {
      _showErrorDialog(progress.errorMessage ?? 'Erro desconhecido');
    }
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Erro no Reset'),
          ],
        ),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Fecha o loading também
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _currentProgress;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🎯 Header
              _buildHeader(theme),

              const SizedBox(height: 40),

              // 📊 Progress Section
              _buildProgressSection(theme, progress),

              const SizedBox(height: 40),

              // 📱 Status Cards
              _buildStatusCards(theme, progress),

              const SizedBox(height: 30),

              // 💡 Financial Tip
              _buildFinancialTip(theme),

              const SizedBox(height: 40),

              // ⚡ Action Buttons (if timeout reached)
              if (progress?.isCompleted == true && progress?.phase != ResetPhase.completed)
                _buildActionButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // Ícone animado
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.sync,
                  size: 40,
                  color: theme.primaryColor,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        Text(
          'Resetando Base de Dados',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Conectando ao Servidor e iniciando download',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(ThemeData theme, ResetProgress? progress) {
    final percentage = ((progress?.progress ?? 0.0) * 100).toInt();

    return Column(
      children: [
        // Progress Bar
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: theme.dividerColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Percentage e Message
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$percentage%',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),

            if (progress?.processedCount != null && progress?.totalCount != null)
              Text(
                '${progress!.processedCount}/${progress.totalCount}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          progress?.message ?? 'Preparando...',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          progress?.detailMessage ?? 'Iniciando processo...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusCards(ThemeData theme, ResetProgress? progress) {
    final modules = [
      {'name': 'Contas', 'icon': Icons.account_balance, 'done': _isModuleDone('contas', progress)},
      {'name': 'Transações', 'icon': Icons.receipt_long, 'done': _isModuleDone('transacoes', progress)},
      {'name': 'Cartões', 'icon': Icons.credit_card, 'done': _isModuleDone('cartoes', progress)},
      {'name': 'Categorias', 'icon': Icons.category, 'done': _isModuleDone('categorias', progress)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        final isDone = module['done'] as bool;
        final isActive = _isModuleActive(module['name'] as String, progress);

        return Container(
          decoration: BoxDecoration(
            color: isDone
              ? theme.primaryColor.withOpacity(0.1)
              : theme.cardColor,
            border: Border.all(
              color: isDone
                ? theme.primaryColor
                : isActive
                  ? theme.primaryColor.withOpacity(0.5)
                  : theme.dividerColor,
              width: isDone || isActive ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),

              // Ícone com animação
              if (isActive && !isDone)
                AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Icon(
                        module['icon'] as IconData,
                        color: theme.primaryColor,
                        size: 20,
                      ),
                    );
                  },
                )
              else
                Icon(
                  isDone ? Icons.check_circle : module['icon'] as IconData,
                  color: isDone
                    ? Colors.green
                    : theme.iconTheme.color?.withOpacity(0.6),
                  size: 20,
                ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  module['name'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                    color: isDone
                      ? theme.primaryColor
                      : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinancialTip(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(_currentTipIndex),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: theme.primaryColor,
              size: 20,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                _financialTips[_currentTipIndex],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        const Divider(),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close),
                label: const Text('Continuar Navegando'),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Mostrar progresso detalhado
                  _showDetailedProgress();
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Ver Progresso'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          '✅ Dados principais carregados!\n🔄 Finalizando em segundo plano...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.green,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  bool _isModuleDone(String moduleName, ResetProgress? progress) {
    if (progress == null) return false;

    // Simplified logic - in a real implementation, you'd track each module separately
    switch (moduleName.toLowerCase()) {
      case 'contas':
        return progress.progress > 0.2;
      case 'transacoes':
        return progress.progress > 0.5;
      case 'cartoes':
        return progress.progress > 0.7;
      case 'categorias':
        return progress.progress > 0.9;
      default:
        return false;
    }
  }

  bool _isModuleActive(String moduleName, ResetProgress? progress) {
    if (progress == null) return false;

    return progress.currentTable?.toLowerCase().contains(moduleName.toLowerCase()) ?? false;
  }

  void _showDetailedProgress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Progresso Detalhado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fase: ${_currentProgress?.phase.toString() ?? 'Desconhecida'}'),
            const SizedBox(height: 8),
            Text('Progresso: ${((_currentProgress?.progress ?? 0) * 100).toInt()}%'),
            const SizedBox(height: 8),
            Text('Mensagem: ${_currentProgress?.message ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Detalhes: ${_currentProgress?.detailMessage ?? 'N/A'}'),
            if (_currentProgress?.currentTable != null) ...[
              const SizedBox(height: 8),
              Text('Tabela atual: ${_currentProgress!.currentTable!}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _tipTimer?.cancel();
    super.dispose();
  }
}
