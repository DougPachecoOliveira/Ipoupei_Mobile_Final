// 📊 Planejamento Service - iPoupei Mobile
//
// Serviço para operações de planejamentos com Supabase
// Baseado na estrutura do CategoriaService
//
// Baseado em: Repository Pattern

import 'dart:developer';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../models/planejamento_model.dart';
import '../../categorias/models/categoria_model.dart';
import '../../../database/local_database.dart';
import '../../../sync/sync_manager.dart';
import '../../../sync/connectivity_helper.dart';
import 'package:uuid/uuid.dart';

class PlanejamentoService {
  static PlanejamentoService? _instance;
  static PlanejamentoService get instance {
    _instance ??= PlanejamentoService._internal();
    return _instance!;
  }

  PlanejamentoService._internal() {
    inicializar();
  }

  final _supabase = Supabase.instance.client;
  final _localDb = LocalDatabase.instance;
  final _uuid = const Uuid();

  // Estado interno
  final StreamController<List<PlanejamentoModel>> _planejamentosController =
      StreamController<List<PlanejamentoModel>>.broadcast();

  List<PlanejamentoModel> _planejamentosCache = [];
  DateTime _periodoAtual = DateTime.now();
  bool _carregando = false;

  // ===========================
  // GETTERS E STREAMS
  // ===========================

  Stream<List<PlanejamentoModel>> get planejamentosStream => _planejamentosController.stream;
  List<PlanejamentoModel> get planejamentos => List.unmodifiable(_planejamentosCache);
  DateTime get periodoAtual => _periodoAtual;
  bool get carregando => _carregando;

  // ===========================
  // INICIALIZAÇÃO
  // ===========================

  Future<void> inicializar() async {
    log('🔄 PlanejamentoService: Inicializando...');
    try {
      await carregarPlanejamentos();
      log('✅ PlanejamentoService: Inicializado com sucesso');
    } catch (e) {
      log('❌ PlanejamentoService: Erro na inicialização: $e');
    }
  }

  // ===========================
  // NAVEGAÇÃO DE PERÍODO
  // ===========================

  void setPeriodo(DateTime periodo) {
    _periodoAtual = periodo;
    carregarPlanejamentos();
  }

  void periodoAnterior() {
    _periodoAtual = DateTime(_periodoAtual.year, _periodoAtual.month - 1);
    carregarPlanejamentos();
  }

  void proximoPeriodo() {
    _periodoAtual = DateTime(_periodoAtual.year, _periodoAtual.month + 1);
    carregarPlanejamentos();
  }

  void periodoAtualHoje() {
    _periodoAtual = DateTime.now();
    carregarPlanejamentos();
  }

  void definirPeriodo(DateTime novaData) {
    _periodoAtual = novaData;
  }

  String formatarPeriodo() {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${meses[_periodoAtual.month - 1]} ${_periodoAtual.year}';
  }

  // ===========================
  // CARREGAR PLANEJAMENTOS (OFFLINE-FIRST)
  // ===========================

  Future<void> carregarPlanejamentos({String? tipo, bool modoAnual = false}) async {
    if (_carregando) return;

    _carregando = true;
    log('🔄 PlanejamentoService: Carregando planejamentos...');

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _planejamentosCache = [];
        _planejamentosController.add(_planejamentosCache);
        return;
      }

      log('📊 Carregando planejamentos IGUAL AO REACT para: ${_supabase.auth.currentUser?.email}');

      // 🚀 NOVA IMPLEMENTAÇÃO: IGUAL AO REACT
      if (await ConnectivityHelper.instance.isConnected()) {
        try {
          await _fetchDadosComparativosIgualReact(userId, tipo, modoAnual);
          return;
        } catch (onlineError) {
          log('❌ Erro na busca online, usando fallback local: $onlineError');
        }
      }

      // FALLBACK: Busca local se falhou ou sem conexão
      await _localDb.setCurrentUser(userId);
      final localData = await _localDb.fetchPlanejamentosLocal(
        ano: _periodoAtual.year,
        mes: modoAnual ? null : _periodoAtual.month,
        tipo: tipo,
      );

      // Se SQLite está vazio, faz sync inicial do Supabase
      if (localData.isEmpty) {
        log('🔄 SQLite vazio - fazendo sync inicial do Supabase...');
        try {
          await _syncInitialFromSupabase(userId);
          final localDataAfterSync = await _localDb.fetchPlanejamentosLocal(
            ano: _periodoAtual.year,
            mes: modoAnual ? null : _periodoAtual.month,
            tipo: tipo,
          );
          await _processarDadosComparativosPlanejamentos(localDataAfterSync);
        } catch (syncError) {
          log('⚠️ Sync inicial falhou: $syncError');
          await _processarDadosComparativosPlanejamentos(localData);
        }
      } else {
        await _processarDadosComparativosPlanejamentos(localData);
      }

    } catch (e) {
      log('❌ Erro ao carregar planejamentos: $e');
      _planejamentosCache = [];
      _planejamentosController.add(_planejamentosCache);
    } finally {
      _carregando = false;
    }
  }

  /// 🚀 BUSCAR DADOS IGUAL AO REACT (SEM RPC)
  Future<void> _fetchDadosComparativosIgualReact(String userId, String? tipo, bool modoAnual) async {
    log('🚀 Buscando dados igual ao React...');

    try {
      // 1. Buscar TODAS as categorias do usuário (igual ao React linha 55-60)
      final categorias = await _supabase
          .from('categorias')
          .select('id, nome, tipo, cor, icone, usuario_id')
          .eq('usuario_id', userId)
          .eq('ativo', true)
          .order('nome');

      log('📂 Categorias encontradas: ${categorias.length}');

      // 2. Buscar TODAS as subcategorias (igual ao React linha 64-70)
      final subcategorias = await _supabase
          .from('subcategorias')
          .select('id, nome, categoria_id, usuario_id')
          .eq('usuario_id', userId)
          .eq('ativo', true)
          .order('nome');

      log('📂 Subcategorias encontradas: ${subcategorias.length}');

      // 3. Buscar planejamentos do período (igual ao React linha 74-80)
      final planejamentosQuery = _supabase
          .from('planejamentos')
          .select('*')
          .eq('usuario_id', userId);

      if (!modoAnual) {
        planejamentosQuery
            .eq('ano', _periodoAtual.year)
            .eq('mes', _periodoAtual.month);
      } else {
        planejamentosQuery.eq('ano', _periodoAtual.year);
      }

      final planejamentos = await planejamentosQuery;
      log('📊 Planejamentos encontrados: ${planejamentos.length}');

      // 4. Buscar transações do período (igual ao React linha 84-93)
      final dataInicio = modoAnual
          ? '${_periodoAtual.year}-01-01'
          : '${_periodoAtual.year}-${_periodoAtual.month.toString().padLeft(2, '0')}-01';

      final dataFim = modoAnual
          ? '${_periodoAtual.year}-12-31'
          : DateTime(_periodoAtual.year, _periodoAtual.month + 1, 0).toIso8601String().split('T')[0];

      final transacoes = await _supabase
          .from('transacoes')
          .select('categoria_id, subcategoria_id, tipo, valor, efetivado')
          .eq('usuario_id', userId)
          .gte('data', dataInicio)
          .lte('data', dataFim);

      log('💳 Transações encontradas: ${transacoes.length}');

      // 5. Buscar transações históricas para média (igual ao React linha 97-107)
      final dataInicioHistorico = modoAnual
          ? DateTime(_periodoAtual.year - 1, _periodoAtual.month, 1).toIso8601String().split('T')[0]
          : DateTime(_periodoAtual.year, _periodoAtual.month - 3, 1).toIso8601String().split('T')[0];

      final dataFimHistorico = modoAnual
          ? DateTime(_periodoAtual.year, 1, 0).toIso8601String().split('T')[0]
          : DateTime(_periodoAtual.year, _periodoAtual.month, 0).toIso8601String().split('T')[0];

      final transacoesHistoricas = await _supabase
          .from('transacoes')
          .select('categoria_id, subcategoria_id, tipo, valor')
          .eq('usuario_id', userId)
          .eq('efetivado', true)
          .gte('data', dataInicioHistorico)
          .lte('data', dataFimHistorico);

      log('📈 Transações históricas encontradas: ${transacoesHistoricas.length}');

      // 6. Processar dados (igual ao React linha 112-118)
      final dadosProcessados = await _processarDadosComparativosIgualReact({
        'categorias': categorias,
        'subcategorias': subcategorias,
        'planejamentos': planejamentos,
        'transacoes': transacoes,
        'transacoesHistoricas': transacoesHistoricas,
      });

      _planejamentosCache = dadosProcessados;
      _planejamentosController.add(_planejamentosCache);

      log('✅ Dados processados igual ao React: ${dadosProcessados.length} itens');

    } catch (e) {
      log('❌ Erro ao buscar dados igual ao React: $e');
      rethrow;
    }
  }

  /// 🔄 CARREGAR COM RPC DO SUPABASE
  Future<List<Map<String, dynamic>>> _carregarComRpcSupabase(String userId) async {
    log('🚀 Carregando planejamentos via RPC planejamento_mensal_ipoupei_2025...');

    try {
      final response = await _supabase.rpc('planejamento_mensal_ipoupei_2025', params: {
        'p_usuario_id': userId,
        'p_ano': _periodoAtual.year,
        'p_mes': _periodoAtual.month,
      });

      if (response is List) {
        log('✅ RPC planejamento_mensal_ipoupei_2025 retornou ${response.length} registros');
        return response.cast<Map<String, dynamic>>();
      } else {
        log('⚠️ RPC retornou formato inesperado: $response');
        return [];
      }
    } catch (e) {
      log('❌ Erro ao chamar RPC planejamento_mensal_ipoupei_2025: $e');
      return [];
    }
  }

  /// 🔄 SYNC INICIAL DO SUPABASE PARA SQLITE
  Future<void> _syncInitialFromSupabase(String userId) async {
    log('🔄 Iniciando sync inicial de planejamentos...');

    // Busca planejamentos do Supabase
    final response = await _supabase
        .from('planejamentos')
        .select('*')
        .eq('usuario_id', userId)
        .eq('ano', _periodoAtual.year)
        .eq('mes', _periodoAtual.month);

    if (response is List && response.isNotEmpty) {
      for (final item in response) {
        // Converte para formato SQLite
        final planejamentoData = Map<String, dynamic>.from(item);
        planejamentoData['sync_status'] = 'synced';
        planejamentoData['last_sync'] = DateTime.now().toIso8601String();

        // Salva no SQLite
        await _localDb.savePlanejamentoLocal(planejamentoData);
      }
      log('✅ Sync inicial concluído: ${response.length} planejamentos');
    }
  }

  /// 🚀 PROCESSAR DADOS DO RPC (já vem calculado do Supabase)
  Future<void> _processarDadosDoRpc(List<Map<String, dynamic>> rpcData) async {
    log('🚀 Processando dados do RPC (já calculados)...');

    final planejamentosProcessados = <PlanejamentoModel>[];

    for (final item in rpcData) {
      // RPC já retorna dados calculados, só precisa converter para PlanejamentoModel
      final planejamento = PlanejamentoModel.fromJson({
        'id': item['id'] ?? '${item['categoria_id']}_${item['subcategoria_id'] ?? 'principal'}_rpc',
        'usuario_id': item['usuario_id'],
        'ano': item['ano'],
        'mes': item['mes'],
        'categoria_id': item['categoria_id'],
        'subcategoria_id': item['subcategoria_id'],
        'tipo': item['tipo'],
        'valor_planejado': (item['valor_planejado'] as num?)?.toDouble() ?? 0.0,
        'created_at': item['created_at'],
        'updated_at': item['updated_at'],
        'categoria_nome': item['categoria_nome'],
        'categoria_icone': item['categoria_icone'],
        'categoria_cor': item['categoria_cor'],
        'subcategoria_nome': item['subcategoria_nome'],
        // RPC já calcula estes valores (igual ao React)
        'valor_realizado': (item['valor_realizado'] as num?)?.toDouble() ?? 0.0,
        'valor_previsto': (item['valor_previsto'] as num?)?.toDouble() ?? 0.0,
        'media_historica': (item['media_historica'] as num?)?.toDouble() ?? 0.0,
        'total_transacoes_realizadas': item['total_transacoes_realizadas'] as int? ?? 0,
        'total_transacoes_previstas': item['total_transacoes_previstas'] as int? ?? 0,
      });

      planejamentosProcessados.add(planejamento);
    }

    _planejamentosCache = planejamentosProcessados;
    _planejamentosController.add(_planejamentosCache);

    log('✅ RPC processado: ${planejamentosProcessados.length} planejamentos');
  }

  /// 🚀 PROCESSAR DADOS IGUAL AO REACT (linha 139-207 do React)
  Future<List<PlanejamentoModel>> _processarDadosComparativosIgualReact(Map<String, dynamic> dados) async {
    log('🚀 Processando dados igual ao React...');

    final categorias = dados['categorias'] as List<dynamic>;
    final subcategorias = dados['subcategorias'] as List<dynamic>;
    final planejamentos = dados['planejamentos'] as List<dynamic>;
    final transacoes = dados['transacoes'] as List<dynamic>;
    final transacoesHistoricas = dados['transacoesHistoricas'] as List<dynamic>;

    final resultado = <PlanejamentoModel>[];

    // Processar cada categoria (igual ao React linha 144)
    for (final categoria in categorias) {
      final categoriaId = categoria['id'] as String;
      final categoriaTipo = categoria['tipo'] as String;

      log('🔍 Processando categoria: ${categoria['nome']} (${categoria['tipo']})');

      // Buscar subcategorias desta categoria (igual ao React linha 146)
      final subsDestaCategoria = subcategorias
          .where((s) => s['categoria_id'] == categoriaId)
          .toList();

      if (subsDestaCategoria.isNotEmpty) {
        log('📂 Categoria ${categoria['nome']} tem ${subsDestaCategoria.length} subcategorias');

        // Categoria com subcategorias (igual ao React linha 148-159)
        for (final sub in subsDestaCategoria) {
          final item = _criarItemComparativoIgualReact(
            categoria: categoria,
            subcategoria: sub,
            planejamentos: planejamentos,
            transacoes: transacoes,
            transacoesHistoricas: transacoesHistoricas,
          );
          resultado.add(item);
        }

        // Verificar se há transações sem subcategoria (igual ao React linha 161-192)
        final transacoesSemSubcategoria = transacoes.where((t) =>
            t['categoria_id'] == categoriaId &&
            (t['subcategoria_id'] == null || t['subcategoria_id'] == '') &&
            t['tipo'] == categoriaTipo).toList();

        final transacoesHistoricasSemSubcategoria = transacoesHistoricas.where((t) =>
            t['categoria_id'] == categoriaId &&
            (t['subcategoria_id'] == null || t['subcategoria_id'] == '') &&
            t['tipo'] == categoriaTipo).toList();

        // Se há transações sem subcategoria, criar entrada "Sem subcategoria"
        if (transacoesSemSubcategoria.isNotEmpty || transacoesHistoricasSemSubcategoria.isNotEmpty) {
          log('🔍 Encontradas transações sem subcategoria para ${categoria['nome']}');
          final itemSemSubcategoria = _criarItemComparativoIgualReact(
            categoria: categoria,
            subcategoria: {'id': 'sem_subcategoria', 'nome': 'Sem subcategoria'},
            planejamentos: [], // Não buscar planejamentos para "Sem subcategoria"
            transacoes: transacoes,
            transacoesHistoricas: transacoesHistoricas,
            forceSemSubcategoria: true,
          );
          resultado.add(itemSemSubcategoria);
        }
      } else {
        log('📂 Categoria ${categoria['nome']} SEM subcategorias');

        // Categoria sem subcategorias (igual ao React linha 194-202)
        final item = _criarItemComparativoIgualReact(
          categoria: categoria,
          subcategoria: null,
          planejamentos: planejamentos,
          transacoes: transacoes,
          transacoesHistoricas: transacoesHistoricas,
        );
        resultado.add(item);
      }
    }

    log('✅ Processamento concluído: ${resultado.length} itens');
    return resultado;
  }

  /// 🚀 CRIAR ITEM COMPARATIVO IGUAL AO REACT (linha 212-260 do React)
  PlanejamentoModel _criarItemComparativoIgualReact({
    required Map<String, dynamic> categoria,
    Map<String, dynamic>? subcategoria,
    required List<dynamic> planejamentos,
    required List<dynamic> transacoes,
    required List<dynamic> transacoesHistoricas,
    bool forceSemSubcategoria = false,
  }) {
    final categoriaId = categoria['id'] as String;
    final categoriaTipo = categoria['tipo'] as String;
    final subcategoriaId = subcategoria?['id'] as String?;

    // Para "Sem subcategoria", forçar busca por transações sem subcategoria_id (linha 214)
    final buscaSemSubcategoria = forceSemSubcategoria || (subcategoria == null);

    // Buscar planejamento (linha 216-221)
    Map<String, dynamic>? planejamento;
    try {
      planejamento = planejamentos.firstWhere((p) =>
          p['categoria_id'] == categoriaId &&
          (buscaSemSubcategoria
              ? (p['subcategoria_id'] == null || p['subcategoria_id'] == '')
              : p['subcategoria_id'] == subcategoriaId) &&
          p['tipo'] == categoriaTipo);
    } catch (e) {
      planejamento = null;
    }

    // Buscar transações do mês (linha 223-228)
    final transacoesMes = transacoes.where((t) =>
        t['categoria_id'] == categoriaId &&
        (buscaSemSubcategoria
            ? (t['subcategoria_id'] == null || t['subcategoria_id'] == '')
            : t['subcategoria_id'] == subcategoriaId) &&
        t['tipo'] == categoriaTipo).toList();

    // Calcular realizado e previsto (linha 230-237)
    final valorRealizado = transacoesMes
        .where((t) => t['efetivado'] == true)
        .fold(0.0, (acc, t) => acc + ((t['valor'] as num?)?.abs().toDouble() ?? 0.0));

    final valorPrevisto = transacoesMes
        .where((t) => t['efetivado'] == false)
        .fold(0.0, (acc, t) => acc + ((t['valor'] as num?)?.abs().toDouble() ?? 0.0));

    final totalTransacoesRealizadas = transacoesMes.where((t) => t['efetivado'] == true).length;
    final totalTransacoesPrevistas = transacoesMes.where((t) => t['efetivado'] == false).length;

    // Calcular média histórica (linha 242-250)
    final transacoesHistoricasCategoria = transacoesHistoricas.where((t) =>
        t['categoria_id'] == categoriaId &&
        (buscaSemSubcategoria
            ? (t['subcategoria_id'] == null || t['subcategoria_id'] == '')
            : t['subcategoria_id'] == subcategoriaId) &&
        t['tipo'] == categoriaTipo).toList();

    final mediaHistorica = transacoesHistoricasCategoria.isNotEmpty
        ? transacoesHistoricasCategoria.fold(0.0, (acc, t) => acc + ((t['valor'] as num?)?.abs().toDouble() ?? 0.0)) / 3.0 // Média de 3 meses
        : 0.0;

    // Criar ID único
    final id = subcategoriaId != null && subcategoriaId != 'sem_subcategoria'
        ? '${categoriaId}_${subcategoriaId}_comparativo'
        : '${categoriaId}_principal_comparativo';

    return PlanejamentoModel.fromJson({
      'id': id,
      'usuario_id': _supabase.auth.currentUser?.id,
      'ano': _periodoAtual.year,
      'mes': _periodoAtual.month,
      'categoria_id': categoriaId,
      'subcategoria_id': subcategoriaId == 'sem_subcategoria' ? null : subcategoriaId,
      'tipo': categoriaTipo,
      'valor_planejado': (planejamento?['valor_planejado'] as num?)?.toDouble() ?? 0.0,
      'created_at': planejamento?['created_at'],
      'updated_at': planejamento?['updated_at'],
      'categoria_nome': categoria['nome'],
      'categoria_icone': categoria['icone'],
      'categoria_cor': categoria['cor'],
      'subcategoria_nome': subcategoria?['nome'],
      'valor_realizado': valorRealizado,
      'valor_previsto': valorPrevisto,
      'media_historica': mediaHistorica,
      'total_transacoes_realizadas': totalTransacoesRealizadas,
      'total_transacoes_previstas': totalTransacoesPrevistas,
    });
  }

  /// 📊 PROCESSAR DADOS COMPARATIVOS
  Future<void> _processarDadosComparativosPlanejamentos(List<Map<String, dynamic>> localData) async {
    log('🔍 Debug - Iniciando processamento de dados comparativos...');
    log('🔍 Debug - Dados locais encontrados: ${localData.length}');

    // Busca valores realizados/previstos das transações
    final valoresTransacoes = await _localDb.fetchValoresPlanejamento(
      ano: _periodoAtual.year,
      mes: _periodoAtual.month,
    );
    log('🔍 Debug - Valores de transações encontrados: ${valoresTransacoes.length}');

    // Busca categorias para dados adicionais
    final categorias = await _localDb.fetchCategoriasLocal();
    log('🔍 Debug - Categorias encontradas: ${categorias.length}');

    // Busca todas as subcategorias existentes para criar entradas zeradas
    final todasSubcategorias = await _localDb.fetchSubcategoriasLocal();
    log('🔍 Debug - Subcategorias no banco: ${todasSubcategorias.length}');

    final planejamentosProcessados = <PlanejamentoModel>[];
    final subcategoriasComPlanejamento = <String>{};

    // Primeiro, processa os planejamentos existentes
    for (final item in localData) {
      // Encontra categoria correspondente
      final categoria = categorias.firstWhere(
        (cat) => cat['id'] == item['categoria_id'],
        orElse: () => <String, dynamic>{},
      );

      // Encontra subcategoria se existir
      Map<String, dynamic> subcategoria = {};
      if (item['subcategoria_id'] != null) {
        final subcategorias = await _localDb.fetchSubcategoriasLocal(categoriaId: item['categoria_id']);
        subcategoria = subcategorias.firstWhere(
          (subcat) => subcat['id'] == item['subcategoria_id'],
          orElse: () => <String, dynamic>{},
        );
      }

      // Busca valores das transações
      final chave = item['subcategoria_id'] != null
          ? '${item['categoria_id']}|${item['subcategoria_id']}'
          : item['categoria_id'];

      final valores = valoresTransacoes[chave] ?? {
        'valor_realizado': 0.0,
        'valor_previsto': 0.0,
        'transacoes_realizadas': 0.0,
        'transacoes_previstas': 0.0,
      };

      // Busca média histórica
      final mediaHistorica = await _localDb.fetchMediaHistoricaCategoria(
        categoriaId: item['categoria_id'],
        subcategoriaId: item['subcategoria_id'],
        anoAtual: _periodoAtual.year,
        mesAtual: _periodoAtual.month,
        tipo: item['tipo'],
      );

      // Cria modelo completo
      final planejamento = PlanejamentoModel.fromJson({
        ...item,
        'categoria_nome': categoria['nome'],
        'categoria_icone': categoria['icone'],
        'categoria_cor': categoria['cor'],
        'subcategoria_nome': subcategoria['nome'],
        'valor_realizado': valores['valor_realizado'],
        'valor_previsto': valores['valor_previsto'],
        'media_historica': mediaHistorica,
        'total_transacoes_realizadas': valores['transacoes_realizadas']?.toInt() ?? 0,
        'total_transacoes_previstas': valores['transacoes_previstas']?.toInt() ?? 0,
      });

      planejamentosProcessados.add(planejamento);

      // Marca subcategoria como tendo planejamento
      if (item['subcategoria_id'] != null) {
        subcategoriasComPlanejamento.add('${item['categoria_id']}|${item['subcategoria_id']}');
      }
    }

    // Segundo, busca categorias que têm transações para criar planejamentos zerados
    final categoriasComPlanejamento = localData
        .where((item) => item['subcategoria_id'] == null)
        .map((item) => item['categoria_id'] as String)
        .toSet();

    // Busca categorias que têm valores realizados (transações) mesmo sem planejamento
    final categoriasComTransacoes = valoresTransacoes.keys
        .where((chave) => !chave.contains('|')) // Só categorias principais (sem subcategorias)
        .toSet();

    log('🔍 Debug subcategorias zeradas:');
    log('📊 Total categorias: ${categorias.length}');
    log('📊 Total subcategorias: ${todasSubcategorias.length}');
    log('📊 Categorias com planejamento: ${categoriasComPlanejamento.length}');
    log('📊 Categorias com transações: ${categoriasComTransacoes.length}');
    log('📊 Planejamentos existentes: ${localData.length}');

    // Combina as duas listas: categorias com planejamento + categorias com transações
    final categoriasParaProcessar = <String>{
      ...categoriasComPlanejamento,
      ...categoriasComTransacoes,
    };

    for (final categoria in categorias) {
      final categoriaId = categoria['id'] as String;

      log('🔍 Analisando categoria: ${categoria['nome']} (ID: $categoriaId)');

      // Processa se categoria tem planejamento OU tem transações
      if (!categoriasParaProcessar.contains(categoriaId)) {
        log('⏭️ Categoria sem planejamento nem transações, pulando...');
        continue;
      }

      // Se não tem planejamento principal mas tem transações, criar um planejamento principal zerado
      if (!categoriasComPlanejamento.contains(categoriaId) && categoriasComTransacoes.contains(categoriaId)) {
        log('💡 Criando planejamento principal zerado para categoria com transações: ${categoria['nome']}');

        final valores = valoresTransacoes[categoriaId] ?? {
          'valor_realizado': 0.0,
          'valor_previsto': 0.0,
        };

        final planejamentoPrincipal = PlanejamentoModel.fromJson({
          'id': '${categoriaId}_principal_virtual',
          'usuario_id': _supabase.auth.currentUser?.id,
          'ano': _periodoAtual.year,
          'mes': _periodoAtual.month,
          'categoria_id': categoriaId,
          'subcategoria_id': null,
          'tipo': categoria['tipo'],
          'valor_planejado': 0.0, // Zerado
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'categoria_nome': categoria['nome'],
          'categoria_icone': categoria['icone'],
          'categoria_cor': categoria['cor'],
          'subcategoria_nome': null,
          'valor_realizado': valores['valor_realizado'],
          'valor_previsto': valores['valor_previsto'],
          'media_historica': 0.0,
          'total_transacoes_realizadas': 0,
          'total_transacoes_previstas': 0,
        });

        planejamentosProcessados.add(planejamentoPrincipal);
      }

      // Busca subcategorias desta categoria
      final subcategoriasDaCategoria = todasSubcategorias
          .where((sub) => sub['categoria_id'] == categoriaId)
          .toList();

      log('📂 Subcategorias da categoria ${categoria['nome']}: ${subcategoriasDaCategoria.length}');

      for (final subcategoria in subcategoriasDaCategoria) {
        final subcategoriaId = subcategoria['id'] as String;
        final subcategoriaNome = subcategoria['nome'] as String;
        final chaveSubcategoria = '$categoriaId|$subcategoriaId';

        log('🔍 Processando subcategoria: $subcategoriaNome (ID: $subcategoriaId)');

        // Se já existe planejamento para esta subcategoria, pula
        if (subcategoriasComPlanejamento.contains(chaveSubcategoria)) {
          log('⏭️ Subcategoria já tem planejamento, pulando...');
          continue;
        }

        log('✅ Criando planejamento virtual para subcategoria: $subcategoriaNome');

        // Busca valores das transações para subcategoria zerada
        final valores = valoresTransacoes[chaveSubcategoria] ?? {
          'valor_realizado': 0.0,
          'valor_previsto': 0.0,
          'transacoes_realizadas': 0.0,
          'transacoes_previstas': 0.0,
        };

        // Busca média histórica
        final mediaHistorica = await _localDb.fetchMediaHistoricaCategoria(
          categoriaId: categoriaId,
          subcategoriaId: subcategoriaId,
          anoAtual: _periodoAtual.year,
          mesAtual: _periodoAtual.month,
          tipo: categoria['tipo'],
        );

        // Cria planejamento virtual zerado
        final planejamentoZerado = PlanejamentoModel.fromJson({
          'id': '${categoriaId}_${subcategoriaId}_virtual',
          'usuario_id': _supabase.auth.currentUser?.id,
          'ano': _periodoAtual.year,
          'mes': _periodoAtual.month,
          'categoria_id': categoriaId,
          'subcategoria_id': subcategoriaId,
          'tipo': categoria['tipo'],
          'valor_planejado': 0.0, // Zerado
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'categoria_nome': categoria['nome'],
          'categoria_icone': categoria['icone'],
          'categoria_cor': categoria['cor'],
          'subcategoria_nome': subcategoria['nome'],
          'valor_realizado': valores['valor_realizado'],
          'valor_previsto': valores['valor_previsto'],
          'media_historica': mediaHistorica,
          'total_transacoes_realizadas': valores['transacoes_realizadas']?.toInt() ?? 0,
          'total_transacoes_previstas': valores['transacoes_previstas']?.toInt() ?? 0,
        });

        planejamentosProcessados.add(planejamentoZerado);
      }
    }

    _planejamentosCache = planejamentosProcessados;
    _planejamentosController.add(_planejamentosCache);

    // Debug final
    final subcategoriasVirtuais = planejamentosProcessados.where((p) => p.subcategoriaId != null).length;
    log('✅ Planejamentos processados: ${planejamentosProcessados.length} (incluindo subcategorias zeradas)');
    log('🔍 Debug - Subcategorias virtuais criadas: $subcategoriasVirtuais');
  }

  // ===========================
  // SALVAR PLANEJAMENTO (OFFLINE-FIRST)
  // ===========================

  Future<void> salvarPlanejamento(PlanejamentoModel planejamento) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      log('💾 Salvando planejamento com RPC: ${planejamento.id}');

      // Se é um planejamento virtual (ID contém '_virtual'), cria um novo ID real
      PlanejamentoModel planejamentoParaSalvar = planejamento;
      if (planejamento.id.contains('_virtual') || planejamento.id.contains('_rpc')) {
        planejamentoParaSalvar = planejamento.copyWith(
          id: _uuid.v4(), // Gera novo ID real
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        log('🆕 Convertendo planejamento virtual/RPC em real: ${planejamentoParaSalvar.id}');
      }

      // 💾 ESTRATÉGIA SIMPLIFICADA: Sempre salvar localmente e usar fila de sync
      log('💾 Salvando planejamento localmente e adicionando à fila de sync...');

      // Salva localmente - isso já adiciona automaticamente à fila de sync com operação UPSERT
      await _localDb.savePlanejamentoLocal(planejamentoParaSalvar.toJson());
      log('✅ Planejamento salvo localmente: ${planejamentoParaSalvar.id}');

      // 🔄 FORÇA RELOAD DO BANCO PARA ATUALIZAR CACHE
      await _recarregarCacheDoLocal();

    } catch (e) {
      log('❌ Erro ao salvar planejamento: $e');
      rethrow;
    }
  }

  // ===========================
  // RECARREGAR CACHE DO LOCAL
  // ===========================

  /// Força reload do cache a partir do banco local
  Future<void> _recarregarCacheDoLocal() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _planejamentosCache = [];
        _planejamentosController.add(_planejamentosCache);
        return;
      }

      log('🔄 Recarregando cache do SQLite local...');

      // Busca dados atualizados do SQLite
      await _localDb.setCurrentUser(userId);
      final localData = await _localDb.fetchPlanejamentosLocal(
        ano: _periodoAtual.year,
        mes: _periodoAtual.month,
      );

      // Processa e atualiza cache
      await _processarDadosComparativosPlanejamentos(localData);

      log('✅ Cache recarregado com ${_planejamentosCache.length} planejamentos');
    } catch (e) {
      log('❌ Erro ao recarregar cache do local: $e');
    }
  }

  // ===========================
  // EXCLUIR PLANEJAMENTO (OFFLINE-FIRST)
  // ===========================

  Future<void> excluirPlanejamento(String planejamentoId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      log('🗑️ Excluindo planejamento offline-first: $planejamentoId');

      // Remove do cache local primeiro
      _planejamentosCache.removeWhere((p) => p.id == planejamentoId);
      _planejamentosController.add(_planejamentosCache);

      // Remove do SQLite
      await _localDb.excluirPlanejamentoLocal(planejamentoId);

      // Tenta remover do Supabase se online
      if (await ConnectivityHelper.instance.isConnected()) {
        try {
          await _supabase
              .from('planejamentos')
              .delete()
              .eq('id', planejamentoId)
              .eq('usuario_id', userId);
          log('✅ Planejamento removido do Supabase: $planejamentoId');
        } catch (syncError) {
          log('⚠️ Erro ao remover do Supabase (ficará pendente): $syncError');
          // Erro de sincronização não impede a exclusão local
        }
      }

    } catch (e) {
      log('❌ Erro ao excluir planejamento: $e');
      rethrow;
    }
  }

  // ===========================
  // AÇÕES ESPECIAIS
  // ===========================

  /// Copia planejamentos do mês anterior via RPC
  Future<void> copiarMesAnterior() async {
    log('📅 Copiando planejamentos do mês anterior via RPC...');

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    // 🚀 USA RPC que já copia do mês anterior (igual ao React)
    if (await ConnectivityHelper.instance.isConnected()) {
      try {
        log('🚀 Chamando RPC ip_prod_copiar_planejamento_mes_anterior...');

        final response = await _supabase.rpc('ip_prod_copiar_planejamento_mes_anterior', params: {
          'p_usuario_id': userId,
          'p_ano_destino': _periodoAtual.year,
          'p_mes_destino': _periodoAtual.month,
        });

        log('✅ RPC ip_prod_copiar_planejamento_mes_anterior executado: $response');

        // Recarrega dados para pegar valores atualizados
        await carregarPlanejamentos();

        log('📅 Cópia do mês anterior realizada via RPC com sucesso!');
        return;
      } catch (rpcError) {
        log('❌ Erro no RPC copiar mês anterior, usando fallback: $rpcError');
      }
    }

    // FALLBACK: método antigo se RPC falhar
    log('⚠️ Usando fallback local para copiar mês anterior...');

    final mesAnterior = DateTime(_periodoAtual.year, _periodoAtual.month - 1);

    // Busca planejamentos do mês anterior
    final planejamentosAnteriores = await _localDb.fetchPlanejamentosLocal(
      ano: mesAnterior.year,
      mes: mesAnterior.month,
    );

    for (final item in planejamentosAnteriores) {
      final novoPlanejamento = PlanejamentoModel(
        id: _uuid.v4(),
        usuarioId: item['usuario_id'],
        ano: _periodoAtual.year,
        mes: _periodoAtual.month,
        categoriaId: item['categoria_id'],
        subcategoriaId: item['subcategoria_id'],
        tipo: item['tipo'],
        valorPlanejado: (item['valor_planejado'] as num).toDouble(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await salvarPlanejamento(novoPlanejamento);
    }

    await carregarPlanejamentos();
  }

  /// Aplica média histórica para todas as categorias via RPC
  Future<void> aplicarMediaHistorica() async {
    log('📊 Iniciando aplicação de média histórica via RPC...');

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    // 🚀 USA RPC que já calcula média histórica (igual ao React)
    if (await ConnectivityHelper.instance.isConnected()) {
      try {
        log('🚀 Chamando RPC economia_categorias_ipoupei_2025...');

        final response = await _supabase.rpc('economia_categorias_ipoupei_2025', params: {
          'p_usuario_id': userId,
          'p_ano_destino': _periodoAtual.year,
          'p_mes_destino': _periodoAtual.month,
        });

        log('✅ RPC economia_categorias_ipoupei_2025 executado: $response');

        // Recarrega dados para pegar valores atualizados
        await carregarPlanejamentos();

        log('📊 Média histórica aplicada via RPC com sucesso!');
        return;
      } catch (rpcError) {
        log('❌ Erro no RPC economia_categorias, usando fallback: $rpcError');
      }
    }

    // FALLBACK: método antigo se RPC falhar
    log('⚠️ Usando fallback local para média histórica...');

    int planejamentosAtualizados = 0;
    for (final planejamento in _planejamentosCache) {
      if (planejamento.mediaHistorica > 0) {
        final novoPlanejamento = planejamento.copyWith(
          valorPlanejado: planejamento.mediaHistorica,
          updatedAt: DateTime.now(),
        );

        await salvarPlanejamento(novoPlanejamento);
        planejamentosAtualizados++;
        log('✅ Aplicada média para ${planejamento.categoriaNome}: R\$ ${planejamento.mediaHistorica.toStringAsFixed(2)}');
      }
    }

    log('📊 Média histórica aplicada a $planejamentosAtualizados planejamentos');
  }

  /// Aplica desafio de economia (reduz despesas em X%)
  Future<void> aplicarDesafioEconomia(double percentual) async {
    if (percentual <= 0 || percentual > 50) {
      throw Exception('Percentual deve estar entre 1% e 50%');
    }

    log('💰 Iniciando desafio de economia ($percentual%)...');

    final reducao = percentual / 100;
    int despesasReduzidas = 0;

    for (final planejamento in _planejamentosCache) {
      if (planejamento.isDespesa && planejamento.valorPlanejado > 0) {
        final novoValor = planejamento.valorPlanejado * (1 - reducao);
        final novoPlanejamento = planejamento.copyWith(
          valorPlanejado: novoValor,
          updatedAt: DateTime.now(),
        );

        await salvarPlanejamento(novoPlanejamento);
        despesasReduzidas++;
        log('💰 Reduzida ${planejamento.categoriaNome}: R\$ ${planejamento.valorPlanejado.toStringAsFixed(2)} → R\$ ${novoValor.toStringAsFixed(2)}');
      }
    }

    log('💰 Desafio aplicado a $despesasReduzidas despesas (-$percentual%)');
  }

  /// Repete planejamentos pelo ano todo
  Future<void> repetirPeloAno() async {
    log('🔄 Iniciando repetição pelo ano todo...');

    final planejamentosBase = List<PlanejamentoModel>.from(_planejamentosCache);
    int totalCriados = 0;

    for (int mes = 1; mes <= 12; mes++) {
      if (mes == _periodoAtual.month) continue; // Pula o mês atual

      for (final planejamento in planejamentosBase) {
        final novoPlanejamento = planejamento.copyWith(
          id: _uuid.v4(),
          mes: mes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await salvarPlanejamento(novoPlanejamento);
        totalCriados++;
      }
      log('🔄 Mês $mes: ${planejamentosBase.length} planejamentos criados');
    }

    log('🔄 Repetição concluída: $totalCriados planejamentos criados para o ano');
  }

  // ===========================
  // DADOS AGRUPADOS IGUAL AO REACT (linha 563-613)
  // ===========================

  /// 🚀 Agrupar dados por categoria igual ao React
  Map<String, Map<String, dynamic>> getDadosAgrupados() {
    final grupos = <String, Map<String, dynamic>>{
      'receita': {},
      'despesa': {},
    };

    for (final item in _planejamentosCache) {
      final tipo = item.tipo;
      final categoriaId = item.categoriaId;

      if (!grupos[tipo]!.containsKey(categoriaId)) {
        grupos[tipo]![categoriaId] = {
          'categoria_id': categoriaId,
          'categoria_nome': item.categoriaNome,
          'categoria_cor': item.categoriaCor,
          'categoria_icone': item.categoriaIcone,
          'tipo': tipo,
          'subcategorias': <PlanejamentoModel>[],
          // Totais da categoria
          'total_planejado': 0.0,
          'total_realizado': 0.0,
          'total_previsto': 0.0,
          'media_historica_total': 0.0,
        };
      }

      final grupo = grupos[tipo]![categoriaId]!;

      if (item.subcategoriaId != null && item.subcategoriaId!.isNotEmpty) {
        // É uma subcategoria (incluindo "sem_subcategoria")
        if (item.subcategoriaId != 'sem_subcategoria') {
          // Subcategoria normal - adicionar à lista
          (grupo['subcategorias'] as List<PlanejamentoModel>).add(item);
        }

        // Acumular totais para todas as subcategorias (incluindo "sem_subcategoria")
        grupo['total_planejado'] = (grupo['total_planejado'] as double) + item.valorPlanejado;
        grupo['total_realizado'] = (grupo['total_realizado'] as double) + item.valorRealizado;
        grupo['total_previsto'] = (grupo['total_previsto'] as double) + item.valorPrevisto;
      } else {
        // É categoria principal sem subcategorias - armazenar valores diretos
        grupo['valor_planejado'] = item.valorPlanejado;
        grupo['valor_realizado'] = item.valorRealizado;
        grupo['valor_previsto'] = item.valorPrevisto;
        grupo['media_historica'] = item.mediaHistorica;

        // Para categorias sem subcategorias, o total é igual ao valor individual
        grupo['total_planejado'] = item.valorPlanejado;
        grupo['total_realizado'] = item.valorRealizado;
        grupo['total_previsto'] = item.valorPrevisto;
      }
    }

    return grupos;
  }

  // ===========================
  // ESTATÍSTICAS CORRETAS
  // ===========================

  /// 🚀 Estatísticas calculadas corretamente com agrupamento
  Map<String, dynamic> getEstatisticas() {
    final grupos = getDadosAgrupados();

    final receitas = grupos['receita']!.values;
    final despesas = grupos['despesa']!.values;

    final stats = {
      'receitas': {
        'planejado': receitas.fold(0.0, (acc, r) => acc + (r['total_planejado'] as double)),
        'realizado': receitas.fold(0.0, (acc, r) => acc + (r['total_realizado'] as double)),
        'previsto': receitas.fold(0.0, (acc, r) => acc + (r['total_previsto'] as double)),
      },
      'despesas': {
        'planejado': despesas.fold(0.0, (acc, d) => acc + (d['total_planejado'] as double)),
        'realizado': despesas.fold(0.0, (acc, d) => acc + (d['total_realizado'] as double)),
        'previsto': despesas.fold(0.0, (acc, d) => acc + (d['total_previsto'] as double)),
      }
    };

    // Calcular economia
    final receitasMap = stats['receitas'] as Map<String, double>;
    final despesasMap = stats['despesas'] as Map<String, double>;

    final receitaPlanejado = receitasMap['planejado']!;
    final receitaRealizado = receitasMap['realizado']!;
    final receitaPrevisto = receitasMap['previsto']!;
    final despesaPlanejado = despesasMap['planejado']!;
    final despesaRealizado = despesasMap['realizado']!;
    final despesaPrevisto = despesasMap['previsto']!;

    stats['economia'] = {
      'planejado': receitaPlanejado - despesaPlanejado,
      'realizado': receitaRealizado - despesaRealizado,
      'previsto': (receitaRealizado + receitaPrevisto) - (despesaRealizado + despesaPrevisto),
    };

    return stats;
  }

  // Getters para compatibilidade (usando estatísticas corretas)
  double get totalReceitas {
    final stats = getEstatisticas();
    return stats['receitas']['planejado'] as double;
  }

  double get totalDespesas {
    final stats = getEstatisticas();
    return stats['despesas']['planejado'] as double;
  }

  double get saldoPlanejado => totalReceitas - totalDespesas;

  double get totalRealizadoReceitas {
    final stats = getEstatisticas();
    return (stats['receitas']['realizado'] as double) + (stats['receitas']['previsto'] as double);
  }

  double get totalRealizadoDespesas {
    final stats = getEstatisticas();
    return (stats['despesas']['realizado'] as double) + (stats['despesas']['previsto'] as double);
  }

  double get saldoRealizado => totalRealizadoReceitas - totalRealizadoDespesas;

  // ===========================
  // MANUTENÇÃO E LIMPEZA
  // ===========================

  /// 🧹 Limpar registros inválidos e duplicados
  Future<void> limparDadosInconsistentes() async {
    log('🧹 Iniciando limpeza de dados inconsistentes...');

    try {
      // 1. Limpar registros virtuais com IDs malformados
      await _limparRegistrosVirtuaisInvalidos();

      // 2. Deduplicar planejamentos (especialmente Alimentação)
      await _deduplicarPlanejamentos();

      // 3. Limpar queue de sync com problemas
      await _limparQueueSyncProblematica();

      // 4. Recarregar dados limpos
      await _recarregarCacheDoLocal();

      log('✅ Limpeza de dados concluída com sucesso!');
    } catch (e) {
      log('❌ Erro durante limpeza de dados: $e');
    }
  }

  /// 🚨 Reset de emergência - remove TODOS os planejamentos do período atual
  Future<void> resetEmergenciaPeriodoAtual() async {
    log('🚨 RESET DE EMERGÊNCIA: removendo todos os planejamentos do período ${_periodoAtual.month}/${_periodoAtual.year}');

    final db = _localDb.database;
    if (db == null) {
      log('❌ Database não disponível para reset');
      return;
    }

    try {
      // Remove todos os planejamentos do período atual
      final count = await db.delete(
        'planejamentos',
        where: 'ano = ? AND mes = ?',
        whereArgs: [_periodoAtual.year, _periodoAtual.month],
      );

      log('🗑️ Removidos $count planejamentos do período ${_periodoAtual.month}/${_periodoAtual.year}');

      // Limpar cache local
      _planejamentosCache.clear();

      // Notificar mudanças via Stream
      _planejamentosController.add(_planejamentosCache);

      log('🔄 Reset de emergência concluído');
    } catch (e) {
      log('❌ Erro durante reset de emergência: $e');
      rethrow;
    }
  }

  /// 🗑️ Limpar registros virtuais com IDs inválidos
  Future<void> _limparRegistrosVirtuaisInvalidos() async {
    log('🗑️ Removendo registros virtuais inválidos...');

    // Remove registros com IDs malformados (contendo "_virtual")
    final query = '''
      DELETE FROM planejamentos
      WHERE id LIKE '%_virtual%' OR id LIKE '%_%_%_%_%_%_virtual'
    ''';

    final db = _localDb.database;
    if (db != null) {
      final count = await db.rawDelete(query);
      log('🗑️ Removidos $count registros virtuais inválidos');
    } else {
      log('❌ Database não disponível para limpeza');
    }
  }

  /// 📊 Deduplicar planejamentos da mesma categoria/subcategoria
  Future<void> _deduplicarPlanejamentos() async {
    log('📊 Deduplicando planejamentos...');

    final db = _localDb.database;
    if (db == null) {
      log('❌ Database não disponível para deduplicação');
      return;
    }

    // Busca duplicatas na mesma categoria/subcategoria para o mesmo período
    final query = '''
      SELECT categoria_id, subcategoria_id, tipo, COUNT(*) as duplicates
      FROM planejamentos
      WHERE ano = ? AND mes = ?
      GROUP BY categoria_id, subcategoria_id, tipo
      HAVING COUNT(*) > 1
    ''';

    final duplicates = await db.rawQuery(query, [
      _periodoAtual.year,
      _periodoAtual.month,
    ]);

    for (final duplicate in duplicates) {
      final categoriaId = duplicate['categoria_id'] as String;
      final subcategoriaId = duplicate['subcategoria_id'] as String?;
      final tipo = duplicate['tipo'] as String;
      final count = duplicate['duplicates'] as int;

      log('📊 Encontradas $count duplicatas para categoria: $categoriaId${subcategoriaId != null ? ' (sub: $subcategoriaId)' : ''} - tipo: $tipo');

      // Busca todos os registros duplicados ordenados por data de criação
      final duplicateRecords = await db.query(
        'planejamentos',
        where: 'categoria_id = ? AND subcategoria_id ${subcategoriaId != null ? '= ?' : 'IS NULL'} AND tipo = ? AND ano = ? AND mes = ?',
        whereArgs: subcategoriaId != null
          ? [categoriaId, subcategoriaId, tipo, _periodoAtual.year, _periodoAtual.month]
          : [categoriaId, tipo, _periodoAtual.year, _periodoAtual.month],
        orderBy: 'created_at DESC',
      );

      if (duplicateRecords.length > 1) {
        // Identificar o registro com menor valor (original) e manter este
        final recordsWithValues = duplicateRecords.map((record) => {
          'record': record,
          'valor': (record['valor_planejado'] as num?)?.toDouble() ?? 0.0,
        }).toList();

        // Ordenar por valor crescente para manter o menor (original)
        recordsWithValues.sort((a, b) => (a['valor'] as double).compareTo(b['valor'] as double));

        final toKeep = recordsWithValues.first['record'] as Map<String, dynamic>;
        final toDelete = recordsWithValues.skip(1).map((item) => item['record'] as Map<String, dynamic>);

        for (final record in toDelete) {
          await db.delete(
            'planejamentos',
            where: 'id = ?',
            whereArgs: [record['id']],
          );
          log('🗑️ Removido planejamento duplicado (valor: R\$ ${record['valor_planejado']}): ${record['id']}');
        }

        log('✅ Mantido planejamento original (valor: R\$ ${toKeep['valor_planejado']}): ${toKeep['id']}');
      }
    }
  }

  /// 🔄 Limpar queue de sync com problemas
  Future<void> _limparQueueSyncProblematica() async {
    log('🔄 Limpando queue de sync problemática...');

    final db = _localDb.database;
    if (db == null) {
      log('❌ Database não disponível para limpeza de sync');
      return;
    }

    // Remove itens da queue com IDs virtuais malformados
    final query = '''
      DELETE FROM sync_queue
      WHERE record_id LIKE '%_virtual%' OR record_id LIKE '%_%_%_%_%_%_virtual'
    ''';

    try {
      final count = await db.rawDelete(query);
      log('🔄 Removidos $count itens problemáticos da queue de sync');
    } catch (e) {
      log('⚠️ Erro ao limpar queue de sync: $e');
    }
  }

  // ===========================
  // CLEANUP
  // ===========================

  void dispose() {
    _planejamentosController.close();
  }
}