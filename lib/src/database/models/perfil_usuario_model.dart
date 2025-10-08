// 👤 Perfil Usuario Model - iPoupei Mobile
// 
// Modelo de dados para perfil_usuario
// Mapeia exatamente as colunas do Supabase
// 
// Baseado em: Data Model + Type Safety

class PerfilUsuarioModel {
  final String id;
  final String nome;
  final String email;
  final String? avatarUrl;
  final String? telefone;
  final String? dataNascimento;
  final String? profissao;
  final bool perfilPublico;
  final bool aceitaNotificacoes;
  final bool aceitaMarketing;
  final String moedaPadrao;
  final String formatoData;
  final int primeiroDiaSemana;
  final bool diagnosticoCompleto;
  final String? dataDiagnostico;
  final String? sentimentoFinanceiro;
  final String? percepcaoControle;
  final String? percepcaoGastos;
  final String? disciplinaFinanceira;
  final String? relacaoDinheiro;
  final double? rendaMensal;
  final String? tipoRenda;
  final bool contaAtiva;
  final String? dataDesativacao;
  final int? mediaHorasTrabalhadasMes;
  final bool primeiroAcesso;
  final int diagnosticoEtapaAtual;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PerfilUsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
    this.avatarUrl,
    this.telefone,
    this.dataNascimento,
    this.profissao,
    this.perfilPublico = false,
    this.aceitaNotificacoes = true,
    this.aceitaMarketing = false,
    this.moedaPadrao = 'BRL',
    this.formatoData = 'DD/MM/YYYY',
    this.primeiroDiaSemana = 1,
    this.diagnosticoCompleto = false,
    this.dataDiagnostico,
    this.sentimentoFinanceiro,
    this.percepcaoControle,
    this.percepcaoGastos,
    this.disciplinaFinanceira,
    this.relacaoDinheiro,
    this.rendaMensal,
    this.tipoRenda,
    this.contaAtiva = true,
    this.dataDesativacao,
    this.mediaHorasTrabalhadasMes,
    this.primeiroAcesso = true,
    this.diagnosticoEtapaAtual = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria modelo a partir do Map do SQLite
  factory PerfilUsuarioModel.fromSQLite(Map<String, dynamic> map) {
    return PerfilUsuarioModel(
      id: map['id'] as String,
      nome: map['nome'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatar_url'] as String?,
      telefone: map['telefone'] as String?,
      dataNascimento: map['data_nascimento'] as String?,
      profissao: map['profissao'] as String?,
      perfilPublico: (map['perfil_publico'] as int?) == 1,
      aceitaNotificacoes: (map['aceita_notificacoes'] as int?) == 1,
      aceitaMarketing: (map['aceita_marketing'] as int?) == 1,
      moedaPadrao: map['moeda_padrao'] as String? ?? 'BRL',
      formatoData: map['formato_data'] as String? ?? 'DD/MM/YYYY',
      primeiroDiaSemana: map['primeiro_dia_semana'] as int? ?? 1,
      diagnosticoCompleto: (map['diagnostico_completo'] as int?) == 1,
      dataDiagnostico: map['data_diagnostico'] as String?,
      sentimentoFinanceiro: map['sentimento_financeiro'] as String?,
      percepcaoControle: map['percepcao_controle'] as String?,
      percepcaoGastos: map['percepcao_gastos'] as String?,
      disciplinaFinanceira: map['disciplina_financeira'] as String?,
      relacaoDinheiro: map['relacao_dinheiro'] as String?,
      rendaMensal: map['renda_mensal'] as double?,
      tipoRenda: map['tipo_renda'] as String?,
      contaAtiva: (map['conta_ativa'] as int?) == 1,
      dataDesativacao: map['data_desativacao'] as String?,
      mediaHorasTrabalhadasMes: map['media_horas_trabalhadas_mes'] as int?,
      primeiroAcesso: (map['primeiro_acesso'] as int?) == 1,
      diagnosticoEtapaAtual: map['diagnostico_etapa_atual'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Cria modelo a partir do Map do Supabase
  factory PerfilUsuarioModel.fromSupabase(Map<String, dynamic> map) {
    return PerfilUsuarioModel(
      id: map['id'] as String,
      nome: map['nome'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatar_url'] as String?,
      telefone: map['telefone'] as String?,
      dataNascimento: map['data_nascimento'] as String?,
      profissao: map['profissao'] as String?,
      perfilPublico: map['perfil_publico'] as bool? ?? false,
      aceitaNotificacoes: map['aceita_notificacoes'] as bool? ?? true,
      aceitaMarketing: map['aceita_marketing'] as bool? ?? false,
      moedaPadrao: map['moeda_padrao'] as String? ?? 'BRL',
      formatoData: map['formato_data'] as String? ?? 'DD/MM/YYYY',
      primeiroDiaSemana: map['primeiro_dia_semana'] as int? ?? 1,
      diagnosticoCompleto: map['diagnostico_completo'] as bool? ?? false,
      dataDiagnostico: map['data_diagnostico'] as String?,
      sentimentoFinanceiro: map['sentimento_financeiro'] as String?,
      percepcaoControle: map['percepcao_controle'] as String?,
      percepcaoGastos: map['percepcao_gastos'] as String?,
      disciplinaFinanceira: map['disciplina_financeira'] as String?,
      relacaoDinheiro: map['relacao_dinheiro'] as String?,
      rendaMensal: (map['renda_mensal'] as num?)?.toDouble(),
      tipoRenda: map['tipo_renda'] as String?,
      contaAtiva: map['conta_ativa'] as bool? ?? true,
      dataDesativacao: map['data_desativacao'] as String?,
      mediaHorasTrabalhadasMes: map['media_horas_trabalhadas_mes'] as int?,
      primeiroAcesso: map['primeiro_acesso'] as bool? ?? true,
      diagnosticoEtapaAtual: map['diagnostico_etapa_atual'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Converte para Map do SQLite
  Map<String, dynamic> toSQLite() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'avatar_url': avatarUrl,
      'telefone': telefone,
      'data_nascimento': dataNascimento,
      'profissao': profissao,
      'perfil_publico': perfilPublico ? 1 : 0,
      'aceita_notificacoes': aceitaNotificacoes ? 1 : 0,
      'aceita_marketing': aceitaMarketing ? 1 : 0,
      'moeda_padrao': moedaPadrao,
      'formato_data': formatoData,
      'primeiro_dia_semana': primeiroDiaSemana,
      'diagnostico_completo': diagnosticoCompleto ? 1 : 0,
      'data_diagnostico': dataDiagnostico,
      'sentimento_financeiro': sentimentoFinanceiro,
      'percepcao_controle': percepcaoControle,
      'percepcao_gastos': percepcaoGastos,
      'disciplina_financeira': disciplinaFinanceira,
      'relacao_dinheiro': relacaoDinheiro,
      'renda_mensal': rendaMensal,
      'tipo_renda': tipoRenda,
      'conta_ativa': contaAtiva ? 1 : 0,
      'data_desativacao': dataDesativacao,
      'media_horas_trabalhadas_mes': mediaHorasTrabalhadasMes,
      'primeiro_acesso': primeiroAcesso ? 1 : 0,
      'diagnostico_etapa_atual': diagnosticoEtapaAtual,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Converte para Map do Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'avatar_url': avatarUrl,
      'telefone': telefone,
      'data_nascimento': dataNascimento,
      'profissao': profissao,
      'perfil_publico': perfilPublico,
      'aceita_notificacoes': aceitaNotificacoes,
      'aceita_marketing': aceitaMarketing,
      'moeda_padrao': moedaPadrao,
      'formato_data': formatoData,
      'primeiro_dia_semana': primeiroDiaSemana,
      'diagnostico_completo': diagnosticoCompleto,
      'data_diagnostico': dataDiagnostico,
      'sentimento_financeiro': sentimentoFinanceiro,
      'percepcao_controle': percepcaoControle,
      'percepcao_gastos': percepcaoGastos,
      'disciplina_financeira': disciplinaFinanceira,
      'relacao_dinheiro': relacaoDinheiro,
      'renda_mensal': rendaMensal,
      'tipo_renda': tipoRenda,
      'conta_ativa': contaAtiva,
      'data_desativacao': dataDesativacao,
      'media_horas_trabalhadas_mes': mediaHorasTrabalhadasMes,
      'primeiro_acesso': primeiroAcesso,
      'diagnostico_etapa_atual': diagnosticoEtapaAtual,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copia modelo com modificações
  PerfilUsuarioModel copyWith({
    String? nome,
    String? email,
    String? avatarUrl,
    String? telefone,
    String? dataNascimento,
    String? profissao,
    bool? perfilPublico,
    bool? aceitaNotificacoes,
    bool? aceitaMarketing,
    String? moedaPadrao,
    String? formatoData,
    int? primeiroDiaSemana,
    bool? diagnosticoCompleto,
    String? dataDiagnostico,
    String? sentimentoFinanceiro,
    String? percepcaoControle,
    String? percepcaoGastos,
    String? disciplinaFinanceira,
    String? relacaoDinheiro,
    double? rendaMensal,
    String? tipoRenda,
    bool? contaAtiva,
    String? dataDesativacao,
    int? mediaHorasTrabalhadasMes,
    bool? primeiroAcesso,
    int? diagnosticoEtapaAtual,
    DateTime? updatedAt,
  }) {
    return PerfilUsuarioModel(
      id: id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      telefone: telefone ?? this.telefone,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      profissao: profissao ?? this.profissao,
      perfilPublico: perfilPublico ?? this.perfilPublico,
      aceitaNotificacoes: aceitaNotificacoes ?? this.aceitaNotificacoes,
      aceitaMarketing: aceitaMarketing ?? this.aceitaMarketing,
      moedaPadrao: moedaPadrao ?? this.moedaPadrao,
      formatoData: formatoData ?? this.formatoData,
      primeiroDiaSemana: primeiroDiaSemana ?? this.primeiroDiaSemana,
      diagnosticoCompleto: diagnosticoCompleto ?? this.diagnosticoCompleto,
      dataDiagnostico: dataDiagnostico ?? this.dataDiagnostico,
      sentimentoFinanceiro: sentimentoFinanceiro ?? this.sentimentoFinanceiro,
      percepcaoControle: percepcaoControle ?? this.percepcaoControle,
      percepcaoGastos: percepcaoGastos ?? this.percepcaoGastos,
      disciplinaFinanceira: disciplinaFinanceira ?? this.disciplinaFinanceira,
      relacaoDinheiro: relacaoDinheiro ?? this.relacaoDinheiro,
      rendaMensal: rendaMensal ?? this.rendaMensal,
      tipoRenda: tipoRenda ?? this.tipoRenda,
      contaAtiva: contaAtiva ?? this.contaAtiva,
      dataDesativacao: dataDesativacao ?? this.dataDesativacao,
      mediaHorasTrabalhadasMes: mediaHorasTrabalhadasMes ?? this.mediaHorasTrabalhadasMes,
      primeiroAcesso: primeiroAcesso ?? this.primeiroAcesso,
      diagnosticoEtapaAtual: diagnosticoEtapaAtual ?? this.diagnosticoEtapaAtual,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'PerfilUsuarioModel(id: $id, nome: $nome, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PerfilUsuarioModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}