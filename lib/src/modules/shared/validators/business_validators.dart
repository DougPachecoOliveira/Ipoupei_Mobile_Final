// 🏢 Business Validators - iPoupei Mobile
// 
// Validadores de regras de negócio específicas
// Baseado no sistema React/Supabase idêntico
// 
// Baseado em: Business Rules Pattern

import 'dart:developer';
import '../../../database/local_database.dart';

class BusinessValidators {
  static final LocalDatabase _localDB = LocalDatabase.instance;
  
  /// 🏦 VALIDAR SE CONTA PODE SER EXCLUÍDA
  static Future<Map<String, dynamic>> validarExclusaoConta(String contaId) async {
    try {
      // Verificar se possui transações
      final transacoes = await _localDB.select(
        'transacoes',
        where: 'conta_id = ? OR conta_destino_id = ?',
        whereArgs: [contaId, contaId],
        limit: 1,
      );

      if (transacoes.isNotEmpty) {
        return {
          'canDelete': false,
          'reason': 'POSSUI_TRANSACOES',
          'message': 'Esta conta possui transações e não pode ser excluída.',
          'suggestion': 'Você pode arquivar a conta em vez de excluí-la.',
        };
      }

      return {
        'canDelete': true,
        'message': 'Conta pode ser excluída com segurança.',
      };

    } catch (e) {
      log('❌ Erro ao validar exclusão de conta: $e');
      return {
        'canDelete': false,
        'reason': 'ERRO_VALIDACAO',
        'message': 'Erro ao validar exclusão da conta.',
      };
    }
  }

  /// 📂 VALIDAR SE CATEGORIA PODE SER EXCLUÍDA
  static Future<Map<String, dynamic>> validarExclusaoCategoria(String categoriaId) async {
    try {
      // Verificar se possui transações
      final transacoes = await _localDB.select(
        'transacoes',
        where: 'categoria_id = ?',
        whereArgs: [categoriaId],
        limit: 1,
      );

      if (transacoes.isNotEmpty) {
        // Contar total de transações
        final totalTransacoes = await _localDB.database!.rawQuery(
          'SELECT COUNT(*) as count FROM transacoes WHERE categoria_id = ?',
          [categoriaId],
        );
        
        final count = totalTransacoes.first['count'] as int;

        return {
          'canDelete': false,
          'reason': 'POSSUI_TRANSACOES',
          'message': 'Esta categoria possui $count transação(ões) e não pode ser excluída.',
          'suggestion': 'Você pode arquivar a categoria em vez de excluí-la.',
          'transactionCount': count,
        };
      }

      // Verificar se possui subcategorias
      final subcategorias = await _localDB.select(
        'subcategorias',
        where: 'categoria_id = ?',
        whereArgs: [categoriaId],
        limit: 1,
      );

      if (subcategorias.isNotEmpty) {
        final totalSubcategorias = await _localDB.database!.rawQuery(
          'SELECT COUNT(*) as count FROM subcategorias WHERE categoria_id = ?',
          [categoriaId],
        );
        
        final count = totalSubcategorias.first['count'] as int;

        return {
          'canDelete': false,
          'reason': 'POSSUI_SUBCATEGORIAS',
          'message': 'Esta categoria possui $count subcategoria(s) e não pode ser excluída.',
          'suggestion': 'Exclua primeiro as subcategorias.',
          'subcategoryCount': count,
        };
      }

      return {
        'canDelete': true,
        'message': 'Categoria pode ser excluída com segurança.',
      };

    } catch (e) {
      log('❌ Erro ao validar exclusão de categoria: $e');
      return {
        'canDelete': false,
        'reason': 'ERRO_VALIDACAO',
        'message': 'Erro ao validar exclusão da categoria.',
      };
    }
  }

  /// 📋 VALIDAR SE SUBCATEGORIA PODE SER EXCLUÍDA
  static Future<Map<String, dynamic>> validarExclusaoSubcategoria(String subcategoriaId) async {
    try {
      // Verificar se possui transações
      final transacoes = await _localDB.select(
        'transacoes',
        where: 'subcategoria_id = ?',
        whereArgs: [subcategoriaId],
        limit: 1,
      );

      if (transacoes.isNotEmpty) {
        final totalTransacoes = await _localDB.database!.rawQuery(
          'SELECT COUNT(*) as count FROM transacoes WHERE subcategoria_id = ?',
          [subcategoriaId],
        );
        
        final count = totalTransacoes.first['count'] as int;

        return {
          'canDelete': false,
          'reason': 'POSSUI_TRANSACOES',
          'message': 'Esta subcategoria possui $count transação(ões) e não pode ser excluída.',
          'suggestion': 'Você pode arquivar a subcategoria em vez de excluí-la.',
          'transactionCount': count,
        };
      }

      return {
        'canDelete': true,
        'message': 'Subcategoria pode ser excluída com segurança.',
      };

    } catch (e) {
      log('❌ Erro ao validar exclusão de subcategoria: $e');
      return {
        'canDelete': false,
        'reason': 'ERRO_VALIDACAO',
        'message': 'Erro ao validar exclusão da subcategoria.',
      };
    }
  }

  /// 💳 VALIDAR TRANSFERÊNCIA ENTRE CONTAS
  static Future<Map<String, dynamic>> validarTransferencia({
    required String contaOrigemId,
    required String contaDestinoId,
    required double valor,
  }) async {
    try {
      // Verificar se contas existem e estão ativas
      final contaOrigem = await _localDB.select(
        'contas',
        where: 'id = ? AND ativo = 1',
        whereArgs: [contaOrigemId],
      );

      if (contaOrigem.isEmpty) {
        return {
          'isValid': false,
          'reason': 'CONTA_ORIGEM_INVALIDA',
          'message': 'Conta de origem não encontrada ou inativa.',
        };
      }

      final contaDestino = await _localDB.select(
        'contas',
        where: 'id = ? AND ativo = 1',
        whereArgs: [contaDestinoId],
      );

      if (contaDestino.isEmpty) {
        return {
          'isValid': false,
          'reason': 'CONTA_DESTINO_INVALIDA',
          'message': 'Conta de destino não encontrada ou inativa.',
        };
      }

      // Verificar saldo da conta origem (opcional - aviso)
      final saldoOrigem = contaOrigem.first['saldo'] as double? ?? 0.0;
      if (saldoOrigem < valor) {
        return {
          'isValid': true,
          'warning': true,
          'reason': 'SALDO_INSUFICIENTE',
          'message': 'A conta de origem ficará com saldo negativo (R\$ ${(saldoOrigem - valor).toStringAsFixed(2)}).',
          'suggestion': 'Deseja continuar mesmo assim?',
        };
      }

      return {
        'isValid': true,
        'message': 'Transferência pode ser realizada.',
      };

    } catch (e) {
      log('❌ Erro ao validar transferência: $e');
      return {
        'isValid': false,
        'reason': 'ERRO_VALIDACAO',
        'message': 'Erro ao validar transferência.',
      };
    }
  }

  /// 💰 VALIDAR SALDO MÍNIMO DA CONTA
  static Future<Map<String, dynamic>> validarSaldoMinimo({
    required String contaId,
    required double valorOperacao,
  }) async {
    try {
      final conta = await _localDB.select(
        'contas',
        where: 'id = ?',
        whereArgs: [contaId],
      );

      if (conta.isEmpty) {
        return {
          'isValid': false,
          'reason': 'CONTA_NAO_ENCONTRADA',
          'message': 'Conta não encontrada.',
        };
      }

      final saldoAtual = conta.first['saldo'] as double? ?? 0.0;
      final novoSaldo = saldoAtual - valorOperacao;

      // Definir limite mínimo (configurável)
      final limiteMinimo = -1000.0; // R$ -1000 (descoberto)

      if (novoSaldo < limiteMinimo) {
        return {
          'isValid': false,
          'reason': 'LIMITE_DESCOBERTO_EXCEDIDO',
          'message': 'Operação excederia o limite de descoberto permitido.',
          'currentBalance': saldoAtual,
          'newBalance': novoSaldo,
          'limit': limiteMinimo,
        };
      }

      if (novoSaldo < 0) {
        return {
          'isValid': true,
          'warning': true,
          'reason': 'SALDO_NEGATIVO',
          'message': 'A conta ficará com saldo negativo (R\$ ${novoSaldo.toStringAsFixed(2)}).',
          'suggestion': 'Deseja continuar?',
        };
      }

      return {
        'isValid': true,
        'message': 'Operação dentro dos limites permitidos.',
      };

    } catch (e) {
      log('❌ Erro ao validar saldo mínimo: $e');
      return {
        'isValid': false,
        'reason': 'ERRO_VALIDACAO',
        'message': 'Erro ao validar saldo mínimo.',
      };
    }
  }

  /// 📅 VALIDAR DATA DE TRANSAÇÃO
  static Map<String, dynamic> validarDataTransacao(DateTime dataTransacao) {
    final agora = DateTime.now();
    final inicioMes = DateTime(agora.year, agora.month, 1);
    final fimMes = DateTime(agora.year, agora.month + 1, 0);
    
    // Permitir até 3 meses no passado
    final tresMesesAtras = DateTime(agora.year, agora.month - 3, 1);
    
    // Permitir até 1 ano no futuro
    final umAnoFuturo = DateTime(agora.year + 1, agora.month, agora.day);

    if (dataTransacao.isBefore(tresMesesAtras)) {
      return {
        'isValid': false,
        'reason': 'DATA_MUITO_ANTIGA',
        'message': 'Data não pode ser mais de 3 meses no passado.',
      };
    }

    if (dataTransacao.isAfter(umAnoFuturo)) {
      return {
        'isValid': false,
        'reason': 'DATA_MUITO_FUTURA',
        'message': 'Data não pode ser mais de 1 ano no futuro.',
      };
    }

    // Aviso para datas fora do mês atual
    if (dataTransacao.isBefore(inicioMes) || dataTransacao.isAfter(fimMes)) {
      return {
        'isValid': true,
        'warning': true,
        'reason': 'DATA_FORA_MES_ATUAL',
        'message': 'Transação será registrada fora do mês atual.',
      };
    }

    return {
      'isValid': true,
      'message': 'Data válida.',
    };
  }

  /// 🔍 VALIDAR DUPLICATA DE TRANSAÇÃO
  static Future<Map<String, dynamic>> validarDuplicataTransacao({
    required String descricao,
    required double valor,
    required DateTime data,
    required String contaId,
    String? transacaoExcluirId,
  }) async {
    try {
      // Buscar transações similares (mesmo valor, conta e data próxima)
      final inicioDia = DateTime(data.year, data.month, data.day);
      final fimDia = DateTime(data.year, data.month, data.day, 23, 59, 59);

      String where = 'conta_id = ? AND valor = ? AND data BETWEEN ? AND ?';
      List<dynamic> whereArgs = [
        contaId,
        valor,
        inicioDia.toIso8601String(),
        fimDia.toIso8601String(),
      ];

      // Excluir transação atual se estiver editando
      if (transacaoExcluirId != null) {
        where += ' AND id != ?';
        whereArgs.add(transacaoExcluirId);
      }

      final transacoesSimilares = await _localDB.select(
        'transacoes',
        where: where,
        whereArgs: whereArgs,
        limit: 5,
      );

      if (transacoesSimilares.isNotEmpty) {
        return {
          'hasDuplicates': true,
          'warning': true,
          'reason': 'POSSIVEL_DUPLICATA',
          'message': 'Encontradas ${transacoesSimilares.length} transação(ões) similar(es) na mesma data.',
          'suggestions': transacoesSimilares.map((t) => {
            'descricao': t['descricao'],
            'valor': t['valor'],
            'data': t['data'],
          }).toList(),
        };
      }

      return {
        'hasDuplicates': false,
        'message': 'Nenhuma transação similar encontrada.',
      };

    } catch (e) {
      log('❌ Erro ao validar duplicatas: $e');
      return {
        'hasDuplicates': false,
        'error': true,
        'message': 'Erro ao verificar duplicatas.',
      };
    }
  }

  /// 📊 VALIDAR LIMITES DE CATEGORIAS POR USUÁRIO
  static Future<Map<String, dynamic>> validarLimiteCategoria(String tipo) async {
    try {
      final userId = _localDB.currentUserId;
      if (userId == null) {
        return {
          'isValid': false,
          'reason': 'USUARIO_NAO_LOGADO',
          'message': 'Usuário não está logado.',
        };
      }

      final totalCategorias = await _localDB.database!.rawQuery(
        'SELECT COUNT(*) as count FROM categorias WHERE user_id = ? AND tipo = ? AND arquivada = 0',
        [userId, tipo],
      );

      final count = totalCategorias.first['count'] as int;
      const limiteMaximo = 50; // Limite por tipo

      if (count >= limiteMaximo) {
        return {
          'isValid': false,
          'reason': 'LIMITE_CATEGORIA_EXCEDIDO',
          'message': 'Você atingiu o limite de $limiteMaximo categorias de $tipo.',
          'suggestion': 'Arquive algumas categorias não utilizadas.',
          'currentCount': count,
          'maxLimit': limiteMaximo,
        };
      }

      return {
        'isValid': true,
        'message': 'Pode criar nova categoria.',
        'currentCount': count,
        'maxLimit': limiteMaximo,
      };

    } catch (e) {
      log('❌ Erro ao validar limite de categoria: $e');
      return {
        'isValid': false,
        'reason': 'ERRO_VALIDACAO',
        'message': 'Erro ao validar limite de categoria.',
      };
    }
  }
}