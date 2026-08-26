import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/servicio_asignado_error_widget.dart';
import '/components/servicio_asignado_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'aceptar_servicio_model.dart';
export 'aceptar_servicio_model.dart';

class AceptarServicioWidget extends StatefulWidget {
  const AceptarServicioWidget({
    super.key,
    required this.idservicio,
  });

  final String? idservicio;

  @override
  State<AceptarServicioWidget> createState() => _AceptarServicioWidgetState();
}

class _AceptarServicioWidgetState extends State<AceptarServicioWidget> {
  late AceptarServicioModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AceptarServicioModel());

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
                    'Aceptar servicio',
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
                      'Recuerda que al aceptar el servicio, también estás aceptando los términos y condiciones.\n\nEsta acción es definitiva y no se puede revertir.',
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
                      onPressed: () async {
                        var _shouldSetState = false;
                        _model.validacion =
                            await SolicitudesServicioTable().queryRows(
                          queryFn: (q) => q.eqOrNull(
                            'id',
                            widget!.idservicio,
                          ),
                        );
                        _shouldSetState = true;
                        if (_model.validacion?.firstOrNull?.profesionalId ==
                                null ||
                            _model.validacion?.firstOrNull?.profesionalId ==
                                '') {
                          await showDialog(
                            context: context,
                            builder: (dialogContext) {
                              return Dialog(
                                elevation: 0,
                                insetPadding: EdgeInsets.zero,
                                backgroundColor: Colors.transparent,
                                alignment: AlignmentDirectional(0.0, 0.0)
                                    .resolve(Directionality.of(context)),
                                child: ServicioAsignadoErrorWidget(),
                              );
                            },
                          );

                          if (_shouldSetState) safeSetState(() {});
                          return;
                        } else {
                          await SolicitudesServicioTable().update(
                            data: {
                              'profesional_id': currentUserUid,
                            },
                            matchingRows: (rows) => rows.eqOrNull(
                              'id',
                              widget!.idservicio,
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Update listo',
                                style: TextStyle(
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                              ),
                              duration: Duration(milliseconds: 2000),
                              backgroundColor:
                                  FlutterFlowTheme.of(context).secondary,
                            ),
                          );
                          _model.tarjeta =
                              await TarjetasGuardadasTable().queryRows(
                            queryFn: (q) => q.eqOrNull(
                              'usuario_id',
                              _model.validacion?.firstOrNull?.usuarioId,
                            ),
                          );
                          _shouldSetState = true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Tarjetas guardadas lista',
                                style: TextStyle(
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                              ),
                              duration: Duration(milliseconds: 2000),
                              backgroundColor:
                                  FlutterFlowTheme.of(context).secondary,
                            ),
                          );
                          _model.usuarioServicio =
                              await UsuariosTable().queryRows(
                            queryFn: (q) => q.eqOrNull(
                              'id',
                              _model.validacion?.firstOrNull?.usuarioId,
                            ),
                          );
                          _shouldSetState = true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Query usuarios listo',
                                style: TextStyle(
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                              ),
                              duration: Duration(milliseconds: 2000),
                              backgroundColor:
                                  FlutterFlowTheme.of(context).secondary,
                            ),
                          );
                          _model.aceptaceToken =
                              await actions.getAcceptanceToken(
                            FFDevEnvironmentValues().publicKey,
                            FFDevEnvironmentValues().isProduction,
                          );
                          _shouldSetState = true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Custom action 1 listo',
                                style: TextStyle(
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                              ),
                              duration: Duration(milliseconds: 2000),
                              backgroundColor:
                                  FlutterFlowTheme.of(context).secondary,
                            ),
                          );
                          if (getJsonField(
                            _model.aceptaceToken,
                            r'''$.success''',
                          )) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Succes listo',
                                  style: TextStyle(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                                ),
                                duration: Duration(milliseconds: 2000),
                                backgroundColor:
                                    FlutterFlowTheme.of(context).secondary,
                              ),
                            );
                            _model.pago = await actions.createTransaction(
                              FFDevEnvironmentValues().privateKey,
                              FFDevEnvironmentValues().publicKey,
                              functions.stringToIngeter(
                                  _model.tarjeta!.firstOrNull!.paymentSourceId),
                              getJsonField(
                                _model.aceptaceToken,
                                r'''$.acceptanceToken''',
                              ).toString(),
                              ((valueOrDefault<double>(
                                            _model.validacion?.firstOrNull
                                                ?.precio,
                                            0.0,
                                          ) +
                                          valueOrDefault<double>(
                                            _model.validacion?.firstOrNull
                                                ?.precioAdicionales,
                                            0.0,
                                          )) *
                                      100)
                                  .round(),
                              'COP',
                              _model.usuarioServicio!.firstOrNull!
                                  .correoElectronico!,
                              _model.validacion!.firstOrNull!.id,
                              FFDevEnvironmentValues().integrityKey,
                              true,
                            );
                            _shouldSetState = true;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Create transaction listo',
                                  style: TextStyle(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                                ),
                                duration: Duration(milliseconds: 2000),
                                backgroundColor:
                                    FlutterFlowTheme.of(context).secondary,
                              ),
                            );
                            if (getJsonField(
                              _model.pago,
                              r'''$.success''',
                            )) {
                              if ('APPROVED' ==
                                  getJsonField(
                                    _model.pago,
                                    r'''$.status''',
                                  ).toString()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'aprobado',
                                      style: TextStyle(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                      ),
                                    ),
                                    duration: Duration(milliseconds: 2000),
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).secondary,
                                  ),
                                );
                                await SolicitudesServicioTable().update(
                                  data: {
                                    'estado': 'aceptadas',
                                    'profesional_id': currentUserUid,
                                    'estado_pago': 'pagado',
                                  },
                                  matchingRows: (rows) => rows.eqOrNull(
                                    'id',
                                    widget!.idservicio,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'aprobado 1',
                                      style: TextStyle(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                      ),
                                    ),
                                    duration: Duration(milliseconds: 2000),
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).secondary,
                                  ),
                                );
                                await TransaccionesTable().insert({
                                  'numero_transaccion': getJsonField(
                                    _model.pago,
                                    r'''$.transactionId''',
                                  )?.toString(),
                                  'referencia_externa': getJsonField(
                                    _model.pago,
                                    r'''$.reference''',
                                  )?.toString(),
                                  // Lo que Wompi confirmo, no lo que calculo la app.
                                  // Sin esto no hay forma de auditar un cobro.
                                  'datos_pago': getJsonField(
                                    _model.pago,
                                    r'''$.fullData''',
                                  ),
                                  'solicitud_id':
                                      _model.validacion?.firstOrNull?.id,
                                  'usuario_id':
                                      _model.usuarioServicio?.firstOrNull?.id,
                                  'monto': valueOrDefault<double>(
                                        _model.validacion?.firstOrNull?.precio,
                                        0.0,
                                      ) +
                                      valueOrDefault<double>(
                                        _model.validacion?.firstOrNull
                                            ?.precioAdicionales,
                                        0.0,
                                      ),
                                  'moneda': 'COP',
                                  'proveedor_pago': 'WOMPI',
                                  'fecha_pago': supaSerialize<DateTime>(
                                      getCurrentTimestamp),
                                  'fecha_registro': supaSerialize<DateTime>(
                                      getCurrentTimestamp),
                                  'metodo_pago': 'Tarjeta',
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'aprobado 2',
                                      style: TextStyle(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                      ),
                                    ),
                                    duration: Duration(milliseconds: 2000),
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).secondary,
                                  ),
                                );
                                _model.apNotificacion =
                                    await SendNotificationUserHulpCall.call(
                                  userIdSupabase:
                                      _model.validacion?.firstOrNull?.usuarioId,
                                  title: 'Tu solicitud ha sido aceptada',
                                  message: 'Haz click aqui',
                                );

                                _shouldSetState = true;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'aprobado 3',
                                      style: TextStyle(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                      ),
                                    ),
                                    duration: Duration(milliseconds: 2000),
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).secondary,
                                  ),
                                );
                                Navigator.pop(context);
                                await showDialog(
                                  context: context,
                                  builder: (dialogContext) {
                                    return Dialog(
                                      elevation: 0,
                                      insetPadding: EdgeInsets.zero,
                                      backgroundColor: Colors.transparent,
                                      alignment: AlignmentDirectional(0.0, 0.0)
                                          .resolve(Directionality.of(context)),
                                      child: ServicioAsignadoWidget(),
                                    );
                                  },
                                );

                                if (_shouldSetState) safeSetState(() {});
                                return;
                              } else if ('DECLINED' ==
                                  getJsonField(
                                    _model.pago,
                                    r'''$.status''',
                                  ).toString()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'rechazado',
                                      style: TextStyle(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                      ),
                                    ),
                                    duration: Duration(milliseconds: 2000),
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).secondary,
                                  ),
                                );
                                await SolicitudesServicioTable().update(
                                  data: {
                                    'profesional_id': '',
                                  },
                                  matchingRows: (rows) => rows.eqOrNull(
                                    'id',
                                    widget!.idservicio,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'pago rechazado',
                                      style: TextStyle(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                      ),
                                    ),
                                    duration: Duration(milliseconds: 4000),
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).secondary,
                                  ),
                                );
                                if (_shouldSetState) safeSetState(() {});
                                return;
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'no es aprobado',
                                      style: TextStyle(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                      ),
                                    ),
                                    duration: Duration(milliseconds: 2000),
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).secondary,
                                  ),
                                );
                                await SolicitudesServicioTable().update(
                                  data: {
                                    'profesional_id': '',
                                  },
                                  matchingRows: (rows) => rows.eqOrNull(
                                    'id',
                                    widget!.idservicio,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'pago no es aprobado',
                                      style: TextStyle(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                      ),
                                    ),
                                    duration: Duration(milliseconds: 4000),
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).secondary,
                                  ),
                                );
                                if (_shouldSetState) safeSetState(() {});
                                return;
                              }
                            } else {
                              await SolicitudesServicioTable().update(
                                data: {
                                  'profesional_id': '',
                                },
                                matchingRows: (rows) => rows.eqOrNull(
                                  'id',
                                  widget!.idservicio,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'pago fallido',
                                    style: TextStyle(
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                    ),
                                  ),
                                  duration: Duration(milliseconds: 4000),
                                  backgroundColor:
                                      FlutterFlowTheme.of(context).secondary,
                                ),
                              );
                              if (_shouldSetState) safeSetState(() {});
                              return;
                            }
                          } else {
                            await SolicitudesServicioTable().update(
                              data: {
                                'profesional_id': '',
                              },
                              matchingRows: (rows) => rows.eqOrNull(
                                'id',
                                widget!.idservicio,
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error Aceptace Token',
                                  style: TextStyle(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                                ),
                                duration: Duration(milliseconds: 4000),
                                backgroundColor:
                                    FlutterFlowTheme.of(context).secondary,
                              ),
                            );
                            if (_shouldSetState) safeSetState(() {});
                            return;
                          }
                        }

                        if (_shouldSetState) safeSetState(() {});
                      },
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
