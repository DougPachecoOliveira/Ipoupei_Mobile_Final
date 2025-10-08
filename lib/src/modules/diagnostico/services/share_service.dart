// 📤 Share Service - iPoupei Mobile
//
// Service para compartilhamento do resultado do diagnóstico
// Versão simplificada sem dependências externas
//
// Funcionalidades: Clipboard

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service para compartilhamento de resultados
class ShareService {
  /// Compartilhar resultado (copia para clipboard)
  Future<void> compartilharResultado(Map<String, dynamic> resultado) async {
    try {
      final texto = _gerarTextoCompartilhamento(resultado);

      // Copiar para clipboard
      await Clipboard.setData(ClipboardData(text: texto));

      debugPrint('✅ Resultado copiado para clipboard');
    } catch (e) {
      debugPrint('❌ Erro ao copiar resultado: $e');
      rethrow;
    }
  }

  /// Gerar texto para compartilhamento
  String _gerarTextoCompartilhamento(Map<String, dynamic> resultado) {
    final scoreTotal = resultado['score_total'] ?? 0;
    final interpretacao = _getInterpretacao(scoreTotal);
    final scores = resultado['scores'] as Map<String, dynamic>? ?? {};

    return '''
🎯 MEU DIAGNÓSTICO FINANCEIRO

📊 Score: $scoreTotal/100 pontos
🏆 Nível: $interpretacao

📈 SCORES POR DIMENSÃO:
${_formatarScores(scores)}

📱 Calculado pelo app iPoupei
#EducacaoFinanceira #OrganizacaoFinanceira
''';
  }

  /// Formatar scores por dimensão
  String _formatarScores(Map<String, dynamic> scores) {
    if (scores.isEmpty) return '• Nenhuma dimensão avaliada';

    return scores.entries.map((entry) {
      final nome = _getNomeDimensao(entry.key);
      final score = entry.value;
      return '• $nome: $score/20';
    }).join('\n');
  }

  /// Obter nome da dimensão
  String _getNomeDimensao(String key) {
    switch (key) {
      case 'percepcao':
        return 'Percepção';
      case 'organizacao':
        return 'Organização';
      case 'controle':
        return 'Controle';
      case 'planejamento':
        return 'Planejamento';
      case 'investimento':
        return 'Investimento';
      default:
        return key;
    }
  }

  /// Interpretação do score
  String _getInterpretacao(int score) {
    if (score >= 80) return 'Excelente';
    if (score >= 60) return 'Bom';
    if (score >= 40) return 'Regular';
    return 'Precisa melhorar';
  }

  /// Mostrar dialog com texto de compartilhamento
  Future<void> mostrarPreview(BuildContext context, Map<String, dynamic> resultado) async {
    final texto = _gerarTextoCompartilhamento(resultado);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share, color: Colors.blue),
            SizedBox(width: 8),
            Text('Compartilhar Resultado'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Texto que será copiado:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  texto,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await compartilharResultado(resultado);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Resultado copiado para a área de transferência!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar'),
          ),
        ],
      ),
    );
  }
}