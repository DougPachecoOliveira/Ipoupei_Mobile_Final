// 📂 Categorias Sugeridas - iPoupei Mobile
//
// Categorias e subcategorias originais do sistema
// Versão com emojis simples e cores vibrantes
//
// Baseado em: categoriasSugeridasData original

import 'package:flutter/material.dart';

/// Categorias e subcategorias ORIGINAIS do sistema iPoupei
/// Versão simplificada com emojis e cores vibrantes
class CategoriasSugeridasService {

  /// 8 categorias de DESPESAS
  static const List<Map<String, dynamic>> despesas = [
    {
      'id': 'desp_1',
      'nome': 'Alimentação',
      'cor': '#FF6B6B',
      'icone': '🍽️',
      'subcategorias': [
        {'nome': 'Supermercado'},
        {'nome': 'Restaurante'},
        {'nome': 'Lanche/Fast Food/Delivery'},
        {'nome': 'Açougue/Feira'}
      ]
    },
    {
      'id': 'desp_2',
      'nome': 'Transporte',
      'cor': '#4ECDC4',
      'icone': '🚗',
      'subcategorias': [
        {'nome': 'Combustível'},
        {'nome': 'Uber/Taxi'},
        {'nome': 'Transporte Público'},
        {'nome': 'Manutenção Veículo'},
        {'nome': 'Estacionamento'}
      ]
    },
    {
      'id': 'desp_3',
      'nome': 'Moradia',
      'cor': '#45B7D1',
      'icone': '🏠',
      'subcategorias': [
        {'nome': 'Aluguel'},
        {'nome': 'Condomínio'},
        {'nome': 'Energia Elétrica'},
        {'nome': 'Água'},
        {'nome': 'Internet'},
        {'nome': 'Gás'}
      ]
    },
    {
      'id': 'desp_4',
      'nome': 'Saúde',
      'cor': '#96CEB4',
      'icone': '🏥',
      'subcategorias': [
        {'nome': 'Consultas Médicas/Dentista'},
        {'nome': 'Medicamentos'},
        {'nome': 'Exames'},
        {'nome': 'Plano de Saúde'}
      ]
    },
    {
      'id': 'desp_5',
      'nome': 'Educação',
      'cor': '#FFEAA7',
      'icone': '📚',
      'subcategorias': [
        {'nome': 'Cursos'},
        {'nome': 'Livros'},
        {'nome': 'Material Escolar'},
        {'nome': 'Mensalidade'}
      ]
    },
    {
      'id': 'desp_6',
      'nome': 'Lazer',
      'cor': '#DDA0DD',
      'icone': '🎉',
      'subcategorias': [
        {'nome': 'Cinema/Teatro'},
        {'nome': 'Viagens'},
        {'nome': 'Hobbies'},
        {'nome': 'Streaming'}
      ]
    },
    {
      'id': 'desp_7',
      'nome': 'Vestuário',
      'cor': '#98D8C8',
      'icone': '👕',
      'subcategorias': [
        {'nome': 'Roupas'},
        {'nome': 'Calçados'},
        {'nome': 'Acessórios'}
      ]
    },
    {
      'id': 'desp_8',
      'nome': 'Pets',
      'cor': '#F7DC6F',
      'icone': '🐕',
      'subcategorias': [
        {'nome': 'Ração'},
        {'nome': 'Veterinário'},
        {'nome': 'Medicamentos Pet'},
        {'nome': 'Acessórios'}
      ]
    }
  ];

  /// 5 categorias de RECEITAS
  static const List<Map<String, dynamic>> receitas = [
    {
      'id': 'rec_1',
      'nome': 'Salário',
      'cor': '#27AE60',
      'icone': '💰',
      'subcategorias': [
        {'nome': 'Salário Principal'},
        {'nome': 'Horas Extras'},
        {'nome': 'Bonificação'},
        {'nome': '13º Salário'}
      ]
    },
    {
      'id': 'rec_2',
      'nome': 'Freelance',
      'cor': '#3498DB',
      'icone': '💼',
      'subcategorias': [
        {'nome': 'Projetos'},
        {'nome': 'Consultoria'},
        {'nome': 'Serviços'}
      ]
    },
    {
      'id': 'rec_3',
      'nome': 'Investimentos',
      'cor': '#9B59B6',
      'icone': '📈',
      'subcategorias': [
        {'nome': 'Dividendos'},
        {'nome': 'Juros'},
        {'nome': 'Rendimentos CDB'},
        {'nome': 'Fundos'}
      ]
    },
    {
      'id': 'rec_4',
      'nome': 'Vendas',
      'cor': '#E67E22',
      'icone': '🛍️',
      'subcategorias': [
        {'nome': 'Produtos'},
        {'nome': 'Usados'},
        {'nome': 'Artesanato'}
      ]
    },
    {
      'id': 'rec_5',
      'nome': 'Outros',
      'cor': '#95A5A6',
      'icone': '💸',
      'subcategorias': [
        {'nome': 'Presente'},
        {'nome': 'Reembolso'},
        {'nome': 'Prêmio'}
      ]
    }
  ];

  /// Obter todas as categorias sugeridas
  static List<Map<String, dynamic>> getCategoriasSugeridas() {
    return [...receitas, ...despesas];
  }

  /// Obter todas as categorias sugeridas separadas por tipo
  static Map<String, List<Map<String, dynamic>>> getAll() {
    return {
      'receitas': receitas,
      'despesas': despesas,
    };
  }

  /// Obter categorias por tipo
  static List<Map<String, dynamic>> getByTipo(String tipo) {
    switch (tipo) {
      case 'receita':
        return receitas;
      case 'despesa':
        return despesas;
      default:
        return [];
    }
  }

  /// Buscar categoria por nome (case insensitive)
  static Map<String, dynamic>? findByNome(String nome, String tipo) {
    final categorias = getByTipo(tipo);
    try {
      return categorias.firstWhere(
        (cat) => cat['nome'].toString().toLowerCase() == nome.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Validar se categoria existe nas sugestões
  static bool exists(String nome, String tipo) {
    return findByNome(nome, tipo) != null;
  }

  /// Estatísticas das categorias sugeridas
  static Map<String, int> getStats() {
    int totalSubcategoriasReceitas = receitas.fold(0, (sum, cat) =>
        sum + (cat['subcategorias'] as List).length);

    int totalSubcategoriasDespesas = despesas.fold(0, (sum, cat) =>
        sum + (cat['subcategorias'] as List).length);

    return {
      'totalReceitas': receitas.length,
      'totalDespesas': despesas.length,
      'totalSubcategoriasReceitas': totalSubcategoriasReceitas,
      'totalSubcategoriasDespesas': totalSubcategoriasDespesas,
      'totalGeral': receitas.length + despesas.length,
    };
  }

  /// 🎨 OBTER EMOJI POR NOME (usado no lugar dos ícones)
  static String getEmojiIcon(String icone) {
    return icone; // Retorna o próprio emoji
  }
}

/// 🎨 CONVERTER COR PARA FLUTTER COLOR
Color parseColor(String hexColor) {
  try {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  } catch (e) {
    return const Color(0xFF3B82F6); // Azul padrão
  }
}