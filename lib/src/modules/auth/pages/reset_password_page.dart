// 🔑 Reset Password Page - iPoupei Mobile
//
// Página para redefinir senha após clicar no link do email
// Equivalente ao ResetPassword.jsx do React
//
// Fluxo:
// 1. Usuário clica "Esqueceu a senha?" → envia email
// 2. Email contém link com deep link → abre app
// 3. App detecta passwordRecovery → navega para esta página
// 4. Usuário define nova senha → atualiza no Supabase

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_colors.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// ✅ VALIDAR SENHAS
  bool _validatePasswords() {
    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'A senha deve ter pelo menos 6 caracteres';
      });
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'As senhas não coincidem';
      });
      return false;
    }

    return true;
  }

  /// 🔄 REDEFINIR SENHA
  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_validatePasswords()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Atualizar senha no Supabase
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      setState(() {
        _successMessage = 'Senha redefinida com sucesso! Redirecionando...';
      });

      // Aguardar 2 segundos e redirecionar
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/navigation');
      }
    } catch (e) {
      debugPrint('❌ Erro ao redefinir senha: $e');
      setState(() {
        _errorMessage = 'Erro ao redefinir senha. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background com gradiente teal
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.tealPrimary,
                  AppColors.tealEscuro,
                  Color(0xFF004D4D),
                ],
              ),
            ),
          ),

          // Conteúdo
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _buildCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 💳 CARD PRINCIPAL
  Widget _buildCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.tealClaro,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildTitle(),
                const SizedBox(height: 24),
                if (_errorMessage != null) _buildErrorMessage(),
                if (_successMessage != null) _buildSuccessMessage(),
                if (_successMessage == null) ...[
                  _buildForm(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                ],
                const SizedBox(height: 24),
                _buildBackToLogin(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📷 HEADER COM LOGO
  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/Logo.png',
          width: 140,
          height: 140,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        const Text(
          'Defina sua nova senha de acesso',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.cinzaMedio,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// 🔤 TÍTULO
  Widget _buildTitle() {
    return const Text(
      'Redefinir Senha',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.cinzaEscuro,
      ),
    );
  }

  /// ❌ MENSAGEM DE ERRO
  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.vermelhoErro10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.vermelhoErro20),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.vermelhoErro, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.vermelhoErro,
                fontSize: 13,
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.verdeSucesso10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.verdeSucesso20),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.verdeSucesso, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _successMessage!,
              style: const TextStyle(
                color: AppColors.verdeSucesso,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 FORMULÁRIO
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nova Senha
          _buildTextField(
            controller: _passwordController,
            label: 'Nova senha',
            hint: 'Digite sua nova senha',
            icon: Icons.lock_outline,
            obscureText: !_showPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.cinzaMedio,
              ),
              onPressed: () =>
                  setState(() => _showPassword = !_showPassword),
            ),
          ),
          const SizedBox(height: 16),

          // Confirmar Senha
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirmar senha',
            hint: 'Confirme sua nova senha',
            icon: Icons.lock_outline,
            obscureText: !_showConfirmPassword,
            textInputAction: TextInputAction.done,
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: AppColors.cinzaMedio,
              ),
              onPressed: () => setState(
                  () => _showConfirmPassword = !_showConfirmPassword),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔤 TEXT FIELD
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.cinzaMedio),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.cinzaClaro,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cinzaBorda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cinzaBorda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.tealPrimary, width: 2),
        ),
      ),
      obscureText: obscureText,
      textInputAction: textInputAction ?? TextInputAction.next,
      enabled: !_isLoading,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo obrigatório';
        }
        return null;
      },
    );
  }

  /// 🔘 BOTÃO SUBMIT
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleResetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tealPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.cinzaMedio,
          elevation: 0,
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
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_reset, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Redefinir Senha',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 🔗 VOLTAR PARA LOGIN
  Widget _buildBackToLogin() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.cinzaBorda, width: 1),
        ),
      ),
      child: TextButton(
        onPressed: _isLoading
            ? null
            : () => Navigator.of(context).pushReplacementNamed('/login'),
        child: const Text(
          'Voltar para login',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.tealPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
