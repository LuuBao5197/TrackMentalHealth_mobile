import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget tabletLayout;

  const ResponsiveLayout({
    Key? key,
    required this.mobileLayout,
    required this.tabletLayout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxWidth < 600) {
          return mobileLayout;
        } else {
          return tabletLayout;
        }
      },
    );
  }
}
