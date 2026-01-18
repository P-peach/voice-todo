import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// 麦克风按钮组件（语音输入）
class MicrophoneButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onPressed;
  final double size;

  const MicrophoneButton({
    super.key,
    required this.isListening,
    required this.onPressed,
    this.size = 72,
  });

  @override
  State<MicrophoneButton> createState() => _MicrophoneButtonState();
}

class _MicrophoneButtonState extends State<MicrophoneButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(MicrophoneButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // 脉冲波纹效果
              if (widget.isListening)
                Container(
                  width: widget.size * _pulseAnimation.value * 1.4,
                  height: widget.size * _pulseAnimation.value * 1.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                ),
              if (widget.isListening)
                Container(
                  width: widget.size * _scaleAnimation.value * 1.2,
                  height: widget.size * _scaleAnimation.value * 1.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
              // 主按钮
              Transform.scale(
                scale: widget.isListening ? _scaleAnimation.value : 1.0,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.isListening
                          ? [
                              AppColors.primary,
                              AppColors.tertiary,
                            ]
                          : [
                              theme.colorScheme.primary,
                              theme.colorScheme.primaryContainer,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: widget.isListening ? 20 : 12,
                        spreadRadius: widget.isListening ? 5 : 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isListening ? Icons.stop : Icons.mic,
                    size: widget.size * 0.5,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
