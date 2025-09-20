// 📅 Timeline Transações - iPoupei Mobile
// 
// Componente timeline para visualização cronológica das transações
// Features: Visual connectors, Agrupamento por período, Saldo corrente
// 
// Baseado em: Device UX Patterns + Timeline Design

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transacao_model.dart';
import '../../contas/models/conta_model.dart';
import '../../cartoes/models/cartao_model.dart';
import '../../categorias/models/categoria_model.dart';

class TimelineTransacoes extends StatelessWidget {
  final List<TransacaoModel> transacoes;
  final List<ContaModel> contas;
  final List<CartaoModel> cartoes;
  final List<CategoriaModel> categorias;
  final Function(TransacaoModel) onTransacaoTap;
  final bool mostrarSaldoCorrente;
  final Color corTema;

  const TimelineTransacoes({
    super.key,
    required this.transacoes,
    required this.contas,
    required this.cartoes,
    required this.categorias,
    required this.onTransacaoTap,
    this.mostrarSaldoCorrente = false,
    this.corTema = const Color(0xFF0891B2),
  });

  @override
  Widget build(BuildContext context) {
    if (transacoes.isEmpty) {
      return _buildEstadoVazio();
    }

    final transacoesOrdenadas = List<TransacaoModel>.from(transacoes)
      ..sort((a, b) => b.data.compareTo(a.data));

    return _buildTimeline(transacoesOrdenadas);
  }

  Widget _buildEstadoVazio() {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma transação para mostrar',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione transações para ver a timeline',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<TransacaoModel> transacoesOrdenadas) {
    // Agrupar transações por data
    final Map<String, List<TransacaoModel>> transacoesPorDia = {};
    for (final transacao in transacoesOrdenadas) {
      final chaveDia = DateFormat('yyyy-MM-dd').format(transacao.data);
      transacoesPorDia[chaveDia] ??= [];
      transacoesPorDia[chaveDia]!.add(transacao);
    }

    // Criar lista de widgets para o ListView
    final List<Widget> timelineItems = [];
    final diasOrdenados = transacoesPorDia.keys.toList()..sort((a, b) => b.compareTo(a));
    
    for (int diaIndex = 0; diaIndex < diasOrdenados.length; diaIndex++) {
      final chaveDia = diasOrdenados[diaIndex];
      final data = DateTime.parse(chaveDia);
      final transacoesDoDia = transacoesPorDia[chaveDia]!;
      final isUltimoDia = diaIndex == diasOrdenados.length - 1;
      
      // Calcular total do dia
      double totalDia = 0.0;
      for (final transacao in transacoesDoDia) {
        if (transacao.tipo == 'receita') {
          totalDia += transacao.valor;
        } else {
          totalDia -= transacao.valor;
        }
      }
      
      // Adicionar grupo do dia (header + transações)
      timelineItems.add(
        _buildGrupoDia(
          data, 
          totalDia, 
          transacoesDoDia, 
          isUltimoDia,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 80),
      child: Column(
        children: timelineItems,
      ),
    );
  }

  /// 📅 GRUPO DO DIA - Header + Transações com Timeline Alinhada
  Widget _buildGrupoDia(
    DateTime data, 
    double totalDia, 
    List<TransacaoModel> transacoes,
    bool isUltimoDia,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Coluna da timeline (ponto do dia + conectores)
          SizedBox(
            width: 60,
            child: Column(
              children: [
                // Conector superior (se não for o primeiro dia)
                if (transacoes != this.transacoes.first || data != this.transacoes.first.data)
                  Container(
                    width: 2,
                    height: 24, // Altura para alinhar com o centro do header
                    color: corTema.withOpacity(0.3),
                  ),
                
                // Ponto do dia (alinhado com header)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: corTema,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                
                // Conectores para as transações
                ...transacoes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final isLast = index == transacoes.length - 1;
                  
                  return Column(
                    children: [
                      // Conector até a transação
                      Container(
                        width: 2,
                        height: 20,
                        color: corTema.withOpacity(0.3),
                      ),
                      
                      // Ícone da transação
                      _buildIconeStatus(entry.value),
                      
                      // Conector após a transação (se não for a última)
                      if (!isLast || !isUltimoDia)
                        Container(
                          width: 2,
                          height: 20,
                          color: corTema.withOpacity(0.3),
                        ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          
          // Conteúdo (header + transações)
          Expanded(
            child: Column(
              children: [
                // Header do dia
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatarDataGrupoDevice(data),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (totalDia != 0)
                        Text(
                          '${totalDia >= 0 ? '+' : ''}${_formatarMoeda(totalDia)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: totalDia >= 0 
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Transações do dia
                ...transacoes.map((transacao) => _buildTransacaoTimeline(transacao)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📱 TRANSAÇÃO TIMELINE - Sem conectores laterais  
  Widget _buildTransacaoTimeline(TransacaoModel transacao) {
    final conta = transacao.contaId != null ? _encontrarConta(transacao.contaId!) : null;
    final cartao = transacao.cartaoId != null ? _encontrarCartao(transacao.cartaoId!) : null;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onTransacaoTap(transacao),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LINHA 1: Conta/Cartão + Horário - Padrão Device
            Row(
              children: [
                Expanded(
                  child: Text(
                    _getTextoConta(transacao, conta, cartao),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(transacao.data),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // LINHA 2: Tipo + Descrição + Valor - Padrão Device
            Row(
              children: [
                _buildIndicadorTipo(transacao),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    transacao.descricao,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildValor(transacao),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // LINHA 3: Chips de informações - Padrão Device
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _buildChipsInformacoes(transacao),
            ),
            
            // Saldo corrente (se habilitado)
            if (mostrarSaldoCorrente) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: corTema.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: corTema.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 12,
                      color: corTema,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Saldo: ${_formatarMoeda(0.0)}', // TODO: Calcular saldo real
                      style: TextStyle(
                        fontSize: 11,
                        color: corTema,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Observações (se houver)
            if (transacao.observacoes != null && transacao.observacoes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                transacao.observacoes!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // INDICADOR DE TIPO - Padrão Device
  Widget _buildIndicadorTipo(TransacaoModel transacao) {
    IconData icone;
    Color cor;
    
    switch (transacao.tipo) {
      case 'receita':
        icone = Icons.north_east;
        cor = const Color(0xFF10B981); // Verde success
        break;
      case 'despesa':
        if (transacao.cartaoId != null) {
          icone = Icons.credit_card;
          cor = const Color(0xFF7C3AED); // Roxo
        } else {
          icone = Icons.south_east;
          cor = const Color(0xFFEF4444); // Vermelho error
        }
        break;
      case 'transferencia':
        icone = Icons.swap_horiz;
        cor = const Color(0xFF3B82F6); // Azul
        break;
      default:
        icone = Icons.help_outline;
        cor = const Color(0xFF6B7280); // Cinza
    }
    
    return Icon(
      icone,
      size: 16,
      color: cor,
    );
  }

  // VALOR COM PREFIXO - Padrão Device
  Widget _buildValor(TransacaoModel transacao) {
    String prefixo;
    
    switch (transacao.tipo) {
      case 'receita':
        prefixo = '+';
        break;
      case 'despesa':
        prefixo = '-';
        break;
      case 'transferencia':
        prefixo = '';
        break;
      default:
        prefixo = '';
    }
    
    return Text(
      '$prefixo${_formatarMoeda(transacao.valor)}',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
    );
  }

  // TEXTO DA CONTA - Padrão Device
  String _getTextoConta(TransacaoModel transacao, ContaModel? conta, CartaoModel? cartao) {
    if (transacao.tipo == 'transferencia') {
      final contaOrigem = conta?.nome ?? 'Conta';
      final contaDestino = 'Conta Destino'; // TODO: Buscar conta destino real
      return '$contaOrigem → $contaDestino';
    } else if (transacao.cartaoId != null) {
      return cartao?.nome ?? 'Cartão não encontrado';
    } else {
      return conta?.nome ?? 'Conta não encontrada';
    }
  }

  /// 🎨 ÍCONE DE STATUS - Padrão Device
  Widget _buildIconeStatus(TransacaoModel transacao) {
    Color corStatus;
    
    // Definir cor do status (igual ao padrão Device)
    if (transacao.tipo == 'receita') {
      corStatus = const Color(0xFF10B981); // Verde
    } else if (transacao.efetivado) {
      corStatus = const Color(0xFF10B981); // Verde (efetivada)
    } else {
      corStatus = const Color(0xFFF59E0B); // Amarelo (pendente)
    }
    
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: corStatus,
        shape: BoxShape.circle,
      ),
    );
  }

  /// 📅 FORMATAÇÃO DE DATA PARA GRUPO - Padrão Device
  String _formatarDataGrupoDevice(DateTime data) {
    final agora = DateTime.now();
    final ontem = DateTime.now().subtract(const Duration(days: 1));
    
    if (_mesmaData(data, agora)) {
      return 'Hoje';
    } else if (_mesmaData(data, ontem)) {
      return 'Ontem';
    } else {
      final meses = [
        '', 'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
        'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
      ];
      
      // Se for do ano atual, não mostra o ano
      if (data.year == agora.year) {
        return '${data.day} de ${meses[data.month]}';
      } else {
        // Se for de outro ano, usa formato abreviado
        final mesesAbrev = [
          '', 'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
          'jul', 'ago', 'set', 'out', 'nov', 'dez'
        ];
        return '${data.day} de ${mesesAbrev[data.month]} de ${data.year}';
      }
    }
  }

  // CHIPS DE INFORMAÇÕES - Padrão Device
  List<Widget> _buildChipsInformacoes(TransacaoModel transacao) {
    final List<Widget> chips = [];
    
    // 1. RECORRENTE - Azul sólido
    if (transacao.ehRecorrente || transacao.recorrente) {
      chips.add(_buildChipRecorrente(transacao.tipoRecorrencia));
    }
    
    // 2. PARCELADO - Laranja sólido
    if ((transacao.totalParcelas ?? 0) > 1) {
      chips.add(_buildChipParcelado(transacao.parcelaAtual ?? 1, transacao.totalParcelas ?? 1));
    }
    
    // 3. PREVISÍVEL - Roxo sólido
    if (transacao.tipoDespesa == 'previsivel' || transacao.tipoReceita == 'previsivel') {
      chips.add(_buildChipPrevisivel());
    }
    
    // 4. CATEGORIA - Cor da categoria
    if (transacao.categoriaId != null) {
      chips.add(_buildChipCategoria(transacao));
    }
    
    // 5. TAGS (máximo 2)
    if (transacao.tags != null && transacao.tags!.isNotEmpty) {
      for (final tag in transacao.tags!.take(2)) {
        chips.add(_buildChipTag(tag));
      }
    }
    
    return chips;
  }

  // CHIP RECORRENTE - Azul sólido
  Widget _buildChipRecorrente(String? tipoRecorrencia) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6), // Azul sólido
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _formatarRecorrencia(tipoRecorrencia),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // CHIP PARCELADO - Laranja sólido
  Widget _buildChipParcelado(int parcelaAtual, int totalParcelas) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange, // Laranja sólido
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.credit_card, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$parcelaAtual/$totalParcelas',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // CHIP PREVISÍVEL - Roxo sólido
  Widget _buildChipPrevisivel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.purple, // Roxo sólido
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Previsível',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // CHIP CATEGORIA - Cor da categoria
  Widget _buildChipCategoria(TransacaoModel transacao) {
    final categoria = _encontrarCategoria(transacao.categoriaId!);
    
    if (categoria == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF6B7280), // Cinza como padrão
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Categoria',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      );
    }
    
    // Converter cor hex para Color
    Color corCategoria;
    try {
      corCategoria = Color(int.parse(categoria.cor.replaceAll('#', '0xFF')));
    } catch (e) {
      corCategoria = const Color(0xFF6B7280); // Fallback para cinza
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: corCategoria,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        categoria.nome,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  // Helper para encontrar categoria
  CategoriaModel? _encontrarCategoria(String categoriaId) {
    try {
      return categorias.firstWhere((c) => c.id == categoriaId);
    } catch (e) {
      return null;
    }
  }

  // CHIP TAG - Teal sólido
  Widget _buildChipTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF14B8A6), // Teal sólido
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            tag,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  bool _mesmaData(DateTime data1, DateTime data2) {
    return data1.year == data2.year && 
           data1.month == data2.month && 
           data1.day == data2.day;
  }

  ContaModel? _encontrarConta(String contaId) {
    try {
      return contas.firstWhere((c) => c.id == contaId);
    } catch (e) {
      return null;
    }
  }

  CartaoModel? _encontrarCartao(String cartaoId) {
    try {
      return cartoes.firstWhere((c) => c.id == cartaoId);
    } catch (e) {
      return null;
    }
  }

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarRecorrencia(String? tipo) {
    switch (tipo) {
      case 'semanal':
        return 'Semanal';
      case 'quinzenal':
        return 'Quinzenal';
      case 'mensal':
        return 'Mensal';
      case 'anual':
        return 'Anual';
      default:
        return 'Recorrente';
    }
  }

  String _formatarTipoEspecifico(String tipo) {
    switch (tipo) {
      case 'extra':
        return 'Extra';
      case 'previsivel':
        return 'Previsível';
      case 'parcelada':
        return 'Parcelada';
      default:
        return tipo;
    }
  }
}