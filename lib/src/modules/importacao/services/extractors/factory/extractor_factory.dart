// lib/src/modules/importacao/services/extractors/factory/extractor_factory.dart

import 'dart:developer' as dev;
import '../base/bank_extractor.dart';
import '../implementations/excel_extractor.dart';
import '../implementations/bradesco_extractor.dart';
import '../implementations/nubank_extractor.dart';
import '../implementations/itau_fatura_extractor.dart';
import '../implementations/generic_extractor.dart';

/// Factory para detectar banco e criar extractor apropriado
class ExtractorFactory {
  // Lista de extractors registrados (ordem de prioridade)
  static final List<BankExtractor> _extractors = [
    ExcelExtractor(), // Maior prioridade - processa Excel primeiro
    BradescoExtractor(),
    NubankExtractor(),
    ItauFaturaExtractor(),
    // Adicione novos bancos aqui...

    // GenericExtractor SEMPRE por último (fallback)
    GenericExtractor(),
  ];

  /// Detecta banco e retorna extractor apropriado
  ///
  /// Testa cada extractor na ordem de prioridade até encontrar
  /// um que possa processar o arquivo. Se nenhum for encontrado,
  /// retorna GenericExtractor.
  ///
  /// [content] Conteúdo do arquivo CSV
  /// [fileName] Nome do arquivo
  /// [excludeExcel] Exclui ExcelExtractor da busca (evita recursão)
  ///
  /// Retorna o extractor mais apropriado
  static BankExtractor detectExtractor(
    String content,
    String fileName, {
    bool excludeExcel = false,
  }) {
    dev.log('🔍 Iniciando detecção de banco para: $fileName');
    dev.log('📄 Primeiros 200 chars: ${content.substring(0, content.length > 200 ? 200 : content.length)}');

    // Ordenar por prioridade (maior primeiro)
    final sortedExtractors = List<BankExtractor>.from(_extractors)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    // Filtrar ExcelExtractor se solicitado (evita recursão)
    final extractorsToTest = excludeExcel
        ? sortedExtractors.where((e) => e.bankId != 'excel').toList()
        : sortedExtractors;

    for (final extractor in extractorsToTest) {
      try {
        dev.log('🧪 Testando ${extractor.bankName} (prioridade: ${extractor.priority})...');

        if (extractor.canHandle(content, fileName)) {
          dev.log('✅ Banco detectado: ${extractor.bankName}');
          return extractor;
        }
      } catch (e) {
        dev.log('⚠️ Erro ao testar ${extractor.bankName}: $e');
        continue;
      }
    }

    // Fallback para GenericExtractor
    dev.log('⚠️ Nenhum banco específico detectado, usando GenericExtractor');
    return GenericExtractor();
  }

  /// Retorna lista de todos os bancos suportados
  static List<String> getSupportedBanks() {
    return _extractors
        .where((e) => e.bankId != 'generic')
        .map((e) => e.bankName)
        .toList();
  }

  /// Registra um novo extractor (para extensões futuras)
  static void registerExtractor(BankExtractor extractor) {
    _extractors.insert(_extractors.length - 1, extractor); // Antes do Generic
    dev.log('✅ Extractor registrado: ${extractor.bankName}');
  }
}