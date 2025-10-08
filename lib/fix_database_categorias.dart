// Script de correção única para fix do banco de dados
// Execute UMA VEZ para corrigir as subcategorias que estão com categoria_id errado

import 'package:sqflite/sqflite.dart';
import 'src/database/local_database.dart';

Future<void> fixSubcategoriasDatabase() async {
  print('🔧 Iniciando correção das subcategorias...');

  final db = LocalDatabase.instance.database;
  if (db == null) {
    print('❌ Database não inicializado');
    return;
  }

  try {
    // Mapeamento: Subcategoria → Categoria Correta
    final Map<String, String> subcategoriaParaCategoria = {
      // Transporte
      'Combustível': 'Transporte',
      'Uber/Taxi': 'Transporte',
      'Transporte Público': 'Transporte',
      'Estacionamento': 'Transporte',
      'Pedágio': 'Transporte',
      'Manutenção Veículo': 'Transporte',

      // Alimentação
      'Supermercado': 'Alimentação',
      'Restaurante': 'Alimentação',
      'Lanche/Fast Food/Delivery': 'Alimentação',
      'Açougue/Feira': 'Alimentação',

      // Vestuário
      'Roupas': 'Vestuário',
      'Calçados': 'Vestuário',
      'Acessórios': 'Vestuário',

      // Lazer
      'Streaming': 'Lazer',
      'Cinema/Teatro': 'Lazer',
      'Viagens': 'Lazer',
      'Hobbies': 'Lazer',

      // Moradia
      'Aluguel': 'Moradia',
      'Condomínio': 'Moradia',
      'Energia Elétrica': 'Moradia',
      'Água': 'Moradia',
      'Internet': 'Moradia',
      'Gás': 'Moradia',
      'Outros': 'Moradia',

      // Educação
      'Cursos': 'Educação',
      'Livros': 'Educação',
      'Material Escolar': 'Educação',
      'Mensalidade': 'Educação',

      // Pets
      'Ração': 'Pets',
      'Veterinário': 'Pets',
      'Medicamentos Pet': 'Pets',

      // Bens e Patrimônio
      'Eletrônicos': 'Bens e Patrimônio',
      'Eletrodomésticos': 'Bens e Patrimônio',
      'Móveis e Decoração': 'Bens e Patrimônio',
      'Veículo': 'Bens e Patrimônio',
      'Imóvel': 'Bens e Patrimônio',
      'Ferramentas e Equipamentos': 'Bens e Patrimônio',
      'Reformas e Materiais': 'Bens e Patrimônio',

      // Saúde (corretas)
      'Consultas Médicas/Dentista': 'Saúde',
      'Medicamentos': 'Saúde',
      'Exames': 'Saúde',
      'Plano de Saúde': 'Saúde',
      'Higiene': 'Saúde',
    };

    int corrigidas = 0;
    int erros = 0;

    for (final entry in subcategoriaParaCategoria.entries) {
      final nomeSubcategoria = entry.key;
      final nomeCategoria = entry.value;

      try {
        // Buscar ID da categoria correta
        final categoriaResult = await db.query(
          'categorias',
          where: 'nome = ?',
          whereArgs: [nomeCategoria],
          limit: 1,
        );

        if (categoriaResult.isEmpty) {
          print('⚠️ Categoria não encontrada: $nomeCategoria');
          erros++;
          continue;
        }

        final categoriaId = categoriaResult.first['id'] as String;

        // Atualizar subcategoria
        final updated = await db.update(
          'subcategorias',
          {'categoria_id': categoriaId, 'updated_at': DateTime.now().toIso8601String()},
          where: 'nome = ?',
          whereArgs: [nomeSubcategoria],
        );

        if (updated > 0) {
          print('✅ "$nomeSubcategoria" → "$nomeCategoria" (corrigida)');
          corrigidas++;
        }
      } catch (e) {
        print('❌ Erro ao corrigir "$nomeSubcategoria": $e');
        erros++;
      }
    }

    print('');
    print('🎯 RESULTADO DA CORREÇÃO:');
    print('   ✅ Subcategorias corrigidas: $corrigidas');
    print('   ❌ Erros: $erros');
    print('');
    print('✅ Correção concluída! Reinicie o app para ver as mudanças.');

  } catch (e) {
    print('❌ Erro geral na correção: $e');
  }
}
