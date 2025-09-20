import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../../shared/components/ui/smart_field.dart';
import '../models/transacao_model.dart';
import '../services/transacao_edit_service.dart' show TransacaoEditService, EscopoEdicao;

class AplicarReajustePage extends StatefulWidget {
  final TransacaoModel transacao;
  final Function(double, bool, EscopoEdicao) onReajusteAplicado;

  const AplicarReajustePage({
    super.key,
    required this.transacao,
    required this.onReajusteAplicado,
  });

  @override
  State<AplicarReajustePage> createState() => _AplicarReajustePageState();
}

class _AplicarReajustePageState extends State<AplicarReajustePage> {
  final _percentualController = TextEditingController();
  bool _isAumento = true;
  bool _processando = false;
  bool _temRecorrenciaOuParcelamento = false;
  bool _incluirFuturas = false;
  int _quantidadeFuturas = 0;

  @override
  void initState() {
    super.initState();
    
    // Listener para atualizar preview do reajuste em tempo real
    _percentualController.addListener(() {
      setState(() {
        // Atualiza o preview quando o percentual muda
      });
    });
    
    _analisarTransacao();
  }

  @override
  void dispose() {
    _percentualController.dispose();
    super.dispose();
  }

  Future<void> _analisarTransacao() async {
    // Verificar se tem parcelas ou recorrências
    if (widget.transacao.recorrente || widget.transacao.grupoRecorrencia != null) {
      _temRecorrenciaOuParcelamento = true;
      
      // Calcular quantidade de futuras transações
      _calcularQuantidadeFuturas();
      
      // Se a transação estiver efetivada, força incluir futuras (só pode alterar futuras)
      if (widget.transacao.efetivado) {
        _incluirFuturas = true;
      }
    }

    setState(() {
      // Atualizar estado após análise
    });
  }

  void _calcularQuantidadeFuturas() {
    // Se tem parcelas
    if (widget.transacao.numeroTotalParcelas != null && widget.transacao.numeroTotalParcelas! > 1) {
      final atual = widget.transacao.numeroParcelaAtual ?? 1;
      final total = widget.transacao.numeroTotalParcelas!;
      _quantidadeFuturas = total - atual;
    }
    // Se é recorrente - estimar baseado em um ano
    else if (widget.transacao.recorrente) {
      final tipo = widget.transacao.tipoRecorrencia ?? 'Mensal';
      switch (tipo.toLowerCase()) {
        case 'diária':
        case 'diario':
          _quantidadeFuturas = 365; // Aproximação de um ano
          break;
        case 'semanal':
          _quantidadeFuturas = 52; // 52 semanas no ano
          break;
        case 'quinzenal':
          _quantidadeFuturas = 26; // 26 quinzenas no ano
          break;
        case 'mensal':
          _quantidadeFuturas = 12; // 12 meses no ano
          break;
        case 'bimestral':
          _quantidadeFuturas = 6; // 6 bimestres no ano
          break;
        case 'trimestral':
          _quantidadeFuturas = 4; // 4 trimestres no ano
          break;
        case 'semestral':
          _quantidadeFuturas = 2; // 2 semestres no ano
          break;
        case 'anual':
          _quantidadeFuturas = 1; // 1 por ano
          break;
        default:
          _quantidadeFuturas = 12; // Padrão mensal
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      appBar: AppBar(
        backgroundColor: _getCorHeader(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.transacao.descricao.isNotEmpty 
                  ? widget.transacao.descricao 
                  : 'Aplicar Reajuste',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.percent,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildCardTransacao(),
              const SizedBox(height: 24),
              
              // Seleção de tipo de reajuste
              _buildTipoReajuste(),
              const SizedBox(height: 24),
              
              // Campo de percentual usando SmartField
              SmartField(
                controller: _percentualController,
                label: 'Percentual do ${_isAumento ? "Aumento" : "Desconto"}',
                hint: '10,5%',
                icon: _isAumento ? Icons.trending_up : Icons.trending_down,
                transactionContext: 'percentual',
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {}); // Atualizar preview
                },
              ),
              
              // Opções de escopo (para transações recorrentes/parceladas)
              if (_temRecorrenciaOuParcelamento) ...[
                const SizedBox(height: 24),
                _buildCheckboxFuturas(),
              ],
              
              // Preview do impacto do reajuste
              if (_percentualController.text.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildPreviewReajuste(),
              ],
              
              const SizedBox(height: 60),
              
              if (_processando)
                const CircularProgressIndicator()
              else
                _buildBotaoGradiente(
                  texto: 'Aplicar ${_isAumento ? "Aumento" : "Desconto"}',
                  icone: _isAumento ? Icons.trending_up : Icons.trending_down,
                  onPressed: _aplicarReajuste,
                ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardTransacao() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getCorHeader().withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCorHeader().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.transacao.tipo.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getCorHeader(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'R\$ ${widget.transacao.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ),
                // Badge indicando se tem recorrência/parcelas
                if (_temRecorrenciaOuParcelamento)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.roxoPrimario.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 12,
                          color: AppColors.roxoPrimario,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _quantidadeFuturas > 0 ? '+$_quantidadeFuturas' : 'Série',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.roxoPrimario,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.transacao.descricao,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoReajuste() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isAumento = true),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isAumento 
                    ? AppColors.verdeSucesso.withOpacity(0.1)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isAumento 
                      ? AppColors.verdeSucesso
                      : AppColors.cinzaBorda,
                  width: _isAumento ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: _isAumento 
                        ? AppColors.verdeSucesso
                        : AppColors.cinzaTexto,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aumento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _isAumento ? FontWeight.w600 : FontWeight.normal,
                      color: _isAumento 
                          ? AppColors.verdeSucesso
                          : AppColors.cinzaTexto,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isAumento = false),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: !_isAumento 
                    ? AppColors.vermelhoErro.withOpacity(0.1)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: !_isAumento 
                      ? AppColors.vermelhoErro
                      : AppColors.cinzaBorda,
                  width: !_isAumento ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.trending_down,
                    color: !_isAumento 
                        ? AppColors.vermelhoErro
                        : AppColors.cinzaTexto,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Desconto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: !_isAumento ? FontWeight.w600 : FontWeight.normal,
                      color: !_isAumento 
                          ? AppColors.vermelhoErro
                          : AppColors.cinzaTexto,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxFuturas() {
    if (_quantidadeFuturas == 0) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: () => setState(() => _incluirFuturas = !_incluirFuturas),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _incluirFuturas 
            ? AppColors.verdeSucesso.withOpacity(0.1)
            : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _incluirFuturas 
              ? AppColors.verdeSucesso 
              : AppColors.cinzaBorda,
            width: _incluirFuturas ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _incluirFuturas 
                  ? AppColors.verdeSucesso 
                  : Colors.transparent,
                border: Border.all(
                  color: _incluirFuturas 
                    ? AppColors.verdeSucesso 
                    : AppColors.cinzaBorda,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _incluirFuturas
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.transacao.efetivado
                      ? 'Aplicar reajuste às futuras transações'
                      : 'Incluir futuras transações no reajuste',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _incluirFuturas 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                      color: _incluirFuturas 
                        ? AppColors.verdeSucesso
                        : AppColors.cinzaEscuro,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _quantidadeFuturas > 0
                      ? widget.transacao.efetivado
                        ? 'Alterar as próximas $_quantidadeFuturas transações (atual já efetivada)'
                        : 'Aplicar também às próximas $_quantidadeFuturas transações'
                      : 'Não há futuras transações para alterar',
                    style: TextStyle(
                      fontSize: 13,
                      color: _incluirFuturas 
                        ? AppColors.verdeSucesso.withOpacity(0.8)
                        : AppColors.cinzaTexto,
                    ),
                  ),
                ],
              ),
            ),
            if (_quantidadeFuturas > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _incluirFuturas 
                    ? AppColors.verdeSucesso.withOpacity(0.1)
                    : AppColors.cinzaMedio.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$_quantidadeFuturas',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _incluirFuturas 
                      ? AppColors.verdeSucesso 
                      : AppColors.cinzaTexto,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewReajuste() {
    final percentual = double.tryParse(_percentualController.text.replaceAll(',', '.'));
    if (percentual == null || percentual <= 0) return const SizedBox.shrink();
    
    final valorAtual = widget.transacao.valor;
    final valorReajustado = _isAumento 
        ? valorAtual * (1 + percentual / 100)
        : valorAtual * (1 - percentual / 100);
    final diferenca = valorReajustado - valorAtual;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isAumento 
          ? AppColors.verdeSucesso.withOpacity(0.05)
          : AppColors.vermelhoErro.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isAumento 
            ? AppColors.verdeSucesso.withOpacity(0.2)
            : AppColors.vermelhoErro.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isAumento ? Icons.trending_up : Icons.trending_down,
                color: _isAumento ? AppColors.verdeSucesso : AppColors.vermelhoErro,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Preview do Reajuste',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isAumento ? AppColors.verdeSucesso : AppColors.vermelhoErro,
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
                      'Valor Atual',
                      style: TextStyle(fontSize: 12, color: AppColors.cinzaTexto),
                    ),
                    Text(
                      'R\$ ${valorAtual.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cinzaEscuro,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: _isAumento ? AppColors.verdeSucesso : AppColors.vermelhoErro),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Novo Valor',
                      style: TextStyle(fontSize: 12, color: AppColors.cinzaTexto),
                    ),
                    Text(
                      'R\$ ${valorReajustado.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isAumento ? AppColors.verdeSucesso : AppColors.vermelhoErro,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${_isAumento ? '+' : ''}R\$ ${diferenca.abs().toStringAsFixed(2).replaceAll('.', ',')} (${_isAumento ? '+' : '-'}${percentual.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _isAumento ? AppColors.verdeSucesso : AppColors.vermelhoErro,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBotaoGradiente({
    required String texto,
    required IconData icone,
    required VoidCallback onPressed,
  }) {
    final cor = _isAumento ? AppColors.verdeSucesso : AppColors.vermelhoErro;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cor, cor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icone,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  texto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _aplicarReajuste() async {
    final percentual = double.tryParse(_percentualController.text.replaceAll(',', '.'));
    if (percentual == null || percentual <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um percentual válido')),
      );
      return;
    }

    setState(() {
      _processando = true;
    });

    try {
      final resultado = await TransacaoEditService.instance.aplicarReajuste(
        widget.transacao,
        percentual,
        isAumento: _isAumento,
      );

      if (resultado.sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado.mensagem ?? 'Reajuste aplicado')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado.erro ?? 'Erro desconhecido')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() {
        _processando = false;
      });
    }
  }

  Color _getCorHeader() {
    if (widget.transacao.tipo == 'receita') {
      return AppColors.verdeSucesso;
    } else if (widget.transacao.tipo == 'despesa') {
      return widget.transacao.cartaoId != null 
        ? AppColors.roxoPrimario 
        : AppColors.vermelhoErro;
    } else {
      return AppColors.azul;
    }
  }

}