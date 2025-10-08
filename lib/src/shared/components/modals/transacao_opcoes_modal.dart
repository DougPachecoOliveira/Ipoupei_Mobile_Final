// 🎛️ Modal de Opções da Transação - iPoupei Mobile
//
// Modal reutilizável completo para exibir opções de ação sobre uma transação
// Inclui: Editar, Efetivar, Desefetivar, Duplicar e Excluir
// Com modal de confirmação de exclusão integrado
//
// Extraído de: transacoes_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../modules/shared/theme/app_colors.dart';
import '../../../modules/transacoes/models/transacao_model.dart';
import '../../../modules/transacoes/components/transaction_detail_card.dart';
import '../../../modules/transacoes/services/transacao_service.dart';
import '../../../modules/transacoes/services/transacao_edit_service.dart';
import '../../../modules/transacoes/pages/editar_transacao_page.dart';
import '../../../modules/categorias/models/categoria_model.dart';
import '../ui/app_button.dart';

/// Classe principal para exibir o modal de opções da transação
class TransacaoOpcoesModal {
  /// Mostra o modal de opções da transação
  static Future<void> mostrar({
    required BuildContext context,
    required TransacaoModel transacao,
    required VoidCallback onAtualizarLista,
    List<CategoriaModel>? categorias,
    VoidCallback? onVerTodasPendentes,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TransacaoOpcoesModalContent(
        transacao: transacao,
        onAtualizarLista: onAtualizarLista,
        categorias: categorias ?? [],
        onVerTodasPendentes: onVerTodasPendentes,
      ),
    );
  }
}

/// Widget interno do modal de opções
class _TransacaoOpcoesModalContent extends StatelessWidget {
  final TransacaoModel transacao;
  final VoidCallback onAtualizarLista;
  final List<CategoriaModel> categorias;
  final VoidCallback? onVerTodasPendentes;

  const _TransacaoOpcoesModalContent({
    required this.transacao,
    required this.onAtualizarLista,
    required this.categorias,
    this.onVerTodasPendentes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle visual do modal
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.cinzaMedio,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Card completo da transação com todos os detalhes
            TransactionDetailCard(
              transacao: transacao,
              showMetadata: true,
              loadDataAutomatically: true,
            ),

            const SizedBox(height: 24),

            const Text(
              'O que você deseja fazer?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.cinzaEscuro,
              ),
            ),

            const SizedBox(height: 16),

            // Editar
            EditOptionCardModal(
              titulo: 'Editar',
              subtitulo: 'Alterar dados da transação',
              icone: Icons.edit,
              cor: AppColors.azul,
              onTap: () {
                Navigator.of(context).pop();
                _navegarParaEditarAvancado(context, transacao, onAtualizarLista);
              },
            ),

            // Efetivar (apenas se não efetivada E não for despesa de cartão)
            if (!transacao.efetivado && transacao.cartaoId == null)
              EditOptionCardModal(
                titulo: 'Efetivar',
                subtitulo: 'Marcar como confirmada',
                icone: Icons.check_circle,
                cor: AppColors.verdeSucesso,
                onTap: () {
                  Navigator.of(context).pop();
                  _efetivarTransacao(context, transacao, onAtualizarLista);
                },
              ),

            // Desefetivar (apenas se efetivada E não for despesa de cartão)
            if (transacao.efetivado && transacao.cartaoId == null)
              EditOptionCardModal(
                titulo: 'Desefetivar',
                subtitulo: 'Marcar como pendente',
                icone: Icons.remove_circle,
                cor: AppColors.amareloAlerta,
                onTap: () {
                  Navigator.of(context).pop();
                  _desefetivarTransacao(context, transacao, onAtualizarLista);
                },
              ),

            // Ver Todas Pendentes (só aparece se callback fornecido)
            if (onVerTodasPendentes != null)
              EditOptionCardModal(
                titulo: 'Ver Todas Pendentes',
                subtitulo: 'Ir para lista completa de pendências',
                icone: Icons.list_alt,
                cor: AppColors.azul,
                onTap: () {
                  Navigator.of(context).pop();
                  onVerTodasPendentes!();
                },
              ),

            // Duplicar
            EditOptionCardModal(
              titulo: 'Duplicar',
              subtitulo: 'Criar uma cópia desta transação',
              icone: Icons.copy,
              cor: AppColors.cinzaMedio,
              onTap: () {
                Navigator.of(context).pop();
                _duplicarTransacao(context, transacao, onAtualizarLista);
              },
            ),

            // Excluir (apenas se não efetivada)
            if (!transacao.efetivado)
              EditOptionCardModal(
                titulo: 'Excluir',
                subtitulo: 'Remover permanentemente',
                icone: Icons.delete,
                cor: AppColors.vermelhoErro,
                onTap: () {
                  Navigator.of(context).pop();
                  _excluirTransacao(context, transacao, onAtualizarLista, categorias);
                },
              )
            else
              EditOptionCardModal(
                titulo: 'Não é possível excluir',
                subtitulo: 'Transações efetivadas não podem ser excluídas',
                icone: Icons.block,
                cor: AppColors.cinzaMedio,
                onTap: () {},
                habilitado: false,
                mensagemDesabilitado: 'Transações efetivadas não podem ser excluídas',
              ),
          ],
        ),
      ),
    );
  }

  // ======================================================================
  // MÉTODOS DE AÇÃO
  // ======================================================================

  /// 🔧 NAVEGAR PARA EDIÇÃO AVANÇADA
  static void _navegarParaEditarAvancado(
    BuildContext context,
    TransacaoModel transacao,
    VoidCallback onAtualizarLista,
  ) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditarTransacaoPage(
          transacao: transacao,
          modo: ModoEdicao.completa,
        ),
      ),
    );

    if (resultado == true) {
      onAtualizarLista();
    }
  }

  /// ✅ EFETIVAR TRANSAÇÃO
  static void _efetivarTransacao(
    BuildContext context,
    TransacaoModel transacao,
    VoidCallback onAtualizarLista,
  ) async {
    try {
      final resultado = await TransacaoEditService.instance.efetivar(transacao);

      if (resultado.sucesso) {
        onAtualizarLista();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resultado.mensagem ?? 'Transação efetivada')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resultado.erro ?? 'Erro desconhecido')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao efetivar transação: $e')),
        );
      }
    }
  }

  /// ❌ DESEFETIVAR TRANSAÇÃO
  static void _desefetivarTransacao(
    BuildContext context,
    TransacaoModel transacao,
    VoidCallback onAtualizarLista,
  ) async {
    try {
      final resultado = await TransacaoEditService.instance.desefetivar(transacao);

      if (resultado.sucesso) {
        onAtualizarLista();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resultado.mensagem ?? 'Transação marcada como pendente')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado.erro ?? 'Erro desconhecido'),
              backgroundColor: AppColors.vermelhoErro,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao desefetivar transação: $e'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
    }
  }

  /// 📋 DUPLICAR TRANSAÇÃO
  static void _duplicarTransacao(
    BuildContext context,
    TransacaoModel transacao,
    VoidCallback onAtualizarLista,
  ) async {
    try {
      final resultado = await TransacaoEditService.instance.duplicar(transacao);

      if (resultado.sucesso) {
        onAtualizarLista();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resultado.mensagem ?? 'Transação duplicada')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resultado.erro ?? 'Erro desconhecido')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao duplicar transação: $e')),
        );
      }
    }
  }

  /// 🗑️ EXCLUIR TRANSAÇÃO
  static void _excluirTransacao(
    BuildContext context,
    TransacaoModel transacao,
    VoidCallback onAtualizarLista,
    List<CategoriaModel> categorias,
  ) async {
    final confirmacao = await _mostrarModalConfirmacaoExclusao(
      context,
      transacao,
      categorias,
    );

    if (confirmacao == true) {
      try {
        await TransacaoService.instance.deleteTransacao(transacao.id);
        onAtualizarLista();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transação "${transacao.descricao}" excluída')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir transação: $e')),
          );
        }
      }
    }
  }

  // ======================================================================
  // MODAL DE CONFIRMAÇÃO DE EXCLUSÃO
  // ======================================================================

  /// 🗑️ MODAL DE CONFIRMAÇÃO DE EXCLUSÃO
  static Future<bool?> _mostrarModalConfirmacaoExclusao(
    BuildContext context,
    TransacaoModel transacao,
    List<CategoriaModel> categorias,
  ) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildExclusaoHeader(context),
              _buildExclusaoBody(context, transacao, categorias),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildExclusaoHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.vermelhoErro,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.delete_forever,
            color: AppColors.branco,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Excluir Transação',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.branco,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.branco),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }

  static Widget _buildExclusaoBody(
    BuildContext context,
    TransacaoModel transacao,
    List<CategoriaModel> categorias,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExclusaoResumo(transacao, categorias),
          const SizedBox(height: 24),
          const Text(
            'Esta ação não pode ser desfeita. Tem certeza que deseja continuar?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.cinzaTexto,
            ),
          ),
          const SizedBox(height: 32),
          _buildExclusaoBotoes(context),
        ],
      ),
    );
  }

  static Widget _buildExclusaoResumo(
    TransacaoModel transacao,
    List<CategoriaModel> categorias,
  ) {
    final categoria = categorias.firstWhere(
      (c) => c.id == transacao.categoriaId,
      orElse: () => CategoriaModel(
        id: '',
        usuarioId: '',
        nome: 'Sem categoria',
        tipo: transacao.tipo,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.vermelhoTransparente10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.vermelhoTransparente20,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconeTransacao(transacao),
                color: AppColors.vermelhoErro,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  transacao.descricao,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(transacao.valor),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.vermelhoErro,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            categoria.nome,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.cinzaTexto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM/yyyy').format(transacao.data),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.cinzaLegenda,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildExclusaoBotoes(BuildContext context) {
    return Row(
      children: [
        // Botão Cancelar
        Expanded(
          child: AppButton.outline(
            text: 'CANCELAR',
            onPressed: () => Navigator.of(context).pop(false),
            customColor: AppColors.cinzaTexto,
          ),
        ),

        const SizedBox(width: 16),

        // Botão Excluir
        Expanded(
          child: AppButton(
            text: 'EXCLUIR',
            icon: Icons.delete_forever,
            onPressed: () => Navigator.of(context).pop(true),
            customColor: AppColors.vermelhoErro,
          ),
        ),
      ],
    );
  }

  // ======================================================================
  // HELPERS
  // ======================================================================

  /// 🎨 OBTER ÍCONE DA TRANSAÇÃO
  static IconData _getIconeTransacao(TransacaoModel transacao) {
    if (transacao.tipo == 'receita') {
      return Icons.trending_up;
    } else if (transacao.tipo == 'despesa') {
      return transacao.cartaoId != null ? Icons.credit_card : Icons.trending_down;
    } else {
      return Icons.swap_horiz; // transferência
    }
  }
}

// ======================================================================
// WIDGET DE OPÇÃO DO MODAL (CARD CLICÁVEL)
// ======================================================================

class EditOptionCardModal extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final Color cor;
  final VoidCallback onTap;
  final bool habilitado;
  final String? mensagemDesabilitado;

  const EditOptionCardModal({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.cor,
    required this.onTap,
    this.habilitado = true,
    this.mensagemDesabilitado,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: habilitado ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: habilitado ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cor,
                          cor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: cor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icone,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cinzaEscuro,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          habilitado ? subtitulo : mensagemDesabilitado ?? subtitulo,
                          style: TextStyle(
                            fontSize: 14,
                            color: habilitado ? AppColors.cinzaTexto : AppColors.cinzaMedio,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (habilitado)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: cor,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
