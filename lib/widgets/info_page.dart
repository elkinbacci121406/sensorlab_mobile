import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:light/light.dart';
import 'package:proximity_sensor/proximity_sensor.dart';

enum _Estado { comprobando, disponible, noDisponible }

class _Funcion {
  final String nombre;
  final IconData icon;
  final String paquete;
  final String permisos;
  final String sinLecturas;
  _Estado estado = _Estado.comprobando;
  String detalle = '';

  _Funcion({
    required this.nombre,
    required this.icon,
    required this.paquete,
    required this.permisos,
    required this.sinLecturas,
  });
}

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final _bateria = _Funcion(
    nombre: 'Batería',
    icon: Icons.battery_full,
    paquete: 'battery_plus',
    permisos:
        'Android e iOS: no requiere permisos. Web: usa la Battery Status API, '
        'que solo existe en navegadores basados en Chromium.',
    sinLecturas:
        'El porcentaje cambia lentamente; conecta o desconecta el cargador '
        'para ver el cambio de estado.',
  );

  final _luz = _Funcion(
    nombre: 'Luz ambiental',
    icon: Icons.light_mode,
    paquete: 'light',
    permisos:
        'Android: no requiere permisos. iOS: necesita SensorKit, un permiso '
        'especial que Apple solo concede a apps de investigación. Web: no soportado.',
    sinLecturas:
        'Cambia la iluminación alrededor del teléfono. Si sigue sin datos, '
        'el equipo no expone un sensor de luz accesible.',
  );

  final _proximidad = _Funcion(
    nombre: 'Proximidad',
    icon: Icons.sensors,
    paquete: 'proximity_sensor',
    permisos:
        'Android e iOS: no requiere permisos de ejecución. Web y escritorio: '
        'no soportado.',
    sinLecturas:
        'Acerca la mano a la parte superior del teléfono. Muchos sensores '
        'solo distinguen dos estados (cerca / lejos), no la distancia.',
  );

  List<_Funcion> get _funciones => [_bateria, _luz, _proximidad];

  bool get _esMovil =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _plataforma {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  @override
  void initState() {
    super.initState();
    _ejecutarComprobaciones();
  }

  Future<void> _comprobar() async {
    setState(() {
      for (final f in _funciones) {
        f.estado = _Estado.comprobando;
        f.detalle = '';
      }
    });
    await _ejecutarComprobaciones();
  }

  Future<void> _ejecutarComprobaciones() async {
    await Future.wait([
      _comprobarBateria(),
      _comprobarLuz(),
      _comprobarProximidad(),
    ]);
  }

  void _marcar(_Funcion f, bool ok, String detalle) {
    if (!mounted) return;
    setState(() {
      f.estado = ok ? _Estado.disponible : _Estado.noDisponible;
      f.detalle = detalle;
    });
  }

  Future<void> _comprobarBateria() async {
    try {
      final nivel = await Battery().batteryLevel;
      _marcar(_bateria, true, 'Lectura actual: $nivel%');
    } catch (e) {
      _marcar(_bateria, false, 'No se pudo leer la batería: $e');
    }
  }

  // El paquete light no tiene un método de disponibilidad: se escucha el
  // sensor unos segundos y se comprueba si llega alguna lectura.
  Future<void> _comprobarLuz() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _marcar(_luz, false, 'No soportado en $_plataforma.');
      return;
    }
    try {
      final lux = await Light().lightSensorStream
          .where((v) => v >= 0)
          .first
          .timeout(const Duration(seconds: 4));
      _marcar(_luz, true, 'Lectura recibida: $lux lx');
    } on TimeoutException {
      _marcar(_luz, false, 'Sin lecturas en 4 s: el sensor no está disponible.');
    } catch (e) {
      _marcar(_luz, false, 'Error: $e');
    }
  }

  Future<void> _comprobarProximidad() async {
    if (!_esMovil) {
      _marcar(_proximidad, false, 'No soportado en $_plataforma.');
      return;
    }
    try {
      final ok = await ProximitySensor.isProximitySensorAvailable();
      _marcar(
        _proximidad,
        ok,
        ok ? 'El sistema reporta un sensor de proximidad.' : 'El sistema no reporta un sensor de proximidad.',
      );
    } catch (e) {
      _marcar(_proximidad, false, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _comprobar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_android),
              title: Text('Plataforma: $_plataforma'),
              subtitle: const Text(
                'La disponibilidad depende del hardware, del sistema operativo '
                'y del paquete. Desliza hacia abajo para volver a comprobar.',
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final f in _funciones) _FuncionCard(funcion: f),
          const SizedBox(height: 8),
          Text(
            'SensorLab Mobile · Programación Móvil · Grupo 03\n'
            'Elkin · Oscar · Libardo · Juan',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FuncionCard extends StatelessWidget {
  final _Funcion funcion;

  const _FuncionCard({required this.funcion});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (Widget badge, Color color) = switch (funcion.estado) {
      _Estado.comprobando => (
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          Colors.grey,
        ),
      _Estado.disponible => (
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
          Colors.greenAccent,
        ),
      _Estado.noDisponible => (
          const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
          Colors.redAccent,
        ),
    };
    final estadoTexto = switch (funcion.estado) {
      _Estado.comprobando => 'Comprobando…',
      _Estado.disponible => 'Disponible',
      _Estado.noDisponible => 'No disponible',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(funcion.icon),
                const SizedBox(width: 12),
                Expanded(child: Text(funcion.nombre, style: textTheme.titleMedium)),
                badge,
                const SizedBox(width: 6),
                Text(estadoTexto, style: textTheme.labelLarge?.copyWith(color: color)),
              ],
            ),
            if (funcion.detalle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(funcion.detalle, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 8),
            _Dato(titulo: 'Paquete', valor: funcion.paquete),
            _Dato(titulo: 'Permisos', valor: funcion.permisos),
            _Dato(titulo: 'Si no hay lecturas', valor: funcion.sinLecturas),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String titulo;
  final String valor;

  const _Dato({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$titulo: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: valor),
          ],
        ),
        style: textTheme.bodySmall,
      ),
    );
  }
}
