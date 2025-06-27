# PCR Reagent Calculator

A Flutter application for calculating PCR reagent volumes with configuration save/load functionality.

## Features

- Calculate PCR reagent volumes based on number of reactions and reaction volume
- Support for template DNA volume input
- Optional reagent inclusion/exclusion
- Save and load different PCR configurations
- Export results to PDF or copy to clipboard
- Modern, intuitive user interface

## Dependencies

- Flutter SDK
- shared_preferences: For saving configurations locally
- pdf & printing: For PDF export functionality
- path_provider: For file system access
- numberpicker: For number input controls

## Getting Started

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the application

## Usage

1. Enter the number of reactions and reaction volume
2. Specify template DNA volume if needed
3. Click calculate to see reagent volumes
4. Use the save button (💾) to save current configuration
5. Use the load button (📂) to load saved configurations
6. Export results using Print or Copy buttons

## Configuration Management

- Save multiple PCR configurations with custom names
- Load previously saved configurations instantly
- Delete unwanted configurations
- All configurations are stored locally on the device
