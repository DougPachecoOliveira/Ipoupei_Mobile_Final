import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../models/transacao_model.dart';
import '../services/transacao_edit_service.dart';

class AlterarDataPage extends StatefulWidget {
  final TransacaoModel transacao;
  final Function(DateTime) onDataAlterada;

  const AlterarDataPage({
    super.key,
    required this.transacao,
    required this.onDataAlterada,
  });

  @override
  State<AlterarDataPage> createState() => _AlterarDataPageState();
}

class _AlterarDataPageState extends State<AlterarDataPage> {
  late DateTime _dataSelecionada;
  Map<String, dynamic>? _infoFaturaDestino;
  bool _carregandoValidacao = false;
  String? _erroValidacao;
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    _dataSelecionada = widget.transacao.data;
    _atualizarPreviewFatura();
  }

  Future<void> _atualizarPreviewFatura() async {
    if (widget.transacao.cartaoId == null) return;

    setState(() {
      _carregandoValidacao = true;
      _erroValidacao = null;
    });

    try {
      // Para simplificar, vamos simular a validação da fatura
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Calcular fatura de destino simulada
      _infoFaturaDestino = _calcularFaturaDestino(_dataSelecionada);
      
      // Simular verificação se fatura já está paga
      final mes = _infoFaturaDestino!['mesFatura'] as int;
      final ano = _infoFaturaDestino!['anoFatura'] as int;
      
      // Exemplo: considerar faturas de meses anteriores como "pagas"
      final hoje = DateTime.now();
      final dataFatura = DateTime(ano, mes);
      final mesPassado = DateTime(hoje.year, hoje.month - 1);
      
      if (dataFatura.isBefore(mesPassado)) {
        _erroValidacao = 'Esta data levaria a transação para uma fatura já paga (${_formatarMesAno(mes, ano)})';
      }
    } catch (e) {
      _erroValidacao = 'Erro ao validar data: $e';
    } finally {
      setState(() {
        _carregandoValidacao = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _getCorHeader(),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Alterar Data',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _processando || _erroValidacao != null ? null : _confirmarAlteracao,
            child: _processando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Salvar',
                    style: TextStyle(
                      color: _erroValidacao == null ? Colors.white : Colors.white54,
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
            // Header com info da transação
            _buildHeaderTransacao(),
            const SizedBox(height: 24),

            // Seletor de data
            _buildSeletorData(),
            const SizedBox(height: 24),

            // Preview da fatura (apenas para cartões)
            if (widget.transacao.cartaoId != null) ...[
              _buildPreviewFatura(),
              const SizedBox(height: 24),
            ],

            // Botão de confirmação (versão móvel)
            _buildBotaoConfirmacao(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTransacao() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 4),
          Text(
            'Data atual: ${_formatarData(widget.transacao.data)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeletorData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nova Data',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _getCorHeader(),
          ),
        ),
        const SizedBox(height: 8),
        
        InkWell(
          onTap: () async {
            final novaData = await showDatePicker(
              context: context,
              initialDate: _dataSelecionada,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: _getCorHeader(),
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            
            if (novaData != null) {
              setState(() {
                _dataSelecionada = novaData;
              });
              await _atualizarPreviewFatura();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: _getCorHeader(), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: _getCorHeader()),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatarData(_dataSelecionada),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: _getCorHeader()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewFatura() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview da Fatura',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _getCorHeader(),
          ),
        ),
        const SizedBox(height: 8),
        
        if (_carregandoValidacao)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_infoFaturaDestino != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _erroValidacao != null 
                ? AppColors.vermelhoErro.withOpacity(0.1)
                : AppColors.verdeSucesso.withOpacity(0.1),
              border: Border.all(
                color: _erroValidacao != null 
                  ? AppColors.vermelhoErro
                  : AppColors.verdeSucesso,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _erroValidacao != null ? Icons.error : Icons.check_circle,
                      color: _erroValidacao != null 
                        ? AppColors.vermelhoErro
                        : AppColors.verdeSucesso,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fatura ${_formatarMesAno(_infoFaturaDestino!['mesFatura'], _infoFaturaDestino!['anoFatura'])}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                if (_erroValidacao != null)
                  Text(
                    _erroValidacao!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.vermelhoErro,
                    ),
                  )
                else ...[
                  Text(
                    _infoFaturaDestino!['faturaFechada'] 
                      ? '⚠️ Fatura já fechada - transação irá para esta fatura'
                      : '✅ Fatura em aberto - transação será incluída normalmente',
                    style: TextStyle(
                      fontSize: 14,
                      color: _infoFaturaDestino!['faturaFechada']
                        ? AppColors.amareloAlerta
                        : AppColors.verdeSucesso,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBotaoConfirmacao() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processando || _erroValidacao != null ? null : _confirmarAlteracao,
        style: ElevatedButton.styleFrom(
          backgroundColor: _erroValidacao == null 
            ? _getCorHeader()
            : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                _erroValidacao == null ? 'Confirmar Alteração' : 'Data Inválida',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _confirmarAlteracao() async {
    if (_erroValidacao != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_erroValidacao!),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
      return;
    }

    setState(() {
      _processando = true;
    });

    try {
      final resultado = await TransacaoEditService.instance.alterarData(
        widget.transacao,
        novaData: _dataSelecionada,
      );
      
      if (resultado.sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensagem ?? 'Data alterada com sucesso'),
            backgroundColor: AppColors.tealPrimary,
          ),
        );
        widget.onDataAlterada(_dataSelecionada);
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.erro ?? 'Erro ao alterar data'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar data: $e'),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
    } finally {
      setState(() {
        _processando = false;
      });
    }
  }

  Map<String, dynamic> _calcularFaturaDestino(DateTime dataTransacao) {
    final diaFechamento = 10; // Exemplo: dia 10 de cada mês
    
    DateTime dataFechamento;
    if (dataTransacao.day <= diaFechamento) {
      dataFechamento = DateTime(dataTransacao.year, dataTransacao.month, diaFechamento);
    } else {
      final proximoMes = dataTransacao.month == 12 ? 1 : dataTransacao.month + 1;
      final proximoAno = dataTransacao.month == 12 ? dataTransacao.year + 1 : dataTransacao.year;
      dataFechamento = DateTime(proximoAno, proximoMes, diaFechamento);
    }
    
    final hoje = DateTime.now();
    final faturaJaFechada = hoje.isAfter(dataFechamento);
    
    return {
      'mesFatura': dataFechamento.month,
      'anoFatura': dataFechamento.year,
      'dataFechamento': dataFechamento,
      'faturaFechada': faturaJaFechada,
    };
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _formatarMesAno(int mes, int ano) {
    final nomesMeses = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${nomesMeses[mes]} $ano';
  }

  Color _getCorHeader() {
    if (widget.transacao.cartaoId != null) return AppColors.roxoPrimario;
    
    switch (widget.transacao.tipo) {
      case 'receita':
        return AppColors.tealPrimary;
      case 'despesa':
        return AppColors.vermelhoHeader;
      case 'transferencia':
        return AppColors.azulHeader;
      default:
        return AppColors.tealPrimary;
    }
  }
}