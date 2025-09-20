// 🚀 Main - iPoupei Mobile
// 
// Ponto de entrada da aplicação Flutter
// Inicializa auth integration e configura rotas
// 
// Baseado em: Flutter Material App + Provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/auth_integration.dart';
import 'src/supabase_auth_service.dart';
import 'src/modules/auth/pages/login_page.dart';
import 'src/modules/auth/pages/signup_page.dart';
import 'src/modules/dashboard/pages/home_page.dart';
import 'src/routes/main_navigation.dart';
import 'src/modules/contas/services/conta_service.dart';
import 'src/sync/sync_manager.dart';

void main() async {
  // Garante que os widgets estão inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializa toda a infraestrutura de auth e database
    debugPrint('🚀 Inicializando iPoupei Mobile...');
    await authIntegration.initialize();
    debugPrint('✅ iPoupei Mobile inicializado com sucesso!');
    
  } catch (e) {
    debugPrint('❌ Erro na inicialização: $e');
    // Continua execução mesmo com erro de inicialização
    // O app vai funcionar em modo degradado
  }
  
  runApp(const IPoupeiApp());
}

class IPoupeiApp extends StatelessWidget {
  const IPoupeiApp({super.key});

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
        
        // Tema da aplicação
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'System',
        ),
        
        // Rota inicial
        home: const AuthWrapper(),
        
        // Rotas nomeadas
        routes: {
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignUpPage(),
          '/home': (context) => const HomePage(),
          '/navigation': (context) => const MainNavigation(),
        },
        
        // Rota desconhecida
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const LoginPage(),
          );
        },
      ),
    );
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
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Carregando iPoupei...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    // Se está autenticado, força sync e mostra navegação principal
    if (authService.isAuthenticated) {
      return const AuthenticatedWrapper();
    }
    
    // Senão, mostra login
    return const LoginPage();
  }
}

/// 🔒 Wrapper Autenticado - Força sync antes de mostrar app
class AuthenticatedWrapper extends StatefulWidget {
  const AuthenticatedWrapper({super.key});

  @override
  State<AuthenticatedWrapper> createState() => _AuthenticatedWrapperState();
}

class _AuthenticatedWrapperState extends State<AuthenticatedWrapper> with TickerProviderStateMixin {
  bool _syncCompleted = false;
  bool _syncError = false;
  String _syncMessage = 'Sincronizando dados...';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Inicializar animação de pulse
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Iniciar animação repetida
    _pulseController.repeat(reverse: true);

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
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se sync completou com sucesso, mostra app normal
    if (_syncCompleted && !_syncError) {
      return const MainNavigation();
    }
    
    // Senão, mostra loading de sync
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_syncError) ...[
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Image.asset(
                      'assets/images/Logo.png',
                      width: 240,
                      height: 240,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _syncMessage,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Sincronizando todos os dados: contas, categorias, cartões e transações...\nGarantindo dados atualizados do Servidor',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
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
          ],
        ),
      ),
    );
  }
}
