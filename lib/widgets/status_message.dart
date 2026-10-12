import 'package:flutter/material.dart';

/// Mensaje centrado para sensores no disponibles, sin lecturas o con error.
class StatusMessage extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String detalle;
  final VoidCallback? onRetry;

  const StatusMessage({
    super.key,
    required this.icon,
    required this.titulo,
    required this.detalle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.orangeAccent),
            const SizedBox(height: 16),
            Text(titulo, textAlign: TextAlign.center, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(detalle, textAlign: TextAlign.center, style: textTheme.bodyMedium),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
