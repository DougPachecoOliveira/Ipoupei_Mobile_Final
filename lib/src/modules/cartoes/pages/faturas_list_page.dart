// 📋 Faturas List Page - iPoupei Mobile
//
// Tela de visualização das faturas por ano (baseada em extrato_cartao_page.dart)
// Mostra 12 meses com dados REAIS: Futura, Em Aberto, Paga, Vencida
// Mantém o MESMO AppBar da gestão do cartão

import 'package:flutter/material.dart';
import '../models/cartao_model.dart';
import '../models/fatura_model.dart';
import '../services/fatura_detection_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';

class FaturasListPage extends StatefulWidget {
  final CartaoModel cartao;

  const FaturasListPage({
    Key? key,
    required this.cartao,
  }) : super(key: key);

  @override
  State<FaturasListPage> createState() => _FaturasListPageState();
}

class _FaturasListPageState extends State<FaturasListPage> {
  final FaturaDetectionService _faturaDetectionService = FaturaDetectionService.instance;
  
  int _anoAtual = DateTime.now().year;
  bool _carregando = true;
  Map<int, Map<String, dynamic>> _faturasPorMes = {}; // mes -> dados da fatura
  double _totalAno = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarFaturasDoAno();
  }

  /// ✅ CARREGAR FATURAS DO ANO
  Future<void> _carregarFaturasDoAno() async {
    setState(() {
      _carregando = true;
      _faturasPorMes.clear();
      _totalAno = 0.0;
    });

    try {
      debugPrint('📊 Carregando faturas do ano $_anoAtual para ${widget.cartao.nome}');

      // ✅ OTIMIZADO: Buscar todas as faturas do ano de uma vez
      final faturasPorMes = await _faturaDetectionService.obterFaturasAno(
        widget.cartao.id, 
        _anoAtual
      );

      // Processar faturas para o formato esperado pela UI
      for (int mes = 1; mes <= 12; mes++) {
        final fatura = faturasPorMes[mes];
        
        if (fatura == null) {
          _faturasPorMes[mes] = {
            'valor': 0.0,
            'status': 'futura',
            'fatura': null,
          };
        } else {
          // Determinar status baseado na fatura
          String status = 'futura';
          if (fatura.paga) {
            status = 'paga';
          } else if (fatura.isVencida) {
            status = 'vencida';
          } else if (fatura.valorTotal > 0) {
            status = 'aberta'; // Em aberto
          }

          _faturasPorMes[mes] = {
            'valor': fatura.valorTotal,
            'status': status,
            'fatura': fatura,
          };

          _totalAno += fatura.valorTotal;
        }
      }

      debugPrint('✅ Faturas carregadas - Total do ano: ${CurrencyFormatter.format(_totalAno)}');

    } catch (e) {
      debugPrint('❌ Erro ao carregar faturas: $e');
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      appBar: _buildAppBar(),
      body: _carregando 
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  /// ✅ APP BAR (IGUAL EXTRATO_CARTAO_PAGE.DART)
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.roxoHeader,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Seta na borda esquerda (padrão Cartões)
          Transform.translate(
            offset: const Offset(-8, 0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
          
          // Título
          Text(
            'Faturas - ${widget.cartao.nome}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ CORPO DA TELA
  Widget _buildBody() {
    return Column(
      children: [
        // Header com seletor de ano e total
        _buildHeaderAno(),
        
        // Lista dos 12 meses
        Expanded(
          child: _buildListaMeses(),
        ),
        
        // Botão voltar
        _buildBotaoVoltar(),
      ],
    );
  }

  /// ✅ HEADER DO ANO (ROXO FORTE IGUAL APPBAR)
  Widget _buildHeaderAno() {
    return Container(
      color: AppColors.roxoHeader,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Seletor de ano - PADRÃO CATEGORIAS/EXTRATO
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                onPressed: () {
                  setState(() {
                    _anoAtual--;
                  });
                  _carregarFaturasDoAno();
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(52),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _anoAtual.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                onPressed: () {
                  setState(() {
                    _anoAtual++;
                  });
                  _carregarFaturasDoAno();
                },
              ),
            ],
          ),
          
          const Spacer(),
          
          // Total do ano - APENAS BRANCO
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              Text(
                CurrencyFormatter.format(_totalAno),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ LISTA DOS 12 MESES (IGUAL REFERÊNCIA)
  Widget _buildListaMeses() {
    return Container(
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.all(0),
        itemCount: 12,
        separatorBuilder: (context, index) {
          return Container(
            height: 1,
            color: AppColors.cinzaClaro,
            margin: const EdgeInsets.only(left: 16),
          );
        },
        itemBuilder: (context, index) {
          final mes = index + 1;
          final dadosFatura = _faturasPorMes[mes] ?? {'valor': 0.0, 'status': 'futura'};
          
          return _buildItemMes(mes, dadosFatura);
        },
      ),
    );
  }

  /// ✅ ITEM MÊS (IGUAL REFERÊNCIA EXTRATO)
  Widget _buildItemMes(int mes, Map<String, dynamic> dadosFatura) {
    final valor = dadosFatura['valor'] as double;
    final status = dadosFatura['status'] as String;
    
    // Nomes dos meses abreviados
    final nomesMeses = [
      'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN',
      'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'
    ];
    
    final nomeMes = nomesMeses[mes - 1];
    final anoAbrev = _anoAtual.toString().substring(2); // Ex: "25"
    
    return InkWell(
      onTap: valor > 0 ? () => _abrirDetalhesFatura(mes, dadosFatura) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            // Ícone do status
            _buildIconeStatus(status),
            const SizedBox(width: 12),
            
            // Mês/Ano
            Text(
              '$nomeMes/$anoAbrev',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.cinzaEscuro,
              ),
            ),
            
            const Spacer(),
            
            // Valor e Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(valor),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cinzaEscuro,
                  ),
                ),
                Text(
                  _obterTextoStatus(status),
                  style: TextStyle(
                    fontSize: 12,
                    color: _obterCorStatus(status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ ÍCONE STATUS (CORES DISTINTAS)
  Widget _buildIconeStatus(String status) {
    IconData icone;
    Color cor;
    
    switch (status) {
      case 'aberta':
        icone = Icons.receipt_long;
        cor = Colors.orange; // Laranja para Em Aberto
        break;
      case 'paga':
        icone = Icons.check_circle;
        cor = const Color(0xFF4CAF50); // Verde para Paga
        break;
      case 'parcelado':
        icone = Icons.credit_card;
        cor = const Color(0xFF9C27B0); // Roxo para Parcelado
        break;
      case 'parcial':
        icone = Icons.pie_chart;
        cor = const Color(0xFFFFC107); // Âmbar para Parcial
        break;
      case 'vencida':
        icone = Icons.error;
        cor = Colors.red;
        break;
      default: // futura
        icone = Icons.schedule;
        cor = Colors.grey;
    }
    
    return Icon(icone, color: cor, size: 24);
  }

  /// ✅ TEXTO STATUS (INCLUINDO NOVOS TIPOS)
  String _obterTextoStatus(String status) {
    switch (status) {
      case 'aberta':
        return 'Em Aberto';
      case 'paga':
        return 'Paga';
      case 'parcelado':
        return 'Parcelado';
      case 'parcial':
        return 'Pago Parcial';
      case 'vencida':
        return 'Vencida';
      default:
        return 'Futura';
    }
  }

  /// ✅ COR DO STATUS (INCLUINDO NOVOS TIPOS)
  Color _obterCorStatus(String status) {
    switch (status) {
      case 'aberta':
        return Colors.orange; // Laranja para Em Aberto
      case 'paga':
        return const Color(0xFF4CAF50); // Verde para Paga
      case 'parcelado':
        return const Color(0xFF9C27B0); // Roxo para Parcelado
      case 'parcial':
        return const Color(0xFFFFC107); // Âmbar para Parcial
      case 'vencida':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// ✅ BOTÃO VOLTAR (IGUAL EXTRATO)
  Widget _buildBotaoVoltar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(
              color: AppColors.roxoHeader,
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back,
                color: AppColors.roxoHeader,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'VOLTAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.roxoHeader,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ ABRIR DETALHES DA FATURA
  void _abrirDetalhesFatura(int mes, Map<String, dynamic> dadosFatura) {
    // TODO: Implementar navegação para detalhes da fatura
    debugPrint('📋 Abrir detalhes da fatura: Mês $mes');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Detalhes da fatura de $mes/${_anoAtual.toString().substring(2)} em desenvolvimento'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}