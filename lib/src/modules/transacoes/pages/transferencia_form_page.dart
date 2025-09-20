// ↔️ Transferência Form Page - iPoupei Mobile
// 
// Página de formulário para transferências entre contas
// 
// Baseado em: Form Pattern + Transfer Pattern

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/transacao_service.dart';
import '../../contas/models/conta_model.dart';
import '../../contas/services/conta_service.dart';
import '../../auth/components/loading_overlay.dart';
import '../components/smart_field.dart';
import '../../../shared/components/ui/app_button.dart';
import '../../shared/theme/app_colors.dart';
import '../../categorias/data/categoria_icons.dart';

class TransferenciaFormPage extends StatefulWidget {
  const TransferenciaFormPage({super.key});

  @override
  State<TransferenciaFormPage> createState() => _TransferenciaFormPageState();
}

/// MoneyInputFormatter - idêntico ao transacao_form_page
class MoneyInputFormatter extends TextInputFormatter {
  final bool allowNegative;

  MoneyInputFormatter({this.allowNegative = true});
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    try {
      final numbersOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (numbersOnly.isEmpty) {
        return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
      }

      final value = int.parse(numbersOnly);
      final formatted = (value / 100).toStringAsFixed(2).replaceAll('.', ',');
      
      final newText = 'R\$ $formatted';
      
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    } catch (e) {
      return oldValue;
    }
  }
}

class _TransferenciaFormPageState extends State<TransferenciaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _transacaoService = TransacaoService.instance;
  final _contaService = ContaService.instance;
  
  // Controllers
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _contaOrigemController = TextEditingController();
  final _contaDestinoController = TextEditingController();
  final _dataController = TextEditingController();
  
  // 🎯 CONTROLADORES DE NAVEGAÇÃO (IGUAL TRANSACAO)
  final _scrollController = ScrollController();
  
  // Focus Nodes para navegação automática
  final _descricaoFocusNode = FocusNode();
  final _valorFocusNode = FocusNode();
  final _observacoesFocusNode = FocusNode();
  final _contaOrigemFocusNode = FocusNode();
  final _contaDestinoFocusNode = FocusNode();
  final _dataFocusNode = FocusNode();
  final _salvarButtonFocusNode = FocusNode();
  
  // Estados
  String? _contaOrigemId;
  String? _contaDestinoId;
  DateTime _dataSelecionada = DateTime.now();
  bool _loading = false;
  
  // 🎨 ESTADOS DE UI E PREVIEW (IGUAL TRANSACAO)
  Map<String, dynamic>? _preview;
  ContaModel? _contaOrigemEscolhida;
  ContaModel? _contaDestinoEscolhida;
  
  // Dados carregados
  List<ContaModel> _contas = [];

  @override
  void initState() {
    super.initState();
    _inicializarFormulario();
    _setupNavigationListeners(); // 🎯 NOVA FUNCIONALIDADE
    _carregarContas();
  }
  
  void _inicializarFormulario() {
    // Inicializar data controller com data atual
    _dataController.text = _formatarDataBr(_dataSelecionada);
    _descricaoController.text = 'Transferência entre contas';
  }
  
  /// 🎯 SETUP NAVEGAÇÃO AUTOMÁTICA (IGUAL TRANSACAO)
  void _setupNavigationListeners() {
    // Listeners de navegação automática
    _valorFocusNode.addListener(() {
      if (!_valorFocusNode.hasFocus && _valorController.text.isNotEmpty) {
        final valorParsed = _parseMoneyValue(_valorController.text);
        if (valorParsed > 0) {
          debugPrint('🔔 Valor válido, preparando navegação...');
        }
      }
    });
  }

  @override
  void dispose() {
    // Controllers
    _descricaoController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    _contaOrigemController.dispose();
    _contaDestinoController.dispose();
    _dataController.dispose();
    
    // 🎯 CONTROLADORES DE NAVEGAÇÃO
    _scrollController.dispose();
    _descricaoFocusNode.dispose();
    _valorFocusNode.dispose();
    _observacoesFocusNode.dispose();
    _contaOrigemFocusNode.dispose();
    _contaDestinoFocusNode.dispose();
    _dataFocusNode.dispose();
    _salvarButtonFocusNode.dispose();
    
    super.dispose();
  }

  /// 🔄 CARREGAR CONTAS
  Future<void> _carregarContas() async {
    try {
      final contas = await _contaService.fetchContas();
      setState(() {
        _contas = contas.where((c) => c.ativo).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar contas: $e')),
        );
      }
    }
  }

  /// 💰 PARSE VALOR MONETÁRIO (IGUAL TRANSACAO) 
  double _parseMoneyValue(String value) {
    if (value.isEmpty) return 0.0;
    
    String cleanValue = value
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    
    return double.tryParse(cleanValue) ?? 0.0;
  }
  
  /// 📅 FORMATAR DATA BRASILEIRA
  String _formatarDataBr(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
  
  /// 💰 CONVERTER INPUT PARA DOUBLE (MANTER COMPATIBILIDADE)
  double _converterInputParaDouble(String input) {
    return _parseMoneyValue(input);
  }

  /// 📅 SELECIONAR DATA
  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (data != null) {
      setState(() {
        _dataSelecionada = data;
        _dataController.text = _formatarDataBr(data); // ✅ ATUALIZAR CONTROLLER
      });
      _atualizarPreview(); // ✅ ATUALIZAR PREVIEW
    }
  }

  /// 🔄 ATUALIZAR PREVIEW DA TRANSFERÊNCIA
  void _atualizarPreview() {
    if (!mounted) return;
    
    final valor = _parseMoneyValue(_valorController.text);
    final descricao = _descricaoController.text;
    
    if (valor > 0 && descricao.isNotEmpty && _contaOrigemEscolhida != null && _contaDestinoEscolhida != null) {
      setState(() {
        _preview = {
          'valor': valor,
          'descricao': descricao,
          'data': _dataSelecionada,
          'contaOrigem': _contaOrigemEscolhida!.nome,
          'contaDestino': _contaDestinoEscolhida!.nome,
          'observacoes': _observacoesController.text,
        };
      });
    } else {
      setState(() {
        _preview = null;
      });
    }
  }

  /// 🔄 TROCAR CONTAS DE LUGAR
  void _trocarContas() {
    if (_contaOrigemId != null && _contaDestinoId != null) {
      setState(() {
        // Trocar IDs
        final tempId = _contaOrigemId;
        _contaOrigemId = _contaDestinoId;
        _contaDestinoId = tempId;
        
        // Trocar objetos
        final tempConta = _contaOrigemEscolhida;
        _contaOrigemEscolhida = _contaDestinoEscolhida;
        _contaDestinoEscolhida = tempConta;
        
        // Atualizar controllers
        _contaOrigemController.text = _contaOrigemEscolhida?.nome ?? '';
        _contaDestinoController.text = _contaDestinoEscolhida?.nome ?? '';
      });
      _atualizarPreview(); // ✅ ATUALIZAR PREVIEW
    }
  }

  /// 🏦 SELECIONAR CONTA ORIGEM (IGUAL TRANSACAO_FORM)
  Future<void> _selecionarContaOrigem() async {
    if (_contas.isEmpty) return;
    
    final conta = await showModalBottomSheet<ContaModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle do modal
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Título
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Conta de Origem',
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Lista scrollável de contas
            Expanded(
              child: ListView.builder(
                itemCount: _contas.where((c) => c.id != _contaDestinoId).length,
                itemBuilder: (context, index) {
                  final contasDisponiveis = _contas.where((c) => c.id != _contaDestinoId).toList();
                  final conta = contasDisponiveis[index];
                  final isSelected = _contaOrigemId == conta.id;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? AppColors.cinzaClaro : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: conta.cor != null && conta.cor!.isNotEmpty
                              ? Color(int.parse(conta.cor!.replaceAll('#', '0xFF')))
                              : Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: conta.icone != null && conta.icone!.isNotEmpty
                              ? _getIconeByName(conta.icone!, size: 20, color: Colors.white)
                              : const Icon(Icons.account_balance, color: Colors.white, size: 20),
                        ),
                      ),
                      title: Text(
                        conta.nome,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        'Saldo: R\$ ${conta.saldo.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: isSelected 
                          ? const Icon(Icons.check_circle, color: Colors.red)
                          : null,
                      onTap: () => Navigator.pop(context, conta),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    
    if (conta != null) {
      setState(() {
        _contaOrigemId = conta.id;
        _contaOrigemEscolhida = conta;
        _contaOrigemController.text = conta.nome;
      });
      _atualizarPreview();
      
      // ✅ NAVEGAÇÃO AUTOMÁTICA PARA CONTA DESTINO
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          debugPrint('🔔 Conta origem selecionada, navegando para conta destino...');
          _selecionarContaDestino();
        }
      });
    }
  }

  /// 🏦 SELECIONAR CONTA DESTINO (IGUAL TRANSACAO_FORM)
  Future<void> _selecionarContaDestino() async {
    if (_contas.isEmpty) return;
    
    final conta = await showModalBottomSheet<ContaModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle do modal
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Título
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Conta de Destino',
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Lista scrollável de contas
            Expanded(
              child: ListView.builder(
                itemCount: _contas.where((c) => c.id != _contaOrigemId).length,
                itemBuilder: (context, index) {
                  final contasDisponiveis = _contas.where((c) => c.id != _contaOrigemId).toList();
                  final conta = contasDisponiveis[index];
                  final isSelected = _contaDestinoId == conta.id;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? AppColors.cinzaClaro : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: conta.cor != null && conta.cor!.isNotEmpty
                              ? Color(int.parse(conta.cor!.replaceAll('#', '0xFF')))
                              : Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: conta.icone != null && conta.icone!.isNotEmpty
                              ? _getIconeByName(conta.icone!, size: 20, color: Colors.white)
                              : const Icon(Icons.account_balance, color: Colors.white, size: 20),
                        ),
                      ),
                      title: Text(
                        conta.nome,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        'Saldo: R\$ ${conta.saldo.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: isSelected 
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () => Navigator.pop(context, conta),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    
    if (conta != null) {
      setState(() {
        _contaDestinoId = conta.id;
        _contaDestinoEscolhida = conta;
        _contaDestinoController.text = conta.nome;
      });
      _atualizarPreview();
      
      // ✅ SCROLL FINAL APÓS SELECIONAR CONTA DESTINO
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients) {
          debugPrint('🔔 Conta destino selecionada, fazendo scroll final...');
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent * 0.90,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  /// 👁️ VERIFICAR SE TEM DADOS MÍNIMOS PARA PREVIEW
  bool _temDadosMinimos() {
    final valor = _parseMoneyValue(_valorController.text);
    return valor > 0 && 
           _descricaoController.text.isNotEmpty && 
           _contaOrigemEscolhida != null && 
           _contaDestinoEscolhida != null;
  }

  /// 🎨 CONSTRUIR WIDGET DE PREVIEW LIMPO (ESTILO DEVICE)
  Widget _buildPreview() {
    if (_preview == null || !_temDadosMinimos()) {
      return const SizedBox.shrink();
    }
    final valor = _preview!['valor'] as double;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.azulHeader.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.azulHeader.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.preview, color: AppColors.azulHeader, size: 20),
              SizedBox(width: 8),
              Text(
                'PREVIEW DA TRANSFERÊNCIA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulHeader,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Conta Origem
          Row(
            children: [
              // Ícone da conta origem
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _contaOrigemEscolhida?.cor != null && _contaOrigemEscolhida!.cor!.isNotEmpty
                      ? Color(int.parse(_contaOrigemEscolhida!.cor!.replaceAll('#', '0xFF')))
                      : AppColors.azulHeader,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: _contaOrigemEscolhida?.icone != null && _contaOrigemEscolhida!.icone!.isNotEmpty
                      ? _getIconeByName(_contaOrigemEscolhida!.icone!, size: 18, color: Colors.white)
                      : const Icon(Icons.account_balance, size: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              
              // Dados da conta origem
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _contaOrigemEscolhida?.nome ?? 'Conta Origem',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.cinzaEscuro,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _formatarValor(_contaOrigemEscolhida?.saldo ?? 0.0),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.cinzaTexto,
                          ),
                        ),
                        const Text(
                          ' → ',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.cinzaMedio,
                          ),
                        ),
                        Text(
                          _formatarValor((_contaOrigemEscolhida?.saldo ?? 0.0) - valor),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ((_contaOrigemEscolhida?.saldo ?? 0.0) - valor) >= 0 
                                ? AppColors.verdeSucesso 
                                : AppColors.vermelhoErro,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Conta Destino
          Row(
            children: [
              // Ícone da conta destino
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _contaDestinoEscolhida?.cor != null && _contaDestinoEscolhida!.cor!.isNotEmpty
                      ? Color(int.parse(_contaDestinoEscolhida!.cor!.replaceAll('#', '0xFF')))
                      : AppColors.azulHeader,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: _contaDestinoEscolhida?.icone != null && _contaDestinoEscolhida!.icone!.isNotEmpty
                      ? _getIconeByName(_contaDestinoEscolhida!.icone!, size: 18, color: Colors.white)
                      : const Icon(Icons.account_balance, size: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              
              // Dados da conta destino
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _contaDestinoEscolhida?.nome ?? 'Conta Destino',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.cinzaEscuro,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _formatarValor(_contaDestinoEscolhida?.saldo ?? 0.0),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.cinzaTexto,
                          ),
                        ),
                        const Text(
                          ' → ',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.cinzaMedio,
                          ),
                        ),
                        Text(
                          _formatarValor((_contaDestinoEscolhida?.saldo ?? 0.0) + valor),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.verdeSucesso,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Observações (se houver)
          if (_preview!['observacoes']?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              _preview!['observacoes'],
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.cinzaTexto,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 💰 FORMATAR VALOR MONETÁRIO
  String _formatarValor(double valor) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatter.format(valor);
  }


  /// 💾 SALVAR TRANSFERÊNCIA
  Future<void> _salvarTransferencia() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final descricao = _descricaoController.text.trim();
      final valor = _converterInputParaDouble(_valorController.text);
      final observacoes = _observacoesController.text.trim();

      await _transacaoService.criarTransferencia(
        contaOrigemId: _contaOrigemId!,
        contaDestinoId: _contaDestinoId!,
        valor: valor,
        data: _dataSelecionada,
        descricao: descricao,
        observacoes: observacoes.isEmpty ? null : observacoes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transferência "$descricao" criada com sucesso!')),
        );
        Navigator.of(context).pop(true); // Retorna sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar transferência: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 🎨 WIDGET SELETOR DE CONTAS
  Widget _buildSeletorContas() {
    final contaOrigem = _contas.firstWhere(
      (c) => c.id == _contaOrigemId,
      orElse: () => ContaModel(
        id: '',
        usuarioId: '',
        nome: 'Selecione uma conta',
        tipo: 'corrente',
        saldoInicial: 0,
        saldo: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final contaDestino = _contas.firstWhere(
      (c) => c.id == _contaDestinoId,
      orElse: () => ContaModel(
        id: '',
        usuarioId: '',
        nome: 'Selecione uma conta',
        tipo: 'corrente',
        saldoInicial: 0,
        saldo: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transferir de/para',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Conta origem
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('De:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: _contaOrigemId != null ? Colors.red[50] : Colors.grey[50],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contaOrigem.nome,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (_contaOrigemId != null)
                              Text(
                                'Saldo: R\$ ${contaOrigem.saldo.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Botão trocar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      IconButton(
                        onPressed: _contaOrigemId != null && _contaDestinoId != null 
                            ? _trocarContas 
                            : null,
                        icon: const Icon(Icons.swap_horiz),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue[100],
                          foregroundColor: Colors.blue[700],
                        ),
                        tooltip: 'Trocar contas',
                      ),
                    ],
                  ),
                ),
                
                // Conta destino
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Para:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: _contaDestinoId != null ? Colors.green[50] : Colors.grey[50],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contaDestino.nome,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (_contaDestinoId != null)
                              Text(
                                'Saldo: R\$ ${contaDestino.saldo.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MÉTODO PARA RENDERIZAR ÍCONES DAS CONTAS
  Widget _getIconeByName(String icone, {required double size, Color? color}) {
    return CategoriaIcons.renderIcon(icone, size, color: color);
  }

  /// Helper para criar ícone pequeno colorido para campos preenchidos
  Widget _buildSmallColoredIcon({
    required String? icone,
    required Color? cor,
    required Color fallbackColor,
    double size = 18,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cor ?? fallbackColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: icone != null && icone.isNotEmpty
            ? _getIconeByName(icone, size: size * 0.7, color: Colors.white)
            : Icon(Icons.account_balance, size: size * 0.7, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      message: 'Criando transferência...',
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppColors.azulHeader,
          foregroundColor: Colors.white,
          title: const Text('Nova Transferência'),
          elevation: 0,
          actions: [
            if (_preview != null)
              TextButton(
                onPressed: () => _salvarTransferencia(),
                child: const Text(
                  'SALVAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          controller: _scrollController, // ✅ SCROLL CONTROLLER
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ CAMPOS COM SMARTFIELD E NAVEGAÇÃO AUTOMÁTICA
                
                // Descrição
                SmartField(
                  controller: _descricaoController,
                  focusNode: _descricaoFocusNode,
                  label: 'Descrição',
                  hint: 'Ex: Transferência entre contas',
                  icon: Icons.description,
                  isCartaoContext: false,
                  transactionContext: 'transferencia',
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () {
                    debugPrint('🔔 Descrição completa, indo para valor...');
                    FocusScope.of(context).unfocus();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        _valorFocusNode.requestFocus();
                      }
                    });
                  },
                  onChanged: (value) => _atualizarPreview(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Descrição é obrigatória';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Valor
                SmartField(
                  controller: _valorController,
                  focusNode: _valorFocusNode,
                  label: 'Valor',
                  hint: 'R\$ 0,00',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  isCartaoContext: false,
                  transactionContext: 'transferencia',
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () {
                    debugPrint('🔔 Valor completo, indo para conta origem...');
                    final valor = _parseMoneyValue(_valorController.text);
                    if (valor > 0) {
                      FocusScope.of(context).unfocus();
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          _selecionarContaOrigem();
                        }
                      });
                    }
                  },
                  onChanged: (value) => _atualizarPreview(),
                  validator: (value) {
                    final valor = _parseMoneyValue(value ?? '');
                    if (valor <= 0) {
                      return 'Valor deve ser maior que zero';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ✅ CAMPOS DE CONTAS COM SMARTFIELD
                Row(
                  children: [
                    // Conta origem
                    Expanded(
                      child: SmartField(
                        controller: _contaOrigemController,
                        focusNode: _contaOrigemFocusNode,
                        label: 'Conta de Origem',
                        hint: 'Selecionar conta',
                        icon: _contaOrigemEscolhida != null
                            ? null // Remove ícone padrão quando preenchido
                            : Icons.account_balance,
                        leadingIcon: _contaOrigemEscolhida != null
                            ? _buildSmallColoredIcon(
                                icone: _contaOrigemEscolhida!.icone,
                                cor: _contaOrigemEscolhida!.cor != null && _contaOrigemEscolhida!.cor!.isNotEmpty
                                    ? Color(int.parse(_contaOrigemEscolhida!.cor!.replaceAll('#', '0xFF')))
                                    : null,
                                fallbackColor: AppColors.azulHeader,
                              )
                            : null,
                        readOnly: true,
                        isCartaoContext: false,
                        transactionContext: 'transferencia',
                        onTap: _selecionarContaOrigem,
                        validator: (value) {
                          if (_contaOrigemEscolhida == null) {
                            return 'Selecione a conta de origem';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    // Botão trocar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          IconButton(
                            onPressed: _contaOrigemId != null && _contaDestinoId != null 
                                ? _trocarContas 
                                : null,
                            icon: const Icon(Icons.swap_horiz),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.azulHeader.withOpacity(0.1),
                              foregroundColor: AppColors.azulHeader,
                            ),
                            tooltip: 'Trocar contas',
                          ),
                        ],
                      ),
                    ),
                    
                    // Conta destino
                    Expanded(
                      child: SmartField(
                        controller: _contaDestinoController,
                        focusNode: _contaDestinoFocusNode,
                        label: 'Conta de Destino',
                        hint: 'Selecionar conta',
                        icon: _contaDestinoEscolhida != null
                            ? null // Remove ícone padrão quando preenchido
                            : Icons.account_balance,
                        leadingIcon: _contaDestinoEscolhida != null
                            ? _buildSmallColoredIcon(
                                icone: _contaDestinoEscolhida!.icone,
                                cor: _contaDestinoEscolhida!.cor != null && _contaDestinoEscolhida!.cor!.isNotEmpty
                                    ? Color(int.parse(_contaDestinoEscolhida!.cor!.replaceAll('#', '0xFF')))
                                    : null,
                                fallbackColor: AppColors.azulHeader,
                              )
                            : null,
                        readOnly: true,
                        isCartaoContext: false,
                        transactionContext: 'transferencia',
                        onTap: _selecionarContaDestino,
                        validator: (value) {
                          if (_contaDestinoEscolhida == null) {
                            return 'Selecione a conta de destino';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Data
                SmartField(
                  controller: _dataController,
                  focusNode: _dataFocusNode,
                  label: 'Data da Transferência',
                  hint: 'DD/MM/AAAA',
                  icon: Icons.calendar_today,
                  readOnly: true,
                  isCartaoContext: false,
                  transactionContext: 'transferencia',
                  onTap: _selecionarData,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Data é obrigatória';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Observações
                SmartField(
                  controller: _observacoesController,
                  focusNode: _observacoesFocusNode,
                  label: 'Observações (opcional)',
                  hint: 'Informações adicionais...',
                  icon: Icons.notes,
                  maxLines: 3,
                  isCartaoContext: false,
                  transactionContext: 'transferencia',
                  textInputAction: TextInputAction.done,
                  onChanged: (value) => _atualizarPreview(),
                  onEditingComplete: () {
                    debugPrint('🔔 Observações completas...');
                    FocusScope.of(context).unfocus();
                    // Scroll para mostrar preview
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted && _scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent * 0.90,
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOut,
                        );
                      }
                    });
                  },
                ),

                const SizedBox(height: 8),

                // ✅ PREVIEW DA TRANSFERÊNCIA
                if (_preview != null) _buildPreview(),
                
                const SizedBox(height: 24),

                // ✅ BOTÕES COM APPBUTTON (IGUAL TRANSACAO)
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outline(
                        text: 'Cancelar',
                        onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                        size: AppButtonSize.medium,
                        fullWidth: true,
                        customColor: AppColors.azulHeader, // ✅ COR AZUL TRANSFERÊNCIA
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppButtonExtensions.transferencia(
                        text: 'Transferir',
                        onPressed: _loading ? null : _salvarTransferencia,
                        size: AppButtonSize.medium,
                        fullWidth: true,
                        isLoading: _loading,
                        icon: Icons.swap_horiz,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                
                // ✅ PADDING EXTRA PARA BOTÕES DE NAVEGAÇÃO
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}