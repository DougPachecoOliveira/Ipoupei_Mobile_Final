// ✅ Validation Utils - iPoupei Mobile
// 
// Utilitários para validação de dados do sistema
// Valida campos idênticos ao React/Supabase
// 
// Baseado em: Validation Pattern + Business Rules

import 'dart:developer';

class ValidationUtils {
  
  /// 📧 VALIDAR EMAIL
  static String? validarEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email é obrigatório';
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Email inválido';
    }

    return null;
  }

  /// 🔒 VALIDAR SENHA
  static String? validarSenha(String? senha) {
    if (senha == null || senha.isEmpty) {
      return 'Senha é obrigatória';
    }

    if (senha.length < 8) {
      return 'Senha deve ter pelo menos 8 caracteres';
    }

    return null;
  }

  /// 👤 VALIDAR NOME
  static String? validarNome(String? nome) {
    if (nome == null || nome.trim().isEmpty) {
      return 'Nome é obrigatório';
    }

    if (nome.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }

    if (nome.trim().length > 100) {
      return 'Nome deve ter no máximo 100 caracteres';
    }

    return null;
  }

  /// 💰 VALIDAR VALOR MONETÁRIO
  static String? validarValorMonetario(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Valor é obrigatório';
    }

    // Remove formatação de moeda
    String valorLimpo = valor
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    final valorNumerico = double.tryParse(valorLimpo);
    if (valorNumerico == null) {
      return 'Valor inválido';
    }

    if (valorNumerico < 0) {
      return 'Valor não pode ser negativo';
    }

    if (valorNumerico > 999999999.99) {
      return 'Valor muito alto';
    }

    return null;
  }

  /// 💰 VALIDAR VALOR MONETÁRIO OBRIGATÓRIO POSITIVO
  static String? validarValorMonetarioPositivo(String? valor) {
    final erro = validarValorMonetario(valor);
    if (erro != null) return erro;

    String valorLimpo = valor!
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    final valorNumerico = double.parse(valorLimpo);
    if (valorNumerico <= 0) {
      return 'Valor deve ser maior que zero';
    }

    return null;
  }

  /// 📅 VALIDAR DATA
  static String? validarData(String? data) {
    if (data == null || data.trim().isEmpty) {
      return 'Data é obrigatória';
    }

    try {
      final dataParseada = DateTime.parse(data);
      
      // Não pode ser muito no futuro (1 ano)
      final umAnoFuturo = DateTime.now().add(const Duration(days: 365));
      if (dataParseada.isAfter(umAnoFuturo)) {
        return 'Data não pode ser mais de 1 ano no futuro';
      }

      // Não pode ser muito no passado (10 anos)
      final dezAnosPassado = DateTime.now().subtract(const Duration(days: 3650));
      if (dataParseada.isBefore(dezAnosPassado)) {
        return 'Data não pode ser mais de 10 anos no passado';
      }

      return null;
    } catch (e) {
      return 'Data inválida';
    }
  }

  /// 📱 VALIDAR TELEFONE
  static String? validarTelefone(String? telefone) {
    if (telefone == null || telefone.trim().isEmpty) {
      return null; // Telefone é opcional
    }

    // Remove formatação
    String telefoneLimpo = telefone
        .replaceAll(RegExp(r'[^\d]'), '');

    if (telefoneLimpo.length < 10 || telefoneLimpo.length > 11) {
      return 'Telefone deve ter 10 ou 11 dígitos';
    }

    return null;
  }

  /// 🏦 VALIDAR NOME DE CONTA
  static String? validarNomeConta(String? nome) {
    if (nome == null || nome.trim().isEmpty) {
      return 'Nome da conta é obrigatório';
    }

    if (nome.trim().length < 3) {
      return 'Nome deve ter pelo menos 3 caracteres';
    }

    if (nome.trim().length > 50) {
      return 'Nome deve ter no máximo 50 caracteres';
    }

    return null;
  }

  /// 📂 VALIDAR NOME DE CATEGORIA
  static String? validarNomeCategoria(String? nome) {
    if (nome == null || nome.trim().isEmpty) {
      return 'Nome da categoria é obrigatório';
    }

    if (nome.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }

    if (nome.trim().length > 30) {
      return 'Nome deve ter no máximo 30 caracteres';
    }

    return null;
  }

  /// 📝 VALIDAR DESCRIÇÃO
  static String? validarDescricao(String? descricao) {
    if (descricao == null || descricao.trim().isEmpty) {
      return 'Descrição é obrigatória';
    }

    if (descricao.trim().length < 3) {
      return 'Descrição deve ter pelo menos 3 caracteres';
    }

    if (descricao.trim().length > 100) {
      return 'Descrição deve ter no máximo 100 caracteres';
    }

    return null;
  }

  /// 💳 VALIDAR TIPO CONTA
  static String? validarTipoConta(String? tipo) {
    if (tipo == null || tipo.trim().isEmpty) {
      return 'Tipo de conta é obrigatório';
    }

    const tiposValidos = [
      'conta_corrente',
      'conta_poupanca',
      'carteira',
      'investimento',
      'outros'
    ];

    if (!tiposValidos.contains(tipo)) {
      return 'Tipo de conta inválido';
    }

    return null;
  }

  /// 📊 VALIDAR TIPO TRANSAÇÃO
  static String? validarTipoTransacao(String? tipo) {
    if (tipo == null || tipo.trim().isEmpty) {
      return 'Tipo de transação é obrigatório';
    }

    const tiposValidos = [
      'receita',
      'despesa',
      'transferencia'
    ];

    if (!tiposValidos.contains(tipo)) {
      return 'Tipo de transação inválido';
    }

    return null;
  }

  /// 🎨 VALIDAR COR HEX
  static String? validarCorHex(String? cor) {
    if (cor == null || cor.trim().isEmpty) {
      return null; // Cor é opcional
    }

    final corRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');
    if (!corRegex.hasMatch(cor)) {
      return 'Cor deve estar no formato #RRGGBB';
    }

    return null;
  }

  /// 🆔 VALIDAR UUID
  static String? validarUUID(String? uuid) {
    if (uuid == null || uuid.trim().isEmpty) {
      return 'ID é obrigatório';
    }

    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );

    if (!uuidRegex.hasMatch(uuid)) {
      return 'ID inválido';
    }

    return null;
  }

  /// 📊 VALIDAR PERCENTUAL
  static String? validarPercentual(String? percentual) {
    if (percentual == null || percentual.trim().isEmpty) {
      return 'Percentual é obrigatório';
    }

    String percentualLimpo = percentual
        .replaceAll('%', '')
        .replaceAll(',', '.')
        .trim();

    final valor = double.tryParse(percentualLimpo);
    if (valor == null) {
      return 'Percentual inválido';
    }

    if (valor < 0 || valor > 100) {
      return 'Percentual deve estar entre 0% e 100%';
    }

    return null;
  }

  /// 🔢 VALIDAR NÚMERO INTEIRO
  static String? validarInteiro(String? numero, {int? min, int? max}) {
    if (numero == null || numero.trim().isEmpty) {
      return 'Número é obrigatório';
    }

    final valor = int.tryParse(numero.trim());
    if (valor == null) {
      return 'Número inválido';
    }

    if (min != null && valor < min) {
      return 'Valor deve ser pelo menos $min';
    }

    if (max != null && valor > max) {
      return 'Valor deve ser no máximo $max';
    }

    return null;
  }

  /// 📝 VALIDAR OBSERVAÇÕES (OPCIONAL)
  static String? validarObservacoes(String? observacoes) {
    if (observacoes == null || observacoes.trim().isEmpty) {
      return null; // Observações são opcionais
    }

    if (observacoes.trim().length > 500) {
      return 'Observações devem ter no máximo 500 caracteres';
    }

    return null;
  }

  /// 🏪 VALIDAR BANCO
  static String? validarBanco(String? banco) {
    if (banco == null || banco.trim().isEmpty) {
      return null; // Banco é opcional
    }

    if (banco.trim().length > 50) {
      return 'Nome do banco deve ter no máximo 50 caracteres';
    }

    return null;
  }

  /// 💼 VALIDAR PROFISSÃO
  static String? validarProfissao(String? profissao) {
    if (profissao == null || profissao.trim().isEmpty) {
      return null; // Profissão é opcional
    }

    if (profissao.trim().length > 100) {
      return 'Profissão deve ter no máximo 100 caracteres';
    }

    return null;
  }

  /// 🎯 VALIDAR MÚLTIPLOS CAMPOS
  static Map<String, String> validarFormulario(Map<String, dynamic> campos) {
    final erros = <String, String>{};

    campos.forEach((campo, valor) {
      String? erro;
      
      switch (campo) {
        case 'email':
          erro = validarEmail(valor);
          break;
        case 'senha':
          erro = validarSenha(valor);
          break;
        case 'nome':
          erro = validarNome(valor);
          break;
        case 'valor':
          erro = validarValorMonetario(valor);
          break;
        case 'valorPositivo':
          erro = validarValorMonetarioPositivo(valor);
          break;
        case 'data':
          erro = validarData(valor);
          break;
        case 'telefone':
          erro = validarTelefone(valor);
          break;
        case 'nomeConta':
          erro = validarNomeConta(valor);
          break;
        case 'nomeCategoria':
          erro = validarNomeCategoria(valor);
          break;
        case 'descricao':
          erro = validarDescricao(valor);
          break;
        case 'tipoConta':
          erro = validarTipoConta(valor);
          break;
        case 'tipoTransacao':
          erro = validarTipoTransacao(valor);
          break;
        case 'cor':
          erro = validarCorHex(valor);
          break;
        case 'uuid':
          erro = validarUUID(valor);
          break;
        default:
          log('⚠️ Campo de validação não reconhecido: $campo');
      }

      if (erro != null) {
        erros[campo] = erro;
      }
    });

    return erros;
  }

  /// 🔍 SANITIZAR STRING
  static String sanitizarString(String? input) {
    if (input == null) return '';
    
    return input
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Remove espaços extras
        .replaceAll(RegExp(r'[<>]'), ''); // Remove caracteres perigosos
  }

  /// 💰 CONVERTER VALOR MONETÁRIO PARA DOUBLE
  static double converterValorMonetario(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 0.0;
    
    try {
      String valorLimpo = valor
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      
      return double.parse(valorLimpo);
    } catch (e) {
      log('❌ Erro ao converter valor monetário: $valor');
      return 0.0;
    }
  }

  /// 📊 VALIDAR SE É CAMPO OBRIGATÓRIO
  static bool isCampoObrigatorio(String campo) {
    const camposObrigatorios = [
      'email',
      'senha', 
      'nome',
      'valor',
      'valorPositivo',
      'data',
      'nomeConta',
      'nomeCategoria',
      'descricao',
      'tipoConta',
      'tipoTransacao',
      'uuid'
    ];
    
    return camposObrigatorios.contains(campo);
  }
}