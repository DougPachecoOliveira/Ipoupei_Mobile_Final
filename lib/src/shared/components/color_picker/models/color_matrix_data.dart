// lib/src/shared/components/color_picker/models/color_matrix_data.dart
import 'package:flutter/material.dart';

/// Dados da matriz 2D de cores organizadas por matiz e intensidade
class ColorMatrixData {

  /// Estrutura da matriz: [linha][coluna] = cor
  /// Organizada exatamente como na imagem: escala de cinza no topo, depois cores por matiz
  static const List<List<Map<String, String>>> matrix = [

    // LINHA 1: Escala de Cinza (topo da imagem)
    [
      {'nome': 'Cinza Claro 1', 'hex': '#F5F5F5'},
      {'nome': 'Cinza Claro 2', 'hex': '#E0E0E0'},
      {'nome': 'Cinza Claro 3', 'hex': '#CCCCCC'},
      {'nome': 'Cinza Médio 1', 'hex': '#B0B0B0'},
      {'nome': 'Cinza Médio 2', 'hex': '#959595'},
      {'nome': 'Cinza Médio 3', 'hex': '#7A7A7A'},
      {'nome': 'Cinza Escuro 1', 'hex': '#606060'},
      {'nome': 'Cinza Escuro 2', 'hex': '#484848'},
      {'nome': 'Cinza Escuro 3', 'hex': '#303030'},
      {'nome': 'Cinza Escuro 4', 'hex': '#202020'},
      {'nome': 'Cinza Escuro 5', 'hex': '#101010'},
      {'nome': 'Preto', 'hex': '#000000'},
    ],

    // LINHA 2: Tons Escuros/Saturados
    [
      {'nome': 'Ciano Escuro', 'hex': '#006B7A'},
      {'nome': 'Azul Escuro', 'hex': '#003D7A'},
      {'nome': 'Índigo Escuro', 'hex': '#2E1065'},
      {'nome': 'Violeta Escuro', 'hex': '#4A0E4E'},
      {'nome': 'Magenta Escuro', 'hex': '#7A1448'},
      {'nome': 'Vermelho Escuro', 'hex': '#7A1E1E'},
      {'nome': 'Laranja Escuro', 'hex': '#B8510A'},
      {'nome': 'Amarelo Escuro', 'hex': '#B8A20A'},
      {'nome': 'Lima Escuro', 'hex': '#6B7A0A'},
      {'nome': 'Verde Escuro', 'hex': '#2E5A1A'},
      {'nome': 'Verde Azul Escuro', 'hex': '#0A5A48'},
      {'nome': 'Turquesa Escuro', 'hex': '#0A6B7A'},
    ],

    // LINHA 3: Tons Médios
    [
      {'nome': 'Ciano Médio', 'hex': '#1A9FB0'},
      {'nome': 'Azul Médio', 'hex': '#1A5AAD'},
      {'nome': 'Índigo Médio', 'hex': '#4A2C8A'},
      {'nome': 'Violeta Médio', 'hex': '#6B2C7A'},
      {'nome': 'Magenta Médio', 'hex': '#AD3D6B'},
      {'nome': 'Vermelho Médio', 'hex': '#AD4A4A'},
      {'nome': 'Laranja Médio', 'hex': '#D06A1A'},
      {'nome': 'Amarelo Médio', 'hex': '#D0BD1A'},
      {'nome': 'Lima Médio', 'hex': '#9FAD1A'},
      {'nome': 'Verde Médio', 'hex': '#5A7A3D'},
      {'nome': 'Verde Azul Médio', 'hex': '#1A7A5A'},
      {'nome': 'Turquesa Médio', 'hex': '#1A9FB0'},
    ],

    // LINHA 4: Tons Saturados (centro - onde está a seleção)
    [
      {'nome': 'Ciano Saturado', 'hex': '#33CCE6'},
      {'nome': 'Azul Saturado', 'hex': '#3377E6'},
      {'nome': 'Índigo Saturado', 'hex': '#6648CC'},
      {'nome': 'Violeta Saturado', 'hex': '#8C48AD'},
      {'nome': 'Magenta Saturado', 'hex': '#E06699'},
      {'nome': 'Vermelho Saturado', 'hex': '#E66666'}, // Área da seleção
      {'nome': 'Laranja Saturado', 'hex': '#FF8533'},
      {'nome': 'Amarelo Saturado', 'hex': '#FFD633'},
      {'nome': 'Lima Saturado', 'hex': '#CCFF33'},
      {'nome': 'Verde Saturado', 'hex': '#7AE666'},
      {'nome': 'Verde Azul Saturado', 'hex': '#33E699'},
      {'nome': 'Turquesa Saturado', 'hex': '#33CCE6'},
    ],

    // LINHA 5: Tons Brilhantes
    [
      {'nome': 'Ciano Brilhante', 'hex': '#66E6FF'},
      {'nome': 'Azul Brilhante', 'hex': '#6699FF'},
      {'nome': 'Índigo Brilhante', 'hex': '#9966FF'},
      {'nome': 'Violeta Brilhante', 'hex': '#B366E6'},
      {'nome': 'Magenta Brilhante', 'hex': '#FF99CC'},
      {'nome': 'Vermelho Brilhante', 'hex': '#FF9999'},
      {'nome': 'Laranja Brilhante', 'hex': '#FFB366'},
      {'nome': 'Amarelo Brilhante', 'hex': '#FFE666'},
      {'nome': 'Lima Brilhante', 'hex': '#E6FF66'},
      {'nome': 'Verde Brilhante', 'hex': '#99FF99'},
      {'nome': 'Verde Azul Brilhante', 'hex': '#66FFCC'},
      {'nome': 'Turquesa Brilhante', 'hex': '#66E6FF'},
    ],

    // LINHA 6: Tons Claros
    [
      {'nome': 'Ciano Claro', 'hex': '#99F0FF'},
      {'nome': 'Azul Claro', 'hex': '#99CCFF'},
      {'nome': 'Índigo Claro', 'hex': '#CC99FF'},
      {'nome': 'Violeta Claro', 'hex': '#D699FF'},
      {'nome': 'Magenta Claro', 'hex': '#FFCCEE'},
      {'nome': 'Vermelho Claro', 'hex': '#FFCCCC'},
      {'nome': 'Laranja Claro', 'hex': '#FFD699'},
      {'nome': 'Amarelo Claro', 'hex': '#FFF099'},
      {'nome': 'Lima Claro', 'hex': '#F0FF99'},
      {'nome': 'Verde Claro', 'hex': '#CCFFCC'},
      {'nome': 'Verde Azul Claro', 'hex': '#99FFEE'},
      {'nome': 'Turquesa Claro', 'hex': '#99F0FF'},
    ],

    // LINHA 7: Tons Mais Escuros (base da imagem)
    [
      {'nome': 'Ciano Escuro Base', 'hex': '#80D4E6'},
      {'nome': 'Azul Escuro Base', 'hex': '#80B8FF'},
      {'nome': 'Índigo Escuro Base', 'hex': '#B380FF'},
      {'nome': 'Violeta Escuro Base', 'hex': '#CC80FF'},
      {'nome': 'Magenta Escuro Base', 'hex': '#FFB3DD'},
      {'nome': 'Vermelho Escuro Base', 'hex': '#FFB3B3'},
      {'nome': 'Laranja Escuro Base', 'hex': '#FFD080'},
      {'nome': 'Amarelo Escuro Base', 'hex': '#FFE680'},
      {'nome': 'Lima Escuro Base', 'hex': '#E6FF80'},
      {'nome': 'Verde Escuro Base', 'hex': '#B3FFB3'},
      {'nome': 'Verde Azul Escuro Base', 'hex': '#80FFD4'},
      {'nome': 'Turquesa Escuro Base', 'hex': '#80E6FF'},
    ],
  ];

  /// Labels para as intensidades (linhas)
  static const List<String> intensityLabels = [
    'Cinza',
    'Escuro',
    'Médio',
    'Saturado',
    'Brilhante',
    'Claro',
    'Pastel',
  ];

  /// Labels para os matizes (colunas)
  static const List<String> hueLabels = [
    'Branco',
    'Cinza 1',
    'Cinza 2',
    'Cinza 3',
    'Cinza 4',
    'Cinza 5',
    'Cinza 6',
    'Cinza 7',
    'Cinza 8',
    'Cinza 9',
    'Cinza 10',
    'Preto',
  ];

  /// Ícones para cada matiz
  static const List<IconData> hueIcons = [
    Icons.circle, // Ciano
    Icons.circle, // Azul
    Icons.circle, // Índigo
    Icons.circle, // Roxo
    Icons.circle, // Magenta
    Icons.circle, // Vermelho
    Icons.circle, // Laranja
    Icons.circle, // Amarelo
    Icons.circle, // Lima
    Icons.circle, // Verde
    Icons.circle, // Esmeralda
    Icons.circle, // Turquesa
  ];

  /// Cores de ícone para cada matiz
  static const List<Color> hueIconColors = [
    Color(0xFF00B4CC), // Ciano
    Color(0xFF3380FF), // Azul
    Color(0xFF6600FF), // Índigo
    Color(0xFF8000E6), // Roxo
    Color(0xFFE0007A), // Magenta
    Color(0xFFE60000), // Vermelho
    Color(0xFFFF9900), // Laranja
    Color(0xFFFFFF00), // Amarelo
    Color(0xFF99FF00), // Lima
    Color(0xFF4DCC00), // Verde
    Color(0xFF00CC66), // Esmeralda
    Color(0xFF00CCFF), // Turquesa
  ];

  /// Método para obter cor por coordenadas
  static Map<String, String>? getColor(int row, int column) {
    if (row < 0 || row >= matrix.length || column < 0 || column >= matrix[0].length) {
      return null;
    }
    return matrix[row][column];
  }

  /// Método para obter todas as cores em formato AppColorItem
  static List<Map<String, dynamic>> getAllColorsAsAppColorItems() {
    final List<Map<String, dynamic>> colors = [];

    for (int row = 0; row < matrix.length; row++) {
      for (int column = 0; column < matrix[row].length; column++) {
        final colorData = matrix[row][column];
        colors.add({
          'nome': colorData['nome']!,
          'hexValue': colorData['hex']!,
          'category': hueLabels[column],
          'intensity': intensityLabels[row],
          'row': row,
          'column': column,
        });
      }
    }

    return colors;
  }

  /// Método para buscar cor por nome ou hex
  static Map<String, dynamic>? findColor(String searchTerm) {
    final allColors = getAllColorsAsAppColorItems();

    for (final color in allColors) {
      if (color['nome'].toString().toLowerCase().contains(searchTerm.toLowerCase()) ||
          color['hexValue'].toString().toLowerCase() == searchTerm.toLowerCase()) {
        return color;
      }
    }

    return null;
  }

  /// Número total de linhas na matriz
  static int get rowCount => matrix.length;

  /// Número total de colunas na matriz
  static int get columnCount => matrix.isNotEmpty ? matrix[0].length : 0;
}