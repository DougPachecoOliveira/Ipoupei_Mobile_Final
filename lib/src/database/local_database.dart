// 💾 Local Database - iPoupei Mobile
// 
// Gerencia SQLite local como mirror do Supabase
// Armazena dados offline e sincroniza quando online
// 
// Baseado em: Tabelas principais do Supabase
// Arquitetura: SQLite + Mirror Pattern

import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../sync/sync_manager.dart';

/// Local Database Service - Gerencia dados offline
class LocalDatabase {
  static LocalDatabase? _instance;
  static LocalDatabase get instance {
    _instance ??= LocalDatabase._internal();
    return _instance!;
  }
  
  LocalDatabase._internal();
  
  Database? _database;
  String? _currentUserId;
  bool _initialized = false;
  
  /// Getters públicos
  bool get isInitialized => _initialized;
  String? get currentUserId => _currentUserId;
  Database? get database => _database;
  
  /// 🚀 INICIALIZA DATABASE
  Future<void> initialize() async {
    if (_initialized && _database != null) return;

    debugPrint('💾 Inicializando Local Database...');

    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'ipoupei_local.db');

      _database = await openDatabase(
        path,
        version: 6,
        onCreate: _createTables,
        onUpgrade: _upgradeTables,
      );

      _initialized = true;
      debugPrint('✅ Local Database inicializado: $path');

    } catch (e) {
      debugPrint('❌ Erro ao inicializar Local Database: $e');
      rethrow;
    }
  }

  /// 🗑️ DELETAR E RECRIAR DATABASE
  Future<void> deletarERecriarDatabase() async {
    debugPrint('🗑️ Deletando e recriando banco de dados...');

    try {
      // Fechar database se estiver aberto
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Deletar arquivo do banco
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'ipoupei_local.db');
      await deleteDatabase(path);

      _initialized = false;
      debugPrint('✅ Banco de dados deletado: $path');

      // Reinicializar
      await initialize();
      debugPrint('✅ Banco de dados recriado com sucesso!');

    } catch (e) {
      debugPrint('❌ Erro ao deletar e recriar banco: $e');
      rethrow;
    }
  }

  /// 📋 CRIA TABELAS ESPELHO DO SUPABASE
  Future<void> _createTables(Database db, int version) async {
    debugPrint('📋 Criando tabelas locais...');
    
    // Tabela perfil_usuario - espelho exato do Supabase
    await db.execute('''
      CREATE TABLE perfil_usuario (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        email TEXT NOT NULL,
        avatar_url TEXT,
        telefone TEXT,
        data_nascimento TEXT,
        profissao TEXT,
        perfil_publico INTEGER DEFAULT 0,
        aceita_notificacoes INTEGER DEFAULT 1,
        aceita_marketing INTEGER DEFAULT 0,
        moeda_padrao TEXT DEFAULT 'BRL',
        formato_data TEXT DEFAULT 'DD/MM/YYYY',
        primeiro_dia_semana INTEGER DEFAULT 1,
        diagnostico_completo INTEGER DEFAULT 0,
        data_diagnostico TEXT,
        sentimento_financeiro TEXT,
        percepcao_controle TEXT,
        percepcao_gastos TEXT,
        disciplina_financeira TEXT,
        relacao_dinheiro TEXT,
        renda_mensal REAL,
        tipo_renda TEXT,
        conta_ativa INTEGER DEFAULT 1,
        data_desativacao TEXT,
        media_horas_trabalhadas_mes INTEGER,
        primeiro_acesso INTEGER DEFAULT 1,
        diagnostico_etapa_atual INTEGER DEFAULT 0,
        diagnostico_progresso_json TEXT,
        diagnostico_score_total INTEGER DEFAULT 0,
        diagnostico_score_percepcao INTEGER DEFAULT 0,
        diagnostico_score_organizacao INTEGER DEFAULT 0,
        diagnostico_score_controle INTEGER DEFAULT 0,
        diagnostico_score_planejamento INTEGER DEFAULT 0,
        diagnostico_score_investimento INTEGER DEFAULT 0,
        diagnostico_resultado_json TEXT,
        aceita_comunic_email INTEGER DEFAULT 1,
        aceita_comunic_whatsapp INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        last_sync TEXT
      )
    ''');
    
    // Tabela notificacoes - espelho exato do Supabase
    await db.execute('''
      CREATE TABLE notificacoes (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        titulo TEXT NOT NULL,
        mensagem TEXT NOT NULL,
        tipo TEXT DEFAULT 'info',
        categoria_notificacao TEXT,
        referencia TEXT,
        importante INTEGER DEFAULT 0,
        lida INTEGER DEFAULT 0,
        data_criacao TEXT NOT NULL,
        data_leitura TEXT,
        arquivada INTEGER DEFAULT 0,
        data_arquivamento TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        sync_status TEXT DEFAULT 'synced',
        last_sync TEXT,
        FOREIGN KEY (user_id) REFERENCES perfil_usuario (id)
      )
    ''');
    
    // Tabela contas - espelho exato do Supabase
    await db.execute('''
      CREATE TABLE contas (
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        banco TEXT,
        agencia TEXT,
        conta TEXT,
        saldo REAL DEFAULT 0,
        cor TEXT DEFAULT '#3B82F6',
        icone TEXT DEFAULT 'bank',
        ativo INTEGER DEFAULT 1,
        incluir_soma_total INTEGER DEFAULT 1,
        ordem INTEGER DEFAULT 0,
        observacoes TEXT,
        origem_diagnostico INTEGER DEFAULT 0,
        conta_principal INTEGER DEFAULT 0,
        saldo_inicial REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        last_sync TEXT,
        FOREIGN KEY (usuario_id) REFERENCES perfil_usuario (id)
      )
    ''');
    
    // Tabela categorias - espelho exato do Supabase
    await db.execute('''
      CREATE TABLE categorias (
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        cor TEXT DEFAULT '#6B7280',
        icone TEXT DEFAULT 'folder',
        descricao TEXT,
        ativo INTEGER DEFAULT 1,
        ordem INTEGER DEFAULT 0,
        classificacao_regra TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        last_sync TEXT,
        FOREIGN KEY (usuario_id) REFERENCES perfil_usuario (id)
      )
    ''');
    
    // Tabela subcategorias - espelho exato do Supabase
    await db.execute('''
      CREATE TABLE subcategorias (
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        categoria_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        descricao TEXT,
        ativo INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        last_sync TEXT,
        FOREIGN KEY (usuario_id) REFERENCES perfil_usuario (id),
        FOREIGN KEY (categoria_id) REFERENCES categorias (id)
      )
    ''');
    
    // Tabela cartoes - espelho exato do Supabase
    await db.execute('''
      CREATE TABLE cartoes (
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        bandeira TEXT,
        banco TEXT,
        limite REAL DEFAULT 0,
        dia_fechamento INTEGER,
        dia_vencimento INTEGER,
        cor TEXT DEFAULT '#EF4444',
        ativo INTEGER DEFAULT 1,
        observacoes TEXT,
        origem_diagnostico INTEGER DEFAULT 0,
        conta_debito_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        last_sync TEXT,
        FOREIGN KEY (usuario_id) REFERENCES perfil_usuario (id),
        FOREIGN KEY (conta_debito_id) REFERENCES contas (id)
      )
    ''');
    
    // Tabela transacoes - espelho exato do Supabase
    await db.execute('''
      CREATE TABLE transacoes (
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        descricao TEXT NOT NULL,
        valor REAL NOT NULL,
        tipo TEXT NOT NULL,
        data TEXT NOT NULL,
        conta_id TEXT,
        cartao_id TEXT,
        categoria_id TEXT,
        subcategoria_id TEXT,
        efetivado INTEGER DEFAULT 1,
        recorrente INTEGER DEFAULT 0,
        transferencia INTEGER DEFAULT 0,
        conta_destino_id TEXT,
        compartilhada_com TEXT,
        parcela_atual INTEGER,
        total_parcelas INTEGER,
        grupo_parcelamento TEXT,
        observacoes TEXT,
        tags TEXT,
        localizacao TEXT,
        origem_diagnostico INTEGER DEFAULT 0,
        sincronizado INTEGER DEFAULT 1,
        valor_parcela REAL,
        numero_parcelas INTEGER DEFAULT 1,
        fatura_vencimento TEXT,
        grupo_recorrencia TEXT,
        eh_recorrente INTEGER DEFAULT 0,
        tipo_recorrencia TEXT,
        numero_recorrencia INTEGER,
        total_recorrencias INTEGER,
        data_proxima_recorrencia TEXT,
        ajuste_manual INTEGER DEFAULT 0,
        motivo_ajuste TEXT,
        tipo_receita TEXT,
        tipo_despesa TEXT,
        data_efetivacao TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        last_sync TEXT,
        FOREIGN KEY (usuario_id) REFERENCES perfil_usuario (id),
        FOREIGN KEY (conta_id) REFERENCES contas (id),
        FOREIGN KEY (cartao_id) REFERENCES cartoes (id),
        FOREIGN KEY (categoria_id) REFERENCES categorias (id),
        FOREIGN KEY (subcategoria_id) REFERENCES subcategorias (id),
        FOREIGN KEY (conta_destino_id) REFERENCES contas (id)
      )
    ''');
    
    // Tabela faturas - espelho exato do Supabase
    await db.execute('''
      CREATE TABLE faturas (
        id TEXT PRIMARY KEY,
        cartao_id TEXT NOT NULL,
        usuario_id TEXT NOT NULL,
        ano INTEGER NOT NULL,
        mes INTEGER NOT NULL,
        data_fechamento TEXT NOT NULL,
        data_vencimento TEXT NOT NULL,
        valor_total REAL NOT NULL DEFAULT 0,
        valor_pago REAL DEFAULT 0,
        valor_minimo REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'aberta',
        paga INTEGER DEFAULT 0,
        data_pagamento TEXT,
        observacoes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sincronizado INTEGER DEFAULT 0,
        sync_status TEXT DEFAULT 'synced',
        last_sync TEXT,
        FOREIGN KEY (cartao_id) REFERENCES cartoes (id),
        FOREIGN KEY (usuario_id) REFERENCES perfil_usuario (id)
      )
    ''');
    
    // Tabela planejamentos - espelho exato do Supabase
    await db.execute('''
      CREATE TABLE planejamentos (
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        ano INTEGER NOT NULL,
        mes INTEGER NOT NULL,
        categoria_id TEXT NOT NULL,
        subcategoria_id TEXT,
        tipo TEXT NOT NULL,
        valor_planejado REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        last_sync TEXT,
        FOREIGN KEY (usuario_id) REFERENCES perfil_usuario (id),
        FOREIGN KEY (categoria_id) REFERENCES categorias (id),
        FOREIGN KEY (subcategoria_id) REFERENCES subcategorias (id)
      )
    ''');

    // Tabela de sincronização
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT,
        created_at TEXT NOT NULL,
        attempts INTEGER DEFAULT 0
      )
    ''');

    // Tabela grupos_metadados - para resolver performance de grupos grandes
    await db.execute('''
      CREATE TABLE grupos_metadados (
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        tipo_grupo TEXT NOT NULL,
        grupo_id TEXT NOT NULL,
        descricao TEXT,
        valor_unitario REAL,
        data_primeira TEXT,
        data_ultima TEXT,
        total_items INTEGER,
        items_efetivados INTEGER,
        items_pendentes INTEGER,
        valor_total REAL,
        valor_efetivado REAL,
        valor_pendente REAL,
        tipo_recorrencia TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        sync_status TEXT DEFAULT 'synced',
        last_sync TEXT,
        UNIQUE(grupo_id, usuario_id),
        FOREIGN KEY (usuario_id) REFERENCES perfil_usuario (id)
      )
    ''');
    
    // Índices para melhor performance
    await db.execute('CREATE INDEX idx_contas_usuario ON contas(usuario_id)');
    await db.execute('CREATE INDEX idx_categorias_usuario ON categorias(usuario_id)');
    await db.execute('CREATE INDEX idx_subcategorias_categoria ON subcategorias(categoria_id)');
    await db.execute('CREATE INDEX idx_cartoes_usuario ON cartoes(usuario_id)');
    await db.execute('CREATE INDEX idx_transacoes_usuario ON transacoes(usuario_id)');
    await db.execute('CREATE INDEX idx_transacoes_data ON transacoes(data)');
    await db.execute('CREATE INDEX idx_transacoes_tipo ON transacoes(tipo)');
    await db.execute('CREATE INDEX idx_faturas_usuario ON faturas(usuario_id)');
    await db.execute('CREATE INDEX idx_faturas_cartao ON faturas(cartao_id)');
    await db.execute('CREATE INDEX idx_faturas_periodo ON faturas(ano, mes)');
    await db.execute('CREATE INDEX idx_planejamentos_usuario ON planejamentos(usuario_id)');
    await db.execute('CREATE INDEX idx_planejamentos_periodo ON planejamentos(ano, mes)');
    await db.execute('CREATE INDEX idx_planejamentos_categoria ON planejamentos(categoria_id)');
    await db.execute('CREATE INDEX idx_sync_queue_table ON sync_queue(table_name)');
    await db.execute('CREATE INDEX idx_grupos_metadados_usuario ON grupos_metadados(usuario_id)');
    await db.execute('CREATE INDEX idx_grupos_metadados_grupo ON grupos_metadados(grupo_id)');
    await db.execute('CREATE INDEX idx_grupos_metadados_tipo ON grupos_metadados(tipo_grupo)');
    
    debugPrint('✅ Tabelas locais criadas com estrutura espelho do Supabase');
  }
  
  /// 🔄 UPGRADE DE TABELAS
  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Upgrade de tabelas: $oldVersion -> $newVersion');
    
    if (oldVersion < 2) {
      debugPrint('🔄 Adicionando tabela faturas na versão 2...');

      // Tabela faturas - espelho exato do Supabase
      await db.execute('''
        CREATE TABLE faturas (
          id TEXT PRIMARY KEY,
          cartao_id TEXT NOT NULL,
          usuario_id TEXT NOT NULL,
          ano INTEGER NOT NULL,
          mes INTEGER NOT NULL,
          data_fechamento TEXT NOT NULL,
          data_vencimento TEXT NOT NULL,
          valor_total REAL NOT NULL DEFAULT 0,
          valor_pago REAL DEFAULT 0,
          valor_minimo REAL NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'aberta',
          paga INTEGER DEFAULT 0,
          data_pagamento TEXT,
          observacoes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          sincronizado INTEGER DEFAULT 0,
          sync_status TEXT DEFAULT 'synced',
          last_sync TEXT,
          FOREIGN KEY (cartao_id) REFERENCES cartoes (id),
          FOREIGN KEY (usuario_id) REFERENCES perfil_usuario (id)
        )
      ''');

      // Índices para a tabela faturas
      await db.execute('CREATE INDEX idx_faturas_usuario ON faturas(usuario_id)');
      await db.execute('CREATE INDEX idx_faturas_cartao ON faturas(cartao_id)');
      await db.execute('CREATE INDEX idx_faturas_periodo ON faturas(ano, mes)');

      debugPrint('✅ Tabela faturas criada na versão 2');
    }

    if (oldVersion < 3) {
      debugPrint('🔄 Adicionando campos do diagnóstico na versão 3...');

      // Adicionar novos campos de diagnóstico na tabela perfil_usuario
      await db.execute('ALTER TABLE perfil_usuario ADD COLUMN diagnostico_progresso_json TEXT');
      await db.execute('ALTER TABLE perfil_usuario ADD COLUMN diagnostico_score_total INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE perfil_usuario ADD COLUMN diagnostico_score_percepcao INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE perfil_usuario ADD COLUMN diagnostico_score_organizacao INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE perfil_usuario ADD COLUMN diagnostico_score_controle INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE perfil_usuario ADD COLUMN diagnostico_score_planejamento INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE perfil_usuario ADD COLUMN diagnostico_score_investimento INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE perfil_usuario ADD COLUMN diagnostico_resultado_json TEXT');
      // await db.execute('ALTER TABLE perfil_usuario ADD COLUMN diagnostico_dividas_json TEXT'); // Campo não existe no Supabase

      debugPrint('✅ Campos do diagnóstico adicionados na versão 3');
    }

    if (oldVersion < 4) {
      debugPrint('🔄 Adicionando tabelas planejamentos e grupos_metadados na versão 4...');

      // Tabela planejamentos - espelho exato do Supabase
      await db.execute('''
        CREATE TABLE planejamentos (
          id TEXT PRIMARY KEY,
          usuario_id TEXT NOT NULL,
          ano INTEGER NOT NULL,
          mes INTEGER NOT NULL,
          categoria_id TEXT NOT NULL,
          subcategoria_id TEXT,
          tipo TEXT NOT NULL,
          valor_planejado REAL NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          sync_status TEXT DEFAULT 'synced',
          last_sync TEXT,
          FOREIGN KEY (usuario_id) REFERENCES perfil_usuario (id),
          FOREIGN KEY (categoria_id) REFERENCES categorias (id),
          FOREIGN KEY (subcategoria_id) REFERENCES subcategorias (id)
        )
      ''');

      // Tabela grupos_metadados - para resolver performance de grupos grandes
      await db.execute('''
        CREATE TABLE grupos_metadados (
          id TEXT PRIMARY KEY,
          usuario_id TEXT NOT NULL,
          tipo_grupo TEXT NOT NULL,
          grupo_id TEXT NOT NULL,
          descricao TEXT,
          valor_unitario REAL,
          data_primeira TEXT,
          data_ultima TEXT,
          total_items INTEGER,
          items_efetivados INTEGER,
          items_pendentes INTEGER,
          valor_total REAL,
          valor_efetivado REAL,
          valor_pendente REAL,
          tipo_recorrencia TEXT,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          sync_status TEXT DEFAULT 'synced',
          last_sync TEXT,
          UNIQUE(grupo_id, usuario_id),
          FOREIGN KEY (usuario_id) REFERENCES perfil_usuario (id)
        )
      ''');

      // Índices para a tabela planejamentos
      await db.execute('CREATE INDEX idx_planejamentos_usuario ON planejamentos(usuario_id)');
      await db.execute('CREATE INDEX idx_planejamentos_periodo ON planejamentos(ano, mes)');
      await db.execute('CREATE INDEX idx_planejamentos_categoria ON planejamentos(categoria_id)');

      // Índices para a tabela grupos_metadados
      await db.execute('CREATE INDEX idx_grupos_metadados_usuario ON grupos_metadados(usuario_id)');
      await db.execute('CREATE INDEX idx_grupos_metadados_grupo ON grupos_metadados(grupo_id)');
      await db.execute('CREATE INDEX idx_grupos_metadados_tipo ON grupos_metadados(tipo_grupo)');

      debugPrint('✅ Tabelas planejamentos e grupos_metadados criadas na versão 4');
    }

    if (oldVersion < 5) {
      debugPrint('🔄 Verificação e correção da versão 5...');

      // Verifica se a tabela planejamentos existe (casos de upgrade falhado)
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='planejamentos';"
      );

      if (result.isEmpty) {
        debugPrint('⚠️ Tabela planejamentos não encontrada, criando...');

        // Tabela planejamentos - espelho exato do Supabase
        await db.execute('''
          CREATE TABLE planejamentos (
            id TEXT PRIMARY KEY,
            usuario_id TEXT NOT NULL,
            ano INTEGER NOT NULL,
            mes INTEGER NOT NULL,
            categoria_id TEXT NOT NULL,
            subcategoria_id TEXT,
            tipo TEXT NOT NULL,
            valor_planejado REAL NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status TEXT DEFAULT 'synced',
            last_sync TEXT,
            FOREIGN KEY (usuario_id) REFERENCES perfil_usuario (id),
            FOREIGN KEY (categoria_id) REFERENCES categorias (id),
            FOREIGN KEY (subcategoria_id) REFERENCES subcategorias (id)
          )
        ''');

        // Índices para a tabela planejamentos
        await db.execute('CREATE INDEX idx_planejamentos_usuario ON planejamentos(usuario_id)');
        await db.execute('CREATE INDEX idx_planejamentos_periodo ON planejamentos(ano, mes)');
        await db.execute('CREATE INDEX idx_planejamentos_categoria ON planejamentos(categoria_id)');

        debugPrint('✅ Tabela planejamentos criada na versão 5');
      } else {
        debugPrint('✅ Tabela planejamentos já existe na versão 5');
      }
    }

    if (oldVersion < 6) {
      debugPrint('🔄 Adicionando colunas de comunicação na versão 6...');

      // Verificar se as colunas já existem antes de tentar adicioná-las
      final tableInfo = await db.rawQuery('PRAGMA table_info(perfil_usuario)');
      final columnNames = tableInfo.map((column) => column['name']).toSet();

      if (!columnNames.contains('aceita_comunic_email')) {
        await db.execute('ALTER TABLE perfil_usuario ADD COLUMN aceita_comunic_email INTEGER DEFAULT 1');
        debugPrint('✅ Coluna aceita_comunic_email adicionada');
      } else {
        debugPrint('✅ Coluna aceita_comunic_email já existe');
      }

      if (!columnNames.contains('aceita_comunic_whatsapp')) {
        await db.execute('ALTER TABLE perfil_usuario ADD COLUMN aceita_comunic_whatsapp INTEGER DEFAULT 1');
        debugPrint('✅ Coluna aceita_comunic_whatsapp adicionada');
      } else {
        debugPrint('✅ Coluna aceita_comunic_whatsapp já existe');
      }

      debugPrint('✅ Colunas de comunicação processadas na versão 6');
    }
  }
  
  /// 👤 DEFINE USUÁRIO ATUAL
  Future<void> setCurrentUser(String userId) async {
    if (!_initialized) await initialize();

    // Log apenas quando o usuário realmente muda
    if (_currentUserId != userId) {
      debugPrint('👤 Usuário alterado para: $userId');
      _currentUserId = userId;

      // Verifica se o perfil do usuário existe localmente
      await _ensureUserProfile(userId);
    }
  }
  
  /// 🚪 LIMPA USUÁRIO ATUAL
  Future<void> clearCurrentUser() async {
    if (!_initialized) return;
    
    debugPrint('🧹 Limpando dados do usuário atual...');
    
    _currentUserId = null;
    
    // TODO: Implementar limpeza seletiva de dados sensíveis
    // Por enquanto, mantemos os dados para funcionamento offline
    
    debugPrint('✅ Dados do usuário limpos');
  }
  
  /// 👤 GARANTE QUE PERFIL DO USUÁRIO EXISTE
  Future<void> _ensureUserProfile(String userId) async {
    try {
      final result = await _database!.query(
        'perfil_usuario',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      
      if (result.isEmpty) {
        debugPrint('👤 Criando perfil de usuário local: $userId');
        
        // ✅ OBTER DADOS DO USUÁRIO AUTENTICADO
        final user = Supabase.instance.client.auth.currentUser;
        final email = user?.email ?? 'usuario@app.com';
        final nome = user?.userMetadata?['nome'] ?? user?.userMetadata?['name'] ?? 'Usuário';
        
        await _database!.insert('perfil_usuario', {
          'id': userId,
          'nome': nome, // ✅ CAMPO OBRIGATÓRIO - dados reais do usuário
          'email': email, // ✅ CAMPO OBRIGATÓRIO - dados reais do usuário
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending',
          'last_sync': null,
        });
      }
      
    } catch (e) {
      debugPrint('❌ Erro ao garantir perfil do usuário: $e');
    }
  }
  
  /// 🔧 GARANTE INICIALIZAÇÃO ANTES DE QUALQUER OPERAÇÃO
  Future<void> _ensureInitialized() async {
    if (!_initialized || _database == null) {
      debugPrint('🔄 Auto-inicializando LocalDatabase...');
      await initialize();
    }
  }

  /// 📊 MÉTODOS BÁSICOS DE CRUD COM AUTO-INICIALIZAÇÃO
  
  /// Busca registros de uma tabela
  Future<List<Map<String, dynamic>>> select(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    await _ensureInitialized(); // ✅ AUTO-INICIALIZAÇÃO
    
    return await _database!.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }
  
  /// Executa uma query SQL customizada
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    await _ensureInitialized(); // ✅ AUTO-INICIALIZAÇÃO
    return await _database!.rawQuery(sql, arguments);
  }
  
  /// Insere registro em uma tabela
  Future<int> insert(String table, Map<String, dynamic> values) async {
    await _ensureInitialized(); // ✅ AUTO-INICIALIZAÇÃO
    
    // Adiciona metadados de sync
    values['created_at'] = DateTime.now().toIso8601String();
    values['updated_at'] = DateTime.now().toIso8601String();
    values['sync_status'] = 'pending';
    
    return await _database!.insert(table, values);
  }
  
  /// Atualiza registro em uma tabela
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    await _ensureInitialized(); // ✅ AUTO-INICIALIZAÇÃO
    
    // Atualiza metadados de sync
    values['updated_at'] = DateTime.now().toIso8601String();
    values['sync_status'] = 'pending';
    
    return await _database!.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }
  
  /// Deleta registro de uma tabela
  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    await _ensureInitialized(); // ✅ AUTO-INICIALIZAÇÃO
    
    return await _database!.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }
  
  /// 🔄 MÉTODOS DE SINCRONIZAÇÃO
  
  /// Adiciona operação à fila de sincronização E DISPARA SYNC AUTOMÁTICO
  Future<void> addToSyncQueue(
    String tableName,
    String recordId,
    String operation,
    Map<String, dynamic> data, {
    bool skipAutoSync = false,
  }) async {
    debugPrint('🔔 addToSyncQueue CHAMADO: $operation em $tableName.$recordId');
    debugPrint('📊 Dados: ${data.keys.join(', ')}');
    debugPrint('🏗️ Initialized: $_initialized, Database: ${_database != null}');
    
    if (!_initialized || _database == null) {
      debugPrint('❌ ERRO: Database não inicializado!');
      return;
    }
    
    try {
      await _database!.insert('sync_queue', {
        'table_name': tableName,
        'record_id': recordId,
        'operation': operation,
        'data': data.toString(), // JSON.encode seria melhor
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Item inserido na sync_queue com sucesso');
      
      // Verificar se foi inserido
      final count = await _database!.query('sync_queue', where: 'record_id = ?', whereArgs: [recordId]);
      debugPrint('🔍 Verificação: ${count.length} itens na queue para $recordId');
      
    } catch (e) {
      debugPrint('❌ ERRO ao inserir na sync_queue: $e');
      return;
    }
    
    // 🚀 DISPARA SINCRONIZAÇÃO AUTOMÁTICA APÓS ADICIONAR À QUEUE (SE NÃO FOR OPERAÇÃO EM LOTE)
    if (!skipAutoSync) {
      debugPrint('📡 Item adicionado à sync queue - disparando sincronização automática');
      _triggerAutoSync(tableName, operation, recordId);
    } else {
      debugPrint('⏸️ Auto sync pulado - operação em lote');
    }
  }
  
  /// 🚀 DISPARA SINCRONIZAÇÃO AUTOMÁTICA (SEM AWAIT PARA NÃO BLOQUEAR)
  void _triggerAutoSync(String tableName, String operation, String recordId) {
    // Executa de forma assíncrona para não bloquear a operação principal
    Future.microtask(() async {
      try {
        debugPrint('🔄 Iniciando sync automático para $operation em $tableName.$recordId');
        
        // Acessa o SyncManager e dispara sincronização
        final syncManager = SyncManager.instance;
        
        // DEBUG: Verificar status do sync manager
        debugPrint('🔍 SYNC DEBUG: isOnline=${syncManager.isOnline}, status=${syncManager.status}');

        // Só sincroniza se estiver online e não estiver já sincronizando
        if (syncManager.isOnline && syncManager.status != SyncStatus.syncing) {
          debugPrint('🔄 Executando sync automático para $operation em $tableName.$recordId');
          await syncManager.syncAll();
          debugPrint('✅ Sync automático concluído para $operation em $tableName.$recordId');

          // 🔄 AGENDA REFRESH INTELIGENTE: Notifica UI após 3 segundos
          _agendarNotificacaoRefresh(tableName, operation, recordId);
        } else {
          debugPrint('⏸️ Sync automático ignorado - isOnline: ${syncManager.isOnline}, status: ${syncManager.status}');

          // 🚨 FORÇAR SYNC se for planejamentos (temporário para debug)
          if (tableName == 'planejamentos') {
            debugPrint('🔥 FORÇANDO sync para planejamentos...');
            try {
              // Força sync completo para garantir que itens sejam processados
              await syncManager.syncAll();
              debugPrint('✅ Sync forçado concluído');
              _agendarNotificacaoRefresh(tableName, operation, recordId);
            } catch (syncError) {
              debugPrint('❌ Erro no sync forçado: $syncError');
            }
          }
        }
        
      } catch (e) {
        debugPrint('❌ Erro no sync automático: $e');
        // Não propaga o erro para não afetar a operação principal
      }
    });
  }

  /// 📡 AGENDA NOTIFICAÇÃO DE REFRESH PARA UIs
  void _agendarNotificacaoRefresh(String tableName, String operation, String recordId) {
    Future.delayed(const Duration(seconds: 3), () {
      debugPrint('📡 Refresh recomendado para $tableName após $operation');
      // Aqui poderia ter um StreamController global para notificar UIs
      // Por enquanto, apenas log para debug
    });
  }
  
  /// Busca itens pendentes de sincronização
  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    if (!_initialized || _database == null) return [];
    
    return await _database!.query(
      'sync_queue',
      orderBy: 'created_at ASC',
      limit: 50,
    );
  }
  
  /// Remove item da fila de sincronização
  Future<void> removeSyncItem(int syncId) async {
    if (!_initialized || _database == null) return;
    
    await _database!.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [syncId],
    );
  }
  
  /// 🧹 LIMPA TODA A QUEUE DE SYNC (para resolver problemas de read-only)
  Future<void> clearSyncQueue() async {
    if (!_initialized || _database == null) return;
    
    final count = await _database!.delete('sync_queue');
    debugPrint('🧹 Queue de sync limpa: $count itens removidos');
  }
  
  /// 📂 MÉTODOS ESPECÍFICOS PARA CATEGORIAS
  
  /// Busca categorias localmente (offline-first)
  Future<List<Map<String, dynamic>>> fetchCategoriasLocal({String? tipo}) async {
    if (!_initialized || _database == null || _currentUserId == null) return [];
    
    String whereClause = 'usuario_id = ? AND ativo = 1';
    List<dynamic> whereArgs = [_currentUserId];
    
    if (tipo != null && tipo.isNotEmpty) {
      whereClause += ' AND tipo = ?';
      whereArgs.add(tipo);
    }
    
    final result = await _database!.query(
      'categorias',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    
    return result;
  }

  /// 🚀 BUSCAR CATEGORIAS COM VALORES PRÉ-CALCULADOS (OFFLINE - OTIMIZADO)
  /// Baseado no padrão de performance do conta_service
  Future<List<Map<String, dynamic>>> fetchCategoriasComValoresLocal({
    String? tipo,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    if (!_initialized || _database == null || _currentUserId == null) return [];
    
    log('🚀 Buscando categorias com valores otimizado (offline)...');
    
    // Constrói WHERE clause dinâmica
    String whereClauseCategoria = 'c.usuario_id = ? AND c.ativo = 1';
    String whereClauseTransacao = 't.usuario_id = ? AND t.efetivado = 1';
    List<dynamic> whereArgs = [_currentUserId, _currentUserId];
    
    if (tipo != null && tipo.isNotEmpty) {
      whereClauseCategoria += ' AND c.tipo = ?';
      whereArgs.add(tipo);
    }
    
    if (dataInicio != null) {
      whereClauseTransacao += ' AND t.data >= ?';
      whereArgs.add(dataInicio.toIso8601String().split('T')[0]);
    }
    
    if (dataFim != null) {
      whereClauseTransacao += ' AND t.data <= ?';
      whereArgs.add(dataFim.toIso8601String().split('T')[0]);
    }
    
    // Query otimizada com LEFT JOIN - Uma única query ao invés de N+1
    final sql = '''
      SELECT 
        c.id,
        c.nome,
        c.cor,
        c.icone,
        c.tipo,
        c.ativo,
        c.created_at,
        c.updated_at,
        COALESCE(stats.valor_total, 0.0) as valor_total,
        COALESCE(stats.quantidade_transacoes, 0) as quantidade_transacoes
      FROM categorias c
      LEFT JOIN (
        SELECT 
          t.categoria_id,
          SUM(t.valor) as valor_total,
          COUNT(*) as quantidade_transacoes
        FROM transacoes t
        WHERE $whereClauseTransacao
        GROUP BY t.categoria_id
      ) stats ON c.id = stats.categoria_id
      WHERE $whereClauseCategoria
      ORDER BY stats.valor_total DESC, c.nome ASC
    ''';
    
    log('🔍 SQL Otimizado: $sql');
    log('🔍 Args: $whereArgs');
    log('🔍 User ID: $_currentUserId');
    log('🔍 Período: ${dataInicio?.toIso8601String().split('T')[0]} até ${dataFim?.toIso8601String().split('T')[0]}');

    final result = await _database!.rawQuery(sql, whereArgs);

    log('✅ Categorias com valores carregadas: ${result.length}');

    // 🐛 DEBUG: Log detailed results
    for (final row in result) {
      final nome = row['nome'] as String;
      final valorTotal = row['valor_total'] as double;
      final qtdTransacoes = row['quantidade_transacoes'] as int;
      log('🔍 Categoria: $nome | Valor: R\$ $valorTotal | Transações: $qtdTransacoes');
    }

    // 🐛 DEBUG: Verificar se há transações no período para debug
    final debugTransacoes = await _database!.rawQuery('''
      SELECT COUNT(*) as total, SUM(valor) as soma_valores
      FROM transacoes
      WHERE usuario_id = ?
        AND efetivado = 1
        AND data >= ?
        AND data <= ?
    ''', [_currentUserId,
          dataInicio?.toIso8601String().split('T')[0] ?? '1900-01-01',
          dataFim?.toIso8601String().split('T')[0] ?? '2100-12-31']);

    if (debugTransacoes.isNotEmpty) {
      final totalTransacoes = debugTransacoes.first['total'] as int;
      final somaValores = debugTransacoes.first['soma_valores'] as double?;
      log('🔍 DEBUG: Total transações efetivadas no período: $totalTransacoes | Soma total: R\$ ${somaValores ?? 0.0}');
    }

    return result;
  }
  
  /// Busca subcategorias localmente com JOIN
  Future<List<Map<String, dynamic>>> fetchSubcategoriasLocal({String? categoriaId}) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      debugPrint('❌ fetchSubcategoriasLocal: Database não inicializado');
      return [];
    }
    
    String whereClause = 's.usuario_id = ? AND s.ativo = 1';
    List<dynamic> whereArgs = [_currentUserId];

    if (categoriaId != null && categoriaId.isNotEmpty) {
      whereClause += ' AND s.categoria_id = ?';
      whereArgs.add(categoriaId);
    }
    
    final result = await _database!.rawQuery('''
      SELECT 
        s.id,
        s.usuario_id,
        s.nome,
        s.descricao,
        s.ativo,
        s.created_at,
        s.updated_at,
        s.categoria_id,
        COALESCE(c.nome, 'Categoria não encontrada') AS categoria_nome,
        COALESCE(c.tipo, 'unknown') AS categoria_tipo
      FROM subcategorias s
      LEFT JOIN categorias c ON c.id = s.categoria_id AND c.usuario_id = s.usuario_id AND c.ativo = 1
      WHERE $whereClause
      ORDER BY s.created_at DESC
    ''', whereArgs);
    
    // Log apenas em caso de erro ou quando vazio
    if (result.isEmpty && categoriaId != null) {
      debugPrint('⚠️ Nenhuma subcategoria encontrada para categoria: $categoriaId');
    }
    
    return result;
  }
  
  /// Adiciona categoria localmente
  Future<String> addCategoriaLocal(Map<String, dynamic> categoriaData) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }
    
    categoriaData['sync_status'] = 'pending';
    categoriaData['last_sync'] = null;
    
    await _database!.insert('categorias', categoriaData);
    
    // Adiciona à fila de sync
    await addToSyncQueue(
      'categorias',
      categoriaData['id'],
      'INSERT',
      categoriaData,
    );
    
    return categoriaData['id'];
  }
  
  /// Adiciona subcategoria localmente  
  Future<String> addSubcategoriaLocal(Map<String, dynamic> subcategoriaData) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }
    
    debugPrint('💾 Salvando subcategoria offline: ${subcategoriaData['nome']}');
    subcategoriaData['sync_status'] = 'pending';
    subcategoriaData['last_sync'] = null;

    await _database!.insert('subcategorias', subcategoriaData);
    
    // Adiciona à fila de sync
    await addToSyncQueue(
      'subcategorias',
      subcategoriaData['id'],
      'INSERT',
      subcategoriaData,
    );
    
    return subcategoriaData['id'];
  }
  
  /// Atualiza categoria localmente
  Future<void> updateCategoriaLocal(String categoriaId, Map<String, dynamic> updateData) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }
    
    // Adiciona metadados de sync
    updateData['updated_at'] = DateTime.now().toIso8601String();
    updateData['sync_status'] = 'pending';
    
    await _database!.update(
      'categorias',
      updateData,
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [categoriaId, _currentUserId],
    );
    
    // Adiciona à fila de sync
    await addToSyncQueue(
      'categorias',
      categoriaId,
      'UPDATE',
      updateData,
    );
  }
  
  /// Atualiza subcategoria localmente  
  Future<void> updateSubcategoriaLocal(String subcategoriaId, String categoriaId, Map<String, dynamic> updateData) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }
    
    // Adiciona metadados de sync
    updateData['updated_at'] = DateTime.now().toIso8601String();
    updateData['sync_status'] = 'pending';
    
    await _database!.update(
      'subcategorias',
      updateData,
      where: 'id = ? AND categoria_id = ? AND usuario_id = ?',
      whereArgs: [subcategoriaId, categoriaId, _currentUserId],
    );
    
    // Adiciona à fila de sync
    await addToSyncQueue(
      'subcategorias',
      subcategoriaId,
      'UPDATE',
      updateData,
    );
  }
  
  /// Verifica se categoria tem transações (para soft/hard delete)
  Future<bool> categoriaTemTransacoes(String categoriaId) async {
    if (!_initialized || _database == null || _currentUserId == null) return false;
    
    final result = await _database!.query(
      'transacoes',
      where: 'categoria_id = ? AND usuario_id = ?',
      whereArgs: [categoriaId, _currentUserId],
      limit: 1,
    );
    
    return result.isNotEmpty;
  }
  
  /// Verifica se subcategoria tem transações
  Future<bool> subcategoriaTemTransacoes(String subcategoriaId) async {
    if (!_initialized || _database == null || _currentUserId == null) return false;
    
    final result = await _database!.query(
      'transacoes',
      where: 'subcategoria_id = ? AND usuario_id = ?',
      whereArgs: [subcategoriaId, _currentUserId],
      limit: 1,
    );
    
    return result.isNotEmpty;
  }
  
  /// Delete categoria com lógica soft/hard delete
  Future<Map<String, dynamic>> deleteCategoriaLocal(String categoriaId) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }
    
    // Verifica se tem transações
    final temTransacoes = await categoriaTemTransacoes(categoriaId);
    
    if (temTransacoes) {
      // SOFT DELETE: ativo = false
      await _database!.update(
        'categorias',
        {
          'ativo': 0,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending',
        },
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [categoriaId, _currentUserId],
      );
      
      // Desativa subcategorias também
      await _database!.update(
        'subcategorias',
        {
          'ativo': 0,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending',
        },
        where: 'categoria_id = ? AND usuario_id = ?',
        whereArgs: [categoriaId, _currentUserId],
      );
      
      // Adiciona à fila de sync
      await addToSyncQueue('categorias', categoriaId, 'SOFT_DELETE', {'ativo': 0});
      
      return {'success': true, 'type': 'soft_delete', 'message': 'Categoria desativada'};
    } else {
      // HARD DELETE: Remove fisicamente
      
      // 1. Remove subcategorias primeiro
      await _database!.delete(
        'subcategorias',
        where: 'categoria_id = ? AND usuario_id = ?',
        whereArgs: [categoriaId, _currentUserId],
      );
      
      // 2. Remove categoria
      await _database!.delete(
        'categorias',
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [categoriaId, _currentUserId],
      );
      
      // Adiciona à fila de sync
      await addToSyncQueue('categorias', categoriaId, 'DELETE', {});
      
      return {'success': true, 'type': 'hard_delete', 'message': 'Categoria removida'};
    }
  }
  
  /// Delete subcategoria com lógica soft/hard delete
  Future<Map<String, dynamic>> deleteSubcategoriaLocal(String subcategoriaId, String categoriaId) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }
    
    // Verifica se tem transações
    final temTransacoes = await subcategoriaTemTransacoes(subcategoriaId);
    
    if (temTransacoes) {
      // SOFT DELETE: ativo = false
      await _database!.update(
        'subcategorias',
        {
          'ativo': 0,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending',
        },
        where: 'id = ? AND categoria_id = ? AND usuario_id = ?',
        whereArgs: [subcategoriaId, categoriaId, _currentUserId],
      );
      
      // Adiciona à fila de sync
      await addToSyncQueue('subcategorias', subcategoriaId, 'SOFT_DELETE', {'ativo': 0});
      
      return {'success': true, 'type': 'soft_delete', 'message': 'Subcategoria desativada'};
    } else {
      // HARD DELETE: Remove fisicamente
      await _database!.delete(
        'subcategorias',
        where: 'id = ? AND categoria_id = ? AND usuario_id = ?',
        whereArgs: [subcategoriaId, categoriaId, _currentUserId],
      );
      
      // Adiciona à fila de sync
      await addToSyncQueue('subcategorias', subcategoriaId, 'DELETE', {});
      
      return {'success': true, 'type': 'hard_delete', 'message': 'Subcategoria removida'};
    }
  }

  /// 🏦 MÉTODOS ESPECÍFICOS PARA CONTAS
  
  /// Busca contas localmente (offline-first) 
  Future<List<Map<String, dynamic>>> fetchContasLocal({bool incluirArquivadas = false}) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      debugPrint('❌ fetchContasLocal: Database não inicializado');
      return [];
    }
    
    debugPrint('🏦 Buscando contas para user: $_currentUserId, incluirArquivadas: $incluirArquivadas');
    
    String whereClause = 'usuario_id = ?';
    List<dynamic> whereArgs = [_currentUserId];
    
    if (!incluirArquivadas) {
      whereClause += ' AND ativo = 1';
    }
    
    // Debug: Contar total de contas primeiro
    final debugCount = await _database!.rawQuery('''
      SELECT COUNT(*) as total,
             SUM(CASE WHEN ativo = 1 THEN 1 ELSE 0 END) as ativas,
             SUM(CASE WHEN ativo = 0 THEN 1 ELSE 0 END) as inativas
      FROM contas 
      WHERE usuario_id = ?
    ''', [_currentUserId]);
    
    debugPrint('📊 Debug contas - Total: ${debugCount.first['total']}, Ativas: ${debugCount.first['ativas']}, Inativas: ${debugCount.first['inativas']}');
    
    // Busca contas com cálculo de saldo atual
    final contas = await _database!.query(
      'contas',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'ordem, nome',
    );
    
    debugPrint('✅ Query contas retornou: ${contas.length} itens');
    
    // Para cada conta, usa saldo que já vem sincronizado do Supabase
    final List<Map<String, dynamic>> contasComSaldo = [];
    
    for (final conta in contas) {
      final contaId = conta['id'] as String;
      final saldoInicial = (conta['saldo_inicial'] as num?)?.toDouble() ?? 0.0;
      
      // ✅ SEMPRE usa saldo do Supabase (fonte da verdade)
      final saldoAtual = (conta['saldo'] as num?)?.toDouble() ?? saldoInicial;
      debugPrint('📊 Saldo para $contaId: R\$ ${saldoAtual.toStringAsFixed(2)}');
      
      final contaComSaldo = Map<String, dynamic>.from(conta);
      contaComSaldo['saldo'] = saldoAtual; // Saldo do Supabase ou calculado
      contaComSaldo['saldo_atual'] = saldoAtual; // Alias para compatibilidade
      
      contasComSaldo.add(contaComSaldo);
    }
    
    return contasComSaldo;
  }
  
  /// Calcula saldo atual de uma conta específica
  Future<double> calcularSaldoContaLocal(String contaId, double saldoInicial) async {
    if (!_initialized || _database == null || _currentUserId == null) return saldoInicial;
    
    try {
      // Soma receitas
      final receitasResult = await _database!.rawQuery('''
        SELECT COALESCE(SUM(valor), 0) as total
        FROM transacoes
        WHERE conta_id = ? AND usuario_id = ? AND tipo = 'receita' AND efetivado = 1
      ''', [contaId, _currentUserId]);
      final totalReceitas = (receitasResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      // Soma despesas (sem cartão)
      final despesasResult = await _database!.rawQuery('''
        SELECT COALESCE(SUM(valor), 0) as total
        FROM transacoes
        WHERE conta_id = ? AND usuario_id = ? AND tipo = 'despesa' AND efetivado = 1
      ''', [contaId, _currentUserId]);
      final totalDespesas = (despesasResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      // Transferências recebidas
      final transfRecebidasResult = await _database!.rawQuery('''
        SELECT COALESCE(SUM(valor), 0) as total
        FROM transacoes
        WHERE conta_destino_id = ? AND usuario_id = ? AND tipo = 'transferencia' AND efetivado = 1
      ''', [contaId, _currentUserId]);
      final totalTransfRecebidas = (transfRecebidasResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      // Transferências enviadas
      final transfEnviadasResult = await _database!.rawQuery('''
        SELECT COALESCE(SUM(valor), 0) as total
        FROM transacoes
        WHERE conta_id = ? AND usuario_id = ? AND tipo = 'transferencia' AND efetivado = 1
      ''', [contaId, _currentUserId]);
      final totalTransfEnviadas = (transfEnviadasResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      // Fórmula exata do React
      final somaTransacoes = totalReceitas - totalDespesas + totalTransfRecebidas - totalTransfEnviadas;
      return saldoInicial + somaTransacoes;
    } catch (e) {
      debugPrint('❌ Erro ao calcular saldo da conta $contaId: $e');
      return saldoInicial; // Fallback para saldo inicial
    }
  }
  
  /// Adiciona conta localmente
  Future<String> addContaLocal(Map<String, dynamic> contaData) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }
    
    contaData['sync_status'] = 'pending';
    contaData['last_sync'] = null;
    
    await _database!.insert('contas', contaData);
    
    // Adiciona à fila de sync
    await addToSyncQueue(
      'contas',
      contaData['id'],
      'INSERT',
      contaData,
    );
    
    return contaData['id'];
  }
  
  /// Atualiza conta localmente
  Future<void> updateContaLocal(String contaId, Map<String, dynamic> updateData) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }
    
    // Adiciona metadados de sync
    updateData['updated_at'] = DateTime.now().toIso8601String();
    updateData['sync_status'] = 'pending';
    
    await _database!.update(
      'contas',
      updateData,
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [contaId, _currentUserId],
    );
    
    // Adiciona à fila de sync
    await addToSyncQueue(
      'contas',
      contaId,
      'UPDATE',
      updateData,
    );
  }
  
  /// Arquivar conta localmente
  Future<void> arquivarContaLocal(String contaId, String? motivo) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }
    
    final now = DateTime.now().toIso8601String().split('T')[0]; // Só a data
    final motivoTexto = motivo ?? 'Sem motivo especificado';
    
    // Busca observações atuais
    final contaAtual = await _database!.query(
      'contas',
      columns: ['observacoes'],
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [contaId, _currentUserId],
    );
    
    String observacoesAtuais = '';
    if (contaAtual.isNotEmpty) {
      observacoesAtuais = contaAtual.first['observacoes'] as String? ?? '';
    }
    
    final novasObservacoes = '$observacoesAtuais\n[Arquivada: $now] $motivoTexto'.trim();
    
    final updateData = {
      'ativo': 0, // SQLite usa INTEGER para boolean
      'observacoes': novasObservacoes,
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
    };
    
    await _database!.update(
      'contas',
      updateData,
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [contaId, _currentUserId],
    );
    
    // Adiciona à fila de sync
    await addToSyncQueue('contas', contaId, 'ARCHIVE', updateData);
  }
  
  /// Desarquivar conta localmente
  Future<void> desarquivarContaLocal(String contaId) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }
    
    final updateData = {
      'ativo': 1, // SQLite usa INTEGER para boolean
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
    };
    
    await _database!.update(
      'contas',
      updateData,
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [contaId, _currentUserId],
    );
    
    // Adiciona à fila de sync
    await addToSyncQueue('contas', contaId, 'UNARCHIVE', updateData);
  }
  
  /// Verifica se conta tem transações (para exclusão)
  Future<int> contaTemTransacoes(String contaId) async {
    if (!_initialized || _database == null || _currentUserId == null) return 0;
    
    final result = await _database!.rawQuery('''
      SELECT COUNT(*) as total
      FROM transacoes
      WHERE (conta_id = ? OR conta_destino_id = ?) AND usuario_id = ?
    ''', [contaId, contaId, _currentUserId]);
    
    return (result.first['total'] as int?) ?? 0;
  }
  
  /// Exclui conta localmente
  Future<Map<String, dynamic>> excluirContaLocal(String contaId, {bool confirmacao = false}) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }
    
    // Verifica se tem transações
    final totalTransacoes = await contaTemTransacoes(contaId);
    
    if (totalTransacoes > 0 && !confirmacao) {
      return {
        'success': false,
        'error': 'POSSUI_TRANSACOES',
        'message': 'Esta conta possui $totalTransacoes transação(ões).',
        'quantidadeTransacoes': totalTransacoes,
      };
    }
    
    // Exclui fisicamente
    await _database!.delete(
      'contas',
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [contaId, _currentUserId],
    );
    
    // Adiciona à fila de sync
    await addToSyncQueue('contas', contaId, 'DELETE', {});
    
    return {'success': true, 'message': 'Conta excluída'};
  }
  
  /// Calcula saldo total das contas ativas
  Future<double> calcularSaldoTotalLocal() async {
    if (!_initialized || _database == null || _currentUserId == null) return 0.0;
    
    try {
      final contas = await fetchContasLocal(incluirArquivadas: false);
      
      double saldoTotal = 0.0;
      for (final conta in contas) {
        final incluirNasoma = (conta['incluir_soma_total'] as int?) == 1;
        if (incluirNasoma) {
          final saldo = (conta['saldo'] as num?)?.toDouble() ?? 0.0;
          saldoTotal += saldo;
        }
      }
      
      return saldoTotal;
    } catch (e) {
      debugPrint('❌ Erro ao calcular saldo total: $e');
      return 0.0;
    }
  }
  
  /// Corrige saldo de conta com dois métodos: ajuste ou saldo_inicial
  Future<Map<String, dynamic>> corrigirSaldoContaLocal(
    String contaId,
    double saldoDesejado,
    String metodo,
    String motivo,
  ) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }
    
    try {
      if (metodo == 'ajuste') {
        return await _corrigirPorAjuste(contaId, saldoDesejado, motivo);
      } else if (metodo == 'saldo_inicial') {
        return await _corrigirPorSaldoInicial(contaId, saldoDesejado, motivo);
      } else {
        return {
          'success': false,
          'error': 'Método inválido. Use "ajuste" ou "saldo_inicial"',
        };
      }
    } catch (e) {
      debugPrint('❌ Erro ao corrigir saldo da conta: $e');
      return {
        'success': false,
        'error': 'Erro interno: $e',
      };
    }
  }
  
  /// Método 1: Correção por ajuste (cria transação de correção)
  Future<Map<String, dynamic>> _corrigirPorAjuste(String contaId, double saldoDesejado, String motivo) async {
    // Busca conta atual
    final contas = await _database!.query(
      'contas',
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [contaId, _currentUserId],
    );
    
    if (contas.isEmpty) {
      return {'success': false, 'error': 'Conta não encontrada'};
    }
    
    final conta = contas.first;
    final saldoInicial = (conta['saldo_inicial'] as num?)?.toDouble() ?? 0.0;
    final saldoAtual = await calcularSaldoContaLocal(contaId, saldoInicial);
    
    final diferenca = saldoDesejado - saldoAtual;
    
    if (diferenca == 0) {
      return {
        'success': true,
        'message': 'Saldo já está correto',
        'diferenca': 0.0,
      };
    }
    
    // Cria transação de correção
    final now = DateTime.now();
    final transacaoId = const Uuid().v4();
    
    final transacaoData = {
      'id': transacaoId,
      'usuario_id': _currentUserId,
      'conta_id': contaId,
      'data': now.toIso8601String().split('T')[0], // Só a data
      'descricao': 'Ajuste de saldo manual',
      'tipo': diferenca > 0 ? 'receita' : 'despesa',
      'valor': diferenca.abs(), // Valor sempre positivo
      'efetivado': true, // ✅ CORRIGIDO: boolean como no React
      'ajuste_manual': 1,
      'motivo_ajuste': motivo,
      'observacoes': motivo,
      'categoria_id': null,
      'subcategoria_id': null,
      'cartao_id': null,
      'recorrente': 0,
      'transferencia': 0,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'sync_status': 'pending',
    };
    
    await _database!.insert('transacoes', transacaoData);
    
    // Adiciona à fila de sync
    await addToSyncQueue('transacoes', transacaoId, 'INSERT', transacaoData);
    
    return {
      'success': true,
      'message': 'Saldo corrigido com transação de ajuste',
      'diferenca': diferenca,
      'saldoAnterior': saldoAtual,
      'saldoNovo': saldoDesejado,
      'metodo': 'ajuste',
    };
  }
  
  /// Método 2: Correção por saldo inicial (recalcula usando fórmula SQL)
  Future<Map<String, dynamic>> _corrigirPorSaldoInicial(String contaId, double saldoDesejado, String motivo) async {
    // Busca soma de todas as transações (fórmula exata do React)
    
    // 1. Soma receitas
    final receitasResult = await _database!.rawQuery('''
      SELECT COALESCE(SUM(valor), 0) as total
      FROM transacoes
      WHERE conta_id = ? AND usuario_id = ? AND tipo = 'receita' AND efetivado = 1
    ''', [contaId, _currentUserId]);
    final totalReceitas = (receitasResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    // 2. Soma despesas
    final despesasResult = await _database!.rawQuery('''
      SELECT COALESCE(SUM(valor), 0) as total
      FROM transacoes
      WHERE conta_id = ? AND usuario_id = ? AND tipo = 'despesa' AND efetivado = 1
    ''', [contaId, _currentUserId]);
    final totalDespesas = (despesasResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    // 3. Transferências recebidas
    final transfRecebidasResult = await _database!.rawQuery('''
      SELECT COALESCE(SUM(valor), 0) as total
      FROM transacoes
      WHERE conta_destino_id = ? AND usuario_id = ? AND tipo = 'transferencia' AND efetivado = 1
    ''', [contaId, _currentUserId]);
    final totalTransfRecebidas = (transfRecebidasResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    // 4. Transferências enviadas
    final transfEnviadasResult = await _database!.rawQuery('''
      SELECT COALESCE(SUM(valor), 0) as total
      FROM transacoes
      WHERE conta_id = ? AND usuario_id = ? AND tipo = 'transferencia' AND efetivado = 1
    ''', [contaId, _currentUserId]);
    final totalTransfEnviadas = (transfEnviadasResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    // 5. Fórmula exata: somaTransacoes = totalReceitas - totalDespesas + totalTransfRecebidas - totalTransfEnviadas
    final somaTransacoes = totalReceitas - totalDespesas + totalTransfRecebidas - totalTransfEnviadas;
    
    // 6. Calcula novo saldo inicial: novoSaldoInicial = saldoDesejado - somaTransacoes
    final novoSaldoInicial = saldoDesejado - somaTransacoes;
    
    // Atualiza saldo inicial na conta
    final updateData = {
      'saldo_inicial': novoSaldoInicial,
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
    };
    
    await _database!.update(
      'contas',
      updateData,
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [contaId, _currentUserId],
    );
    
    // Adiciona à fila de sync
    await addToSyncQueue('contas', contaId, 'SALDO_CORRECTION', updateData);
    
    return {
      'success': true,
      'message': 'Saldo inicial recalculado',
      'saldoInicialAnterior': 'N/A',
      'saldoInicialNovo': novoSaldoInicial,
      'saldoDesejado': saldoDesejado,
      'somaTransacoes': somaTransacoes,
      'metodo': 'saldo_inicial',
    };
  }

  /// 💳 MÉTODOS ESPECÍFICOS PARA TRANSAÇÕES

  /// Adiciona transação localmente
  Future<String> addTransacaoLocal(Map<String, dynamic> transacaoData) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }
    
    debugPrint('💳 Salvando transação offline: ${transacaoData['descricao']}');
    debugPrint('📝 Grupo parcelamento: ${transacaoData['grupo_parcelamento']}');
    debugPrint('📝 Parcela: ${transacaoData['parcela_atual']}/${transacaoData['total_parcelas']}');
    
    transacaoData['sync_status'] = 'pending';
    transacaoData['last_sync'] = null;
    
    await _database!.insert('transacoes', transacaoData, conflictAlgorithm: ConflictAlgorithm.replace);
    
    // Adiciona à fila de sync
    await addToSyncQueue(
      'transacoes',
      transacaoData['id'],
      'INSERT',
      transacaoData,
    );
    
    debugPrint('✅ Transação salva no SQLite: ${transacaoData['id']}');
    return transacaoData['id'];
  }

  /// Busca transações por grupo de parcelamento
  Future<List<Map<String, dynamic>>> getTransacoesByGrupoParcelamento(String grupoId) async {
    if (!_initialized || _database == null || _currentUserId == null) return [];
    
    debugPrint('🔍 Buscando transações do grupo parcelamento: $grupoId');
    
    final result = await _database!.query(
      'transacoes',
      where: 'grupo_parcelamento = ? AND usuario_id = ?',
      whereArgs: [grupoId, _currentUserId],
      orderBy: 'parcela_atual ASC',
    );
    
    debugPrint('✅ Encontradas ${result.length} parcelas no grupo');
    return result;
  }

  /// Atualiza transação localmente
  Future<void> updateTransacaoLocal(String transacaoId, Map<String, dynamic> updateData, {bool skipAutoSync = false}) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }
    
    updateData['updated_at'] = DateTime.now().toIso8601String();
    updateData['sync_status'] = 'pending';
    
    await _database!.update(
      'transacoes',
      updateData,
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [transacaoId, _currentUserId],
    );
    
    // Adiciona à fila de sync
    await addToSyncQueue(
      'transacoes',
      transacaoId,
      'UPDATE',
      updateData,
      skipAutoSync: skipAutoSync,
    );
    
    debugPrint('✅ Transação atualizada: $transacaoId');
  }

  /// Atualiza grupo de parcelas (igual ao React updateGrupoValor)
  Future<void> updateGrupoParcelamentoLocal(String grupoId, double novoValor, String escopo) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }
    
    debugPrint('🔄 Atualizando grupo parcelamento: $grupoId, escopo: $escopo');
    
    String whereClause = 'grupo_parcelamento = ? AND usuario_id = ?';
    List<dynamic> whereArgs = [grupoId, _currentUserId];
    
    if (escopo == 'futuras') {
      // Só parcelas futuras não efetivadas
      whereClause += ' AND efetivado = 0 AND data >= ?';
      whereArgs.add(DateTime.now().toIso8601String().split('T')[0]);
    }
    
    final updateData = {
      'valor': novoValor,
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
    };
    
    final result = await _database!.update(
      'transacoes',
      updateData,
      where: whereClause,
      whereArgs: whereArgs,
    );
    
    debugPrint('✅ Grupo parcelamento atualizado: $result transações afetadas');
  }

  /// 💰 BUSCAR VALORES POR CATEGORIA (OFFLINE-FIRST)
  Future<Map<String, double>> fetchValoresPorCategoria({
    required String userId,
    required DateTime dataInicio,
    required DateTime dataFim,
    String? tipo,
  }) async {
    await _ensureInitialized();
    
    final whereClause = StringBuffer();
    final whereArgs = <dynamic>[];
    
    whereClause.write('usuario_id = ? AND efetivado = 1');
    whereArgs.addAll([userId]);
    
    whereClause.write(' AND data >= ? AND data <= ?');
    whereArgs.addAll([
      dataInicio.toIso8601String().split('T')[0],
      dataFim.toIso8601String().split('T')[0],
    ]);
    
    if (tipo != null) {
      whereClause.write(' AND tipo = ?');
      whereArgs.add(tipo);
    }
    
    final result = await _database!.rawQuery('''
      SELECT 
        categoria_id,
        COALESCE(SUM(valor), 0) as total_valor
      FROM transacoes 
      WHERE $whereClause
      GROUP BY categoria_id
      ORDER BY total_valor DESC
    ''', whereArgs);
    
    // 🔍 DEBUG: Log da query e resultados
    debugPrint('🔍 DEBUG fetchValoresPorCategoria:');
    debugPrint('  📋 Query WHERE: $whereClause');
    debugPrint('  📋 Args: $whereArgs');
    debugPrint('  📋 Resultados encontrados: ${result.length}');
    
    final Map<String, double> valoresPorCategoria = {};
    
    for (final row in result) {
      final categoriaId = row['categoria_id'] as String?;
      final totalValor = (row['total_valor'] as num?)?.toDouble() ?? 0.0;
      
      debugPrint('  📊 Categoria: $categoriaId, Valor: R\$${totalValor.toStringAsFixed(2)}');
      
      if (categoriaId != null) {
        valoresPorCategoria[categoriaId] = totalValor;
      }
    }
    
    debugPrint('🔍 DEBUG: Mapa final com ${valoresPorCategoria.length} categorias');
    
    return valoresPorCategoria;
  }

  /// 📊 BUSCAR TOTAIS POR TIPO (OFFLINE-FIRST)
  Future<Map<String, double>> fetchTotaisPorTipo({
    required String userId,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    await _ensureInitialized();
    
    final result = await _database!.rawQuery('''
      SELECT 
        tipo,
        COALESCE(SUM(valor), 0) as total_valor
      FROM transacoes 
      WHERE usuario_id = ? AND efetivado = 1
      AND data >= ? AND data <= ?
      GROUP BY tipo
    ''', [
      userId,
      dataInicio.toIso8601String().split('T')[0],
      dataFim.toIso8601String().split('T')[0],
    ]);
    
    final Map<String, double> totais = {'receita': 0.0, 'despesa': 0.0};
    
    for (final row in result) {
      final tipo = row['tipo'] as String?;
      final totalValor = (row['total_valor'] as num?)?.toDouble() ?? 0.0;
      
      if (tipo != null) {
        totais[tipo] = totalValor;
      }
    }
    
    return totais;
  }

  /// Exclui transação localmente
  Future<void> deleteTransacaoLocal(String transacaoId) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }

    debugPrint('🗑️ Excluindo transação offline: $transacaoId');

    await _database!.delete(
      'transacoes',
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [transacaoId, _currentUserId],
    );

    // Adiciona à fila de sync para exclusão no Supabase
    await addToSyncQueue(
      'transacoes',
      transacaoId,
      'DELETE',
      {'id': transacaoId}, // Dados mínimos para identificação
    );
  }

  /// 📊 MÉTODOS ESPECÍFICOS PARA PLANEJAMENTOS

  /// Busca planejamentos localmente (offline-first)
  Future<List<Map<String, dynamic>>> fetchPlanejamentosLocal({
    required int ano,
    int? mes, // Agora opcional - null para ano inteiro
    String? tipo,
  }) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      debugPrint('❌ fetchPlanejamentosLocal: Database não inicializado');
      return [];
    }

    debugPrint('📊 Buscando planejamentos para user: $_currentUserId, ano: $ano, mes: $mes, tipo: $tipo');

    String whereClause = 'usuario_id = ? AND ano = ?';
    List<dynamic> whereArgs = [_currentUserId, ano];

    // Adicionar filtro de mês se especificado
    if (mes != null) {
      whereClause += ' AND mes = ?';
      whereArgs.add(mes);
    }

    if (tipo != null) {
      whereClause += ' AND tipo = ?';
      whereArgs.add(tipo);
    }

    final planejamentos = await _database!.query(
      'planejamentos',
      where: whereClause,
      whereArgs: whereArgs,
    );

    debugPrint('✅ Query planejamentos retornou: ${planejamentos.length} itens');
    return planejamentos;
  }

  /// Salva planejamento localmente (offline-first)
  Future<void> savePlanejamentoLocal(Map<String, dynamic> planejamento) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }

    debugPrint('💾 Salvando planejamento offline: ${planejamento['id']}');

    // Prepara dados para SQLite
    final planejamentoData = Map<String, dynamic>.from(planejamento);
    planejamentoData['sync_status'] = 'pending';
    planejamentoData['last_sync'] = DateTime.now().toIso8601String();

    // 🚀 CORREÇÃO: Garantir que created_at e updated_at tenham valores válidos
    final now = DateTime.now().toIso8601String();
    if (planejamentoData['created_at'] == null) {
      planejamentoData['created_at'] = now;
    }
    if (planejamentoData['updated_at'] == null) {
      planejamentoData['updated_at'] = now;
    }

    await _database!.insert(
      'planejamentos',
      planejamentoData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Adiciona à fila de sync
    await addToSyncQueue(
      'planejamentos',
      planejamento['id'],
      'UPSERT',
      planejamento,
    );
  }

  /// Exclui planejamento localmente (offline-first)
  Future<void> excluirPlanejamentoLocal(String planejamentoId) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      throw Exception('Database não inicializado');
    }

    debugPrint('🗑️ Excluindo planejamento offline: $planejamentoId');

    // Remove do SQLite
    await _database!.delete(
      'planejamentos',
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [planejamentoId, _currentUserId],
    );

    // Adiciona à fila de sync para exclusão no Supabase
    await addToSyncQueue(
      'planejamentos',
      planejamentoId,
      'DELETE',
      {'id': planejamentoId},
    );
  }

  /// Busca valores realizados e previstos por categoria para planejamento
  Future<Map<String, Map<String, double>>> fetchValoresPlanejamento({
    required int ano,
    required int mes,
    String? tipo,
  }) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      return {};
    }

    final dataInicio = DateTime(ano, mes, 1);
    final dataFim = DateTime(ano, mes + 1, 0);

    String whereClause = 'usuario_id = ? AND data >= ? AND data <= ?';
    List<dynamic> whereArgs = [
      _currentUserId,
      dataInicio.toIso8601String().split('T')[0],
      dataFim.toIso8601String().split('T')[0],
    ];

    if (tipo != null) {
      whereClause += ' AND tipo = ?';
      whereArgs.add(tipo);
    }

    // Busca transações realizadas e previstas
    final result = await _database!.rawQuery('''
      SELECT
        categoria_id,
        subcategoria_id,
        COALESCE(SUM(CASE WHEN efetivado = 1 THEN valor ELSE 0 END), 0) as valor_realizado,
        COALESCE(SUM(CASE WHEN efetivado = 0 THEN valor ELSE 0 END), 0) as valor_previsto,
        COUNT(CASE WHEN efetivado = 1 THEN 1 END) as transacoes_realizadas,
        COUNT(CASE WHEN efetivado = 0 THEN 1 END) as transacoes_previstas
      FROM transacoes
      WHERE $whereClause
      GROUP BY categoria_id, subcategoria_id
    ''', whereArgs);

    final Map<String, Map<String, double>> valores = {};

    for (final row in result) {
      final categoriaId = row['categoria_id'] as String?;
      final subcategoriaId = row['subcategoria_id'] as String?;
      final valorRealizado = (row['valor_realizado'] as num?)?.toDouble() ?? 0.0;
      final valorPrevisto = (row['valor_previsto'] as num?)?.toDouble() ?? 0.0;
      final transacoesRealizadas = (row['transacoes_realizadas'] as int?) ?? 0;
      final transacoesPrevistas = (row['transacoes_previstas'] as int?) ?? 0;

      if (categoriaId != null) {
        final chave = subcategoriaId != null ? '$categoriaId|$subcategoriaId' : categoriaId;
        valores[chave] = {
          'valor_realizado': valorRealizado,
          'valor_previsto': valorPrevisto,
          'transacoes_realizadas': transacoesRealizadas.toDouble(),
          'transacoes_previstas': transacoesPrevistas.toDouble(),
        };
      }
    }

    return valores;
  }

  /// Busca média histórica de uma categoria (últimos 3 meses)
  Future<double> fetchMediaHistoricaCategoria({
    required String categoriaId,
    String? subcategoriaId,
    required int anoAtual,
    required int mesAtual,
    String? tipo,
  }) async {
    if (!_initialized || _database == null || _currentUserId == null) {
      return 0.0;
    }

    // Calcula os últimos 3 meses
    final meses = <String>[];
    for (int i = 1; i <= 3; i++) {
      final data = DateTime(anoAtual, mesAtual - i);
      final dataInicio = DateTime(data.year, data.month, 1);
      final dataFim = DateTime(data.year, data.month + 1, 0);
      meses.add('("${dataInicio.toIso8601String().split('T')[0]}", "${dataFim.toIso8601String().split('T')[0]}")');
    }

    String whereClause = 'usuario_id = ? AND categoria_id = ? AND efetivado = 1';
    List<dynamic> whereArgs = [_currentUserId, categoriaId];

    if (subcategoriaId != null) {
      whereClause += ' AND subcategoria_id = ?';
      whereArgs.add(subcategoriaId);
    }

    if (tipo != null) {
      whereClause += ' AND tipo = ?';
      whereArgs.add(tipo);
    }

    final result = await _database!.rawQuery('''
      SELECT COALESCE(AVG(total_mes), 0) as media
      FROM (
        SELECT
          strftime('%Y-%m', data) as mes_ano,
          SUM(valor) as total_mes
        FROM transacoes
        WHERE $whereClause
        AND data >= date('now', '-3 months', 'start of month')
        AND data < date('now', 'start of month')
        GROUP BY mes_ano
      )
    ''', whereArgs);

    return (result.first['media'] as num?)?.toDouble() ?? 0.0;
  }

  // =============================================================================
  // ⚡ RECÁLCULO AUTOMÁTICO DE SALDOS E LIMITES (PERFORMANCE OTIMIZADA)
  // =============================================================================

  /// ⚡ Recalcula saldo de uma conta baseado em transações efetivadas
  ///
  /// Atualiza o campo `saldo` da conta somando:
  /// - saldo_inicial + receitas efetivadas - despesas efetivadas + transferências
  ///
  /// Performance: ~2-5ms (query SQL única otimizada)
  /// Não-bloqueante: Pode ser chamado com unawaited() para execução paralela
  ///
  /// Exemplo de uso:
  /// ```dart
  /// await LocalDatabase.instance.recalcularSaldoConta(contaId); // Bloqueante
  /// unawaited(LocalDatabase.instance.recalcularSaldoConta(contaId)); // Paralelo
  /// ```
  Future<void> recalcularSaldoConta(String contaId) async {
    if (_database == null || _currentUserId == null) {
      debugPrint('⚠️ Recálculo saldo: Database não inicializado');
      return;
    }

    try {
      // 📊 DEBUG: Buscar saldo ANTES do recálculo
      final contaAntes = await _database!.query('contas', where: 'id = ?', whereArgs: [contaId]);
      final saldoAntes = contaAntes.isNotEmpty ? (contaAntes.first['saldo'] as num?)?.toDouble() : null;
      final saldoInicial = contaAntes.isNotEmpty ? (contaAntes.first['saldo_inicial'] as num?)?.toDouble() : 0.0;
      debugPrint('💰 ANTES recalcular: Conta $contaId - Saldo: R\$ $saldoAntes, Saldo Inicial: R\$ $saldoInicial');

      // 📊 DEBUG: Componentes do cálculo
      final receitas = await _database!.rawQuery('''
        SELECT COALESCE(SUM(valor), 0) as total FROM transacoes
        WHERE conta_id = ? AND tipo = 'receita' AND efetivado = 1 AND usuario_id = ?
      ''', [contaId, _currentUserId]);
      final totalReceitas = (receitas.first['total'] as num?)?.toDouble() ?? 0.0;

      final despesas = await _database!.rawQuery('''
        SELECT COALESCE(SUM(valor), 0) as total FROM transacoes
        WHERE conta_id = ? AND tipo = 'despesa' AND efetivado = 1 AND cartao_id IS NULL AND usuario_id = ?
      ''', [contaId, _currentUserId]);
      final totalDespesas = (despesas.first['total'] as num?)?.toDouble() ?? 0.0;

      final transfRecebidas = await _database!.rawQuery('''
        SELECT COALESCE(SUM(valor), 0) as total FROM transacoes
        WHERE conta_destino_id = ? AND tipo = 'transferencia' AND efetivado = 1 AND usuario_id = ?
      ''', [contaId, _currentUserId]);
      final totalTransfRecebidas = (transfRecebidas.first['total'] as num?)?.toDouble() ?? 0.0;

      final transfEnviadas = await _database!.rawQuery('''
        SELECT COALESCE(SUM(valor), 0) as total FROM transacoes
        WHERE conta_id = ? AND tipo = 'transferencia' AND efetivado = 1 AND usuario_id = ?
      ''', [contaId, _currentUserId]);
      final totalTransfEnviadas = (transfEnviadas.first['total'] as num?)?.toDouble() ?? 0.0;

      final saldoCalculado = (saldoInicial ?? 0.0) + totalReceitas - totalDespesas + totalTransfRecebidas - totalTransfEnviadas;

      debugPrint('📊 COMPONENTES:');
      debugPrint('  + Saldo Inicial: R\$ ${saldoInicial?.toStringAsFixed(2)}');
      debugPrint('  + Receitas: R\$ ${totalReceitas.toStringAsFixed(2)}');
      debugPrint('  - Despesas: R\$ ${totalDespesas.toStringAsFixed(2)}');
      debugPrint('  + Transf Recebidas: R\$ ${totalTransfRecebidas.toStringAsFixed(2)}');
      debugPrint('  - Transf Enviadas: R\$ ${totalTransfEnviadas.toStringAsFixed(2)}');
      debugPrint('  = SALDO CALCULADO: R\$ ${saldoCalculado.toStringAsFixed(2)}');

      // ✅ Query única otimizada - recalcula saldo baseado na fórmula:
      // saldo = saldo_inicial + receitas - despesas + transf_recebidas - transf_enviadas
      await _database!.rawQuery('''
        UPDATE contas
        SET saldo = (
          saldo_inicial +
          COALESCE((
            SELECT SUM(valor)
            FROM transacoes
            WHERE conta_id = ?
              AND tipo = 'receita'
              AND efetivado = 1
              AND usuario_id = ?
          ), 0) -
          COALESCE((
            SELECT SUM(valor)
            FROM transacoes
            WHERE conta_id = ?
              AND tipo = 'despesa'
              AND efetivado = 1
              AND cartao_id IS NULL
              AND usuario_id = ?
          ), 0) +
          COALESCE((
            SELECT SUM(valor)
            FROM transacoes
            WHERE conta_destino_id = ?
              AND tipo = 'transferencia'
              AND efetivado = 1
              AND usuario_id = ?
          ), 0) -
          COALESCE((
            SELECT SUM(valor)
            FROM transacoes
            WHERE conta_id = ?
              AND tipo = 'transferencia'
              AND efetivado = 1
              AND usuario_id = ?
          ), 0)
        ),
        updated_at = ?
        WHERE id = ? AND usuario_id = ?
      ''', [
        contaId, _currentUserId, // receitas
        contaId, _currentUserId, // despesas
        contaId, _currentUserId, // transferências recebidas
        contaId, _currentUserId, // transferências enviadas
        DateTime.now().toIso8601String(),
        contaId,
        _currentUserId,
      ]);

      // 📊 DEBUG: Buscar saldo DEPOIS do recálculo
      final contaDepois = await _database!.query('contas', where: 'id = ?', whereArgs: [contaId]);
      final saldoDepois = contaDepois.isNotEmpty ? (contaDepois.first['saldo'] as num?)?.toDouble() : null;
      debugPrint('💰 DEPOIS recalcular: Conta $contaId - Saldo: R\$ $saldoDepois');

      if (saldoAntes != saldoDepois) {
        debugPrint('🔄 MUDANÇA DE SALDO: R\$ $saldoAntes → R\$ $saldoDepois (Δ ${(saldoDepois! - saldoAntes!).toStringAsFixed(2)})');
      }

      debugPrint('⚡ Saldo recalculado para conta $contaId');
    } catch (e) {
      debugPrint('❌ Erro ao recalcular saldo da conta: $e');
    }
  }

  /// ⚡ Aplica delta de mudança no saldo (MÉTODO CORRETO PARA OFFLINE)
  ///
  /// ⚠️ IMPORTANTE: Use este método ao invés de recalcularSaldoConta() offline!
  ///
  /// PROBLEMA com recalcularSaldoConta() offline:
  /// - SQLite não tem TODAS as transações (sync só baixa últimos 12-14 meses)
  /// - recalcularSaldoConta faz: saldo_inicial + sum(transações no SQLite)
  /// - MAS FALTA transações antigas (2021-2022) que não estão no SQLite!
  /// - Resultado: saldo INCORRETO (faltando R$6000+)
  ///
  /// SOLUÇÃO: Aplicar apenas o DELTA da mudança
  /// - Efetivar R$2000: aplicarDeltaSaldo(contaId, +2000)
  /// - Desefetivar R$500: aplicarDeltaSaldo(contaId, -500)
  ///
  /// Quando voltar online, sync sobrescreverá com saldo correto do Supabase.
  ///
  /// Performance: ~5ms (apenas UPDATE, sem SUM)
  Future<void> aplicarDeltaSaldo(String contaId, double delta) async {
    if (_database == null || _currentUserId == null) {
      debugPrint('⚠️ Aplicar delta: Database não inicializado');
      return;
    }

    try {
      final contaAntes = await _database!.query('contas', where: 'id = ?', whereArgs: [contaId]);
      final saldoAntes = contaAntes.isNotEmpty ? (contaAntes.first['saldo'] as num?)?.toDouble() : 0.0;

      debugPrint('💰 Aplicando delta: Conta $contaId - Saldo Antes: R\$ ${saldoAntes?.toStringAsFixed(2)}, Delta: R\$ ${delta.toStringAsFixed(2)}');

      await _database!.rawQuery('''
        UPDATE contas
        SET saldo = saldo + ?,
            updated_at = ?
        WHERE id = ? AND usuario_id = ?
      ''', [
        delta,
        DateTime.now().toIso8601String(),
        contaId,
        _currentUserId,
      ]);

      final contaDepois = await _database!.query('contas', where: 'id = ?', whereArgs: [contaId]);
      final saldoDepois = contaDepois.isNotEmpty ? (contaDepois.first['saldo'] as num?)?.toDouble() : null;
      debugPrint('💰 Delta aplicado: R\$ $saldoAntes → R\$ $saldoDepois (Δ ${delta.toStringAsFixed(2)})');

    } catch (e) {
      debugPrint('❌ Erro ao aplicar delta no saldo: $e');
    }
  }

  /// ⚡ Recalcula limite usado de um cartão baseado em despesas pendentes
  ///
  /// Cartões não guardam "limite_usado" em coluna própria.
  /// O limite usado é calculado dinamicamente somando transações não efetivadas.
  ///
  /// Este método não faz nada (placeholder para consistência da API).
  /// O cálculo real é feito em CartaoDataService.calcularLimiteUtilizado()
  ///
  /// Performance: ~0ms (no-op)
  Future<void> recalcularLimiteCartao(String cartaoId) async {
    // ℹ️ Cartões não têm campo "limite_usado" no banco
    // O cálculo é feito sob demanda em CartaoDataService
    // Este método existe apenas para manter consistência da API
    debugPrint('ℹ️ Recálculo de limite de cartão não necessário (calculado sob demanda)');
  }

  /// 🧹 DISPOSE
  Future<void> dispose() async {
    await _database?.close();
    _database = null;
    _initialized = false;
    debugPrint('🧹 Local Database disposed');
  }
}

/// 🎯 Singleton global para acesso fácil
final localDatabase = LocalDatabase.instance;