// lib/src/modules/diagnostico/widgets/diagnostico_header.dart

import 'package:flutter/material.dart';
import '../models/diagnostico_etapa.dart';

/// Header do diagnóstico com progresso e navegação
class DiagnosticoHeader extends StatelessWidget {
  final DiagnosticoEtapa etapaAtual;
  final double progresso; // 0-100
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final bool showProgress;

  const DiagnosticoHeader({
    super.key,
    required this.etapaAtual,
    required this.progresso,
    this.onBack,
    this.onClose,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            etapaAtual.cor,
            etapaAtual.cor.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha superior - Navegação
              _buildTopNavigation(context),

              const SizedBox(height: 16),

              // Título da etapa
              _buildEtapaTitulo(),

              if (showProgress) ...[
                const SizedBox(height: 16),

                // Barra de progresso
                _buildProgressBar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói navegação superior
  Widget _buildTopNavigation(BuildContext context) {
    return Row(
      children: [
        // Botão voltar
        if (onBack != null)
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          )
        else
          const SizedBox(width: 36), // Espaço para centralização

        // Título central
        Expanded(
          child: Text(
            'Diagnóstico Financeiro',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Botão fechar
        if (onClose != null)
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          )
        else
          const SizedBox(width: 36), // Espaço para centralização
      ],
    );
  }

  /// Constrói título e descrição da etapa
  Widget _buildEtapaTitulo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícone + Título
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                etapaAtual.icone,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etapaAtual.titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (etapaAtual.subtitulo != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      etapaAtual.subtitulo!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        // Descrição (se houver)
        if (etapaAtual.descricao != null) ...[
          const SizedBox(height: 12),
          Text(
            etapaAtual.descricao!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  /// Constrói barra de progresso
  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Texto do progresso
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${progresso.toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Barra de progresso
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progresso / 100,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Header simples para casos especiais
class DiagnosticoHeaderSimples extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final IconData? icone;
  final Color? cor;
  final VoidCallback? onClose;

  const DiagnosticoHeaderSimples({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.icone,
    this.cor,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final corFinal = cor ?? const Color(0xFF3b82f6);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            corFinal,
            corFinal.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone (se houver)
              if (icone != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icone,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
              ],

              // Título e subtítulo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitulo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitulo!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Botão fechar
              if (onClose != null)
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}