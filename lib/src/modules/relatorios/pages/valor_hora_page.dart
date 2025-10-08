import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../services/valor_hora_service.dart';
import '../../../database/local_database.dart';
import '../../../auth_integration.dart';
import '../../cartoes/models/cartao_model.dart';
import '../../cartoes/widgets/cartao_card.dart';
import '../../categorias/data/categoria_icons.dart';

/// Página "Quanto Vale Minha Hora"
/// Mostra quantas horas você trabalha para pagar cada categoria/cartão
class ValorHoraPage extends StatefulWidget {
  const ValorHoraPage({super.key});

  @override
  State<ValorHoraPage> createState() => _ValorHoraPageState();
}

class _ValorHoraPageState extends State<ValorHoraPage> {
  final _valorHoraService = ValorHoraService.instance;
  final _localDb = LocalDatabase.instance;
  final _authIntegration = AuthIntegration.instance;

  Map<String, dynamic>? _dadosPerfil;
  List<Map<String, dynamic>> _gastosCategoria = [];
  List<Map<String, dynamic>> _gastosCartao = [];
  bool _loading = true;
  String? _erro;

  // Filtro de visualização: 'categorias' ou 'cartoes'
  String _filtroAtivo = 'categorias';

  // Controle de mês/período
  DateTime _mesAtual = DateTime.now();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      // 1. Buscar dados do perfil (renda, horas, valor/hora)
      final dadosPerfil = await _valorHoraService.obterDadosCompletos();

      if (dadosPerfil == null) {
        setState(() {
          _erro = 'Configure sua renda mensal e horas trabalhadas no Diagnóstico';
          _loading = false;
        });
        return;
      }

      // 2. Buscar gastos por categoria do mês atual
      final gastosCategoria = await _buscarGastosPorCategoria();

      // 3. Buscar gastos por cartão do mês atual
      final gastosCartao = await _buscarGastosPorCartao();

      setState(() {
        _dadosPerfil = dadosPerfil;
        _gastosCategoria = gastosCategoria;
        _gastosCartao = gastosCartao;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar dados: $e';
        _loading = false;
      });
    }
  }

  /// Buscar gastos por categoria do mês selecionado
  Future<List<Map<String, dynamic>>> _buscarGastosPorCategoria() async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) return [];

    try {
      final inicioMes = DateTime(_mesAtual.year, _mesAtual.month, 1);
      final fimMes = DateTime(_mesAtual.year, _mesAtual.month + 1, 0);

      final result = await _localDb.database?.query(
        'transacoes',
        columns: ['valor', 'categoria_id'],
        where: '''
          usuario_id = ?
          AND tipo = 'despesa'
          AND data >= ?
          AND data <= ?
        ''',
        whereArgs: [
          userId,
          inicioMes.toIso8601String().split('T')[0],
          fimMes.toIso8601String().split('T')[0],
        ],
      ) ?? [];

      // Agrupar por categoria
      final gastosPorCategoria = <String, Map<String, dynamic>>{};

      for (final row in result) {
        final valor = ((row['valor'] as num?) ?? 0).toDouble();
        final categoriaId = row['categoria_id'] as String?;

        if (categoriaId == null) continue;

        // Buscar dados da categoria
        final categoriaResult = await _localDb.database?.query(
          'categorias',
          columns: ['nome', 'cor', 'icone'],
          where: 'id = ?',
          whereArgs: [categoriaId],
          limit: 1,
        ) ?? [];

        if (categoriaResult.isEmpty) continue;

        final categoriaData = categoriaResult.first;

        if (!gastosPorCategoria.containsKey(categoriaId)) {
          gastosPorCategoria[categoriaId] = {
            'categoria_id': categoriaId,
            'categoria_nome': categoriaData['nome'] as String,
            'categoria_cor': categoriaData['cor'] as String,
            'categoria_icone': categoriaData['icone'] as String? ?? 'folder',
            'valor_total': 0.0,
          };
        }

        gastosPorCategoria[categoriaId]!['valor_total'] =
            (gastosPorCategoria[categoriaId]!['valor_total'] as double) + valor;
      }

      // Converter para lista e ordenar por valor (do maior para o menor)
      final lista = gastosPorCategoria.values.toList();
      lista.sort((a, b) =>
          (b['valor_total'] as double).compareTo(a['valor_total'] as double));

      // Retornar TODOS os gastos
      return lista;
    } catch (e) {
      print('❌ Erro ao buscar gastos por categoria: $e');
      return [];
    }
  }

  /// Buscar gastos por cartão do mês selecionado
  Future<List<Map<String, dynamic>>> _buscarGastosPorCartao() async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) return [];

    try {
      final inicioMes = DateTime(_mesAtual.year, _mesAtual.month, 1);
      final fimMes = DateTime(_mesAtual.year, _mesAtual.month + 1, 0);

      final result = await _localDb.database?.query(
        'transacoes',
        columns: ['valor', 'cartao_id'],
        where: '''
          usuario_id = ?
          AND cartao_id IS NOT NULL
          AND data >= ?
          AND data <= ?
        ''',
        whereArgs: [
          userId,
          inicioMes.toIso8601String().split('T')[0],
          fimMes.toIso8601String().split('T')[0],
        ],
      ) ?? [];

      // Agrupar por cartão
      final gastosPorCartao = <String, Map<String, dynamic>>{};

      for (final row in result) {
        final valor = ((row['valor'] as num?) ?? 0).toDouble();
        final cartaoId = row['cartao_id'] as String?;

        if (cartaoId == null) continue;

        // Buscar dados completos do cartão
        final cartaoResult = await _localDb.database?.query(
          'cartoes',
          where: 'id = ?',
          whereArgs: [cartaoId],
          limit: 1,
        ) ?? [];

        if (cartaoResult.isEmpty) continue;

        final cartaoData = cartaoResult.first;

        if (!gastosPorCartao.containsKey(cartaoId)) {
          gastosPorCartao[cartaoId] = {
            'cartao_id': cartaoId,
            'cartao_nome': cartaoData['nome'] as String,
            'cartao_cor': cartaoData['cor'] as String? ?? '#6B7280',
            'cartao_data': cartaoData, // Dados completos do cartão
            'valor_total': 0.0,
          };
        }

        gastosPorCartao[cartaoId]!['valor_total'] =
            (gastosPorCartao[cartaoId]!['valor_total'] as double) + valor;
      }

      // Converter para lista e ordenar por valor (do maior para o menor)
      final lista = gastosPorCartao.values.toList();
      lista.sort((a, b) =>
          (b['valor_total'] as double).compareTo(a['valor_total'] as double));

      // Retornar TODOS os gastos
      return lista;
    } catch (e) {
      print('❌ Erro ao buscar gastos por cartão: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? _buildErro()
              : RefreshIndicator(
                  onRefresh: _carregarDados,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderValorHora(),
                        const SizedBox(height: 24),
                        _buildFiltroVisualizacao(),
                        const SizedBox(height: 16),
                        if (_filtroAtivo == 'categorias')
                          _buildSecaoGastos(
                            titulo: '💰 Gastos por Categoria',
                            gastos: _gastosCategoria,
                            tipoNome: 'categoria_nome',
                            tipoCor: 'categoria_cor',
                            tipo: 'categoria',
                          )
                        else
                          _buildSecaoGastos(
                            titulo: '💳 Gastos por Cartão',
                            gastos: _gastosCartao,
                            tipoNome: 'cartao_nome',
                            tipoCor: 'cartao_cor',
                            tipo: 'cartao',
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.roxoHeader,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      title: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Valor da Hora',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              GestureDetector(
                onTap: _mesAnterior,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              Text(
                _formatarMesAno(_mesAtual),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: _proximoMes,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _mesAnterior() {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month - 1, 1);
    });
    _carregarDados();
  }

  void _proximoMes() {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + 1, 1);
    });
    _carregarDados();
  }

  String _formatarMesAno(DateTime data) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    final ano = data.year.toString().substring(2);
    return '${meses[data.month - 1]}/$ano';
  }

  String _formatarMesAnoCompleto(DateTime data) {
    final meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${meses[data.month - 1]} ${data.year}';
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: AppColors.laranjaAlerta,
            ),
            const SizedBox(height: 16),
            Text(
              _erro!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.cinzaTexto,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/diagnostico');
              },
              icon: const Icon(Icons.settings),
              label: const Text('Ir para Diagnóstico'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roxoHeader,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroVisualizacao() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBotaoFiltro(
              label: '💰 Categorias',
              value: 'categorias',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBotaoFiltro(
              label: '💳 Cartões',
              value: 'cartoes',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoFiltro({
    required String label,
    required String value,
  }) {
    final isActive = _filtroAtivo == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroAtivo = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.roxoHeader : AppColors.cinzaTexto,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderValorHora() {
    if (_dadosPerfil == null) return const SizedBox.shrink();

    final valorHora = _dadosPerfil!['valor_hora'] as double;
    final rendaMensal = _dadosPerfil!['renda_mensal'] as double;
    final horasMes = _dadosPerfil!['horas_trabalhadas_mes'] as int;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.roxoHeader,
            AppColors.roxoHeader.withAlpha(208),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.roxoHeader.withAlpha(78),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Círculo decorativo
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

          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Valor da Hora - destaque principal
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(52),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.attach_money,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Valor da Hora',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withAlpha(208),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(valorHora),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider vertical
                Container(
                  width: 1,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withAlpha(26),
                        Colors.white.withAlpha(78),
                        Colors.white.withAlpha(26),
                      ],
                    ),
                  ),
                ),

                // Renda e Horas
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Renda
                      Text(
                        'Renda Mensal',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withAlpha(182),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(rendaMensal),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Horas
                      Text(
                        'Horas Trabalhadas',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withAlpha(182),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$horasMes horas',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoGastos({
    required String titulo,
    required List<Map<String, dynamic>> gastos,
    required String tipoNome,
    required String tipoCor,
    required String tipo,
  }) {
    if (gastos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum gasto encontrado neste mês',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.cinzaTexto,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...gastos.map((gasto) => _buildItemGasto(gasto, tipoNome, tipoCor, tipo)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemGasto(
    Map<String, dynamic> gasto,
    String tipoNome,
    String tipoCor,
    String tipo,
  ) {
    // Se for cartão, usar o CartaoCard
    if (tipo == 'cartao' && gasto.containsKey('cartao_data')) {
      return _buildCartaoItem(gasto);
    }

    // Para categorias, usar o card customizado
    final nome = gasto[tipoNome] as String;
    final cor = _parseColor(gasto[tipoCor] as String);
    final icone = gasto['categoria_icone'] as String? ?? 'folder';
    final valor = gasto['valor_total'] as double;
    final valorHora = _dadosPerfil!['valor_hora'] as double;
    final horas = valor / valorHora;
    final percentual =
        (valor / (_dadosPerfil!['renda_mensal'] as double)) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cor, cor.withAlpha(208)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cor.withAlpha(78),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CategoriaIcons.renderIcon(
                      icone,
                      20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.format(valor),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                '${_valorHoraService.formatarHoras(horas)} de trabalho',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.pie_chart,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                '${percentual.toStringAsFixed(1)}% da sua renda',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartaoItem(Map<String, dynamic> gasto) {
    final cartaoData = gasto['cartao_data'] as Map<String, dynamic>;
    final cartao = CartaoModel.fromJson(cartaoData);
    final valor = gasto['valor_total'] as double;
    final valorHora = _dadosPerfil!['valor_hora'] as double;
    final horas = valor / valorHora;
    final percentual = (valor / (_dadosPerfil!['renda_mensal'] as double)) * 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Card do cartão (visual bonito)
          CartaoCard(
            cartao: cartao,
            valorUtilizado: valor,
            showUtilizacao: true,
            showFaturaInfo: false,
            isCompact: false,
          ),

          // Info de horas trabalhadas - MESMA LARGURA DO CARTÃO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 18,
                        color: AppColors.roxoHeader,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Você trabalhou ${_valorHoraService.formatarHoras(horas)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cinzaEscuro,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(valor),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.roxoHeader,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.pie_chart,
                        size: 16,
                        color: AppColors.cinzaTexto,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${percentual.toStringAsFixed(1)}% da sua renda mensal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.cinzaTexto,
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
    );
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
      } else if (colorStr.startsWith('0x')) {
        return Color(int.parse(colorStr));
      } else {
        return Color(int.parse('0xFF$colorStr'));
      }
    } catch (e) {
      return AppColors.roxoHeader;
    }
  }
}
