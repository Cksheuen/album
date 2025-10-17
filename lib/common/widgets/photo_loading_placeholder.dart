import 'package:flutter/material.dart';

/// 照片加载占位符组件
/// 用于在图片加载过程中显示加载动画
class PhotoLoadingPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final String? loadingText;

  const PhotoLoadingPlaceholder({
    super.key,
    this.width,
    this.height,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.15),
            Colors.purple.withOpacity(0.15),
          ],
        ),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 脉动动画背景
          _PulsingBackground(),
          // 加载指示器
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 旋转加载图标
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.withOpacity(0.7),
                  ),
                ),
              ),
              if (loadingText != null) ...[
                const SizedBox(height: 8),
                Text(
                  loadingText!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          // 右上角图标
          Positioned(
            top: 8,
            right: 8,
            child: Icon(
              Icons.download_outlined,
              color: Colors.blue.withOpacity(0.4),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// 脉动动画背景
class _PulsingBackground extends StatefulWidget {
  @override
  _PulsingBackgroundState createState() => _PulsingBackgroundState();
}

class _PulsingBackgroundState extends State<_PulsingBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.white.withOpacity(_animation.value * 0.5),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 紧凑型加载占位符（用于网格列表）
class CompactPhotoLoadingPlaceholder extends StatelessWidget {
  final double? size;

  const CompactPhotoLoadingPlaceholder({
    super.key,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.blue.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}
