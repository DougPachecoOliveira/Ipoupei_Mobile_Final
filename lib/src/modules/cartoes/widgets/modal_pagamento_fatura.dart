import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/cartao_model.dart';
import '../models/fatura_model.dart';
import '../services/fatura_operations_service.dart';
import '../../contas/models/conta_model.dart';
import '../../contas/services/conta_service.dart';
import '../../contas/data/contas_sugeridas.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/modal_selecao_conta.dart';

class ModalPagamentoFatura extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final CartaoModel cartao;
  final FaturaModel? fatura;
  final VoidCallback onSuccess;

  const ModalPagamentoFatura({
    Key? key,
    required this.isOpen,
    required this.onClose,
    required this.cartao,
    required this.fatura,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<ModalPagamentoFatura> createState() => _ModalPagamentoFaturaState();
}

class _ModalPagamentoFaturaState extends State<ModalPagamentoFatura> {
  final FaturaOperationsService _faturaOperations = FaturaOperationsService.instance;
  final ContaService _contaService = ContaService.instance;
  final _formKey = GlobalKey<FormState>();

  String? _contaId;
  ContaModel? _contaSelecionada;
  List<ContaModel> _contas = [];
  double? _valorPago;
  DateTime? _dataPagamento = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.fatura != null) {
      _valorPago = widget.fatura!.valorTotal;
    }
    _carregarContas();
  }

  /// Carregar contas disponíveis
  Future<void> _carregarContas() async {
    try {
      final contas = await _contaService.getContasAtivas();
      setState(() {
        _contas = contas;
        // Selecionar conta principal se disponível
        _contaSelecionada = contas.isEmpty
            ? null
            : contas.firstWhere(
                (c) => c.contaPrincipal,
                orElse: () => contas.first,
              );
        if (_contaSelecionada != null && _contaSelecionada!.id.isNotEmpty) {
          _contaId = _contaSelecionada!.id;
        }
      });
    } catch (e) {
      // Erro ao carregar contas
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.green),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Pagar Fatura',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informações do Cartão
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cartão: ${widget.cartao.nome}'),
                  Text('Bandeira: ${widget.cartao.bandeira ?? "N/A"}'),
                  if (widget.fatura != null)
                    Text('Vencimento: ${_formatarData(widget.fatura!.dataVencimento)}'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Formulário
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Conta de Pagamento
                  const Text('Conta de Pagamento *'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selecionarConta,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          if (_contaSelecionada != null)
                            _buildContaIcon(_contaSelecionada!)
                          else
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.account_balance, color: Colors.grey),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _contaSelecionada?.nome ?? 'Selecione a conta',
                              style: TextStyle(
                                color: _contaSelecionada != null ? Colors.black : Colors.grey[600],
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Valor Pago
                  const Text('Valor a Pagar *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _valorPago?.toStringAsFixed(2).replaceAll('.', ','),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Digite o valor';
                      final valor = double.tryParse(value.replaceAll(',', '.'));
                      if (valor == null || valor <= 0) return 'Valor inválido';
                      return null;
                    },
                    onChanged: (value) {
                      _valorPago = double.tryParse(value.replaceAll(',', '.'));
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Data do Pagamento
                  const Text('Data do Pagamento *'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selecionarData,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 12),
                          Text(_formatarData(_dataPagamento!)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Ações
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : widget.onClose,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _confirmarPagamento,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar Pagamento'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Selecionar conta usando modal elegante reutilizável
  Future<void> _selecionarConta() async {
    if (_contas.isEmpty) return;

    final conta = await ModalSelecaoConta.mostrar(
      context: context,
      contas: _contas,
      contaSelecionada: _contaSelecionada,
      titulo: 'Selecionar Conta para Pagamento',
      subtitulo: null,
      mostrarSaldo: true,
      permitirNenhuma: false,
    );

    if (conta != null) {
      setState(() {
        _contaSelecionada = conta;
        _contaId = conta.id;
      });
    }
  }

  /// Ícone da conta com logo do banco
  Widget _buildContaIcon(ContaModel conta) {
    final corConta = conta.cor != null && conta.cor!.isNotEmpty
        ? Color(int.parse(conta.cor!.replaceAll('#', '0xFF')))
        : Colors.blue;

    // Buscar cor e logo oficial do banco
    final corOficialBanco = _buscarCorOficialBanco(conta.banco);
    final corFinal = corOficialBanco ?? corConta;
    final logo = _buscarLogoBanco(conta.banco);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: corFinal,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: logo != null && logo.isNotEmpty
            ? Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(2),
                child: _buildLogoWidget(logo, size: 28),
              )
            : Icon(
                conta.icone != null ? _getIconeFromString(conta.icone!) : Icons.account_balance,
                color: Colors.white,
                size: 20,
              ),
      ),
    );
  }

  /// Buscar logo do banco
  String? _buscarLogoBanco(String? banco) {
    if (banco == null || banco.isEmpty) return null;

    try {
      final bancoEncontrado = ContasSugeridas.todas.firstWhere(
        (contaSugerida) => contaSugerida['banco'] == banco,
        orElse: () => <String, dynamic>{},
      );
      return bancoEncontrado['logo'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Buscar cor oficial do banco
  Color? _buscarCorOficialBanco(String? banco) {
    if (banco == null || banco.isEmpty) return null;

    try {
      final bancoEncontrado = ContasSugeridas.todas.firstWhere(
        (contaSugerida) => contaSugerida['banco'] == banco,
        orElse: () => <String, dynamic>{},
      );
      final corString = bancoEncontrado['cor'] as String?;
      if (corString != null && corString.isNotEmpty) {
        return Color(int.parse(corString.replaceAll('#', '0xFF')));
      }
    } catch (e) {
      // Falha silenciosa
    }
    return null;
  }

  /// Widget do logo
  Widget _buildLogoWidget(String logo, {required double size}) {
    final fallback = Icon(Icons.account_balance, color: Colors.white, size: size * 0.7);

    try {
      final lowerLogo = logo.toLowerCase();
      if (lowerLogo.endsWith('.svg')) {
        return SvgPicture.asset(
          logo,
          width: size,
          height: size,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => fallback,
        );
      }
      return Image.asset(
        logo,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    } catch (e) {
      return fallback;
    }
  }

  /// Converter string para ícone
  IconData _getIconeFromString(String icone) {
    switch (icone.toLowerCase()) {
      case 'savings':
        return Icons.savings;
      case 'account_balance':
        return Icons.account_balance;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.account_balance;
    }
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataPagamento!,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (data != null) {
      setState(() => _dataPagamento = data);
    }
  }

  Future<void> _confirmarPagamento() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_contaId == null || _valorPago == null || _valorPago! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos obrigatórios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resultado = await _faturaOperations.pagarFatura(
        cartaoId: widget.cartao.id,
        faturaVencimento: widget.fatura!.dataVencimento.toIso8601String().split('T')[0],
        contaId: _contaId!,
        valorPago: _valorPago!,
        dataPagamento: _dataPagamento,
      );

      if (resultado['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fatura paga com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
        widget.onClose();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['error'] ?? 'Erro ao pagar fatura'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}
