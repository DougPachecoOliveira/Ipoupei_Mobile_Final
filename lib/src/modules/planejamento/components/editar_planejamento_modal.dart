// 📊 Editar Planejamento Modal - iPoupei Mobile
//
// Modal para editar valores de planejamento
// Baseado na estrutura dos modais de categorias
//
// Funcionalidades: Edição inline + Validação + Sugestões

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/planejamento_model.dart';
import '../services/planejamento_service.dart';
import '../../../shared/utils/format_currency.dart';
import '../../shared/theme/app_colors.dart';

class EditarPlanejamentoModal extends StatefulWidget {
  final PlanejamentoModel planejamento;
  final Function(PlanejamentoModel)? onSaved;

  const EditarPlanejamentoModal({
    super.key,
    required this.planejamento,
    this.onSaved,
  });

  @override
  State<EditarPlanejamentoModal> createState() => _EditarPlanejamentoModalState();
}

class _EditarPlanejamentoModalState extends State<EditarPlanejamentoModal> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final PlanejamentoService _service = PlanejamentoService.instance;

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _valorController.text = widget.planejamento.valorPlanejado.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  // ===========================
  // SALVAR PLANEJAMENTO
  // ===========================

  Future<void> _salvarPlanejamento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
    });

    try {
      final novoValor = double.parse(_valorController.text.replaceAll(',', '.'));

      final planejamentoAtualizado = widget.planejamento.copyWith(
        valorPlanejado: novoValor,
      );

      await _service.salvarPlanejamento(planejamentoAtualizado);

      if (mounted) {
        widget.onSaved?.call(planejamentoAtualizado);
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meta atualizada com sucesso!'),
            backgroundColor: AppColors.verdeSucesso,
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: AppColors.vermelhoErro,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  // ===========================
  // SUGESTÕES BASEADAS NA MÉDIA
  // ===========================

  void _aplicarMediaHistorica() {
    if (widget.planejamento.mediaHistorica > 0) {
      _valorController.text = widget.planejamento.mediaHistorica.toStringAsFixed(2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há dados históricos suficientes'),
          backgroundColor: AppColors.laranjaAlerta,
        ),
      );
    }
  }

  void _aplicarValorAtual() {
    if (widget.planejamento.totalMes > 0) {
      _valorController.text = widget.planejamento.totalMes.toStringAsFixed(2);
    }
  }

  void _zerarMeta() {
    _valorController.text = '0.00';
  }

  // ===========================
  // UI
  // ===========================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildInfoAtual(),
            const SizedBox(height: 20),
            _buildFormulario(),
            const SizedBox(height: 16),
            _buildSugestoes(),
            const SizedBox(height: 24),
            _buildBotoes(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Ícone da categoria
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCorCategoria(),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              widget.planejamento.categoriaIcone ?? '📊',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Nome da categoria
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar Meta',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cinzaEscuro,
                ),
              ),
              Text(
                widget.planejamento.categoriaNome ?? 'Sem nome',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.cinzaMedio,
                ),
              ),
              if (widget.planejamento.subcategoriaNome != null)
                Text(
                  widget.planejamento.subcategoriaNome!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.cinzaMedio,
                  ),
                ),
            ],
          ),
        ),

        // Botão fechar
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: AppColors.cinzaMedio),
        ),
      ],
    );
  }

  Widget _buildInfoAtual() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cinzaClaro,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Situação Atual',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.cinzaMedio,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Realizado',
                    style: TextStyle(fontSize: 11, color: AppColors.cinzaMedio),
                  ),
                  Text(
                    formatCurrency(widget.planejamento.totalMes),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Meta Atual',
                    style: TextStyle(fontSize: 11, color: AppColors.cinzaMedio),
                  ),
                  Text(
                    formatCurrency(widget.planejamento.valorPlanejado),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Progresso',
                    style: TextStyle(fontSize: 11, color: AppColors.cinzaMedio),
                  ),
                  Text(
                    '${widget.planejamento.percentualCumprimento.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getCorProgresso(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _valorController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        decoration: InputDecoration(
          labelText: 'Nova Meta',
          prefixText: 'R\$ ',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.roxoHeader, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Digite um valor';
          }
          final numero = double.tryParse(value.replaceAll(',', '.'));
          if (numero == null) {
            return 'Digite um número válido';
          }
          if (numero < 0) {
            return 'O valor não pode ser negativo';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSugestoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sugestões Rápidas',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.cinzaMedio,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (widget.planejamento.mediaHistorica > 0)
              _buildChipSugestao(
                'Média 3m: ${formatCurrency(widget.planejamento.mediaHistorica)}',
                () => _aplicarMediaHistorica(),
                Icons.analytics,
              ),
            if (widget.planejamento.totalMes > 0)
              _buildChipSugestao(
                'Usar atual: ${formatCurrency(widget.planejamento.totalMes)}',
                () => _aplicarValorAtual(),
                Icons.trending_up,
              ),
            _buildChipSugestao(
              'Zerar meta',
              () => _zerarMeta(),
              Icons.clear,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChipSugestao(String label, VoidCallback onTap, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
      onPressed: onTap,
      backgroundColor: AppColors.cinzaClaro,
      side: BorderSide(color: AppColors.cinzaBorda),
    );
  }

  Widget _buildBotoes() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _salvando ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancelar'),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: ElevatedButton(
            onPressed: _salvando ? null : _salvarPlanejamento,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.roxoHeader,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _salvando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Salvar Meta',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  // ===========================
  // AUXILIARES
  // ===========================

  Color _getCorCategoria() {
    try {
      final cor = widget.planejamento.categoriaCor;
      if (cor != null && cor.isNotEmpty) {
        return Color(int.parse(cor.replaceAll('#', '0xFF')));
      }
    } catch (e) {
      // Cor padrão
    }
    return AppColors.cinzaEscuro;
  }

  Color _getCorProgresso() {
    final pct = widget.planejamento.percentualCumprimento;
    if (pct >= 100) return AppColors.vermelhoErro;
    if (pct >= 80) return AppColors.verdeSucesso;
    if (pct >= 50) return AppColors.laranjaAlerta;
    return AppColors.cinzaMedio;
  }
}