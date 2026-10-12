import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:light/light.dart';
import 'status_message.dart';

class LightPage extends StatefulWidget {
  const LightPage({super.key});

  @override
  State<LightPage> createState() => _LightPageState();
}

class _LightPageState extends State<LightPage> {
  // En Android el paquete no avisa si falta el sensor: simplemente no emite. 
  // Por eso, si en este tiempo no llega ninguna lectura, se informa al usuario.
  static const Duration _timeout = Duration(seconds: 5);

  StreamSubscription<int>? _subscription;
  Timer? _timeoutTimer;

  int? _lux;
  int? _min;
  int? _max;
  bool _sinLecturas = false;
  String? _error;

  bool get _plataformaSoportada =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _retry() {
    setState(() {
      _lux = null;
      _min = null;
      _max = null;
      _sinLecturas = false;
      _error = null;
    });
    _start();
  }

  void _start() {
    _subscription?.cancel();
    _timeoutTimer?.cancel();
    if (!_plataformaSoportada) return;

    _subscription = Light().lightSensorStream.listen(
      (lux) {
        if (!mounted || lux < 0) return;
        _timeoutTimer?.cancel();
        setState(() {
          _lux = lux;
          _sinLecturas = false;
          _min = _min == null ? lux : math.min(_min!, lux);
          _max = _max == null ? lux : math.max(_max!, lux);
        });
      },
      onError: (Object e) {
        if (mounted) setState(() => _error = 'Error en el sensor de luz: $e');
      },
    );

    _timeoutTimer = Timer(_timeout, () {
      if (mounted && _lux == null) setState(() => _sinLecturas = true);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  // Rangos aproximados de referencia para interpretar la lectura.
  ({String label, IconData icon, Color color}) _nivel(int lux) {
    if (lux < 10) {
      return (label: 'Muy oscuro', icon: Icons.nightlight, color: Colors.indigoAccent);
    }
    if (lux < 100) {
      return (label: 'Penumbra', icon: Icons.wb_twilight, color: Colors.blueAccent);
    }
    if (lux < 1000) {
      return (label: 'Interior iluminado', icon: Icons.lightbulb, color: Colors.amber);
    }
    if (lux < 10000) {
      return (label: 'Exterior / nublado', icon: Icons.wb_cloudy, color: Colors.orangeAccent);
    }
    return (label: 'Luz solar directa', icon: Icons.wb_sunny, color: Colors.yellowAccent);
  }

  // Escala logarítmica: 1 lux ≈ 0 y 100 000 lux ≈ 1.
  double _intensidad(int lux) => (math.log(lux + 1) / math.log(100001)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    if (!_plataformaSoportada) {
      return const StatusMessage(
        icon: Icons.block,
        titulo: 'Sensor de luz no disponible en esta plataforma',
        detalle:
            'El paquete light solo entrega lecturas en Android. En iOS requiere '
            'SensorKit, un permiso especial que Apple solo concede a apps de '
            'investigación, y en Web no existe acceso al sensor.',
      );
    }

    if (_error != null) {
      return StatusMessage(
        icon: Icons.error_outline,
        titulo: 'No se pudo leer el sensor de luz',
        detalle: _error!,
        onRetry: _retry,
      );
    }

    if (_lux == null) {
      if (_sinLecturas) {
        return StatusMessage(
          icon: Icons.sensors_off,
          titulo: 'No se reciben lecturas',
          detalle:
              'Este dispositivo no tiene un sensor de luz accesible o no ha '
              'enviado datos. Prueba cambiando la iluminación o reintenta.',
          onRetry: _retry,
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final lux = _lux!;
    final nivel = _nivel(lux);
    final intensidad = _intensidad(lux);
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // El "foco" brilla más cuanta más luz recibe el sensor.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: nivel.color.withValues(alpha: 0.15 + 0.6 * intensidad),
                        blurRadius: 10 + 50 * intensidad,
                        spreadRadius: 4 + 16 * intensidad,
                      ),
                    ],
                  ),
                  child: Icon(nivel.icon, size: 72, color: nivel.color),
                ),
                const SizedBox(height: 24),
                Text('$lux lx', style: textTheme.displaySmall),
                const SizedBox(height: 8),
                Text(nivel.label, style: textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  width: 240,
                  child: LinearProgressIndicator(
                    value: intensidad,
                    minHeight: 10,
                    color: nivel.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mín: $_min lx  ·  Máx: $_max lx',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Lleva el teléfono de una zona iluminada a otra más oscura '
                  'para ver el cambio.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
