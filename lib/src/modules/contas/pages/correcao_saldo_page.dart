// 🔧 Correção Saldo Page - iPoupei Mobile
// 
// Página para correção de saldo das contas
// Dois métodos: Ajuste (transação) e Saldo Inicial (recalculo)
// 
// Baseado em: Form Pattern + Confirmation Pattern

import 'package:flutter/material.dart';
import '../models/conta_model.dart';
import '../services/conta_service.dart';
import '../../auth/components/loading_overlay.dart';
import '../../shared/theme/app_colors.dart';
import '../../../shared/components/ui/app_text.dart';
import 'package:flutter/services.dart';

class CorrecaoSaldoPage extends StatefulWidget {
  final ContaModel conta;

  const CorrecaoSaldoPage({
    super.key,
    required this.conta,
  });

  @override
  State<CorrecaoSaldoPage> createState() => _CorrecaoSaldoPageState();
}

class _CorrecaoSaldoPageState extends State<CorrecaoSaldoPage> {
  final _formKey = GlobalKey<FormState>();
  final _contaService = ContaService.instance;
  
  // Controllers
  final _novoSaldoController = TextEditingController();
  final _motivoController = TextEditingController();
  
  // Estados
  String _metodoSelecionado = 'ajuste'; // Padrão: Criar Transação de Ajuste
  bool _loading = false;
  double _novoSaldoValue = 0.0;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    // Arredondar o saldo inicial para evitar problemas de precisão
    _novoSaldoValue = double.parse(widget.conta.saldo.toStringAsFixed(2));
    _validationError = null;
    
    // Inicializar controller com saldo atual formatado
    _novoSaldoController.text = 'R\$ ${_formatarMoedaParaInput(_novoSaldoValue)}';
    
    debugPrint('🔍 INIT: saldo=${widget.conta.saldo}, _novoSaldoValue=$_novoSaldoValue');
    
    // Validar imediatamente para mostrar o estado inicial correto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validarNovoSaldo();
    });
  }

  @override
  void dispose() {
    _novoSaldoController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  /// ✅ VALIDAR NOVO SALDO
  void _validarNovoSaldo() {
    setState(() {
      // Arredondar para 2 casas decimais para evitar problemas de precisão
      final novoSaldoArredondado = double.parse(_novoSaldoValue.toStringAsFixed(2));
      final saldoAtualArredondado = double.parse(widget.conta.saldo.toStringAsFixed(2));
      final diferenca = (novoSaldoArredondado - saldoAtualArredondado).abs();
      
      debugPrint('🔍 VALIDAÇÃO: _novoSaldoValue=$novoSaldoArredondado, saldo=$saldoAtualArredondado, diferenca=$diferenca');
      
      if (_novoSaldoValue == 0.0) {
        _validationError = 'Digite o novo saldo';
      } else if (diferenca < 0.01) {
        _validationError = 'O novo saldo deve ser diferente do atual (diferença mínima: R\$ 0,01)';
      } else {
        _validationError = null;
      }
      
      debugPrint('🔍 VALIDATION ERROR: $_validationError');
    });
  }

  /// 🔧 CORRIGIR SALDO
  Future<void> _corrigirSaldo() async {
    _validarNovoSaldo();
    if (_validationError != null) return;

    // Confirmação antes de executar
    final confirmacao = await _mostrarConfirmacao();
    if (!confirmacao) return;

    setState(() => _loading = true);

    try {
      await _contaService.corrigirSaldoConta(
        contaId: widget.conta.id,
        novoSaldo: _novoSaldoValue,
        metodo: _metodoSelecionado,
        motivo: _motivoController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saldo corrigido com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true); // Retorna sucesso
        }
        
        // 🔄 REFRESH INTELIGENTE: Agenda recarregamento dos dados após operação
        _agendarRefreshPosOperacao();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao corrigir saldo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /// ✅ MOSTRAR CONFIRMAÇÃO
  Future<bool> _mostrarConfirmacao() async {
    final saldoAtual = widget.conta.saldo;
    final diferenca = _novoSaldoValue - saldoAtual;
    
    String metodoDescricao;
    String impactoDescricao;
    
    if (_metodoSelecionado == 'ajuste') {
      metodoDescricao = 'Método: Criar Transação de Ajuste';
      impactoDescricao = 'Uma ${diferenca > 0 ? "receita" : "despesa"} de ${_formatarMoeda(diferenca.abs())} será criada.';
    } else {
      metodoDescricao = 'Método: Alterar Saldo Inicial';
      impactoDescricao = 'O saldo inicial será recalculado mantendo o histórico de transações.';
    }

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText.cardTitle('Confirmar Correção'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.body('Conta: ${widget.conta.nome}'),
            const SizedBox(height: 8),
            AppText.body('Saldo atual: ${_formatarMoeda(saldoAtual)}'),
            AppText.body('Novo saldo: ${_formatarMoeda(_novoSaldoValue)}'),
            Text(
              'Diferença: ${diferenca > 0 ? "+" : ""}${_formatarMoeda(diferenca)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: diferenca > 0 ? Colors.green : Colors.red,
              ),
            ),
            const Divider(),
            Text(metodoDescricao, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(impactoDescricao),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(false);
              }
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tealPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    
    return resultado ?? false;
  }

  /// 🔄 AGENDA REFRESH INTELIGENTE PÓS-OPERAÇÃO
  void _agendarRefreshPosOperacao() {
    // Agenda refresh em 3 segundos para dar tempo da sincronização
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Busca dados atualizados do Supabase para garantir consistência
        _recarregarDadosDoConta();
      }
    });
  }

  /// 📡 RECARREGA DADOS DA CONTA DO SUPABASE
  Future<void> _recarregarDadosDoConta() async {
    try {
      // Força refresh dos dados da conta específica
      final contasAtualizadas = await _contaService.fetchContas();
      final contaAtualizada = contasAtualizadas.firstWhere(
        (c) => c.id == widget.conta.id,
        orElse: () => widget.conta,
      );
      
      // Se os dados mudaram, dispara rebuild automático
      if (mounted && contaAtualizada.saldo != widget.conta.saldo) {
        // Log para debug
        debugPrint('🔄 Dados atualizados pós-operação:');
        debugPrint('   Saldo anterior: ${widget.conta.saldo}');
        debugPrint('   Saldo atual: ${contaAtualizada.saldo}');
        
        // Força rebuild se necessário (opcional - depende do estado)
        setState(() {
          // Força rebuild para garantir dados atualizados
        });
      }
    } catch (e) {
      debugPrint('⚠️ Erro no refresh pós-operação: $e');
      // Não propaga erro para não prejudicar UX
    }
  }

  /// 💰 INFO SALDO ATUAL (como na referência)
  Widget _buildInfoAtual() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20), // 🔧 ESPAÇO EMBAIXO
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F4), // Verde teal mais suave
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.tealPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏦 LINHA DO BANCO
          Row(
            children: [
              Icon(
                Icons.account_balance,
                size: 18,
                color: AppColors.tealPrimary,
              ),
              const SizedBox(width: 8),
              AppText.cardTitle(
                widget.conta.banco ?? 'Banco não informado',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                color: AppColors.cinzaEscuro,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 💰 LINHA DO SALDO
          Row(
            children: [
              const Text('💰', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.cardSecondary(
                      'Saldo Atual',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      color: AppColors.cinzaTexto,
                    ),
                    AppText.cardValue(
                      _formatarMoeda(widget.conta.saldo),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      color: AppColors.tealPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🎯 SELETOR DE OPÇÃO (como na referência)
  Widget _buildSeletorOpcao() {
    final opcoes = [
      {
        'id': 'ajuste',
        'nome': 'Criar Transação de Ajuste',
        'icone': Icons.receipt_long,
        'descricao': 'Registra uma transação para ajustar o saldo',
      },
      {
        'id': 'saldo_inicial',
        'nome': 'Alterar Saldo Inicial',
        'icone': Icons.edit,
        'descricao': 'Corrige o saldo inicial da conta',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.cardTitle(
          'Como você quer ajustar?',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          color: Colors.black87,
        ),
        const SizedBox(height: 12),
        ...opcoes.map<Widget>((opcao) {
          final isSelected = opcao['id'] == _metodoSelecionado;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _metodoSelecionado = opcao['id'] as String;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? AppColors.tealPrimary : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected 
                      ? AppColors.tealPrimary.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected 
                          ? Icons.radio_button_checked 
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.tealPrimary : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      opcao['icone'] as IconData,
                      color: isSelected ? AppColors.tealPrimary : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opcao['nome'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.tealPrimary : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opcao['descricao'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 💰 CAMPO NOVO SALDO (linha simples)
  Widget _buildCampoNovoSaldo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.attach_money, size: 16, color: AppColors.tealPrimary),
            const SizedBox(width: 8),
            AppText.cardTitle(
              'Novo Saldo',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              color: Colors.black87,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _novoSaldoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          inputFormatters: [
            MoneyInputFormatter(allowNegative: true),
          ],
          onChanged: (valor) {
            debugPrint('🔍 ONCHANGED: "$valor"');
            final novoValor = _extrairValorNumerico(valor);
            debugPrint('🔍 VALOR EXTRAÍDO: $novoValor (de "$valor")');
            setState(() {
              _novoSaldoValue = novoValor;
            });
            debugPrint('🔍 NOVO VALOR ATRIBUÍDO: $_novoSaldoValue');
            debugPrint('🔍 SALDO ATUAL: ${widget.conta.saldo}');
            debugPrint('🔍 DIFERENÇA: ${(_novoSaldoValue - widget.conta.saldo).abs()}');
            _validarNovoSaldo();
          },
          textInputAction: _metodoSelecionado == 'ajuste' ? TextInputAction.next : TextInputAction.done,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'R\$ 0,00',
            border: const UnderlineInputBorder(),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.tealPrimary, width: 2),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        if (_validationError != null) ...[
          const SizedBox(height: 8),
          AppText.body(
            _validationError!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            color: Colors.red,
          ),
        ],
      ],
    );
  }

  /// 📝 CAMPO MOTIVO (linha simples)
  Widget _buildCampoMotivo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.note_add, size: 16, color: AppColors.tealPrimary),
            const SizedBox(width: 8),
            AppText.cardTitle(
              'Motivo do Ajuste',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              color: Colors.black87,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _motivoController,
          maxLines: 2,
          textInputAction: TextInputAction.done,
          onChanged: (valor) {
            setState(() {});
          },
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: 'Ex: Correção de lançamento, taxa não registrada...',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            border: const UnderlineInputBorder(),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.tealPrimary, width: 2),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ],
    );
  }

  /// 🔘 BOTÕES CANCELAR E CONFIRMAR
  Widget _buildBotoes() {
    // Debug das condições
    final temErro = _validationError != null;
    // Arredondar valores para evitar problemas de precisão
    final novoSaldoArredondado = double.parse(_novoSaldoValue.toStringAsFixed(2));
    final saldoAtualArredondado = double.parse(widget.conta.saldo.toStringAsFixed(2));
    final diferenca = (novoSaldoArredondado - saldoAtualArredondado).abs();
    final saldoIgual = diferenca < 0.01; // Tolerância para decimais
    final precisaMotivo = _metodoSelecionado == 'ajuste' && _motivoController.text.trim().isEmpty;
    
    debugPrint('🔍 DEBUG BOTÃO:');
    debugPrint('   _validationError: $_validationError');
    debugPrint('   _novoSaldoValue: $novoSaldoArredondado');
    debugPrint('   widget.conta.saldo: $saldoAtualArredondado');
    debugPrint('   diferenca: $diferenca (deve ser >= 0.01)');
    debugPrint('   _metodoSelecionado: $_metodoSelecionado');
    debugPrint('   motivo: "${_motivoController.text}"');
    debugPrint('   temErro: $temErro, saldoIgual: $saldoIgual, precisaMotivo: $precisaMotivo');
    
    final podeExecutar = !temErro && !saldoIgual && !precisaMotivo;
    debugPrint('🔍 PODE EXECUTAR: $podeExecutar');
    
    return Row(
      children: [
        // Botão Cancelar
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: AppText.button(
                'CANCELAR',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                color: AppColors.tealPrimary,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Botão Confirmar
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: podeExecutar && !_loading ? _corrigirSaldo : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, size: 18),
                        const SizedBox(width: 8),
                        AppText.button(
                          'CONFIRMAR',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// 🎨 HELPER FUNCTIONS
  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// 💰 FORMATAR MOEDA PARA INPUT (sem R$)
  String _formatarMoedaParaInput(double valor) {
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  /// 🔢 EXTRAIR VALOR NUMÉRICO DE STRING FORMATADA
  double _extrairValorNumerico(String texto) {
    if (texto.isEmpty) return 0.0;
    
    debugPrint('🔍 EXTRAÇÃO ORIGINAL: "$texto"');
    
    // Detectar sinal negativo
    bool isNegative = texto.trim().startsWith('-');
    
    // Remove tudo exceto dígitos e vírgula
    String cleaned = texto.replaceAll(RegExp(r'[^0-9,]'), '');
    
    debugPrint('🔍 EXTRAÇÃO LIMPA: "$cleaned"');
    
    if (cleaned.isEmpty) return 0.0;
    
    double valor = 0.0;
    
    // Se tem vírgula, é formato brasileiro: X,XX
    if (cleaned.contains(',')) {
      final parts = cleaned.split(',');
      if (parts.length == 2) {
        final integerPart = int.tryParse(parts[0]) ?? 0;
        // Garante que decimal tenha exatamente 2 dígitos
        final decimalStr = parts[1].padRight(2, '0').substring(0, 2);
        final decimalPart = int.tryParse(decimalStr) ?? 0;
        valor = integerPart + (decimalPart / 100.0);
      } else if (parts.length == 1 && parts[0].isNotEmpty) {
        // Só vírgula no final: "123," = 123.00
        valor = double.tryParse(parts[0]) ?? 0.0;
      }
    } else {
      // Só números, sempre tratar como valor já formatado pelo MoneyInputFormatter
      // O formatter já converte para centavos, então dividir por 100
      final number = int.tryParse(cleaned) ?? 0;
      valor = number / 100.0;
    }
    
    if (isNegative) valor = -valor;
    
    // Arredondar para 2 casas decimais para evitar problemas de precisão
    valor = double.parse(valor.toStringAsFixed(2));
    
    debugPrint('🔍 VALOR FINAL EXTRAÍDO: $valor');
    
    return valor;
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      message: 'Processando ajuste...',
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: Container(
                  color: Colors.white, // 🔧 FORÇA FUNDO BRANCO
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: _buildBody(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 HEADER TEAL COM TÍTULO E REFERÊNCIA DA CONTA
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20), // 🔧 MAIS ESPAÇO NO TOPO
      decoration: const BoxDecoration(
        color: AppColors.tealPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.tune,
              color: Colors.white,
              size: 28, // 🔧 ÍCONE MAIOR
            ),
            const SizedBox(width: 16), // 🔧 MAIS ESPAÇO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.appBarTitle(
                    'Ajustar Saldo',
                    style: const TextStyle(
                      fontSize: 20, // 🔧 TÍTULO MAIOR
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6), // 🔧 MAIS ESPAÇO ENTRE LINHAS
                  AppText.cardSecondary(
                    '${widget.conta.banco ?? 'Banco'} • ${widget.conta.nome}', // 🔧 NOME DO BANCO + CONTA
                    style: const TextStyle(
                      fontSize: 15, // 🔧 TEXTO MAIOR
                      fontWeight: FontWeight.w500,
                    ),
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),
      ),
    );
  }

  /// 📱 CORPO DO MODAL
  Widget _buildBody() {
    return Container(
      color: Colors.white, // 🔧 GARANTE FUNDO BRANCO
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seletor de método
              _buildSeletorOpcao(),
              
              const SizedBox(height: 20),
              
              // Campo novo saldo
              _buildCampoNovoSaldo(),
              
              const SizedBox(height: 16),
              
              // Campo motivo (apenas para ajuste)  
              if (_metodoSelecionado == 'ajuste') _buildCampoMotivo(),
              if (_metodoSelecionado == 'ajuste') const SizedBox(height: 16),
              
              const SizedBox(height: 32),
              
              // Botões
              _buildBotoes(),
            ],
          ),
        ),
      ),
    );
  }
}

/// MoneyInputFormatter - formatação de moeda brasileira
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
      // Extrair apenas números e sinal de negativo se permitido
      String numbersOnly;
      bool isNegative = false;
      
      if (allowNegative && newValue.text.startsWith('-')) {
        isNegative = true;
        numbersOnly = newValue.text.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
      } else {
        numbersOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
      }
      
      if (numbersOnly.isEmpty) {
        return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
      }
      
      final number = int.parse(numbersOnly);
      final formatted = (number / 100).toStringAsFixed(2).replaceAll('.', ',');
      
      final finalText = isNegative ? '-R\$ $formatted' : 'R\$ $formatted';
      
      return TextEditingValue(
        text: finalText,
        selection: TextSelection.collapsed(offset: finalText.length),
      );
    } catch (e) {
      return oldValue;
    }
  }
}