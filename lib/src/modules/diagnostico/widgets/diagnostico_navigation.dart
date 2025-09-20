// lib/modules/diagnostico/widgets/diagnostico_navigation.dart

import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../models/diagnostico_etapa.dart';

/// Navegação inferior do diagnóstico com botões de voltar/continuar
class DiagnosticoNavigation extends StatelessWidget {
  final DiagnosticoEtapa etapaAtual;
  final bool podeVoltar;
  final bool podeContinuar;
  final VoidCallback? onVoltar;
  final VoidCallback? onContinuar;
  final VoidCallback? onPular; // Para etapas opcionais

  const DiagnosticoNavigation({
    super.key,
    required this.etapaAtual,
    required this.podeVoltar,
    required this.podeContinuar,
    this.onVoltar,
    this.onContinuar,
    this.onPular,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildNavigationContent(context),
        ),
      ),
    );
  }

  Widget _buildNavigationContent(BuildContext context) {
    // Layout especial para etapas de resultado/processamento
    if (etapaAtual.tipo == TipoDiagnosticoEtapa.resultado) {
      return _buildResultadoNavigation();
    }

    if (etapaAtual.tipo == TipoDiagnosticoEtapa.processamento) {
      return _buildProcessamentoNavigation();
    }

    // Layout padrão
    return Row(
      children: [
        // Botão voltar
        _buildBotaoVoltar(),

        const SizedBox(width: 16),

        // Botão pular (se disponível)
        if (onPular != null) ...[
          _buildBotaoPular(),
          const SizedBox(width: 16),
        ],

        // Botão continuar
        Expanded(
          flex: 3,
          child: _buildBotaoContinuar(),
        ),
      ],
    );
  }

  /// Botão voltar
  Widget _buildBotaoVoltar() {
    return Expanded(
      flex: 1,
      child: OutlinedButton.icon(
        onPressed: podeVoltar ? onVoltar : null,
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Voltar'),
        style: OutlinedButton.styleFrom(
          foregroundColor: podeVoltar ? etapaAtual.cor : AppColors.cinzaTexto,
          side: BorderSide(
            color: podeVoltar ? etapaAtual.cor : AppColors.cinzaClaro,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  /// Botão pular (para etapas opcionais)
  Widget _buildBotaoPular() {
    return TextButton(
      onPressed: onPular,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.cinzaTexto,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      child: const Text(
        'Pular',
        style: TextStyle(
          fontSize: 14,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  /// Botão continuar
  Widget _buildBotaoContinuar() {
    return ElevatedButton.icon(
      onPressed: podeContinuar ? onContinuar : null,
      icon: _getBotaoContinuarIcon(),
      label: Text(_getBotaoContinuarTexto()),
      style: ElevatedButton.styleFrom(
        backgroundColor: podeContinuar ? etapaAtual.cor : AppColors.cinzaClaro,
        foregroundColor: Colors.white,
        elevation: podeContinuar ? 2 : 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Navegação para tela de resultado
  Widget _buildResultadoNavigation() {
    return Column(
      children: [
        // Mensagem de conclusão
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.verdeSucesso.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.verdeSucesso.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.verdeSucesso,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diagnóstico Concluído!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cinzaEscuro,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Seu perfil financeiro foi calculado',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.cinzaTexto,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Botões de ação
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onVoltar,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Compartilhar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: etapaAtual.cor,
                  side: BorderSide(color: etapaAtual.cor, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: onContinuar,
                icon: const Icon(Icons.home, size: 18),
                label: const Text('Ir para Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: etapaAtual.cor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Navegação para tela de processamento
  Widget _buildProcessamentoNavigation() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Indicador de progresso
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(etapaAtual.cor),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Processando seu diagnóstico...',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.cinzaTexto,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            'Estamos analisando seus dados para criar\nseu perfil financeiro personalizado',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.cinzaTexto,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Ícone do botão continuar baseado na etapa
  Widget _getBotaoContinuarIcon() {
    switch (etapaAtual.tipo) {
      case TipoDiagnosticoEtapa.intro:
        return const Icon(Icons.play_arrow, size: 18);
      case TipoDiagnosticoEtapa.cadastro:
        // Se pode continuar (etapa validada), mostrar seta
        // Senão, mostrar ícone de adicionar
        return podeContinuar
            ? const Icon(Icons.arrow_forward, size: 18)
            : const Icon(Icons.add, size: 18);
      case TipoDiagnosticoEtapa.questionario:
        return const Icon(Icons.check, size: 18);
      case TipoDiagnosticoEtapa.processamento:
        return const Icon(Icons.analytics, size: 18);
      case TipoDiagnosticoEtapa.resultado:
        return const Icon(Icons.home, size: 18);
      default:
        return const Icon(Icons.arrow_forward, size: 18);
    }
  }

  /// Texto do botão continuar baseado na etapa
  String _getBotaoContinuarTexto() {
    switch (etapaAtual.tipo) {
      case TipoDiagnosticoEtapa.intro:
        return 'Começar Diagnóstico';
      case TipoDiagnosticoEtapa.cadastro:
        // Se pode continuar (etapa validada), mostrar "Próximo"
        // Senão, mostrar texto de cadastro
        return podeContinuar ? 'Próximo' : 'Cadastrar ${_getTipoCadastro()}';
      case TipoDiagnosticoEtapa.questionario:
        return 'Responder Questionário';
      case TipoDiagnosticoEtapa.processamento:
        return 'Processar Diagnóstico';
      case TipoDiagnosticoEtapa.resultado:
        return 'Ir para Dashboard';
      default:
        return 'Continuar';
    }
  }

  /// Tipo de cadastro baseado na etapa
  String _getTipoCadastro() {
    switch (etapaAtual.id) {
      case 'categorias': return 'Categorias';
      case 'contas': return 'Contas';
      case 'cartoes': return 'Cartões';
      case 'receitas': return 'Receitas';
      case 'despesas-fixas': return 'Despesas Fixas';
      case 'despesas-variaveis': return 'Despesas Variáveis';
      default: return 'Dados';
    }
  }
}

/// Navegação simplificada para casos especiais
class DiagnosticoNavigationSimples extends StatelessWidget {
  final String textoBotaoPrincipal;
  final VoidCallback? onBotaoPrincipal;
  final String? textoBotaoSecundario;
  final VoidCallback? onBotaoSecundario;
  final Color? cor;
  final bool isLoading;

  const DiagnosticoNavigationSimples({
    super.key,
    required this.textoBotaoPrincipal,
    this.onBotaoPrincipal,
    this.textoBotaoSecundario,
    this.onBotaoSecundario,
    this.cor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final corFinal = cor ?? AppColors.azulHeader;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Botão secundário (se houver)
              if (textoBotaoSecundario != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBotaoSecundario,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: corFinal,
                      side: BorderSide(color: corFinal, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(textoBotaoSecundario!),
                  ),
                ),
                const SizedBox(width: 16),
              ],

              // Botão principal
              Expanded(
                flex: textoBotaoSecundario != null ? 2 : 1,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onBotaoPrincipal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLoading ? AppColors.cinzaClaro : corFinal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(textoBotaoPrincipal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}