// 💡 Insights Rápidos Widget - iPoupei Mobile
//
// Widget de insights financeiros inteligentes
// Baseado na lógica do Dashboard.jsx (React)
//
// Analisa dados financeiros e gera insights automaticamente

import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../models/resumo_financeiro_model.dart';
import '../services/graficos_categoria_service.dart';

/// Widget de insights rápidos baseado no React Dashboard
class InsightsRapidosWidget extends StatefulWidget {
  final ResumoFinanceiroData? data;
  final DateTime dataInicio;
  final DateTime dataFim;

  const InsightsRapidosWidget({
    super.key,
    required this.data,
    required this.dataInicio,
    required this.dataFim,
  });

  @override
  State<InsightsRapidosWidget> createState() => _InsightsRapidosWidgetState();
}

class _InsightsRapidosWidgetState extends State<InsightsRapidosWidget> {
  final GraficosCategoriaService _service = GraficosCategoriaService.instance;
  List<Map<String, dynamic>> _categoriasDespesas = [];
  bool _carregandoCategorias = false;

  // Controle da navegação manual
  int _currentInsightIndex = 0;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  @override
  void didUpdateWidget(InsightsRapidosWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataInicio != widget.dataInicio || oldWidget.dataFim != widget.dataFim) {
      _carregarCategorias();
    }
  }

  /// 📊 Carregar dados das categorias para insights mais ricos
  Future<void> _carregarCategorias() async {
    setState(() => _carregandoCategorias = true);

    try {
      final categorias = await _service.buscarDespesasPorCategoria(widget.dataInicio, widget.dataFim);
      setState(() {
        _categoriasDespesas = categorias;
        _carregandoCategorias = false;
      });

      // Reset do índice quando recarrega dados
      setState(() {
        _currentInsightIndex = 0;
      });
    } catch (e) {
      setState(() => _carregandoCategorias = false);
    }
  }

  /// 👆 Navegar para próximo insight
  void _proximoInsight() {
    final insights = _calcularInsights();
    if (insights.length > 1) {
      setState(() {
        _currentInsightIndex = (_currentInsightIndex + 1) % insights.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se não tem dados, não mostra nada
    if (widget.data == null) return const SizedBox.shrink();

    final insights = _calcularInsights();

    // Se não gerou insights, não mostra
    if (insights.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _proximoInsight,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 120, // Altura fixa compacta
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.tealPrimary.withAlpha(250),
              const Color(0xFF00A693),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.tealPrimary.withAlpha(102),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Efeito de brilho sutil
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withAlpha(51),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Conteúdo horizontal compacto
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Ícone dourado minimalista
                  const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFFFD700), // Dourado
                    size: 16,
                  ),

                  const SizedBox(width: 16),

                  // Insight atual com rotação automática
                  Expanded(
                    child: insights.isEmpty
                        ? const Text(
                            'Carregando insights...',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          )
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 800),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut,
                                )),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: _buildCurrentInsight(insights[_currentInsightIndex % insights.length]),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// 💡 Calcular insights baseado nos dados (LÓGICA IDÊNTICA AO REACT WEB)
  List<InsightModel> _calcularInsights() {
    final insights = <InsightModel>[];

    if (widget.data == null) return insights;

    // 📊 DADOS DISPONÍVEIS (igual ao React)
    final dadosReceitas = widget.data!.totalReceitas; // atual
    final dadosDespesas = widget.data!.totalDespesas; // atual
    final dadosCartao = widget.data!.totalCartoes; // atual

    // 🎯 INSIGHT SOBRE SALDO (igual ao React)
    // Usar diferença receitas vs despesas como proxy para "saldo previsto vs atual"
    final saldoLiquido = dadosReceitas - dadosDespesas;
    if (saldoLiquido > 0) {
      insights.add(InsightModel(
        tipo: TipoInsight.positivo,
        icone: Icons.trending_up,
        titulo: 'Saldo em crescimento',
        descricao: 'Você tem ${CurrencyFormatter.format(saldoLiquido)} de saldo positivo este período',
      ));
    } else if (saldoLiquido < 0) {
      insights.add(InsightModel(
        tipo: TipoInsight.alerta,
        icone: Icons.adjust,
        titulo: 'Atenção aos gastos',
        descricao: 'Você gastou ${CurrencyFormatter.format(saldoLiquido.abs())} além do que recebeu',
      ));
    }

    // 📊 INSIGHT SOBRE MAIOR CATEGORIA DE GASTOS (IMPLEMENTADO - igual ao React!)
    if (_categoriasDespesas.isNotEmpty && !_carregandoCategorias) {
      final maiorCategoria = _categoriasDespesas.first; // Já vem ordenado por valor DESC
      final nomeCategoria = maiorCategoria['categoria'] as String;
      final valorCategoria = maiorCategoria['total_valor'] as double;

      insights.add(InsightModel(
        tipo: TipoInsight.informativo,
        icone: Icons.bar_chart,
        titulo: 'Maior categoria de gastos',
        descricao: '$nomeCategoria: ${CurrencyFormatter.format(valorCategoria)}',
      ));
    }

    // 💳 INSIGHT SOBRE USO DO CARTÃO (igual ao React)
    if (dadosCartao > 0) {
      // Como não temos dados de limite ainda, usar valores absolutos
      if (dadosCartao > 2000) {
        insights.add(InsightModel(
          tipo: TipoInsight.alerta,
          icone: Icons.credit_card,
          titulo: 'Uso alto do cartão',
          descricao: '${CurrencyFormatter.format(dadosCartao)} gastos no cartão - monitore os limites',
        ));
      } else {
        insights.add(InsightModel(
          tipo: TipoInsight.positivo,
          icone: Icons.account_balance_wallet,
          titulo: 'Uso consciente do cartão',
          descricao: '${CurrencyFormatter.format(dadosCartao)} gastos no cartão - bom controle',
        ));
      }
    }

    // 🎯 INSIGHT MOTIVACIONAL (fallback - igual ao React)
    if (insights.isEmpty) {
      insights.add(InsightModel(
        tipo: TipoInsight.motivacional,
        icone: Icons.bolt,
        titulo: 'Continue organizando!',
        descricao: 'Você está no caminho certo para organizar suas finanças',
      ));
    }

    // Máximo 3 insights (igual ao React)
    return insights.take(3).toList();
  }

  /// 🎨 Insight atual em exibição
  Widget _buildCurrentInsight(InsightModel insight) {
    final config = _getCompactInsightConfig(insight.tipo);

    return Container(
      key: ValueKey(insight.titulo), // Key para AnimatedSwitcher
      child: Row(
        children: [
          // Ícone compacto
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: config.iconColor.withAlpha(204),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight.icone,
              color: Colors.white,
              size: 16,
            ),
          ),

          const SizedBox(width: 12),

          // Conteúdo compacto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  insight.titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  insight.descricao,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Indicador de progresso (pontos)
          Row(
            children: List.generate(_calcularInsights().length, (index) {
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: index == _currentInsightIndex
                      ? Colors.white
                      : Colors.white.withAlpha(76),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 🎨 Configuração compacta por tipo de insight
  CompactInsightConfig _getCompactInsightConfig(TipoInsight tipo) {
    switch (tipo) {
      case TipoInsight.positivo:
        return CompactInsightConfig(
          iconColor: const Color(0xFF10B981),
          borderColor: const Color(0xFF10B981).withAlpha(76),
          titleColor: const Color(0xFF065F46),
          textColor: const Color(0xFF047857),
          accentColor: const Color(0xFF10B981),
        );

      case TipoInsight.alerta:
        return CompactInsightConfig(
          iconColor: const Color(0xFFEF4444),
          borderColor: const Color(0xFFEF4444).withAlpha(76),
          titleColor: const Color(0xFF7F1D1D),
          textColor: const Color(0xFF991B1B),
          accentColor: const Color(0xFFEF4444),
        );

      case TipoInsight.informativo:
        return CompactInsightConfig(
          iconColor: const Color(0xFF06B6D4),
          borderColor: const Color(0xFF06B6D4).withAlpha(76),
          titleColor: const Color(0xFF164E63),
          textColor: const Color(0xFF0E7490),
          accentColor: const Color(0xFF06B6D4),
        );

      case TipoInsight.motivacional:
        return CompactInsightConfig(
          iconColor: const Color(0xFF8B5CF6),
          borderColor: const Color(0xFF8B5CF6).withAlpha(76),
          titleColor: const Color(0xFF4C1D95),
          textColor: const Color(0xFF6D28D9),
          accentColor: const Color(0xFF8B5CF6),
        );
    }
  }
}

/// 📊 Modelo de dados do insight
class InsightModel {
  final TipoInsight tipo;
  final IconData icone;
  final String titulo;
  final String descricao;

  InsightModel({
    required this.tipo,
    required this.icone,
    required this.titulo,
    required this.descricao,
  });
}

/// 🎯 Tipos de insight (baseado no React)
enum TipoInsight {
  positivo,     // Verde - boas notícias
  alerta,       // Vermelho - atenção necessária
  informativo,  // Azul/Teal - informação neutra
  motivacional, // Roxo - incentivo
}

/// 🎨 Configuração visual compacta do insight
class CompactInsightConfig {
  final Color iconColor;
  final Color borderColor;
  final Color titleColor;
  final Color textColor;
  final Color accentColor;

  CompactInsightConfig({
    required this.iconColor,
    required this.borderColor,
    required this.titleColor,
    required this.textColor,
    required this.accentColor,
  });
}