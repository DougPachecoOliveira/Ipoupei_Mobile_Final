import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../services/valor_hora_service.dart';
import '../../../database/local_database.dart';
import '../../../auth_integration.dart';

/// Widget chamativo que mostra o maior gasto em horas de trabalho
/// "Este mês você trabalhou X horas para pagar [Categoria/Cartão]"
class ValorHoraWidget extends StatefulWidget {
  final DateTime? mesReferencia;

  const ValorHoraWidget({
    super.key,
    this.mesReferencia,
  });

  @override
  State<ValorHoraWidget> createState() => _ValorHoraWidgetState();
}

class _ValorHoraWidgetState extends State<ValorHoraWidget> {
  final _valorHoraService = ValorHoraService.instance;
  final _localDb = LocalDatabase.instance;
  final _authIntegration = AuthIntegration.instance;

  Map<String, dynamic>? _maiorCategoria;
  Map<String, dynamic>? _maiorCartao;
  double? _valorHora;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarMaiorGasto();
  }

  @override
  void didUpdateWidget(ValorHoraWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mesReferencia != widget.mesReferencia) {
      _carregarMaiorGasto();
    }
  }

  Future<void> _carregarMaiorGasto() async {
    setState(() => _loading = true);

    try {
      // Buscar valor da hora
      final valorHora = await _valorHoraService.calcularValorHora();

      if (valorHora == null) {
        setState(() {
          _loading = false;
          _valorHora = null;
          _maiorCategoria = null;
          _maiorCartao = null;
        });
        return;
      }

      // Buscar maior gasto por categoria
      final maiorCategoria = await _buscarMaiorCategoria();

      // Buscar maior gasto por cartão
      final maiorCartao = await _buscarMaiorCartao();

      // Calcular horas para ambos
      if (maiorCategoria != null) {
        final horas = maiorCategoria['valor'] / valorHora;
        final percentual = await _valorHoraService.calcularPercentualRenda(maiorCategoria['valor']);
        maiorCategoria['horas'] = horas;
        maiorCategoria['percentual'] = percentual ?? 0.0;
      }

      if (maiorCartao != null) {
        final horas = maiorCartao['valor'] / valorHora;
        final percentual = await _valorHoraService.calcularPercentualRenda(maiorCartao['valor']);
        maiorCartao['horas'] = horas;
        maiorCartao['percentual'] = percentual ?? 0.0;
      }

      setState(() {
        _valorHora = valorHora;
        _maiorCategoria = maiorCategoria;
        _maiorCartao = maiorCartao;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _valorHora = null;
        _maiorCategoria = null;
        _maiorCartao = null;
      });
    }
  }

  Future<Map<String, dynamic>?> _buscarMaiorCategoria() async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) return null;

    try {
      final mesRef = widget.mesReferencia ?? DateTime.now();
      final inicioMes = DateTime(mesRef.year, mesRef.month, 1);
      final fimMes = DateTime(mesRef.year, mesRef.month + 1, 0);

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

      final gastosPorCategoria = <String, double>{};

      for (final row in result) {
        final valor = ((row['valor'] as num?) ?? 0).toDouble();
        final categoriaId = row['categoria_id'] as String?;

        if (categoriaId != null) {
          gastosPorCategoria[categoriaId] =
              (gastosPorCategoria[categoriaId] ?? 0.0) + valor;
        }
      }

      if (gastosPorCategoria.isEmpty) return null;

      // Encontrar categoria com maior gasto
      final categoriaId = gastosPorCategoria.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      final valor = gastosPorCategoria[categoriaId]!;

      // Buscar nome da categoria
      final categoriaResult = await _localDb.database?.query(
        'categorias',
        columns: ['nome', 'cor'],
        where: 'id = ?',
        whereArgs: [categoriaId],
        limit: 1,
      ) ?? [];

      if (categoriaResult.isEmpty) return null;

      return {
        'tipo': 'categoria',
        'nome': categoriaResult.first['nome'] as String,
        'cor': categoriaResult.first['cor'] as String,
        'valor': valor,
      };
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _buscarMaiorCartao() async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) return null;

    try {
      final mesRef = widget.mesReferencia ?? DateTime.now();
      final inicioMes = DateTime(mesRef.year, mesRef.month, 1);
      final fimMes = DateTime(mesRef.year, mesRef.month + 1, 0);

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

      final gastosPorCartao = <String, double>{};

      for (final row in result) {
        final valor = ((row['valor'] as num?) ?? 0).toDouble();
        final cartaoId = row['cartao_id'] as String?;

        if (cartaoId != null) {
          gastosPorCartao[cartaoId] =
              (gastosPorCartao[cartaoId] ?? 0.0) + valor;
        }
      }

      if (gastosPorCartao.isEmpty) return null;

      // Encontrar cartão com maior gasto
      final cartaoId = gastosPorCartao.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      final valor = gastosPorCartao[cartaoId]!;

      // Buscar nome do cartão
      final cartaoResult = await _localDb.database?.query(
        'cartoes',
        columns: ['nome', 'cor'],
        where: 'id = ?',
        whereArgs: [cartaoId],
        limit: 1,
      ) ?? [];

      if (cartaoResult.isEmpty) return null;

      return {
        'tipo': 'cartao',
        'nome': cartaoResult.first['nome'] as String,
        'cor': cartaoResult.first['cor'] as String? ?? '#6B7280',
        'valor': valor,
      };
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    // Se não tem dados do perfil (renda/horas), mostrar convite para diagnóstico
    if (_valorHora == null || (_maiorCategoria == null && _maiorCartao == null)) {
      return _buildConviteDiagnostico(context);
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/valor-hora');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.roxoHeader, Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
            Column(
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
                        Icons.schedule,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Quantas horas trabalho para pagar:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Dados: Categoria e Cartão lado a lado
                Row(
                  children: [
                    // Maior Categoria
                    if (_maiorCategoria != null)
                      Expanded(
                        child: _buildGastoItem(
                          tipo: 'categoria',
                          emoji: '💰',
                          label: 'Categoria',
                          nome: _maiorCategoria!['nome'] as String,
                          horas: _maiorCategoria!['horas'] as double,
                          valor: _maiorCategoria!['valor'] as double,
                        ),
                      ),

                    // Divider
                    if (_maiorCategoria != null && _maiorCartao != null)
                      Container(
                        width: 1,
                        height: 60,
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

                    // Maior Cartão
                    if (_maiorCartao != null)
                      Expanded(
                        child: _buildGastoItem(
                          tipo: 'cartao',
                          emoji: '💳',
                          label: 'Cartão',
                          nome: _maiorCartao!['nome'] as String,
                          horas: _maiorCartao!['horas'] as double,
                          valor: _maiorCartao!['valor'] as double,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Botão Ver Detalhes
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Ver Detalhes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.roxoHeader,
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

  Widget _buildGastoItem({
    required String tipo,
    required String emoji,
    required String label,
    required String nome,
    required double horas,
    required double valor,
  }) {
    final horasFormatadas = _valorHoraService.formatarHoras(horas);

    // Formatar valor com separador de milhar
    String formatarValor(double valor) {
      final partes = valor.toStringAsFixed(2).split('.');
      final inteiro = partes[0];
      final decimal = partes[1];

      // Adicionar separador de milhar
      String inteiroFormatado = '';
      int contador = 0;
      for (int i = inteiro.length - 1; i >= 0; i--) {
        if (contador == 3) {
          inteiroFormatado = '.$inteiroFormatado';
          contador = 0;
        }
        inteiroFormatado = inteiro[i] + inteiroFormatado;
        contador++;
      }

      return 'R\$ $inteiroFormatado,$decimal';
    }

    final valorFormatado = formatarValor(valor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withAlpha(182),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$emoji $nome',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          horasFormatadas,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valorFormatado,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  /// Widget bonito de convite para fazer o diagnóstico
  Widget _buildConviteDiagnostico(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/diagnostico');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.tealPrimary,
              AppColors.tealPrimary.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.tealPrimary.withAlpha(78),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícone com fundo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(52),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.schedule,
                color: Colors.white,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quanto vale sua hora?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure sua renda e descubra',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withAlpha(208),
                    ),
                  ),
                ],
              ),
            ),

            // Botão branco
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Configurar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tealPrimary,
                ),
              ),
            ),
          ],
        ),
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
