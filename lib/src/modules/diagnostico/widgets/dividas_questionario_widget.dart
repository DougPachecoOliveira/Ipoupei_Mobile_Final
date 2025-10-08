// 💳 Dívidas Questionário Widget - iPoupei Mobile
//
// Widget de formulário para questionário de dívidas
// Permite cadastrar dívidas individuais e estratégias
//
// Design: Cards expansíveis + formulários dinâmicos

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../models/dividas_model.dart';
import '../../transacoes/components/smart_field.dart';

/// MoneyInputFormatter - mesmo da TransacaoFormPage
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

    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (text.length == 1) {
      text = '0,0$text';
    } else if (text.length == 2) {
      text = '0,${text}';
    } else {
      String integerPart = text.substring(0, text.length - 2);
      String decimalPart = text.substring(text.length - 2);

      integerPart = integerPart.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );

      text = '$integerPart,$decimalPart';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Widget do questionário de dívidas
class DividasQuestionarioWidget extends StatefulWidget {
  final DividasDiagnostico dividasInicial;
  final Function(DividasDiagnostico) onChanged;
  final bool showValidationErrors;

  const DividasQuestionarioWidget({
    super.key,
    required this.dividasInicial,
    required this.onChanged,
    this.showValidationErrors = false,
  });

  @override
  State<DividasQuestionarioWidget> createState() => _DividasQuestionarioWidgetState();
}

class _DividasQuestionarioWidgetState extends State<DividasQuestionarioWidget> {
  late DividasDiagnostico _dividas;
  bool _mostrarFormulario = false;

  // Controllers para nova dívida
  final _descricaoController = TextEditingController();
  final _instituicaoController = TextEditingController();
  final _valorTotalController = TextEditingController();
  final _valorParcelaController = TextEditingController();
  final _parcelasRestantesController = TextEditingController();
  final _parcelasTotaisController = TextEditingController();

  String _situacaoSelecionada = 'em_dia';
  String? _motivoSelecionado;
  String? _estrategiaSelecionada;

  @override
  void initState() {
    super.initState();
    _dividas = widget.dividasInicial;
    _motivoSelecionado = _dividas.motivoPrincipal;
    _estrategiaSelecionada = _dividas.estrategiaPagamento;
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _instituicaoController.dispose();
    _valorTotalController.dispose();
    _valorParcelaController.dispose();
    _parcelasRestantesController.dispose();
    _parcelasTotaisController.dispose();
    super.dispose();
  }

  void _atualizarDividas(DividasDiagnostico novasDividas) {
    setState(() {
      _dividas = novasDividas;
    });
    widget.onChanged(_dividas);
  }

  /// Converter input monetário para double
  double _parseMoneyValue(String input) {
    if (input.isEmpty) return 0.0;
    String cleaned = input.replaceAll(RegExp(r'[^0-9,]'), '');
    cleaned = cleaned.replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Introdução
          _buildIntroducao(),

          const SizedBox(height: 24),

          // Pergunta principal: Tem dívidas?
          _buildPerguntaPrincipal(),

          const SizedBox(height: 20),

          // Se tem dívidas, mostrar formulários
          if (_dividas.temDividas) ...[
            _buildListaDividas(),

            const SizedBox(height: 16),

            _buildBotaoAdicionarDivida(),

            const SizedBox(height: 24),

            _buildMotivoPrincipal(),

            const SizedBox(height: 20),

            _buildEstrategiaPagamento(),

            const SizedBox(height: 20),

            _buildResumoTotal(),

            // Formulário para nova dívida
            if (_mostrarFormulario) ...[
              const SizedBox(height: 20),
              _buildFormularioNovaDivida(),
            ],
          ],

          const SizedBox(height: 80), // Espaço para navegação
        ],
      ),
    );
  }

  /// Introdução do questionário
  Widget _buildIntroducao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade50,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber,
            size: 48,
            color: Colors.red.shade600,
          ),
          const SizedBox(height: 16),
          const Text(
            'Suas dívidas atuais',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Esta etapa é opcional, mas ajuda muito no seu diagnóstico. Seja honesto sobre sua situação atual.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Pergunta principal: Você tem dívidas?
  Widget _buildPerguntaPrincipal() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Você possui dívidas atualmente?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Opções verticais como no React
            Column(
              children: [
                // Sim, tenho dívidas
                InkWell(
                  onTap: () => _atualizarDividas(_dividas.copyWith(temDividas: true)),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _dividas.temDividas == true
                        ? Colors.red.shade50
                        : Colors.transparent,
                      border: Border.all(
                        color: _dividas.temDividas == true
                          ? Colors.red.shade300
                          : Colors.grey.shade300,
                        width: _dividas.temDividas == true ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: _dividas.temDividas,
                          onChanged: (value) => _atualizarDividas(_dividas.copyWith(temDividas: value)),
                          activeColor: Colors.red.shade600,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('😰 Sim, tenho dívidas')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Não tenho dívidas
                InkWell(
                  onTap: () => _atualizarDividas(_dividas.copyWith(temDividas: false, dividas: [])),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _dividas.temDividas == false
                        ? Colors.green.shade50
                        : Colors.transparent,
                      border: Border.all(
                        color: _dividas.temDividas == false
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                        width: _dividas.temDividas == false ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: _dividas.temDividas,
                          onChanged: (value) => _atualizarDividas(_dividas.copyWith(temDividas: value, dividas: [])),
                          activeColor: Colors.green.shade600,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('😊 Não tenho dívidas')),
                      ],
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

  /// Lista de dívidas cadastradas
  Widget _buildListaDividas() {
    if (_dividas.dividas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.credit_card_off,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Nenhuma dívida cadastrada ainda',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione suas dívidas para um diagnóstico mais preciso',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suas dívidas:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        ..._dividas.dividas.asMap().entries.map((entry) {
          final index = entry.key;
          final divida = entry.value;
          return _buildDividaCard(divida, index);
        }),
      ],
    );
  }

  /// Card de uma dívida
  Widget _buildDividaCard(DividaIndividual divida, int index) {
    final corSituacao = divida.situacao == 'em_dia'
      ? Colors.green
      : divida.situacao == 'atrasada'
        ? Colors.red
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    divida.descricao,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: corSituacao.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    divida.situacao.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: corSituacao.shade700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removerDivida(index),
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  iconSize: 20,
                ),
              ],
            ),

            if (divida.instituicao != null) ...[
              const SizedBox(height: 4),
              Text(
                divida.instituicao!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Valor Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(divida.valorTotal),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (divida.valorParcela != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parcela',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(divida.valorParcela!),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (divida.parcelasRestantes != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Restantes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          '${divida.parcelasRestantes}x',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
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

  /// Botão para adicionar nova dívida
  Widget _buildBotaoAdicionarDivida() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _mostrarFormulario = !_mostrarFormulario;
            if (!_mostrarFormulario) {
              _limparFormulario();
            }
          });
        },
        icon: Icon(_mostrarFormulario ? Icons.close : Icons.add),
        label: Text(_mostrarFormulario ? 'Cancelar' : 'Adicionar Dívida'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.azulHeader,
          side: const BorderSide(color: AppColors.azulHeader),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  /// Formulário para nova dívida
  Widget _buildFormularioNovaDivida() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nova Dívida',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Descrição
          SmartField(
            controller: _descricaoController,
            label: 'Descrição da dívida',
            hint: 'Ex: Cartão de Crédito, Financiamento...',
            icon: Icons.description,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Descrição é obrigatória';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Instituição
          SmartField(
            controller: _instituicaoController,
            label: 'Instituição (opcional)',
            hint: 'Ex: Banco do Brasil, Nubank...',
            icon: Icons.account_balance,
          ),

          const SizedBox(height: 12),

          // Valor total
          SmartField(
            controller: _valorTotalController,
            label: 'Valor total da dívida',
            hint: 'R\$ 0,00',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
            inputFormatters: [MoneyInputFormatter()],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Valor total é obrigatório';
              }
              final parsedValue = _parseMoneyValue(value);
              if (parsedValue <= 0) {
                return 'Valor deve ser maior que zero';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Situação
          const Text(
            'Situação da dívida:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Em dia'),
                selected: _situacaoSelecionada == 'em_dia',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _situacaoSelecionada = 'em_dia';
                    });
                  }
                },
              ),
              ChoiceChip(
                label: const Text('Atrasada'),
                selected: _situacaoSelecionada == 'atrasada',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _situacaoSelecionada = 'atrasada';
                    });
                  }
                },
              ),
              ChoiceChip(
                label: const Text('Quitada'),
                selected: _situacaoSelecionada == 'quitada',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _situacaoSelecionada = 'quitada';
                    });
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botão salvar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _salvarNovaDivida,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulHeader,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Salvar Dívida'),
            ),
          ),
        ],
      ),
    );
  }

  /// Motivo principal das dívidas
  Widget _buildMotivoPrincipal() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Qual o principal motivo das suas dívidas?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _motivoSelecionado,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Selecione o motivo principal',
            ),
            items: DividasQuestionario.motivosPrincipais.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _motivoSelecionado = value;
              });
              _atualizarDividas(_dividas.copyWith(motivoPrincipal: value));
            },
          ),
        ],
      ),
    );
  }

  /// Estratégia de pagamento
  Widget _buildEstrategiaPagamento() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Como você lida com essas dívidas?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _estrategiaSelecionada,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Selecione sua estratégia',
            ),
            items: DividasQuestionario.estrategiasPagamento.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _estrategiaSelecionada = value;
              });
              _atualizarDividas(_dividas.copyWith(estrategiaPagamento: value));
            },
          ),
        ],
      ),
    );
  }

  /// Resumo total das dívidas
  Widget _buildResumoTotal() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade50,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.red.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total das dívidas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(_dividas.totalDividas),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_dividas.dividas.length} dívida${_dividas.dividas.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  if (_dividas.dividasEmAtraso > 0)
                    Text(
                      '${_dividas.dividasEmAtraso} em atraso',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (_dividas.totalParcelasMensais > 0) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Parcelas mensais: ${CurrencyFormatter.format(_dividas.totalParcelasMensais)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Salvar nova dívida
  void _salvarNovaDivida() {
    if (_descricaoController.text.isEmpty || _valorTotalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha pelo menos a descrição e o valor total'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final valorTotal = double.tryParse(_valorTotalController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0;
    if (valorTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valor total deve ser maior que zero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final novaDivida = DividaIndividual(
      descricao: _descricaoController.text,
      instituicao: _instituicaoController.text.isNotEmpty ? _instituicaoController.text : null,
      valorTotal: valorTotal / 100, // Converter centavos para reais
      valorParcela: _valorParcelaController.text.isNotEmpty
          ? (double.tryParse(_valorParcelaController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0) / 100
          : null,
      parcelasRestantes: _parcelasRestantesController.text.isNotEmpty
          ? int.tryParse(_parcelasRestantesController.text)
          : null,
      parcelasTotais: _parcelasTotaisController.text.isNotEmpty
          ? int.tryParse(_parcelasTotaisController.text)
          : null,
      situacao: _situacaoSelecionada,
    );

    _atualizarDividas(_dividas.adicionarDivida(novaDivida));
    _limparFormulario();
    setState(() {
      _mostrarFormulario = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dívida adicionada com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Remover dívida
  void _removerDivida(int index) {
    _atualizarDividas(_dividas.removerDivida(index));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dívida removida'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Limpar formulário
  void _limparFormulario() {
    _descricaoController.clear();
    _instituicaoController.clear();
    _valorTotalController.clear();
    _valorParcelaController.clear();
    _parcelasRestantesController.clear();
    _parcelasTotaisController.clear();
    _situacaoSelecionada = 'em_dia';
  }
}