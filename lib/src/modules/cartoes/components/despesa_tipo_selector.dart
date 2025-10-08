// 🏷️ Despesa Tipo Selector - iPoupei Mobile
// 
// Seletor específico para tipos de despesa (Simples, Parcelada, Recorrente)
// Baseado no TipoSelector mas com interface simplificada para este caso
// 
import 'package:flutter/material.dart';

class DespesaTipoSelector extends StatelessWidget {
  final List<String> tipos;
  final int tipoSelecionado;
  final ValueChanged<int> onTipoChanged;
  final List<Color> colors;

  const DespesaTipoSelector({
    super.key,
    required this.tipos,
    required this.tipoSelecionado,
    required this.onTipoChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: tipos.asMap().entries.map((entry) {
          final index = entry.key;
          final tipo = entry.value;
          final isSelected = tipoSelecionado == index;
          final color = colors[index % colors.length];
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onTipoChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(2),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ] : null,
                  border: isSelected ? Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ) : null,
                ),
                child: Text(
                  tipo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? color
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}