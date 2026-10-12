import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'status_message.dart';

class _Evento {
  final bool cerca;
  final DateTime hora;

  const _Evento(this.cerca, this.hora); 
}

class ProximityPage extends StatefulWidget {
  const ProximityPage({super.key});

  @override
  State<ProximityPage> createState() => _ProximityPageState();
}

class _ProximityPageState extends State<ProximityPage> {
  static const int _maxHistorial = 8;

  StreamSubscription<int>? _subscription;

  bool _loading = true;
  bool _disponible = false;
  bool? _cerca;
  int _contador = 0;
  final List<_Evento> _historial = [];
  String? _error;

  bool get _plataformaSoportada =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!_plataformaSoportada) {
      _loading = false;
      return;
    }

    try {
      _disponible = await ProximitySensor.isProximitySensorAvailable();
    } catch (_) {
      _disponible = false;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (!_disponible) return;

    // El sensor envía 1 cuando hay un objeto cerca y 0 cuando se aleja.
    _subscription = ProximitySensor.events.listen(
      (event) {
        if (!mounted) return;
        final cerca = event > 0;
        setState(() {
          _cerca = cerca;
          _contador++;
          _historial.insert(0, _Evento(cerca, DateTime.now()));
          if (_historial.length > _maxHistorial) _historial.removeLast();
        });
      },
      onError: (Object e) {
        if (mounted) setState(() => _error = 'Error en el sensor de proximidad: $e');
      },
    );
  }

  void _retry() {
    _subscription?.cancel();
    setState(() {
      _loading = true;
      _cerca = null;
      _contador = 0;
      _historial.clear();
      _error = null;
    });
    _init();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String _formatoHora(DateTime t) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(t.hour)}:${dos(t.minute)}:${dos(t.second)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_plataformaSoportada) {
      return const StatusMessage(
        icon: Icons.block,
        titulo: 'Sensor de proximidad no disponible en esta plataforma',
        detalle:
            'El paquete proximity_sensor funciona en Android e iOS. '
            'En Web y escritorio no hay acceso a este sensor.',
      );
    }

    if (!_disponible) {
      return StatusMessage(
        icon: Icons.sensors_off,
        titulo: 'Este dispositivo no tiene sensor de proximidad',
        detalle:
            'El sistema operativo no reporta un sensor de proximidad. '
            'Algunos equipos (tablets, emuladores) no lo incluyen.',
        onRetry: _retry,
      );
    }

    if (_error != null) {
      return StatusMessage(
        icon: Icons.error_outline,
        titulo: 'No se pudo leer el sensor de proximidad',
        detalle: _error!,
        onRetry: _retry,
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final cerca = _cerca;
    final color = switch (cerca) {
      true => Colors.redAccent,
      false => Colors.greenAccent,
      null => Colors.grey,
    };
    final texto = switch (cerca) {
      true => 'CERCA',
      false => 'LEJOS',
      null => 'Esperando…',
    };

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
                // El círculo se encoge y cambia de color cuando algo se acerca.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: cerca == true ? 120 : 160,
                  height: cerca == true ? 120 : 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                    border: Border.all(color: color, width: 4),
                  ),
                  child: Icon(
                    cerca == true ? Icons.back_hand : Icons.sensors,
                    size: 56,
                    color: color,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  texto,
                  style: textTheme.displaySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Eventos recibidos: $_contador', style: textTheme.titleMedium),
                const SizedBox(height: 16),
                if (_historial.isEmpty)
                  Text(
                    'Acerca la mano a la parte superior del teléfono.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall,
                  )
                else
                  SizedBox(
                    width: 240,
                    child: Column(
                      children: [
                        for (final e in _historial)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: e.cerca ? Colors.redAccent : Colors.greenAccent,
                                ),
                                const SizedBox(width: 8),
                                Text(e.cerca ? 'Cerca' : 'Lejos'),
                                const Spacer(),
                                Text(_formatoHora(e.hora), style: textTheme.bodySmall),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'El sensor suele estar junto al auricular superior; la '
                  'posición exacta depende del modelo.',
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
