import 'package:flutter/material.dart';
import '../models/transacao_model.dart';
import '../services/transacao_edit_service.dart';
import 'escopo_edicao_modal.dart';
import 'operacao_feedback_widget.dart';

/// Helper para executar operações em transações com feedback visual simplificado
/// Agora sempre usa operações locais após download silencioso
class OperacaoHelper {
  /// Executa operação de edição de valor com modal de escopo e feedback
  static Future<bool> editarValor({
    required BuildContext context,
    required TransacaoModel transacao,
    required double novoValor,
  }) async {
    try {
      // Se for transação individual, executa direto
      if (transacao.grupoRecorrencia == null && transacao.grupoParcelamento == null) {
        return await _executarOperacaoSimples(
          context: context,
          titulo: 'Editando Valor',
          operacao: () => TransacaoEditService.instance.editarValor(
            transacao,
            novoValor,
            escopo: EscopoEdicao.apenasEsta,
          ),
        );
      }

      // Para grupos, mostrar modal de escopo simples
      final escopo = await EscopoEdicaoHelper.mostrar(
        context: context,
        tipoOperacao: 'Editar Valor',
        totalTransacoes: 0, // Será calculado pelo service
        transacoesLocais: 0, // Será calculado pelo service
        requerConexao: false, // Sempre local agora
        detalhesOperacao: 'Novo valor: R\$ ${novoValor.toStringAsFixed(2).replaceAll('.', ',')}',
      );

      if (escopo == null) return false; // Cancelado

      // Executar operação sempre local
      return await _executarOperacaoSimples(
        context: context,
        titulo: 'Editando Valor',
        operacao: () => TransacaoEditService.instance.editarValor(
          transacao,
          novoValor,
          escopo: escopo,
        ),
      );

    } catch (e) {
      _mostrarErro(context, 'Erro ao editar valor: $e');
      return false;
    }
  }

  /// Executa operação de edição de descrição com modal de escopo e feedback
  static Future<bool> editarDescricao({
    required BuildContext context,
    required TransacaoModel transacao,
    required String novaDescricao,
  }) async {
    try {
      // Se for transação individual, executa direto
      if (transacao.grupoRecorrencia == null && transacao.grupoParcelamento == null) {
        return await _executarOperacaoSimples(
          context: context,
          titulo: 'Editando Descrição',
          operacao: () => TransacaoEditService.instance.editarDescricao(
            transacao,
            novaDescricao: novaDescricao,
            escopo: EscopoEdicao.apenasEsta,
          ),
        );
      }

      // Para grupos, mostrar modal de escopo simples
      final escopo = await EscopoEdicaoHelper.mostrar(
        context: context,
        tipoOperacao: 'Editar Descrição',
        totalTransacoes: 0, // Será calculado pelo service
        transacoesLocais: 0, // Será calculado pelo service
        requerConexao: false, // Sempre local agora
        detalhesOperacao: 'Nova descrição: "$novaDescricao"',
      );

      if (escopo == null) return false; // Cancelado

      // Executar operação sempre local
      return await _executarOperacaoSimples(
        context: context,
        titulo: 'Editando Descrição',
        operacao: () => TransacaoEditService.instance.editarDescricao(
          transacao,
          novaDescricao: novaDescricao,
          escopo: escopo,
        ),
      );

    } catch (e) {
      _mostrarErro(context, 'Erro ao editar descrição: $e');
      return false;
    }
  }

  /// Executa operação de confirmação (efetivar) com modal de escopo e feedback
  static Future<bool> confirmar({
    required BuildContext context,
    required TransacaoModel transacao,
  }) async {
    try {
      // Se for transação individual, executa direto
      if (transacao.grupoRecorrencia == null && transacao.grupoParcelamento == null) {
        return await _executarOperacaoSimples(
          context: context,
          titulo: 'Confirmando Transação',
          operacao: () => TransacaoEditService.instance.efetivar(transacao),
        );
      }

      // Para grupos, mostrar modal de escopo simples
      final escopo = await EscopoEdicaoHelper.mostrar(
        context: context,
        tipoOperacao: 'Confirmar Transações',
        totalTransacoes: 0, // Será calculado pelo service
        transacoesLocais: 0, // Será calculado pelo service
        requerConexao: false, // Sempre local agora
        detalhesOperacao: 'Marcar como efetivadas (pagas)',
      );

      if (escopo == null) return false; // Cancelado

      // Executar operação sempre local
      return await _executarOperacaoSimples(
        context: context,
        titulo: 'Confirmando Transações',
        operacao: () => TransacaoEditService.instance.efetivar(
          transacao,
          incluirFuturas: escopo != EscopoEdicao.apenasEsta,
        ),
      );

    } catch (e) {
      _mostrarErro(context, 'Erro ao confirmar transação: $e');
      return false;
    }
  }

  /// Executa operação de exclusão com modal de escopo e feedback
  static Future<bool> excluir({
    required BuildContext context,
    required TransacaoModel transacao,
  }) async {
    try {
      // Se for transação individual, executa direto
      if (transacao.grupoRecorrencia == null && transacao.grupoParcelamento == null) {
        return await _executarOperacaoSimples(
          context: context,
          titulo: 'Excluindo Transação',
          operacao: () => TransacaoEditService.instance.excluirTransacao(transacao),
        );
      }

      // Para grupos, mostrar modal de escopo simples
      final escopo = await EscopoEdicaoHelper.mostrar(
        context: context,
        tipoOperacao: 'Excluir Transações',
        totalTransacoes: 0, // Será calculado pelo service
        transacoesLocais: 0, // Será calculado pelo service
        requerConexao: false, // Sempre local agora
        detalhesOperacao: 'Esta ação não pode ser desfeita',
      );

      if (escopo == null) return false; // Cancelado

      // Executar operação sempre local
      return await _executarOperacaoSimples(
        context: context,
        titulo: 'Excluindo Transações',
        operacao: () => TransacaoEditService.instance.excluirGrupo(
          transacao,
          escopo,
        ),
      );

    } catch (e) {
      _mostrarErro(context, 'Erro ao excluir transação: $e');
      return false;
    }
  }

  // ===== MÉTODOS PRIVADOS =====

  /// Executa operação simples (transação individual) com feedback básico
  static Future<bool> _executarOperacaoSimples({
    required BuildContext context,
    required String titulo,
    required Future<ResultadoEdicao<bool>> Function() operacao,
  }) async {
    final controller = OperacaoFeedbackController();
    bool sucesso = false;

    try {
      final future = OperacaoFeedbackDialog.mostrar(
        context: context,
        titulo: titulo,
        stream: controller.stream,
      );

      controller.preparando('Executando operação...');

      final resultado = await operacao();

      if (resultado.sucesso) {
        controller.concluido(resultado.mensagem ?? 'Operação concluída');
        sucesso = true;
      } else {
        controller.erro(resultado.erro ?? 'Erro na operação');
      }

      await future;
      return sucesso;

    } catch (e) {
      controller.erro('Erro inesperado', e.toString());
      return false;
    } finally {
      controller.dispose();
    }
  }


  /// Mostra mensagem de erro
  static void _mostrarErro(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Exemplo de uso:
///
/// ```dart
/// // Editar valor com todo o fluxo automático
/// final sucesso = await OperacaoHelper.editarValor(
///   context: context,
///   transacao: transacao,
///   novoValor: 150.00,
/// );
///
/// if (sucesso) {
///   // Operação concluída com sucesso
///   // O widget será atualizado automaticamente
/// }
/// ```