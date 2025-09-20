// 📈 Evolução Mensal Page - iPoupei Mobile
// 
// Página de evolução mensal com gráficos
// Mostra tendências ao longo do tempo
// 
// Baseado em: Material Design + Charts

import 'package:flutter/material.dart';

class EvolucaoMensalPage extends StatelessWidget {
  final DateTime dataInicio;
  final DateTime dataFim;

  const EvolucaoMensalPage({
    super.key,
    required this.dataInicio,
    required this.dataFim,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolução Mensal'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Evolução Mensal - Em desenvolvimento'),
      ),
    );
  }
}