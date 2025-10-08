// 🚀 Enhanced Excel Extractor - iPoupei Mobile
//
// Extrator robusto para planilhas Excel que detecta automaticamente
// formatos de dados financeiros e extrai transações de forma inteligente
//
// Features:
// - Detecção automática de formato de dados
// - Suporte a múltiplas planilhas
// - Análise inteligente de colunas
// - Tratamento de diferentes formatos de data e valor
// - Extração flexível sem dependência de formato específico

import 'dart:io';
import 'dart:developer';
import 'package:excel/excel.dart';
import '../models/transacao_importada_model.dart';
import '../../../auth_integration.dart';

/// Extrator avançado para arquivos Excel
class EnhancedExcelExtractor {
  static final EnhancedExcelExtractor _instance = EnhancedExcelExtractor._internal();
  static EnhancedExcelExtractor get instance => _instance;
  EnhancedExcelExtractor._internal();

  final _authIntegration = AuthIntegration.instance;

  /// Processa arquivo Excel com detecção automática inteligente
  Future<List<TransacaoImportada>> processarArquivoExcel(
    File file, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) async {
    try {
      log('🚀 ENHANCED EXCEL: Iniciando processamento de ${file.path}');

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception('Arquivo Excel não contém planilhas');
      }

      // Analisar todas as planilhas para encontrar a melhor
      Sheet? melhorPlanilha;
      String? melhorNome;
      int melhorScore = 0;

      for (final entry in excel.tables.entries) {
        final nome = entry.key;
        final planilha = entry.value;

        if (planilha.rows.isEmpty) continue;

        final score = _avaliarPlanilha(planilha, nome);
        log('📊 Planilha "$nome": score=$score (${planilha.rows.length} linhas)');

        if (score > melhorScore) {
          melhorScore = score;
          melhorPlanilha = planilha;
          melhorNome = nome;
        }
      }

      if (melhorPlanilha == null) {
        throw Exception('Nenhuma planilha válida encontrada');
      }

      log('🎯 Usando planilha "$melhorNome" (score: $melhorScore)');

      // Extrair transações da melhor planilha
      final transacoes = await _extrairTransacoesDaPlanilha(
        melhorPlanilha,
        file.path.split('/').last,
        tipoImportacao: tipoImportacao,
        contaId: contaId,
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
      );

      log('✅ ENHANCED EXCEL: ${transacoes.length} transações extraídas');
      return transacoes;

    } catch (e) {
      log('❌ Erro no Enhanced Excel Extractor: $e');
      rethrow;
    }
  }

  /// Avalia uma planilha para determinar se contém dados financeiros relevantes
  int _avaliarPlanilha(Sheet planilha, String nome) {
    int score = 0;

    // Bonificar por nome sugestivo
    final nomeLower = nome.toLowerCase();
    if (nomeLower.contains('extrato') || nomeLower.contains('transac') ||
        nomeLower.contains('moviment') || nomeLower.contains('fatura') ||
        nomeLower.contains('cobranca') || nomeLower.contains('lancament')) {
      score += 20;
    }

    // Penalizar planilhas muito pequenas ou muito grandes
    final numLinhas = planilha.rows.length;
    if (numLinhas < 5) {
      score -= 10;
    } else if (numLinhas > 10000) {
      score -= 5;
    } else if (numLinhas > 50) {
      score += 10;
    }

    // Analisar primeiras linhas para detectar padrões financeiros
    final primeirasLinhas = planilha.rows.take(10).toList();
    int contadorDatas = 0;
    int contadorValores = 0;
    int contadorTextos = 0;

    for (final linha in primeirasLinhas) {
      for (final celula in linha) {
        final valor = _obterValorCelula(celula);
        if (valor.isEmpty) continue;

        if (_isDateLike(valor)) {
          contadorDatas++;
        } else if (_isValueLike(valor)) {
          contadorValores++;
        } else if (valor.length > 3 && !_isNumericOnly(valor)) {
          contadorTextos++;
        }
      }
    }

    // Bonificar presença balanceada de datas, valores e textos
    if (contadorDatas >= 3) score += 15;
    if (contadorValores >= 3) score += 15;
    if (contadorTextos >= 5) score += 10;

    // Bonificar se tem uma boa mistura
    if (contadorDatas >= 2 && contadorValores >= 2 && contadorTextos >= 3) {
      score += 20;
    }

    return score;
  }

  /// Extrai transações de uma planilha específica
  Future<List<TransacaoImportada>> _extrairTransacoesDaPlanilha(
    Sheet planilha,
    String fileName, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) async {
    final transacoes = <TransacaoImportada>[];
    final userId = _authIntegration.authService.currentUser?.id ?? '';

    // Detectar automaticamente o mapeamento de colunas
    final mapeamento = _detectarMapeamentoColunas(planilha);
    log('🗺️ Mapeamento detectado: $mapeamento');

    if (mapeamento['dataCol'] == -1 || mapeamento['descricaoCol'] == -1) {
      throw Exception('Não foi possível detectar colunas essenciais (data/descrição)');
    }

    // Determinar linha de início (pulando headers)
    int linhaInicio = (mapeamento['temHeader'] as int) == 1 ? 1 : 0;

    // Se detectou header mas as primeiras linhas parecem dados, ajustar
    if ((mapeamento['temHeader'] as int) == 1 && linhaInicio < planilha.rows.length) {
      final primeiraLinhaDados = planilha.rows[linhaInicio];
      bool pareceHeader = true;

      for (int col = 0; col < primeiraLinhaDados.length && col < 5; col++) {
        final valor = _obterValorCelula(primeiraLinhaDados[col]);
        if (_isDateLike(valor) || _isValueLike(valor)) {
          pareceHeader = false;
          break;
        }
      }

      if (pareceHeader && linhaInicio + 1 < planilha.rows.length) {
        linhaInicio++;
        log('📋 Pulando linha adicional de header');
      }
    }

    log('📊 Processando a partir da linha $linhaInicio (${planilha.rows.length - linhaInicio} linhas de dados)');

    // Processar cada linha de dados
    for (int i = linhaInicio; i < planilha.rows.length; i++) {
      try {
        final linha = planilha.rows[i];
        final transacao = _extrairTransacaoDaLinha(
          linha,
          i,
          mapeamento,
          fileName,
          userId,
          tipoImportacao: tipoImportacao,
          contaId: contaId,
          cartaoId: cartaoId,
          faturaVencimento: faturaVencimento,
        );

        if (transacao != null) {
          transacoes.add(transacao);
        }
      } catch (e) {
        log('⚠️ Erro ao processar linha $i: $e');
        continue;
      }
    }

    return transacoes;
  }

  /// Detecta automaticamente o mapeamento das colunas
  Map<String, dynamic> _detectarMapeamentoColunas(Sheet planilha) {
    if (planilha.rows.isEmpty) {
      return {'dataCol': -1, 'descricaoCol': -1, 'valorCol': -1, 'temHeader': false};
    }

    final primeiraLinha = planilha.rows[0];
    final numColunas = primeiraLinha.length;

    // Verificar se primeira linha é header
    bool temHeader = _detectarHeader(primeiraLinha);

    // Se tem header, analisar nomes das colunas
    if (temHeader) {
      final mapeamento = _mapearPorNomesColunas(primeiraLinha);
      if (mapeamento['dataCol'] != -1 && mapeamento['descricaoCol'] != -1) {
        mapeamento['temHeader'] = 1;
        return mapeamento;
      }
    }

    // Analisar padrões nas primeiras linhas de dados
    final linhasAnalise = planilha.rows.skip(temHeader ? 1 : 0).take(5).toList();
    if (linhasAnalise.isEmpty) {
      return {'dataCol': -1, 'descricaoCol': -1, 'valorCol': -1, 'temHeader': temHeader ? 1 : 0};
    }

    // Analisar cada coluna
    final scoresColunas = <int, Map<String, int>>{};

    for (int col = 0; col < numColunas; col++) {
      scoresColunas[col] = {'data': 0, 'valor': 0, 'texto': 0, 'vazio': 0};

      for (final linha in linhasAnalise) {
        if (col < linha.length) {
          final valor = _obterValorCelula(linha[col]);

          if (valor.isEmpty) {
            scoresColunas[col]!['vazio'] = scoresColunas[col]!['vazio']! + 1;
          } else if (_isDateLike(valor)) {
            scoresColunas[col]!['data'] = scoresColunas[col]!['data']! + 1;
          } else if (_isValueLike(valor)) {
            scoresColunas[col]!['valor'] = scoresColunas[col]!['valor']! + 1;
          } else if (valor.length > 2) {
            scoresColunas[col]!['texto'] = scoresColunas[col]!['texto']! + 1;
          }
        }
      }
    }

    // Encontrar melhores colunas
    int dataCol = -1, valorCol = -1, descricaoCol = -1;
    int maxDataScore = 0, maxValorScore = 0;

    for (int col = 0; col < numColunas; col++) {
      final scores = scoresColunas[col]!;

      // Coluna de data
      if (scores['data']! > maxDataScore && scores['data']! >= 2) {
        maxDataScore = scores['data']!;
        dataCol = col;
      }

      // Coluna de valor
      if (scores['valor']! > maxValorScore && scores['valor']! >= 2) {
        maxValorScore = scores['valor']!;
        valorCol = col;
      }
    }

    // Coluna de descrição (melhor coluna de texto que não seja data nem valor)
    int maxTextoScore = 0;
    for (int col = 0; col < numColunas; col++) {
      if (col == dataCol || col == valorCol) continue;

      final scores = scoresColunas[col]!;
      if (scores['texto']! > maxTextoScore && scores['vazio']! < 3) {
        maxTextoScore = scores['texto']!;
        descricaoCol = col;
      }
    }

    log('📊 Análise de colunas:');
    for (int col = 0; col < numColunas; col++) {
      final scores = scoresColunas[col]!;
      final tipo = col == dataCol ? ' [DATA]' :
                  col == valorCol ? ' [VALOR]' :
                  col == descricaoCol ? ' [DESC]' : '';
      log('   Col $col: data=${scores['data']}, valor=${scores['valor']}, texto=${scores['texto']}, vazio=${scores['vazio']}$tipo');
    }

    return {
      'dataCol': dataCol,
      'descricaoCol': descricaoCol,
      'valorCol': valorCol,
      'temHeader': temHeader ? 1 : 0,
    };
  }

  /// Detecta se a primeira linha é um cabeçalho
  bool _detectarHeader(List<Cell?> primeiraLinha) {
    int contadorTexto = 0;
    int contadorData = 0;
    int contadorValor = 0;

    for (final celula in primeiraLinha) {
      final valor = _obterValorCelula(celula);
      if (valor.isEmpty) continue;

      if (_isDateLike(valor)) {
        contadorData++;
      } else if (_isValueLike(valor)) {
        contadorValor++;
      } else if (valor.length > 3) {
        contadorTexto++;
      }
    }

    // Se tem mais texto que dados, provavelmente é header
    return contadorTexto > (contadorData + contadorValor);
  }

  /// Mapeia colunas baseado nos nomes dos headers
  Map<String, int> _mapearPorNomesColunas(List<Cell?> headerRow) {
    int dataCol = -1, valorCol = -1, descricaoCol = -1;

    for (int i = 0; i < headerRow.length; i++) {
      final nome = _obterValorCelula(headerRow[i]).toLowerCase();

      // Detectar coluna de data
      if ((nome.contains('data') || nome.contains('date') ||
           nome.contains('vencimento') || nome.contains('movimen')) && dataCol == -1) {
        dataCol = i;
      }

      // Detectar coluna de valor
      else if ((nome.contains('valor') || nome.contains('value') ||
                nome.contains('amount') || nome.contains('preco') ||
                nome.contains('total') || nome.contains('quantia')) && valorCol == -1) {
        valorCol = i;
      }

      // Detectar coluna de descrição
      else if ((nome.contains('descri') || nome.contains('historico') ||
                nome.contains('description') || nome.contains('produto') ||
                nome.contains('estabelecimento') || nome.contains('comercio') ||
                nome.contains('memo') || nome.contains('detalhes')) && descricaoCol == -1) {
        descricaoCol = i;
      }
    }

    return {
      'dataCol': dataCol,
      'descricaoCol': descricaoCol,
      'valorCol': valorCol,
    };
  }

  /// Extrai uma transação de uma linha específica
  TransacaoImportada? _extrairTransacaoDaLinha(
    List<Cell?> linha,
    int indice,
    Map<String, dynamic> mapeamento,
    String fileName,
    String userId, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) {
    try {
      // Extrair dados usando mapeamento
      DateTime? data;
      String descricao = '';
      double valor = 0.0;

      // Data
      final dataCol = mapeamento['dataCol'] as int;
      if (dataCol >= 0 && dataCol < linha.length) {
        data = _parseDate(_obterValorCelula(linha[dataCol]));
      }

      // Descrição
      final descricaoCol = mapeamento['descricaoCol'] as int;
      if (descricaoCol >= 0 && descricaoCol < linha.length) {
        descricao = _obterValorCelula(linha[descricaoCol]).trim();
      }

      // Valor
      final valorCol = mapeamento['valorCol'] as int;
      if (valorCol >= 0 && valorCol < linha.length) {
        valor = _parseValue(_obterValorCelula(linha[valorCol]));
      }

      // Se não conseguiu valor na coluna mapeada, procurar em outras colunas
      if (valor == 0.0) {
        for (int i = 0; i < linha.length; i++) {
          if (i == dataCol || i == descricaoCol) continue;

          final valorTeste = _parseValue(_obterValorCelula(linha[i]));
          if (valorTeste != 0.0) {
            valor = valorTeste;
            break;
          }
        }
      }

      // Se não conseguiu descrição, procurar melhor coluna de texto
      if (descricao.isEmpty) {
        for (int i = 0; i < linha.length; i++) {
          if (i == dataCol || i == valorCol) continue;

          final textoTeste = _obterValorCelula(linha[i]).trim();
          if (textoTeste.length > 3 && !_isDateLike(textoTeste) && !_isValueLike(textoTeste)) {
            descricao = textoTeste;
            break;
          }
        }
      }

      // Validar dados mínimos
      if (data == null || descricao.isEmpty || valor == 0.0) {
        return null;
      }

      // Determinar tipo da transação
      String tipo = valor > 0 ? 'receita' : 'despesa';
      valor = valor.abs();

      return TransacaoImportada(
        id: 'excel_${DateTime.now().millisecondsSinceEpoch}_$indice',
        data: data,
        descricao: descricao,
        valor: valor,
        tipo: tipo,
        origem: 'Excel Enhanced',
        usuarioId: userId,
        contaId: contaId,
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
        efetivado: false,
        observacoes: 'Importado via Enhanced Excel Extractor',
        linhaBruta: linha.map((c) => _obterValorCelula(c)).join('|'),
        indiceOriginal: indice,
        metadados: {
          'extractor': 'Enhanced Excel',
          'fileName': fileName,
          'dataCol': dataCol,
          'descricaoCol': descricaoCol,
          'valorCol': valorCol,
          'originalLine': indice,
        },
      );

    } catch (e) {
      log('❌ Erro ao extrair transação da linha $indice: $e');
      return null;
    }
  }

  /// Obtém valor da célula como string
  String _obterValorCelula(Cell? celula) {
    if (celula == null) return '';

    final valor = celula.value;
    if (valor == null) return '';

    return valor.toString().trim();
  }

  /// Verifica se texto parece uma data
  bool _isDateLike(String text) {
    if (text.length < 6) return false;

    final patterns = [
      RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}'),
      RegExp(r'\d{4}[/-]\d{1,2}[/-]\d{1,2}'),
      RegExp(r'\d{1,2}\.\d{1,2}\.\d{2,4}'),
    ];

    return patterns.any((p) => p.hasMatch(text));
  }

  /// Verifica se texto parece um valor monetário
  bool _isValueLike(String text) {
    if (text.length < 1) return false;

    final cleaned = text.replaceAll(RegExp(r'[R$\s€£¥]'), '').trim();
    if (cleaned.isEmpty) return false;

    // Aceitar formatos como: 123.45, 1,234.56, 1.234,56, -123.45, (123.45)
    final patterns = [
      RegExp(r'^-?\d+[,.]?\d*$'),
      RegExp(r'^-?\d{1,3}([,.]\d{3})*[,.]?\d{0,2}$'),
      RegExp(r'^\(\d+[,.]?\d*\)$'), // Para valores negativos em parênteses
    ];

    return patterns.any((p) => p.hasMatch(cleaned));
  }

  /// Verifica se texto é apenas numérico
  bool _isNumericOnly(String text) {
    return RegExp(r'^\d+$').hasMatch(text.trim());
  }

  /// Parse de data flexível
  DateTime? _parseDate(String text) {
    if (text.isEmpty) return null;

    try {
      // Tentar ISO format primeiro
      if (RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(text)) {
        return DateTime.parse(text.split(' ')[0]);
      }

      // DD/MM/YYYY ou DD/MM/YY
      if (RegExp(r'\d{1,2}/\d{1,2}/\d{2,4}').hasMatch(text)) {
        final parts = text.split('/');
        int ano = int.parse(parts[2]);
        if (ano < 100) ano += (ano < 50) ? 2000 : 1900;
        return DateTime(ano, int.parse(parts[1]), int.parse(parts[0]));
      }

      // DD-MM-YYYY
      if (RegExp(r'\d{1,2}-\d{1,2}-\d{2,4}').hasMatch(text)) {
        final parts = text.split('-');
        int ano = int.parse(parts[2]);
        if (ano < 100) ano += (ano < 50) ? 2000 : 1900;
        return DateTime(ano, int.parse(parts[1]), int.parse(parts[0]));
      }

      // DD.MM.YYYY
      if (RegExp(r'\d{1,2}\.\d{1,2}\.\d{2,4}').hasMatch(text)) {
        final parts = text.split('.');
        int ano = int.parse(parts[2]);
        if (ano < 100) ano += (ano < 50) ? 2000 : 1900;
        return DateTime(ano, int.parse(parts[1]), int.parse(parts[0]));
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse de valor monetário flexível
  double _parseValue(String text) {
    if (text.isEmpty) return 0.0;

    try {
      // Detectar se está em parênteses (valor negativo)
      bool isNegative = text.contains('(') && text.contains(')');

      // Limpar texto
      String cleaned = text
          .replaceAll(RegExp(r'[R$€£¥\s()]'), '')
          .replaceAll(RegExp(r'^-'), '')
          .trim();

      if (cleaned.isEmpty) return 0.0;

      // Se tem vírgula e ponto, determinar formato
      if (cleaned.contains(',') && cleaned.contains('.')) {
        final lastComma = cleaned.lastIndexOf(',');
        final lastDot = cleaned.lastIndexOf('.');

        if (lastComma > lastDot) {
          // Formato brasileiro: 1.234.567,89
          cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // Formato americano: 1,234,567.89
          cleaned = cleaned.replaceAll(',', '');
        }
      } else if (cleaned.contains(',')) {
        // Apenas vírgula - verificar se é separador decimal
        final parts = cleaned.split(',');
        if (parts.length == 2 && parts[1].length <= 2) {
          // Decimal: 123,45
          cleaned = cleaned.replaceAll(',', '.');
        } else {
          // Separador de milhares: 1,234
          cleaned = cleaned.replaceAll(',', '');
        }
      }

      double valor = double.parse(cleaned);
      return isNegative ? -valor : valor;

    } catch (e) {
      return 0.0;
    }
  }
}