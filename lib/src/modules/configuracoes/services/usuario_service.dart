// 👤 Usuario Service - iPoupei Mobile
//
// Serviço para gerenciar perfil e configurações do usuário
// Baseado em: UserProfile.jsx do projeto React

import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';

class UsuarioService {
  static final UsuarioService _instance = UsuarioService._internal();
  static UsuarioService get instance => _instance;
  UsuarioService._internal();

  final _supabase = Supabase.instance.client;

  /// 📥 BUSCAR PERFIL DO USUÁRIO
  Future<UserProfileModel?> fetchUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      log('📥 Buscando perfil do usuário: ${user.id}');
      log('🔍 UserMetadata: ${user.userMetadata}');

      // Buscar dados da tabela perfil_usuario
      final response = await _supabase
          .from('perfil_usuario')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final data = response;

      // Combinar dados do auth.users (user_metadata) com perfil_usuario
      // PRIORIDADE: user_metadata é sempre mais atualizado que a tabela
      final avatarUrl = user.userMetadata?['avatar_url'] ??      // Custom avatar
                       user.userMetadata?['picture'] ??          // Google usa 'picture'
                       user.userMetadata?['avatar'] ??           // Fallback genérico
                       data?['avatar_url'];                      // Tabela (menos prioritário)

      final profile = UserProfileModel(
        id: user.id,
        email: user.email ?? '',
        nome: data?['nome'] ?? user.userMetadata?['nome'] ?? user.userMetadata?['full_name'],
        telefone: data?['telefone'] ?? user.userMetadata?['telefone'],
        avatarUrl: avatarUrl,
        aceitaNotificacoes: data?['aceita_notificacoes'] ?? true,
        aceitaMarketing: data?['aceita_marketing'] ?? false,
        provider: user.appMetadata['provider'] as String?,
        createdAt: data?['created_at'] != null
            ? DateTime.parse(data!['created_at'])
            : null,
        updatedAt: data?['updated_at'] != null
            ? DateTime.parse(data!['updated_at'])
            : null,
      );

      log('✅ Perfil carregado: ${profile.nome}');
      return profile;
    } catch (e) {
      log('❌ Erro ao buscar perfil: $e');
      return null;
    }
  }

  /// 💾 ATUALIZAR INFORMAÇÕES PESSOAIS
  Future<bool> updatePersonalInfo({
    String? nome,
    String? telefone,
    String? avatarUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      log('💾 Atualizando informações pessoais...');
      log('📝 Nome recebido: "$nome"');
      log('📞 Telefone recebido: "$telefone"');

      // Preparar dados para user_metadata
      final userMetadata = <String, dynamic>{};

      if (nome != null && nome.trim().isNotEmpty) {
        userMetadata['nome'] = nome.trim();
        userMetadata['full_name'] = nome.trim();
      }

      if (telefone != null) {
        final cleanPhone = telefone.replaceAll(RegExp(r'\D'), '');
        log('📞 Telefone limpo: "$cleanPhone"');
        userMetadata['telefone'] = cleanPhone;
      }

      if (avatarUrl != null) {
        userMetadata['avatar_url'] = avatarUrl;
      }

      log('🔄 Atualizando auth.users com: $userMetadata');

      // Atualizar auth.users user_metadata
      final authResponse = await _supabase.auth.updateUser(
        UserAttributes(data: userMetadata),
      );

      log('✅ Auth.users atualizado!');

      if (authResponse.user == null) {
        throw Exception('Erro ao atualizar auth');
      }

      // Atualizar tabela perfil_usuario
      final profileData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (nome != null) profileData['nome'] = nome.trim();
      if (telefone != null) {
        final cleanPhone = telefone.replaceAll(RegExp(r'\D'), '');
        profileData['telefone'] = cleanPhone;
        log('📞 Salvando telefone na tabela: "$cleanPhone"');
      }
      if (avatarUrl != null) profileData['avatar_url'] = avatarUrl;

      log('🔄 Atualizando perfil_usuario com: $profileData');

      await _supabase
          .from('perfil_usuario')
          .update(profileData)
          .eq('id', user.id);

      log('✅ Perfil_usuario atualizado!');
      log('✅ Informações pessoais atualizadas');
      return true;
    } catch (e) {
      log('❌ Erro ao atualizar informações pessoais: $e');
      return false;
    }
  }

  /// 🔒 ALTERAR SENHA
  Future<Map<String, dynamic>> updatePassword(String newPassword) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'Usuário não autenticado'};
      }

      // Verificar se é usuário Google
      if (user.appMetadata['provider'] == 'google') {
        return {
          'success': false,
          'error': 'Usuários Google devem alterar senha pela conta Google'
        };
      }

      log('🔒 Alterando senha...');

      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        return {'success': false, 'error': 'Erro ao alterar senha'};
      }

      log('✅ Senha alterada com sucesso');
      return {'success': true};
    } catch (e) {
      log('❌ Erro ao alterar senha: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// ⚙️ SALVAR PREFERÊNCIAS
  Future<bool> savePreferences({
    required bool aceitaNotificacoes,
    required bool aceitaMarketing,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      log('⚙️ Salvando preferências...');

      await _supabase
          .from('perfil_usuario')
          .update({
            'aceita_notificacoes': aceitaNotificacoes,
            'aceita_marketing': aceitaMarketing,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      log('✅ Preferências salvas');
      return true;
    } catch (e) {
      log('❌ Erro ao salvar preferências: $e');
      return false;
    }
  }

  /// 📤 GERAR BACKUP DOS DADOS
  Future<Map<String, dynamic>> generateBackup() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      log('📤 Gerando backup dos dados...');

      final backup = {
        'info': {
          'usuario_id': user.id,
          'email': user.email,
          'nome': user.userMetadata?['nome'] ?? 'Usuário iPoupei',
          'data_backup': DateTime.now().toIso8601String(),
          'versao': '1.0',
        },
        'dados': {
          'contas': [],
          'cartoes': [],
          'categorias': [],
          'subcategorias': [],
          'transacoes': [],
          'transferencias': [],
          'planejamentos': [],
        },
        'resumo': {
          'total_registros': 0,
          'tabelas_processadas': 0,
          'status': 'completo',
        },
      };

      // Buscar dados de todas as tabelas
      final tables = [
        {'name': 'contas', 'key': 'contas'},
        {'name': 'cartoes', 'key': 'cartoes'},
        {'name': 'categorias', 'key': 'categorias'},
        {'name': 'subcategorias', 'key': 'subcategorias'},
        {'name': 'transacoes', 'key': 'transacoes'},
        {'name': 'transferencias', 'key': 'transferencias'},
        {'name': 'planejamentos', 'key': 'planejamentos'},
      ];

      int totalRegistros = 0;
      int tabelasProcessadas = 0;

      for (final table in tables) {
        try {
          final data = await _supabase
              .from(table['name']!)
              .select()
              .eq('usuario_id', user.id);

          final dados = data;
          (backup['dados'] as Map)[table['key']!] = dados;
          totalRegistros += dados.length;
          tabelasProcessadas++;
        } catch (e) {
          log('⚠️ Erro ao buscar ${table['name']}: $e');
        }
      }

      (backup['resumo'] as Map)['total_registros'] = totalRegistros;
      (backup['resumo'] as Map)['tabelas_processadas'] = tabelasProcessadas;

      log('✅ Backup gerado: $totalRegistros registros');
      return backup;
    } catch (e) {
      log('❌ Erro ao gerar backup: $e');
      return {};
    }
  }

  /// 📥 IMPORTAR BACKUP DOS DADOS
  Future<Map<String, dynamic>> importBackup(Map<String, dynamic> backupData) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      log('📥 Importando backup dos dados...');

      // Validar estrutura do backup
      if (!backupData.containsKey('info') ||
          !backupData.containsKey('dados') ||
          !backupData.containsKey('resumo')) {
        return {
          'success': false,
          'error': 'Formato de backup inválido'
        };
      }

      final dados = backupData['dados'] as Map<String, dynamic>;
      int registrosImportados = 0;
      int erros = 0;

      // Importar dados em ordem (contas antes de transações, etc)
      final importOrder = [
        'categorias',
        'subcategorias',
        'contas',
        'cartoes',
        'transacoes',
        'transferencias',
        'planejamentos',
      ];

      for (final tableName in importOrder) {
        if (!dados.containsKey(tableName)) continue;

        final registros = dados[tableName] as List;
        if (registros.isEmpty) continue;

        try {
          log('📥 Importando ${registros.length} registros de $tableName...');

          for (final registro in registros) {
            try {
              // Remover campos gerados automaticamente
              final dadosLimpos = Map<String, dynamic>.from(registro);
              dadosLimpos.remove('created_at');
              dadosLimpos.remove('updated_at');

              // Garantir usuario_id correto
              dadosLimpos['usuario_id'] = user.id;

              // Verificar se já existe pelo ID original
              final idOriginal = registro['id'];
              if (idOriginal != null) {
                final existe = await _supabase
                    .from(tableName)
                    .select('id')
                    .eq('id', idOriginal)
                    .maybeSingle();

                if (existe != null) {
                  // Atualizar registro existente
                  await _supabase
                      .from(tableName)
                      .update(dadosLimpos)
                      .eq('id', idOriginal);
                } else {
                  // Inserir novo registro mantendo o ID
                  await _supabase
                      .from(tableName)
                      .insert(dadosLimpos);
                }
              } else {
                // Inserir sem ID (será gerado automaticamente)
                dadosLimpos.remove('id');
                await _supabase
                    .from(tableName)
                    .insert(dadosLimpos);
              }

              registrosImportados++;
            } catch (e) {
              log('⚠️ Erro ao importar registro de $tableName: $e');
              erros++;
            }
          }

          log('✅ $tableName importado com sucesso');
        } catch (e) {
          log('❌ Erro ao importar tabela $tableName: $e');
          erros++;
        }
      }

      log('✅ Importação concluída: $registrosImportados registros, $erros erros');

      return {
        'success': true,
        'registros_importados': registrosImportados,
        'erros': erros,
      };
    } catch (e) {
      log('❌ Erro ao importar backup: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔍 VERIFICAR STATUS DA CONTA
  Future<Map<String, dynamic>> checkAccountStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'Usuário não autenticado'};
      }

      log('🔍 Verificando status da conta...');

      final response = await _supabase
          .from('perfil_usuario')
          .select('conta_ativa, data_desativacao')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        return {'success': false, 'error': 'Perfil não encontrado'};
      }

      final contaAtiva = response['conta_ativa'] as bool? ?? true;
      final dataDesativacao = response['data_desativacao'] as String?;

      log('✅ Conta ativa: $contaAtiva');

      return {
        'success': true,
        'conta_ativa': contaAtiva,
        'data_desativacao': dataDesativacao,
      };
    } catch (e) {
      log('❌ Erro ao verificar status da conta: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// ✅ REATIVAR CONTA
  Future<Map<String, dynamic>> reactivateAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'Usuário não autenticado'};
      }

      log('✅ Reativando conta...');

      // Marcar conta como ativa no perfil_usuario
      await _supabase
          .from('perfil_usuario')
          .update({
            'conta_ativa': true,
            'data_desativacao': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      log('✅ Conta reativada');
      return {'success': true};
    } catch (e) {
      log('❌ Erro ao reativar conta: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🗑️ DESATIVAR CONTA
  Future<Map<String, dynamic>> deactivateAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'Usuário não autenticado'};
      }

      log('🗑️ Desativando conta...');

      // Marcar conta como inativa no perfil_usuario
      await _supabase
          .from('perfil_usuario')
          .update({
            'conta_ativa': false,
            'data_desativacao': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      // Fazer logout
      await _supabase.auth.signOut();

      log('✅ Conta desativada');
      return {'success': true};
    } catch (e) {
      log('❌ Erro ao desativar conta: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🗑️ EXCLUIR CONTA PERMANENTEMENTE
  Future<Map<String, dynamic>> deleteAccount(String confirmText) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'Usuário não autenticado'};
      }

      if (confirmText != 'EXCLUIR MINHA CONTA') {
        return {
          'success': false,
          'error': 'Digite exatamente "EXCLUIR MINHA CONTA" para confirmar'
        };
      }

      log('🗑️ Excluindo conta permanentemente...');

      // Chamar função RPC que exclui tudo (dados + auth)
      try {
        final response = await _supabase.rpc(
          'delete_user_complete',
          params: {'target_user_id': user.id},
        );

        log('✅ Função delete_user_complete executada: $response');
      } catch (e) {
        log('❌ Erro ao executar delete_user_complete: $e');
        // Mesmo com erro, continua para fazer logout
      }

      // Fazer logout local
      await _supabase.auth.signOut();

      log('✅ Conta excluída permanentemente');
      return {'success': true};
    } catch (e) {
      log('❌ Erro ao excluir conta: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
