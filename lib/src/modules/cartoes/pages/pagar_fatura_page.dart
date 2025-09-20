// ⚠️ PÁGINA INATIVA - NÃO É USADA NO APP
// Esta página foi substituída por pagamento_fatura_page.dart
// Mantida apenas para referência histórica

/* 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../shared/widgets/smart_field.dart';
import '../models/cartao_model.dart';
import '../models/fatura_model.dart';
import '../services/fatura_operations_service.dart';
import '../../contas/models/conta_model.dart';
import '../../contas/services/conta_service.dart';

// PÁGINA COMENTADA - VER pagamento_fatura_page.dart
/*
class PagarFaturaPage extends StatefulWidget {
  final CartaoModel cartao;
  final FaturaModel fatura;

  const PagarFaturaPage({
    super.key,
    required this.cartao,
    required this.fatura,
  });

  @override
  State<PagarFaturaPage> createState() => _PagarFaturaPageState();
}

class _PagarFaturaPageState extends State<PagarFaturaPage> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _valorFocusNode = FocusNode();
  final _observacoesController = TextEditingController();
  
  final FaturaOperationsService _faturaOperations = FaturaOperationsService.instance;
  final ContaService _contaService = ContaService.instance;
  
  String? _contaSelecionada;
  DateTime _dataPagamento = DateTime.now();
  bool _isLoading = false;
  bool _pagarValorTotal = true;
  List<ContaModel> _contas = [];
  
  // Variáveis para parcelamento
  int _numeroParcelas = 2;
  final _valorParcelaController = TextEditingController();
  final _valorParcelaFocusNode = FocusNode();
  
  // Opções de pagamento
  final List<Map<String, dynamic>> _opcoesPagamento = [
    {
      'tipo': 'total',
      'titulo': 'Valor Total da Fatura',
      'icone': Icons.credit_card,
      'cor': Colors.green,
    },
    {
      'tipo': 'minimo',
      'titulo': 'Valor Mínimo',
      'icone': Icons.attach_money,
      'cor': Colors.orange,
    },
    {
      'tipo': 'personalizado',
      'titulo': 'Valor Personalizado',
      'icone': Icons.edit,
      'cor': Colors.blue,
    },
    {
      'tipo': 'parcelado',
      'titulo': 'Pagamento Parcelado',
      'icone': Icons.calendar_month,
      'cor': Colors.purple,
    },
  ];
  String _tipoPagamentoSelecionado = 'total';

  @override
  void initState() {
    super.initState();
    _valorController.text = CurrencyFormatter.formatInput(widget.fatura.valorTotal);
    _carregarContas();
  }

  @override
  void dispose() {
    _valorController.dispose();
    _valorFocusNode.dispose();
    _valorParcelaController.dispose();
    _valorParcelaFocusNode.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _carregarContas() async {
    try {
      final contas = await _contaService.fetchContas();
      setState(() {
        _contas = contas.where((conta) => conta.ativo).toList();
        // Selecionar conta de débito automático se existir
        if (widget.cartao.contaDebitoId != null) {
          final contaDebito = _contas.firstWhere(
            (c) => c.id == widget.cartao.contaDebitoId,
            orElse: () => _contas.isNotEmpty ? _contas.first : ContaModel(
              id: '',
              nome: '',
              tipo: '',
              saldo: 0,
              ativo: true,
              dataAtualizacao: DateTime.now(),
            ),
          );
          if (contaDebito.id.isNotEmpty) {
            _contaSelecionada = contaDebito.id;
          }
        }
      });
    } catch (e) {
      debugPrint('Erro ao carregar contas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.roxoHeader,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Pagar Fatura',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: _mostrarAjuda,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCartaoInfo(),
            const SizedBox(height: 20),
            _buildFaturaInfo(),
            const SizedBox(height: 20),
            _buildOpcoesPagamento(),
            const SizedBox(height: 20),
            _buildContaPagamento(),
            const SizedBox(height: 20),
            _buildDataPagamento(),
            const SizedBox(height: 20),
            _buildObservacoes(),
            const SizedBox(height: 100), // Espaço para o botão fixo
          ],
        ),
      ),
    );
  }

  Widget _buildCartaoInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Color(int.parse(widget.cartao.cor?.replaceAll('#', '0xFF') ?? '0xFF6200EA')),
              Color(int.parse(widget.cartao.cor?.replaceAll('#', '0xFF') ?? '0xFF6200EA')).withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.credit_card, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.cartao.nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.cartao.bandeira != null)
              Text(
                'Bandeira: ${widget.cartao.bandeira}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            if (widget.cartao.banco != null)
              Text(
                'Banco: ${widget.cartao.banco}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaturaInfo() {
    final diasAteVencimento = widget.fatura.diasAteVencimento;
    final isVencida = diasAteVencimento < 0;
    final isProximaVencimento = diasAteVencimento <= 5 && diasAteVencimento >= 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: isVencida ? Colors.red : isProximaVencimento ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Informações da Fatura',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Valor Total', CurrencyFormatter.format(widget.fatura.valorTotal)),
            _buildInfoRow('Valor Mínimo', CurrencyFormatter.format(widget.fatura.valorMinimo ?? widget.fatura.valorTotal * 0.15)),
            _buildInfoRow('Vencimento', DateFormat('dd/MM/yyyy').format(widget.fatura.dataVencimento)),
            _buildInfoRow(
              'Status',
              isVencida 
                ? 'Vencida (${diasAteVencimento.abs()} dias)'
                : isProximaVencimento 
                  ? 'Próxima ao vencimento ($diasAteVencimento dias)'
                  : 'Em dia',
              cor: isVencida ? Colors.red : isProximaVencimento ? Colors.orange : Colors.green,
            ),
            if (widget.fatura.valorPago > 0) ...[
              const Divider(),
              _buildInfoRow('Valor já Pago', CurrencyFormatter.format(widget.fatura.valorPago), cor: Colors.blue),
              _buildInfoRow('Saldo Devedor', CurrencyFormatter.format(widget.fatura.valorTotal - widget.fatura.valorPago), cor: Colors.orange),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? cor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: cor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcoesPagamento() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Valor a Pagar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._opcoesPagamento.map((opcao) => _buildOpcaoPagamento(opcao)),
            if (_tipoPagamentoSelecionado == 'personalizado') ...[
              const SizedBox(height: 16),
              SmartField(
                controller: _valorController,
                focusNode: _valorFocusNode,
                label: 'Valor Personalizado',
                hint: 'R\$ 0,00',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^[\d,\.]*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Digite o valor';
                  final valor = CurrencyFormatter.parseValue(value);
                  if (valor <= 0) return 'Valor deve ser maior que zero';
                  if (valor > widget.fatura.valorTotal) return 'Valor não pode ser maior que o total da fatura';
                  return null;
                },
              ),
            ],
            
            // Configurações de Parcelamento
            if (_tipoPagamentoSelecionado == 'parcelado') ...[
              const SizedBox(height: 16),
              const Text(
                'Configurações do Parcelamento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  // Número de Parcelas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Número de Parcelas',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.roxoHeader,
                                width: 1,
                              ),
                            ),
                          ),
                          child: TextFormField(
                            initialValue: _numeroParcelas.toString(),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '2',
                              prefixIcon: Icon(Icons.calendar_month, color: Colors.grey),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _numeroParcelas = int.tryParse(value) ?? 2;
                              });
                            },
                            validator: (value) {
                              final parcelas = int.tryParse(value ?? '') ?? 0;
                              if (parcelas < 2 || parcelas > 60) {
                                return 'Entre 2 e 60 parcelas';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Valor de Cada Parcela
                  Expanded(
                    child: SmartField(
                      controller: _valorParcelaController,
                      focusNode: _valorParcelaFocusNode,
                      label: 'Valor de Cada Parcela',
                      hint: 'R\$ 0,00',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^[\d,\.]*')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Digite o valor da parcela';
                        final valor = CurrencyFormatter.parseValue(value);
                        if (valor <= 0) return 'Valor deve ser maior que zero';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Resumo do Parcelamento
              if (_valorParcelaController.text.isNotEmpty && _numeroParcelas > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Resumo do Parcelamento',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...() {
                        final valorParcela = CurrencyFormatter.parseValue(_valorParcelaController.text);
                        final valorTotal = valorParcela * _numeroParcelas;
                        final diferenca = valorTotal - widget.fatura.valorTotal;
                        final percentual = widget.fatura.valorTotal > 0 
                          ? (diferenca / widget.fatura.valorTotal) * 100 
                          : 0;
                        
                        return [
                          Text('• Total a pagar: ${CurrencyFormatter.format(valorTotal)}'),
                          Text('• Valor original: ${CurrencyFormatter.format(widget.fatura.valorTotal)}'),
                          if (diferenca > 0) ...[
                            Text(
                              '• Custo adicional: ${CurrencyFormatter.format(diferenca)} (+${percentual.toStringAsFixed(1)}%)',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                            ),
                          ],
                          const Text('• Débito hoje: R\$ 0,00 (será parcelado)', 
                                   style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                        ];
                      }(),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOpcaoPagamento(Map<String, dynamic> opcao) {
    final isSelected = _tipoPagamentoSelecionado == opcao['tipo'];
    double valor = widget.fatura.valorTotal;
    
    if (opcao['tipo'] == 'minimo') {
      valor = widget.fatura.valorMinimo ?? widget.fatura.valorTotal * 0.15;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _tipoPagamentoSelecionado = opcao['tipo'];
            if (opcao['tipo'] != 'personalizado') {
              _valorController.text = CurrencyFormatter.formatInput(valor);
            } else {
              _valorController.clear();
            }
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? opcao['cor'] : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? opcao['cor'].withOpacity(0.1) : null,
          ),
          child: Row(
            children: [
              Icon(
                opcao['icone'],
                color: isSelected ? opcao['cor'] : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opcao['titulo'],
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? opcao['cor'] : Colors.black87,
                      ),
                    ),
                    if (opcao['tipo'] != 'personalizado')
                      Text(
                        CurrencyFormatter.format(valor),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? opcao['cor'] : Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              Radio<String>(
                value: opcao['tipo'],
                groupValue: _tipoPagamentoSelecionado,
                onChanged: (value) {
                  setState(() {
                    _tipoPagamentoSelecionado = value!;
                    if (value != 'personalizado') {
                      _valorController.text = CurrencyFormatter.formatInput(valor);
                    } else {
                      _valorController.clear();
                    }
                  });
                },
                activeColor: opcao['cor'],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContaPagamento() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conta de Pagamento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_contas.isEmpty)
              const Text(
                'Nenhuma conta encontrada',
                style: TextStyle(color: Colors.grey),
              )
            else
              DropdownButtonFormField<String>(
                value: _contaSelecionada,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                  hintText: 'Selecione a conta para pagamento',
                ),
                validator: (value) => value == null ? 'Selecione uma conta' : null,
                onChanged: (value) => setState(() => _contaSelecionada = value),
                items: _contas.map((conta) => DropdownMenuItem(
                  value: conta.id,
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(conta.nome),
                            Text(
                              'Saldo: ${CurrencyFormatter.format(conta.saldo)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPagamento() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data do Pagamento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selecionarData,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(_dataPagamento),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservacoes() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Observações (Opcional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Adicione observações sobre este pagamento...',
                prefixIcon: Icon(Icons.note_alt),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmarPagamento,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payment, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Confirmar Pagamento - ${CurrencyFormatter.format(CurrencyFormatter.parseValue(_valorController.text))}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataPagamento,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.roxoHeader,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (data != null) {
      setState(() => _dataPagamento = data);
    }
  }

  Future<void> _confirmarPagamento() async {
    if (!_formKey.currentState!.validate()) return;
    
    final valor = CurrencyFormatter.parseValue(_valorController.text);
    
    if (_contaSelecionada == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos obrigatórios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirmação do pagamento
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cartão: ${widget.cartao.nome}'),
            Text('Valor: ${CurrencyFormatter.format(valor)}'),
            Text('Data: ${DateFormat('dd/MM/yyyy').format(_dataPagamento)}'),
            const SizedBox(height: 16),
            const Text(
              'Deseja confirmar este pagamento?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    setState(() => _isLoading = true);

    try {
      final resultado = await _faturaOperations.pagarFatura(
        cartaoId: widget.cartao.id,
        faturaVencimento: widget.fatura.dataVencimento.toIso8601String().split('T')[0],
        contaId: _contaSelecionada!,
        valorPago: valor,
        dataPagamento: _dataPagamento,
        observacoes: _observacoesController.text.trim().isEmpty 
          ? null 
          : _observacoesController.text.trim(),
      );

      if (resultado['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Fatura paga com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Retornar para a tela anterior
        Navigator.pop(context, true);
      } else {
        throw Exception(resultado['error'] ?? 'Erro ao processar pagamento');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Erro: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarAjuda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda - Pagamento de Fatura'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Valor Total:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Paga o valor completo da fatura.'),
              SizedBox(height: 12),
              Text(
                'Valor Mínimo:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Paga apenas o valor mínimo para evitar juros no próximo mês.'),
              SizedBox(height: 12),
              Text(
                'Valor Personalizado:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Permite escolher um valor específico entre o mínimo e o total.'),
              SizedBox(height: 12),
              Text(
                'Importante:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              Text('Pagamentos parciais podem gerar juros no próximo ciclo.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}*/
