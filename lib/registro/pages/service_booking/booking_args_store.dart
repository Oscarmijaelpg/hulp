// Almacén temporal de args entre páginas de booking.
// Evita pasar objetos Dart vía GoRouter extra (incompatible con FFParameters
// que castea extra a Map<String, dynamic>).

import '/backend/supabase/database/tables/servicios.dart';

// ── Servicio pendiente (detalles → formulario) ────────────────────────────────

class ServiceStore {
  ServiceStore._();

  static ServiciosRow? _pending;

  /// Llamar antes de navegar a ServiceBookingFormPage.
  static void set(ServiciosRow servicio) => _pending = servicio;

  /// Si hay un servicio esperando. Se consulta sin consumirlo: al terminar el
  /// login hay que saber si el usuario venía de darle a «Agendar» para
  /// devolverlo ahí en vez de soltarlo en la portada, y el formulario lo
  /// consumirá después.
  static bool get hayPendiente => _pending != null;

  /// Para cuando se abandona el flujo y el servicio ya no debe reaparecer.
  static void limpiar() => _pending = null;

  /// Leer y limpiar en ServiceBookingFormPage.initState().
  static ServiciosRow? consume() {
    final v = _pending;
    _pending = null;
    return v;
  }
}

// ── Args de éxito (formulario → pantalla de confirmación) ─────────────────────

class BookingArgsStore {
  BookingArgsStore._();

  static BookingSuccessArgsData? _pending;

  /// Guardar antes de navegar a BookingSuccessPage.
  static void set(BookingSuccessArgsData args) => _pending = args;

  /// Leer y limpiar desde BookingSuccessPage.
  static BookingSuccessArgsData? consume() {
    final v = _pending;
    _pending = null;
    return v;
  }
}

class BookingSuccessArgsData {
  const BookingSuccessArgsData({
    required this.solicitudId,
    required this.serviceName,
    required this.serviceDesc,
    required this.servicePrice,
    required this.serviceImage,
    required this.fecha,
    required this.hora,
    required this.ciudad,
    required this.direccion,
    this.complemento,
  });

  final String solicitudId;
  final String serviceName;
  final String serviceDesc;
  final String servicePrice;
  final String serviceImage;
  final DateTime fecha;
  final String hora;
  final String ciudad;
  final String direccion;
  final String? complemento;
}

/// Marca que el usuario salió del agendamiento a dar de alta un método de pago.
///
/// La pantalla de pago está tres niveles por debajo del formulario
/// (agendamiento → métodos de pago → mis tarjetas → pago), así que al guardar
/// la tarjeta un solo «atrás» dejaba al usuario a medio camino, lejos de la
/// solicitud que estaba creando. Con esta marca la pantalla de pago sabe que
/// tiene que devolverlo al formulario de una vez.
///
/// Si llega a métodos de pago desde el menú, la marca está apagada y el
/// comportamiento es el de siempre: se queda viendo sus tarjetas.
class FlujoMetodoPago {
  FlujoMetodoPago._();

  static bool desdeAgendamiento = false;
}
