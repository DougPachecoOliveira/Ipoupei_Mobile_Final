// lib/src/modules/shared/theme/cartao_color_palette.dart
import 'package:flutter/material.dart';

/// Paleta de cores específica para personalização de cartões
/// Com mais de 70 opções organizadas por categoria
class CartaoColorPalette {
  
  /// VERMELHOS - tons vibrantes e pastéis
  static const Map<String, String> vermelhos = {
    'Vermelho Clássico': '#F44336',
    'Vermelho Escuro': '#C62828',
    'Vermelho Vivo': '#FF1744',
    'Vermelho Rose': '#E91E63',
    'Vermelho Coral': '#FF5722',
    'Vermelho Cherry': '#D32F2F',
    'Vermelho Burgundy': '#8E0000',
    'Vermelho Tijolo': '#B71C1C',
    'Vermelho Pastel': '#FFCDD2',
    'Vermelho Salmão': '#FF8A80',
  };

  /// ROSAS - tons femininos e modernos
  static const Map<String, String> rosas = {
    'Rosa Pink': '#E91E63',
    'Rosa Claro': '#FCE4EC',
    'Rosa Quartz': '#F8BBD9',
    'Rosa Magenta': '#C2185B',
    'Rosa Fuschia': '#AD1457',
    'Rosa Blush': '#F48FB1',
    'Rosa Nude': '#FFAB91',
    'Rosa Millennial': '#F7CAC9',
  };

  /// LARANJAS - tons energéticos
  static const Map<String, String> laranjas = {
    'Laranja Clássico': '#FF9800',
    'Laranja Escuro': '#E65100',
    'Laranja Vivo': '#FF6D00',
    'Laranja Coral': '#FF7043',
    'Laranja Pêssego': '#FFAB40',
    'Laranja Tangerina': '#FF8F00',
    'Laranja Pastel': '#FFE0B2',
    'Laranja Sunset': '#FF9100',
  };

  /// AMARELOS - tons solares e dourados
  static const Map<String, String> amarelos = {
    'Amarelo Clássico': '#FFEB3B',
    'Amarelo Ouro': '#FFC107',
    'Amarelo Limão': '#CDDC39',
    'Amarelo Canário': '#FFFF00',
    'Amarelo Mostarda': '#F57F17',
    'Amarelo Pastel': '#FFF9C4',
    'Amarelo Âmbar': '#FFA000',
    'Amarelo Sol': '#FFCA28',
  };

  /// VERDES - tons naturais e vibrantes
  static const Map<String, String> verdes = {
    'Verde Clássico': '#4CAF50',
    'Verde Escuro': '#2E7D32',
    'Verde Esmeralda': '#00C853',
    'Verde Lima': '#8BC34A',
    'Verde Oliva': '#689F38',
    'Verde Menta': '#A7FFEB',
    'Verde Floresta': '#388E3C',
    'Verde Neon': '#76FF03',
    'Verde Pastel': '#C8E6C9',
    'Verde Teal': '#009688',
  };

  /// AZUIS - tons oceânicos e tecnológicos
  static const Map<String, String> azuis = {
    'Azul Clássico': '#2196F3',
    'Azul Marinho': '#1565C0',
    'Azul Royal': '#3F51B5',
    'Azul Céu': '#03DAC6',
    'Azul Turquesa': '#00BCD4',
    'Azul Petróleo': '#006064',
    'Azul Aço': '#607D8B',
    'Azul Pastel': '#BBDEFB',
    'Azul Elétrico': '#2979FF',
    'Azul Índigo': '#3F51B5',
  };

  /// ROXOS - tons místicos e elegantes
  static const Map<String, String> roxos = {
    'Roxo Clássico': '#9C27B0',
    'Roxo Escuro': '#6A1B9A',
    'Roxo Violeta': '#673AB7',
    'Roxo Lavanda': '#E1BEE7',
    'Roxo Ametista': '#AA00FF',
    'Roxo Uva': '#4A148C',
    'Roxo Lilás': '#CE93D8',
    'Roxo Deep': '#512DA8',
  };

  /// NEUTROS - tons sofisticados
  static const Map<String, String> neutros = {
    'Cinza Grafite': '#424242',
    'Cinza Chumbo': '#616161',
    'Cinza Prata': '#9E9E9E',
    'Cinza Claro': '#BDBDBD',
    'Preto Elegante': '#212121',
    'Branco Gelo': '#FAFAFA',
    'Bege': '#F5F5DC',
    'Marrom Café': '#5D4037',
    'Marrom Chocolate': '#3E2723',
    'Bronze': '#CD7F32',
  };

  /// TONS ESPECIAIS - cores únicas e modernas
  static const Map<String, String> especiais = {
    'Dourado': '#FFD700',
    'Prateado': '#C0C0C0',
    'Cobre': '#B87333',
    'Rose Gold': '#E8B4B8',
    'Champagne': '#F7E7CE',
    'Mint': '#98FB98',
    'Coral Vivo': '#FF6B6B',
    'Lavanda French': '#9BB5FF',
    'Sage Green': '#9CAF88',
    'Dusty Rose': '#DCAE96',
  };

  /// Método para obter TODAS as cores em uma lista única
  static Map<String, String> get todasAsCores {
    final Map<String, String> todas = {};
    todas.addAll(vermelhos);
    todas.addAll(rosas);
    todas.addAll(laranjas);
    todas.addAll(amarelos);
    todas.addAll(verdes);
    todas.addAll(azuis);
    todas.addAll(roxos);
    todas.addAll(neutros);
    todas.addAll(especiais);
    return todas;
  }

  /// Método para obter cores por categoria
  static Map<String, String> getCoresPorCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'vermelhos':
        return vermelhos;
      case 'rosas':
        return rosas;
      case 'laranjas':
        return laranjas;
      case 'amarelos':
        return amarelos;
      case 'verdes':
        return verdes;
      case 'azuis':
        return azuis;
      case 'roxos':
        return roxos;
      case 'neutros':
        return neutros;
      case 'especiais':
        return especiais;
      default:
        return todasAsCores;
    }
  }

  /// Lista das categorias disponíveis para cartões
  static const List<String> categorias = [
    'Vermelhos',
    'Rosas', 
    'Laranjas',
    'Amarelos',
    'Verdes',
    'Azuis',
    'Roxos',
    'Neutros',
    'Especiais',
  ];

  /// Método utilitário para converter hex em Color
  static Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Método para verificar se uma cor é clara (para contraste de texto)
  static bool isColorLight(String hexColor) {
    final color = hexToColor(hexColor);
    final brightness = (color.red * 299 + color.green * 587 + color.blue * 114) / 1000;
    return brightness > 186;
  }
}