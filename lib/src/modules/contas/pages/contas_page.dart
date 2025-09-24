// 🏦 Contas Page - iPoupei Mobile
// 
// Página principal para listagem de contas
// Design atualizado com faixa lateral colorida
// Funcionalidades completas de CRUD
// 
// Baseado em: Material Design + Navigation Pattern

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/conta_model.dart';
import '../services/conta_service.dart';
import 'conta_form_page.dart';
import 'correcao_saldo_page.dart';
import 'gestao_conta_page.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/responsive_sizes.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../../shared/components/ui/loading_widget.dart';
import '../../../shared/components/ui/app_error_widget.dart';
import '../../../shared/components/ui/app_button.dart';
import '../../../shared/components/ui/app_text.dart';
import '../../../sync/sync_manager.dart';
import '../../relatorios/pages/relatorios_page.dart';
import '../../../routes/main_navigation.dart';

class ContasPage extends StatefulWidget {
  const ContasPage({super.key});

  @override
  State<ContasPage> createState() => _ContasPageState();
}

class _ContasPageState extends State<ContasPage> {
  // === FUNCIONALIDADE 100% DO ORIGINAL ===
  final _contaService = ContaService.instance;
  
  List<ContaModel> _contas = [];
  List<ContaModel> _contasArquivadas = [];
  bool _loading = false;
  bool _mostrarArquivadas = false;
  double _saldoTotal = 0.0;

  // === VISUAL DO TESTE 1 ===
  String _viewMode = 'consolidado'; // consolidado, mini
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarContas();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 🔄 FORÇA SYNC + REFRESH INTELIGENTE APÓS OPERAÇÕES CRÍTICAS
  Future<void> _forcarSyncERefresh(String operacao) async {
    try {
      // 1. Força sync imediato
      await SyncManager.instance.syncAll();
      
      // 2. Aguarda um pouco para garantir processamento
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // 3. Força refresh com dados do Supabase
      await _contaService.forcarResync();
      
      // 4. Aguarda mais um pouco para sincronização completa
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // 5. Recarrega a interface
      await _carregarContas();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $operacao sincronizada com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
      
    } catch (e) {
      debugPrint('❌ Erro no sync após $operacao: $e');
      
      // Fallback: pelo menos recarrega local
      await _carregarContas();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ $operacao salva localmente, sincronizando em background'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 🔄 CARREGAR CONTAS (funcionalidade original)
  Future<void> _carregarContas() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    
    try {
      // Buscar contas ativas
      final contas = await _contaService.fetchContas();
      final contasAtivas = contas.where((c) => c.ativo).toList();
      final contasArquivadas = contas.where((c) => !c.ativo).toList();
      
      // Buscar saldo total
      final saldoTotal = await _contaService.getSaldoTotal();
      
      setState(() {
        _contas = contasAtivas;
        _contasArquivadas = contasArquivadas;
        _saldoTotal = saldoTotal;
        _loading = false;
      });
      
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar contas: $e';
        _loading = false;
      });
    }
  }

  /// 📊 CALCULAR PENDENTES DO MÊS CORRENTE
  Future<double> _calcularPendentesDoMes() async {
    try {
      // Pegar primeiro e último dia do mês atual
      final hoje = DateTime.now();
      final primeiroDiaMes = DateTime(hoje.year, hoje.month, 1);
      final ultimoDiaMes = DateTime(hoje.year, hoje.month + 1, 0);
      
      // Simulação de pendentes para demonstração
      // TODO: Implementar busca real das transações pendentes do mês
      // Exemplo: SELECT SUM(valor) FROM transacoes WHERE data_vencimento BETWEEN primeiroDiaMes AND ultimoDiaMes AND status = 'pendente'
      
      // Simulando algumas pendências para demonstrar o funcionamento:
      final pendentesSimulados = [
        1200.00, // Aluguel
        450.50,  // Cartão
        89.90,   // Internet
        234.67,  // Luz
      ];
      
      return pendentesSimulados.fold<double>(0.0, (sum, valor) => sum + valor); // 1975.07
    } catch (e) {
      print('Erro ao calcular pendentes: $e');
      return 0.0;
    }
  }

  /// 🧹 LIMPAR QUEUE DE SYNC (funcionalidade original)
  Future<void> _limparQueueSync() async {
    try {
      setState(() => _loading = true);
      
      await SyncManager.instance.clearSyncQueue();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Queue de sync limpa com sucesso!'),
            backgroundColor: AppColors.verdeSucesso,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao limpar queue: $e'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /// ➕ NAVEGAR PARA CRIAR CONTA (funcionalidade original)
  void _navegarParaCriarConta() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const ContaFormPage(modo: 'criar'),
      ),
    );
    
    if (resultado == true) {
      _carregarContas();
    }
  }

  /// ✏️ NAVEGAR PARA EDITAR CONTA (funcionalidade original)
  void _navegarParaGestaoCompleta(ContaModel conta) async {
    final bool? precisaAtualizar = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => GestaoContaPage(conta: conta),
      ),
    );
    
    // 🔄 RECARREGAR DADOS QUANDO VOLTAR DA GESTÃO
    // (sempre recarrega para garantir sincronização com gráficos)
    if (precisaAtualizar == true || precisaAtualizar == null) {
      _carregarContas();
    }
  }

  void _navegarParaEditarConta(ContaModel conta) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ContaFormPage(modo: 'editar', conta: conta),
      ),
    );
    
    if (resultado == true) {
      _carregarContas();
    }
  }

  /// 🔧 NAVEGAR PARA CORREÇÃO DE SALDO (funcionalidade original)
  void _navegarParaCorrecaoSaldo(ContaModel conta) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CorrecaoSaldoPage(conta: conta),
      ),
    );
    
    if (resultado == true) {
      _carregarContas();
    }
  }

  /// 📂 VER CONTAS ARQUIVADAS (funcionalidade original)
  void _verContasArquivadas() {
    setState(() {
      _mostrarArquivadas = !_mostrarArquivadas;
    });
  }

  /// 🎯 CRIAR DADOS DEMO (funcionalidade original)
  Future<void> _criarDadosDemo() async {
    try {
      setState(() => _loading = true);

      // Criar múltiplas contas demo para demonstração
      final contasDemo = [
        {
          'nome': 'Conta Corrente Itaú',
          'tipo': 'corrente',
          'banco': 'Itaú',
          'saldoInicial': 2500.0,
          'cor': '#FF6B00',
        },
        {
          'nome': 'Poupança Caixa',
          'tipo': 'poupanca',
          'banco': 'Caixa Econômica',
          'saldoInicial': 1800.0,
          'cor': '#0066CC',
        },
        {
          'nome': 'Carteira Digital',
          'tipo': 'carteira',
          'banco': 'PicPay',
          'saldoInicial': 150.0,
          'cor': '#21C25E',
        },
      ];

      for (final conta in contasDemo) {
        await _contaService.addConta(
          nome: conta['nome'] as String,
          tipo: conta['tipo'] as String,
          banco: conta['banco'] as String,
          saldoInicial: conta['saldoInicial'] as double,
          cor: conta['cor'] as String,
        );
      }

      await _carregarContas();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contas demo criadas com sucesso!'),
            backgroundColor: AppColors.verdeSucesso,
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar dados demo: $e'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 🏦 NAVEGAR PARA CONTAS POPULARES (versão simples - 3 contas básicas)
  Future<void> _navegarParaContasPopulares() async {
    try {
      setState(() => _loading = true);

      // Criar os 3 tipos básicos de conta que todo mundo precisa
      final contasBasicas = [
        {
          'nome': 'Conta Corrente',
          'tipo': 'corrente',
          'banco': 'Banco Principal',
          'saldoInicial': 0.0,
          'cor': '#2196F3', // Azul para corrente
        },
        {
          'nome': 'Carteira',
          'tipo': 'carteira',
          'banco': 'Dinheiro Físico',
          'saldoInicial': 0.0,
          'cor': '#4CAF50', // Verde para carteira
        },
        {
          'nome': 'Poupança',
          'tipo': 'poupanca',
          'banco': 'Reserva de Emergência',
          'saldoInicial': 0.0,
          'cor': '#FF9800', // Laranja para poupança
        },
      ];

      for (final conta in contasBasicas) {
        await _contaService.addConta(
          nome: conta['nome'] as String,
          tipo: conta['tipo'] as String,
          banco: conta['banco'] as String,
          saldoInicial: conta['saldoInicial'] as double,
          cor: conta['cor'] as String,
        );
      }

      await _carregarContas();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contas básicas criadas: Corrente, Carteira e Poupança!'),
            backgroundColor: AppColors.verdeSucesso,
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar contas básicas: $e'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }


  /// Parse de cor da string (visual do teste1)
  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppColors.tealPrimary;
    }
  }

  /// Mapper de ícone por tipo (visual do teste1)
  IconData _iconFromSlug(String? slug) {
    if (slug == null || slug.isEmpty) {
      return Icons.account_balance_wallet_outlined;
    }
    
    switch (slug.toLowerCase()) {
      case 'corrente':
        return Icons.account_balance;
      case 'poupanca':  
        return Icons.savings;
      case 'carteira':
        return Icons.account_balance_wallet;
      case 'investimento':
        return Icons.trending_up;
      case 'outros':
        return Icons.more_horiz;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  /// Formatar tipo de conta (visual do teste1)
  String _formatarTipoConta(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'corrente':
        return 'Conta Corrente';
      case 'poupanca':
        return 'Poupança';
      case 'carteira':
        return 'Carteira';
      case 'investimento':
        return 'Investimento';
      case 'outros':
        return 'Outros';
      default:
        return tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mostrarArquivadas ? Colors.white : AppColors.cinzaClaro,
      
      // AppBar com visual do teste1 + funcionalidades reais
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        elevation: 0,
        toolbarHeight: ResponsiveSizes.appBarHeight(context, base: 42), // 56 * 0.75 = 42
        leading: _mostrarArquivadas ? IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: ResponsiveSizes.appBarIconSize(context, base: 21),
          ),
          onPressed: () {
            // Volta para contas ativas
            setState(() {
              _mostrarArquivadas = false;
            });
          },
        ) : null, // Sem botão de voltar quando está em contas ativas
        title: AppText.appBarTitle(
          _mostrarArquivadas ? 'Contas Arquivadas' : 'Gerenciar Contas',
          style: AppTypography.appBarTitle(context),
        ),
        actions: _mostrarArquivadas 
          ? [] // AppBar clean sem ícones quando mostrando arquivadas
          : [
              IconButton(
                icon: Icon(
                  Icons.archive,
                  color: Colors.white,
                  size: ResponsiveSizes.appBarIconSize(context, base: 21),
                ),
                onPressed: _verContasArquivadas,
                tooltip: 'Ver arquivadas',
              ),
              IconButton(
                icon: Icon(
                  _viewMode == 'consolidado' ? Icons.view_module : Icons.view_list,
                  color: Colors.white,
                  size: ResponsiveSizes.appBarIconSize(context, base: 21),
                ),
                onPressed: () {
                  setState(() {
                    _viewMode = _viewMode == 'consolidado' ? 'mini' : 'consolidado';
                  });
                },
                tooltip: _viewMode == 'consolidado' ? 'Mini cards' : 'Cards normais',
              ),
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: ResponsiveSizes.appBarIconSize(context, base: 21),
                ),
                onPressed: _navegarParaCriarConta,
                tooltip: 'Nova conta',
              ),
            ],
      ),
      
      body: _buildConteudo(),
    );
  }

  /// Conteúdo principal (visual da screenshot)
  Widget _buildConteudo() {
    if (_loading) {
      return const Center(
        child: LoadingWidget(
          message: 'Carregando contas...',
          color: AppColors.tealPrimary,
        ),
      );
    }
    
    if (_erro != null) {
      return Center(
        child: AppErrorWidget(
          message: _erro!,
          onRetry: _carregarContas,
        ),
      );
    }
    
    final contasParaExibir = _mostrarArquivadas ? _contasArquivadas : _contas;
    
    if (_mostrarArquivadas) {
      // 🎨 LAYOUT SUPER CLEAN PARA CONTAS ARQUIVADAS
      return contasParaExibir.isEmpty 
        ? _buildVazio() // Estado vazio clean
        : SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                ...contasParaExibir.map((conta) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _buildContaItem(conta),
                )),
                const SizedBox(height: 20),
              ],
            ),
          );
    }

    // Layout original para contas ativas
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card de resumo (apenas para contas ativas)
          _buildResumoCard(),
          
          const SizedBox(height: 16),
          
          // Lista de contas
          if (contasParaExibir.isEmpty)
            _buildVazio()
          else if (_viewMode == 'consolidado')
            ...contasParaExibir.map((conta) => _buildContaItem(conta))
          else
            ...contasParaExibir.map((conta) => _buildContaSimples(conta)),
            
          const SizedBox(height: 32),
          
          // Botões inferiores (apenas para contas ativas)
          _buildBotoesInferiores(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Widget estado vazio (visual do teste1)
  Widget _buildVazio() {
    if (_mostrarArquivadas) {
      // 🎨 ESTADO VAZIO SUPER CLEAN PARA CONTAS ARQUIVADAS
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone clean e simples
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.archive_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Título clean
              AppText.cardTitle(
                'Nenhuma conta arquivada',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                color: Colors.black87,
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle clean
              Text(
                'Contas arquivadas aparecerão aqui',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Estado vazio elegante para contas ativas - inspirado nos cartões
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone principal
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.tealPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: AppColors.tealPrimary,
              ),
            ),

            const SizedBox(height: 24),

            // Título
            AppText.cardTitle(
              'Nenhuma conta cadastrada',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              color: AppColors.cinzaEscuro,
            ),

            const SizedBox(height: 12),

            // Descrição
            AppText.body(
              'Comece organizando suas finanças adicionando suas contas bancárias, carteiras e investimentos',
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
              color: AppColors.cinzaTexto,
            ),

            const SizedBox(height: 32),

            // Botão principal - Contas Básicas
            AppButton(
              text: 'Criar Contas Básicas',
              onPressed: _navegarParaContasPopulares,
              variant: AppButtonVariant.primary,
              customColor: AppColors.tealPrimary,
              icon: Icons.account_balance,
              fullWidth: true,
            ),

            const SizedBox(height: 12),

            // Botão secundário - Criar personalizada
            AppButton(
              text: 'Criar Conta Personalizada',
              onPressed: _navegarParaCriarConta,
              variant: AppButtonVariant.outline,
              customColor: AppColors.tealPrimary,
              icon: Icons.add,
              fullWidth: true,
            ),

            const SizedBox(height: 12),

            // Botão terciário - Demo
            AppButton(
              text: 'Testar com Dados Demo',
              onPressed: _criarDadosDemo,
              variant: AppButtonVariant.outline,
              customColor: AppColors.cinzaTexto,
              icon: Icons.play_arrow,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Modo consolidado (visual do teste1 + funcionalidades reais)
  Widget _buildModoConsolidado(List<ContaModel> contas) {
    return RefreshIndicator(
      color: AppColors.tealPrimary,
      onRefresh: _carregarContas,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              if (!_mostrarArquivadas) _buildResumoCard(),
              const SizedBox(height: 24),
              _buildListaEmbebida(contas),
              const SizedBox(height: 32),
              _botoesInferiores(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Modo empilhado (visual do teste1)
  Widget _buildModoEmpilhado(List<ContaModel> contas) {
    return RefreshIndicator(
      color: AppColors.tealPrimary,
      onRefresh: _carregarContas,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              if (!_mostrarArquivadas) _buildResumoCard(),
              const SizedBox(height: 24),
              ...contas.map((conta) => _buildContaSimples(conta)),
              const SizedBox(height: 32),
              _botoesInferiores(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Card de resumo (visual da screenshot)
  Widget _buildResumoCard() {
    return Container(
      padding: ResponsiveSizes.padding(
        context: context,
        base: const EdgeInsets.all(12),
        compact: const EdgeInsets.all(10),
        expanded: const EdgeInsets.all(16),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.tealPrimary, AppColors.tealPrimary.withValues(alpha: 0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealPrimary.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primeira linha: Ícone + Saldo | Contas Ativas + Número
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone + Saldo
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: ResponsiveSizes.iconSize(
                          context: context,
                          base: 16,
                          small: 14,
                          large: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo',
                          style: AppTypography.onDarkSecondary(
                            context,
                            AppTypography.label(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(_saldoTotal), // SALDO REAL!
                          style: AppTypography.onDark(
                            context,
                            AppTypography.currencyMedium(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Contas Ativas
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Contas Ativas',
                    style: AppTypography.onDarkSecondary(
                      context,
                      AppTypography.label(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: ResponsiveSizes.circularContainer(
                      context: context,
                      base: 36,
                      small: 32,
                      large: 40,
                    ),
                    height: ResponsiveSizes.circularContainer(
                      context: context,
                      base: 36,
                      small: 32,
                      large: 40,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(
                        ResponsiveSizes.circularContainer(
                          context: context,
                          base: 36,
                          small: 32,
                          large: 40,
                        ) / 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${_contas.length}', // QUANTIDADE REAL!
                        style: AppTypography.onDark(
                          context,
                          AppTypography.bold(
                            AppTypography.bodyMedium(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Projeção (saldo - pendentes do mês)
          FutureBuilder<double>(
            future: _calcularPendentesDoMes(),
            builder: (context, snapshot) {
              final pendentes = snapshot.data ?? 0.0;
              final projecao = _saldoTotal - pendentes;
              final temPendentes = pendentes != 0.0;
              
              if (!temPendentes) {
                return const SizedBox.shrink(); // Não mostra se não tem pendentes
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Projeção (após pendentes do mês)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        projecao < _saldoTotal ? Icons.trending_down : Icons.trending_up,
                        color: projecao < _saldoTotal ? Colors.red : Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        CurrencyFormatter.format(projecao),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${CurrencyFormatter.format(pendentes * -1)} pendentes)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Lista embebida (visual do teste1)
  Widget _buildListaEmbebida(List<ContaModel> contas) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 0),
      itemCount: contas.length,
      itemBuilder: (context, i) => _buildContaItem(contas[i]),
    );
  }

  /// Card de conta (visual com faixa lateral colorida como offline)
  Widget _buildContaItem(ContaModel conta) {
    final cor = _parseColor(conta.cor ?? '#008080');
    final saldoNegativo = conta.saldo < 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Material(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navegarParaGestaoCompleta(conta),
          child: Container(
            height: ResponsiveSizes.cardHeight(context, base: 67),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.branco,
            ),
            child: Row(
              children: [
                // 🎨 FAIXA LATERAL COLORIDA (como no offline)
                Container(
                  width: ResponsiveSizes.cardSidebarWidth(context, base: 37),
                  decoration: BoxDecoration(
                    color: cor, // Cor da conta
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _iconFromSlug(conta.tipo),
                      color: Colors.white,
                      size: ResponsiveSizes.iconSize(
                        context: context,
                        base: 17,
                        small: 15,
                        large: 19,
                      ),
                    ),
                  ),
                ),
                
                // Conteúdo principal
                Expanded(
                  child: Padding(
                    padding: ResponsiveSizes.padding(
                      context: context,
                      base: const EdgeInsets.all(11),
                      compact: const EdgeInsets.all(9),
                      expanded: const EdgeInsets.all(13),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primeira linha: Nome + Saldo
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: AppText.cardTitle(
                                  conta.nome,
                                  style: AppTypography.cardTitle(context),
                                  group: AppTextGroups.cardTitles,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AppText.cardValue(
                                CurrencyFormatter.format(conta.saldo),
                                style: AppTypography.cardCurrency(context),
                                color: saldoNegativo ? Colors.red[600] : Colors.green[600],
                                group: AppTextGroups.cardValues,
                              ),
                            ],
                          ),
                        ),
                        
                        // Segunda linha: Banco + Menu
                        Row(
                          children: [
                            Expanded(
                              child: AppText.cardSecondary(
                                '${conta.banco ?? 'Sem banco'} • Conta',
                                style: AppTypography.cardSecondary(context),
                                group: AppTextGroups.cardSecondary,
                              ),
                            ),
                            
                            // Menu três pontinhos
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _mostrarMenuConta(conta),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.more_horiz,
                                  color: AppColors.cinzaTexto,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mini card para modo empilhado (visual do teste1 + funcionalidades reais)
  Widget _buildContaSimples(ContaModel conta) {
    final cor = _parseColor(conta.cor ?? '#008080');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _mostrarMenuConta(conta), // MENU REAL!
          child: Container(
            height: ResponsiveSizes.cardHeight(context, base: 50),
            padding: ResponsiveSizes.padding(
              context: context,
              base: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              compact: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              expanded: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  cor,
                  cor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveSizes.spacing(
                      context: context,
                      base: 4,
                      compact: 3,
                      expanded: 5,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    _iconFromSlug(conta.tipo),
                    color: Colors.white,
                    size: ResponsiveSizes.iconSize(
                      context: context,
                      base: 14,
                      small: 12,
                      large: 16,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText.cardTitle(
                        conta.nome,
                        style: AppTypography.onDark(
                          context,
                          AppTypography.semiBold(
                            AppTypography.caption(context),
                          ),
                        ),
                        group: AppTextGroups.miniCards,
                      ),
                      if (conta.banco != null)
                        AppText.cardSecondary(
                          conta.banco!,
                          style: AppTypography.onDarkSecondary(
                            context,
                            AppTypography.caption(context),
                          ),
                          group: AppTextGroups.miniCards,
                        ),
                    ],
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppText.cardValue(
                    CurrencyFormatter.format(conta.saldo),
                    style: AppTypography.onDark(
                      context,
                      AppTypography.bold(
                        AppTypography.caption(context),
                      ),
                    ),
                    group: AppTextGroups.miniCards,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Menu da conta com FUNCIONALIDADES REAIS
  /// 🎯 MOSTRAR MENU DA CONTA (funcionalidades completas)
  void _mostrarMenuConta(ContaModel conta) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.cardTitle(
              conta.nome,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: const Icon(Icons.dashboard, color: AppColors.tealPrimary),
              title: AppText.body('Gestão Completa'),
              subtitle: AppText.cardSecondary('Insights, gráficos e análises'),
              onTap: () {
                Navigator.pop(context);
                _navegarParaGestaoCompleta(conta);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.tealPrimary),
              title: AppText.body('Editar Conta'),
              onTap: () {
                Navigator.pop(context);
                _navegarParaEditarConta(conta);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.account_balance, color: AppColors.tealPrimary),
              title: AppText.body('Ajustar Saldo'),
              onTap: () {
                Navigator.pop(context);
                _navegarParaCorrecaoSaldo(conta);
              },
            ),
            
            if (conta.ativo) ...[
              ListTile(
                leading: const Icon(Icons.archive, color: Colors.orange),
                title: AppText.body('Arquivar Conta'),
                onTap: () {
                  Navigator.pop(context);
                  _arquivarConta(conta);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.unarchive, color: Colors.green),
                title: AppText.body('Desarquivar Conta'),
                onTap: () {
                  Navigator.pop(context);
                  _desarquivarConta(conta);
                },
              ),
            ],
            
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: AppText.body('Excluir Conta'),
              onTap: () {
                Navigator.pop(context);
                _excluirConta(conta);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Botões inferiores (roláveis com o conteúdo)
  Widget _buildBotoesInferiores() {
    return Row(
      children: [
        // Botão VOLTAR (lado esquerdo)
        Expanded(
          child: AppButton.outline(
            text: 'VOLTAR',
            icon: Icons.arrow_back,
            size: AppButtonSize.medium,
            onPressed: () {
              // Se pode voltar (veio de outra página, como diagnóstico), volta
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                // Se não pode voltar (página inicial), vai para navegação principal
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(initialIndex: 2), // Índice 2 = Relatórios
                  ),
                  (route) => false,
                );
              }
            },
            customColor: AppColors.tealPrimary,
            fullWidth: true,
          ),
        ),

        const SizedBox(width: 12),

        // Botão NOVA CONTA (lado direito)
        Expanded(
          child: AppButton.primary(
            text: 'NOVA CONTA',
            icon: Icons.add,
            size: AppButtonSize.medium,
            onPressed: _navegarParaCriarConta,
            customColor: AppColors.tealPrimary,
            fullWidth: true,
          ),
        ),
      ],
    );
  }

  /// Botões inferiores (visual do teste1) - MÉTODO ANTIGO
  Widget _botoesInferiores() {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: AppButton(
                text: 'NOVA CONTA',
                icon: Icons.add,
                onPressed: _navegarParaCriarConta, // FUNÇÃO REAL!
                variant: AppButtonVariant.primary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: AppButton(
                text: 'VOLTAR',
                icon: Icons.arrow_back,
                onPressed: () {
                  // Se pode voltar (veio de outra página, como diagnóstico), volta
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    // Se não pode voltar (página inicial), vai para navegação principal
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainNavigation(initialIndex: 2), // Índice 2 = Relatórios
                      ),
                      (route) => false,
                    );
                  }
                },
                variant: AppButtonVariant.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 💬 MOSTRAR DIÁLOGO DE MOTIVO
  Future<String?> _mostrarDialogMotivo(String titulo, String label) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText.cardTitle(titulo),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText.button('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: AppText.button('Confirmar'),
          ),
        ],
      ),
    );
  }

  /// ❓ MOSTRAR CONFIRMAÇÃO
  Future<bool> _mostrarConfirmacao(String titulo, String mensagem) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText.cardTitle(titulo),
        content: AppText.body(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: AppText.button('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: AppText.button('Confirmar'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// 🗃️ ARQUIVAR CONTA
  void _arquivarConta(ContaModel conta) async {
    final motivo = await _mostrarDialogMotivo('Arquivar', 'Digite o motivo (opcional):');
    if (motivo == null) return; // Usuário cancelou
    
    try {
      // Mostra loading durante operação
      setState(() => _loading = true);
      
      await _contaService.arquivarConta(conta.id, motivo: motivo);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📦 Arquivando "${conta.nome}"... Sincronizando com Supabase'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 🔄 FORÇA SYNC COMPLETO + REFRESH INTELIGENTE
        await _forcarSyncERefresh('Arquivamento');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao arquivar conta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// 📤 DESARQUIVAR CONTA
  void _desarquivarConta(ContaModel conta) async {
    try {
      // Mostra loading durante operação
      setState(() => _loading = true);
      
      await _contaService.desarquivarConta(conta.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📤 Desarquivando "${conta.nome}"... Sincronizando com Supabase'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 🔄 FORÇA SYNC COMPLETO + REFRESH INTELIGENTE
        await _forcarSyncERefresh('Desarquivamento');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao desarquivar conta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// 🗑️ EXCLUIR CONTA
  void _excluirConta(ContaModel conta) async {
    final confirmacao = await _mostrarConfirmacao(
      'Excluir Conta',
      'Tem certeza que deseja excluir a conta "${conta.nome}"?\n\nEsta ação não pode ser desfeita.',
    );
    
    if (!confirmacao) return;

    try {
      await _contaService.excluirConta(conta.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conta "${conta.nome}" excluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _carregarContas();
      }
    } catch (e) {
      if (mounted) {
        // Se há transações vinculadas, oferece exclusão forçada
        if (e.toString().contains('transações') || e.toString().contains('possui')) {
          final forcarExclusao = await _mostrarConfirmacao(
            'Conta possui transações',
            'A conta "${conta.nome}" possui transações vinculadas.\n\nDeseja mesmo excluir? Isso também excluirá todas as transações relacionadas.',
          );
          
          if (forcarExclusao) {
            try {
              await _contaService.excluirConta(conta.id, confirmacao: true);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Conta "${conta.nome}" e suas transações foram excluídas!'),
                    backgroundColor: Colors.orange,
                  ),
                );
                _carregarContas();
              }
            } catch (e2) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao forçar exclusão: $e2'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir conta: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

}