// 📝 Conta Form Page - iPoupei Mobile
// 
// Página de formulário para criar/editar contas
// Campos idênticos ao React
// 
// Baseado em: Form Pattern + Material Design
//
// 🔄 ÚLTIMAS ALTERAÇÕES:
// ✅ Botões roláveis (removido bottomNavigationBar fixo)
// ✅ Modal de ajuste usando CorrecaoSaldoPage (substituído AlertDialog antigo)
// ✅ Textos dos botões otimizados ("Salvar" em vez de "Salvar Conta")

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/conta_model.dart';
import '../services/conta_service.dart';
import '../../../shared/components/loading/ipoupei_loading_system.dart';
import '../../shared/theme/app_colors.dart';
import '../../../shared/components/ui/smart_currency_input.dart';
import '../../../shared/components/color_picker/advanced_color_picker.dart';
import '../../../shared/components/color_picker/models/color_picker_config.dart';
import 'correcao_saldo_page.dart';

class ContaFormPage extends StatefulWidget {
  final String modo; // 'criar' ou 'editar'
  final ContaModel? conta;

  const ContaFormPage({
    super.key,
    required this.modo,
    this.conta,
  });

  @override
  State<ContaFormPage> createState() => _ContaFormPageState();
}

class _ContaFormPageState extends State<ContaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _contaService = ContaService.instance;
  
  // Controllers
  final _nomeController = TextEditingController();
  final _bancoController = TextEditingController();
  final _saldoController = TextEditingController();
  
  // Focus Nodes para navegação automática
  final _nomeFocusNode = FocusNode();
  final _bancoFocusNode = FocusNode();
  final _saldoFocusNode = FocusNode();
  final _bancoPersonalizadoFocusNode = FocusNode();
  
  // Estados
  String _tipoSelecionado = 'corrente';
  String _corSelecionada = '#00BCD4';
  int _iconeSelecionadoIndex = 0; // Mudou de string para index
  bool _contaPrincipal = false;
  bool _loading = false;
  String _bancoSelecionado = '';
  
  /// 🎯 VALIDAÇÃO DO FORMULÁRIO (campos obrigatórios)
  bool get _isFormValid {
    // Nome obrigatório (mínimo 2 caracteres)
    if (_nomeController.text.trim().length < 2) return false;
    
    // Saldo obrigatório (não pode estar vazio)
    if (_saldoController.text.trim().isEmpty) return false;
    
    // 🏦 VALIDAÇÃO DE BANCO POR TIPO:
    if (_tipoSelecionado == 'corrente' || _tipoSelecionado == 'poupanca') {
      // Para contas tradicionais, banco obrigatório
      if (_bancoSelecionado.isEmpty) return false;
      if (_bancoSelecionado == 'Outros' && _bancoPersonalizadoController.text.trim().length < 2) return false;
    } 
    else if (_tipoSelecionado == 'investimento' || _tipoSelecionado == 'outros') {
      // Para investimento e outros, campo personalizado obrigatório
      if (_bancoSelecionado != 'Outros' || _bancoPersonalizadoController.text.trim().length < 2) return false;
    }
    else if (_tipoSelecionado == 'carteira') {
      // Para carteira, auto-preenchido é válido (sempre "Carteira")
      // Não precisa validação adicional de banco
    }
    
    return true;
  }

  /// 🎨 DETECTA SE É APENAS MUDANÇA VISUAL (estrela, cor, ícone)
  bool _isOnlyVisualChange() {
    if (widget.modo != 'editar' || widget.conta == null) return false;
    
    final conta = widget.conta!;
    final nomeAtual = _nomeController.text.trim();
    final saldoAtual = _converterInputParaDouble(_saldoController.text);
    
    // Se campos importantes mudaram, não é apenas visual
    final camposImportantesMudaram = nomeAtual != conta.nome ||
                                   saldoAtual != conta.saldo ||
                                   _tipoSelecionado != conta.tipo ||
                                   _getBancoFinalParaSalvar() != (conta.banco ?? '');
    
    if (camposImportantesMudaram) return false;
    
    // Se chegou aqui, só mudaram campos visuais
    return _contaPrincipal != conta.contaPrincipal ||
           _corSelecionada != (conta.cor ?? '#00BCD4') ||
           _iconeSelecionadoIndex != _getIconeIndexPorNome(conta.icone ?? 'bank');
  }

  /// 🔄 DETECTA SE HOUVE ALTERAÇÕES (para modo edição)
  bool get _temAlteracoes {
    // Modo criação sempre permite salvar se válido
    if (widget.modo == 'criar') return _isFormValid;
    
    // Modo edição: verifica se algo mudou
    if (widget.conta == null) return false;
    final conta = widget.conta!;
    
    // ⚡ MUDANÇAS VISUAIS: Permite salvar SEM validação complexa
    final mudancaVisual = _contaPrincipal != conta.contaPrincipal ||
                         _corSelecionada != (conta.cor ?? '#00BCD4') ||
                         _iconeSelecionadoIndex != _getIconeIndexPorNome(conta.icone ?? 'bank');
    
    if (mudancaVisual) {
      return true; // 🎯 PERMITE SALVAR MUDANÇAS VISUAIS SEMPRE
    }
    
    // Compara outros campos com valor original
    final nomeAtual = _nomeController.text.trim();
    final saldoAtual = _converterInputParaDouble(_saldoController.text);
    
    try {
      final bancoAtual = _getBancoFinalParaSalvar();
      
      // ✅ DETECTA ALTERAÇÕES DE TEXTO (precisa de validação)
      final mudancas = {
        'nome': nomeAtual != conta.nome,
        'saldo': saldoAtual != conta.saldo,
        'tipo': _tipoSelecionado != conta.tipo,
        'banco': bancoAtual != (conta.banco ?? ''),
      };
      
      final temAlteracao = mudancas.values.any((mudou) => mudou);
      return temAlteracao && _isFormValid;
      
    } catch (e) {
      // Fallback: se erro na validação, verifica só nome/saldo
      final mudancasBasicas = nomeAtual != conta.nome || saldoAtual != conta.saldo;
      return mudancasBasicas && _isFormValid;
    }
  }
  
  // Controller para banco personalizado
  final _bancoPersonalizadoController = TextEditingController();
  
  // Opções de tipo
  final List<Map<String, String>> _tiposContas = [
    {'valor': 'corrente', 'label': 'Conta Corrente'},
    {'valor': 'poupanca', 'label': 'Poupança'},
    {'valor': 'investimento', 'label': 'Investimento'},
    {'valor': 'carteira', 'label': 'Carteira'},
    {'valor': 'outros', 'label': 'Outros'},
  ];
  
  // Bancos sugeridos (como na screenshot)
  final List<Map<String, dynamic>> _bancosSugeridos = [
    {'nome': 'Itaú', 'cor': '#FF6D00', 'icon': Icons.account_balance},
    {'nome': 'Bradesco', 'cor': '#CC092F', 'icon': Icons.account_balance},
    {'nome': 'Nubank', 'cor': '#8A05BE', 'icon': Icons.credit_card},
    {'nome': 'Santander', 'cor': '#EC0000', 'icon': Icons.account_balance},
    {'nome': 'Banco do Brasil', 'cor': '#FFF100', 'icon': Icons.account_balance},
    {'nome': 'Outros', 'cor': '#757575', 'icon': Icons.more_horiz},
  ];
  
  // Ícones disponíveis (expansivos)
  final List<IconData> _iconesDisponiveis = [
    // Instituições
    Icons.account_balance,
    Icons.domain,
    Icons.business,
    Icons.corporate_fare,
    Icons.location_city,
    // Produtos
    Icons.credit_card,
    Icons.account_balance_wallet,
    Icons.savings,
    Icons.trending_up,
    Icons.paid,
    Icons.monetization_on,
    Icons.payment,
    Icons.local_atm,
    // Especiais
    Icons.diamond,
    Icons.star,
    Icons.favorite,
    Icons.security,
    Icons.verified,
    Icons.flash_on,
    Icons.rocket_launch,
    Icons.auto_awesome,
  ];

  // Cores disponíveis (iguais aos cartões - cores de bancos brasileiros)
  final List<String> _coresDisponiveis = [
    '#8A05BE', // Roxo Nubank
    '#FF6500', // Laranja Inter
    '#FFD700', // Amarelo C6
    '#21C25E', // Verde PicPay
    '#DC143C', // Vermelho Santander
    '#1E3A8A', // Azul BTG
    '#000000', // Preto XP
    '#6B7280', // Cinza Padrão
  ];

  @override
  void initState() {
    super.initState();
    _inicializarFormulario();
    
    // 🎯 LISTENERS PARA DETECÇÃO DE ALTERAÇÕES EM TEMPO REAL
    _nomeController.addListener(() => setState(() {}));
    _saldoController.addListener(() => setState(() {}));
    _bancoPersonalizadoController.addListener(() => setState(() {}));
    // Nota: Cor, ícone e principal já fazem setState() nos seus onTap/onChanged
    
    // 🎯 FOCO AUTOMÁTICO NO NOME APÓS CARREGAR A PÁGINA
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.modo == 'criar') {
        _nomeFocusNode.requestFocus();
      }
    });
  }
  
  void _inicializarFormulario() {
    if (widget.modo == 'editar' && widget.conta != null) {
      final conta = widget.conta!;
      _nomeController.text = conta.nome;
      _bancoController.text = conta.banco ?? '';
      _saldoController.text = _formatarValorParaInput(conta.saldo); // ✅ SALDO ATUAL, não inicial
      _tipoSelecionado = conta.tipo;
      _corSelecionada = conta.cor ?? '#00BCD4';
      _contaPrincipal = conta.contaPrincipal;
      _iconeSelecionadoIndex = _getIconeIndexPorNome(conta.icone ?? 'bank');
    } else {
      // Inicialização padrão para criação
      _corSelecionada = '#00BCD4'; // Primeira cor da lista
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _bancoController.dispose();
    _saldoController.dispose();
    _bancoPersonalizadoController.dispose();
    
    // Dispose focus nodes
    _nomeFocusNode.dispose();
    _bancoFocusNode.dispose();
    _saldoFocusNode.dispose();
    _bancoPersonalizadoFocusNode.dispose();
    
    super.dispose();
  }

  /// 🎯 NAVEGAÇÃO AUTOMÁTICA ENTRE CAMPOS
  void _navegarParaProximoCampo() {
    // Se tipo é carteira, vai direto para saldo (não precisa banco)
    if (_tipoSelecionado == 'carteira') {
      _saldoFocusNode.requestFocus();
      return;
    }
    
    // Se já tem banco selecionado e não é "Outros", vai para saldo
    if (_bancoSelecionado.isNotEmpty && _bancoSelecionado != 'Outros') {
      _saldoFocusNode.requestFocus();
      return;
    }
    
    // Se banco selecionado é "Outros" ou investimento/outros, vai para banco personalizado
    if (_bancoSelecionado == 'Outros' || 
        _tipoSelecionado == 'investimento' || 
        _tipoSelecionado == 'outros') {
      _bancoPersonalizadoFocusNode.requestFocus();
      return;
    }
    
    // Senão, vai para dropdown de banco (não tem focus, então vai para saldo)
    _saldoFocusNode.requestFocus();
  }

  /// 💰 FORMATAR VALOR PARA INPUT
  String _formatarValorParaInput(double valor) {
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }
  
  /// 💰 FORMATAR VALOR PARA EXIBIÇÃO COM SEPARADORES DE MILHARES
  String _formatarValorParaExibicao(double valor) {
    if (valor.isNaN) return '0,00';
    
    String valorStr = valor.toStringAsFixed(2);
    List<String> partes = valorStr.split('.');
    String inteiros = partes[0];
    String decimais = partes[1];
    
    // Adiciona separador de milhares
    String integersComSeparador = '';
    for (int i = 0; i < inteiros.length; i++) {
      if (i > 0 && (inteiros.length - i) % 3 == 0) {
        integersComSeparador += '.';
      }
      integersComSeparador += inteiros[i];
    }
    
    return '$integersComSeparador,$decimais';
  }

  /// 💰 CONVERTER INPUT PARA DOUBLE
  double _converterInputParaDouble(String input) {
    if (input.isEmpty) return 0.0;
    
    // Remove tudo que não é dígito, vírgula ou ponto
    String cleaned = input.replaceAll(RegExp(r'[^0-9,.]'), '');
    
    // Substitui vírgula por ponto
    cleaned = cleaned.replaceAll(',', '.');
    
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// 💾 SALVAR CONTA
  Future<void> _salvarConta() async {
    if (!_formKey.currentState!.validate()) return;

    // 🎯 DIFERENTES TIPOS DE FEEDBACK BASEADO NA OPERAÇÃO
    final isOnlyVisualChange = widget.modo == 'editar' && _isOnlyVisualChange();
    
    if (!isOnlyVisualChange) {
      setState(() => _loading = true);
    }

    try {
      final nome = _nomeController.text.trim();
      final saldoInicial = _converterInputParaDouble(_saldoController.text);

      if (widget.modo == 'criar') {
        await _contaService.addConta(
          nome: nome,
          tipo: _tipoSelecionado,
          banco: _getBancoFinalParaSalvar(), // 🎯 Baseado na lógica React
          saldoInicial: saldoInicial,
          cor: _corSelecionada,
          icone: _getIconeNomePorIndex(_iconeSelecionadoIndex),
          contaPrincipal: _contaPrincipal,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Conta "$nome" criada com sucesso!')),
          );
        }
      } else {
        await _contaService.updateConta(
          contaId: widget.conta!.id,
          nome: nome,
          tipo: _tipoSelecionado,
          banco: _getBancoFinalParaSalvar(), // 🎯 Baseado na lógica React
          cor: _corSelecionada,
          icone: _getIconeNomePorIndex(_iconeSelecionadoIndex),
          contaPrincipal: _contaPrincipal,
        );

        if (mounted) {
          // 🎯 RECARREGAR DADOS APÓS SALVAR (para atualizar estado da conta principal)
          await _recarregarDadosConta();
          
          // 🎯 FEEDBACK DIFERENCIADO POR TIPO DE MUDANÇA
          if (isOnlyVisualChange) {
            // Feedback sutil para mudanças visuais
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Salvo!'),
                  ],
                ),
                backgroundColor: Colors.green[600],
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
                margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
              ),
            );
          } else {
            // Feedback completo para mudanças importantes
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Conta "$nome" atualizada com sucesso!')),
            );
          }
        }
      }

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true); // Retorna sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar conta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (!isOnlyVisualChange) {
        setState(() => _loading = false);
      }
    }
  }

  /// 🎨 SELETOR DE COR (rolagem horizontal como na screenshot)
  Widget _buildSeletorCor() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cor da Conta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: Row(
              children: [
                // Lista de cores principais
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _coresDisponiveis.length,
                    itemBuilder: (context, index) {
                      final cor = _coresDisponiveis[index];
                      final corAtual = Color(int.parse(cor.replaceFirst('#', '0xFF')));
                      final selecionada = cor == _corSelecionada;

                      return Container(
                        margin: EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _corSelecionada = cor;
                            });
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: corAtual,
                              shape: BoxShape.circle,
                              border: selecionada
                                  ? Border.all(color: Colors.grey[400]!, width: 3)
                                  : Border.all(color: Colors.grey[300]!, width: 1),
                            ),
                            child: selecionada
                                ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Botão "Mais Cores"
                GestureDetector(
                  onTap: _mostrarModalCoresExtendidas,
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cinzaBorda),
                    ),
                    child: const Icon(Icons.add, color: Colors.grey, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  /// 🎨 HELPER FUNCTIONS
  IconData _getIconePorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'corrente':
        return Icons.account_balance;
      case 'poupanca':
        return Icons.savings;
      case 'investimento':
        return Icons.trending_up;
      case 'carteira':
        return Icons.account_balance_wallet;
      case 'outros':
        return Icons.more_horiz;
      default:
        return Icons.account_balance;
    }
  }

  /// 🎨 Modal com todas as cores estendidas usando o novo seletor
  Future<void> _mostrarModalCoresExtendidas() async {
    final selectedColor = await AdvancedColorPicker.show(
      context: context,
      type: ColorPickerType.account,
      currentColor: _corSelecionada,
      bankName: _bancoSelecionado, // Sugerir cores baseadas no banco
    );
    if (selectedColor != null) {
      setState(() {
        _corSelecionada = selectedColor;
      });
    }
  }

  /// 🎨 PREVIEW DA CONTA (igual à screenshot)
  Widget _buildPreviewConta() {
    final nome = _nomeController.text.trim();
    final saldo = _converterInputParaDouble(_saldoController.text);
    final banco = _bancoController.text.trim();
    final cor = Color(int.parse(_corSelecionada.replaceFirst('#', '0xFF')));

    // Se não tem dados suficientes, não mostra preview
    if (nome.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome do banco selecionado (pequeno)
          if (banco.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                banco,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          
          // Card da conta
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Ícone colorido da conta
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: cor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconesDisponiveis[_iconeSelecionadoIndex],
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Informações da conta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        banco.isNotEmpty ? banco : _formatarTipoParaExibicao(_tipoSelecionado),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Valor
                Text(
                  saldo.toStringAsFixed(2).replaceAll('.', ','),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: saldo >= 0 ? Colors.green[600] : Colors.red[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatarTipoParaExibicao(String tipo) {
    switch (tipo) {
      case 'corrente': return 'Conta Corrente';
      case 'poupanca': return 'Poupança';
      case 'investimento': return 'Investimento';
      case 'carteira': return 'Carteira';
      case 'outros': return 'Outros';
      default: return tipo;
    }
  }

  int _getIconeIndexPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'corrente':
        return 0; // Icons.account_balance
      case 'poupanca':
        return 8; // Icons.savings
      case 'investimento':
        return 9; // Icons.trending_up
      case 'carteira':
        return 7; // Icons.account_balance_wallet
      case 'outros':
        return 2; // Icons.business
      default:
        return 0; // Icons.account_balance
    }
  }

  int _getIconeIndexPorNome(String nome) {
    switch (nome.toLowerCase()) {
      case 'bank': return 0;
      case 'domain': return 1;
      case 'business': return 2;
      case 'corporate_fare': return 3;
      case 'location_city': return 4;
      case 'credit_card': return 5;
      case 'account_balance_wallet': return 6;
      case 'wallet': return 6;
      case 'savings': return 7;
      case 'trending_up': return 8;
      case 'investment': return 8;
      case 'paid': return 9;
      case 'monetization_on': return 10;
      case 'payment': return 11;
      case 'local_atm': return 12;
      case 'diamond': return 13;
      case 'star': return 14;
      case 'favorite': return 15;
      case 'security': return 16;
      case 'verified': return 17;
      case 'flash_on': return 18;
      case 'rocket_launch': return 19;
      case 'auto_awesome': return 20;
      default: return 0;
    }
  }

  String _getIconeNomePorIndex(int index) {
    const nomes = [
      'account_balance', 'domain', 'business', 'corporate_fare', 'location_city',
      'credit_card', 'account_balance_wallet', 'savings', 'trending_up', 'paid',
      'monetization_on', 'payment', 'local_atm', 'diamond', 'star',
      'favorite', 'security', 'verified', 'flash_on', 'rocket_launch', 'auto_awesome'
    ];
    return index < nomes.length ? nomes[index] : 'account_balance';
  }

  /// 🎯 TEXTO INICIAL PARA TIPOS ESPECIAIS (baseado no offline)
  String _getTextoInicialPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'carteira':
        return 'Carteira';         // Já vem preenchido, não precisa editar
      case 'outros':
        return 'Outros';           // Base para personalizar
      case 'investimento':
        return 'Corretora';        // Sugestão inicial (pode editar)
      default:
        return '';
    }
  }

  /// 🎯 BANCO FINAL PARA SALVAR (baseado no React - formData.banco.trim())
  String? _getBancoFinalParaSalvar() {
    if (_tipoSelecionado == 'corrente' || _tipoSelecionado == 'poupanca') {
      // Para contas tradicionais, usar banco selecionado ou personalizado
      if (_bancoSelecionado == 'Outros') {
        return _bancoPersonalizadoController.text.trim().isEmpty 
            ? null 
            : _bancoPersonalizadoController.text.trim();
      } else {
        return _bancoSelecionado.isEmpty ? null : _bancoSelecionado;
      }
    } 
    else if (_tipoSelecionado == 'investimento' || _tipoSelecionado == 'carteira' || _tipoSelecionado == 'outros') {
      // Para tipos especiais, sempre usar campo personalizado
      return _bancoPersonalizadoController.text.trim().isEmpty 
          ? null 
          : _bancoPersonalizadoController.text.trim();
    }
    
    return null;
  }

  /// 💰 CAMPO DE SALDO COM LÓGICA DE EDIÇÃO
  Widget _buildCampoSaldo() {
    final bool isEdicao = widget.modo == 'editar';
    
    if (isEdicao) {
      // 🔒 MODO EDIÇÃO: Campo bloqueado com botão de ajuste
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.tealTransparente10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.tealTransparente20,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Ícone
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.tealPrimary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.attach_money,
                color: Colors.white,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'R\$ ${_formatarValorParaExibicao(_converterInputParaDouble(_saldoController.text))}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tealPrimary,
                    ),
                  ),
                  const Text(
                    'Toque para ajustar o saldo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Botão de editar
            IconButton(
              onPressed: () => _mostrarModalAjusteSaldo(),
              icon: const Icon(
                Icons.edit,
                color: AppColors.tealPrimary,
                size: 20,
              ),
              tooltip: 'Ajustar saldo',
            ),
          ],
        ),
      );
    } else {
      // ✏️ MODO CRIAÇÃO: SmartCurrencyInput com UX perfeita
      return SmartCurrencyInput(
        controller: _saldoController,
        focusNode: _saldoFocusNode,
        hintText: 'R\$ 0,00',
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) {
          // Ao terminar de digitar saldo, salva automaticamente se tem alterações
          if (_temAlteracoes && !_loading) {
            _salvarConta();
          }
        },
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            final numero = _converterInputParaDouble(value);
            if (numero.isNaN) {
              return 'Digite um valor válido';
            }
          }
          return null;
        },
      );
    }
  }


  /// 🔧 MODAL DE AJUSTE DE SALDO (usando o modal existente da gestão de contas)
  /// 
  /// ✅ REFATORADO: Substituído o modal customizado antigo pelo modal da gestão de contas
  /// 📝 BACKUP/DELETAR: O modal AlertDialog antigo foi removido - agora usa CorrecaoSaldoPage
  /// 🎯 CONSISTÊNCIA: Mesmo comportamento do modal na gestão de contas
  Future<void> _mostrarModalAjusteSaldo() async {
    if (widget.conta == null) return;
    
    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CorrecaoSaldoPage(conta: widget.conta!);
      },
    );
    
    if (resultado == true && mounted) {
      // Recarregar os dados da conta para pegar o saldo atualizado
      await _recarregarDadosConta();
    }
  }

  /// 🔄 RECARREGAR DADOS DA CONTA APÓS AJUSTE DE SALDO OU ALTERAÇÕES
  Future<void> _recarregarDadosConta() async {
    try {
      final contaService = ContaService.instance;
      final contasAtualizadas = await contaService.fetchContas();
      final contaAtualizada = contasAtualizadas.firstWhere(
        (c) => c.id == widget.conta!.id,
        orElse: () => widget.conta!,
      );
      
      // Atualiza TODOS os dados da conta, não só o saldo
      if (mounted) {
        setState(() {
          _saldoController.text = _formatarValorParaInput(contaAtualizada.saldo);
          _contaPrincipal = contaAtualizada.contaPrincipal; // ✅ ATUALIZA CONTA PRINCIPAL
          _nomeController.text = contaAtualizada.nome;
          _corSelecionada = contaAtualizada.cor ?? '#00BCD4';
          _tipoSelecionado = contaAtualizada.tipo;
          _iconeSelecionadoIndex = _getIconeIndexPorNome(contaAtualizada.icone ?? 'bank');
        });
        
        // Feedback sutil de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Dados atualizados!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
            margin: EdgeInsets.only(bottom: 100, left: 20, right: 20),
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao recarregar dados da conta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar dados. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🏛️ BANCOS SUGERIDOS (com nomes como na screenshot)
  Widget _buildBancosSugeridos() {
    // 🎯 MOSTRAR BANCOS APENAS PARA CONTA CORRENTE E POUPANÇA (igual offline)
    final mostrarBancosSugeridos = _tipoSelecionado == 'corrente' || _tipoSelecionado == 'poupanca';
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Banco',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // 🏦 BANCOS SUGERIDOS - só aparece para Conta Corrente e Poupança (igual offline)
          if (mostrarBancosSugeridos) ...[
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _bancosSugeridos.length,
                itemBuilder: (context, index) {
                final banco = _bancosSugeridos[index];
                final cor = Color(int.parse(banco['cor'].replaceFirst('#', '0xFF')));
                final selecionado = _bancoSelecionado == banco['nome'];

                return Container(
                  margin: EdgeInsets.only(right: index == _bancosSugeridos.length - 1 ? 0 : 16),
                  child: GestureDetector(
                    onTap: () => _selecionarBanco(banco),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: cor,
                            borderRadius: BorderRadius.circular(16),
                            border: selecionado
                                ? Border.all(color: AppColors.tealPrimary, width: 2)
                                : null,
                          ),
                          child: Icon(
                            banco['icon'],
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          banco['nome'],
                          style: TextStyle(
                            fontSize: 11,
                            color: selecionado ? AppColors.tealPrimary : Colors.grey[600],
                            fontWeight: selecionado ? FontWeight.w600 : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ], // 🔚 Fecha o if (mostrarBancosSugeridos)
          
          // Campo "Outros" (aparece quando selecionado)
          if (_bancoSelecionado == 'Outros') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.edit, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Nome do Banco',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bancoPersonalizadoController,
              focusNode: _bancoPersonalizadoFocusNode,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                // Após preencher banco personalizado, vai para saldo
                _saldoFocusNode.requestFocus();
              },
              decoration: InputDecoration(
                hintText: 'Digite o nome do banco',
                hintStyle: const TextStyle(color: Colors.grey),
                border: const UnderlineInputBorder(),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.tealEscuro, width: 2),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: _bancoPersonalizadoController.text.isNotEmpty 
                        ? AppColors.tealPrimary 
                        : AppColors.cinzaBorda,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (value) {
                setState(() {
                  _bancoController.text = value.isEmpty ? 'Outros' : value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  void _selecionarBanco(Map<String, dynamic> banco) {
    setState(() {
      _bancoSelecionado = banco['nome'];
      
      if (banco['nome'] == 'Outros') {
        _bancoPersonalizadoController.clear();
        _bancoController.text = 'Outros';
      } else {
        _bancoPersonalizadoController.clear();
        _bancoController.text = banco['nome'];
        _corSelecionada = banco['cor'];
        _iconeSelecionadoIndex = _getIconeIndexPorTipo(_tipoSelecionado);
      }
    });
  }

  /// 🎨 SELETOR DE ÍCONE (rolagem horizontal como na screenshot)
  Widget _buildSeletorIcone() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ícone da Conta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _iconesDisponiveis.length,
              itemBuilder: (context, index) {
                final selecionado = index == _iconeSelecionadoIndex;

                return Container(
                  margin: EdgeInsets.only(right: index == _iconesDisponiveis.length - 1 ? 0 : 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _iconeSelecionadoIndex = index;
                      });
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: selecionado 
                            ? AppColors.tealPrimary
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: selecionado
                            ? Border.all(color: AppColors.tealPrimary, width: 2)
                            : Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Icon(
                        _iconesDisponiveis[index],
                        color: selecionado ? Colors.white : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  /// 📋 TIPOS DE CONTA (igual à screenshot)
  Widget _buildTiposConta() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de Conta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _tiposContas.map((tipo) {
              final selecionado = tipo['valor'] == _tipoSelecionado;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _tipoSelecionado = tipo['valor']!;
                    
                    // 🎯 LÓGICA BASEADA NO OFFLINE - Auto-comportamento por tipo
                    if (tipo['valor'] == 'investimento' || tipo['valor'] == 'carteira' || tipo['valor'] == 'outros') {
                      // Auto-seleciona "Outros" para tipos especiais
                      _bancoSelecionado = 'Outros';
                      _bancoController.text = 'Outros';
                      _corSelecionada = '#757575';
                      
                      // Pre-preenche baseado no tipo (igual offline)
                      String textoInicial = _getTextoInicialPorTipo(tipo['valor']!);
                      _bancoPersonalizadoController.text = textoInicial;
                      
                      // Para investimento, foca o campo (igual offline)
                      if (tipo['valor'] == 'investimento') {
                        // Delay para focar após o build
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Future.delayed(const Duration(milliseconds: 350), () {
                            // TODO: Implementar focus no campo personalizado
                          });
                        });
                      }
                    } else {
                      // Reset para tipos tradicionais (corrente, poupanca)
                      _bancoSelecionado = '';
                      _bancoPersonalizadoController.clear();
                      _bancoController.text = '';
                    }
                    
                    // Auto-ajusta ícone baseado no tipo
                    _iconeSelecionadoIndex = _getIconeIndexPorTipo(tipo['valor']!);
                  });
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: selecionado ? AppColors.tealPrimary : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: selecionado
                        ? Border.all(color: AppColors.tealPrimary, width: 2)
                        : Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getIconePorTipo(tipo['valor']!),
                        color: selecionado ? Colors.white : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tipo['valor'] == 'corrente' ? 'Corrente' :
                        tipo['valor'] == 'poupanca' ? 'Poupança' :
                        tipo['valor'] == 'investimento' ? 'Investment' :
                        tipo['valor'] == 'carteira' ? 'Carteira' : 'Outros',
                        style: TextStyle(
                          fontSize: 9,
                          color: selecionado ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  /// 📝 CAMPOS DE TEXTO (igual à screenshot)
  Widget _buildCamposTexto() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome da conta
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text(
                      'Nome da Conta',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nomeController,
                  focusNode: _nomeFocusNode,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    // Navega para próximo campo baseado no tipo selecionado
                    _navegarParaProximoCampo();
                  },
                  decoration: InputDecoration(
                    hintText: 'Ex: Conta Corrente Itaú',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: const UnderlineInputBorder(),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.tealEscuro, width: 2),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: _nomeController.text.isNotEmpty 
                            ? AppColors.tealPrimary 
                            : AppColors.cinzaBorda,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Saldo inicial
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      widget.modo == 'editar' ? 'Saldo Atual' : 'Saldo Inicial',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.modo == 'editar') ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: _mostrarModalAjusteSaldo,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.tealPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune, size: 14, color: AppColors.tealPrimary),
                              SizedBox(width: 4),
                              Text(
                                'Ajustar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.tealPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                _buildCampoSaldo(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📱 BOTÕES ROLÁVEIS (sem posicionamento fixo)
  Widget _buildBotoesRolaveis() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Botão VOLTAR (esquerda)
          Expanded(
            child: OutlinedButton(
              onPressed: _loading ? null : () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(false);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.tealPrimary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppColors.tealPrimary, width: 1),
              ),
              child: const Text(
                'Voltar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Botão SALVAR (direita)
          Expanded(
            child: ElevatedButton(
              onPressed: _temAlteracoes && !_loading ? _salvarConta : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _temAlteracoes && !_loading 
                    ? AppColors.tealPrimary     // Verde quando válido
                    : AppColors.cinzaMedio,     // Cinza quando inválido
                foregroundColor: _temAlteracoes && !_loading 
                    ? Colors.white              // Texto branco quando válido
                    : AppColors.cinzaTexto,     // Texto cinza quando inválido
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                widget.modo == 'criar' ? 'Criar' : 'Salvar',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.modo == 'criar' ? 'Nova Conta' : 'Editar Conta';

    return IPoupeiProcessingOverlay(
      isProcessing: _loading,
      context: IPoupeiLoadingContext.saving,
      message: widget.modo == 'criar' ? 'Criando conta...' : 'Salvando alterações...',
      child: Scaffold(
        backgroundColor: AppColors.branco,
        appBar: AppBar(
          backgroundColor: AppColors.tealPrimary,
          foregroundColor: Colors.white,
          title: Text(titulo),
          elevation: 0,
          actions: [
            TextButton(
              onPressed: _temAlteracoes && !_loading ? _salvarConta : null,
              child: Text(
                'Salvar',
                style: TextStyle(
                  color: _temAlteracoes && !_loading 
                      ? Colors.white      // Branco quando válido
                      : Colors.white54,   // Transparente quando inválido
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Campos de texto (topo)
              _buildCamposTexto(),
              
              // Tipo de conta
              _buildTiposConta(),
              
              // Bancos sugeridos
              _buildBancosSugeridos(),
              
              // Ícone da conta
              _buildSeletorIcone(),
              
              // Cor da conta
              _buildSeletorCor(),
              
              // ⭐ Estrela Conta Principal (com efeito visual)
              Container(
                margin: const EdgeInsets.all(16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _contaPrincipal = !_contaPrincipal;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _contaPrincipal ? AppColors.tealPrimary.withAlpha(25) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _contaPrincipal ? AppColors.tealPrimary : Colors.grey[300]!, 
                          width: _contaPrincipal ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Estrela animada com efeito
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.elasticOut,
                            child: Icon(
                              _contaPrincipal ? Icons.star : Icons.star_border,
                              color: _contaPrincipal ? AppColors.tealEscuro : Colors.grey[600],
                              size: _contaPrincipal ? 28 : 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _contaPrincipal 
                                  ? 'Conta Principal ⭐' 
                                  : 'Definir como conta principal',
                              style: TextStyle(
                                fontSize: 16,
                                color: _contaPrincipal ? AppColors.tealEscuro : Colors.black87,
                                fontWeight: _contaPrincipal ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_contaPrincipal)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.tealPrimary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'PRINCIPAL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Preview da conta (como na screenshot)
              _buildPreviewConta(),
              
              // Botões roláveis na parte inferior
              _buildBotoesRolaveis(),
              
              const SizedBox(height: 20), // Espaço final
            ],
          ),
        ),
      ),
    );
  }
}