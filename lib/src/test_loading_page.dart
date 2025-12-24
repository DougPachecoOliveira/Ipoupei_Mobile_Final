import 'package:flutter/material.dart';

import 'shared/components/ipoupei_loading.dart';
import 'shared/components/loading/ipoupei_wave_loader.dart';
import 'shared/components/loading/ipoupei_svg_stroke_loader.dart';

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
        title: const Text('Tester • Loadings iPoupei'),
        backgroundColor: const Color(0xFF17a2a2),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCard(
                title: '🏆 Onda + seta (recomendado)',
                child: IPoupeiWaveLoader(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 260,
                ),
              ),
              _buildCard(
                title: 'SVG original desenhado (stroke)',
                child: const IPoupeiSvgStrokeLoader(
                  width: 320,
                  height: 240,
                  strokeWidth: 8,
                ),
              ),
              _buildCard(
                title: 'Logo crescendo + texto',
                child: const IPoupeiWaveLoader(
                  width: 280,
                  height: 220,
                  label: 'Carregando iPoupei...',
                ),
              ),
              _buildCard(
                title: 'Flutter CircularProgressIndicator',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        strokeWidth: 5,
                        color: Color(0xFF17a2a2),
                        backgroundColor: Color(0xFFE0F2F1),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text('Puro Flutter, sem customizações pesadas'),
                  ],
                ),
              ),
              _buildCard(
                title: 'Loader clássico (shader)',
                child: const IPoupeiLoading(
                  size: 140,
                  loadingText: 'Sincronizando...',
                  showText: true,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showOverlay = !showOverlay;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF17a2a2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    showOverlay ? 'Esconder Overlay' : 'Mostrar Overlay',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Overlay usa CircularProgressIndicator padrão',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
          if (showOverlay)
            Container(
              color: Colors.black.withOpacity(0.45),
              child: const Center(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    color: Colors.white,
                    backgroundColor: Color(0xFF17a2a2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Center(child: child),
          ],
        ),
      ),
    );
  }
}
