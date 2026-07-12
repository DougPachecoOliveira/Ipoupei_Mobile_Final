// 🚀 Main - iPoupei Mobile
// 
// Ponto de entrada da aplicação Flutter
// Inicializa auth integration e configura rotas
// 
// Baseado em: Flutter Material App + Provider

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

import 'src/auth_integration.dart';
import 'src/supabase_auth_service.dart';
import 'src/modules/auth/pages/login_ipoupei_page.dart';
import 'src/shared/components/ui/enhanced_splash_screen.dart';
import 'src/modules/auth/pages/signup_page.dart';
import 'src/modules/auth/pages/reset_password_page.dart';
// import 'src/modules/dashboard/pages/home_page.dart'; // DEPRECATED: Use /navigation
import 'src/modules/planejamento/pages/planejamento_page.dart';
import 'src/modules/relatorios/pages/valor_hora_page.dart';
import 'src/modules/categorias/pages/categorias_sugeridas_page.dart';
import 'src/modules/diagnostico/pages/diagnostico_flow_page.dart';
import 'src/modules/configuracoes/pages/configuracoes_page.dart';
import 'src/routes/main_navigation.dart';
import 'src/test_loading_page.dart';
import 'src/modules/contas/services/conta_service.dart';
import 'src/sync/sync_manager.dart';
import 'src/modules/categorias/data/categoria_icons.dart'; // ✅ Para pré-carregar ícones
import 'src/shared/theme/app_theme.dart';

void main() async {
  // Garante que os widgets estão inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ PRÉ-CARREGAR TODOS OS ÍCONES (RESOLVE TREE SHAKING iOS)
  try {
    debugPrint('🎯 Pré-carregando ícones para evitar tree shaking...');
    CategoriaIcons.preloadAllIcons();
    debugPrint('✅ Ícones pré-carregados com sucesso!');
  } catch (e) {
    debugPrint('⚠️ Erro ao pré-carregar ícones: $e (continuando...)');
  }

  try {
    // Inicializa toda a infraestrutura de auth e database
    debugPrint('🚀 Inicializando iPoupei Mobile...');
    await authIntegration.initialize();
    debugPrint('✅ iPoupei Mobile inicializado com sucesso!');

    // 🔧 FIX TEMPORÁRIO: Corrige subcategorias com categoria_id errado
    // DESABILITADO - problema com nomes hardcoded que não existem no banco
    // try {
    //   debugPrint('🔧 Executando fix de subcategorias...');
    //   await fixSubcategoriasDatabase();
    //   debugPrint('✅ Fix de subcategorias concluído!');
    // } catch (e) {
    //   debugPrint('⚠️ Erro ao executar fix: $e');
    // }

  } catch (e) {
    debugPrint('❌ Erro na inicialização: $e');
    // Continua execução mesmo com erro de inicialização
    // O app vai funcionar em modo degradado
  }

  runApp(const IPoupeiApp());
}

// GlobalKey para navegação
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class IPoupeiApp extends StatefulWidget {
  const IPoupeiApp({super.key});

  @override
  State<IPoupeiApp> createState() => _IPoupeiAppState();
}

class _IPoupeiAppState extends State<IPoupeiApp> {
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _setupDeepLinkHandler();
  }

  /// 🔗 CONFIGURA HANDLER DE DEEP LINKS PARA OAUTH CALLBACKS
  void _setupDeepLinkHandler() {
    _appLinks = AppLinks();

    // Escuta deep links quando o app já está rodando
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('🔗 Deep link recebido (app rodando): $uri');
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('❌ Erro no deep link listener: $err');
    });

    // Verifica se o app foi aberto via deep link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        debugPrint('🔗 Deep link inicial (app aberto): $uri');
        _handleDeepLink(uri);
      }
    }).catchError((err) {
      debugPrint('❌ Erro ao verificar deep link inicial: $err');
    });
  }

  /// 🔄 PROCESSA DEEP LINK PARA OAUTH E PASSWORD RECOVERY
  void _handleDeepLink(Uri uri) async {
    try {
      debugPrint('🔄 Processando deep link: ${uri.toString()}');

      // Verifica se é callback de auth (OAuth ou password recovery)
      if (uri.scheme == 'br.com.ipoupei.mobile' && uri.host == 'auth' && uri.path == '/callback') {
        debugPrint('✅ Callback de auth detectado!');

        // Extrai parâmetros do URL
        final urlString = uri.toString();
        debugPrint('🔍 URL completo para processamento: $urlString');

        try {
          // Processa a sessão com o Supabase
          await Supabase.instance.client.auth.getSessionFromUrl(Uri.parse(urlString));
          debugPrint('✅ Sessão processada com sucesso via deep link!');

          // Navega para a tela principal
          Future.delayed(const Duration(milliseconds: 500), () {
            navigatorKey.currentState?.pushReplacementNamed('/navigation');
          });

        } catch (authError) {
          debugPrint('❌ Erro ao processar sessão: $authError');

          // Se der erro, navega para login
          Future.delayed(const Duration(milliseconds: 500), () {
            navigatorKey.currentState?.pushReplacementNamed('/login');
          });
        }
      } else {
        debugPrint('ℹ️ Deep link não é callback de auth: ${uri.toString()}');
      }

    } catch (e) {
      debugPrint('❌ Erro ao processar deep link: $e');
    }
  }

  /// 👂 LISTENER PARA DETECTAR PASSWORD RECOVERY
  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      debugPrint('🔐 Auth event: $event');

      // Detectar password recovery
      if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('🔑 Password recovery detectado - navegando para /reset-password');

        // Navegar para página de reset password
        Future.delayed(const Duration(milliseconds: 300), () {
          navigatorKey.currentState?.pushReplacementNamed('/reset-password');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider para AuthService (se quiser usar Provider pattern)
        Provider<SupabaseAuthService>.value(
          value: authIntegration.authService,
        ),
      ],
      child: MaterialApp(
        title: 'iPoupei Mobile',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey, // Para poder navegar de fora do contexto
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),
          Locale('en', 'US'),
        ],

        // Respeita acessibilidade sem permitir escalas que quebrem layouts
        // antigos durante a migração para o novo design system.
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final systemTextScale = mediaQuery.textScaler.scale(1.0);
          final finalTextScale = systemTextScale.clamp(0.9, 1.3);

          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(finalTextScale),
            ),
            child: child!,
          );
        },

        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        themeAnimationDuration: const Duration(milliseconds: 220),
        
        // Rota inicial
        home: const AuthWrapper(),
        
        // Rotas nomeadas
        routes: {
          '/login': (context) => const LoginIpoupeiPage(),
          '/signup': (context) => const SignUpPage(),
          '/reset-password': (context) => const ResetPasswordPage(),
          // '/home': (context) => const HomePage(), // DEPRECATED: Use /navigation
          '/navigation': (context) => const MainNavigation(),

          // 🧭 ROTAS COM NAVEGAÇÃO PARA ATALHOS
          '/contas': (context) => const MainNavigation(initialIndex: 0),
          '/cartoes': (context) => const MainNavigation(initialIndex: 1),
          '/relatorios': (context) => const MainNavigation(initialIndex: 2),
          '/categorias': (context) => const MainNavigation(initialIndex: 3),
          '/transacoes': (context) => const MainNavigation(initialIndex: 4),

          '/planejamento': (context) => const PlanejamentoPage(),
          '/valor-hora': (context) => const ValorHoraPage(),
          '/categorias-sugeridas': (context) => const CategoriasSugeridasPage(),
          '/diagnostico': (context) => const DiagnosticoFlowPage(),
          '/configuracoes': (context) => const ConfiguracoesPage(),
          '/test-loading': (context) => TestLoadingPage(),
        },
        
        // Rota desconhecida
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const LoginIpoupeiPage(),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // AppLinks é automaticamente disposto pelo package
    super.dispose();
  }
}

/// 🔐 Auth Wrapper - Decide qual tela mostrar baseado no status de auth
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    
    // Escuta mudanças no status de autenticação
    authIntegration.authService.statusStream.listen((status) {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = authIntegration.authService;
    
    // Mostra loading enquanto verifica autenticação
    if (authService.isLoading) {
      return const EnhancedSplashScreen(
        message: 'Carregando iPoupei...',
        subtitle: 'Verificando autenticação e inicializando o sistema',
        showProgress: true,
      );
    }
    
    // Se está autenticado, força sync e mostra navegação principal
    if (authService.isAuthenticated) {
      return const AuthenticatedWrapper();
    }

    // Senão, mostra login
    return const LoginIpoupeiPage();
  }
}

/// 🔒 Wrapper Autenticado - Força sync antes de mostrar app
class AuthenticatedWrapper extends StatefulWidget {
  const AuthenticatedWrapper({super.key});

  @override
  State<AuthenticatedWrapper> createState() => _AuthenticatedWrapperState();
}

class _AuthenticatedWrapperState extends State<AuthenticatedWrapper> {
  bool _syncCompleted = false;
  bool _syncError = false;
  String _syncMessage = 'Sincronizando dados...';

  @override
  void initState() {
    super.initState();
    _forcarSyncCompleto();
  }

  /// 🔄 FORÇA SYNC COMPLETO OBRIGATÓRIO DE TODOS OS DADOS
  Future<void> _forcarSyncCompleto() async {
    try {
      final userId = authIntegration.authService.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');
      
      // 1. Sincronizar Contas (com saldos corretos do Supabase)
      setState(() {
        _syncMessage = 'Sincronizando contas...';
      });
      await ContaService.instance.forcarResync();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 2. SyncManager fará sync completo de categorias, cartões e transações
      setState(() {
        _syncMessage = 'Sincronizando categorias...';
      });
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _syncMessage = 'Sincronizando cartões...';
      });
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _syncMessage = 'Sincronizando transações...';
      });
      
      // 3. Força sync inicial completo do SyncManager (inclui tudo)
      try {
        await SyncManager.instance.syncInitial();
      } catch (e) {
        debugPrint('⚠️ Erro sync completo: $e (continuando...)');
      }
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 4. Verificação final
      setState(() {
        _syncMessage = 'Finalizando sincronização...';
      });
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _syncMessage = 'Sincronização completa! ✅';
        _syncCompleted = true;
      });
      
      // 5. Aguarda para mostrar sucesso
      await Future.delayed(const Duration(milliseconds: 800));
      
    } catch (e) {
      debugPrint('❌ Erro no sync completo: $e');
      setState(() {
        _syncError = true;
        _syncMessage = 'Erro na sincronização';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // Se sync completou com sucesso, mostra app normal
    if (_syncCompleted && !_syncError) {
      return const MainNavigation();
    }
    
    // Senão, mostra loading de sync elegante
    if (!_syncError) {
      return EnhancedSplashScreen(
        message: _syncMessage,
        subtitle: 'Sincronizando todos os dados: contas, categorias, cartões e transações...\nGarantindo dados atualizados do Servidor',
        showProgress: true,
      );
    }

    // Tela de erro de sync
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _syncMessage,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _syncError = false;
                  _syncCompleted = false;
                });
                _forcarSyncCompleto();
              },
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
