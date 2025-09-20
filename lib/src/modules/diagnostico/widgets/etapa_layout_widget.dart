// 🎨 Etapa Layout Widget - iPoupei Mobile
//
// Layout bonito para etapas do diagnóstico igual ao offline
// Design inspirado no StepWrapper.jsx com gradientes
//
// Visual: Background gradiente + card branco + sombras

import 'package:flutter/material.dart';
import '../models/diagnostico_etapa.dart';

/// Layout bonito para etapas do diagnóstico
class EtapaLayoutWidget extends StatelessWidget {
  final DiagnosticoEtapa etapa;
  final Widget child;
  final double progresso;
  final int etapaAtual;
  final int totalEtapas;

  const EtapaLayoutWidget({
    super.key,
    required this.etapa,
    required this.child,
    required this.progresso,
    required this.etapaAtual,
    required this.totalEtapas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header com progresso
              _buildProgressHeader(),

              const SizedBox(height: 20),

              // Card principal branco
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header da etapa
                        _buildEtapaHeader(),

                        // Conteúdo da etapa
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header com progresso simples
  Widget _buildProgressHeader() {
    return Column(
      children: [
        // Barra de progresso
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progresso / 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFef4444), Color(0xFFf59e0b)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Texto da etapa
        Text(
          'Etapa ${etapaAtual + 1} de $totalEtapas',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Header da etapa
  Widget _buildEtapaHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            etapa.cor.withOpacity(0.1),
            etapa.cor.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: etapa.cor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Ícone da etapa
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: etapa.cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              etapa.icone,
              color: etapa.cor,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Título e descrição
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etapa.titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
                if (etapa.descricao != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    etapa.descricao!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6b7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de opção bonito para seleções
class OptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const OptionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.color = const Color(0xFF008080),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : const Color(0xFFe5e7eb),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Ícone (se fornecido)
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.1) : const Color(0xFFf9fafb),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? color : const Color(0xFF6b7280),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : const Color(0xFF1f2937),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6b7280),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Indicador de seleção
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Input de valor monetário bonito
class MoneyInputCard extends StatelessWidget {
  final String label;
  final String? hint;
  final double? value;
  final ValueChanged<double?> onChanged;
  final bool isRequired;

  const MoneyInputCard({
    super.key,
    required this.label,
    this.hint,
    this.value,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFf9fafb),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Color(0xFFef4444),
                    fontSize: 16,
                  ),
                ),
            ],
          ),

          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6b7280),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Input
          TextFormField(
            initialValue: value?.toStringAsFixed(2).replaceAll('.', ','),
            onChanged: (text) {
              final cleanText = text.replaceAll(',', '.');
              final parsedValue = double.tryParse(cleanText);
              onChanged(parsedValue);
            },
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
            decoration: InputDecoration(
              prefixText: 'R\$ ',
              prefixStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6b7280),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF008080), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}