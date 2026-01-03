// 🏷️ Gestão Categoria Page - iPoupei Mobile
// 
// Página de gestão completa da categoria com insights e métricas
// Baseada na gestao_conta_page.dart mas adaptada para categorias
// 
// Features:
// - AppBar com seletor de mês
// - Card da categoria com botões de ação  
// - Métricas resumo (3 cards)
// - Seção de subcategorias
// - Insights e dicas
// - Gráficos (evolução, entradas vs saídas, subcategorias)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pie_chart_sz/pie_chart_sz.dart';
import 'package:collection/collection.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../models/categoria_model.dart';
import '../services/categoria_service.dart';
import '../components/criar_categoria_modal.dart';
import '../components/criar_subcategoria_modal.dart';
import '../components/migrar_categoria_modal.dart';
import '../components/excluir_categoria_modal.dart';
import '../data/categoria_icons.dart';
import '../../transacoes/services/transacao_service.dart';
import '../../transacoes/pages/transacoes_page.dart';
import '../../../shared/components/navigation/app_bottom_navigation.dart';
import '../../../routes/main_navigation.dart';

/// Página de gestão completa da categoria com insights e métricas
class GestaoCategoriaPage extends StatefulWidget {
  final CategoriaModel categoria;

  const GestaoCategoriaPage({
    super.key,
    required this.categoria,
  });

  @override
  State<GestaoCategoriaPage> createState() => _GestaoCategoriaPageState();
}

class _GestaoCategoriaPageState extends State<GestaoCategoriaPage> {
  DateTime _mesAtual = DateTime.now();
  bool _carregando = true;
  String? _erro;
  bool _modoAno = false; // true = ano, false = mês
  
  // 📊 DADOS DA CATEGORIA
  double _valorTotal = 0.0;
  int _qtdPendentes = 0;
  int _qtdEfetivados = 0;
  double _valorPendente = 0.0;
  double _valorEfetivado = 0.0;
  List<SubcategoriaModel> _subcategorias = [];
  
  // 📈 DADOS DOS GRÁFICOS
  List<Map<String, dynamic>> _evolucaoValores = [];
  List<Map<String, dynamic>> _pendenteVsEfetivado = [];
  List<Map<String, dynamic>> _valoresPorSubcategoria = [];
  
  // 🎯 DADOS COMBINADOS: TODAS as subcategorias com seus valores (zero ou não)
  List<Map<String, dynamic>> _subcategoriasCompletas = [];
  
  // 🔄 CONTROLE DE MIGRAÇÃO
  bool _houveMigracao = false;

  @override
  void initState() {
    super.initState();
    _inicializarComPreCache();
  }

  /// 🚀 INICIALIZAR COM PRÉ-CACHE DOS ÚLTIMOS 12 MESES
  Future<void> _inicializarComPreCache() async {
    try {
      // Pré-carregar os últimos 12 meses + 6 meses futuros em background
      debugPrint('🚀 Pré-carregando 12 meses passados + 6 futuros para navegação instantânea...');
      
      // Não esperar - faz em background para não bloquear a UI
      CategoriaService.instance.preCarregarUltimos12Meses(forceRefresh: false);
      
      // Carregar dados do mês atual normalmente
      await _carregarDados();
    } catch (e) {
      debugPrint('❌ Erro na inicialização com pré-cache: $e');
      // Se der erro, carrega normalmente
      await _carregarDados();
    }
  }

  /// 📡 CARREGAR TODOS OS DADOS DA GESTÃO DA CATEGORIA
  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    
    try {
      await Future.wait([
        _carregarMetricasResumo(),
        _carregarSubcategorias(),
        _carregarEvolucaoValores(),
        _carregarPendenteVsEfetivado(),
        _carregarValoresPorSubcategoria(),
      ].map((future) => future.catchError((error) {
        debugPrint('⚠️ Erro em carregamento individual: $error');
        return;
      })));
      
      // 🎯 COMBINAR subcategorias com valores após carregar ambos
      await _combinarSubcategoriasComValores();
      
      setState(() {
        _carregando = false;
        _erro = null;
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados da categoria: $e');
      setState(() {
        _carregando = false;
        _erro = 'Erro ao carregar dados';
      });
    }
  }

  /// 🚀 CARREGAR MÉTRICAS DE RESUMO (OTIMIZADO - USA PRÉ-CACHE!)
  Future<void> _carregarMetricasResumo() async {
    try {
      DateTime dataInicio, dataFim;
      
      if (_modoAno) {
        // Dados anuais consolidados (ano inteiro)
        dataInicio = DateTime(_mesAtual.year, 1, 1);
        dataFim = DateTime(_mesAtual.year, 12, 31);
      } else {
        // Dados mensais (mês atual)
        dataInicio = DateTime(_mesAtual.year, _mesAtual.month, 1);
        dataFim = DateTime(_mesAtual.year, _mesAtual.month + 1, 0);
      }

      debugPrint('🚀 Carregando métricas otimizadas para categoria: ${widget.categoria.nome}');

      // 🚀 USA DADOS PRÉ-CARREGADOS (MUITO MAIS RÁPIDO!)
      final categoriasComValores = await CategoriaService.instance.fetchCategoriasComValoresCache(
        dataInicio: dataInicio,
        dataFim: dataFim,
        tipo: widget.categoria.tipo,
      );

      // Buscar nossa categoria específica nos dados pré-carregados
      final nossaCategoria = categoriasComValores.where(
        (item) => item['id'] == widget.categoria.id
      ).firstOrNull;

      if (nossaCategoria != null) {
        // ⚡ DADOS JÁ PRÉ-CALCULADOS - INSTANTÂNEO!
        final totalCache = (nossaCategoria['valor_total'] as num?)?.toDouble() ?? 0.0;
        final totalTransacoesCache =
            (nossaCategoria['quantidade_transacoes'] as num?)?.toInt() ?? 0;
        
        // Para pendentes, ainda precisamos buscar (são poucos)
        await _carregarTransacoesPendentes(dataInicio, dataFim);
        
        _valorTotal = totalCache;
        _valorEfetivado = _valorTotal - _valorPendente;
        _qtdEfetivados = totalTransacoesCache - _qtdPendentes;
        
        debugPrint('⚡ Métricas PRÉ-CALCULADAS - Total: R\$ $_valorTotal, Efetivado: R\$ $_valorEfetivado');
      } else {
        debugPrint('⚠️ Categoria não encontrada no pré-cache, usando fallback...');
        await _carregarMetricasResumoFallback(dataInicio, dataFim);
      }

    } catch (e) {
      debugPrint('❌ Erro nas métricas otimizadas, usando fallback: $e');
      await _carregarMetricasResumoFallback(
        DateTime(_mesAtual.year, _mesAtual.month, 1),
        DateTime(_mesAtual.year, _mesAtual.month + 1, 0),
      );
    }
  }

  /// ⚡ CARREGAR APENAS TRANSAÇÕES PENDENTES (RÁPIDO)
  Future<void> _carregarTransacoesPendentes(DateTime dataInicio, DateTime dataFim) async {
    try {
      // Busca apenas as pendentes (normalmente são poucas)
      final transacoesPendentes = await TransacaoService.instance.fetchTransacoes(
        categoriaId: widget.categoria.id,
        dataInicio: dataInicio,
        dataFim: dataFim,
        limit: 1000,
        // efetivado: false, // TODO: Implementar filtro se não existir
      );

      _qtdPendentes = 0;
      _valorPendente = 0.0;
      
      for (final transacao in transacoesPendentes) {
        if (!transacao.efetivado) {
          _qtdPendentes++;
          _valorPendente += transacao.valor;
        }
      }

      debugPrint('⚡ Pendentes carregadas: $_qtdPendentes (R\$ $_valorPendente)');
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar pendentes: $e');
      _qtdPendentes = 0;
      _valorPendente = 0.0;
    }
  }

  /// 💰 FALLBACK: MÉTODO ORIGINAL (APENAS SE PRÉ-CACHE FALHAR)
  Future<void> _carregarMetricasResumoFallback(DateTime dataInicio, DateTime dataFim) async {
    try {
      final transacoes = await TransacaoService.instance.fetchTransacoes(
        categoriaId: widget.categoria.id,
        dataInicio: dataInicio,
        dataFim: dataFim,
        limit: 10000,
      );

      _valorTotal = 0.0;
      _qtdPendentes = 0;
      _qtdEfetivados = 0;
      _valorPendente = 0.0;
      _valorEfetivado = 0.0;

      for (final transacao in transacoes) {
        _valorTotal += transacao.valor;
        
        if (transacao.efetivado) {
          _qtdEfetivados++;
          _valorEfetivado += transacao.valor;
        } else {
          _qtdPendentes++;
          _valorPendente += transacao.valor;
        }
      }

      debugPrint('📊 Métricas fallback - Total: R\$ $_valorTotal, Efetivado: R\$ $_valorEfetivado');
    } catch (e) {
      debugPrint('❌ Erro no fallback de métricas: $e');
      _valorTotal = 0.0;
      _qtdPendentes = 0;
      _qtdEfetivados = 0;
      _valorPendente = 0.0;
      _valorEfetivado = 0.0;
    }
  }

  /// 📂 CARREGAR SUBCATEGORIAS
  Future<void> _carregarSubcategorias() async {
    try {
      debugPrint('🔍 Carregando subcategorias para categoria: ${widget.categoria.id} (${widget.categoria.nome})');
      _subcategorias = await CategoriaService.instance.fetchSubcategorias(
        categoriaId: widget.categoria.id,
      );
      debugPrint('✅ Subcategorias carregadas: ${_subcategorias.length}');
      if (_subcategorias.isNotEmpty) {
        for (final sub in _subcategorias) {
          debugPrint('  - ${sub.nome} (${sub.id})');
        }
      } else {
        debugPrint('📝 Nenhuma subcategoria encontrada para a categoria ${widget.categoria.nome}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar subcategorias: $e');
      _subcategorias = [];
    }
  }

  /// 🎯 COMBINAR TODAS AS SUBCATEGORIAS COM SEUS VALORES
  Future<void> _combinarSubcategoriasComValores() async {
    try {
      debugPrint('🎯 Combinando ${_subcategorias.length} subcategorias com valores...');
      
      _subcategoriasCompletas.clear();
      
      // Para cada subcategoria, buscar seus valores ou usar zero
      for (final subcategoria in _subcategorias) {
        // Buscar dados reais da subcategoria em _valoresPorSubcategoria  
        final dadosComValor = _valoresPorSubcategoria.firstWhereOrNull(
          (item) => item['id'] == subcategoria.id
        );
        
        // Criar entrada completa com todos os dados
        final subcategoriaCompleta = {
          // Dados da subcategoria
          'id': subcategoria.id,
          'nome': subcategoria.nome,
          'cor': subcategoria.cor ?? widget.categoria.cor,
          'icone': subcategoria.icone ?? widget.categoria.icone,
          'ativo': subcategoria.ativo,
          'categoria_id': subcategoria.categoriaId,
          
          // Valores (podem ser zero)
          'valor_total': dadosComValor?['valorTotal'] as double? ?? 0.0,
          'valor_efetivado': dadosComValor?['valorEfetivado'] as double? ?? 0.0,
          'valor_pendente': dadosComValor?['valorPendente'] as double? ?? 0.0,
          'qtd_efetivados': dadosComValor?['qtdEfetivados'] as int? ?? 0,
          'qtd_pendentes': dadosComValor?['qtdPendentes'] as int? ?? 0,
          
          // Flag para identificar se tem transações
          'tem_transacoes': (dadosComValor?['valorTotal'] as double? ?? 0.0) > 0,
        };
        
        _subcategoriasCompletas.add(subcategoriaCompleta);
      }
      
      // Ordenar: com transações primeiro, depois por nome
      _subcategoriasCompletas.sort((a, b) {
        final aTemTransacoes = a['tem_transacoes'] as bool;
        final bTemTransacoes = b['tem_transacoes'] as bool;
        
        // Primeiro critério: com transações primeiro
        if (aTemTransacoes && !bTemTransacoes) return -1;
        if (!aTemTransacoes && bTemTransacoes) return 1;
        
        // Segundo critério: ordem alfabética
        return (a['nome'] as String).compareTo(b['nome'] as String);
      });
      
      debugPrint('✅ Subcategorias completas preparadas: ${_subcategoriasCompletas.length}');
      debugPrint('   📊 Com transações: ${_subcategoriasCompletas.where((s) => s['tem_transacoes']).length}');
      debugPrint('   📝 Sem transações: ${_subcategoriasCompletas.where((s) => !s['tem_transacoes']).length}');
      
    } catch (e) {
      debugPrint('❌ Erro ao combinar subcategorias com valores: $e');
      _subcategoriasCompletas = [];
    }
  }

  /// 🚀 CARREGAR EVOLUÇÃO DE VALORES (SUPER OTIMIZADO - USA PRÉ-CACHE!)
  Future<void> _carregarEvolucaoValores() async {
    try {
      final agora = DateTime.now();
      _evolucaoValores = [];

      debugPrint('🚀 Carregando evolução com PRÉ-CACHE dos últimos 12 meses!');
      
      // ⚡ USAR PRÉ-CACHE PARA CADA MÊS (INSTANTÂNEO!)
      final Map<String, double> valoresPorMes = {};
      
      for (int i = 0; i < 12; i++) {
        final mes = DateTime(agora.year, agora.month - (11 - i), 1);
        final dataInicio = DateTime(mes.year, mes.month, 1);
        final dataFim = DateTime(mes.year, mes.month + 1, 0);
        
        try {
          // Busca no pré-cache (instantâneo se disponível)
          final categoriasComValores = await CategoriaService.instance.fetchCategoriasComValoresCache(
            dataInicio: dataInicio,
            dataFim: dataFim,
            tipo: widget.categoria.tipo,
            forceRefresh: false, // Use cache
          );
          
          // Buscar nossa categoria específica
          final nossaCategoria = categoriasComValores.where(
            (item) => item['id'] == widget.categoria.id
          ).firstOrNull;
          
          final chave = '${mes.year}-${mes.month.toString().padLeft(2, '0')}';
          valoresPorMes[chave] = (nossaCategoria?['valor_total'] as num?)?.toDouble() ?? 0.0;
          
        } catch (e) {
          debugPrint('⚠️ Erro ao buscar mês ${mes.month}/${mes.year}: $e');
          final chave = '${mes.year}-${mes.month.toString().padLeft(2, '0')}';
          valoresPorMes[chave] = 0.0;
        }
      }

      // Gerar dados de evolução (super rápido!)
      for (int i = 0; i < 12; i++) {
        final mes = DateTime(agora.year, agora.month - (11 - i), 1);
        final chave = '${mes.year}-${mes.month.toString().padLeft(2, '0')}';
        final valorMes = valoresPorMes[chave] ?? 0.0;

        _evolucaoValores.add({
          'mes': _formatarMesAbrev(mes),
          'valor': valorMes,
          'isAtual': i == 11,
        });
      }

      final totalCarregado = _evolucaoValores.where((m) => m['valor'] > 0).length;
      debugPrint('⚡ Evolução PRÉ-CALCULADA: $totalCarregado/12 meses com dados');
      
    } catch (e) {
      debugPrint('❌ Erro na evolução otimizada, usando fallback: $e');
      await _carregarEvolucaoValoresFallback();
    }
  }

  /// 💰 FALLBACK: EVOLUÇÃO MÉTODO ORIGINAL
  Future<void> _carregarEvolucaoValoresFallback() async {
    try {
      final agora = DateTime.now();
      _evolucaoValores = [];

      final dozeUltimosMesesInicio = DateTime(agora.year, agora.month - 11, 1);
      final fimPeriodo = DateTime(agora.year, agora.month + 1, 0);
      
      final todasTransacoes = await TransacaoService.instance.fetchTransacoes(
        categoriaId: widget.categoria.id,
        dataInicio: dozeUltimosMesesInicio,
        dataFim: fimPeriodo,
        limit: 10000,
      );

      final Map<String, double> valoresPorMes = {};
      
      for (final transacao in todasTransacoes) {
        if (transacao.efetivado) {
          final data = transacao.data;
          final chave = '${data.year}-${data.month.toString().padLeft(2, '0')}';
          valoresPorMes[chave] = (valoresPorMes[chave] ?? 0.0) + transacao.valor;
        }
      }

      for (int i = 0; i < 12; i++) {
        final mes = DateTime(agora.year, agora.month - (11 - i), 1);
        final chave = '${mes.year}-${mes.month.toString().padLeft(2, '0')}';
        final valorMes = valoresPorMes[chave] ?? 0.0;

        _evolucaoValores.add({
          'mes': _formatarMesAbrev(mes),
          'valor': valorMes,
          'isAtual': i == 11,
        });
      }

      debugPrint('📊 Evolução fallback carregada: ${_evolucaoValores.length} meses');
    } catch (e) {
      debugPrint('❌ Erro no fallback de evolução: $e');
      _evolucaoValores = [];
    }
  }

  /// 📅 CARREGAR GASTOS POR DIA DA SEMANA
  Future<void> _carregarPendenteVsEfetivado() async {
    try {
      DateTime dataInicio, dataFim;
      
      if (_modoAno) {
        // Dados anuais (ano inteiro)
        dataInicio = DateTime(_mesAtual.year, 1, 1);
        dataFim = DateTime(_mesAtual.year, 12, 31);
      } else {
        // Dados mensais (mês atual)
        dataInicio = DateTime(_mesAtual.year, _mesAtual.month, 1);
        dataFim = DateTime(_mesAtual.year, _mesAtual.month + 1, 0);
      }

      // Buscar transações do período
      final transacoes = await TransacaoService.instance.fetchTransacoes(
        categoriaId: widget.categoria.id,
        dataInicio: dataInicio,
        dataFim: dataFim,
        limit: 10000,
      );

      // Agrupar por dia da semana
      final gastosPorDia = <int, double>{
        1: 0.0, // Segunda
        2: 0.0, // Terça
        3: 0.0, // Quarta
        4: 0.0, // Quinta
        5: 0.0, // Sexta
        6: 0.0, // Sábado
        7: 0.0, // Domingo
      };

      for (final transacao in transacoes) {
        if (transacao.efetivado) {
          final diaSemana = transacao.data.weekday; // 1=segunda, 7=domingo
          gastosPorDia[diaSemana] = gastosPorDia[diaSemana]! + transacao.valor;
        }
      }

      // Converter para formato esperado
      final dadosBase = [
        {'dia': 'Dom', 'valor': gastosPorDia[7]!},
        {'dia': 'Seg', 'valor': gastosPorDia[1]!},
        {'dia': 'Ter', 'valor': gastosPorDia[2]!},
        {'dia': 'Qua', 'valor': gastosPorDia[3]!},
        {'dia': 'Qui', 'valor': gastosPorDia[4]!},
        {'dia': 'Sex', 'valor': gastosPorDia[5]!},
        {'dia': 'Sáb', 'valor': gastosPorDia[6]!},
      ];
      
      // Ordenar por valor para determinar cores (menor = verde, maior = vermelho)
      final valoresOrdenados = dadosBase.map((d) => d['valor'] as double).toList()..sort();
      final valorMinimo = valoresOrdenados.first;
      final valorMaximo = valoresOrdenados.last;
      
      // Aplicar cores baseadas na performance (verde teal = bom, vermelho = ruim)
      _pendenteVsEfetivado = dadosBase.map((item) {
        final valor = item['valorTotal'] as double;
        final String cor;
        
        if (valorMaximo - valorMinimo == 0) {
          // Todos os valores iguais - usar cor neutra
          cor = '#008080'; // Teal padrão
        } else {
          // Normalizar valor entre 0 e 1
          final normalizado = (valor - valorMinimo) / (valorMaximo - valorMinimo);
          
          if (normalizado <= 0.33) {
            // Melhores resultados - tons de verde teal
            cor = _lerp('#00A693', '#008080', normalizado * 3); // Verde teal claro para escuro
          } else if (normalizado <= 0.66) {
            // Resultados medianos - tons neutros
            cor = _lerp('#FFA500', '#FF8C00', (normalizado - 0.33) * 3); // Laranja claro para escuro
          } else {
            // Piores resultados - tons de vermelho
            cor = _lerp('#FF6B6B', '#DC3545', (normalizado - 0.66) * 3); // Vermelho claro para escuro
          }
        }
        
        return {
          'dia': item['dia'],
          'valor': valor,
          'cor': cor,
        };
      }).toList();
      
    } catch (e) {
      debugPrint('❌ Erro ao carregar gastos por dia da semana: $e');
      _pendenteVsEfetivado = [];
    }
  }

  /// 🏷️ CARREGAR VALORES POR SUBCATEGORIA
  Future<void> _carregarValoresPorSubcategoria() async {
    try {
      debugPrint('🗓️ _mesAtual atual: ${_mesAtual.day}/${_mesAtual.month}/${_mesAtual.year}');
      debugPrint('📊 _modoAno: $_modoAno');
      
      DateTime dataInicio, dataFim;
      
      if (_modoAno) {
        // Dados anuais (ano inteiro)
        dataInicio = DateTime(_mesAtual.year, 1, 1);
        dataFim = DateTime(_mesAtual.year, 12, 31);
      } else {
        // Dados mensais (mês atual)
        dataInicio = DateTime(_mesAtual.year, _mesAtual.month, 1);
        dataFim = DateTime(_mesAtual.year, _mesAtual.month + 1, 0);
      }

      // 🔄 LIMPAR DADOS ANTERIORES E ATUALIZAR UI
      setState(() {
        _valoresPorSubcategoria = [];
      });

      if (_modoAno) {
        // 📅 MODO ANO: Agregar dados de múltiplos meses do pré-cache
        debugPrint('🟡 MODO ANO ATIVADO - Período: 01/01/${dataInicio.year} a 31/12/${dataInicio.year}');
        debugPrint('⚡ Tentando agregar subcategorias de 12 meses do pré-cache...');
        await _carregarSubcategoriasAnoComPreCache(dataInicio.year);
      } else {
        // 📅 MODO MÊS: Usar fallback otimizado (subcategorias sempre precisam de query específica)
        debugPrint('🟢 MODO MÊS ATIVADO - Período: ${dataInicio.day}/${dataInicio.month}/${dataInicio.year} a ${dataFim.day}/${dataFim.month}/${dataFim.year}');
        debugPrint('⚡ Carregando subcategorias do mês...');
        await _carregarValoresPorSubcategoriaFallback(dataInicio, dataFim);
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar valores por subcategoria: $e');
      _valoresPorSubcategoria = [];
    }
  }

  /// 📅 CARREGAR SUBCATEGORIAS ANO INTEIRO COM PRÉ-CACHE
  Future<void> _carregarSubcategoriasAnoComPreCache(int ano) async {
    try {
      debugPrint('🚀 Agregando subcategorias do ano $ano usando pré-cache...');
      
      final Map<String, Map<String, dynamic>> dadosPorSub = {};
      int mesesComDados = 0;
      
      // Tentar carregar cada mês do ano do pré-cache
      for (int mes = 1; mes <= 12; mes++) {
        try {
          final dataInicio = DateTime(ano, mes, 1);
          final dataFim = DateTime(ano, mes + 1, 0);
          
          final categoriasComValores = await CategoriaService.instance.fetchCategoriasComValoresCache(
            dataInicio: dataInicio,
            dataFim: dataFim,
            tipo: widget.categoria.tipo,
            forceRefresh: false,
          );

          // Se encontrou dados no pré-cache para este mês
          if (categoriasComValores.isNotEmpty) {
            debugPrint('⚡ Mês $mes/$ano encontrado no pré-cache');
            
            // Carregar transações deste mês para agregação por subcategoria
            final transacoesMes = await TransacaoService.instance.fetchTransacoes(
              categoriaId: widget.categoria.id,
              dataInicio: dataInicio,
              dataFim: dataFim,
              limit: 10000,
            );
            
            debugPrint('📊 Mês $mes/$ano: ${transacoesMes.length} transações encontradas');
            
            // Agregar dados completos por subcategoria
            int transacoesProcessadas = 0;
            for (final transacao in transacoesMes) {
              if (transacao.subcategoriaId != null) {
                final subcategoriaId = transacao.subcategoriaId!;
                
                // Inicializar dados da subcategoria se não existir
                dadosPorSub[subcategoriaId] ??= {
                  'valorEfetivado': 0.0,
                  'qtdEfetivados': 0,
                  'valorPendente': 0.0,
                  'qtdPendentes': 0,
                };
                
                if (transacao.efetivado) {
                  dadosPorSub[subcategoriaId]!['valorEfetivado'] += transacao.valor;
                  dadosPorSub[subcategoriaId]!['qtdEfetivados']++;
                  transacoesProcessadas++;
                } else {
                  dadosPorSub[subcategoriaId]!['valorPendente'] += transacao.valor;
                  dadosPorSub[subcategoriaId]!['qtdPendentes']++;
                }
              }
            }
            debugPrint('💰 Mês $mes/$ano: $transacoesProcessadas transações efetivadas agregadas');
            mesesComDados++;
          } else {
            debugPrint('❌ Mês $mes/$ano: Não encontrado no pré-cache');
          }
        } catch (e) {
          debugPrint('⚠️ Erro no mês $mes/$ano, continuando: $e');
        }
      }
      
      // Criar lista final com dados completos para as subcategorias
      _valoresPorSubcategoria.clear();
      for (final subcategoria in _subcategorias) {
        final dados = dadosPorSub[subcategoria.id];
        if (dados != null) {
          final valorEfetivado = dados['valorEfetivado'] as double;
          final valorPendente = dados['valorPendente'] as double;
          final valorTotal = valorEfetivado + valorPendente;
          
          if (valorTotal > 0) {
            _valoresPorSubcategoria.add({
              'id': subcategoria.id,
              'nome': subcategoria.nome,
              'valorTotal': valorTotal,
              'valorEfetivado': valorEfetivado,
              'qtdEfetivados': dados['qtdEfetivados'] as int,
              'valorPendente': valorPendente,
              'qtdPendentes': dados['qtdPendentes'] as int,
              'color': widget.categoria.cor,
            });
          }
        }
      }

      debugPrint('✅ Ano $ano agregado: $mesesComDados meses, ${_valoresPorSubcategoria.length} subcategorias');
      debugPrint('🔍 VALORES FINAIS DAS SUBCATEGORIAS (MODO ANO):');
      double totalGeral = 0.0;
      for (final item in _valoresPorSubcategoria) {
        final valor = item['valorTotal'] as double;
        totalGeral += valor;
        debugPrint('  📊 ${item['nome']}: R\$ ${valor.toStringAsFixed(2)} (E: ${item['valorEfetivado']}, P: ${item['valorPendente']})');
      }
      debugPrint('💰 TOTAL GERAL DO ANO: R\$ ${totalGeral.toStringAsFixed(2)}');
      debugPrint('📅 DADOS USADOS: $mesesComDados de 12 meses do ano $ano');
      
      // 🔄 FORÇAR ATUALIZAÇÃO DA UI
      if (mounted) {
        setState(() {});
      }
      
      // Se não conseguiu dados suficientes do pré-cache, usar fallback
      if (mesesComDados < 6) {
        debugPrint('⚠️ Poucos meses no pré-cache ($mesesComDados), usando fallback anual...');
        await _carregarValoresPorSubcategoriaFallback(
          DateTime(ano, 1, 1), 
          DateTime(ano, 12, 31)
        );
      }
    } catch (e) {
      debugPrint('❌ Erro na agregação anual, usando fallback: $e');
      await _carregarValoresPorSubcategoriaFallback(
        DateTime(ano, 1, 1), 
        DateTime(ano, 12, 31)
      );
    }
  }

  /// 🔄 FALLBACK OTIMIZADO: SUBCATEGORIAS
  Future<void> _carregarValoresPorSubcategoriaFallback(DateTime dataInicio, DateTime dataFim) async {
    try {
      // 🚀 OTIMIZAÇÃO: Uma única consulta para todas as transações da categoria
      debugPrint('🔍 Fallback: Buscando transações da categoria ${widget.categoria.nome}');
      debugPrint('📅 Período fallback: ${dataInicio.day}/${dataInicio.month}/${dataInicio.year} a ${dataFim.day}/${dataFim.month}/${dataFim.year}');
      final todasTransacoes = await TransacaoService.instance.fetchTransacoes(
        categoriaId: widget.categoria.id,
        dataInicio: dataInicio,
        dataFim: dataFim,
        limit: 10000,
      );
      
      debugPrint('💰 ${todasTransacoes.length} transações encontradas para subcategorias');

      // Criar mapa para agrupar dados completos por subcategoria
      final Map<String, Map<String, dynamic>> dadosPorSub = {};
      
      // Processar todas as transações uma vez só
      for (final transacao in todasTransacoes) {
        if (transacao.subcategoriaId != null) {
          final subcategoriaId = transacao.subcategoriaId!;
          
          // Inicializar dados da subcategoria se não existir
          dadosPorSub[subcategoriaId] ??= {
            'valorEfetivado': 0.0,
            'qtdEfetivados': 0,
            'valorPendente': 0.0,
            'qtdPendentes': 0,
          };
          
          if (transacao.efetivado) {
            dadosPorSub[subcategoriaId]!['valorEfetivado'] += transacao.valor;
            dadosPorSub[subcategoriaId]!['qtdEfetivados']++;
          } else {
            dadosPorSub[subcategoriaId]!['valorPendente'] += transacao.valor;
            dadosPorSub[subcategoriaId]!['qtdPendentes']++;
          }
        }
      }
      
      // Criar lista final com dados completos para as subcategorias
      _valoresPorSubcategoria.clear();
      for (final subcategoria in _subcategorias) {
        final dados = dadosPorSub[subcategoria.id];
        if (dados != null) {
          final valorEfetivado = dados['valorEfetivado'] as double;
          final valorPendente = dados['valorPendente'] as double;
          final valorTotal = valorEfetivado + valorPendente;
          
          if (valorTotal > 0) {
            _valoresPorSubcategoria.add({
              'id': subcategoria.id,
              'nome': subcategoria.nome,
              'valorTotal': valorTotal,
              'valorEfetivado': valorEfetivado,
              'qtdEfetivados': dados['qtdEfetivados'] as int,
              'valorPendente': valorPendente,
              'qtdPendentes': dados['qtdPendentes'] as int,
              'color': widget.categoria.cor,
            });
          }
        }
      }

      debugPrint('✅ Subcategorias carregadas: ${_valoresPorSubcategoria.length}');
      debugPrint('🔍 VALORES FINAIS DAS SUBCATEGORIAS (MODO MÊS):');
      double totalGeral = 0.0;
      for (final item in _valoresPorSubcategoria) {
        final valor = item['valorTotal'] as double;
        totalGeral += valor;
        debugPrint('  📊 ${item['nome']}: R\$ ${valor.toStringAsFixed(2)} (E: ${item['valorEfetivado']}, P: ${item['valorPendente']})');
      }
      debugPrint('💰 TOTAL GERAL DO MÊS: R\$ ${totalGeral.toStringAsFixed(2)}');
      
      // 🔄 FORÇAR ATUALIZAÇÃO DA UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Erro no fallback das subcategorias: $e');
      _valoresPorSubcategoria = [];
    }
  }

  /// 📅 FORMATAR MÊS ABREVIADO
  String _formatarMesAbrev(DateTime data) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${meses[data.month - 1]}/${data.year.toString().substring(2)}';
  }

  /// ⬅️ NAVEGAR PARA ANTERIOR (MÊS OU ANO)
  void _mesAnterior() {
    setState(() {
      if (_modoAno) {
        _mesAtual = DateTime(_mesAtual.year - 1, _mesAtual.month, 1);
      } else {
        _mesAtual = DateTime(_mesAtual.year, _mesAtual.month - 1, 1);
      }
    });
    _carregarDados();
  }

  /// ➡️ NAVEGAR PARA PRÓXIMO (MÊS OU ANO)
  void _proximoMes() {
    setState(() {
      if (_modoAno) {
        _mesAtual = DateTime(_mesAtual.year + 1, _mesAtual.month, 1);
      } else {
        _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + 1, 1);
      }
    });
    _carregarDados();
  }

  /// 📅 ALTERNAR MODO MÊS/ANO
  void _selecionarAno() async {
    setState(() {
      _modoAno = !_modoAno; // Alterna entre modo mês e ano
    });
    _carregarDados(); // Recarrega dados para o novo modo
  }

  /// 🎯 NAVEGAR PARA AÇÃO ESPECÍFICA
  void _navegarParaAcao(String acao) async {
    switch (acao) {
      case 'nova_categoria':
        await _abrirModalNovaCategoria();
        break;
      case 'editar_categoria':
        await _abrirModalEditarCategoria();
        break;
      case 'migrar':
        _mostrarMigrarCategoria();
        break;
      case 'excluir':
        await _excluirCategoria();
        break;
      case 'criar_sub':
        await _abrirModalNovaSubcategoria();
        break;
      case 'transacoes':
        _navegarParaTransacoes();
        break;
    }
  }

  Future<void> _abrirModalNovaCategoria() async {
    final resultado = await showModalBottomSheet<CategoriaModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CriarCategoriaModal(
        tipo: widget.categoria.tipo,
        onCategoriaCriada: (categoria) {
          debugPrint('✅ Nova categoria criada: ${categoria.nome}');
        },
      ),
    );
    
    if (resultado != null) {
      await _carregarDados();
    }
  }

  Future<void> _abrirModalEditarCategoria() async {
    final resultado = await showModalBottomSheet<CategoriaModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CriarCategoriaModal(
        tipo: widget.categoria.tipo,
        categoriaParaEditar: widget.categoria,
        onCategoriaCriada: (categoria) {
          debugPrint('✅ Categoria editada: ${categoria.nome}');
        },
      ),
    );
    
    if (resultado != null) {
      await _carregarDados();
    }
  }

  Future<void> _abrirModalNovaSubcategoria() async {
    final resultado = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CriarSubcategoriaModal(
        categoria: widget.categoria,
        onSubcategoriaCriada: (subcategoria) {
          debugPrint('✅ Nova subcategoria criada: ${subcategoria['nome']}');
        },
      ),
    );
    
    if (resultado != null) {
      await _carregarSubcategorias();
    }
  }

  Future<void> _mostrarMigrarCategoria() async {
    try {
      // Carregar todas as categorias para o seletor
      final todasCategorias = await CategoriaService.instance.fetchCategorias();
      
      // Verificar dependências da categoria atual
      final dependencias = await CategoriaService.instance.verificarDependenciasCategoria(widget.categoria.id);
      
      if (dependencias['success'] && !dependencias['temDependencias']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta categoria não possui dados para migrar')),
        );
        return;
      }
      
      if (!dependencias['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao verificar dependências: ${dependencias['error']}')),
        );
        return;
      }
      
      final resultado = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: MigrarCategoriaModal(
            categoriaOrigem: widget.categoria,
            qtdTransacoes: dependencias['qtdTransacoes'] ?? 0,
            qtdSubcategorias: dependencias['qtdSubcategorias'] ?? 0,
            categoriasDisponiveis: todasCategorias,
          ),
        ),
      );
      
      if (resultado != null && resultado['success']) {
        _houveMigracao = true; // Marcar que houve migração
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado['message'])),
        );
        await _carregarDados(); // Recarregar dados após migração
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir migração: $e')),
      );
    }
  }

  Future<void> _excluirCategoria() async {
    try {
      // Carregar todas as categorias para possível migração
      final todasCategorias = await CategoriaService.instance.fetchCategorias();
      
      final resultado = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ExcluirCategoriaModal(
            categoria: widget.categoria,
            todasCategorias: todasCategorias,
          ),
        ),
      );
      
      if (resultado != null && resultado['success']) {
        Navigator.pop(context, {
          'migrationOccurred': true, // Exclusão também requer refresh
        }); // Sair da página já que categoria foi excluída
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir exclusão: $e')),
      );
    }
  }

  void _navegarParaTransacoes() {
    debugPrint('🧭 Navegando para transações da categoria: ${widget.categoria.nome} (${widget.categoria.id})');
    debugPrint('🧭 Mês selecionado: ${_mesAtual.month}/${_mesAtual.year}');

    // Navegar diretamente para TransacoesPage com filtro da categoria (preserva navegação anterior)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransacoesPage(
          filtrosIniciais: {
            'categoria_id': widget.categoria.id,
          },
          showNavigationBar: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cor = _parseColor(widget.categoria.cor);
    final headerColor = widget.categoria.tipo == 'despesa' 
        ? AppColors.vermelhoHeader 
        : AppColors.tealPrimary;
    
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      appBar: _buildAppBar(headerColor),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.tealPrimary,
              ),
            )
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _erro!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _carregarDados,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tealPrimary,
                        ),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _buildBody(cor, headerColor),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 3, // Categorias é o índice 3
        onTap: _onBottomNavigationTap,
      ),
    );
  }

  /// 🔝 APPBAR COM SELETOR DE MÊS INTEGRADO
  PreferredSizeWidget _buildAppBar(Color headerColor) {
    return AppBar(
      backgroundColor: headerColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Botão voltar
          Transform.translate(
            offset: const Offset(-8, 0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
          Expanded(
            child: Text(
              'Gerir Categoria',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis, // ✅ Lidar com texto longo
              maxLines: 1, // ✅ Manter uma linha
            ),
          ),
        ],
      ),
      actions: [
        // Seletor de mês integrado no actions
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
          onPressed: _mesAnterior,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        GestureDetector(
          onTap: _selecionarAno,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _modoAno ? _mesAtual.year.toString() : _formatarMesAno(_mesAtual),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
          onPressed: _proximoMes,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  /// 📱 CORPO DA PÁGINA
  Widget _buildBody(Color cor, Color headerColor) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Card da categoria + ações
          _buildCardCategoriaComAcoes(cor, headerColor),
          
          const SizedBox(height: 12),
          
          // 3 cards de resumo
          _buildResumoMetricas(),
          
          const SizedBox(height: 12),
          
          // Seção de subcategorias
          _buildSecaoSubcategorias(cor),
          
          const SizedBox(height: 12),
          
          // Card de insights
          _buildCardInsights(),
          
          const SizedBox(height: 12),
          
          // Gráficos
          _buildGraficos(),

          const SizedBox(height: 24),

          // Botão de voltar
          _buildBotaoVoltar(headerColor),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 🏷️ CARD DA CATEGORIA COM AÇÕES
  Widget _buildCardCategoriaComAcoes(Color cor, Color headerColor) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card da categoria
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: _buildCardCategoria(cor),
          ),
          
          // Chips de ações (6 botões)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildChipsElegantes(headerColor),
          ),
        ],
      ),
    );
  }

  /// 🎴 CARD DA CATEGORIA
  Widget _buildCardCategoria(Color cor) {
    return Container(
      height: 94,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.branco,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🎨 FAIXA LATERAL COLORIDA
          Container(
            width: 50,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Center(
              child: CategoriaIcons.renderIcon(
                widget.categoria.icone,
                24,
                color: Colors.white,
              ),
            ),
          ),
          
          // Conteúdo principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primeira linha: Nome + Valor Total
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.categoria.nome,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cinzaEscuro,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          CurrencyFormatter.format(_valorTotal),
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: widget.categoria.tipo == 'despesa' 
                                ? Colors.red[600] 
                                : Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Segunda linha: Apenas subcategorias
                  Text(
                    'Subcategorias (${_subcategoriasCompletas.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.cinzaTexto,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔗 CHIPS ELEGANTES DE AÇÕES (3x2)
  Widget _buildChipsElegantes(Color headerColor) {
    return Column(
      children: [
        // Primeira linha: 3 chips
        Row(
          children: [
            Expanded(child: _buildChipElegante(
              icone: Icons.add,
              titulo: 'NOVA',
              cor: AppColors.verdeSucesso,
              onTap: () => _navegarParaAcao('nova_categoria'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildChipElegante(
              icone: Icons.edit,
              titulo: 'EDITAR',
              cor: AppColors.azul,
              onTap: () => _navegarParaAcao('editar_categoria'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildChipElegante(
              icone: Icons.swap_horiz,
              titulo: 'MIGRAR',
              cor: AppColors.roxoPrimario,
              onTap: () => _navegarParaAcao('migrar'),
            )),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Segunda linha: 3 chips
        Row(
          children: [
            Expanded(child: _buildChipElegante(
              icone: Icons.analytics,
              titulo: 'TRANSAÇÕES',
              cor: headerColor,
              onTap: () => _navegarParaAcao('transacoes'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildChipElegante(
              icone: Icons.create_new_folder,
              titulo: 'CRIAR SUB',
              cor: AppColors.tealPrimary,
              onTap: () => _navegarParaAcao('criar_sub'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildChipElegante(
              icone: Icons.delete_outline,
              titulo: 'EXCLUIR',
              cor: AppColors.vermelhoErro,
              onTap: () => _navegarParaAcao('excluir'),
            )),
          ],
        ),
      ],
    );
  }

  /// 🎯 CHIP ELEGANTE INDIVIDUAL
  Widget _buildChipElegante({
    required IconData icone,
    required String titulo,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.cinzaClaro,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone colorido
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icone,
                  color: cor,
                  size: 20,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Título
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cinzaEscuro,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📊 RESUMO MÉTRICAS (3 cards)
  Widget _buildResumoMetricas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricaCard(
              titulo: 'Valor Total',
              valor: CurrencyFormatter.format(_valorTotal),
              quantidade: null,
              cor: AppColors.tealPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricaCard(
              titulo: 'Pendentes',
              valor: CurrencyFormatter.formatCompact(_valorPendente),
              quantidade: _qtdPendentes,
              cor: AppColors.amareloAlerta,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricaCard(
              titulo: 'Efetivados',
              valor: CurrencyFormatter.formatCompact(_valorEfetivado),
              quantidade: _qtdEfetivados,
              cor: AppColors.verdeSucesso,
            ),
          ),
        ],
      ),
    );
  }

  /// 📈 CARD DE MÉTRICA INDIVIDUAL
  Widget _buildMetricaCard({
    required String titulo,
    required String valor,
    int? quantidade,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Valor em cima - com scroll horizontal se necessário
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                valor,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ),
            const SizedBox(height: 4),
            // Título + quantidade (se houver) - com scroll horizontal se necessário
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.cinzaTexto,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                  if (quantidade != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '($quantidade)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.cinzaTexto,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📂 SEÇÃO DE SUBCATEGORIAS
  Widget _buildSecaoSubcategorias(Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header com botão Nova Subcategoria
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder_open,
                    color: AppColors.cinzaTexto,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Subcategorias',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _navegarParaAcao('criar_sub'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nova', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(60, 30),
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de subcategorias
            if (_subcategoriasCompletas.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhuma subcategoria',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Crie subcategorias para organizar melhor',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...(_subcategoriasCompletas.asMap().entries.map((entry) {
                final index = entry.key;
                final subcategoriaCompleta = entry.value;
                return _buildItemSubcategoriaCompleta(subcategoriaCompleta, cor, index == _subcategoriasCompletas.length - 1);
              })),
          ],
        ),
      ),
    );
  }

  /// 🎯 ITEM DA SUBCATEGORIA COMPLETA (MOSTRA TODAS, COM OU SEM TRANSAÇÕES)
  Widget _buildItemSubcategoriaCompleta(Map<String, dynamic> subcategoriaCompleta, Color cor, bool isLast) {
    // Extrair dados da subcategoria completa
    final id = subcategoriaCompleta['id'] as String;
    final nome = subcategoriaCompleta['nome'] as String;
    final valorTotal = subcategoriaCompleta['valor_total'] as double;
    final valorEfetivado = subcategoriaCompleta['valor_efetivado'] as double;
    final valorPendente = subcategoriaCompleta['valor_pendente'] as double;
    final qtdEfetivados = subcategoriaCompleta['qtd_efetivados'] as int;
    final qtdPendentes = subcategoriaCompleta['qtd_pendentes'] as int;
    final temTransacoes = subcategoriaCompleta['tem_transacoes'] as bool;
    
    // 🎨 Cores baseadas no status de uso
    final corBase = temTransacoes ? cor : Colors.grey.shade400;
    final corTexto = temTransacoes ? Colors.black87 : Colors.grey.shade600;
    final corFundo = temTransacoes ? Colors.white : Colors.grey.shade50;
    
    return Column(
      children: [
        Material(
          color: corFundo,
          child: InkWell(
            onTap: () => _mostrarMenuSubcategoriaCompleta(subcategoriaCompleta),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: temTransacoes ? Colors.grey.shade200 : Colors.grey.shade300,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // 🎨 INDICADOR COLORIDO ELEGANTE
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: corBase,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  const SizedBox(width: 14),
                  
                  // 📝 CONTEÚDO PRINCIPAL
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome + Valor (linha principal)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                nome,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: temTransacoes ? FontWeight.w500 : FontWeight.w400,
                                  color: corTexto,
                                ),
                              ),
                            ),
                            
                            // Valor total
                            Text(
                              CurrencyFormatter.format(valorTotal),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: temTransacoes ? FontWeight.bold : FontWeight.normal,
                                color: temTransacoes ? corBase : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        
                        // Detalhes apenas se houver transações
                        if (temTransacoes) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (qtdEfetivados > 0)
                                Text(
                                  '✅ $qtdEfetivados efetivado${qtdEfetivados > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              
                              if (qtdEfetivados > 0 && qtdPendentes > 0)
                                Text(
                                  ' • ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              
                              if (qtdPendentes > 0)
                                Text(
                                  '⏳ $qtdPendentes pendente${qtdPendentes > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                            ],
                          ),
                        ] else ...[
                          // Indicação sutil para subcategorias não utilizadas
                          const SizedBox(height: 4),
                          Text(
                            'Sem movimentações neste período',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // 🔧 ÍCONE DE MENU
                  Icon(
                    Icons.more_vert,
                    size: 16,
                    color: temTransacoes ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Divisor (exceto no último item)
        if (!isLast)
          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),
      ],
    );
  }

  /// 🚀 ITEM DA SUBCATEGORIA (DESIGN MODERNO E COMPACTO) - MÉTODO ORIGINAL
  Widget _buildItemSubcategoria(SubcategoriaModel subcategoria, Color cor, bool isLast) {
    // Buscar dados reais da subcategoria em _valoresPorSubcategoria
    final dadosSubcategoria = _valoresPorSubcategoria.firstWhereOrNull(
      (item) => item['id'] == subcategoria.id
    );
    
    // Usar dados reais ou valores zerados se não houver transações
    final valorTotal = dadosSubcategoria?['valorTotal'] as double? ?? 0.0;
    final valorEfetivado = dadosSubcategoria?['valorEfetivado'] as double? ?? 0.0;
    final qtdEfetivados = dadosSubcategoria?['qtdEfetivados'] as int? ?? 0;
    final valorPendente = dadosSubcategoria?['valorPendente'] as double? ?? 0.0;
    final qtdPendentes = dadosSubcategoria?['qtdPendentes'] as int? ?? 0;
    
    // NOTA: Método original ainda esconde subcategorias sem transações
    if (valorTotal == 0 && valorPendente == 0) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _mostrarMenuSubcategoria(subcategoria),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // 🎨 INDICADOR COLORIDO ELEGANTE (SEM ÍCONE REPETIDO)
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  const SizedBox(width: 14),
                  
                  // 📝 CONTEÚDO PRINCIPAL
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome + Valor (linha principal)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subcategoria.nome,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: AppColors.cinzaEscuro,
                                ),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(valorTotal),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                                color: AppColors.cinzaEscuro,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // ⚡ INDICADORES VISUAIS COM VALORES
                        Row(
                          children: [
                            // Efetivados - Verde com quantidade e valor
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.verdeSucesso10,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.verdeSucesso30,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${CurrencyFormatter.formatCompact(valorEfetivado)} ($qtdEfetivados)',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.verdeSucesso,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 10),
                            
                            // Pendentes - Amarelo com quantidade e valor
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.amareloAlerta10,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.amareloAlerta30,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${CurrencyFormatter.formatCompact(valorPendente)} ($qtdPendentes)',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.amareloAlerta,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 📱 MENU DISCRETO
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _mostrarMenuSubcategoria(subcategoria),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.more_horiz,
                        color: AppColors.cinzaTexto.withValues(alpha: 0.7),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Divisor mais sutil
        if (!isLast)
          Container(
            margin: const EdgeInsets.only(left: 30),
            height: 1,
            color: Colors.grey.shade100,
          ),
      ],
    );
  }

  /// 💡 CARD DE INSIGHTS E DICAS
  Widget _buildCardInsights() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com logo do iPoupei
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.azulHeader.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.azulHeader,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'iP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Insights iPoupei',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Insights baseados nos dados
            ...(_generateInsights().map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    insight['icone'] as IconData,
                    color: insight['cor'] as Color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight['texto'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.cinzaTexto,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ))),
          ],
        ),
      ),
    );
  }

  /// 📊 SEÇÃO DOS GRÁFICOS
  Widget _buildGraficos() {
    return Column(
      children: [
        // Gráfico de evolução dos valores
        _buildGraficoEvolucaoValores(),
        
        const SizedBox(height: 12),
        
        // Gráfico gastos por dia da semana
        _buildGraficoGastosPorDia(),
        
        const SizedBox(height: 12),
        
        // Gráfico de subcategorias
        _buildGraficoSubcategorias(),
      ],
    );
  }

  /// 📈 GRÁFICO DE EVOLUÇÃO DOS VALORES
  Widget _buildGraficoEvolucaoValores() {
    if (_evolucaoValores.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.tealPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.show_chart,
                    color: AppColors.tealPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Evolução dos Valores',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Legenda do gráfico
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendaItem('Dados reais', AppColors.tealPrimary),
                  const SizedBox(width: 24),
                  _buildLegendaItem('Projeção', AppColors.cinzaMedio),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Gráfico de linha (igual ao contas page)
            SizedBox(
              height: 200,
              child: _evolucaoValores.isEmpty
                  ? Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_flat,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sem movimentações',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'nos últimos 12 meses',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.shade300,
                                strokeWidth: 1,
                                dashArray: [3, 3],
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < _evolucaoValores.length) {
                                    final item = _evolucaoValores[index];
                                    final mes = item['mes'] as String;
                                    return Text(
                                      mes.split('/')[0], // Só o mês (Jan, Fev, etc.)
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    CurrencyFormatter.formatCompact(value),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey.shade600,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            // Linha sólida para dados reais (passado + atual) 
                            LineChartBarData(
                              spots: _evolucaoValores.asMap().entries
                                  .where((entry) => !(entry.value['isProjecao'] ?? false))
                                  .map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final valor = ((item['valor'] as num?) ?? 0.0).toDouble();
                                return FlSpot(index.toDouble(), valor);
                              }).toList(),
                              isCurved: true,
                              curveSmoothness: 0.2,
                              color: AppColors.tealPrimary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.tealPrimary.withValues(alpha: 0.1),
                              ),
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: AppColors.tealPrimary,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                            ),
                            // Linha conectada para projeção (atual + futuro)
                            LineChartBarData(
                              spots: _evolucaoValores.asMap().entries
                                  .where((entry) => (entry.value['isAtual'] ?? false) || (entry.value['isProjecao'] ?? false))
                                  .map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final valor = ((item['valor'] as num?) ?? 0.0).toDouble();
                                return FlSpot(index.toDouble(), valor);
                              }).toList(),
                              isCurved: true,
                              curveSmoothness: 0.2,
                              color: AppColors.cinzaMedio,
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dashArray: [8, 4],
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 3,
                                    color: AppColors.cinzaMedio,
                                    strokeWidth: 1,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📅 GRÁFICO GASTOS POR DIA DA SEMANA
  Widget _buildGraficoGastosPorDia() {
    if (_pendenteVsEfetivado.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.azulHeader.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_view_week,
                    color: AppColors.azulHeader,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Gastos por Dia da Semana',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Gráfico de barras coloridas
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _pendenteVsEfetivado.map((dia) {
                  final valor = dia['valor'] as double;
                  final maxValor = _pendenteVsEfetivado.map((d) => d['valor'] as double).reduce((a, b) => a > b ? a : b);
                  final altura = (valor / maxValor) * 140; // Altura máxima de 140px
                  final cor = Color(int.parse('0xFF${(dia['cor'] as String).substring(1)}'));
                  
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Valor em cima da barra
                      Text(
                        CurrencyFormatter.formatCompact(valor),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cinzaTexto,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Barra colorida
                      Container(
                        width: 24,
                        height: altura,
                        decoration: BoxDecoration(
                          color: cor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dia da semana
                      Text(
                        dia['dia'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.cinzaTexto,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Resumo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Maior Gasto',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        _pendenteVsEfetivado.isEmpty ? 'R\$ 0,00' : 
                        CurrencyFormatter.formatCompact(
                          (_pendenteVsEfetivado.map((d) => d['valor'] as double).reduce((a, b) => a > b ? a : b))
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.vermelhoErro,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade300),
                  Column(
                    children: [
                      Text(
                        'Média Diária',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        _pendenteVsEfetivado.isEmpty ? 'R\$ 0,00' : 
                        CurrencyFormatter.formatCompact(
                          (_pendenteVsEfetivado.map((d) => d['valor'] as double).reduce((a, b) => a + b)) / 7
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.tealPrimary,
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

  /// 🎨 FUNÇÃO PARA GERAR CORES BASEADAS NO VALOR
  Color _getColorByValue(double valor, double maxValor) {
    if (maxValor == 0) return AppColors.tealPrimary;
    
    // Normaliza o valor (0 a 1)
    final normalizado = valor / maxValor;
    
    // Gradiente: Teal (menores) → Laranja → Vermelho (maiores)
    if (normalizado <= 0.33) {
      // Teal para azul
      return Color.lerp(AppColors.tealPrimary, Colors.blue.shade600, normalizado * 3)!;
    } else if (normalizado <= 0.66) {
      // Azul para laranja
      return Color.lerp(Colors.blue.shade600, Colors.orange.shade600, (normalizado - 0.33) * 3)!;
    } else {
      // Laranja para vermelho
      return Color.lerp(Colors.orange.shade600, Colors.red.shade600, (normalizado - 0.66) * 3)!;
    }
  }

  /// 🥧 GRÁFICO PIZZA DE SUBCATEGORIAS
  Widget _buildGraficoSubcategorias() {
    final totalGastos = _valoresPorSubcategoria.isEmpty 
        ? 0.0 
        : _valoresPorSubcategoria.fold<double>(0, (sum, item) => sum + (item['valorTotal'] as double));
    
    // ✅ CORREÇÃO ANTI-REGRESSÃO: Mostrar todas as subcategorias (incluindo zeradas)
    // Subcategorias zeradas são informação valiosa para análise
    final subcategoriasComValor = _valoresPorSubcategoria.toList();
    // REMOVIDO: .where((item) => (item['valorTotal'] as double) > 0)
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(21),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Estilo gestão cartões
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.roxoHeader.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pie_chart,
                    color: AppColors.roxoHeader,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Gastos por Subcategoria',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Layout lado a lado - Estilo gestão cartões
            if (_subcategorias.isEmpty)
              _buildEstadoVazioSubcategorias()
            else if (totalGastos == 0)
              _buildEstadoSemMovimentacoes()
            else
              Row(
                children: [
                  // Gráfico de pizza - Estilo gestão cartões
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 200,
                      child: PieChart(
                        _buildPieChartDataSubcategorias(),
                        swapAnimationDuration: const Duration(milliseconds: 800),
                        swapAnimationCurve: Curves.easeInOutCubic,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Legenda lateral - Estilo gestão cartões
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...subcategoriasComValor.take(6).map((subcategoria) {
                          final cores = [
                            AppColors.tealPrimary, 
                            AppColors.roxoHeader, 
                            Colors.orange, 
                            Colors.red, 
                            Colors.green, 
                            Colors.blue
                          ];
                          final index = subcategoriasComValor.indexOf(subcategoria);
                          final cor = cores[index % cores.length];
                          final valor = subcategoria['valorTotal'] as double;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: cor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subcategoria['nome'] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        CurrencyFormatter.formatCompact(valor),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Gera dados do PieChart no estilo fl_chart (igual gestão cartões)
  PieChartData _buildPieChartDataSubcategorias() {
    final cores = [
      AppColors.tealPrimary, 
      AppColors.roxoHeader, 
      Colors.orange, 
      Colors.red, 
      Colors.green, 
      Colors.blue
    ];
    
    // ✅ CORREÇÃO ANTI-REGRESSÃO: Mostrar todas as subcategorias (incluindo zeradas)
    final subcategoriasComValor = _valoresPorSubcategoria.toList();
    // REMOVIDO: .where((item) => (item['valorTotal'] as double) > 0)
    
    final totalGastos = subcategoriasComValor.fold<double>(
      0, (sum, item) => sum + (item['valorTotal'] as double)
    );
    
    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 50,
      sections: subcategoriasComValor.take(6).map((subcategoria) {
        final index = subcategoriasComValor.indexOf(subcategoria);
        final cor = cores[index % cores.length];
        final valor = subcategoria['valorTotal'] as double;
        final percentual = (valor / totalGastos) * 100;
        
        return PieChartSectionData(
          color: cor,
          value: valor,
          title: '${percentual.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList(),
    );
  }

  /// Estado vazio para quando não há subcategorias
  Widget _buildEstadoVazioSubcategorias() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Sem subcategorias',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Crie subcategorias para\nvisualizar o gráfico',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Estado sem movimentações
  Widget _buildEstadoSemMovimentacoes() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Sem movimentações',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nenhuma transação encontrada\npara este período',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 🏷️ ITEM DA LEGENDA
  Widget _buildLegendaItem(String texto, Color cor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.cinzaTexto,
          ),
        ),
      ],
    );
  }

  /// 🎯 HELPERS

  /// Formatar mês e ano (Jan/24)
  String _formatarMesAno(DateTime data) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${meses[data.month - 1]}/${data.year.toString().substring(2)}';
  }

  /// Gerar insights automáticos baseados nos dados
  List<Map<String, dynamic>> _generateInsights() {
    List<Map<String, dynamic>> insights = [];
    
    final percentualEfetivado = _qtdEfetivados / (_qtdPendentes + _qtdEfetivados);
    
    if (percentualEfetivado > 0.8) {
      insights.add({
        'icone': Icons.trending_up,
        'cor': AppColors.verdeSucesso,
        'texto': 'Ótimo controle! ${(_qtdEfetivados / (_qtdPendentes + _qtdEfetivados) * 100).toStringAsFixed(1)}% das transações estão efetivadas.',
      });
    } else if (percentualEfetivado < 0.5) {
      insights.add({
        'icone': Icons.warning_amber,
        'cor': Colors.orange,
        'texto': 'Muitas transações pendentes. Considere efetivar algumas para ter controle mais preciso.',
      });
    }
    
    if (_subcategorias.length > 3) {
      insights.add({
        'icone': Icons.folder_open,
        'cor': AppColors.tealPrimary,
        'texto': 'Boa organização! ${_subcategorias.length} subcategorias ajudam a detalhar seus gastos.',
      });
    } else if (_subcategorias.isEmpty) {
      insights.add({
        'icone': Icons.create_new_folder,
        'cor': AppColors.azul,
        'texto': 'Crie subcategorias para organizar melhor os gastos desta categoria.',
      });
    }
    
    if (insights.isEmpty) {
      insights.add({
        'icone': Icons.info_outline,
        'cor': AppColors.tealPrimary,
        'texto': 'Continue acompanhando sua categoria para receber insights personalizados.',
      });
    }
    
    return insights;
  }

  /// Parse de cor da string
  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppColors.tealPrimary;
    }
  }

  /// Interpolar entre duas cores hexadecimais
  String _lerp(String cor1, String cor2, double t) {
    try {
      // Limitar t entre 0 e 1
      t = t.clamp(0.0, 1.0);
      
      // Converter cores para RGB
      final c1 = Color(int.parse(cor1.replaceAll('#', '0xFF')));
      final c2 = Color(int.parse(cor2.replaceAll('#', '0xFF')));
      
      // Interpolar componentes RGB
      final r = ((c2.red - c1.red) * t + c1.red).round().clamp(0, 255);
      final g = ((c2.green - c1.green) * t + c1.green).round().clamp(0, 255);
      final b = ((c2.blue - c1.blue) * t + c1.blue).round().clamp(0, 255);
      
      // Converter de volta para hex
      return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
    } catch (_) {
      return cor1; // Fallback para primeira cor se houver erro
    }
  }

  /// Menu da subcategoria
  /// 🎯 MENU PARA SUBCATEGORIA COMPLETA (COM OU SEM TRANSAÇÕES)
  void _mostrarMenuSubcategoriaCompleta(Map<String, dynamic> subcategoriaCompleta) {
    final nome = subcategoriaCompleta['nome'] as String;
    final id = subcategoriaCompleta['id'] as String;
    final temTransacoes = subcategoriaCompleta['tem_transacoes'] as bool;
    final valorTotal = subcategoriaCompleta['valor_total'] as double;
    
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
            // Header com nome e status
            Column(
              children: [
                Text(
                  nome,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (temTransacoes) ...[
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(valorTotal),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'Sem movimentações neste período',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.tealPrimary),
              title: const Text('Editar Subcategoria'),
              onTap: () async {
                Navigator.pop(context);
                // Converter dados para SubcategoriaModel para compatibilidade
                final subcategoriaModel = SubcategoriaModel(
                  id: id,
                  categoriaId: subcategoriaCompleta['categoria_id'] as String,
                  usuarioId: '', // Não necessário para edição
                  nome: nome,
                  ativo: subcategoriaCompleta['ativo'] as bool,
                  createdAt: DateTime.now(), // Não necessário para edição  
                  updatedAt: DateTime.now(), // Não necessário para edição
                );
                await _abrirModalEditarSubcategoria(subcategoriaModel);
              },
            ),
            
            if (temTransacoes)
              ListTile(
                leading: const Icon(Icons.analytics, color: AppColors.verdeSucesso),
                title: const Text('Ver Transações'),
                subtitle: Text('${subcategoriaCompleta['qtd_efetivados'] + subcategoriaCompleta['qtd_pendentes']} transações'),
                onTap: () {
                  Navigator.pop(context);
                  _navegarParaTransacoesSubcategoria(id, nome);
                },
              )
            else
              ListTile(
                leading: Icon(Icons.info_outline, color: Colors.grey.shade500),
                title: const Text('Sem Transações'),
                subtitle: const Text('Esta subcategoria não possui movimentações'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Excluir Subcategoria'),
              subtitle: temTransacoes 
                  ? const Text('Atenção: possui transações vinculadas')
                  : const Text('Subcategoria sem uso pode ser excluída'),
              onTap: () async {
                Navigator.pop(context);
                // Converter dados para SubcategoriaModel para compatibilidade
                final subcategoriaModel = SubcategoriaModel(
                  id: id,
                  categoriaId: subcategoriaCompleta['categoria_id'] as String,
                  usuarioId: '', // Não necessário para exclusão
                  nome: nome,
                  ativo: subcategoriaCompleta['ativo'] as bool,
                  createdAt: DateTime.now(), // Não necessário para exclusão
                  updatedAt: DateTime.now(), // Não necessário para exclusão
                );
                await _excluirSubcategoria(subcategoriaModel);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarMenuSubcategoria(SubcategoriaModel subcategoria) {
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
            Text(
              subcategoria.nome,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.tealPrimary),
              title: const Text('Editar Subcategoria'),
              onTap: () async {
                Navigator.pop(context);
                await _abrirModalEditarSubcategoria(subcategoria);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.analytics, color: AppColors.verdeSucesso),
              title: const Text('Ver Transações'),
              onTap: () {
                Navigator.pop(context);
                _navegarParaTransacoesSubcategoria(subcategoria.id, subcategoria.nome);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Excluir Subcategoria'),
              onTap: () async {
                Navigator.pop(context);
                await _excluirSubcategoria(subcategoria);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirModalEditarSubcategoria(SubcategoriaModel subcategoria) async {
    final resultado = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CriarSubcategoriaModal(
        categoria: widget.categoria,
        nomeInicial: subcategoria.nome, // Pré-preenche com nome atual
        subcategoriaIdEditando: subcategoria.id, // Passa ID para edição
        onSubcategoriaCriada: (dadosAtualizados) {
          debugPrint('✅ Subcategoria editada: ${dadosAtualizados['nome']}');
        },
      ),
    );

    if (resultado != null) {
      await _carregarSubcategorias();
    }
  }

  Future<void> _excluirSubcategoria(SubcategoriaModel subcategoria) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Subcategoria'),
        content: Text('Deseja excluir a subcategoria "${subcategoria.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    
    if (confirmar == true) {
      try {
        await CategoriaService.instance.deleteSubcategoria(
          widget.categoria.id, 
          subcategoria.id,
        );
        await _carregarSubcategorias();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subcategoria excluída com sucesso')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir subcategoria: $e')),
        );
      }
    }
  }

  /// 🔙 BOTÃO DE VOLTAR
  Widget _buildBotaoVoltar(Color headerColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 20),
          label: const Text('Voltar para Categorias'),
          style: ElevatedButton.styleFrom(
            backgroundColor: headerColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  /// 🔍 NAVEGAR PARA TRANSAÇÕES DA SUBCATEGORIA
  void _navegarParaTransacoesSubcategoria(String subcategoriaId, String subcategoriaNome) {
    debugPrint('🎯 Navegando para transações: categoria=${widget.categoria.nome}, subcategoria=$subcategoriaNome');

    // Navegar diretamente para TransacoesPage com filtros
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransacoesPage(
          filtrosIniciais: {
            'categoria_id': widget.categoria.id,
            'subcategoria_id': subcategoriaId,
          },
          showNavigationBar: true,
        ),
      ),
    );
  }

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MainNavigation(initialIndex: index),
      ),
      (route) => false,
    );
  }
}
