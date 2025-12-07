// lib/src/modules/importacao/services/extractors/implementations/bradesco_extractor.dart

import 'dart:io';
import 'dart:developer' as dev;
import '../base/bank_extractor.dart';
import '../../../models/transacao_importada_model.dart';
import '../../../../../auth_integration.dart';

/// Extractor específico para arquivos CSV do Bradesco
///
/// Formato esperado:
/// - Linha 1: Info da conta (Ag: XXXX | Conta: XXXX-X)
/// - Linha 2: Headers (Data;Histórico;Docto.;Crédito (R$);Débito (R$);Saldo (R$))
/// - Linhas 3+: Transações
/// - Últimas linhas: Rodapé/Resumo
///
/// Características:
/// - Separador: ponto-vírgula (;)
/// - Data: DD/MM/YYYY
/// - Decimal: vírgula (,)
/// - Crédito e Débito em colunas separadas
class BradescoExtractor extends BankExtractor {
  final _authIntegration = AuthIntegration.instance;

  @override
  String get bankId => 'bradesco';

  @override
  String get bankName => 'Bradesco';

  @override
  int get priority => 80; // Alta prioridade - detecção específica

  // Índices das colunas no CSV Bradesco
  static const int _colData = 0;
  static const int _colHistorico = 1;
  static const int _colDocumento = 2;
  static const int _colCredito = 3;
  static const int _colDebito = 4;
  static const int _colSaldo = 5;

  @override
  bool canHandle(String content, String fileName) {
    // Estratégia 1: Nome do arquivo
    if (_detectByFileName(fileName)) {
      log('✅ Detectado por nome do arquivo');
      return true;
    }

    // Estratégia 2: Padrões no conteúdo
    if (_detectByContent(content)) {
      log('✅ Detectado por padrões no conteúdo');
      return true;
    }

    return false;
  }

  /// Detecta pelo nome do arquivo
  bool _detectByFileName(String fileName) {
    final name = fileName.toLowerCase();

    // Padrões comuns de nomes de arquivo Bradesco
    final patterns = [
      'bradesco',
      'extrato_bradesco',
      'conta_bradesco',
      'cc_bradesco',
      'ag_', // Arquivos com padrão "ag_XXXX_conta_XXXX.csv"
    ];

    return patterns.any((pattern) => name.contains(pattern));
  }

  /// Detecta por padrões no conteúdo
  bool _detectByContent(String content) {
    // Verificações de padrões específicos do Bradesco

    // 1. Primeira linha contém info da conta no formato "Ag: XXXX | Conta: XXXX-X"
    final lines = content.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines[0].toLowerCase();
      if (firstLine.contains('ag:') && firstLine.contains('conta:')) {
        return true;
      }
    }

    // 2. Header com padrão específico do Bradesco
    if (lines.length > 1) {
      final secondLine = lines[1].toLowerCase();
      if (secondLine.contains('data') &&
          secondLine.contains('histórico') &&
          secondLine.contains('docto') &&
          secondLine.contains('crédito') &&
          secondLine.contains('débito') &&
          secondLine.contains('saldo')) {
        return true;
      }
    }

    // 3. Padrão de separador e colunas
    if (content.contains(';') &&
        content.contains('Crédito (R\$)') &&
        content.contains('Débito (R\$)')) {
      return true;
    }

    return false;
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
    log('📊 Iniciando extração de transações');

    try {
      final lines = content.split('\n');
      final transacoes = <TransacaoImportada>[];
      final userId = _authIntegration.authService.currentUser?.id ?? '';

      // Validar estrutura mínima
      if (lines.length < 3) {
        throw ExtractorException(
          'Arquivo muito curto. Mínimo esperado: 3 linhas (info conta, header, dados)',
          bankId: bankId,
        );
      }

      // Extrair informações da conta (linha 1)
      final accountInfo = _extractAccountInfo(lines[0]);
      log('🏦 Conta detectada: ${accountInfo['agencia']} / ${accountInfo['conta']}');

      // Validar header (linha 2)
      if (!_validateHeader(lines[1])) {
        throw ExtractorException(
          'Header inválido. Esperado formato Bradesco com colunas: Data, Histórico, Docto., Crédito, Débito, Saldo',
          bankId: bankId,
        );
      }

      // Processar transações (linha 3 em diante)
      int linhaInicio = 2; // Pular linha de conta e header
      int linhaAtual = linhaInicio;

      for (int i = linhaInicio; i < lines.length; i++) {
        linhaAtual = i;
        final line = lines[i].trim();

        // Parar se chegou no rodapé
        if (_isFooterLine(line)) {
          log('📌 Rodapé detectado na linha $i, parando processamento');
          break;
        }

        // Pular linhas vazias
        if (line.isEmpty) continue;

        try {
          final transacao = _extractTransactionFromLine(
            line,
            i,
            userId,
            tipoImportacao: tipoImportacao,
            contaId: contaId,
            cartaoId: cartaoId,
            faturaVencimento: faturaVencimento,
            accountInfo: accountInfo,
          );

          if (transacao != null) {
            transacoes.add(transacao);
          }
        } catch (e) {
          log('⚠️ Erro ao processar linha $i: $e');
          // Continua processando as outras linhas
          continue;
        }
      }

      log('✅ Extração concluída: ${transacoes.length} transações processadas');

      if (transacoes.isEmpty) {
        throw ExtractorException(
          'Nenhuma transação válida encontrada no arquivo',
          bankId: bankId,
        );
      }

      return transacoes;

    } catch (e) {
      if (e is ExtractorException) rethrow;

      throw ExtractorException(
        'Erro ao processar arquivo Bradesco: ${e.toString()}',
        bankId: bankId,
        originalError: e,
      );
    }
  }

  /// Extrai informações da conta da primeira linha
  Map<String, String> _extractAccountInfo(String line) {
    final info = <String, String>{};

    // Padrão: "Extrato de: Ag: 2328 | Conta: 2539-9"
    final agenciaMatch = RegExp(r'Ag:\s*(\d+)').firstMatch(line);
    final contaMatch = RegExp(r'Conta:\s*([\d-]+)').firstMatch(line);

    if (agenciaMatch != null) {
      info['agencia'] = agenciaMatch.group(1)!;
    }

    if (contaMatch != null) {
      info['conta'] = contaMatch.group(1)!;
    }

    return info;
  }

  /// Valida se o header está no formato esperado
  bool _validateHeader(String line) {
    final lower = line.toLowerCase();

    return lower.contains('data') &&
           lower.contains('histórico') &&
           (lower.contains('crédito') || lower.contains('debito'));
  }

  /// Verifica se a linha é parte do rodapé
  bool _isFooterLine(String line) {
    final lower = line.toLowerCase();

    // Padrões de rodapé Bradesco
    final footerPatterns = [
      'filtro de resultados',
      'movimentação entre',
      'os dados acima',
      'últimos lancamentos',
      'não há lançamentos',
      'total',
    ];

    return footerPatterns.any((pattern) => lower.contains(pattern));
  }

  /// Extrai transação de uma linha
  TransacaoImportada? _extractTransactionFromLine(
    String line,
    int lineIndex,
    String userId, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
    Map<String, String>? accountInfo,
  }) {
    final parts = line.split(';');

    // Validar número mínimo de colunas
    if (parts.length < 6) {
      log('⚠️ Linha $lineIndex ignorada: menos de 6 colunas (${parts.length})');
      return null;
    }

    // Extrair dados
    final dataStr = parts[_colData].trim();
    final historico = parts[_colHistorico].trim();
    final documento = parts[_colDocumento].trim();
    final creditoStr = parts[_colCredito].trim();
    final debitoStr = parts[_colDebito].trim();
    final saldoStr = parts[_colSaldo].trim();

    // Validações básicas
    if (dataStr.isEmpty || historico.isEmpty) {
      log('⚠️ Linha $lineIndex ignorada: data ou histórico vazio');
      return null;
    }

    // Ignorar linha "SALDO ANTERIOR"
    if (historico.toUpperCase().contains('SALDO ANTERIOR')) {
      return null;
    }

    // Parse data
    final data = _parseDate(dataStr);
    if (data == null) {
      log('⚠️ Linha $lineIndex ignorada: data inválida "$dataStr"');
      return null;
    }

    // Parse valor (crédito ou débito)
    double valor = 0.0;
    String tipo = 'despesa';

    if (creditoStr.isNotEmpty && creditoStr != '0,00') {
      valor = _parseValue(creditoStr);
      tipo = 'receita';
    } else if (debitoStr.isNotEmpty && debitoStr != '0,00') {
      valor = _parseValue(debitoStr);
      tipo = 'despesa';
    } else {
      log('⚠️ Linha $lineIndex ignorada: sem valor de crédito ou débito');
      return null;
    }

    // Criar transação
    return TransacaoImportada(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}_$lineIndex',
      data: data,
      descricao: historico,
      valor: valor.abs(),
      tipo: tipo,
      origem: 'Bradesco CSV',
      usuarioId: userId,
      contaId: contaId,
      cartaoId: cartaoId,
      faturaVencimento: faturaVencimento,
      efetivado: false,
      observacoes: documento.isNotEmpty ? 'Documento: $documento' : '',
      linhaBruta: line,
      indiceOriginal: lineIndex,
      metadados: {
        'banco': bankName,
        'bankId': bankId,
        'agencia': accountInfo?['agencia'] ?? '',
        'conta': accountInfo?['conta'] ?? '',
        'documento': documento,
        'saldo': saldoStr,
        'tipoImportacao': tipoImportacao,
      },
    );
  }

  /// Parse data no formato DD/MM/YYYY
  DateTime? _parseDate(String value) {
    try {
      // Remover espaços e BOM
      final cleaned = value.trim().replaceAll('\uFEFF', '');

      // Formato DD/MM/YYYY
      final match = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(cleaned);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);

        return DateTime(year, month, day);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse valor monetário brasileiro (formato: 1.234,56)
  double _parseValue(String value) {
    try {
      // Remover espaços, BOM, símbolo de moeda
      String cleaned = value.trim()
          .replaceAll('\uFEFF', '')
          .replaceAll('R\$', '')
          .replaceAll(' ', '');

      // Se vazio, retornar 0
      if (cleaned.isEmpty) return 0.0;

      // Trocar separadores: 1.234,56 → 1234.56
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');

      return double.parse(cleaned);
    } catch (e) {
      log('⚠️ Erro ao parsear valor "$value": $e');
      return 0.0;
    }
  }
}