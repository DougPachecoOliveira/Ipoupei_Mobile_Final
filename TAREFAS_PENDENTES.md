# ✅ Tarefas Pendentes - iPoupei Mobile

## 🎯 Status Atual do Projeto

### ✅ O que JÁ ESTÁ PRONTO (Código):

- ✅ Login com Email/Senha funcionando
- ✅ Cadastro funcionando
- ✅ Botão "Continuar com Google" implementado
- ✅ Deep links configurados no AndroidManifest.xml
- ✅ `redirectTo` correto: `com.ipoupei.app://auth/callback`
- ✅ Função `signInWithGoogle()` implementada
- ✅ Função `resetPassword()` implementada (envia email)
- ✅ Navegação principal inicia em Relatórios
- ✅ LoginIpoupeiPage com Google SSO e botão de demonstração

---

## ⚠️ O que FALTA FAZER

### 🔴 PRIORIDADE ALTA - Configurações no Supabase/Google Cloud

Estas são **configurações externas** que você precisa fazer manualmente:

---

### 1️⃣ Configurar Google SSO (OBRIGATÓRIO para login com Google funcionar)

**Status:** ❌ Google SSO não funciona sem isso

**Tempo estimado:** 10 minutos

**Documentação:** `GOOGLE_SSO_CHECKLIST.md`

#### Passo 1: Google Cloud Console

🔗 https://console.cloud.google.com/apis/credentials

```
1. Criar OAuth Client ID → Android
2. Package name: com.example.ipoupei_mobile
3. SHA-1: B1:AD:28:BA:31:59:F0:25:02:40:AC:18:7C:81:78:38:82:A9:01:E8
4. Criar → Copiar Client ID gerado
```

#### Passo 2: Supabase Dashboard

🔗 https://supabase.com/dashboard/project/ykifgrblmicoymavcqnu/auth/providers

```
1. Authentication → URL Configuration
2. Additional Redirect URLs → Adicionar:
   com.ipoupei.app://auth/callback

3. Authentication → Providers → Google
4. Authorized Client IDs → Colar o Client ID Android do passo 1
5. Save
```

#### Passo 3: Voltar ao Google Cloud Console

```
1. OAuth Client ID (Web) → Authorized redirect URIs
2. Adicionar APENAS:
   https://ykifgrblmicoymavcqnu.supabase.co/auth/v1/callback
3. Save
```

#### Passo 4: Testar

```bash
flutter run --release
```

Testar em dispositivo físico (não funciona em emulador)

---

### 2️⃣ Configurar SMTP no Supabase (OBRIGATÓRIO para emails funcionarem)

**Status:** ❌ Recuperação de senha não funciona sem isso

**Tempo estimado:** 5-10 minutos

**Documentação:** `SUPABASE_EMAIL_SETUP.md`

#### Opção A: Gmail (Mais Fácil)

🔗 https://supabase.com/dashboard/project/ykifgrblmicoymavcqnu/settings/auth

```
1. Project Settings → Auth → SMTP Settings
2. Enable Custom SMTP: ✅
3. Preencher:
   - SMTP Host: smtp.gmail.com
   - SMTP Port: 587
   - SMTP User: seu-email@gmail.com
   - SMTP Password: [Senha de app do Gmail]
   - Sender Email: seu-email@gmail.com
   - Sender Name: iPoupei
4. Save
```

**Como criar senha de app no Gmail:**
- https://myaccount.google.com/apppasswords
- Criar senha de app: "Supabase iPoupei"
- Copiar senha gerada

#### Opção B: SendGrid (Produção)

```
1. Criar conta: https://sendgrid.com/
2. Criar API Key
3. Configurar no Supabase:
   - SMTP Host: smtp.sendgrid.net
   - SMTP Port: 587
   - SMTP User: apikey
   - SMTP Password: [API Key do SendGrid]
```

#### Testar

```
1. Abrir app
2. "Esqueceu a senha?"
3. Digitar email
4. Verificar se email chegou
```

---

### 🟡 PRIORIDADE MÉDIA - Criar Página de Reset Password no Mobile

**Status:** ❌ Código falta implementar

**Tempo estimado:** 30-40 minutos

**Por que falta:** O Web tem a página `ResetPassword.jsx`, mas o Mobile não tem equivalente.

**O que acontece agora:**
1. ✅ Usuário clica "Esqueceu a senha?"
2. ✅ Email é enviado (depois de configurar SMTP)
3. ✅ Usuário clica no link
4. ✅ App abre via deep link
5. ❌ **App não mostra tela para definir nova senha**

#### O que precisa ser criado:

**1. Criar arquivo:** `lib/src/modules/auth/pages/reset_password_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth_integration.dart';

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
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'As senhas não coincidem';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Atualizar senha
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      if (mounted) {
        // Mostrar sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha redefinida com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar para a tela principal
        Navigator.of(context).pushReplacementNamed('/navigation');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao redefinir senha: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF008080),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 40,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/Logo.png',
                      width: 140,
                      height: 140,
                    ),
                    const SizedBox(height: 24),

                    // Título
                    const Text(
                      'Redefinir Senha',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'Digite sua nova senha',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6b7280),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Mensagem de erro
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Campo Nova Senha
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Nova senha',
                        hintText: 'Digite sua nova senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF008080), width: 2),
                        ),
                      ),
                      obscureText: !_showPassword,
                      enabled: !_isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite a nova senha';
                        }
                        if (value.length < 6) {
                          return 'A senha deve ter pelo menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo Confirmar Senha
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirme a senha',
                        hintText: 'Confirme sua nova senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF008080), width: 2),
                        ),
                      ),
                      obscureText: !_showConfirmPassword,
                      enabled: !_isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirme a senha';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Botão Redefinir
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleResetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008080),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF9CA3AF),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**2. Adicionar rota em `main.dart`:**

```dart
routes: {
  '/login': (context) => const LoginIpoupeiPage(),
  '/signup': (context) => const SignUpPage(),
  '/reset-password': (context) => const ResetPasswordPage(), // ← ADICIONAR
  '/navigation': (context) => const MainNavigation(),
  // ...
},
```

**3. Tratar deep link de password recovery:**

No `main.dart` ou `auth_integration.dart`, adicionar listener:

```dart
// Escutar mudanças de autenticação
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  final event = data.event;

  // Se for recovery de senha, navegar para reset-password
  if (event == AuthChangeEvent.passwordRecovery) {
    navigatorKey.currentState?.pushReplacementNamed('/reset-password');
  }
  // Login normal
  else if (event == AuthChangeEvent.signedIn) {
    navigatorKey.currentState?.pushReplacementNamed('/navigation');
  }
});
```

---

## 📋 RESUMO - O que fazer AGORA

### Ordem de Prioridade:

#### 1️⃣ **Configurar Google SSO** (10 min)
- Google Cloud → Criar OAuth Client ID Android
- Supabase → Adicionar deep link e Client ID
- Testar login com Google

**Arquivo guia:** `GOOGLE_SSO_CHECKLIST.md`

---

#### 2️⃣ **Configurar SMTP** (5-10 min)
- Supabase → SMTP Settings
- Gmail ou SendGrid
- Testar envio de email

**Arquivo guia:** `SUPABASE_EMAIL_SETUP.md`

---

#### 3️⃣ **Criar página Reset Password** (30-40 min)
- Criar `reset_password_page.dart`
- Adicionar rota
- Tratar evento de recovery
- Testar fluxo completo

**Arquivo guia:** `RECUPERACAO_SENHA_WEB_VS_MOBILE.md`

---

## ✅ Após Tudo Configurado

O app estará **100% funcional** com:
- ✅ Login com Email/Senha
- ✅ Cadastro
- ✅ Google SSO (Android)
- ✅ Recuperação de senha completa
- ✅ Deep links funcionando
- ✅ Navegação correta

---

## 🎯 Próximos Passos (Futuro)

Depois do básico funcionando:
- [ ] Configurar Google SSO para iOS
- [ ] Build de release para produção
- [ ] Publicar na Google Play Store
- [ ] Melhorias de UI/UX
- [ ] Testes automatizados

---

## 📞 Precisa de Ajuda?

**Configurações:**
- Google Cloud: Difícil? Veja prints no `GOOGLE_SSO_CHECKLIST.md`
- SMTP: Use Gmail primeiro (mais fácil)

**Código:**
- Reset Password: Código completo está acima
- Copiar e colar deve funcionar

**Testes:**
- Google SSO: Precisa dispositivo físico
- Email: Verifique pasta Spam

---

**🚀 Comece pela configuração do Google SSO - é o mais importante e rápido!**
