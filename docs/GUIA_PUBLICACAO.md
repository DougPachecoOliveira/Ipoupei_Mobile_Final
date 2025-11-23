# GUIA DE PUBLICAÇÃO - iPoupei

**Passo a passo completo para publicar o app nas lojas**

---

## SOBRE O iPOUPEI

**O iPoupei não é mais um app de controle de gastos.**

É uma **plataforma de reabilitação e educação financeira pessoal** — o pronto-socorro financeiro do brasileiro endividado.

Antes de publicar, tenha certeza de que tudo reflete essa identidade.

---

## CHECKLIST GERAL

### Documentação (Concluída)
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

### Hospedagem dos Documentos (Você faz)
- [ ] Política de Privacidade online
- [ ] Termos de Uso online
- [ ] FAQ online (opcional)

---

## PARTE 1: CONFIGURAÇÕES DO PROJETO

### 1.1 Alterar Application ID

**CRÍTICO:** O `applicationId` atual é `com.example.ipoupei_mobile`. Isso **não pode** ser publicado assim.

**Novo ID sugerido:** `br.com.ipoupei.app`

**Arquivo:** `android/app/build.gradle.kts`

```kotlin
defaultConfig {
    applicationId = "br.com.ipoupei.app"  // ALTERAR
    minSdk = 21
    targetSdk = 36
    ...
}
```

**Arquivo:** `android/app/build.gradle.kts` (namespace)

```kotlin
android {
    namespace = "br.com.ipoupei.app"  // ALTERAR
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

---

### 1.2 Atualizar Nome do App

**Arquivo:** `android/app/src/main/AndroidManifest.xml`

```xml
<application
    android:label="iPoupei"
    ...
```

---

### 1.3 Atualizar Supabase (Se necessário)

Se você mudou o scheme do deep link, atualize também no Supabase:
1. Vá no dashboard do Supabase
2. Authentication > URL Configuration
3. Atualize o Redirect URL para: `br.com.ipoupei.app://auth/callback`

---

## PARTE 2: CRIAR KEYSTORE (ASSINATURA)

### 2.1 Por que isso é importante

O keystore é a "identidade" do seu app. Sem ele, você não consegue:
- Publicar na Play Store
- Lançar atualizações
- Provar que você é o desenvolvedor

**GUARDE O KEYSTORE EM LUGAR SEGURO.** Se perder, não poderá mais atualizar o app.

### 2.2 Gerar Keystore

Execute no terminal:

```bash
keytool -genkey -v \
  -keystore ~/ipoupei-release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias ipoupei
```

Você vai precisar informar:
- Senha do keystore (ANOTE!)
- Senha da chave (pode ser a mesma)
- Seu nome
- Organização (ASTRACORTEX TECNOLOGIA LTDA)
- Cidade (Barueri)
- Estado (SP)
- País (BR)

### 2.3 Criar arquivo key.properties

Crie o arquivo `android/key.properties`:

```properties
storePassword=SUA_SENHA_AQUI
keyPassword=SUA_SENHA_AQUI
keyAlias=ipoupei
storeFile=/caminho/completo/para/ipoupei-release-key.jks
```

**IMPORTANTE:** Adicione este arquivo ao `.gitignore`!

```bash
echo "android/key.properties" >> .gitignore
echo "*.jks" >> .gitignore
```

### 2.4 Configurar build.gradle.kts

**Arquivo:** `android/app/build.gradle.kts`

Adicione no topo, antes de `plugins`:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Dentro do bloco `android`, adicione:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String?
        keyPassword = keystoreProperties["keyPassword"] as String?
        storeFile = keystoreProperties["storeFile"]?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String?
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

---

## PARTE 3: GERAR BUILD DE RELEASE

### 3.1 Limpar projeto

```bash
flutter clean
flutter pub get
```

### 3.2 App Bundle (Recomendado para Google Play)

```bash
flutter build appbundle --release
```

O arquivo será gerado em:
```
build/app/outputs/bundle/release/app-release.aab
```

### 3.3 APK (Para testes ou distribuição direta)

```bash
flutter build apk --release
```

O arquivo será gerado em:
```
build/app/outputs/flutter-apk/app-release.apk
```

### 3.4 Verificar o build

Antes de enviar, teste o APK/AAB em um dispositivo real:

```bash
flutter install --release
```

---

## PARTE 4: GOOGLE PLAY CONSOLE

### 4.1 Criar Conta de Desenvolvedor

1. Acesse: https://play.google.com/console
2. Faça login com conta Google (recomendo usar conta da empresa)
3. Pague a taxa única de **$25** (~R$125)
4. Preencha informações do desenvolvedor:
   - Nome: ASTRACORTEX TECNOLOGIA LTDA
   - E-mail: contato@ipoupei.com.br
   - Telefone: (seu telefone)
   - Site: https://ipoupei.com.br

### 4.2 Criar Novo App

1. Clique em **"Criar app"**
2. Preencha:
   - **Nome:** iPoupei
   - **Idioma padrão:** Português (Brasil)
   - **Tipo de app:** App
   - **Gratuito ou pago:** Pago (ou com assinatura in-app)
   - Aceite as declarações

### 4.3 Configurar Ficha da Loja

**Ficha principal da loja:**

| Campo | Onde encontrar |
|-------|----------------|
| Nome do app | iPoupei |
| Descrição curta | Ver `TEXTOS_LOJAS.md` |
| Descrição completa | Ver `TEXTOS_LOJAS.md` |

**Elementos gráficos:**

| Asset | Especificação |
|-------|---------------|
| Ícone | 512x512px PNG (sem transparência) |
| Imagem em destaque | 1024x500px PNG ou JPG |
| Screenshots celular | 1080x1920px (mínimo 2, máximo 8) |

### 4.4 Classificação de Conteúdo

1. Vá em **Política** > **Classificação do conteúdo**
2. Inicie o questionário
3. Responda honestamente (ver `TEXTOS_LOJAS.md` para referência)
4. **Resultado esperado:** Livre

### 4.5 Configurações de App

**Categoria:**
- Categoria: **Finanças**
- Tags: Controle financeiro, Orçamento, Dívidas

**Detalhes de contato:**
- E-mail: suporte@ipoupei.com.br
- Site: https://ipoupei.com.br

**Política de Privacidade:**
- URL: https://ipoupei.com.br/privacidade

### 4.6 Configurar Monetização (Assinatura)

1. Vá em **Monetização** > **Produtos** > **Assinaturas**
2. Crie a assinatura:
   - **ID do produto:** `ipoupei_annual_first_year`
   - **Nome:** iPoupei - Primeiro Ano
   - **Descrição:** App completo + Mentoria financeira personalizada
   - **Preço:** R$ 299,00
   - **Período:** Anual (não renovável automaticamente)

3. Crie segunda assinatura (renovação anual):
   - **ID do produto:** `ipoupei_annual_renewal`
   - **Nome:** iPoupei - Renovação Anual
   - **Descrição:** Acesso completo ao app
   - **Preço:** R$ 199,00
   - **Período:** Anual

4. Crie terceira assinatura (mensal):
   - **ID do produto:** `ipoupei_monthly`
   - **Nome:** iPoupei - Mensal
   - **Descrição:** Acesso completo ao app
   - **Preço:** R$ 19,90
   - **Período:** Mensal

### 4.7 Upload do App

1. Vá em **Produção** > **Criar nova versão**
2. Faça upload do arquivo `.aab`
3. Preencha as **Notas da versão** (ver `TEXTOS_LOJAS.md`)
4. Revise tudo
5. **Enviar para revisão**

### 4.8 Tempo de Revisão

| Tipo | Prazo estimado |
|------|----------------|
| Primeira submissão | 3-7 dias úteis |
| Atualizações | 1-3 dias úteis |
| Revisão manual (se solicitada) | Até 14 dias |

---

## PARTE 5: HOSPEDAGEM DOS DOCUMENTOS

### 5.1 O que precisa estar online

| Documento | URL sugerida |
|-----------|--------------|
| Política de Privacidade | https://ipoupei.com.br/privacidade |
| Termos de Uso | https://ipoupei.com.br/termos |
| FAQ (opcional) | https://ipoupei.com.br/ajuda |

### 5.2 Opção 1: GitHub Pages (Grátis)

1. Crie repositório `ipoupei/ipoupei.github.io`
2. Converta os arquivos .md para HTML
3. Faça commit e push
4. Acesse via: `https://ipoupei.github.io/privacidade`

**Para converter MD para HTML:**
```bash
# Instalar pandoc (se não tiver)
sudo apt install pandoc

# Converter
pandoc POLITICA_DE_PRIVACIDADE.md -o privacidade.html
pandoc TERMOS_DE_USO.md -o termos.html
pandoc FAQ_SUPORTE.md -o ajuda.html
```

### 5.3 Opção 2: Site Próprio

Se você já tem o domínio ipoupei.com.br:
1. Crie as páginas no seu servidor/CMS
2. Cole o conteúdo dos arquivos .md
3. Garanta que as URLs funcionem

### 5.4 Opção 3: Notion (Rápido)

1. Crie páginas no Notion com o conteúdo
2. Publique as páginas (Share > Publish to web)
3. Use as URLs do Notion temporariamente

---

## PARTE 6: CHECKLIST FINAL

### Antes de Enviar para Revisão

**Obrigatório:**
- [ ] Application ID alterado (não pode ser com.example.*)
- [ ] Keystore criado e guardado em LOCAL SEGURO
- [ ] Build de release testado em dispositivo real
- [ ] Nome do app correto (iPoupei)
- [ ] Ícone do app finalizado
- [ ] Pelo menos 2 screenshots de qualidade
- [ ] Política de privacidade hospedada e acessível
- [ ] Descrição curta preenchida
- [ ] Descrição longa preenchida
- [ ] Classificação de conteúdo respondida
- [ ] E-mail de suporte funcionando
- [ ] Categoria correta (Finanças)

**Recomendado:**
- [ ] Feature graphic criado
- [ ] 4-8 screenshots
- [ ] Termos de uso hospedados
- [ ] FAQ hospedado
- [ ] Teste em múltiplos dispositivos

### Erros Comuns

| Erro | Solução |
|------|---------|
| "App assinado com chave de debug" | Configure o keystore corretamente |
| "Application ID inválido" | Não use com.example.* |
| "Política de privacidade não acessível" | Verifique a URL, teste em navegador anônimo |
| "Screenshots muito pequenos" | Use 1080x1920px mínimo |
| "Descrição muito curta" | Mínimo ~300 caracteres na descrição longa |

---

## PARTE 7: PÓS-PUBLICAÇÃO

### 7.1 Após Aprovação

1. **Teste o app** baixando da loja
2. **Monitore avaliações** — responda rapidamente
3. **Acompanhe crashes** no Play Console
4. **Divulgue** nas redes sociais

### 7.2 Primeiras Atualizações

Para atualizar o app:
1. Incremente a versão em `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # Aumente o número
   ```
2. Gere novo build
3. Faça upload no Play Console
4. Preencha notas da versão
5. Envie para revisão

### 7.3 Respondendo Avaliações

Use os templates em `TEXTOS_LOJAS.md` para manter consistência no tom de voz.

---

## INFORMAÇÕES DE CONTATO

**ASTRACORTEX TECNOLOGIA LTDA**

- **CNPJ:** 61.442.503/0001-01
- **Endereço:** Alameda Rio Negro, 503 - Barueri/SP
- **E-mail Comercial:** contato@ipoupei.com.br
- **E-mail de Suporte:** suporte@ipoupei.com.br
- **Site:** https://ipoupei.com.br

---

## RECURSOS ÚTEIS

- [Documentação Flutter - Build Release](https://docs.flutter.dev/deployment/android)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Guia de Classificação de Conteúdo](https://support.google.com/googleplay/android-developer/answer/9859655)
- [Requisitos de Assets](https://support.google.com/googleplay/android-developer/answer/9866151)

---

**© 2025 ASTRACORTEX TECNOLOGIA LTDA**

*iPoupei — O pronto-socorro financeiro do brasileiro endividado.*
