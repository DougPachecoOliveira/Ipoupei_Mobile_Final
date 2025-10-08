// 📊 Resumo Orçamento Widget - iPoupei Mobile
//
// Widget elegante de resumo do orçamento mensal
// Header branco com relevo + Cards horizontais simples
//
// Funcionalidades: Header elevado + Toggle efetivados + Layout limpo

import 'package:flutter/material.dart';
import '../models/planejamento_model.dart';
import '../services/planejamento_service.dart';
import '../pages/planejamento_page.dart';
import '../../../shared/utils/format_currency.dart';
import '../../shared/theme/app_colors.dart';

class ResumoOrcamentoWidget extends StatefulWidget {
  final DateTime dataAtual;
  final bool modoAnual;

  const ResumoOrcamentoWidget({
    super.key,
    required this.dataAtual,
    this.modoAnual = false,
  });

  @override
  State<ResumoOrcamentoWidget> createState() => _ResumoOrcamentoWidgetState();
}

class _ResumoOrcamentoWidgetState extends State<ResumoOrcamentoWidget> {
  final PlanejamentoService _service = PlanejamentoService.instance;

  List<PlanejamentoModel> _planejamentos = [];
  bool _loading = true;
  bool _incluirPendentes = false; // Igual ao planejamento principal

  // Usa dados passados pelo parâmetro igual ao planejamento page
  DateTime get _dataAtual => widget.dataAtual;
  bool get _modoAnual => widget.modoAnual;

  @override
  void initState() {
    super.initState();
    _carregarDados();

    // Escuta mudanças no service
    _service.planejamentosStream.listen((planejamentos) {
      if (mounted) {
        _filtrarPlanejamentos();
      }
    });
  }

  @override
  void didUpdateWidget(ResumoOrcamentoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarregar se a data mudou
    if (oldWidget.dataAtual != widget.dataAtual || oldWidget.modoAnual != widget.modoAnual) {
      _carregarDados();
    }
  }

  Future<void> _carregarDados() async {
    setState(() => _loading = true);

    try {
      // Define período no service baseado na data atual
      _service.definirPeriodo(_dataAtual);
      await _service.carregarPlanejamentos(modoAnual: _modoAnual);
      _filtrarPlanejamentos();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _filtrarPlanejamentos() {
    List<PlanejamentoModel> planejamentosFiltrados;

    if (_modoAnual) {
      // Modo anual: todos os planejamentos do ano
      planejamentosFiltrados = _service.planejamentos.where((p) {
        return p.ano == _dataAtual.year;
      }).toList();
    } else {
      // Modo mensal: apenas do mês atual
      planejamentosFiltrados = _service.planejamentos.where((p) {
        return p.ano == _dataAtual.year && p.mes == _dataAtual.month;
      }).toList();
    }

    if (mounted) {
      setState(() {
        _planejamentos = planejamentosFiltrados;
        _loading = false;
      });
    }
  }

  // Calcular totais igual ao planejamento principal
  double get _totalDespesasPlanejado {
    return _planejamentos
        .where((p) => p.isDespesa)
        .fold(0.0, (sum, p) => sum + p.valorPlanejado);
  }

  double get _totalDespesasRealizado {
    return _planejamentos
        .where((p) => p.isDespesa)
        .fold(0.0, (sum, p) => sum + (_incluirPendentes ? p.totalMes : p.valorRealizado));
  }

  double get _totalReceitasPlanejado {
    return _planejamentos
        .where((p) => p.isReceita)
        .fold(0.0, (sum, p) => sum + p.valorPlanejado);
  }

  double get _totalReceitasRealizado {
    return _planejamentos
        .where((p) => p.isReceita)
        .fold(0.0, (sum, p) => sum + (_incluirPendentes ? p.totalMes : p.valorRealizado));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderComRelevo(),
          if (_loading)
            _buildLoadingState()
          else if (_planejamentos.isEmpty)
            _buildEmptyState()
          else
            _buildCardsSimples(),
        ],
      ),
    );
  }

  Widget _buildHeaderComRelevo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Título simples
          const Text(
            'Planejamento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          // Toggle efetivados/pendentes (igual ao planejamento principal)
          if (_planejamentos.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _incluirPendentes = !_incluirPendentes;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _incluirPendentes ? AppColors.azul : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _incluirPendentes ? 'Efetivado + Pendente' : 'Apenas Efetivado',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _incluirPendentes ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealPrimary),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _navegarParaPlanejamento,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 32,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              const Text(
                'Nenhum planejamento configurado',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Toque para criar',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardsSimples() {
    final temReceitas = _totalReceitasPlanejado > 0;
    final temDespesas = _totalDespesasPlanejado > 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card Receitas (se existir)
          if (temReceitas) ...[
            _buildCardHorizontal(
              titulo: 'Receitas do Mês',
              valorRealizado: _totalReceitasRealizado,
              valorPlanejado: _totalReceitasPlanejado,
              isReceita: true,
            ),
            if (temDespesas) const SizedBox(height: 12),
          ],

          // Card Despesas (se existir)
          if (temDespesas)
            _buildCardHorizontal(
              titulo: 'Despesas do Mês',
              valorRealizado: _totalDespesasRealizado,
              valorPlanejado: _totalDespesasPlanejado,
              isReceita: false,
            ),
        ],
      ),
    );
  }

  Widget _buildCardHorizontal({
    required String titulo,
    required double valorRealizado,
    required double valorPlanejado,
    required bool isReceita,
  }) {
    final percentual = valorPlanejado > 0 ? (valorRealizado / valorPlanejado) * 100 : 0.0;
    final corProgresso = _getProgressColor(percentual, isReceita: isReceita);

    return GestureDetector(
      onTap: _navegarParaPlanejamento,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha principal: Título vs Valores (igual ao planejamento principal)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Título
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Valores: Realizado vs Planejado
                Text(
                  '${formatCurrency(valorRealizado)} vs ${formatCurrency(valorPlanejado)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Barra de progresso
            LinearProgressIndicator(
              value: valorPlanejado > 0 ? (percentual / 100).clamp(0.0, 1.0) : 0.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(corProgresso),
              minHeight: 4,
            ),

            const SizedBox(height: 4),

            // Percentual
            Text(
              '${percentual.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double percentual, {bool isReceita = false}) {
    if (isReceita) {
      // RECEITAS: Bom quando atinge/supera a meta
      if (percentual >= 100) return AppColors.verdeSucesso;
      if (percentual >= 80) return AppColors.laranjaAlerta;
      return AppColors.vermelhoErro;
    } else {
      // DESPESAS: Bom quando fica abaixo da meta
      if (percentual <= 50) return AppColors.verdeSucesso;
      if (percentual <= 80) return AppColors.laranjaAlerta;
      return AppColors.vermelhoErro;
    }
  }

  void _navegarParaPlanejamento() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PlanejamentoPage(),
      ),
    );
  }
}