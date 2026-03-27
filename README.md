# CityBuilder

A lightweight mobile city-building game prototype built with Flutter.

## Features

* **20x20 Grid Map**: Scrollable and zoomable interactive city grid.
* **Building Placement**: Tap to place Houses, Farms, and Power Plants.
* **Resource Engine**: Tracks Credits, Food, Power, and Population.
* **Periodic Generation**: Resources update every 5 seconds based on your buildings.
* **Persistence**: Automatically saves your city and resources to local storage.

## How to Run Locally

1. **Install Flutter**: Make sure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and added to your PATH.
2. **Clone/Download**: Navigate to this project directory (`city_builder`).
3. **Fetch Dependencies**: Run the following command in your terminal:
   ```bash
   flutter pub get
   ```
4. **Run the App**: Connect a device, start an emulator, or run in Chrome:
   ```bash
   flutter run
   ```

## Project Structure

The codebase is modular to make adding new features easy:

* `lib/models/`: Contains the core data structures.
  * `building_type.dart`: Defines all buildings, their costs, and resource yields. **Add new buildings here!**
  * `resources.dart`: Tracks the four resource types.
  * `tile.dart`: Represents a single cell on the grid.
  * `game_state.dart`: The top-level snapshot of the grid and resources.
* `lib/providers/`: State management.
  * `game_provider.dart`: The engine that runs the 5-second tick, handles placement logic, and triggers saves.
* `lib/services/`:
  * `save_service.dart`: Handles JSON serialisation to `shared_preferences`.
* `lib/widgets/`: Reusable UI components (`city_grid.dart`, `resource_bar.dart`, etc.).
* `lib/screens/`: The main `game_screen.dart` that assembles the UI.

## Adding New Buildings

To add a new building (e.g., a "Water Plant"):
1. Open `lib/models/building_type.dart`.
2. Add `waterPlant` to the `BuildingType` enum.
3. Add a new `BuildingConfig` entry to the `buildingConfigs` map with its emoji, cost, and resource deltas.
4. The UI and game engine will automatically pick it up!
