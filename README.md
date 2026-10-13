# SensorLab Mobile

**Laboratorio de sensores móviles en Flutter**
Programación Móvil · Grupo 03

> «¿Alguna vez se han preguntado cómo sabe su celular cuánta batería le queda, si hay suficiente luz o si tienen el teléfono pegado al oído? Hoy lo vamos a demostrar con Flutter».

## Sobre el proyecto

SensorLab Mobile es una miniapp desarrollada en Flutter que reúne en una sola aplicación tres funcionalidades nativas del dispositivo:

1. **Nivel y estado de la batería**
2. **Lectura de luz ambiental**
3. **Detección de proximidad**

El objetivo no es solo explicar la teoría, sino **ver los sensores en acción**: la app muestra lecturas reales del teléfono en tiempo real. Cuando el hardware o la plataforma no permiten obtener un dato, la app lo dice claramente en lugar de mostrar valores inventados. Así el manejo de errores también forma parte de la demostración.

La app tiene una pantalla principal con navegación inferior (o lateral en pantallas anchas) y cuatro módulos.

## Módulos

### 🔋 Batería
Muestra el **porcentaje real** de la batería y el **estado de carga**: cargando, descargando, completa o conectada sin cargar.

- **Cómo funciona:** el sistema operativo mantiene la información de la batería (nivel y si está conectada a una fuente de energía). La app consulta el nivel y se suscribe a los cambios de estado, que llegan como eventos cada vez que se conecta o desconecta el cargador. Como el porcentaje cambia despacio, se vuelve a consultar cada 5 segundos.
- **Interfaz:** ícono según el estado, porcentaje grande y barra de color (verde, naranja o rojo según el nivel).
- **Demostración:** conectar y desconectar el cargador y observar el cambio de estado. El porcentaje puede no variar inmediatamente.

### 💡 Luz ambiental
Muestra la **iluminación en lux** y una representación visual que cambia con la luz.

- **Cómo funciona:** el sensor de luz, normalmente junto a la cámara frontal, mide cuánta luz llega al teléfono. Es el mismo sensor que usa el sistema para ajustar el brillo automático. La unidad es el **lux** (lumen por metro cuadrado): una habitación oscura ronda 1–10 lx, una oficina 300–500 lx y la luz solar directa supera los 10 000 lx.
- **Interfaz:** valor en lux, clasificación del nivel (muy oscuro, penumbra, interior iluminado, exterior/nublado, luz solar directa), un ícono que brilla más con más luz, una barra en escala logarítmica y el mínimo y máximo de la sesión.
- **Demostración:** llevar el teléfono de una zona iluminada a otra más oscura, sin tapar ni forzar el dispositivo.
- **Si no hay sensor:** si en 5 segundos no llega ninguna lectura, la app muestra «No se reciben lecturas» con un botón para reintentar.

### 📡 Proximidad
Muestra en tiempo real si hay un objeto **«Cerca»** o **«Lejos»** del teléfono.

- **Cómo funciona:** el sensor de proximidad, ubicado junto al auricular superior, emite luz infrarroja invisible y mide cuánta se refleja. Si un objeto está muy cerca (la mano o la cara durante una llamada), el reflejo es fuerte y el sensor reporta «cerca». Es lo que hace que la pantalla se apague cuando acercas el teléfono al oído. La mayoría de los sensores solo distinguen esos dos estados, no la distancia exacta.
- **Interfaz:** un círculo que cambia de tamaño y color (verde = lejos, rojo = cerca), el estado en grande, un contador de eventos y el historial de los últimos cambios con su hora.
- **Demostración:** acercar y retirar la mano de la parte superior del teléfono. La posición exacta del sensor depende del modelo.
- **Si no hay sensor:** la app consulta primero si el dispositivo lo tiene y, si no, lo informa.

### ℹ️ Información del dispositivo
Pantalla de diagnóstico que indica:

- En qué plataforma se ejecuta la app.
- Si cada sensor está **disponible o no**, comprobándolo en el momento.
- Qué paquete se usa para cada función.
- Qué permisos requiere en cada plataforma.
- Qué hacer si no se reciben lecturas.

Se actualiza deslizando hacia abajo.

## Tecnologías y paquetes

| Función | Paquete | Uso |
| --- | --- | --- |
| Batería | [battery_plus](https://pub.dev/packages/battery_plus) `^7.1.2` | Consultar el nivel y escuchar cambios del estado de carga |
| Luz ambiental | [light](https://pub.dev/packages/light) `^5.0.0` | Recibir eventos del sensor de luz en lux |
| Proximidad | [proximity_sensor](https://pub.dev/packages/proximity_sensor) `^2.0.0` | Escuchar eventos de proximidad (1 = cerca, 0 = lejos) |

- **Framework:** Flutter 3.44 (Dart 3.12), Material 3 con tema oscuro.
- **Patrón de lectura:** cada módulo se suscribe a un `Stream` de eventos del sensor y actualiza la interfaz con `setState`. Las suscripciones se cancelan al salir de la pantalla para no gastar batería.

## Permisos y diferencias entre plataformas

| Función | Android | iOS | Web |
| --- | --- | --- | --- |
| Batería | Sin permisos | Sin permisos | Solo navegadores basados en Chromium (Battery Status API) |
| Luz ambiental | Sin permisos | Requiere SensorKit, un permiso especial que Apple solo concede a apps de investigación; la app lo marca como no disponible | No soportado |
| Proximidad | Sin permisos | Sin permisos; el sistema apaga la pantalla al acercar un objeto | No soportado |

Ninguna de las tres funciones requiere **permisos de ejecución** en Android, es decir, ningún diálogo de «Permitir / Denegar». Aun así, en `AndroidManifest.xml` los sensores se declaran como características opcionales:

```xml
<uses-feature android:name="android.hardware.sensor.light" android:required="false" />
<uses-feature android:name="android.hardware.sensor.proximity" android:required="false" />
```

Con `required="false"` la app se puede instalar en equipos que no tengan esos sensores y, en ese caso, muestra el aviso de no disponible en lugar de fallar.

## Estructura del código

```
lib/
├── main.dart                  # Punto de entrada y tema de la app
├── screens/
│   └── home_screen.dart       # Pantalla principal y navegación entre módulos
└── widgets/
    ├── battery_page.dart      # Módulo de batería
    ├── light_page.dart        # Módulo de luz ambiental
    ├── proximity_page.dart    # Módulo de proximidad
    ├── info_page.dart         # Información y disponibilidad de sensores
    └── status_message.dart    # Mensaje común para sensor no disponible o error
test/
└── widget_test.dart           # Prueba de la pantalla principal
```

## Instalación y ejecución

**Requisitos:** Flutter 3.44 o superior y un teléfono Android real con la **depuración USB** activada. Los sensores no se pueden probar de forma fiable en un emulador.

```bash
git clone https://github.com/elkinbacci121406/sensorlab_mobile.git
cd sensorlab_mobile
flutter pub get
flutter devices          # verificar que aparece el teléfono
flutter run -d <id-del-dispositivo>
```

**Notas:**
- En Windows, compilar con plugins requiere activar el Modo de desarrollador (`start ms-settings:developers`).
- En teléfonos Xiaomi (MIUI/HyperOS) también hay que activar **Instalar vía USB** y **Depuración USB (ajustes de seguridad)** en las Opciones de desarrollador.

Para ejecutar las pruebas:

```bash
flutter test
```

## Plataformas probadas

| Plataforma | Estado |
| --- | --- |
| Android 16 (Xiaomi, dispositivo real) | La app compila, se instala y se ejecuta |
| iOS | No probado (el equipo no cuenta con dispositivo iOS) |
| Web | No soportado para luz y proximidad |

## Limitaciones conocidas

- La disponibilidad de los sensores depende del hardware, del sistema operativo y de la versión del paquete.
- El paquete `light` no tiene un método para consultar si existe el sensor: la app espera 5 segundos y, si no llega ninguna lectura, lo informa.
- Muchos sensores de proximidad solo distinguen dos estados (cerca / lejos), no la distancia exacta.
- En iOS el sensor de proximidad solo emite cuando cambia el estado, no al abrir la pantalla.
- El porcentaje de batería cambia lentamente; la app lo refresca cada 5 segundos.

## Equipo

| Integrante | Responsabilidad |
| --- | --- |
| **Elkin** | Módulo de batería: nivel, estado de carga e indicador |
| **Oscar** | Módulo de luz ambiental: lectura en lux e indicador visual |
| **Libardo** | Módulo de proximidad: estado «Cerca / Lejos» y eventos en tiempo real |
| **Juan** | Integración, navegación, disponibilidad de sensores, permisos y pruebas |

Cada integrante tiene un módulo principal a su cargo, pero el desarrollo, las pruebas y la revisión se hicieron en equipo.

---

Proyecto académico · Programación Móvil · Grupo 03
