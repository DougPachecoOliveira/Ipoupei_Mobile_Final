# ⚙️ Página de Configurações - Como Funciona

## 📋 O QUE FOI IMPLEMENTADO

Acabamos de criar a **Página de Configurações do Usuário** completa no iPoupei Mobile.

---

## 🔄 COMO FUNCIONA A SINCRONIZAÇÃO

### **1. ONDE OS DADOS SÃO SALVOS**

A página de Configurações trabalha com **2 locais de armazenamento**:

#### **📍 Supabase (Nuvem)**
```dart
// Tabela: perfil_usuario
{
  id: 'user-uuid',
  email: 'usuario@email.com',
  nome: 'João Silva',
  telefone: '11999999999',
  avatar_url: 'https://...',
  aceita_notificacoes: true,
  aceita_marketing: false,
  created_at: '2025-10-06T...',
  updated_at: '2025-10-06T...'
}

// Tabela: auth.users (user_metadata)
{
  id: 'user-uuid',
  email: 'usuario@email.com',
  user_metadata: {
    nome: 'João Silva',
    telefone: '11999999999',
    avatar_url: 'https://...'
  }
}
```

#### **📍 Offline (Não Aplicável)**
A página de **Configurações NÃO usa SQLite local** porque:
- ✅ Dados de perfil são leves (poucos KB)
- ✅ Sempre busca do Supabase em tempo real
- ✅ Garante dados mais atualizados
- ✅ Evita conflitos de sincronização

---

## 🔐 FLUXO DE FUNCIONAMENTO

### **AO ABRIR A PÁGINA:**

```dart
// 1. Busca perfil do Supabase
Future<void> _carregarPerfil() async {
  // Chama UsuarioService
  final profile = await _usuarioService.fetchUserProfile();

  // Atualiza UI com dados
  setState(() {
    _userProfile = profile;
    _nomeController.text = profile.nome ?? '';
    _telefoneController.text = profile.telefone ?? '';
    // ...
  });
}
```

**O que acontece:**
1. 🔍 Busca dados da tabela `perfil_usuario` no Supabase
2. 🔍 Combina com `user_metadata` do `auth.users`
3. 📱 Exibe na interface

---

### **AO SALVAR ALTERAÇÕES:**

```dart
// 2. Salva informações pessoais
Future<void> _salvarInformacoesPessoais() async {
  final success = await _usuarioService.updatePersonalInfo(
    nome: _nomeController.text.trim(),
    telefone: _telefoneController.text.trim(),
  );

  if (success) {
    _mostrarMensagem('Informações atualizadas!', 'success');
    _carregarPerfil(); // Recarrega dados
  }
}
```

**O que acontece:**
1. 📤 **ENVIA para Supabase** (2 locais):
   - `auth.users.user_metadata` (para auth)
   - `perfil_usuario` (para dados estendidos)

2. ✅ **Recebe confirmação**

3. 🔄 **Recarrega perfil** atualizado

**NÃO há SQLite** porque dados de perfil não precisam de cache offline.

---

## 🚀 CADA FUNCIONALIDADE

### **1️⃣ Informações Pessoais**

**Salvar:**
```dart
// UsuarioService.updatePersonalInfo()
1. Prepara dados:
   userMetadata = { nome, telefone, avatar_url }

2. Atualiza Supabase AUTH:
   supabase.auth.updateUser(UserAttributes(data: userMetadata))

3. Atualiza TABELA perfil_usuario:
   supabase.from('perfil_usuario').update(profileData)

4. Retorna sucesso
```

**Não usa SQLite** ✅

---

### **2️⃣ Alterar Senha**

```dart
// UsuarioService.updatePassword()
1. Verifica se é usuário Google (não pode alterar)

2. Atualiza senha no Supabase:
   supabase.auth.updateUser(UserAttributes(password: newPassword))

3. Retorna sucesso/erro
```

**Não usa SQLite** ✅

---

### **3️⃣ Preferências**

```dart
// UsuarioService.savePreferences()
1. Atualiza diretamente no Supabase:
   supabase.from('perfil_usuario').update({
     aceita_notificacoes: true/false,
     aceita_marketing: true/false
   })

2. Retorna sucesso
```

**Não usa SQLite** ✅

---

### **4️⃣ Gerar Backup**

```dart
// UsuarioService.generateBackup()
1. Busca TODAS as tabelas do usuário:
   - contas
   - cartoes
   - categorias
   - transacoes
   - transferencias
   - planejamentos

2. Monta JSON:
   {
     info: { usuario_id, email, data_backup },
     dados: { contas: [...], cartoes: [...] },
     resumo: { total_registros: 1234 }
   }

3. Retorna JSON (para download)
```

**Busca do Supabase, não do SQLite** ✅

---

### **5️⃣ Desativar/Excluir Conta**

```dart
// UsuarioService.deactivateAccount()
1. Marca conta como inativa:
   supabase.from('perfil_usuario').update({ ativo: false })

2. Faz logout:
   supabase.auth.signOut()
```

**Não usa SQLite** ✅

---

## ⚡ POR QUE NÃO USA OFFLINE-FIRST?

### **Comparação:**

| **Recurso** | **Usa SQLite?** | **Motivo** |
|------------|----------------|-----------|
| **Transações** | ✅ SIM | Muitos dados, precisa funcionar offline |
| **Contas** | ✅ SIM | Saldos precisam de cache local |
| **Cartões** | ✅ SIM | Faturas complexas, offline-first |
| **Configurações** | ❌ NÃO | Poucos dados, sempre busca atual |

---

### **Vantagens de NÃO usar SQLite para perfil:**

1. ✅ **Sempre dados atualizados**
   - Não há risco de dados desatualizados
   - Busca direto do servidor

2. ✅ **Sem conflitos de sincronização**
   - Não precisa resolver conflitos
   - Uma única fonte de verdade (Supabase)

3. ✅ **Mais simples**
   - Menos código
   - Menos bugs potenciais

4. ✅ **Leve**
   - Poucos dados (~1KB por perfil)
   - Resposta rápida mesmo online

---

## 📊 FLUXO COMPLETO VISUAL

```
┌─────────────────────────────────────────┐
│  USUÁRIO ABRE CONFIGURAÇÕES             │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  ConfiguracoesPage._carregarPerfil()    │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  UsuarioService.fetchUserProfile()      │
│  - Busca de perfil_usuario              │
│  - Combina com auth.users               │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│         SUPABASE (NUVEM)                │
│  📊 perfil_usuario                      │
│  🔐 auth.users.user_metadata            │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  Exibe dados na UI                      │
│  - Avatar, Nome, Email, Telefone        │
│  - Preferências                         │
└─────────────────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
┌─────────────┐   ┌──────────────────┐
│ Usuário     │   │ Clica em         │
│ edita dados │   │ "Salvar"         │
└─────────────┘   └──────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  UsuarioService.updatePersonalInfo()    │
│  - Valida dados                         │
│  - Prepara userMetadata                 │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│         SALVA NO SUPABASE               │
│  1. auth.updateUser(userMetadata)       │
│  2. perfil_usuario.update(data)         │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  ✅ Sucesso - Recarrega perfil          │
│  📱 Exibe mensagem "Atualizado!"        │
└─────────────────────────────────────────┘
```

---

## 🔑 PONTOS IMPORTANTES

### **1. Dupla Gravação**
```dart
// Sempre salva em 2 lugares:
// 1. auth.users (para autenticação)
await supabase.auth.updateUser(UserAttributes(data: userMetadata));

// 2. perfil_usuario (para dados estendidos)
await supabase.from('perfil_usuario').update(profileData);
```

### **2. Detecção Google SSO**
```dart
// Verifica provider antes de alterar senha
if (user.appMetadata['provider'] == 'google') {
  return 'Usuários Google não podem alterar senha aqui';
}
```

### **3. Validações**
```dart
// Telefone brasileiro
if (telefone.length < 10 || telefone.length > 11) {
  return erro;
}

// Senha mínima
if (senha.length < 6) {
  return erro;
}
```

---

## 📱 COMO O USUÁRIO VÊ

1. **Abre Configurações** → Busca dados do Supabase
2. **Edita nome/telefone** → Mantém local (não salvo ainda)
3. **Clica "Salvar"** → Envia para Supabase
4. **Recebe confirmação** → "✅ Atualizado!"
5. **Dados recarregam** → Mostra versão atualizada

**Tudo em tempo real, sem cache local!**

---

## 🆚 DIFERENÇA DE OUTRAS PÁGINAS

### **Transações Page (Offline-First):**
```dart
// 1. Salva no SQLite LOCAL primeiro
await LocalDatabase.instance.insertTransacao(transacao);

// 2. DEPOIS tenta sincronizar com Supabase
if (isOnline) {
  await supabase.from('transacoes').insert(data);
}

// 3. SyncManager sincroniza periodicamente
Timer.periodic(() => syncAll());
```

### **Configurações Page (Online-Only):**
```dart
// 1. Salva DIRETO no Supabase
await supabase.from('perfil_usuario').update(data);

// 2. Pronto! Não usa SQLite
```

---

## ✅ RESUMO FINAL

### **Configurações Page:**
- ❌ **NÃO usa SQLite local**
- ✅ **Busca direto do Supabase**
- ✅ **Salva direto no Supabase**
- ✅ **Sem sincronização necessária**
- ✅ **Sempre dados atualizados**

### **Por que é assim:**
1. Dados leves (perfil do usuário)
2. Não precisa funcionar offline
3. Sempre quer versão mais recente
4. Evita conflitos de sync

---

## 🎯 ARQUIVOS CRIADOS

1. **Model:** `user_profile_model.dart`
   - Define estrutura de dados

2. **Service:** `usuario_service.dart`
   - Busca/salva no Supabase
   - NÃO usa LocalDatabase

3. **Page:** `configuracoes_page.dart`
   - Interface das 5 abas
   - Chama UsuarioService

4. **Navegação:** `main_navigation.dart`
   - Adicionado 6º item no menu

---

**Implementado em:** Outubro 2025
**Status:** ✅ 100% Funcional
**Sincronização:** Online-Only (não usa Offline-First para perfil)
