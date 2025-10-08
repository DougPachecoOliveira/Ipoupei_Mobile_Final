// 📊 Grupos Metadados Service - iPoupei Mobile
//
// Gerencia metadados de grupos de transações (parcelas/recorrências)
// Resolve problemas de performance com grupos grandes
//
// Baseado em: Metadata pattern + Cache pattern

import 'dart:developer';
import '../database/local_database.dart';
import 'package:uuid/uuid.dart';

/// Modelo para metadados de grupos de transações
class GrupoMetadados {
  final String id;
  final String usuarioId;
  final String tipoGrupo; // 'recorrencia' ou 'parcelamento'
  final String grupoId;
  final String? descricao;
  final double? valorUnitario;
  final DateTime? dataPrimeira;
  final DateTime? dataUltima;
  final int? totalItems;
  final int? itemsEfetivados;
  final int? itemsPendentes;
  final double? valorTotal;
  final double? valorEfetivado;
  final double? valorPendente;
  final String? tipoRecorrencia;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GrupoMetadados({
    required this.id,
    required this.usuarioId,
    required this.tipoGrupo,
    required this.grupoId,
    this.descricao,
    this.valorUnitario,
    this.dataPrimeira,
    this.dataUltima,
    this.totalItems,
    this.itemsEfetivados,
    this.itemsPendentes,
    this.valorTotal,
    this.valorEfetivado,
    this.valorPendente,
    this.tipoRecorrencia,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GrupoMetadados.fromJson(Map<String, dynamic> json) {
    return GrupoMetadados(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      tipoGrupo: json['tipo_grupo'] as String,
      grupoId: json['grupo_id'] as String,
      descricao: json['descricao'] as String?,
      valorUnitario: (json['valor_unitario'] as num?)?.toDouble(),
      dataPrimeira: json['data_primeira'] != null ? DateTime.parse(json['data_primeira']) : null,
      dataUltima: json['data_ultima'] != null ? DateTime.parse(json['data_ultima']) : null,
      totalItems: json['total_items'] as int?,
      itemsEfetivados: json['items_efetivados'] as int?,
      itemsPendentes: json['items_pendentes'] as int?,
      valorTotal: (json['valor_total'] as num?)?.toDouble(),
      valorEfetivado: (json['valor_efetivado'] as num?)?.toDouble(),
      valorPendente: (json['valor_pendente'] as num?)?.toDouble(),
      tipoRecorrencia: json['tipo_recorrencia'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'tipo_grupo': tipoGrupo,
      'grupo_id': grupoId,
      'descricao': descricao,
      'valor_unitario': valorUnitario,
      'data_primeira': dataPrimeira?.toIso8601String(),
      'data_ultima': dataUltima?.toIso8601String(),
      'total_items': totalItems,
      'items_efetivados': itemsEfetivados,
      'items_pendentes': itemsPendentes,
      'valor_total': valorTotal,
      'valor_efetivado': valorEfetivado,
      'valor_pendente': valorPendente,
      'tipo_recorrencia': tipoRecorrencia,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Calcula o percentual de progresso por quantidade
  double get percentualProgressoQuantidade {
    if (totalItems == null || totalItems == 0) return 0.0;
    return (itemsEfetivados ?? 0) / totalItems! * 100;
  }

  /// Calcula o percentual de progresso por valor
  double get percentualProgressoValor {
    if (valorTotal == null || valorTotal == 0) return 0.0;
    return (valorEfetivado ?? 0) / valorTotal! * 100;
  }

  /// Retorna uma string formatada do progresso por quantidade
  String get progressoQuantidadeFormatado {
    return '${itemsEfetivados ?? 0}/${totalItems ?? 0}';
  }

  /// Retorna se o grupo está completamente pago
  bool get estCompleto {
    return itemsEfetivados == totalItems && totalItems != null && totalItems! > 0;
  }
}

/// Serviço para gerenciar metadados de grupos de transações
class GruposMetadadosService {
  static GruposMetadadosService? _instance;
  static GruposMetadadosService get instance {
    _instance ??= GruposMetadadosService._internal();
    return _instance!;
  }

  GruposMetadadosService._internal();

  final LocalDatabase _localDB = LocalDatabase.instance;
  final Uuid _uuid = const Uuid();

  /// 🔍 OBTER METADADOS DE UM GRUPO
  Future<GrupoMetadados?> obterMetadadosGrupo(String grupoId, String usuarioId) async {
    try {
      print('📊 Buscando metadados do grupo: $grupoId para usuário: $usuarioId');

      final result = await _localDB.select(
        'grupos_metadados',
        where: 'grupo_id = ? AND usuario_id = ?',
        whereArgs: [grupoId, usuarioId],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final metadados = GrupoMetadados.fromJson(result.first);
        print('✅ Metadados encontrados: ${metadados.descricao} (${metadados.progressoQuantidadeFormatado})');
        return metadados;
      }

      print('⚠️ Metadados não encontrados para grupo: $grupoId');
      return null;
    } catch (e) {
      print('❌ Erro ao buscar metadados do grupo: $e');
      return null;
    }
  }

  /// 🔄 ATUALIZAR OU CRIAR METADADOS DE UM GRUPO
  Future<bool> atualizarMetadadosGrupo(String grupoId, String usuarioId, String tipoGrupo) async {
    try {
      log('🔄 Atualizando metadados do grupo: $grupoId');

      // Query para recalcular metadados baseados nas transações atuais
      final query = tipoGrupo == 'recorrencia' ? '''
        SELECT
          MAX(descricao) as descricao,
          MAX(valor) as valor_unitario,
          MIN(data) as data_primeira,
          MAX(data) as data_ultima,
          COUNT(*) as total_items,
          SUM(CASE WHEN efetivado = 1 THEN 1 ELSE 0 END) as items_efetivados,
          SUM(CASE WHEN efetivado = 0 THEN 1 ELSE 0 END) as items_pendentes,
          SUM(valor) as valor_total,
          SUM(CASE WHEN efetivado = 1 THEN valor ELSE 0 END) as valor_efetivado,
          SUM(CASE WHEN efetivado = 0 THEN valor ELSE 0 END) as valor_pendente,
          MAX(tipo_recorrencia) as tipo_recorrencia
        FROM transacoes
        WHERE grupo_recorrencia = ? AND usuario_id = ?
      ''' : '''
        SELECT
          MAX(descricao) as descricao,
          MAX(valor) as valor_unitario,
          MIN(data) as data_primeira,
          MAX(data) as data_ultima,
          COUNT(*) as total_items,
          SUM(CASE WHEN efetivado = 1 THEN 1 ELSE 0 END) as items_efetivados,
          SUM(CASE WHEN efetivado = 0 THEN 1 ELSE 0 END) as items_pendentes,
          SUM(valor) as valor_total,
          SUM(CASE WHEN efetivado = 1 THEN valor ELSE 0 END) as valor_efetivado,
          SUM(CASE WHEN efetivado = 0 THEN valor ELSE 0 END) as valor_pendente,
          NULL as tipo_recorrencia
        FROM transacoes
        WHERE grupo_parcelamento = ? AND usuario_id = ?
      ''';

      final results = await _localDB.rawQuery(query, [grupoId, usuarioId]);

      if (results.isEmpty || results.first['total_items'] == 0) {
        print('⚠️ Nenhuma transação encontrada para o grupo: $grupoId');
        return false;
      }

      final data = results.first;
      print('🔍 [DEBUG] Dados calculados para grupo $grupoId:');
      print('   - total_items: ${data['total_items']}');
      print('   - items_efetivados: ${data['items_efetivados']}');
      print('   - valor_total: ${data['valor_total']}');
      print('   - valor_efetivado: ${data['valor_efetivado']}');
      final now = DateTime.now();

      // Verificar se metadados já existem
      final existingResult = await _localDB.select(
        'grupos_metadados',
        where: 'grupo_id = ? AND usuario_id = ?',
        whereArgs: [grupoId, usuarioId],
        limit: 1,
      );

      final metadadosData = {
        'usuario_id': usuarioId,
        'tipo_grupo': tipoGrupo,
        'grupo_id': grupoId,
        'descricao': data['descricao'],
        'valor_unitario': data['valor_unitario'],
        'data_primeira': data['data_primeira'],
        'data_ultima': data['data_ultima'],
        'total_items': data['total_items'],
        'items_efetivados': data['items_efetivados'],
        'items_pendentes': data['items_pendentes'],
        'valor_total': data['valor_total'],
        'valor_efetivado': data['valor_efetivado'],
        'valor_pendente': data['valor_pendente'],
        'tipo_recorrencia': data['tipo_recorrencia'],
        'updated_at': now.toIso8601String(),
      };

      if (existingResult.isEmpty) {
        // Criar novo registro
        metadadosData['id'] = _uuid.v4();
        metadadosData['created_at'] = now.toIso8601String();

        await _localDB.database!.insert('grupos_metadados', metadadosData);
        log('✅ Metadados criados para grupo: $grupoId');
      } else {
        // Atualizar registro existente
        await _localDB.database!.update(
          'grupos_metadados',
          metadadosData,
          where: 'grupo_id = ? AND usuario_id = ?',
          whereArgs: [grupoId, usuarioId],
        );
        log('✅ Metadados atualizados para grupo: $grupoId');
      }

      return true;
    } catch (e) {
      log('❌ Erro ao atualizar metadados do grupo: $e');
      return false;
    }
  }

  /// 📋 LISTAR TODOS OS METADADOS DE UM USUÁRIO
  Future<List<GrupoMetadados>> listarMetadadosUsuario(String usuarioId, {String? tipoGrupo}) async {
    try {
      String where = 'usuario_id = ?';
      List<dynamic> whereArgs = [usuarioId];

      if (tipoGrupo != null) {
        where += ' AND tipo_grupo = ?';
        whereArgs.add(tipoGrupo);
      }

      final results = await _localDB.select(
        'grupos_metadados',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'data_primeira ASC',
      );

      return results.map((json) => GrupoMetadados.fromJson(json)).toList();
    } catch (e) {
      log('❌ Erro ao listar metadados do usuário: $e');
      return [];
    }
  }

  /// 🗑️ REMOVER METADADOS DE UM GRUPO
  Future<bool> removerMetadadosGrupo(String grupoId, String usuarioId) async {
    try {
      final rowsAffected = await _localDB.database!.delete(
        'grupos_metadados',
        where: 'grupo_id = ? AND usuario_id = ?',
        whereArgs: [grupoId, usuarioId],
      );

      if (rowsAffected > 0) {
        log('✅ Metadados removidos para grupo: $grupoId');
        return true;
      }

      log('⚠️ Nenhum metadado encontrado para remoção: $grupoId');
      return false;
    } catch (e) {
      log('❌ Erro ao remover metadados do grupo: $e');
      return false;
    }
  }

  /// 🧹 LIMPAR METADADOS ÓRFÃOS (grupos sem transações)
  Future<int> limparMetadadosOrfaos(String usuarioId) async {
    try {
      log('🧹 Limpando metadados órfãos para usuário: $usuarioId');

      final query = '''
        DELETE FROM grupos_metadados
        WHERE usuario_id = ?
        AND grupo_id NOT IN (
          SELECT DISTINCT COALESCE(grupo_recorrencia, grupo_parcelamento)
          FROM transacoes
          WHERE usuario_id = ?
          AND (grupo_recorrencia IS NOT NULL OR grupo_parcelamento IS NOT NULL)
        )
      ''';

      final rowsAffected = await _localDB.database!.rawDelete(query, [usuarioId, usuarioId]);

      if (rowsAffected > 0) {
        log('✅ $rowsAffected metadados órfãos removidos');
      }

      return rowsAffected;
    } catch (e) {
      log('❌ Erro ao limpar metadados órfãos: $e');
      return 0;
    }
  }

  /// 🔄 SINCRONIZAR TODOS OS METADADOS DE UM USUÁRIO
  Future<int> sincronizarTodosMetadadosUsuario(String usuarioId) async {
    try {
      print('🔄 Sincronizando todos os metadados para usuário: $usuarioId');

      // Debug: verificar se tabela existe
      try {
        final testQuery = await _localDB.rawQuery('SELECT COUNT(*) as count FROM grupos_metadados WHERE 1=0');
        print('✅ Tabela grupos_metadados existe');
      } catch (e) {
        print('❌ ERRO: Tabela grupos_metadados NÃO existe: $e');
        return 0;
      }

      // Buscar todos os grupos únicos de transações
      final query = '''
        SELECT
          COALESCE(grupo_recorrencia, grupo_parcelamento) as grupo_id,
          CASE
            WHEN grupo_recorrencia IS NOT NULL THEN 'recorrencia'
            ELSE 'parcelamento'
          END as tipo_grupo
        FROM transacoes
        WHERE usuario_id = ?
        AND (grupo_recorrencia IS NOT NULL OR grupo_parcelamento IS NOT NULL)
        GROUP BY grupo_id, tipo_grupo
      ''';

      final grupos = await _localDB.rawQuery(query, [usuarioId]);
      int sincronizados = 0;

      for (final grupo in grupos) {
        final grupoId = grupo['grupo_id'] as String;
        final tipoGrupo = grupo['tipo_grupo'] as String;

        final sucesso = await atualizarMetadadosGrupo(grupoId, usuarioId, tipoGrupo);
        if (sucesso) {
          sincronizados++;
        }
      }

      // Limpar órfãos após sincronização
      await limparMetadadosOrfaos(usuarioId);

      log('✅ $sincronizados grupos de metadados sincronizados');
      return sincronizados;
    } catch (e) {
      log('❌ Erro ao sincronizar metadados do usuário: $e');
      return 0;
    }
  }

  /// 💾 SALVAR METADADOS VINDOS DO SUPABASE (método interno usado pelo sync)
  Future<bool> salvarMetadadosSupabase(Map<String, dynamic> metadados) async {
    try {
      final grupoId = metadados['grupo_id'] as String;
      final usuarioId = _localDB.currentUserId!;

      print('💾 Salvando metadados do Supabase para grupo: $grupoId');
      print('   - Total items: ${metadados['total_items']}');
      print('   - Efetivados: ${metadados['items_efetivados']}');
      print('   - Valor total: ${metadados['valor_total']}');

      // Verificar se já existe
      final existingResult = await _localDB.select(
        'grupos_metadados',
        where: 'grupo_id = ? AND usuario_id = ?',
        whereArgs: [grupoId, usuarioId],
        limit: 1,
      );

      final now = DateTime.now();
      final metadadosData = {
        'usuario_id': usuarioId,
        'tipo_grupo': metadados['tipo_grupo'],
        'grupo_id': grupoId,
        'descricao': metadados['descricao'],
        'valor_unitario': metadados['valor_unitario'],
        'data_primeira': (metadados['data_primeira'] as DateTime).toIso8601String(),
        'data_ultima': (metadados['data_ultima'] as DateTime).toIso8601String(),
        'total_items': metadados['total_items'],
        'items_efetivados': metadados['items_efetivados'],
        'items_pendentes': metadados['items_pendentes'],
        'valor_total': metadados['valor_total'],
        'valor_efetivado': metadados['valor_efetivado'],
        'valor_pendente': metadados['valor_pendente'],
        'tipo_recorrencia': metadados['tipo_recorrencia'],
        'updated_at': now.toIso8601String(),
      };

      if (existingResult.isEmpty) {
        // Criar novo
        metadadosData['id'] = _uuid.v4();
        metadadosData['created_at'] = now.toIso8601String();
        await _localDB.database!.insert('grupos_metadados', metadadosData);
        print('✅ Novos metadados criados para grupo: $grupoId');
      } else {
        // Atualizar existente
        await _localDB.database!.update(
          'grupos_metadados',
          metadadosData,
          where: 'grupo_id = ? AND usuario_id = ?',
          whereArgs: [grupoId, usuarioId],
        );
        print('✅ Metadados atualizados para grupo: $grupoId');
      }

      return true;
    } catch (e) {
      print('❌ Erro ao salvar metadados do Supabase: $e');
      return false;
    }
  }

  /// 🧹 LIMPAR TODOS OS METADADOS (para forçar nova sincronização)
  Future<int> limparTodosMetadados() async {
    try {
      print('🧹 Limpando todos os metadados para forçar nova sincronização...');

      final rowsDeleted = await _localDB.database!.delete('grupos_metadados');

      print('✅ $rowsDeleted registros de metadados removidos');
      return rowsDeleted;
    } catch (e) {
      print('❌ Erro ao limpar metadados: $e');
      return 0;
    }
  }
}