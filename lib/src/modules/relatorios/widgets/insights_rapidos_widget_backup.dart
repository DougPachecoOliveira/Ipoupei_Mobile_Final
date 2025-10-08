// 💡 Insights Rápidos Widget - iPoupei Mobile (BACKUP DESIGN PREMIUM)
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
class InsightsRapidosWidgetBackup extends StatefulWidget {
  final ResumoFinanceiroData? data;
  final DateTime dataInicio;
  final DateTime dataFim;

  const InsightsRapidosWidgetBackup({
    super.key,
    required this.data,
    required this.dataInicio,
    required this.dataFim,
  });

  @override
  State<InsightsRapidosWidgetBackup> createState() => _InsightsRapidosWidgetBackupState();
}

class _InsightsRapidosWidgetBackupState extends State<InsightsRapidosWidgetBackup> {
  final GraficosCategoriaService _service = GraficosCategoriaService.instance;
  List<Map<String, dynamic>> _categoriasDespesas = [];
  bool _carregandoCategorias = false;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  @override
  void didUpdateWidget(InsightsRapidosWidgetBackup oldWidget) {
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
    } catch (e) {
      setState(() => _carregandoCategorias = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se não tem dados, não mostra nada
    if (widget.data == null) return const SizedBox.shrink();

    final insights = _calcularInsights();

    // Se não gerou insights, não mostra
    if (insights.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.tealPrimary.withAlpha(245),
            AppColors.tealPrimary.withAlpha(230),
            const Color(0xFF00A693),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealPrimary.withAlpha(76),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.white.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(-4, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withAlpha(102),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Padrão de brilho sutil
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withAlpha(38),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Conteúdo principal
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header glamouroso
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFF0F9FF)],
                            ).createShader(bounds),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Insights Inteligentes',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Sua situação financeira',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Lista de insights premium
                    ...insights.map((insight) => _buildPremiumInsightCard(insight)),

                    const SizedBox(height: 8),
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
    final dadosSaldo = widget.data!.saldoContas; // atual
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

  /// 🎨 Card premium de insight com design sofisticado
  Widget _buildPremiumInsightCard(InsightModel insight) {
    final config = _getPremiumInsightConfig(insight.tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: config.gradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: config.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: config.shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Efeito de brilho no canto
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        config.glowColor,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Conteúdo principal
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Ícone premium com animação visual
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            config.iconGradientStart,
                            config.iconGradientEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: config.iconShadowColor,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        insight.icone,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Conteúdo elegante
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.titulo,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: config.titleColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            insight.descricao,
                            style: TextStyle(
                              fontSize: 14,
                              color: config.textColor,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Indicador visual do tipo
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            config.accentColor,
                            config.accentColor.withAlpha(128),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
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

  /// 🎨 Configuração premium por tipo de insight
  PremiumInsightConfig _getPremiumInsightConfig(TipoInsight tipo) {
    switch (tipo) {
      case TipoInsight.positivo:
        return PremiumInsightConfig(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withAlpha(230),
              Colors.white.withAlpha(204),
            ],
          ),
          borderColor: const Color(0xFF10B981).withAlpha(102),
          shadowColor: const Color(0xFF10B981).withAlpha(51),
          glowColor: const Color(0xFF10B981).withAlpha(38),
          iconGradientStart: const Color(0xFF10B981),
          iconGradientEnd: const Color(0xFF059669),
          iconShadowColor: const Color(0xFF10B981).withAlpha(76),
          titleColor: const Color(0xFF065F46),
          textColor: const Color(0xFF047857),
          accentColor: const Color(0xFF10B981),
        );

      case TipoInsight.alerta:
        return PremiumInsightConfig(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withAlpha(230),
              Colors.white.withAlpha(204),
            ],
          ),
          borderColor: const Color(0xFFEF4444).withAlpha(102),
          shadowColor: const Color(0xFFEF4444).withAlpha(51),
          glowColor: const Color(0xFFEF4444).withAlpha(38),
          iconGradientStart: const Color(0xFFEF4444),
          iconGradientEnd: const Color(0xFFDC2626),
          iconShadowColor: const Color(0xFFEF4444).withAlpha(76),
          titleColor: const Color(0xFF7F1D1D),
          textColor: const Color(0xFF991B1B),
          accentColor: const Color(0xFFEF4444),
        );

      case TipoInsight.informativo:
        return PremiumInsightConfig(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withAlpha(230),
              Colors.white.withAlpha(204),
            ],
          ),
          borderColor: const Color(0xFF06B6D4).withAlpha(102),
          shadowColor: const Color(0xFF06B6D4).withAlpha(51),
          glowColor: const Color(0xFF06B6D4).withAlpha(38),
          iconGradientStart: const Color(0xFF06B6D4),
          iconGradientEnd: const Color(0xFF0891B2),
          iconShadowColor: const Color(0xFF06B6D4).withAlpha(76),
          titleColor: const Color(0xFF164E63),
          textColor: const Color(0xFF0E7490),
          accentColor: const Color(0xFF06B6D4),
        );

      case TipoInsight.motivacional:
        return PremiumInsightConfig(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withAlpha(230),
              Colors.white.withAlpha(204),
            ],
          ),
          borderColor: const Color(0xFF8B5CF6).withAlpha(102),
          shadowColor: const Color(0xFF8B5CF6).withAlpha(51),
          glowColor: const Color(0xFF8B5CF6).withAlpha(38),
          iconGradientStart: const Color(0xFF8B5CF6),
          iconGradientEnd: const Color(0xFF7C3AED),
          iconShadowColor: const Color(0xFF8B5CF6).withAlpha(76),
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

/// 🎨 Configuração visual premium do insight
class PremiumInsightConfig {
  final LinearGradient gradient;
  final Color borderColor;
  final Color shadowColor;
  final Color glowColor;
  final Color iconGradientStart;
  final Color iconGradientEnd;
  final Color iconShadowColor;
  final Color titleColor;
  final Color textColor;
  final Color accentColor;

  PremiumInsightConfig({
    required this.gradient,
    required this.borderColor,
    required this.shadowColor,
    required this.glowColor,
    required this.iconGradientStart,
    required this.iconGradientEnd,
    required this.iconShadowColor,
    required this.titleColor,
    required this.textColor,
    required this.accentColor,
  });
}