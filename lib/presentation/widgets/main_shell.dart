import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../injection/service_locator.dart';
import '../../presentation/blocs/home_bloc.dart';
import '../../presentation/blocs/map_bloc.dart';
import '../../presentation/blocs/messages_bloc.dart';
import '../../presentation/blocs/profile_bloc.dart';
import '../../presentation/blocs/trips_bloc.dart';
import '../../presentation/widgets/shared_widgets.dart';
import '../../presentation/pages/passenger/home_page.dart';
import '../../presentation/pages/passenger/map_page.dart';
import '../../presentation/pages/passenger/messages_page.dart';
import '../../presentation/pages/profile_page.dart';
import '../../presentation/pages/passenger/my_trips_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<HomeBloc>()),
        BlocProvider(create: (_) => sl<TripsBloc>()),
        BlocProvider(create: (_) => sl<MapBloc>()),
        BlocProvider(create: (_) => sl<MessagesBloc>()),
        BlocProvider(create: (_) => sl<ProfileBloc>()),
      ],
      child: Builder(
        builder: (context) {
          final pages = const [
            HomePage(),
            MyTripsPage(),
            MapPage(),
            MessagesPage(),
            ProfilePage(),
          ];

          return Scaffold(
            body: IndexedStack(index: _currentIndex, children: pages),
            bottomNavigationBar: RideLeafBottomNav(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
          );
        },
      ),
    );
  }
}
