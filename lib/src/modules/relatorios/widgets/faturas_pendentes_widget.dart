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
  final Function(String cartaoId) onFaturaTap;

  const FaturasPendentesWidget({
    super.key,
    required this.onFaturaTap,
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

    return Container(
      // Sem margin - usa o padding do ScrollView igual outros widgets
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

          // Lista de faturas
          if (_loading)
            _buildLoadingState()
          else
            ..._buildFaturasList(),

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
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6), // Compacto
      child: Row(
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
          const Text(
            'Faturas de Cartão',
            style: TextStyle(
              fontSize: 16, // Menor que normal
              fontWeight: FontWeight.w600,
              color: AppColors.cinzaEscuro,
            ),
          ),

          const Spacer(),

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

  /// 📋 Lista de faturas compacta
  List<Widget> _buildFaturasList() {
    final widgets = <Widget>[];

    for (int i = 0; i < _faturas.length; i++) {
      final fatura = _faturas[i];
      final isLast = i == _faturas.length - 1;

      // Item da fatura
      widgets.add(_buildFaturaItem(fatura));

      // Divider (exceto no último)
      if (!isLast) {
        widgets.add(_buildDivider());
      }
    }

    return widgets;
  }

  /// 💳 Item individual da fatura (ultra compacto)
  Widget _buildFaturaItem(FaturaPendente fatura) {
    return InkWell(
      onTap: () => widget.onFaturaTap(fatura.cartaoId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), // Compacto
        child: Column(
          children: [
            // Primeira linha: Ícone + Nome + Valor
            Row(
              children: [
                // Ícone do cartão (pequeno)
                Container(
                  width: 24, // Bem pequeno
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.roxoHeader.withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    color: AppColors.roxoHeader,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),

                // Nome do cartão
                Expanded(
                  child: Text(
                    fatura.nomeCartao,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cinzaEscuro,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Valor da fatura
                Text(
                  CurrencyFormatter.format(fatura.valorFatura),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.vermelhoErro,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Segunda linha: Status + Badge (se vencida)
            Row(
              children: [
                const SizedBox(width: 34), // Alinhado com texto acima

                // Status da fatura
                Expanded(
                  child: Text(
                    fatura.statusTexto,
                    style: TextStyle(
                      fontSize: 12,
                      color: fatura.corStatus,
                      fontWeight: fatura.isCritica ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),

                // Badge "VENCIDO" se necessário
                if (fatura.mostrarBadgeVencido)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.vermelhoErro,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'VENCIDO',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ➖ Divider compacto
  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 52), // Alinhado com texto
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.cinzaBorda,
      ),
    );
  }
}