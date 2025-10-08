// 🗃️ Cartões Arquivados Page - iPoupei Mobile
//
// Página para exibir e gerenciar cartões de crédito arquivados
// Permite restaurar cartões arquivados para ativo

import 'package:flutter/material.dart';
import '../models/cartao_model.dart';
import '../services/cartao_service.dart';
import '../widgets/cartao_card.dart';

class CartoesArquivadosPage extends StatefulWidget {
  const CartoesArquivadosPage({super.key});

  @override
  State<CartoesArquivadosPage> createState() => _CartoesArquivadosPageState();
}

class _CartoesArquivadosPageState extends State<CartoesArquivadosPage> {
  final CartaoService _cartaoService = CartaoService.instance;
  List<CartaoModel> _cartoesArquivados = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarCartoesArquivados();
  }

  Future<void> _carregarCartoesArquivados() async {
    setState(() => _loading = true);

    try {
      final cartoes = await _cartaoService.listarCartoesArquivados();
      setState(() {
        _cartoesArquivados = cartoes;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar cartões arquivados: $e')),
        );
      }
    }
  }

  Future<void> _restaurarCartao(CartaoModel cartao) async {
    try {
      await _cartaoService.reativarCartao(cartao.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${cartao.nome} restaurado com sucesso!')),
        );
        _carregarCartoesArquivados(); // Recarregar lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao restaurar cartão: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cartões Arquivados'),
        backgroundColor: Colors.grey[50],
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cartoesArquivados.isEmpty
              ? _buildEmptyState()
              : _buildCartoesArquivados(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum cartão arquivado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cartões arquivados aparecerão aqui',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartoesArquivados() {
    return RefreshIndicator(
      onRefresh: _carregarCartoesArquivados,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _cartoesArquivados.length,
        itemBuilder: (context, index) {
          final cartao = _cartoesArquivados[index];
          return CartaoCard(
            cartao: cartao,
            isCompact: false,
            showUtilizacao: true,
            onTap: () => _showRestaurarDialog(cartao),
            trailing: _buildRestaurarButton(cartao),
          );
        },
      ),
    );
  }

  Widget _buildRestaurarButton(CartaoModel cartao) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.red[300]!, width: 1),
          ),
          child: Text(
            'ARQUIVADO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.red[700],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _showRestaurarDialog(cartao),
          icon: const Icon(Icons.restore, size: 16),
          label: const Text('Restaurar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  void _showRestaurarDialog(CartaoModel cartao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Cartão'),
        content: Text('Deseja restaurar o cartão "${cartao.nome}"?\n\nEle voltará a aparecer na lista de cartões ativos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restaurarCartao(cartao);
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }
}