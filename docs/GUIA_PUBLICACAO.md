# GUIA DE PUBLICAÇÃO - iPoupei

**Passo a passo completo para publicar o app nas lojas**

---

## CHECKLIST PRÉ-PUBLICAÇÃO

### Documentação (Concluído)
- [x] Política de Privacidade
- [x] Termos de Uso
- [x] FAQ / Central de Ajuda
- [x] Textos para as lojas
- [x] Changelog

### Configurações do Projeto (Pendente)
- [ ] Alterar Application ID
- [ ] Configurar assinatura (keystore)
- [ ] Atualizar nome do app
- [ ] Gerar build de release

### Contas de Desenvolvedor (Você faz)
- [ ] Google Play Console ($25)
- [ ] Apple Developer ($99/ano) - se for iOS

### Assets Gráficos (Você faz)
- [ ] Ícone 512x512px
- [ ] Feature Graphic 1024x500px
- [ ] Screenshots (mínimo 2)

---

## PARTE 1: CONFIGURAÇÕES DO PROJETO

### 1.1 Alterar Application ID

O `applicationId` atual é `com.example.ipoupei_mobile`. Deve ser alterado para um ID único.

**Sugestão:** `br.com.ipoupei.app`

**Arquivo:** `android/app/build.gradle.kts`

```kotlin
defaultConfig {
    applicationId = "br.com.ipoupei.app"  // ALTERAR AQUI
    minSdk = 21
    targetSdk = 36
    ...
}
```

**Arquivo:** `android/app/src/main/AndroidManifest.xml`

Atualizar o deep link:
```xml
<data
    android:scheme="br.com.ipoupei.app"
    android:host="auth"
    android:path="/callback" />
```

### 1.2 Atualizar Nome do App

**Arquivo:** `android/app/src/main/AndroidManifest.xml`

```xml
<application
    android:label="iPoupei"  <!-- Nome que aparece no celular -->
    ...
```

### 1.3 Atualizar namespace

**Arquivo:** `android/app/build.gradle.kts`

```kotlin
android {
    namespace = "br.com.ipoupei.app"  // ALTERAR AQUI
    ...
}
```

---

## PARTE 2: CRIAR KEYSTORE (ASSINATURA)

### 2.1 Gerar Keystore

Execute no terminal:

```bash
keytool -genkey -v -keystore ~/ipoupei-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ipoupei
```

**IMPORTANTE:** Guarde a senha em local seguro! Se perder, não poderá atualizar o app.

### 2.2 Criar arquivo key.properties

Criar arquivo `android/key.properties`:

```properties
storePassword=SUA_SENHA_AQUI
keyPassword=SUA_SENHA_AQUI
keyAlias=ipoupei
storeFile=/caminho/para/ipoupei-release-key.jks
```

**IMPORTANTE:** Adicione este arquivo ao `.gitignore`!

### 2.3 Configurar build.gradle.kts para usar keystore

**Arquivo:** `android/app/build.gradle.kts`

Adicionar antes do bloco `android`:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Dentro do bloco `android`, adicionar:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}
```

---

## PARTE 3: GERAR BUILD DE RELEASE

### 3.1 App Bundle (Recomendado para Google Play)

```bash
flutter build appbundle --release
```

O arquivo será gerado em:
`build/app/outputs/bundle/release/app-release.aab`

### 3.2 APK (Alternativa)

```bash
flutter build apk --release
```

O arquivo será gerado em:
`build/app/outputs/flutter-apk/app-release.apk`

---

## PARTE 4: GOOGLE PLAY CONSOLE

### 4.1 Criar Conta de Desenvolvedor

1. Acesse: https://play.google.com/console
2. Faça login com conta Google
3. Pague a taxa única de **$25**
4. Preencha informações do desenvolvedor

### 4.2 Criar Novo App

1. Clique em **"Criar app"**
2. Preencha:
   - Nome: **iPoupei**
   - Idioma: **Português (Brasil)**
   - Tipo: **App**
   - Gratuito/Pago: **Pago** (ou com assinatura)

### 4.3 Configurar Ficha da Loja

**Seção: Ficha principal da loja**

| Campo | Valor |
|-------|-------|
| Nome do app | iPoupei |
| Descrição curta | (usar texto do arquivo TEXTOS_LOJAS.md) |
| Descrição completa | (usar texto do arquivo TEXTOS_LOJAS.md) |

**Seção: Elementos gráficos**

| Asset | Especificação |
|-------|---------------|
| Ícone | 512x512px PNG (32 bits, sem transparência) |
| Imagem em destaque | 1024x500px PNG ou JPG |
| Screenshots celular | 1080x1920px (mínimo 2) |

### 4.4 Classificação de Conteúdo

1. Vá em **Política** > **Classificação do conteúdo**
2. Preencha o questionário
3. Responda "Não" para conteúdo violento, sexual, etc.
4. Resultado esperado: **Livre**

### 4.5 Configurar Preço e Distribuição

1. Vá em **Monetização** > **Produtos no app**
2. Configure a assinatura anual
3. Selecione países de distribuição (Brasil)

### 4.6 Política de Privacidade

1. Vá em **Política** > **Conteúdo do app**
2. Cole a URL da sua política de privacidade
3. Exemplo: `https://ipoupei.com.br/privacidade`

### 4.7 Upload do App

1. Vá em **Produção** > **Criar nova versão**
2. Faça upload do arquivo `.aab`
3. Preencha as notas da versão
4. Envie para revisão

---

## PARTE 5: HOSPEDAGEM DOS DOCUMENTOS

### Opção 1: GitHub Pages (Grátis)

1. Crie repositório `ipoupei/ipoupei.github.io`
2. Adicione os arquivos HTML da política/termos
3. Acesse via: `https://ipoupei.github.io/privacidade`

### Opção 2: Site próprio

Hospedar em `ipoupei.com.br`:
- `/privacidade` - Política de Privacidade
- `/termos` - Termos de Uso
- `/suporte` - FAQ/Central de Ajuda

### Conversão MD para HTML

Você pode converter os arquivos .md para HTML usando:
- Pandoc: `pandoc POLITICA_DE_PRIVACIDADE.md -o privacidade.html`
- Online: https://markdowntohtml.com/

---

## PARTE 6: CHECKLIST FINAL

### Antes de Enviar para Revisão

- [ ] Application ID alterado (não pode ser com.example.*)
- [ ] Keystore criado e guardado em local seguro
- [ ] Nome do app configurado corretamente
- [ ] Ícone do app finalizado
- [ ] Screenshots de qualidade
- [ ] Feature graphic criado
- [ ] Política de privacidade hospedada e acessível
- [ ] Descrições preenchidas
- [ ] Classificação de conteúdo respondida
- [ ] Preço/assinatura configurada
- [ ] Países de distribuição selecionados

### Tempo de Revisão

- **Primeira revisão:** 3-7 dias úteis
- **Atualizações:** 1-3 dias úteis

---

## SUPORTE

Se precisar de ajuda durante o processo:

- **E-mail:** suporte@ipoupei.com.br
- **Documentação Google Play:** https://support.google.com/googleplay/android-developer

---

**© 2025 ASTRACORTEX TECNOLOGIA LTDA**
