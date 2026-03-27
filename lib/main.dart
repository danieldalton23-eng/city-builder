// ============================================================
// main.dart
// Application entry point.
//
// Architecture overview:
//   main()
//     └─ CityBuilderApp (MaterialApp)
//           └─ ChangeNotifierProvider<GameProvider>
//                 └─ SlotPickerScreen  (launch screen)
//                       └─ GameScreen (after slot selection)
//                             ├─ ResourceBar
//                             ├─ CityGrid
//                             ├─ BuildingSelector (Tier 1 + Tier 2 tabs)
//                             └─ UpgradePanel (when tile selected)
//
// New screens accessible from GameScreen AppBar menu:
//   • StatisticsScreen  — fl_chart resource history
//   • AchievementsScreen — milestone grid
//   • SlotPickerScreen  — switch between 3 save slots
//
// State management: provider package (ChangeNotifier pattern)
// Persistence:      shared_preferences (JSON, 3 slots)
// Design system:    lib/theme/app_theme.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'screens/slot_picker_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for the best grid experience on mobile.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const CityBuilderApp());
}

class CityBuilderApp extends StatelessWidget {
  const CityBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Provider is created here but init() is called only after
      // the player selects a save slot in SlotPickerScreen.
      create: (_) => GameProvider(),
      child: MaterialApp(
        title: 'CityBuilder',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SlotPickerScreen(),
      ),
    );
  }
}
