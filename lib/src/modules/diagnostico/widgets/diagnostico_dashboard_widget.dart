// 📊 Diagnóstico Dashboard Widget - iPoupei Mobile
//
// Widget bonito igual ao offline com gradientes e design sofisticado
// Design inspirado no DiagnosticoDashboard.jsx do offline
//
// Visual: Gradientes + sombras + padrões decorativos

import 'package:flutter/material.dart';
import '../../../database/local_database.dart';
import '../services/diagnostico_service.dart';
import '../services/score_calculator.dart';
import '../pages/diagnostico_flow_page.dart';
import '../models/percepcao_financeira.dart';
import '../../shared/theme/app_colors.dart';

/// Widget bonito do dashboard de diagnóstico
class DiagnosticoDashboardWidget extends StatefulWidget {
  const DiagnosticoDashboardWidget({super.key});

  @override
  State<DiagnosticoDashboardWidget> createState() => _DiagnosticoDashboardWidgetState();
}

class _DiagnosticoDashboardWidgetState extends State<DiagnosticoDashboardWidget> {
  final DiagnosticoService _diagnosticoService = DiagnosticoService();
  final ScoreCalculator _scoreCalculator = ScoreCalculator();

  bool _isLoading = true;
  Map<String, dynamic>? _statusDiagnostico;

  @override
  void initState() {
    super.initState();
    _carregarStatusDiagnostico();
  }

  /// Carregar status do diagnóstico
  Future<void> _carregarStatusDiagnostico() async {
    setState(() => _isLoading = true);

    try {
      final userId = LocalDatabase.instance.currentUserId;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _statusDiagnostico = null;
        });
        return;
      }

      final progresso = await _diagnosticoService.carregarProgresso();
      final etapaAtual = progresso['etapa_atual'] ?? 0;
      final diagnosticoCompleto = progresso['diagnostico_completo'] == 1;

      Map<String, dynamic>? resultado;
      if (diagnosticoCompleto) {
        final percepcao = await _diagnosticoService.carregarPercepcao();
        final dividas = await _diagnosticoService.carregarDividas();
        final contasCount = await _diagnosticoService.contarContas();
        final cartoesCount = await _diagnosticoService.contarCartoes();
        final categoriasCount = await _diagnosticoService.contarCategorias();

        resultado = await _scoreCalculator.calcularResultadoCompleto(
          percepcao: percepcao,
          dividas: dividas,
          contasCount: contasCount,
          cartoesCount: cartoesCount,
          categoriasCount: categoriasCount,
        );
      }

      setState(() {
        _statusDiagnostico = {
          'etapa_atual': etapaAtual,
          'completo': diagnosticoCompleto,
          'resultado': resultado,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (_statusDiagnostico == null) {
      return _buildNotLoggedInCard();
    }

    final completo = _statusDiagnostico!['completo'] ?? false;

    if (completo) {
      return _buildCompletedCard();
    } else {
      return _buildInProgressCard();
    }
  }

  /// Card de loading bonito
  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFf9fafb),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFe5e7eb)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF008080),
            ),
            SizedBox(height: 12),
            Text(
              'Carregando diagnóstico...',
              style: TextStyle(
                color: Color(0xFF6b7280),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card quando não logado
  Widget _buildNotLoggedInCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFf9fafb),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFe5e7eb)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.login,
              color: Color(0xFF6b7280),
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Entre para acessar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1f2937),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Faça login para ver seu diagnóstico',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6b7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Card bonito quando em progresso
  Widget _buildInProgressCard() {
    final etapaAtual = _statusDiagnostico!['etapa_atual'] ?? 0;
    final totalEtapas = 9; // Total de etapas do diagnóstico (incluindo resultado)
    final progresso = ((etapaAtual + 1) / totalEtapas * 100).round().clamp(0, 100);

    return GestureDetector(
      onTap: _abrirDiagnostico,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.tealPrimary, Color(0xFF0F766E)], // Tons de teal
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.tealPrimary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Círculos decorativos
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // Conteúdo principal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com ícone
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Diagnóstico Financeiro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$progresso%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Progresso
                  Text(
                    'Etapa ${etapaAtual + 1} de $totalEtapas',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Barra de progresso
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progresso / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Call to action
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Continuar Diagnóstico',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.tealPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card bonito quando completo
  Widget _buildCompletedCard() {
    final resultado = _statusDiagnostico!['resultado'];
    final score = resultado?['score_total'] ?? 0;

    return GestureDetector(
      onTap: _verResultados,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.tealPrimary, AppColors.tealEscuro],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.tealTransparente50,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Círculos decorativos
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),

            // Conteúdo principal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com troféu
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Diagnóstico Concluído',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Score
                  Row(
                    children: [
                      Text(
                        'Seu Score: ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$score/100',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Botões de ação
                  Row(
                    children: [
                      // Botão Ver Detalhes
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Ver Detalhes',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.tealPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Botão Refazer
                      GestureDetector(
                        onTap: _refazerDiagnostico,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Abrir diagnóstico
  void _abrirDiagnostico() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DiagnosticoFlowPage(),
      ),
    );
  }

  /// Ver resultados
  void _verResultados() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DiagnosticoFlowPage(),
      ),
    );
  }

  /// Refazer diagnóstico
  Future<void> _refazerDiagnostico() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refazer Diagnóstico'),
        content: const Text(
          'Tem certeza que deseja refazer o diagnóstico?\n\n'
          'Todos os dados coletados serão apagados e você começará do início.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Refazer'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        // Reiniciar diagnóstico
        await _diagnosticoService.reiniciar();

        // Recarregar status
        await _carregarStatusDiagnostico();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Diagnóstico reiniciado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navegar para diagnóstico
          _abrirDiagnostico();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro ao reiniciar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}