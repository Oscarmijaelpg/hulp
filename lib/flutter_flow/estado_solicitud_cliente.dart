import 'package:flutter/material.dart';

import '/environment_values.dart';

bool get usaEstadosSprint3Cliente =>
    Uri.tryParse(FFDevEnvironmentValues().supabaseUrl)?.host ==
    'ptafsiwlhxomgqmdmidf.supabase.co';

String etiquetaEstadoSprint3Cliente(String? estado) => switch (estado) {
      'entrantes' => 'Pendiente',
      'aceptadas' || 'iniciadas' => 'Aceptado',
      'en camino' => 'Activo',
      'en proceso' => 'En curso',
      'finalizadas' => 'Finalizado',
      'cancelada' || 'canceladas' => 'Cancelado',
      'reagendada' || 'reagendadas' => 'Reagendada',
      _ => 'Estado desconocido',
    };

bool coincideFiltroEstadoSprint3(String? estado, String filtro) {
  final etiqueta = etiquetaEstadoSprint3Cliente(estado);
  if (filtro == 'Activa') return etiqueta == 'Activo';
  if (filtro == 'Finalizado' && etiqueta == 'Reagendada') return true;
  return etiqueta == filtro;
}

Color fondoEstadoSprint3Cliente(String? estado) => switch (estado) {
      'aceptadas' || 'iniciadas' || 'en camino' => const Color(0xFFCFE3FC),
      'en proceso' => const Color(0xFFFFE9CC),
      'finalizadas' => const Color(0xFFDFF9D2),
      'cancelada' || 'canceladas' || 'reagendada' || 'reagendadas' =>
        const Color(0xFFF9DCDF),
      _ => const Color(0xFFDFDFDF),
    };

Color textoEstadoSprint3Cliente(String? estado) => switch (estado) {
      'aceptadas' || 'iniciadas' || 'en camino' => const Color(0xFF0D70E7),
      'en proceso' => const Color(0xFFED8600),
      'finalizadas' => const Color(0xFF18AC4C),
      'cancelada' || 'canceladas' || 'reagendada' || 'reagendadas' =>
        const Color(0xFFBC1021),
      _ => const Color(0xFF606060),
    };
