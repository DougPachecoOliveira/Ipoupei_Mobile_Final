// lib/src/modules/importacao/services/extractors/implementations/generic_extractor.dart

import 'dart:io';
import '../base/bank_extractor.dart';
import '../../../models/transacao_importada_model.dart';
import '../../importacao_service.dart';

/// Extractor genérico - fallback quando nenhum banco específico é detectado
///
/// Usa a lógica existente do ImportacaoService._parseCSVSimples()
/// para manter compatibilidade com arquivos que já funcionam.
class GenericExtractor extends BankExtractor {
  @override
  String get bankId => 'generic';

  @override
  String get bankName => 'Genérico';

  @override
  int get priority => 0; // Menor prioridade - sempre usado como fallback

  @override
  bool canHandle(String content, String fileName) {
    // GenericExtractor sempre pode processar qualquer arquivo
    // Ele é o fallback final
    return true;
  }

  @override
  Future<List<TransacaoImportada>> extract(
    File file,
    String content, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) async {
    log('📄 Usando processamento genérico (fallback)');

    // Delegar para o método existente do ImportacaoService
    // Isso garante que arquivos que já funcionam continuem funcionando
    final service = ImportacaoService.instance;

    // Usar o método parseCSVSimples diretamente
    // (evita recursão infinita no processarArquivoCSV)
    return await service.parseCSVSimples(
      content,
      file.path.split('/').last,
      tipoImportacao,
      contaId,
      cartaoId,
      faturaVencimento,
    );
  }
}