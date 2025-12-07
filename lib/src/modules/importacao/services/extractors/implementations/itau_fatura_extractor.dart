// lib/src/modules/importacao/services/extractors/implementations/itau_fatura_extractor.dart

import 'dart:io';
import 'dart:developer';
import 'package:excel/excel.dart';
import '../base/bank_extractor.dart';
import '../../../models/transacao_importada_model.dart';
import '../../../../../auth_integration.dart';

/// Extractor para Fatura Excel Itaú
///
/// Implementa as regras específicas que funcionavam "100% bem" antes
/// para extrair transações de faturas Excel do cartão Itaú.
class ItauFaturaExtractor extends BankExtractor {
  @override
  String get bankId => 'itau_fatura';

  @override
  String get bankName => 'Itaú Fatura Excel';

  @override
  int get priority => 70;

  @override
  bool canHandle(String content, String fileName) {
    log('🏦 [ITAU] Verificando se pode processar: $fileName');

    // Verificar se é arquivo Excel ou CSV
    final name = fileName.toLowerCase();
    final isExcel = name.endsWith('.xlsx') || name.endsWith('.xls');
    final isCsv = name.endsWith('.csv');

    if (!isExcel && !isCsv) {
      log('❌ [ITAU] Não é arquivo Excel nem CSV');
      return false;
    }

    // Verificar se tem indicadores específicos de fatura Itaú
    final contentLower = content.toLowerCase();
    final hasItauFaturaIndicators =
      // Cabeçalho típico de fatura Itaú
      contentLower.contains('logotipo itaú') ||
      contentLower.contains('logotipo itau') ||
      // Estrutura típica da fatura
      (contentLower.contains('total da fatura anterior') &&
       contentLower.contains('lançamentos nacionais')) ||
      // Palavras-chave específicas de fatura
      (contentLower.contains('fatura') &&
       (contentLower.contains('itau') || contentLower.contains('itaú'))) ||
      // Formato típico de linha de transação
      contentLower.contains('pagamento efetuado') ||
      // Padrão de parcelas típico do Itaú
      RegExp(r'\d{2}/\d{2}/\d{4}.*?\d{2}/\d{2}').hasMatch(contentLower);

    if (hasItauFaturaIndicators) {
      log('✅ [ITAU] Arquivo ${isExcel ? "Excel" : "CSV"} com formato de fatura Itaú detectado');
      return true;
    }

    log('⚠️ [ITAU] Arquivo sem indicadores específicos de fatura Itaú');
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
    log('🏦 [ITAU] Iniciando processamento específico Itaú: ${file.path}');

    try {
      final fileName = file.path.split('/').last;
      String csvContent;

      // Detectar se é CSV ou Excel
      if (fileName.toLowerCase().endsWith('.csv')) {
        log('📋 [ITAU] Processando arquivo CSV');
        csvContent = content;
      } else {
        log('📊 [ITAU] Processando arquivo Excel');
        // Ler arquivo Excel diretamente
        final bytes = await file.readAsBytes();
        final excel = Excel.decodeBytes(bytes);

        if (excel.tables.isEmpty) {
          throw ExtractorException('Nenhuma planilha encontrada', bankId: bankId);
        }

        // Encontrar planilha com dados
        final sheetName = _findDataSheet(excel);
        if (sheetName == null) {
          throw ExtractorException('Nenhuma planilha com dados encontrada', bankId: bankId);
        }

        log('✅ [ITAU] Usando planilha: $sheetName');

        // Converter para CSV
        csvContent = _convertSheetToCSV(excel, sheetName);
      }

      // Processar com lógica específica Itaú
      return await _processItauFaturaCSV(
        csvContent,
        fileName,
        tipoImportacao: tipoImportacao,
        contaId: contaId,
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
      );

    } catch (e) {
      log('❌ [ITAU] Erro no processamento: $e');
      if (e is ExtractorException) rethrow;
      throw ExtractorException('Erro ao processar fatura Itaú: $e', bankId: bankId, originalError: e);
    }
  }

  /// Encontra planilha com dados (mesma lógica do ExcelExtractor)
  String? _findDataSheet(Excel excel) {
    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) continue;

      // Verificar se tem dados válidos
      for (final row in sheet.rows) {
        final hasData = row.any((cell) =>
          cell?.value != null && cell!.value.toString().trim().isNotEmpty
        );
        if (hasData) return sheetName;
      }
    }
    return null;
  }

  /// Converte planilha para CSV
  String _convertSheetToCSV(Excel excel, String sheetName) {
    final sheet = excel.tables[sheetName];
    if (sheet == null) return '';

    final csvLines = <String>[];
    for (final row in sheet.rows) {
      final csvCells = <String>[];
      for (final cell in row) {
        String cellValue = '';
        if (cell?.value != null) {
          cellValue = cell!.value.toString().trim();
          // Escapar vírgulas e aspas para CSV
          if (cellValue.contains(',') || cellValue.contains('"')) {
            cellValue = '"${cellValue.replaceAll('"', '""')}"';
          }
        }
        csvCells.add(cellValue);
      }

      if (csvCells.any((cell) => cell.isNotEmpty)) {
        csvLines.add(csvCells.join(','));
      }
    }
    return csvLines.join('\n');
  }

  /// Processa CSV com regras específicas do Itaú (baseado na lógica que funcionava antes)
  Future<List<TransacaoImportada>> _processItauFaturaCSV(
    String csvContent,
    String fileName, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) async {
    log('💳 [ITAU] Processando CSV específico Itaú Fatura');

    final transacoes = <TransacaoImportada>[];
    final userId = AuthIntegration.instance.authService.currentUser?.id ?? '';

    final lines = csvContent.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isEmpty) return transacoes;

    // Fatura Itaú usa ; como separador
    const separator = ';';

    log('📋 [ITAU] Analisando ${lines.length} linhas');

    // Processar cada linha buscando por transações
    for (int i = 0; i < lines.length; i++) {
      try {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(separator);
        if (parts.length < 4) continue;

        // Linha de transação tem formato: data;descrição;;valor
        // Exemplo: 29/10/2024;Expedia Do Brasil 09/12;;R$ 118,32
        final dataStr = parts[0].trim();
        final descricaoStr = parts[1].trim();
        final valorStr = parts.length > 3 ? parts[3].trim() : '';

        // Verificar se é linha de transação válida
        if (_isDateLike(dataStr) && descricaoStr.isNotEmpty && _isValueLike(valorStr)) {
          final transacao = _parseItauFaturaTransaction(
            dataStr,
            descricaoStr,
            valorStr,
            i,
            userId,
            fileName,
            contaId,
            cartaoId,
            faturaVencimento,
          );

          if (transacao != null) {
            transacoes.add(transacao);
            log('✅ [ITAU] Transação extraída: ${transacao.data} - ${transacao.descricao} - R\$ ${transacao.valor}');
          }
        }
      } catch (e) {
        log('⚠️ [ITAU] Erro linha $i: $e');
        continue;
      }
    }

    log('✅ [ITAU] Total de ${transacoes.length} transações processadas');
    return transacoes;
  }

  /// Parse específico para transação de fatura Itaú
  TransacaoImportada? _parseItauFaturaTransaction(
    String dataStr,
    String descricaoStr,
    String valorStr,
    int linha,
    String userId,
    String fileName,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  ) {
    try {
      // Parse da data (formato DD/MM/YYYY)
      final data = _parseDate(dataStr);
      if (data == null) return null;

      // Parse do valor (formato R$ 1.234,56)
      final valor = _parseValue(valorStr);
      if (valor == 0.0) return null;

      // Detectar informações de parcela na descrição
      final parcelaInfo = _detectParcelaInfo(descricaoStr);

      // Calcular data real da parcela se necessário
      DateTime dataFinal = data;
      if (parcelaInfo != null && parcelaInfo['atual']! > 1) {
        dataFinal = _calcularDataRealParcela(data, parcelaInfo['atual']!, parcelaInfo['total']!);
        log('🗓️ [ITAU] Data corrigida para parcela ${parcelaInfo['atual']}/${parcelaInfo['total']}: ${dataFinal.toString().substring(0, 10)}');
      }

      // Limpar descrição removendo info de parcela
      String descricaoLimpa = descricaoStr;
      if (parcelaInfo != null) {
        // Remover padrão XX/XX do final da descrição
        descricaoLimpa = descricaoStr.replaceAll(RegExp(r'\s*\d{1,2}/\d{1,2}\s*$'), '').trim();
      }

      return TransacaoImportada(
        id: '',
        usuarioId: userId,
        data: dataFinal,
        descricao: descricaoLimpa,
        valor: valor,
        tipo: valor > 0 ? 'receita' : 'despesa',
        origem: 'fatura_itau_csv',
        contaId: contaId,
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
        observacoes: parcelaInfo != null
            ? 'Parcela ${parcelaInfo['atual']}/${parcelaInfo['total']} - Data original: ${dataStr}'
            : '',
        linhaBruta: '$dataStr;$descricaoStr;;$valorStr',
        indiceOriginal: linha,
        metadados: {
          'banco': 'itau',
          'tipo_arquivo': 'fatura_csv',
          if (parcelaInfo != null) ...{
            'parcela_atual': parcelaInfo['atual'],
            'parcela_total': parcelaInfo['total'],
            'data_primeira_parcela': dataStr,
            'data_real_parcela': dataFinal.toString().substring(0, 10),
          },
          'faturaVencimento': faturaVencimento?.toString() ?? '',
        },
      );

    } catch (e) {
      log('❌ [ITAU] Erro ao processar transação linha $linha: $e');
      return null;
    }
  }

  /// Parse de data no formato DD/MM/YYYY
  DateTime? _parseDate(String dateStr) {
    try {
      final match = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(dateStr);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        return DateTime(year, month, day);
      }
    } catch (e) {
      log('❌ [ITAU] Erro ao converter data: $dateStr - $e');
    }
    return null;
  }

  /// Parse de valor brasileiro R$ 1.234,56
  double _parseValue(String valueStr) {
    try {
      // Remover R$, espaços e converter vírgula para ponto
      String cleaned = valueStr
          .replaceAll(RegExp(r'[R$\s]'), '')
          .replaceAll('.', '')
          .replaceAll(',', '.');

      // Se tem sinal negativo no início, manter
      if (valueStr.trim().startsWith('-')) {
        cleaned = '-$cleaned';
      }

      return double.parse(cleaned);
    } catch (e) {
      log('❌ [ITAU] Erro ao converter valor: $valueStr - $e');
      return 0.0;
    }
  }

  /// Verifica se string parece com data
  bool _isDateLike(String text) {
    return RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(text.trim());
  }

  /// Verifica se string parece com valor monetário
  bool _isValueLike(String text) {
    final cleaned = text.trim();
    return cleaned.startsWith('R\$') ||
           cleaned.startsWith('-R\$') ||
           RegExp(r'^-?\d+[.,]\d{2}$').hasMatch(cleaned);
  }

  /// Obsoleto - mantido para compatibilidade
  Map<String, int> _detectItauColumns(List<String> lines, String separator, int startLine) {
    return {};

    final sampleLines = lines.skip(startLine).take(3).toList();
    final columnCount = sampleLines[0].split(separator).length;
    final columnScores = <int, Map<String, int>>{};

    // Inicializar contadores
    for (int col = 0; col < columnCount; col++) {
      columnScores[col] = {'data': 0, 'valor': 0, 'texto': 0};
    }

    // Analisar amostras
    for (final line in sampleLines) {
      final parts = line.split(separator);
      for (int col = 0; col < parts.length && col < columnCount; col++) {
        final part = parts[col].trim();

        if (_isDateLike(part)) {
          columnScores[col]!['data'] = columnScores[col]!['data']! + 1;
        } else if (_isValueLike(part)) {
          columnScores[col]!['valor'] = columnScores[col]!['valor']! + 1;
        } else if (part.isNotEmpty && part.length > 3) {
          columnScores[col]!['texto'] = columnScores[col]!['texto']! + 1;
        }
      }
    }

    // Encontrar melhores colunas
    int dataCol = -1, valorCol = -1, descricaoCol = -1;
    int maxDataScore = 0, maxValorScore = 0;

    for (int col = 0; col < columnCount; col++) {
      final scores = columnScores[col]!;
      if (scores['data']! > maxDataScore) {
        maxDataScore = scores['data']!;
        dataCol = col;
      }
      if (scores['valor']! > maxValorScore) {
        maxValorScore = scores['valor']!;
        valorCol = col;
      }
    }

    // Para descrição, usar heurística (coluna com mais texto variado)
    descricaoCol = _findBestDescriptionColumn(sampleLines, separator, dataCol, valorCol);

    return {
      'data': dataCol,
      'valor': valorCol,
      'descricao': descricaoCol,
    };
  }

  /// Encontra melhor coluna para descrição
  int _findBestDescriptionColumn(List<String> sampleLines, String separator, int dataCol, int valorCol) {
    final columnCount = sampleLines[0].split(separator).length;
    int bestCol = -1;
    double bestScore = 0;

    for (int col = 0; col < columnCount; col++) {
      if (col == dataCol || col == valorCol) continue;

      double totalLength = 0;
      int textCount = 0;
      final uniqueValues = <String>{};

      for (final line in sampleLines) {
        final parts = line.split(separator);
        if (col < parts.length) {
          final text = parts[col].trim();
          if (text.isNotEmpty && !_isDateLike(text) && !_isValueLike(text)) {
            totalLength += text.length;
            textCount++;
            uniqueValues.add(text.toLowerCase());
          }
        }
      }

      if (textCount > 0) {
        final avgLength = totalLength / textCount;
        final variety = uniqueValues.length / textCount.clamp(1, 999);
        final score = avgLength * 0.6 + variety * 20;

        if (score > bestScore) {
          bestScore = score;
          bestCol = col;
        }
      }
    }

    return bestCol;
  }

  /// Parse de linha específica Itaú
  TransacaoImportada? _parseItauTransaction(
    String line,
    String separator,
    Map<String, int> columnMapping,
    int lineIndex,
    String userId,
    String fileName,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  ) {
    final parts = line.split(separator);
    if (parts.length < 3) return null;

    DateTime? data;
    String descricao = '';
    double valor = 0.0;

    // Usar mapeamento de colunas detectado
    final dataCol = columnMapping['data'] ?? -1;
    final descricaoCol = columnMapping['descricao'] ?? -1;
    final valorCol = columnMapping['valor'] ?? -1;

    if (dataCol >= 0 && dataCol < parts.length) {
      data = _parseItauDate(parts[dataCol].trim());
    }

    if (descricaoCol >= 0 && descricaoCol < parts.length) {
      descricao = parts[descricaoCol].trim();
    }

    if (valorCol >= 0 && valorCol < parts.length) {
      valor = _parseItauValue(parts[valorCol].trim());
    }

    // Fallback: varrer colunas se não detectou
    if (data == null || descricao.isEmpty || valor == 0.0) {
      for (int j = 0; j < parts.length && j < 10; j++) {
        final part = parts[j].trim();

        if (data == null && _isDateLike(part)) {
          data = _parseItauDate(part);
        }
        if (valor == 0.0 && _isValueLike(part)) {
          valor = _parseItauValue(part);
        }
        if (descricao.isEmpty && !_isDateLike(part) && !_isValueLike(part) && part.isNotEmpty) {
          descricao = part;
        }
      }
    }

    // Só criar transação se tem os dados essenciais
    if (data != null && descricao.isNotEmpty && valor != 0.0) {
      // REGRAS ESPECÍFICAS ITAÚ: Detectar parcelas e corrigir data
      final parcelaInfo = _detectParcelaInfo(descricao);
      DateTime dataFinal = data;
      String observacoesExtras = 'Importado de fatura Itaú: $fileName';
      Map<String, dynamic> metadadosExtras = {
        'banco': 'Itaú',
        'formatType': 'excel_fatura',
        'extractor': 'itau_fatura',
      };

      if (parcelaInfo != null) {
        // CORREÇÃO CRÍTICA: Calcular data real da parcela
        dataFinal = _calcularDataRealParcela(data, parcelaInfo['atual']!, parcelaInfo['total']!);
        observacoesExtras = 'Importado de fatura Itaú: $fileName - Parcela ${parcelaInfo['atual']}/${parcelaInfo['total']} (1ª parcela: ${_formatarData(data)})';
        metadadosExtras['parcela'] = parcelaInfo;
        metadadosExtras['dataPrimeiraParcela'] = data.toIso8601String();
        metadadosExtras['dataParcelaAtual'] = dataFinal.toIso8601String();

        log('📅 [ITAU] Parcela ${parcelaInfo['atual']}/${parcelaInfo['total']} | 1ª parcela: ${_formatarData(data)} → Parcela atual: ${_formatarData(dataFinal)}');
      }

      return TransacaoImportada(
        id: 'itau_${DateTime.now().millisecondsSinceEpoch}_$lineIndex',
        data: dataFinal, // Data corrigida para parcela atual
        descricao: descricao,
        valor: valor.abs(),
        tipo: 'despesa', // Fatura é sempre despesa
        origem: 'Itaú Excel',
        usuarioId: userId,
        contaId: contaId,
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
        efetivado: false,
        observacoes: observacoesExtras,
        linhaBruta: line,
        indiceOriginal: lineIndex,
        metadados: metadadosExtras,
      );
    }

    return null;
  }

  /// Parse de data específico Itaú (DD/MM/YYYY típico)
  DateTime? _parseItauDate(String text) {
    try {
      // DD/MM/YYYY (padrão Itaú)
      if (RegExp(r'\d{1,2}/\d{1,2}/\d{4}').hasMatch(text)) {
        final parts = text.split('/');
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }

      // DD-MM-YYYY
      if (RegExp(r'\d{1,2}-\d{1,2}-\d{4}').hasMatch(text)) {
        final parts = text.split('-');
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse de valor específico Itaú (R$ formato brasileiro)
  double _parseItauValue(String text) {
    try {
      String cleaned = text
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll(RegExp(r'[()]+'), '')
          .trim();

      // Detectar negativo
      bool isNegative = cleaned.startsWith('-');
      cleaned = cleaned.replaceAll('-', '');

      // Formato brasileiro: R$ 1.000,50
      if (cleaned.contains(',') && cleaned.contains('.')) {
        final lastComma = cleaned.lastIndexOf(',');
        final lastDot = cleaned.lastIndexOf('.');

        if (lastComma > lastDot) {
          // 1.000,50 (padrão brasileiro Itaú)
          cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // 1,000.50
          cleaned = cleaned.replaceAll(',', '');
        }
      } else if (cleaned.contains(',')) {
        // Apenas vírgula - assumir decimal brasileiro
        cleaned = cleaned.replaceAll(',', '.');
      }

      double value = double.parse(cleaned);
      return isNegative ? -value : value;
    } catch (e) {
      return 0.0;
    }
  }

  // Métodos duplicados removidos - usar as versões da linha 344 e 349

  /// Detecta informações de parcela na descrição (padrão Itaú: \d{1,2}/\d{1,2})
  /// Exemplo: "Expedia Do Brasil 09/12" → {atual: 9, total: 12}
  /// Exemplo: "180Seguros10/12" → {atual: 10, total: 12}
  Map<String, int>? _detectParcelaInfo(String descricao) {
    final parcelaMatch = RegExp(r'\s*(\d{1,2})/(\d{1,2})\s*$').firstMatch(descricao);

    if (parcelaMatch != null) {
      final parcelaAtual = int.tryParse(parcelaMatch.group(1) ?? '');
      final totalParcelas = int.tryParse(parcelaMatch.group(2) ?? '');

      if (parcelaAtual != null && totalParcelas != null &&
          parcelaAtual > 0 && parcelaAtual <= totalParcelas) {
        log('🔢 [ITAU] Parcela detectada: $parcelaAtual/$totalParcelas em "$descricao"');
        return {
          'atual': parcelaAtual,
          'total': totalParcelas,
        };
      }
    }

    return null;
  }

  /// Calcula a data real da parcela atual
  /// PROBLEMA: Itaú mostra data da 1ª parcela em todas as linhas
  /// SOLUÇÃO: Data Real = Data 1ª Parcela + (Parcela Atual - 1) meses
  DateTime _calcularDataRealParcela(DateTime dataPrimeiraParcela, int parcelaAtual, int totalParcelas) {
    if (parcelaAtual <= 1 || parcelaAtual > totalParcelas) {
      return dataPrimeiraParcela; // Se é a primeira ou inválida, manter original
    }

    // Calcular quantos meses avançar
    final mesesParaAvancar = parcelaAtual - 1;

    // Criar nova data avançando os meses
    final dataCalculada = DateTime(
      dataPrimeiraParcela.year,
      dataPrimeiraParcela.month + mesesParaAvancar,
      dataPrimeiraParcela.day,
    );

    return dataCalculada;
  }

  /// Formata data para exibição (DD/MM/YYYY)
  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}