# musta_pro

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Limitaciones para iOS en Ubuntu

Actualmente, no es posible compilar y firmar aplicaciones iOS directamente en Ubuntu debido a las restricciones de Apple. Para generar un archivo `.ipa`, es necesario utilizar un entorno macOS con Xcode instalado. Esto se debe a que:

- Xcode, la herramienta oficial de desarrollo de Apple, solo está disponible en macOS.
- La firma de aplicaciones iOS requiere certificados y perfiles de aprovisionamiento que solo se pueden gestionar en macOS.

### Opciones para compilar `.ipa` desde Ubuntu

1. **Usar un Mac físico o virtual**:
   - Configura un entorno macOS con Xcode.
   - Ejecuta el comando:
     ```bash
     flutter build ipa
     ```
   - Esto generará el archivo `.ipa` en la carpeta `build/ios/ipa/`.

2. **Usar un servicio de CI/CD en la nube**:
   - **Codemagic**: Servicio especializado en Flutter que permite compilar y distribuir aplicaciones iOS.
   - **GitHub Actions**: Configura un workflow con un runner macOS para compilar el `.ipa`.

3. **Servicios de alquiler de Mac en la nube**:
   - Plataformas como MacStadium o Mac in Cloud ofrecen acceso remoto a máquinas macOS.

### Opciones de CI/CD para compilar `.ipa`

#### 1. Codemagic
Codemagic es una plataforma de CI/CD diseñada específicamente para Flutter. Permite compilar, probar y distribuir aplicaciones iOS sin necesidad de un Mac físico.

Pasos básicos:
1. Regístrate en [Codemagic](https://codemagic.io/).
2. Conecta tu repositorio de código (GitHub, GitLab, Bitbucket).
3. Configura un flujo de trabajo para iOS:
   - Sube tus certificados y perfiles de aprovisionamiento.
   - Define los comandos de build, como:
     ```bash
     flutter build ipa
     ```
4. Ejecuta el flujo de trabajo y descarga el `.ipa` generado.

#### 2. GitHub Actions
GitHub Actions permite configurar flujos de trabajo personalizados para compilar aplicaciones iOS en runners macOS.

Ejemplo de configuración básica (`.github/workflows/ios.yml`):
```yaml
name: Build iOS

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: macos-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Set up Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: 'stable'

    - name: Install dependencies
      run: flutter pub get

    - name: Build iOS
      run: flutter build ipa

    - name: Upload artifact
      uses: actions/upload-artifact@v3
      with:
        name: ios-build
        path: build/ios/ipa/
```

Sube tus certificados y perfiles de aprovisionamiento como secretos en GitHub para firmar la app correctamente.

### Próximos pasos

Si necesitas ayuda para configurar un servicio de CI/CD o un entorno macOS, indícalo y te proporcionaré más detalles.
