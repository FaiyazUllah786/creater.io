import "package:creatorio/common/theme/colors.dart";
import "package:creatorio/common/theme/theme_provider.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "package:shimmer/shimmer.dart";

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    return Shimmer.fromColors(
      baseColor: isDark ? blackColor : Colors.grey[300]!,
      highlightColor: isDark ? blackColorOpacity25 : Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
