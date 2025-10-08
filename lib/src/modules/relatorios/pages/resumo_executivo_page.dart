// 📊 Resumo Executivo Page - iPoupei Mobile
// 
// Página de resumo executivo com indicadores financeiros
// Dashboard completo com métricas principais
// 
// Baseado em: Material Design + Analytics Dashboard

import 'package:flutter/material.dart';

class ResumoExecutivoPage extends StatelessWidget {
  final DateTime dataInicio;
  final DateTime dataFim;

  const ResumoExecutivoPage({
    super.key,
    required this.dataInicio,
    required this.dataFim,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumo Executivo'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Resumo Executivo - Em desenvolvimento'),
      ),
    );
  }
}