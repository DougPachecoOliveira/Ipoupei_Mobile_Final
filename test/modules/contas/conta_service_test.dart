// 🧪 Conta Service Tests - iPoupei Mobile
// 
// Testes unitários para o serviço de contas
// 
// Baseado em: Flutter Test + Mockito

import 'package:flutter_test/flutter_test.dart';
import '../../../lib/src/modules/contas/models/conta_model.dart';
import '../../../lib/src/modules/contas/services/conta_service.dart';

void main() {
  group('ContaModel', () {
    test('deve criar ContaModel corretamente', () {
      final conta = ContaModel(
        id: '123',
        usuarioId: 'user123',
        nome: 'Teste',
        tipo: 'corrente',
        saldoInicial: 1000.0,
        saldo: 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(conta.id, '123');
      expect(conta.nome, 'Teste');
      expect(conta.tipo, 'corrente');
      expect(conta.saldoInicial, 1000.0);
      expect(conta.saldo, 1000.0);
    });

    test('deve criar ContaModel a partir de JSON', () {
      final json = {
        'id': '123',
        'usuario_id': 'user123',
        'nome': 'Teste',
        'tipo': 'corrente',
        'saldo_inicial': 1000.0,
        'saldo': 1000.0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final conta = ContaModel.fromJson(json);

      expect(conta.id, '123');
      expect(conta.usuarioId, 'user123');
      expect(conta.nome, 'Teste');
      expect(conta.tipo, 'corrente');
    });

    test('deve converter ContaModel para JSON', () {
      final conta = ContaModel(
        id: '123',
        usuarioId: 'user123',
        nome: 'Teste',
        tipo: 'corrente',
        saldoInicial: 1000.0,
        saldo: 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = conta.toJson();

      expect(json['id'], '123');
      expect(json['usuario_id'], 'user123');
      expect(json['nome'], 'Teste');
      expect(json['tipo'], 'corrente');
    });

    test('deve fazer copyWith corretamente', () {
      final conta = ContaModel(
        id: '123',
        usuarioId: 'user123',
        nome: 'Teste',
        tipo: 'corrente',
        saldoInicial: 1000.0,
        saldo: 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final contaCopy = conta.copyWith(nome: 'Novo Nome', saldo: 2000.0);

      expect(contaCopy.id, '123');
      expect(contaCopy.nome, 'Novo Nome');
      expect(contaCopy.saldo, 2000.0);
      expect(contaCopy.saldoInicial, 1000.0); // Não alterado
    });
  });

  // Removido grupo de testes para métodos privados que não existem mais
}