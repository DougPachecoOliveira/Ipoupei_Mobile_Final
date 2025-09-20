// 🧾 Step03 Gastos Mensais - iPoupei Mobile
//
// Baseado no Step03_GastosMensais.jsx do offline
// Distribuição de gastos por categoria com percentuais
//
// Layout: 6 categorias com inputs de valor + feedback

import 'package:flutter/material.dart';
import '../widgets/etapa_layout_widget.dart';
import '../models/diagnostico_etapa.dart';

class Step03GastosPage extends StatefulWidget {
  final Map<String, double> gastosIniciais;
  final double? rendaMensal;
  final Function(Map<String, double> gastos) onChanged;
  final VoidCallback onContinuar;

  const Step03GastosPage({
    super.key,
    required this.gastosIniciais,
    this.rendaMensal,
    required this.onChanged,
    required this.onContinuar,
  });

  @override
  State<Step03GastosPage> createState() => _Step03GastosPageState();
}

class _Step03GastosPageState extends State<Step03GastosPage> {
  late Map<String, double> _gastos;

  // Categorias com dados do offline
  final List<Map<String, dynamic>> _categorias = [
    {
      'key': 'moradia',
      'icon': '🏠',
      'title': 'Moradia',
      'subtitle': 'Aluguel, condomínio, IPTU, luz, água',
      'sugestao': 30,
      'color': const Color(0xFF10b981),
    },
    {
      'key': 'transporte',
      'icon': '🚗',
      'title': 'Transporte',
      'subtitle': 'Combustível, transporte público, manutenção',
      'sugestao': 15,
      'color': const Color(0xFF3b82f6),
    },
    {
      'key': 'alimentacao',
      'icon': '🍔',
      'title': 'Alimentação',
      'subtitle': 'Mercado, restaurantes, delivery',
      'sugestao': 15,
      'color': const Color(0xFFf59e0b),
    },
    {
      'key': 'cartao',
      'icon': '💳',
      'title': 'Cartão de Crédito',
      'subtitle': 'Fatura total do cartão',
      'sugestao': 20,
      'color': const Color(0xFFef4444),
    },
    {
      'key': 'lazer',
      'icon': '🎭',
      'title': 'Lazer',
      'subtitle': 'Cinema, shows, viagens, hobbies',
      'sugestao': 10,
      'color': const Color(0xFF8b5cf6),
    },
    {
      'key': 'outros',
      'icon': '⚫',
      'title': 'Outros',
      'subtitle': 'Roupas, farmácia, cuidados pessoais',
      'sugestao': 10,
      'color': const Color(0xFF6b7280),
    },
  ];

  @override
  void initState() {
    super.initState();
    _gastos = Map<String, double>.from(widget.gastosIniciais);
  }

  double get _totalGastos => _gastos.values.fold(0.0, (sum, valor) => sum + valor);

  double get _totalPercentual {
    if (widget.rendaMensal == null || widget.rendaMensal! <= 0) return 0;
    return (_totalGastos / widget.rendaMensal!) * 100;
  }

  bool get _podeAvancar => _gastos.values.any((valor) => valor > 0);

  void _updateGasto(String categoria, double valor) {
    setState(() {
      _gastos[categoria] = valor;
    });
    widget.onChanged(_gastos);
  }

  @override
  Widget build(BuildContext context) {
    return EtapaLayoutWidget(
      etapa: DiagnosticoEtapas.todas[2],
      progresso: DiagnosticoEtapas.calcularProgressoPorIndice(2),
      etapaAtual: 2,
      totalEtapas: DiagnosticoEtapas.todas.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instrução
          const Text(
            'Como você distribui seus gastos mensais?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          if (widget.rendaMensal != null)
            Text(
              'Renda mensal: R\$ ${widget.rendaMensal!.toStringAsFixed(2).replaceAll('.', ',')}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 24),

          // Resumo total
          if (_totalGastos > 0) _buildResumoTotal(),

          const SizedBox(height: 16),

          // Lista de categorias
          Expanded(
            child: ListView.builder(
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final categoria = _categorias[index];
                return _buildCategoriaCard(categoria);
              },
            ),
          ),

          const SizedBox(height: 16),

          // Botão continuar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _podeAvancar ? widget.onContinuar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf59e0b),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoTotal() {
    final isExcesso = widget.rendaMensal != null && _totalGastos > widget.rendaMensal!;
    final color = isExcesso ? const Color(0xFFef4444) : const Color(0xFF10b981);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total dos gastos:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
              Text(
                'R\$ ${_totalGastos.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          if (widget.rendaMensal != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Percentual da renda:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6b7280),
                  ),
                ),
                Text(
                  '${_totalPercentual.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriaCard(Map<String, dynamic> categoria) {
    final key = categoria['key'] as String;
    final valor = _gastos[key] ?? 0;
    final percentual = widget.rendaMensal != null && widget.rendaMensal! > 0
        ? (valor / widget.rendaMensal!) * 100
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe5e7eb)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da categoria
          Row(
            children: [
              Text(
                categoria['icon'],
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoria['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                    Text(
                      categoria['subtitle'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (categoria['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${categoria['sugestao']}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: categoria['color'],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Input de valor
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: valor > 0 ? valor.toStringAsFixed(2).replaceAll('.', ',') : '',
                  onChanged: (text) {
                    final cleanText = text.replaceAll(',', '.');
                    final parsedValue = double.tryParse(cleanText) ?? 0;
                    _updateGasto(key, parsedValue);
                  },
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixText: 'R\$ ',
                    hintText: '0,00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: categoria['color'], width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              if (percentual > 0) ...[
                const SizedBox(width: 12),
                Text(
                  '${percentual.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: categoria['color'],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}