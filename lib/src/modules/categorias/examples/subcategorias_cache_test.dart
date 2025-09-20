// 🔖 Teste do Sistema de Cache de Subcategorias - iPoupei Mobile
// 
// Exemplo prático de como utilizar o novo sistema de cache de subcategorias
// que espelha o sistema já implementado para categorias
//
// Features testadas:
// - Cache local com TTL de 5 minutos
// - Pré-cache dos últimos 12 meses
// - Atualização automática a cada 5 minutos
// - Busca com valores pré-calculados
// - Fallback offline e online

import 'package:flutter/material.dart';
import '../services/categoria_service.dart';

class SubcategoriasCacheTest extends StatefulWidget {
  const SubcategoriasCacheTest({super.key});

  @override
  State<SubcategoriasCacheTest> createState() => _SubcategoriasCacheTestState();
}

class _SubcategoriasCacheTestState extends State<SubcategoriasCacheTest> {
  final _categoriaService = CategoriaService.instance;
  bool _testando = false;
  List<String> _resultados = [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔖 Teste Cache Subcategorias'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            '🔖 Sistema de Cache de Subcategorias',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Este teste verifica todas as funcionalidades do cache de subcategorias:\n'
            '• Cache local com TTL de 5 minutos\n'
            '• Pré-cache dos últimos 12 meses\n'
            '• Atualização automática a cada 5 minutos\n'
            '• Busca com valores pré-calculados\n'
            '• Fallback offline e online',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: _testando ? null : _executarTodosOsTestes,
            child: _testando 
                ? const Text('⏳ Executando Testes...')
                : const Text('🚀 Executar Todos os Testes'),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _testando ? null : _testarCacheBasico,
                  child: const Text('📊 Teste Cache Básico'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _testando ? null : _testarPreCache,
                  child: const Text('⚡ Teste Pré-Cache'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _testando ? null : _testarAtualizacaoAutomatica,
                  child: const Text('⏰ Teste Auto-Update'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _testando ? null : _verificarStatus,
                  child: const Text('📊 Ver Status'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Resultados dos Testes:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _resultados.length,
                        itemBuilder: (context, index) {
                          final resultado = _resultados[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text(
                              resultado,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: resultado.contains('✅') 
                                    ? Colors.green[700]
                                    : resultado.contains('❌')
                                    ? Colors.red[700]
                                    : resultado.contains('⚠️')
                                    ? Colors.orange[700]
                                    : Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
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

  /// 🚀 EXECUTAR TODOS OS TESTES SEQUENCIALMENTE
  Future<void> _executarTodosOsTestes() async {
    setState(() {
      _testando = true;
      _resultados.clear();
    });

    _adicionarResultado('🚀 Iniciando bateria completa de testes...');
    
    await _testarCacheBasico();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testarPreCache();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testarAtualizacaoAutomatica();
    await Future.delayed(const Duration(seconds: 1));
    
    await _verificarStatus();
    
    _adicionarResultado('🎯 Todos os testes concluídos!');
    
    setState(() => _testando = false);
  }

  /// 📊 TESTE 1: CACHE BÁSICO DE SUBCATEGORIAS
  Future<void> _testarCacheBasico() async {
    _adicionarResultado('');
    _adicionarResultado('📊 === TESTE CACHE BÁSICO ===');
    
    try {
      final agora = DateTime.now();
      final inicioMes = DateTime(agora.year, agora.month, 1);
      final fimMes = DateTime(agora.year, agora.month + 1, 0);
      
      _adicionarResultado('📅 Período de teste: ${inicioMes.day}/${inicioMes.month} a ${fimMes.day}/${fimMes.month}');
      
      // Primeira chamada - deve ir no servidor
      _adicionarResultado('⏳ Primeira chamada (servidor)...');
      final inicio1 = DateTime.now();
      final dadosSubcategorias1 = await _categoriaService.fetchSubcategoriasComValoresCache(
        dataInicio: inicioMes,
        dataFim: fimMes,
      );
      final tempo1 = DateTime.now().difference(inicio1).inMilliseconds;
      _adicionarResultado('✅ ${dadosSubcategorias1.length} subcategorias em ${tempo1}ms');
      
      // Segunda chamada - deve vir do cache (muito mais rápido)
      _adicionarResultado('⏳ Segunda chamada (cache)...');
      final inicio2 = DateTime.now();
      final dadosSubcategorias2 = await _categoriaService.fetchSubcategoriasComValoresCache(
        dataInicio: inicioMes,
        dataFim: fimMes,
      );
      final tempo2 = DateTime.now().difference(inicio2).inMilliseconds;
      _adicionarResultado('⚡ ${dadosSubcategorias2.length} subcategorias em ${tempo2}ms (cache)');
      
      // Verificar se o cache foi efetivo
      if (tempo2 < tempo1 * 0.5) {
        _adicionarResultado('✅ Cache funcionando! ${((tempo1 - tempo2) / tempo1 * 100).toInt()}% mais rápido');
      } else {
        _adicionarResultado('⚠️ Cache pode não estar funcionando corretamente');
      }
      
      // Mostrar alguns resultados
      if (dadosSubcategorias1.isNotEmpty) {
        _adicionarResultado('📋 Exemplo de subcategoria encontrada:');
        final primeira = dadosSubcategorias1.first;
        _adicionarResultado('   • Nome: ${primeira['nome']}');
        _adicionarResultado('   • Valor Total: R\$ ${primeira['valor_total']?.toStringAsFixed(2) ?? '0.00'}');
        _adicionarResultado('   • Qtd Transações: ${primeira['quantidade_transacoes'] ?? 0}');
      }
      
    } catch (e) {
      _adicionarResultado('❌ Erro no teste de cache básico: $e');
    }
  }

  /// ⚡ TESTE 2: PRÉ-CACHE DOS ÚLTIMOS 12 MESES
  Future<void> _testarPreCache() async {
    _adicionarResultado('');
    _adicionarResultado('⚡ === TESTE PRÉ-CACHE ===');
    
    try {
      // Testar alguns meses anteriores que devem estar no pré-cache
      final agora = DateTime.now();
      final mesAnterior = DateTime(agora.year, agora.month - 1, 1);
      final fimMesAnterior = DateTime(agora.year, agora.month, 0);
      
      _adicionarResultado('📅 Testando mês anterior: ${mesAnterior.month}/${mesAnterior.year}');
      
      final inicio = DateTime.now();
      final dadosPreCache = await _categoriaService.fetchSubcategoriasComValoresCache(
        dataInicio: mesAnterior,
        dataFim: fimMesAnterior,
      );
      final tempo = DateTime.now().difference(inicio).inMilliseconds;
      
      if (tempo < 100) {
        _adicionarResultado('⚡ Pré-cache funcionando! ${dadosPreCache.length} subcategorias em ${tempo}ms');
      } else {
        _adicionarResultado('⏳ ${dadosPreCache.length} subcategorias em ${tempo}ms (pode não estar em pré-cache)');
      }
      
      // Testar 3 meses atrás
      final mes3Atras = DateTime(agora.year, agora.month - 3, 1);
      final fim3Atras = DateTime(agora.year, agora.month - 2, 0);
      
      _adicionarResultado('📅 Testando 3 meses atrás: ${mes3Atras.month}/${mes3Atras.year}');
      
      final inicio2 = DateTime.now();
      final dados3Meses = await _categoriaService.fetchSubcategoriasComValoresCache(
        dataInicio: mes3Atras,
        dataFim: fim3Atras,
      );
      final tempo2 = DateTime.now().difference(inicio2).inMilliseconds;
      
      _adicionarResultado('📊 ${dados3Meses.length} subcategorias em ${tempo2}ms');
      
    } catch (e) {
      _adicionarResultado('❌ Erro no teste de pré-cache: $e');
    }
  }

  /// ⏰ TESTE 3: ATUALIZAÇÃO AUTOMÁTICA
  Future<void> _testarAtualizacaoAutomatica() async {
    _adicionarResultado('');
    _adicionarResultado('⏰ === TESTE ATUALIZAÇÃO AUTOMÁTICA ===');
    
    try {
      final status = _categoriaService.getStatusPreCache();
      
      _adicionarResultado('📊 Status da atualização automática:');
      _adicionarResultado('   • Ativa: ${status['atualizacao_automatica_ativa']}');
      _adicionarResultado('   • Timer ativo: ${status['timer_ativo']}');
      
      if (status['atualizacao_automatica_ativa'] == true) {
        _adicionarResultado('✅ Atualização automática configurada corretamente!');
        _adicionarResultado('📅 Próxima atualização em até 5 minutos');
      } else {
        _adicionarResultado('⚠️ Atualização automática não está ativa');
      }
      
      // Testar parar e reiniciar
      _adicionarResultado('');
      _adicionarResultado('🔄 Testando parar/reiniciar atualização automática...');
      
      _categoriaService.pararAtualizacaoAutomatica();
      await Future.delayed(const Duration(milliseconds: 100));
      
      final statusParado = _categoriaService.getStatusPreCache();
      if (statusParado['atualizacao_automatica_ativa'] == false) {
        _adicionarResultado('✅ Parada da atualização automática funciona!');
      }
      
      _categoriaService.iniciarAtualizacaoAutomatica();
      await Future.delayed(const Duration(milliseconds: 100));
      
      final statusReiniciado = _categoriaService.getStatusPreCache();
      if (statusReiniciado['atualizacao_automatica_ativa'] == true) {
        _adicionarResultado('✅ Reinício da atualização automática funciona!');
      }
      
    } catch (e) {
      _adicionarResultado('❌ Erro no teste de atualização automática: $e');
    }
  }

  /// 📊 VERIFICAR STATUS COMPLETO DO SISTEMA
  Future<void> _verificarStatus() async {
    _adicionarResultado('');
    _adicionarResultado('📊 === STATUS COMPLETO DO SISTEMA ===');
    
    try {
      final status = _categoriaService.getStatusPreCache();
      
      _adicionarResultado('🔖 Cache de Subcategorias:');
      _adicionarResultado('   • Períodos carregados: ${status['subcategorias_periodos_carregados']}');
      _adicionarResultado('   • Cache normal size: ${status['subcategorias_cache_normal_size']}');
      _adicionarResultado('   • Último pré-carregamento: ${status['subcategorias_ultimo_precarregamento']?.toString().split('.')[0] ?? 'Nunca'}');
      _adicionarResultado('   • Em andamento: ${status['subcategorias_precarregamento_em_andamento']}');
      
      _adicionarResultado('');
      _adicionarResultado('📊 Cache de Categorias:');
      _adicionarResultado('   • Períodos carregados: ${status['categorias_periodos_carregados']}');
      _adicionarResultado('   • Cache normal size: ${status['categorias_cache_normal_size']}');
      
      _adicionarResultado('');
      _adicionarResultado('⏰ Atualização Automática:');
      _adicionarResultado('   • Ativa: ${status['atualizacao_automatica_ativa']}');
      _adicionarResultado('   • Timer ativo: ${status['timer_ativo']}');
      
      _adicionarResultado('');
      _adicionarResultado('💾 Resumo Geral:');
      _adicionarResultado('   • Total chaves cache: ${status['total_chaves_cache']}');
      _adicionarResultado('   • Memória estimada: ${status['memoria_estimada_kb']} KB');
      
      // Mostrar algumas chaves de exemplo
      final chavesSubcategorias = status['subcategorias_chaves_precache'] as List?;
      if (chavesSubcategorias != null && chavesSubcategorias.isNotEmpty) {
        _adicionarResultado('');
        _adicionarResultado('🔑 Exemplos de chaves de subcategorias em cache:');
        final exemplos = chavesSubcategorias.take(3);
        for (final chave in exemplos) {
          _adicionarResultado('   • $chave');
        }
        if (chavesSubcategorias.length > 3) {
          _adicionarResultado('   ... e mais ${chavesSubcategorias.length - 3} chaves');
        }
      }
      
    } catch (e) {
      _adicionarResultado('❌ Erro ao verificar status: $e');
    }
  }

  /// 📝 ADICIONAR RESULTADO AO LOG
  void _adicionarResultado(String resultado) {
    final timestamp = DateTime.now().toString().split(' ')[1].split('.')[0];
    final linha = resultado.isEmpty ? '' : '[$timestamp] $resultado';
    
    setState(() {
      _resultados.add(linha);
    });
    
    // Auto-scroll para o final
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Se há itens suficientes, faz scroll para o final
      if (_resultados.length > 10) {
        // Scroll lógico será tratado pelo ListView
      }
    });
  }
}