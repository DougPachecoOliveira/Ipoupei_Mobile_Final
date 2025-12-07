import 'package:flutter/material.dart';
import 'shared/components/ipoupei_loading.dart';

class TestLoadingPage extends StatefulWidget {
  const TestLoadingPage({Key? key}) : super(key: key);

  @override
  _TestLoadingPageState createState() => _TestLoadingPageState();
}

class _TestLoadingPageState extends State<TestLoadingPage> {
  bool showOverlay = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teste IPoupei Loading'),
        backgroundColor: Color(0xFF17a2a2),
      ),
      body: IPoupeiLoadingOverlay(
        isLoading: showOverlay,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Loading simples
              Container(
                height: 250,
                child: Column(
                  children: [
                    Text('Loading Simples:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    IPoupeiLoading(size: 150),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Loading personalizado
              Container(
                height: 150,
                child: Column(
                  children: [
                    Text('Loading Personalizado:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    IPoupeiLoading(
                      size: 100,
                      loadingText: 'Sincronizando...',
                      showText: true,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Botão para testar overlay
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showOverlay = !showOverlay;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF17a2a2),
                ),
                child: Text(
                  showOverlay ? 'Esconder Overlay' : 'Mostrar Overlay',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}