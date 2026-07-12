// 🔄 Exemplo de Aplicação do Sistema de Feedback em Transferências
// 
// Demonstra como usar o OperationFeedbackHelper para transferências entre contas

import 'package:flutter/material.dart';
import '../../../shared/utils/operation_feedback_helper.dart';

class TransferenciaFeedbackExample extends StatefulWidget {
  @override
  _TransferenciaFeedbackExampleState createState() => _TransferenciaFeedbackExampleState();
}

class _TransferenciaFeedbackExampleState extends State<TransferenciaFeedbackExample> {
  
  /// 💸 EXEMPLO: Transferência entre Contas
  Future<void> _realizarTransferencia() async {
    await OperationFeedbackHelper.executeWithNavigation(
      context: context,
      operation: OperationType.transfer,
      entityName: 'transferência',
      operationFunction: () async {
        // Simula transferência
        await Future.delayed(Duration(milliseconds: 800));
        
        // Aqui seria a chamada real:
        // await transferenciaService.transferir(
        //   contaOrigemId: contaOrigemId,
        //   contaDestinoId: contaDestinoId,
        //   valor: valor,
        //   descricao: descricao,
        // );
        
        return true; // Simula sucesso
      },
      popOnSuccess: true,
      onRefreshComplete: () {
        // Recarrega saldos de ambas as contas
        _recarregarSaldos();
        _recarregarExtratoTransferencias();
      },
    );
  }
  
  /// ⚡ EXEMPLO: Transferência com Feedback Customizado
  Future<void> _transferenciaCustomizada() async {
    // Versão manual para controle total
    try {
      // 1. Executa operação
      final sucesso = await _executarTransferencia();
      
      if (sucesso && context.mounted) {
        // 2. Feedback customizado para transferências
        await OperationFeedbackHelper.executeOperationFeedback(
          context: context,
          operation: OperationType.transfer,
          entityName: 'transferência',
          onRefreshComplete: () {
            _recarregarSaldos();
            _mostrarResumoTransferencia();
          },
        );
        
        // 3. Navega de volta
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _mostrarErro(e.toString());
    }
  }
  
  Future<bool> _executarTransferencia() async {
    // Simula operação de transferência
    await Future.delayed(Duration(seconds: 1));
    return true;
  }
  
  void _recarregarSaldos() {
    // Recarrega saldos das contas envolvidas
    setState(() {});
  }
  
  void _recarregarExtratoTransferencias() {
    // Recarrega histórico de transferências
    setState(() {});
  }
  
  void _mostrarResumoTransferencia() {
    // Mostra resumo detalhado da transferência
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transferência Concluída'),
        content: Text('Sua transferência foi processada com sucesso!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _mostrarErro(String erro) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro na transferência: $erro'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transferências - Feedback')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _realizarTransferencia,
              child: Text('Transferência Simples'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _transferenciaCustomizada,
              child: Text('Transferência Customizada'),
            ),
          ],
        ),
      ),
    );
  }
}
