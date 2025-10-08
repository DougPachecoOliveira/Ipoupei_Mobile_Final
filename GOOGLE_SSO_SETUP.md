# 🔵 Configuração do Google SSO no iPoupei Mobile

## ✅ Código Implementado

- ✅ `SupabaseAuthService.signInWithGoogle()` - Implementado
- ✅ `SupabaseAuthService.resetPassword()` - Implementado
- ✅ `LoginIpoupeiPage` - Google SSO botão pronto
- ✅ Deep links configurados: `ipoupei://login-callback` e `ipoupei://reset-password`

---

## 📋 Próximos Passos para Ativar Google SSO

### **1️⃣ Configurar OAuth no Google Cloud Console**

1. Acesse: https://console.cloud.google.com/
2. Crie um novo projeto ou selecione o existente "iPoupei"
3. Vá em **APIs & Services** → **Credentials**
4. Clique em **+ CREATE CREDENTIALS** → **OAuth client ID**

#### **Para Android:**
- Application type: **Android**
- Package name: `com.ipoupei.ipoupei_mobile` (ou o que está no `android/app/build.gradle`)
- SHA-1: Execute no terminal:
  ```bash
  cd android
  ./gradlew signingReport
  ```
  Copie o SHA-1 fingerprint do **debug** (ou **release** para produção)

#### **Para iOS:**
- Application type: **iOS**
- Bundle ID: Pegar do `ios/Runner.xcodeproj/project.pbxproj`

#### **Para Web (opcional):**
- Application type: **Web application**
- Authorized redirect URIs: `https://seu-projeto.supabase.co/auth/v1/callback`

5. Após criar, você receberá:
   - **Client ID**
   - **Client Secret**

---

### **2️⃣ Configurar Google SSO no Supabase**

1. Acesse o Supabase Dashboard: https://supabase.com/dashboard
2. Selecione seu projeto iPoupei
3. Vá em **Authentication** → **Providers**
4. Encontre **Google** e clique em **Enable**
5. Cole:
   - **Client ID** (do Google Cloud Console)
   - **Client Secret** (do Google Cloud Console)
6. Copie a **Callback URL** do Supabase:
   ```
   https://[SEU-PROJETO].supabase.co/auth/v1/callback
   ```
7. Volte ao Google Cloud Console e adicione essa URL em:
   **Credentials** → Seu OAuth Client → **Authorized redirect URIs**

8. **Salvar** no Supabase

---

### **3️⃣ Configurar Deep Links no Android**

Edite: `android/app/src/main/AndroidManifest.xml`

Adicione dentro da tag `<activity android:name=".MainActivity">`:

```xml
<!-- Deep Links para OAuth Callback -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />

    <!-- Scheme customizado -->
    <data
        android:scheme="ipoupei"
        android:host="login-callback" />
    <data
        android:scheme="ipoupei"
        android:host="reset-password" />
</intent-filter>

<!-- HTTPS Deep Links (opcional - recomendado para produção) -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />

    <data
        android:scheme="https"
        android:host="ipoupei.com"
        android:pathPrefix="/auth/callback" />
</intent-filter>
```

---

### **4️⃣ Configurar Deep Links no iOS**

Edite: `ios/Runner/Info.plist`

Adicione antes do último `</dict>`:

```xml
<!-- Deep Links -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.ipoupei.ipoupei_mobile</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>ipoupei</string>
        </array>
    </dict>
</array>

<!-- Universal Links (opcional) -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:ipoupei.com</string>
</array>
```

---

### **5️⃣ Atualizar Supabase URL no Código**

Edite: `lib/main.dart` (ou onde você inicializa o Supabase)

Verifique se o `redirectUrl` está configurado:

```dart
await Supabase.initialize(
  url: 'https://[SEU-PROJETO].supabase.co',
  anonKey: '[SUA-ANON-KEY]',
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce, // Importante para OAuth
  ),
);
```

---

### **6️⃣ Testar no Dispositivo Real**

⚠️ **Google SSO NÃO funciona no emulador/simulador**

1. **Build e instale no dispositivo físico:**
   ```bash
   flutter run --release
   ```

2. **Clique no botão "Continuar com Google"**

3. **Fluxo esperado:**
   - Abre o navegador/Google
   - Usuário faz login no Google
   - Redireciona de volta para o app (via deep link)
   - App recebe token e faz login automático
   - Navega para `/home`

---

## 🐛 Troubleshooting

### **Erro: "redirect_uri_mismatch"**
- ✅ Verifique se a Callback URL do Supabase está nas **Authorized redirect URIs** do Google Cloud
- ✅ Verifique se não há espaços ou caracteres extras

### **App não abre após login no Google**
- ✅ Verifique os deep links no AndroidManifest.xml / Info.plist
- ✅ Teste o deep link manualmente: `adb shell am start -a android.intent.action.VIEW -d "ipoupei://login-callback"`

### **SHA-1 fingerprint errado**
- ✅ Use o comando `./gradlew signingReport` na pasta `android/`
- ✅ Para produção, use o SHA-1 da release keystore

### **Google SSO funciona no React mas não no Flutter**
- ✅ Certifique-se que o pacote Android é o mesmo nos dois
- ✅ Verifique se criou um OAuth Client ID separado para Android no Google Cloud

---

## 📱 Testando sem configurar Google Cloud

Se quiser testar a tela sem configurar o Google SSO:

1. Comente o botão Google na `login_ipoupei_page.dart`:
   ```dart
   // if (_mode == AuthMode.login) ...[
   //   _buildGoogleButton(),
   //   _buildDivider(),
   // ],
   ```

2. Use login/registro com email/senha normalmente

---

## ✅ Checklist Final

- [ ] OAuth Client ID criado no Google Cloud Console
- [ ] SHA-1 fingerprint adicionado (Android)
- [ ] Bundle ID configurado (iOS)
- [ ] Client ID e Secret salvos no Supabase
- [ ] Callback URL adicionada no Google Cloud
- [ ] Deep links configurados no AndroidManifest.xml
- [ ] Deep links configurados no Info.plist
- [ ] Testado em dispositivo físico Android
- [ ] Testado em dispositivo físico iOS

---

## 📚 Referências

- [Supabase Auth com Google](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Flutter Deep Links](https://docs.flutter.dev/development/ui/navigation/deep-linking)
- [Supabase Flutter Package](https://pub.dev/packages/supabase_flutter)

---

**💡 Dica:** Comece configurando para Android primeiro (é mais fácil). Depois faça iOS.
