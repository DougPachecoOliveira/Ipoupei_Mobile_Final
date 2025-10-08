#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Remove chamada para método inexistente salvarProgressoNoSupabase"""

import sys

if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# Ler o arquivo
with open('lib/src/modules/diagnostico/pages/diagnostico_flow_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Texto antigo com a chamada errada
old_code = '''    if (confirmar && mounted) {
      // SALVAR NO SUPABASE ANTES DE SAIR!
      try {
        final service = DiagnosticoService.instance;
        debugPrint('💾 [FLOW] Salvando progresso no Supabase antes de sair...');
        await service.salvarProgressoNoSupabase();
        debugPrint('✅ [FLOW] Progresso salvo com sucesso!');
      } catch (e) {
        debugPrint('❌ [FLOW] Erro ao salvar progresso: $e');
        // Mostrar feedback ao usuário
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aviso: não foi possível salvar o progresso ($e)'),
              backgroundColor: AppColors.amareloAlerta,
            ),
          );
        }
      }

      // Fechar a tela
      if (mounted) {
        Navigator.of(context).pop();
      }
    }'''

# Texto novo sem a chamada
new_code = '''    if (confirmar && mounted) {
      // O progresso ja esta sendo salvo automaticamente
      debugPrint('💾 [FLOW] Fechando diagnostico...');
      Navigator.of(context).pop();
    }'''

# Substituir
if old_code in content:
    content = content.replace(old_code, new_code)
    print("OK - Codigo substituido!")
else:
    print("ERRO - Codigo nao encontrado! Tentando regex...")
    import re
    # Tentar capturar o bloco inteiro
    pattern = r'if \(confirmar && mounted\) \{[^}]*?salvarProgressoNoSupabase\(\);[^}]*?\}\s*\}'
    if re.search(pattern, content, re.DOTALL):
        content = re.sub(
            r'if \(confirmar && mounted\) \{\s*// SALVAR NO SUPABASE.*?Navigator\.of\(context\)\.pop\(\);\s*\}\s*\}',
            '''if (confirmar && mounted) {
      debugPrint('💾 [FLOW] Fechando diagnostico...');
      Navigator.of(context).pop();
    }''',
            content,
            flags=re.DOTALL
        )
        print("OK - Substituido via regex!")
    else:
        print("ERRO - Nao encontrado!")
        sys.exit(1)

# Salvar
with open('lib/src/modules/diagnostico/pages/diagnostico_flow_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Arquivo corrigido!")
print("Removida chamada para metodo inexistente salvarProgressoNoSupabase()")
