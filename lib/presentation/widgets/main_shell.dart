import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../injection/service_locator.dart';
import '../../presentation/blocs/blocs.dart';
import '../../presentation/widgets/shared_widgets.dart';
import '../../presentation/pages/pages.dart';

/// Exposes a static method so any descendant can switch the bottom tab
/// without needing to push a new route.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Call from any widget inside MainShell to switch tabs.
  /// Tab indices: 0=Home, 1=Trips, 2=Map, 3=Messages, 4=Profile
  static void switchTab(BuildContext context, int index) {
    context.findAncestorStateOfType<_MainShellState>()?.switchTab(index);
    if (index == 2) {
      context.read<MapBloc>().add(const MapInitialized());
    }
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void switchTab(int index) => setState(() => _currentIndex = index);

  final _pages = const [
    HomePage(),
    MyTripsPage(),
    MapPage(),
    MessagesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<HomeBloc>()),
        BlocProvider(create: (_) => sl<TripsBloc>()),
        BlocProvider(create: (_) => sl<MapBloc>()),
        BlocProvider(create: (_) => sl<MessagesBloc>()),
        BlocProvider(create: (_) => sl<NotificationsBloc>()),
        BlocProvider(create: (_) => sl<ProfileBloc>()),
      ],
      child: Builder(
        builder: (blocContext) => Scaffold(
          body: IndexedStack(index: _currentIndex, children: _pages),
          bottomNavigationBar: RideLeafBottomNav(
            currentIndex: _currentIndex,
            onTap: (index) {
              switchTab(index);
              if (index == 2) {
                blocContext.read<MapBloc>().add(const MapInitialized());
              }
            },
          ),
        ),
      ),
    );
  }
}
