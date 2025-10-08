// 🎯 Demo Credentials Button - iPoupei Mobile
// 
// Botão para preencher credenciais de demonstração
// 
// Baseado em: Demo/Development patterns

import 'package:flutter/material.dart';

class DemoCredentialsButton extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController? nameController;
  
  const DemoCredentialsButton({
    super.key,
    required this.emailController,
    required this.passwordController,
    this.nameController,
  });
  
  void _fillDemoCredentials() {
    emailController.text = 'daolive.big+ipoupei1@gmail.com';
    passwordController.text = 'Doug1707';
    if (nameController != null) {
      nameController!.text = 'Douglas Oliveira';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: OutlinedButton.icon(
        onPressed: _fillDemoCredentials,
        icon: Icon(
          Icons.science,
          color: Colors.orange[600],
          size: 18,
        ),
        label: Text(
          'Preencher dados de demonstração',
          style: TextStyle(
            color: Colors.orange[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.orange[300]!),
          backgroundColor: Colors.orange[50],
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}