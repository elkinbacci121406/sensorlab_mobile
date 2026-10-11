import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

class BatteryPage extends StatefulWidget {
  const BatteryPage({super.key});

  @override
  State<BatteryPage> createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  final Battery _battery = Battery();

  int _level = 0;
  BatteryState _state = BatteryState.unknown;
  bool _loading = true;
  String? _error;

  StreamSubscription<BatteryState>? _stateSubscription;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      if (!mounted) return;
      setState(() {
        _level = level;
        _state = state;
        _loading = false;
      });

      // Escucha cuando conectas o desconectas el cargador.
      _stateSubscription = _battery.onBatteryStateChanged.listen(
        (newState) async {
          await _readLevel();
          if (!mounted) return;
          setState(() => _state = newState);
        },
        onError: (Object e) {
          if (mounted) setState(() => _error = 'Error en el sensor: $e');
        },
      );

      // El porcentaje cambia despacio, así que lo refrescamos cada 5 s.
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _readLevel());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo leer la batería en este dispositivo.\n$e';
      });
    }
  }

  Future<void> _readLevel() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _level = level);
    } catch (_) {
      // Si falla una lectura puntual, se conserva el último valor.
    }
  }

  IconData get _icon => switch (_state) {
    BatteryState.charging => Icons.battery_charging_full,
    BatteryState.full => Icons.battery_full,
    BatteryState.discharging => Icons.battery_std,
    BatteryState.connectedNotCharging => Icons.power,
    _ => Icons.battery_unknown,
  };

  String get _label => switch (_state) {
    BatteryState.charging => 'Cargando',
    BatteryState.full => 'Completa',
    BatteryState.discharging => 'Descargando',
    BatteryState.connectedNotCharging => 'Conectada, sin cargar',
    _ => 'Desconocido',
  };

  Color get _levelColor {
    if (_level <= 20) return Colors.redAccent;
    if (_level <= 50) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

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
                Icon(_icon, size: 72, color: _levelColor),
                const SizedBox(height: 16),
                Text(
                  '$_level%',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Estado: $_label',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 240,
                  child: LinearProgressIndicator(
                    value: _level / 100,
                    minHeight: 10,
                    color: _levelColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Conecta o desconecta el cargador para ver el cambio de estado.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
