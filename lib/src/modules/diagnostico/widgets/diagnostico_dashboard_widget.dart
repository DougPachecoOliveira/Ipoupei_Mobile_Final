// 📊 Diagnóstico Dashboard Widget - iPoupei Mobile
//
// Widget bonito igual ao offline com gradientes e design sofisticado
// Design inspirado no DiagnosticoDashboard.jsx do offline
//
// Visual: Gradientes + sombras + padrões decorativos

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../database/local_database.dart';
import '../../../sync/sync_manager.dart';
import '../services/diagnostico_service.dart';
import '../services/score_calculator.dart';
import '../pages/diagnostico_flow_page.dart';
import '../models/percepcao_financeira.dart';
import '../models/diagnostico_etapa.dart';
import '../../shared/theme/app_colors.dart';

/// Widget bonito do dashboard de diagnóstico
class DiagnosticoDashboardWidget extends StatefulWidget {
  const DiagnosticoDashboardWidget({super.key});

  @override
  State<DiagnosticoDashboardWidget> createState() => _DiagnosticoDashboardWidgetState();
}

class _DiagnosticoDashboardWidgetState extends State<DiagnosticoDashboardWidget>
    with WidgetsBindingObserver {
  final DiagnosticoService _diagnosticoService = DiagnosticoService.instance;
  final ScoreCalculator _scoreCalculator = ScoreCalculator();

  bool _isLoading = true;
  Map<String, dynamic>? _statusDiagnostico;
  RealtimeChannel? _realtimeChannel;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _carregarStatusDiagnostico();
    _setupRealtimeSubscription();
    _setupDailySync();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Configurar escuta de mudanças em tempo real do Supabase
  /// NOTA: Por enquanto, apenas monitora mudanças via lifecycle do app
  void _setupRealtimeSubscription() {
    // Não precisa de Realtime - o widget recarrega quando o app volta ao primeiro plano
    debugPrint('🔔 [DIAGNOSTICO_WIDGET] Modo simples: recarga via app lifecycle');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Recarregar quando o app volta ao primeiro plano
      _carregarStatusDiagnostico();
    }
  }

  /// Carregar status do diagnóstico diretamente do Supabase
  Future<void> _carregarStatusDiagnostico() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🚀 [DIAGNOSTICO_WIDGET_NEW] Carregando status DIRETO do Supabase...');

      final userId = LocalDatabase.instance.currentUserId;
      if (userId == null) {
        debugPrint('⚠️ [DIAGNOSTICO_WIDGET] Usuário não logado');
        setState(() {
          _isLoading = false;
          _statusDiagnostico = null;
        });
        return;
      }

      debugPrint('✅ [DIAGNOSTICO_WIDGET] UserId: $userId');

      // 🎯 BUSCAR DIRETO DO SUPABASE - sem cache local
      debugPrint('🔄 [DIAGNOSTICO_WIDGET_NEW] Chamando buscarDiagnosticoSupabase...');
      debugPrint('🔍 [DIAGNOSTICO_WIDGET_NEW] Service instance: $_diagnosticoService');
      debugPrint('🔍 [DIAGNOSTICO_WIDGET_NEW] Service type: ${_diagnosticoService.runtimeType}');

      Map<String, dynamic>? dadosSupabase;
      try {
        dadosSupabase = await _diagnosticoService.buscarDiagnosticoSupabase();
        debugPrint('🔄 [DIAGNOSTICO_WIDGET_NEW] Resultado: $dadosSupabase');
      } catch (e, stackTrace) {
        debugPrint('❌ [DIAGNOSTICO_WIDGET_NEW] Erro ao chamar método: $e');
        debugPrint('❌ [DIAGNOSTICO_WIDGET_NEW] Stack: $stackTrace');
        dadosSupabase = null;
      }

      if (dadosSupabase == null) {
        debugPrint('⚠️ [DIAGNOSTICO_WIDGET] Nenhum dado encontrado no Supabase - exibindo NOT LOGGED IN');
        setState(() {
          _isLoading = false;
          _statusDiagnostico = null;
        });
        return;
      }

      debugPrint('✅ [DIAGNOSTICO_WIDGET] Dados do Supabase: $dadosSupabase');
      debugPrint('🔥 [DIAGNOSTICO_WIDGET] *** HOT RELOAD FORÇADO *** NOVA VERSÃO CORRIGIDA');

      final diagnosticoCompleto = dadosSupabase['completo'] ?? false;
      final etapaAtual = dadosSupabase['etapa_atual'] ?? 0;
      final resultadoJson = dadosSupabase['resultado'];

      debugPrint('🎯 [DIAGNOSTICO_WIDGET] DADOS EXTRAÍDOS -> completo: $diagnosticoCompleto, etapa: $etapaAtual');

      // Parse do resultado JSON se existir
      Map<String, dynamic>? resultado;
      if (resultadoJson != null && resultadoJson is Map) {
        resultado = Map<String, dynamic>.from(resultadoJson);
        debugPrint('✅ [DIAGNOSTICO_WIDGET] Score do Supabase: ${resultado['score_total']}');
      } else if (resultadoJson != null && resultadoJson is String) {
        try {
          resultado = Map<String, dynamic>.from(
            json.decode(resultadoJson)
          );
          debugPrint('✅ [DIAGNOSTICO_WIDGET] Score do Supabase (JSON string): ${resultado?['score_total']}');
        } catch (e) {
          debugPrint('⚠️ [DIAGNOSTICO_WIDGET] Erro ao parse do resultado JSON: $e');
        }
      }

      debugPrint('📊 [DIAGNOSTICO_WIDGET] Status final:');
      debugPrint('📊 [DIAGNOSTICO_WIDGET] - etapaAtual: $etapaAtual');
      debugPrint('📊 [DIAGNOSTICO_WIDGET] - diagnosticoCompleto: $diagnosticoCompleto');
      debugPrint('📊 [DIAGNOSTICO_WIDGET] - resultado: $resultado');

      if (mounted) {
        setState(() {
          _statusDiagnostico = {
            'etapa_atual': etapaAtual,
            'completo': diagnosticoCompleto,
            'resultado': resultado,
          };
          _isLoading = false;
        });

        debugPrint('✅ [DIAGNOSTICO_WIDGET] Status atualizado com dados do Supabase');
        debugPrint('✅ [DIAGNOSTICO_WIDGET] Widget irá mostrar: ${diagnosticoCompleto ? "COMPLETED CARD 🎉" : "IN PROGRESS CARD (etapa ${etapaAtual + 1})"}');
      }
    } catch (e) {
      debugPrint('❌ [DIAGNOSTICO_WIDGET] Erro ao carregar do Supabase: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Método público para recarregar o status
  void recarregar() {
    debugPrint('🔄 [DIAGNOSTICO_WIDGET] Recarga manual solicitada');
    _carregarStatusDiagnostico();
  }

  /// Método público para forçar finalização do diagnóstico (DEBUG)
  Future<void> forcarFinalizacao() async {
    debugPrint('🔧 [DIAGNOSTICO_WIDGET] FORÇANDO FINALIZAÇÃO MANUAL...');
    try {
      setState(() => _isLoading = true);

      // Forçar finalização
      await _diagnosticoService.proximaEtapa();

      // Recarregar dados
      await _carregarStatusDiagnostico();

      debugPrint('✅ [DIAGNOSTICO_WIDGET] Finalização forçada concluída');
    } catch (e) {
      debugPrint('❌ [DIAGNOSTICO_WIDGET] Erro ao forçar finalização: $e');
    }
  }

  /// Método público para forçar sync manual com Supabase
  Future<void> forcarSync() async {
    debugPrint('🔄 [DIAGNOSTICO_WIDGET] Sync manual forçado');
    try {
      setState(() => _isLoading = true);

      // Sincronizar com Supabase
      await SyncManager.instance.syncPerfilUsuario(force: true);

      // Recarregar dados
      await _carregarStatusDiagnostico();

      // Atualizar timestamp da última sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('diagnostico_last_sync', DateTime.now().millisecondsSinceEpoch);

      debugPrint('✅ [DIAGNOSTICO_WIDGET] Sync manual concluído');
    } catch (e) {
      debugPrint('❌ [DIAGNOSTICO_WIDGET] Erro no sync manual: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 [DIAGNOSTICO_WIDGET] ===== BUILD DEBUG =====');
    debugPrint('🎨 [DIAGNOSTICO_WIDGET] _isLoading: $_isLoading');
    debugPrint('🎨 [DIAGNOSTICO_WIDGET] _statusDiagnostico: $_statusDiagnostico');

    if (_isLoading) {
      debugPrint('🎨 [DIAGNOSTICO_WIDGET] Renderizando LOADING');
      return _buildLoadingCard();
    }

    if (_statusDiagnostico == null) {
      debugPrint('🎨 [DIAGNOSTICO_WIDGET] Renderizando NOT LOGGED IN');
      return _buildNotLoggedInCard();
    }

    final completo = _statusDiagnostico!['completo'] ?? false;
    debugPrint('🎨 [DIAGNOSTICO_WIDGET] Status completo: $completo');

    if (completo) {
      debugPrint('🎨 [DIAGNOSTICO_WIDGET] Renderizando COMPLETED CARD 🎉');
      return _buildCompletedCard();
    } else {
      debugPrint('🎨 [DIAGNOSTICO_WIDGET] Renderizando IN PROGRESS CARD');
      return _buildInProgressCard();
    }
  }

  /// Card de loading bonito
  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFf9fafb),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFe5e7eb)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF008080),
            ),
            SizedBox(height: 12),
            Text(
              'Carregando diagnóstico...',
              style: TextStyle(
                color: Color(0xFF6b7280),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card quando não logado
  Widget _buildNotLoggedInCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFf9fafb),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFe5e7eb)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.login,
              color: Color(0xFF6b7280),
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Entre para acessar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1f2937),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Faça login para ver seu diagnóstico',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6b7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Card bonito quando em progresso
  Widget _buildInProgressCard() {
    final etapaAtual = _statusDiagnostico!['etapa_atual'] ?? 0;
    final totalEtapas = DiagnosticoEtapas.fluxoCompleto.length; // Total dinâmico de etapas
    final progresso = ((etapaAtual + 1) / totalEtapas * 100).round().clamp(0, 100);

    return GestureDetector(
      onTap: _abrirDiagnostico,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.tealPrimary, Color(0xFF0F766E)], // Tons de teal
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.tealPrimary.withAlpha(78),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Círculos decorativos
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(26),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(12),
                ),
              ),
            ),

            // Conteúdo principal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com ícone
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(52),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Diagnóstico Financeiro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(52),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$progresso%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Progresso
                  Text(
                    'Etapa ${etapaAtual + 1} de $totalEtapas',
                    style: TextStyle(
                      color: Colors.white.withAlpha(208),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Barra de progresso
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(52),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progresso / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Call to action
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Continuar Diagnóstico',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.tealPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card bonito quando completo
  Widget _buildCompletedCard() {
    final resultado = _statusDiagnostico!['resultado'];
    final score = resultado?['score_total'] ?? 0;
    final valorHora = resultado?['valor_hora'] ?? 0.0;

    // 🔍 DEBUG: Print do score que está sendo exibido no widget
    debugPrint('🎯 [WIDGET_DASHBOARD] ===== SCORE DEBUG =====');
    debugPrint('🎯 [WIDGET_DASHBOARD] Score exibido no widget: $score');
    debugPrint('🎯 [WIDGET_DASHBOARD] Resultado completo: $resultado');
    debugPrint('🎯 [WIDGET_DASHBOARD] Status diagnóstico: $_statusDiagnostico');
    debugPrint('🎯 [WIDGET_DASHBOARD] ===== FIM SCORE DEBUG =====');

    return GestureDetector(
      onTap: _verResultados,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)], // Azul festivo
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withAlpha(78), // Sombra azul
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Círculos decorativos
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(26),
                ),
              ),
            ),

            // Conteúdo principal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header festivo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(52),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.celebration,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '🎉 Parabéns!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Diagnóstico 100% Completo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Score e Valor da Hora
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Seu Score: ',
                            style: TextStyle(
                              color: Colors.white.withAlpha(208),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '$score/100',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (valorHora > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Valor/Hora: ',
                              style: TextStyle(
                                color: Colors.white.withAlpha(208),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'R\$ ${valorHora.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Botões de ação
                  Row(
                    children: [
                      // Botão Ver Detalhes
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Ver Detalhes',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.tealPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Botão Refazer
                      GestureDetector(
                        onTap: _refazerDiagnostico,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(52),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Abrir diagnóstico
  void _abrirDiagnostico() async {
    // Navegar para o diagnóstico e ESPERAR ele fechar
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DiagnosticoFlowPage(),
      ),
    );

    // Quando voltar, RECARREGAR o widget!
    debugPrint('🔄 [DIAGNOSTICO_WIDGET] Voltou do diagnóstico - recarregando...');
    _carregarStatusDiagnostico();
  }

  /// Ver resultados
  void _verResultados() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DiagnosticoFlowPage(),
      ),
    );
  }

  /// 🕐 Configurar sync automático diário
  void _setupDailySync() async {
    try {
      // Verificar se já passou mais de 1 dia desde última sync
      await _checkAndPerformDailySync();

      // Configurar timer para verificar a cada hora se precisa sync
      _syncTimer = Timer.periodic(const Duration(hours: 1), (timer) {
        _checkAndPerformDailySync();
      });

      debugPrint('⏰ [DIAGNOSTICO_WIDGET] Sync diário configurado');
    } catch (e) {
      debugPrint('❌ [DIAGNOSTICO_WIDGET] Erro ao configurar sync diário: $e');
    }
  }

  /// Verificar e realizar sync diário se necessário
  Future<void> _checkAndPerformDailySync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncKey = 'diagnostico_last_sync';
      final lastSync = prefs.getInt(lastSyncKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Se passou mais de 24 horas (86400000 ms), fazer sync
      if (now - lastSync > 86400000) {
        debugPrint('🔄 [DIAGNOSTICO_WIDGET] Realizando sync diário automático...');

        try {
          // Sincronizar dados de perfil_usuario com Supabase
          await SyncManager.instance.syncPerfilUsuario(force: true);
          debugPrint('✅ [DIAGNOSTICO_WIDGET] Sync com Supabase concluído');
        } catch (e) {
          debugPrint('⚠️ [DIAGNOSTICO_WIDGET] Erro no sync com Supabase: $e');
        }

        // Recarregar dados do banco forçando refresh
        if (mounted) {
          _carregarStatusDiagnostico();
        }

        // Salvar timestamp da última sync
        await prefs.setInt(lastSyncKey, now);
        debugPrint('✅ [DIAGNOSTICO_WIDGET] Sync diário concluído');
      }
    } catch (e) {
      debugPrint('❌ [DIAGNOSTICO_WIDGET] Erro no sync diário: $e');
    }
  }

  /// Refazer diagnóstico
  Future<void> _refazerDiagnostico() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refazer Diagnóstico'),
        content: const Text(
          'Tem certeza que deseja refazer o diagnóstico?\n\n'
          'Todos os dados coletados serão apagados e você começará do início.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Refazer'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        // Reiniciar diagnóstico
        await _diagnosticoService.reiniciar();

        // Recarregar status
        await _carregarStatusDiagnostico();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Diagnóstico reiniciado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navegar para diagnóstico
          _abrirDiagnostico();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro ao reiniciar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}