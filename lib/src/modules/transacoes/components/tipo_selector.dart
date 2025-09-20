// 🏷️ Tipo Selector - iPoupei Mobile
// 
// Seletor de tipos elegante adaptado do projeto device
// Compatível com a arquitetura mobile existente
// 
// Features:
// - Segmented control com múltiplas opções
// - Visual moderno com sombras e estados animados
// - Ícones + textos + descrições
// - Configurável com lista dinâmica de tipos
// - Otimizado para touch mobile

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme/app_colors.dart';

/// Seletor elegante de tipos com visual segmented control
/// Substitui RadioButton e outras seleções simples
class TipoSelector extends StatelessWidget {
  final String tipoSelecionado;
  final ValueChanged<String> onChanged;
  final List<TipoSelectorOption> tipos;
  final EdgeInsetsGeometry? padding;
  final bool hapticFeedback;
  final double? height;

  const TipoSelector({
    super.key,
    required this.tipoSelecionado,
    required this.onChanged,
    required this.tipos,
    this.padding,
    this.hapticFeedback = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cinzaClaro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: tipos.length <= 3
          ? _buildHorizontalLayout()
          : _buildGridLayout(),
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      children: tipos.map((tipo) {
        final isSelected = tipoSelecionado == tipo.id;
        return Expanded(
          child: _buildTipoOption(tipo, isSelected),
        );
      }).toList(),
    );
  }

  Widget _buildGridLayout() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: tipos.length,
      itemBuilder: (context, index) {
        final tipo = tipos[index];
        final isSelected = tipoSelecionado == tipo.id;
        return _buildTipoOption(tipo, isSelected);
      },
    );
  }

  Widget _buildTipoOption(TipoSelectorOption tipo, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (hapticFeedback) {
          HapticFeedback.selectionClick();
        }
        onChanged(tipo.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.branco : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                tipo.icone,
                color: isSelected 
                    ? (tipo.cor ?? Colors.blue)
                    : Colors.grey.shade600,
                size: 20,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Nome
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? AppColors.cinzaEscuro
                    : AppColors.cinzaTexto,
              ),
              child: Text(
                tipo.nome,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Descrição (se houver)
            if (tipo.descricao != null) ...[
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 8,
                  color: isSelected 
                      ? AppColors.cinzaTexto
                      : AppColors.cinzaMedio,
                ),
                child: Text(
                  tipo.descricao!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opção do TipoSelector
class TipoSelectorOption {
  final String id;
  final String nome;
  final String? descricao;
  final IconData icone;
  final Color? cor;

  const TipoSelectorOption({
    required this.id,
    required this.nome,
    required this.icone,
    this.descricao,
    this.cor,
  });
}

/// Extensões para tipos comuns de transação
extension TipoSelectorExtensions on TipoSelector {
  // Seletor de tipos de transação (receita/despesa)
  static TipoSelector transacao({
    Key? key,
    required String tipoSelecionado,
    required ValueChanged<String> onChanged,
    bool hapticFeedback = true,
  }) {
    return TipoSelector(
      key: key,
      tipoSelecionado: tipoSelecionado,
      onChanged: onChanged,
      hapticFeedback: hapticFeedback,
      height: 80,
      tipos: const [
        TipoSelectorOption(
          id: 'receita',
          nome: 'Receita',
          descricao: 'Dinheiro entrando',
          icone: Icons.add_circle,
          cor: Colors.green,
        ),
        TipoSelectorOption(
          id: 'despesa',
          nome: 'Despesa',
          descricao: 'Dinheiro saindo',
          icone: Icons.remove_circle,
          cor: Colors.red,
        ),
      ],
    );
  }

  // Seletor de frequência de transação
  static TipoSelector tipoTransacao({
    Key? key,
    required String tipoSelecionado,
    required ValueChanged<String> onChanged,
    required String tipoReceita, // 'receita' ou 'despesa'
    bool hapticFeedback = true,
  }) {
    final isReceita = tipoReceita == 'receita';
    final corContextual = isReceita ? AppColors.tealPrimary : AppColors.vermelhoHeader;
    
    return TipoSelector(
      key: key,
      tipoSelecionado: tipoSelecionado,
      onChanged: onChanged,
      hapticFeedback: hapticFeedback,
      height: 85,
      tipos: [
        TipoSelectorOption(
          id: 'extra',
          nome: 'Extra',
          descricao: 'Valor único',
          icone: isReceita ? Icons.star : Icons.shopping_bag_outlined,
          cor: isReceita ? Colors.orange : corContextual,
        ),
        TipoSelectorOption(
          id: 'previsivel',
          nome: 'Recorrente',
          descricao: 'Repete todo mês',
          icone: Icons.repeat,
          cor: corContextual,
        ),
        TipoSelectorOption(
          id: 'parcelada',
          nome: 'Parcelada',
          descricao: 'Dividida em parcelas',
          icone: Icons.calendar_month,
          cor: Colors.purple,
        ),
      ],
    );
  }

  // Seletor de frequência
  static TipoSelector frequencia({
    Key? key,
    required String tipoSelecionado,
    required ValueChanged<String> onChanged,
    bool hapticFeedback = true,
  }) {
    return TipoSelector(
      key: key,
      tipoSelecionado: tipoSelecionado,
      onChanged: onChanged,
      hapticFeedback: hapticFeedback,
      tipos: const [
        TipoSelectorOption(
          id: 'semanal',
          nome: 'Semanal',
          icone: Icons.date_range,
          cor: Colors.purple,
        ),
        TipoSelectorOption(
          id: 'quinzenal',
          nome: 'Quinzenal',
          icone: Icons.calendar_view_week,
          cor: Colors.indigo,
        ),
        TipoSelectorOption(
          id: 'mensal',
          nome: 'Mensal',
          icone: Icons.calendar_today,
          cor: Colors.blue,
        ),
        TipoSelectorOption(
          id: 'anual',
          nome: 'Anual',
          icone: Icons.event,
          cor: Colors.teal,
        ),
      ],
    );
  }
}