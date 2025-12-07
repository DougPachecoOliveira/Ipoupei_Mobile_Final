import 'package:flutter/material.dart';

class IPoupeiLoading extends StatefulWidget {
  final double size;
  final bool showText;
  final String? loadingText;

  const IPoupeiLoading({
    Key? key,
    this.size = 200,
    this.showText = true,
    this.loadingText = 'Carregando...',
  }) : super(key: key);

  @override
  State<IPoupeiLoading> createState() => _IPoupeiLoadingState();
}

class _IPoupeiLoadingState extends State<IPoupeiLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [
                        0.0,
                        _animation.value - 0.3,
                        _animation.value,
                        _animation.value + 0.1,
                        1.0,
                      ].map((s) => s.clamp(0.0, 1.0)).toList(),
                      colors: const [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.white,
                        Colors.white,
                        Colors.white,
                      ],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/images/Ipoupei_logo.jpg',
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),
          if (widget.showText) ...[
            const SizedBox(height: 24),
            Text(
              widget.loadingText ?? 'Carregando...',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF17a2a2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class IPoupeiLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color backgroundColor;

  const IPoupeiLoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.backgroundColor = const Color(0x80000000),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor,
            child: const IPoupeiLoading(),
          ),
      ],
    );
  }
}