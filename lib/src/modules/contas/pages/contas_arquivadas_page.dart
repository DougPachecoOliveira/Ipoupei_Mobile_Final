// 🗃️ Contas Arquivadas Page - iPoupei Mobile
//
// Página para exibir e gerenciar contas arquivadas
// Permite restaurar contas arquivadas para ativo

import 'package:flutter/material.dart';
import '../models/conta_model.dart';
import '../services/conta_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';

class ContasArquivadasPage extends StatefulWidget {
  const ContasArquivadasPage({super.key});

  @override
  State<ContasArquivadasPage> createState() => _ContasArquivadasPageState();
}

class _ContasArquivadasPageState extends State<ContasArquivadasPage> {
  final ContaService _contaService = ContaService.instance;
  List<ContaModel> _contasArquivadas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarContasArquivadas();
  }

  Future<void> _carregarContasArquivadas() async {
    setState(() => _loading = true);

    try {
      final contas = await _contaService.getContasArquivadas();
      setState(() {
        _contasArquivadas = contas;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar contas arquivadas: $e')),
        );
      }
    }
  }

  Future<void> _restaurarConta(ContaModel conta) async {
    try {
      await _contaService.desarquivarConta(conta.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${conta.nome} restaurada com sucesso!')),
        );
        _carregarContasArquivadas(); // Recarregar lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao restaurar conta: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 42,
        title: const Text(
          'Contas Arquivadas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      backgroundColor: AppColors.cinzaClaro,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _contasArquivadas.isEmpty
              ? _buildEmptyState()
              : _buildContasArquivadas(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma conta arquivada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contas arquivadas aparecerão aqui',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContasArquivadas() {
    return RefreshIndicator(
      onRefresh: _carregarContasArquivadas,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            ...(_contasArquivadas.map((conta) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _buildContaItem(conta),
            ))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContaItem(ContaModel conta) {
    final cor = _parseColor(conta.cor ?? '#008080');
    final saldoNegativo = conta.saldo < 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Material(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black.withAlpha(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showRestaurarDialog(conta),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.branco,
            ),
            child: Column(
              children: [
                // Card principal (similar ao original)
                Container(
                  height: 71,
                  child: Row(
                    children: [
                      // Faixa lateral colorida
                      Container(
                        width: 37,
                        decoration: BoxDecoration(
                          color: cor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _iconFromSlug(conta.tipo),
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),

                      // Conteúdo principal
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Primeira linha: Nome + Saldo
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        conta.nome,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.cinzaEscuro,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      CurrencyFormatter.format(conta.saldo),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: saldoNegativo ? Colors.red[600] : Colors.green[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Segunda linha: Banco + Badge simples
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${conta.banco ?? 'Sem banco'} • Conta',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.cinzaTexto,
                                      ),
                                    ),
                                  ),

                                  // Badge de arquivada apenas
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.red[300]!, width: 1),
                                    ),
                                    child: Text(
                                      'ARQUIVADA',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red[700],
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

                // Botão de restaurar separado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: ElevatedButton.icon(
                    onPressed: () => _showRestaurarDialog(conta),
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('Restaurar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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


  void _showRestaurarDialog(ContaModel conta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Conta'),
        content: Text('Deseja restaurar a conta "${conta.nome}"?\n\nEla voltará a aparecer na lista de contas ativas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restaurarConta(conta);
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  /// Parse de cor da string
  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppColors.tealPrimary;
    }
  }

  /// Mapper de ícone por tipo
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
}