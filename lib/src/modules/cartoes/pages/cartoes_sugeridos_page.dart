import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../../shared/components/ui/app_button.dart';
import '../data/cartoes_sugeridos.dart';
import '../models/cartao_model.dart';
import '../services/cartao_service.dart';
import '../widgets/cartao_card.dart';

/// Página de cartões sugeridos para importação
/// Permite selecionar múltiplos cartões pré-configurados
class CartoesSugeridosPage extends StatefulWidget {
  const CartoesSugeridosPage({super.key});

  @override
  State<CartoesSugeridosPage> createState() => _CartoesSugeridosPageState();
}

class _CartoesSugeridosPageState extends State<CartoesSugeridosPage> {
  final _cartaoService = CartaoService.instance;
  final Set<String> _cartoesSelecionados = {};
  String _filtroAtual = 'todos';
  String _bandeiraFiltro = 'todas';
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(), // Header compacto
          _buildFiltros(),
          Expanded(child: _buildListaCartoes()),
          _buildActions(),
        ],
      ),
    );
  }

  /// AppBar customizada
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Cartões Sugeridos',
        style: TextStyle(
          color: AppColors.branco,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      backgroundColor: AppColors.roxoHeader,
      foregroundColor: AppColors.branco,
      elevation: 0,
      actions: [
        if (_cartoesSelecionados.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brancoTransparente20,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_cartoesSelecionados.length} selecionados',
              style: const TextStyle(
                color: AppColors.branco,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  /// Header simples e compacto
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.roxoHeader,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: const Text(
        'Selecione os cartões que você possui para importá-los automaticamente',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.branco,
          height: 1.3,
        ),
      ),
    );
  }

  /// Filtros de categoria e bandeira
  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filtro por categoria
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFiltroChip('todos', 'Todos', _obterContadorTodos()),
                _buildFiltroChip('populares', 'Populares', CartoesSugeridos.populares.length),
                _buildFiltroChip('iniciantes', 'Iniciantes', CartoesSugeridos.iniciantes.length),
                _buildFiltroChip('premium', 'Premium', CartoesSugeridos.premium.length),
                _buildFiltroChip('co-branded', 'Co-branded', _obterContadorCoBranded()),
                _buildFiltroChip('viagens', 'Viagens', _obterContadorViagens()),
                _buildFiltroChip('internacionais', 'Internacionais', _obterContadorInternacionais()),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filtro por bandeira
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBandeiraChip('todas', 'Todas'),
                _buildBandeiraChip('VISA', 'Visa'),
                _buildBandeiraChip('MASTERCARD', 'Mastercard'),
                _buildBandeiraChip('ELO', 'Elo'),
                _buildBandeiraChip('AMEX', 'Amex'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Chip de filtro
  Widget _buildFiltroChip(String filtro, String label, int count) {
    final isSelected = _filtroAtual == filtro;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filtroAtual = filtro;
          });
        },
        selectedColor: AppColors.roxoTransparente20,
        checkmarkColor: AppColors.roxoHeader,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.roxoHeader : AppColors.cinzaTexto,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  /// Chip de bandeira
  Widget _buildBandeiraChip(String bandeira, String label) {
    final isSelected = _bandeiraFiltro == bandeira;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _bandeiraFiltro = bandeira;
          });
        },
        selectedColor: AppColors.roxoTransparente20,
        checkmarkColor: AppColors.roxoHeader,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.roxoHeader : AppColors.cinzaTexto,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  /// Lista de cartões
  Widget _buildListaCartoes() {
    final cartoesFiltrados = _obterCartoesFiltrados();
    
    if (cartoesFiltrados.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.cinzaTexto,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum cartão encontrado',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.cinzaTexto,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tente ajustar os filtros',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.cinzaTexto,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: cartoesFiltrados.length,
      itemBuilder: (context, index) {
        final cartaoData = cartoesFiltrados[index];
        final cartao = CartaoModel.fromJson({
          'id': '',
          'usuario_id': '',
          'nome': cartaoData['nome'],
          'limite': cartaoData['limite'],
          'dia_fechamento': cartaoData['dia_fechamento'],
          'dia_vencimento': cartaoData['dia_vencimento'],
          'bandeira': cartaoData['bandeira'],
          'banco': null,
          'conta_debito_id': null,
          'cor': cartaoData['cor'],
          'observacoes': null,
          'ativo': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending',
        });
        
        final cartaoKey = '${cartaoData['nome']}_${cartaoData['bandeira']}';
        final isSelected = _cartoesSelecionados.contains(cartaoKey);

        return CartaoCard(
          cartao: cartao,
          showUtilizacao: false,
          onTap: () => _toggleSelecao(cartaoKey),
          trailing: Checkbox(
            value: isSelected,
            onChanged: (value) => _toggleSelecao(cartaoKey),
            activeColor: AppColors.roxoHeader,
          ),
        );
      },
    );
  }

  /// Ações inferiores
Widget _buildActions() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      color: AppColors.branco,
      border: Border(top: BorderSide(color: AppColors.cinzaClaro)),
    ),
    child: Column(
      children: [
        // Informações dos cartões selecionados
        if (_cartoesSelecionados.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.roxoTransparente10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.roxoHeader,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_cartoesSelecionados.length} cartões selecionados para importação',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.roxoHeader,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Botões de ação
        Row(
          children: [
            // Botão Limpar (só aparece se há seleções)
            if (_cartoesSelecionados.isNotEmpty) ...[
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _limparSelecao,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: AppColors.roxoHeader),
                  ),
                  child: const Text(
                    'Limpar',
                    style: TextStyle(color: AppColors.roxoHeader),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            
            // Botão principal (Importar ou Pular)
            Expanded(
              flex: _cartoesSelecionados.isNotEmpty ? 2 : 1,
              child: AppButton(
                text: _cartoesSelecionados.isEmpty 
                    ? 'Pular esta etapa' 
                    : _isLoading 
                        ? 'Importando...' 
                        : 'Importar Selecionados',
                onPressed: _isLoading 
                    ? null 
                    : _cartoesSelecionados.isEmpty 
                        ? _pularEtapa 
                        : _importarSelecionados,
                variant: _cartoesSelecionados.isEmpty 
                    ? AppButtonVariant.secondary 
                    : AppButtonVariant.primary,
                customColor: AppColors.roxoHeader,
                isLoading: _isLoading,
                fullWidth: true,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  /// Obter cartões filtrados
  List<Map<String, dynamic>> _obterCartoesFiltrados() {
    List<Map<String, dynamic>> cartoes;

    // Filtrar por categoria
    switch (_filtroAtual) {
      case 'populares':
        cartoes = CartoesSugeridos.porCategoria('populares');
        break;
      case 'iniciantes':
        cartoes = CartoesSugeridos.porCategoria('iniciantes');
        break;
      case 'premium':
        cartoes = CartoesSugeridos.porCategoria('premium');
        break;
      case 'co-branded':
        cartoes = CartoesSugeridos.porCategoria('co-branded');
        break;
      case 'viagens':
        cartoes = CartoesSugeridos.porCategoria('viagens');
        break;
      case 'internacionais':
        cartoes = CartoesSugeridos.porCategoria('internacionais');
        break;
      default:
        cartoes = CartoesSugeridos.todos;
    }

    // Filtrar por bandeira
    if (_bandeiraFiltro != 'todas') {
      cartoes = cartoes.where((c) => c['bandeira'] == _bandeiraFiltro).toList();
    }

    return cartoes;
  }

  /// Contadores para filtros
  int _obterContadorTodos() => CartoesSugeridos.todos.length;
  int _obterContadorCoBranded() => CartoesSugeridos.porCategoria('co-branded').length;
  int _obterContadorViagens() => CartoesSugeridos.porCategoria('viagens').length;
  int _obterContadorInternacionais() => CartoesSugeridos.porCategoria('internacionais').length;

  /// Toggle seleção de cartão
  void _toggleSelecao(String cartaoKey) {
    setState(() {
      if (_cartoesSelecionados.contains(cartaoKey)) {
        _cartoesSelecionados.remove(cartaoKey);
      } else {
        _cartoesSelecionados.add(cartaoKey);
      }
    });
  }

  /// Limpar seleção
  void _limparSelecao() {
    setState(() {
      _cartoesSelecionados.clear();
    });
  }

  /// Importar cartões selecionados
  Future<void> _importarSelecionados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cartoesParaImportar = CartoesSugeridos.todos
          .where((cartao) {
            final key = '${cartao['nome']}_${cartao['bandeira']}';
            return _cartoesSelecionados.contains(key);
          })
          .toList();

      final sucesso = await _cartaoService.importarCartoesSugeridos(cartoesParaImportar);
      
      if (mounted) {
        if (sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${cartoesParaImportar.length} cartões importados com sucesso!'),
              backgroundColor: AppColors.verdeSucesso,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao importar cartões'),
              backgroundColor: AppColors.vermelhoErro,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar cartões: $e'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Pular esta etapa
  void _pularEtapa() {
    Navigator.of(context).pop(false);
  }
}