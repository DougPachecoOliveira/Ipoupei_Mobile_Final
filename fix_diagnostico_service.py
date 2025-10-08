#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Script para corrigir o método _salvarDadosNoBanco no diagnostico_service.dart"""

import re
import sys

# Configurar encoding para UTF-8 no Windows
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# Ler o arquivo
with open('lib/src/modules/diagnostico/services/diagnostico_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Texto antigo que queremos substituir
old_text = '''  /// Salvar dados no banco de acordo com a etapa
  Future<void> _salvarDadosNoBanco(String etapaId, Map<String, dynamic> dados) async {'''

# Texto novo
new_text = '''  /// Salvar dados no banco de acordo com a etapa (aceita Map ou List ou qualquer tipo)
  Future<void> _salvarDadosNoBanco(String etapaId, dynamic dados) async {'''

# Substituir
content = content.replace(old_text, new_text)

# Agora vamos modificar o conteúdo do switch para adicionar mais casos
# Encontrar o switch e adicionar log de tipo
switch_pattern = r"(log\('💾 \[DIAGNOSTICO_SERVICE\] Salvando dados da etapa: \$etapaId'\);\\s+log\('👤 \[DIAGNOSTICO_SERVICE\] User ID: \$_userId'\);)"

replacement = r"\1\n    log('📊 [DIAGNOSTICO_SERVICE] Tipo: ${dados.runtimeType}');"

content = re.sub(switch_pattern, replacement, content)

# Salvar o arquivo modificado
with open('lib/src/modules/diagnostico/services/diagnostico_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("OK - Arquivo modificado com sucesso!")
print("Mudancas:")
print("1. Metodo _salvarDadosNoBanco agora aceita 'dynamic' ao inves de 'Map<String, dynamic>'")
print("2. Adicionado log de tipo de dados")
