# 🔑 Recuperação de Senha - Web vs Mobile

## 📋 Como Funciona nos Dois Projetos

---

## 🌐 iPoupei WEB (React)

### 📂 Localização do Código

```
C:\Projetos Flutter\ipoupei\src\modules\auth\
├── store/authStore.js         ← Função resetPassword()
├── pages/Login.jsx             ← Formulário "Esqueceu a senha?"
└── pages/ResetPassword.jsx     ← Página para redefinir senha
```

---

### 🔄 Fluxo Completo

#### 1️⃣ Usuário Clica em "Esqueceu a senha?"

**Arquivo:** `Login.jsx`

```jsx
// Botão na tela de login
<button onClick={() => setMode('recovery')}>
  Esqueceu a senha?
</button>
```

#### 2️⃣ Usuário Digita Email e Clica "Enviar Link"

**Arquivo:** `Login.jsx` (linha 198-204)

```jsx
const result = await resetPassword(email);
```

#### 3️⃣ Chamada para Supabase

**Arquivo:** `authStore.js` (linha 235-252)

```javascript
resetPassword: async (email) => {
  const { error } = await supabase.auth.resetPasswordForEmail(
    email.trim(),
    {
      redirectTo: `${window.location.origin}/reset-password`
      // Exemplo: https://ipoupei.vercel.app/reset-password
    }
  );

  if (error) throw error;

  return { success: true };
}
```

**✅ URL de Redirecionamento:**
```
https://ipoupei.vercel.app/reset-password
(ou http://localhost:5173/reset-password em dev)
```

#### 4️⃣ Supabase Envia Email

Email contém link como:
```
https://ipoupei.vercel.app/reset-password?token=abc123...
```

#### 5️⃣ Usuário Clica no Link do Email

Abre navegador → `https://ipoupei.vercel.app/reset-password?token=abc123`

#### 6️⃣ Página ResetPassword.jsx Carrega

**Arquivo:** `ResetPassword.jsx`

```jsx
// Verifica se o usuário está autenticado (com token válido)
if (!isAuthenticated) {
  // Mostra erro: "Link inválido ou expirado"
  return <ErrorMessage />;
}

// Token válido → Mostra formulário para nova senha
return (
  <form onSubmit={handleSubmit}>
    <input type="password" placeholder="Nova senha" />
    <input type="password" placeholder="Confirme a senha" />
    <button>Redefinir senha</button>
  </form>
);
```

#### 7️⃣ Usuário Define Nova Senha

**Arquivo:** `ResetPassword.jsx` (linha 65)

```jsx
const { success } = await updatePassword(newPassword);

if (success) {
  // Redireciona para dashboard após 3 segundos
  navigate('/app/dashboard');
}
```

---

## 📱 iPoupei MOBILE (Flutter)

### 📂 Localização do Código

```
C:\Projetos Flutter\ipoupei_mobile\lib\src\
├── supabase_auth_service.dart      ← Função resetPassword()
└── modules/auth/pages/
    └── login_ipoupei_page.dart     ← Formulário "Esqueceu a senha?"
```

---

### 🔄 Fluxo Completo

#### 1️⃣ Usuário Clica em "Esqueceu a senha?"

**Arquivo:** `login_ipoupei_page.dart`

```dart
TextButton(
  onPressed: () => _changeMode(AuthMode.recovery),
  child: Text('Esqueceu a senha?'),
)
```

#### 2️⃣ Usuário Digita Email e Clica "Enviar Link"

**Arquivo:** `login_ipoupei_page.dart` (linha 154-161)

```dart
case AuthMode.recovery:
  await authIntegration.authService.resetPassword(
    email: _emailController.text.trim(),
  );
  setState(() {
    _successMessage = 'Email de recuperação enviado!';
  });
  break;
```

#### 3️⃣ Chamada para Supabase

**Arquivo:** `supabase_auth_service.dart` (linha 335-352)

```dart
Future<void> resetPassword({required String email}) async {
  await Supabase.instance.client.auth.resetPasswordForEmail(
    email.trim(),
    redirectTo: 'com.ipoupei.app://auth/callback', // Deep link
  );

  debugPrint('✅ Email de recuperação enviado');
}
```

**✅ URL de Redirecionamento:**
```
com.ipoupei.app://auth/callback
(Deep link que abre o app)
```

#### 4️⃣ Supabase Envia Email

Email contém link como:
```
com.ipoupei.app://auth/callback?token=abc123...
```

#### 5️⃣ Usuário Clica no Link do Email (Smartphone)

- Android detecta o deep link `com.ipoupei.app://`
- Abre automaticamente o app iPoupei

**Configuração:** `AndroidManifest.xml` (linha 45-55)

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />

    <!-- Deep link -->
    <data
        android:scheme="com.ipoupei.app"
        android:host="auth"
        android:path="/callback" />
</intent-filter>
```

#### 6️⃣ App Abre e Recebe Token

O Supabase Flutter SDK automaticamente:
- Detecta o callback
- Valida o token
- Autentica o usuário

#### 7️⃣ App Navega para Redefinição de Senha

**⚠️ PROBLEMA ATUAL:**
```
❌ Não existe página específica de redefinição de senha no Mobile!
```

O fluxo deveria ser:
1. ✅ Email enviado
2. ✅ Link clicado
3. ✅ App abre
4. ❌ Tela de redefinir senha (NÃO EXISTE)

---

## 📊 Comparação Side-by-Side

| Etapa | Web (React) | Mobile (Flutter) | Status |
|-------|-------------|------------------|--------|
| **1. Tela de recuperação** | ✅ Modo "recovery" na Login.jsx | ✅ AuthMode.recovery | ✅ OK |
| **2. Envio de email** | ✅ `resetPassword(email)` | ✅ `resetPassword(email)` | ✅ OK |
| **3. Redirect URL** | `https://ipoupei.vercel.app/reset-password` | `com.ipoupei.app://auth/callback` | ✅ OK |
| **4. Link no email** | HTTPS (abre navegador) | Deep link (abre app) | ✅ OK |
| **5. Página de reset** | ✅ `ResetPassword.jsx` | ❌ **NÃO EXISTE** | ❌ FALTA |
| **6. Formulário nova senha** | ✅ 2 campos + validação | ❌ **NÃO EXISTE** | ❌ FALTA |
| **7. Atualizar senha** | ✅ `updatePassword()` | ❌ **NÃO EXISTE** | ❌ FALTA |

---

## ❌ Problema Atual no Mobile

### O que acontece agora:

1. ✅ Usuário clica "Esqueceu a senha?"
2. ✅ Digita email
3. ✅ Clica "Enviar link"
4. ❌ **ERRO 500 - "Error sending recovery email"**

### Causa:

**SMTP não configurado no Supabase** → Email não é enviado

### Se o SMTP estivesse configurado:

1. ✅ Email seria enviado
2. ✅ Usuário clica no link
3. ✅ App abre (via deep link)
4. ❌ **App não sabe o que fazer com o callback de reset**
5. ❌ **Não existe tela para redefinir senha**

---

## ✅ Solução para o Mobile

### Precisa Criar:

#### 1️⃣ Página de Redefinição de Senha

**Criar:** `lib/src/modules/auth/pages/reset_password_page.dart`

```dart
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _handleResetPassword() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      // Mostra erro
      return;
    }

    // Atualizar senha
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: _passwordController.text),
    );

    // Sucesso → Navega para /navigation
    Navigator.of(context).pushReplacementNamed('/navigation');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Redefinir Senha')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Nova senha'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirme a senha'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleResetPassword,
              child: Text('Redefinir Senha'),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 2️⃣ Adicionar Função updatePassword no SupabaseAuthService

**Arquivo:** `supabase_auth_service.dart`

```dart
/// 🔄 ATUALIZAR SENHA
Future<void> updatePassword({required String newPassword}) async {
  await _waitForInitialization();

  debugPrint('🔄 Atualizando senha...');

  try {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );

    debugPrint('✅ Senha atualizada com sucesso');

  } catch (e) {
    debugPrint('❌ Erro ao atualizar senha: $e');
    throw Exception('Erro ao atualizar senha: $e');
  }
}
```

#### 3️⃣ Configurar Rota no main.dart

**Arquivo:** `main.dart`

```dart
routes: {
  '/login': (context) => const LoginIpoupeiPage(),
  '/signup': (context) => const SignUpPage(),
  '/reset-password': (context) => const ResetPasswordPage(), // NOVA
  '/navigation': (context) => const MainNavigation(),
  // ...
},
```

#### 4️⃣ Tratar Deep Link de Reset Password

Atualmente, o deep link `com.ipoupei.app://auth/callback` é tratado automaticamente pelo Supabase.

**O Supabase já:**
- ✅ Detecta o callback
- ✅ Valida o token
- ✅ Autentica o usuário

**Após autenticar, o app deveria:**
- Detectar que é um reset password (não login normal)
- Navegar para `/reset-password` (não `/navigation`)

**Isso pode ser feito verificando o tipo de evento:**

```dart
// Em auth_integration.dart ou main.dart
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  final event = data.event;

  if (event == AuthChangeEvent.passwordRecovery) {
    // Navegar para página de reset password
    navigatorKey.currentState?.pushReplacementNamed('/reset-password');
  } else if (event == AuthChangeEvent.signedIn) {
    // Login normal
    navigatorKey.currentState?.pushReplacementNamed('/navigation');
  }
});
```

---

## 🎯 Checklist Completo para Mobile

### Backend (Supabase):

- [ ] Configurar SMTP (Gmail, SendGrid, etc.)
- [ ] Adicionar `com.ipoupei.app://auth/callback` em Additional Redirect URLs
- [ ] Testar envio de email

### Código Mobile:

- [ ] Criar `ResetPasswordPage`
- [ ] Adicionar função `updatePassword()` no `SupabaseAuthService`
- [ ] Adicionar rota `/reset-password` no `main.dart`
- [ ] Tratar evento `AuthChangeEvent.passwordRecovery`
- [ ] Navegar para página correta após deep link

### Teste:

- [ ] Clicar em "Esqueceu a senha?"
- [ ] Digitar email e enviar
- [ ] Verificar email recebido
- [ ] Clicar no link do email
- [ ] App abre automaticamente
- [ ] Tela de redefinir senha aparece
- [ ] Digitar nova senha
- [ ] Senha atualizada com sucesso
- [ ] Login funciona com nova senha

---

## 📚 Referências

**Web (React):**
- `src/modules/auth/store/authStore.js:235` - resetPassword()
- `src/modules/auth/pages/Login.jsx:198` - Formulário recovery
- `src/modules/auth/pages/ResetPassword.jsx` - Página completa

**Mobile (Flutter):**
- `lib/src/supabase_auth_service.dart:335` - resetPassword()
- `lib/src/modules/auth/pages/login_ipoupei_page.dart:154` - Modo recovery
- ❌ Página de reset **NÃO EXISTE**

**Supabase Docs:**
- [Password Recovery](https://supabase.com/docs/guides/auth/auth-password-reset)
- [Deep Links](https://supabase.com/docs/guides/auth/auth-deep-linking)
- [SMTP Configuration](https://supabase.com/docs/guides/auth/auth-smtp)

---

**💡 Resumo:** O Web tem fluxo completo de recuperação de senha funcionando (exceto SMTP). O Mobile tem apenas envio de email, mas falta a tela de redefinição de senha.
