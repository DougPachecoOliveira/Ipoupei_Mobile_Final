// 🚀 Exemplo de uso do Sistema de Categorias
// 
// Página de demonstração para testar todas as funcionalidades
// Use este arquivo para acessar facilmente o sistema
// 
// Para usar: Importe e navegue para CategoriasPageExample

import 'package:flutter/material.dart';
import '../pages/categorias_page.dart';

/// 🎯 PÁGINA DE EXEMPLO PARA TESTAR CATEGORIAS
/// 
/// Como usar:
/// 1. Importe este arquivo onde quiser
/// 2. Navegue para CategoriasPageExample()
/// 3. Clique no botão para abrir o sistema completo
class CategoriasPageExample extends StatelessWidget {
  const CategoriasPageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Sistema de Categorias'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.category,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                const Text(
                  '🚀 Sistema Completo de Categorias',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Interface visual 100% baseada no projeto antigo\ncom engine offline-sync da gestão de cartão',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Botão principal
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoriasPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('🎯 Abrir Sistema de Categorias'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Card com funcionalidades
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text(
                              'Funcionalidades Implementadas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem('🎨', 'Interface Visual', 'Header dinâmico, tabs animadas, cores do projeto antigo'),
                        _buildFeatureItem('🔄', 'Engine Offline-Sync', 'Carregamento paralelo, estados de loading, pull-to-refresh'),
                        _buildFeatureItem('📊', 'Dados Mockados', '4 categorias + 3 subcategorias para demonstração'),
                        _buildFeatureItem('🛠️', 'CRUD Completo', 'Criar, editar, excluir categorias e subcategorias'),
                        _buildFeatureItem('🎯', 'Ícones & Cores', 'Sistema completo de 600+ ícones e cores hex'),
                        _buildFeatureItem('📱', 'Responsivo', 'Cards, chips, menus contextuais e estados vazios'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Card com instruções
                Card(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Como Testar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '1. Clique no botão azul acima\n'
                          '2. Veja as categorias mockadas\n'
                          '3. Teste as tabs Despesas/Receitas\n'
                          '4. Use os botões do header (lâmpada, refresh, busca, +)\n'
                          '5. Toque nos cards para ver menus contextuais\n'
                          '6. Pull-to-refresh para recarregar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.2,
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

/// 🎯 EXEMPLO SIMPLES - Apenas o botão
class CategoriasQuickAccess extends StatelessWidget {
  const CategoriasQuickAccess({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CategoriasPage(),
          ),
        );
      },
      icon: const Icon(Icons.category),
      label: const Text('Categorias'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    );
  }
}

/// 🎯 EXEMPLO PARA HEADER - Para adicionar em qualquer AppBar
class CategoriasHeaderButton extends StatelessWidget {
  const CategoriasHeaderButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CategoriasPage(),
          ),
        );
      },
      icon: const Icon(Icons.category),
      tooltip: 'Sistema de Categorias',
    );
  }
}