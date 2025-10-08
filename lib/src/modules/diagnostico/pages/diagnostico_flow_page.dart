// lib/modules/diagnostico/pages/diagnostico_flow_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_colors.dart';
import '../../../shared/components/ui/loading_widget.dart';
import '../../../database/local_database.dart';
import '../models/diagnostico_etapa.dart';
import '../services/diagnostico_service.dart';
import '../widgets/diagnostico_header.dart';
import '../widgets/diagnostico_navigation.dart';
import '../widgets/etapa_wrapper.dart';

/// Página principal do fluxo de diagnóstico financeiro
/// RESPONSABILIDADES: Navegação via PageView + coordenação entre Service e UI
class DiagnosticoFlowPage extends StatefulWidget {
  /// Etapa específica para iniciar (opcional)
  final String? etapaInicial;

  const DiagnosticoFlowPage({
    super.key,
    this.etapaInicial,
  });

  @override
  State<DiagnosticoFlowPage> createState() => _DiagnosticoFlowPageState();
}

class _DiagnosticoFlowPageState extends State<DiagnosticoFlowPage> {
  // 📄 NAVEGAÇÃO
  late PageController _pageController;
  bool _isPageChanging = false;
  bool _isLoading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _inicializarDiagnostico();
  }

  /// Inicializa o diagnóstico e vai para etapa específica se necessário
  Future<void> _inicializarDiagnostico() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      // Usar mounted check para evitar problemas de contexto
      if (!mounted) return;

      final service = DiagnosticoService.instance;

      // Inicializar service
      await service.inicializar();

      // Se foi passada etapa inicial específica, navegar para ela
      if (widget.etapaInicial != null && mounted) {
        final indice = DiagnosticoEtapas.getIndiceEtapa(widget.etapaInicial!);
        if (indice != -1) {
          service.irParaEtapa(indice);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _pageController.jumpToPage(indice);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [DIAGNOSTICO_FLOW] Erro ao inicializar: $e');
      setState(() {
        _erro = 'Erro ao carregar diagnóstico: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      body: ValueListenableBuilder<Map<String, dynamic>>(
        valueListenable: DiagnosticoService.instance.statusNotifier,
        builder: (context, status, child) {
          try {
            // Estado de loading
            if (_isLoading) {
              return _buildLoadingState();
            }

            // Estado de erro
            if (_erro != null) {
              return _buildErrorState(_erro!);
            }

            // Fluxo principal
            return _buildMainFlow();
          } catch (e) {
            debugPrint('❌ [DIAGNOSTICO_FLOW] Erro no build: $e');
            return _buildGenericErrorState();
          }
        },
      ),
    );
  }

  /// Constrói estado de loading
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingWidget(size: 48),
          SizedBox(height: 16),
          Text(
            'Carregando diagnóstico...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.cinzaTexto,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói estado de erro
  Widget _buildErrorState(String erro) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.vermelhoErro.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.vermelhoErro,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ops! Algo deu errado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.cinzaEscuro,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              erro,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.cinzaTexto,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _inicializarDiagnostico(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulHeader,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói fluxo principal do diagnóstico
  Widget _buildMainFlow() {
    final service = DiagnosticoService.instance;

    // Debug detalhado da sincronização
    debugPrint('🔄 [FLOW] _buildMainFlow - Service etapa: ${service.etapaAtual} (${service.etapaAtualObj.id})');

    // Sincronizar PageView com service se necessário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        final currentPage = _pageController.page?.round() ?? 0;
        debugPrint('🔄 [FLOW] PostFrame - PageView página: $currentPage, Service etapa: ${service.etapaAtual}');

        if (currentPage != service.etapaAtual && !_isPageChanging) {
          debugPrint('🔄 [FLOW] DESSINCRONIA DETECTADA! Sincronizando PageView: página $currentPage → etapa ${service.etapaAtual}');
          _pageController.jumpToPage(service.etapaAtual);
        } else if (currentPage == service.etapaAtual) {
          debugPrint('✅ [FLOW] PageView e Service sincronizados na etapa $currentPage');
        }
      } else {
        debugPrint('⚠️ [FLOW] PageController não disponível para sincronização');
      }
    });

    return Column(
      children: [
        // Header com progresso
        DiagnosticoHeader(
          etapaAtual: service.etapaAtualObj,
          progresso: service.progresso,
          onBack: _podeVoltar() ? () => _voltarEtapa() : null,
          onClose: () => _confirmarFechar(context),
        ),

        // PageView com as etapas
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Bloqueia swipe manual
            itemCount: DiagnosticoEtapas.fluxoCompleto.length,
            onPageChanged: (index) => _onPageChanged(index),
            itemBuilder: (context, index) => _buildEtapa(
              DiagnosticoEtapas.fluxoCompleto[index],
            ),
          ),
        ),

        // Navegação inferior (ocultar na tela de resultado)
        if (service.etapaAtualObj.id != 'resultado')
          DiagnosticoNavigation(
            etapaAtual: service.etapaAtualObj,
            podeVoltar: _podeVoltar(),
            podeContinuar: _podeContinuar(),
            onVoltar: () => _voltarEtapa(),
            onContinuar: () => _proximaEtapa(),
            onPular: service.etapaAtualObj.permitirPular ? () => _pularEtapa() : null,
          ),
      ],
    );
  }

  /// Constrói uma etapa específica
  Widget _buildEtapa(DiagnosticoEtapa etapa) {
    final service = DiagnosticoService.instance;
    return EtapaWrapper(
      etapa: etapa,
      dadosColetados: service.dadosColetados,
      onDadosChanged: (dados) => _onDadosChanged(etapa, dados),
    );
  }

  /// Constrói estado de erro genérico
  Widget _buildGenericErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.vermelhoErro.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.vermelhoErro,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ops! Algo deu errado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.cinzaEscuro,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar o diagnóstico. Tente novamente em alguns instantes.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.cinzaTexto,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.cinzaTexto,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Tentar recarregar a página
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const DiagnosticoFlowPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔄 CONTROLE DE NAVEGAÇÃO
  /// Chamado quando PageView muda de página
  void _onPageChanged(int index) {
    final service = DiagnosticoService.instance;

    debugPrint('📄 [FLOW] _onPageChanged chamado - Nova página: $index, Service etapa: ${service.etapaAtual}, _isPageChanging: $_isPageChanging');

    if (_isPageChanging) {
      debugPrint('🔄 [FLOW] Ignorando _onPageChanged - página em mudança programática');
      return; // Evita loops
    }

    // Sincronizar service apenas se necessário
    if (service.etapaAtual != index) {
      debugPrint('🔄 [FLOW] Sincronizando Service: etapa ${service.etapaAtual} → $index');
      service.irParaEtapa(index);
    } else {
      debugPrint('✅ [FLOW] Service já está na etapa correta: $index');
    }
  }

  /// Avança para próxima etapa
  Future<void> _proximaEtapa() async {
    final service = DiagnosticoService.instance;

    if (!_podeContinuar()) {
      _mostrarErroValidacao();
      return;
    }

    _isPageChanging = true;

    try {
      // Avançar no service
      service.proximaEtapa();

      // Animar PageView
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

    } catch (e) {
      debugPrint('❌ [FLOW] Erro ao avançar etapa: $e');
      _mostrarErroGenerico();
    } finally {
      _isPageChanging = false;
    }
  }

  /// Volta para etapa anterior
  Future<void> _voltarEtapa() async {
    final service = DiagnosticoService.instance;

    if (!_podeVoltar()) return;

    _isPageChanging = true;

    try {
      // Voltar no service
      service.voltarEtapa();

      // Animar PageView
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

    } catch (e) {
      debugPrint('❌ [FLOW] Erro ao voltar etapa: $e');
    } finally {
      _isPageChanging = false;
    }
  }

  /// Pula etapa atual (se permitido)
  Future<void> _pularEtapa() async {
    final service = DiagnosticoService.instance;
    final etapa = service.etapaAtualObj;

    // Confirmar com usuário
    final confirmar = await _confirmarPularEtapa(etapa);
    if (!confirmar) return;

    // Mesmo fluxo de próxima etapa
    await _proximaEtapa();
  }

  /// Chamado quando dados de uma etapa mudam
  void _onDadosChanged(DiagnosticoEtapa etapa, Map<String, dynamic> dados) {
    final service = DiagnosticoService.instance;

    debugPrint('🚀 [DIAGNOSTICO_FLOW] *** onDadosChanged CHAMADO! ***');
    debugPrint('🔄 [DIAGNOSTICO_FLOW] Dados recebidos para ${etapa.id}: $dados');
    debugPrint('🔄 [DIAGNOSTICO_FLOW] Service etapa atual ANTES de salvar: ${service.etapaAtual} (${service.etapaAtualObj.id})');

    // Salvar dados no service baseado no tipo de etapa
    switch (etapa.id) {
      case 'categorias':
        // Para categorias, usar método específico se existir
        if (dados.containsKey('categorias')) {
          service.salvarDadosEtapa('categorias', dados['categorias']);
        }
        break;
      case 'percepcao':
        // dados contém Map da percepção, salvar usando método genérico
        if (dados.containsKey('percepcao')) {
          service.salvarDadosEtapa('percepcao', dados['percepcao']);
        }
        break;
      case 'contas':
        // Usar método genérico para aceitar qualquer tipo de dados
        if (dados.containsKey('contas')) {
          service.salvarDadosEtapa('contas', dados['contas']);
        }
        break;
      case 'cartoes':
        // Usar método genérico para aceitar qualquer tipo de dados
        if (dados.containsKey('cartoes')) {
          service.salvarDadosEtapa('cartoes', dados['cartoes']);
        }
        break;
      case 'receitas':
        // Usar método genérico para aceitar qualquer tipo de dados
        if (dados.containsKey('receitas')) {
          service.salvarDadosEtapa('receitas', dados['receitas']);
        }
        break;
      case 'despesas-fixas':
        // Usar método genérico para aceitar qualquer tipo de dados
        if (dados.containsKey('despesas-fixas')) {
          service.salvarDadosEtapa('despesas-fixas', dados['despesas-fixas']);
        }
        break;
      case 'despesas-variaveis':
        // Usar método genérico para aceitar qualquer tipo de dados
        if (dados.containsKey('despesas-variaveis')) {
          service.salvarDadosEtapa('despesas-variaveis', dados['despesas-variaveis']);
        }
        break;
      case 'dividas':
        if (dados.containsKey('dividas')) {
          service.salvarDadosEtapa('dividas', dados['dividas']);
        }
        break;
      case 'renda':
        // Dados de renda incluem: renda, situacao e horasTrabalhadasMes
        if (dados.containsKey('renda') && dados.containsKey('situacao') && dados.containsKey('horasTrabalhadasMes')) {
          service.salvarDadosEtapa('renda', dados['renda']);
          service.salvarDadosEtapa('situacao', dados['situacao']);
          service.salvarDadosEtapa('horasTrabalhadasMes', dados['horasTrabalhadasMes']);
        }
        break;
    }

    debugPrint('🔄 [DIAGNOSTICO_FLOW] Service etapa atual DEPOIS de salvar: ${service.etapaAtual} (${service.etapaAtualObj.id})');
    debugPrint('🔄 [DIAGNOSTICO_FLOW] Service pode avançar: ${service.podeAvancar}');
  }

  /// 🔍 VALIDAÇÕES DE NAVEGAÇÃO
  bool _podeVoltar() {
    return DiagnosticoService.instance.podeVoltar;
  }

  bool _podeContinuar() {
    return DiagnosticoService.instance.podeAvancar;
  }

  /// 🔔 FEEDBACKS PARA USUÁRIO
  void _mostrarErroValidacao() {
    final service = DiagnosticoService.instance;
    final etapa = service.etapaAtualObj;
    final mensagem = etapa.getMensagemErro(service.dadosColetados) ??
                     'Complete os campos obrigatórios desta etapa';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: AppColors.vermelhoErro,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _mostrarErroGenerico() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ops! Algo deu errado. Tente novamente.'),
        backgroundColor: AppColors.vermelhoErro,
      ),
    );
  }

  /// 💬 DIÁLOGOS DE CONFIRMAÇÃO
  Future<bool> _confirmarPularEtapa(DiagnosticoEtapa etapa) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pular Etapa'),
        content: Text(
          'Tem certeza que deseja pular "${etapa.titulo}"?\n\n'
          'Você pode voltar depois se precisar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.amareloAlerta,
            ),
            child: const Text('Pular'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _confirmarFechar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Diagnóstico'),
        content: const Text(
          'Tem certeza que deseja sair?\n\n'
          'Seu progresso será salvo e você poderá continuar depois.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.vermelhoErro,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmar && mounted) {
      // Salvar progresso no Supabase E no banco local antes de sair
      try {
        final service = DiagnosticoService.instance;
        final etapaAtual = service.etapaAtual;

        debugPrint('💾 [FLOW] Salvando etapa $etapaAtual...');

        // Pegar o userId do Supabase
        final userId = Supabase.instance.client.auth.currentUser?.id;

        if (userId == null) {
          throw Exception('Usuário não autenticado');
        }

        // 1. SALVAR NO BANCO LOCAL
        debugPrint('💾 [FLOW] Salvando no banco local...');
        await LocalDatabase.instance.update(
          'perfil_usuario',
          {
            'diagnostico_etapa_atual': etapaAtual,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [userId],
        );
        debugPrint('✅ [FLOW] Salvo no banco local!');

        // 2. SALVAR NO SUPABASE
        debugPrint('💾 [FLOW] Salvando no Supabase...');
        await Supabase.instance.client
            .from('perfil_usuario')
            .update({
              'diagnostico_etapa_atual': etapaAtual,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);

        debugPrint('✅ [FLOW] Etapa $etapaAtual salva no Supabase e banco local!');
      } catch (e) {
        debugPrint('❌ [FLOW] Erro ao salvar: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aviso: não foi possível salvar o progresso'),
              backgroundColor: AppColors.amareloAlerta,
            ),
          );
        }
      }

      // Fechar a tela
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

/// Widget para casos especiais de navegação
class DiagnosticoFlowPageRoute {
  /// Navega para o diagnóstico a partir de uma etapa específica
  static void irParaEtapa(BuildContext context, String etapaId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiagnosticoFlowPage(etapaInicial: etapaId),
      ),
    );
  }

  /// Navega para o diagnóstico do início
  static void iniciarDiagnostico(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DiagnosticoFlowPage(),
      ),
    );
  }

  /// Navega para o diagnóstico substituindo a rota atual
  static void substituirPorDiagnostico(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const DiagnosticoFlowPage(),
      ),
    );
  }
}