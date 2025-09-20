// 🏦 Relatório Conta Page - iPoupei Mobile
// 
// Página de análise por conta
// Performance de cada conta bancária
// 
// Baseado em: Material Design + Account Analytics

import 'package:flutter/material.dart';

class RelatorioContaPage extends StatelessWidget {
  final DateTime dataInicio;
  final DateTime dataFim;

  const RelatorioContaPage({
    super.key,
    required this.dataInicio,
    required this.dataFim,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise por Conta'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Análise por Conta - Em desenvolvimento'),
      ),
    );
  }
}