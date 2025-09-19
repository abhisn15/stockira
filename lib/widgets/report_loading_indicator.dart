import 'package:flutter/material.dart';

class ReportLoadingIndicator extends StatefulWidget {
  final String message;
  final bool isVisible;
  final VoidCallback? onCancel;
  final Color? color;

  const ReportLoadingIndicator({
    super.key,
    required this.message,
    this.isVisible = true,
    this.onCancel,
    this.color,
  });

  @override
  State<ReportLoadingIndicator> createState() => _ReportLoadingIndicatorState();
}

class _ReportLoadingIndicatorState extends State<ReportLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    if (widget.isVisible) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(ReportLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _rotationController.stop();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated loading icon
          AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 2 * 3.14159,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: (widget.color ?? Colors.blue).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.assignment_turned_in,
                      size: 30,
                      color: widget.color ?? Colors.blue,
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Loading message
          Text(
            widget.message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Progress indicator
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.color ?? Colors.blue,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Cancel button
          if (widget.onCancel != null)
            TextButton(
              onPressed: widget.onCancel,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ReportSubmissionOverlay extends StatelessWidget {
  final String message;
  final bool isVisible;
  final VoidCallback? onCancel;
  final Color? color;

  const ReportSubmissionOverlay({
    super.key,
    required this.message,
    this.isVisible = true,
    this.onCancel,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: ReportLoadingIndicator(
          message: message,
          isVisible: isVisible,
          onCancel: onCancel,
          color: color,
        ),
      ),
    );
  }
}

class ReportStatusIndicator extends StatelessWidget {
  final ReportStatus status;
  final String message;
  final VoidCallback? onRetry;

  const ReportStatusIndicator({
    super.key,
    required this.status,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String title;

    switch (status) {
      case ReportStatus.loading:
        color = Colors.blue;
        icon = Icons.hourglass_empty;
        title = 'Processing...';
        break;
      case ReportStatus.success:
        color = Colors.green;
        icon = Icons.check_circle;
        title = 'Success';
        break;
      case ReportStatus.error:
        color = Colors.red;
        icon = Icons.error;
        title = 'Error';
        break;
      case ReportStatus.pending:
        color = Colors.orange;
        icon = Icons.pending;
        title = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (status == ReportStatus.error && onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum ReportStatus {
  loading,
  success,
  error,
  pending,
}
