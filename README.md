# Frontend Android – Flutter Project

This repository contains the frontend of the project developed using Flutter.

## 📁 Project Structure

The source code is organized based on recommended Flutter practices, with a focus on separation of concerns:

```
lib/
├── pages/
│   ├── Game/           # Screens related to game functionalities
│   ├── InGame/         # Game board and in-game logic
│   └── Login/          # Login, password recovery, and authentication views
├── Presentation/       # General presentation components and welcome screen
├── services/           # Backend communication services (e.g., sockets)
├── utils/              # General reusable utilities
├── widgets/            # Reusable custom widgets
├── main.dart           # Main entry point of the application
```

## 🧾 Naming and Style Conventions

- **English** has been established as the standard language for all code, file names, and directory structures.
- Each subgroup has followed naming conventions tailored to the technologies used in their development.
- A global naming standard for events, variables, and functions has been followed to ensure code consistency.
- Specific conventions for each subgroup are documented in the `README.md` files of the corresponding subproject repositories.

## 📦 Dependencies

Project dependencies are defined in the `pubspec.yaml` file. To install them, run:

```bash
flutter pub get
```

## ▶️ Running the App

To run the app in debug mode:

```bash
flutter run
```

## 📱 Building the APK for Android Devices

To generate an installable `.apk` file for your Android device, follow these steps:

1. **Ensure dependencies are installed:**

   ```bash
   flutter pub get
   ```

2. **Build the APK in release mode:**

   ```bash
   flutter build apk --release
   ```

   This will generate the `.apk` file located at:

   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

3. **Transfer and install the APK on your Android device:**

   - Use a USB cable or a file-sharing app to move the `.apk` to your phone.
   - On the phone, open the file and allow installation from unknown sources if prompted.

> You can also use `flutter install` if your device is connected and developer mode is enabled.

## 🌐 Environment Configuration

To run the app, you need to provide environment-specific variables using a `.env` file.

Create a `.env` file at the root of the project based on the provided example:

```bash
cp .env.example .env
```

Then, edit the `.env` file and replace the placeholder values with the actual backend URL. For example:

```env
SERVER_BACKEND=https://your-real-backend-url.com/
```

> ⚠️ The actual backend URL is not included in this repository for security reasons. Please contact the project maintainer to obtain the correct value.

## 📄 License

This project is licensed under the terms specified in the [LICENSE](./LICENSE) file.
