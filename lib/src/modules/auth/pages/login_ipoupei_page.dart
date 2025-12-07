// 🔐 Login iPoupei Page - iPoupei Mobile
//
// Tela de autenticação COMPLETA e Mobile-First
// Design moderno com identidade visual iPoupei (Teal)
//
// Features:
// - Design mobile-first (tela toda)
// - Google SSO
// - Demo credentials
// - Lembrar de mim com SharedPreferences
// - Campos touch-friendly
// - Animações suaves

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io';
import '../../../auth_integration.dart';
import '../../shared/theme/app_colors.dart';
import '../../configuracoes/services/usuario_service.dart';

enum AuthMode { login, register, recovery }

class LoginIpoupeiPage extends StatefulWidget {
  const LoginIpoupeiPage({super.key});

  @override
  State<LoginIpoupeiPage> createState() => _LoginIpoupeiPageState();
}

class _LoginIpoupeiPageState extends State<LoginIpoupeiPage>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nomeController = TextEditingController();

  // Estados
  AuthMode _mode = AuthMode.login;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _rememberMe = false;

  // Animação
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Carregar email salvo (se "lembrar de mim" estiver ativo)
    _loadSavedEmail();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  /// 💾 CARREGAR EMAIL SALVO
  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (rememberMe && savedEmail != null) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = true;
        });
      }
    } catch (e) {
      // Ignora erro ao carregar
    }
  }

  /// 💾 SALVAR OU LIMPAR EMAIL
  Future<void> _saveRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_rememberMe) {
        // Salvar email
        await prefs.setString('saved_email', _emailController.text.trim());
        await prefs.setBool('remember_me', true);
      } else {
        // Limpar email salvo
        await prefs.remove('saved_email');
        await prefs.setBool('remember_me', false);
      }
    } catch (e) {
      // Ignora erro ao salvar
    }
  }

  /// 🔄 MUDAR MODO
  void _changeMode(AuthMode newMode) {
    setState(() {
      _mode = newMode;
      _errorMessage = null;
      _successMessage = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
      if (newMode != AuthMode.register) {
        _nomeController.clear();
      }
    });
    _animationController.reset();
    _animationController.forward();
  }

  /// 🚀 SUBMETER FORMULÁRIO
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      switch (_mode) {
        case AuthMode.login:
          // Salvar ou limpar "lembrar de mim" ANTES do login
          await _saveRememberMe();

          await authIntegration.authService.signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          // Verificar se conta está desativada
          if (mounted) {
            await _checkAccountStatus();
          }
          break;

        case AuthMode.register:
          await authIntegration.authService.signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            nome: _nomeController.text.trim(),
          );
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/navigation');
          }
          break;

        case AuthMode.recovery:
          await authIntegration.authService.resetPassword(
            email: _emailController.text.trim(),
          );
          setState(() {
            _successMessage = 'Email enviado! Verifique sua caixa de entrada.';
          });
          break;
      }
    } catch (e) {
      String errorMsg = e.toString()
          .replaceAll('Exception: ', '')
          .replaceAll('AuthException: ', '');

      setState(() {
        if (errorMsg.contains('Invalid login credentials')) {
          _errorMessage = 'Email ou senha incorretos';
        } else if (errorMsg.contains('Email not confirmed')) {
          _errorMessage = 'Email não confirmado. Verifique sua caixa de entrada.';
        } else {
          _errorMessage = errorMsg;
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔵 GOOGLE SSO
  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await authIntegration.authService.signInWithGoogle();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/navigation');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🍎 APPLE SSO
  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await authIntegration.authService.signInWithApple();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/navigation');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔍 VERIFICAR STATUS DA CONTA
  Future<void> _checkAccountStatus() async {
    try {
      final usuarioService = UsuarioService.instance;
      final result = await usuarioService.checkAccountStatus();

      if (!mounted) return;

      if (result['success'] == true) {
        final contaAtiva = result['conta_ativa'] as bool? ?? true;

        if (!contaAtiva) {
          await _showReactivationDialog();
        } else {
          Navigator.of(context).pushReplacementNamed('/navigation');
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/navigation');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/navigation');
      }
    }
  }

  /// 🔄 DIALOG DE REATIVAÇÃO
  Future<void> _showReactivationDialog() async {
    final shouldReactivate = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pause_circle, color: Colors.orange),
            SizedBox(width: 12),
            Text('Conta Desativada'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sua conta foi desativada anteriormente.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Deseja reativar sua conta agora?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tealPrimary,
            ),
            child: const Text('Reativar'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (shouldReactivate == true) {
      final usuarioService = UsuarioService.instance;
      final result = await usuarioService.reactivateAccount();

      if (result['success'] == true) {
        Navigator.of(context).pushReplacementNamed('/navigation');
      } else {
        await authIntegration.authService.signOut();
        setState(() {
          _errorMessage = 'Erro ao reativar conta';
        });
      }
    } else {
      await authIntegration.authService.signOut();
      setState(() {
        _errorMessage = 'Você precisa reativar sua conta para continuar';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/Logo.png',
                      width: 110,
                      height: 110,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Título
                  Text(
                    _mode == AuthMode.login
                        ? 'Bem-vindo!'
                        : _mode == AuthMode.register
                            ? 'Criar conta'
                            : 'Recuperar senha',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.tealEscuro,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtítulo
                  Text(
                    _mode == AuthMode.login
                        ? 'Entre para continuar'
                        : _mode == AuthMode.register
                            ? 'Comece grátis agora'
                            : 'Vamos recuperar seu acesso',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.cinzaMedio,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Mensagens
                  if (_errorMessage != null) _buildErrorMessage(),
                  if (_successMessage != null) _buildSuccessMessage(),

                  // OAuth SSO (apenas login)
                  if (_mode == AuthMode.login) ...[
                    _buildOAuthButtons(),
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                  ],

                  // Formulário
                  _buildForm(),

                  const SizedBox(height: 16),


                  const SizedBox(height: 24),

                  // Botão Principal
                  _buildSubmitButton(),

                  const SizedBox(height: 20),

                  // Links
                  _buildFooterLinks(),

                  const SizedBox(height: 20),

                  // BOTÃO TESTE LOADING (TEMPORÁRIO)
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/test-loading'),
                    child: const Text(
                      '🧪 Testar Loading',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  /// ❌ MENSAGEM DE ERRO
  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.vermelhoErro10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.vermelhoErro20, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.vermelhoErro, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.vermelhoErro,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ MENSAGEM DE SUCESSO
  Widget _buildSuccessMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.verdeSucesso10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.verdeSucesso20, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.verdeSucesso, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _successMessage!,
              style: const TextStyle(
                color: AppColors.verdeSucesso,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔵🍎 BOTÕES OAUTH
  Widget _buildOAuthButtons() {
    return Column(
      children: [
        // Botão Google
        SizedBox(
          height: 56,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            icon: Image.asset(
              'assets/images/google-logo.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.g_mobiledata, size: 28, color: AppColors.cinzaEscuro),
            ),
            label: Text(
              _isLoading ? 'Redirecionando...' : 'Continuar com Google',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.cinzaEscuro,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.cinzaBorda, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        // Espaçamento entre botões
        const SizedBox(height: 12),

        // Botão Apple (apenas no iOS)
        if (Platform.isIOS) ...[
          SizedBox(
            height: 56,
            width: double.infinity,
            child: SignInWithAppleButton(
              onPressed: _isLoading ? () {} : () => _handleAppleSignIn(),
              text: 'Continuar com Apple',
              style: SignInWithAppleButtonStyle.black,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ],
      ],
    );
  }

  /// ➗ DIVISOR
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.cinzaBorda, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: TextStyle(
              color: AppColors.cinzaMedio,
              fontSize: 14,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.cinzaBorda, thickness: 1),
        ),
      ],
    );
  }

  /// 📝 FORMULÁRIO
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nome (apenas registro)
          if (_mode == AuthMode.register) ...[
            _buildTextField(
              controller: _nomeController,
              label: 'Nome completo',
              hint: 'Como devemos te chamar?',
              icon: Icons.person_outline,
              keyboardType: TextInputType.name,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite seu nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'seu@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return 'Digite um email válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Senha (exceto recovery)
          if (_mode != AuthMode.recovery) ...[
            _buildTextField(
              controller: _passwordController,
              label: 'Senha',
              hint: 'Mínimo 6 caracteres',
              icon: Icons.lock_outline,
              obscureText: !_showPassword,
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Senha deve ter no mínimo 6 caracteres';
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.cinzaMedio,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Confirmar senha (apenas registro)
          if (_mode == AuthMode.register) ...[
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirmar senha',
              hint: 'Digite a senha novamente',
              icon: Icons.lock_outline,
              obscureText: !_showConfirmPassword,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'As senhas não coincidem';
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.cinzaMedio,
                ),
                onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Opções (apenas login)
          if (_mode == AuthMode.login) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Lembrar de mim
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) => setState(() => _rememberMe = value!),
                        activeColor: AppColors.tealPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Lembrar',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.cinzaTexto,
                      ),
                    ),
                  ],
                ),
                // Esqueceu senha
                TextButton(
                  onPressed: () => _changeMode(AuthMode.recovery),
                  child: const Text(
                    'Esqueceu a senha?',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.tealPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 🔤 CAMPO DE TEXTO
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.tealPrimary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.tealClaro.withAlpha(12),
        labelStyle: const TextStyle(color: AppColors.cinzaMedio),
        hintStyle: TextStyle(color: AppColors.cinzaMedio.withAlpha(130)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cinzaBorda, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.tealPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.vermelhoErro, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.vermelhoErro, width: 2),
        ),
        errorStyle: const TextStyle(
          color: AppColors.vermelhoErro,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      style: const TextStyle(color: AppColors.cinzaEscuro, fontSize: 16),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      enabled: !_isLoading,
    );
  }

  /// 🔘 BOTÃO SUBMIT
  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tealPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.cinzaMedio,
          elevation: 4,
          shadowColor: AppColors.tealPrimary.withAlpha(104),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _mode == AuthMode.login
                    ? 'Entrar'
                    : _mode == AuthMode.register
                        ? 'Criar conta'
                        : 'Enviar link',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// 🔗 LINKS RODAPÉ
  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _mode == AuthMode.login
              ? 'Não tem uma conta? '
              : _mode == AuthMode.register
                  ? 'Já tem uma conta? '
                  : 'Lembrou da senha? ',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.cinzaMedio,
          ),
        ),
        TextButton(
          onPressed: () => _changeMode(
            _mode == AuthMode.login ? AuthMode.register : AuthMode.login,
          ),
          child: Text(
            _mode == AuthMode.login
                ? 'Cadastre-se'
                : _mode == AuthMode.register
                    ? 'Fazer login'
                    : 'Voltar',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.tealPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
