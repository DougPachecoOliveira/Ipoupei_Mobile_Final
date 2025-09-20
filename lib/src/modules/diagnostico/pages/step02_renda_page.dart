// 💰 Step02 Renda - iPoupei Mobile
//
// Baseado no Step02_Renda.jsx do offline
// Coleta renda mensal e situação no final do mês
//
// Layout: Input de renda + opções de situação

import 'package:flutter/material.dart';
import '../widgets/etapa_layout_widget.dart';
import '../models/diagnostico_etapa.dart';

class Step02RendaPage extends StatefulWidget {
  final double? rendaInicial;
  final String? situacaoInicial;
  final Function(double renda, String situacao) onChanged;
  final VoidCallback onContinuar;

  const Step02RendaPage({
    super.key,
    this.rendaInicial,
    this.situacaoInicial,
    required this.onChanged,
    required this.onContinuar,
  });

  @override
  State<Step02RendaPage> createState() => _Step02RendaPageState();
}

class _Step02RendaPageState extends State<Step02RendaPage> {
  final TextEditingController _rendaController = TextEditingController();
  double? _renda;
  String? _situacao;

  @override
  void initState() {
    super.initState();
    _renda = widget.rendaInicial;
    _situacao = widget.situacaoInicial;

    if (_renda != null) {
      _rendaController.text = _renda!.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  bool get _podeAvancar => _renda != null && _situacao != null;

  void _handleRendaChanged(String value) {
    final cleanValue = value.replaceAll(',', '.');
    final parsedValue = double.tryParse(cleanValue);

    setState(() {
      _renda = parsedValue;
    });

    if (_renda != null && _situacao != null) {
      widget.onChanged(_renda!, _situacao!);
    }
  }

  void _handleSituacaoChanged(String situacao) {
    setState(() {
      _situacao = situacao;
    });

    if (_renda != null && _situacao != null) {
      widget.onChanged(_renda!, _situacao!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EtapaLayoutWidget(
      etapa: DiagnosticoEtapas.todas[1],
      progresso: DiagnosticoEtapas.calcularProgressoPorIndice(1),
      etapaAtual: 1,
      totalEtapas: DiagnosticoEtapas.todas.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input de renda
          MoneyInputCard(
            label: 'Qual sua renda líquida mensal?',
            hint: 'Valor que sobra após descontos e impostos',
            value: _renda,
            onChanged: (value) {
              if (value != null) {
                setState(() => _renda = value);
                if (_situacao != null) {
                  widget.onChanged(value, _situacao!);
                }
              }
            },
            isRequired: true,
          ),

          const SizedBox(height: 24),

          // Situação no final do mês
          const Text(
            'Como fica no final do mês?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),

          const SizedBox(height: 16),

          // Opções de situação
          _buildSituacaoOptions(),

          const Spacer(),

          // Feedback dinâmico
          if (_renda != null) _buildFeedback(),

          const SizedBox(height: 16),

          // Botão continuar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _podeAvancar ? widget.onContinuar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10b981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSituacaoOptions() {
    final opcoes = [
      {
        'value': 'sobra',
        'title': '💰 Sobra dinheiro',
        'subtitle': 'Consigo guardar ou investir',
        'color': const Color(0xFF10b981),
      },
      {
        'value': 'equilibrado',
        'title': '⚖️ Fico zerado',
        'subtitle': 'Gasto tudo que ganho',
        'color': const Color(0xFFf59e0b),
      },
      {
        'value': 'falta',
        'title': '😰 Falta dinheiro',
        'subtitle': 'Preciso me endividar ou pedir emprestado',
        'color': const Color(0xFFef4444),
      },
      {
        'value': 'nao_sei',
        'title': '🤷‍♂️ Não sei dizer',
        'subtitle': 'Não tenho controle dos gastos',
        'color': const Color(0xFF6b7280),
      },
    ];

    return Column(
      children: opcoes.map((opcao) => OptionCard(
        title: opcao['title'] as String,
        subtitle: opcao['subtitle'] as String,
        isSelected: _situacao == opcao['value'],
        onTap: () => _handleSituacaoChanged(opcao['value'] as String),
        color: opcao['color'] as Color,
      )).toList(),
    );
  }

  Widget _buildFeedback() {
    if (_renda == null) return const SizedBox();

    String feedback;
    Color color;
    IconData icon;

    if (_renda! >= 10000) {
      feedback = 'Excelente! Com essa renda você tem bom potencial de poupança.';
      color = const Color(0xFF10b981);
      icon = Icons.trending_up;
    } else if (_renda! >= 5000) {
      feedback = 'Boa renda! Vamos ver como otimizar seus gastos.';
      color = const Color(0xFF10b981);
      icon = Icons.thumb_up;
    } else if (_renda! >= 2000) {
      feedback = 'Vamos trabalhar juntos para maximizar essa renda.';
      color = const Color(0xFFf59e0b);
      icon = Icons.insights;
    } else {
      feedback = 'Todo início é importante. Vamos construir juntos!';
      color = const Color(0xFF667eea);
      icon = Icons.emoji_events;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feedback,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rendaController.dispose();
    super.dispose();
  }
}