# 📱 iPoupei Mobile

Aplicativo Flutter do iPoupei com sincronização offline/online automática.


## 🚀 Como Rodar

```bash
# Instalar dependências
flutter pub get

# Rodar no dispositivo/emulador
flutter run

# Para build release
flutter build apk
```

## ✨ Funcionalidades

### ✅ Implementadas
- 🔐 **Auth completo** com Supabase (login/logout/cadastro)
- 💾 **SQLite local** espelho exato das tabelas do Supabase
- 🔄 **Sincronização automática** offline ↔ online
- 📱 **Interface responsiva** Material Design 3
- ⚡ **Dependências atualizadas** para versões mais recentes
- 🎨 **withValues()** para cores (Flutter 3.22+)
- 🌐 **Connectivity Plus 6.1.5+** com List<ConnectivityResult>

### 🔧 Recursos Técnicos
- **Offline-first:** App funciona 100% sem internet
- **Auto-sync:** Sincroniza automaticamente quando online
- **Real-time:** Escuta mudanças de conectividade
- **Enterprise patterns:** Singleton, Dependency Injection, Repository

## 📂 Estrutura

```
lib/src/
├── modules/              # Módulos por funcionalidade
│   ├── auth/            # Autenticação 
│   ├── dashboard/       # Tela principal
│   └── ...              # Outros módulos
├── database/            # SQLite local
├── sync/                # Sincronização
├── auth_integration.dart    # Integração de serviços
└── supabase_auth_service.dart  # Serviço de auth
```

## 🌐 Configuração Supabase

### Credenciais (já configuradas)
- **Project ID:** `ykifgrblmicoymavcqnu`
- **URL:** `https://ykifgrblmicoymavcqnu.supabase.co`
- **Anon Key:** Válida até 2033 ✅

### Tabelas Principais (Estrutura Idêntica ao Supabase)
- `perfil_usuario` - Dados do usuário (29 colunas)
- `contas` - Contas bancárias (19 colunas)
- `categorias` - Categorias de transações (12 colunas) 
- `subcategorias` - Subcategorias (8 colunas)
- `cartoes` - Cartões de crédito (15 colunas)
- `transacoes` - Transações financeiras (39 colunas)

## 🎨 UI/UX

- **Design System:** Material Design 3
- **Cores:** Tons de azul (#1976D2)
- **Componentes:** Reutilizáveis e consistentes
- **Responsivo:** Funciona em qualquer tamanho de tela

## 📱 Estados de Sync

- 🟢 **Sincronizado:** Dados em dia com o servidor
- 🔵 **Sincronizando:** Enviando/recebendo dados
- 🟠 **Offline:** Funcionando localmente
- 🔴 **Erro:** Problema na sincronização

## 🔧 Development

### Debug
```bash
# Logs detalhados no console
flutter run --verbose

# Análise de código
flutter analyze

# Testes
flutter test
```

### Build
```bash
# Android APK
flutter build apk --release

# iOS (requer macOS)
flutter build ios --release
```

---

**🎉 Pronto para usar! O app funciona offline e sincroniza automaticamente quando online.**
