import 'package:flutter/material.dart';
import '../../categorias/models/categoria_model.dart';
import '../../contas/models/conta_model.dart';
import '../../cartoes/models/cartao_model.dart';
import '../../categorias/services/categoria_service.dart';
import '../../contas/services/conta_service.dart';
import '../../cartoes/services/cartao_service.dart';
import '../pages/transacoes_page.dart';

class FiltrosTransacoesModal extends StatefulWidget {
  final TransacoesPageMode modo;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onFiltrosAplicados;
  final Map<String, dynamic> filtrosAtuais;

  const FiltrosTransacoesModal({
    super.key,
    required this.modo,
    required this.onClose,
    required this.onFiltrosAplicados,
    required this.filtrosAtuais,
  });

  @override
  State<FiltrosTransacoesModal> createState() => _FiltrosTransacoesModalState();
}

class _FiltrosTransacoesModalState extends State<FiltrosTransacoesModal> {
  late Map<String, dynamic> _filtrosTemp;
  List<CategoriaModel> _categorias = [];
  List<ContaModel> _contas = [];
  List<CartaoModel> _cartoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _filtrosTemp = Map<String, dynamic>.from(widget.filtrosAtuais);
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final futures = await Future.wait([
        CategoriaService.instance.fetchCategorias(),
        ContaService.instance.fetchContas(),
        CartaoService.instance.listarCartoesAtivos(),
      ]);
      
      if (mounted) {
        setState(() {
          _categorias = futures[0] as List<CategoriaModel>;
          _contas = futures[1] as List<ContaModel>;
          _cartoes = futures[2] as List<CartaoModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar dados para filtros: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _aplicarFiltros() {
    widget.onFiltrosAplicados(_filtrosTemp);
    widget.onClose();
  }

  void _limparFiltros() {
    setState(() {
      _filtrosTemp = {
        'categorias': <String>[],
        'contas': <String>[],
        'cartoes': <String>[],
        'status': <String>[],
        'valorMinimo': 0.0,
        'valorMaximo': 999999.0,
        'dataInicio': null,
        'dataFim': null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 
                        MediaQuery.of(context).padding.bottom,
              ),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildFiltrosPorModo(),
                    ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.modo.corHeader,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.tune,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (_temFiltrosAtivos())
                  Text(
                    '${_contarFiltrosAtivos()} filtros ativos',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _limparFiltros,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text(
              'Limpar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFiltrosPorModo() {
    final widgets = <Widget>[];
    
    // Status (todos os modos)
    widgets.addAll([
      _buildTituloSecao('Status da Transação'),
      const SizedBox(height: 8),
      _buildFiltrosStatus(),
      const SizedBox(height: 20),
    ]);
    
    // Categorias (receitas, despesas e todas)
    if (widget.modo == TransacoesPageMode.receitas || 
        widget.modo == TransacoesPageMode.despesas ||
        widget.modo == TransacoesPageMode.todas) {
      widgets.addAll([
        _buildTituloSecao('Categorias'),
        const SizedBox(height: 8),
        _buildFiltroCategorias(),
        const SizedBox(height: 20),
      ]);
    }
    
    // Contas (todos os modos exceto cartões)
    if (widget.modo != TransacoesPageMode.cartoes) {
      widgets.addAll([
        _buildTituloSecao('Contas'),
        const SizedBox(height: 8),
        _buildFiltroContas(),
        const SizedBox(height: 20),
      ]);
    }
    
    // Cartões (modo cartões e todas)
    if (widget.modo == TransacoesPageMode.cartoes || 
        widget.modo == TransacoesPageMode.todas) {
      widgets.addAll([
        _buildTituloSecao('Cartões'),
        const SizedBox(height: 8),
        _buildFiltroCartoes(),
        const SizedBox(height: 20),
      ]);
    }
    
    // Faixa de valores
    widgets.addAll([
      _buildTituloSecao('Faixa de Valores'),
      const SizedBox(height: 12),
      _buildFiltroValores(),
      const SizedBox(height: 20),
    ]);
    
    // Período personalizado
    widgets.addAll([
      _buildTituloSecao('Período Personalizado'),
      const SizedBox(height: 12),
      _buildFiltroPeriodo(),
    ]);
    
    return widgets;
  }

  Widget _buildTituloSecao(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildFiltrosStatus() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildChipFiltro(
          label: 'Efetivadas',
          icon: Icons.check_circle,
          selected: _filtrosTemp['status']?.contains('efetivado') ?? false,
          color: const Color(0xFF10B981),
          onTap: () {
            setState(() {
              _filtrosTemp['status'] ??= <String>[];
              if (_filtrosTemp['status'].contains('efetivado')) {
                _filtrosTemp['status'].remove('efetivado');
              } else {
                _filtrosTemp['status'].add('efetivado');
              }
            });
          },
        ),
        _buildChipFiltro(
          label: 'Pendentes',
          icon: Icons.schedule,
          selected: _filtrosTemp['status']?.contains('pendente') ?? false,
          color: const Color(0xFFF59E0B),
          onTap: () {
            setState(() {
              _filtrosTemp['status'] ??= <String>[];
              if (_filtrosTemp['status'].contains('pendente')) {
                _filtrosTemp['status'].remove('pendente');
              } else {
                _filtrosTemp['status'].add('pendente');
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildFiltroCategorias() {
    final categoriasFiltradas = _categorias.where((cat) {
      if (widget.modo == TransacoesPageMode.receitas) {
        return cat.tipo == 'receita';
      } else if (widget.modo == TransacoesPageMode.despesas) {
        return cat.tipo == 'despesa';
      }
      return true;
    }).toList();
    
    if (categoriasFiltradas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Nenhuma categoria encontrada',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categoriasFiltradas.map<Widget>((categoria) {
        final cor = categoria.cor.isNotEmpty
            ? _parseColor(categoria.cor)
            : const Color(0xFF6B7280);
        
        return _buildChipFiltro(
          label: categoria.nome,
          selected: _filtrosTemp['categorias']?.contains(categoria.id) ?? false,
          color: cor,
          onTap: () {
            setState(() {
              _filtrosTemp['categorias'] ??= <String>[];
              if (_filtrosTemp['categorias'].contains(categoria.id)) {
                _filtrosTemp['categorias'].remove(categoria.id);
              } else {
                _filtrosTemp['categorias'].add(categoria.id);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildFiltroContas() {
    if (_contas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Nenhuma conta encontrada',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _contas.map<Widget>((conta) {
        final corConta = conta.cor != null && conta.cor!.isNotEmpty
            ? _parseColor(conta.cor!)
            : const Color(0xFF0891B2);
        
        return _buildChipFiltro(
          label: conta.nome,
          icon: Icons.account_balance,
          selected: _filtrosTemp['contas']?.contains(conta.id) ?? false,
          color: corConta,
          onTap: () {
            setState(() {
              _filtrosTemp['contas'] ??= <String>[];
              if (_filtrosTemp['contas'].contains(conta.id)) {
                _filtrosTemp['contas'].remove(conta.id);
              } else {
                _filtrosTemp['contas'].add(conta.id);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildFiltroCartoes() {
    if (_cartoes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Nenhum cartão encontrado',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _cartoes.map<Widget>((cartao) {
        final cor = cartao.cor != null && cartao.cor!.isNotEmpty
            ? _parseColor(cartao.cor!)
            : const Color(0xFF7C3AED);
        
        return _buildChipFiltro(
          label: cartao.nome,
          icon: Icons.credit_card,
          selected: _filtrosTemp['cartoes']?.contains(cartao.id) ?? false,
          color: cor,
          onTap: () {
            setState(() {
              _filtrosTemp['cartoes'] ??= <String>[];
              if (_filtrosTemp['cartoes'].contains(cartao.id)) {
                _filtrosTemp['cartoes'].remove(cartao.id);
              } else {
                _filtrosTemp['cartoes'].add(cartao.id);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildFiltroValores() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Valor mínimo',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: (_filtrosTemp['valorMinimo'] ?? 0.0) > 0
                    ? 'R\$ ${(_filtrosTemp['valorMinimo'] ?? 0.0).toStringAsFixed(2).replaceAll('.', ',')}'
                    : '',
                decoration: const InputDecoration(
                  hintText: 'R\$ 0,00',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final numStr = value.replaceAll('R\$ ', '').replaceAll(',', '.');
                  final num = double.tryParse(numStr) ?? 0.0;
                  setState(() {
                    _filtrosTemp['valorMinimo'] = num;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Valor máximo',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: (_filtrosTemp['valorMaximo'] ?? 999999.0) < 999999
                    ? 'R\$ ${(_filtrosTemp['valorMaximo'] ?? 999999.0).toStringAsFixed(2).replaceAll('.', ',')}'
                    : '',
                decoration: const InputDecoration(
                  hintText: 'R\$ 999.999,99',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final numStr = value.replaceAll('R\$ ', '').replaceAll(',', '.');
                  final num = double.tryParse(numStr) ?? 999999.0;
                  setState(() {
                    _filtrosTemp['valorMaximo'] = num;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltroPeriodo() {
    return Column(
      children: [
        const Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Deixe em branco para usar o período selecionado',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data inicial',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selecionarData(true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _filtrosTemp['dataInicio'] != null
                                ? _formatarData(_filtrosTemp['dataInicio'])
                                : 'Selecionar',
                            style: TextStyle(
                              fontSize: 14,
                              color: _filtrosTemp['dataInicio'] != null
                                  ? const Color(0xFF374151)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data final',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selecionarData(false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _filtrosTemp['dataFim'] != null
                                ? _formatarData(_filtrosTemp['dataFim'])
                                : 'Selecionar',
                            style: TextStyle(
                              fontSize: 14,
                              color: _filtrosTemp['dataFim'] != null
                                  ? const Color(0xFF374151)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChipFiltro({
    required String label,
    IconData? icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected 
                ? color.withOpacity(0.15)
                : const Color(0xFFF3F4F6).withOpacity(0.5),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 2,
            ),
            boxShadow: selected ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: selected ? color : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: selected ? color : const Color(0xFF6B7280),
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_temFiltrosAtivos())
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: widget.modo.corHeader.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.modo.corHeader.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: widget.modo.corHeader,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtros personalizados aplicados',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.modo.corHeader,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClose,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _aplicarFiltros,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.modo.corHeader,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Aplicar Filtros',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selecionarData(bool isInicio) async {
    final data = await showDatePicker(
      context: context,
      initialDate: isInicio 
          ? _filtrosTemp['dataInicio'] ?? DateTime.now()
          : _filtrosTemp['dataFim'] ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.modo.corHeader,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF374151),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (data != null) {
      setState(() {
        if (isInicio) {
          _filtrosTemp['dataInicio'] = data;
          if (_filtrosTemp['dataFim'] != null && 
              data.isAfter(_filtrosTemp['dataFim'])) {
            _filtrosTemp['dataFim'] = data;
          }
        } else {
          _filtrosTemp['dataFim'] = data;
          if (_filtrosTemp['dataInicio'] != null && 
              data.isBefore(_filtrosTemp['dataInicio'])) {
            _filtrosTemp['dataInicio'] = data;
          }
        }
      });
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  bool _temFiltrosAtivos() {
    return (_filtrosTemp['categorias']?.isNotEmpty ?? false) ||
           (_filtrosTemp['contas']?.isNotEmpty ?? false) ||
           (_filtrosTemp['cartoes']?.isNotEmpty ?? false) ||
           (_filtrosTemp['status']?.isNotEmpty ?? false) ||
           (_filtrosTemp['valorMinimo'] ?? 0.0) > 0 ||
           (_filtrosTemp['valorMaximo'] ?? 999999.0) < 999999 ||
           _filtrosTemp['dataInicio'] != null ||
           _filtrosTemp['dataFim'] != null;
  }

  int _contarFiltrosAtivos() {
    int count = 0;
    if (_filtrosTemp['categorias']?.isNotEmpty ?? false) count++;
    if (_filtrosTemp['contas']?.isNotEmpty ?? false) count++;
    if (_filtrosTemp['cartoes']?.isNotEmpty ?? false) count++;
    if (_filtrosTemp['status']?.isNotEmpty ?? false) count++;
    if ((_filtrosTemp['valorMinimo'] ?? 0.0) > 0) count++;
    if ((_filtrosTemp['valorMaximo'] ?? 999999.0) < 999999) count++;
    if (_filtrosTemp['dataInicio'] != null) count++;
    if (_filtrosTemp['dataFim'] != null) count++;
    return count;
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
      } else if (colorStr.startsWith('0x')) {
        return Color(int.parse(colorStr));
      } else {
        return Color(int.parse('0xFF$colorStr'));
      }
    } catch (e) {
      return const Color(0xFF6B7280);
    }
  }
}