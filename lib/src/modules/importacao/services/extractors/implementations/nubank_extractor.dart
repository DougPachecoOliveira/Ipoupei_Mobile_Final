// lib/src/modules/importacao/services/extractors/implementations/nubank_extractor.dart

import 'dart:io';
import '../base/bank_extractor.dart';
import '../../../models/transacao_importada_model.dart';
import '../../../../../auth_integration.dart';

/// Extractor específico para arquivos CSV do Nubank
///
/// Formatos suportados:
///
/// CONTA CORRENTE:
/// - Header: Data,Valor,Identificador,Descrição
/// - Separador: vírgula (,)
/// - Data: DD/MM/YYYY
/// - Decimal: ponto (.)
/// - Valor: Sinal indica tipo (negativo = despesa, positivo = receita)
///
/// CARTÃO DE CRÉDITO:
/// - Header: date,category,title,amount
/// - Separador: vírgula (,)
/// - Data: YYYY-MM-DD
/// - Decimal: ponto (.)
/// - Valor: Sempre positivo (cartão = despesa)
///
/// Características:
/// - Formato mais simples de todos os bancos
/// - Header limpo na linha 1
/// - Sem rodapé
/// - Sem BOM
/// - 4 colunas apenas
class NubankExtractor extends BankExtractor {
  final _authIntegration = AuthIntegration.instance;

  @override
  String get bankId => 'nubank';

  @override
  String get bankName => 'Nubank';

  @override
  int get priority => 75; // Alta prioridade - detecção específica

  @override
  bool canHandle(String content, String fileName) {
    // Estratégia 1: Nome do arquivo
    if (_detectByFileName(fileName)) {
      log('✅ Detectado por nome do arquivo');
      return true;
    }

    // Estratégia 2: Header específico
    if (_detectByHeader(content)) {
      log('✅ Detectado por header específico');
      return true;
    }

    return false;
  }

  /// Detecta pelo nome do arquivo
  bool _detectByFileName(String fileName) {
    final name = fileName.toLowerCase();

    // Padrões comuns de nomes de arquivo Nubank
    final patterns = [
      'nu_', // Padrão oficial: NU_88781580_01JUN2025_29JUN2025.csv
      'nubank',
      'conta_nubank',
    ];

    return patterns.any((pattern) => name.startsWith(pattern) || name.contains(pattern));
  }

  /// Detecta por header específico
  bool _detectByHeader(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty) return false;

    final header = lines[0].toLowerCase().trim();

    // Headers do Nubank

    // Conta corrente: Data,Valor,Identificador,Descrição
    final isContaCorrente = header == 'data,valor,identificador,descrição' ||
                           header == 'data,valor,identificador,descricao' || // Sem acento
                           (header.contains('data') && header.contains('valor') && header.contains('identificador') &&
                            (header.contains('descrição') || header.contains('descricao')));

    // Cartão de crédito: date,category,title,amount
    final isCartaoCredito = header == 'date,category,title,amount' ||
                           (header.contains('date') && header.contains('category') &&
                            header.contains('title') && header.contains('amount'));

    return isContaCorrente || isCartaoCredito;
  }

  /// Detecta o tipo de arquivo Nubank (conta corrente ou cartão de crédito)
  String _detectNubankType(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty) return 'conta_corrente'; // Default

    final header = lines[0].toLowerCase().trim();

    // Cartão de crédito: date,category,title,amount
    if (header == 'date,category,title,amount' ||
        (header.contains('date') && header.contains('category') &&
         header.contains('title') && header.contains('amount'))) {
      return 'cartao_credito';
    }

    // Default: conta corrente
    return 'conta_corrente';
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
      if (lines.length < 2) {
        throw ExtractorException(
          'Arquivo muito curto. Mínimo esperado: 2 linhas (header + dados)',
          bankId: bankId,
        );
      }

      // Validar header
      if (!_detectByHeader(content)) {
        throw ExtractorException(
          'Header inválido. Esperado formato Nubank: Data,Valor,Identificador,Descrição ou date,category,title,amount',
          bankId: bankId,
        );
      }

      // Detectar tipo do arquivo
      final nubankType = _detectNubankType(content);
      log('🏦 Header Nubank válido detectado - Tipo: $nubankType');

      // Processar transações (linha 1 em diante, pular header)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();

        // Pular linhas vazias
        if (line.isEmpty) continue;

        try {
          final transacao = _extractTransactionFromLine(
            line,
            i,
            userId,
            nubankType,
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
        'Erro ao processar arquivo Nubank: ${e.toString()}',
        bankId: bankId,
        originalError: e,
      );
    }
  }

  /// Extrai transação de uma linha
  TransacaoImportada? _extractTransactionFromLine(
    String line,
    int lineIndex,
    String userId,
    String nubankType, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) {
    // Parse CSV inteligente que lida com vírgulas na descrição
    final parts = _parseCSVLine(line);

    // Validar número de colunas
    if (parts.length < 4) {
      log('⚠️ Linha $lineIndex ignorada: menos de 4 colunas (${parts.length})');
      return null;
    }

    String dataStr, valorStr, uuid, descricao;

    if (nubankType == 'cartao_credito') {
      // Formato cartão: date,category,title,amount
      dataStr = parts[0].trim(); // date (YYYY-MM-DD)
      final categoria = parts[1].trim(); // category
      descricao = parts[2].trim(); // title
      valorStr = parts[3].trim(); // amount
      uuid = 'cartao_${DateTime.now().millisecondsSinceEpoch}_$lineIndex'; // Gerar UUID único

      // Para cartão, incluir categoria na descrição se disponível
      if (categoria.isNotEmpty && categoria != descricao) {
        descricao = '$categoria - $descricao';
      }
    } else {
      // Formato conta corrente: Data,Valor,Identificador,Descrição
      dataStr = parts[0].trim();
      valorStr = parts[1].trim();
      uuid = parts[2].trim();
      descricao = parts[3].trim();
    }

    // Validações básicas
    if (dataStr.isEmpty || valorStr.isEmpty || descricao.isEmpty) {
      log('⚠️ Linha $lineIndex ignorada: campos obrigatórios vazios');
      return null;
    }

    // Parse data
    final data = _parseDate(dataStr, nubankType);
    if (data == null) {
      log('⚠️ Linha $lineIndex ignorada: data inválida "$dataStr"');
      return null;
    }

    // Parse valor
    final valor = double.tryParse(valorStr);
    if (valor == null || valor == 0.0) {
      log('⚠️ Linha $lineIndex ignorada: valor inválido "$valorStr"');
      return null;
    }

    // Tipo baseado no formato
    String tipo;
    double valorAbsoluto;

    if (nubankType == 'cartao_credito') {
      // Cartão de crédito: sempre despesa, valor sempre positivo
      tipo = 'despesa';
      valorAbsoluto = valor.abs();
    } else {
      // Conta corrente: sinal indica tipo (negativo = despesa, positivo = receita)
      tipo = valor < 0 ? 'despesa' : 'receita';
      valorAbsoluto = valor.abs();
    }

    // Extrair informações do PIX da descrição (se houver)
    final pixInfo = _extractPixInfo(descricao);

    // Criar transação
    return TransacaoImportada(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}_$lineIndex',
      data: data,
      descricao: descricao,
      valor: valorAbsoluto,
      tipo: tipo,
      origem: 'Nubank CSV',
      usuarioId: userId,
      contaId: contaId,
      cartaoId: cartaoId,
      faturaVencimento: faturaVencimento,
      efetivado: false,
      observacoes: '',
      linhaBruta: line,
      indiceOriginal: lineIndex,
      metadados: {
        'banco': bankName,
        'bankId': bankId,
        'nubankType': nubankType, // Tipo detectado (conta_corrente ou cartao_credito)
        'uuid': uuid,
        'valorOriginal': valor, // Manter valor com sinal original
        'tipoImportacao': tipoImportacao,
        ...pixInfo, // Adicionar informações do PIX se houver
      },
    );
  }

  /// Parse data nos formatos DD/MM/YYYY (conta corrente) ou YYYY-MM-DD (cartão de crédito)
  DateTime? _parseDate(String value, String nubankType) {
    try {
      // Remover espaços
      final cleaned = value.trim();

      if (nubankType == 'cartao_credito') {
        // Formato YYYY-MM-DD
        final match = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(cleaned);
        if (match != null) {
          final year = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final day = int.parse(match.group(3)!);

          return DateTime(year, month, day);
        }
      } else {
        // Formato DD/MM/YYYY (conta corrente)
        final match = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(cleaned);
        if (match != null) {
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final year = int.parse(match.group(3)!);

          return DateTime(year, month, day);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Extrai informações do PIX da descrição
  Map<String, dynamic> _extractPixInfo(String descricao) {
    final pixInfo = <String, dynamic>{};

    // Detectar se é PIX
    if (descricao.toLowerCase().contains('pix')) {
      pixInfo['isPix'] = true;

      // Detectar tipo de PIX
      if (descricao.toLowerCase().contains('transferência enviada')) {
        pixInfo['pixTipo'] = 'enviado';
      } else if (descricao.toLowerCase().contains('transferência recebida')) {
        pixInfo['pixTipo'] = 'recebido';
      }

      // Tentar extrair nome do destinatário/remetente
      final match = RegExp(r'- ([A-ZÁÇÃÕÉÍÓÚÊ\s]+)').firstMatch(descricao);
      if (match != null) {
        pixInfo['pixNome'] = match.group(1)?.trim();
      }
    } else {
      pixInfo['isPix'] = false;
    }

    return pixInfo;
  }

  /// Parse inteligente de linha CSV que lida com vírgulas na descrição
  ///
  /// Como o Nubank não usa aspas, assumimos que apenas os primeiros 3 campos
  /// são separados por vírgula, e todo o resto é a descrição
  List<String> _parseCSVLine(String line) {
    final parts = <String>[];
    int commaCount = 0;
    int startIndex = 0;

    // Encontrar as primeiras 3 vírgulas (data, valor, identificador)
    for (int i = 0; i < line.length; i++) {
      if (line[i] == ',') {
        // Adicionar a parte atual
        parts.add(line.substring(startIndex, i));
        startIndex = i + 1;
        commaCount++;

        // Se encontrou 3 vírgulas, o resto é a descrição
        if (commaCount == 3) {
          parts.add(line.substring(startIndex)); // Todo o resto é descrição
          break;
        }
      }
    }

    // Se não encontrou 3 vírgulas, fallback para split simples
    if (parts.length < 4) {
      return line.split(',');
    }

    return parts;
  }
}