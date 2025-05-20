# Decryptor

A Flutter application for decrypting PDF files using RSA and AES.

## Features

- Decrypts PDF files encrypted with AES.
- Uses RSA to decrypt the AES key.
- Custom window title bar.
- Acrylic window effect (if supported).
- User-friendly interface for selecting files and folders.

## Getting Started

### Prerequisites

**For running the application:**
- Java Runtime Environment (JRE)

**For development:**
- Flutter SDK: [Installation Guide](https://flutter.dev/docs/get-started/install)
- Java Development Kit (JDK)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/decryptor.git
   ```
2. Navigate to the project directory:
   ```bash
   cd decryptor
   ```
3. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

### Running the Application

```bash
flutter run
```

## Usage

1. Launch the application.
   `[Screenshot of the application interface]`
2. Select the encrypted PDF file(s) or a folder containing encrypted PDF files.
3. Select your RSA private key file (e.g., `collegeCodeprivate.key`) and the encrypted AES key file (e.g., `collegeCodeaes.key`).
4. Choose a destination folder for the decrypted files.
5. Click the "Decrypt" button.

**Note:** This application requires Java Runtime Environment (JRE) to be installed on your system to perform the decryption.

## Dependencies

This project uses the following main dependencies:

- [flutter](https://pub.dev/packages/flutter)
- [cupertino_icons](https://pub.dev/packages/cupertino_icons)
- [file_picker](https://pub.dev/packages/file_picker)
- [path_provider](https://pub.dev/packages/path_provider)
- [pointycastle](https://pub.dev/packages/pointycastle)
- [flutter_svg](https://pub.dev/packages/flutter_svg)
- [google_fonts](https://pub.dev/packages/google_fonts)
- [provider](https://pub.dev/packages/provider)
- [window_manager](https://pub.dev/packages/window_manager)
- [desktop_drop](https://pub.dev/packages/desktop_drop)
- [shared_preferences](https://pub.dev/packages/shared_preferences)
- [flutter_acrylic](https://pub.dev/packages/flutter_acrylic)
- [asn1lib](https://pub.dev/packages/asn1lib)
- [archive](https://pub.dev/packages/archive)

For a complete list of dependencies, please refer to the `pubspec.yaml` file.

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
