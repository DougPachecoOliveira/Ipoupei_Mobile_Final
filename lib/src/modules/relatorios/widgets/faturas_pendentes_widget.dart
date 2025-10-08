// 💳 Faturas Pendentes Widget - iPoupei Mobile
//
// Widget ultra compacto para mostrar faturas críticas
// Só aparece quando há faturas vencidas ou vencendo em 3 dias
//
// Design: 50% menor que widgets normais, informação essencial apenas

import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
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

    // Não mostrar se estiver carregando e não tem dados
    if (_loading && _faturas.isEmpty) {
      return const SizedBox.shrink();
    }

    // Não mostrar se não tem faturas pendentes
    if (_faturas.isEmpty && !_loading) {
      return const SizedBox.shrink();
    }

    // Não mostrar se deu erro
    if (_error != null) {
      return const SizedBox.shrink();
    }


    return Container(
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
          // Header compacto
          _buildHeader(),

          // Lista de mini cards de faturas
          if (_loading)
            _buildLoadingState()
          else
            ..._buildFaturasCards(),

          // Padding bottom
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 📋 Header compacto com alerta
  Widget _buildHeader() {
    final totalVencidas = _faturas.quantidadeVencidas;
    final totalVencendo = _faturas.quantidadeVencendo3Dias;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6), // Igual ao TransacoesPendentesWidget
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone de alerta
          Container(
            width: 28, // Menor que normal
            height: 28,
            decoration: BoxDecoration(
              color: totalVencidas > 0
                  ? AppColors.vermelhoErro.withAlpha(26)
                  : AppColors.amareloAlerta.withAlpha(26),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: totalVencidas > 0 ? AppColors.vermelhoErro : AppColors.amareloAlerta,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),

          // Título
          const Expanded(
            child: Text(
              'Faturas de Cartão',
              style: TextStyle(
                fontSize: 16, // Menor que normal
                fontWeight: FontWeight.w600,
                color: AppColors.cinzaEscuro,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Contador de pendências
          if (_faturas.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: totalVencidas > 0
                    ? AppColors.vermelhoErro.withAlpha(26)
                    : AppColors.amareloAlerta.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                totalVencidas > 0
                    ? '$totalVencidas vencida${totalVencidas > 1 ? 's' : ''}'
                    : '$totalVencendo vencendo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: totalVencidas > 0 ? AppColors.vermelhoErro : AppColors.amareloAlerta,
                ),
              ),
            ),

          // Botão refresh (pequeno)
          const SizedBox(width: 8),
          if (!_loading)
            GestureDetector(
              onTap: _carregarFaturas,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.cinzaClaro,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.refresh,
                  color: AppColors.cinzaMedio,
                  size: 14,
                ),
              ),
            ),
        ],
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
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
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