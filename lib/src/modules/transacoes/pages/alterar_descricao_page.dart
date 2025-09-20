import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../../shared/components/ui/smart_field.dart';
import '../models/transacao_model.dart';
import '../services/transacao_edit_service.dart';

/// Página específica para alterar descrição de transações
class AlterarDescricaoPage extends StatefulWidget {
  final TransacaoModel transacao;
  final Function(String novaDescricao, EscopoEdicao escopo)? onDescricaoAlterada;

  const AlterarDescricaoPage({
    super.key,
    required this.transacao,
    this.onDescricaoAlterada,
  });

  @override
  State<AlterarDescricaoPage> createState() => _AlterarDescricaoPageState();
}

class _AlterarDescricaoPageState extends State<AlterarDescricaoPage> {
  late TextEditingController _controller;
  EscopoEdicao _escopoSelecionado = EscopoEdicao.apenasEsta;
  bool _temRecorrenciaOuParcelamento = false;
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.transacao.descricao);
    _analisarRecorrencia();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _analisarRecorrencia() {
    final transacao = widget.transacao;
    
    // Verificar recorrência
    bool temRecorrencia = transacao.recorrente || 
                         (transacao.grupoRecorrencia?.isNotEmpty ?? false);
    
    // Verificar parcelamento
    bool temParcelamento = !transacao.parcelaUnica ||
                          (transacao.totalParcelas != null && transacao.totalParcelas! > 1) ||
                          (transacao.grupoParcelamento?.isNotEmpty ?? false);
    
    setState(() {
      _temRecorrenciaOuParcelamento = temRecorrencia || temParcelamento;
    });
  }

  /// Confirma a alteração
  Future<void> _confirmarAlteracao() async {
    final novaDescricao = _controller.text.trim();
    
    
    if (novaDescricao.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A descrição não pode estar vazia'),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
      return;
    }

    setState(() {
      _processando = true;
    });

    try {
      // O escopo já é o mesmo tipo usado pelo service
      final escopoService = _escopoSelecionado;
      
      final resultado = await TransacaoEditService.instance.editarDescricao(
        widget.transacao,
        novaDescricao: novaDescricao,
        escopo: escopoService,
      );
      
      if (resultado.sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensagem ?? 'Descrição alterada com sucesso'),
            backgroundColor: AppColors.tealPrimary,
          ),
        );
        
        widget.onDescricaoAlterada?.call(novaDescricao, _escopoSelecionado);
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.erro ?? 'Erro ao alterar descrição'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar descrição: $e'),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
    } finally {
      setState(() {
        _processando = false;
      });
    }
  }


  /// Obter cor do header baseada no tipo da transação
  Color _getCorHeader() {
    switch (widget.transacao.tipo) {
      case 'receita':
        return AppColors.tealPrimary;
      case 'despesa':
        return widget.transacao.cartaoId != null 
          ? AppColors.roxoPrimario 
          : AppColors.vermelhoErro;
      default:
        return AppColors.azul;
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
                  : 'Alterar Descrição',
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
                Icons.edit,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _processando ? null : _confirmarAlteracao,
            child: _processando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Salvar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de descrição
            _buildCampoDescricao(),
            
            const SizedBox(height: 24),
            
            // Opções de escopo (se há recorrência/parcelamento)
            if (_temRecorrenciaOuParcelamento) ...[
              _buildOpcoesEscopo(),
              const SizedBox(height: 24),
            ],
            
            // Botão de salvar
            _buildBotaoSalvar(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  Widget _buildCampoDescricao() {
    return SmartField(
      controller: _controller,
      label: 'Nova Descrição',
      hint: 'Digite a nova descrição...',
      icon: Icons.edit,
      transactionContext: widget.transacao.tipo,
      maxLines: 1,
      maxLength: 200,
      autofocus: true,
      onChanged: (value) {
        setState(() {}); // Atualizar preview se existir
      },
    );
  }

  Widget _buildOpcoesEscopo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinzaBorda),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCorHeader().withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.settings_suggest, color: _getCorHeader(), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Escopo da Alteração',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getCorHeader(),
                  ),
                ),
              ],
            ),
          ),
          
          // Opções de escopo com RadioListTile elegantes
          ...EscopoEdicao.values.map((escopo) {
            final isSelected = _escopoSelecionado == escopo;
            final cor = _getCorHeader();
            
            return Container(
              decoration: BoxDecoration(
                color: isSelected ? cor.withOpacity(0.1) : null,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.cinzaBorda.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
              ),
              child: RadioListTile<EscopoEdicao>(
                value: escopo,
                groupValue: _escopoSelecionado,
                onChanged: (EscopoEdicao? value) {
                  if (value != null) {
                    setState(() {
                      _escopoSelecionado = value;
                    });
                  }
                },
                title: Text(
                  escopo.descricao,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? cor : AppColors.cinzaEscuro,
                  ),
                ),
                subtitle: Text(
                  _getSubtituloEscopo(escopo),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.cinzaTexto,
                  ),
                ),
                activeColor: cor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            );
          }),
        ],
      ),
    );
  }



  Widget _buildBotaoSalvar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processando ? null : _confirmarAlteracao,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getCorHeader(),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _processando
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Salvando...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _temRecorrenciaOuParcelamento 
                      ? 'Salvar (${_escopoSelecionado.descricao})'
                      : 'Salvar',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Obter subtítulo para cada escopo
  String _getSubtituloEscopo(EscopoEdicao escopo) {
    switch (escopo) {
      case EscopoEdicao.apenasEsta:
        return 'Altera apenas esta transação específica';
      case EscopoEdicao.estasEFuturas:
        return 'Altera esta transação e todas as futuras do mesmo grupo';
      case EscopoEdicao.todasRelacionadas:
        return 'Altera todas as transações (passadas e futuras) do mesmo grupo';
    }
  }
}