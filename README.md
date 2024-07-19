# QR App

QR App is a Flutter application designed for QR code generation and management. This application provides users with the ability to create, store, and manage QR codes efficiently.

## Features

- **QR Code Generation**: Create QR codes for various types of data.
- **Recent QR Codes**: View and manage recently generated QR codes.
- **Settings**: Customize the app's settings to suit your preferences.
- **Image Saving**: Save QR codes as images with customizable text.

## Getting Started

This section will help you get started with setting up and running the QR App on your local machine.

### Prerequisites

- Flutter SDK: [Install Flutter](https://flutter.dev/docs/get-started/install)
- Dart SDK: Comes bundled with Flutter
- A code editor (VS Code, Android Studio, etc.)

### Installation

1. **Clone the repository**:
    ```bash
    git clone https://github.com/your-username/qr_app.git
    cd qr_app
    ```

2. **Install dependencies**:
    ```bash
    flutter pub get
    ```

3. **Run the application**:
    ```bash
    flutter run
    ```

### Project Structure

```
qr_app/
├── .dart_tool/              # Dart tool files
├── .idea/                   # IDE specific files
├── android/                 # Android-specific files
├── assets/                  # Assets such as images, fonts, etc.
├── build/                   # Generated build files
├── ios/                     # iOS-specific files
├── lib/                     # Dart source files
│   ├── screens/             # UI Screens
│   │   ├── home_screen.dart
│   │   ├── loading_screen.dart
│   │   ├── terms_conditions_screen.dart
│   │   
│   ├── widgets/             # Reusable widgets
│   ├── models/              # Data models
│   ├── services/            # Business logic and services
│   ├── utils/               # Utility functions and constants
│   └── main.dart            # Entry point of the app
├── linux/                   # Linux-specific files
├── macos/                   # macOS-specific files
├── test/                    # Unit and widget tests
├── windows/                 # Windows-specific files
├── .flutter-plugins
├── .flutter-plugins-dependencies
├── .gitignore               # Specifies files to ignore in git
├── .metadata                # Metadata for the Flutter project
├── analysis_options.yaml    # Analysis options for Dart
├── pubspec.lock             # Lock file for dependencies
├── pubspec.yaml             # Project dependencies and assets
├── qr_app.iml               # IntelliJ IDEA module file
└── README.md                # Project documentation
```

## Technologies Used

### Flutter Framework

- **Cross-platform Development**: Flutter enables the development of a single codebase that runs seamlessly on Android, iOS, Linux, macOS, and Windows, ensuring consistent performance and user interface across all platforms.
- **Dart Programming Language**: Utilizes Dart, a modern language optimized for fast apps on any platform, ensuring a smooth development experience and efficient performance.

### Flutter Packages and Plugins

- **qr_flutter (4.1.0)**: Used for generating customizable QR codes.
- **screenshot (1.2.3)**: Captures screenshots within the app, useful for saving generated QR codes.
- **path_provider (2.0.9)**: Provides access to commonly used locations on the filesystem.
- **image_picker (0.8.4+3)**: Allows users to pick images from the gallery or camera.
- **shared_preferences (2.0.12)**: Stores simple data persistently across app launches.
- **share (2.0.4)**: Enables sharing of QR codes and other content.
- **file_picker (4.1.4)**: Facilitates file selection within the app.
- **printing (5.4.0)**: Supports printing QR codes directly from the app.
- **image_gallery_saver (2.0.3)**: Saves images to the gallery.
- **permission_handler (10.2.0)**: Manages permissions for accessing device features.
- **gallery_saver (2.3.1)**: Another package for saving images and videos to the gallery.
- **gal (2.3.0)**: For saving images within the app.
- **glassmorphism (2.0.0)**: Adds glassmorphism design elements to the UI.
- **cupertino_icons (1.0.6)**: Provides iOS style icons.

### Local Storage Solutions

- **SQLite**: Utilizes SQLite for local storage, enabling the app to save generated QR codes, user preferences, and history directly on the user’s device.
- **Shared Preferences**: For lightweight data storage such as user settings and app configurations.

### Security and Compliance

- **Data Encryption**: Implements encryption for local data storage, ensuring user data is protected.
- **GDPR Compliance**: Adheres to GDPR regulations, ensuring user data privacy and security.

## Key Features

### QR Code Generation

- **Customizable QR Codes**: Generate QR codes for various data types (URLs, text, contact info) with options for color, size, and embedded logos.
- **Text Addition**: Add custom text below the generated QR code.
- **Color Customization**: Change the color of the QR code to match user preferences.
- **Embedded Logo Customization**: Change the embedded logo within the QR code to a desired one.

### QR Code Management

- **Recent QR Codes**: Display QR codes generated within the last 10 days for quick access.
- **Automatic Deletion**: Automatically delete QR codes older than 10 days to keep the app clutter-free.
- **High-Quality Image Saving**: Save generated QR codes to the device gallery in high-quality image formats.
- **Export Options**: Export QR codes as PDF files for easy sharing and printing.
- **Print QR Codes**: Directly print QR codes from the app using supported printers.

### Profile and Settings Sections

- **Profile Section**: Input and manage user data, providing a personalized experience within the app. (Note: This feature is not yet completed.)
- **Settings Section**: Access related policies of the app and options to disable the app. (Note: This feature is not yet completed.)

## Usage

- **Generating QR Codes**:
    1. Navigate to the QR Code Generator screen.
    2. Enter the data you want to encode.
    3. Tap the generate button to create the QR code.
    4. Save the QR code as an image with optional text.

- **Managing Recent QR Codes**:
    1. Access the home screen to view recently generated QR codes.
    2. Tap on any QR code to view details or delete it.

## Contributing

We welcome contributions to the QR App! Here are some ways you can get involved:

1. **Report Bugs**: If you encounter any issues, please report them on the [issue tracker](https://github.com/your-username/qr_app/issues).
2. **Suggest Features**: Have an idea for a new feature? Open an issue with your suggestion.
3. **Submit Pull Requests**: If you want to contribute code, follow these steps:
    - Fork the repository.
    - Create a new branch (`git checkout -b feature/your-feature-name`).
    - Make your changes.
    - Commit your changes (`git commit -m 'Add some feature'`).
    - Push to the branch (`git push origin feature/your-feature-name`).
    - Open a pull request.

Before submitting, please ensure your changes align with the project's coding standards and include appropriate tests.

## License

This project is licensed under the QR App License. See the [LICENSE](LICENSE) file for details.

## Contact

For any questions or feedback, please open an issue on GitHub.


