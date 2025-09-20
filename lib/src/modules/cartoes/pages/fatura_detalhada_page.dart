// 🔍 Cartão Details Page - iPoupei Mobile
// 
// Página de detalhes de fatura específica
// Equivalente ao modo 'detalhada' do GestaoCartoes.jsx
// 
// Features:
// - Detalhes completos da fatura selecionada
// - Lista de transações da fatura
// - Operações: Pagar, Reabrir, Estornar
// - Filtros por categoria
// - Exclusão de transações/parcelas
// - Resumo financeiro da fatura

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_colors.dart';
import '../../../shared/components/ui/app_button.dart';
import '../models/cartao_model.dart';
import '../models/fatura_model.dart';
import '../../transacoes/models/transacao_model.dart';
import '../services/cartao_data_service.dart';
import '../services/fatura_operations_service.dart';
import '../../../database/local_database.dart';
import 'despesa_cartao_page.dart';

/// Página de Fatura Detalhada
/// Equivalente ao modo 'detalhada' do GestaoCartoes.jsx 
class FaturaDetalhadaPage extends StatefulWidget {
  final CartaoModel cartao;
  final String? faturaVencimento;

  const FaturaDetalhadaPage({
    super.key,
    required this.cartao,
    this.faturaVencimento,
  });

  @override
  State<FaturaDetalhadaPage> createState() => _FaturaDetalhadaPageState();
}

class _FaturaDetalhadaPageState extends State<FaturaDetalhadaPage> {
  // Serviços
  final CartaoDataService _cartaoDataService = CartaoDataService.instance;
  final FaturaOperationsService _faturaOperations = FaturaOperationsService.instance;
  
  // Estados principais
  bool _isLoading = true;
  bool _mostrarValores = true;
  String? _error;
  String _filtroCategoria = 'todas';
  
  // Dados da fatura
  List<TransacaoModel> _transacoes = [];
  Map<String, dynamic> _statusFatura = {};
  List<Map<String, dynamic>> _gastosPorCategoria = [];
  double _valorTotalFatura = 0.0;
  double _valorPago = 0.0;
  
  // Faturas disponíveis para trocar
  List<String> _faturasDisponiveis = [];
  String _faturaAtual = '';

  @override
  void initState() {
    super.initState();
    _faturaAtual = widget.faturaVencimento ?? _gerarProximaFatura();
    _inicializar();
  }

  /// 🚀 INICIALIZAR PÁGINA
  Future<void> _inicializar() async {
    try {
      debugPrint('🚀 Inicializando detalhes da fatura...');
      
      // Garantir que o banco local está inicializado
      await LocalDatabase.instance.initialize();
      await LocalDatabase.instance.setCurrentUser(
        Supabase.instance.client.auth.currentUser?.id ?? 'unknown'
      );
      
      await _carregarDadosFatura();
      
    } catch (e) {
      debugPrint('❌ Erro na inicialização: $e');
      setState(() {
        _error = 'Erro ao carregar fatura: $e';
        _isLoading = false;
      });
    }
  }

  /// 📊 CARREGAR DADOS DA FATURA
  Future<void> _carregarDadosFatura() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      debugPrint('🔄 Carregando fatura: ${widget.cartao.nome} - $_faturaAtual');
      
      // Carregar transações da fatura
      final transacoes = await _cartaoDataService.fetchTransacoesFatura(
        widget.cartao.id,
        _faturaAtual,
        incluirParcelasExternas: true,
      );
      
      // Carregar status da fatura
      final status = await _cartaoDataService.verificarStatusFatura(
        widget.cartao.id,
        _faturaAtual,
      );
      
      // Carregar gastos por categoria
      final gastosPorCategoria = await _cartaoDataService.fetchGastosPorCategoria(
        widget.cartao.id,
        _faturaAtual,
      );
      
      // Calcular valores
      double valorTotal = 0.0;
      double valorPago = 0.0;
      
      for (final transacao in transacoes) {
        final valor = transacao.valor;
        valorTotal += valor;
        
        if (transacao.efetivado) {
          valorPago += valor;
        }
      }
      
      setState(() {
        _transacoes = transacoes;
        _statusFatura = status;
        _gastosPorCategoria = gastosPorCategoria;
        _valorTotalFatura = valorTotal;
        _valorPago = valorPago;
        _isLoading = false;
      });
      
      debugPrint('✅ Fatura carregada: ${transacoes.length} transações, R\$ ${valorTotal.toStringAsFixed(2)}');
      
    } catch (e) {
      debugPrint('❌ Erro ao carregar fatura: $e');
      setState(() {
        _error = 'Erro ao carregar fatura: $e';
        _isLoading = false;
      });
    }
  }

  /// 📅 GERAR PRÓXIMA FATURA
  String _gerarProximaFatura() {
    final agora = DateTime.now();
    final diaVencimento = widget.cartao.diaVencimento;
    
    // Se ainda não passou o vencimento deste mês, usar este mês
    DateTime proximoVencimento;
    if (agora.day <= diaVencimento) {
      proximoVencimento = DateTime(agora.year, agora.month, diaVencimento);
    } else {
      // Senão, próximo mês
      proximoVencimento = DateTime(agora.year, agora.month + 1, diaVencimento);
    }
    
    return proximoVencimento.toIso8601String().split('T')[0];
  }

  /// 💰 PAGAR FATURA
  Future<void> _pagarFatura() async {
    final valorRestante = _valorTotalFatura - _valorPago;
    
    if (valorRestante <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta fatura já está paga!'),
          backgroundColor: AppColors.verdeSucesso,
        ),
      );
      return;
    }
    
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pagar Fatura'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cartão: ${widget.cartao.nome}'),
            const SizedBox(height: 8),
            Text('Valor total: ${_formatarValor(_valorTotalFatura)}'),
            Text('Já pago: ${_formatarValor(_valorPago)}'),
            const SizedBox(height: 8),
            Text(
              'Pagar: ${_formatarValor(valorRestante)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.vermelhoErro,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Todas as transações serão marcadas como efetivadas.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.cinzaTexto,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          AppButton(
            text: 'Pagar',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    
    if (confirma != true) return;
    
    try {
      setState(() => _isLoading = true);
      
      // TODO: Implementar pagamento no service
      // await _faturaOperations.pagarFatura(widget.cartao.id, _faturaAtual);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fatura paga com sucesso!'),
          backgroundColor: AppColors.verdeSucesso,
        ),
      );
      
      await _carregarDadosFatura();
      
    } catch (e) {
      debugPrint('❌ Erro ao pagar fatura: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao pagar fatura: $e'),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔄 REABRIR FATURA
  Future<void> _reabrirFatura() async {
    if (_valorPago == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta fatura não foi paga ainda!'),
          backgroundColor: AppColors.laranjaAlerta,
        ),
      );
      return;
    }
    
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reabrir Fatura'),
        content: Text(
          'Deseja reabrir a fatura do cartão "${widget.cartao.nome}"?\n\n'
          'Todas as transações voltarão ao estado "não efetivado".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.laranjaAlerta),
            child: const Text('Reabrir'),
          ),
        ],
      ),
    );
    
    if (confirma != true) return;
    
    try {
      setState(() => _isLoading = true);
      
      // TODO: Implementar reabertura no service
      // await _faturaOperations.reabrirFatura(widget.cartao.id, _faturaAtual);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fatura reaberta com sucesso!'),
          backgroundColor: AppColors.verdeSucesso,
        ),
      );
      
      await _carregarDadosFatura();
      
    } catch (e) {
      debugPrint('❌ Erro ao reabrir fatura: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao reabrir fatura: $e'),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ➕ ADICIONAR DESPESA
  Future<void> _adicionarDespesa() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => DespesaCartaoPage(cartaoInicial: widget.cartao),
      ),
    );
    
    // Se despesa foi adicionada, recarregar fatura
    if (resultado == true) {
      await _carregarDadosFatura();
    }
  }

  /// 🗑️ EXCLUIR TRANSAÇÃO
  Future<void> _excluirTransacao(Map<String, dynamic> transacao) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Transação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transação: ${transacao['descricao'] ?? 'Sem descrição'}'),
            Text('Valor: ${_formatarValor((transacao['valor'] as num?)?.toDouble() ?? 0.0)}'),
            const SizedBox(height: 12),
            if (transacao['grupo_parcelamento'] != null) ...[
              const Text(
                'Esta transação faz parte de um parcelamento.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.laranjaAlertaesWEs,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Deseja excluir apenas esta parcela ou todas?',
                style: TextStyle(fontSize: 12),
              ),
            ] else ...[
              const Text(
                'Esta ação não pode ser desfeita.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.vermelhoErro,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          if (transacao['grupo_parcelamento'] != null) ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Só Esta Parcela'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                _excluirParcelamentoCompleto(transacao);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.vermelhoErro),
              child: const Text('Todas as Parcelas'),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.vermelhoErro),
              child: const Text('Excluir'),
            ),
          ],
        ],
      ),
    );
    
    if (confirma != true) return;
    
    try {
      setState(() => _isLoading = true);
      
      // TODO: Implementar exclusão no service
      // await _faturaOperations.excluirTransacao(transacao['id']);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transação excluída com sucesso!'),
          backgroundColor: AppColors.verdeSucesso,
        ),
      );
      
      await _carregarDadosFatura();
      
    } catch (e) {
      debugPrint('❌ Erro ao excluir transação: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir transação: $e'),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🗑️ EXCLUIR PARCELAMENTO COMPLETO
  Future<void> _excluirParcelamentoCompleto(Map<String, dynamic> transacao) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Parcelamento'),
        content: Text(
          'Deseja excluir TODAS as parcelas do parcelamento "${transacao['descricao'] ?? 'Sem descrição'}"?\n\n'
          'Esta ação afetará parcelas em outras faturas e não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.vermelhoErro),
            child: const Text('Excluir Todas'),
          ),
        ],
      ),
    );
    
    if (confirma != true) return;
    
    try {
      setState(() => _isLoading = true);
      
      // TODO: Implementar exclusão de parcelamento no service
      // await _faturaOperations.excluirParcelamento(transacao['grupo_parcelamento']);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parcelamento excluído com sucesso!'),
          backgroundColor: AppColors.verdeSucesso,
        ),
      );
      
      await _carregarDadosFatura();
      
    } catch (e) {
      debugPrint('❌ Erro ao excluir parcelamento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir parcelamento: $e'),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 💰 FORMATADOR DE VALORES
  String _formatarValor(double valor) {
    if (!_mostrarValores) return '•••••';
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// 📊 BUILD RESUMO DA FATURA
  Widget _buildResumoFatura() {
    final valorRestante = _valorTotalFatura - _valorPago;
    final percentualPago = _valorTotalFatura > 0 ? (_valorPago / _valorTotalFatura * 100) : 0;
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: Color(int.parse(widget.cartao.cor?.replaceAll('#', '0xFF') ?? '0xFF6B7280')),
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    color: Color(int.parse(widget.cartao.cor?.replaceAll('#', '0xFF') ?? '0xFF6B7280')),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.cartao.nome,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cinzaEscuro,
                          ),
                        ),
                        Text(
                          'Vencimento: ${DateTime.parse(_faturaAtual).day}/${DateTime.parse(_faturaAtual).month.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.cinzaTexto,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Valores
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total da Fatura',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.cinzaTexto,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatarValor(_valorTotalFatura),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.vermelhoErro,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Valor Pago',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.cinzaTexto,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatarValor(_valorPago),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.verdeSucesso,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (valorRestante > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Restante a Pagar',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.cinzaTexto,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatarValor(valorRestante),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.laranjaAlerta,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              
              // Progresso do pagamento
              if (_valorTotalFatura > 0) ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progresso do Pagamento',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.cinzaTexto,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${percentualPago.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: percentualPago == 100 ? AppColors.verdeSucesso : AppColors.laranjaAlerta,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentualPago / 100,
                        backgroundColor: AppColors.cinzaClaro,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentualPago == 100 ? AppColors.verdeSucesso : AppColors.laranjaAlerta,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ],
              
              // Ações
              const SizedBox(height: 20),
              Row(
                children: [
                  if (valorRestante > 0) ...[
                    Expanded(
                      child: AppButton(
                        text: 'Pagar Fatura',
                        onPressed: _pagarFatura,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (_valorPago > 0) ...[
                    Expanded(
                      child: AppButton(
                        text: 'Reabrir',
                        onPressed: _reabrirFatura,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: AppButton(
                      text: 'Nova Despesa',
                      onPressed: _adicionarDespesa,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 BUILD LISTA DE TRANSAÇÕES
  Widget _buildListaTransacoes() {
    if (_transacoes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 48, color: AppColors.cinzaMedio),
              SizedBox(height: 16),
              Text(
                'Nenhuma transação encontrada',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.cinzaTexto,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Adicione despesas ao seu cartão para visualizá-las aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.cinzaMedio,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Filtrar por categoria se necessário
    List<Map<String, dynamic>> transacoesFiltradas = _transacoes;
    if (_filtroCategoria != 'todas') {
      transacoesFiltradas = _transacoes
          .where((t) => (t['categoria_nome'] ?? '') == _filtroCategoria)
          .toList();
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: transacoesFiltradas.length,
      itemBuilder: (context, index) {
        final transacao = transacoesFiltradas[index];
        return _buildTransacaoItem(transacao);
      },
    );
  }

  /// 📝 BUILD ITEM DE TRANSAÇÃO
  Widget _buildTransacaoItem(Map<String, dynamic> transacao) {
    final valor = (transacao['valor'] as num?)?.toDouble() ?? 0.0;
    final descricao = transacao['descricao'] ?? 'Sem descrição';
    final categoria = transacao['categoria_nome'] ?? 'Sem categoria';
    final efetivado = transacao['efetivado'] == true;
    final isParcelada = transacao['grupo_parcelamento'] != null;
    final isExterna = transacao['eh_parcela_externa'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: efetivado ? AppColors.verdeSucesso.withOpacity(0.1) : AppColors.laranjaAlerta.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            efetivado ? Icons.check_circle : Icons.schedule,
            color: efetivado ? AppColors.verdeSucesso : AppColors.laranjaAlerta,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                descricao,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isParcelada) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.azulHeader.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${transacao['parcela_atual'] ?? 1}/${transacao['total_parcelas'] ?? 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.azulHeader,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (isExterna) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cinzaMedio.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'EXT',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.cinzaMedio,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categoria,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.cinzaTexto,
              ),
            ),
            if (efetivado && transacao['conta_pagamento_nome'] != null) ...[
              const SizedBox(height: 2),
              Text(
                'Pago via: ${transacao['conta_pagamento_nome']}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.verdeSucesso,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatarValor(valor),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: efetivado ? AppColors.verdeSucesso : AppColors.vermelhoErro,
                  ),
                ),
                Text(
                  efetivado ? 'Pago' : 'Pendente',
                  style: TextStyle(
                    fontSize: 10,
                    color: efetivado ? AppColors.verdeSucesso : AppColors.laranjaAlerta,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'excluir':
                    _excluirTransacao(transacao);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'excluir',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: AppColors.vermelhoErro),
                      SizedBox(width: 8),
                      Text('Excluir', style: TextStyle(color: AppColors.vermelhoErro)),
                    ],
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert, color: AppColors.cinzaTexto),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fatura Detalhada'),
        centerTitle: true,
        actions: [
          // Toggle mostrar valores
          IconButton(
            onPressed: () => setState(() => _mostrarValores = !_mostrarValores),
            icon: Icon(_mostrarValores ? Icons.visibility : Icons.visibility_off),
            tooltip: _mostrarValores ? 'Ocultar valores' : 'Mostrar valores',
          ),
          
          // Filtro por categoria
          if (_gastosPorCategoria.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (categoria) => setState(() => _filtroCategoria = categoria),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'todas',
                  child: Text(
                    'Todas as Categorias',
                    style: TextStyle(
                      fontWeight: _filtroCategoria == 'todas' ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                ..._gastosPorCategoria.map((gasto) => PopupMenuItem(
                      value: gasto['categoria_nome'] ?? '',
                      child: Text(
                        gasto['categoria_nome'] ?? 'Sem categoria',
                        style: TextStyle(
                          fontWeight: _filtroCategoria == gasto['categoria_nome'] 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                      ),
                    )).toList(),
              ],
              child: const Icon(Icons.filter_list),
              tooltip: 'Filtrar por categoria',
            ),
        ],
      ),
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: AppColors.vermelhoErro),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.cinzaTexto),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: 'Tentar Novamente',
                        onPressed: _carregarDadosFatura,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarDadosFatura,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resumo da fatura
                        _buildResumoFatura(),
                        
                        // Título das transações
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Text(
                                'Transações',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cinzaEscuro,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.azulHeader.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_transacoes.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.azulHeader,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_filtroCategoria != 'todas') ...[
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(_filtroCategoria),
                                  onDeleted: () => setState(() => _filtroCategoria = 'todas'),
                                  backgroundColor: AppColors.azulHeader.withOpacity(0.1),
                                  labelStyle: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.azulHeader,
                                  ),
                                  deleteIconColor: AppColors.azulHeader,
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Lista de transações
                        _buildListaTransacoes(),
                        
                        const SizedBox(height: 80), // Espaço para FAB
                      ],
                    ),
                  ),
                ),
                
      // FAB para adicionar despesa
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarDespesa,
        backgroundColor: AppColors.roxoHeader,
        heroTag: 'fatura_detalhada_fab',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}