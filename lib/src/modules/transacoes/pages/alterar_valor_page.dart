import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme/app_colors.dart';
import '../models/transacao_model.dart';
import '../services/transacao_edit_service.dart' show TransacaoEditService, EscopoEdicao;


/// Página específica para alterar valor de transações
class AlterarValorPage extends StatefulWidget {
  final TransacaoModel transacao;
  final Function(double, EscopoEdicao) onValorAlterado;

  const AlterarValorPage({
    super.key,
    required this.transacao,
    required this.onValorAlterado,
  });

  @override
  State<AlterarValorPage> createState() => _AlterarValorPageState();
}

class _AlterarValorPageState extends State<AlterarValorPage> {
  final _valorController = TextEditingController();
  bool _incluirFuturas = false;
  bool _processando = false;
  int _quantidadeFuturas = 0;
  bool _temParcelasOuRecorrencias = false;

  @override
  void initState() {
    super.initState();
    _valorController.text = widget.transacao.valor.toStringAsFixed(2);
    
    // Listener para atualizar preview em tempo real
    _valorController.addListener(() {
      setState(() {
        // Atualiza o preview quando o valor muda
      });
    });
    
    _analisarTransacao();
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _analisarTransacao() async {
    // Verificar se tem parcelas ou recorrências
    if (widget.transacao.recorrente || widget.transacao.grupoRecorrencia != null) {
      _temParcelasOuRecorrencias = true;
      
      // Calcular quantidade de futuras transações
      await _calcularQuantidadeFuturas();
      
      // Se a transação estiver efetivada, força incluir futuras (só pode alterar futuras)
      if (widget.transacao.efetivado) {
        _incluirFuturas = true;
      }
    }

    setState(() {
      // Atualizar estado após análise
    });
  }

  Future<void> _calcularQuantidadeFuturas() async {
    try {
      // 🔄 Usar contagem real das transações no banco
      final quantidadeReal = await TransacaoEditService.instance.contarTransacoesAfetadas(
        widget.transacao,
        EscopoEdicao.estasEFuturas,
      );
      
      setState(() {
        _quantidadeFuturas = quantidadeReal;
      });
      
      print('🔍 [DEBUG] Quantidade real de transações futuras: $quantidadeReal');
    } catch (e) {
      print('❌ [ERROR] Erro ao calcular quantidade de futuras: $e');
      // Fallback para estimativa em caso de erro
      _calcularQuantidadeFuturasEstimada();
    }
  }
  
  void _calcularQuantidadeFuturasEstimada() {
    // Se tem parcelas
    if (widget.transacao.numeroTotalParcelas != null && widget.transacao.numeroTotalParcelas! > 1) {
      final atual = widget.transacao.numeroParcelaAtual ?? 1;
      final total = widget.transacao.numeroTotalParcelas!;
      _quantidadeFuturas = total - atual;
    }
    // Se é recorrente - estimar baseado em um ano
    else if (widget.transacao.recorrente) {
      final tipo = widget.transacao.tipoRecorrencia ?? 'Mensal';
      switch (tipo.toLowerCase()) {
        case 'diária':
        case 'diario':
          _quantidadeFuturas = 365; // Aproximação de um ano
          break;
        case 'semanal':
          _quantidadeFuturas = 52; // 52 semanas no ano
          break;
        case 'quinzenal':
          _quantidadeFuturas = 26; // 26 quinzenas no ano
          break;
        case 'mensal':
          _quantidadeFuturas = 12; // 12 meses no ano
          break;
        case 'bimestral':
          _quantidadeFuturas = 6; // 6 bimestres no ano
          break;
        case 'trimestral':
          _quantidadeFuturas = 4; // 4 trimestres no ano
          break;
        case 'semestral':
          _quantidadeFuturas = 2; // 2 semestres no ano
          break;
        case 'anual':
          _quantidadeFuturas = 1; // 1 por ano
          break;
        default:
          _quantidadeFuturas = 12; // Padrão mensal
      }
    }
  }

  /// ✅ PODE HABILITAR BOTÃO SALVAR (SIMILAR AO TRANSACAO FORM)
  bool get _podeHabilitar {
    final texto = _valorController.text.trim();
    if (texto.isEmpty) return false;

    // Usar o parser do CurrencyFormatter para validar
    try {
      final novoValor = _parseValue(texto);
      return !_processando && novoValor > 0;
    } catch (e) {
      return false;
    }
  }

  /// Parse do valor usando formato brasileiro (compatível com MoneyInputFormatter)
  double _parseValue(String text) {
    if (text.isEmpty) return 0.0;

    // Remove R$ e espaços
    String cleaned = text.replaceAll('R\$', '').replaceAll(' ', '').trim();

    if (cleaned.isEmpty) return 0.0;

    // Formato brasileiro: 123,45
    if (cleaned.contains(',')) {
      cleaned = cleaned.replaceAll(',', '.');
    }

    return double.tryParse(cleaned) ?? 0.0;
  }

  Future<void> _salvarNovoValor() async {
    final novoValor = _parseValue(_valorController.text);
    if (novoValor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um valor válido')),
      );
      return;
    }

    setState(() {
      _processando = true;
    });

    try {
      // Mapear escopo para incluirFuturas 
      final incluirFuturas = _incluirFuturas;
      
      final resultado = await TransacaoEditService.instance.editarValor(
        widget.transacao,
        novoValor,
        escopo: incluirFuturas ? EscopoEdicao.estasEFuturas : EscopoEdicao.apenasEsta,
      );
      
      if (resultado.sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensagem ?? 'Valor alterado com sucesso'),
            backgroundColor: AppColors.tealPrimary,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.erro ?? 'Erro ao alterar valor'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() {
        _processando = false;
      });
    }
  }

  Color _getCorHeader() {
    if (widget.transacao.tipo == 'receita') {
      return AppColors.tealPrimary;
    } else if (widget.transacao.tipo == 'despesa') {
      return widget.transacao.cartaoId != null 
        ? AppColors.roxoPrimario 
        : AppColors.vermelhoErro;
    } else {
      return AppColors.azul;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      appBar: AppBar(
        backgroundColor: _getCorHeader(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.transacao.descricao.isNotEmpty 
                  ? widget.transacao.descricao 
                  : 'Editar Valor',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(52),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _podeHabilitar ? _salvarNovoValor : null,
            child: Text(
              'Salvar',
              style: TextStyle(
                color: _podeHabilitar ? Colors.white : Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildCardTransacao(),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _valorController,
                keyboardType: TextInputType.number,
                inputFormatters: [MoneyInputFormatter()],
                textInputAction: TextInputAction.done,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Novo Valor',
                  hintText: 'R\$ 0,00',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _getCorHeader(),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  // Callback quando o valor muda
                  setState(() {
                    // Atualiza preview
                  });
                },
              ),
              
              if (_temParcelasOuRecorrencias) ...[
                const SizedBox(height: 24),
                _buildCheckboxFuturas(),
              ],
              
              // Preview das alterações (se tem futuras e valor alterado)
              if (_temParcelasOuRecorrencias && _valorController.text.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildPreviewAlteracoes(),
              ],
              
              const SizedBox(height: 60),
              
              _buildBotaoGradiente(
                texto: 'Salvar Novo Valor',
                icone: Icons.save,
                onPressed: _processando ? () {} : _salvarNovoValor,
                processando: _processando,
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardTransacao() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(21),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCorHeader().withAlpha(26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.transacao.tipo.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getCorHeader(),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'R\$ ${widget.transacao.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cinzaEscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.transacao.descricao.isNotEmpty 
              ? widget.transacao.descricao 
              : 'Transação sem descrição',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.cinzaEscuro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxFuturas() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _incluirFuturas 
            ? AppColors.tealPrimary.withAlpha(78)
            : AppColors.cinzaMedio.withAlpha(52),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.transacao.efetivado ? null : () {
            setState(() {
              _incluirFuturas = !_incluirFuturas;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _incluirFuturas 
                      ? AppColors.tealPrimary 
                      : Colors.transparent,
                    border: Border.all(
                      color: _incluirFuturas 
                        ? AppColors.tealPrimary 
                        : AppColors.cinzaMedio,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _incluirFuturas
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.transacao.efetivado 
                          ? 'Alterar futuras transações'
                          : 'Incluir futuras transações',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _incluirFuturas 
                            ? AppColors.tealPrimary 
                            : AppColors.cinzaEscuro,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _quantidadeFuturas > 0
                          ? widget.transacao.efetivado
                            ? 'Alterar as próximas $_quantidadeFuturas transações (atual já efetivada)'
                            : 'Aplicar também às próximas $_quantidadeFuturas transações'
                          : 'Não há futuras transações para alterar',
                        style: TextStyle(
                          fontSize: 13,
                          color: _incluirFuturas 
                            ? AppColors.tealPrimary.withAlpha(208)
                            : AppColors.cinzaTexto,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_quantidadeFuturas > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _incluirFuturas 
                        ? AppColors.tealPrimary.withAlpha(26)
                        : AppColors.cinzaMedio.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+$_quantidadeFuturas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _incluirFuturas 
                          ? AppColors.tealPrimary 
                          : AppColors.cinzaTexto,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewAlteracoes() {
    final novoValor = _parseValue(_valorController.text);
    if (novoValor <= 0) return const SizedBox.shrink();
    
    final valorAtual = widget.transacao.valor;
    final diferenca = novoValor - valorAtual;
    final percentual = ((diferenca / valorAtual) * 100);
    final isAumento = diferenca > 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAumento 
          ? AppColors.tealPrimary.withAlpha(12)
          : AppColors.vermelhoErro.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAumento 
            ? AppColors.tealPrimary.withAlpha(52)
            : AppColors.vermelhoErro.withAlpha(52),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAumento ? Icons.trending_up : Icons.trending_down,
                color: isAumento ? AppColors.tealPrimary : AppColors.vermelhoErro,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.transacao.efetivado 
                  ? 'Preview - Alteração apenas das Futuras'
                  : 'Preview da Alteração',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isAumento ? AppColors.tealPrimary : AppColors.vermelhoErro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Valor Atual',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.cinzaTexto,
                      ),
                    ),
                    Text(
                      'R\$ ${valorAtual.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cinzaEscuro,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: AppColors.cinzaMedio,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Novo Valor',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.cinzaTexto,
                      ),
                    ),
                    Text(
                      'R\$ ${novoValor.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isAumento ? AppColors.tealPrimary : AppColors.vermelhoErro,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isAumento 
                ? AppColors.tealPrimary.withAlpha(26)
                : AppColors.vermelhoErro.withAlpha(26),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${isAumento ? '+' : ''}${percentual.toStringAsFixed(1)}% '
              '(${isAumento ? '+' : ''}R\$ ${diferenca.abs().toStringAsFixed(2).replaceAll('.', ',')})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isAumento ? AppColors.tealPrimary : AppColors.vermelhoErro,
              ),
            ),
          ),
          if (_incluirFuturas && _quantidadeFuturas > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.azul.withAlpha(12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.azul.withAlpha(52),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.repeat,
                    color: AppColors.azul,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta alteração será aplicada a $_quantidadeFuturas futuras transações',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.azul,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBotaoGradiente({
    required String texto,
    required IconData icone,
    required VoidCallback onPressed,
    bool processando = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getCorHeader(), _getCorHeader().withAlpha(208)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getCorHeader().withAlpha(78),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: processando
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Salvando...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icone,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        texto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Formatter para valores monetários usando abordagem cents-first
/// Compatível com despesa_cartao_page.dart
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