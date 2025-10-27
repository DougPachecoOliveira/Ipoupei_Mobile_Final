// 🔐 Login Page - iPoupei Mobile
// 
// Tela de login simples com email e senha
// Integra com SupabaseAuthService
// 
// Baseado em: Material Design + Clean Architecture

import 'package:flutter/material.dart';

import '../../../auth_integration.dart';
import '../components/auth_form.dart';
import '../components/loading_overlay.dart';
import '../../configuracoes/services/usuario_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  /// 🔐 REALIZA LOGIN
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await authIntegration.authService.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Verificar se a conta está desativada
      if (mounted) {
        await _checkAccountStatus();
      }

    } catch (e) {
      setState(() {
        // Remove prefixos comuns e melhora a mensagem
        String errorMsg = e.toString()
            .replaceAll('Exception: ', '')
            .replaceAll('AuthException: ', '')
            .replaceAll('Error: ', '');

        // Mensagens amigáveis para erros comuns
        if (errorMsg.contains('Invalid login credentials') ||
            errorMsg.contains('Email ou senha incorretos')) {
          _errorMessage = 'Email ou senha incorretos';
        } else if (errorMsg.contains('Email not confirmed')) {
          _errorMessage = 'Email não confirmado. Verifique sua caixa de entrada.';
        } else if (errorMsg.contains('Too many requests')) {
          _errorMessage = 'Muitas tentativas. Tente novamente em alguns minutos.';
        } else if (errorMsg.contains('Network') || errorMsg.contains('network') ||
                   errorMsg.contains('connection') || errorMsg.contains('Connection')) {
          _errorMessage = 'Erro de conexão. Verifique sua internet.';
        } else {
          // Usa a mensagem tratada ou uma mensagem genérica
          _errorMessage = errorMsg.isNotEmpty ? errorMsg : 'Erro ao fazer login. Tente novamente.';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// 🔍 VERIFICA STATUS DA CONTA APÓS LOGIN
  Future<void> _checkAccountStatus() async {
    try {
      final usuarioService = UsuarioService.instance;
      final result = await usuarioService.checkAccountStatus();

      if (!mounted) return;

      if (result['success'] == true) {
        final contaAtiva = result['conta_ativa'] as bool? ?? true;

        if (!contaAtiva) {
          // Conta está desativada - mostrar dialog
          await _showReactivationDialog();
        } else {
          // Conta ativa - navegar normalmente
          Navigator.of(context).pushReplacementNamed('/navigation');
        }
      } else {
        // Erro ao verificar - navegar mesmo assim
        Navigator.of(context).pushReplacementNamed('/navigation');
      }
    } catch (e) {
      // Erro ao verificar - navegar mesmo assim
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/navigation');
      }
    }
  }

  /// 🔄 MOSTRA DIALOG DE REATIVAÇÃO
  Future<void> _showReactivationDialog() async {
    final shouldReactivate = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.pause_circle, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Conta Desativada'),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Você poderá voltar a usar todas as funcionalidades do iPoupei.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Reativar Conta'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (shouldReactivate == true) {
      // Reativar conta
      await _reactivateAccount();
    } else {
      // Fazer logout e voltar para login
      await authIntegration.authService.signOut();
      setState(() {
        _isLoading = false;
        _errorMessage = 'Você precisa reativar sua conta para continuar.';
      });
    }
  }

  /// ✅ REATIVA A CONTA
  Future<void> _reactivateAccount() async {
    try {
      final usuarioService = UsuarioService.instance;
      final result = await usuarioService.reactivateAccount();

      if (!mounted) return;

      if (result['success'] == true) {
        // Conta reativada - navegar para app
        Navigator.of(context).pushReplacementNamed('/navigation');
      } else {
        // Erro ao reativar
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao reativar conta. Tente novamente.';
        });
        await authIntegration.authService.signOut();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao reativar conta. Tente novamente.';
        });
      }
      await authIntegration.authService.signOut();
    }
  }

  /// 📝 NAVEGA PARA CADASTRO
  void _goToSignUp() {
    Navigator.of(context).pushNamed('/signup');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo/Título
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'iPoupei',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Controle financeiro inteligente',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Formulário de Login
                AuthForm(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  errorMessage: _errorMessage,
                ),
                
                
                const SizedBox(height: 24),
                
                // Botão de Login
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Link para esqueci senha
                TextButton(
                  onPressed: () {
                    // TODO: Implementar forgot password
                  },
                  child: Text(
                    'Esqueci minha senha',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Divisor
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Link para cadastro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Não tem uma conta? ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: _goToSignUp,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: Text(
                        'Cadastre-se',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}