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
//                             ├─ TickIndicator
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
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'screens/slot_picker_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for the best grid experience.
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
      // Create provider but do NOT call init() here —
      // init() is called after the player picks a slot.
      create: (context) => GameProvider(),
      child: MaterialApp(
        title: 'CityBuilder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1B1B2F),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF64B5F6),
            secondary: Color(0xFFFFD700),
          ),
        ),
        // Start at the slot picker so the player always chooses
        // which city to load or create.
        home: const SlotPickerScreen(),
      ),
    );
  }
}
