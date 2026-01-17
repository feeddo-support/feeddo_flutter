# Feeddo Flutter Example

This is a complete example application demonstrating how to integrate the [Feeddo Flutter SDK](../README.md).

It showcases:
- Required SDK initialization
- User identification and metadata
- Opening the support chat widget
- Opening the community board (feature requests & bug reports)
- Handling notifications

## Getting Started

1. **Clone the repository** and navigate to the example directory:

   ```bash
   cd feeddo_flutter/example
   ```

2. **Install dependencies**:

   ```bash
   flutter pub get
   ```

3. **Configure Firebase (Optional)**:
   This example uses Firebase for push notifications. If you want to test push notifications:
   - Create a Firebase project
   - Configure it for your platform (Android/iOS)
   - Add your `google-services.json` / `GoogleService-Info.plist`
   - Update `firebase_options.dart`

   *Note: You can run the app without Firebase configuration, but push notifications will not work.*

4. **Run the App**:

   ```bash
   flutter run
   ```

## Key Files

- `lib/main.dart`: Contains the complete implementation. Look for `_initFeeddo()` to see SDK initialization and `Feeddo.show(context)` to see how to trigger the widget.

## Usage in App

The example app provides buttons to:
- Open Support Chat: Launches the main AI support interface.
- Open Community Board: Shows the public features/bugs list.
- Update User: Demonstrates how to update user traits (email, segment) at runtime.
- Toggle Theme: Switches between Light and Dark mode to show Feeddo's theme adaptability.
