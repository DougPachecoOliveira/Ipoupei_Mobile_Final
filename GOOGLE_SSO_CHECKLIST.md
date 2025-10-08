# ✅ Checklist - Google SSO iPoupei Mobile

## 📱 CÓDIGO JÁ ATUALIZADO ✅

- ✅ AndroidManifest.xml: Deep link `com.ipoupei.app://auth/callback`
- ✅ launchMode: `singleTask`
- ✅ Código Flutter: `redirectTo: 'com.ipoupei.app://auth/callback'`

---

## 📋 CONFIGURAÇÕES MANUAIS (VOCÊ PRECISA FAZER)

### 1️⃣ Supabase Dashboard

**URL:** https://supabase.com/dashboard

**Caminho:** Authentication → URL Configuration (Settings)

**SITE URL:**
- Pode manter o padrão do projeto
- Não precisa alterar

**Additional Redirect URLs:**
```
com.ipoupei.app://auth/callback
```

**Caminho:** Authentication → Providers → Google

- ✅ Enable Google: **LIGADO**
- ✅ Client ID: **[JÁ PREENCHIDO]**
- ✅ Client Secret: **[JÁ PREENCHIDO]**
- Clique em **SAVE**

---

### 2️⃣ Google Cloud Console

**URL:** https://console.cloud.google.com/apis/credentials

**Caminho:** APIs & Services → Credentials → OAuth 2.0 Client IDs → **Web application**

**Authorized redirect URIs (APENAS HTTPS do Supabase):**
```
https://ykifgrblmicoymavcqnu.supabase.co/auth/v1/callback
```

⚠️ **IMPORTANTE:**
- ✅ Adicione APENAS a URL HTTPS do Supabase
- ❌ NÃO adicione `com.ipoupei.app://auth/callback` aqui
- Clique em **SAVE**

---

### 3️⃣ Teste em Dispositivo Físico

⚠️ **Google SSO NÃO funciona no emulador!**

**Comandos:**
```bash
cd "C:\Projetos Flutter\ipoupei_mobile"
flutter clean
flutter pub get
flutter run --release
```

**Fluxo esperado:**
1. ✅ Toque em "Continuar com Google"
2. ✅ Abre navegador/Google
3. ✅ Faz login no Google
4. ✅ Redireciona para: `com.ipoupei.app://auth/callback`
5. ✅ Android reabre o app automaticamente
6. ✅ Sessão autenticada e navega para /home

---

## 🐛 Troubleshooting

### ❌ Erro: "redirect_uri_mismatch"

**Solução:**
- Verifique se `https://ykifgrblmicoymavcqnu.supabase.co/auth/v1/callback` está em **Authorized redirect URIs** no Google Cloud
- Verifique se não há espaços ou caracteres extras

### ❌ Login completa mas app não reabre

**Solução:**
- Confira tríplice conferência:
  - AndroidManifest: `scheme="com.ipoupei.app"`, `host="auth"`, `path="/callback"`
  - Supabase Additional Redirect URLs: `com.ipoupei.app://auth/callback`
  - Código: `redirectTo: 'com.ipoupei.app://auth/callback'`

### ❌ App reabre mas não loga

**Solução:**
- Verifique se o Supabase está sendo inicializado antes do tratamento do deep link
- Confira a versão do `supabase_flutter` no pubspec.yaml
- Verifique logs com `flutter run --release`

---

## ✅ Checklist Final

**Supabase:**
- [ ] Additional Redirect URLs contém `com.ipoupei.app://auth/callback`
- [ ] Google Provider habilitado
- [ ] Client ID e Secret salvos

**Google Cloud Console:**
- [ ] Authorized redirect URIs inclui APENAS `https://ykifgrblmicoymavcqnu.supabase.co/auth/v1/callback`
- [ ] NÃO incluir `com.ipoupei.app://auth/callback` no Google Cloud

**Código (JÁ FEITO):**
- [✅] AndroidManifest.xml com deep link correto
- [✅] launchMode="singleTask"
- [✅] redirectTo correto no código Flutter

**Teste:**
- [ ] Testado em dispositivo físico Android
- [ ] Login com Google funcionando
- [ ] App reabre automaticamente após login
- [ ] Navegação para /home OK

---

## 📊 Resumo de URLs

| Local | URL | Tipo |
|-------|-----|------|
| **Supabase - Additional Redirect URLs** | `com.ipoupei.app://auth/callback` | Deep Link |
| **Google Cloud - Authorized redirect URIs** | `https://ykifgrblmicoymavcqnu.supabase.co/auth/v1/callback` | HTTPS |
| **AndroidManifest.xml** | `scheme="com.ipoupei.app"` `host="auth"` `path="/callback"` | Deep Link |
| **Código Flutter** | `redirectTo: 'com.ipoupei.app://auth/callback'` | Deep Link |

---

## 🎯 Diferença Chave

**Web OAuth (Google Cloud):**
- Usa HTTPS redirect do Supabase
- Não conhece deep links do app

**Mobile Deep Link (Supabase + Android):**
- Supabase sabe redirecionar para deep link
- Android captura via intent-filter

Por isso:
- Google Cloud → HTTPS do Supabase ✅
- Supabase → Deep link do app ✅
