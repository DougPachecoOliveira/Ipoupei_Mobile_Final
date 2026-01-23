// 🚀 Importação Service - iPoupei Mobile v4 - PDF AVANÇADO
//
// Service completo para importação de extratos bancários
// Usa JS Engine para parsing + TransacaoService existente para salvar
// Suporte a todos os bancos e formatos do iPoupei Web
//
// Baseado em: flutter_js + TransacaoService existente

import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:excel/excel.dart';
import '../models/transacao_importada_model.dart';
import '../../transacoes/services/transacao_service.dart';
import 'conectcar_extractor.dart';
// import 'enhanced_excel_extractor.dart'; // Temporariamente desabilitado devido a problema com tipo Cell
import '../../../auth_integration.dart';
import '../../../database/local_database.dart';
import 'extractors/factory/extractor_factory.dart';
import 'extractors/base/bank_extractor.dart';
import '../../cartoes/services/cartao_data_service.dart';
import '../../cartoes/services/fatura_service.dart';
import '../../../sync/sync_manager.dart';
import '../../shared/validators/business_validators.dart';

/// Service completo para importação de transações de extratos bancários
class ImportacaoService {
  static final ImportacaoService _instance = ImportacaoService._internal();
  static ImportacaoService get instance => _instance;
  ImportacaoService._internal();

  JavascriptRuntime? _jsEngine;
  bool _jsEngineInitialized = false;

  final _transacaoService = TransacaoService.instance;
  final _authIntegration = AuthIntegration.instance;


  /// Inicializa o JS Engine com os parsers
  Future<void> _initializeJSEngine() async {
    if (_jsEngineInitialized) return;

    try {
      log('🚀 Inicializando JS Engine para importação...');

      _jsEngine = getJavascriptRuntime();

      // Carregar scripts de parsing na ordem correta (dependências primeiro)
      final utilsJS = await rootBundle.loadString('assets/js/parseUtils.js');
      final bankConfigsJS = await rootBundle.loadString('assets/js/bankConfigs.js');
      final bankDetectorJS = await rootBundle.loadString('assets/js/bankDetector.js');
      final csvExtractorJS = await rootBundle.loadString('assets/js/csvExtractor.js');
      final pdfExtractorJS = await rootBundle.loadString('assets/js/pdfExtractor.js');
      final ofxExtractorJS = await rootBundle.loadString('assets/js/ofxExtractor.js');

      // Executar scripts no engine na ordem correta
      _jsEngine!.evaluate(utilsJS);
      _jsEngine!.evaluate(bankConfigsJS);
      _jsEngine!.evaluate(bankDetectorJS);
      _jsEngine!.evaluate(csvExtractorJS);
      _jsEngine!.evaluate(pdfExtractorJS);
      _jsEngine!.evaluate(ofxExtractorJS);

      _jsEngineInitialized = true;
      log('✅ JS Engine inicializado com sucesso');

    } catch (e) {
      log('❌ Erro ao inicializar JS Engine: $e');
      rethrow;
    }
  }

  /// Detecta o formato do arquivo e retorna informações do banco
  Future<Map<String, dynamic>> detectarFormatoArquivo(File file) async {
    await _initializeJSEngine();

    try {
      final content = await file.readAsString();
      final fileName = file.path.split('/').last.toLowerCase();

      final result = _jsEngine!.evaluate('''
        (function() {
          try {
            // Detectar formato usando os mesmos algoritmos do web
            var detection = BankDetector.detectFormat('$fileName', `$content`);
            return JSON.stringify(detection);
          } catch (e) {
            return JSON.stringify({
              error: e.message,
              bankName: 'Genérico',
              formatType: 'csv',
              confidence: 0.5
            });
          }
        })()
      ''');

      return jsonDecode(result.stringResult);

    } catch (e) {
      log('❌ Erro na detecção de formato: $e');
      // Retorna formato genérico em caso de erro
      return {
        'bankName': 'Genérico',
        'formatType': 'csv',
        'confidence': 0.5,
        'separator': ',',
        'hasHeader': true
      };
    }
  }

  /// Processa arquivo CSV/TXT e retorna lista de transações
  Future<List<TransacaoImportada>> processarArquivoCSV(
    File file, {
    required String tipoImportacao, // 'conta' ou 'cartao'
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) async {
    try {
      log('🚀 INICIANDO PROCESSAMENTO CSV: ${file.path}');
      log('📊 Contexto: tipo=$tipoImportacao, conta=$contaId, cartao=$cartaoId');

      await _initializeJSEngine();

      final content = await file.readAsString();
      final fileName = file.path.split('/').last;

      log('📄 Arquivo lido: ${content.length} caracteres');
      log('📄 Primeiras 200 chars: ${content.substring(0, content.length > 200 ? 200 : content.length)}');

      // ✨ NOVA LÓGICA: Usar ExtractorFactory para detectar banco específico
      log('🔍 Detectando banco específico...');
      final extractor = ExtractorFactory.detectExtractor(content, fileName);
      log('🏦 Usando extractor: ${extractor.bankName} (${extractor.bankId})');

      // Se for GenericExtractor, usar lógica legada diretamente
      // (evita recursão infinita)
      if (extractor.bankId == 'generic') {
        log('⚠️ Usando processamento legado (sem extractor específico)');
        return await _parseCSVSimples(
          content,
          fileName,
          tipoImportacao,
          contaId,
          cartaoId,
          faturaVencimento,
        );
      }

      // Usar extractor específico
      try {
        final transacoes = await extractor.extract(
          file,
          content,
          tipoImportacao: tipoImportacao,
          contaId: contaId,
          cartaoId: cartaoId,
          faturaVencimento: faturaVencimento,
        );

        log('✅ CSV processado via ${extractor.bankName}: ${transacoes.length} transações');
        return transacoes;

      } catch (e) {
        if (e is ExtractorException) {
          log('❌ Erro no extractor ${extractor.bankName}: $e');
          // Se extractor específico falhar, tentar fallback
          log('🔄 Tentando fallback para método legado...');
          return await _parseCSVSimples(
            content,
            fileName,
            tipoImportacao,
            contaId,
            cartaoId,
            faturaVencimento,
          );
        }
        rethrow;
      }

      // CÓDIGO LEGADO ABAIXO (será usado apenas como fallback)
      // TODO: Remover após validação completa dos extractors

      // Contexto de importação para o JS (LEGACY)
      final context = jsonEncode({
        'tipoImportacao': tipoImportacao,
        'contaId': contaId ?? '',
        'cartaoId': cartaoId ?? '',
        'faturaVencimento': faturaVencimento?.toIso8601String() ?? '',
      });

      log('📋 Contexto JS: $context');

      // Executar parsing no JS Engine (IGUAL AO REACT)
      final result = _jsEngine!.evaluate('''
        (function() {
          try {
            console.log('🚀 JS Engine: Iniciando processamento CSV');

            var extractor = new CSVExtractor();
            console.log('✅ JS Engine: CSVExtractor criado');

            var rawData = extractor.extract('$fileName', `$content`);
            console.log('✅ JS Engine: Dados extraídos:', rawData.analysis);

            var transactions = extractor.parseTransactions(rawData, $context);
            console.log('✅ JS Engine: Transações processadas:', transactions.length);

            return JSON.stringify({
              success: true,
              transactions: transactions,
              metadata: {
                totalProcessed: transactions.length,
                bankDetected: rawData.analysis?.formatType || 'generic',
                separator: rawData.analysis?.separator || ','
              }
            });
          } catch (e) {
            console.error('❌ JS Engine: Erro detalhado:', e.message);
            console.error('❌ JS Engine: Stack:', e.stack);
            return JSON.stringify({
              success: false,
              error: e.message,
              stack: e.stack,
              transactions: []
            });
          }
        })()
      ''');

      log('📋 Resultado JS: ${result.stringResult}');

      final parsedResult = jsonDecode(result.stringResult);

      if (!parsedResult['success']) {
        log('❌ Erro no parsing JS: ${parsedResult['error']}');
        log('❌ Stack: ${parsedResult['stack']}');
        throw Exception('Erro no parsing: ${parsedResult['error']}');
      }

      final transactionsList = parsedResult['transactions'] as List;
      final userId = _authIntegration.authService.currentUser?.id ?? '';

      log('🔄 Convertendo ${transactionsList.length} transações para modelo Dart');

      // Converter para modelo Dart
      final transacoes = transactionsList.map((t) {
        return TransacaoImportada(
          id: t['id']?.toString() ?? '',
          data: _safeDateParse(t['data']),
          descricao: t['descricao'] ?? '',
          valor: (t['valor'] ?? 0.0).toDouble(),
          tipo: t['tipo'] ?? 'despesa',
          origem: t['origem'] ?? 'CSV',
          usuarioId: userId,
          contaId: t['conta_id'],
          cartaoId: t['cartao_id'],
          faturaVencimento: t['fatura_vencimento'] != null
              ? _safeDateParse(t['fatura_vencimento'])
              : null,
          efetivado: t['efetivado'] ?? false,
          observacoes: t['observacoes'] ?? '',
          linhaBruta: t['linhaBruta'] ?? '',
          indiceOriginal: t['indiceOriginal'] ?? 0,
          metadados: Map<String, dynamic>.from(t['metadados'] ?? {}),
        );
      }).toList();

      log('✅ CSV processado com sucesso: ${transacoes.length} transações');
      return transacoes;

    } catch (e) {
      log('❌ Erro no processamento CSV: $e');
      rethrow;
    }
  }

  /// Parser CSV simples para formatos comuns (público para GenericExtractor)
  Future<List<TransacaoImportada>> parseCSVSimples(
    String content,
    String fileName,
    String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  ) async {
    return await _parseCSVSimples(content, fileName, tipoImportacao, contaId, cartaoId, faturaVencimento);
  }

  /// Parser CSV simples para formatos comuns (interno)
  Future<List<TransacaoImportada>> _parseCSVSimples(
    String content,
    String fileName,
    String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  ) async {
    final transacoes = <TransacaoImportada>[];
    final userId = _authIntegration.authService.currentUser?.id ?? '';

    try {
      final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (lines.isEmpty) return transacoes;

      // Detectar separador (incluindo TAB para Bradesco)
      String separator = ',';
      if (content.contains('\t') && content.split('\t').length > content.split(',').length) {
        separator = '\t';
        log('📋 Separador TAB detectado (formato Bradesco)');
      } else if (content.contains(';')) {
        separator = ';';
      }

      // Detecção automática de padrão analisando as primeiras linhas
      int startLine = 0;
      int dataCol = -1, descricaoCol = -1, valorCol = -1;

      // Verificar se tem header
      final firstLine = lines[0];
      final firstLineParts = firstLine.split(separator);
      bool hasHeader = false;

      // Se a primeira linha não tem padrão de data/valor, provavelmente é header
      if (firstLineParts.length >= 3) {
        final hasDatePattern = firstLineParts.any((part) => _isDateLike(part.trim()));
        final hasValuePattern = firstLineParts.any((part) => _isValueLike(part.trim()));

        if (!hasDatePattern && !hasValuePattern) {
          hasHeader = true;
          startLine = 1;
          log('📋 Header detectado: ${firstLineParts.join(" | ")}');
        }
      }

      // Detectar automaticamente analisando algumas linhas de dados
      if (lines.length > startLine) {
        final sampleLines = lines.skip(startLine).take(3).toList();
        final columnAnalysis = _analyzeColumnPatterns(sampleLines, separator);

        dataCol = columnAnalysis['dataCol'] ?? -1;
        valorCol = columnAnalysis['valorCol'] ?? -1;
        descricaoCol = columnAnalysis['descricaoCol'] ?? -1;

        log('🔍 Padrão detectado automaticamente: data=$dataCol, valor=$valorCol, descrição=$descricaoCol');
      }

      for (int i = startLine; i < lines.length; i++) {
        try {
          final parts = lines[i].split(separator);
          if (parts.length < 3) continue;

          DateTime? data;
          String descricao = '';
          double valor = 0.0;

          // Se temos mapeamento do header, usar ele
          if (dataCol >= 0 && dataCol < parts.length) {
            data = _parseDate(parts[dataCol].trim());
          }

          if (descricaoCol >= 0 && descricaoCol < parts.length) {
            descricao = parts[descricaoCol].trim();
          }

          if (valorCol >= 0 && valorCol < parts.length) {
            valor = _parseValue(parts[valorCol].trim());
          }

          // Detectar formato Bradesco (Crédito/Débito separados)
          if (valor == 0.0 && parts.length >= 5) {
            valor = _parseBradescoValues(parts);
          }

          // Fallback: detectar por conteúdo se não conseguiu pelo header
          if (data == null || descricao.isEmpty || valor == 0.0) {
            for (int j = 0; j < parts.length && j < 10; j++) {
              final part = parts[j].trim();

              if (data == null && _isDateLike(part)) {
                data = _parseDate(part);
              }

              if (valor == 0.0 && _isValueLike(part)) {
                valor = _parseValue(part);
              }

              if (descricao.isEmpty && !_isDateLike(part) && !_isValueLike(part) && part.isNotEmpty) {
                descricao = part;
              }
            }
          }

          if (data != null && descricao.isNotEmpty && valor != 0.0) {
            // Determinar tipo (receita/despesa) baseado no valor
            String tipo = valor > 0 ? 'receita' : 'despesa';
            valor = valor.abs(); // Valor sempre positivo

            final transacao = TransacaoImportada(
              id: 'temp_${DateTime.now().millisecondsSinceEpoch}_$i',
              data: data,
              descricao: descricao,
              valor: valor,
              tipo: tipo,
              origem: 'CSV',
              usuarioId: userId,
              contaId: contaId,
              cartaoId: cartaoId,
              faturaVencimento: faturaVencimento,
              efetivado: false,
              observacoes: 'Importado de $fileName',
              linhaBruta: lines[i],
              indiceOriginal: i,
              metadados: {'banco': 'Detectado automaticamente'},
            );

            transacoes.add(transacao);
          }
        } catch (e) {
          log('Erro ao processar linha $i: $e');
          continue;
        }
      }

      return transacoes;
    } catch (e) {
      log('❌ Erro no parser simples: $e');
      return [];
    }
  }

  /// Fallback para JS Engine
  Future<List<TransacaoImportada>> _processarComJSEngine(
    File file,
    String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  ) async {
    await _initializeJSEngine();

    try {
      final content = await file.readAsString();
      final fileName = file.path.split('/').last;

      // Contexto de importação para o JS
      final context = jsonEncode({
        'tipoImportacao': tipoImportacao,
        'contaId': contaId ?? '',
        'cartaoId': cartaoId ?? '',
        'faturaVencimento': faturaVencimento?.toIso8601String() ?? '',
      });

      // Executar parsing no JS Engine
      final result = _jsEngine!.evaluate('''
        (function() {
          try {
            // Usar os mesmos parsers do projeto web (CORRIGIDO!)
            var extractor = new CSVExtractor();
            var rawData = extractor.extract('$fileName', `$content`);
            var transactions = extractor.parseTransactions(rawData, $context);

            return JSON.stringify({
              success: true,
              transactions: transactions,
              metadata: {
                totalProcessed: transactions.length,
                bankDetected: rawData.analysis?.formatType || 'generic'
              }
            });
          } catch (e) {
            console.error('❌ Erro no JS Engine:', e.message, e.stack);
            return JSON.stringify({
              success: false,
              error: e.message,
              stack: e.stack,
              transactions: []
            });
          }
        })()
      ''');

      final parsedResult = jsonDecode(result.stringResult);

      if (!parsedResult['success']) {
        throw Exception('Erro no parsing: ${parsedResult['error']}');
      }

      final transactionsList = parsedResult['transactions'] as List;
      final userId = _authIntegration.authService.currentUser?.id ?? '';

      // Converter para modelo Dart
      final transacoes = transactionsList.map((t) {
        return TransacaoImportada(
          id: t['id']?.toString() ?? '',
          data: _safeDateParse(t['data']),
          descricao: t['descricao'] ?? '',
          valor: (t['valor'] ?? 0.0).toDouble(),
          tipo: t['tipo'] ?? 'despesa',
          origem: t['origem'] ?? 'CSV',
          usuarioId: userId,
          contaId: t['conta_id'],
          cartaoId: t['cartao_id'],
          faturaVencimento: t['fatura_vencimento'] != null
              ? _safeDateParse(t['fatura_vencimento'])
              : null,
          efetivado: t['efetivado'] ?? false,
          observacoes: t['observacoes'] ?? '',
          linhaBruta: t['linhaBruta'] ?? '',
          indiceOriginal: t['indiceOriginal'] ?? 0,
          metadados: Map<String, dynamic>.from(t['metadados'] ?? {}),
        );
      }).toList();

      log('✅ Processamento JS concluído: ${transacoes.length} transações');
      return transacoes;

    } catch (e) {
      log('❌ Erro no processamento JS: $e');
      rethrow;
    }
  }

  /// Verifica se o texto parece uma data
  bool _isDateLike(String text) {
    final datePatterns = [
      RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{4}'),  // DD/MM/YYYY ou DD-MM-YYYY
      RegExp(r'\d{4}[/-]\d{1,2}[/-]\d{1,2}'),  // YYYY-MM-DD
      RegExp(r'\d{1,2}\.\d{1,2}\.\d{4}'),      // DD.MM.YYYY
    ];

    return datePatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Verifica se o texto parece um valor monetário
  bool _isValueLike(String text) {
    final cleanText = text.replaceAll(RegExp(r'[R$\s]'), '').replaceAll(' ', '');
    return RegExp(r'^-?\d+[,.]?\d*$').hasMatch(cleanText);
  }

  /// Parse de data flexível
  DateTime? _parseDate(String text) {
    try {
      // DD/MM/YYYY
      if (RegExp(r'\d{1,2}/\d{1,2}/\d{4}').hasMatch(text)) {
        final parts = text.split('/');
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }

      // DD-MM-YYYY
      if (RegExp(r'\d{1,2}-\d{1,2}-\d{4}').hasMatch(text)) {
        final parts = text.split('-');
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }

      // YYYY-MM-DD
      if (RegExp(r'\d{4}-\d{1,2}-\d{1,2}').hasMatch(text)) {
        return DateTime.parse(text);
      }

      // DD.MM.YYYY
      if (RegExp(r'\d{1,2}\.\d{1,2}\.\d{4}').hasMatch(text)) {
        final parts = text.split('.');
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse de valor monetário flexível
  double _parseValue(String text) {
    try {
      String cleaned = text
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll(RegExp(r'[()]+'), '')
          .trim();

      // Detectar sinal negativo
      bool isNegative = cleaned.startsWith('-');
      cleaned = cleaned.replaceAll('-', '');

      // Se tem vírgula e ponto, assumir formato brasileiro
      if (cleaned.contains(',') && cleaned.contains('.')) {
        final lastComma = cleaned.lastIndexOf(',');
        final lastDot = cleaned.lastIndexOf('.');

        if (lastComma > lastDot) {
          // 1.000,50 (brasileiro)
          cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // 1,000.50 (americano)
          cleaned = cleaned.replaceAll(',', '');
        }
      } else if (cleaned.contains(',')) {
        // Apenas vírgula - assumir decimal se 2 dígitos depois
        final parts = cleaned.split(',');
        if (parts.length == 2 && parts[1].length <= 2) {
          cleaned = cleaned.replaceAll(',', '.');
        } else {
          cleaned = cleaned.replaceAll(',', '');
        }
      }

      double value = double.parse(cleaned);
      return isNegative ? -value : value;
    } catch (e) {
      return 0.0;
    }
  }

  /// Parse de valor de resultado JavaScript
  double _parseDoubleFromJS(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  /// Processa arquivo OFX (Open Financial Exchange)
  Future<List<TransacaoImportada>> processarArquivoOFX(
    File file, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) async {
    await _initializeJSEngine();

    try {
      log('📄 Processando OFX: ${file.path}');

      final content = await file.readAsString();
      final fileName = file.path.split('/').last;

      final context = jsonEncode({
        'tipoImportacao': tipoImportacao,
        'contaId': contaId ?? '',
        'cartaoId': cartaoId ?? '',
        'faturaVencimento': faturaVencimento?.toIso8601String() ?? '',
      });

      // Usar OFXExtractor implementado
      final result = _jsEngine!.evaluate('''
        (function() {
          try {
            var extractor = new OFXExtractor();
            var rawData = extractor.extract('$fileName', `$content`);
            var transactions = extractor.parseTransactions(rawData, $context);

            return JSON.stringify({
              success: true,
              transactions: transactions,
              metadata: {
                totalProcessed: transactions.length,
                accountType: rawData.analysis.accountType || 'UNKNOWN'
              }
            });
          } catch (e) {
            return JSON.stringify({
              success: false,
              error: e.message,
              transactions: []
            });
          }
        })()
      ''');

      final parsedResult = jsonDecode(result.stringResult);

      if (!parsedResult['success']) {
        throw Exception('Erro no parsing OFX: ${parsedResult['error']}');
      }

      // Converter para modelo Dart (mesmo código do CSV/PDF)
      final transactionsList = parsedResult['transactions'] as List;
      final userId = _authIntegration.authService.currentUser?.id ?? '';

      final transacoes = transactionsList.map((t) {
        return TransacaoImportada(
          id: t['id']?.toString() ?? '',
          data: _safeDateParse(t['data']),
          descricao: t['descricao'] ?? '',
          valor: (t['valor'] ?? 0.0).toDouble(),
          tipo: t['tipo'] ?? 'despesa',
          origem: t['origem'] ?? 'OFX',
          usuarioId: userId,
          contaId: t['conta_id'],
          cartaoId: t['cartao_id'],
          faturaVencimento: t['fatura_vencimento'] != null
              ? _safeDateParse(t['fatura_vencimento'])
              : null,
          efetivado: t['efetivado'] ?? false,
          observacoes: t['observacoes'] ?? '',
          linhaBruta: t['linhaBruta'] ?? '',
          indiceOriginal: t['indiceOriginal'] ?? 0,
          metadados: Map<String, dynamic>.from(t['metadados'] ?? {}),
        );
      }).toList();

      log('✅ OFX processado: ${transacoes.length} transações');
      return transacoes;

    } catch (e) {
      log('❌ Erro no processamento OFX: $e');
      rethrow;
    }
  }

  /// Processa arquivo Excel/XLSX com extrator robusto
  Future<List<TransacaoImportada>> processarArquivoExcel(
    File file, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) async {
    try {
      log('📊 INICIANDO PROCESSAMENTO EXCEL: ${file.path}');
      log('📋 Contexto: tipo=$tipoImportacao, conta=$contaId, cartao=$cartaoId');

      final fileName = file.path.split('/').last;

      // ✨ NOVA LÓGICA: Usar ExtractorFactory para detectar banco específico
      // O ExcelExtractor será detectado primeiro por ter prioridade alta (90)
      log('🔍 Detectando extractor para arquivo Excel...');
      final extractor = ExtractorFactory.detectExtractor('', fileName);
      log('🏦 Usando extractor: ${extractor.bankName} (${extractor.bankId})');

      // Usar extractor detectado
      final transacoes = await extractor.extract(
        file,
        '', // ExcelExtractor lê o arquivo diretamente
        tipoImportacao: tipoImportacao,
        contaId: contaId,
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
      );

      log('✅ Excel processado via ${extractor.bankName}: ${transacoes.length} transações');
      return transacoes;

    } catch (e) {
      log('❌ Erro no processamento Excel: $e');
      rethrow;
    }
  }

  /// Processa arquivo PDF (extrato/fatura) usando JavaScript extractor avançado
  Future<List<TransacaoImportada>> processarArquivoPDF(
    File file, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) async {
    try {
      final filePath = file.path;
      log('🚀 Iniciando processamento PDF: ${file.path}');

      // MODO DIRETO: Pular JS Engine e usar APENAS parser Dart que funciona
      log('🔧 [PDF_DIRECT] Usando parser Dart direto (sem JS Engine)');

      // Extrair texto real do PDF
      log('📄 Extraindo texto do PDF: $filePath');
      String pdfText;
      try {
        pdfText = await ReadPdfText.getPDFtext(filePath);
        if (pdfText.isEmpty) {
          throw Exception('Não foi possível extrair texto do PDF');
        }
      } catch (e) {
        log('💥 [PDF_DEBUG] ERRO CRÍTICO ao extrair texto: ${e.runtimeType} - ${e.toString()}');
        if (e.toString().contains('Pointer') || e.toString().contains('length')) {
          log('🔧 [PDF_DEBUG] Erro de Pointer detectado - tentando fallback');
          throw Exception('Erro na biblioteca PDF (Pointer issue). Tente converter o PDF para outro formato.');
        }
        rethrow;
      }

      log('📄 Texto extraído do PDF (${pdfText.length} chars)');
      log('📝 Primeiros 300 chars: ${pdfText.substring(0, pdfText.length > 300 ? 300 : pdfText.length)}');

      final fileName = file.path.split('/').last;

      // Usar APENAS parser Dart (que funciona perfeitamente)
      log('⚡ [PDF_DIRECT] Usando parser Dart exclusivo...');
      return _parseTextToTransactions(
        pdfText,
        fileName,
        tipoImportacao: tipoImportacao,
        contaId: contaId,
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
      );

    } catch (e) {
      log('❌ Erro no processamento PDF: $e');
      rethrow;
    }
  }

  /// Analisa texto extraído do PDF para encontrar transações
  List<TransacaoImportada> _parseTextToTransactions(
    String pdfText,
    String fileName, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) {
    final transacoes = <TransacaoImportada>[];
    final lines = pdfText.split('\n');
    final userId = _authIntegration.authService.currentUser?.id ?? '';
    int transactionIndex = 0;

    log('🔍 Analisando ${lines.length} linhas do PDF');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Buscar padrões de transação comuns em PDFs de extrato/fatura
      final transactionData = _extractTransactionFromPDFLine(line);

      if (transactionData != null) {
        final transacao = TransacaoImportada(
          id: 'pdf_${DateTime.now().millisecondsSinceEpoch}_${transactionIndex++}',
          data: transactionData['data'] as DateTime,
          descricao: transactionData['descricao'] as String,
          valor: (transactionData['valor'] as double).abs(),
          tipo: (transactionData['valor'] as double) >= 0 ? 'receita' : 'despesa',
          origem: 'PDF',
          usuarioId: userId,
          contaId: contaId,
          cartaoId: cartaoId,
          faturaVencimento: faturaVencimento,
          efetivado: false,
          observacoes: 'Importado de PDF: $fileName',
          linhaBruta: line,
          indiceOriginal: i,
          metadados: {
            'banco': 'PDF Import',
            'formatType': 'pdf',
            'linha': i + 1,
            'fileName': fileName,
          },
        );

        transacoes.add(transacao);
        log('✅ Transação extraída: ${transactionData['descricao']} - R\$ ${transactionData['valor']}');
      }
    }

    return transacoes;
  }

  /// Extrai dados de transação de uma linha de PDF - VERSÃO NUBANK ESPECÍFICA
  Map<String, dynamic>? _extractTransactionFromPDFLine(String line) {
    // PADRÃO ESPECÍFICO NUBANK que sabemos que funciona:
    // "09 MAR 2025 Total de saídas Transferência enviada pelo Pix - 30,00"

    log('🔍 Testando linha: "$line"');

    // Padrão Nubank: DD MMM YYYY DESCRIÇÃO - VALOR
    final nubankPattern = RegExp(r'(\d{1,2})\s+(JAN|FEV|MAR|ABR|MAI|JUN|JUL|AGO|SET|OUT|NOV|DEZ)\s+(\d{4})\s+(.+?)\s+-\s+(\d+[.,]\d{2})');
    final nubankMatch = nubankPattern.firstMatch(line);

    if (nubankMatch != null) {
      try {
        final dia = int.parse(nubankMatch.group(1)!);
        final mesStr = nubankMatch.group(2)!;
        final ano = int.parse(nubankMatch.group(3)!);
        final descricao = nubankMatch.group(4)!.trim();
        final valorStr = nubankMatch.group(5)!.replaceAll(',', '.');

        // Mapear mês
        final meses = {
          'JAN': 1, 'FEV': 2, 'MAR': 3, 'ABR': 4, 'MAI': 5, 'JUN': 6,
          'JUL': 7, 'AGO': 8, 'SET': 9, 'OUT': 10, 'NOV': 11, 'DEZ': 12
        };

        final mes = meses[mesStr] ?? 3; // Default março
        final data = DateTime(ano, mes, dia);
        final valor = double.parse(valorStr) * -1; // Nubank usa - para despesa

        log('✅ Match Nubank: data=$dia/$mes/$ano, desc="$descricao", valor=$valor');

        return {
          'data': data,
          'descricao': descricao,
          'valor': valor,
        };
      } catch (e) {
        log('⚠️ Erro parse Nubank: $e');
      }
    }

    // Fallback: padrões genéricos
    final patterns = [
      // DD/MM/YYYY DESCRIÇÃO VALOR
      RegExp(r'(\d{2}/\d{2}/\d{4})\s+(.+?)\s+([-+]?\d+[.,]\d{2})\s*$'),
      // DD/MM DESCRIÇÃO VALOR (ano implícito)
      RegExp(r'(\d{2}/\d{2})\s+(.+?)\s+([-+]?\d+[.,]\d{2})\s*$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        try {
          String dataStr, descricao, valorStr;

          dataStr = match.group(1)!;
          descricao = match.group(2)!.trim();
          valorStr = match.group(3)!;

          // Processar data
          DateTime data;
          try {
            if (dataStr.length == 5) { // DD/MM
              final now = DateTime.now();
              final parts = dataStr.split('/');
              data = DateTime(now.year, int.parse(parts[1]), int.parse(parts[0]));
            } else { // DD/MM/YYYY
              final parts = dataStr.split('/');
              data = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            }
          } catch (e) {
            data = DateTime.now();
          }

          // Processar valor
          final valor = _parseValue(valorStr);

          if (descricao.isNotEmpty && valor != 0) {
            return {
              'data': data,
              'descricao': descricao,
              'valor': valor,
            };
          }
        } catch (e) {
          // Continuar tentando outros padrões
          continue;
        }
      }
    }

    return null;
  }

  /// Analisa padrões de colunas em algumas linhas de exemplo
  Map<String, int> _analyzeColumnPatterns(List<String> sampleLines, String separator) {
    if (sampleLines.isEmpty) return {};

    final columnCount = sampleLines[0].split(separator).length;
    final columnScores = <int, Map<String, int>>{};

    // Inicializar contadores para cada coluna
    for (int col = 0; col < columnCount; col++) {
      columnScores[col] = {'data': 0, 'valor': 0, 'texto': 0};
    }

    // Analisar cada linha de exemplo
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

    // Encontrar a melhor coluna para cada tipo
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

    // Para descrição, usar lógica mais inteligente
    descricaoCol = _findBestDescriptionColumn(sampleLines, separator, dataCol, valorCol);

    log('📊 Análise de colunas:');
    for (int col = 0; col < columnCount; col++) {
      final scores = columnScores[col]!;
      log('   Coluna $col: data=${scores['data']}, valor=${scores['valor']}, texto=${scores['texto']}');
    }

    return {
      'dataCol': dataCol,
      'valorCol': valorCol,
      'descricaoCol': descricaoCol,
    };
  }

  /// Processa valores específicos do formato Bradesco (Crédito/Débito separados)
  double _parseBradescoValues(List<String> parts) {
    if (parts.length < 5) return 0.0;

    // Formato Bradesco: Data | Histórico | Docto | Crédito | Débito | Saldo
    // Índices típicos:      0     1         2       3         4        5

    double credito = 0.0;
    double debito = 0.0;

    // Tentar encontrar colunas de crédito e débito
    for (int i = 2; i < parts.length && i < 6; i++) {
      final value = _parseValue(parts[i].trim());
      if (value > 0) {
        // Se estiver na posição típica de crédito (3) ou tem valor pequeno, é crédito
        if (i == 3 || (credito == 0.0 && value < 100000)) {
          credito = value;
        } else if (debito == 0.0) {
          debito = value;
        }
      }
    }

    // Se só tem crédito, retorna positivo. Se só tem débito, retorna negativo
    if (credito > 0 && debito == 0.0) {
      log('💰 Bradesco: Crédito R\$ $credito');
      return credito;
    } else if (debito > 0 && credito == 0.0) {
      log('💸 Bradesco: Débito R\$ $debito');
      return -debito;
    } else if (credito > 0 && debito > 0) {
      // Se ambos têm valor, priorizar o maior (pode ser erro de parsing)
      final maior = credito > debito ? credito : -debito;
      log('⚖️ Bradesco: Crédito R\$ $credito, Débito R\$ $debito → usando ${maior > 0 ? "crédito" : "débito"}');
      return maior;
    }

    return 0.0;
  }

  /// Encontra a melhor coluna para descrição entre múltiplas colunas de texto
  int _findBestDescriptionColumn(List<String> sampleLines, String separator, int dataCol, int valorCol) {
    if (sampleLines.isEmpty) return -1;

    final columnCount = sampleLines[0].split(separator).length;
    final candidatos = <int, Map<String, dynamic>>{};

    // Analisar todas as colunas que não são data nem valor
    for (int col = 0; col < columnCount; col++) {
      if (col == dataCol || col == valorCol) continue;

      double somaComprimento = 0;
      int contadorTexto = 0;
      int contadorVariado = 0;
      Set<String> valoresUnicos = {};

      for (final line in sampleLines) {
        final parts = line.split(separator);
        if (col < parts.length) {
          final text = parts[col].trim();
          if (text.isNotEmpty && !_isDateLike(text) && !_isValueLike(text)) {
            somaComprimento += text.length;
            contadorTexto++;
            valoresUnicos.add(text.toLowerCase());

            // Bonificar se tem palavras descritivas
            if (text.toLowerCase().contains('transfer') ||
                text.toLowerCase().contains('pagamento') ||
                text.toLowerCase().contains('compra') ||
                text.toLowerCase().contains('pix') ||
                text.length > 20) {
              contadorVariado++;
            }
          }
        }
      }

      if (contadorTexto > 0) {
        final comprimentoMedio = somaComprimento / contadorTexto;
        final variedade = valoresUnicos.length / contadorTexto.clamp(1, 999);

        candidatos[col] = {
          'comprimentoMedio': comprimentoMedio,
          'variedade': variedade,
          'contadorVariado': contadorVariado,
          'score': comprimentoMedio * 0.6 + variedade * 20 + contadorVariado * 10,
        };
      }
    }

    if (candidatos.isEmpty) return -1;

    // Encontrar o candidato com maior score
    int melhorColuna = -1;
    double melhorScore = 0;

    candidatos.forEach((col, stats) {
      final score = stats['score'] as double;
      log('🧠 Coluna $col: comprimento=${stats['comprimentoMedio']?.toStringAsFixed(1)}, variedade=${stats['variedade']?.toStringAsFixed(2)}, descritivo=${stats['contadorVariado']}, score=${score.toStringAsFixed(1)}');

      if (score > melhorScore) {
        melhorScore = score;
        melhorColuna = col;
      }
    });

    log('🎯 Melhor coluna para descrição: $melhorColuna (score: ${melhorScore.toStringAsFixed(1)})');
    return melhorColuna;
  }

  /// Auto-detecta categoria baseado na descrição
  String? autoDetectarCategoria(String descricao, String tipo) {
    final descricaoLower = descricao.toLowerCase();

    // Padrões para receitas
    if (tipo == 'receita') {
      if (descricaoLower.contains('salario') || descricaoLower.contains('salário')) {
        return 'Salário';
      } else if (descricaoLower.contains('freelance') || descricaoLower.contains('extra')) {
        return 'Freelance';
      } else if (descricaoLower.contains('pix') || descricaoLower.contains('transferencia')) {
        return 'Transferência Recebida';
      } else {
        return 'Receita Geral';
      }
    }

    // Padrões para despesas
    if (descricaoLower.contains('ifood') || descricaoLower.contains('rappi') ||
        descricaoLower.contains('uber eats')) {
      return 'Alimentação';
    } else if (descricaoLower.contains('mercado') || descricaoLower.contains('supermercado') ||
               descricaoLower.contains('padaria')) {
      return 'Alimentação';
    } else if (descricaoLower.contains('uber') || descricaoLower.contains('99') ||
               descricaoLower.contains('cabify')) {
      return 'Transporte';
    } else if (descricaoLower.contains('posto') || descricaoLower.contains('gasolina') ||
               descricaoLower.contains('etanol')) {
      return 'Transporte';
    } else if (descricaoLower.contains('netflix') || descricaoLower.contains('spotify') ||
               descricaoLower.contains('amazon prime')) {
      return 'Lazer';
    } else if (descricaoLower.contains('farmacia') || descricaoLower.contains('drogaria')) {
      return 'Saúde';
    } else {
      return 'Despesa Geral';
    }
  }

  /// Validação completa de transação importada com detecção de duplicidade e fingerprint
  /// Retorna estrutura detalhada: {'status': 'ok'|'warning'|'blocked', 'motivos': [], 'matches': [], 'canOverride': bool}
  Future<Map<String, dynamic>> validarImportacaoTransacao(
    TransacaoImportada transacao,
    String nomeArquivo,
  ) async {
    final motivos = <String>[];
    final matches = <Map<String, dynamic>>[];
    var status = 'ok';
    var canOverride = true;

    try {
      log('🔍 Validando importação: ${transacao.descricao} - R\$ ${transacao.valor}');

      // 1. VALIDAÇÃO DE FATURA FECHADA (BLOQUEIO TOTAL)
      if (transacao.cartaoId != null && transacao.cartaoId!.isNotEmpty) {
        final faturaCalculada = transacao.faturaVencimento ??
            await _calcularProximaFaturaValida(transacao.cartaoId!, transacao.data);

        final fatura = await FaturaService().buscarFaturaPorPeriodo(
          transacao.cartaoId!,
          faturaCalculada.year,
          faturaCalculada.month,
        );

        if (fatura != null && (fatura.status == 'fechada' || fatura.status == 'paga')) {
          return {
            'status': 'blocked',
            'motivos': ['fatura_fechada'],
            'message': 'Fatura do período ${faturaCalculada.month.toString().padLeft(2, '0')}/${faturaCalculada.year} está ${fatura.status}.',
            'matches': [],
            'canOverride': false,
          };
        }
      }

      // 2. VALIDAÇÃO DE FINGERPRINT (WARNING)
      final fingerprint = transacao.gerarFingerprint(nomeArquivo);
      log('🔑 [VALIDACAO] Fingerprint gerado: $fingerprint');
      log('🔍 [VALIDACAO] Chamando BusinessValidators.validarFingerprintExistente...');

      final fingerprintValidacao = await BusinessValidators.validarFingerprintExistente(
        fingerprint: fingerprint,
      );

      log('🔍 [VALIDACAO] Resultado da validação de fingerprint: $fingerprintValidacao');

      if (fingerprintValidacao['exists'] == true) {
        status = 'warning';
        motivos.add('fingerprint_duplicado');
        matches.addAll(List<Map<String, dynamic>>.from(fingerprintValidacao['matches'] ?? []));
        log('⚠️ [VALIDACAO] Fingerprint duplicado detectado - status: $status');
      } else {
        log('✅ [VALIDACAO] Fingerprint único - sem duplicatas');
      }

      // 3. VALIDAÇÃO DE DUPLICIDADE POR CONTA (WARNING)
      log('🔍 [VALIDACAO] Transação contaId: "${transacao.contaId}", cartaoId: "${transacao.cartaoId}"');
      if (transacao.contaId != null && transacao.contaId!.isNotEmpty) {
        log('🔍 [VALIDACAO] Verificando duplicidade por conta para: ${transacao.contaId}');
        final duplicataValidacao = await BusinessValidators.validarDuplicataTransacao(
          descricao: transacao.descricao,
          valor: transacao.valor,
          data: transacao.data,
          contaId: transacao.contaId!,
        );

        log('🔍 [VALIDACAO] Resultado duplicidade conta: $duplicataValidacao');

        if (duplicataValidacao['hasDuplicates'] == true) {
          status = 'warning';
          motivos.add('duplicidade_conta');
          matches.addAll(List<Map<String, dynamic>>.from(duplicataValidacao['suggestions'] ?? []));
          log('⚠️ [VALIDACAO] Duplicidade por conta detectada');
        }
      } else {
        log('🔍 [VALIDACAO] Transação não tem contaId válido - pulando validação de duplicidade por conta');
      }

      // 4. VALIDAÇÃO DE DUPLICIDADE POR CARTÃO (WARNING)
      if (transacao.cartaoId != null && transacao.cartaoId!.isNotEmpty) {
        log('🔍 [VALIDACAO] Verificando duplicidade por cartão para: ${transacao.cartaoId}');
        final duplicataValidacao = await BusinessValidators.validarDuplicataTransacaoCartao(
          descricao: transacao.descricao,
          valor: transacao.valor,
          data: transacao.data,
          cartaoId: transacao.cartaoId!,
          faturaVencimento: transacao.faturaVencimento,
        );

        log('🔍 [VALIDACAO] Resultado duplicidade cartão: $duplicataValidacao');

        if (duplicataValidacao['hasDuplicates'] == true) {
          status = 'warning';
          motivos.add('duplicidade_cartao');
          matches.addAll(List<Map<String, dynamic>>.from(duplicataValidacao['suggestions'] ?? []));
          log('⚠️ [VALIDACAO] Duplicidade por cartão detectada');
        }
      } else {
        log('🔍 [VALIDACAO] Transação não tem cartaoId válido - pulando validação de duplicidade por cartão');
      }

      // 5. VALIDAÇÃO GERAL DE DUPLICIDADE (SE NÃO TEM CONTA/CARTÃO DEFINIDO)
      if ((transacao.contaId == null || transacao.contaId!.isEmpty) &&
          (transacao.cartaoId == null || transacao.cartaoId!.isEmpty)) {
        log('🔍 [VALIDACAO] Executando validação geral de duplicidade (sem conta/cartão específico)');
        final duplicataGeral = await _validarDuplicidadeGeral(transacao);
        log('🔍 [VALIDACAO] Resultado duplicidade geral: $duplicataGeral');

        if (duplicataGeral['hasDuplicates'] == true) {
          status = 'warning';
          motivos.add('duplicidade_geral');
          matches.addAll(List<Map<String, dynamic>>.from(duplicataGeral['suggestions'] ?? []));
          log('⚠️ [VALIDACAO] Duplicidade geral detectada');
        }
      }

      final result = {
        'status': status,
        'motivos': motivos,
        'matches': matches,
        'canOverride': canOverride,
        'fingerprint': fingerprint,
      };

      if (status == 'warning') {
        result['message'] = 'Encontradas ${matches.length} transação(ões) similar(es) ou duplicata de importação.';
      } else {
        result['message'] = 'Transação válida para importação.';
      }

      log('✅ Validação concluída: $status (${motivos.length} motivos)');
      return result;

    } catch (e) {
      log('❌ Erro na validação: $e');
      return {
        'status': 'ok',
        'motivos': [],
        'matches': [],
        'canOverride': true,
        'message': 'Erro na validação, permitindo importação.',
        'error': e.toString(),
      };
    }
  }

  /// 🔍 VALIDAÇÃO GERAL DE DUPLICIDADE (SEM CONTA/CARTÃO ESPECÍFICO)
  Future<Map<String, dynamic>> _validarDuplicidadeGeral(TransacaoImportada transacao) async {
    try {
      log('🔍 [DUPLICIDADE_GERAL] Validando transação: ${transacao.descricao} - R\$ ${transacao.valor}');

      // Buscar transações na mesma data (±1 dia) com valor idêntico
      final dataInicio = transacao.data.subtract(Duration(days: 1));
      final dataFim = transacao.data.add(Duration(days: 1));

      // Fazer busca ampla (em todas as contas/cartões do usuário)
      final query = '''
        SELECT id, descricao, valor, data, conta_id, cartao_id
        FROM transacoes
        WHERE data >= ? AND data <= ?
        AND ABS(valor - ?) < 0.01
        AND (transferencia IS NULL OR transferencia = 0)
        ORDER BY data DESC
        LIMIT 10
      ''';

      final args = [
        dataInicio.toIso8601String(),
        dataFim.toIso8601String(),
        transacao.valor,
      ];

      log('🔍 [DUPLICIDADE_GERAL] Query: $query');
      log('🔍 [DUPLICIDADE_GERAL] Args: $args');

      final transacoesSimilares = await LocalDatabase.instance.database!.rawQuery(query, args);

      log('🔍 [DUPLICIDADE_GERAL] Encontradas ${transacoesSimilares.length} transações similares');

      if (transacoesSimilares.isNotEmpty) {
        // Verificar similaridade de descrição
        final matches = <Map<String, dynamic>>[];

        for (final similar in transacoesSimilares) {
          final descricaoSimilar = similar['descricao'] as String;
          final similarity = _calcularSimilaridadeDescricao(
            transacao.descricao.toLowerCase(),
            descricaoSimilar.toLowerCase()
          );

          log('🔍 [DUPLICIDADE_GERAL] Comparando "${transacao.descricao}" vs "$descricaoSimilar" = ${(similarity * 100).toInt()}%');

          // Se a similaridade for >= 70%, considerar possível duplicata
          if (similarity >= 0.7) {
            matches.add({
              'id': similar['id'],
              'descricao': descricaoSimilar,
              'valor': similar['valor'],
              'data': similar['data'],
              'similaridade': (similarity * 100).toInt(),
            });
          }
        }

        if (matches.isNotEmpty) {
          return {
            'hasDuplicates': true,
            'warning': true,
            'reason': 'DUPLICIDADE_GERAL',
            'message': 'Encontradas ${matches.length} transação(ões) similar(es) com mesmo valor e data próxima.',
            'suggestions': matches,
          };
        }
      }

      return {
        'hasDuplicates': false,
        'message': 'Nenhuma transação similar encontrada.',
      };

    } catch (e) {
      log('❌ [DUPLICIDADE_GERAL] Erro: $e');
      return {
        'hasDuplicates': false,
        'error': true,
        'message': 'Erro ao verificar duplicidade geral.',
      };
    }
  }

  /// 📊 CALCULAR SIMILARIDADE ENTRE DESCRIÇÕES
  double _calcularSimilaridadeDescricao(String desc1, String desc2) {
    // Normalizar strings
    final normalized1 = desc1.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalized2 = desc2.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

    // Se são iguais após normalização, 100% similar
    if (normalized1 == normalized2) return 1.0;

    // Calcular similaridade por palavras
    final palavras1 = normalized1.split(' ').where((w) => w.length > 2).toSet();
    final palavras2 = normalized2.split(' ').where((w) => w.length > 2).toSet();

    if (palavras1.isEmpty && palavras2.isEmpty) return 1.0;
    if (palavras1.isEmpty || palavras2.isEmpty) return 0.0;

    final intersection = palavras1.intersection(palavras2).length;
    final union = palavras1.union(palavras2).length;

    return intersection / union;
  }

  Future<List<String>> salvarTransacoesImportadas(
    List<TransacaoImportada> transacoes, {
    Set<int>? indicesParaPular,
    String nomeArquivo = '',
  }) async {
    final transacoesSalvas = <String>[];
    final transacoesBloqueadas = <String>[];

    try {
      log('💾 Salvando ${transacoes.length} transações importadas...');

      for (int i = 0; i < transacoes.length; i++) {
        final transacao = transacoes[i];

        // Pular transações selecionadas pelo usuário
        if (indicesParaPular?.contains(i) == true) {
          log('⏭️ Pulando transação por seleção do usuário: ${transacao.descricao}');
          continue;
        }

        try {
          // ✅ VALIDAR ANTES DE SALVAR
          final validacao = await validarImportacaoTransacao(transacao, nomeArquivo);
          if (validacao['status'] == 'blocked') {
            log('🚫 Transação bloqueada: ${transacao.descricao} - ${validacao['message']}');
            transacoesBloqueadas.add(transacao.descricao);
            continue; // Pula essa transação
          }

          List<String> ids;

          // ✅ CALCULAR SE DEVE MARCAR COMO PAGO (apenas para conta)
          final dataAtual = DateTime.now();
          final dataAtualSemHora = DateTime(dataAtual.year, dataAtual.month, dataAtual.day);
          final dataTransacaoSemHora = DateTime(transacao.data.year, transacao.data.month, transacao.data.day);

          // Data passada ou hoje = pago: true, Data futura = pago: false
          final pagoAutomatico = !dataTransacaoSemHora.isAfter(dataAtualSemHora);

          // ✅ PREPARAR OBSERVAÇÕES COM FINGERPRINT
          final fingerprint = validacao['fingerprint'] as String? ?? transacao.gerarFingerprint(nomeArquivo);
          final observacoesComFingerprint = transacao.observacoes.isNotEmpty
              ? '${transacao.observacoes}\n\nfingerprint:$fingerprint'
              : 'Importado de ${transacao.origem}\n\nfingerprint:$fingerprint';

          if (transacao.tipo == 'receita') {
            // ✅ RECEITA DE CONTA: data passada = pago: true
            ids = await _transacaoService.criarReceita(
              descricao: transacao.descricao,
              valor: transacao.valor,
              data: transacao.data,
              contaId: transacao.contaId ?? '',
              categoriaId: transacao.categoriaId ?? '',
              subcategoriaId: transacao.subcategoriaId,
              tipoReceita: 'extra',
              efetivado: pagoAutomatico, // ⭐ AUTOMÁTICO baseado na data
              observacoes: observacoesComFingerprint,
              numeroParcelas: null,
              frequenciaParcelada: null,
              frequenciaPrevisivel: null,
              numeroRepeticoes: null,
            ).then((transacoes) => transacoes.map((t) => t.id).toList());
            log('✅ Receita criada - pago: $pagoAutomatico (data: ${transacao.data})');
          } else {
            // Despesas: verificar se é conta ou cartão
            if (transacao.cartaoId != null && transacao.cartaoId!.isNotEmpty) {
              // ✅ DESPESA DE CARTÃO: sempre pendente (fatura aberta ou cria fatura)
              final cartaoDataService = CartaoDataService.instance;

              final faturaCalculada = transacao.faturaVencimento ??
                  await _calcularProximaFaturaValida(transacao.cartaoId!, transacao.data);

              final resultado = await cartaoDataService.criarDespesaCartao(
                cartaoId: transacao.cartaoId!,
                categoriaId: transacao.categoriaId ?? '',
                subcategoriaId: transacao.subcategoriaId,
                descricao: transacao.descricao,
                valorTotal: transacao.valor,
                dataCompra: transacao.data.toIso8601String().split('T')[0],
                faturaVencimento: faturaCalculada.toIso8601String().split('T')[0],
                observacoes: observacoesComFingerprint,
              );

              ids = [resultado['transacaoId'] as String];
              log('✅ Despesa cartão criada (pendente na fatura)');
            } else {
              // ✅ DESPESA DE CONTA: data passada = pago: true
              ids = await _transacaoService.criarDespesa(
                descricao: transacao.descricao,
                valor: transacao.valor,
                data: transacao.data,
                contaId: transacao.contaId ?? '',
                categoriaId: transacao.categoriaId ?? '',
                subcategoriaId: transacao.subcategoriaId,
                tipoDespesa: 'extra',
                efetivado: pagoAutomatico, // ⭐ AUTOMÁTICO baseado na data
                observacoes: observacoesComFingerprint,
                numeroParcelas: null,
                frequenciaParcelada: null,
                frequenciaPrevisivel: null,
                numeroRepeticoes: null,
              ).then((transacoes) => transacoes.map((t) => t.id).toList());
              log('✅ Despesa conta criada - pago: $pagoAutomatico (data: ${transacao.data})');
            }
          }

          transacoesSalvas.addAll(ids);

        } catch (e) {
          log('❌ Erro ao salvar transação ${transacao.descricao}: $e');
          // Continua com as próximas mesmo se uma falhar
        }
      }

      if (transacoesBloqueadas.isNotEmpty) {
        log('🚫 ${transacoesBloqueadas.length} transações bloqueadas (fatura fechada)');
      }

      log('✅ Importação concluída: ${transacoesSalvas.length} salvas, ${transacoesBloqueadas.length} bloqueadas');

      // ✅ SINCRONIZAÇÃO BIDIRECIONAL - UMA VEZ SÓ NO FINAL
      // Upload para Supabase + Download de volta para SQLite
      // Garante consistência entre Supabase (fonte da verdade) e SQLite local
      if (transacoesSalvas.isNotEmpty) {
        try {
          log('🔄 Forçando sincronização bidirecional (Supabase ↔ SQLite)...');
          final syncManager = SyncManager.instance;
          await syncManager.syncAll();
          log('✅ Sincronização bidirecional concluída - dados consistentes');
        } catch (syncError) {
          log('⚠️ Erro na sincronização (transações salvas localmente): $syncError');
          // Continua mesmo com erro de sync - dados estão salvos offline
        }
      }

      return transacoesSalvas;

    } catch (e) {
      log('❌ Erro geral na importação: $e');
      rethrow;
    }
  }

  /// Calcula próxima fatura baseada na data da compra e dados do cartão
  Future<DateTime> _calcularProximaFaturaValida(String cartaoId, DateTime dataCompra) async {
    try {
      // Buscar dados do cartão
      final cartaoDataService = CartaoDataService.instance;
      final cartao = await cartaoDataService.fetchCartao(cartaoId);

      // Usar dados do cartão ou valores padrão como fallback
      final diaFechamento = cartao?.diaFechamento ?? 15;
      final diaVencimento = cartao?.diaVencimento ?? 10;

      log('🎯 Calculando fatura para cartão $cartaoId: fechamento=$diaFechamento, vencimento=$diaVencimento');

      // Usar o método correto do CartaoDataService para calcular a fatura
      if (cartao != null) {
        final faturaCalculada = cartaoDataService.calcularFaturaAlvo(cartao, dataCompra);
        var faturaVencimento = faturaCalculada.dataVencimento;

        log('📅 Fatura calculada: ${faturaVencimento.toIso8601String().split('T')[0]}');

        // Verificar se a fatura está paga/fechada e buscar próxima válida
        for (int tentativas = 0; tentativas < 12; tentativas++) {
          final faturaString = faturaVencimento.toIso8601String().split('T')[0];
          final statusFatura = await cartaoDataService.verificarStatusFatura(cartaoId, faturaString);

          final faturaPaga = statusFatura['status_paga'] == true;

          if (!faturaPaga) {
            log('✅ Fatura válida encontrada: $faturaString');
            return faturaVencimento;
          }

          log('⚠️ Fatura $faturaString já está paga, calculando próxima...');

          // Calcular próxima fatura usando os dados corretos do cartão
          final proximaData = DateTime(dataCompra.year, dataCompra.month + tentativas + 2, dataCompra.day);
          final proximaFatura = cartaoDataService.calcularFaturaAlvo(cartao, proximaData);
          faturaVencimento = proximaFatura.dataVencimento;
        }

        return faturaVencimento;
      }

      // Fallback para quando não conseguir buscar dados do cartão
      DateTime faturaVencimento;

      if (dataCompra.day <= diaFechamento) {
        // Compra antes do fechamento - vai para a fatura do mês seguinte
        faturaVencimento = DateTime(dataCompra.year, dataCompra.month + 1, diaVencimento);
      } else {
        // Compra após o fechamento - vai para a fatura de dois meses
        faturaVencimento = DateTime(dataCompra.year, dataCompra.month + 2, diaVencimento);
      }

      // Ajustar se passou do ano
      if (faturaVencimento.month > 12) {
        faturaVencimento = DateTime(faturaVencimento.year + 1, faturaVencimento.month - 12, diaVencimento);
      }

      // Verificar se a fatura está paga/fechada
      for (int tentativas = 0; tentativas < 12; tentativas++) {
        final faturaString = faturaVencimento.toIso8601String().split('T')[0];
        final statusFatura = await cartaoDataService.verificarStatusFatura(cartaoId, faturaString);

        final faturaPaga = statusFatura['status_paga'] == true;

        if (!faturaPaga) {
          log('✅ Fatura válida encontrada: $faturaString');
          return faturaVencimento;
        }

        log('⚠️ Fatura $faturaString já está paga, tentando próxima...');

        // Próximo mês
        faturaVencimento = DateTime(faturaVencimento.year, faturaVencimento.month + 1, diaVencimento);
        if (faturaVencimento.month > 12) {
          faturaVencimento = DateTime(faturaVencimento.year + 1, faturaVencimento.month - 12, diaVencimento);
        }
      }

      // Se todas as 12 tentativas falharam, retornar a data original como fallback
      log('❌ Não foi possível encontrar fatura válida, usando cálculo original');
      return DateTime(dataCompra.year, dataCompra.month + 1, diaVencimento);

    } catch (e) {
      log('❌ Erro ao calcular próxima fatura: $e');
      // Fallback para cálculo simples
      final diaVencimento = 10;
      return DateTime(dataCompra.year, dataCompra.month + 1, diaVencimento);
    }
  }

  /// Validação de transação importada
  Map<String, dynamic> validarTransacao(TransacaoImportada transacao) {
    final erros = <String>[];
    final avisos = <String>[];

    // Validações obrigatórias
    if (transacao.descricao.trim().isEmpty) {
      erros.add('Descrição é obrigatória');
    }

    if (transacao.valor <= 0) {
      erros.add('Valor deve ser maior que zero');
    }

    if (transacao.categoriaId == null || transacao.categoriaId!.isEmpty) {
      erros.add('Categoria é obrigatória');
    }

    if (transacao.contaId == null && transacao.cartaoId == null) {
      erros.add('Conta ou cartão deve ser selecionado');
    }

    // Avisos
    if (transacao.data.isAfter(DateTime.now().add(const Duration(days: 365)))) {
      avisos.add('Data muito no futuro');
    }

    if (transacao.valor > 100000) {
      avisos.add('Valor muito alto');
    }

    return {
      'valida': erros.isEmpty,
      'erros': erros,
      'avisos': avisos,
    };
  }

  /// Estatísticas das transações importadas
  Map<String, dynamic> calcularEstatisticas(List<TransacaoImportada> transacoes) {
    // Excluir transferências das estatísticas financeiras
    final transacoesSemTransferencias = transacoes.where((t) {
      final descricaoLower = t.descricao.toLowerCase();
      final observacoesLower = t.observacoes.toLowerCase();
      return !(descricaoLower.contains('pix') ||
               descricaoLower.contains('transferencia') ||
               descricaoLower.contains('transferência') ||
               observacoesLower.contains('transfer'));
    }).toList();

    final receitas = transacoesSemTransferencias.where((t) => t.tipo == 'receita').toList();
    final despesas = transacoesSemTransferencias.where((t) => t.tipo == 'despesa').toList();

    final totalReceitas = receitas.fold<double>(0, (sum, t) => sum + t.valor);
    final totalDespesas = despesas.fold<double>(0, (sum, t) => sum + t.valor);

    return {
      'total': transacoes.length,
      'receitas': {
        'quantidade': receitas.length,
        'valor': totalReceitas,
      },
      'despesas': {
        'quantidade': despesas.length,
        'valor': totalDespesas,
      },
      'saldo': totalReceitas - totalDespesas,
      'periodos': {
        'dataInicial': transacoesSemTransferencias.isNotEmpty
            ? transacoesSemTransferencias.map((t) => t.data).reduce((a, b) => a.isBefore(b) ? a : b)
            : null,
        'dataFinal': transacoesSemTransferencias.isNotEmpty
            ? transacoesSemTransferencias.map((t) => t.data).reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      },
    };
  }

  /// Parse de data seguro que lida com vários formatos
  DateTime _safeDateParse(dynamic dateInput) {
    if (dateInput == null) {
      return DateTime.now();
    }

    String dateStr = dateInput.toString().trim();

    try {
      // Tentar DateTime.parse primeiro (ISO format)
      return DateTime.parse(dateStr);
    } catch (e) {
      // Se falhar, tentar outros formatos
      try {
        // DD/MM/YYYY
        if (RegExp(r'\d{1,2}/\d{1,2}/\d{4}').hasMatch(dateStr)) {
          final parts = dateStr.split('/');
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }

        // DD-MM-YYYY
        if (RegExp(r'\d{1,2}-\d{1,2}-\d{4}').hasMatch(dateStr)) {
          final parts = dateStr.split('-');
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }

        // YYYY-MM-DD (que deveria funcionar no DateTime.parse, mas como fallback)
        if (RegExp(r'\d{4}-\d{1,2}-\d{1,2}').hasMatch(dateStr)) {
          final parts = dateStr.split('-');
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }

        // Se não conseguir parsear, retornar data atual
        log('⚠️ Não foi possível parsear data: $dateStr, usando data atual');
        return DateTime.now();
      } catch (e2) {
        log('⚠️ Erro ao parsear data: $dateStr, usando data atual. Erro: $e2');
        return DateTime.now();
      }
    }
  }

  /// Processamento genérico simples de Excel
  Future<List<TransacaoImportada>> _processarExcelGenerico(
    File file, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) async {
    try {
      log('📊 Processando Excel genérico: ${file.path}');

      // Ler arquivo Excel diretamente com a biblioteca excel
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception('Nenhuma planilha encontrada no arquivo Excel');
      }

      // Usar primeira planilha
      final tableName = excel.tables.keys.first;
      final table = excel.tables[tableName];

      if (table == null || table.rows.isEmpty) {
        throw Exception('Planilha vazia');
      }

      // Converter para CSV para usar o processamento existente
      final csvLines = <String>[];
      for (final row in table.rows) {
        final cellValues = <String>[];
        for (final cell in row) {
          final value = cell?.value?.toString() ?? '';
          cellValues.add(value);
        }
        csvLines.add(cellValues.join(','));
      }

      final csvContent = csvLines.join('\n');
      log('📄 Excel convertido para CSV: ${csvLines.length} linhas');

      // Salvar temporariamente como CSV
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_excel_${DateTime.now().millisecondsSinceEpoch}.csv');

      try {
        await tempFile.writeAsString(csvContent);

        // Processar usando método CSV simples (não JS Engine)
        final transacoes = await _parseCSVSimples(
          csvContent,
          tempFile.path.split('/').last,
          tipoImportacao,
          contaId,
          cartaoId,
          faturaVencimento,
        );

        // Recriar transações com origem correta
        final transacoesExcel = <TransacaoImportada>[];
        for (final transacao in transacoes) {
          final metadadosAtualizados = Map<String, dynamic>.from(transacao.metadados);
          metadadosAtualizados['arquivoOriginal'] = file.path.split('/').last;
          metadadosAtualizados['metodoProcessamento'] = 'Excel → CSV';

          transacoesExcel.add(TransacaoImportada(
            id: transacao.id,
            data: transacao.data,
            descricao: transacao.descricao,
            valor: transacao.valor,
            tipo: transacao.tipo,
            origem: 'Excel', // Corrigir origem
            usuarioId: transacao.usuarioId,
            contaId: transacao.contaId,
            cartaoId: transacao.cartaoId,
            categoriaId: transacao.categoriaId,
            subcategoriaId: transacao.subcategoriaId,
            faturaVencimento: transacao.faturaVencimento,
            efetivado: transacao.efetivado,
            observacoes: transacao.observacoes,
            linhaBruta: transacao.linhaBruta,
            indiceOriginal: transacao.indiceOriginal,
            metadados: metadadosAtualizados,
          ));
        }

        log('✅ Excel genérico processado: ${transacoesExcel.length} transações');
        return transacoesExcel;

      } finally {
        // Limpar arquivo temporário
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (e) {
          log('⚠️ Erro ao deletar arquivo temporário: $e');
        }
      }

    } catch (e) {
      log('❌ Erro no processamento Excel genérico: $e');
      rethrow;
    }
  }


  /// Limpa recursos do JS Engine
  void dispose() {
    _jsEngine?.dispose();
    _jsEngineInitialized = false;
  }
}