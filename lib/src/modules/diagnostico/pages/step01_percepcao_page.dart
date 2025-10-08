// 💭 Step01 Percepção - iPoupei Mobile
//
// Questionário de percepção financeira
// Coleta como o usuário se relaciona com dinheiro
//
// Layout: 5 perguntas de múltipla escolha sobre percepção financeira

import 'package:flutter/material.dart';
import '../widgets/etapa_layout_widget.dart';
import '../models/diagnostico_etapa.dart';
import '../models/percepcao_financeira.dart';

class Step01PercepcaoPage extends StatefulWidget {
  final PercepcaoFinanceira? percepcaoInicial;
  final Function(PercepcaoFinanceira percepcao) onChanged;
  final VoidCallback onContinuar;

  const Step01PercepcaoPage({
    super.key,
    this.percepcaoInicial,
    required this.onChanged,
    required this.onContinuar,
  });

  @override
  State<Step01PercepcaoPage> createState() => _Step01PercepcaoPageState();
}

class _Step01PercepcaoPageState extends State<Step01PercepcaoPage> {
  late PercepcaoFinanceira _percepcao;

  @override
  void initState() {
    super.initState();
    _percepcao = widget.percepcaoInicial ?? PercepcaoFinanceira.vazio();
  }

  bool get _podeAvancar {
    return _percepcao.sentimentoFinanceiro != null &&
        _percepcao.percepcaoControle != null &&
        _percepcao.percepcaoGastos != null &&
        _percepcao.disciplinaFinanceira != null &&
        _percepcao.relacaoDinheiro != null;
  }

  void _handleResposta(String campo, String valor) {
    setState(() {
      switch (campo) {
        case 'sentimento':
          _percepcao = PercepcaoFinanceira(
            sentimentoFinanceiro: valor,
            percepcaoControle: _percepcao.percepcaoControle,
            percepcaoGastos: _percepcao.percepcaoGastos,
            disciplinaFinanceira: _percepcao.disciplinaFinanceira,
            relacaoDinheiro: _percepcao.relacaoDinheiro,
            rendaMensal: _percepcao.rendaMensal,
            horasTrabalhadasMes: _percepcao.horasTrabalhadasMes,
          );
          break;
        case 'controle':
          _percepcao = PercepcaoFinanceira(
            sentimentoFinanceiro: _percepcao.sentimentoFinanceiro,
            percepcaoControle: valor,
            percepcaoGastos: _percepcao.percepcaoGastos,
            disciplinaFinanceira: _percepcao.disciplinaFinanceira,
            relacaoDinheiro: _percepcao.relacaoDinheiro,
            rendaMensal: _percepcao.rendaMensal,
            horasTrabalhadasMes: _percepcao.horasTrabalhadasMes,
          );
          break;
        case 'gastos':
          _percepcao = PercepcaoFinanceira(
            sentimentoFinanceiro: _percepcao.sentimentoFinanceiro,
            percepcaoControle: _percepcao.percepcaoControle,
            percepcaoGastos: valor,
            disciplinaFinanceira: _percepcao.disciplinaFinanceira,
            relacaoDinheiro: _percepcao.relacaoDinheiro,
            rendaMensal: _percepcao.rendaMensal,
            horasTrabalhadasMes: _percepcao.horasTrabalhadasMes,
          );
          break;
        case 'disciplina':
          _percepcao = PercepcaoFinanceira(
            sentimentoFinanceiro: _percepcao.sentimentoFinanceiro,
            percepcaoControle: _percepcao.percepcaoControle,
            percepcaoGastos: _percepcao.percepcaoGastos,
            disciplinaFinanceira: valor,
            relacaoDinheiro: _percepcao.relacaoDinheiro,
            rendaMensal: _percepcao.rendaMensal,
            horasTrabalhadasMes: _percepcao.horasTrabalhadasMes,
          );
          break;
        case 'relacao':
          _percepcao = PercepcaoFinanceira(
            sentimentoFinanceiro: _percepcao.sentimentoFinanceiro,
            percepcaoControle: _percepcao.percepcaoControle,
            percepcaoGastos: _percepcao.percepcaoGastos,
            disciplinaFinanceira: _percepcao.disciplinaFinanceira,
            relacaoDinheiro: valor,
            rendaMensal: _percepcao.rendaMensal,
            horasTrabalhadasMes: _percepcao.horasTrabalhadasMes,
          );
          break;
      }
    });

    widget.onChanged(_percepcao);
  }

  @override
  Widget build(BuildContext context) {
    return EtapaLayoutWidget(
      etapa: DiagnosticoEtapas.todas[1], // Percepção é a segunda etapa (índice 1)
      progresso: DiagnosticoEtapas.calcularProgressoPorIndice(1),
      etapaAtual: 1,
      totalEtapas: DiagnosticoEtapas.todas.length,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Introdução
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF8b5cf6).withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF8b5cf6).withAlpha(78),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.psychology,
                    size: 48,
                    color: Color(0xFF8b5cf6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Como você se relaciona com o dinheiro?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1f2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Responda com sinceridade para um diagnóstico mais preciso',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6b7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pergunta 1: Como você se sente em relação ao dinheiro?
            _buildPergunta(
              numero: 1,
              pergunta: 'Como você se sente em relação ao dinheiro?',
              campo: 'sentimento',
              opcoes: const [
                {'valor': 'ansioso', 'label': '😰 Ansioso e preocupado'},
                {'valor': 'confuso', 'label': '😵 Confuso, não sei o que fazer'},
                {'valor': 'esperancoso', 'label': '😊 Esperançoso, quero melhorar'},
                {'valor': 'confiante', 'label': '😎 Confiante no meu futuro'},
              ],
              valorSelecionado: _percepcao.sentimentoFinanceiro,
            ),

            const SizedBox(height: 20),

            // Pergunta 2: Como você avalia seu controle financeiro?
            _buildPergunta(
              numero: 2,
              pergunta: 'Como você avalia seu controle financeiro atual?',
              campo: 'controle',
              opcoes: const [
                {'valor': 'nenhum', 'label': '😰 Não tenho controle nenhum'},
                {'valor': 'pouco', 'label': '😐 Tenho pouco controle'},
                {'valor': 'parcial', 'label': '🙂 Tenho controle parcial'},
                {'valor': 'total', 'label': '😎 Tenho controle total'},
              ],
              valorSelecionado: _percepcao.percepcaoControle,
            ),

            const SizedBox(height: 20),

            // Pergunta 3: Como você percebe seus gastos?
            _buildPergunta(
              numero: 3,
              pergunta: 'Como você percebe seus gastos mensais?',
              campo: 'gastos',
              opcoes: const [
                {'valor': 'descontrolados', 'label': '😱 Totalmente descontrolados'},
                {'valor': 'altos', 'label': '😰 Altos demais'},
                {'valor': 'equilibrados', 'label': '😊 Razoavelmente equilibrados'},
                {'valor': 'controlados', 'label': '😎 Bem controlados'},
              ],
              valorSelecionado: _percepcao.percepcaoGastos,
            ),

            const SizedBox(height: 20),

            // Pergunta 4: Com que frequência você controla seus gastos?
            _buildPergunta(
              numero: 4,
              pergunta: 'Com que frequência você controla seus gastos?',
              campo: 'disciplina',
              opcoes: const [
                {'valor': 'nunca', 'label': '🤷‍♂️ Nunca controlo'},
                {'valor': 'raramente', 'label': '😅 Raramente'},
                {'valor': 'as-vezes', 'label': '🤔 Às vezes'},
                {'valor': 'sempre', 'label': '💪 Sempre controlo'},
              ],
              valorSelecionado: _percepcao.disciplinaFinanceira,
            ),

            const SizedBox(height: 20),

            // Pergunta 5: Você planeja seu futuro financeiro?
            _buildPergunta(
              numero: 5,
              pergunta: 'Você planeja seu futuro financeiro?',
              campo: 'relacao',
              opcoes: const [
                {'valor': 'nao', 'label': '😟 Não penso nisso'},
                {'valor': 'pensando', 'label': '🤯 Estou pensando em começar'},
                {'valor': 'sim-basico', 'label': '📝 Sim, tenho planos básicos'},
                {'valor': 'sim-planos', 'label': '🎯 Sim, tenho planos detalhados'},
              ],
              valorSelecionado: _percepcao.relacaoDinheiro,
            ),

            const SizedBox(height: 24),

            // Botão continuar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _podeAvancar ? widget.onContinuar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8b5cf6),
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
      ),
    );
  }

  Widget _buildPergunta({
    required int numero,
    required String pergunta,
    required String campo,
    required List<Map<String, String>> opcoes,
    String? valorSelecionado,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe5e7eb)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$numero. $pergunta',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 16),
          ...opcoes.map((opcao) {
            final isSelected = valorSelecionado == opcao['valor'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _handleResposta(campo, opcao['valor']!),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected
                        ? const Color(0xFF8b5cf6).withAlpha(26)
                        : Colors.white,
                    foregroundColor: isSelected
                        ? const Color(0xFF8b5cf6)
                        : const Color(0xFF6b7280),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF8b5cf6)
                          : const Color(0xFFe5e7eb),
                      width: isSelected ? 2 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      opcao['label']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
