// 🎛️ Modal de Opções da Transação - iPoupei Mobile
//
// Modal reutilizável completo para exibir opções de ação sobre uma transação
// Inclui: Editar, Efetivar, Desefetivar, Duplicar e Excluir
// Com modal de confirmação de exclusão integrado
//
// Extraído de: transacoes_page.dart

import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // Usado apenas pelos métodos legacy comentados
import '../../../modules/shared/theme/app_colors.dart';
import '../../../modules/transacoes/models/transacao_model.dart';
import '../../../modules/transacoes/components/transaction_detail_card.dart';
import '../../../modules/transacoes/services/transacao_service.dart';
import '../../../modules/transacoes/services/transacao_edit_service.dart';
import '../../../routes/main_navigation.dart';
import '../../../modules/transacoes/pages/editar_transacao_page.dart';
import '../../../modules/categorias/models/categoria_model.dart';
// import '../ui/app_button.dart'; // Removido - usando OutlinedButton e ElevatedButton nativos

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
        // Atualizar lista após exclusão
        onAtualizarLista();

        // Fechar modal de opções se ainda estiver aberto
        if (context.mounted) {
          Navigator.of(context).pop(); // Fechar modal de opções

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transação "${transacao.descricao}" excluída')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir transação: $e')),
          );

          // Em caso de erro crítico, navegar para tela segura
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MainNavigation(initialIndex: 2),
            ),
            (route) => false,
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
        return _ModalExclusaoContent(
          transacao: transacao,
          categorias: categorias,
        );
      },
    );
  }

  // Método _buildExclusaoHeader removido - usando nova implementação _ModalExclusaoContent

  // Métodos legacy _buildExclusaoBody e _buildExclusaoBotoes removidos
  // Usando nova implementação _ModalExclusaoContent
  /*
  static Widget _buildExclusaoBodyLegacy(
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
  */

  // ======================================================================
  // HELPERS
  // ======================================================================

  // Método _getIconeTransacao removido - usado apenas pelos métodos legacy comentados
  /*
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
  */
}

// ======================================================================
// MODAL DE EXCLUSÃO COM OPÇÕES DE ESCOPO
// ======================================================================

class _ModalExclusaoContent extends StatefulWidget {
  final TransacaoModel transacao;
  final List<CategoriaModel> categorias;

  const _ModalExclusaoContent({
    required this.transacao,
    required this.categorias,
  });

  @override
  State<_ModalExclusaoContent> createState() => _ModalExclusaoContentState();
}

class _ModalExclusaoContentState extends State<_ModalExclusaoContent> {
  EscopoEdicao? _escopoSelecionado;
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    // Se não tem grupo, só pode excluir esta transação
    if (widget.transacao.grupoRecorrencia == null) {
      _escopoSelecionado = EscopoEdicao.apenasEsta;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.vermelhoErro.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.vermelhoErro,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_forever,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Excluir Transação',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.vermelhoErro,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta ação não pode ser desfeita',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.cinzaTexto,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTransacaoResumo(),
          const SizedBox(height: 20),
          if (widget.transacao.grupoRecorrencia != null) ...[
            const Text(
              'Esta transação faz parte de um grupo:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.cinzaEscuro,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildOpcoesEscopo(),
            const SizedBox(height: 20),
          ] else ...[
            const Text(
              'Tem certeza que deseja excluir esta transação?',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.cinzaTexto,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
          _buildBotoes(),
        ],
      ),
    );
  }

  Widget _buildTransacaoResumo() {
    final categoria = widget.categorias.firstWhere(
      (c) => c.id == widget.transacao.categoriaId,
      orElse: () => CategoriaModel(
        id: '',
        usuarioId: '',
        nome: 'Sem categoria',
        tipo: widget.transacao.tipo,
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
      child: Row(
        children: [
          Icon(
            _getIconeTransacao(),
            color: AppColors.vermelhoErro,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.transacao.descricao,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.cinzaEscuro,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  categoria.nome,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.cinzaTexto,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'R\$ ${widget.transacao.valor.abs().toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.vermelhoErro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcoesEscopo() {
    return Column(
      children: [
        _buildOpcaoEscopo(
          escopo: EscopoEdicao.apenasEsta,
          titulo: 'Apenas esta transação',
          subtitulo: 'Excluir somente esta ocorrência',
        ),
        const SizedBox(height: 12),
        _buildOpcaoEscopo(
          escopo: EscopoEdicao.estasEFuturas,
          titulo: 'Esta e futuras transações',
          subtitulo: 'Excluir esta e todas as próximas do grupo',
        ),
      ],
    );
  }

  Widget _buildOpcaoEscopo({
    required EscopoEdicao escopo,
    required String titulo,
    required String subtitulo,
  }) {
    final selecionado = _escopoSelecionado == escopo;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: selecionado ? AppColors.vermelhoErro : AppColors.cinzaBorda,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _escopoSelecionado = escopo;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selecionado ? AppColors.vermelhoErro : AppColors.cinzaTexto,
                      width: 2,
                    ),
                    color: selecionado ? AppColors.vermelhoErro : Colors.transparent,
                  ),
                  child: selecionado
                      ? const Icon(
                          Icons.check,
                          size: 12,
                          color: AppColors.branco,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: selecionado ? AppColors.vermelhoErro : AppColors.cinzaEscuro,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.cinzaTexto,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selecionado)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.vermelhoErro.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.vermelhoErro,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotoes() {
    final podeExcluir = widget.transacao.grupoRecorrencia == null || _escopoSelecionado != null;

    return Row(
      children: [
        // Botão Cancelar
        Expanded(
          child: OutlinedButton(
            onPressed: _processando ? null : () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[400]!),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.cinzaTexto,
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Botão Excluir
        Expanded(
          child: ElevatedButton(
            onPressed: (podeExcluir && !_processando) ? _executarExclusao : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vermelhoErro,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_processando)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(Icons.delete_forever, size: 18),
                const SizedBox(width: 8),
                Text(
                  _processando ? 'Excluindo...' : 'Excluir',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _executarExclusao() async {
    setState(() {
      _processando = true;
    });

    try {
      if (widget.transacao.grupoRecorrencia != null && _escopoSelecionado != null) {
        // Exclusão por escopo para transação recorrente
        final resultado = await TransacaoEditService.instance.excluirGrupo(
          widget.transacao,
          _escopoSelecionado!,
        );

        if (!resultado.sucesso) {
          throw Exception(resultado.erro ?? 'Erro ao excluir grupo');
        }
      } else {
        // Exclusão simples
        await TransacaoService.instance.deleteTransacao(widget.transacao.id);
      }

      // Navegação segura após exclusão
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _processando = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );

        // Em caso de erro grave, navegar para tela segura
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainNavigation(initialIndex: 2),
          ),
          (route) => false,
        );
      }
    }
  }

  IconData _getIconeTransacao() {
    if (widget.transacao.tipo == 'receita') {
      return Icons.trending_up;
    } else if (widget.transacao.tipo == 'despesa') {
      return widget.transacao.cartaoId != null ? Icons.credit_card : Icons.trending_down;
    } else {
      return Icons.swap_horiz;
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
            color: cor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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
                          cor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: cor.withValues(alpha: 0.3),
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
                        color: cor.withValues(alpha: 0.1),
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
