// lib/src/modules/transacoes/services/transacao_edit_service.dart

import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/transacao_model.dart';
import '../../../database/local_database.dart';
import '../../../sync/connectivity_helper.dart';
import '../../../sync/sync_manager.dart';
import '../../../services/grupos_metadados_service.dart';

/// Escopo de edição para transações
enum EscopoEdicao {
  apenasEsta('Apenas esta transação'),
  estasEFuturas('Esta e futuras transações'),
  todasRelacionadas('Todas as transações relacionadas');

  const EscopoEdicao(this.descricao);
  final String descricao;
}

/// Resultado de uma operação de edição
class ResultadoEdicao<T> {
  final bool sucesso;
  final T? dados;
  final String? mensagem;
  final String? erro;

  ResultadoEdicao({
    required this.sucesso,
    this.dados,
    this.mensagem,
    this.erro,
  });

  factory ResultadoEdicao.sucesso({T? dados, String? mensagem}) {
    return ResultadoEdicao(
      sucesso: true,
      dados: dados,
      mensagem: mensagem,
    );
  }

  factory ResultadoEdicao.erro(String erro) {
    return ResultadoEdicao(
      sucesso: false,
      erro: erro,
    );
  }
}

/// Serviço para operações de edição de transações
/// Funciona para todos os tipos: receita, despesa, transferência
class TransacaoEditService {
  static TransacaoEditService? _instance;
  static TransacaoEditService get instance {
    _instance ??= TransacaoEditService._internal();
    return _instance!;
  }
  
  TransacaoEditService._internal();

  final _supabase = Supabase.instance.client;

  // ===== EFETIVAR TRANSAÇÃO =====
  
  /// Efetiva uma transação (marca como efetivada)
  /// ⚠️ O trigger do banco atualiza os saldos automaticamente
  Future<ResultadoEdicao<bool>> efetivar(
    TransacaoModel transacao, {
    bool incluirFuturas = false,
  }) async {
    try {
      if (transacao.efetivado) {
        return ResultadoEdicao.erro('Transação já está efetivada');
      }

      // ❌ CARTÕES NÃO PODEM SER EFETIVADOS INDIVIDUALMENTE
      if (transacao.cartaoId != null) {
        return ResultadoEdicao.erro('Despesas de cartão não podem ser efetivadas individualmente. Elas são efetivadas quando a fatura é paga.');
      }

      // Efetivar apenas esta transação
      if (!incluirFuturas || (transacao.grupoRecorrencia == null && transacao.grupoParcelamento == null)) {
        await _updateTransacao(transacao.id!, {
          'efetivado': true,
          'data_efetivacao': DateTime.now().toIso8601String(),
        });

        return ResultadoEdicao.sucesso(
          mensagem: 'Transação efetivada com sucesso',
        );
      }

      // Efetivar esta + futuras
      final transacoesFuturas = await _buscarTransacoesFuturas(transacao);
      int efetivadas = 0;
      
      for (final t in transacoesFuturas) {
        if (!t.efetivado) {
          await _updateTransacao(t.id!, {
            'efetivado': true,
            'data_efetivacao': DateTime.now().toIso8601String(),
          });
          efetivadas++;
        }
      }

      return ResultadoEdicao.sucesso(
        mensagem: '$efetivadas transações efetivadas',
      );
    } catch (e) {
      log('❌ Erro ao efetivar transação: $e');
      return ResultadoEdicao.erro('Erro ao efetivar transação: $e');
    }
  }

  // ===== DESEFETIVAR TRANSAÇÃO =====
  
  /// Marca transação como pendente (não efetivada)
  /// ⚠️ O trigger do banco atualiza os saldos automaticamente
  Future<ResultadoEdicao<bool>> desefetivar(
    TransacaoModel transacao, {
    bool incluirFuturas = false,
  }) async {
    try {
      if (!transacao.efetivado) {
        return ResultadoEdicao.erro('Transação já está pendente');
      }

      // ❌ CARTÕES EFETIVADOS NÃO PODEM SER DESEFETIVADOS
      if (transacao.cartaoId != null) {
        return ResultadoEdicao.erro('Despesas de cartão efetivadas não podem ser tornadas pendentes (fatura já paga)');
      }

      // Desefetivar apenas esta transação
      if (!incluirFuturas || (transacao.grupoRecorrencia == null && transacao.grupoParcelamento == null)) {
        await _updateTransacao(transacao.id!, {
          'efetivado': false,
          'data_efetivacao': null,
        });

        return ResultadoEdicao.sucesso(
          mensagem: 'Transação marcada como pendente',
        );
      }

      // Desefetivar esta + futuras
      final transacoesFuturas = await _buscarTransacoesFuturas(transacao);
      int desefetivadas = 0;
      
      for (final t in transacoesFuturas) {
        if (t.efetivado) {
          await _updateTransacao(t.id!, {
            'efetivado': false,
            'data_efetivacao': null,
          });
          desefetivadas++;
        }
      }

      return ResultadoEdicao.sucesso(
        mensagem: '$desefetivadas transações marcadas como pendentes',
      );
    } catch (e) {
      log('❌ Erro ao desefetivar transação: $e');
      return ResultadoEdicao.erro('Erro ao desefetivar transação: $e');
    }
  }

  // ===== EDITAR VALOR =====
  
  /// Edita apenas o valor de uma transação
  Future<ResultadoEdicao<bool>> editarValor(
    TransacaoModel transacao,
    double novoValor, {
    EscopoEdicao escopo = EscopoEdicao.apenasEsta,
  }) async {
    try {
      // Validações específicas para cartões
      if (transacao.cartaoId != null && transacao.efetivado) {
        return ResultadoEdicao.erro('Não é possível editar valor de despesa de cartão já efetivada (fatura paga)');
      }
      
      // Validações gerais
      if (transacao.efetivado && transacao.cartaoId == null) {
        return ResultadoEdicao.erro('Não é possível editar transação efetivada');
      }

      if (novoValor <= 0) {
        return ResultadoEdicao.erro('Valor deve ser maior que zero');
      }

      // Atualizar apenas esta transação
      if (escopo == EscopoEdicao.apenasEsta || (transacao.grupoRecorrencia == null && transacao.grupoParcelamento == null)) {
        await _updateTransacao(transacao.id!, {
          'valor': novoValor,
        });

        return ResultadoEdicao.sucesso(
          mensagem: 'Valor atualizado com sucesso',
        );
      }

      // Buscar transações baseado no escopo
      List<TransacaoModel> transacoesParaAtualizar;
      String tipoEscopo;
      
      log('🔍 [DEBUG] editarValor - buscando transações para escopo: $escopo');
      
      if (escopo == EscopoEdicao.estasEFuturas) {
        transacoesParaAtualizar = await _buscarTransacoesFuturas(transacao);
        tipoEscopo = 'futuras';
      } else { // EscopoEdicao.todasRelacionadas
        transacoesParaAtualizar = await _buscarTodasTransacoesRelacionadas(transacao);
        tipoEscopo = 'relacionadas';
      }

      final totalTransacoes = transacoesParaAtualizar.length;
      int atualizadas = 0;
      int ignoradas = 0;
      
      log('🔍 [DEBUG] editarValor - Encontradas $totalTransacoes transações para verificar');
      log('🔍 [DEBUG] INICIANDO LOOP DE ATUALIZAÇÃO DE VALOR:');
      
      for (int i = 0; i < transacoesParaAtualizar.length; i++) {
        final t = transacoesParaAtualizar[i];
        final progresso = '${i + 1} de $totalTransacoes';
        
        log('🔄 [PROGRESSO] $progresso - Processando ID: ${t.id} | Valor atual: ${t.valor}');
        
        if (!t.efetivado) {
          try {
            log('🔄 [PROGRESSO] $progresso - Atualizando valor para: $novoValor');
            await _updateTransacao(t.id!, {
              'valor': novoValor,
            }, skipAutoSync: true);
            atualizadas++;
            log('✅ [PROGRESSO] $progresso - SUCESSO! Valor atualizado');
          } catch (e) {
            log('❌ [PROGRESSO] $progresso - ERRO ao atualizar valor: $e');
          }
        } else {
          ignoradas++;
          log('⚠️ [PROGRESSO] $progresso - IGNORADA (efetivada)');
        }
      }
      
      log('🔍 [DEBUG] LOOP DE ATUALIZAÇÃO DE VALOR FINALIZADO:');
      log('   - Total processadas: $totalTransacoes');
      log('   - Atualizadas: $atualizadas');
      log('   - Ignoradas: $ignoradas');

      final mensagemFinal = '$atualizadas de $totalTransacoes valores $tipoEscopo atualizados ($ignoradas já efetivadas)';
      
      log('✅ [RESULTADO FINAL] $mensagemFinal');
      
      // 🔄 Executar sincronização em lote para todas as transações atualizadas
      if (atualizadas > 0) {
        try {
          log('🔄 [BATCH SYNC] Iniciando sincronização em lote de $atualizadas transações...');
          await SyncManager.instance.syncAll();
          log('✅ [BATCH SYNC] Sincronização em lote concluída com sucesso');
        } catch (e) {
          log('⚠️ [BATCH SYNC] Erro na sincronização em lote: $e');
          // Não falha a operação principal, apenas registra o erro
        }
      }
      
      return ResultadoEdicao.sucesso(
        mensagem: mensagemFinal,
      );
    } catch (e) {
      log('❌ Erro ao editar valor: $e');
      return ResultadoEdicao.erro('Erro ao atualizar valor: $e');
    }
  }

  // ===== APLICAR REAJUSTE =====
  
  /// Aplica reajuste percentual em transações futuras
  Future<ResultadoEdicao<int>> aplicarReajuste(
    TransacaoModel transacao,
    double percentual, {
    bool isAumento = true,
  }) async {
    try {
      if ((transacao.grupoRecorrencia == null && transacao.grupoParcelamento == null)) {
        return ResultadoEdicao.erro('Transação não faz parte de uma recorrência');
      }

      // ℹ️ INFORMAÇÃO PARA CARTÕES
      if (transacao.cartaoId != null) {
        log('⚠️ Aplicando reajuste em despesa de cartão - verifique se não afeta fechamento de faturas');
      }

      final transacoesFuturas = await _buscarTransacoesFuturas(transacao);
      int atualizadas = 0;

      for (final t in transacoesFuturas) {
        if (!t.efetivado) {
          final novoValor = isAumento
            ? t.valor * (1 + percentual / 100)
            : t.valor * (1 - percentual / 100);

          await _updateTransacao(t.id!, {
            'valor': novoValor,
          }, skipAutoSync: true);
          
          atualizadas++;
        }
      }

      // 🔄 Executar sincronização em lote para todas as transações atualizadas
      if (atualizadas > 0) {
        try {
          log('🔄 [BATCH SYNC] Iniciando sincronização em lote de $atualizadas transações...');
          await SyncManager.instance.syncAll();
          log('✅ [BATCH SYNC] Sincronização em lote concluída com sucesso');
        } catch (e) {
          log('⚠️ [BATCH SYNC] Erro na sincronização em lote: $e');
          // Não falha a operação principal, apenas registra o erro
        }
      }
      
      return ResultadoEdicao.sucesso(
        dados: atualizadas,
        mensagem: '$atualizadas transações reajustadas em ${percentual.toStringAsFixed(1)}%',
      );
    } catch (e) {
      log('❌ Erro ao aplicar reajuste: $e');
      return ResultadoEdicao.erro('Erro ao aplicar reajuste: $e');
    }
  }

  // ===== EXCLUIR TRANSAÇÕES =====
  
  /// Exclui transação(ões)
  Future<ResultadoEdicao<int>> excluir(
    TransacaoModel transacao, {
    bool incluirFuturas = false,
  }) async {
    try {
      // Validações específicas para cartões
      if (transacao.cartaoId != null && transacao.efetivado) {
        return ResultadoEdicao.erro('Não é possível excluir despesa de cartão já efetivada (fatura paga)');
      }
      
      // Validações gerais
      if (transacao.efetivado && transacao.cartaoId == null) {
        return ResultadoEdicao.erro('Não é possível excluir transação efetivada');
      }

      // Excluir apenas esta
      if (!incluirFuturas || (transacao.grupoRecorrencia == null && transacao.grupoParcelamento == null)) {
        await _deleteTransacao(transacao.id!);
        return ResultadoEdicao.sucesso(
          dados: 1,
          mensagem: 'Transação excluída com sucesso',
        );
      }

      // Excluir futuras
      final transacoesFuturas = await _buscarTransacoesFuturas(transacao);
      int excluidas = 0;

      for (final t in transacoesFuturas) {
        if (!t.efetivado) {
          await _deleteTransacao(t.id!);
          excluidas++;
        }
      }

      return ResultadoEdicao.sucesso(
        dados: excluidas,
        mensagem: '$excluidas transações excluídas',
      );
    } catch (e) {
      log('❌ Erro ao excluir: $e');
      return ResultadoEdicao.erro('Erro ao excluir transações: $e');
    }
  }

  // ===== DUPLICAR TRANSAÇÃO =====
  
  /// Duplica uma transação com nova data
  Future<ResultadoEdicao<TransacaoModel>> duplicar(
    TransacaoModel transacao, {
    DateTime? novaData,
  }) async {
    try {
      final data = novaData ?? DateTime.now();
      
      // ❌ CARTÕES: Sempre duplica apenas a transação atual (não futuras) 
      // Não faz sentido duplicar todas as futuras de cartão
      if (transacao.cartaoId != null) {
        log('💳 Despesa de cartão - duplicação sempre individual');
      }
      
      // Criar nova transação baseada na original
      final dadosNovos = {
        'usuario_id': transacao.usuarioId,
        'tipo': transacao.tipo,
        'tipo_receita': transacao.tipoReceita,
        'tipo_despesa': transacao.tipoDespesa,
        'valor': transacao.valor,
        'data': data.toIso8601String().split('T')[0],
        'descricao': '${transacao.descricao} (cópia)',
        'observacoes': transacao.observacoes,
        'categoria_id': transacao.categoriaId,
        'subcategoria_id': transacao.subcategoriaId,
        'conta_id': transacao.contaId,
        'conta_destino_id': transacao.contaDestinoId,
        'cartao_id': transacao.cartaoId,
        'efetivado': false,
        'recorrente': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('transacoes')
          .insert(dadosNovos)
          .select()
          .single();
      
      return ResultadoEdicao.sucesso(
        dados: TransacaoModel.fromJson(response),
        mensagem: 'Transação duplicada com sucesso',
      );
    } catch (e) {
      log('❌ Erro ao duplicar: $e');
      return ResultadoEdicao.erro('Erro ao duplicar transação: $e');
    }
  }

  // ===== MOVER PARA OUTRO MÊS =====
  
  /// Move transação para outro mês mantendo o dia
  Future<ResultadoEdicao<bool>> moverParaMes(
    TransacaoModel transacao,
    DateTime novoMes,
  ) async {
    try {
      if (transacao.efetivado) {
        return ResultadoEdicao.erro('Não é possível mover transação efetivada');
      }

      // ✅ CARTÕES PENDENTES: Podem ser movidos entre faturas abertas
      if (transacao.cartaoId != null && transacao.efetivado) {
        return ResultadoEdicao.erro('Despesas de cartão efetivadas não podem ser movidas (fatura já paga)');
      }
      
      // ℹ️ CARTÕES PENDENTES: Log informativo sobre movimento entre faturas
      if (transacao.cartaoId != null && !transacao.efetivado) {
        log('💳 Movendo despesa de cartão pendente para ${_nomeMes(novoMes.month)}/${novoMes.year} - próxima fatura em aberto');
      }

      final novaData = DateTime(
        novoMes.year,
        novoMes.month,
        transacao.data.day,
      );

      final ultimoDiaMes = DateTime(novoMes.year, novoMes.month + 1, 0).day;
      if (novaData.day > ultimoDiaMes) {
        return ResultadoEdicao.erro(
          'Dia ${novaData.day} não existe em ${_nomeMes(novoMes.month)}',
        );
      }

      await _updateTransacao(transacao.id!, {
        'data': novaData.toIso8601String().split('T')[0],
      });

      return ResultadoEdicao.sucesso(
        mensagem: 'Transação movida para ${_nomeMes(novoMes.month)}/${novoMes.year}',
      );
    } catch (e) {
      log('❌ Erro ao mover transação: $e');
      return ResultadoEdicao.erro('Erro ao mover transação: $e');
    }
  }

  // ===== ALTERAR CATEGORIA =====
  
  /// Altera categoria/subcategoria de transações
  Future<ResultadoEdicao<bool>> alterarCategoria(
    TransacaoModel transacao, {
    String? novaCategoriaId,
    String? novaSubcategoriaId,
    EscopoEdicao escopo = EscopoEdicao.apenasEsta,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (novaCategoriaId != null) {
        updates['categoria_id'] = novaCategoriaId;
      }

      if (novaSubcategoriaId != null) {
        updates['subcategoria_id'] = novaSubcategoriaId;
      }

      // Atualizar apenas esta transação
      if (escopo == EscopoEdicao.apenasEsta || (transacao.grupoRecorrencia == null && transacao.grupoParcelamento == null)) {
        await _updateTransacao(transacao.id!, updates);
        return ResultadoEdicao.sucesso(
          mensagem: 'Categoria atualizada',
        );
      }

      // Buscar transações baseado no escopo
      List<TransacaoModel> transacoesParaAtualizar;
      String tipoEscopo;
      
      log('🔍 [DEBUG] alterarCategoria - buscando transações para escopo: $escopo');
      
      if (escopo == EscopoEdicao.estasEFuturas) {
        transacoesParaAtualizar = await _buscarTransacoesFuturas(transacao);
        tipoEscopo = 'futuras';
      } else { // EscopoEdicao.todasRelacionadas
        transacoesParaAtualizar = await _buscarTodasTransacoesRelacionadas(transacao);
        tipoEscopo = 'relacionadas';
      }

      final totalTransacoes = transacoesParaAtualizar.length;
      int atualizadas = 0;
      int ignoradas = 0;
      
      log('🔍 [DEBUG] alterarCategoria - Encontradas $totalTransacoes transações para verificar');
      log('🔍 [DEBUG] INICIANDO LOOP DE ATUALIZAÇÃO DE CATEGORIA:');
      
      for (int i = 0; i < transacoesParaAtualizar.length; i++) {
        final t = transacoesParaAtualizar[i];
        final progresso = '${i + 1} de $totalTransacoes';
        
        log('🔄 [PROGRESSO] $progresso - Processando ID: ${t.id} | Categoria atual: ${t.categoriaId}');
        
        if (!t.efetivado || t.cartaoId != null) {
          try {
            log('🔄 [PROGRESSO] $progresso - Atualizando categoria');
            await _updateTransacao(t.id!, updates, skipAutoSync: true);
            atualizadas++;
            log('✅ [PROGRESSO] $progresso - SUCESSO! Categoria atualizada');
          } catch (e) {
            log('❌ [PROGRESSO] $progresso - ERRO ao atualizar categoria: $e');
          }
        } else {
          ignoradas++;
          log('⚠️ [PROGRESSO] $progresso - IGNORADA (efetivada e não-cartão)');
        }
      }
      
      log('🔍 [DEBUG] LOOP DE ATUALIZAÇÃO DE CATEGORIA FINALIZADO:');
      log('   - Total processadas: $totalTransacoes');
      log('   - Atualizadas: $atualizadas');
      log('   - Ignoradas: $ignoradas');

      final mensagemFinal = 'Categoria atualizada em $atualizadas de $totalTransacoes transações $tipoEscopo';
      
      log('✅ [RESULTADO FINAL] $mensagemFinal');
      
      // 🔄 Executar sincronização em lote para todas as transações atualizadas
      if (atualizadas > 0) {
        try {
          log('🔄 [BATCH SYNC] Iniciando sincronização em lote de $atualizadas transações...');
          await SyncManager.instance.syncAll();
          log('✅ [BATCH SYNC] Sincronização em lote concluída com sucesso');
        } catch (e) {
          log('⚠️ [BATCH SYNC] Erro na sincronização em lote: $e');
          // Não falha a operação principal, apenas registra o erro
        }
      }
      
      return ResultadoEdicao.sucesso(
        mensagem: mensagemFinal,
      );
    } catch (e) {
      log('❌ Erro ao alterar categoria: $e');
      return ResultadoEdicao.erro('Erro ao alterar categoria: $e');
    }
  }

  // ===== EDITAR CARTÃO EFETIVADO =====
  
  /// Edita apenas campos permitidos em cartões efetivados
  /// (descrição, categoria, subcategoria, observações)
  Future<ResultadoEdicao<bool>> editarCartaoEfetivado(
    TransacaoModel transacao, {
    String? novaDescricao,
    String? novaCategoriaId,
    String? novaSubcategoriaId,
    String? novasObservacoes,
  }) async {
    try {
      // Validar se é cartão efetivado
      if (transacao.cartaoId == null) {
        return ResultadoEdicao.erro('Esta operação é apenas para despesas de cartão');
      }

      if (!transacao.efetivado) {
        return ResultadoEdicao.erro('Cartão não está efetivado. Use os métodos de edição normal');
      }

      final updates = <String, dynamic>{};

      if (novaDescricao != null) {
        updates['descricao'] = novaDescricao;
      }

      if (novaCategoriaId != null) {
        updates['categoria_id'] = novaCategoriaId;
      }

      if (novaSubcategoriaId != null) {
        updates['subcategoria_id'] = novaSubcategoriaId;
      }

      if (novasObservacoes != null) {
        updates['observacoes'] = novasObservacoes;
      }

      if (updates.isEmpty) {
        return ResultadoEdicao.erro('Nenhum campo para atualizar');
      }

      await _updateTransacao(transacao.id!, updates);

      return ResultadoEdicao.sucesso(
        mensagem: 'Cartão efetivado atualizado com sucesso',
      );
    } catch (e) {
      log('❌ Erro ao editar cartão efetivado: $e');
      return ResultadoEdicao.erro('Erro ao editar cartão efetivado: $e');
    }
  }

  // ===== EDITAR DESCRIÇÃO =====
  
  /// Edita descrição de transações com suporte a escopo
  Future<ResultadoEdicao<bool>> editarDescricao(
    TransacaoModel transacao, {
    required String novaDescricao,
    EscopoEdicao escopo = EscopoEdicao.apenasEsta,
  }) async {
    try {
      print('🚨🚨🚨 [TESTE] editarDescricao CHAMADO - escopo: $escopo');
      print('🚨🚨🚨 [TESTE] transacao.id: ${transacao.id}');
      print('🚨🚨🚨 [TESTE] grupoRecorrencia: ${transacao.grupoRecorrencia}');
      print('🚨🚨🚨 [TESTE] grupoParcelamento: ${transacao.grupoParcelamento}');
      log('🔍 [DEBUG] editarDescricao chamado - escopo: $escopo');
      
      if (novaDescricao.trim().isEmpty) {
        return ResultadoEdicao.erro('Descrição não pode estar vazia');
      }

      // Validar se transação efetivada (apenas cartões efetivados podem ser editados)
      if (transacao.efetivado && transacao.cartaoId == null) {
        return ResultadoEdicao.erro('Não é possível editar descrição de transação efetivada');
      }

      final updates = {
        'descricao': novaDescricao.trim(),
      };

      // Debug detalhado da condição
      print('🚨🚨🚨 [TESTE] ANALISANDO CONDIÇÃO:');
      print('🚨🚨🚨 [TESTE] escopo == EscopoEdicao.apenasEsta: ${escopo == EscopoEdicao.apenasEsta}');
      print('🚨🚨🚨 [TESTE] transacao.grupoRecorrencia == null: ${transacao.grupoRecorrencia == null}');
      print('🚨🚨🚨 [TESTE] transacao.grupoParcelamento == null: ${transacao.grupoParcelamento == null}');
      final condicaoGrupos = (transacao.grupoRecorrencia == null && transacao.grupoParcelamento == null);
      print('🚨🚨🚨 [TESTE] condicaoGrupos: $condicaoGrupos');
      final condicaoFinal = escopo == EscopoEdicao.apenasEsta || condicaoGrupos;
      print('🚨🚨🚨 [TESTE] condicaoFinal (vai entrar no apenas esta?): $condicaoFinal');

      // Atualizar apenas esta transação
      if (escopo == EscopoEdicao.apenasEsta || (transacao.grupoRecorrencia == null && transacao.grupoParcelamento == null)) {
        print('🚨🚨🚨 [TESTE] ✅ ENTROU NO APENAS ESTA - escopo: $escopo');
        log('🔍 [DEBUG] Atualizando apenas esta transação');
        await _updateTransacao(transacao.id!, updates);
        return ResultadoEdicao.sucesso(
          mensagem: 'Descrição atualizada',
        );
      }

      print('🚨🚨🚨 [TESTE] ✅ NÃO ENTROU NO APENAS ESTA - continuando para lógica de grupos');

      // Buscar transações baseado no escopo
      List<TransacaoModel> transacoesParaAtualizar;
      String tipoEscopo;
      
      print('🚨🚨🚨 [TESTE] INICIANDO BUSCA DE TRANSAÇÕES RELACIONADAS');
      
      if (escopo == EscopoEdicao.estasEFuturas) {
        print('🚨🚨🚨 [TESTE] ✅ ESCOPO: estasEFuturas');
        log('🔍 [DEBUG] Buscando esta e futuras transações');
        transacoesParaAtualizar = await _buscarTransacoesFuturas(transacao);
        tipoEscopo = 'futuras';
      } else { // EscopoEdicao.todasRelacionadas
        print('🚨🚨🚨 [TESTE] ✅ ESCOPO: todasRelacionadas');
        log('🔍 [DEBUG] Buscando todas as transações relacionadas');
        transacoesParaAtualizar = await _buscarTodasTransacoesRelacionadas(transacao);
        tipoEscopo = 'relacionadas';
      }
      
      print('🚨🚨🚨 [TESTE] TRANSAÇÕES ENCONTRADAS: ${transacoesParaAtualizar.length}');

      final totalTransacoes = transacoesParaAtualizar.length;
      int atualizadas = 0;
      int ignoradas = 0;
      
      log('🔍 [DEBUG] Encontradas $totalTransacoes transações para verificar e atualizar');
      log('🔍 [DEBUG] INICIANDO LOOP DE ATUALIZAÇÃO:');
      
      for (int i = 0; i < transacoesParaAtualizar.length; i++) {
        final t = transacoesParaAtualizar[i];
        final progresso = '${i + 1} de $totalTransacoes';
        
        log('🔄 [PROGRESSO] $progresso - Processando ID: ${t.id} | Descrição: "${t.descricao}"');
        
        if (!t.efetivado || t.cartaoId != null) {
          try {
            log('🔄 [PROGRESSO] $progresso - Atualizando descrição para: "$novaDescricao"');
            await _updateTransacao(t.id!, updates, skipAutoSync: true);
            atualizadas++;
            log('✅ [PROGRESSO] $progresso - SUCESSO! Descrição atualizada');
          } catch (e) {
            log('❌ [PROGRESSO] $progresso - ERRO ao atualizar: $e');
            // Continua o loop mesmo com erro
          }
        } else {
          ignoradas++;
          log('⚠️ [PROGRESSO] $progresso - IGNORADA (efetivada e não-cartão)');
        }
      }
      
      log('🔍 [DEBUG] LOOP DE ATUALIZAÇÃO FINALIZADO:');
      log('   - Total processadas: $totalTransacoes');
      log('   - Atualizadas: $atualizadas');
      log('   - Ignoradas: $ignoradas');

      final mensagemFinal = atualizadas > 0 
        ? '$atualizadas de $totalTransacoes descrições $tipoEscopo atualizadas'
        : 'Nenhuma transação foi atualizada (todas efetivadas ou erro)';
      
      log('✅ [RESULTADO FINAL] $mensagemFinal');
      
      // 🔄 Executar sincronização em lote para todas as transações atualizadas
      if (atualizadas > 0) {
        try {
          log('🔄 [BATCH SYNC] Iniciando sincronização em lote de $atualizadas transações...');
          await SyncManager.instance.syncAll();
          log('✅ [BATCH SYNC] Sincronização em lote concluída com sucesso');
        } catch (e) {
          log('⚠️ [BATCH SYNC] Erro na sincronização em lote: $e');
          // Não falha a operação principal, apenas registra o erro
        }
      }
      
      return ResultadoEdicao.sucesso(
        mensagem: mensagemFinal,
      );
    } catch (e) {
      log('❌ Erro ao editar descrição: $e');
      return ResultadoEdicao.erro('Erro ao editar descrição: $e');
    }
  }

  // ===== EDITAR OBSERVAÇÕES =====
  
  /// Edita observações de transações com suporte a escopo
  Future<ResultadoEdicao<bool>> editarObservacoes(
    TransacaoModel transacao, {
    required String novasObservacoes,
    EscopoEdicao escopo = EscopoEdicao.apenasEsta,
  }) async {
    try {
      final updates = {
        'observacoes': novasObservacoes.trim().isEmpty ? null : novasObservacoes.trim(),
      };

      // Atualizar apenas esta transação
      if (escopo == EscopoEdicao.apenasEsta || (transacao.grupoRecorrencia == null && transacao.grupoParcelamento == null)) {
        await _updateTransacao(transacao.id!, updates);
        return ResultadoEdicao.sucesso(
          mensagem: 'Observações atualizadas',
        );
      }

      // Buscar transações baseado no escopo
      List<TransacaoModel> transacoesParaAtualizar;
      String tipoEscopo;
      
      log('🔍 [DEBUG] editarObservacoes - buscando transações para escopo: $escopo');
      
      if (escopo == EscopoEdicao.estasEFuturas) {
        transacoesParaAtualizar = await _buscarTransacoesFuturas(transacao);
        tipoEscopo = 'futuras';
      } else { // EscopoEdicao.todasRelacionadas
        transacoesParaAtualizar = await _buscarTodasTransacoesRelacionadas(transacao);
        tipoEscopo = 'relacionadas';
      }

      final totalTransacoes = transacoesParaAtualizar.length;
      int atualizadas = 0;
      
      log('🔍 [DEBUG] editarObservacoes - Encontradas $totalTransacoes transações para atualizar');
      log('🔍 [DEBUG] INICIANDO LOOP DE ATUALIZAÇÃO DE OBSERVAÇÕES:');
      
      for (int i = 0; i < transacoesParaAtualizar.length; i++) {
        final t = transacoesParaAtualizar[i];
        final progresso = '${i + 1} de $totalTransacoes';
        
        log('🔄 [PROGRESSO] $progresso - Processando ID: ${t.id}');
        
        try {
          log('🔄 [PROGRESSO] $progresso - Atualizando observações');
          await _updateTransacao(t.id!, updates, skipAutoSync: true);
          atualizadas++;
          log('✅ [PROGRESSO] $progresso - SUCESSO! Observações atualizadas');
        } catch (e) {
          log('❌ [PROGRESSO] $progresso - ERRO ao atualizar observações: $e');
        }
      }
      
      log('🔍 [DEBUG] LOOP DE ATUALIZAÇÃO DE OBSERVAÇÕES FINALIZADO:');
      log('   - Total processadas: $totalTransacoes');
      log('   - Atualizadas: $atualizadas');

      final mensagemFinal = '$atualizadas observações $tipoEscopo atualizadas';
      
      log('✅ [RESULTADO FINAL] $mensagemFinal');
      
      // 🔄 Executar sincronização em lote para todas as transações atualizadas
      if (atualizadas > 0) {
        try {
          log('🔄 [BATCH SYNC] Iniciando sincronização em lote de $atualizadas transações...');
          await SyncManager.instance.syncAll();
          log('✅ [BATCH SYNC] Sincronização em lote concluída com sucesso');
        } catch (e) {
          log('⚠️ [BATCH SYNC] Erro na sincronização em lote: $e');
          // Não falha a operação principal, apenas registra o erro
        }
      }
      
      return ResultadoEdicao.sucesso(
        mensagem: mensagemFinal,
      );
    } catch (e) {
      log('❌ Erro ao editar observações: $e');
      return ResultadoEdicao.erro('Erro ao editar observações: $e');
    }
  }

  // ===== ALTERAR DATA =====
  
  /// Altera data de uma transação
  Future<ResultadoEdicao<bool>> alterarData(
    TransacaoModel transacao, {
    required DateTime novaData,
  }) async {
    try {
      // Validar se transação efetivada
      if (transacao.efetivado) {
        return ResultadoEdicao.erro('Não é possível alterar data de transação efetivada');
      }

      final updates = {
        'data': novaData.toIso8601String().split('T')[0], // Formato YYYY-MM-DD
      };

      await _updateTransacao(transacao.id!, updates);

      return ResultadoEdicao.sucesso(
        mensagem: 'Data atualizada para ${_formatarData(novaData)}',
      );
    } catch (e) {
      log('❌ Erro ao alterar data: $e');
      return ResultadoEdicao.erro('Erro ao alterar data: $e');
    }
  }

  // ===== ALTERAR CONTA =====
  
  /// Altera conta de transação SIMPLES (não recorrente/parcelada)
  Future<ResultadoEdicao<bool>> alterarConta(
    TransacaoModel transacao, {
    required String novaContaId,
  }) async {
    try {
      // Validar se é transação simples
      if (transacao.grupoRecorrencia != null || transacao.grupoParcelamento != null) {
        return ResultadoEdicao.erro('Não é possível alterar conta de transação recorrente ou parcelada');
      }

      // Validar se transação efetivada
      if (transacao.efetivado) {
        return ResultadoEdicao.erro('Não é possível alterar conta de transação efetivada');
      }

      // Validar se é transação de cartão
      if (transacao.cartaoId != null) {
        return ResultadoEdicao.erro('Transações de cartão não possuem conta editável');
      }

      // Validar se não é transferência (tem conta destino)
      if (transacao.contaDestinoId != null) {
        return ResultadoEdicao.erro('Use o método específico para transferências');
      }

      final updates = {
        'conta_id': novaContaId,
      };

      await _updateTransacao(transacao.id!, updates);

      return ResultadoEdicao.sucesso(
        mensagem: 'Conta alterada com sucesso',
      );
    } catch (e) {
      log('❌ Erro ao alterar conta: $e');
      return ResultadoEdicao.erro('Erro ao alterar conta: $e');
    }
  }

  // ===== ALTERAR CARTÃO =====
  
  /// Altera cartão de transação SIMPLES (não recorrente/parcelada)
  Future<ResultadoEdicao<bool>> alterarCartao(
    TransacaoModel transacao, {
    required String novoCartaoId,
  }) async {
    try {
      // Validar se é transação simples
      if (transacao.grupoRecorrencia != null || transacao.grupoParcelamento != null) {
        return ResultadoEdicao.erro('Não é possível alterar cartão de transação recorrente ou parcelada');
      }

      // Validar se transação efetivada
      if (transacao.efetivado) {
        return ResultadoEdicao.erro('Não é possível alterar cartão de transação efetivada');
      }

      // Validar se é transação de despesa
      if (transacao.tipo != 'despesa') {
        return ResultadoEdicao.erro('Apenas despesas podem usar cartão');
      }

      // Validar se não é transferência
      if (transacao.contaDestinoId != null) {
        return ResultadoEdicao.erro('Transferências não podem usar cartão');
      }

      final updates = {
        'cartao_id': novoCartaoId,
        'conta_id': null, // Remove conta se for trocar para cartão
      };

      await _updateTransacao(transacao.id!, updates);

      return ResultadoEdicao.sucesso(
        mensagem: 'Cartão alterado com sucesso',
      );
    } catch (e) {
      log('❌ Erro ao alterar cartão: $e');
      return ResultadoEdicao.erro('Erro ao alterar cartão: $e');
    }
  }

  // ===== MÉTODOS PÚBLICOS DE CONSULTA =====
  
  /// Conta quantas transações serão afetadas por escopo
  Future<int> contarTransacoesAfetadas(
    TransacaoModel transacao,
    EscopoEdicao escopo,
  ) async {
    if (escopo == EscopoEdicao.apenasEsta) {
      return 1;
    }
    
    if (escopo == EscopoEdicao.estasEFuturas) {
      final futuras = await _buscarTransacoesFuturas(transacao);
      return futuras.length;
    }
    
    // EscopoEdicao.todasRelacionadas
    final todas = await _buscarTodasTransacoesRelacionadas(transacao);
    return todas.length;
  }

  // ===== HELPERS PRIVADOS =====
  
  /// Busca transações futuras do mesmo grupo (recorrência OU parcelamento)
  Future<List<TransacaoModel>> _buscarTransacoesFuturas(TransacaoModel transacao) async {
    // Verificar se tem grupo de recorrência ou parcelamento
    log('🔍 [DEBUG] _buscarTransacoesFuturas INICIADO');
    log('🔍 [DEBUG] DADOS DA TRANSAÇÃO ORIGEM:');
    log('   ID: ${transacao.id}');
    log('   Descrição: ${transacao.descricao}');
    log('   Data: ${transacao.data}');
    log('   Parcela Atual: ${transacao.parcelaAtual}');
    log('   Total Parcelas: ${transacao.totalParcelas}');
    log('   Grupo Recorrência: ${transacao.grupoRecorrencia}');
    log('   Grupo Parcelamento: ${transacao.grupoParcelamento}');
    log('   É Recorrente: ${transacao.recorrente}');
    log('   Eh Recorrente: ${transacao.ehRecorrente}');
    log('   Parcela Única: ${transacao.parcelaUnica}');
    
    if (transacao.grupoRecorrencia == null && transacao.grupoParcelamento == null) {
      log('❌ Transação não tem grupo - retornando apenas ela mesma');
      
      // 🔍 DEBUG: Se tem parcelas mas não tem grupo, pode ser transação antiga
      if ((transacao.totalParcelas != null && transacao.totalParcelas! > 1) || !transacao.parcelaUnica) {
        log('⚠️ POSSÍVEL TRANSAÇÃO PARCELADA ANTIGA SEM GRUPO_PARCELAMENTO!');
        log('   Executando migração automática...');
        
        // Executar migração automática
        try {
          await migrarTransacoesParceladasAntigas();
          log('✅ Migração automática concluída, tentando novamente...');
          
          // Buscar a transação atualizada
          final transacaoAtualizada = await _buscarTransacaoAtualizada(transacao.id!);
          if (transacaoAtualizada != null && transacaoAtualizada.grupoParcelamento != null) {
            log('✅ Transação agora tem grupo_parcelamento: ${transacaoAtualizada.grupoParcelamento}');
            return _buscarTransacoesFuturas(transacaoAtualizada); // Tentar novamente com dados atualizados
          }
        } catch (e) {
          log('❌ Erro na migração automática: $e');
        }
      }
      
      // 🔍 DEBUG: Se é recorrente mas não tem grupo, pode ser transação antiga
      if ((transacao.recorrente || transacao.ehRecorrente) && transacao.grupoRecorrencia == null) {
        log('⚠️ POSSÍVEL TRANSAÇÃO RECORRENTE ANTIGA SEM GRUPO_RECORRENCIA!');
        log('   Executando migração automática...');
        
        // Executar migração automática
        try {
          await migrarTransacoesRecorrentesAntigas();
          log('✅ Migração de recorrência automática concluída, tentando novamente...');
          
          // Buscar a transação atualizada
          final transacaoAtualizada = await _buscarTransacaoAtualizada(transacao.id!);
          if (transacaoAtualizada != null && transacaoAtualizada.grupoRecorrencia != null) {
            log('✅ Transação agora tem grupo_recorrencia: ${transacaoAtualizada.grupoRecorrencia}');
            return _buscarTransacoesFuturas(transacaoAtualizada); // Tentar novamente com dados atualizados
          }
        } catch (e) {
          log('❌ Erro na migração automática de recorrência: $e');
        }
      }
      
      return [transacao];
    }

    try {
      final userId = LocalDatabase.instance.currentUserId;
      if (userId == null) {
        log('❌ Usuário não autenticado');
        return [transacao];
      }

      List<Map<String, dynamic>> response;
      String tipoGrupo = '';

      // Buscar por grupo de recorrência (transações que se repetem)
      if (transacao.grupoRecorrencia != null) {
        tipoGrupo = 'RECORRÊNCIA';
        log('🔄 [DEBUG] Buscando por grupo de recorrência: ${transacao.grupoRecorrencia}');
        log('🔄 [DEBUG] Data filtro (>=): ${transacao.data.toIso8601String().split('T')[0]}');
        
        final sqlQuery = '''
          SELECT * FROM transacoes 
          WHERE usuario_id = ? 
            AND grupo_recorrencia = ? 
            AND DATE(data) >= DATE(?)
          ORDER BY data ASC
        ''';
        
        final sqlParams = [
          userId,
          transacao.grupoRecorrencia!,
          transacao.data.toIso8601String().split('T')[0],
        ];
        
        log('🔄 [DEBUG] SQL QUERY EXECUTADA:');
        log('   SQL: $sqlQuery');
        log('   PARAMS: $sqlParams');
        
        response = await LocalDatabase.instance.rawQuery(sqlQuery, sqlParams);
        log('🔄 [DEBUG] SQL RESPONSE: ${response.length} registros encontrados');
      }
      // Buscar por grupo de parcelamento (parcelas de uma transação)
      else if (transacao.grupoParcelamento != null) {
        tipoGrupo = 'PARCELAMENTO';
        log('📦 [DEBUG] Buscando por grupo de parcelamento: ${transacao.grupoParcelamento}');
        log('📦 [DEBUG] Data filtro (>=): ${transacao.data.toIso8601String().split('T')[0]}');
        
        // Primeiro, vamos verificar quantas transações existem com esse grupo (sem filtro de data)
        final debugCount = await LocalDatabase.instance.rawQuery('''
          SELECT COUNT(*) as total FROM transacoes 
          WHERE usuario_id = ? AND grupo_parcelamento = ?
        ''', [userId, transacao.grupoParcelamento!]);
        log('📦 [DEBUG] Total de transações no grupo (sem filtro data): ${debugCount.first['total']}');
        
        final sqlQuery = '''
          SELECT * FROM transacoes 
          WHERE usuario_id = ? 
            AND grupo_parcelamento = ? 
            AND DATE(data) >= DATE(?)
          ORDER BY data ASC
        ''';
        
        final sqlParams = [
          userId,
          transacao.grupoParcelamento!,
          transacao.data.toIso8601String().split('T')[0],
        ];
        
        log('📦 [DEBUG] SQL QUERY EXECUTADA:');
        log('   SQL: $sqlQuery');
        log('   PARAMS: $sqlParams');
        
        response = await LocalDatabase.instance.rawQuery(sqlQuery, sqlParams);
        log('📦 [DEBUG] SQL RESPONSE: ${response.length} registros encontrados');
      }
      else {
        log('❌ Nenhum grupo identificado');
        return [transacao];
      }

      final transacoes = response.map<TransacaoModel>((data) => TransacaoModel.fromJson(data)).toList();
      log('✅ [$tipoGrupo] ${transacoes.length} transações futuras encontradas');
      
      // Log detalhado de cada transação encontrada
      for (int i = 0; i < transacoes.length; i++) {
        final t = transacoes[i];
        log('   ${i + 1}. ID: ${t.id} | Descrição: "${t.descricao}" | Data: ${t.data} | Efetivado: ${t.efetivado}');
      }
      
      log('🔍 [DEBUG] _buscarTransacoesFuturas FINALIZADO - Retornando ${transacoes.length} transações');
      return transacoes;
    } catch (e) {
      log('❌ Erro ao buscar transações futuras: $e');
      return [transacao];
    }
  }

  /// Busca TODAS as transações relacionadas do mesmo grupo (passadas, presentes e futuras)
  Future<List<TransacaoModel>> _buscarTodasTransacoesRelacionadas(TransacaoModel transacao) async {
    // Verificar se tem grupo de recorrência ou parcelamento
    log('🔍 [DEBUG] _buscarTodasTransacoesRelacionadas INICIADO');
    log('🔍 [DEBUG] DADOS DA TRANSAÇÃO ORIGEM:');
    log('   ID: ${transacao.id}');
    log('   Descrição: ${transacao.descricao}');
    log('   Data: ${transacao.data}');
    log('   Grupo Recorrência: ${transacao.grupoRecorrencia}');
    log('   Grupo Parcelamento: ${transacao.grupoParcelamento}');
    
    if (transacao.grupoRecorrencia == null && transacao.grupoParcelamento == null) {
      log('❌ Transação não tem grupo - retornando apenas ela mesma');
      return [transacao];
    }

    try {
      final userId = LocalDatabase.instance.currentUserId;
      if (userId == null) {
        log('❌ Usuário não autenticado');
        return [transacao];
      }

      List<Map<String, dynamic>> response;
      String tipoGrupo = '';

      // Buscar por grupo de recorrência (transações que se repetem)
      if (transacao.grupoRecorrencia != null) {
        tipoGrupo = 'RECORRÊNCIA';
        log('🔄 [DEBUG] Buscando TODAS por grupo de recorrência: ${transacao.grupoRecorrencia}');
        
        final sqlQuery = '''
          SELECT * FROM transacoes 
          WHERE usuario_id = ? 
            AND grupo_recorrencia = ?
          ORDER BY data ASC
        ''';
        
        final sqlParams = [userId, transacao.grupoRecorrencia!];
        
        log('🔄 [DEBUG] SQL QUERY EXECUTADA:');
        log('   SQL: $sqlQuery');
        log('   PARAMS: $sqlParams');
        
        response = await LocalDatabase.instance.rawQuery(sqlQuery, sqlParams);
        log('🔄 [DEBUG] SQL RESPONSE: ${response.length} registros encontrados');
      }
      // Buscar por grupo de parcelamento (parcelas de uma transação)
      else if (transacao.grupoParcelamento != null) {
        tipoGrupo = 'PARCELAMENTO';
        log('📦 [DEBUG] Buscando TODAS por grupo de parcelamento: ${transacao.grupoParcelamento}');
        
        final sqlQuery = '''
          SELECT * FROM transacoes 
          WHERE usuario_id = ? 
            AND grupo_parcelamento = ?
          ORDER BY data ASC
        ''';
        
        final sqlParams = [userId, transacao.grupoParcelamento!];
        
        log('📦 [DEBUG] SQL QUERY EXECUTADA:');
        log('   SQL: $sqlQuery');
        log('   PARAMS: $sqlParams');
        
        response = await LocalDatabase.instance.rawQuery(sqlQuery, sqlParams);
        log('📦 [DEBUG] SQL RESPONSE: ${response.length} registros encontrados');
      }
      else {
        log('❌ Nenhum grupo identificado');
        return [transacao];
      }

      final transacoes = response.map<TransacaoModel>((data) => TransacaoModel.fromJson(data)).toList();
      log('✅ [$tipoGrupo] ${transacoes.length} transações TOTAIS encontradas');
      
      // Log detalhado de cada transação encontrada
      for (int i = 0; i < transacoes.length; i++) {
        final t = transacoes[i];
        log('   ${i + 1}. ID: ${t.id} | Descrição: "${t.descricao}" | Data: ${t.data} | Efetivado: ${t.efetivado}');
      }
      
      log('🔍 [DEBUG] _buscarTodasTransacoesRelacionadas FINALIZADO - Retornando ${transacoes.length} transações');
      return transacoes;
    } catch (e) {
      log('❌ Erro ao buscar todas as transações relacionadas: $e');
      return [transacao];
    }
  }

  /// Atualiza transação usando padrão offline-first
  Future<void> _updateTransacao(String id, Map<String, dynamic> updates, {bool skipAutoSync = false}) async {
    log('🔄 [UPDATE] _updateTransacao INICIADO - ID: $id');
    log('🔄 [UPDATE] Updates recebidos: $updates');
    
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      log('❌ [UPDATE] ERRO: Usuário não autenticado');
      throw Exception('Usuário não autenticado');
    }

    final updateData = {
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
    };

    log('🔄 [UPDATE] Dados finais para atualização: $updateData');
    log('🔄 [UPDATE] Atualizando transação OFFLINE-FIRST: $id');

    // 🔍 VERIFICA CONECTIVIDADE
    final isOnline = await ConnectivityHelper.instance.isOnline();
    log('🌐 Status conectividade: ${isOnline ? "ONLINE" : "OFFLINE"}');

    // ✅ SEMPRE ATUALIZA SQLite LOCAL PRIMEIRO (OFFLINE-FIRST)
    await LocalDatabase.instance.updateTransacaoLocal(id, updateData, skipAutoSync: skipAutoSync);
    log('✅ Transação atualizada no SQLite local: $id');

    // 🌐 TENTA SINCRONIZAR COM SUPABASE SE ONLINE
    if (isOnline) {
      try {
        await _supabase
            .from('transacoes')
            .update(updateData)
            .eq('id', id)
            .eq('usuario_id', userId);
        log('✅ Transação sincronizada com Supabase: $id');
      } catch (e) {
        log('⚠️ Falha na sincronização com Supabase: $e');
        // Não falha - dados já estão salvos localmente
        // Sync automático tentará novamente em background
      }
    } else {
      log('📱 Offline: Transação será sincronizada quando voltar online');
    }
  }

  /// Exclui transação usando padrão offline-first
  Future<void> _deleteTransacao(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    log('🗑️ Excluindo transação OFFLINE-FIRST: $id');

    // 🔍 VERIFICA CONECTIVIDADE
    final isOnline = await ConnectivityHelper.instance.isOnline();
    log('🌐 Status conectividade: ${isOnline ? "ONLINE" : "OFFLINE"}');

    // ✅ SEMPRE EXCLUI DO SQLite LOCAL PRIMEIRO (OFFLINE-FIRST)
    await LocalDatabase.instance.deleteTransacaoLocal(id);
    log('✅ Transação excluída do SQLite local: $id');

    // 🌐 TENTA SINCRONIZAR COM SUPABASE SE ONLINE
    if (isOnline) {
      try {
        await _supabase
            .from('transacoes')
            .delete()
            .eq('id', id)
            .eq('usuario_id', userId);
        log('✅ Transação excluída do Supabase: $id');
      } catch (e) {
        log('⚠️ Falha na exclusão no Supabase: $e');
        // Não falha - dados já foram excluídos localmente
        // Sync automático tentará novamente em background
      }
    } else {
      log('📱 Offline: Exclusão será sincronizada quando voltar online');
    }
  }

  String _nomeMes(int mes) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return meses[mes - 1];
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  // ===== MIGRAÇÃO DE DADOS =====
  
  /// 🔧 MIGRAÇÃO: Corrigir transações recorrentes antigas sem grupo_recorrencia
  Future<void> migrarTransacoesRecorrentesAntigas() async {
    try {
      final userId = LocalDatabase.instance.currentUserId;
      if (userId == null) {
        log('❌ Usuário não autenticado para migração de recorrência');
        return;
      }

      log('🔧 Iniciando migração de transações recorrentes antigas...');

      // Buscar transações que são recorrentes mas não têm grupo_recorrencia
      final transacoesSemGrupo = await LocalDatabase.instance.rawQuery('''
        SELECT * FROM transacoes 
        WHERE usuario_id = ? 
          AND ((recorrente = 1 OR eh_recorrente = 1) AND (grupo_recorrencia IS NULL OR grupo_recorrencia = ''))
        ORDER BY descricao, valor, data ASC
      ''', [userId]);

      if (transacoesSemGrupo.isEmpty) {
        log('✅ Nenhuma transação recorrente antiga encontrada');
        return;
      }

      log('🔧 Encontradas ${transacoesSemGrupo.length} transações recorrentes sem grupo');

      // Agrupar transações por características similares (descrição base, valor, categoria)
      final gruposIdentificados = <String, List<Map<String, dynamic>>>{};
      
      for (final transacao in transacoesSemGrupo) {
        // Criar chave baseada em descrição, valor e categoria
        final descricao = transacao['descricao'] ?? '';
        final valor = transacao['valor'] ?? 0.0;
        final categoriaId = transacao['categoria_id'] ?? 'sem_categoria';
        
        final chave = '${descricao}_${valor}_${categoriaId}';
        
        if (!gruposIdentificados.containsKey(chave)) {
          gruposIdentificados[chave] = [];
        }
        gruposIdentificados[chave]!.add(transacao);
      }

      int gruposCorrigidos = 0;
      int transacoesAtualizadas = 0;

      // Para cada grupo identificado, criar grupo_recorrencia
      for (final entrada in gruposIdentificados.entries) {
        final chave = entrada.key;
        final transacoes = entrada.value;
        
        // Apenas criar grupo se tiver mais de 1 transação
        if (transacoes.length > 1) {
          final grupoId = const Uuid().v4();
          log('🔧 Criando grupo recorrência $grupoId para ${transacoes.length} transações: $chave');
          
          // Atualizar todas as transações do grupo
          for (int i = 0; i < transacoes.length; i++) {
            final transacao = transacoes[i];
            await LocalDatabase.instance.database!.update(
              'transacoes',
              {
                'grupo_recorrencia': grupoId,
                'numero_recorrencia': i + 1,
                'total_recorrencias': transacoes.length,
                'recorrente': 1,
                'eh_recorrente': 1,
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [transacao['id']],
            );
            transacoesAtualizadas++;
          }
          gruposCorrigidos++;
        }
      }

      log('✅ Migração de recorrência concluída:');
      log('   - $gruposCorrigidos grupos criados');
      log('   - $transacoesAtualizadas transações atualizadas');

    } catch (e) {
      log('❌ Erro na migração de transações recorrentes: $e');
    }
  }

  /// 🔧 MIGRAÇÃO: Corrigir transações parceladas antigas sem grupo_parcelamento
  Future<void> migrarTransacoesParceladasAntigas() async {
    try {
      final userId = LocalDatabase.instance.currentUserId;
      if (userId == null) {
        log('❌ Usuário não autenticado para migração');
        return;
      }

      log('🔧 Iniciando migração de transações parceladas antigas...');

      // Buscar transações que têm parcelas mas não têm grupo_parcelamento
      final transacoesSemGrupo = await LocalDatabase.instance.rawQuery('''
        SELECT * FROM transacoes 
        WHERE usuario_id = ? 
          AND (
            (total_parcelas > 1 AND (grupo_parcelamento IS NULL OR grupo_parcelamento = ''))
            OR
            (parcela_unica = 0 AND (grupo_parcelamento IS NULL OR grupo_parcelamento = ''))
          )
        ORDER BY descricao, valor, data ASC
      ''', [userId]);

      if (transacoesSemGrupo.isEmpty) {
        log('✅ Nenhuma transação parcelada antiga encontrada');
        return;
      }

      log('🔧 Encontradas ${transacoesSemGrupo.length} transações parceladas sem grupo');

      // Agrupar transações por características similares
      final gruposIdentificados = <String, List<Map<String, dynamic>>>{};
      
      for (final transacao in transacoesSemGrupo) {
        // Criar chave baseada em descrição base, valor e cartão
        final descricaoBase = _extrairDescricaoBase(transacao['descricao'] ?? '');
        final valor = transacao['valor'] ?? 0.0;
        final cartaoId = transacao['cartao_id'] ?? 'sem_cartao';
        final totalParcelas = transacao['total_parcelas'] ?? 1;
        
        final chave = '${descricaoBase}_${valor}_${cartaoId}_${totalParcelas}';
        
        if (!gruposIdentificados.containsKey(chave)) {
          gruposIdentificados[chave] = [];
        }
        gruposIdentificados[chave]!.add(transacao);
      }

      int gruposCorrigidos = 0;
      int transacoesAtualizadas = 0;

      // Para cada grupo identificado, criar grupo_parcelamento
      for (final entrada in gruposIdentificados.entries) {
        final chave = entrada.key;
        final transacoes = entrada.value;
        
        // Apenas criar grupo se tiver mais de 1 transação
        if (transacoes.length > 1) {
          final grupoId = const Uuid().v4();
          log('🔧 Criando grupo $grupoId para ${transacoes.length} transações: $chave');
          
          // Atualizar todas as transações do grupo
          for (int i = 0; i < transacoes.length; i++) {
            final transacao = transacoes[i];
            await LocalDatabase.instance.database!.update(
              'transacoes',
              {
                'grupo_parcelamento': grupoId,
                'parcela_atual': i + 1,
                'total_parcelas': transacoes.length,
                'parcela_unica': 0,
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [transacao['id']],
            );
            transacoesAtualizadas++;
          }
          gruposCorrigidos++;
        }
      }

      log('✅ Migração concluída:');
      log('   - $gruposCorrigidos grupos criados');
      log('   - $transacoesAtualizadas transações atualizadas');

    } catch (e) {
      log('❌ Erro na migração de transações parceladas: $e');
    }
  }
  
  /// 🔧 Extrair descrição base removendo sufixos de parcela
  String _extrairDescricaoBase(String descricao) {
    // Remover padrões como " (1/8)", " (2/8)", etc.
    final regex = RegExp(r'\s*\(\d+/\d+\)\s*$');
    return descricao.replaceAll(regex, '').trim();
  }
  
  /// 🔍 Buscar transação atualizada por ID
  Future<TransacaoModel?> _buscarTransacaoAtualizada(String transacaoId) async {
    try {
      final userId = LocalDatabase.instance.currentUserId;
      if (userId == null) return null;

      final result = await LocalDatabase.instance.rawQuery('''
        SELECT * FROM transacoes 
        WHERE id = ? AND usuario_id = ?
      ''', [transacaoId, userId]);

      if (result.isNotEmpty) {
        return TransacaoModel.fromJson(result.first);
      }
      return null;
    } catch (e) {
      log('❌ Erro ao buscar transação atualizada: $e');
      return null;
    }
  }

  // ===== MÉTODOS DE EXCLUSÃO =====

  /// Exclui uma transação individual
  Future<ResultadoEdicao<bool>> excluirTransacao(TransacaoModel transacao) async {
    final resultado = await excluir(transacao, incluirFuturas: false);
    return ResultadoEdicao(
      sucesso: resultado.sucesso,
      mensagem: resultado.mensagem,
      erro: resultado.erro,
    );
  }

  /// Exclui grupo de transações baseado no escopo
  Future<ResultadoEdicao<bool>> excluirGrupo(
    TransacaoModel transacao,
    EscopoEdicao escopo,
  ) async {
    switch (escopo) {
      case EscopoEdicao.apenasEsta:
        return await excluirTransacao(transacao);

      case EscopoEdicao.estasEFuturas:
        final resultado = await excluir(transacao, incluirFuturas: true);
        return ResultadoEdicao(
          sucesso: resultado.sucesso,
          mensagem: resultado.mensagem,
          erro: resultado.erro,
        );

      case EscopoEdicao.todasRelacionadas:
        // Para todas relacionadas, buscar todas as transações do grupo
        try {
          List<TransacaoModel> todasTransacoes;
          if (transacao.grupoRecorrencia != null) {
            todasTransacoes = await _buscarTodasTransacoesRelacionadas(transacao);
          } else if (transacao.grupoParcelamento != null) {
            todasTransacoes = await _buscarTodasTransacoesRelacionadas(transacao);
          } else {
            return await excluirTransacao(transacao);
          }

          int excluidas = 0;
          for (final t in todasTransacoes) {
            if (!t.efetivado) {
              try {
                await _deleteTransacao(t.id!);
                excluidas++;
              } catch (e) {
                log('❌ Erro ao excluir transação ${t.id}: $e');
              }
            }
          }

          if (excluidas > 0) {
            await SyncManager.instance.syncAll();
          }

          return ResultadoEdicao.sucesso(
            mensagem: '$excluidas transações excluídas do grupo',
          );

        } catch (e) {
          log('❌ Erro ao excluir grupo: $e');
          return ResultadoEdicao.erro('Erro ao excluir grupo: $e');
        }
    }
  }


  // ===== VALIDAÇÃO DE JANELA DE DADOS =====

  /// Verifica se uma data está dentro da janela de dados locais (±12 meses)
  static bool _estaDetroDaJanelaLocal(DateTime data) {
    final agora = DateTime.now();
    final dozesMesesAtras = agora.subtract(const Duration(days: 365));
    final dozesMesesAFrente = agora.add(const Duration(days: 365));

    return data.isAfter(dozesMesesAtras) && data.isBefore(dozesMesesAFrente);
  }

  /// Analisa se uma operação em grupo pode ser feita totalmente local
  Future<Map<String, dynamic>> analisarEscopoOperacao(
    TransacaoModel transacao,
    EscopoEdicao escopo,
  ) async {
    try {
      final userId = LocalDatabase.instance.currentUserId;
      if (userId == null) {
        return {
          'podeUsarLocal': false,
          'totalTransacoes': 0,
          'transacoesLocais': 0,
          'requerConexao': true,
          'erro': 'Usuário não identificado',
        };
      }

      int totalTransacoes = 0;
      int transacoesLocais = 0;
      List<Map<String, dynamic>> transacoesAfetadas = [];

      switch (escopo) {
        case EscopoEdicao.apenasEsta:
          totalTransacoes = 1;
          transacoesLocais = 1;
          break;

        case EscopoEdicao.estasEFuturas:
          // Busca transações futuras no grupo
          if (transacao.grupoRecorrencia != null) {
            final query = '''
              SELECT * FROM transacoes
              WHERE usuario_id = ? AND grupo_recorrencia = ? AND data >= ?
              ORDER BY data ASC
            ''';
            transacoesAfetadas = await LocalDatabase.instance.rawQuery(
              query,
              [userId, transacao.grupoRecorrencia, transacao.data.toIso8601String()]
            );
          } else if (transacao.grupoParcelamento != null) {
            final query = '''
              SELECT * FROM transacoes
              WHERE usuario_id = ? AND grupo_parcelamento = ? AND data >= ?
              ORDER BY data ASC
            ''';
            transacoesAfetadas = await LocalDatabase.instance.rawQuery(
              query,
              [userId, transacao.grupoParcelamento, transacao.data.toIso8601String()]
            );
          } else {
            totalTransacoes = 1;
            transacoesLocais = 1;
          }
          break;

        case EscopoEdicao.todasRelacionadas:
          // Busca todas as transações do grupo
          if (transacao.grupoRecorrencia != null) {
            // Primeiro tenta buscar localmente
            final queryLocal = '''
              SELECT * FROM transacoes
              WHERE usuario_id = ? AND grupo_recorrencia = ?
              ORDER BY data ASC
            ''';
            transacoesAfetadas = await LocalDatabase.instance.rawQuery(
              queryLocal,
              [userId, transacao.grupoRecorrencia]
            );

            // Verifica se há metadados do grupo para saber o total real
            try {
              final metadadosService = GruposMetadadosService.instance;
              final metadados = await metadadosService.obterMetadadosGrupo(
                transacao.grupoRecorrencia!,
                userId
              );

              if (metadados != null) {
                totalTransacoes = metadados.totalItems ?? 0;
              } else {
                totalTransacoes = transacoesAfetadas.length;
              }
            } catch (e) {
              totalTransacoes = transacoesAfetadas.length;
            }
          } else if (transacao.grupoParcelamento != null) {
            final queryLocal = '''
              SELECT * FROM transacoes
              WHERE usuario_id = ? AND grupo_parcelamento = ?
              ORDER BY data ASC
            ''';
            transacoesAfetadas = await LocalDatabase.instance.rawQuery(
              queryLocal,
              [userId, transacao.grupoParcelamento]
            );

            totalTransacoes = transacoesAfetadas.length;
          } else {
            totalTransacoes = 1;
            transacoesLocais = 1;
          }
          break;
      }

      // Conta quantas transações estão dentro da janela local
      if (transacoesAfetadas.isNotEmpty) {
        transacoesLocais = transacoesAfetadas.length;

        // Verifica se todas as datas estão dentro da janela
        for (final t in transacoesAfetadas) {
          final data = DateTime.parse(t['data'] as String);
          if (!_estaDetroDaJanelaLocal(data)) {
            // Se encontrar uma data fora da janela, significa que há mais transações
            // que não estão no banco local
            break;
          }
        }
      }

      final podeUsarLocal = totalTransacoes == transacoesLocais && transacoesLocais > 0;
      final requerConexao = !podeUsarLocal && totalTransacoes > transacoesLocais;

      return {
        'podeUsarLocal': podeUsarLocal,
        'totalTransacoes': totalTransacoes,
        'transacoesLocais': transacoesLocais,
        'requerConexao': requerConexao,
        'transacoesAfetadas': transacoesAfetadas,
      };

    } catch (e) {
      log('❌ Erro ao analisar escopo da operação: $e');
      return {
        'podeUsarLocal': false,
        'totalTransacoes': 0,
        'transacoesLocais': 0,
        'requerConexao': true,
        'erro': 'Erro ao analisar operação: $e',
      };
    }
  }

  /// Verifica se todas as transações de um grupo estão dentro da janela local
  Future<bool> todasTransacoesNaJanelaLocal(
    String? grupoRecorrencia,
    String? grupoParcelamento,
  ) async {
    if (grupoRecorrencia == null && grupoParcelamento == null) return true;

    try {
      final userId = LocalDatabase.instance.currentUserId;
      if (userId == null) return false;

      String query;
      String grupoId;

      if (grupoRecorrencia != null) {
        query = '''
          SELECT MIN(data) as data_min, MAX(data) as data_max
          FROM transacoes
          WHERE usuario_id = ? AND grupo_recorrencia = ?
        ''';
        grupoId = grupoRecorrencia;
      } else {
        query = '''
          SELECT MIN(data) as data_min, MAX(data) as data_max
          FROM transacoes
          WHERE usuario_id = ? AND grupo_parcelamento = ?
        ''';
        grupoId = grupoParcelamento!;
      }

      final result = await LocalDatabase.instance.rawQuery(query, [userId, grupoId]);

      if (result.isNotEmpty && result.first['data_min'] != null) {
        final dataMin = DateTime.parse(result.first['data_min'] as String);
        final dataMax = DateTime.parse(result.first['data_max'] as String);

        return _estaDetroDaJanelaLocal(dataMin) && _estaDetroDaJanelaLocal(dataMax);
      }

      return true;
    } catch (e) {
      log('❌ Erro ao verificar janela local: $e');
      return false;
    }
  }

  // ===== MÉTODOS PARA COMPATIBILIDADE COM PÁGINAS SEPARADAS =====

  /// Método para análise de transação (compatibilidade)
  static Future<Map<String, dynamic>> analisarTransacao(String transacaoId) async {
    // Retorna informações sobre a transação para as páginas separadas
    return {
      'temRelacionadas': false,
      'quantidadeFuturas': 0,
    };
  }
}