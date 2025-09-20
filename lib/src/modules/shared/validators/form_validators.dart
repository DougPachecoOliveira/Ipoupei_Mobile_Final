// ✅ Form Validators - iPoupei Mobile
// 
// Validadores específicos para formulários do app
// Baseado no sistema React/Supabase idêntico
// 
// Baseado em: Form Validation Pattern

import '../../../utils/validation_utils.dart';

class FormValidators {
  
  /// 🏦 VALIDADOR PARA FORMULÁRIO DE CONTA
  static Map<String, String> validarFormularioConta({
    required String nome,
    required String tipo,
    String? banco,
    String? saldoInicial,
    String? cor,
  }) {
    return ValidationUtils.validarFormulario({
      'nomeConta': nome,
      'tipoConta': tipo,
      'banco': banco,
      'valorPositivo': saldoInicial,
      'cor': cor,
    });
  }

  /// 💳 VALIDADOR PARA FORMULÁRIO DE TRANSAÇÃO
  static Map<String, String> validarFormularioTransacao({
    required String descricao,
    required String valor,
    required String data,
    required String tipo,
    String? contaId,
    String? categoriaId,
    String? observacoes,
  }) {
    final erros = ValidationUtils.validarFormulario({
      'descricao': descricao,
      'valorPositivo': valor,
      'data': data,
      'tipoTransacao': tipo,
      'observacoes': observacoes,
    });

    // Validações específicas para transação
    if (contaId == null || contaId.isEmpty) {
      erros['conta'] = 'Conta é obrigatória';
    }

    if ((tipo == 'receita' || tipo == 'despesa') && 
        (categoriaId == null || categoriaId.isEmpty)) {
      erros['categoria'] = 'Categoria é obrigatória';
    }

    return erros;
  }

  /// 📂 VALIDADOR PARA FORMULÁRIO DE CATEGORIA
  static Map<String, String> validarFormularioCategoria({
    required String nome,
    required String tipo,
    String? cor,
    String? icone,
    String? descricao,
  }) {
    final erros = ValidationUtils.validarFormulario({
      'nomeCategoria': nome,
      'tipoTransacao': tipo,
      'cor': cor,
    });

    // Validação específica para tipo de categoria
    if (tipo != 'receita' && tipo != 'despesa') {
      erros['tipo'] = 'Tipo deve ser "receita" ou "despesa"';
    }

    return erros;
  }

  /// 📋 VALIDADOR PARA FORMULÁRIO DE SUBCATEGORIA
  static Map<String, String> validarFormularioSubcategoria({
    required String nome,
    required String categoriaId,
    String? cor,
    String? icone,
  }) {
    final erros = ValidationUtils.validarFormulario({
      'nomeCategoria': nome,
      'uuid': categoriaId,
      'cor': cor,
    });

    return erros;
  }

  /// 🔄 VALIDADOR PARA FORMULÁRIO DE TRANSFERÊNCIA
  static Map<String, String> validarFormularioTransferencia({
    required String valor,
    required String data,
    required String contaOrigemId,
    required String contaDestinoId,
    required String descricao,
    String? observacoes,
  }) {
    final erros = ValidationUtils.validarFormulario({
      'valorPositivo': valor,
      'data': data,
      'descricao': descricao,
      'observacoes': observacoes,
    });

    // Validações específicas para transferência
    if (contaOrigemId.isEmpty) {
      erros['contaOrigem'] = 'Conta de origem é obrigatória';
    }

    if (contaDestinoId.isEmpty) {
      erros['contaDestino'] = 'Conta de destino é obrigatória';
    }

    if (contaOrigemId == contaDestinoId) {
      erros['contas'] = 'Contas de origem e destino devem ser diferentes';
    }

    final valorNumerico = ValidationUtils.converterValorMonetario(valor);
    if (valorNumerico <= 0) {
      erros['valor'] = 'Valor da transferência deve ser maior que zero';
    }

    return erros;
  }

  /// 👤 VALIDADOR PARA FORMULÁRIO DE PERFIL
  static Map<String, String> validarFormularioPerfil({
    required String nome,
    required String email,
    String? telefone,
    String? profissao,
  }) {
    return ValidationUtils.validarFormulario({
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'profissao': profissao,
    });
  }

  /// 🔒 VALIDADOR PARA FORMULÁRIO DE LOGIN
  static Map<String, String> validarFormularioLogin({
    required String email,
    required String senha,
  }) {
    return ValidationUtils.validarFormulario({
      'email': email,
      'senha': senha,
    });
  }

  /// 📝 VALIDADOR PARA FORMULÁRIO DE REGISTRO
  static Map<String, String> validarFormularioRegistro({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) {
    final erros = ValidationUtils.validarFormulario({
      'nome': nome,
      'email': email,
      'senha': senha,
    });

    // Validar confirmação de senha
    if (senha != confirmarSenha) {
      erros['confirmarSenha'] = 'Senhas não coincidem';
    }

    return erros;
  }

  /// 💰 VALIDADOR PARA CORREÇÃO DE SALDO
  static Map<String, String> validarCorrecaoSaldo({
    required String novoSaldo,
    required String motivo,
  }) {
    final erros = ValidationUtils.validarFormulario({
      'valor': novoSaldo,
      'descricao': motivo,
    });

    return erros;
  }

  /// 🎯 HELPER - VERIFICAR SE FORMULÁRIO É VÁLIDO
  static bool isFormularioValido(Map<String, String> erros) {
    return erros.isEmpty;
  }

  /// 🎯 HELPER - OBTER PRIMEIRO ERRO
  static String? obterPrimeiroErro(Map<String, String> erros) {
    return erros.isNotEmpty ? erros.values.first : null;
  }

  /// 🎯 HELPER - OBTER TODOS OS ERROS COMO STRING
  static String obterTodosErros(Map<String, String> erros) {
    return erros.values.join('\n');
  }
}