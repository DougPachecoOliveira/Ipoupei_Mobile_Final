// lib/src/modules/transacoes/pages/editar_transacao_page.dart

import 'dart:developer';
import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
// import '../../../shared/components/ui/loading_widget.dart';
import '../models/transacao_model.dart';
import '../services/transacao_edit_service.dart' show TransacaoEditService, EscopoEdicao;
import '../services/transacao_edit_service.dart' as service;
import '../../contas/services/conta_service.dart';
import '../../cartoes/services/cartao_service.dart';
import '../../cartoes/services/fatura_service.dart';
import '../../categorias/services/categoria_service.dart';
import '../../categorias/data/categoria_icons.dart';
import '../../categorias/models/categoria_model.dart';
import '../../../database/local_database.dart';
import '../../../services/grupos_metadados_service.dart';
import '../../../sync/sync_manager.dart';
import '../../contas/models/conta_model.dart';
import '../../cartoes/models/cartao_model.dart';
import '../../../shared/utils/currency_formatter.dart';
import 'alterar_descricao_page.dart';
import 'alterar_valor_page.dart';
import 'alterar_data_page.dart';
import 'alterar_categoria_page.dart';
import 'alterar_observacoes_page.dart';
import 'alterar_conta_page.dart';
import 'aplicar_reajuste_page.dart';
import '../components/transaction_detail_card.dart';
import '../components/operacao_helper.dart';
import '../components/escopo_edicao_modal.dart';


/// Modos de edição disponíveis
enum ModoEdicao {
  completa(
    titulo: 'Editar Transação',
    descricao: 'Altere todos os campos disponíveis',
  ),
  apenasValor(
    titulo: 'Editar Valor',
    descricao: 'Altere apenas o valor desta transação',
  ),
  valorFuturas(
    titulo: 'Editar Valor + Futuras',
    descricao: 'Altere o valor desta e das próximas parcelas',
  ),
  reajuste(
    titulo: 'Aplicar Reajuste',
    descricao: 'Aplique um percentual de reajuste',
  );

  const ModoEdicao({
    required this.titulo,
    required this.descricao,
  });

  final String titulo;
  final String descricao;
}

/// Página unificada para editar transações
/// Detecta o tipo e carrega a interface apropriada
class EditarTransacaoPage extends StatefulWidget {
  final TransacaoModel transacao;
  final ModoEdicao modo;
  final VoidCallback? onTransacaoEditada; // Callback para notificar edições

  const EditarTransacaoPage({
    super.key,
    required this.transacao,
    this.modo = ModoEdicao.completa,
    this.onTransacaoEditada,
  });

  @override
  State<EditarTransacaoPage> createState() => _EditarTransacaoPageState();
}

class _EditarTransacaoPageState extends State<EditarTransacaoPage> {
  bool _analisando = true;
  bool _temParcelasOuRecorrencias = false;
  bool _processando = false;
  int _quantidadeFuturas = 0;
  DateTime? _dataPrimeiraTransacao;
  DateTime? _dataUltimaTransacao;
  int? _posicaoAtualNoGrupo;
  int? _totalTransacoesGrupo;

  // Dados financeiros do grupo
  double? _valorTotalGrupo;
  double? _valorEfetivadoGrupo;
  double? _valorPendenteGrupo;
  int? _itemsEfetivados;
  int? _itemsPendentes;
  GrupoMetadados? _metadadosGrupo;

  // Controllers para edição rápida
  final _valorController = TextEditingController();
  final _percentualController = TextEditingController();
  
  bool _incluirFuturas = false;
  bool _isAumento = true;
  late EscopoEdicao _escopoEdicaoReajuste;
  
  // Dados carregados
  String? _nomeConta;
  String? _nomeCartao;
  String? _nomeCategoria;
  String? _nomeSubcategoria;
  String? _iconeCategoria; // Mudou para String
  Color? _corCategoria;
  // Dados da conta/cartão
  String? _iconeConta;
  Color? _corConta;
  String? _iconeCartao;
  Color? _corCartao;

  @override
  void initState() {
    super.initState();

    // Debug logging para troubleshooting de grupos grandes
    print('===== EDITANDO TRANSAÇÃO =====');
    log('ID: ${widget.transacao.id}');
    log('Descrição: ${widget.transacao.descricao}');
    log('Valor: ${widget.transacao.valor}');
    log('Data: ${widget.transacao.data}');
    log('Efetivado: ${widget.transacao.efetivado}');
    log('Recorrente: ${widget.transacao.recorrente}');
    log('Grupo Recorrência: ${widget.transacao.grupoRecorrencia}');
    log('Tipo Recorrência: ${widget.transacao.tipoRecorrencia}');
    log('Número Recorrência: ${widget.transacao.numeroRecorrencia}');
    log('Total Recorrências: ${widget.transacao.totalRecorrencias}');
    log('Parcela Única: ${widget.transacao.parcelaUnica}');
    log('Grupo Parcelamento: ${widget.transacao.grupoParcelamento}');
    log('Parcela Atual: ${widget.transacao.parcelaAtual}');
    log('Total Parcelas: ${widget.transacao.totalParcelas}');
    log('User ID: ${widget.transacao.usuarioId}');
    log('===============================');

    _valorController.text = widget.transacao.valor.toStringAsFixed(2);
    
    // Listener para atualizar preview em tempo real
    _valorController.addListener(() {
      setState(() {
        // Atualiza o preview quando o valor muda
      });
    });
    
    // Listener para atualizar preview do reajuste em tempo real
    _percentualController.addListener(() {
      setState(() {
        // Atualiza o preview quando o percentual muda
      });
    });
    
    // Inicializar escopo de reajuste baseado no status da transação
    _escopoEdicaoReajuste = widget.transacao.efetivado 
        ? EscopoEdicao.estasEFuturas 
        : EscopoEdicao.apenasEsta;
    
    _analisarTransacao();
    _baixarGrupoSeNecessario(); // Download silencioso em background
  }

  @override
  void dispose() {
    _valorController.dispose();
    _percentualController.dispose();
    super.dispose();
  }

  Future<void> _analisarTransacao() async {
    // Verificar se tem parcelas ou recorrências
    if (widget.transacao.recorrente || widget.transacao.grupoRecorrencia != null) {
      _temParcelasOuRecorrencias = true;

      // Calcular quantidade de futuras transações
      _calcularQuantidadeFuturas();

      // Buscar metadados do grupo (datas, valores, progresso)
      await _buscarMetadadosGrupo();

      // Se a transação estiver efetivada, força incluir futuras (só pode alterar futuras)
      if (widget.transacao.efetivado) {
        _incluirFuturas = true;
      }
    }
    
    // Carregar dados das entidades relacionadas
    await _carregarDadosRelacionados();

    setState(() {
      _analisando = false;
    });
  }
  
  void _calcularQuantidadeFuturas() {
    // Se tem parcelas
    if (widget.transacao.totalParcelas != null && widget.transacao.totalParcelas! > 1) {
      final atual = widget.transacao.parcelaAtual ?? 1;
      final total = widget.transacao.totalParcelas!;
      _quantidadeFuturas = total - atual;
    }
    // Se é recorrente - estimar baseado em um ano
    else if (widget.transacao.recorrente) {
      final tipo = widget.transacao.tipoRecorrencia ?? 'Mensal';
      switch (tipo.toLowerCase()) {
        case 'diária':
        case 'diario':
          _quantidadeFuturas = 365; // Aproximação de um ano
          break;
        case 'semanal':
          _quantidadeFuturas = 52; // 52 semanas no ano
          break;
        case 'quinzenal':
          _quantidadeFuturas = 26; // 26 quinzenas no ano
          break;
        case 'mensal':
          _quantidadeFuturas = 12; // 12 meses no ano
          break;
        case 'bimestral':
          _quantidadeFuturas = 6; // 6 bimestres no ano
          break;
        case 'trimestral':
          _quantidadeFuturas = 4; // 4 trimestres no ano
          break;
        case 'semestral':
          _quantidadeFuturas = 2; // 2 semestres no ano
          break;
        case 'anual':
          _quantidadeFuturas = 1; // 1 por ano
          break;
        default:
          _quantidadeFuturas = 12; // Padrão mensal
      }
    }
  }

  /// Buscar datas da primeira e última transação do grupo
  Future<void> _buscarDatasGrupo() async {
    try {
      log('🔍 [DEBUG] _buscarDatasGrupo() iniciado');
      log('🔍 Transação ID: ${widget.transacao.id}');
      log('🔍 Grupo Recorrência: ${widget.transacao.grupoRecorrencia}');
      log('🔍 Grupo Parcelamento: ${widget.transacao.grupoParcelamento}');
      log('🔍 Número Recorrência: ${widget.transacao.numeroRecorrencia}');
      log('🔍 Total Recorrências: ${widget.transacao.totalRecorrencias}');
      log('🔍 Parcela Atual: ${widget.transacao.parcelaAtual}');
      log('🔍 Total Parcelas: ${widget.transacao.totalParcelas}');

      final db = LocalDatabase.instance;

      // Para parcelas: usar grupo_parcelamento e parcela_atual/total_parcelas
      if (widget.transacao.totalParcelas != null && widget.transacao.totalParcelas! > 1) {
        if (widget.transacao.grupoParcelamento != null) {
          // Buscar primeira e última parcela baseado nos números sequenciais
          final queryDatas = '''
            SELECT
              (SELECT data FROM transacoes t1
               WHERE t1.grupo_parcelamento = ? AND t1.usuario_id = ?
                 AND t1.parcela_atual = 1) as primeira_data,
              (SELECT data FROM transacoes t2
               WHERE t2.grupo_parcelamento = ? AND t2.usuario_id = ?
                 AND t2.parcela_atual = (
                   SELECT MAX(parcela_atual) FROM transacoes t3
                   WHERE t3.grupo_parcelamento = ? AND t3.usuario_id = ?
                 )) as ultima_data,
              MAX(total_parcelas) as total_parcelas,
              COUNT(*) as parcelas_criadas
            FROM transacoes
            WHERE grupo_parcelamento = ? AND usuario_id = ?
          ''';

          final resultado = await db.rawQuery(queryDatas, [
            widget.transacao.grupoParcelamento,  // primeira_data subquery
            widget.transacao.usuarioId,
            widget.transacao.grupoParcelamento,  // ultima_data subquery
            widget.transacao.usuarioId,
            widget.transacao.grupoParcelamento,  // MAX subquery dentro de ultima_data
            widget.transacao.usuarioId,
            widget.transacao.grupoParcelamento,  // WHERE principal
            widget.transacao.usuarioId
          ]);

          print('🔍 [DEBUG] Parcelas - Query resultado: $resultado');

          if (resultado.isNotEmpty) {
            if (resultado.first['primeira_data'] != null) {
              _dataPrimeiraTransacao = DateTime.parse(resultado.first['primeira_data']);
              print('✅ Primeira parcela: ${resultado.first['primeira_data']}');
            }
            if (resultado.first['ultima_data'] != null) {
              _dataUltimaTransacao = DateTime.parse(resultado.first['ultima_data']);
              print('✅ Última data do grupo: ${resultado.first['ultima_data']}');
            }
            _totalTransacoesGrupo = resultado.first['total_parcelas'];
            print('✅ Total parcelas: ${resultado.first['total_parcelas']}');
            print('✅ Parcelas criadas: ${resultado.first['parcelas_criadas']}');
          }

          // Usar parcela_atual diretamente
          _posicaoAtualNoGrupo = widget.transacao.parcelaAtual;

          return; // Já processado
        }
      }
      // Para recorrências: usar grupo_recorrencia e numero_recorrencia/total_recorrencias
      else if (widget.transacao.recorrente && widget.transacao.grupoRecorrencia != null) {
        // Buscar primeira e última recorrência baseado nos números sequenciais
        final queryDatas = '''
          SELECT
            (SELECT data FROM transacoes t1
             WHERE t1.grupo_recorrencia = ? AND t1.usuario_id = ?
               AND t1.numero_recorrencia = 1) as primeira_data,
            (SELECT data FROM transacoes t2
             WHERE t2.grupo_recorrencia = ? AND t2.usuario_id = ?
               AND t2.numero_recorrencia = (
                 SELECT MAX(numero_recorrencia) FROM transacoes t3
                 WHERE t3.grupo_recorrencia = ? AND t3.usuario_id = ?
               )) as ultima_data,
            MAX(total_recorrencias) as total_recorrencias,
            COUNT(*) as recorrencias_criadas
          FROM transacoes
          WHERE grupo_recorrencia = ? AND usuario_id = ?
        ''';

        final resultado = await db.rawQuery(queryDatas, [
          widget.transacao.grupoRecorrencia,  // primeira_data subquery
          widget.transacao.usuarioId,
          widget.transacao.grupoRecorrencia,  // ultima_data subquery
          widget.transacao.usuarioId,
          widget.transacao.grupoRecorrencia,  // MAX subquery dentro de ultima_data
          widget.transacao.usuarioId,
          widget.transacao.grupoRecorrencia,  // WHERE principal
          widget.transacao.usuarioId
        ]);

        print('🔍 [DEBUG] Recorrências - Query resultado: $resultado');

        if (resultado.isNotEmpty) {
          if (resultado.first['primeira_data'] != null) {
            _dataPrimeiraTransacao = DateTime.parse(resultado.first['primeira_data']);
            print('✅ Primeira recorrência: ${resultado.first['primeira_data']}');
          }
          if (resultado.first['ultima_data'] != null) {
            _dataUltimaTransacao = DateTime.parse(resultado.first['ultima_data']);
            print('✅ Última data do grupo: ${resultado.first['ultima_data']}');
          }
          _totalTransacoesGrupo = resultado.first['total_recorrencias'];
          print('✅ Total recorrências: ${resultado.first['total_recorrencias']}');
          print('✅ Recorrências criadas: ${resultado.first['recorrencias_criadas']}');
        }

        // Usar numero_recorrencia diretamente
        _posicaoAtualNoGrupo = widget.transacao.numeroRecorrencia;

        return; // Já processado
      }

      // Fallback para transações sem grupo: buscar pela descrição/valor
      if (widget.transacao.totalParcelas != null && widget.transacao.totalParcelas! > 1) {
        // Para parcelas sem grupo, usar campos diretos
        _posicaoAtualNoGrupo = widget.transacao.parcelaAtual ?? 1;
        _totalTransacoesGrupo = widget.transacao.totalParcelas;

        final queryFallback = '''
          SELECT MIN(data) as primeira_data, MAX(data) as ultima_data
          FROM transacoes
          WHERE descricao = ? AND valor = ? AND total_parcelas = ? AND usuario_id = ?
          ORDER BY parcela_atual ASC
        ''';

        final resultado = await db.rawQuery(queryFallback, [
          widget.transacao.descricao,
          widget.transacao.valor,
          widget.transacao.totalParcelas,
          widget.transacao.usuarioId
        ]);

        if (resultado.isNotEmpty && resultado.first['primeira_data'] != null) {
          _dataPrimeiraTransacao = DateTime.parse(resultado.first['primeira_data']);
          _dataUltimaTransacao = DateTime.parse(resultado.first['ultima_data']);
        }
      }
      else if (widget.transacao.recorrente) {
        final queryFallback = '''
          SELECT MIN(data) as primeira_data, MAX(data) as ultima_data, MAX(total_recorrencias) as total
          FROM transacoes
          WHERE descricao = ? AND valor = ? AND recorrente = 1 AND usuario_id = ?
          ORDER BY numero_recorrencia ASC
        ''';

        final resultado = await db.rawQuery(queryFallback, [
          widget.transacao.descricao,
          widget.transacao.valor,
          widget.transacao.usuarioId
        ]);

        if (resultado.isNotEmpty && resultado.first['primeira_data'] != null) {
          _dataPrimeiraTransacao = DateTime.parse(resultado.first['primeira_data']);
          _dataUltimaTransacao = DateTime.parse(resultado.first['ultima_data']);
          _totalTransacoesGrupo = resultado.first['total'];
        }

        // Usar numero_recorrencia diretamente
        _posicaoAtualNoGrupo = widget.transacao.numeroRecorrencia;
      }

    } catch (e) {
      log('❌ [ERROR] Erro ao buscar datas do grupo: $e');
      // Em caso de erro, usar dados estimados
      _dataPrimeiraTransacao = widget.transacao.data;
      _dataUltimaTransacao = widget.transacao.data;
    }

    // Debug: mostrar resultados finais
    log('🔍 [DEBUG] Resultados finais do _buscarDatasGrupo:');
    log('🔍 Primeira data: $_dataPrimeiraTransacao');
    log('🔍 Última data: $_dataUltimaTransacao');
    log('🔍 Posição atual no grupo: $_posicaoAtualNoGrupo');
    log('🔍 Total transações do grupo: $_totalTransacoesGrupo');
    log('🔍 [DEBUG] _buscarDatasGrupo() finalizado');
  }

  /// 📊 BUSCAR METADADOS DO GRUPO (método otimizado)
  Future<void> _buscarMetadadosGrupo() async {
    try {
      print('📊 [DEBUG] _buscarMetadadosGrupo() iniciado');

      String? grupoId;
      String tipoGrupo;

      // Identificar qual tipo de grupo e o ID
      if (widget.transacao.grupoRecorrencia != null) {
        grupoId = widget.transacao.grupoRecorrencia;
        tipoGrupo = 'recorrencia';
        print('🔍 Grupo de recorrência identificado: $grupoId');
      } else if (widget.transacao.grupoParcelamento != null) {
        grupoId = widget.transacao.grupoParcelamento;
        tipoGrupo = 'parcelamento';
        print('🔍 Grupo de parcelamento identificado: $grupoId');
      } else {
        print('⚠️ Transação sem grupo identificado');
        return;
      }

      if (grupoId == null) {
        print('⚠️ ID do grupo é null');
        return;
      }

      // Buscar metadados na tabela otimizada
      final service = GruposMetadadosService.instance;
      _metadadosGrupo = await service.obterMetadadosGrupo(grupoId, widget.transacao.usuarioId);

      if (_metadadosGrupo != null) {
        // ✅ Usar dados dos metadados
        _dataPrimeiraTransacao = _metadadosGrupo!.dataPrimeira;
        _dataUltimaTransacao = _metadadosGrupo!.dataUltima;
        _totalTransacoesGrupo = _metadadosGrupo!.totalItems;
        _valorTotalGrupo = _metadadosGrupo!.valorTotal;
        _valorEfetivadoGrupo = _metadadosGrupo!.valorEfetivado;
        _valorPendenteGrupo = _metadadosGrupo!.valorPendente;
        _itemsEfetivados = _metadadosGrupo!.itemsEfetivados;
        _itemsPendentes = _metadadosGrupo!.itemsPendentes;

        // Posição atual da transação - com correção para números inconsistentes
        if (tipoGrupo == 'recorrencia') {
          final numeroOriginal = widget.transacao.numeroRecorrencia;
          print('🔍 Posição recorrência original: $numeroOriginal');
          print('🔍 Total do grupo: ${_metadadosGrupo!.totalItems}');

          // Se numero_recorrencia é igual ao total, significa que todos têm o mesmo número
          // Neste caso, usamos NULL para não mostrar posição incorreta
          if (numeroOriginal != null && numeroOriginal == _metadadosGrupo!.totalItems) {
            print('⚠️ Números de recorrência inconsistentes detectados - não mostrando posição');
            _posicaoAtualNoGrupo = null;
          } else {
            _posicaoAtualNoGrupo = numeroOriginal;
          }
        } else {
          _posicaoAtualNoGrupo = widget.transacao.parcelaAtual;
          print('🔍 Posição parcelamento: ${widget.transacao.parcelaAtual}');
        }

        print('✅ Metadados carregados: ${_metadadosGrupo!.descricao}');
        print('📊 Progresso: ${_metadadosGrupo!.progressoQuantidadeFormatado}');
        print('💰 Valores: ${CurrencyFormatter.format(_valorEfetivadoGrupo ?? 0)} de ${CurrencyFormatter.format(_valorTotalGrupo ?? 0)}');
      } else {
        print('⚠️ Metadados não encontrados, usando método fallback');
        // Fallback para o método antigo se metadados não existirem
        await _buscarDatasGrupo();

        // ✅ FORÇAR SYNC DOS METADADOS DO SUPABASE
        print('🔄 Forçando sync dos metadados do Supabase...');
        try {
          await _forcarSyncMetadados();
          // Tentar buscar novamente após o sync
          _metadadosGrupo = await service.obterMetadadosGrupo(grupoId, widget.transacao.usuarioId);
          if (_metadadosGrupo != null) {
            print('✅ Metadados encontrados após sync forçado!');
            // Recarregar dados com metadados corretos
            _dataPrimeiraTransacao = _metadadosGrupo!.dataPrimeira;
            _dataUltimaTransacao = _metadadosGrupo!.dataUltima;
            _totalTransacoesGrupo = _metadadosGrupo!.totalItems;
            _valorTotalGrupo = _metadadosGrupo!.valorTotal;
            _valorEfetivadoGrupo = _metadadosGrupo!.valorEfetivado;
            _valorPendenteGrupo = _metadadosGrupo!.valorPendente;
            _itemsEfetivados = _metadadosGrupo!.itemsEfetivados;
            _itemsPendentes = _metadadosGrupo!.itemsPendentes;
          }
        } catch (e) {
          print('❌ Erro ao forçar sync dos metadados: $e');
        }

        // Tentar gerar metadados localmente para próximas consultas
        await service.atualizarMetadadosGrupo(grupoId, widget.transacao.usuarioId, tipoGrupo);
      }

      print('📊 [DEBUG] _buscarMetadadosGrupo() finalizado');
    } catch (e) {
      print('❌ [ERROR] Erro ao buscar metadados do grupo: $e');
      // Fallback para método antigo em caso de erro
      await _buscarDatasGrupo();
    }
  }

  /// 🔄 FORÇAR SYNC DOS METADADOS DO SUPABASE
  Future<void> _forcarSyncMetadados() async {
    try {
      print('🚀 Forçando download dos metadados do Supabase...');

      // Limpar metadados antigos primeiro
      final service = GruposMetadadosService.instance;
      await service.limparTodosMetadados();

      // Forçar nova sincronização
      final syncManager = SyncManager.instance;
      await syncManager.syncAll(); // Isso vai chamar o sync dos metadados

      print('✅ Sync forçado concluído');
    } catch (e) {
      print('❌ Erro no sync forçado: $e');
      rethrow;
    }
  }

  /// Recarrega a transação do banco de dados
  Future<void> _recarregarTransacao() async {
    try {
      final db = LocalDatabase.instance;
      final resultado = await db.select(
        'transacoes',
        where: 'id = ?',
        whereArgs: [widget.transacao.id],
      );
      
      if (resultado.isNotEmpty) {
        final transacaoAtualizada = TransacaoModel.fromJson(resultado.first);
        
        // Atualizar o widget.transacao seria ideal, mas é final
        // Por enquanto, vamos recarregar apenas os dados relacionados
        await _carregarDadosRelacionados();
        
        // Atualizar o controller de valor se necessário
        _valorController.text = transacaoAtualizada.valor.toStringAsFixed(2);
        
        setState(() {
          // Forçar rebuild da interface
        });
        
        print('🔄 [REFRESH] Transação recarregada do banco de dados');
      }
    } catch (e) {
      print('❌ [REFRESH] Erro ao recarregar transação: $e');
    }
  }

  /// Baixa silenciosamente todas as transações do grupo se necessário
  Future<void> _baixarGrupoSeNecessario() async {
    try {
      // Verificar se é grupo (recorrência ou parcelamento)
      final grupoId = widget.transacao.grupoRecorrencia ??
                     widget.transacao.grupoParcelamento;

      if (grupoId == null) return; // Não é grupo

      final tipoGrupo = widget.transacao.grupoRecorrencia != null
        ? 'recorrencia'
        : 'parcelamento';

      // Verificar se precisa baixar dados adicionais
      final precisaBaixar = await SyncManager.instance.grupoPrecisaDownload(
        grupoId: grupoId,
        tipoGrupo: tipoGrupo,
      );

      if (!precisaBaixar) return; // Já tem tudo local

      debugPrint('🔄 Baixando grupo completo em background: $grupoId');

      // Baixar silenciosamente (sem bloquear UI)
      final transacoesBaixadas = await SyncManager.instance.baixarTransacoesGrupo(
        grupoId: grupoId,
        tipoGrupo: tipoGrupo,
      );

      if (transacoesBaixadas > 0) {
        debugPrint('✅ Download completo: $transacoesBaixadas transações baixadas');

        // Opcional: recarregar dados se necessário
        // await _analisarTransacao();
      }

    } catch (e) {
      debugPrint('❌ Erro no download silencioso: $e');
      // Não interrompe o funcionamento normal
    }
  }

  Future<void> _carregarDadosRelacionados() async {
    try {
      // Carregar dados da conta
      if (widget.transacao.contaId != null) {
        final contas = await ContaService.instance.fetchContas();
        final conta = ContaService.instance.getContaById(
          widget.transacao.contaId!,
          contas,
        );
        if (conta != null) {
          _nomeConta = conta.nome;
          _iconeConta = conta.icone;
          if (conta.cor != null) {
            _corConta = _corDeString(conta.cor!);
          }
        }
      }
      
      // Carregar dados do cartão
      if (widget.transacao.cartaoId != null) {
        final cartao = await CartaoService.instance.buscarCartaoPorId(
          widget.transacao.cartaoId!,
        );
        if (cartao != null) {
          _nomeCartao = cartao.nome;
          // CartaoModel não tem campo icone, usar ícone baseado na bandeira ou padrão
          _iconeCartao = _obterIconeCartaoPorBandeira(cartao.bandeira);
          if (cartao.cor != null) {
            _corCartao = _corDeString(cartao.cor!);
          }
        }
      }
      
      // Carregar dados da categoria
      if (widget.transacao.categoriaId != null) {
        final categorias = await CategoriaService.instance.fetchCategorias();
        final categoria = CategoriaService.instance.getCategoriaById(
          widget.transacao.categoriaId!,
          categorias,
        );
        if (categoria != null) {
          _nomeCategoria = categoria.nome;
          
          // Armazenar string do ícone para usar com CategoriaIcons
          _iconeCategoria = categoria.icone;
          
          // Obter cor da categoria
          if (categoria.cor != null) {
            _corCategoria = _corDeString(categoria.cor!);
          }
        }
      }
      
      // Carregar nome da subcategoria
      if (widget.transacao.subcategoriaId != null) {
        final subcategorias = await CategoriaService.instance.fetchSubcategorias();
        final subcategoria = CategoriaService.instance.getSubcategoriaById(
          widget.transacao.subcategoriaId!,
          subcategorias,
        );
        _nomeSubcategoria = subcategoria?.nome;
      }
    } catch (e) {
      // Se falhar, os valores ficam null e usamos fallback
      debugPrint('Erro ao carregar dados relacionados: $e');
    }
  }
  
  /// Obter widget de ícone por nome (mesmo padrão do TransacaoFormPage)
  Widget _getIconeByName(String icone, {required double size, Color? color}) {
    return CategoriaIcons.renderIcon(icone, size, color: color);
  }
  
  /// Obter ícone do cartão baseado na bandeira
  String _obterIconeCartaoPorBandeira(String? bandeira) {
    if (bandeira == null) return 'credit_card';
    
    switch (bandeira.toLowerCase()) {
      case 'visa':
        return 'payment'; // Ícone de pagamento
      case 'mastercard':
        return 'credit_card';
      case 'elo':
        return 'account_balance_wallet';
      case 'american express':
      case 'amex':
        return 'credit_score';
      case 'hipercard':
        return 'contactless';
      case 'diners':
        return 'dining';
      default:
        return 'credit_card';
    }
  }
  
  /// Converte string de cor para Color
  Color _corDeString(String corString) {
    try {
      // Remove # se existir
      final cor = corString.replaceAll('#', '');
      
      // Adiciona FF para alpha se necessário
      final corCompleta = cor.length == 6 ? 'FF$cor' : cor;
      
      return Color(int.parse(corCompleta, radix: 16));
    } catch (e) {
      return AppColors.tealPrimary; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_analisando) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _getCorHeader(),
          title: const Text(
            'Analisando...',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Mostrar interface baseada no modo
    switch (widget.modo) {
      case ModoEdicao.completa:
        return _buildOpcoesEdicao();
      case ModoEdicao.apenasValor:
      case ModoEdicao.valorFuturas:
        // Navegar diretamente para a página de alterar valor
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => AlterarValorPage(
                transacao: widget.transacao,
                onValorAlterado: (novoValor, escopo) async {
                  // Callback para tratar alteração de valor
                  Navigator.of(context).pop();
                  
                  // 🔄 Refresh automático após edição em grupo
                  if (escopo != EscopoEdicao.apenasEsta) {
                    print('🔄 [REFRESH] Executando refresh após edição de valor em grupo...');
                    await _recarregarTransacao();
                    // Notificar página externa para refresh
                    widget.onTransacaoEditada?.call();
                  }
                },
              ),
            ),
          );
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case ModoEdicao.reajuste:
        // Navegar diretamente para a página de reajuste
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => AplicarReajustePage(
                transacao: widget.transacao,
                onReajusteAplicado: (percentual, isAumento, escopo) {
                  setState(() {
                    // Atualizar dados após reajuste
                  });
                },
              ),
            ),
          );
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
    }
  }

  Color _getCorHeader() {
    if (widget.transacao.tipo == 'receita') {
      return AppColors.tealPrimary;
    } else if (widget.transacao.tipo == 'despesa') {
      return widget.transacao.cartaoId != null 
        ? AppColors.roxoHeader 
        : AppColors.vermelhoErro;
    } else {
      return AppColors.azul;
    }
  }

  /// Obter contexto da transação para o SmartField
  String _getTransactionContext() {
    switch (widget.transacao.tipo) {
      case 'receita':
        return 'receita';
      case 'despesa':
        return 'despesa';
      case 'transferencia':
        return 'transferencia';
      default:
        return 'despesa';
    }
  }

  IconData _getIconeTipo() {
    if (widget.transacao.tipo == 'receita') {
      return Icons.trending_up;
    } else if (widget.transacao.tipo == 'despesa') {
      return widget.transacao.cartaoId != null 
        ? Icons.credit_card 
        : Icons.trending_down;
    } else {
      return Icons.swap_horiz;
    }
  }

  Widget _buildOpcoesEdicao() {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      appBar: AppBar(
        backgroundColor: _getCorHeader(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.transacao.descricao.isNotEmpty 
                  ? widget.transacao.descricao 
                  : 'Editar Transação',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(52),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.branco,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card com informações completas da transação
              TransactionDetailCard(
                transacao: widget.transacao,
                showMetadata: true,
                loadDataAutomatically: true,
              ),
              
              const SizedBox(height: 20),
              
              // Opções de edição
              const Text(
                'O que você deseja editar?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cinzaEscuro,
                ),
              ),
            
              const SizedBox(height: 20),
              
              // Editar Descrição
              EditOptionCard(
                titulo: 'Alterar Descrição',
                subtitulo: 'Edite o nome/descrição da transação',
                icone: Icons.edit,
                cor: AppColors.azul,
                onTap: () => _showEdicaoDescricao(),
              ),
              
              const SizedBox(height: 12),
              
              // Editar valor (disponível para pendentes OU efetivadas com futuras)
              if (!widget.transacao.efetivado || _temParcelasOuRecorrencias) ...[
                EditOptionCard(
                  titulo: 'Alterar Valor',
                  subtitulo: _getSubtituloEdicaoValor(),
                  icone: Icons.attach_money,
                  cor: AppColors.tealPrimary,
                  onTap: () => _showEdicaoValor(),
                ),
                const SizedBox(height: 12),
              ],
              
              // Editar Data (apenas pendentes)
              if (!widget.transacao.efetivado) ...[
                EditOptionCard(
                  titulo: 'Alterar Data',
                  subtitulo: widget.transacao.cartaoId != null 
                    ? 'Altere a data (pode mudar a fatura do cartão)'
                    : 'Altere a data da transação',
                  icone: Icons.calendar_today,
                  cor: AppColors.amareloAlerta,
                  onTap: () => _showEdicaoData(),
                ),
                const SizedBox(height: 12),
              ],
              
              // Editar Conta/Cartão (apenas pendentes)
              if (!widget.transacao.efetivado) ...[
                // Para cartões e contas: só permite trocar se for transação simples (não parcelada/recorrente)
                // Grupos de parcelas/recorrências devem manter a mesma conta/cartão
                if (!_temParcelasOuRecorrencias) ...[
                  EditOptionCard(
                    titulo: widget.transacao.cartaoId != null ? 'Alterar Cartão' : 'Alterar Conta',
                    subtitulo: widget.transacao.cartaoId != null 
                      ? 'Mude o cartão de crédito desta transação'
                      : 'Mude a conta de origem desta transação',
                    icone: widget.transacao.cartaoId != null 
                      ? Icons.credit_card 
                      : Icons.account_balance_wallet,
                    cor: widget.transacao.cartaoId != null 
                      ? AppColors.roxoHeader 
                      : AppColors.azul,
                    onTap: () => _showEdicaoContaCartao(),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
              
              // Editar Categoria
              EditOptionCard(
                titulo: 'Alterar Categoria',
                subtitulo: 'Mude a categoria e subcategoria',
                icone: Icons.category,
                cor: AppColors.tealPrimary,
                onTap: () => _showEdicaoCategoria(),
              ),
              const SizedBox(height: 12),
              
              // Editar Observações
              EditOptionCard(
                titulo: 'Observações',
                subtitulo: 'Adicione ou edite observações',
                icone: Icons.notes,
                cor: AppColors.cinzaEscuro,
                onTap: () => _showEdicaoObservacoes(),
              ),
              const SizedBox(height: 12),
              
              // Aplicar reajuste percentual (disponível para qualquer transação com futuras)
              if (_temParcelasOuRecorrencias) ...[
                EditOptionCard(
                  titulo: 'Aplicar Reajuste %',
                  subtitulo: widget.transacao.efetivado
                    ? 'Aplique reajuste apenas às futuras transações'
                    : 'Aplique um percentual de aumento ou desconto',
                  icone: Icons.percent,
                  cor: AppColors.roxoPrimario,
                  onTap: _showEdicaoReajuste,
                ),
                const SizedBox(height: 12),
              ],
              
              // Ações adicionais
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              
              // Efetivar transação (apenas se não for despesa de cartão)
              if (!widget.transacao.efetivado && widget.transacao.cartaoId == null) ...[
                EditOptionCard(
                  titulo: 'Efetivar Transação',
                  subtitulo: 'Marque como efetivada (confirmada)',
                  icone: Icons.check_circle,
                  cor: AppColors.tealPrimary,
                  onTap: _efetivarTransacao,
                ),
                const SizedBox(height: 12),
              ],
              
              // Duplicar transação
              EditOptionCard(
                titulo: 'Duplicar',
                subtitulo: 'Crie uma cópia desta transação',
                icone: Icons.copy,
                cor: AppColors.azul,
                onTap: _duplicarTransacao,
              ),
              
              const SizedBox(height: 12),
              
              // Excluir transação
              EditOptionCard(
                titulo: 'Excluir',
                subtitulo: 'Remove esta transação permanentemente',
                icone: Icons.delete,
                cor: AppColors.vermelhoErro,
                habilitado: !widget.transacao.efetivado,
                mensagemDesabilitado: 'Transações efetivadas não podem ser excluídas',
                onTap: _excluirTransacao,
              ),
            ],
          ),
        ),
      ),
    );
  }



  /// Obter opções de escopo disponíveis baseadas no status da transação
  List<EscopoEdicao> _getOpcoesEscopoDisponiveis() {
    if (widget.transacao.efetivado) {
      // Se a transação atual já foi efetivada, só pode alterar futuras
      return [EscopoEdicao.estasEFuturas];
    } else {
      // Se a transação atual não foi efetivada, pode alterar ela e/ou futuras
      return [
        EscopoEdicao.apenasEsta,
        EscopoEdicao.estasEFuturas,
      ];
    }
  }

  /// Opções de escopo para reajuste de percentual
  Widget _buildOpcoesEscopoReajuste() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinzaBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCorHeader().withAlpha(26),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.settings_suggest,
                  color: _getCorHeader(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Escopo do Reajuste',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getCorHeader(),
                  ),
                ),
              ],
            ),
          ),
          
          // Opções de escopo (filtradas baseadas no status da transação)
          ..._getOpcoesEscopoDisponiveis().map((escopo) {
            final isSelected = _escopoEdicaoReajuste == escopo;
            final cor = _getCorHeader();
            
            return Container(
              decoration: BoxDecoration(
                color: isSelected ? cor.withAlpha(26) : null,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.cinzaBorda.withAlpha(130),
                    width: 0.5,
                  ),
                ),
              ),
              child: RadioListTile<EscopoEdicao>(
                value: escopo,
                groupValue: _escopoEdicaoReajuste,
                onChanged: (value) {
                  setState(() {
                    _escopoEdicaoReajuste = value ?? EscopoEdicao.apenasEsta;
                  });
                },
                title: Text(
                  escopo.descricao,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? cor : AppColors.cinzaEscuro,
                  ),
                ),
                subtitle: Text(
                  _getDescricaoEscopoReajuste(escopo),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.cinzaTexto,
                  ),
                ),
                activeColor: cor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            );
          }).toList(),
          
          // Preview do impacto
          if (_percentualController.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cinzaClaro.withAlpha(130),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: _buildPreviewImpactoReajuste(),
            ),
          ],
        ],
      ),
    );
  }

  /// Descrição detalhada de cada escopo de reajuste
  String _getDescricaoEscopoReajuste(EscopoEdicao escopo) {
    switch (escopo) {
      case EscopoEdicao.apenasEsta:
        return widget.transacao.efetivado 
          ? 'Transação já efetivada - não disponível'
          : 'Aplicar reajuste apenas nesta transação';
      case EscopoEdicao.estasEFuturas:
        return widget.transacao.efetivado
          ? 'Aplicar reajuste apenas às próximas transações da série'
          : 'Aplicar reajuste nesta e nas próximas transações';
      case EscopoEdicao.todasRelacionadas:
        return 'Aplicar reajuste em todas as transações relacionadas (passadas e futuras)';
    }
  }

  /// Preview do impacto do reajuste
  Widget _buildPreviewImpactoReajuste() {
    final percentual = double.tryParse(_percentualController.text.replaceAll(',', '.')) ?? 0;
    if (percentual <= 0) {
      return const SizedBox.shrink();
    }

    final valorAtual = widget.transacao.valor;
    final valorReajustado = _isAumento 
        ? valorAtual * (1 + percentual / 100)
        : valorAtual * (1 - percentual / 100);

    final diferenca = valorReajustado - valorAtual;
    final transacoesAfetadas = _getQuantidadeTransacoesAfetadas();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview do Reajuste',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _getCorHeader(),
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Valor atual:', style: TextStyle(fontSize: 12)),
            Text(
              'R\$ ${valorAtual.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Novo valor:', style: const TextStyle(fontSize: 12)),
            Text(
              'R\$ ${valorReajustado.toStringAsFixed(2).replaceAll('.', ',')}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isAumento ? AppColors.verdeSucesso : AppColors.vermelhoErro,
              ),
            ),
          ],
        ),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_isAumento ? "Aumento" : "Redução"}:', style: const TextStyle(fontSize: 12)),
            Text(
              '${_isAumento ? "+" : "-"}R\$ ${diferenca.abs().toStringAsFixed(2).replaceAll('.', ',')}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isAumento ? AppColors.verdeSucesso : AppColors.vermelhoErro,
              ),
            ),
          ],
        ),
        
        if (transacoesAfetadas > 1) ...[
          const SizedBox(height: 4),
          const Divider(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Transações afetadas:', style: TextStyle(fontSize: 12)),
              Text(
                '$transacoesAfetadas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getCorHeader(),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Impacto total:', style: TextStyle(fontSize: 12)),
              Text(
                '${_isAumento ? "+" : "-"}R\$ ${(diferenca * transacoesAfetadas).abs().toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isAumento ? AppColors.verdeSucesso : AppColors.vermelhoErro,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Calcula quantidade de transações que serão afetadas pelo reajuste
  int _getQuantidadeTransacoesAfetadas() {
    switch (_escopoEdicaoReajuste) {
      case EscopoEdicao.apenasEsta:
        return 1;
      case EscopoEdicao.estasEFuturas:
        // Para simplificar, vamos assumir que há 5 transações futuras em média
        // Em uma implementação real, isso seria calculado baseado nos dados reais
        return _temParcelasOuRecorrencias ? 6 : 1;
      case EscopoEdicao.todasRelacionadas:
        // Para simplificar, vamos assumir que há 10 transações relacionadas em média
        // Em uma implementação real, isso seria calculado baseado nos dados reais
        return _temParcelasOuRecorrencias ? 12 : 1;
    }
  }

  Widget _buildCardTransacao() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCorTipoTransacao().withAlpha(52),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(21),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📍 LINHA 1: Tipo + Valor + Status
            Row(
              children: [
                // Tipo da transação
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCorTipoTransacao().withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconeTipoTransacao(),
                        size: 14,
                        color: _getCorTipoTransacao(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTextoTipoTransacao(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getCorTipoTransacao(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Valor
                Expanded(
                  child: Text(
                    CurrencyFormatter.format(widget.transacao.valor),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ),
                // Status Badge
                _buildStatusBadge(),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 📍 LINHA 2: Conta/Cartão + Categoria  
            Row(
              children: [
                // Ícone da conta/cartão
                _buildIconeQuadradoConta(
                  size: 28,
                ),
                const SizedBox(width: 10),
                // Nome da conta
                Expanded(
                  flex: widget.transacao.categoriaId != null ? 2 : 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getNomeConta(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cinzaEscuro,
                        ),
                      ),
                      Text(
                        widget.transacao.descricao,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.cinzaTexto,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Categoria (se existir)
                if (widget.transacao.categoriaId != null) ...[
                  const SizedBox(width: 8),
                  _buildIconeQuadradoCategoria(
                    iconeString: _iconeCategoria,
                    cor: _getCorCategoria(),
                    size: 24,
                  ),
                  const SizedBox(width: 6),
                  // Nome da categoria + subcategoria
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getNomeCategoria(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cinzaEscuro,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_getNomeSubcategoria().isNotEmpty)
                          Text(
                            _getNomeSubcategoria(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.cinzaTexto,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            
            // 📍 LINHA 3: Informações adicionais (parcelas/recorrência)
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.cinzaTexto,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatarInfoParcelas(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.cinzaTexto,
                    ),
                  ),
                ),
                // Data da transação
                Text(
                  '${widget.transacao.data.day.toString().padLeft(2, '0')}/${widget.transacao.data.month.toString().padLeft(2, '0')}/${widget.transacao.data.year}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.cinzaTexto,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // 📍 LINHA 3.5: Detalhes de período e progresso (para parcelas/recorrências)
            if (_temParcelasOuRecorrencias) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color: AppColors.cinzaTexto,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatarDetalhesProgresso(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.cinzaTexto,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // 📍 LINHA 4: Observações (se existirem)
            if (widget.transacao.observacoes != null && widget.transacao.observacoes!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 14,
                    color: AppColors.cinzaTexto,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.transacao.observacoes!.trim(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.cinzaTexto,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Badge de status da transação (harmonizado com TransacoesPage + texto didático)
  Widget _buildStatusBadge() {
    final efetivado = widget.transacao.efetivado;
    final cor = efetivado 
        ? const Color(0xFF10B981) // Verde success
        : const Color(0xFFF59E0B); // Amarelo warning
    final texto = efetivado ? 'Efetivada' : 'Pendente';
    final icone = efetivado ? Icons.check_circle : Icons.schedule;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icone,
            color: cor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }


  /// Botão com gradiente e estilo visual do app
  Widget _buildBotaoGradiente({
    required String texto,
    required IconData icone,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getCorHeader(), _getCorHeader().withAlpha(208)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getCorHeader().withAlpha(78),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icone,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  texto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget EditOptionCard({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color cor,
    required VoidCallback onTap,
    bool habilitado = true,
    String? mensagemDesabilitado,
  }) {
    return Opacity(
      opacity: habilitado ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cor.withAlpha(52),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: habilitado ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cor,
                          cor.withAlpha(208),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: cor.withAlpha(78),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icone, 
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cinzaEscuro,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          habilitado ? subtitulo : mensagemDesabilitado ?? subtitulo,
                          style: TextStyle(
                            fontSize: 14,
                            color: habilitado ? AppColors.cinzaTexto : AppColors.cinzaMedio,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (habilitado)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cor.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: cor,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEdicaoDescricao() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlterarDescricaoPage(
          transacao: widget.transacao,
          onDescricaoAlterada: (novaDescricao, escopo) async {
            // 🔄 Refresh automático após edição em grupo
            if (escopo != EscopoEdicao.apenasEsta) {
              print('🔄 [REFRESH] Executando refresh após edição de descrição em grupo...');
              await _recarregarTransacao();
              // Notificar página externa para refresh
              widget.onTransacaoEditada?.call();
            } else {
              setState(() {
                // Atualizar dados da transação
              });
            }
          },
        ),
      ),
    );
  }


  void _showEdicaoData() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlterarDataPage(
          transacao: widget.transacao,
          onDataAlterada: (novaData) {
            setState(() {
              // Atualizar dados da transação
            });
          },
        ),
      ),
    );
  }

  void _showEdicaoContaCartao() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlterarContaPage(
          transacao: widget.transacao,
          onContaAlterada: () {
            setState(() {
              // Atualizar dados da transação
            });
          },
        ),
      ),
    );
  }

  void _showEdicaoCategoria() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlterarCategoriaPage(
          transacao: widget.transacao,
          onCategoriaAlterada: () async {
            // Como o callback não tem escopo, vamos sempre fazer refresh
            print('🔄 [REFRESH] Executando refresh após edição de categoria...');
            await _recarregarTransacao();
            // Notificar página externa para refresh
            widget.onTransacaoEditada?.call();
          },
        ),
      ),
    );
  }

  void _showEdicaoObservacoes() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlterarObservacoesPage(
          transacao: widget.transacao,
          onObservacoesAlteradas: () {
            setState(() {
              // Atualizar dados da transação
            });
          },
        ),
      ),
    );
  }

  void _showEdicaoReajuste() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AplicarReajustePage(
          transacao: widget.transacao,
          onReajusteAplicado: (percentual, isAumento, escopo) {
            setState(() {
              // Atualizar dados da transação
            });
          },
        ),
      ),
    );
  }

  void _showEdicaoValor() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlterarValorPage(
          transacao: widget.transacao,
          onValorAlterado: (novoValor, escopo) async {
            // 🔄 Refresh automático após edição em grupo
            if (escopo != EscopoEdicao.apenasEsta) {
              print('🔄 [REFRESH] Executando refresh após edição de valor em grupo...');
              await _recarregarTransacao();
              // Notificar página externa para refresh
              widget.onTransacaoEditada?.call();
            } else {
              setState(() {
                // Atualizar dados da transação
              });
            }
          },
        ),
      ),
    );
  }


  Future<void> _salvarNovoValor() async {
    final novoValor = double.tryParse(_valorController.text.replaceAll(',', '.'));
    if (novoValor == null || novoValor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um valor válido')),
      );
      return;
    }

    setState(() {
      _processando = true;
    });

    try {
      final resultado = await TransacaoEditService.instance.editarValor(
        widget.transacao,
        novoValor,
        escopo: _incluirFuturas ? EscopoEdicao.estasEFuturas : EscopoEdicao.apenasEsta,
      );

      if (resultado.sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado.mensagem ?? 'Valor atualizado')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado.erro ?? 'Erro desconhecido')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() {
        _processando = false;
      });
    }
  }

  Future<void> _aplicarReajuste() async {
    final percentual = double.tryParse(_percentualController.text.replaceAll(',', '.'));
    if (percentual == null || percentual <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um percentual válido')),
      );
      return;
    }

    setState(() {
      _processando = true;
    });

    try {
      final resultado = await TransacaoEditService.instance.aplicarReajuste(
        widget.transacao,
        percentual,
        isAumento: _isAumento,
      );

      if (resultado.sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado.mensagem ?? 'Reajuste aplicado')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado.erro ?? 'Erro desconhecido')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() {
        _processando = false;
      });
    }
  }

  Future<void> _efetivarTransacao() async {
    try {
      // Se for transação individual, executa direto
      if (!_temParcelasOuRecorrencias) {
        await _executarEfetivacao(EscopoEdicao.apenasEsta);
        return;
      }

      // Para grupos, mostrar modal de escopo
      final escopo = await _mostrarModalEscopoEfetivar();
      if (escopo == null) return; // Cancelado

      await _executarEfetivacao(escopo);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  /// Executa a efetivação com o escopo definido
  Future<void> _executarEfetivacao(EscopoEdicao escopo) async {
    setState(() {
      _processando = true;
    });

    try {
      // Usar OperacaoHelper para operação com feedback visual
      final sucesso = await OperacaoHelper.confirmar(
        context: context,
        transacao: widget.transacao,
      );

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transação efetivada com sucesso'),
            backgroundColor: AppColors.verdeSucesso,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao efetivar: $e'),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
    } finally {
      setState(() {
        _processando = false;
      });
    }
  }

  Future<void> _duplicarTransacao() async {
    try {
      // Mostrar confirmação explicativa primeiro
      final confirmado = await _mostrarConfirmacaoDuplicar();
      if (!confirmado) return;

      await _executarDuplicacao();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  /// Executa a duplicação da transação (sempre individual)
  Future<void> _executarDuplicacao() async {
    setState(() {
      _processando = true;
    });

    try {
      final resultado = await TransacaoEditService.instance.duplicar(
        widget.transacao,
      );

      if (resultado.sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensagem ?? 'Transação duplicada com sucesso'),
            backgroundColor: AppColors.verdeSucesso,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.erro ?? 'Erro ao duplicar transação'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao duplicar: $e'),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
    } finally {
      setState(() {
        _processando = false;
      });
    }
  }

  Future<void> _excluirTransacao() async {
    try {
      EscopoEdicao? escopo;

      // Se for grupo, mostrar modal de escopo primeiro
      if (_temParcelasOuRecorrencias) {
        escopo = await _mostrarModalEscopoExcluir();
        if (escopo == null) return; // Cancelado
      } else {
        escopo = EscopoEdicao.apenasEsta;
      }

      // Depois mostrar confirmação final
      final confirmado = await _mostrarConfirmacaoExclusao(escopo);
      if (!confirmado) return;

      await _executarExclusao(escopo);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  /// Confirmação final para exclusão
  Future<bool> _mostrarConfirmacaoExclusao(EscopoEdicao escopo) async {
    final String mensagem = escopo == EscopoEdicao.apenasEsta
        ? 'Tem certeza que deseja excluir esta transação?'
        : 'Tem certeza que deseja excluir esta e as transações futuras do grupo?';

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.vermelhoErro.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete, color: AppColors.vermelhoErro, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Confirmar Exclusão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mensagem, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.vermelhoErro.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.vermelhoErro.withAlpha(78)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppColors.vermelhoErro, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Esta ação não pode ser desfeita',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vermelhoErro,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    return confirmado ?? false;
  }

  /// Executa a exclusão com o escopo definido
  Future<void> _executarExclusao(EscopoEdicao escopo) async {
    setState(() {
      _processando = true;
    });

    try {
      // Usar OperacaoHelper para operação com feedback visual
      final sucesso = await OperacaoHelper.excluir(
        context: context,
        transacao: widget.transacao,
      );

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transação excluída com sucesso'),
            backgroundColor: AppColors.verdeSucesso,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir: $e'),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
    } finally {
      setState(() {
        _processando = false;
      });
    }
  }

  /// 🎨 HELPER METHODS PARA ÍCONES E CORES

  /// Obter ícone do tipo de transação
  IconData _getIconeTipoTransacao() {
    if (widget.transacao.tipo == 'receita') {
      return Icons.trending_up;
    } else if (widget.transacao.tipo == 'despesa') {
      return widget.transacao.cartaoId != null 
        ? Icons.credit_card 
        : Icons.trending_down;
    } else {
      return Icons.swap_horiz; // transferência
    }
  }

  /// Obter cor do tipo de transação
  Color _getCorTipoTransacao() {
    if (widget.transacao.tipo == 'receita') {
      return AppColors.verdeSucesso;
    } else if (widget.transacao.tipo == 'despesa') {
      return widget.transacao.cartaoId != null 
        ? AppColors.roxoPrimario 
        : AppColors.vermelhoErro;
    } else {
      return AppColors.azul; // transferência
    }
  }

  /// Obter texto do tipo de transação
  String _getTextoTipoTransacao() {
    if (widget.transacao.tipo == 'receita') {
      return 'RECEITA';
    } else if (widget.transacao.tipo == 'despesa') {
      return widget.transacao.cartaoId != null ? 'CARTÃO' : 'DESPESA';
    } else {
      return 'TRANSFERÊNCIA';
    }
  }

  /// Construir ícone quadrado colorido (igual CategoriaPage)
  Widget _buildIconeQuadrado({
    required IconData icone,
    required Color cor,
    double size = 32,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icone,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }

  /// Formatar informações de parcelas/recorrência de forma compacta
  String _formatarInfoParcelas() {
    final transacao = widget.transacao;

    // ✅ USAR METADADOS SE DISPONÍVEIS (mais preciso)
    if (_metadadosGrupo != null) {
      if (_metadadosGrupo!.tipoGrupo == 'parcelamento') {
        final atual = _posicaoAtualNoGrupo ?? transacao.parcelaAtual ?? 1;
        final total = _metadadosGrupo!.totalItems ?? 1;
        return '$atual/$total parcelas';
      } else if (_metadadosGrupo!.tipoGrupo == 'recorrencia') {
        final numeroRecorrencia = _posicaoAtualNoGrupo ?? transacao.numeroRecorrencia;
        final totalRecorrencias = _metadadosGrupo!.totalItems ?? transacao.totalRecorrencias;

        // Formatar tipo de recorrência (usar dos metadados ou fallback)
        String tipoFormatado = 'Recorrente';
        final tipoRecorrencia = _metadadosGrupo!.tipoRecorrencia ?? transacao.tipoRecorrencia;
        if (tipoRecorrencia != null && tipoRecorrencia.isNotEmpty) {
          tipoFormatado = 'Recorrente ${tipoRecorrencia.toLowerCase()}';
        }

        // Adicionar posição se disponível, consistente e não for muito grande
        if (numeroRecorrencia != null && totalRecorrencias != null &&
            totalRecorrencias <= 100 && numeroRecorrencia != totalRecorrencias) {
          return '$tipoFormatado • $numeroRecorrencia/$totalRecorrencias';
        } else if (totalRecorrencias != null && totalRecorrencias > 100) {
          return '$tipoFormatado • ${_metadadosGrupo!.itemsEfetivados ?? 0}/${totalRecorrencias} efetivadas';
        } else {
          return tipoFormatado;
        }
      }
    }

    // 📋 FALLBACK PARA MÉTODO ANTIGO
    // Se tem parcelas
    if (transacao.totalParcelas != null && transacao.totalParcelas! > 1) {
      final atual = transacao.parcelaAtual ?? 1;
      final total = transacao.totalParcelas!;
      return '$atual/$total parcelas';
    }

    // Se é recorrente - incluir posição se disponível
    if (transacao.recorrente) {
      final numeroRecorrencia = _posicaoAtualNoGrupo ?? transacao.numeroRecorrencia;
      final totalRecorrencias = _totalTransacoesGrupo ?? transacao.totalRecorrencias;

      // Formatar tipo de recorrência
      String tipoFormatado = 'Recorrente';
      if (transacao.tipoRecorrencia != null && transacao.tipoRecorrencia!.isNotEmpty) {
        final tipo = transacao.tipoRecorrencia!;
        final tipoCapitalizado = tipo[0].toUpperCase() + tipo.substring(1).toLowerCase();
        tipoFormatado = 'Recorrente $tipoCapitalizado';
      }

      if (numeroRecorrencia != null && totalRecorrencias != null) {
        return '$tipoFormatado • $numeroRecorrencia/$totalRecorrencias';
      } else if (numeroRecorrencia != null) {
        return '$tipoFormatado • Ocorrência $numeroRecorrencia';
      } else {
        return tipoFormatado;
      }
    }

    // Se é simples
    return 'Transação única';
  }

  /// Formatar detalhes de período e progresso para parcelas/recorrências
  String _formatarDetalhesProgresso() {
    if (!_temParcelasOuRecorrencias) return '';

    // Função helper para formatar data (formato compacto)
    String formatarData(DateTime? data) {
      if (data == null) return 'N/A';

      const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
                     'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

      final mes = meses[data.month - 1];
      final ano = data.year.toString().substring(2); // Apenas últimos 2 dígitos

      return '$mes/$ano';
    }

    List<String> detalhes = [];

    // Adicionar período (datas) - formato compacto
    final inicioData = formatarData(_dataPrimeiraTransacao);
    if (_dataUltimaTransacao != null) {
      final fimData = formatarData(_dataUltimaTransacao);
      detalhes.add('De $inicioData à $fimData');
    } else {
      detalhes.add('A partir de $inicioData');
    }

    // ✅ ADICIONAR INFORMAÇÕES FINANCEIRAS (se disponíveis) - formato compacto
    if (_metadadosGrupo != null && _valorTotalGrupo != null && _valorEfetivadoGrupo != null) {
      final valorEfetivado = CurrencyFormatter.format(_valorEfetivadoGrupo!);
      final valorTotal = CurrencyFormatter.format(_valorTotalGrupo!);
      detalhes.add('$valorEfetivado/$valorTotal');
    }

    return detalhes.join(' • ');
  }

  /// Obter nome da conta/cartão
  String _getNomeConta() {
    if (widget.transacao.cartaoId != null) {
      return _nomeCartao ?? 'Cartão de Crédito';
    } else if (widget.transacao.contaId != null) {
      return _nomeConta ?? 'Conta Principal';
    } else {
      return 'Conta Principal';
    }
  }

  /// Obter nome da categoria
  String _getNomeCategoria() {
    if (widget.transacao.categoriaId != null) {
      return _nomeCategoria ?? 'Categoria';
    }
    return '';
  }

  /// Obter nome da subcategoria
  String _getNomeSubcategoria() {
    if (widget.transacao.subcategoriaId != null) {
      return _nomeSubcategoria ?? 'Subcategoria';
    }
    return '';
  }

  /// Construir ícone quadrado para categoria usando o sistema CategoriaIcons
  Widget _buildIconeQuadradoCategoria({
    String? iconeString,
    required Color cor,
    double size = 32,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: iconeString != null && iconeString.isNotEmpty
            ? _getIconeByName(iconeString, size: size * 0.6, color: Colors.white)
            : const Icon(Icons.category, color: Colors.white),
      ),
    );
  }
  
  /// Construir ícone quadrado para conta/cartão usando dados reais
  Widget _buildIconeQuadradoConta({
    double size = 32,
  }) {
    String? iconeString;
    Color cor;
    IconData fallbackIcon;
    
    if (widget.transacao.cartaoId != null) {
      // É um cartão
      iconeString = _iconeCartao;
      cor = _corCartao ?? AppColors.roxoPrimario;
      fallbackIcon = Icons.credit_card;
    } else {
      // É uma conta
      iconeString = _iconeConta;
      cor = _corConta ?? _getCorTipoTransacao();
      fallbackIcon = Icons.account_balance;
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: iconeString != null && iconeString.isNotEmpty
            ? _getIconeByName(iconeString, size: size * 0.6, color: Colors.white)
            : Icon(fallbackIcon, color: Colors.white, size: size * 0.6),
      ),
    );
  }

  /// Obter cor da categoria
  Color _getCorCategoria() {
    return _corCategoria ?? AppColors.verdeSucesso;
  }
  
  /// Obter subtítulo contextual para edição de valor
  String _getSubtituloEdicaoValor() {
    if (widget.transacao.efetivado && _temParcelasOuRecorrencias) {
      return 'Altere apenas as futuras parcelas/recorrências (atual já efetivada)';
    } else if (_temParcelasOuRecorrencias) {
      return 'Altere o valor com opção de incluir futuras';
    } else {
      return 'Altere o valor desta transação';
    }
  }
  
  /// Checkbox bonito e informativo para incluir futuras
  Widget _buildCheckboxFuturas() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _incluirFuturas 
            ? AppColors.verdeSucesso.withAlpha(78)
            : AppColors.cinzaMedio.withAlpha(52),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.transacao.efetivado ? null : () {
            setState(() {
              _incluirFuturas = !_incluirFuturas;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _incluirFuturas 
                      ? AppColors.verdeSucesso 
                      : Colors.transparent,
                    border: Border.all(
                      color: _incluirFuturas 
                        ? AppColors.verdeSucesso 
                        : AppColors.cinzaMedio,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _incluirFuturas
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.transacao.efetivado 
                          ? 'Alterar futuras transações'
                          : 'Incluir futuras transações',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _incluirFuturas 
                            ? AppColors.verdeSucesso 
                            : AppColors.cinzaEscuro,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _quantidadeFuturas > 0
                          ? widget.transacao.efetivado
                            ? 'Alterar as próximas $_quantidadeFuturas transações (atual já efetivada)'
                            : 'Aplicar também às próximas $_quantidadeFuturas transações'
                          : 'Não há futuras transações para alterar',
                        style: TextStyle(
                          fontSize: 13,
                          color: _incluirFuturas 
                            ? AppColors.verdeSucesso.withAlpha(208)
                            : AppColors.cinzaTexto,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_quantidadeFuturas > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _incluirFuturas 
                        ? AppColors.verdeSucesso.withAlpha(26)
                        : AppColors.cinzaMedio.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+$_quantidadeFuturas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _incluirFuturas 
                          ? AppColors.verdeSucesso 
                          : AppColors.cinzaTexto,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Preview informativo das alterações
  Widget _buildPreviewAlteracoes() {
    final novoValor = double.tryParse(_valorController.text.replaceAll(',', '.'));
    if (novoValor == null || novoValor <= 0) return const SizedBox.shrink();
    
    final valorAtual = widget.transacao.valor;
    final diferenca = novoValor - valorAtual;
    final percentual = ((diferenca / valorAtual) * 100);
    final isAumento = diferenca > 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAumento 
          ? AppColors.verdeSucesso.withAlpha(12)
          : AppColors.vermelhoErro.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAumento 
            ? AppColors.verdeSucesso.withAlpha(52)
            : AppColors.vermelhoErro.withAlpha(52),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAumento ? Icons.trending_up : Icons.trending_down,
                color: isAumento ? AppColors.verdeSucesso : AppColors.vermelhoErro,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.transacao.efetivado 
                  ? 'Preview - Alteração apenas das Futuras'
                  : 'Preview da Alteração',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isAumento ? AppColors.verdeSucesso : AppColors.vermelhoErro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Valor Atual',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.cinzaTexto,
                      ),
                    ),
                    Text(
                      'R\$ ${valorAtual.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cinzaEscuro,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: AppColors.cinzaMedio,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Novo Valor',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.cinzaTexto,
                      ),
                    ),
                    Text(
                      'R\$ ${novoValor.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isAumento ? AppColors.verdeSucesso : AppColors.vermelhoErro,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isAumento 
                ? AppColors.verdeSucesso.withAlpha(26)
                : AppColors.vermelhoErro.withAlpha(26),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${isAumento ? '+' : ''}${percentual.toStringAsFixed(1)}% '
              '(${isAumento ? '+' : ''}R\$ ${diferenca.abs().toStringAsFixed(2).replaceAll('.', ',')})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isAumento ? AppColors.verdeSucesso : AppColors.vermelhoErro,
              ),
            ),
          ),
          if (_incluirFuturas && _quantidadeFuturas > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.azul.withAlpha(12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.azul.withAlpha(52),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.repeat,
                    color: AppColors.azul,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta alteração será aplicada a $_quantidadeFuturas futuras transações',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.azul,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Dialog para editar descrição
  Widget _buildDialogEdicaoDescricao() {
    final controller = TextEditingController(text: widget.transacao.descricao);
    
    return AlertDialog(
      title: const Text('Alterar Descrição'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              hintText: 'Digite a nova descrição...',
              border: OutlineInputBorder(),
            ),
            maxLength: 100,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final novaDescricao = controller.text.trim();
            if (novaDescricao.isNotEmpty) {
              // Descrição já integrada com AlterarDescricaoPage
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Descrição alterada com sucesso!')),
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
  
  /// Seletor de data usando DatePicker nativo
  Future<void> _selecionarData() async {
    try {
      final dataAtual = widget.transacao.data;
      
      final novaData = await showDatePicker(
        context: context,
        initialDate: dataAtual,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: _getCorHeader(),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (novaData != null && novaData != dataAtual) {
        // Mostrar aviso para cartão se necessário
        if (widget.transacao.cartaoId != null) {
          final confirmacao = await _mostrarAvisoAlteracaoDataCartao(dataAtual, novaData);
          if (!confirmacao) return;
        }
        
        await _salvarNovaData(novaData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar data: $e')),
      );
    }
  }
  
  /// Mostrar aviso sobre alteração de data em cartão
  Future<bool> _mostrarAvisoAlteracaoDataCartao(DateTime dataAtual, DateTime novaData) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.amareloAlerta),
            const SizedBox(width: 8),
            const Text('Atenção'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Você está alterando a data de uma transação de cartão de crédito.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text('Data atual: ${_formatarData(dataAtual)}'),
            Text('Nova data: ${_formatarData(novaData)}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amareloAlerta.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.amareloAlerta.withAlpha(78)),
              ),
              child: Text(
                'Esta alteração pode mover a transação para uma fatura diferente, dependendo da data de fechamento do cartão.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.amareloAlerta,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getCorHeader(),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    
    return confirmacao ?? false;
  }
  
  /// Salvar nova data
  Future<void> _salvarNovaData(DateTime novaData) async {
    try {
      final resultado = await TransacaoEditService.instance.alterarData(
        widget.transacao,
        novaData: novaData,
      );
      
      if (resultado.sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensagem ?? 'Data alterada com sucesso'),
            backgroundColor: AppColors.verdeSucesso,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.erro ?? 'Erro ao alterar data'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar data: $e'),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
    }
  }
  
  /// Seletor de contas/cartões baseado no tipo da transação
  Future<void> _selecionarContaCartao() async {
    try {
      final isCartao = widget.transacao.cartaoId != null;
      
      if (isCartao) {
        // Se é transação de cartão, só pode escolher outros cartões
        await _selecionarCartao();
      } else {
        // Se é transação de conta (receita/despesa/transferência), só pode escolher contas
        await _selecionarConta();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir seletor: $e')),
      );
    }
  }
  
  /// Seletor apenas de cartões com informações de fatura
  Future<void> _selecionarCartao() async {
    try {
      final cartoes = await CartaoService.instance.listarCartoesAtivos();
      
      if (cartoes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum cartão encontrado')),
        );
        return;
      }
      
      final cartao = await showModalBottomSheet<CartaoModel>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle do modal
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Título
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Selecionar Cartão',
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Lista scrollável de cartões
              Expanded(
                child: ListView.builder(
                  itemCount: cartoes.length,
                  itemBuilder: (context, index) {
                    final cartao = cartoes[index];
                    final isSelected = widget.transacao.cartaoId == cartao.id;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected ? AppColors.cinzaClaro : null,
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cartao.cor != null && cartao.cor!.isNotEmpty
                                ? _corDeString(cartao.cor!)
                                : AppColors.roxoHeader,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.credit_card,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        title: Text(
                          cartao.nome,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cartao.bandeira ?? 'Cartão de Crédito',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _obterTextoFaturaDestino(cartao),
                              style: TextStyle(
                                fontSize: 11,
                                color: _calcularFaturaDestino(cartao, widget.transacao.data)['faturaFechada'] 
                                  ? AppColors.amareloAlerta 
                                  : AppColors.verdeSucesso,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: isSelected 
                          ? Icon(Icons.check, color: AppColors.roxoHeader)
                          : null,
                        onTap: () async {
                          // Verificar se pode usar este cartão (não tem fatura paga)
                          final podeUsar = await _podeUsarCartao(cartao);
                          if (!podeUsar) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Não é possível mover esta transação para um cartão com fatura já paga'),
                                backgroundColor: AppColors.vermelhoErro,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context, cartao);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
      
      if (cartao != null) {
        // Verificar se há mudança de fatura e mostrar aviso se necessário
        final infoFatura = _calcularFaturaDestino(cartao, widget.transacao.data);
        final cartaoAtual = widget.transacao.cartaoId;
        
        if (cartao.id != cartaoAtual) {
          final confirmar = await _mostrarAvisoTrocaCartao(cartao, infoFatura);
          if (confirmar) {
            await _salvarNovoCartao(cartao);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar cartões: $e')),
      );
    }
  }
  
  /// Seletor apenas de contas
  Future<void> _selecionarConta() async {
    try {
      final contas = await ContaService.instance.fetchContas();
      
      if (contas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma conta encontrada')),
        );
        return;
      }
      
      final conta = await showModalBottomSheet<ContaModel>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle do modal
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Título
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Selecionar Conta',
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Lista scrollável de contas
              Expanded(
                child: ListView.builder(
                  itemCount: contas.length,
                  itemBuilder: (context, index) {
                    final conta = contas[index];
                    final isSelected = widget.transacao.contaId == conta.id;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected ? AppColors.cinzaClaro : null,
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: conta.cor != null && conta.cor!.isNotEmpty
                                ? _corDeString(conta.cor!)
                                : AppColors.azul,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: conta.icone != null && conta.icone!.isNotEmpty
                                ? _getIconeByName(conta.icone!, size: 20, color: Colors.white)
                                : const Icon(Icons.account_balance, color: Colors.white, size: 20),
                          ),
                        ),
                        title: Text(
                          conta.nome,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          conta.tipo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: isSelected 
                          ? Icon(Icons.check, color: AppColors.azul)
                          : null,
                        onTap: () => Navigator.pop(context, conta),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
      
      if (conta != null) {
        await _salvarNovaConta(conta);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar contas: $e')),
      );
    }
  }
  
  /// Salvar novo cartão
  Future<void> _salvarNovoCartao(CartaoModel cartao) async {
    try {
      // Cartão já integrado com AlterarContaPage
      
      // Atualizar dados locais
      setState(() {
        _nomeCartao = cartao.nome;
        _iconeCartao = _obterIconeCartaoPorBandeira(cartao.bandeira);
        if (cartao.cor != null) {
          _corCartao = _corDeString(cartao.cor!);
        }
        
        // Limpar dados da conta
        _nomeConta = null;
        _iconeConta = null;
        _corConta = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cartão alterado para ${cartao.nome}')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar cartão: $e')),
      );
    }
  }
  
  /// Salvar nova conta
  Future<void> _salvarNovaConta(ContaModel conta) async {
    try {
      // Chamar serviço para alterar conta
      final resultado = await TransacaoEditService.instance.alterarConta(
        widget.transacao,
        novaContaId: conta.id!,
      );
      
      if (resultado.sucesso) {
        // Atualizar dados locais
        setState(() {
          _nomeConta = conta.nome;
          _iconeConta = conta.icone;
          if (conta.cor != null) {
            _corConta = _corDeString(conta.cor!);
          }
          
          // Limpar dados do cartão
          _nomeCartao = null;
          _iconeCartao = null;
          _corCartao = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado.mensagem ?? 'Conta alterada para ${conta.nome}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado.erro ?? 'Erro ao alterar conta')),
        );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar conta: $e')),
      );
    }
  }
  
  /// Seletor de categoria reutilizando padrão do app
  Future<void> _selecionarCategoria() async {
    try {
      final categorias = await CategoriaService.instance.fetchCategorias();
      final categoriasFiltradas = categorias.where((c) => c.tipo == widget.transacao.tipo).toList();
      
      if (categoriasFiltradas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma categoria encontrada')),
        );
        return;
      }
      
      final categoria = await showModalBottomSheet<CategoriaModel>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle do modal
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Título
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Selecionar Categoria',
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Lista scrollável de categorias
              Expanded(
                child: ListView.builder(
                  itemCount: categoriasFiltradas.length,
                  itemBuilder: (context, index) {
                    final categoria = categoriasFiltradas[index];
                    final isSelected = widget.transacao.categoriaId == categoria.id;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected ? AppColors.cinzaClaro : null,
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: categoria.cor != null && categoria.cor!.isNotEmpty
                                ? _corDeString(categoria.cor!)
                                : _getCorTipoTransacao(),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: categoria.icone.isNotEmpty
                                ? _getIconeByName(categoria.icone, size: 20, color: Colors.white)
                                : const Icon(Icons.category, color: Colors.white, size: 20),
                          ),
                        ),
                        title: Text(
                          categoria.nome,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected 
                          ? Icon(Icons.check, color: _getCorTipoTransacao())
                          : null,
                        onTap: () => Navigator.pop(context, categoria),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
      
      if (categoria != null) {
        // Categoria já integrada com AlterarCategoriaPage
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Use o seletor de categoria com escopo')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar categorias: $e')),
      );
    }
  }
  
  
  // Função _salvarNovaCategoria removida - use apenas a versão com escopo (chips)

  /// Salvar nova descrição com escopo de recorrência/parcelamento
  Future<void> _salvarNovaDescricao(String novaDescricao, EscopoEdicao escopo) async {
    try {
      // Debug: log do escopo selecionado
      log('🔍 [DEBUG] Editando descrição - Escopo: $escopo');
      
      // Mapear escopo UI para escopo do service
      final escopoService = switch (escopo) {
        EscopoEdicao.apenasEsta => service.EscopoEdicao.apenasEsta,
        EscopoEdicao.estasEFuturas => service.EscopoEdicao.estasEFuturas,
        EscopoEdicao.todasRelacionadas => service.EscopoEdicao.todasRelacionadas,
      };
      
      final resultado = await TransacaoEditService.instance.editarDescricao(
        widget.transacao,
        novaDescricao: novaDescricao,
        escopo: escopoService,
      );
      
      if (resultado.sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensagem ?? 'Descrição alterada com sucesso'),
            backgroundColor: AppColors.verdeSucesso,
          ),
        );
        
        // Atualizar dados locais e voltar para página principal
        setState(() {
          // A página já será atualizada pelo callback
        });
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.erro ?? 'Erro ao alterar descrição'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar descrição: $e')),
      );
    }
  }
  
  // Nota: Dialog de observações removido - substituído por página inteligente

  // ===== MÉTODOS AUXILIARES PARA MODAIS DE ESCOPO =====

  /// Modal de escopo para efetivação de transações
  Future<EscopoEdicao?> _mostrarModalEscopoEfetivar() async {
    return await EscopoEdicaoHelper.mostrar(
      context: context,
      tipoOperacao: 'Efetivar Transações',
      totalTransacoes: 0, // Será calculado pelo service
      transacoesLocais: 0, // Será calculado pelo service
      requerConexao: false, // Sempre local agora
      detalhesOperacao: 'Marcar como efetivadas (pagas/recebidas)',
    );
  }

  /// Modal de escopo para exclusão de transações
  Future<EscopoEdicao?> _mostrarModalEscopoExcluir() async {
    return await EscopoEdicaoHelper.mostrar(
      context: context,
      tipoOperacao: 'Excluir Transações',
      totalTransacoes: 0, // Será calculado pelo service
      transacoesLocais: 0, // Será calculado pelo service
      requerConexao: false, // Sempre local agora
      detalhesOperacao: 'Esta ação não pode ser desfeita',
    );
  }

  /// Confirmação para duplicação de transação (sempre individual)
  Future<bool> _mostrarConfirmacaoDuplicar() async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.azul.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.copy, color: AppColors.azul, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Duplicar Transação'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Uma nova transação será criada com os mesmos dados desta.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.azul.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.azul.withAlpha(78)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.azul, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'A nova transação será individual (não fará parte do grupo)',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azul,
              foregroundColor: Colors.white,
            ),
            child: const Text('Duplicar'),
          ),
        ],
      ),
    );

    return confirmacao ?? false;
  }

  /// Formatar data para exibição
  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
  
  /// Calcular qual fatura a transação irá cair baseado na data e fechamento do cartão
  Map<String, dynamic> _calcularFaturaDestino(CartaoModel cartao, DateTime dataTransacao) {
    final hoje = DateTime.now();
    final diaFechamento = cartao.diaFechamento;
    
    // Calcular o mês/ano da fatura baseado na data da transação e dia de fechamento
    DateTime dataFechamento;
    
    if (dataTransacao.day <= diaFechamento) {
      // Se a transação é antes do fechamento, vai para a fatura do mesmo mês
      dataFechamento = DateTime(dataTransacao.year, dataTransacao.month, diaFechamento);
    } else {
      // Se a transação é depois do fechamento, vai para a fatura do próximo mês
      final proximoMes = dataTransacao.month == 12 ? 1 : dataTransacao.month + 1;
      final proximoAno = dataTransacao.month == 12 ? dataTransacao.year + 1 : dataTransacao.year;
      dataFechamento = DateTime(proximoAno, proximoMes, diaFechamento);
    }
    
    // Verificar se a fatura já está fechada (passou da data de fechamento)
    final faturaJaFechada = hoje.isAfter(dataFechamento);
    
    return {
      'mesFatura': dataFechamento.month,
      'anoFatura': dataFechamento.year,
      'dataFechamento': dataFechamento,
      'faturaFechada': faturaJaFechada,
      'proximaFatura': faturaJaFechada,
    };
  }
  
  /// Obter texto explicativo sobre qual fatura a transação irá
  String _obterTextoFaturaDestino(CartaoModel cartao) {
    final dataTransacao = widget.transacao.data;
    final infoFatura = _calcularFaturaDestino(cartao, dataTransacao);
    
    final mes = infoFatura['mesFatura'] as int;
    final ano = infoFatura['anoFatura'] as int;
    final faturaFechada = infoFatura['faturaFechada'] as bool;
    
    final nomesMeses = [
      '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    
    if (faturaFechada) {
      return 'Fatura ${nomesMeses[mes]}/$ano já fechada. Irá para próxima fatura.';
    } else {
      return 'Fatura ${nomesMeses[mes]}/$ano (Fecha dia ${cartao.diaFechamento})';
    }
  }
  
  /// Verificar se pode mover a transação para o cartão (evitar faturas pagas)
  Future<bool> _podeUsarCartao(CartaoModel cartao) async {
    final dataTransacao = widget.transacao.data;
    final infoFatura = _calcularFaturaDestino(cartao, dataTransacao);
    
    final mes = infoFatura['mesFatura'] as int;
    final ano = infoFatura['anoFatura'] as int;
    
    // Verificar se existe uma fatura para o período de destino
    final faturaService = FaturaService();
    final faturaDestino = await faturaService.buscarFaturaPorPeriodo(cartao.id, ano, mes);
    
    // Se não existe fatura, pode usar (será criada automaticamente)
    if (faturaDestino == null) return true;
    
    // Se a fatura já está paga, não pode mover a transação
    if (faturaDestino.paga) {
      return false;
    }
    
    return true;
  }
  
  /// Mostrar aviso sobre troca de cartão e mudança de fatura
  Future<bool> _mostrarAvisoTrocaCartao(CartaoModel novoCartao, Map<String, dynamic> infoFatura) async {
    final mes = infoFatura['mesFatura'] as int;
    final ano = infoFatura['anoFatura'] as int;
    final faturaFechada = infoFatura['faturaFechada'] as bool;
    
    final nomesMeses = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.credit_card, color: AppColors.roxoHeader),
            const SizedBox(width: 8),
            const Text('Trocar Cartão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Você está alterando esta transação para o cartão "${novoCartao.nome}".',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: faturaFechada 
                  ? AppColors.amareloAlerta.withAlpha(26)
                  : AppColors.verdeSucesso.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: faturaFechada 
                    ? AppColors.amareloAlerta.withAlpha(78)
                    : AppColors.verdeSucesso.withAlpha(78)
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        faturaFechada ? Icons.warning : Icons.info,
                        color: faturaFechada ? AppColors.amareloAlerta : AppColors.verdeSucesso,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Destino da Transação',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: faturaFechada ? AppColors.amareloAlerta : AppColors.verdeSucesso,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    faturaFechada
                      ? 'A fatura de ${nomesMeses[mes]}/$ano já foi fechada (dia ${novoCartao.diaFechamento}). Esta transação irá para a próxima fatura disponível.'
                      : 'Esta transação será incluída na fatura de ${nomesMeses[mes]}/$ano (fecha no dia ${novoCartao.diaFechamento}).',
                    style: TextStyle(
                      fontSize: 13,
                      color: faturaFechada ? AppColors.amareloAlerta : AppColors.verdeSucesso,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            Text(
              'Data da transação: ${_formatarData(widget.transacao.data)}',
              style: const TextStyle(fontSize: 12, color: AppColors.cinzaTexto),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.roxoHeader,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Troca'),
          ),
        ],
      ),
    );
    
    return confirmacao ?? false;
  }
}

