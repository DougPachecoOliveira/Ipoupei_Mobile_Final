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
import '../../cartoes/services/cartao_data_service.dart';
import '../../cartoes/services/fatura_service.dart';
import '../../../sync/sync_manager.dart';

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

      // Contexto de importação para o JS
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

  /// Parser CSV simples para formatos comuns
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
      log('📊 INICIANDO PROCESSAMENTO EXCEL ROBUSTO: ${file.path}');
      log('📋 Contexto: tipo=$tipoImportacao, conta=$contaId, cartao=$cartaoId');

      final fileName = file.path.split('/').last.toLowerCase();

      // Primeiro tentar o extrator específico do Conectcar se aplicável
      if (fileName.contains('conectcar') || fileName.contains('extrato_conectcar')) {
        log('🚗 Detectado arquivo Conectcar específico, tentando extrator especializado');

        try {
          final conectcarExtractor = ConectcarExtractor();
          final transacoes = await conectcarExtractor.processarArquivoConectcar(
            file,
            tipoImportacao: tipoImportacao,
            contaId: contaId,
            cartaoId: cartaoId,
            faturaVencimento: faturaVencimento,
          );

          if (transacoes.isNotEmpty) {
            log('✅ Excel Conectcar processado: ${transacoes.length} transações');
            return transacoes;
          }

        } catch (e) {
          log('❌ Erro no extrator Conectcar: $e');

          // Se é um erro de formato, mostrar mensagem específica
          if (e.toString().contains('Header do arquivo não indica formato Excel válido') ||
              e.toString().contains('Damaged Excel file') ||
              e.toString().contains('Failed to decode data using encoding')) {
            throw Exception(
              '🚗 ARQUIVO CONECTCAR COM PROBLEMA DE FORMATO\n\n'
              '💡 SOLUÇÕES RÁPIDAS:\n\n'
              '1️⃣ CONVERTA PARA CSV:\n'
              '   • Abra o arquivo no Excel\n'
              '   • Arquivo → Salvar Como → CSV\n'
              '   • Importe o arquivo CSV\n\n'
              '2️⃣ BAIXE NOVAMENTE:\n'
              '   • Site do Conectcar → Extrato\n'
              '   • Baixe formato .xlsx\n\n'
              '3️⃣ VERIFIQUE O ARQUIVO:\n'
              '   • Abra no Excel primeiro\n'
              '   • Se não abrir, está corrompido\n\n'
              'Erro técnico: ${e.toString().split('\n').first}'
            );
          }

          // Continue para extrator robusto para outros erros
        }
      }

      // TODO: Usar o novo extrator robusto como método principal (temporariamente desabilitado)
      log('⚠️ Enhanced Excel Extractor temporariamente desabilitado - usando método legado');
      /*
      final enhancedExtractor = EnhancedExcelExtractor.instance;
      final transacoes = await enhancedExtractor.processarArquivoExcel(
        file,
        tipoImportacao: tipoImportacao,
        contaId: contaId,
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
      );

      if (transacoes.isNotEmpty) {
        log('✅ Enhanced Excel processado: ${transacoes.length} transações');
        return transacoes;
      }
      */

      // Fallback para método genérico antigo apenas se o robusto falhar
      log('⚠️ Enhanced Extractor não encontrou dados, tentando método legado');
      return await _processarExcelGenerico(
        file,
        tipoImportacao: tipoImportacao,
        contaId: contaId,
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
      );

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

      await _initializeJSEngine();

      // Extrair texto real do PDF
      log('📄 Extraindo texto do PDF: $filePath');
      final pdfText = await ReadPdfText.getPDFtext(filePath);
      if (pdfText.isEmpty) {
        throw Exception('Não foi possível extrair texto do PDF');
      }

      log('📄 Texto extraído do PDF (${pdfText.length} chars)');
      log('📝 Primeiros 300 chars: ${pdfText.substring(0, pdfText.length > 300 ? 300 : pdfText.length)}');

      final fileName = file.path.split('/').last;

      // Força reinicialização completa do JS engine para carregar mudanças
      _jsEngine = null;
      _jsEngineInitialized = false;
      await _initializeJSEngine();

      // Usar JavaScript PDF extractor avançado
      final extractorResult = await _jsEngine!.evaluate('''
        (function() {
          try {
            const fileName = "${fileName}";
            const pdfText = `${pdfText.replaceAll('`', '\\`').replaceAll('\\', '\\\\')}`;

            console.log('📄 PDFExtractor: Processando', fileName);
            console.log('📄 Texto recebido:', pdfText.length, 'chars');

            // Criar resultado similar ao extractFromBase64 mas com texto real
            const result = {
              rawText: pdfText,
              lines: pdfText.split('\\n').filter(line => line.trim()),
              analysis: {
                formatType: 'pdf',
                separator: null,
                hasHeader: false,
                columnCount: 0,
                pagesProcessed: 1
              },
              metadata: {
                fileName: fileName,
                fileType: 'PDF',
                contentLength: pdfText.length,
                extractedAt: new Date().toISOString()
              }
            };

            console.log('✅ PDF estruturado:', result.lines.length, 'linhas');

            // Usar PDFExtractor.parseTransactions com contexto
            const context = {
              tipoImportacao: "${tipoImportacao}",
              contaId: "${contaId ?? ''}",
              cartaoId: "${cartaoId ?? ''}",
              faturaVencimento: "${faturaVencimento?.toIso8601String() ?? ''}"
            };

            const pdfExtractor = new PDFExtractor();
            const transacoes = pdfExtractor.parseTransactions(result, context);

            console.log('🎯 PDFExtractor: processadas', transacoes.length, 'transações');
            return transacoes;

          } catch (error) {
            console.error('❌ Erro no PDFExtractor:', error);
            return [];
          }
        })()
      ''');

      final transacoesJS = extractorResult.rawResult;
      log('🎯 JavaScript retornou: ${transacoesJS?.length ?? 0} transações');

      if (transacoesJS == null || transacoesJS.isEmpty) {
        log('⚠️ JavaScript não retornou transações, tentando parser Dart simples...');
        return _parseTextToTransactions(
          pdfText,
          fileName,
          tipoImportacao: tipoImportacao,
          contaId: contaId,
          cartaoId: cartaoId,
          faturaVencimento: faturaVencimento,
        );
      }

      // Converter resultado JavaScript para TransacaoImportada
      final transacoes = <TransacaoImportada>[];
      for (final item in transacoesJS) {
        if (item is Map<String, dynamic>) {
          try {
            final transacao = TransacaoImportada(
              id: item['id']?.toString() ?? 'pdf_${DateTime.now().millisecondsSinceEpoch}',
              data: _safeDateParse(item['data']?.toString()),
              descricao: item['descricao']?.toString() ?? 'Transação PDF',
              valor: _parseDoubleFromJS(item['valor']),
              tipo: item['tipo']?.toString() ?? 'despesa',
              origem: 'PDF',
              usuarioId: _authIntegration.authService.currentUser?.id ?? '',
              contaId: contaId,
              cartaoId: cartaoId,
              faturaVencimento: faturaVencimento,
              efetivado: false,
              observacoes: item['observacoes']?.toString() ?? '',
              linhaBruta: item['linhaBruta']?.toString() ?? '',
              indiceOriginal: item['indiceOriginal'] ?? 0,
              metadados: {
                ...((item['metadados'] as Map<String, dynamic>?) ?? {}),
                'extractedAt': DateTime.now().toIso8601String(),
                'fileName': fileName,
                'sourceType': 'JavaScript PDF Extractor',
              },
            );
            transacoes.add(transacao);
          } catch (e) {
            log('⚠️ Erro convertendo transação JS: $e');
          }
        }
      }

      log('✅ PDF processado com JS: ${transacoes.length} transações');

      return transacoes;

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

  /// Extrai dados de transação de uma linha de PDF
  Map<String, dynamic>? _extractTransactionFromPDFLine(String line) {
    // Padrões comuns em PDFs de extrato/fatura
    final patterns = [
      // DD/MM/YYYY DESCRIÇÃO VALOR
      RegExp(r'(\d{2}/\d{2}/\d{4})\s+(.+?)\s+([-+]?\d+[.,]\d{2})\s*$'),
      // DD/MM DESCRIÇÃO VALOR (ano implícito)
      RegExp(r'(\d{2}/\d{2})\s+(.+?)\s+([-+]?\d+[.,]\d{2})\s*$'),
      // DESCRIÇÃO DD/MM/YYYY VALOR
      RegExp(r'(.+?)\s+(\d{2}/\d{2}/\d{4})\s+([-+]?\d+[.,]\d{2})\s*$'),
      // DESCRIÇÃO DD/MM VALOR
      RegExp(r'(.+?)\s+(\d{2}/\d{2})\s+([-+]?\d+[.,]\d{2})\s*$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        try {
          String dataStr, descricao, valorStr;

          if (pattern.pattern.startsWith(r'(\d{2}')) {
            // Data no início
            dataStr = match.group(1)!;
            descricao = match.group(2)!.trim();
            valorStr = match.group(3)!;
          } else {
            // Data no meio/fim
            descricao = match.group(1)!.trim();
            dataStr = match.group(2)!;
            valorStr = match.group(3)!;
          }

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

  /// Salva transações importadas usando o TransacaoService existente
  /// Valida se transação pode ser importada (especialmente para cartões)
  /// Retorna Map com {'valido': bool, 'erro': String?}
  Future<Map<String, dynamic>> validarImportacaoTransacao(TransacaoImportada transacao) async {
    try {
      // ✅ VALIDAÇÃO APENAS PARA CARTÃO
      if (transacao.cartaoId != null && transacao.cartaoId!.isNotEmpty) {
        final faturaCalculada = transacao.faturaVencimento ??
            await _calcularProximaFaturaValida(transacao.cartaoId!, transacao.data);

        // Buscar fatura do período
        final fatura = await FaturaService().buscarFaturaPorPeriodo(
          transacao.cartaoId!,
          faturaCalculada.year,
          faturaCalculada.month,
        );

        if (fatura != null) {
          // ❌ BLOQUEIO: Fatura FECHADA não permite importação
          if (fatura.status == 'fechada' || fatura.status == 'paga') {
            return {
              'valido': false,
              'erro': 'Fatura do período ${faturaCalculada.month.toString().padLeft(2, '0')}/${faturaCalculada.year} está ${fatura.status}. Não é possível importar transações.',
            };
          }
        }
        // Se fatura não existe OU está aberta → permite importação (cria pendente)
      }

      return {'valido': true, 'erro': null};
    } catch (e) {
      log('⚠️ Erro na validação: $e');
      return {'valido': true, 'erro': null}; // Em caso de erro, permitir importação
    }
  }

  Future<List<String>> salvarTransacoesImportadas(
    List<TransacaoImportada> transacoes
  ) async {
    final transacoesSalvas = <String>[];
    final transacoesBloqueadas = <String>[];

    try {
      log('💾 Salvando ${transacoes.length} transações importadas...');

      for (final transacao in transacoes) {
        try {
          // ✅ VALIDAR ANTES DE SALVAR
          final validacao = await validarImportacaoTransacao(transacao);
          if (validacao['valido'] == false) {
            log('🚫 Transação bloqueada: ${transacao.descricao} - ${validacao['erro']}');
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
              observacoes: transacao.observacoes.isNotEmpty
                  ? transacao.observacoes
                  : 'Importado de ${transacao.origem}',
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
                observacoes: transacao.observacoes.isNotEmpty
                    ? transacao.observacoes
                    : 'Importado de ${transacao.origem}',
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
                observacoes: transacao.observacoes.isNotEmpty
                    ? transacao.observacoes
                    : 'Importado de ${transacao.origem}',
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
    final receitas = transacoes.where((t) => t.tipo == 'receita').toList();
    final despesas = transacoes.where((t) => t.tipo == 'despesa').toList();

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
        'dataInicial': transacoes.isNotEmpty
            ? transacoes.map((t) => t.data).reduce((a, b) => a.isBefore(b) ? a : b)
            : null,
        'dataFinal': transacoes.isNotEmpty
            ? transacoes.map((t) => t.data).reduce((a, b) => a.isAfter(b) ? a : b)
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