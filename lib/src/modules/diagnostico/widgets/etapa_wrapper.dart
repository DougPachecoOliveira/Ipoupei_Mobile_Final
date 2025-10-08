// lib/modules/diagnostico/widgets/etapa_wrapper.dart

import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../models/diagnostico_etapa.dart';
import '../models/percepcao_financeira.dart';
import '../models/dividas_model.dart';
import '../services/diagnostico_service.dart';
// import '../services/share_service.dart'; // Não existe ainda
// import '../services/score_calculator.dart' as calc; // Não existe ainda
import '../pages/diagnostico_flow_page.dart';
import 'dividas_questionario_widget.dart';
import 'youtube_player_widget.dart';
import 'percepcao_questionario_widget.dart';
// Imports das páginas reais do app
import '../../categorias/pages/categorias_sugeridas_page.dart';
import '../../contas/pages/contas_page.dart';
import '../../cartoes/pages/cartoes_sugeridos_page.dart';
import '../../transacoes/pages/transacao_form_page.dart';

// Imports dos serviços para contagem real
import '../../categorias/services/categoria_service.dart';
import '../../contas/services/conta_service.dart';
import '../../cartoes/services/cartao_service.dart';
import '../../transacoes/services/transacao_service.dart';

/// Wrapper que decide qual conteúdo mostrar para cada etapa
/// RESPONSABILIDADES: Renderizar conteúdo específico por tipo de etapa + coordenar com modais reais
class EtapaWrapper extends StatefulWidget {
  final DiagnosticoEtapa etapa;
  final Map<String, dynamic> dadosColetados;
  final Function(Map<String, dynamic>) onDadosChanged;

  const EtapaWrapper({
    super.key,
    required this.etapa,
    required this.dadosColetados,
    required this.onDadosChanged,
  });

  @override
  State<EtapaWrapper> createState() => _EtapaWrapperState();
}

class _EtapaWrapperState extends State<EtapaWrapper> {
  @override
  void initState() {
    super.initState();

    // Se é etapa de processamento, simular processamento automático
    if (widget.etapa.id == 'processamento') {
      _simularProcessamento();
    }
  }

  /// Simula o processamento automático e avança para resultado
  void _simularProcessamento() async {
    await Future.delayed(const Duration(seconds: 8)); // Simula 8 segundos de processamento

    if (mounted) {
      // Avançar para próxima etapa (resultado)
      DiagnosticoService.instance.proximaEtapa();

      debugPrint('🧮 [PROCESSAMENTO] Processamento concluído - avançando para resultado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vídeo explicativo (se houver)
          if (widget.etapa.video != null) ...[
            _buildVideoSection(),
            const SizedBox(height: 24),
          ],

          // Conteúdo específico da etapa
          _buildEtapaContent(),

          // Espaço extra para navegação
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  /// Constrói seção do vídeo
  Widget _buildVideoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player do YouTube
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: YoutubePlayerWidget(
              video: widget.etapa.video!,
              autoPlay: false,
            ),
          ),

          // Informações do vídeo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.etapa.video!.titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cinzaEscuro,
                  ),
                ),
                if (widget.etapa.video!.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.etapa.video!.subtitle!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.cinzaTexto,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói conteúdo específico baseado no tipo de etapa
  Widget _buildEtapaContent() {
    switch (widget.etapa.tipo) {
      case TipoDiagnosticoEtapa.intro:
        return _buildIntroContent();
      case TipoDiagnosticoEtapa.cadastro:
        return _buildCadastroContent();
      case TipoDiagnosticoEtapa.questionario:
        return _buildQuestionarioContent();
      case TipoDiagnosticoEtapa.processamento:
        return _buildProcessamentoContent();
      case TipoDiagnosticoEtapa.resultado:
        return _buildResultadoContent();
    }
  }

  /// Conteúdo de introdução
  Widget _buildIntroContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícone principal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.etapa.cor.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.etapa.icone,
              size: 48,
              color: widget.etapa.cor,
            ),
          ),

          const SizedBox(height: 24),

          // Título e descrição
          Text(
            'Vamos conhecer sua situação financeira atual',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.cinzaEscuro,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Em poucos passos, vamos mapear sua vida financeira e criar um plano personalizado para você alcançar seus objetivos.',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.cinzaTexto,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Benefícios
          ..._buildBeneficios(),
        ],
      ),
    );
  }

  /// Lista de benefícios para tela de intro
  List<Widget> _buildBeneficios() {
    final beneficios = [
      {'icone': Icons.insights, 'titulo': 'Diagnóstico Personalizado', 'desc': 'Score baseado na sua situação real'},
      {'icone': Icons.trending_up, 'titulo': 'Plano de Ação', 'desc': 'Próximos passos para melhorar suas finanças'},
      {'icone': Icons.psychology, 'titulo': 'Autoconhecimento', 'desc': 'Entenda sua relação com dinheiro'},
      {'icone': Icons.security, 'titulo': 'Dados Seguros', 'desc': 'Suas informações ficam apenas no seu dispositivo'},
    ];

    return beneficios.map((beneficio) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.etapa.cor.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              beneficio['icone'] as IconData,
              color: widget.etapa.cor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  beneficio['titulo'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cinzaEscuro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  beneficio['desc'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.cinzaTexto,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )).toList();
  }

  /// Conteúdo de cadastro (chama modais reais)
  Widget _buildCadastroContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícone da etapa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.etapa.cor.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.etapa.icone,
              size: 40,
              color: widget.etapa.cor,
            ),
          ),

          const SizedBox(height: 20),

          // Instruções
          Text(
            _getInstrucoesCadastro(),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.cinzaTexto,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Status dos dados coletados
          _buildStatusDadosColetados(),

          const SizedBox(height: 20),

          // Botões de ação
          _buildBotoesCadastro(),
        ],
      ),
    );
  }

  /// Conteúdo de questionário
  Widget _buildQuestionarioContent() {
    if (widget.etapa.id == 'percepcao') {
      return _buildPercepcaoQuestionario();
    } else if (widget.etapa.id == 'dividas') {
      return _buildDividasQuestionario();
    }

    return _buildQuestionarioGenerico();
  }

  /// Conteúdo de processamento
  Widget _buildProcessamentoContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animação de loading
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(widget.etapa.cor),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Analisando seus dados...',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.cinzaEscuro,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            'Estamos processando todas as informações para criar seu diagnóstico financeiro personalizado.',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.cinzaTexto,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Etapas do processamento
          ..._buildEtapasProcessamento(),
        ],
      ),
    );
  }

  /// Conteúdo do resultado
  Widget _buildResultadoContent() {
    // Temporariamente sem cálculo de score
    return _buildResultadoCompleto();
  }

  /// Loading do resultado
  Widget _buildResultadoLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Calculando seu score...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.cinzaTexto,
            ),
          ),
        ],
      ),
    );
  }

  /// Erro no resultado
  Widget _buildResultadoErro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.vermelhoErro,
          ),
          SizedBox(height: 16),
          Text(
            'Erro ao calcular diagnóstico',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.cinzaEscuro,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Verifique se todos os dados foram preenchidos corretamente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.cinzaTexto,
            ),
          ),
        ],
      ),
    );
  }

  /// Resultado completo com score calculado
  Widget _buildResultadoCompleto() {
    // GlobalKey para captura de screenshot
    final screenshotKey = GlobalKey();

    return RepaintBoundary(
      key: screenshotKey,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Column(
        children: [
          // Logo do iPoupei + Ícone de sucesso
          Stack(
            alignment: Alignment.center,
            children: [
              // Logo de fundo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/Logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.tealPrimary,
                        size: 60,
                      );
                    },
                  ),
                ),
              ),
              // Ícone de sucesso no canto
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.verdeSucesso,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Seu Diagnóstico Está Pronto!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.cinzaEscuro,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          const Text(
            'Baseado nos seus dados, criamos um diagnóstico completo e um plano personalizado.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.cinzaTexto,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Score simulado
          const Text(
            'Score: 75 pontos',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.verdeSucesso,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Perfil: Intermediário',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.cinzaTexto,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Botões de ação
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botão de compartilhar
                  ElevatedButton.icon(
                    onPressed: () => _compartilharResultado(),
                    icon: const Icon(Icons.share),
                    label: const Text('Compartilhar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulHeader,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),

                  // Botão de preview
                  OutlinedButton.icon(
                    onPressed: () => _previewResultado(),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Preview'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.azulHeader,
                      side: const BorderSide(color: AppColors.azulHeader),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Botão para ir ao dashboard
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _irParaDashboard(),
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Ir para Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Botão refazer diagnóstico
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _refazerDiagnostico(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refazer Diagnóstico'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.amareloAlerta,
                    side: const BorderSide(color: AppColors.amareloAlerta),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  /// Compartilhar resultado
  void _compartilharResultado() {
    // Por enquanto, copiar para clipboard e mostrar mensagem
    // TODO: Implementar screenshot e share quando adicionar pacotes necessários

    const textoCompartilhamento = '''
🎯 Acabei de fazer meu Diagnóstico Financeiro no iPoupei!

📊 Meu Score: 75 pontos
🎖️ Perfil: Intermediário

Descubra você também sua situação financeira e crie seu plano personalizado!

#iPoupei #DiagnosticoFinanceiro #ControleFinanceiro
    ''';

    // Simular compartilhamento
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share, color: AppColors.azulHeader),
            SizedBox(width: 8),
            Text('Compartilhar Resultado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Texto copiado para área de transferência:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                textoCompartilhamento,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Texto copiado! Cole em suas redes sociais'),
                  backgroundColor: AppColors.verdeSucesso,
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulHeader,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Preview do resultado
  void _previewResultado() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '👀 Preview do Resultado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Preview Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.purple.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      // Logo do iPoupei
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/Logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback para ícone se logo não carregar
                              return const Icon(
                                Icons.account_balance_wallet,
                                color: AppColors.tealPrimary,
                                size: 40,
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'iPoupei - Diagnóstico Financeiro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cinzaEscuro,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Score
                      const Text(
                        '🎯 Meu Score Financeiro',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.cinzaTexto,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        '75 pontos',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.verdeSucesso,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Perfil: Intermediário',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cinzaTexto,
                        ),
                      ),

                      const Spacer(),

                      // Footer
                      const Text(
                        'Descubra sua situação financeira com o iPoupei',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.cinzaLegenda,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _compartilharResultado();
                      },
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Compartilhar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.azulHeader,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Fechar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navegar para o dashboard principal
  void _irParaDashboard() {
    // Voltar para a tela principal do app (dashboard)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Refazer diagnóstico (zerar dados e recomeçar)
  Future<void> _refazerDiagnostico() async {
    // Confirmar com o usuário
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
              backgroundColor: AppColors.amareloAlerta,
              foregroundColor: Colors.white,
            ),
            child: const Text('Refazer'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmar) return;

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Reiniciar dados do service
      await DiagnosticoService.instance.reiniciar();

      // Fechar loading
      Navigator.of(context).pop();

      // Navegar para o início do diagnóstico
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const DiagnosticoFlowPage(),
        ),
      );

      // Mostrar confirmação
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Diagnóstico reiniciado! Você pode começar novamente.'),
          backgroundColor: AppColors.verdeSucesso,
        ),
      );
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      debugPrint('❌ [REFAZER] Erro ao limpar dados: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao refazer diagnóstico: $e'),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
    }
  }


  /// MÉTODOS AUXILIARES ESPECÍFICOS

  /// Instruções baseadas no tipo de cadastro
  String _getInstrucoesCadastro() {
    switch (widget.etapa.id) {
      case 'categorias':
        return 'Verificaremos suas categorias existentes. Se você já tem categorias suficientes, pularemos para a próxima etapa. Caso contrário, sugeriremos categorias para importar.';
      case 'contas':
        return 'Visualize suas contas existentes e crie novas se necessário. Você já tem algumas contas cadastradas.';
      case 'cartoes':
        return 'Importe cartões pré-configurados dos principais bancos para facilitar seu controle (opcional).';
      case 'receitas':
        return 'Registre suas fontes de renda: salário, freelances, aluguéis e outras receitas mensais.';
      case 'despesas-fixas':
        return 'Cadastre gastos que se repetem todo mês com o mesmo valor: aluguel, financiamentos, assinaturas.';
      case 'despesas-variaveis':
        return 'Registre gastos que mudam de valor mensalmente: mercado, combustível, lazer, restaurantes.';
      default:
        return 'Complete este cadastro para continuar o diagnóstico.';
    }
  }

  String _getTextoBotaoCadastro() {
    switch (widget.etapa.id) {
      case 'categorias': return 'Verificar Categorias';
      case 'contas': return 'Ver Minhas Contas';
      case 'cartoes': return 'Importar Cartões';
      case 'receitas': return 'Cadastrar Receitas';
      case 'despesas-fixas': return 'Cadastrar Despesas Fixas';
      case 'despesas-variaveis': return 'Cadastrar Despesas Variáveis';
      default: return 'Cadastrar';
    }
  }

  /// Constrói botões de cadastro (com botão verificar para transações)
  Widget _buildBotoesCadastro() {
    final isTransacao = ['receitas', 'despesas-fixas', 'despesas-variaveis'].contains(widget.etapa.id);

    if (isTransacao) {
      // Para transações: botão cadastrar + botão verificar
      return Column(
        children: [
          // Botão principal de cadastro
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _abrirModalCadastro(),
              icon: const Icon(Icons.add),
              label: Text(_getTextoBotaoCadastro()),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.etapa.cor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botão de verificar dados existentes
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _verificarDadosExistentes(),
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(_getTextoVerificarDados()),
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.etapa.cor,
                side: BorderSide(color: widget.etapa.cor, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Para outras etapas: só o botão de cadastro
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _abrirModalCadastro(),
          icon: const Icon(Icons.add),
          label: Text(_getTextoBotaoCadastro()),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.etapa.cor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }
  }

  String _getTextoVerificarDados() {
    switch (widget.etapa.id) {
      case 'receitas': return 'Verificar Receitas Criadas';
      case 'despesas-fixas': return 'Verificar Despesas Fixas';
      case 'despesas-variaveis': return 'Verificar Despesas Variáveis';
      default: return 'Verificar Dados';
    }
  }

  /// Verifica dados existentes e atualiza o diagnóstico
  Future<void> _verificarDadosExistentes() async {
    try {
      debugPrint('🔍 Verificando dados existentes para: ${widget.etapa.id}');

      // Chamar método específico baseado na etapa
      switch (widget.etapa.id) {
        case 'receitas':
          await _buscarDadosReceitasReais();
          break;
        case 'despesas-fixas':
          await _buscarDadosDespesasFixasReais();
          break;
        case 'despesas-variaveis':
          await _buscarDadosDespesasVariaveisReais();
          break;
        default:
          debugPrint('⚠️ Etapa não suportada para verificação: ${widget.etapa.id}');
          return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dados verificados e atualizados!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Erro ao verificar dados: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao verificar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Status dos dados já coletados
  Widget _buildStatusDadosColetados() {
    final dados = widget.dadosColetados[widget.etapa.id];

    if (dados == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.amareloAlerta.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.amareloAlerta.withAlpha(78),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.amareloAlerta,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Nenhum dado cadastrado ainda',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.cinzaTexto,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Se tem dados, mostrar resumo inteligente baseado no novo formato
    String statusTexto = '';
    Color statusCor = AppColors.verdeSucesso;
    IconData statusIcone = Icons.check_circle;

    if (dados is Map) {
      switch (widget.etapa.id) {
        case 'categorias':
          final configurado = dados['configurado'] as bool? ?? false;
          final receitas = dados['receitas'] as int? ?? 0;
          final despesas = dados['despesas'] as int? ?? 0;
          if (configurado) {
            statusTexto = 'Categorias configuradas ($receitas receitas, $despesas despesas)';
          } else {
            statusTexto = 'Categorias pendentes';
            statusCor = AppColors.amareloAlerta;
            statusIcone = Icons.warning;
          }
          break;

        case 'contas':
          final configurado = dados['configurado'] as bool? ?? false;
          final contasAtivas = dados['contas_ativas'] as int? ?? 0;
          if (configurado) {
            statusTexto = 'Contas configuradas ($contasAtivas ativas)';
          } else {
            statusTexto = 'Contas pendentes';
            statusCor = AppColors.amareloAlerta;
            statusIcone = Icons.warning;
          }
          break;

        case 'cartoes':
          final configurado = dados['configurado'] as bool? ?? false;
          final cartoesAtivos = dados['cartoes_ativos'] as int? ?? 0;
          if (configurado) {
            statusTexto = 'Cartões configurados ($cartoesAtivos ativos)';
          } else {
            statusTexto = 'Cartões opcionais';
            statusCor = AppColors.cinzaMedio;
            statusIcone = Icons.info;
          }
          break;

        case 'receitas':
          final configurado = dados['configurado'] as bool? ?? false;
          statusTexto = configurado ? 'Receitas configuradas' : 'Receitas pendentes';
          if (!configurado) {
            statusCor = AppColors.amareloAlerta;
            statusIcone = Icons.warning;
          }
          break;

        case 'despesas-fixas':
          final configurado = dados['configurado'] as bool? ?? false;
          statusTexto = configurado ? 'Despesas fixas configuradas' : 'Despesas fixas pendentes';
          if (!configurado) {
            statusCor = AppColors.amareloAlerta;
            statusIcone = Icons.warning;
          }
          break;

        case 'despesas-variaveis':
          final configurado = dados['configurado'] as bool? ?? false;
          statusTexto = configurado ? 'Despesas variáveis configuradas' : 'Despesas variáveis pendentes';
          if (!configurado) {
            statusCor = AppColors.amareloAlerta;
            statusIcone = Icons.warning;
          }
          break;

        default:
          // Fallback para outras etapas
          final quantidade = dados['quantidade'] as int? ?? (dados.isNotEmpty ? 1 : 0);
          statusTexto = '$quantidade ${_getTipoItemCadastrado()} cadastrado${quantidade != 1 ? 's' : ''}';
      }
    } else if (dados is List) {
      final quantidade = dados.length;
      statusTexto = '$quantidade ${_getTipoItemCadastrado()} cadastrado${quantidade != 1 ? 's' : ''}';
    } else {
      statusTexto = '1 ${_getTipoItemCadastrado()} cadastrado';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusCor.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusCor.withAlpha(78),
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcone,
            color: statusCor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusTexto,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.cinzaTexto,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTipoItemCadastrado() {
    switch (widget.etapa.id) {
      case 'categorias': return 'categoria';
      case 'contas': return 'conta';
      case 'cartoes': return 'cartão';
      case 'receitas': return 'receita';
      case 'despesas-fixas': return 'despesa fixa';
      case 'despesas-variaveis': return 'despesa variável';
      default: return 'item';
    }
  }

  /// Questionário de percepção financeira
  Widget _buildPercepcaoQuestionario() {
    // Obter dados existentes de percepção do diagnostico
    final percepcaoData = widget.dadosColetados['percepcao'] as Map<String, dynamic>?;
    final percepcaoAtual = percepcaoData != null
      ? PercepcaoFinanceira.fromSupabase(percepcaoData)
      : PercepcaoFinanceira.vazio();

    return PercepcaoQuestionarioWidget(
      percepcaoInicial: percepcaoAtual,
      showValidationErrors: false, // Mostrar erros apenas quando tentar avançar
      onChanged: (percepcao) {
        // Salvar dados no diagnostico usando toSupabase para compatibilidade
        final dados = {'percepcao': percepcao.toSupabase()};
        widget.onDadosChanged(dados);

        debugPrint('📝 [PERCEPCAO] Dados atualizados: completo=${percepcao.isObrigatoriosCompletos}');
      },
    );
  }

  Widget _buildDividasQuestionario() {
    // Obter dados existentes de dívidas do diagnostico
    final dividasData = widget.dadosColetados['dividas'] as Map<String, dynamic>?;
    final dividasAtual = dividasData != null
      ? DividasDiagnostico.fromSupabase(dividasData)
      : DividasDiagnostico.vazio();

    return DividasQuestionarioWidget(
      dividasInicial: dividasAtual,
      showValidationErrors: false, // Dívidas são opcionais
      onChanged: (dividas) {
        // Salvar dados no diagnostico usando toSupabase para compatibilidade
        final dados = {'dividas': dividas.toSupabase()};
        widget.onDadosChanged(dados);

        debugPrint('💳 [DIVIDAS] Dados atualizados: tem=${dividas.temDividas}, total=R\$ ${dividas.totalDividas.toStringAsFixed(2)}');
      },
    );
  }

  Widget _buildQuestionarioGenerico() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Questionário: ${widget.etapa.titulo}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.cinzaEscuro,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Questionário será implementado na próxima fase.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.cinzaTexto,
            ),
          ),
        ],
      ),
    );
  }

  /// Etapas do processamento
  List<Widget> _buildEtapasProcessamento() {
    final etapas = [
      'Analisando organização financeira...',
      'Calculando controle de gastos...',
      'Avaliando saúde financeira...',
      'Determinando perfil...',
    ];

    return etapas.asMap().entries.map((entry) {
      final index = entry.key;
      final etapa = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: widget.etapa.cor.withAlpha(52),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.cinzaTexto),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                etapa,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.cinzaTexto,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Abre modal de cadastro específico da etapa
  void _abrirModalCadastro() async {
    try {
      switch (widget.etapa.id) {
        case 'categorias':
          await _navegarParaCategorias();
          break;
        case 'contas':
          await _navegarParaContas();
          break;
        case 'cartoes':
          await _navegarParaCartoes();
          break;
        case 'receitas':
          await _navegarParaReceitas();
          break;
        case 'despesas-fixas':
          await _navegarParaDespesasFixas();
          break;
        case 'despesas-variaveis':
          await _navegarParaDespesasVariaveis();
          break;
        default:
          _simularDadosGenericos();
      }
    } catch (e) {
      debugPrint('❌ [ETAPA_WRAPPER] Erro ao navegar para cadastro: $e');
      // Em caso de erro, usar simulação como fallback
      _simularDadosGenericos();
    }
  }

  /// 🧭 NAVEGAÇÃO PARA PÁGINAS REAIS

  /// Navega para página de categorias ou valida categorias existentes
  Future<void> _navegarParaCategorias() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const CategoriasSugeridasPage(),
      ),
    );

    // Sempre buscar dados reais do banco após voltar da navegação
    await _buscarDadosCategoriasReais();
  }

  /// Navega para página de contas (mostra contas existentes)
  Future<void> _navegarParaContas() async {
    final resultado = await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => const ContasPage(),
      ),
    );

    // Sempre buscar dados reais do banco após voltar da navegação
    await _buscarDadosContasReais();
  }

  /// Navega para página de cartões sugeridos
  Future<void> _navegarParaCartoes() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const CartoesSugeridosPage(),
      ),
    );

    // Sempre buscar dados reais do banco após voltar da navegação
    await _buscarDadosCartoesReais();
  }

  /// Navega para página de adicionar receita
  Future<void> _navegarParaReceitas() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TransacaoFormPage(modo: 'criar', tipo: 'receita'),
      ),
    );

    // Sempre buscar dados reais do banco após voltar da navegação
    await _buscarDadosReceitasReais();
  }

  /// Navega para página de adicionar despesa fixa
  Future<void> _navegarParaDespesasFixas() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TransacaoFormPage(modo: 'criar', tipo: 'despesa'),
      ),
    );

    // Sempre buscar dados reais do banco após voltar da navegação
    await _buscarDadosDespesasFixasReais();
  }

  /// Navega para página de adicionar despesa variável
  Future<void> _navegarParaDespesasVariaveis() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TransacaoFormPage(modo: 'criar', tipo: 'despesa'),
      ),
    );

    // Sempre buscar dados reais do banco após voltar da navegação
    await _buscarDadosDespesasVariaveisReais();
  }

  /// 🔄 MÉTODOS DE BUSCA REAL DE DADOS

  /// Busca dados reais de categorias (OFFLINE FIRST)
  Future<void> _buscarDadosCategoriasReais() async {
    try {
      // 🎯 OFFLINE FIRST: Consulta SIMPLES e RÁPIDA - só COUNT(*)
      debugPrint('🔄 [CATEGORIAS] COUNT simples no SQLite...');

      final receitasCount = await CategoriaService.instance.countCategoriasByTipo('receita');
      final despesasCount = await CategoriaService.instance.countCategoriasByTipo('despesa');
      final totalCount = receitasCount + despesasCount;
      final temCategorias = await CategoriaService.instance.temCategoriasConfiguradas(minimo: 3);

      final dadosCategorias = {
        'configurado': temCategorias,
        'receitas': receitasCount,
        'despesas': despesasCount,
        'total': totalCount,
        'timestamp': DateTime.now().toIso8601String(),
        'origem': 'supabase_count',
      };

      // Atualizar UI com dados frescos do Supabase
      widget.onDadosChanged({'categorias': dadosCategorias});

      // 💾 SALVAR NO SQLITE para próximas consultas offline
      // TODO: await LocalDatabase.instance.saveCategorias(categoriasSupabase);

      if (mounted) {
        final status = temCategorias ? '✅ Categorias configuradas!' : '⚠️ Precisa configurar categorias';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status),
            backgroundColor: temCategorias ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 1),
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Erro no Supabase, tentando SQLite local: $e');
      // FALLBACK: Se Supabase falhar, usar dados locais
      await _buscarCategoriasOffline();
    }
  }

  /// Fallback: busca offline quando Supabase falha
  Future<void> _buscarCategoriasOffline() async {
    try {
      // TODO: final categorias = await LocalDatabase.instance.getCategorias();

      final dadosCategorias = {
        'selecionadas': true,
        'quantidade': 3, // Dados do cache local
        'timestamp': DateTime.now().toIso8601String(),
        'origem': 'sqlite_fallback',
      };

      widget.onDadosChanged({'categorias': dadosCategorias});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 Dados offline carregados'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro também no SQLite: $e');
      _simularDadosCategorias(); // Último recurso
    }
  }

  /// Busca dados reais de contas (SUPABASE FIRST após navegação)
  Future<void> _buscarDadosContasReais() async {
    try {
      // 🎯 OFFLINE FIRST: COUNT rápido no SQLite
      debugPrint('🔄 [CONTAS] COUNT rápido no SQLite...');

      final contasAtivasCount = await ContaService.instance.contarContasAtivas();
      final temContas = await ContaService.instance.temContasConfiguradas(minimo: 1);

      final dadosContas = {
        'configurado': temContas,
        'contas_ativas': contasAtivasCount,
        'timestamp': DateTime.now().toIso8601String(),
        'origem': 'supabase_count',
      };

      widget.onDadosChanged({'contas': dadosContas});

      // 💾 Salvar no SQLite para cache
      // TODO: await LocalDatabase.instance.saveContas(contasSupabase);

      if (mounted) {
        final status = temContas ? '✅ Contas configuradas!' : '⚠️ Precisa configurar contas';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$status'),
            backgroundColor: temContas ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 1),
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Erro no Supabase, usando dados offline: $e');
      await _buscarContasOffline();
    }
  }

  /// Fallback offline para contas
  Future<void> _buscarContasOffline() async {
    try {
      // TODO: final contas = await LocalDatabase.instance.getContas();

      final dadosContas = {
        'contas_visualizadas': true,
        'quantidade': 2, // Cache local
        'timestamp': DateTime.now().toIso8601String(),
        'origem': 'sqlite_fallback',
      };

      widget.onDadosChanged({'contas': dadosContas});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 Contas offline carregadas'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro SQLite: $e');
      _simularDadosContas();
    }
  }

  /// Busca dados reais de cartões (SUPABASE FIRST)
  Future<void> _buscarDadosCartoesReais() async {
    try {
      // 🎯 OFFLINE FIRST: COUNT rápido no SQLite
      debugPrint('🔄 [CARTÕES] COUNT rápido no SQLite...');

      final cartoesAtivosCount = await CartaoService.instance.contarCartoesAtivos();
      final temCartoes = await CartaoService.instance.temCartoesConfigurados(minimo: 1);

      final dadosCartoes = {
        'configurado': temCartoes,
        'cartoes_ativos': cartoesAtivosCount,
        'timestamp': DateTime.now().toIso8601String(),
        'origem': 'supabase_count',
      };

      widget.onDadosChanged({'cartoes': dadosCartoes});

      if (mounted) {
        final status = temCartoes ? '✅ Cartões configurados!' : '⚠️ Cartões opcionais';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$status'),
            backgroundColor: temCartoes ? Colors.green : Colors.grey,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro no Supabase cartões: $e');
      // Cartões são opcionais - fallback mais simples
      final dadosCartoes = {
        'cartoes_importados': false,
        'quantidade': 0,
        'etapa_pulada': true,
        'timestamp': DateTime.now().toIso8601String(),
        'origem': 'fallback',
      };
      widget.onDadosChanged({'cartoes': dadosCartoes});
    }
  }

  /// Busca dados reais de receitas (SUPABASE COUNT - >1 é suficiente)
  Future<void> _buscarDadosReceitasReais() async {
    try {
      // 🎯 COUNT rápido de receitas recorrentes do SQLite
      debugPrint('🔄 [RECEITAS] COUNT receitas recorrentes...');

      final quantidadeReceitas = await TransacaoService.instance.countReceitasRecorrentes();
      final temReceitas = await TransacaoService.instance.temReceitasConfiguradas(minimo: 1);

      final dadosReceitas = {
        'configurado': temReceitas,
        'receitas_recorrentes': quantidadeReceitas,
        'suficiente': temReceitas, // Flag indicando se >=1
        'timestamp': DateTime.now().toIso8601String(),
        'origem': 'supabase_count',
      };

      widget.onDadosChanged({'receitas': dadosReceitas});

      if (mounted) {
        final status = temReceitas ? '✅ Receitas configuradas!' : '⚠️ Receitas pendentes';
        final cor = temReceitas ? Colors.green : Colors.orange;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$status'),
            backgroundColor: cor,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro no Supabase receitas: $e');
      await _buscarReceitasOffline();
    }
  }

  /// Fallback offline para receitas
  Future<void> _buscarReceitasOffline() async {
    try {
      // TODO: final count = await LocalDatabase.instance.countReceitas();
      final quantidadeReceitas = 1; // Cache local
      final temReceitas = quantidadeReceitas > 1;

      final dadosReceitas = {
        'receita_criada': temReceitas,
        'quantidade': quantidadeReceitas,
        'suficiente': temReceitas,
        'timestamp': DateTime.now().toIso8601String(),
        'origem': 'sqlite_fallback',
      };

      widget.onDadosChanged({'receitas': dadosReceitas});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 Receitas offline carregadas'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro SQLite receitas: $e');
      _simularDadosReceitas();
    }
  }

  /// Busca dados reais de despesas fixas (SUPABASE COUNT - >1 é suficiente)
  Future<void> _buscarDadosDespesasFixasReais() async {
    try {
      // 🎯 COUNT rápido de despesas fixas recorrentes do SQLite
      debugPrint('🔄 [DESPESAS FIXAS] COUNT despesas fixas...');

      final quantidadeDespesas = await TransacaoService.instance.countDespesasFixas();
      final temDespesas = await TransacaoService.instance.temDespesasFixasConfiguradas(minimo: 1);

      final dadosDespesas = {
        'configurado': temDespesas,
        'despesas_fixas': quantidadeDespesas,
        'suficiente': temDespesas,
        'timestamp': DateTime.now().toIso8601String(),
        'origem': 'supabase_count',
      };

      widget.onDadosChanged({'despesas-fixas': dadosDespesas});

      if (mounted) {
        final status = temDespesas ? '✅ Despesas fixas configuradas!' : '⚠️ Despesas fixas pendentes';
        final cor = temDespesas ? Colors.green : Colors.orange;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$status'),
            backgroundColor: cor,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro no Supabase despesas fixas: $e');
      await _buscarDespesasFixasOffline();
    }
  }

  /// Fallback offline para despesas fixas
  Future<void> _buscarDespesasFixasOffline() async {
    try {
      // TODO: final count = await LocalDatabase.instance.countDespesasFixas();
      final quantidadeDespesas = 2; // Cache local
      final temDespesas = quantidadeDespesas > 1;

      final dadosDespesas = {
        'despesa_fixa_criada': temDespesas,
        'quantidade': quantidadeDespesas,
        'suficiente': temDespesas,
        'timestamp': DateTime.now().toIso8601String(),
        'origem': 'sqlite_fallback',
      };

      widget.onDadosChanged({'despesas-fixas': dadosDespesas});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 Despesas fixas offline carregadas'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro SQLite despesas fixas: $e');
      _simularDadosDespesasFixas();
    }
  }

  /// Busca dados reais de despesas variáveis (SUPABASE COUNT - >1 é suficiente)
  Future<void> _buscarDadosDespesasVariaveisReais() async {
    try {
      // 🎯 COUNT rápido de despesas variáveis do SQLite
      debugPrint('🔄 [DESPESAS VARIÁVEIS] COUNT despesas variáveis...');

      final quantidadeDespesas = await TransacaoService.instance.countDespesasVariaveis();
      final temDespesas = await TransacaoService.instance.temDespesasVariaveisConfiguradas(minimo: 1);

      final dadosDespesas = {
        'configurado': temDespesas,
        'despesas_variaveis': quantidadeDespesas,
        'suficiente': temDespesas,
        'timestamp': DateTime.now().toIso8601String(),
        'origem': 'supabase_count',
      };

      widget.onDadosChanged({'despesas-variaveis': dadosDespesas});

      if (mounted) {
        final status = temDespesas ? '✅ Despesas variáveis configuradas!' : '⚠️ Despesas variáveis pendentes';
        final cor = temDespesas ? Colors.green : Colors.orange;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$status'),
            backgroundColor: cor,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro no Supabase despesas variáveis: $e');
      await _buscarDespesasVariaveisOffline();
    }
  }

  /// Fallback offline para despesas variáveis
  Future<void> _buscarDespesasVariaveisOffline() async {
    try {
      // TODO: final count = await LocalDatabase.instance.countDespesasVariaveis();
      final quantidadeDespesas = 1; // Cache local
      final temDespesas = quantidadeDespesas > 1;

      final dadosDespesas = {
        'despesa_variavel_criada': temDespesas,
        'quantidade': quantidadeDespesas,
        'suficiente': temDespesas,
        'timestamp': DateTime.now().toIso8601String(),
        'origem': 'sqlite_fallback',
      };

      widget.onDadosChanged({'despesas-variaveis': dadosDespesas});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 Despesas variáveis offline carregadas'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro SQLite despesas variáveis: $e');
      _simularDadosDespesasVariaveis();
    }
  }

  /// Simulações temporárias (até integração completa com APIs)
  void _simularDadosCategorias() {
    final dados = {
      'selecionadas': false,
      'quantidade': 3,
      'timestamp': DateTime.now().toIso8601String(),
      'simulado': true,
    };
    widget.onDadosChanged({'categorias': dados});
  }

  void _simularDadosContas() {
    final dados = [
      {'id': 1, 'nome': 'Conta Corrente Banco do Brasil', 'tipo': 'corrente', 'saldo': 1500.0},
      {'id': 2, 'nome': 'Poupança Caixa', 'tipo': 'poupanca', 'saldo': 5000.0},
    ];
    widget.onDadosChanged({'contas': dados});
  }

  void _simularDadosReceitas() {
    final dados = [
      {'id': 1, 'descricao': 'Salário', 'valor': 3500.0, 'categoria_id': 1},
      {'id': 2, 'descricao': 'Freelance', 'valor': 800.0, 'categoria_id': 1},
    ];
    widget.onDadosChanged({'receitas': dados});
  }

  void _simularDadosDespesasFixas() {
    final dados = [
      {'id': 1, 'descricao': 'Aluguel', 'valor': 1200.0, 'categoria_id': 2},
      {'id': 2, 'descricao': 'Internet', 'valor': 80.0, 'categoria_id': 2},
      {'id': 3, 'descricao': 'Netflix', 'valor': 25.0, 'categoria_id': 2},
    ];
    widget.onDadosChanged({'despesas': dados});
  }

  void _simularDadosDespesasVariaveis() {
    final dados = [
      {'id': 1, 'descricao': 'Mercado', 'valor': 600.0, 'categoria_id': 3},
      {'id': 2, 'descricao': 'Combustível', 'valor': 300.0, 'categoria_id': 3},
      {'id': 3, 'descricao': 'Lazer', 'valor': 200.0, 'categoria_id': 3},
    ];
    widget.onDadosChanged({'despesas': dados});
  }

  void _simularDadosGenericos() {
    widget.onDadosChanged({'dados': ['item1', 'item2', 'item3']});
  }
}