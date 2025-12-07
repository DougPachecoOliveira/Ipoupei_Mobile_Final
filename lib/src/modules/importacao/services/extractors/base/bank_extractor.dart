// lib/src/modules/importacao/services/extractors/base/bank_extractor.dart

import 'dart:io';
import '../../../models/transacao_importada_model.dart';

/// Interface base para extractors bancários
///
/// Cada banco implementa esta interface com sua lógica específica
/// de detecção e extração de transações.
abstract class BankExtractor {
  /// Identificador único do banco (lowercase, sem espaços)
  /// Exemplo: 'bradesco', 'nubank', 'itau'
  String get bankId;

  /// Nome amigável do banco para exibição
  /// Exemplo: 'Bradesco', 'Nubank', 'Itaú'
  String get bankName;

  /// Prioridade de detecção (0-100, maior = mais prioritário)
  /// Usado quando múltiplos extractors podem processar o mesmo arquivo
  ///
  /// Valores sugeridos:
  /// - 90-100: Detecção muito específica (ex: metadados únicos)
  /// - 70-89: Detecção específica (ex: padrões únicos no conteúdo)
  /// - 50-69: Detecção moderada (ex: formato comum mas com indicadores)
  /// - 0-49: Detecção genérica (GenericExtractor = 0)
  int get priority => 50;

  /// Verifica se este extractor pode processar o arquivo
  ///
  /// Deve implementar lógica de detecção baseada em:
  /// - Nome do arquivo
  /// - Conteúdo (headers, padrões específicos)
  /// - Metadados
  ///
  /// [content] Conteúdo completo do arquivo
  /// [fileName] Nome do arquivo (sem path)
  ///
  /// Retorna true se pode processar, false caso contrário
  bool canHandle(String content, String fileName);

  /// Extrai transações do arquivo
  ///
  /// [file] Arquivo a ser processado
  /// [content] Conteúdo já lido do arquivo (performance)
  /// [tipoImportacao] Tipo: 'conta_corrente', 'cartao_credito', 'investimento'
  /// [contaId] ID da conta (opcional)
  /// [cartaoId] ID do cartão (opcional)
  /// [faturaVencimento] Data de vencimento da fatura (opcional)
  ///
  /// Retorna lista de transações extraídas
  /// Lança [ExtractorException] em caso de erro
  Future<List<TransacaoImportada>> extract(
    File file,
    String content, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  });

  /// Método auxiliar para logar com identificação do banco
  void log(String message) {
    print('[$bankName Extractor] $message');
  }
}

/// Exceção específica para erros de extração
class ExtractorException implements Exception {
  final String message;
  final String? bankId;
  final dynamic originalError;

  ExtractorException(
    this.message, {
    this.bankId,
    this.originalError,
  });

  @override
  String toString() {
    final prefix = bankId != null ? '[$bankId] ' : '';
    return 'ExtractorException: $prefix$message';
  }
}