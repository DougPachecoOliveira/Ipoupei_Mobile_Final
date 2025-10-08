// 🏷️ Categoria Valor Model - iPoupei Mobile
// 
// Modelo para representar categorias com valores
// Usado em gráficos e relatórios

class CategoriaValor {
  final String nome;
  final double valor;
  final String color;

  CategoriaValor({
    required this.nome,
    required this.valor,
    required this.color,
  });

  /// Converter para mapa
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'valor': valor,
      'color': color,
    };
  }

  /// Criar a partir de mapa
  factory CategoriaValor.fromMap(Map<String, dynamic> map) {
    return CategoriaValor(
      nome: map['nome'] ?? '',
      valor: (map['valor'] ?? 0.0).toDouble(),
      color: map['color'] ?? '#6B7280',
    );
  }

  @override
  String toString() {
    return 'CategoriaValor(nome: $nome, valor: $valor, color: $color)';
  }
}