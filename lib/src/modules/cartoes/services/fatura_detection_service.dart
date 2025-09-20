// 🔍 Fatura Detection Service - iPoupei Mobile
//
// Detecta faturas baseadas APENAS em transações (100% compatível React):
// - Busca TODAS as transações do período (efetivado = 1 E efetivado = 0)
// - Calcula status dinâmico: paga = todas efetivadas, aberta = tem pendentes
// - NÃO usa tabela faturas (apenas transações, igual React web)
//
// Baseado em: Sistema React em produção + dados reais Supabase

import 'dart:developer';
import '../models/fatura_model.dart';
import '../models/cartao_model.dart';
import '../../../database/local_database.dart';
import '../../../auth_integration.dart';

class FaturaDetectionService {
  static final FaturaDetectionService _instance = FaturaDetectionService._internal();
  static FaturaDetectionService get instance => _instance;
  FaturaDetectionService._internal();

  final LocalDatabase _localDb = LocalDatabase.instance;
  final AuthIntegration _authIntegration = AuthIntegration.instance;

  /// ✅ DETECTAR FATURA ATUAL DO CARTÃO (IGUAL REACT)
  /// LÓGICA CORRETA: Busca TODAS as transações do período (pagas E pendentes)
  Future<FaturaModel?> detectarFaturaAtual(CartaoModel cartao, {DateTime? mesReferencia}) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return null;

      // ✅ USAR MÊS DE REFERÊNCIA OU ATUAL
      final mesAtual = mesReferencia ?? DateTime.now();
      final anoMes = '${mesAtual.year}-${mesAtual.month.toString().padLeft(2, '0')}';
      
      
      // ✅ BUSCAR TODAS AS TRANSAÇÕES DO MÊS (pagas E pendentes) - igual React
      final todasTransacoesMes = await _buscarTodasTransacoesCartaoMes(cartao.id, mesAtual);
      
      if (todasTransacoesMes.isEmpty) {
        return null;
      }

      // ✅ AGRUPAR POR FATURA_VENCIMENTO (deve ter apenas uma data por busca)
      final faturaAtual = _processarTransacoesMes(todasTransacoesMes);
      
      if (faturaAtual == null) {
        return null;
      }

      // Calcular dados da fatura (pagas + pendentes)
      double valorTotal = 0.0;
      double valorPago = 0.0;
      int totalTransacoes = 0;
      bool temPendentes = false;
      bool temEstorno = false;
      bool temParcelas = false;

      for (final transacao in faturaAtual['transacoes']) {
        final valor = (transacao['valor'] as num?)?.toDouble() ?? 0.0;
        final efetivado = (transacao['efetivado'] as int?) == 1;
        final descricao = transacao['descricao'] as String? ?? '';
        final grupoParcelamento = transacao['grupo_parcelamento'];
        
        log('🔍 DEBUG Transação: ${transacao['id']}');
        log('   💰 Valor: $valor');
        log('   ✅ Efetivado: $efetivado');
        log('   📝 Descrição: "$descricao"');
        log('   📦 Grupo Parcelamento: $grupoParcelamento');
        
        // Detectar estorno (valor negativo ou descrição específica)
        if (valor < 0 || descricao.toLowerCase().contains('empréstimo para cobertura')) {
          temEstorno = true;
          log('   🔄 ESTORNO DETECTADO!');
        }
        
        // Detectar parcelas
        if (grupoParcelamento != null) {
          temParcelas = true;
          log('   📦 PARCELA DETECTADA!');
        }
        
        valorTotal += valor;
        if (efetivado) {
          valorPago += valor;
        } else {
          temPendentes = true;
        }
        totalTransacoes++;
      }

      final faturaVencimento = faturaAtual['fatura_vencimento'] as String;
      final faturaVencimentoDate = DateTime.parse(faturaVencimento);
      final isVencida = DateTime.now().isAfter(faturaVencimentoDate);
      
      log('🎯 DETERMINANDO STATUS:');
      log('   ❓ temPendentes: $temPendentes');
      log('   🔄 temEstorno: $temEstorno');
      log('   📦 temParcelas: $temParcelas');
      log('   💰 valorTotal: $valorTotal');
      log('   💳 valorPago: $valorPago');
      log('   ⏰ isVencida: $isVencida');
      
      // Determinar status mais específico da fatura
      String status;
      if (!temPendentes && temEstorno) {
        status = 'parcelado';  // Paga via parcelamento
        log('   ✅ STATUS: PARCELADO (sem pendentes + tem estorno)');
      } else if (!temPendentes && valorPago < valorTotal && valorPago > 0) {
        status = 'parcial';  // Paga parcialmente  
        log('   ✅ STATUS: PARCIAL (sem pendentes + pago < total)');
      } else if (!temPendentes && valorTotal > 0) {
        status = 'paga';  // Paga integralmente
        log('   ✅ STATUS: PAGA (sem pendentes + total > 0)');
      } else if (temPendentes && valorTotal > 0) {
        status = isVencida ? 'vencida' : 'aberta';  // Em aberto ou vencida
        log('   ✅ STATUS: ${status.toUpperCase()} (tem pendentes + total > 0)');
      } else {
        status = 'futura';  // Sem transações ainda
        log('   ✅ STATUS: FUTURA (sem transações)');
      }
      
      final isPaga = ['paga', 'parcelado', 'parcial'].contains(status);
      log('🏁 STATUS FINAL: $status (isPaga: $isPaga)');
      
      // Criar modelo de fatura dinâmico (igual React)
      final fatura = FaturaModel(
        id: '${cartao.id}_$faturaVencimento',
        cartaoId: cartao.id,
        usuarioId: userId,
        ano: DateTime.parse(faturaVencimento).year,
        mes: DateTime.parse(faturaVencimento).month,
        dataFechamento: _calcularDataFechamento(cartao, faturaVencimento),
        dataVencimento: DateTime.parse(faturaVencimento),
        valorTotal: valorTotal,
        valorPago: valorPago,
        valorMinimo: valorTotal * 0.15,
        status: status,
        paga: isPaga,
        dataPagamento: isPaga ? DateTime.now() : null, // Aproximação
        observacoes: 'Fatura $anoMes - $totalTransacoes transações',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sincronizado: true,
      );

      return fatura;

    } catch (e) {
      log('❌ Erro ao detectar fatura: $e');
      return null;
    }
  }

  /// ✅ BUSCAR TRANSAÇÕES PENDENTES DO CARTÃO (NÃO EFETIVADAS)
  Future<List<Map<String, dynamic>>> _buscarTransacoesPendentesCartao(String cartaoId) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return [];

      final result = await _localDb.database?.query(
        'transacoes',
        where: 'usuario_id = ? AND cartao_id = ? AND efetivado = 0 AND fatura_vencimento IS NOT NULL',
        whereArgs: [userId, cartaoId],
        orderBy: 'fatura_vencimento ASC',
      ) ?? [];

      return result;

    } catch (e) {
      log('❌ Erro ao buscar transações pendentes: $e');
      return [];
    }
  }

  /// ✅ BUSCAR TODAS AS TRANSAÇÕES DO CARTÃO EM UM MÊS ESPECÍFICO (pagas E pendentes)
  Future<List<Map<String, dynamic>>> _buscarTodasTransacoesCartaoMes(String cartaoId, DateTime mesReferencia) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return [];

      final anoMes = '${mesReferencia.year}-${mesReferencia.month.toString().padLeft(2, '0')}';
      
      // Buscar transações que tenham fatura_vencimento no mês de referência
      final result = await _localDb.database?.query(
        'transacoes',
        where: 'usuario_id = ? AND cartao_id = ? AND fatura_vencimento IS NOT NULL AND strftime("%Y-%m", fatura_vencimento) = ?',
        whereArgs: [userId, cartaoId, anoMes],
        orderBy: 'data ASC',
      ) ?? [];

      
      return result;

    } catch (e) {
      log('❌ Erro ao buscar todas as transações do mês: $e');
      return [];
    }
  }

  /// ✅ BUSCAR TRANSAÇÕES PENDENTES FILTRADAS POR MÊS ESPECÍFICO
  Future<List<Map<String, dynamic>>> _buscarTransacoesPendentesCartaoMes(String cartaoId, DateTime mesReferencia) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return [];

      // Calcular data de vencimento esperada para o mês
      final diaVencimento = await _obterDiaVencimentoCartao(cartaoId);
      final dataVencimentoMes = DateTime(mesReferencia.year, mesReferencia.month, diaVencimento);
      final faturaVencimentoEsperada = dataVencimentoMes.toIso8601String().split('T')[0];


      final result = await _localDb.database?.query(
        'transacoes',
        where: 'usuario_id = ? AND cartao_id = ? AND efetivado = 0 AND fatura_vencimento = ?',
        whereArgs: [userId, cartaoId, faturaVencimentoEsperada],
        orderBy: 'data ASC',
      ) ?? [];

      return result;

    } catch (e) {
      log('❌ Erro ao buscar transações pendentes do mês: $e');
      return [];
    }
  }

  /// ✅ OBTER DIA DE VENCIMENTO DO CARTÃO
  Future<int> _obterDiaVencimentoCartao(String cartaoId) async {
    try {
      final result = await _localDb.database?.query(
        'cartoes',
        columns: ['dia_vencimento'],
        where: 'id = ?',
        whereArgs: [cartaoId],
        limit: 1,
      );

      if (result != null && result.isNotEmpty) {
        return (result.first['dia_vencimento'] as int?) ?? 10;
      }
      return 10; // Default

    } catch (e) {
      log('❌ Erro ao obter dia vencimento: $e');
      return 10;
    }
  }

  /// ✅ PROCESSAR TRANSAÇÕES DO MÊS ESPECÍFICO
  Map<String, dynamic>? _processarTransacoesMes(List<Map<String, dynamic>> transacoes) {
    if (transacoes.isEmpty) return null;

    // Como já filtramos por mês específico, todas as transações devem ter a mesma fatura_vencimento
    final faturaVencimento = transacoes.first['fatura_vencimento'] as String?;
    if (faturaVencimento == null) return null;


    return {
      'fatura_vencimento': faturaVencimento,
      'transacoes': transacoes,
    };
  }

  /// ✅ ENCONTRAR FATURA ATUAL (MAIS PRÓXIMA DO VENCIMENTO)
  Map<String, dynamic>? _encontrarFaturaAtual(List<Map<String, dynamic>> transacoes) {
    if (transacoes.isEmpty) return null;

    // Agrupar por fatura_vencimento
    final grupos = <String, List<Map<String, dynamic>>>{};
    
    for (final transacao in transacoes) {
      final faturaVencimento = transacao['fatura_vencimento'] as String?;
      if (faturaVencimento != null) {
        grupos[faturaVencimento] ??= [];
        grupos[faturaVencimento]!.add(transacao);
      }
    }

    if (grupos.isEmpty) return null;

    // Encontrar a fatura com vencimento mais próximo (futuro ou até 30 dias atrás)
    final hoje = DateTime.now();
    String? faturaEscolhida;
    int menorDiferenca = 999999;

    for (final faturaVencimento in grupos.keys) {
      try {
        final dataVencimento = DateTime.parse(faturaVencimento);
        final diferenca = dataVencimento.difference(hoje).inDays;
        
        // Priorizar faturas futuras, mas aceitar até 30 dias vencidas
        if (diferenca >= -30 && diferenca < menorDiferenca) {
          menorDiferenca = diferenca;
          faturaEscolhida = faturaVencimento;
        }
      } catch (e) {
        // Ignora datas inválidas
      }
    }

    if (faturaEscolhida == null) return null;

    return {
      'fatura_vencimento': faturaEscolhida,
      'transacoes': grupos[faturaEscolhida]!,
      'dias_vencimento': menorDiferenca,
    };
  }

  /// ✅ CALCULAR DIAS ATÉ VENCIMENTO
  int _diasAteVencimento(DateTime dataVencimento) {
    final hoje = DateTime.now();
    return dataVencimento.difference(hoje).inDays;
  }

  /// ✅ BUSCAR TRANSAÇÕES DE UMA FATURA ESPECÍFICA
  Future<List<Map<String, dynamic>>> _buscarTransacoesFatura(String cartaoId, String faturaVencimento) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return [];

      final result = await _localDb.database?.query(
        'transacoes',
        where: 'usuario_id = ? AND cartao_id = ? AND fatura_vencimento = ?',
        whereArgs: [userId, cartaoId, faturaVencimento],
      ) ?? [];

      log('📊 Encontradas ${result.length} transações para fatura $faturaVencimento');
      return result;

    } catch (e) {
      log('❌ Erro ao buscar transações da fatura: $e');
      return [];
    }
  }

  /// ✅ CALCULAR FATURA VENCIMENTO ALVO
  /// Baseado nas regras do cartão (igual React)
  String _calcularFaturaVencimentoAlvo(CartaoModel cartao, DateTime dataReferencia) {
    try {
      final diaFechamento = cartao.diaFechamento ?? 1;
      final diaVencimento = cartao.diaVencimento ?? 10;
      
      final hoje = dataReferencia;
      final diaAtual = hoje.day;
      
      // Determinar qual fatura (baseado no fechamento)
      DateTime dataVencimentoAlvo;
      
      if (diaAtual > diaFechamento) {
        // Já passou do fechamento, fatura vence no próximo mês
        dataVencimentoAlvo = DateTime(hoje.year, hoje.month + 1, diaVencimento);
      } else {
        // Ainda não fechou, fatura vence neste mês
        dataVencimentoAlvo = DateTime(hoje.year, hoje.month, diaVencimento);
      }

      // Ajustar se vencimento é menor que fechamento
      if (diaVencimento <= diaFechamento) {
        dataVencimentoAlvo = DateTime(dataVencimentoAlvo.year, dataVencimentoAlvo.month + 1, diaVencimento);
      }

      // Verificar se o dia existe no mês
      if (dataVencimentoAlvo.day != diaVencimento) {
        dataVencimentoAlvo = DateTime(dataVencimentoAlvo.year, dataVencimentoAlvo.month + 1, 0);
      }

      return dataVencimentoAlvo.toIso8601String().split('T')[0];

    } catch (e) {
      log('❌ Erro ao calcular fatura alvo: $e');
      // Fallback
      final proximoMes = DateTime(dataReferencia.year, dataReferencia.month + 1, cartao.diaVencimento ?? 10);
      return proximoMes.toIso8601String().split('T')[0];
    }
  }

  /// ✅ CALCULAR DATA DE FECHAMENTO
  DateTime _calcularDataFechamento(CartaoModel cartao, String faturaVencimento) {
    try {
      final dataVencimento = DateTime.parse(faturaVencimento);
      final diaFechamento = cartao.diaFechamento ?? 1;
      
      // Se fechamento < vencimento, fechamento é no mês anterior
      if (diaFechamento < dataVencimento.day) {
        return DateTime(dataVencimento.year, dataVencimento.month - 1, diaFechamento);
      } else {
        return DateTime(dataVencimento.year, dataVencimento.month, diaFechamento);
      }
    } catch (e) {
      return DateTime.now();
    }
  }

  /// ✅ OBTER FATURAS DE UM ANO ESPECÍFICO
  /// Retorna mapa com mês -> FaturaModel para todos os 12 meses
  Future<Map<int, FaturaModel?>> obterFaturasAno(String cartaoId, int ano) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return {};

      log('🔍 FATURA DEBUG: obterFaturasAno para cartão $cartaoId, ano $ano');

      final faturasPorMes = <int, FaturaModel?>{};
      
      // Buscar transações do ano inteiro agrupadas por mês
      final result = await _localDb.database?.rawQuery(
        '''
        SELECT 
          strftime('%m', fatura_vencimento) as mes,
          fatura_vencimento,
          COUNT(*) as total_transacoes,
          SUM(valor) as valor_total,
          SUM(CASE WHEN efetivado = 1 THEN valor ELSE 0 END) as valor_pago,
          MIN(CASE WHEN efetivado = 1 THEN data_efetivacao ELSE NULL END) as primeira_efetivacao,
          MIN(CASE WHEN efetivado = 0 THEN 1 ELSE 0 END) as tem_pendentes
        FROM transacoes 
        WHERE usuario_id = ? 
          AND cartao_id = ? 
          AND fatura_vencimento IS NOT NULL
          AND strftime('%Y', fatura_vencimento) = ?
        GROUP BY strftime('%m', fatura_vencimento), fatura_vencimento
        ORDER BY fatura_vencimento ASC
        ''',
        [userId, cartaoId, ano.toString()],
      ) ?? [];

      log('🔍 FATURA DEBUG: Query retornou ${result.length} grupos de faturas');

      // Buscar dados do cartão
      final cartaoResult = await _localDb.database?.query(
        'cartoes',
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [cartaoId, userId],
        limit: 1,
      );

      if (cartaoResult == null || cartaoResult.isEmpty) return {};
      final cartao = CartaoModel.fromJson(cartaoResult.first);

      // Processar resultados e preencher mapa
      for (final row in result) {
        final mesStr = row['mes'] as String;
        final mes = int.parse(mesStr);
        final faturaVencimento = row['fatura_vencimento'] as String;
        
        final valorTotal = (row['valor_total'] as num?)?.toDouble() ?? 0.0;
        final valorPago = (row['valor_pago'] as num?)?.toDouble() ?? 0.0;
        final temPendentes = (row['tem_pendentes'] as int?) == 1;

        log('🔍 FATURA DEBUG: Processando mês $mes ($faturaVencimento)');
        
        // ✅ BUSCAR TRANSAÇÕES DETALHADAS PARA DETECÇÃO DE STATUS
        final transacoesFatura = await _buscarTransacoesFatura(cartaoId, faturaVencimento);
        
        log('🔍 FATURA DEBUG: Encontradas ${transacoesFatura.length} transações para $faturaVencimento');
        
        // Detectar estorno e parcelas (mesma lógica do detectarFaturaMes)
        bool temEstorno = false;
        bool temParcelas = false;
        
        for (final transacao in transacoesFatura) {
          final valor = (transacao['valor'] as num?)?.toDouble() ?? 0.0;
          final descricao = transacao['descricao'] as String? ?? '';
          final grupoParcelamento = transacao['grupo_parcelamento'];
          
          log('   💰 Transação: $valor - "$descricao" - Parcelas: $grupoParcelamento');
          
          // Detectar estorno (valor negativo ou descrição específica)
          if (valor < 0 || descricao.toLowerCase().contains('empréstimo para cobertura')) {
            temEstorno = true;
            log('   🔄 ESTORNO DETECTADO!');
          }
          
          // Detectar parcelas
          if (grupoParcelamento != null) {
            temParcelas = true;
            log('   📦 PARCELA DETECTADA!');
          }
        }
        
        // Determinar status melhorado (mesma lógica do detectarFaturaMes)
        final dataVencimento = DateTime.parse(faturaVencimento);
        final isVencida = DateTime.now().isAfter(dataVencimento);
        
        String status;
        if (!temPendentes && temEstorno) {
          status = 'parcelado';  // Paga via parcelamento
        } else if (!temPendentes && valorPago < valorTotal && valorPago > 0) {
          status = 'parcial';  // Paga parcialmente  
        } else if (!temPendentes && valorTotal > 0) {
          status = 'paga';  // Paga integralmente
        } else if (temPendentes && valorTotal > 0) {
          status = isVencida ? 'vencida' : 'aberta';  // Em aberto ou vencida
        } else {
          status = 'futura';  // Sem transações ainda
        }
        
        final isPaga = ['paga', 'parcelado', 'parcial'].contains(status);
        
        log('🎯 FATURA DEBUG: Status determinado para mês $mes: "$status" (pendentes: $temPendentes, estorno: $temEstorno, parcelas: $temParcelas)');
        
        DateTime? dataPagamento;
        if (row['primeira_efetivacao'] != null) {
          try {
            dataPagamento = DateTime.parse(row['primeira_efetivacao'] as String);
          } catch (e) {
            // Ignora se não conseguir parsear
          }
        }
        
        final fatura = FaturaModel(
          id: '${cartaoId}_$faturaVencimento',
          cartaoId: cartaoId,
          usuarioId: userId,
          ano: dataVencimento.year,
          mes: dataVencimento.month,
          dataFechamento: _calcularDataFechamento(cartao, faturaVencimento),
          dataVencimento: dataVencimento,
          valorTotal: valorTotal,
          valorPago: valorPago,
          valorMinimo: valorTotal * 0.15,
          status: status,
          paga: isPaga,
          dataPagamento: dataPagamento,
          observacoes: '${row['total_transacoes']} transações',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          sincronizado: true,
        );

        faturasPorMes[mes] = fatura;
      }

      // Preencher meses sem transações com null
      for (int mes = 1; mes <= 12; mes++) {
        faturasPorMes[mes] ??= null;
      }

      return faturasPorMes;

    } catch (e) {
      log('❌ Erro ao obter faturas do ano: $e');
      return {};
    }
  }

  /// ✅ LISTAR FATURAS DISPONÍVEIS DO CARTÃO
  /// Agrupa transações por fatura_vencimento
  Future<List<FaturaModel>> listarFaturasCartao(String cartaoId, {int limite = 12}) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return [];

      // Buscar todas as faturas_vencimento distintas
      final result = await _localDb.database?.rawQuery(
        '''
        SELECT 
          fatura_vencimento,
          COUNT(*) as total_transacoes,
          SUM(valor) as valor_total,
          SUM(CASE WHEN efetivado = 1 THEN valor ELSE 0 END) as valor_pago,
          MIN(CASE WHEN efetivado = 1 THEN data_efetivacao ELSE NULL END) as primeira_efetivacao
        FROM transacoes 
        WHERE usuario_id = ? AND cartao_id = ? AND fatura_vencimento IS NOT NULL
        GROUP BY fatura_vencimento
        ORDER BY fatura_vencimento DESC
        LIMIT ?
        ''',
        [userId, cartaoId, limite],
      ) ?? [];

      // Buscar dados do cartão
      final cartaoResult = await _localDb.database?.query(
        'cartoes',
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [cartaoId, userId],
        limit: 1,
      );

      if (cartaoResult == null || cartaoResult.isEmpty) return [];
      final cartao = CartaoModel.fromJson(cartaoResult.first);

      // Converter em FaturaModel
      final faturas = <FaturaModel>[];
      
      for (final row in result) {
        final faturaVencimento = row['fatura_vencimento'] as String?;
        if (faturaVencimento == null) continue;

        final valorTotal = (row['valor_total'] as num?)?.toDouble() ?? 0.0;
        final valorPago = (row['valor_pago'] as num?)?.toDouble() ?? 0.0;
        final isPaga = valorPago >= valorTotal && valorTotal > 0;
        
        DateTime? dataPagamento;
        if (row['primeira_efetivacao'] != null) {
          try {
            dataPagamento = DateTime.parse(row['primeira_efetivacao'] as String);
          } catch (e) {
            // Ignora se não conseguir parsear
          }
        }

        final dataVencimento = DateTime.parse(faturaVencimento);
        
        final fatura = FaturaModel(
          id: '${cartaoId}_$faturaVencimento',
          cartaoId: cartaoId,
          usuarioId: userId,
          ano: dataVencimento.year,
          mes: dataVencimento.month,
          dataFechamento: _calcularDataFechamento(cartao, faturaVencimento),
          dataVencimento: dataVencimento,
          valorTotal: valorTotal,
          valorPago: valorPago,
          valorMinimo: valorTotal * 0.15,
          status: isPaga ? 'paga' : 'aberta',
          paga: isPaga,
          dataPagamento: dataPagamento,
          observacoes: '${row['total_transacoes']} transações',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          sincronizado: true,
        );

        faturas.add(fatura);
      }

      return faturas;

    } catch (e) {
      log('❌ Erro ao listar faturas: $e');
      return [];
    }
  }

  /// ✅ VERIFICAR SE CARTÃO TEM FATURAS EM ABERTO
  Future<bool> temFaturasEmAberto(String cartaoId) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return false;

      // Buscar transações não efetivadas (= fatura em aberto)
      final result = await _localDb.database?.rawQuery(
        '''
        SELECT COUNT(*) as total
        FROM transacoes 
        WHERE usuario_id = ? 
          AND cartao_id = ? 
          AND efetivado = 0 
          AND fatura_vencimento IS NOT NULL
        ''',
        [userId, cartaoId],
      ) ?? [];

      if (result.isEmpty) return false;
      
      final total = (result.first['total'] as int?) ?? 0;
      return total > 0;

    } catch (e) {
      log('❌ Erro ao verificar faturas em aberto: $e');
      return false;
    }
  }

  /// ✅ CALCULAR VALOR TOTAL EM ABERTO
  Future<double> calcularValorEmAberto(String cartaoId) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return 0.0;

      final result = await _localDb.database?.rawQuery(
        '''
        SELECT SUM(valor) as total
        FROM transacoes 
        WHERE usuario_id = ? 
          AND cartao_id = ? 
          AND efetivado = 0 
          AND fatura_vencimento IS NOT NULL
        ''',
        [userId, cartaoId],
      ) ?? [];

      if (result.isEmpty || result.first['total'] == null) return 0.0;
      
      return (result.first['total'] as num).toDouble();

    } catch (e) {
      log('❌ Erro ao calcular valor em aberto: $e');
      return 0.0;
    }
  }


  /// ✅ DEBUG - RELATÓRIO DE TRANSAÇÕES DO CARTÃO
  Future<Map<String, dynamic>> debugTransacoesCartao(String cartaoId) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return {};

      final result = await _localDb.database?.rawQuery(
        '''
        SELECT 
          fatura_vencimento,
          COUNT(*) as total,
          SUM(valor) as valor_total,
          SUM(CASE WHEN efetivado = 1 THEN 1 ELSE 0 END) as efetivadas,
          SUM(CASE WHEN efetivado = 0 THEN 1 ELSE 0 END) as pendentes
        FROM transacoes 
        WHERE usuario_id = ? AND cartao_id = ?
        GROUP BY fatura_vencimento
        ORDER BY fatura_vencimento DESC
        ''',
        [userId, cartaoId],
      ) ?? [];

      return {
        'cartao_id': cartaoId,
        'total_grupos': result.length,
        'detalhes': result,
      };

    } catch (e) {
      log('❌ Erro no debug: $e');
      return {};
    }
  }

  /// ✅ DEBUG - RELATÓRIO DE FATURAS NA TABELA FATURAS
  Future<Map<String, dynamic>> debugFaturasCartao(String cartaoId) async {
    try {
      final userId = _authIntegration.authService.currentUser?.id;
      if (userId == null) return {};

      final result = await _localDb.database?.query(
        'faturas',
        where: 'usuario_id = ? AND cartao_id = ?',
        whereArgs: [userId, cartaoId],
        orderBy: 'ano DESC, mes DESC',
      ) ?? [];

      return {
        'cartao_id': cartaoId,
        'total_faturas': result.length,
        'faturas': result,
      };

    } catch (e) {
      log('❌ Erro no debug de faturas: $e');
      return {};
    }
  }
}