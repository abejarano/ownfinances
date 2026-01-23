import "package:flutter/material.dart";

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;
  final Widget? drawer;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: drawer,
      body: SafeArea(child: body),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: items,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
