import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../../shared/components/ui/smart_field.dart';
import '../models/transacao_model.dart';
import '../services/transacao_edit_service.dart' show TransacaoEditService, EscopoEdicao;


class AlterarObservacoesPage extends StatefulWidget {
  final TransacaoModel transacao;
  final VoidCallback onObservacoesAlteradas;

  const AlterarObservacoesPage({
    super.key,
    required this.transacao,
    required this.onObservacoesAlteradas,
  });

  @override
  State<AlterarObservacoesPage> createState() => _AlterarObservacoesPageState();
}

class _AlterarObservacoesPageState extends State<AlterarObservacoesPage> {
  late TextEditingController _controller;
  EscopoEdicao _escopoSelecionado = EscopoEdicao.apenasEsta;
  bool _temRecorrenciaOuParcelamento = false;
  String _infoRecorrencia = '';
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.transacao.observacoes ?? '');
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
                         transacao.ehRecorrente ||
                         (transacao.grupoRecorrencia?.isNotEmpty ?? false);
    
    // Verificar parcelamento
    bool temParcelamento = !transacao.parcelaUnica ||
                          (transacao.totalParcelas != null && transacao.totalParcelas! > 1) ||
                          (transacao.grupoParcelamento?.isNotEmpty ?? false);
    
    _temRecorrenciaOuParcelamento = temRecorrencia || temParcelamento;
    
    if (_temRecorrenciaOuParcelamento) {
      // Construir string informativa
      List<String> infos = [];
      
      if (temParcelamento) {
        if (transacao.parcelaAtual != null && transacao.totalParcelas != null) {
          infos.add('Parcela ${transacao.parcelaAtual}/${transacao.totalParcelas}');
        } else {
          infos.add('Transação parcelada');
        }
      }
      
      if (temRecorrencia) {
        if (transacao.tipoRecorrencia != null) {
          infos.add('Recorrência ${transacao.tipoRecorrencia}');
        } else {
          infos.add('Transação recorrente');
        }
      }
      
      _infoRecorrencia = infos.join(' • ');
    }
  }

  Future<void> _salvarAlteracoes() async {
    final novasObservacoes = _controller.text.trim();
    
    setState(() {
      _processando = true;
    });
    
    try {
      // Mapear escopo para incluirFuturas
      final incluirFuturas = _escopoSelecionado != EscopoEdicao.apenasEsta;
      
      final resultado = await TransacaoEditService.instance.editarObservacoes(
        widget.transacao,
        novasObservacoes: novasObservacoes,
        escopo: incluirFuturas ? EscopoEdicao.estasEFuturas : EscopoEdicao.apenasEsta,
      );
      
      if (resultado.sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensagem ?? 'Observações salvas com sucesso'),
            backgroundColor: AppColors.verdeSucesso,
          ),
        );
        
        widget.onObservacoesAlteradas();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.erro ?? 'Erro ao salvar observações'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar observações: $e'),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
    } finally {
      setState(() {
        _processando = false;
      });
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
                  : 'Observações',
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
                Icons.edit_note,
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
            onPressed: _processando ? null : _salvarAlteracoes,
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
            // Preview das observações
            _buildPreviewObservacoes(),
            const SizedBox(height: 24),
            
            // Editor de observações
            _buildEditorObservacoes(),

            // Opções de escopo (apenas se tem recorrência/parcelamento)
            if (_temRecorrenciaOuParcelamento) ...[
              const SizedBox(height: 24),
              _buildOpcoesEscopo(),
            ],
            
            const SizedBox(height: 24),
            
            // Botão de salvar ao final da página
            _buildBotaoSalvar(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewObservacoes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinzaBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: _getCorHeader(), size: 20),
              const SizedBox(width: 8),
              Text(
                'Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getCorHeader(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Antes
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Antes:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.cinzaTexto,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.transacao.observacoes?.isNotEmpty == true 
                      ? widget.transacao.observacoes!
                      : 'Sem observações',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.transacao.observacoes?.isNotEmpty == true 
                        ? AppColors.cinzaEscuro
                        : AppColors.cinzaLegenda,
                    fontStyle: widget.transacao.observacoes?.isNotEmpty == true 
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Depois
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Depois:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.cinzaTexto,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getCorHeader().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getCorHeader().withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _controller.text.isNotEmpty 
                      ? _controller.text
                      : 'Sem observações',
                  style: TextStyle(
                    fontSize: 14,
                    color: _controller.text.isNotEmpty 
                        ? AppColors.cinzaEscuro
                        : AppColors.cinzaLegenda,
                    fontStyle: _controller.text.isNotEmpty 
                        ? FontStyle.normal
                        : FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditorObservacoes() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinzaBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCorHeader().withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: _getCorHeader(), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Editar Observações',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getCorHeader(),
                  ),
                ),
              ],
            ),
          ),
          
          // Campo de texto (SmartField style)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SmartField(
              controller: _controller,
              label: 'Observações',
              hint: 'Adicione observações sobre esta transação...',
              icon: Icons.edit_note,
              transactionContext: widget.transacao.tipo,
              maxLines: 4,
              maxLength: 500,
              onChanged: (value) {
                setState(() {}); // Atualizar preview
              },
            ),
          ),
        ],
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCorHeader().withOpacity(0.1),
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
          
          // Opções de escopo
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
                  _getDescricaoEscopo(escopo),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.cinzaTexto,
                  ),
                ),
                activeColor: cor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBotaoSalvar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processando ? null : _salvarAlteracoes,
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
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Salvando...',
                    style: const TextStyle(
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

  Color _getCorHeader() {
    switch (widget.transacao.tipo) {
      case 'receita':
        return AppColors.tealPrimary;
      case 'despesa':
        return widget.transacao.cartaoId != null 
            ? AppColors.roxoPrimario 
            : AppColors.vermelhoHeader;
      case 'transferencia':
        return AppColors.azulHeader;
      default:
        return AppColors.tealPrimary;
    }
  }

  String _getDescricaoEscopo(EscopoEdicao escopo) {
    switch (escopo) {
      case EscopoEdicao.apenasEsta:
        return 'Alterar observações apenas desta transação';
      case EscopoEdicao.estasEFuturas:
        return 'Alterar observações desta e das próximas transações';
      case EscopoEdicao.todasRelacionadas:
        return 'Alterar observações de todas as transações relacionadas';
    }
  }
}