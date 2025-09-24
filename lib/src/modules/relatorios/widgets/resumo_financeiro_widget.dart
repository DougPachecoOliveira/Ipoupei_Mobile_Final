// 📊 Resumo Financeiro Widget - iPoupei Mobile
//
// Widget de resumo financeiro com navegação interativa
// Baseado no ResumoFinanceiro do iPoupeiDevice
//
// Visual: Estilo SmartField (linhas) + ícones coloridos + navegação

import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../models/resumo_financeiro_model.dart';
import '../services/resumo_financeiro_service.dart';

/// Widget de resumo financeiro com navegação interativa
class ResumoFinanceiroWidget extends StatefulWidget {
  final DateTime dataInicio;
  final DateTime dataFim;
  final Function(TipoResumoFinanceiro tipo) onItemTap;

  const ResumoFinanceiroWidget({
    super.key,
    required this.dataInicio,
    required this.dataFim,
    required this.onItemTap,
  });

  @override
  State<ResumoFinanceiroWidget> createState() => _ResumoFinanceiroWidgetState();
}

class _ResumoFinanceiroWidgetState extends State<ResumoFinanceiroWidget> {
  final ResumoFinanceiroService _service = ResumoFinanceiroService.instance;

  ResumoFinanceiroData? _data;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void didUpdateWidget(ResumoFinanceiroWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarregar se o período mudou
    if (oldWidget.dataInicio != widget.dataInicio || oldWidget.dataFim != widget.dataFim) {
      _carregarDados();
    }
  }

  /// 🔄 Carregar dados do resumo
  Future<void> _carregarDados() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.carregarResumo(
        dataInicio: widget.dataInicio,
        dataFim: widget.dataFim,
      );

      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// 📋 Configuração dos itens do resumo
  List<ItemResumoFinanceiro> get _itensResumo => [
    ItemResumoFinanceiro(
      tipo: TipoResumoFinanceiro.contas,
      label: 'Contas',
      icon: Icons.account_balance,
      color: AppColors.azulHeader,
      valueExtractor: (data) => data.saldoContas,
    ),
    ItemResumoFinanceiro(
      tipo: TipoResumoFinanceiro.receitas,
      label: 'Receitas',
      icon: Icons.add,
      color: AppColors.verdeSucesso,
      valueExtractor: (data) => data.totalReceitas,
    ),
    ItemResumoFinanceiro(
      tipo: TipoResumoFinanceiro.despesas,
      label: 'Despesas',
      icon: Icons.remove,
      color: AppColors.vermelhoErro,
      valueExtractor: (data) => data.totalDespesas * -1, // Negativo para exibição
    ),
    ItemResumoFinanceiro(
      tipo: TipoResumoFinanceiro.cartoes,
      label: 'Cartões de crédito',
      icon: Icons.credit_card,
      color: AppColors.roxoHeader,
      valueExtractor: (data) => data.totalCartoes * -1, // Negativo para exibição
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      // Sem margin - usa o padding do ScrollView (16px) igual ao filtro de período
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conteúdo
          if (_loading && _data == null)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Carregando resumo...',
                      style: TextStyle(color: AppColors.cinzaMedio),
                    ),
                  ],
                ),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.vermelhoErro,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erro ao carregar dados',
                      style: TextStyle(
                        color: AppColors.vermelhoErro,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.cinzaMedio,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _carregarDados,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            )
          else if (_data != null)
            // Itens do resumo
            ..._buildItensResumo()
          else
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Nenhum dado disponível',
                  style: TextStyle(color: AppColors.cinzaMedio),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 📋 Construir lista de itens do resumo
  List<Widget> _buildItensResumo() {
    if (_data == null) return [];

    final widgets = <Widget>[];

    for (int i = 0; i < _itensResumo.length; i++) {
      final item = _itensResumo[i];
      final isLast = i == _itensResumo.length - 1;
      final isFirst = i == 0;

      // Item do resumo
      widgets.add(
        _buildResumoItem(
          item: item,
          value: item.valueExtractor(_data!),
          isLast: isLast,
          isFirst: isFirst,
        ),
      );

      // Divider (exceto no último)
      if (!isLast) {
        widgets.add(_buildDivider());
      }
    }

    return widgets;
  }

  /// 📊 Construir item individual do resumo
  Widget _buildResumoItem({
    required ItemResumoFinanceiro item,
    required double value,
    required bool isLast,
    required bool isFirst,
  }) {
    return InkWell(
      onTap: () => widget.onItemTap(item.tipo),
      child: Padding(
        padding: EdgeInsets.only(
          left: 18, // 16 * 1.15
          right: 18,
          top: isFirst ? 14 : 7, // Top padding para primeiro item
          bottom: isLast ? 14 : 7, // 12 * 1.15 : 6 * 1.15
        ),
        child: Row(
          children: [
            // Ícone em container quadrado com pontas arredondadas
            Container(
              width: 41, // 36 * 1.15
              height: 41,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(12), // 10 * 1.15
              ),
              child: Icon(
                item.icon,
                color: Colors.white,
                size: 23, // 20 * 1.15
              ),
            ),
            const SizedBox(width: 14), // 12 * 1.15

            // Label
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 17, // 15 * 1.15
                  color: AppColors.cinzaEscuro,
                ),
              ),
            ),

            // Valor
            Text(
              CurrencyFormatter.format(value),
              style: TextStyle(
                fontSize: 17, // 15 * 1.15
                fontWeight: FontWeight.w600,
                color: value < 0 ? AppColors.vermelhoErro : AppColors.cinzaEscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ➖ Construir divider
  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 73), // Alinhado com o texto (41px ícone + 14px gap + 18px margin)
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.cinzaBorda,
      ),
    );
  }
}