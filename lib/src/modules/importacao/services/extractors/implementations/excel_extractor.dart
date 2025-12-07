// lib/src/modules/importacao/services/extractors/implementations/excel_extractor.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../base/bank_extractor.dart';
import '../../../models/transacao_importada_model.dart';
import '../factory/extractor_factory.dart';

/// Extractor para arquivos Excel (.xlsx/.xls)
///
/// Este extractor não processa diretamente as transações, mas sim:
/// 1. Lê o arquivo Excel
/// 2. Converte para formato CSV interno
/// 3. Delega para o extractor específico do banco detectado
///
/// Suporta:
/// - .xlsx (Excel 2007+)
/// - .xls (Excel legado)
/// - Múltiplas planilhas (usa a primeira com dados)
/// - Auto-detecção do banco baseada no conteúdo CSV gerado
class ExcelExtractor extends BankExtractor {
  @override
  String get bankId => 'excel';

  @override
  String get bankName => 'Excel Processor';

  @override
  int get priority => 90; // Alta prioridade - detecta primeiro para processar Excel

  @override
  bool canHandle(String content, String fileName) {
    // Detecta por extensão de arquivo
    final name = fileName.toLowerCase();
    return name.endsWith('.xlsx') || name.endsWith('.xls');
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
    log('📊 [EXCEL_DEBUG] Processando arquivo Excel: ${file.path}');

    try {
      // Ler arquivo Excel
      log('📁 [EXCEL_DEBUG] Lendo bytes do arquivo...');
      final bytes = await file.readAsBytes();
      log('✅ [EXCEL_DEBUG] Arquivo lido: ${bytes.length} bytes');

      log('🔓 [EXCEL_DEBUG] Decodificando Excel...');
      final excel = Excel.decodeBytes(bytes);
      log('✅ [EXCEL_DEBUG] Excel decodificado com sucesso');

      // Encontrar a primeira planilha com dados
      log('🔍 [EXCEL_DEBUG] Procurando planilhas...');
      log('📋 [EXCEL_DEBUG] Planilhas disponíveis: ${excel.tables.keys.toList()}');
      final sheetName = _findDataSheet(excel);
      if (sheetName == null) {
        log('❌ [EXCEL_DEBUG] Nenhuma planilha com dados encontrada');
        throw ExtractorException(
          'Nenhuma planilha com dados encontrada no arquivo Excel\n'
          'Planilhas disponíveis: ${excel.tables.keys.toList()}',
          bankId: bankId,
        );
      }

      log('✅ [EXCEL_DEBUG] Planilha selecionada: $sheetName');

      // Converter planilha para CSV
      log('🔄 [EXCEL_DEBUG] Convertendo para CSV...');
      final csvContent = _convertSheetToCSV(excel, sheetName);
      if (csvContent.isEmpty) {
        log('❌ [EXCEL_DEBUG] CSV vazio após conversão');
        throw ExtractorException(
          'Planilha está vazia ou não contém dados válidos',
          bankId: bankId,
        );
      }

      log('✅ [EXCEL_DEBUG] Excel convertido para CSV (${csvContent.length} caracteres)');
      log('📝 [EXCEL_DEBUG] Primeiras linhas do CSV:');
      final lines = csvContent.split('\n');
      for (int i = 0; i < (lines.length > 5 ? 5 : lines.length); i++) {
        log('   $i: ${lines[i]}');
      }

      // Detectar extractor específico baseado no conteúdo CSV
      log('🔍 [EXCEL_DEBUG] Detectando banco específico...');
      final specificExtractor = ExtractorFactory.detectExtractor(
        csvContent,
        file.path.split('/').last,
        excludeExcel: true, // Evitar recursão infinita
      );

      log('✅ [EXCEL_DEBUG] Banco detectado: ${specificExtractor.bankName} (${specificExtractor.bankId})');

      // Delegar para o extractor específico
      log('⚡ [EXCEL_DEBUG] Delegando para extractor específico...');
      final result = await specificExtractor.extract(
        file, // Usar o arquivo original para metadados
        csvContent, // Mas passar o conteúdo CSV convertido
        tipoImportacao: tipoImportacao,
        contaId: contaId,
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
      );

      log('✅ [EXCEL_DEBUG] Processamento concluído: ${result.length} transações');
      return result;

    } catch (e) {
      log('💥 [EXCEL_DEBUG] ERRO CAPTURADO: ${e.runtimeType} - ${e.toString()}');
      log('📍 [EXCEL_DEBUG] Stack trace: ${StackTrace.current}');

      if (e is ExtractorException) {
        log('🔄 [EXCEL_DEBUG] Re-throwing ExtractorException');
        rethrow;
      }

      // Erro específico para arquivos Excel corrompidos/inválidos
      if (e.toString().contains('Invalid argument') ||
          e.toString().contains('FormatException') ||
          e.toString().contains('RangeError') ||
          e.toString().contains('Exception')) {
        log('🚫 [EXCEL_DEBUG] Erro de formato detectado');
        throw ExtractorException(
          '🚗 ARQUIVO EXCEL COM PROBLEMA DE FORMATO\n\n'
          '💡 SOLUÇÕES RÁPIDAS:\n\n'
          '1️⃣ CONVERTA PARA CSV:\n'
          '   • Abra o arquivo no Excel\n'
          '   • Arquivo → Salvar Como → CSV\n'
          '   • Importe o arquivo CSV\n\n'
          '2️⃣ BAIXE NOVAMENTE:\n'
          '   • Site do banco → Extrato\n'
          '   • Baixe formato .xlsx\n\n'
          '3️⃣ VERIFIQUE O ARQUIVO:\n'
          '   • Abra no Excel primeiro\n'
          '   • Se não abrir, está corrompido\n\n'
          'Erro técnico: ${e.toString()}',
          bankId: bankId,
          originalError: e,
        );
      }

      log('🚫 [EXCEL_DEBUG] Erro genérico');
      throw ExtractorException(
        'Erro ao processar arquivo Excel: ${e.toString()}',
        bankId: bankId,
        originalError: e,
      );
    }
  }

  /// Encontra a primeira planilha que contém dados
  String? _findDataSheet(Excel excel) {
    log('🔍 [EXCEL_DEBUG] _findDataSheet: Analisando ${excel.tables.keys.length} planilhas');

    for (final sheetName in excel.tables.keys) {
      log('📋 [EXCEL_DEBUG] Verificando planilha: $sheetName');
      final sheet = excel.tables[sheetName];

      if (sheet == null) {
        log('❌ [EXCEL_DEBUG] Planilha $sheetName é null');
        continue;
      }

      if (sheet.rows.isEmpty) {
        log('❌ [EXCEL_DEBUG] Planilha $sheetName está vazia');
        continue;
      }

      log('📊 [EXCEL_DEBUG] Planilha $sheetName tem ${sheet.rows.length} linhas');

      // Verificar se tem pelo menos uma linha com dados (não só células vazias)
      for (int i = 0; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final hasData = row.any((cell) =>
          cell?.value != null &&
          cell!.value.toString().trim().isNotEmpty
        );
        if (hasData) {
          log('✅ [EXCEL_DEBUG] Planilha $sheetName tem dados na linha $i');
          return sheetName;
        }
      }
      log('⚠️ [EXCEL_DEBUG] Planilha $sheetName não tem dados válidos');
    }

    log('❌ [EXCEL_DEBUG] Nenhuma planilha com dados encontrada');
    return null;
  }

  /// Converte uma planilha Excel para formato CSV
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

          // Escapar vírgulas e aspas para formato CSV válido
          if (cellValue.contains(',') || cellValue.contains('"') || cellValue.contains('\n')) {
            cellValue = '"${cellValue.replaceAll('"', '""')}"';
          }
        }

        csvCells.add(cellValue);
      }

      // Só adicionar linhas que tenham pelo menos um valor não vazio
      if (csvCells.any((cell) => cell.isNotEmpty)) {
        csvLines.add(csvCells.join(','));
      }
    }

    return csvLines.join('\n');
  }
}