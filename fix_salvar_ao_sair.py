#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Script para adicionar salvamento no Supabase ao sair do diagnóstico"""

import sys

# Configurar encoding para UTF-8 no Windows
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# Ler o arquivo
with open('lib/src/modules/diagnostico/pages/diagnostico_flow_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Texto antigo
old_code = '''    ) ?? false;

    if (confirmar && mounted) {
      Navigator.of(context).pop();
    }
  }
}'''

# Texto novo com salvamento
new_code = '''    ) ?? false;

    if (confirmar && mounted) {
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
    }
  }
}'''

# Substituir
if old_code in content:
    content = content.replace(old_code, new_code)
    print("OK - Codigo encontrado e substituido!")
else:
    print("ERRO - Codigo antigo nao encontrado!")
    print("Procurando por variacao...")
    # Tentar sem considerar espaços exatos
    import re
    pattern = r'\)\s*\?\?\s*false;\s*if\s*\(confirmar\s*&&\s*mounted\)\s*\{\s*Navigator\.of\(context\)\.pop\(\);\s*\}\s*\}\s*\}'
    if re.search(pattern, content):
        print("Encontrado com regex! Substituindo...")
        content = re.sub(
            r'(\)\s*\?\?\s*false;)\s*(if\s*\(confirmar\s*&&\s*mounted\)\s*\{)\s*(Navigator\.of\(context\)\.pop\(\);)\s*(\}\s*\}\s*\})',
            r'''\1

    if (confirmar && mounted) {
      // SALVAR NO SUPABASE ANTES DE SAIR!
      try {
        final service = DiagnosticoService.instance;
        debugPrint('💾 [FLOW] Salvando progresso no Supabase antes de sair...');
        await service.salvarProgressoNoSupabase();
        debugPrint('✅ [FLOW] Progresso salvo com sucesso!');
      } catch (e) {
        debugPrint('❌ [FLOW] Erro ao salvar progresso: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aviso: não foi possível salvar o progresso ($e)'),
              backgroundColor: AppColors.amareloAlerta,
            ),
          );
        }
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}''',
            content
        )
    else:
        print("ERRO - Nao foi possivel encontrar o codigo!")
        sys.exit(1)

# Salvar
with open('lib/src/modules/diagnostico/pages/diagnostico_flow_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Arquivo modificado com sucesso!")
print("Agora o progresso sera salvo no Supabase ao sair do diagnostico.")
