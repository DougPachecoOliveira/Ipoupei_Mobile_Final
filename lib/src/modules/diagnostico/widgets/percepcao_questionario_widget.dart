// 🧠 Percepção Questionário Widget - iPoupei Mobile
//
// Widget de formulário para questionário de percepção financeira
// Baseado no questionário do iPoupei Device
//
// Design: Cards com radio buttons e validação

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../shared/theme/app_colors.dart';
import '../models/percepcao_financeira.dart';

/// Widget do questionário de percepção financeira
class PercepcaoQuestionarioWidget extends StatefulWidget {
  final PercepcaoFinanceira percepcaoInicial;
  final Function(PercepcaoFinanceira) onChanged;
  final bool showValidationErrors;

  const PercepcaoQuestionarioWidget({
    super.key,
    required this.percepcaoInicial,
    required this.onChanged,
    this.showValidationErrors = false,
  });

  @override
  State<PercepcaoQuestionarioWidget> createState() => _PercepcaoQuestionarioWidgetState();
}

class _PercepcaoQuestionarioWidgetState extends State<PercepcaoQuestionarioWidget> {
  late PercepcaoFinanceira _percepcao;

  @override
  void initState() {
    super.initState();
    _percepcao = widget.percepcaoInicial;

    // Definir valor padrão para horas trabalhadas se não estiver definido
    if (_percepcao.horasTrabalhadasMes == null) {
      _percepcao = _percepcao.copyWith(horasTrabalhadasMes: 160);
      widget.onChanged(_percepcao);
    }
  }

  void _atualizarPercepcao(String campo, String? valor) {
    setState(() {
      switch (campo) {
        case 'sentimento_financeiro':
          _percepcao = _percepcao.copyWith(sentimentoFinanceiro: valor);
          break;
        case 'percepcao_controle':
          _percepcao = _percepcao.copyWith(percepcaoControle: valor);
          break;
        case 'percepcao_gastos':
          _percepcao = _percepcao.copyWith(percepcaoGastos: valor);
          break;
        case 'disciplina_financeira':
          _percepcao = _percepcao.copyWith(disciplinaFinanceira: valor);
          break;
        case 'relacao_dinheiro':
          _percepcao = _percepcao.copyWith(relacaoDinheiro: valor);
          break;
        case 'tipo_renda':
          _percepcao = _percepcao.copyWith(tipoRenda: valor);
          break;
      }
    });

    widget.onChanged(_percepcao);
  }

  void _atualizarRenda(double? valor) {
    setState(() {
      _percepcao = _percepcao.copyWith(rendaMensal: valor);
    });
    widget.onChanged(_percepcao);
  }

  void _atualizarHoras(int? valor) {
    setState(() {
      _percepcao = _percepcao.copyWith(horasTrabalhadasMes: valor);
    });
    widget.onChanged(_percepcao);
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

          // Perguntas
          ...PercepcaoQuestionario.todasPerguntas.map((pergunta) {
            return Column(
              children: [
                _buildPerguntaCard(pergunta),
                const SizedBox(height: 16),
              ],
            );
          }),

          const SizedBox(height: 24),

          // Seção de Renda e Trabalho
          _buildSecaoRenda(),

          const SizedBox(height: 16),

          // Status de completude
          _buildStatusCompletude(),

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
            Colors.purple.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        children: [
          Icon(
            Icons.psychology,
            size: 48,
            color: Colors.purple.shade600,
          ),
          const SizedBox(height: 16),
          const Text(
            'Conhecendo sua relação com dinheiro',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Responda honestamente às perguntas abaixo. Não há respostas certas ou erradas, o objetivo é entender seu perfil financeiro.',
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

  /// Card de uma pergunta
  Widget _buildPerguntaCard(Map<String, dynamic> pergunta) {
    final perguntaId = pergunta['id'] as String;
    final textoPergunta = pergunta['pergunta'] as String;
    final opcoes = pergunta['opcoes'] as Map<String, String>;
    final obrigatoria = pergunta['obrigatoria'] as bool;

    // Obter valor atual
    String? valorAtual;
    switch (perguntaId) {
      case 'sentimento_financeiro':
        valorAtual = _percepcao.sentimentoFinanceiro;
        break;
      case 'percepcao_controle':
        valorAtual = _percepcao.percepcaoControle;
        break;
      case 'percepcao_gastos':
        valorAtual = _percepcao.percepcaoGastos;
        break;
      case 'disciplina_financeira':
        valorAtual = _percepcao.disciplinaFinanceira;
        break;
      case 'relacao_dinheiro':
        valorAtual = _percepcao.relacaoDinheiro;
        break;
      case 'tipo_renda':
        valorAtual = _percepcao.tipoRenda;
        break;
    }

    // Verificar se tem erro de validação
    final temErro = widget.showValidationErrors &&
                   obrigatoria &&
                   (valorAtual == null || valorAtual.isEmpty);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: temErro ? Colors.red.shade300 : Colors.grey.shade200,
          width: temErro ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            // Título da pergunta
            Row(
              children: [
                Expanded(
                  child: Text(
                    textoPergunta,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (obrigatoria)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Obrigatória',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Opções
            ...opcoes.entries.map((opcao) {
              final valor = opcao.key;
              final texto = opcao.value;
              final isSelected = valorAtual == valor;

              return Column(
                children: [
                  InkWell(
                    onTap: () => _atualizarPercepcao(perguntaId, valor),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                          ? Colors.purple.shade50
                          : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                            ? Colors.purple.shade300
                            : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: valor,
                            groupValue: valorAtual,
                            onChanged: (value) => _atualizarPercepcao(perguntaId, value),
                            activeColor: Colors.purple.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              texto,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                  ? Colors.purple.shade800
                                  : Colors.black87,
                                fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }),

            // Erro de validação
            if (temErro)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Esta pergunta é obrigatória',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Status de completude
  Widget _buildStatusCompletude() {
    final isCompleto = _percepcao.isObrigatoriosCompletos;
    final totalPerguntas = PercepcaoQuestionario.todasPerguntas.length;
    final perguntasRespondidas = _contarPerguntasRespondidas();
    final totalCampos = totalPerguntas + 2; // +2 para renda e horas

    // Debug para ver quais campos estão faltando
    if (kDebugMode) {
      print('🔍 Debug Percepção:');
      print('  sentimentoFinanceiro: ${_percepcao.sentimentoFinanceiro}');
      print('  percepcaoControle: ${_percepcao.percepcaoControle}');
      print('  percepcaoGastos: ${_percepcao.percepcaoGastos}');
      print('  disciplinaFinanceira: ${_percepcao.disciplinaFinanceira}');
      print('  relacaoDinheiro: ${_percepcao.relacaoDinheiro}');
      print('  tipoRenda: ${_percepcao.tipoRenda}');
      print('  rendaMensal: ${_percepcao.rendaMensal}');
      print('  horasTrabalhadasMes: ${_percepcao.horasTrabalhadasMes}');
      print('  isCompleto: $isCompleto');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleto ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleto ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleto ? Icons.check_circle : Icons.info,
            color: isCompleto ? Colors.green.shade600 : Colors.orange.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleto
                    ? 'Questionário completo!'
                    : 'Complete todos os campos',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isCompleto ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
                Text(
                  '$perguntasRespondidas de $totalCampos campos preenchidos',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleto ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          // Score preview (se completo)
          if (isCompleto) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${PercepcaoQuestionario.calcularScore(_percepcao)}/45 pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Seção de Renda e Trabalho
  Widget _buildSecaoRenda() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título da seção
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 28,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Renda e Trabalho',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Vamos calcular o valor da sua hora trabalhada',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            // Campo Renda Mensal
            _buildCampoRenda(),

            const SizedBox(height: 16),

            // Campo Horas Trabalhadas
            _buildCampoHoras(),

            const SizedBox(height: 16),

            // Valor da hora calculado
            if (_percepcao.valorHoraTrabalhada != null)
              _buildCardValorHora(),
          ],
        ),
      ),
    );
  }

  /// Campo de renda mensal
  Widget _buildCampoRenda() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Renda líquida mensal',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            initialValue: _percepcao.rendaMensal?.toStringAsFixed(2).replaceAll('.', ','),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'R\$ 0,00',
              prefixText: 'R\$ ',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            onChanged: (value) {
              final cleanValue = value.replaceAll(RegExp(r'[^\d,]'), '').replaceAll(',', '.');
              final parsedValue = double.tryParse(cleanValue);
              _atualizarRenda(parsedValue);
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Valor que efetivamente cai na sua conta',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Campo de horas trabalhadas
  Widget _buildCampoHoras() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Horas trabalhadas por mês',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            initialValue: _percepcao.horasTrabalhadasMes?.toString() ?? '160',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '160',
              suffixText: 'horas',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            onChanged: (value) {
              final parsedValue = int.tryParse(value);
              if (parsedValue != null && parsedValue > 0) {
                _atualizarHoras(parsedValue);
              }
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Exemplo: 40h/semana ≈ 160h/mês',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Card mostrando valor da hora
  Widget _buildCardValorHora() {
    final valorHora = _percepcao.valorHoraTrabalhada!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calculate,
            color: Colors.green.shade600,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Valor da sua hora',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'R\$ ${valorHora.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Contar perguntas respondidas
  int _contarPerguntasRespondidas() {
    int count = 0;
    if (_percepcao.sentimentoFinanceiro != null && _percepcao.sentimentoFinanceiro!.isNotEmpty) count++;
    if (_percepcao.percepcaoControle != null && _percepcao.percepcaoControle!.isNotEmpty) count++;
    if (_percepcao.percepcaoGastos != null && _percepcao.percepcaoGastos!.isNotEmpty) count++;
    if (_percepcao.disciplinaFinanceira != null && _percepcao.disciplinaFinanceira!.isNotEmpty) count++;
    if (_percepcao.relacaoDinheiro != null && _percepcao.relacaoDinheiro!.isNotEmpty) count++;
    if (_percepcao.tipoRenda != null && _percepcao.tipoRenda!.isNotEmpty) count++;
    if (_percepcao.rendaMensal != null && _percepcao.rendaMensal! > 0) count++;
    if (_percepcao.horasTrabalhadasMes != null && _percepcao.horasTrabalhadasMes! > 0) count++;
    return count;
  }
}