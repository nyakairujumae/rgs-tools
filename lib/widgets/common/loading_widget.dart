import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Reusable loading widget with different styles
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;
  final bool showMessage;

  const LoadingWidget({
    super.key,
    this.message,
    this.size,
    this.color,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: CircularProgressIndicator(
              color: color ?? AppTheme.primaryColor,
              strokeWidth: 3,
            ),
          ),
          if (showMessage && message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading overlay widget
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  final Color? overlayColor;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: overlayColor ?? Colors.black.withValues(alpha: 0.3),
            child: LoadingWidget(
              message: loadingMessage,
              size: 50,
            ),
          ),
      ],
    );
  }
}

/// Skeleton loading widget with shimmer effect
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.baseColor ?? (isDark ? const Color(0xFF252525) : const Color(0xFFE6EAF1));
    final highlightColor = widget.highlightColor ?? (isDark ? const Color(0xFF323232) : const Color(0xFFD8DBE0));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        baseColor,
                        highlightColor,
                        baseColor,
                      ],
                      stops: [
                        0.0,
                        _animation.value.clamp(0.0, 1.0),
                        1.0,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// List skeleton loader
class ListSkeletonLoader extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ListSkeletonLoader({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SkeletonLoader(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.circular(25),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    SkeletonLoader(
                      width: 200,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    SkeletonLoader(
                      width: 100,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tool card skeleton loader - matches the tool card design
class ToolCardSkeleton extends StatelessWidget {
  const ToolCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Square image placeholder — matches AspectRatio(1.0) in real card
        AspectRatio(
          aspectRatio: 1.0,
          child: SkeletonLoader(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 6),
        // Tool name — 13px bold
        SkeletonLoader(
          width: double.infinity,
          height: 12,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 4),
        // Category — 10px
        SkeletonLoader(
          width: 80,
          height: 9,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 5),
        // Status pill
        SkeletonLoader(
          width: 56,
          height: 18,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }
}

/// Grid skeleton loader for tool cards
class ToolCardGridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  const ToolCardGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 10.0,
    this.mainAxisSpacing = 12.0,
    this.childAspectRatio = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const ToolCardSkeleton();
      },
    );
  }
}

/// Tool list (table) skeleton — mirrors _buildMobileList layout
class ToolListSkeleton extends StatelessWidget {
  final int itemCount;
  const ToolListSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF252525) : const Color(0xFFE6EAF1);
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFFAFAFA);
    final divColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0);
    final cardBg   = isDark ? const Color(0xFF141414) : Colors.white;

    // Same column widths as the real table
    const double colName     = 160;
    const double colCat      = 130;
    const double colBrand    = 110;
    const double colStatus   = 100;
    const double colCond     = 110;
    const double colAction   =  44;
    const double totalW = colName + colCat + colBrand + colStatus + colCond + colAction;

    Widget skel(double w, {double h = 11}) => SizedBox(
      width: w,
      child: SkeletonLoader(width: w, height: h, borderRadius: BorderRadius.circular(6)),
    );

    Widget cell(double w, Widget child) => SizedBox(
      width: w,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: child,
      ),
    );

    final header = Container(
      color: headerBg,
      child: Row(children: [
        cell(colName,   skel(70, h: 9)),
        cell(colCat,    skel(60, h: 9)),
        cell(colBrand,  skel(45, h: 9)),
        cell(colStatus, skel(45, h: 9)),
        cell(colCond,   skel(55, h: 9)),
        SizedBox(width: colAction),
      ]),
    );

    final rows = <Widget>[header];
    for (int i = 0; i < itemCount; i++) {
      rows.add(Divider(height: 1, thickness: 1, color: divColor));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Name col with thumbnail
          SizedBox(
            width: colName,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                SkeletonLoader(width: 40, height: 40, borderRadius: BorderRadius.circular(8)),
                const SizedBox(width: 8),
                Expanded(child: SkeletonLoader(width: double.infinity, height: 12, borderRadius: BorderRadius.circular(6))),
              ]),
            ),
          ),
          cell(colCat,    skel(80)),
          cell(colBrand,  skel(55)),
          cell(colStatus, skel(60, h: 20)),
          cell(colCond,   skel(60)),
          SizedBox(width: colAction),
        ],
      ));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalW,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        ),
      ),
    );
  }
}

/// Stat card skeleton loader
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Value skeleton
          Expanded(
            child: Center(
              child: SkeletonLoader(
                width: 80,
                height: 32,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Icon and title skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonLoader(
                width: 24,
                height: 24,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 6),
              SkeletonLoader(
                width: 60,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
