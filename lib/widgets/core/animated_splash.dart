import 'package:flutter/material.dart';

class AnimatedSplash extends StatefulWidget {
  final double size;
  const AnimatedSplash({super.key, this.size = 200});

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 6 seconds controller for the heartbeat and text cycle
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
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
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 1080,
          height: 1080,
          child: Stack(
            children: [
              // Heart group (Base + Question)
              Positioned(
                left: 46,
                top: 125,
                width: 988,
                height: 749,
                child: AnimatedHeart(
                  controller: _controller,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset('assets/images/splash_image_1.png'),
                      AnimatedQuestionMark(
                        controller: _controller,
                        child: Image.asset('assets/images/splash_image_2.png'),
                      ),
                    ],
                  ),
                ),
              ),

              // Letters
              AnimatedLetters(controller: _controller),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedHeart extends StatelessWidget {
  final AnimationController controller;
  final Widget child;

  const AnimatedHeart({super.key, required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    // Heartbeat ends around 1.35s in the 6s window
    final Animation<double> scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.035).chain(CurveTween(curve: Curves.easeInOut)), weight: 5.25),
      TweenSequenceItem(tween: Tween(begin: 1.035, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 5.25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.025).chain(CurveTween(curve: Curves.easeInOut)), weight: 6.0),
      TweenSequenceItem(tween: Tween(begin: 1.025, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 6.0),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 77.5),
    ]).animate(controller);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: child,
    );
  }
}

class BottomUpClipper extends CustomClipper<Rect> {
  final double factor;
  BottomUpClipper(this.factor);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, size.height * (1.0 - factor), size.width, size.height);
  }

  @override
  bool shouldReclip(BottomUpClipper oldClipper) => oldClipper.factor != factor;
}

class AnimatedQuestionMark extends StatelessWidget {
  final AnimationController controller;
  final Widget child;

  const AnimatedQuestionMark({super.key, required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    // Fill up: 0.5s to 3.0s
    // Stay full: 3.0s to 4.5s
    // Empty out: 4.5s to 5.5s (along with letters)
    // Empty: 5.5s to 6.0s

    const double fillStart = 0.5 / 6.0;
    const double fillEnd = 3.0 / 6.0;
    const double emptyStart = 4.5 / 6.0;
    const double emptyEnd = 5.5 / 6.0;

    final Animation<double> clipAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: fillStart), // 1.0 = fully clipped
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: fillEnd - fillStart),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: emptyStart - fillEnd),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: emptyEnd - emptyStart),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 1.0 - emptyEnd),
    ]).animate(controller);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return ClipRect(
          clipper: BottomUpClipper(1.0 - clipAnimation.value),
          child: child,
        );
      },
      child: child,
    );
  }
}

class AnimatedLetters extends StatelessWidget {
  final AnimationController controller;
  const AnimatedLetters({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final shadow = [
      Shadow(
        offset: const Offset(1.5, 1.5),
        blurRadius: 3.0,
        color: Colors.black.withValues(alpha: 0.6),
      ),
    ];

    final TextStyle letterStyle = TextStyle(
      fontSize: 85,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
      color: Colors.white,
      shadows: shadow,
    );

    final TextStyle plusStyle = TextStyle(
      fontSize: 85,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
      color: const Color(0xFFFFD700),
      shadows: shadow,
    );

    const String text = 'MEU QUIZ +';
    final List<Widget> letterWidgets = [];

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final isPlus = char == '+';
      final style = isPlus ? plusStyle : letterStyle;

      // Calculate relative times for stagger
      final double appearStart = 1.5 + (i * 0.08); // 0.08s delay per letter
      final double appearEnd = appearStart + 0.5;  // 0.5s duration to appear
      
      final double startRel = appearStart / 6.0;
      final double endRel = appearEnd / 6.0;
      const double disappearStartRel = 4.5 / 6.0; // Starts disappearing at 4.5s
      const double disappearEndRel = 5.5 / 6.0;   // Fully disappeared by 5.5s

      final Animation<double> opacityAnim = TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween(0.0), weight: startRel),
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: endRel - startRel),
        TweenSequenceItem(tween: ConstantTween(1.0), weight: disappearStartRel - endRel),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: disappearEndRel - disappearStartRel),
        TweenSequenceItem(tween: ConstantTween(0.0), weight: 1.0 - disappearEndRel),
      ]).animate(controller);

      final Animation<double> translateYAnim = TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween(30.0), weight: startRel),
        TweenSequenceItem(tween: Tween(begin: 30.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: endRel - startRel),
        TweenSequenceItem(tween: ConstantTween(0.0), weight: disappearStartRel - endRel),
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -30.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: disappearEndRel - disappearStartRel),
        TweenSequenceItem(tween: ConstantTween(-30.0), weight: 1.0 - disappearEndRel),
      ]).animate(controller);
      
      final Animation<double> scaleAnim = TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween(0.5), weight: startRel),
        TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: endRel - startRel),
        TweenSequenceItem(tween: ConstantTween(1.0), weight: disappearStartRel - endRel),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.5).chain(CurveTween(curve: Curves.easeIn)), weight: disappearEndRel - disappearStartRel),
        TweenSequenceItem(tween: ConstantTween(0.5), weight: 1.0 - disappearEndRel),
      ]).animate(controller);

      letterWidgets.add(
        AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Opacity(
              opacity: opacityAnim.value,
              child: Transform.translate(
                offset: Offset(0, translateYAnim.value),
                child: Transform.scale(
                  scale: scaleAnim.value,
                  child: Text(char, style: style),
                ),
              ),
            );
          },
        ),
      );
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: letterWidgets,
      ),
    );
  }
}
