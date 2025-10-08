// 🎯 Diagnóstico Service - iPoupei Mobile
//
// Service principal para gerenciar o diagnóstico financeiro
// Substitui o Provider pattern do offline por service direto
// Integra com LocalDatabase e SyncManager
//
// Responsabilidades: Estado, navegação, persistência

import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../database/local_database.dart';
import '../../../sync/sync_manager.dart';
// import '../../shared/utils/operation_feedback_helper.dart'; // Not available
import '../models/diagnostico_etapa.dart';
import '../models/percepcao_financeira.dart';
import '../models/dividas_model.dart';

/// Service principal para gerenciar o diagnóstico
class DiagnosticoService {
  static DiagnosticoService? _instance;
  static DiagnosticoService get instance {
    _instance ??= DiagnosticoService._internal();
    return _instance!;
  }

  DiagnosticoService._internal();

  // Construtor público para compatibilidade
  factory DiagnosticoService() => instance;

  // Estado atual do diagnóstico
  int _etapaAtual = 0;
  Map<String, dynamic> _dadosColetados = {};
  bool _loading = false;
  bool _isCompleto = false;
  String? _erro;
  String? _userId;

  // Stream controllers para notificar mudanças
  final StreamController<int> _etapaStreamController = StreamController<int>.broadcast();
  final StreamController<Map<String, dynamic>> _dadosStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _loadingStreamController = StreamController<bool>.broadcast();
  final StreamController<String?> _erroStreamController = StreamController<String?>.broadcast();

  // ValueNotifier para compatibilidade com ValueListenableBuilder
  final ValueNotifier<Map<String, dynamic>> statusNotifier = ValueNotifier<Map<String, dynamic>>({});

  // Getters públicos
  int get etapaAtual => _etapaAtual;
  Map<String, dynamic> get dadosColetados => Map.from(_dadosColetados);
  bool get loading => _loading;
  String? get erro => _erro;
  DiagnosticoEtapa get etapaAtualObj => DiagnosticoEtapas.todas[_etapaAtual];
  double get progresso => DiagnosticoEtapas.calcularProgressoPorIndice(_etapaAtual);
  bool get podeAvancar => _validarEtapaAtual();
  bool get podeVoltar => _etapaAtual > 0 && etapaAtualObj.permitirVoltar;

  // Streams para escutar mudanças
  Stream<int> get etapaStream => _etapaStreamController.stream;
  Stream<Map<String, dynamic>> get dadosStream => _dadosStreamController.stream;
  Stream<bool> get loadingStream => _loadingStreamController.stream;
  Stream<String?> get erroStream => _erroStreamController.stream;

  /// Inicializar diagnóstico
  Future<void> inicializar({String? userId}) async {
    try {
      _setLoading(true);
      _setErro(null);

      log('🔄 [DIAGNOSTICO_SERVICE] Iniciando inicialização...');

      // Tentar obter userId
      if (userId != null) {
        log('✅ [DIAGNOSTICO_SERVICE] UserId fornecido: $userId');
        _userId = userId;
      } else {
        log('🔍 [DIAGNOSTICO_SERVICE] Buscando userId automaticamente...');
        _userId = await _getCurrentUserId();
      }

      if (_userId == null || _userId!.isEmpty) {
        final errorMsg = 'Usuário não autenticado ou userId vazio';
        log('❌ [DIAGNOSTICO_SERVICE] $errorMsg');
        throw Exception(errorMsg);
      }

      log('✅ [DIAGNOSTICO_SERVICE] UserId válido obtido: $_userId');

      // Carregar progresso salvo do banco
      await _carregarProgressoSalvo();

      log('✅ [DIAGNOSTICO_SERVICE] Inicializado com sucesso para userId: $_userId');
    } catch (e) {
      log('❌ [DIAGNOSTICO_SERVICE] Erro ao inicializar: $e');
      _setErro(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Carregar progresso salvo do LocalDatabase
  Future<void> _carregarProgressoSalvo() async {
    try {
      // Verificar se temos userId válido
      if (_userId == null || _userId!.isEmpty) {
        log('⚠️ [DIAGNOSTICO_SERVICE] Não há userId válido para carregar progresso salvo');
        return;
      }

      log('🔄 [DIAGNOSTICO_SERVICE] Carregando progresso salvo para userId: $_userId');
      final db = LocalDatabase.instance;

      // Buscar dados do perfil_usuario
      final perfilData = await db.select(
        'perfil_usuario',
        where: 'id = ?',
        whereArgs: [_userId],
      );

      if (perfilData.isNotEmpty) {
        final perfil = perfilData.first;

        // Carregar etapa atual
        _etapaAtual = perfil['diagnostico_etapa_atual'] ?? 0;

        // Carregar dados de percepção se existirem
        if (perfil['sentimento_financeiro'] != null) {
          _dadosColetados['percepcao'] = {
            'sentimento_financeiro': perfil['sentimento_financeiro'],
            'percepcao_controle': perfil['percepcao_controle'],
            'percepcao_gastos': perfil['percepcao_gastos'],
            'disciplina_financeira': perfil['disciplina_financeira'],
            'relacao_dinheiro': perfil['relacao_dinheiro'],
          };
        }

        // Carregar dados de renda
        if (perfil['renda_mensal'] != null) {
          _dadosColetados['receitas'] = {
            'renda_mensal': perfil['renda_mensal'],
            'tipo_renda': perfil['tipo_renda'],
          };
        }
      }

      // Carregar dados de outras etapas (contas, cartões, etc.)
      await _carregarDadosEtapas();

      _notificarMudancas();

    } catch (e) {
      log('❌ [DIAGNOSTICO_SERVICE] Erro ao carregar progresso: $e');
    }
  }

  /// Carregar dados das etapas de cadastro
  Future<void> _carregarDadosEtapas() async {
    try {
      final db = LocalDatabase.instance;

      // Contas
      final contas = await db.select(
        'contas',
        where: 'usuario_id = ? AND ativo = ?',
        whereArgs: [_userId, 1],
      );
      if (contas.isNotEmpty) {
        _dadosColetados['contas'] = {'quantidade': contas.length};
      }

      // Cartões
      final cartoes = await db.select(
        'cartoes',
        where: 'usuario_id = ? AND ativo = ?',
        whereArgs: [_userId, 1],
      );
      if (cartoes.isNotEmpty) {
        _dadosColetados['cartoes'] = {'quantidade': cartoes.length};
      }

      // Categorias
      final categorias = await db.select(
        'categorias',
        where: 'usuario_id = ? AND ativo = ?',
        whereArgs: [_userId, 1],
      );
      if (categorias.isNotEmpty) {
        _dadosColetados['categorias'] = {'quantidade': categorias.length};
      }

      // Receitas
      final receitas = await db.select(
        'transacoes',
        where: 'usuario_id = ? AND tipo = ?',
        whereArgs: [_userId, 'receita'],
      );
      if (receitas.isNotEmpty) {
        _dadosColetados['receitas'] = {
          ...(_dadosColetados['receitas'] ?? {}),
          'quantidade': receitas.length,
        };
      }

      // Despesas
      final despesas = await db.select(
        'transacoes',
        where: 'usuario_id = ? AND tipo = ?',
        whereArgs: [_userId, 'despesa'],
      );
      if (despesas.isNotEmpty) {
        // Separar fixas e variáveis baseado em recorrência
        final fixas = despesas.where((d) => d['recorrente'] == 1).length;
        final variaveis = despesas.length - fixas;

        if (fixas > 0) {
          _dadosColetados['despesas-fixas'] = {'quantidade': fixas};
        }
        if (variaveis > 0) {
          _dadosColetados['despesas-variaveis'] = {'quantidade': variaveis};
        }
      }

      // ✅ CORREÇÃO: Garantir que a etapa intro sempre tenha dados
      if (!_dadosColetados.containsKey('intro')) {
        _dadosColetados['intro'] = {
          'visualizado': true,
          'timestamp': DateTime.now().toIso8601String(),
        };
        log('✅ [DIAGNOSTICO_SERVICE] Dados iniciais da etapa intro criados');
      }

    } catch (e) {
      log('❌ [DIAGNOSTICO_SERVICE] Erro ao carregar dados das etapas: $e');
    }
  }

  /// 📱 NAVEGAÇÃO ENTRE ETAPAS
  /// Avança para próxima etapa (se possível)
  void proximaEtapa() {
    if (!podeAvancar) {
      debugPrint('⚠️ [DIAGNOSTICO] Não pode avançar - etapa atual incompleta');
      return;
    }

    if (_etapaAtual < DiagnosticoEtapas.fluxoCompleto.length - 1) {
      _etapaAtual++;
      salvarProgressoAtual();
      _notificarMudancas();
      debugPrint('➡️ [DIAGNOSTICO] Avançou para etapa $_etapaAtual: ${etapaAtualObj.titulo}');
    }
  }

  /// Volta para etapa anterior (se permitido)
  void voltarEtapa() {
    if (!podeVoltar) {
      debugPrint('⚠️ [DIAGNOSTICO] Não pode voltar da etapa atual');
      return;
    }

    if (_etapaAtual > 0) {
      _etapaAtual--;
      salvarProgressoAtual();
      _notificarMudancas();
      debugPrint('⬅️ [DIAGNOSTICO] Voltou para etapa $_etapaAtual: ${etapaAtualObj.titulo}');
    }
  }

  /// Vai para uma etapa específica (se já foi completada ou é anterior)
  void irParaEtapa(int indice) {
    debugPrint('🎯 [DIAGNOSTICO] irParaEtapa chamado - De $_etapaAtual para $indice');

    if (indice < 0 || indice >= DiagnosticoEtapas.fluxoCompleto.length) {
      debugPrint('⚠️ [DIAGNOSTICO] Índice de etapa inválido: $indice');
      return;
    }

    // Só permite ir para etapas já completadas ou anteriores
    if (indice <= _etapaAtual || _todasEtapasAnterioresCompletas(indice)) {
      final etapaAnterior = _etapaAtual;
      _etapaAtual = indice;
      salvarProgressoAtual();
      _notificarMudancas();
      debugPrint('🎯 [DIAGNOSTICO] Mudou de etapa: $etapaAnterior → $_etapaAtual (${etapaAtualObj.titulo})');
    } else {
      debugPrint('⚠️ [DIAGNOSTICO] Não pode pular para etapa $indice - etapas anteriores incompletas');
    }
  }

  /// Salva dados genéricos para qualquer etapa (aceita Map ou List)
  Future<void> salvarDadosEtapa(String etapaId, dynamic dados) async {
    log('🔥 [DIAGNOSTICO_SERVICE] ===== INÍCIO salvarDadosEtapa =====');
    log('🔥 [DIAGNOSTICO_SERVICE] etapaId: $etapaId');
    log('🔥 [DIAGNOSTICO_SERVICE] dados tipo: ${dados.runtimeType}');
    log('🔥 [DIAGNOSTICO_SERVICE] dados: $dados');

    try {
      _setLoading(true);

      _dadosColetados[etapaId] = dados;
      log('✅ [DIAGNOSTICO_SERVICE] Dados salvos em memória');

      // Salvar no banco baseado no tipo de etapa
      log('🔄 [DIAGNOSTICO_SERVICE] Chamando _salvarDadosNoBanco...');
      await _salvarDadosNoBanco(etapaId, dados);
      log('✅ [DIAGNOSTICO_SERVICE] _salvarDadosNoBanco completado');

      _notificarMudancas();

      log('💾 [DIAGNOSTICO_SERVICE] Dados salvos para etapa: $etapaId');
    } catch (e, stackTrace) {
      log('❌ [DIAGNOSTICO_SERVICE] Erro ao salvar dados: $e');
      log('❌ [DIAGNOSTICO_SERVICE] Stack trace: $stackTrace');
      _setErro(e.toString());
    } finally {
      _setLoading(false);
      log('🔥 [DIAGNOSTICO_SERVICE] ===== FIM salvarDadosEtapa =====');
    }
  }

  /// Salvar dados no banco de acordo com a etapa
  Future<void> _salvarDadosNoBanco(String etapaId, dynamic dados) async {
    final db = LocalDatabase.instance;

    log('💾 [DIAGNOSTICO_SERVICE] Salvando dados da etapa: $etapaId');
    log('👤 [DIAGNOSTICO_SERVICE] User ID: $_userId');
    log('📊 [DIAGNOSTICO_SERVICE] Tipo: ${dados.runtimeType}');
    log('📊 [DIAGNOSTICO_SERVICE] Dados: ${dados.toString()}');

    switch (etapaId) {
      case 'percepcao':
        // Salvar no perfil_usuario (percepção + renda + horas)
        log('💾 [DIAGNOSTICO_SERVICE] Salvando percepção completa no perfil_usuario');
        final updateData = {
          'sentimento_financeiro': dados['sentimento_financeiro'],
          'percepcao_controle': dados['percepcao_controle'],
          'percepcao_gastos': dados['percepcao_gastos'],
          'disciplina_financeira': dados['disciplina_financeira'],
          'relacao_dinheiro': dados['relacao_dinheiro'],
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Adicionar renda e horas se existirem
        if (dados.containsKey('renda_mensal')) {
          updateData['renda_mensal'] = dados['renda_mensal'];
        }
        if (dados.containsKey('tipo_renda')) {
          updateData['tipo_renda'] = dados['tipo_renda'];
        }
        if (dados.containsKey('media_horas_trabalhadas_mes')) {
          updateData['media_horas_trabalhadas_mes'] = dados['media_horas_trabalhadas_mes'];
        }

        log('📝 [DIAGNOSTICO_SERVICE] Dados de percepção a serem atualizados: ${updateData.toString()}');

        final result = await db.update(
          'perfil_usuario',
          updateData,
          where: 'id = ?',
          whereArgs: [_userId],
        );

        log('✅ [DIAGNOSTICO_SERVICE] Percepção completa salva. Linhas afetadas: $result');
        break;

      case 'receitas':
        // Salvar renda no perfil_usuario
        if (dados.containsKey('renda_mensal')) {
          log('💾 [DIAGNOSTICO_SERVICE] Salvando renda no perfil_usuario');
          final updateData = {
            'renda_mensal': dados['renda_mensal'],
            'tipo_renda': dados['tipo_renda'],
            'updated_at': DateTime.now().toIso8601String(),
          };

          log('📝 [DIAGNOSTICO_SERVICE] Dados de renda: ${updateData.toString()}');

          final result = await db.update(
            'perfil_usuario',
            updateData,
            where: 'id = ?',
            whereArgs: [_userId],
          );

          log('✅ [DIAGNOSTICO_SERVICE] Renda salva. Linhas afetadas: $result');
        }
        break;

      case 'renda':
        // Salvar renda mensal no perfil_usuario
        log('💾 [DIAGNOSTICO_SERVICE] Salvando renda mensal no perfil_usuario');
        await db.update(
          'perfil_usuario',
          {
            'renda_mensal': dados,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [_userId],
        );
        break;

      case 'situacao':
        // Salvar situação financeira no perfil_usuario
        log('💾 [DIAGNOSTICO_SERVICE] Salvando situação no perfil_usuario');
        await db.update(
          'perfil_usuario',
          {
            'situacao_fim_mes': dados,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [_userId],
        );
        break;

      case 'horasTrabalhadasMes':
        // Salvar horas trabalhadas no perfil_usuario
        log('💾 [DIAGNOSTICO_SERVICE] Salvando horas trabalhadas no perfil_usuario');
        await db.update(
          'perfil_usuario',
          {
            'media_horas_trabalhadas_mes': dados,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [_userId],
        );
        break;

      case 'dividas':
        // Salvar dívidas como JSON no perfil_usuario
        await db.update(
          'perfil_usuario',
          {
            'dividas_diagnostico': dados.toString(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [_userId],
        );
        break;

      // Para etapas de cadastro (contas, cartões, etc.),
      // os dados já são salvos pelas telas específicas
    }

    // ⚠️ CORREÇÃO CRÍTICA: NÃO salvar progresso da etapa aqui!
    // Isso estava causando o bug de voltar para a etapa anterior
    // O progresso só deve ser salvo quando proximaEtapa() for chamado
    // await _salvarProgressoAtual();  // REMOVIDO

    // Adicionar item à fila de sync para sincronizar com Supabase
    await _adicionarItemFilaSync();
  }

  /// Salvar progresso atual no banco
  Future<void> salvarProgressoAtual() async {
    try {
      // Verificar se temos userId válido
      if (_userId == null || _userId!.isEmpty) {
        log('⚠️ [DIAGNOSTICO_SERVICE] Não é possível salvar progresso: userId inválido');
        return;
      }

      log('💾 [DIAGNOSTICO_SERVICE] Salvando progresso: etapa $_etapaAtual para userId $_userId');
      final db = LocalDatabase.instance;

      await db.update(
        'perfil_usuario',
        {
          'diagnostico_etapa_atual': _etapaAtual,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [_userId],
      );

      log('✅ [DIAGNOSTICO_SERVICE] Progresso salvo com sucesso: etapa $_etapaAtual');

      // Sync direto com Supabase
      await _uploadPerfilUsuarioParaSupabase();

    } catch (e) {
      log('❌ [DIAGNOSTICO_SERVICE] Erro ao salvar progresso: $e');
    }
  }

  /// Sincronizar perfil_usuario diretamente com o Supabase
  Future<void> _adicionarItemFilaSync() async {
    try {
      // Verificar se temos userId válido
      if (_userId == null || _userId!.isEmpty) {
        log('⚠️ [DIAGNOSTICO_SERVICE] Não é possível sincronizar: userId inválido');
        return;
      }

      log('🔄 [DIAGNOSTICO_SERVICE] Sincronizando perfil_usuario diretamente para userId: $_userId');

      // 🚀 UPLOAD DIRETO PARA O SUPABASE
      await _uploadPerfilUsuarioParaSupabase();

      log('✅ [DIAGNOSTICO_SERVICE] Perfil sincronizado diretamente com Supabase');

    } catch (e) {
      log('❌ [DIAGNOSTICO_SERVICE] Erro ao sincronizar perfil: $e');
    }
  }

  /// Upload direto do perfil_usuario para o Supabase
  Future<void> _uploadPerfilUsuarioParaSupabase() async {
    try {
      final db = LocalDatabase.instance;

      // Buscar dados locais do perfil
      final perfilData = await db.select(
        'perfil_usuario',
        where: 'id = ?',
        whereArgs: [_userId],
      );

      if (perfilData.isEmpty) {
        log('❌ [DIAGNOSTICO_SERVICE] Perfil não encontrado localmente');
        return;
      }

      final perfil = Map<String, dynamic>.from(perfilData.first);

      // Remover campos que não devem ser enviados
      perfil.remove('sync_status');
      perfil.remove('last_sync');

      log('📤 [DIAGNOSTICO_SERVICE] Enviando perfil para Supabase: diagnostico_etapa_atual=${perfil['diagnostico_etapa_atual']}');

      // Upload para Supabase
      await Supabase.instance.client
          .from('perfil_usuario')
          .upsert(perfil, onConflict: 'id');

      log('✅ [DIAGNOSTICO_SERVICE] Perfil enviado com sucesso para Supabase');

      // Atualizar status local
      await db.update(
        'perfil_usuario',
        {
          'sync_status': 'synced',
          'last_sync': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [_userId],
      );

    } catch (e) {
      log('❌ [DIAGNOSTICO_SERVICE] Erro no upload direto: $e');
      rethrow;
    }
  }

  /// Carregar progresso do diagnóstico
  Future<Map<String, dynamic>> carregarProgresso() async {
    // Garantir que o serviço está inicializado
    if (_userId == null) {
      final userId = await _getCurrentUserId();
      if (userId != null) {
        _userId = userId;
      }
    }

    // ⚠️ CORREÇÃO: NÃO recarregar se já inicializado (widget sempre mostrava etapa 0)
    // await _carregarProgressoSalvo();
    return {
      'etapa_atual': _etapaAtual,
      'diagnostico_completo': _isCompleto ? 1 : 0,
      'dados_coletados': _dadosColetados,
    };
  }

  /// Carregar dados de percepção
  Future<PercepcaoFinanceira> carregarPercepcao() async {
    if (_dadosColetados.containsKey('percepcao')) {
      final dados = _dadosColetados['percepcao'] as Map<String, dynamic>;
      return PercepcaoFinanceira(
        sentimentoFinanceiro: dados['sentimento_financeiro'],
        percepcaoControle: dados['percepcao_controle'],
        percepcaoGastos: dados['percepcao_gastos'],
        disciplinaFinanceira: dados['disciplina_financeira'],
        relacaoDinheiro: dados['relacao_dinheiro'],
      );
    }
    return PercepcaoFinanceira.vazio();
  }

  /// Carregar dados de dívidas
  Future<List<DividaItem>> carregarDividas() async {
    if (_dadosColetados.containsKey('dividas')) {
      final dados = _dadosColetados['dividas'];

      // Tratar diferentes tipos de dados salvos
      List<dynamic> lista = [];
      if (dados is List) {
        lista = dados;
      } else if (dados is Map<String, dynamic>) {
        // Pode ter uma lista dentro do Map
        if (dados.containsKey('dados')) {
          lista = dados['dados'] as List? ?? [];
        } else if (dados.containsKey('lista')) {
          lista = dados['lista'] as List? ?? [];
        }
      }

      return lista.map((item) => DividaItem.fromMap(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Salvar progresso
  Future<void> salvarProgresso(Map<String, dynamic> progresso) async {
    if (progresso.containsKey('etapa_atual')) {
      _etapaAtual = progresso['etapa_atual'];
    }
    await salvarProgressoAtual();
  }

  /// Salvar dados de percepção
  Future<void> salvarPercepcao(PercepcaoFinanceira percepcao) async {
    _dadosColetados['percepcao'] = {
      'sentimento_financeiro': percepcao.sentimentoFinanceiro,
      'percepcao_controle': percepcao.percepcaoControle,
      'percepcao_gastos': percepcao.percepcaoGastos,
      'disciplina_financeira': percepcao.disciplinaFinanceira,
      'relacao_dinheiro': percepcao.relacaoDinheiro,
    };
    await salvarProgressoAtual();
  }

  /// Salvar dados de dívidas
  Future<void> salvarDividas(List<DividaItem> dividas) async {
    _dadosColetados['dividas'] = dividas.map((item) => item.toMap()).toList();
    await salvarProgressoAtual();
  }

  /// Resetar diagnóstico
  Future<void> resetarDiagnostico() async {
    _etapaAtual = 0;
    _isCompleto = false;
    _dadosColetados.clear();
    await salvarProgressoAtual();
  }

  /// Finalizar diagnóstico
  Future<void> finalizarDiagnostico(Map<String, dynamic> resultado) async {
    try {
      _setLoading(true);

      final db = LocalDatabase.instance;

      await db.update(
        'perfil_usuario',
        {
          'diagnostico_completo': 1,
          'diagnostico_completo_em': DateTime.now().toIso8601String(),
          'diagnostico_etapa_atual': -1, // -1 indica completo
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [_userId],
      );

      // Marcar processamento como completo
      _dadosColetados['processamento_completo'] = true;

      _notificarMudancas();

      log('🎉 [DIAGNOSTICO_SERVICE] Diagnóstico finalizado com sucesso!');

    } catch (e) {
      log('❌ [DIAGNOSTICO_SERVICE] Erro ao finalizar diagnóstico: $e');
      _setErro(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Reiniciar diagnóstico
  Future<void> reiniciar() async {
    try {
      _setLoading(true);

      _etapaAtual = 0;
      _dadosColetados.clear();

      final db = LocalDatabase.instance;

      await db.update(
        'perfil_usuario',
        {
          'diagnostico_etapa_atual': 0,
          'diagnostico_completo': 0,
          'diagnostico_completo_em': null,
          'sentimento_financeiro': null,
          'percepcao_controle': null,
          'percepcao_gastos': null,
          'disciplina_financeira': null,
          'relacao_dinheiro': null,
          'dividas_diagnostico': null,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [_userId],
      );

      _notificarMudancas();

      log('🔄 [DIAGNOSTICO_SERVICE] Diagnóstico reiniciado');

    } catch (e) {
      log('❌ [DIAGNOSTICO_SERVICE] Erro ao reiniciar: $e');
      _setErro(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Verificar se diagnóstico já foi concluído
  Future<bool> isDiagnosticoCompleto() async {
    try {
      final db = LocalDatabase.instance;

      final result = await db.select(
        'perfil_usuario',
        where: 'id = ?',
        whereArgs: [_userId],
      );

      return result.isNotEmpty && (result.first['diagnostico_completo'] == 1);
    } catch (e) {
      log('❌ [DIAGNOSTICO_SERVICE] Erro ao verificar diagnóstico: $e');
      return false;
    }
  }

  /// Obter ID do usuário atual
  Future<String?> _getCurrentUserId() async {
    try {
      // 1. Tentar do LocalDatabase primeiro (mais confiável)
      final localUserId = LocalDatabase.instance.currentUserId;
      if (localUserId != null && localUserId.isNotEmpty) {
        log('✅ [DIAGNOSTICO_SERVICE] User ID do LocalDatabase: $localUserId');
        return localUserId;
      }

      // 2. Fallback para Supabase Auth
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      if (supabaseUser != null && supabaseUser.id.isNotEmpty) {
        log('✅ [DIAGNOSTICO_SERVICE] User ID do Supabase Auth: ${supabaseUser.id}');
        return supabaseUser.id;
      }

      log('❌ [DIAGNOSTICO_SERVICE] Nenhum usuário logado encontrado');
      return null;
    } catch (e) {
      log('❌ [DIAGNOSTICO_SERVICE] Erro ao obter user ID: $e');
      return null;
    }
  }

  /// Contar contas do usuário
  Future<int> contarContas() async {
    try {
      final db = LocalDatabase.instance;
      final result = await db.select(
        'contas',
        where: 'usuario_id = ? AND ativo = 1',
        whereArgs: [_userId],
      );
      return result.length;
    } catch (e) {
      log('❌ [DIAGNOSTICO_SERVICE] Erro ao contar contas: $e');
      return 0;
    }
  }

  /// Contar cartões do usuário
  Future<int> contarCartoes() async {
    try {
      final db = LocalDatabase.instance;
      final result = await db.select(
        'cartoes',
        where: 'usuario_id = ? AND ativo = 1',
        whereArgs: [_userId],
      );
      return result.length;
    } catch (e) {
      log('❌ [DIAGNOSTICO_SERVICE] Erro ao contar cartões: $e');
      return 0;
    }
  }

  /// Contar categorias do usuário
  Future<int> contarCategorias() async {
    try {
      final db = LocalDatabase.instance;
      final result = await db.select(
        'categorias',
        where: 'usuario_id = ? AND ativo = 1',
        whereArgs: [_userId],
      );
      return result.length;
    } catch (e) {
      log('❌ [DIAGNOSTICO_SERVICE] Erro ao contar categorias: $e');
      return 0;
    }
  }

  /// Métodos privados para gerenciar estado
  void _setLoading(bool loading) {
    _loading = loading;
    _loadingStreamController.add(_loading);
    _atualizarStatusNotifier();
  }

  void _setErro(String? erro) {
    _erro = erro;
    _erroStreamController.add(_erro);
    _atualizarStatusNotifier();
  }

  void _notificarMudancas() {
    _etapaStreamController.add(_etapaAtual);
    _dadosStreamController.add(Map.from(_dadosColetados));
    _atualizarStatusNotifier();
  }


  /// 🔍 VALIDAÇÕES
  /// Valida se a etapa atual está completa
  bool _validarEtapaAtual() {
    debugPrint('🎯 [DIAGNOSTICO] Etapa atual: $_etapaAtual (${etapaAtualObj.id})');
    final isCompleta = etapaAtualObj.isCompleta(_dadosColetados);
    debugPrint('🔍 [DIAGNOSTICO] Validação etapa ${etapaAtualObj.id}: $isCompleta');
    debugPrint('🔍 [DIAGNOSTICO] Dados disponíveis: ${_dadosColetados.keys.toList()}');
    if (_dadosColetados.containsKey(etapaAtualObj.id)) {
      debugPrint('🔍 [DIAGNOSTICO] Dados da etapa atual: ${_dadosColetados[etapaAtualObj.id]}');
    } else {
      debugPrint('❌ [DIAGNOSTICO] Dados da etapa ${etapaAtualObj.id} não encontrados!');
    }
    return isCompleta;
  }

  /// Verifica se todas as etapas anteriores estão completas
  bool _todasEtapasAnterioresCompletas(int indiceDestino) {
    for (int i = 0; i < indiceDestino; i++) {
      final etapa = DiagnosticoEtapas.fluxoCompleto[i];
      if (etapa.obrigatorio && !etapa.isCompleta(_dadosColetados)) {
        return false;
      }
    }
    return true;
  }

  /// Atualizar status notifier
  void _atualizarStatusNotifier() {
    statusNotifier.value = {
      'etapaAtual': _etapaAtual,
      'loading': _loading,
      'erro': _erro,
      'progresso': progresso,
      'podeAvancar': podeAvancar,
      'podeVoltar': podeVoltar,
    };
  }

  /// Limpar recursos
  void dispose() {
    _etapaStreamController.close();
    _dadosStreamController.close();
    _loadingStreamController.close();
    _erroStreamController.close();
    statusNotifier.dispose();
  }
}
