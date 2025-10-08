// 📊 Planejamento Card Widget - iPoupei Mobile
//
// Widget de card para planejamento (baseado na imagem fornecida)
// Estrutura idêntica aos cards de categorias
//
// Visual: Ícone + Nome + Valores + Barra de Progresso + Percentual

import 'package:flutter/material.dart';
import '../models/planejamento_model.dart';
import '../../../shared/utils/format_currency.dart';
import '../../shared/theme/app_colors.dart';

class PlanejamentoCard extends StatelessWidget {
  final PlanejamentoModel planejamento;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const PlanejamentoCard({
    super.key,
    required this.planejamento,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.grey.withAlpha(26),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone circular colorido (IGUAL À IMAGEM)
                _buildIconeCategoria(),

                const SizedBox(width: 12),

                // Conteúdo principal
                Expanded(
                  child: _buildConteudo(),
                ),

                // Menu de ações
                if (onEdit != null)
                  _buildMenuAcoes(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconeCategoria() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getCorCategoria(),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          planejamento.categoriaIcone ?? '📊',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nome da categoria (fonte 16, peso 600 - IGUAL CATEGORIAS)
        Text(
          _getNomeExibicao(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Valor atual vs planejado (fonte 13 - BASEADO NA IMAGEM)
        Text(
          _getTextoValores(),
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 6),

        // Barra de progresso linda (IGUAL À IMAGEM)
        _buildBarraProgresso(),

        const SizedBox(height: 4),

        // Percentual (fonte 12 - IGUAL À IMAGEM)
        Text(
          '${planejamento.percentualCumprimento.toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBarraProgresso() {
    return LinearProgressIndicator(
      value: _getValorProgresso(),
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(_getCorProgresso()),
      minHeight: 6,
    );
  }

  Widget _buildMenuAcoes(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
      onSelected: (value) {
        switch (value) {
          case 'editar':
            onEdit?.call();
            break;
          case 'historico':
            _mostrarHistorico(context);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'editar',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Editar Meta'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'historico',
          child: Row(
            children: [
              Icon(Icons.history, size: 18),
              SizedBox(width: 8),
              Text('Ver Histórico'),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================
  // MÉTODOS AUXILIARES
  // ===========================

  String _getNomeExibicao() {
    if (planejamento.subcategoriaNome != null) {
      return '${planejamento.categoriaNome} • ${planejamento.subcategoriaNome}';
    }
    return planejamento.categoriaNome ?? 'Sem nome';
  }

  String _getTextoValores() {
    // Formato igual à imagem: "R$ 216,90 de R$ 1.440,53"
    return '${formatCurrency(planejamento.totalMes)} de ${formatCurrency(planejamento.valorPlanejado)}';
  }

  Color _getCorCategoria() {
    try {
      final cor = planejamento.categoriaCor;
      if (cor != null && cor.isNotEmpty) {
        return Color(int.parse(cor.replaceAll('#', '0xFF')));
      }
    } catch (e) {
      // Cor padrão se não conseguir parsear
    }

    // Cores padrão baseadas no tipo
    return planejamento.isReceita ? AppColors.verdeSucesso : AppColors.cinzaEscuro;
  }

  double _getValorProgresso() {
    if (planejamento.valorPlanejado <= 0) return 0.0;
    return (planejamento.percentualCumprimento / 100).clamp(0.0, 1.0);
  }

  Color _getCorProgresso() {
    // Cores baseadas no percentual (IGUAL CATEGORIAS)
    final pct = planejamento.percentualCumprimento;

    if (pct >= 100) {
      // Ultrapassou - vermelho/laranja dependendo do tipo
      return planejamento.isDespesa ? AppColors.vermelhoErro : AppColors.laranjaAlerta;
    }

    if (pct >= 80) {
      return AppColors.verdeSucesso; // Verde - boa meta
    }

    if (pct >= 50) {
      return AppColors.laranjaAlerta; // Laranja - em andamento
    }

    return AppColors.cinzaMedio; // Cinza - baixo
  }

  void _mostrarHistorico(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getCorCategoria(),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        planejamento.categoriaIcone ?? '📊',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Histórico de Planejamento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cinzaEscuro,
                          ),
                        ),
                        Text(
                          _getNomeExibicao(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.cinzaMedio,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.cinzaMedio),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Informações históricas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cinzaClaro,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dados Históricos (Últimos 3 meses)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cinzaMedio,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow('Média mensal', formatCurrency(planejamento.mediaHistorica)),
                    const SizedBox(height: 8),
                    _buildInfoRow('Meta atual', formatCurrency(planejamento.valorPlanejado)),
                    const SizedBox(height: 8),
                    _buildInfoRow('Realizado este mês', formatCurrency(planejamento.valorRealizado)),
                    const SizedBox(height: 8),
                    _buildInfoRow('Previsto este mês', formatCurrency(planejamento.valorPrevisto)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Status e estatísticas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getCorProgresso().withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getCorProgresso().withAlpha(100),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          planejamento.iconeStatus,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${_getStatusTexto()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getCorProgresso(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Progresso: ${planejamento.percentualCumprimento.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.cinzaMedio,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Transações: ${planejamento.totalTransacoesRealizadas} realizadas, ${planejamento.totalTransacoesPrevistas} previstas',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.cinzaMedio,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botão de ação
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roxoHeader,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.cinzaMedio,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.cinzaEscuro,
          ),
        ),
      ],
    );
  }

  String _getStatusTexto() {
    switch (planejamento.statusMeta) {
      case StatusMeta.ultrapassou:
        return 'Meta Ultrapassada';
      case StatusMeta.boaCaminho:
        return 'Boa Caminho';
      case StatusMeta.emAndamento:
        return 'Em Andamento';
      case StatusMeta.baixo:
        return 'Baixo';
      case StatusMeta.semDados:
        return 'Sem Dados';
    }
  }
}