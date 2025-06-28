# Lab Studio 🧪

Professional laboratory experiment design and calculation toolkit built with Flutter.

## 🎯 Overview

Lab Studio is a comprehensive mobile application designed for laboratory professionals and researchers. Currently featuring a powerful PCR reagent calculator with plans to expand into a complete laboratory workflow management platform.

## ✨ Current Features

### 🧬 PCR Reagent Calculator
- **Bank-style Number Input**: Professional numerical input with comma formatting
- **Intelligent Volume Calculation**: Automatic calculation for multiple reactions
- **Template DNA Management**: Flexible template DNA volume configuration
- **Optional Reagent Support**: Toggle reagents on/off as needed
- **Configuration Management**: Save, load, and manage calculation presets

### 🎨 User Experience
- **Modern UI/UX**: Clean, intuitive interface with iOS-style design
- **Dark/Light Mode**: Full theme switching support
- **Responsive Design**: Optimized for various screen sizes
- **Professional Layout**: Laboratory-focused design patterns

### 🔬 Experiment Tracking
- **Tracking Mode**: Monitor which reagents have been added
- **Dual Display Options**: 
  - **Checkbox Mode**: Visual checkboxes for tracking
  - **Strikethrough Mode**: Text strikethrough for minimalist approach
- **State Management**: Persistent tracking across sessions

### 📊 Export & Sharing
- **PDF Generation**: Professional calculation reports
- **Data Export**: Share results via email, messaging, etc.
- **Print Support**: Direct printing capabilities

### ⚙️ Advanced Settings
- **Theme Preferences**: Dark/Light mode with auto-save
- **Display Customization**: Choose tracking display style
- **Configuration Backup**: Save/restore app configurations

## 🛠️ Technical Details

### Built With
- **Flutter**: Cross-platform mobile development framework
- **Dart**: Programming language
- **Cupertino**: iOS-style UI components
- **SharedPreferences**: Local data persistence
- **PDF Generation**: Professional document export

### Key Dependencies
- Flutter SDK (3.8.1 or higher)
- shared_preferences: Configuration and settings persistence
- pdf & printing: Professional PDF export functionality
- path_provider: File system access for data management
- numberpicker: Enhanced number input controls
- cupertino_icons: iOS-style iconography

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- iOS Simulator / Android Emulator / Physical Device

### Installation
1. Clone the repository:
```bash
git clone https://github.com/[username]/lab-studio.git
cd lab-studio
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## 📱 Usage Guide

### Basic PCR Calculation
1. Enter the number of reactions and reaction volume
2. Specify template DNA volume if needed
3. Toggle optional reagents on/off as required
4. View calculated volumes for each reagent

### Configuration Management
- **Save**: Use the 💾 button to save current setup with a custom name
- **Load**: Use the � button to browse and load saved configurations
- **Delete**: Remove unwanted configurations from the load dialog
- All configurations are stored locally and persist across app sessions

### Experiment Tracking
1. Enable tracking mode in Settings (⚙️)
2. Choose display style: Checkbox or Strikethrough
3. Mark reagents as added during experiment preparation
4. Reset tracking when starting new experiments

### Export & Sharing
- **PDF Export**: Generate professional calculation reports
- **Copy to Clipboard**: Quick sharing of calculation results
- **Print**: Direct printing support for laboratory documentation

## 🔮 Future Roadmap

Lab Studio is designed to expand beyond PCR calculations:

- **🧪 Additional Calculators**: Protein purification, gel electrophoresis, etc.
- **📋 Protocol Management**: Step-by-step experiment protocols
- **📊 Data Analysis**: Built-in statistical analysis tools
- **🔗 Lab Integration**: Connect with lab equipment and LIMS
- **👥 Team Collaboration**: Share protocols and results
- **📈 Progress Tracking**: Experiment history and analytics

## 🤝 Contributing

We welcome contributions! Please feel free to submit issues, feature requests, or pull requests.

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Laboratory professionals who provided feedback and requirements
- Open source community for inspiration and tools

---

**Lab Studio** - Making laboratory calculations simple, accurate, and professional.

🧬 Built with ❤️ for the scientific community
