// 👋 Step01 Welcome - iPoupei Mobile
//
// Baseado no Step01_WelcomeDiagnostico.jsx do offline
// Tela de boas-vindas com preview das 5 etapas principais
//
// Layout: Background gradiente + card central + botão CTA

import 'package:flutter/material.dart';
import '../widgets/etapa_layout_widget.dart';
import '../models/diagnostico_etapa.dart';

class Step01WelcomePage extends StatelessWidget {
  final VoidCallback onContinuar;

  const Step01WelcomePage({
    super.key,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    return EtapaLayoutWidget(
      etapa: DiagnosticoEtapas.todas[0],
      progresso: DiagnosticoEtapas.calcularProgressoPorIndice(0),
      etapaAtual: 0,
      totalEtapas: DiagnosticoEtapas.todas.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título principal
          const Text(
            'Diagnóstico Financeiro Gratuito',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1f2937),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Descubra sua situação financeira atual em apenas 5 minutos',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Preview das etapas
          _buildEtapasPreview(),

          const SizedBox(height: 32),

          // Garantias de privacidade
          _buildPrivacyAssurance(),

          const Spacer(),

          // Botão principal
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onContinuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Começar meu Diagnóstico',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapasPreview() {
    final etapasPreview = [
      {'icon': Icons.monetization_on, 'title': 'Sua Renda', 'subtitle': 'Renda mensal atual'},
      {'icon': Icons.receipt_long, 'title': 'Gastos', 'subtitle': 'Como você gasta seu dinheiro'},
      {'icon': Icons.warning, 'title': 'Dívidas', 'subtitle': 'Situação de dívidas atuais'},
      {'icon': Icons.trending_down, 'title': 'Vilão do Orçamento', 'subtitle': 'O que mais consome seu dinheiro'},
      {'icon': Icons.account_balance, 'title': 'Reservas', 'subtitle': 'Quanto você tem guardado'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'O que vamos analisar:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1f2937),
          ),
        ),
        const SizedBox(height: 16),
        ...etapasPreview.map((etapa) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  etapa['icon'] as IconData,
                  color: const Color(0xFF667eea),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      etapa['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                    Text(
                      etapa['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildPrivacyAssurance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10b981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10b981).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.security,
            color: Color(0xFF10b981),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seus dados estão seguros',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10b981),
                  ),
                ),
                Text(
                  'Não pedimos senhas nem acessamos suas contas',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}