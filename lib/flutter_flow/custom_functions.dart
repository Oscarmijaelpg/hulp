import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/auth/supabase_auth/auth_util.dart';

String obtenerNroLiteral(int numero) {
  // dame de manera literal el "numero" ejemplo 1 = Primera, 2 = Segunda
  switch (numero) {
    case 1:
      return 'Primera';
    case 2:
      return 'Segunda';
    case 3:
      return 'Tercera';
    case 4:
      return 'Cuarta';
    case 5:
      return 'Quinta';
    case 6:
      return 'Sexta';
    case 7:
      return 'Séptima';
    case 8:
      return 'Octava';
    case 9:
      return 'Novena';
    case 10:
      return 'Décima';
    case 11:
      return 'Undécima';
    case 12:
      return 'Duodécima';
    case 13:
      return 'Decimotercera';
    case 14:
      return 'Decimocuarta';
    case 15:
      return 'Decimoquinta';
    case 16:
      return 'Decimosexta';
    case 17:
      return 'Decimoséptima';
    case 18:
      return 'Decimoctava';
    case 19:
      return 'Decimonovena';
    case 20:
      return 'Vigésima';
    case 21:
      return 'Vigésima primera';
    case 22:
      return 'Vigésima segunda';
    case 23:
      return 'Vigésima tercera';
    case 24:
      return 'Vigésima cuarta';
    case 25:
      return 'Vigésima quinta';
    case 26:
      return 'Vigésima sexta';
    case 27:
      return 'Vigésima séptima';
    case 28:
      return 'Vigésima octava';
    case 29:
      return 'Vigésima novena';
    case 30:
      return 'Trigésima';
    default:
      return numero.toString();
  }
}

bool verifyUrlPhoneEmail(String input) {
  final normalized = input.trim();

  // Regex para email (estricto)
  final emailRegex = RegExp(
    r'\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b',
  );

  // Regex para teléfono (acepta +, paréntesis, guiones, espacios)
  final phoneRegex = RegExp(
    r'(\+?\(?\d{1,4}\)?[\s\-\.]*)?(\d{2,4}[\s\-\.]*){2,4}',
  );

  // Regex para URL más precisa (debe tener al menos un punto con dominio)
  final urlRegex = RegExp(
    r'\b((https?:\/\/)?([a-zA-Z0-9\-]+\.)+[a-zA-Z]{2,})(\/[^\s]*)?\b',
  );

  // Retornar si hay coincidencia válida
  return emailRegex.hasMatch(normalized) ||
      phoneRegex.hasMatch(normalized) ||
      urlRegex.hasMatch(normalized);
}

int stringToIngeter(String texto) {
  // convertir texto a entero
  return int.tryParse(texto) ??
      0; // Convert text to integer, return 0 if conversion fails
}

/// Porcentaje de lo que paga el cliente que recibe el talento.
const double porcentajeTalento = 0.72;

double calcularIngresoProveedor(double? monto) {
  // El talento recibe el 72% de lo que paga el cliente, sin más descuentos.
  //
  // Antes esto descontaba la comisión de Wompi (2,65% + $700) más su IVA y
  // entregaba el 75% del resto. Daba un 72,01% que variaba con el importe
  // ($71.937 sobre $99.900 en vez de $71.928) y, sobre todo, no es la regla
  // acordada: el 72% se aplica sobre el total que paga el cliente, incluida
  // la mano de obra adicional, que antes se sumaba entera.
  final m = monto ?? 0;
  if (m <= 0) return 0;
  return m * porcentajeTalento;
}

double calcularIngresoProveedorAgregado(
    double? totalBruto, double? cantidadTransacciones) {
  // Con un porcentaje plano ya no hace falta la cantidad de servicios (el
  // antiguo componente fijo de $700 se cobraba por transacción). El parámetro
  // se conserva porque lo pasan las pantallas generadas.
  final total = totalBruto ?? 0;
  if (total <= 0) return 0;
  return total * porcentajeTalento;
}

String formatPrices(double valor) {
  // Funcion que convierte un double ejemplo 10000 a 10,000 ejemplo 2000000.00   a 2,000,000
  final NumberFormat formatter = NumberFormat('#,##0.00', 'en_US');
  return formatter.format(valor);
}
