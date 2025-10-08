import 'dart:developer';
import '../../../database/local_database.dart';
import '../../../database/models/perfil_usuario_model.dart';
import '../../../auth_integration.dart';

/// Serviço para calcular o valor da hora de trabalho
/// e quantas horas são necessárias para pagar cada gasto
class ValorHoraService {
  static final ValorHoraService _instance = ValorHoraService._internal();
  static ValorHoraService get instance => _instance;
  ValorHoraService._internal();

  final LocalDatabase _localDb = LocalDatabase.instance;
  final AuthIntegration _authIntegration = AuthIntegration.instance;

  /// Buscar perfil do usuário
  Future<PerfilUsuarioModel?> fetchPerfil() async {
    final userId = _authIntegration.authService.currentUser?.id;
    if (userId == null) return null;

    try {
      final result = await _localDb.database?.query(
        'perfil_usuario',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (result == null || result.isEmpty) return null;

      return PerfilUsuarioModel.fromSQLite(result.first);
    } catch (e) {
      log('❌ Erro ao buscar perfil: $e');
      return null;
    }
  }

  /// Calcular valor da hora
  /// Retorna null se não houver dados suficientes
  Future<double?> calcularValorHora() async {
    final perfil = await fetchPerfil();

    if (perfil == null ||
        perfil.rendaMensal == null ||
        perfil.mediaHorasTrabalhadasMes == null ||
        perfil.rendaMensal! <= 0 ||
        perfil.mediaHorasTrabalhadasMes! <= 0) {
      return null;
    }

    return perfil.rendaMensal! / perfil.mediaHorasTrabalhadasMes!;
  }

  /// Calcular quantas horas são necessárias para pagar um valor
  /// Retorna null se não houver dados suficientes
  Future<double?> calcularHorasParaPagar(double valor) async {
    final valorHora = await calcularValorHora();

    if (valorHora == null || valorHora <= 0) return null;

    return valor / valorHora;
  }

  /// Calcular percentual da renda mensal
  /// Retorna null se não houver dados suficientes
  Future<double?> calcularPercentualRenda(double valor) async {
    final perfil = await fetchPerfil();

    if (perfil == null ||
        perfil.rendaMensal == null ||
        perfil.rendaMensal! <= 0) {
      return null;
    }

    return (valor / perfil.rendaMensal!) * 100;
  }

  /// Formatar horas em texto legível
  /// Ex: 32.5 horas → "32h 30min"
  String formatarHoras(double horas) {
    if (horas < 0) return '0h';

    final horasInteiras = horas.floor();
    final minutos = ((horas - horasInteiras) * 60).round();

    if (minutos == 0) {
      return '${horasInteiras}h';
    }

    return '${horasInteiras}h ${minutos}min';
  }

  /// Obter dados completos para análise
  Future<Map<String, dynamic>?> obterDadosCompletos() async {
    final perfil = await fetchPerfil();
    final valorHora = await calcularValorHora();

    if (perfil == null || valorHora == null) return null;

    return {
      'renda_mensal': perfil.rendaMensal!,
      'horas_trabalhadas_mes': perfil.mediaHorasTrabalhadasMes!,
      'valor_hora': valorHora,
      'tipo_renda': perfil.tipoRenda ?? 'Não informado',
      'profissao': perfil.profissao ?? 'Não informada',
    };
  }
}
