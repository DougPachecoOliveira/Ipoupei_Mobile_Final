import 'dart:developer';
import '../../../database/local_database.dart';
import '../../../auth_integration.dart';

/// ✅ SERVIÇO DE RELATÓRIOS - EQUIVALENTE AO useRelatorios.js
/// Responsável por gerar relatórios detalhados e análises avançadas
class RelatoriosService {
  static final RelatoriosService _instance = RelatoriosService._internal();
  static RelatoriosService get instance => _instance;
  RelatoriosService._internal();

  final LocalDatabase _localDb = LocalDatabase.instance;
  final AuthIntegration _authIntegration = AuthIntegration.instance;
  
  String? get _userId => _authIntegration.authService.currentUser?.id;

  /// ✅ BUSCAR DADOS DE CATEGORIAS PARA RELATÓRIOS
  /// Equivalente ao fetchCategoriaData do React
  Future<Map<String, dynamic>> fetchCategoriaData(Map<String, dynamic> filters) async {
    final userId = _userId;
    if (userId == null) return {'success': false, 'error': 'Usuário não autenticado'};

    try {
      final periodo = filters['periodo'] as Map<String, DateTime>;
      final contas = filters['contas'] as List<String>?;
      final categorias = filters['categorias'] as List<String>?;
      final tipoTransacao = filters['tipoTransacao'] as String? ?? 'todas';
      
      final dataInicio = periodo['inicio']!.toIso8601String().split('T')[0];
      final dataFim = periodo['fim']!.toIso8601String().split('T')[0];

      // Construir query base
      var whereClause = 'usuario_id = ? AND data >= ? AND data <= ?';
      var whereArgs = <dynamic>[userId, dataInicio, dataFim];

      // Aplicar filtros
      if (contas != null && contas.isNotEmpty) {
        whereClause += ' AND conta_id IN (${contas.map((_) => '?').join(',')})';
        whereArgs.addAll(contas);
      }

      if (categorias != null && categorias.isNotEmpty) {
        whereClause += ' AND categoria_id IN (${categorias.map((_) => '?').join(',')})';
        whereArgs.addAll(categorias);
      }

      if (tipoTransacao != 'todas') {
        whereClause += ' AND tipo = ?';
        whereArgs.add(tipoTransacao);
      }

      final transacoesResult = await _localDb.database?.query(
        'transacoes',
        where: whereClause,
        whereArgs: whereArgs,
      ) ?? [];

      // Processar dados para o formato do relatório
      final dadosProcessados = await _processarDadosCategorias(transacoesResult, tipoTransacao);
      
      return {'success': true, 'data': dadosProcessados};
    } catch (err) {
      log('❌ Erro ao buscar dados de categorias: $err');
      return {'success': false, 'error': 'Não foi possível carregar os dados de categorias'};
    }
  }

  /// ✅ BUSCAR DADOS DE EVOLUÇÃO TEMPORAL
  /// Equivalente ao fetchEvolucaoData do React
  Future<Map<String, dynamic>> fetchEvolucaoData(Map<String, dynamic> filters) async {
    final userId = _userId;
    if (userId == null) return {'success': false, 'error': 'Usuário não autenticado'};

    try {
      final periodo = filters['periodo'] as Map<String, DateTime>;
      final dataInicio = periodo['inicio']!.toIso8601String().split('T')[0];
      final dataFim = periodo['fim']!.toIso8601String().split('T')[0];

      // Buscar transações do período
      final transacoesResult = await _localDb.database?.query(
        'transacoes',
        where: 'usuario_id = ? AND data >= ? AND data <= ?',
        whereArgs: [userId, dataInicio, dataFim],
        orderBy: 'data ASC',
      ) ?? [];

      // Buscar saldos das contas ativas
      final contasResult = await _localDb.database?.query(
        'contas',
        where: 'usuario_id = ? AND ativo = 1',
        whereArgs: [userId],
      ) ?? [];

      // Processar dados de evolução
      final dadosProcessados = _processarDadosEvolucao(transacoesResult, contasResult, periodo);
      
      return {'success': true, 'data': dadosProcessados};
    } catch (err) {
      log('❌ Erro ao buscar dados de evolução: $err');
      return {'success': false, 'error': 'Não foi possível carregar os dados de evolução'};
    }
  }

  /// ✅ BUSCAR DADOS DE PROJEÇÃO FINANCEIRA
  /// Equivalente ao fetchProjecaoData do React
  Future<Map<String, dynamic>> fetchProjecaoData(
    Map<String, dynamic> filters, 
    Map<String, dynamic> configuracao
  ) async {
    final userId = _userId;
    if (userId == null) return {'success': false, 'error': 'Usuário não autenticado'};

    try {
      final tipoProjecao = configuracao['tipoProjecao'] as String;
      final periodoProjecao = configuracao['periodoProjecao'] as int;
      final incluirInflacao = configuracao['incluirInflacao'] as bool;

      // Buscar dados base para projeções
      final futures = await Future.wait([
        _localDb.database?.query('transacoes', where: 'usuario_id = ? AND recorrente = 1', whereArgs: [userId]) ?? Future.value(<Map<String, dynamic>>[]),
        _localDb.database?.query('contas', where: 'usuario_id = ? AND ativo = 1', whereArgs: [userId]) ?? Future.value(<Map<String, dynamic>>[]),
        _localDb.database?.query('cartoes', where: 'usuario_id = ? AND ativo = 1', whereArgs: [userId]) ?? Future.value(<Map<String, dynamic>>[]),
      ]);

      final transacoes = futures[0] as List<Map<String, dynamic>>;
      final contas = futures[1] as List<Map<String, dynamic>>;
      final cartoes = futures[2] as List<Map<String, dynamic>>;

      // Processar dados de projeção
      final dadosProcessados = _processarDadosProjecao(
        transacoes, contas, cartoes, 
        {'tipoProjecao': tipoProjecao, 'periodoProjecao': periodoProjecao, 'incluirInflacao': incluirInflacao}
      );
      
      return {'success': true, 'data': dadosProcessados};
    } catch (err) {
      log('❌ Erro ao buscar dados de projeção: $err');
      return {'success': false, 'error': 'Não foi possível carregar os dados de projeção'};
    }
  }

  /// ===== MÉTODOS DE PROCESSAMENTO (equivalentes ao React) =====

  /// Processa dados de transações para relatório de categorias
  Future<List<Map<String, dynamic>>> _processarDadosCategorias(
    List<Map<String, dynamic>> transacoes, 
    String tipoTransacao
  ) async {
    final grupos = <String, Map<String, dynamic>>{};
    
    for (final transacao in transacoes) {
      final categoriaId = transacao['categoria_id'] as String?;
      final subcategoriaId = transacao['subcategoria_id'] as String?;
      
      // Buscar dados da categoria
      String categoriaNome = 'Sem categoria';
      String categoriaCor = '#6B7280';
      
      if (categoriaId != null) {
        final categoriaResult = await _localDb.database?.query(
          'categorias',
          columns: ['nome', 'cor'],
          where: 'id = ?',
          whereArgs: [categoriaId],
          limit: 1,
        ) ?? [];
        
        if (categoriaResult.isNotEmpty) {
          categoriaNome = categoriaResult.first['nome'] as String;
          categoriaCor = categoriaResult.first['cor'] as String? ?? '#6B7280';
        }
      }

      // Buscar dados da subcategoria
      String subcategoriaNome = 'Geral';
      if (subcategoriaId != null) {
        final subcategoriaResult = await _localDb.database?.query(
          'subcategorias',
          columns: ['nome'],
          where: 'id = ?',
          whereArgs: [subcategoriaId],
          limit: 1,
        ) ?? [];
        
        if (subcategoriaResult.isNotEmpty) {
          subcategoriaNome = subcategoriaResult.first['nome'] as String;
        }
      }
      
      if (!grupos.containsKey(categoriaNome)) {
        grupos[categoriaNome] = {
          'nome': categoriaNome,
          'valor': 0.0,
          'cor': categoriaCor,
          'subcategorias': <String, Map<String, dynamic>>{},
        };
      }
      
      final valor = ((transacao['valor'] as num?)?.toDouble() ?? 0.0);
      grupos[categoriaNome]!['valor'] = (grupos[categoriaNome]!['valor'] as double) + valor;
      
      final subcategorias = grupos[categoriaNome]!['subcategorias'] as Map<String, Map<String, dynamic>>;
      if (!subcategorias.containsKey(subcategoriaNome)) {
        subcategorias[subcategoriaNome] = {
          'nome': subcategoriaNome,
          'valor': 0.0,
        };
      }
      
      subcategorias[subcategoriaNome]!['valor'] = 
        (subcategorias[subcategoriaNome]!['valor'] as double) + valor;
    }
    
    // Converter para array e calcular percentuais
    final resultado = grupos.values.map((categoria) {
      final subcategorias = (categoria['subcategorias'] as Map<String, Map<String, dynamic>>).values.toList();
      final totalCategoria = categoria['valor'] as double;
      
      return {
        ...categoria,
        'subcategorias': subcategorias.map((sub) => {
          ...sub,
          'percentual': totalCategoria > 0 ? (((sub['valor'] as double) / totalCategoria) * 100).toStringAsFixed(1) : '0',
        }).toList(),
      };
    }).toList();
    
    // Calcular percentual total
    final total = resultado.fold<double>(0.0, (acc, cat) => acc + (cat['valor'] as double));
    
    return resultado.map((categoria) => {
      ...categoria,
      'percentual': total > 0 ? (((categoria['valor'] as double) / total) * 100).toStringAsFixed(1) : '0',
    }).toList()..sort((a, b) => (b['valor'] as double).compareTo(a['valor'] as double));
  }

  /// Processa dados para relatório de evolução temporal
  List<Map<String, dynamic>> _processarDadosEvolucao(
    List<Map<String, dynamic>> transacoes,
    List<Map<String, dynamic>> contas,
    Map<String, DateTime> periodo,
  ) {
    final meses = <Map<String, dynamic>>[];
    final inicio = DateTime(periodo['inicio']!.year, periodo['inicio']!.month, 1);
    final fim = DateTime(periodo['fim']!.year, periodo['fim']!.month + 1, 0);
    
    var mesAtual = inicio;
    var patrimonioAcumulado = contas.fold<double>(0.0, (acc, conta) => 
      acc + ((conta['saldo'] as num?)?.toDouble() ?? 0.0)
    );
    
    while (mesAtual.isBefore(fim) || mesAtual.isAtSameMomentAs(fim)) {
      final inicioMes = DateTime(mesAtual.year, mesAtual.month, 1);
      final fimMes = DateTime(mesAtual.year, mesAtual.month + 1, 0);
      
      // Filtrar transações do mês
      final transacoesMes = transacoes.where((t) {
        final dataTransacao = DateTime.tryParse(t['data'] as String);
        if (dataTransacao == null) return false;
        return dataTransacao.isAfter(inicioMes.subtract(Duration(days: 1))) &&
               dataTransacao.isBefore(fimMes.add(Duration(days: 1)));
      }).toList();
      
      // Calcular receitas e despesas do mês
      final receitas = transacoesMes
          .where((t) => t['tipo'] == 'receita')
          .fold<double>(0.0, (acc, t) => acc + ((t['valor'] as num?)?.toDouble() ?? 0.0));
          
      final despesas = transacoesMes
          .where((t) => t['tipo'] == 'despesa')
          .fold<double>(0.0, (acc, t) => acc + ((t['valor'] as num?)?.toDouble() ?? 0.0));
      
      final saldoMes = receitas - despesas;
      patrimonioAcumulado += saldoMes;
      
      meses.add({
        'periodo': '${_getNomeMes(mesAtual.month)} ${mesAtual.year}',
        'receitas': receitas,
        'despesas': despesas,
        'saldo': saldoMes,
        'patrimonio': patrimonioAcumulado,
        'data': mesAtual.toIso8601String(),
      });
      
      mesAtual = DateTime(mesAtual.year, mesAtual.month + 1, 1);
    }
    
    return meses;
  }

  /// Processa dados para relatório de projeções
  List<Map<String, dynamic>> _processarDadosProjecao(
    List<Map<String, dynamic>> transacoes,
    List<Map<String, dynamic>> contas,
    List<Map<String, dynamic>> cartoes,
    Map<String, dynamic> config,
  ) {
    final tipoProjecao = config['tipoProjecao'] as String;
    final periodoProjecao = config['periodoProjecao'] as int;
    final incluirInflacao = config['incluirInflacao'] as bool;
    
    // Calcular dados base
    final receitaFixa = transacoes
        .where((t) => t['tipo'] == 'receita' && (t['recorrente'] as int?) == 1)
        .fold<double>(0.0, (acc, t) => acc + ((t['valor'] as num?)?.toDouble() ?? 0.0));
        
    final despesaFixa = transacoes
        .where((t) => t['tipo'] == 'despesa' && (t['recorrente'] as int?) == 1)
        .fold<double>(0.0, (acc, t) => acc + ((t['valor'] as num?)?.toDouble() ?? 0.0));
        
    final saldoAtual = contas.fold<double>(0.0, (acc, conta) => 
      acc + ((conta['saldo'] as num?)?.toDouble() ?? 0.0));
    
    // Configurações por tipo de projeção
    const configs = {
      'otimista': {'crescimento': 0.05, 'reducao': 0.02, 'inflacao': 0.005},
      'conservador': {'crescimento': 0.02, 'reducao': 0.0, 'inflacao': 0.008},
      'pessimista': {'crescimento': -0.01, 'reducao': -0.01, 'inflacao': 0.012},
    };
    
    final cenario = configs[tipoProjecao] ?? configs['conservador']!;
    final projecoes = <Map<String, dynamic>>[];
    
    var patrimonioAtual = saldoAtual;
    
    for (int mes = 0; mes <= periodoProjecao; mes++) {
      final fatorCrescimento = _calcularPotencia(1 + (cenario['crescimento'] as double), mes);
      final fatorInflacao = incluirInflacao ? _calcularPotencia(1 + (cenario['inflacao'] as double), mes) : 1.0;
      final fatorReducao = _calcularPotencia(1 + (cenario['reducao'] as double), mes);
      
      final receitaProjetada = receitaFixa * fatorCrescimento;
      final despesaProjetada = despesaFixa * fatorInflacao * fatorReducao;
      final saldoMensal = receitaProjetada - despesaProjetada;
      
      if (mes > 0) {
        patrimonioAtual += saldoMensal;
      }
      
      final data = DateTime.now().add(Duration(days: mes * 30));
      
      projecoes.add({
        'periodo': '${_getNomeMes(data.month)} ${data.year}',
        'receita': receitaProjetada.round(),
        'despesa': despesaProjetada.round(),
        'saldo_mensal': saldoMensal.round(),
        'patrimonio': patrimonioAtual.round(),
        'mes': mes,
      });
    }
    
    return projecoes;
  }

  /// ===== MÉTODOS AUXILIARES =====

  String _getNomeMes(int mes) {
    const nomes = ['', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 
                   'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return nomes[mes] ?? 'Mês';
  }

  double _calcularPotencia(double base, int expoente) {
    if (expoente == 0) return 1.0;
    double resultado = 1.0;
    for (int i = 0; i < expoente; i++) {
      resultado *= base;
    }
    return resultado;
  }
}