# 📧 Configuração de Email no Supabase - iPoupei Mobile

## ⚠️ ERRO ATUAL

```
❌ Erro ao enviar email de recuperação: AuthRetryableFetchException
message: {"code":"unexpected_failure","message":"Error sending recovery email"}
statusCode: 500
```

**Causa:** O Supabase não consegue enviar emails porque não há provedor SMTP configurado.

---

## 📋 SOLUÇÃO - Configurar SMTP no Supabase

### Opção 1: Usar SMTP Próprio (Gmail, Outlook, etc.)

#### 1️⃣ Acessar Supabase Dashboard

```
https://supabase.com/dashboard/project/ykifgrblmicoymavcqnu/settings/auth
```

#### 2️⃣ Configurar SMTP

**Caminho:** Project Settings → Auth → SMTP Settings

**Enable Custom SMTP:** ✅ Ativado

---

### 📧 Exemplo: Gmail SMTP

**SMTP Host:**
```
smtp.gmail.com
```

**SMTP Port:**
```
587
```

**SMTP User:**
```
seu-email@gmail.com
```

**SMTP Password:**
```
[Senha de aplicativo do Gmail - NÃO é sua senha normal]
```

**Sender Email:**
```
seu-email@gmail.com
```

**Sender Name:**
```
iPoupei
```

---

### 🔑 Como criar Senha de Aplicativo no Gmail

1. Acesse: https://myaccount.google.com/security
2. Ative a **Verificação em duas etapas** (se ainda não estiver ativa)
3. Vá em **Senhas de app**: https://myaccount.google.com/apppasswords
4. Crie uma nova senha de app:
   - Nome: `Supabase iPoupei`
   - Copie a senha gerada (16 caracteres sem espaços)
5. Use essa senha no campo **SMTP Password** do Supabase

---

### 📧 Exemplo: Outlook/Hotmail SMTP

**SMTP Host:**
```
smtp-mail.outlook.com
```

**SMTP Port:**
```
587
```

**SMTP User:**
```
seu-email@outlook.com
```

**SMTP Password:**
```
sua-senha-do-outlook
```

**Sender Email:**
```
seu-email@outlook.com
```

**Sender Name:**
```
iPoupei
```

---

### 📧 Exemplo: SendGrid (Recomendado para Produção)

**SMTP Host:**
```
smtp.sendgrid.net
```

**SMTP Port:**
```
587
```

**SMTP User:**
```
apikey
```

**SMTP Password:**
```
[Sua API Key do SendGrid]
```

**Sender Email:**
```
noreply@seudominio.com
```

**Sender Name:**
```
iPoupei
```

**Como criar conta SendGrid:**
1. Acesse: https://sendgrid.com/
2. Crie conta gratuita (100 emails/dia)
3. Verifique seu domínio ou email
4. Crie uma API Key em Settings → API Keys

---

## 📝 Configurar Templates de Email

Após configurar SMTP, você pode personalizar os templates de email.

**Caminho:** Project Settings → Auth → Email Templates

### Templates disponíveis:

1. **Confirm signup** - Email de confirmação de cadastro
2. **Invite user** - Convite de usuário
3. **Magic Link** - Link mágico para login
4. **Reset password** - Recuperação de senha ← **Este está falhando**

---

### Template de Reset Password (Exemplo)

**Subject:**
```
Recupere sua senha - iPoupei
```

**Body (HTML):**
```html
<h2>Recuperação de Senha - iPoupei</h2>

<p>Olá!</p>

<p>Você solicitou a recuperação de senha da sua conta iPoupei.</p>

<p>Clique no link abaixo para redefinir sua senha:</p>

<p>
  <a href="{{ .ConfirmationURL }}"
     style="background-color: #00897B; color: white; padding: 12px 24px;
            text-decoration: none; border-radius: 8px; display: inline-block;">
    Redefinir Senha
  </a>
</p>

<p>Ou copie e cole este link no navegador:</p>
<p>{{ .ConfirmationURL }}</p>

<p>Se você não solicitou esta recuperação, ignore este email.</p>

<p>Este link expira em 24 horas.</p>

<hr>
<p style="color: #666; font-size: 12px;">
  iPoupei - Controle Financeiro Inteligente<br>
  Este é um email automático, não responda.
</p>
```

---

## 🧪 Testar Envio de Email

Após configurar SMTP:

1. **Salve as configurações**
2. **Aguarde 1-2 minutos** (propagação)
3. **Teste no app:**
   - Vá para tela de Login
   - Clique em "Esqueceu a senha?"
   - Digite um email válido
   - Clique em "Enviar link"

4. **Verifique:**
   - ✅ Mensagem de sucesso no app
   - ✅ Email recebido na caixa de entrada
   - ✅ Link funciona e abre o app

---

## 🐛 Troubleshooting

### ❌ Erro 500 - "Error sending recovery email"

**Causas possíveis:**
- SMTP não configurado
- Credenciais SMTP incorretas
- Porta SMTP bloqueada (tente 465 ou 587)
- Email "Sender" não verificado

**Solução:**
- Verifique as credenciais SMTP
- Use senha de aplicativo (Gmail)
- Teste com outro provedor (SendGrid)

---

### ❌ Email não chega

**Causas possíveis:**
- Email na pasta de Spam
- Template de email inválido
- Rate limit (muitos emails enviados)

**Solução:**
- Verifique pasta de Spam
- Adicione noreply@ykifgrblmicoymavcqnu.supabase.co nos contatos
- Aguarde alguns minutos e tente novamente

---

### ❌ Link do email não funciona

**Causas possíveis:**
- Deep link não configurado corretamente
- Redirect URL inválido

**Solução:**
- Verifique se `com.ipoupei.app://auth/callback` está em Additional Redirect URLs
- Verifique AndroidManifest.xml com deep link correto

---

## ✅ Checklist de Configuração

**Supabase Dashboard:**
- [ ] SMTP configurado (Gmail, Outlook ou SendGrid)
- [ ] Sender Email verificado
- [ ] Template "Reset password" configurado
- [ ] Additional Redirect URLs contém `com.ipoupei.app://auth/callback`

**Código (JÁ FEITO):**
- [✅] `redirectTo` atualizado para `com.ipoupei.app://auth/callback`
- [✅] AndroidManifest.xml com deep link correto
- [✅] Função resetPassword() implementada

**Teste:**
- [ ] Email de recuperação enviado com sucesso
- [ ] Email recebido na caixa de entrada
- [ ] Link no email abre o app
- [ ] Possível redefinir senha

---

## 🎯 Recomendação

**Para Desenvolvimento:**
- Use Gmail SMTP com senha de aplicativo
- Rápido de configurar
- Gratuito

**Para Produção:**
- Use SendGrid ou outro provedor profissional
- Melhor entregabilidade
- Analytics de emails
- Sem risco de bloqueio

---

## 📚 Referências

- [Supabase SMTP Settings](https://supabase.com/docs/guides/auth/auth-smtp)
- [Gmail App Passwords](https://support.google.com/accounts/answer/185833)
- [SendGrid Documentation](https://docs.sendgrid.com/)
- [Supabase Email Templates](https://supabase.com/docs/guides/auth/auth-email-templates)

---

**💡 Importante:** Após configurar o SMTP, aguarde 1-2 minutos antes de testar para que as configurações sejam propagadas.
