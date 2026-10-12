# SensorLab Mobile

Miniapp Flutter que reúne tres funcionalidades nativas del dispositivo: batería, luz ambiental y proximidad, más una pantalla de información sobre disponibilidad y permisos.
Programación Móvil, Grupo 03.

**Integrantes:** Elkin (Batería) · Oscar (Luz ambiental) · Libardo (Proximidad) · Juan (Integración y permisos)

## Módulos

| Módulo | Qué muestra | Demostración |
| --- | --- | --- |
| Batería | Porcentaje real y estado de carga (cargando, descargando, completa, conectada sin cargar) | Conectar y desconectar el cargador |
| Luz ambiental | Lectura en lux, nivel de iluminación, mínimo y máximo de la sesión | Pasar de una zona iluminada a otra más oscura |
| Proximidad | Estado «Cerca / Lejos», contador e historial de eventos en tiempo real | Acercar y retirar la mano de la parte superior del teléfono |
| Info | Plataforma, disponibilidad real de cada sensor, paquete, permisos y qué hacer si no hay lecturas | Mostrar un sensor no disponible o sin lecturas |

Si un sensor no existe o no envía datos, la app lo indica en pantalla en lugar de mostrar valores inventados.

## Paquetes

| Función | Paquete | Versión |
| --- | --- | --- |
| Batería | [battery_plus](https://pub.dev/packages/battery_plus) | ^7.1.2 |
| Luz ambiental | [light](https://pub.dev/packages/light) | ^5.0.0 |
| Proximidad | [proximity_sensor](https://pub.dev/packages/proximity_sensor) | ^2.0.0 |

## Cómo ejecutar

Requisitos: Flutter 3.44 o superior y un teléfono Android con la depuración USB activada.

    flutter pub get
    flutter run

En Windows, compilar con plugins requiere activar el Modo de desarrollador (`start ms-settings:developers`).

## Permisos y plataformas

| Función | Android | iOS | Web |
| --- | --- | --- | --- |
| Batería | Sin permisos | Sin permisos | Solo navegadores Chromium (Battery Status API) |
| Luz ambiental | Sin permisos | Requiere SensorKit (permiso especial de Apple para apps de investigación); la app lo marca como no disponible | No soportado |
| Proximidad | Sin permisos | Sin permisos | No soportado |

En `AndroidManifest.xml` los sensores se declaran con `<uses-feature ... android:required="false" />`: la app se puede instalar en equipos sin esos sensores y en ese caso muestra el aviso de no disponible.

## Plataformas probadas

- Android: pendiente de probar en dispositivo real (APK de depuración compila correctamente).

## Limitaciones conocidas

- La disponibilidad de los sensores depende del hardware y del sistema operativo.
- El paquete `light` no tiene un método para consultar si existe el sensor: la app espera 5 s y, si no llega ninguna lectura, muestra «No se reciben lecturas».
- Muchos sensores de proximidad solo distinguen dos estados (cerca / lejos), no la distancia exacta.
- En iOS el sensor de proximidad solo emite cuando cambia el estado, y el sistema apaga la pantalla al acercar un objeto.
- El porcentaje de batería cambia lentamente; la app lo refresca cada 5 s.
