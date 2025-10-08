// 📝 Auth Form - iPoupei Mobile
// 
// Formulário reutilizável para login e cadastro
// Validação integrada
// 
// Baseado em: Material Design + Form Validation

import 'package:flutter/material.dart';

class AuthForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController? nameController;
  final String? errorMessage;
  final bool isSignUp;
  
  const AuthForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    this.nameController,
    this.errorMessage,
    this.isSignUp = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo Nome (apenas no cadastro)
          if (isSignUp && nameController != null) ...[
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, digite seu nome';
                }
                if (value.trim().length < 2) {
                  return 'Nome deve ter pelo menos 2 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          
          // Campo Email
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, digite seu email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Email inválido';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Campo Senha
          TextFormField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, digite sua senha';
              }
              if (isSignUp && value.length < 6) {
                return 'Senha deve ter pelo menos 6 caracteres';
              }
              return null;
            },
          ),
          
          // Mensagem de erro
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 14,
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
}