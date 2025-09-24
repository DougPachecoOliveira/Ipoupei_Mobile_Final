// 💳 Faturas Pendentes Widget - iPoupei Mobile
//
// Widget ultra compacto para mostrar faturas críticas
// Só aparece quando há faturas vencidas ou vencendo em 3 dias
//
// Design: 50% menor que widgets normais, informação essencial apenas

import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/responsive_sizes.dart';
import '../../shared/utils/currency_formatter.dart';
import '../models/fatura_pendente_model.dart';
import '../services/faturas_pendentes_service.dart';

/// Widget compacto para faturas pendentes críticas
class FaturasPendentesWidget extends StatefulWidget {
  final Function(String cartaoId) onPagarFatura;

  const FaturasPendentesWidget({
    super.key,
    required this.onPagarFatura,
  });

  @override
  State<FaturasPendentesWidget> createState() => _FaturasPendentesWidgetState();
}

class _FaturasPendentesWidgetState extends State<FaturasPendentesWidget> {
  final FaturasPendentesService _service = FaturasPendentesService.instance;

  List<FaturaPendente> _faturas = [];
  bool _loading = false;
  bool _expandido = false; // Controle de expansão
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregarFaturas();
  }

  /// 🔄 Carregar faturas pendentes
  Future<void> _carregarFaturas() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final faturas = await _service.buscarFaturasPendentes();

      setState(() {
        _faturas = faturas;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // DEBUG: Sempre mostrar para teste (remover depois)
    debugPrint('🔍 [FATURAS_WIDGET] Build - Loading: $_loading, Faturas: ${_faturas.length}, Error: $_error');

    // Não mostrar se estiver carregando e não tem dados
    if (_loading && _faturas.isEmpty) {
      debugPrint('🔍 [FATURAS_WIDGET] Ocultando: Loading + sem dados');
      return const SizedBox.shrink();
    }

    // Não mostrar se não tem faturas pendentes
    if (_faturas.isEmpty && !_loading) {
      debugPrint('🔍 [FATURAS_WIDGET] Ocultando: Sem faturas + não carregando');
      return const SizedBox.shrink();
    }

    // Não mostrar se deu erro
    if (_error != null) {
      debugPrint('🔍 [FATURAS_WIDGET] Ocultando: Erro $_error');
      return const SizedBox.shrink();
    }

    debugPrint('🔍 [FATURAS_WIDGET] Mostrando widget com ${_faturas.length} faturas');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header compacto
        _buildHeader(),

        // Lista de mini cards de faturas (apenas se expandido)
        if (_expandido) ...[
          const SizedBox(height: 8),
          if (_loading)
            _buildLoadingState()
          else
            ..._buildFaturasCards(),
        ],
      ],
    );
  }

  /// 📋 Header profissional redesenhado
  Widget _buildHeader() {
    final totalVencidas = _faturas.quantidadeVencidas;
    final totalVencendo = _faturas.quantidadeVencendo3Dias;
    final totalFaturas = _faturas.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => setState(() => _expandido = !_expandido),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Ícone de alerta usando padrão do app
              Container(
                width: ResponsiveSizes.iconSize(context: context, base: 32),
                height: ResponsiveSizes.iconSize(context: context, base: 32),
                decoration: BoxDecoration(
                  color: totalVencidas > 0
                      ? AppColors.vermelhoErro.withAlpha(26)
                      : AppColors.amareloAlerta.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: totalVencidas > 0 ? AppColors.vermelhoErro : AppColors.amareloAlerta,
                  size: ResponsiveSizes.iconSize(context: context, base: 18),
                ),
              ),

              SizedBox(width: ResponsiveSizes.spacing(context: context, base: 12)),

              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título usando tipografia padrão do AppBar
                    Text(
                      'Faturas de Cartão',
                      style: AppTypography.appBarTitle(context).copyWith(
                        fontSize: ResponsiveSizes.fontSizeForCards(
                          context: context,
                          base: 14, // 18 * 0.75 = ~14
                          small: 12,
                          large: 15,
                        ),
                        color: AppColors.cinzaEscuro,
                      ),
                    ),
                    // Quantidade usando tipografia padrão
                    Text(
                      '$totalFaturas ${totalFaturas == 1 ? 'fatura pendente' : 'faturas pendentes'}',
                      style: AppTypography.bodySmall(context),
                    ),
                  ],
                ),
              ),

              // Botão atualizar
              IconButton(
                onPressed: _carregarFaturas,
                icon: Icon(
                  Icons.refresh,
                  size: ResponsiveSizes.appBarIconSize(context, base: 21),
                  color: AppColors.cinzaTexto,
                ),
                tooltip: 'Atualizar faturas',
              ),

              // Botão expandir/recolher
              IconButton(
                onPressed: () => setState(() => _expandido = !_expandido),
                icon: Icon(
                  _expandido ? Icons.expand_less : Icons.expand_more,
                  size: ResponsiveSizes.appBarIconSize(context, base: 21),
                  color: AppColors.cinzaTexto,
                ),
                tooltip: _expandido ? 'Recolher' : 'Expandir',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ⏳ Estado de loading
  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  /// 📋 Lista de mini cards de faturas
  List<Widget> _buildFaturasCards() {
    return _faturas.map((fatura) => _buildFaturaCard(fatura)).toList();
  }

  /// 💳 Mini card da fatura (formato consolidado)
  Widget _buildFaturaCard(FaturaPendente fatura) {
    // Cor do cartão (tenta usar a cor do cartão ou padrão)
    Color corCartao = AppColors.roxoHeader;
    if (fatura.corCartao != null && fatura.corCartao!.isNotEmpty) {
      try {
        corCartao = Color(int.parse(fatura.corCartao!.replaceAll('#', '0xFF')));
      } catch (e) {
        // Fallback para cor padrão
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => widget.onPagarFatura(fatura.cartaoId),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  corCartao,
                  corCartao.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Ícone do cartão
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    color: Colors.white,
                    size: 18,
                  ),
                ),

                const SizedBox(width: 12),

                // Informações do cartão
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome do cartão
                      Text(
                        fatura.nomeCartao,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      // Data de vencimento
                      Text(
                        'Venc. ${fatura.dataVencimento.day}/${fatura.dataVencimento.month}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // Valor e status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Valor da fatura
                    Text(
                      CurrencyFormatter.format(fatura.valorFatura),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 2),

                    // Badge de status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: fatura.isCritica
                            ? Colors.red[400]
                            : Colors.orange[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        fatura.isCritica ? 'VENCIDA' : 'VENCE EM ${fatura.diasAteVencimento}D',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}