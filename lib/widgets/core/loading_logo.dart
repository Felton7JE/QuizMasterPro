import 'package:flutter/material.dart';

class _BottomUpClipper extends CustomClipper<Rect> {
  final double factor;
  _BottomUpClipper(this.factor);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, size.height * (1.0 - factor), size.width, size.height);
  }

  @override
  bool shouldReclip(_BottomUpClipper oldClipper) => oldClipper.factor != factor;
}

class LoadingLogo extends StatefulWidget {
  final double size;
  
  /// A reusable loading animation featuring the app logo and an animated question mark
  const LoadingLogo({super.key, this.size = 150});

  @override
  State<LoadingLogo> createState() => _LoadingLogoState();
}

class _LoadingLogoState extends State<LoadingLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _clipAnimation;

  @override
  void initState() {
    super.initState();
    // 2 seconds for a complete fill and empty cycle
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // repeats indefinitely

    // Sequence:
    // 0% to 40%: Fill up (0.0 to 1.0)
    // 40% to 60%: Stay full (1.0)
    // 60% to 100%: Empty out (1.0 to 0.0)
    _clipAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      // Maintain the aspect ratio of the original logo (988x749)
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 988,
          height: 749,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/splash_image_1.png'),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return ClipRect(
                    clipper: _BottomUpClipper(_clipAnimation.value),
                    child: child,
                  );
                },
                child: Image.asset('assets/images/splash_image_2.png'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
