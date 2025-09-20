// 📂 Relatório Categoria Page - iPoupei Mobile
// 
// Página de análise por categoria
// Mostra onde você mais gasta e recebe
// 
// Baseado em: Material Design + Category Analytics

import 'package:flutter/material.dart';

class RelatorioCategoriaPage extends StatelessWidget {
  final DateTime dataInicio;
  final DateTime dataFim;

  const RelatorioCategoriaPage({
    super.key,
    required this.dataInicio,
    required this.dataFim,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise por Categoria'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Análise por Categoria - Em desenvolvimento'),
      ),
    );
  }
}