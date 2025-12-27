import 'package:flutter/material.dart';
import '../../theme/feeddo_theme.dart';

class TypingIndicator extends StatefulWidget {
  final Color? color;
  final double size;
  final FeeddoTheme? theme;

  const TypingIndicator({
    Key? key,
    this.color,
    this.size = 6.0,
    this.theme,
  }) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _animations = _controllers
        .map((controller) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: controller, curve: Curves.easeInOut),
            ))
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.theme ?? FeeddoTheme.light();
    final indicatorColor = widget.color ?? currentTheme.colors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: widget.size,
              height: widget.size,
              transform: Matrix4.translationValues(
                0,
                -4 * _animations[index].value,
                0,
              ),
              decoration: BoxDecoration(
                color: indicatorColor
                    .withOpacity(0.4 + (0.6 * _animations[index].value)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
