// 🚗 Conectcar Excel Extractor - iPoupei Mobile
//
// Extrator específico para arquivos Excel (.xlsx) do Conectcar
// Processa extratos com colunas: Data do lançamento, Veículo, Descrição da transação, Débito
// Concatena Veículo + Descrição da transação para formar a descrição final
//
// Baseado em: excel package + ImportacaoService pattern

import 'dart:io';
import 'dart:developer';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import '../models/transacao_importada_model.dart';
import '../../../auth_integration.dart';

/// Extrator específico para arquivos Excel do Conectcar
class ConectcarExtractor {
  final _authIntegration = AuthIntegration.instance;

  /// Processa arquivo Excel do Conectcar e retorna lista de transações
  Future<List<TransacaoImportada>> processarArquivoConectcar(
    File file, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) async {
    try {
      log('🚗 ConectcarExtractor: Iniciando processamento de ${file.path}');

      // Ler arquivo Excel com tratamento de erro mais robusto
      final bytes = await file.readAsBytes();
      log('📊 Arquivo lido: ${bytes.length} bytes');

      Excel? excel;

      try {
        // Primeira tentativa: validar header do arquivo
        if (bytes.length < 8) {
          throw Exception('Arquivo muito pequeno para ser Excel válido');
        }

        // Verificar se os primeiros bytes indicam um arquivo Excel válido
        final header = bytes.take(8).toList();
        final headerHex = header.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
        log('📊 Header do arquivo: $headerHex');

        // Headers válidos para Excel .xlsx (ZIP-based)
        final isValidExcel = (header[0] == 0x50 && header[1] == 0x4B) || // PK (ZIP signature)
                             (header[0] == 0xD0 && header[1] == 0xCF); // Old Excel format

        if (!isValidExcel) {
          throw Exception('Header do arquivo não indica formato Excel válido');
        }

        // Tentativa de decodificação normal
        excel = Excel.decodeBytes(bytes);
        log('✅ Decodificação Excel bem-sucedida');
      } catch (e) {
        log('❌ Erro na decodificação Excel: $e');

        // Tentar fallback para CSV se o nome do arquivo sugere Conectcar
        final fileName = file.path.split('/').last.toLowerCase();
        if (fileName.contains('conectcar')) {
          log('🔄 Tentando processar como CSV Conectcar...');
          try {
            return await processarArquivoConectcarCSV(
              file,
              tipoImportacao: tipoImportacao,
              contaId: contaId,
              cartaoId: cartaoId,
              faturaVencimento: faturaVencimento,
            );
          } catch (csvError) {
            log('❌ Fallback CSV também falhou: $csvError');
          }
        }

        final fileSize = await file.length();
        log('💾 Arquivo tem ${fileSize} bytes');

        throw Exception(
          '🚗 ARQUIVO CONECTCAR NÃO PODE SER LIDO\n\n'
          '📋 SOLUÇÕES SIMPLES:\n\n'
          '1️⃣ CONVERTA PARA CSV:\n'
          '   • Abra o arquivo no Excel ou Google Sheets\n'
          '   • Menu: Arquivo → Salvar Como → CSV\n'
          '   • Importe o arquivo CSV aqui no app\n\n'
          '2️⃣ BAIXE NOVAMENTE:\n'
          '   • Acesse o site do Conectcar\n'
          '   • Baixe o extrato em formato Excel (.xlsx)\n'
          '   • Tente importar o novo arquivo\n\n'
          '3️⃣ FORMATO SUPORTADO:\n'
          '   • Use arquivos .xlsx (Excel moderno)\n'
          '   • Use arquivos .csv (mais compatível)\n\n'
          '🔍 DIAGNÓSTICO:\n'
          '   Arquivo: ${file.path.split('/').last}\n'
          '   Tamanho: ${(fileSize / 1024).toStringAsFixed(1)} KB\n'
          '   Erro: $e\n\n'
          '💡 DICA: CSV é mais confiável que Excel!'
        );
      }

      // Encontrar a primeira planilha (normalmente 'Sheet1' ou similar)
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null) {
        throw Exception('Planilha não encontrada no arquivo Excel');
      }

      log('📊 Planilha encontrada: $sheetName (${sheet.maxRows} linhas, ${sheet.maxColumns} colunas)');

      // Procurar linha com cabeçalho específico do Conectcar
      int? headerRowIndex;
      Map<String, int> columnIndexes = {};

      for (int rowIndex = 0; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.rows[rowIndex];

        // Converter células para string e verificar se contém o cabeçalho esperado
        final rowText = row.map((cell) => cell?.value?.toString() ?? '').join('|').toLowerCase();

        if (rowText.contains('data do lançamento') &&
            rowText.contains('veículo') &&
            rowText.contains('descrição da transação') &&
            rowText.contains('débito')) {

          headerRowIndex = rowIndex;
          log('📋 Cabeçalho encontrado na linha $rowIndex');

          // Mapear índices das colunas
          for (int colIndex = 0; colIndex < row.length; colIndex++) {
            final cellValue = row[colIndex]?.value?.toString()?.toLowerCase() ?? '';

            if (cellValue.contains('data do lançamento') || cellValue.contains('data')) {
              columnIndexes['data'] = colIndex;
            } else if (cellValue.contains('veículo')) {
              columnIndexes['veiculo'] = colIndex;
            } else if (cellValue.contains('descrição da transação') || cellValue.contains('descrição')) {
              columnIndexes['descricao'] = colIndex;
            } else if (cellValue.contains('débito') || cellValue.contains('valor')) {
              columnIndexes['valor'] = colIndex;
            }
          }
          break;
        }
      }

      if (headerRowIndex == null) {
        throw Exception('Cabeçalho do Conectcar não encontrado. Verifique se o arquivo contém as colunas: "Data do lançamento, Veículo, Descrição da transação, Débito"');
      }

      log('🗂️ Colunas mapeadas: $columnIndexes');

      // Verificar se todas as colunas necessárias foram encontradas
      final requiredColumns = ['data', 'veiculo', 'descricao', 'valor'];
      for (final col in requiredColumns) {
        if (!columnIndexes.containsKey(col)) {
          log('⚠️ Coluna não encontrada: $col');
        }
      }

      // Processar linhas de dados
      final transacoes = <TransacaoImportada>[];
      final userId = _authIntegration.authService.currentUser?.id ?? '';
      int transactionIndex = 0;

      for (int rowIndex = headerRowIndex + 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.rows[rowIndex];

        try {
          // Extrair dados da linha
          final dataStr = _getCellValue(row, columnIndexes['data']);
          final veiculo = _getCellValue(row, columnIndexes['veiculo']);
          final descricaoTransacao = _getCellValue(row, columnIndexes['descricao']);
          final valorStr = _getCellValue(row, columnIndexes['valor']);

          // Pular linhas vazias
          if (dataStr.isEmpty && veiculo.isEmpty && descricaoTransacao.isEmpty && valorStr.isEmpty) {
            continue;
          }

          // Processar data
          final data = _parseDate(dataStr);
          if (data == null) {
            log('⚠️ Data inválida na linha $rowIndex: $dataStr');
            continue;
          }

          // Processar valor (débito = despesa)
          final valor = _parseValue(valorStr);
          if (valor <= 0) {
            log('⚠️ Valor inválido na linha $rowIndex: $valorStr');
            continue;
          }

          // Criar descrição concatenando Veículo + Descrição da transação
          String descricaoFinal = '';
          if (veiculo.isNotEmpty && descricaoTransacao.isNotEmpty) {
            descricaoFinal = '$veiculo - $descricaoTransacao';
          } else if (veiculo.isNotEmpty) {
            descricaoFinal = veiculo;
          } else if (descricaoTransacao.isNotEmpty) {
            descricaoFinal = descricaoTransacao;
          } else {
            descricaoFinal = 'Transação Conectcar';
          }

          // Criar transação
          final transacao = TransacaoImportada(
            id: 'conectcar_${DateTime.now().millisecondsSinceEpoch}_${transactionIndex++}',
            data: data,
            descricao: descricaoFinal,
            valor: valor,
            tipo: 'despesa', // Conectcar é sempre despesa (débito)
            origem: 'Conectcar',
            usuarioId: userId,
            contaId: contaId,
            cartaoId: cartaoId,
            faturaVencimento: faturaVencimento,
            efetivado: false,
            observacoes: 'Importado de extrato Conectcar',
            linhaBruta: row.map((cell) => cell?.value?.toString() ?? '').join('|'),
            indiceOriginal: rowIndex,
            metadados: {
              'banco': 'Conectcar',
              'formatType': 'xlsx',
              'veiculo': veiculo,
              'descricaoOriginal': descricaoTransacao,
              'extractedAt': DateTime.now().toIso8601String(),
              'sourceFile': file.path.split('/').last,
            },
          );

          transacoes.add(transacao);
          log('✅ Transação Conectcar extraída: $descricaoFinal - R\$ ${valor.toStringAsFixed(2)}');

        } catch (e) {
          log('⚠️ Erro ao processar linha $rowIndex: $e');
          continue;
        }
      }

      log('🎯 ConectcarExtractor: ${transacoes.length} transações processadas');
      return transacoes;

    } catch (e) {
      log('❌ Erro no processamento Conectcar: $e');
      rethrow;
    }
  }

  /// Obtém valor da célula de forma segura
  String _getCellValue(List<Data?> row, int? columnIndex) {
    if (columnIndex == null || columnIndex >= row.length) {
      return '';
    }

    final cell = row[columnIndex];
    if (cell?.value == null) {
      return '';
    }

    return cell!.value.toString().trim();
  }

  /// Parse de data flexível para formatos Excel
  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    try {
      // Primeiro, tentar como número (Excel date serial)
      final doubleValue = double.tryParse(dateStr);
      if (doubleValue != null) {
        // Excel dates são número de dias desde 1900-01-01
        final excelEpoch = DateTime(1900, 1, 1);
        return excelEpoch.add(Duration(days: (doubleValue - 2).round())); // -2 para correção do Excel
      }

      // Tentar formatos de texto comuns
      dateStr = dateStr.replaceAll(RegExp(r'[^\d/\-.]'), ''); // Remover caracteres especiais

      // DD/MM/YYYY
      if (RegExp(r'\d{1,2}/\d{1,2}/\d{4}').hasMatch(dateStr)) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }

      // DD-MM-YYYY
      if (RegExp(r'\d{1,2}-\d{1,2}-\d{4}').hasMatch(dateStr)) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }

      // YYYY-MM-DD
      if (RegExp(r'\d{4}-\d{1,2}-\d{1,2}').hasMatch(dateStr)) {
        return DateTime.parse(dateStr);
      }

      return null;
    } catch (e) {
      log('⚠️ Erro ao parsear data: $dateStr - $e');
      return null;
    }
  }

  /// Parse de valor monetário flexível
  double _parseValue(String valueStr) {
    if (valueStr.isEmpty) return 0.0;

    try {
      // Remover símbolos de moeda e espaços
      String cleaned = valueStr
          .replaceAll(RegExp(r'[R$\s]'), '')
          .replaceAll('(', '-')
          .replaceAll(')', '')
          .trim();

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

      return double.parse(cleaned).abs(); // Sempre positivo
    } catch (e) {
      log('⚠️ Erro ao parsear valor: $valueStr - $e');
      return 0.0;
    }
  }

  /// Processa arquivo CSV do Conectcar (fallback quando Excel falha)
  Future<List<TransacaoImportada>> processarArquivoConectcarCSV(
    File file, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) async {
    try {
      log('🚗📄 ConectcarExtractor: Processando CSV como fallback');

      final content = await file.readAsString();
      final lines = const CsvToListConverter().convert(content);

      if (lines.isEmpty) {
        throw Exception('Arquivo CSV vazio');
      }

      // Procurar linha de cabeçalho
      int? headerRowIndex;
      Map<String, int> columnIndexes = {};

      for (int i = 0; i < lines.length; i++) {
        final row = lines[i];
        final rowText = row.join('|').toLowerCase();

        if (rowText.contains('data do lançamento') &&
            rowText.contains('veículo') &&
            rowText.contains('descrição da transação') &&
            rowText.contains('débito')) {

          headerRowIndex = i;
          log('📋 Cabeçalho CSV encontrado na linha $i');

          // Mapear colunas
          for (int j = 0; j < row.length; j++) {
            final cellValue = row[j].toString().toLowerCase();

            if (cellValue.contains('data do lançamento') || cellValue.contains('data')) {
              columnIndexes['data'] = j;
            } else if (cellValue.contains('veículo')) {
              columnIndexes['veiculo'] = j;
            } else if (cellValue.contains('descrição da transação') || cellValue.contains('descrição')) {
              columnIndexes['descricao'] = j;
            } else if (cellValue.contains('débito') || cellValue.contains('valor')) {
              columnIndexes['valor'] = j;
            }
          }
          break;
        }
      }

      if (headerRowIndex == null) {
        throw Exception('Cabeçalho do Conectcar não encontrado no CSV');
      }

      // Processar transações (mesmo código do Excel)
      final transacoes = <TransacaoImportada>[];
      final userId = _authIntegration.authService.currentUser?.id ?? '';
      int transactionIndex = 0;

      for (int i = headerRowIndex + 1; i < lines.length; i++) {
        final row = lines[i];

        try {
          final dataStr = _getCellValueFromList(row, columnIndexes['data']);
          final veiculo = _getCellValueFromList(row, columnIndexes['veiculo']);
          final descricaoTransacao = _getCellValueFromList(row, columnIndexes['descricao']);
          final valorStr = _getCellValueFromList(row, columnIndexes['valor']);

          if (dataStr.isEmpty && veiculo.isEmpty && descricaoTransacao.isEmpty && valorStr.isEmpty) {
            continue;
          }

          final data = _parseDate(dataStr);
          if (data == null) continue;

          final valor = _parseValue(valorStr);
          if (valor <= 0) continue;

          String descricaoFinal = '';
          if (veiculo.isNotEmpty && descricaoTransacao.isNotEmpty) {
            descricaoFinal = '$veiculo - $descricaoTransacao';
          } else if (veiculo.isNotEmpty) {
            descricaoFinal = veiculo;
          } else if (descricaoTransacao.isNotEmpty) {
            descricaoFinal = descricaoTransacao;
          } else {
            descricaoFinal = 'Transação Conectcar';
          }

          final transacao = TransacaoImportada(
            id: 'conectcar_csv_${DateTime.now().millisecondsSinceEpoch}_${transactionIndex++}',
            data: data,
            descricao: descricaoFinal,
            valor: valor,
            tipo: 'despesa',
            origem: 'Conectcar CSV',
            usuarioId: userId,
            contaId: contaId,
            cartaoId: cartaoId,
            faturaVencimento: faturaVencimento,
            efetivado: false,
            observacoes: 'Importado de CSV Conectcar',
            linhaBruta: row.join('|'),
            indiceOriginal: i,
            metadados: {
              'banco': 'Conectcar',
              'formatType': 'csv',
              'veiculo': veiculo,
              'descricaoOriginal': descricaoTransacao,
              'extractedAt': DateTime.now().toIso8601String(),
              'sourceFile': file.path.split('/').last,
            },
          );

          transacoes.add(transacao);
          log('✅ Transação CSV extraída: $descricaoFinal - R\$ ${valor.toStringAsFixed(2)}');

        } catch (e) {
          log('⚠️ Erro ao processar linha CSV $i: $e');
          continue;
        }
      }

      log('🎯 ConectcarExtractor CSV: ${transacoes.length} transações processadas');
      return transacoes;

    } catch (e) {
      log('❌ Erro no processamento CSV Conectcar: $e');
      rethrow;
    }
  }

  /// Obtém valor da célula de lista CSV
  String _getCellValueFromList(List<dynamic> row, int? columnIndex) {
    if (columnIndex == null || columnIndex >= row.length) {
      return '';
    }
    return row[columnIndex]?.toString()?.trim() ?? '';
  }

  /// Detecta se o arquivo é um extrato Conectcar
  static bool isConectcarFile(String fileName, List<List<dynamic>> sampleData) {
    // Verificar nome do arquivo
    final nameLower = fileName.toLowerCase();
    if (nameLower.contains('conectcar')) {
      return true;
    }

    // Verificar conteúdo das primeiras linhas
    for (final row in sampleData.take(10)) {
      final rowText = row.join('|').toLowerCase();
      if (rowText.contains('conectcar') ||
          (rowText.contains('data do lançamento') && rowText.contains('veículo'))) {
        return true;
      }
    }

    return false;
  }
}