import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'finalizar_servicio_model.dart';
export 'finalizar_servicio_model.dart';

class FinalizarServicioWidget extends StatefulWidget {
  const FinalizarServicioWidget({
    super.key,
    required this.idservicio,
  });

  final String? idservicio;

  @override
  State<FinalizarServicioWidget> createState() =>
      _FinalizarServicioWidgetState();
}

class _FinalizarServicioWidgetState extends State<FinalizarServicioWidget> {
  late FinalizarServicioModel _model;

  bool _finalizando = false;

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _finalizarServicio() async {
    if (_finalizando) return;
    if (widget.idservicio == null || widget.idservicio!.isEmpty) {
      _avisar('No se encontró la solicitud.');
      return;
    }
    setState(() => _finalizando = true);
    try {
      final solicitudes = await SolicitudesServicioTable().queryRows(
        queryFn: (q) => q.eqOrNull('id', widget.idservicio),
      );
      final solicitud = solicitudes.firstOrNull;
      if (solicitud == null || solicitud.profesionalId != currentUserUid) {
        _avisar('La solicitud no existe o ya no está asignada a ti.');
        return;
      }
      final finalizadas = await SolicitudesServicioTable().update(
        data: {'estado': 'finalizadas'},
        matchingRows: (rows) => rows
            .eqOrNull('id', solicitud.id)
            .eqOrNull('profesional_id', currentUserUid),
        returnRows: true,
      );
      if (finalizadas.isEmpty) {
        _avisar('La solicitud ya no está asignada a ti. No se realizó un cobro.');
        return;
      }
      final resultado = await _cobrarAlFinalizar(solicitud);
      try {
        await SendNotificationUserHulpCall.call(
          userIdSupabase: solicitud.usuarioId,
          title: 'Tu solicitud ha sido finalizada',
          message: 'Haz click aqui',
        );
      } catch (_) {
        // La notificación no revierte la finalización ni el pago.
      }
      if (!mounted) return;
      _avisar(resultado.isEmpty
          ? 'Servicio finalizado.'
          : 'Servicio finalizado. $resultado');
      Navigator.pop(context);
    } catch (e) {
      _avisar('No se pudo finalizar el servicio: $e');
    } finally {
      if (mounted) setState(() => _finalizando = false);
    }
  }

  String _mensajeErrorPago(dynamic respuesta, String alternativa) {
    if (respuesta is! Map) return alternativa;
    for (final valor in [
      respuesta['error'],
      respuesta['statusMessage'],
      respuesta['message']
    ]) {
      if (valor is String && valor.trim().isNotEmpty) return valor.trim();
    }
    return alternativa;
  }

  Future<String> _cobrarAlFinalizar(SolicitudesServicioRow solicitud) async {
    // Una solicitud pagada solo necesita el cierre operativo.
    if (solicitud.estadoPago == 'pagado') {
      return '';
    }

    var aprobado = false;
    try {
      final metodos = await MetodosPagoTable().queryRows(
        queryFn: (q) => q
            .eqOrNull('usuario_id', solicitud.usuarioId)
            .eqOrNull('es_predeterminado', true),
      );
      int fuente;
      String metodo;
      if (metodos.isNotEmpty) {
        fuente = metodos.first.paymentSourceId;
        metodo = metodos.first.tipo;
      } else {
        final tarjetas = await TarjetasGuardadasTable().queryRows(
          queryFn: (q) => q.eqOrNull('usuario_id', solicitud.usuarioId),
        );
        if (tarjetas.isEmpty) {
          return 'No se realizó un cobro: el cliente no tiene método de pago. '
              'Se conservó el estado del pago.';
        }
        fuente = int.tryParse(tarjetas.first.paymentSourceId) ?? 0;
        metodo = 'CARD';
      }
      if (fuente <= 0) {
        return 'No se realizó un cobro: el método de pago no es válido. '
            'Se conservó el estado del pago.';
      }
      final tokens = await actions.getAcceptanceToken(
        FFDevEnvironmentValues().publicKey,
        FFDevEnvironmentValues().isProduction,
      );
      if (tokens is! Map || tokens['success'] != true) {
        return 'Pago sin confirmar. ${_mensajeErrorPago(tokens, 'No se pudieron obtener los tokens de pago.')}';
      }
      final pago = await actions.createTransaction(
        FFDevEnvironmentValues().privateKey,
        FFDevEnvironmentValues().publicKey,
        fuente,
        tokens['acceptanceToken']?.toString() ?? '',
        (((solicitud.precioBase ?? solicitud.precio) +
                    (solicitud.precioAdicionales ?? 0)) *
                100)
            .round(),
        'COP',
        '', // El backend obtiene el correo del cliente.
        '${solicitud.id}-${DateTime.now().millisecondsSinceEpoch}',
        FFDevEnvironmentValues().integrityKey,
        FFDevEnvironmentValues().isProduction,
        personalDataAuthToken:
            tokens['personalDataAuthToken']?.toString() ?? '',
      );
      if (pago is! Map ||
          pago['success'] != true ||
          pago['status'] != 'APPROVED') {
        return 'Pago sin confirmar. ${_mensajeErrorPago(pago, 'El cobro no fue aprobado.')}';
      }
      aprobado = true;
      await TransaccionesTable().insert({
        'solicitud_id': solicitud.id,
        'usuario_id': solicitud.usuarioId,
        'monto': (pago['amount'] as num) / 100,
        'moneda': 'COP',
        'proveedor_pago': 'WOMPI',
        'metodo_pago': metodo,
        'numero_transaccion': pago['transactionId']?.toString(),
        'referencia_externa': pago['reference']?.toString(),
        'datos_pago': pago['fullData'],
        'fecha_pago': supaSerialize<DateTime>(getCurrentTimestamp),
        'fecha_registro': supaSerialize<DateTime>(getCurrentTimestamp),
      });
      await SolicitudesServicioTable().update(
        data: {'estado_pago': 'pagado'},
        matchingRows: (rows) => rows.eqOrNull('id', solicitud.id),
      );
      return 'Pago aprobado y registrado.';
    } catch (e) {
      if (aprobado) {
        return 'Wompi aprobó el cobro, pero no se pudo completar su registro: $e. '
            'Verifica el pago antes de intentar otro cobro.';
      }
      return 'Pago sin confirmar: $e';
    }
  }

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FinalizarServicioModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 540.0,
          ),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16.0, 24.0, 16.0, 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Opacity(
                      opacity: 0.0,
                      child: Icon(
                        Icons.arrow_back,
                        color: FlutterFlowTheme.of(context).primaryText,
                        size: 24.0,
                      ),
                    ),
                    Text(
                      'Proveedores',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            fontSize: 22.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        Icons.close,
                        color: FlutterFlowTheme.of(context).primaryText,
                        size: 24.0,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
                  child: Image.asset(
                    'assets/images/Iconos_de_estado.png',
                    width: 80.0,
                    height: 80.0,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
                  child: Text(
                    'Finalizar servicio',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          fontSize: 18.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(10.0, 16.0, 10.0, 0.0),
                    child: Text(
                      'Recuerda que al finalizar el servicio, también estás aceptando los términos y condiciones.\n\nEsta acción es definitiva y no se puede revertir.',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 16.0,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                  ),
                ),
                Builder(
                  builder: (context) => Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
                    child: FFButtonWidget(
                      onPressed: _finalizando ? null : _finalizarServicio,
                      text: 'Aceptar',
                      options: FFButtonOptions(
                        height: 40.0,
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
