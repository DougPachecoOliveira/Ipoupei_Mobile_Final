// lib/src/modules/diagnostico/widgets/youtube_player_widget.dart

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/diagnostico_etapa.dart';

/// Widget para reproduzir vídeos do YouTube no diagnóstico
/// RESPONSABILIDADES: Exibir vídeos explicativos + controles de reprodução
class YoutubePlayerWidget extends StatefulWidget {
  final VideoConfig video;
  final bool autoPlay;

  const YoutubePlayerWidget({
    super.key,
    required this.video,
    this.autoPlay = false,
  });

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  YoutubePlayerController? _controller;
  bool _isPlayerReady = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    try {
      _controller = YoutubePlayerController(
        initialVideoId: widget.video.id,
        flags: YoutubePlayerFlags(
          autoPlay: widget.autoPlay,
          mute: false,
          loop: false,
          enableCaption: false,
          controlsVisibleAtStart: true,
          showLiveFullscreenButton: false,
        ),
      );

      _controller!.addListener(() {
        try {
          if (_controller!.value.isReady && !_isPlayerReady && mounted) {
            setState(() {
              _isPlayerReady = true;
            });
          }
        } catch (e) {
          debugPrint('⚠️ [YOUTUBE] Erro no listener: $e');
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        }
      });
    } catch (e) {
      debugPrint('❌ [YOUTUBE] Erro ao inicializar player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    try {
      _controller?.dispose();
    } catch (e) {
      debugPrint('⚠️ [YOUTUBE] Erro ao fazer dispose: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se há erro, mostrar fallback
    if (_hasError || _controller == null) {
      return _buildErrorFallback();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Player do YouTube
            YoutubePlayer(
              controller: _controller!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: const Color(0xFFef4444),
              bottomActions: [
                CurrentPosition(),
                const SizedBox(width: 10),
                ProgressBar(
                  isExpanded: true,
                  colors: ProgressBarColors(
                    playedColor: const Color(0xFFef4444),
                    handleColor: const Color(0xFFef4444),
                  ),
                ),
                const SizedBox(width: 10),
                RemainingDuration(),
                const SizedBox(width: 10),
                PlaybackSpeedButton(),
                const SizedBox(width: 5),
                FullScreenButton(),
              ],
              topActions: [
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.video.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  onPressed: _abrirNoYouTube,
                  tooltip: 'Abrir no YouTube',
                ),
              ],
            ),

            // Informações adicionais
            if (widget.video.subtitle != null || widget.video.duracaoEstimada != null)
              _buildVideoInfo(),
          ],
        ),
      ),
    );
  }

  /// Fallback quando há erro no player
  Widget _buildErrorFallback() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: _abrirNoYouTube,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              widget.video.titulo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Toque para assistir no YouTube',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Informações adicionais do vídeo
  Widget _buildVideoInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.video.subtitle != null) ...[
            Text(
              widget.video.subtitle!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6b7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              // Duração estimada
              if (widget.video.duracaoEstimada != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFef4444).withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFFef4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatarDuracao(widget.video.duracaoEstimada!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFef4444),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Tag "Vídeo explicativo"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3b82f6).withAlpha(26),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      size: 14,
                      color: Color(0xFF3b82f6),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Vídeo explicativo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF3b82f6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  /// Abre vídeo no YouTube (aplicativo ou web)
  Future<void> _abrirNoYouTube() async {
    try {
      // URL do YouTube (não embed)
      final youtubeUrl = 'https://www.youtube.com/watch?v=${widget.video.id}';
      final uri = Uri.parse(youtubeUrl);

      // Tentar abrir no app do YouTube primeiro, depois no navegador
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Tenta abrir no app do YouTube
        );
      } else {
        // Fallback para navegador web
        await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      }
    } catch (e) {
      debugPrint('❌ [YOUTUBE] Erro ao abrir vídeo: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Não foi possível abrir o vídeo. Verifique sua conexão.'),
            backgroundColor: const Color(0xFFef4444),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  /// Formata duração em minutos:segundos
  String _formatarDuracao(Duration duracao) {
    final minutos = duracao.inMinutes;
    final segundos = duracao.inSeconds % 60;
    return '$minutos:${segundos.toString().padLeft(2, '0')}';
  }
}


/// Widget simples para quando não há vídeo configurado
class YoutubePlayerPlaceholder extends StatelessWidget {
  final String titulo;
  final String? subtitulo;

  const YoutubePlayerPlaceholder({
    super.key,
    required this.titulo,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFf3f4f6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFe5e7eb),
            width: 1,
          ),
        ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6b7280).withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.videocam_off_outlined,
              size: 32,
              color: const Color(0xFF6b7280).withAlpha(156),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            titulo,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6b7280).withAlpha(208),
            ),
            textAlign: TextAlign.center,
          ),

          if (subtitulo != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitulo!,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF6b7280).withAlpha(156),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      ),
    );
  }
}