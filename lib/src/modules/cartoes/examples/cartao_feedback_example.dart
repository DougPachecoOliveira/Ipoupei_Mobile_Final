// 💳 Exemplo de Aplicação do Sistema de Feedback em Cartões
// 
// Demonstra como usar o OperationFeedbackHelper para operações de cartão

import 'package:flutter/material.dart';
import '../../../shared/utils/operation_feedback_helper.dart';

class CartaoFeedbackExample extends StatefulWidget {
  @override
  _CartaoFeedbackExampleState createState() => _CartaoFeedbackExampleState();
}

class _CartaoFeedbackExampleState extends State<CartaoFeedbackExample> {
  
  /// 💳 EXEMPLO: Criar Cartão de Crédito
  Future<void> _criarCartao() async {
    await OperationFeedbackHelper.executeWithNavigation(
      context: context,
      operation: OperationType.create,
      entityName: 'cartão',
      operationFunction: () async {
        // Simula criação de cartão
        await Future.delayed(Duration(milliseconds: 500));
        
        // Aqui seria a chamada real:
        // final cartao = await cartaoService.criarCartao(
        //   nome: 'Nubank',
        //   bandeira: 'Mastercard',
        //   limite: 5000.00,
        //   diaFechamento: 15,
        //   diaVencimento: 10,
        // );
        
        return true; // Simula sucesso
      },
      popOnSuccess: true,
      onRefreshComplete: () {
        // Recarrega lista de cartões
        _recarregarCartoes();
      },
    );
  }
  
  /// 💰 EXEMPLO: Pagar Fatura do Cartão
  Future<void> _pagarFatura(String cartaoId, double valor) async {
    await OperationFeedbackHelper.executeOperationFeedback(
      context: context,
      operation: OperationType.payment,
      entityName: 'fatura',
      onRefreshComplete: () {
        // Atualiza saldo e faturas
        _recarregarCartoes();
        _recarregarFaturas();
      },
    );
  }
  
  /// 🔄 EXEMPLO: Atualizar Dados do Cartão  
  Future<void> _atualizarCartao(String cartaoId) async {
    await OperationFeedbackHelper.executeWithNavigation(
      context: context,
      operation: OperationType.update,
      entityName: 'cartão',
      operationFunction: () async {
        // Simula atualização
        await Future.delayed(Duration(milliseconds: 300));
        return true;
      },
      onRefreshComplete: _recarregarCartoes,
    );
  }
  
  /// 📂 EXEMPLO: Arquivar Cartão
  Future<void> _arquivarCartao(String cartaoId) async {
    await OperationFeedbackHelper.executeOperationFeedback(
      context: context,
      operation: OperationType.archive,
      entityName: 'cartão',
      onRefreshComplete: _recarregarCartoes,
    );
  }
  
  void _recarregarCartoes() {
    // Implementa recarregamento
    setState(() {});
  }
  
  void _recarregarFaturas() {
    // Implementa recarregamento de faturas
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cartões - Feedback')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _criarCartao,
              child: Text('Criar Cartão'),
            ),
            ElevatedButton(
              onPressed: () => _pagarFatura('cartao-id', 1500.00),
              child: Text('Pagar Fatura'),
            ),
            ElevatedButton(
              onPressed: () => _atualizarCartao('cartao-id'),
              child: Text('Atualizar Cartão'),
            ),
            ElevatedButton(
              onPressed: () => _arquivarCartao('cartao-id'),
              child: Text('Arquivar Cartão'),
            ),
          ],
        ),
      ),
    );
  }
}