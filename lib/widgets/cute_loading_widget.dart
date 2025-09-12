import 'package:flutter/material.dart';

class CuteLoadingWidget extends StatefulWidget {
  final String? message;
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;

  const CuteLoadingWidget({
    super.key,
    this.message,
    this.size = 80.0,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<CuteLoadingWidget> createState() => _CuteLoadingWidgetState();
}

class _CuteLoadingWidgetState extends State<CuteLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _bounceController.repeat(reverse: true);
    _rotateController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? const Color(0xFF29BDCE);
    final secondaryColor = widget.secondaryColor ?? Colors.white;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cute character animation
        AnimatedBuilder(
          animation: Listenable.merge([_bounceAnimation, _rotateAnimation, _pulseAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Transform.translate(
                offset: Offset(0, -10 * _bounceAnimation.value),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryColor.withOpacity(0.3),
                        primaryColor.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer rotating ring
                      Transform.rotate(
                        angle: _rotateAnimation.value * 2 * 3.14159,
                        child: Container(
                          width: widget.size * 0.9,
                          height: widget.size * 0.9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      
                      // Inner rotating ring
                      Transform.rotate(
                        angle: -_rotateAnimation.value * 2 * 3.14159,
                        child: Container(
                          width: widget.size * 0.6,
                          height: widget.size * 0.6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      
                      // Cute face
                      Container(
                        width: widget.size * 0.4,
                        height: widget.size * 0.4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Eyes
                            Positioned(
                              top: widget.size * 0.12,
                              left: widget.size * 0.08,
                              child: Container(
                                width: widget.size * 0.06,
                                height: widget.size * 0.06,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: secondaryColor,
                                ),
                              ),
                            ),
                            Positioned(
                              top: widget.size * 0.12,
                              right: widget.size * 0.08,
                              child: Container(
                                width: widget.size * 0.06,
                                height: widget.size * 0.06,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: secondaryColor,
                                ),
                              ),
                            ),
                            
                            // Smile
                            Positioned(
                              bottom: widget.size * 0.12,
                              child: Container(
                                width: widget.size * 0.2,
                                height: widget.size * 0.08,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(widget.size * 0.04),
                                  border: Border.all(
                                    color: secondaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Loading text
        if (widget.message != null) ...[
          Text(
            widget.message!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        
        // Loading dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final delay = index * 0.2;
                final animationValue = (_pulseController.value + delay) % 1.0;
                final scale = 0.5 + (0.5 * (1 - (animationValue - 0.5).abs() * 2).clamp(0.0, 1.0));
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.6),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

// Full screen loading overlay
class CuteLoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isVisible;

  const CuteLoadingOverlay({
    super.key,
    this.message,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CuteLoadingWidget(
            message: message ?? 'Loading...',
            size: 100,
          ),
        ),
      ),
    );
  }
}

// Compact loading widget for cards
class CuteLoadingCard extends StatelessWidget {
  final String? message;
  final double height;

  const CuteLoadingCard({
    super.key,
    this.message,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: CuteLoadingWidget(
          message: message,
          size: 60,
        ),
      ),
    );
  }
}
