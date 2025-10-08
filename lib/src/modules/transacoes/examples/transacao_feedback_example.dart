// 💳 Exemplo de Aplicação do Sistema de Feedback em Transações
// 
// Demonstra como usar o OperationFeedbackHelper em modais/páginas de transação

import 'package:flutter/material.dart';
import '../services/transacao_service.dart';
import '../../../shared/utils/operation_feedback_helper.dart';

class TransacaoFeedbackExample extends StatefulWidget {
  @override
  _TransacaoFeedbackExampleState createState() => _TransacaoFeedbackExampleState();
}

class _TransacaoFeedbackExampleState extends State<TransacaoFeedbackExample> {
  final _transacaoService = TransacaoService.instance;
  
  /// 💰 EXEMPLO: Criar Receita com Feedback Completo
  Future<void> _criarReceita() async {
    await OperationFeedbackHelper.executeWithNavigation(
      context: context,
      operation: OperationType.create,
      entityName: 'receita',
      operationFunction: () async {
        // Executa a operação real
        final receitas = await _transacaoService.criarReceita(
          descricao: 'Salário',
          valor: 5000.00,
          data: DateTime.now(),
          contaId: 'conta-id',
          categoriaId: 'categoria-id',
          tipoReceita: 'extra',
        );
        
        return receitas.isNotEmpty; // Retorna sucesso
      },
      popOnSuccess: true, // Fecha modal após sucesso
      onRefreshComplete: () {
        // Callback executado após refresh (3s)
        // Aqui você pode recarregar listas, etc.
        _recarregarListaTransacoes();
      },
    );
  }
  
  /// 💸 EXEMPLO: Criar Despesa com Feedback Completo  
  Future<void> _criarDespesa() async {
    await OperationFeedbackHelper.executeWithNavigation(
      context: context,
      operation: OperationType.create,
      entityName: 'despesa',
      operationFunction: () async {
        // Implementaria criação de despesa aqui
        // final despesas = await _transacaoService.criarDespesa(...);
        return true;
      },
      onRefreshComplete: _recarregarListaTransacoes,
    );
  }
  
  /// 🔄 EXEMPLO: Atualizar Transação Existente
  Future<void> _atualizarTransacao(String transacaoId) async {
    await OperationFeedbackHelper.executeWithNavigation(
      context: context,
      operation: OperationType.update,
      entityName: 'transação',
      operationFunction: () async {
        // Implementaria atualização aqui
        // await _transacaoService.atualizarTransacao(transacaoId, dados);
        return true;
      },
      onRefreshComplete: _recarregarListaTransacoes,
    );
  }
  
  /// 🗑️ EXEMPLO: Excluir Transação
  Future<void> _excluirTransacao(String transacaoId) async {
    await OperationFeedbackHelper.executeWithNavigation(
      context: context,
      operation: OperationType.delete,
      entityName: 'transação',
      operationFunction: () async {
        // Implementaria exclusão aqui
        // await _transacaoService.excluirTransacao(transacaoId);
        return true;
      },
      popOnSuccess: false, // Não fecha modal, só mostra feedback
      onRefreshComplete: _recarregarListaTransacoes,
    );
  }
  
  /// 📡 Callback para recarregar dados após operações
  void _recarregarListaTransacoes() {
    // Aqui você recarregaria sua lista de transações
    setState(() {
      // Força rebuild da lista
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Exemplo Feedback')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _criarReceita,
              child: Text('Criar Receita'),
            ),
            ElevatedButton(
              onPressed: _criarDespesa,
              child: Text('Criar Despesa'),
            ),
            ElevatedButton(
              onPressed: () => _atualizarTransacao('id-exemplo'),
              child: Text('Atualizar Transação'),
            ),
            ElevatedButton(
              onPressed: () => _excluirTransacao('id-exemplo'),
              child: Text('Excluir Transação'),
            ),
          ],
        ),
      ),
    );
  }
}