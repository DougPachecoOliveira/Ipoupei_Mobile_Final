// 🧭 Navigation Context Service - iPoupei Mobile
//
// Serviço para gerenciar contexto de navegação entre páginas
// Permite manter estado de filtros e seleções para UX contextual
//
// Features:
// - Conta/cartão selecionado
// - Filtros aplicados
// - Estado de navegação

import 'package:flutter/foundation.dart';

/// Serviço singleton para gerenciar contexto de navegação
class NavigationContextService extends ChangeNotifier {
  static NavigationContextService? _instance;
  static NavigationContextService get instance => _instance ??= NavigationContextService._();
  NavigationContextService._();

  // Estado do contexto atual
  String? _contaSelecionadaId;
  String? _cartaoSelecionadoId;
  String? _categoriaSelecionadaId;
  Map<String, dynamic> _filtrosAtivos = {};
  DateTime? _mesSelecionado;
  String? _tipoTransacaoSelecionado; // 'receitas' ou 'despesas'

  // Getters
  String? get contaSelecionadaId => _contaSelecionadaId;
  String? get cartaoSelecionadoId => _cartaoSelecionadoId;
  String? get categoriaSelecionadaId => _categoriaSelecionadaId;
  Map<String, dynamic> get filtrosAtivos => Map.from(_filtrosAtivos);
  DateTime? get mesSelecionado => _mesSelecionado;
  String? get tipoTransacaoSelecionado => _tipoTransacaoSelecionado;

  /// Define conta selecionada
  void setContaSelecionada(String? contaId) {
    if (_contaSelecionadaId != contaId) {
      _contaSelecionadaId = contaId;
      _cartaoSelecionadoId = null; // Limpa cartão ao trocar conta
      _categoriaSelecionadaId = null; // Limpa categoria ao trocar conta
      _tipoTransacaoSelecionado = null; // Limpa tipo ao trocar conta
      debugPrint('🧭 Conta selecionada: $contaId');
      notifyListeners();
    }
  }

  /// Define cartão selecionado
  void setCartaoSelecionado(String? cartaoId) {
    if (_cartaoSelecionadoId != cartaoId) {
      _cartaoSelecionadoId = cartaoId;
      _contaSelecionadaId = null; // Limpa conta ao trocar cartão
      _categoriaSelecionadaId = null; // Limpa categoria ao trocar cartão
      _tipoTransacaoSelecionado = null; // Limpa tipo ao trocar cartão
      debugPrint('🧭 Cartão selecionado: $cartaoId');
      notifyListeners();
    }
  }

  /// Define categoria selecionada
  void setCategoriaSelecionada(String? categoriaId) {
    if (_categoriaSelecionadaId != categoriaId) {
      _categoriaSelecionadaId = categoriaId;
      _contaSelecionadaId = null; // Limpa conta ao trocar categoria
      _cartaoSelecionadoId = null; // Limpa cartão ao trocar categoria
      _tipoTransacaoSelecionado = null; // Limpa tipo ao trocar categoria
      debugPrint('🧭 Categoria selecionada: $categoriaId');
      notifyListeners();
    }
  }

  /// Define mês selecionado
  void setMesSelecionado(DateTime? mes) {
    if (_mesSelecionado != mes) {
      _mesSelecionado = mes;
      debugPrint('🧭 Mês selecionado: ${mes?.month}/${mes?.year}');
      notifyListeners();
    }
  }

  /// Define contexto para receitas
  void setContextoReceitas() {
    _contaSelecionadaId = null;
    _cartaoSelecionadoId = null;
    _categoriaSelecionadaId = null;
    _tipoTransacaoSelecionado = 'receitas';
    debugPrint('🧭 Contexto definido para RECEITAS');
    notifyListeners();
  }

  /// Define contexto para despesas
  void setContextoDespesas() {
    _contaSelecionadaId = null;
    _cartaoSelecionadoId = null;
    _categoriaSelecionadaId = null;
    _tipoTransacaoSelecionado = 'despesas';
    debugPrint('🧭 Contexto definido para DESPESAS');
    notifyListeners();
  }

  /// Atualiza filtros ativos
  void setFiltrosAtivos(Map<String, dynamic> filtros) {
    _filtrosAtivos = Map.from(filtros);
    debugPrint('🧭 Filtros atualizados: $_filtrosAtivos');
    notifyListeners();
  }

  /// Adiciona um filtro específico
  void adicionarFiltro(String chave, dynamic valor) {
    _filtrosAtivos[chave] = valor;
    debugPrint('🧭 Filtro adicionado: $chave = $valor');
    notifyListeners();
  }

  /// Remove um filtro específico
  void removerFiltro(String chave) {
    _filtrosAtivos.remove(chave);
    debugPrint('🧭 Filtro removido: $chave');
    notifyListeners();
  }

  /// Gera filtros para TransacoesPage baseado no contexto atual
  Map<String, dynamic> getFiltrosParaTransacoes() {
    final filtros = <String, dynamic>{};

    // Adiciona conta, cartão ou categoria ao filtro
    if (_contaSelecionadaId != null) {
      filtros['conta_id'] = _contaSelecionadaId;
      debugPrint('🧭 Filtro por conta: $_contaSelecionadaId');
    } else if (_cartaoSelecionadoId != null) {
      filtros['cartao_id'] = _cartaoSelecionadoId;
      debugPrint('🧭 Filtro por cartão: $_cartaoSelecionadoId');
    } else if (_categoriaSelecionadaId != null) {
      filtros['categoria_id'] = _categoriaSelecionadaId;
      debugPrint('🧭 Filtro por categoria: $_categoriaSelecionadaId');
    }

    // Adiciona mês se selecionado
    if (_mesSelecionado != null) {
      filtros['mes'] = _mesSelecionado!.month;
      filtros['ano'] = _mesSelecionado!.year;
      debugPrint('🧭 Filtro por período: ${_mesSelecionado!.month}/${_mesSelecionado!.year}');
    }

    // Combina com filtros ativos
    filtros.addAll(_filtrosAtivos);

    return filtros;
  }

  /// Verifica se deve usar modo contextual
  bool get deveUsarModoContextual {
    return _cartaoSelecionadoId != null;
  }

  /// Verifica se deve usar modo receitas
  bool get deveUsarModoReceitas {
    return _tipoTransacaoSelecionado == 'receitas';
  }

  /// Verifica se deve usar modo despesas
  bool get deveUsarModoDespesas {
    return _tipoTransacaoSelecionado == 'despesas';
  }

  /// Limpa todo o contexto
  void limparContexto() {
    _contaSelecionadaId = null;
    _cartaoSelecionadoId = null;
    _categoriaSelecionadaId = null;
    _mesSelecionado = null;
    _tipoTransacaoSelecionado = null;
    _filtrosAtivos.clear();
    debugPrint('🧹 Contexto de navegação limpo');
    notifyListeners();
  }

  /// Verifica se há contexto ativo
  bool get hasContextoAtivo {
    return _contaSelecionadaId != null ||
           _cartaoSelecionadoId != null ||
           _categoriaSelecionadaId != null ||
           _mesSelecionado != null ||
           _tipoTransacaoSelecionado != null ||
           _filtrosAtivos.isNotEmpty;
  }

  /// Gera título contextual para páginas
  String getTituloContextual() {
    if (_contaSelecionadaId != null) {
      return 'Transações da Conta';
    } else if (_cartaoSelecionadoId != null) {
      return 'Transações do Cartão';
    } else if (_categoriaSelecionadaId != null) {
      return 'Transações da Categoria';
    } else if (_tipoTransacaoSelecionado == 'receitas') {
      return 'Receitas';
    } else if (_tipoTransacaoSelecionado == 'despesas') {
      return 'Despesas';
    } else if (_mesSelecionado != null) {
      return 'Transações de ${_mesSelecionado!.month}/${_mesSelecionado!.year}';
    }
    return 'Todas as Transações';
  }

  @override
  String toString() {
    return 'NavigationContext{conta: $_contaSelecionadaId, cartao: $_cartaoSelecionadoId, categoria: $_categoriaSelecionadaId, tipo: $_tipoTransacaoSelecionado, mes: $_mesSelecionado, filtros: $_filtrosAtivos}';
  }
}

/// Instância global para facilitar acesso
final navigationContext = NavigationContextService.instance;