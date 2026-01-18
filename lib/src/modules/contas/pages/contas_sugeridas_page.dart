import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../shared/theme/app_colors.dart';
import '../data/contas_sugeridas.dart';
import '../services/conta_service.dart';

/// Página de contas sugeridas para importação
/// Permite importar contas pré-configuradas dos principais bancos
class ContasSugeridasPage extends StatefulWidget {
  const ContasSugeridasPage({super.key});

  @override
  State<ContasSugeridasPage> createState() => _ContasSugeridasPageState();
}

class _ContasSugeridasPageState extends State<ContasSugeridasPage> {
  final _contaService = ContaService.instance;
  String _buscaTexto = '';
  bool _isLoading = false;
  final Set<String> _contasImportadas = {};
  String _categoriaFiltro = 'todas';

  @override
  void initState() {
    super.initState();
    _carregarContasExistentes();
  }

  /// Carregar contas já existentes para evitar duplicatas
  Future<void> _carregarContasExistentes() async {
    try {
      final contasExistentes = await _contaService.fetchContas();
      setState(() {
        // Adiciona os bancos já cadastrados ao Set
        for (final conta in contasExistentes) {
          if (conta.banco != null && conta.banco!.isNotEmpty) {
            _contasImportadas.add(conta.banco!);
          }
        }
      });
    } catch (e) {
      // Erro ao carregar contas existentes
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          _buildBusca(),
          _buildFiltrosChips(),
          Expanded(child: _buildListaContas()),
        ],
      ),
    );
  }

  /// AppBar customizada
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Contas Sugeridas',
        style: TextStyle(
          color: AppColors.branco,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      backgroundColor: AppColors.tealPrimary,
      foregroundColor: AppColors.branco,
      elevation: 0,
      actions: [
        if (_contasImportadas.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(52),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_contasImportadas.length} importadas',
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

  /// Header com descrição
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.tealPrimary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const Text(
            'Selecione os bancos que você possui',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.branco,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie contas rapidamente com os principais bancos do Brasil',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.branco.withAlpha(234),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Campo de busca
  Widget _buildBusca() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _buscaTexto = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Buscar banco...',
          prefixIcon: const Icon(Icons.search, color: AppColors.tealPrimary),
          filled: true,
          fillColor: AppColors.branco,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// Filtros em chips
  Widget _buildFiltrosChips() {
    final categorias = [
      {'key': 'todas', 'label': 'Todas', 'emoji': '🏦'},
      {'key': 'populares', 'label': 'Populares', 'emoji': '⚡'},
      {'key': 'digitais', 'label': 'Digitais', 'emoji': '🚀'},
      {'key': 'tradicionais', 'label': 'Tradicionais', 'emoji': '🏛️'},
      {'key': 'cooperativas', 'label': 'Cooperativas', 'emoji': '🤝'},
      {'key': 'beneficios', 'label': 'Benefícios', 'emoji': '💳'},
      {'key': 'investimentos', 'label': 'Investimentos', 'emoji': '💰'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categorias.map((categoria) {
            final count = categoria['key'] == 'todas'
                ? ContasSugeridas.todas.length
                : ContasSugeridas.porCategoria(categoria['key']!).length;

            return _buildCategoriaChip(
              categoria['key']!,
              '${categoria['emoji']} ${categoria['label']} ($count)',
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Chip de categoria
  Widget _buildCategoriaChip(String categoria, String label) {
    final isSelected = _categoriaFiltro == categoria;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _categoriaFiltro = categoria;
          });
        },
        selectedColor: AppColors.tealPrimary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.tealPrimary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.tealPrimary : AppColors.cinzaTexto,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Lista de contas
  Widget _buildListaContas() {
    List<Map<String, dynamic>> contasFiltradas;

    if (_buscaTexto.isNotEmpty) {
      // Se há busca, aplicar busca por texto
      contasFiltradas = ContasSugeridas.buscar(_buscaTexto);
    } else if (_categoriaFiltro == 'todas') {
      // Mostrar todas as contas
      contasFiltradas = ContasSugeridas.todas;
    } else {
      // Filtrar por categoria específica
      contasFiltradas = ContasSugeridas.porCategoria(_categoriaFiltro);
    }

    if (contasFiltradas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.cinzaMedio,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum banco encontrado',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.cinzaTexto,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: contasFiltradas.length,
      itemBuilder: (context, index) {
        final conta = contasFiltradas[index];
        final banco = conta['banco'] as String;
        final jaImportada = _contasImportadas.contains(banco);

        return _buildContaCard(conta, jaImportada);
      },
    );
  }


  /// Card de conta
  Widget _buildContaCard(Map<String, dynamic> conta, bool jaImportada) {
    final cor = _parseColor(conta['cor'] as String);
    final nome = conta['nome'] as String;
    final banco = conta['banco'] as String;
    final logo = conta['logo'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [cor, cor.withAlpha(208)],
            ),
          ),
          child: Column(
            children: [
              // Corpo do card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Ícone
                    Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(52),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildLogoWidget(logo),
                    ),

                    const SizedBox(width: 16),

                    // Informações
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banco,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha(234),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Badge de status
                    if (jaImportada)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(52),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Importada',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Botão de importar (sempre visível, mas desabilitado se já importada)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: jaImportada ? 0.05 : 0.15),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: jaImportada ? null : () => _importarConta(conta),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    child: Opacity(
                      opacity: jaImportada ? 0.4 : 1.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoading && !jaImportada)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                jaImportada ? Icons.check_circle : Icons.download,
                                color: Colors.white,
                                size: 18,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              jaImportada ? 'Já Importada' : 'Importar Conta',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Importar conta
  Future<void> _importarConta(Map<String, dynamic> conta) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final nome = conta['nome'] as String;
      final banco = conta['banco'] as String;
      final tipo = conta['tipo'] as String;
      final saldoInicial = (conta['saldo_inicial'] as num).toDouble();
      final cor = conta['cor'] as String;
      final icone = conta['icone'] as String;

      await _contaService.addConta(
        nome: nome,
        tipo: tipo,
        banco: banco,
        saldoInicial: saldoInicial,
        cor: cor,
        icone: icone,
        contaPrincipal: false,
      );

      setState(() {
        _contasImportadas.add(banco);
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$nome importada com sucesso!'),
            backgroundColor: AppColors.verdeSucesso,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar conta: $e'),
            backgroundColor: AppColors.vermelhoErro,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Parse de cor
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
      return AppColors.tealPrimary;
    }
  }

  Widget _buildLogoWidget(String? logo) {
    // Fallback padrão - ajustado para o container 48x48
    const fallbackIcon = Icon(
      Icons.account_balance,
      color: Colors.white,
      size: 20,
    );

    if (logo == null || logo.isEmpty) {
      return fallbackIcon;
    }

    try {
      final lowerLogo = logo.toLowerCase();

      if (lowerLogo.endsWith('.svg')) {
        return SvgPicture.asset(
          logo,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          placeholderBuilder: (BuildContext context) => fallbackIcon,
        );
      }

      return Image.asset(
        logo,
        width: 32,
        height: 32,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Erro ao carregar imagem $logo: $error');
          return fallbackIcon;
        },
      );
    } catch (e) {
      debugPrint('Erro geral ao processar logo $logo: $e');
      return fallbackIcon;
    }
  }
}
