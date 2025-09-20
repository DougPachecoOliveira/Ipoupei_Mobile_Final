import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../models/transacao_model.dart';

/// Card reutilizável para exibir informações de transação
/// Usado nas páginas de edição e visualização
class TransactionCard extends StatelessWidget {
  final TransacaoModel transacao;
  final bool showStatus;
  final bool showRelatedInfo;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transacao,
    this.showStatus = true,
    this.showRelatedInfo = false,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCorTipoTransacao().withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha 1: Tipo + Valor + Status
                Row(
                  children: [
                    // Tipo da transação
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCorTipoTransacao().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconeTipoTransacao(),
                            size: 14,
                            color: _getCorTipoTransacao(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTextoTipoTransacao(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getCorTipoTransacao(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Valor da transação
                    Text(
                      'R\$ ${transacao.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getCorTipoTransacao(),
                      ),
                    ),
                    
                    // Status (se habilitado)
                    if (showStatus) ...[
                      const SizedBox(width: 12),
                      _buildStatusBadge(),
                    ],
                    
                    // Widget customizado no final
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Linha 2: Descrição
                if (transacao.descricao.isNotEmpty)
                  Text(
                    transacao.descricao,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                
                // Subtitle personalizado
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.cinzaTexto,
                    ),
                  ),
                ],
                
                // Informações relacionadas (se habilitado)
                if (showRelatedInfo) ...[
                  const SizedBox(height: 8),
                  _buildRelatedInfo(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Badge de status da transação
  Widget _buildStatusBadge() {
    final isEfetivado = transacao.efetivado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isEfetivado ? AppColors.verdeSucesso : AppColors.amareloAlerta,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isEfetivado ? 'EFETIVADO' : 'PENDENTE',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Informações sobre parcelas/recorrências
  Widget _buildRelatedInfo() {
    // TODO: Implementar lógica para mostrar info de parcelas/recorrências
    // Por enquanto, mostra placeholder
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.azul.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.repeat,
            size: 12,
            color: AppColors.azul,
          ),
          const SizedBox(width: 4),
          Text(
            'Transação relacionada',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.azul,
            ),
          ),
        ],
      ),
    );
  }

  /// Cor baseada no tipo da transação
  Color _getCorTipoTransacao() {
    switch (transacao.tipo.toLowerCase()) {
      case 'receita':
        return AppColors.verdeSucesso;
      case 'despesa':
        return AppColors.vermelhoErro;
      case 'transferencia':
        return AppColors.azul;
      default:
        return AppColors.cinzaEscuro;
    }
  }

  /// Ícone baseado no tipo da transação
  IconData _getIconeTipoTransacao() {
    switch (transacao.tipo.toLowerCase()) {
      case 'receita':
        return Icons.trending_up;
      case 'despesa':
        return Icons.trending_down;
      case 'transferencia':
        return Icons.swap_horiz;
      default:
        return Icons.attach_money;
    }
  }

  /// Texto baseado no tipo da transação
  String _getTextoTipoTransacao() {
    switch (transacao.tipo.toLowerCase()) {
      case 'receita':
        return 'RECEITA';
      case 'despesa':
        return 'DESPESA';
      case 'transferencia':
        return 'TRANSFERÊNCIA';
      default:
        return transacao.tipo.toUpperCase();
    }
  }
}