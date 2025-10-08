// ⚙️ Configurações Page - iPoupei Mobile
//
// Página completa de configurações do usuário com 5 abas:
// 1. Informações Pessoais
// 2. Segurança
// 3. Preferências
// 4. Meus Dados
// 5. Exclusão de Conta
//
// Baseado em: UserProfile.jsx do projeto React

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../shared/theme/app_colors.dart';
import '../../../shared/components/ui/app_button.dart';
import '../../auth/pages/login_ipoupei_page.dart';
import '../services/usuario_service.dart';
import '../models/user_profile_model.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({Key? key}) : super(key: key);

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _usuarioService = UsuarioService.instance;

  UserProfileModel? _userProfile;
  bool _isLoading = true;
  String _message = '';
  String _messageType = ''; // 'success' ou 'error'

  // Controllers para formulários
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _confirmDeleteController = TextEditingController();

  // Estados das preferências
  bool _aceitaNotificacoes = true;
  bool _aceitaMarketing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _carregarPerfil();
    _carregarDadosUsuarioAuth();
  }

  void _carregarDadosUsuarioAuth() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      debugPrint('👤 Usuário autenticado: ${user.email}');
      debugPrint('📸 Avatar URL: ${user.userMetadata?['picture']}');
      debugPrint('👤 Nome: ${user.userMetadata?['full_name'] ?? user.userMetadata?['nome']}');
      debugPrint('🔍 TODOS METADATA: ${user.userMetadata}');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    _confirmDeleteController.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    setState(() => _isLoading = true);

    final profile = await _usuarioService.fetchUserProfile();

    if (profile != null) {
      setState(() {
        _userProfile = profile;
        _nomeController.text = profile.nome ?? '';
        _telefoneController.text = _formatarTelefone(profile.telefone);
        _aceitaNotificacoes = profile.aceitaNotificacoes;
        _aceitaMarketing = profile.aceitaMarketing;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _mostrarMensagem('Erro ao carregar perfil', 'error');
    }
  }

  void _mostrarMensagem(String texto, String tipo) {
    setState(() {
      _message = texto;
      _messageType = tipo;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _message = '';
          _messageType = '';
        });
      }
    });
  }

  String _formatarTelefone(String? telefone) {
    if (telefone == null || telefone.isEmpty) return '';

    final cleaned = telefone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return '';
    if (cleaned.length <= 2) return cleaned;

    // Tenta formatar com diferentes padrões
    if (cleaned.length <= 6) {
      final match = RegExp(r'^(\d{2})(\d+)$').firstMatch(cleaned);
      if (match != null) return '(${match.group(1)}) ${match.group(2)}';
    }
    if (cleaned.length <= 10) {
      final match = RegExp(r'^(\d{2})(\d{4})(\d+)$').firstMatch(cleaned);
      if (match != null) return '(${match.group(1)}) ${match.group(2)}-${match.group(3)}';
    }
    // Celular com 11 dígitos: (11) 98117-5417
    final match = RegExp(r'^(\d{2})(\d{5})(\d{4})$').firstMatch(cleaned);
    if (match != null) return '(${match.group(1)}) ${match.group(2)}-${match.group(3)}';

    // Fallback: retorna sem formatação
    return cleaned;
  }

  Future<void> _selecionarEUploadFoto() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Selecionar imagem da galeria
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      // Ler bytes da imagem
      final bytes = await image.readAsBytes();

      // Upload para Supabase Storage
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'avatars/$fileName';

      // Upload do arquivo
      await Supabase.instance.client.storage
          .from('user-uploads')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '0',
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      // Obter URL pública
      final avatarUrl = Supabase.instance.client.storage
          .from('user-uploads')
          .getPublicUrl(filePath);

      // Atualizar perfil com nova URL
      final success = await _usuarioService.updatePersonalInfo(
        avatarUrl: avatarUrl,
      );

      if (success) {
        _mostrarMensagem('Foto atualizada com sucesso!', 'success');
        await _carregarPerfil();
      } else {
        _mostrarMensagem('Erro ao atualizar foto', 'error');
      }
    } catch (e) {
      debugPrint('❌ Erro no upload: $e');
      _mostrarMensagem('Erro ao fazer upload: ${e.toString()}', 'error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.cinzaClaro,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.tealPrimary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      appBar: AppBar(
        title: const Text(
          'Configurações',
          style: TextStyle(
            color: AppColors.branco,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.branco),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.branco,
          labelColor: AppColors.branco,
          unselectedLabelColor: AppColors.brancoTransparente70,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Pessoal'),
            Tab(icon: Icon(Icons.lock), text: 'Segurança'),
            Tab(icon: Icon(Icons.settings), text: 'Preferências'),
            Tab(icon: Icon(Icons.file_download), text: 'Dados'),
            Tab(icon: Icon(Icons.delete_forever), text: 'Exclusão'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Mensagem de feedback
          if (_message.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: _messageType == 'success'
                  ? AppColors.verdeSucesso10
                  : AppColors.vermelhoErro10,
              child: Row(
                children: [
                  Icon(
                    _messageType == 'success' ? Icons.check_circle : Icons.error,
                    color: _messageType == 'success'
                        ? AppColors.verdeSucesso
                        : AppColors.vermelhoErro,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _message,
                      style: TextStyle(
                        color: _messageType == 'success'
                            ? AppColors.verdeSucesso
                            : AppColors.vermelhoErro,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Conteúdo das abas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAbaInformacoesPessoais(),
                _buildAbaSeguranca(),
                _buildAbaPreferencias(),
                _buildAbaMeusDados(),
                _buildAbaExclusao(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 👤 ABA INFORMAÇÕES PESSOAIS
  Widget _buildAbaInformacoesPessoais() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informações Pessoais',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.cinzaEscuro,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Atualize suas informações básicas de perfil',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.cinzaMedio,
            ),
          ),
          const SizedBox(height: 24),

          // Avatar
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  key: ValueKey(_userProfile?.avatarUrl ?? 'no-avatar'),
                  radius: 50,
                  backgroundColor: AppColors.tealTransparente20,
                  backgroundImage: _userProfile?.avatarUrl != null && _userProfile!.avatarUrl!.isNotEmpty
                      ? NetworkImage(_userProfile!.avatarUrl!)
                      : null,
                  child: _userProfile?.avatarUrl == null || _userProfile!.avatarUrl!.isEmpty
                      ? Text(
                          _userProfile?.initials ?? 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.tealPrimary,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.tealPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.branco, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 18),
                      color: AppColors.branco,
                      onPressed: _selecionarEUploadFoto,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Nome
          const Text(
            'Nome Completo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.cinzaEscuro,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nomeController,
            decoration: InputDecoration(
              hintText: 'Seu nome completo',
              prefixIcon: const Icon(Icons.person),
              filled: true,
              fillColor: AppColors.branco,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Email (read-only)
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.cinzaEscuro,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: _userProfile?.email ?? ''),
            enabled: false,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email),
              filled: true,
              fillColor: AppColors.cinzaClaro,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'O email não pode ser alterado',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.cinzaMedio,
            ),
          ),
          const SizedBox(height: 16),

          // Telefone
          const Text(
            'Telefone',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.cinzaEscuro,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _telefoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '(11) 99999-9999',
              prefixIcon: const Icon(Icons.phone),
              filled: true,
              fillColor: AppColors.branco,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botão Salvar
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Salvar Alterações',
              icon: Icons.save,
              onPressed: _salvarInformacoesPessoais,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _salvarInformacoesPessoais() async {
    try {
      final success = await _usuarioService.updatePersonalInfo(
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.trim(),
      );

      if (success) {
        _mostrarMensagem('Informações atualizadas com sucesso!', 'success');
        await _carregarPerfil();
      } else {
        _mostrarMensagem('Erro ao atualizar informações', 'error');
      }
    } catch (e) {
      _mostrarMensagem('Erro: $e', 'error');
    }
  }

  // 🔒 ABA SEGURANÇA
  Widget _buildAbaSeguranca() {
    final isGoogleUser = _userProfile?.isGoogleUser ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Segurança',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.cinzaEscuro,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Altere sua senha de acesso ao aplicativo',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.cinzaMedio,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.azulTransparente10,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.azulTransparente20),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.azul, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Você já está autenticado. Basta definir a nova senha.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.azul,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (isGoogleUser)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.azulTransparente10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.azulTransparente20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.azul,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Conta vinculada ao Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cinzaEscuro,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sua conta está autenticada via Google. Para alterar sua senha, acesse as configurações da sua Conta Google diretamente.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.cinzaMedio,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nova Senha
                const Text(
                  'Nova Senha',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cinzaEscuro,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _novaSenhaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Nova senha',
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor: AppColors.branco,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mínimo de 6 caracteres',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.cinzaMedio,
                  ),
                ),
                const SizedBox(height: 16),

                // Confirmar Senha
                const Text(
                  'Confirmar Nova Senha',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cinzaEscuro,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmarSenhaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirme a nova senha',
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor: AppColors.branco,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botão Atualizar Senha
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Atualizar Senha',
                    icon: Icons.lock_reset,
                    onPressed: _alterarSenha,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _alterarSenha() async {
    if (_novaSenhaController.text.length < 6) {
      _mostrarMensagem('A senha deve ter pelo menos 6 caracteres', 'error');
      return;
    }

    if (_novaSenhaController.text != _confirmarSenhaController.text) {
      _mostrarMensagem('As senhas não coincidem', 'error');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _usuarioService.updatePassword(_novaSenhaController.text);

    setState(() => _isLoading = false);

    if (result['success']) {
      _mostrarMensagem('Senha alterada com sucesso!', 'success');
      _novaSenhaController.clear();
      _confirmarSenhaController.clear();
    } else {
      _mostrarMensagem(result['error'] ?? 'Erro ao alterar senha', 'error');
    }
  }

  // ⚙️ ABA PREFERÊNCIAS
  Widget _buildAbaPreferencias() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferências',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.cinzaEscuro,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Personalize sua experiência no iPoupei',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.cinzaMedio,
            ),
          ),
          const SizedBox(height: 24),

          // Notificações
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications,
                  color: AppColors.tealPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notificações',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cinzaEscuro,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Receba alertas de vencimentos e lançamentos',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.cinzaMedio,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _aceitaNotificacoes,
                  onChanged: (value) {
                    setState(() => _aceitaNotificacoes = value);
                  },
                  activeColor: AppColors.tealPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Marketing
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.mail,
                  color: AppColors.tealPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emails Promocionais',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cinzaEscuro,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Receba ofertas e novidades por email',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.cinzaMedio,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _aceitaMarketing,
                  onChanged: (value) {
                    setState(() => _aceitaMarketing = value);
                  },
                  activeColor: AppColors.tealPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botão Salvar
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Salvar Preferências',
              icon: Icons.save,
              onPressed: _salvarPreferencias,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _salvarPreferencias() async {
    final success = await _usuarioService.savePreferences(
      aceitaNotificacoes: _aceitaNotificacoes,
      aceitaMarketing: _aceitaMarketing,
    );

    if (success) {
      _mostrarMensagem('Preferências salvas com sucesso!', 'success');
    } else {
      _mostrarMensagem('Erro ao salvar preferências', 'error');
    }
  }

  /// 📤 GERAR BACKUP DOS DADOS
  Future<void> _gerarBackup() async {
    try {
      setState(() => _isLoading = true);

      final backup = await _usuarioService.generateBackup();

      if (backup.isEmpty) {
        _mostrarMensagem('Erro ao gerar backup', 'error');
        return;
      }

      // Converter para JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

      // Obter diretório temporário (sempre tem permissão)
      final directory = await getTemporaryDirectory();

      // Criar nome do arquivo com data
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'ipoupei_backup_$timestamp.json';

      // Salvar no diretório temporário
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      setState(() => _isLoading = false);

      // Compartilhar arquivo (usuário escolhe onde salvar)
      await SharePlus.instance.share(ShareParams(
        title: 'Backup iPoupei',
        subject: 'Backup iPoupei - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
        text: 'Backup completo dos seus dados financeiros do iPoupei',
        files: [XFile(filePath)],
      ));

      _mostrarMensagem('Backup gerado! Escolha onde salvar', 'success');

      // Limpar arquivo temporário após compartilhar
      try {
        await file.delete();
      } catch (e) {
        debugPrint('⚠️ Não foi possível deletar arquivo temporário: $e');
      }
    } catch (e) {
      debugPrint('❌ Erro ao gerar backup: $e');
      _mostrarMensagem('Erro ao gerar backup: ${e.toString()}', 'error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 📥 IMPORTAR BACKUP DOS DADOS
  Future<void> _importarBackup() async {
    try {
      // Selecionar arquivo JSON
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return; // Usuário cancelou
      }

      setState(() => _isLoading = true);

      // Ler arquivo
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      // Parsear JSON
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Confirmar importação
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Importação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠️ ATENÇÃO: Esta ação irá:'),
              const SizedBox(height: 8),
              const Text('• Mesclar os dados do backup com os dados atuais'),
              const Text('• Atualizar registros existentes'),
              const Text('• Inserir novos registros'),
              const SizedBox(height: 16),
              Text(
                'Backup de: ${backupData['info']?['data_backup'] ?? 'Data desconhecida'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Total de registros: ${backupData['resumo']?['total_registros'] ?? '?'}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.tealPrimary,
              ),
              child: const Text('Importar'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() => _isLoading = false);
        return;
      }

      // Importar backup
      final result2 = await _usuarioService.importBackup(backupData);

      if (result2['success'] == true) {
        final registrosImportados = result2['registros_importados'] ?? 0;
        final erros = result2['erros'] ?? 0;

        _mostrarMensagem(
          'Importação concluída! $registrosImportados registros importados, $erros erros',
          erros > 0 ? 'error' : 'success',
        );

        // Aguardar 2 segundos e recarregar app
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          // Forçar reload navegando para login e voltando
          Navigator.of(context).pushNamedAndRemoveUntil('/navigation', (route) => false);
        }
      } else {
        _mostrarMensagem(result2['error'] ?? 'Erro ao importar backup', 'error');
      }
    } catch (e) {
      debugPrint('❌ Erro ao importar backup: $e');
      _mostrarMensagem('Erro ao importar backup: ${e.toString()}', 'error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ⏸️ DESATIVAR CONTA
  Future<void> _desativarConta() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar Conta'),
        content: const Text(
          'Tem certeza que deseja desativar sua conta?\n\n'
          'Você poderá reativá-la fazendo login novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.amareloAlerta,
            ),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final result = await _usuarioService.deactivateAccount();

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        // Fazer logout e voltar para tela de login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginIpoupeiPage()),
          (route) => false,
        );
      }
    } else {
      _mostrarMensagem(result['error'] ?? 'Erro ao desativar conta', 'error');
    }
  }

  /// 🗑️ EXCLUIR CONTA PERMANENTEMENTE
  Future<void> _excluirConta() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.vermelhoErro),
            SizedBox(width: 8),
            Text('Excluir Conta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ ATENÇÃO: Esta ação é irreversível!\n\n'
              'Todos os seus dados serão permanentemente excluídos:\n'
              '• Transações\n'
              '• Contas e cartões\n'
              '• Categorias e planejamentos\n'
              '• Perfil e configurações\n\n'
              'Digite "EXCLUIR MINHA CONTA" para confirmar:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmDeleteController,
              decoration: const InputDecoration(
                hintText: 'EXCLUIR MINHA CONTA',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.vermelhoErro,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      _confirmDeleteController.clear();
      return;
    }

    setState(() => _isLoading = true);

    final result = await _usuarioService.deleteAccount(
      _confirmDeleteController.text,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        // Fazer logout e voltar para tela de login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginIpoupeiPage()),
          (route) => false,
        );
      }
    } else {
      _mostrarMensagem(result['error'] ?? 'Erro ao excluir conta', 'error');
      _confirmDeleteController.clear();
    }
  }

  // 📁 ABA MEUS DADOS
  Widget _buildAbaMeusDados() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meus Dados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.cinzaEscuro,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Exporte ou importe todos os seus dados financeiros',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.cinzaMedio,
            ),
          ),
          const SizedBox(height: 24),

          // Exportar Backup
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.share,
                  size: 60,
                  color: AppColors.tealPrimary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Exportar Backup',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cinzaEscuro,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Salve seus dados em JSON\nEscolha: WhatsApp, Google Drive, Arquivos...',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.cinzaMedio,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Gerar e Compartilhar',
                    icon: Icons.share,
                    onPressed: _gerarBackup,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Importar Backup
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.file_upload,
                  size: 60,
                  color: AppColors.azul,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Importar Backup',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cinzaEscuro,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Restaure seus dados a partir de um arquivo JSON',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.cinzaMedio,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Selecionar Arquivo',
                    icon: Icons.upload_file,
                    customColor: AppColors.azul,
                    onPressed: _importarBackup,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🗑️ ABA EXCLUSÃO
  Widget _buildAbaExclusao() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exclusão de Conta',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.vermelhoErro,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gerencie a exclusão ou desativação da sua conta iPoupei',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.cinzaMedio,
            ),
          ),
          const SizedBox(height: 24),

          // Aviso
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.vermelhoErro10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.vermelhoErro30),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: AppColors.vermelhoErro, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⚠️ Atenção: A exclusão da conta é permanente e não pode ser desfeita. Faça um backup antes de prosseguir.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.vermelhoErro,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Desativar Temporariamente
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.amareloAlerta30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pause_circle, color: AppColors.amareloAlerta),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '⏸️ Desativar Temporariamente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cinzaEscuro,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Suspende sua conta mas mantém os dados para reativação futura',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.cinzaMedio,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Desativar Conta',
                    icon: Icons.pause,
                    customColor: AppColors.amareloAlerta,
                    onPressed: _desativarConta,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Excluir Permanentemente
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.vermelhoErro30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.delete_forever, color: AppColors.vermelhoErro),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '🗑️ Excluir Permanentemente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cinzaEscuro,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Remove sua conta e todos os dados de forma irreversível',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.cinzaMedio,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Excluir Conta',
                    icon: Icons.delete_forever,
                    customColor: AppColors.vermelhoErro,
                    onPressed: _excluirConta,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
