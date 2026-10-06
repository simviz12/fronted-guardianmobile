# Guardian Mobile - Client Frontend

Sistema remoto antirrobo legítimo para Android, desarrollado con Flutter y Clean Architecture.

---

## 🚀 Requisitos previos

- Flutter SDK (versión `>=3.19.0` o superior)
- Dart SDK
- Android SDK configurado con emulador o dispositivo físico
- Backend de Guardian API en ejecución (por defecto en el puerto `3000`)

---

## ⚙️ Conexión al Backend según el entorno

El backend URL se configura mediante `--dart-define=API_BASE_URL`:

### 1. Dispositivo físico Android conectado por USB
Usa reverse port forwarding de adb para comunicar directamente con `localhost:3000`:
```powershell
adb reverse tcp:3000 tcp:3000
flutter run -d <DEVICE_ID> --dart-define=API_BASE_URL=http://localhost:3000
```

### 2. Emulador Android
Usa el alias de loopback estándar del emulador Android (`10.0.2.2`):
```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

### 3. Red Local / LAN IP (Wi-Fi)
Usa la IP de tu PC anfitrión en la red local:
```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.X:3000
```

---

## 🧪 Pruebas y Calidad de Código

### Ejecución de análisis estático:
```powershell
flutter analyze
```

### Ejecución de pruebas unitarias y de widgets:
```powershell
flutter test
```

---

## 🏛️ Arquitectura del Proyecto

Arquitectura limpia orientada a funcionalidades (**Clean Architecture - Feature First**):

```text
lib/
├── core/
│   ├── config/       # ApiConfig (--dart-define)
│   ├── error/        # Failures y manejo tipado de errores
│   ├── network/      # DioClient, interceptores y logs seguros
│   ├── router/       # Configuración de go_router (/ y /server-status)
│   └── theme/        # Design system de Guardian Sentinel (colores, fuentes, widgets)
├── features/
│   └── server_status/
│       ├── domain/   # Entidades, repositorio abstracto, casos de uso
│       ├── data/     # DTOs, datasource remoto (Dio), implementación de repositorio
│       └── presentation/ # Widgets de estado, UI y StateNotifier (Riverpod)
└── main.dart         # Punto de entrada con ProviderScope y MaterialApp.router
```
