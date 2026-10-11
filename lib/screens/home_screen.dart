import 'package:flutter/material.dart';
import '../widgets/battery_page.dart';
import '../widgets/info_page.dart';
import '../widgets/light_page.dart';
import '../widgets/proximity_page.dart';

class _Destino {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;

  const _Destino({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _breakpoint = 600;

  static const List<_Destino> _destinos = [
    _Destino(
      label: 'Batería',
      icon: Icons.battery_std_outlined,
      selectedIcon: Icons.battery_full,
      page: BatteryPage(),
    ),
    _Destino(
      label: 'Luz',
      icon: Icons.light_mode_outlined,
      selectedIcon: Icons.light_mode,
      page: LightPage(),
    ),
    _Destino(
      label: 'Proximidad',
      icon: Icons.sensors_outlined,
      selectedIcon: Icons.sensors,
      page: ProximityPage(),
    ),
    _Destino(
      label: 'Info',
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
      page: InfoPage(),
    ),
  ];

  int _selectedIndex = 0;

  void _onSelect(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= _breakpoint;

        return Scaffold(
          appBar: AppBar(title: const Text('SensorLab Mobile')),
          body: SafeArea(
            child: Row(
              children: [
                if (isWide) ...[
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onSelect,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final d in _destinos)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                ],
                Expanded(child: _destinos[_selectedIndex].page),
              ],
            ),
          ),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onSelect,
                  destinations: [
                    for (final d in _destinos)
                      NavigationDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: d.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
