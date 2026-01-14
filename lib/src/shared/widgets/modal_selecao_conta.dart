// 💳 Modal de Seleção de Conta - iPoupei Mobile
//
// Modal elegante e reutilizável para seleção de contas
// Usado em: pagamento de faturas, seleção de conta débito, etc.
//
// Baseado em: modal_pagamento_fatura.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../modules/contas/models/conta_model.dart';
import '../../modules/contas/data/contas_sugeridas.dart';
import '../utils/currency_formatter.dart';

class ModalSelecaoConta extends StatelessWidget {
  final List<ContaModel> contas;
  final ContaModel? contaSelecionada;
  final String? titulo;
  final String? subtitulo;
  final bool mostrarSaldo;
  final bool permitirNenhuma;
  final String? textoNenhuma;

  const ModalSelecaoConta({
    Key? key,
    required this.contas,
    this.contaSelecionada,
    this.titulo = 'Selecionar Conta',
    this.subtitulo,
    this.mostrarSaldo = true,
    this.permitirNenhuma = true,
    this.textoNenhuma = 'Nenhuma conta',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle do modal
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título e subtítulo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  titulo!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitulo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitulo!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),

          // Lista de contas
          Expanded(
            child: ListView.builder(
              itemCount: contas.length + (permitirNenhuma ? 1 : 0),
              itemBuilder: (context, index) {
                // Opção "Nenhuma"
                if (permitirNenhuma && index == 0) {
                  final isSelected = contaSelecionada == null;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? Colors.grey[50] : null,
                      border: isSelected ? Border.all(color: Colors.grey) : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.block, color: Colors.grey),
                      ),
                      title: Text(textoNenhuma!),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.grey)
                          : null,
                      onTap: () => Navigator.of(context).pop(null),
                    ),
                  );
                }

                // Conta real
                final contaIndex = permitirNenhuma ? index - 1 : index;
                final conta = contas[contaIndex];
                final isSelected = contaSelecionada?.id == conta.id;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? Colors.green[50] : null,
                    border: isSelected ? Border.all(color: Colors.green) : null,
                  ),
                  child: ListTile(
                    leading: _buildContaIcon(conta),
                    title: Text(conta.nome),
                    subtitle: Text(_buildSubtitle(conta)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () => Navigator.of(context).pop(conta),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(ContaModel conta) {
    final banco = conta.banco ?? 'Sem banco';
    if (mostrarSaldo) {
      return '$banco • ${CurrencyFormatter.format(conta.saldo)}';
    }
    return banco;
  }

  /// Ícone da conta com logo do banco
  Widget _buildContaIcon(ContaModel conta) {
    final corConta = conta.cor != null && conta.cor!.isNotEmpty
        ? Color(int.parse(conta.cor!.replaceAll('#', '0xFF')))
        : Colors.blue;

    // Buscar cor e logo oficial do banco
    final corOficialBanco = _buscarCorOficialBanco(conta.banco);
    final corFinal = corOficialBanco ?? corConta;
    final logo = _buscarLogoBanco(conta.banco);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: corFinal,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: logo != null && logo.isNotEmpty
            ? Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(2),
                child: _buildLogoWidget(logo, size: 28),
              )
            : Icon(
                conta.icone != null ? _getIconeFromString(conta.icone!) : Icons.account_balance,
                color: Colors.white,
                size: 20,
              ),
      ),
    );
  }

  /// Buscar logo do banco
  String? _buscarLogoBanco(String? banco) {
    if (banco == null || banco.isEmpty) return null;

    try {
      final bancoEncontrado = ContasSugeridas.todas.firstWhere(
        (contaSugerida) => contaSugerida['banco'] == banco,
        orElse: () => <String, dynamic>{},
      );
      return bancoEncontrado['logo'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Buscar cor oficial do banco
  Color? _buscarCorOficialBanco(String? banco) {
    if (banco == null || banco.isEmpty) return null;

    try {
      final bancoEncontrado = ContasSugeridas.todas.firstWhere(
        (contaSugerida) => contaSugerida['banco'] == banco,
        orElse: () => <String, dynamic>{},
      );
      final corString = bancoEncontrado['cor'] as String?;
      if (corString != null && corString.isNotEmpty) {
        return Color(int.parse(corString.replaceAll('#', '0xFF')));
      }
    } catch (e) {
      // Falha silenciosa
    }
    return null;
  }

  /// Widget do logo
  Widget _buildLogoWidget(String logo, {required double size}) {
    final fallback = Icon(Icons.account_balance, color: Colors.white, size: size * 0.7);

    try {
      final lowerLogo = logo.toLowerCase();
      if (lowerLogo.endsWith('.svg')) {
        return SvgPicture.asset(
          logo,
          width: size,
          height: size,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => fallback,
        );
      }
      return Image.asset(
        logo,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    } catch (e) {
      return fallback;
    }
  }

  /// Converter string para ícone
  IconData _getIconeFromString(String icone) {
    switch (icone.toLowerCase()) {
      case 'savings':
        return Icons.savings;
      case 'account_balance':
        return Icons.account_balance;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.account_balance;
    }
  }

  /// Método estático para mostrar o modal
  static Future<ContaModel?> mostrar({
    required BuildContext context,
    required List<ContaModel> contas,
    ContaModel? contaSelecionada,
    String? titulo = 'Selecionar Conta',
    String? subtitulo,
    bool mostrarSaldo = true,
    bool permitirNenhuma = true,
    String? textoNenhuma = 'Nenhuma conta',
  }) async {
    return await showModalBottomSheet<ContaModel?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ModalSelecaoConta(
        contas: contas,
        contaSelecionada: contaSelecionada,
        titulo: titulo,
        subtitulo: subtitulo,
        mostrarSaldo: mostrarSaldo,
        permitirNenhuma: permitirNenhuma,
        textoNenhuma: textoNenhuma,
      ),
    );
  }
}