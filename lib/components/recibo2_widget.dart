import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recibo2_model.dart';
export 'recibo2_model.dart';

/// Un componente que muestra un titulo, una lista de articulos que tienen un
/// icono, un nombre, una cantidad, un precio por unidad, un precio total, y
/// abajo de todo un precio total de todo, y tambien un boton que diga, pagar.
class Recibo2Widget extends StatefulWidget {
  const Recibo2Widget({
    super.key,
    required this.recibo,
  });

  final RecibosRow? recibo;

  @override
  State<Recibo2Widget> createState() => _Recibo2WidgetState();
}

class _Recibo2WidgetState extends State<Recibo2Widget> {
  late Recibo2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Recibo2Model());

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
            maxWidth: 470.0,
          ),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            boxShadow: [
              BoxShadow(
                blurRadius: 20.0,
                color: Color(0x33000000),
                offset: Offset(
                  0.0,
                  -5.0,
                ),
                spreadRadius: 0.0,
              )
            ],
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 8.0),
                      child: Text(
                        'Metodos de pago',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () async {
                    var _shouldSetState = false;
                    _model.tarjeta = await TarjetasGuardadasTable().queryRows(
                      queryFn: (q) => q.eqOrNull(
                        'usuario_id',
                        currentUserUid,
                      ),
                    );
                    _shouldSetState = true;
                    // Resolver el método de pago: tarjeta activa o, si no hay,
                    // un método alternativo activo (Nequi/Daviplata/Bancolombia).
                    int? psId;
                    String metodoLabel = 'Tarjeta';
                    final tarjetaActiva = _model.tarjeta
                        ?.where((t) => t.activa == true)
                        .firstOrNull;
                    if (tarjetaActiva != null) {
                      psId = functions
                          .stringToIngeter(tarjetaActiva.paymentSourceId);
                    } else {
                      final metodos = await MetodosPagoTable().queryRows(
                        queryFn: (q) =>
                            q.eqOrNull('usuario_id', currentUserUid),
                      );
                      final metodo = metodos
                          .where((m) =>
                              m.estado.toLowerCase() == 'activo' ||
                              m.estado.toLowerCase() == 'active')
                          .firstOrNull;
                      if (metodo != null) {
                        psId = metodo.paymentSourceId;
                        metodoLabel = metodo.tipo;
                      }
                    }
                    if (psId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'No tienes un método de pago disponible. Agrega uno para pagar.',
                            style: TextStyle(
                              color: FlutterFlowTheme.of(context).primaryText,
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
                    _model.aceptaceToken = await actions.getAcceptanceToken(
                      FFDevEnvironmentValues().publicKey,
                      FFDevEnvironmentValues().isProduction,
                    );
                    _shouldSetState = true;
                    if (getJsonField(
                      _model.aceptaceToken,
                      r'''$.success''',
                    )) {
                      _model.pago = await actions.createTransaction(
                        FFDevEnvironmentValues().privateKey,
                        FFDevEnvironmentValues().publicKey,
                        psId,
                        getJsonField(
                          _model.aceptaceToken,
                          r'''$.acceptanceToken''',
                        ).toString(),
                        (widget.recibo!.total * 100).round(),
                        'COP',
                        currentUserEmail,
                        widget.recibo!.id,
                        FFDevEnvironmentValues().integrityKey,
                        FFDevEnvironmentValues().isProduction,
                      );
                      _shouldSetState = true;
                      if (getJsonField(
                        _model.pago,
                        r'''$.success''',
                      )) {
                        if ('APPROVED' ==
                            getJsonField(
                              _model.pago,
                              r'''$.status''',
                            ).toString()) {
                          await TransaccionesTable().insert({
                            'usuario_id': currentUserUid,
                            'monto': widget.recibo?.total,
                            'moneda': 'COP',
                            'proveedor_pago': 'WOMPI',
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
                            'fecha_pago':
                                supaSerialize<DateTime>(getCurrentTimestamp),
                            'fecha_registro':
                                supaSerialize<DateTime>(getCurrentTimestamp),
                            'metodo_pago': metodoLabel,
                            'solicitud_id': widget.recibo?.solicitudId,
                          });
                          await RecibosTable().update(
                            data: {
                              'estado': 'aceptado',
                            },
                            matchingRows: (rows) => rows.eqOrNull(
                              'id',
                              widget.recibo?.id,
                            ),
                          );
                          Navigator.pop(context);
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
                                'pago rechazado',
                                style: TextStyle(
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
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
                                'pago no es aprobado',
                                style: TextStyle(
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'pago fallido',
                              style: TextStyle(
                                color: FlutterFlowTheme.of(context).primaryText,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error Aceptace Token',
                            style: TextStyle(
                              color: FlutterFlowTheme.of(context).primaryText,
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

                    if (_shouldSetState) safeSetState(() {});
                  },
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: 60.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(
                            Icons.credit_card,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24.0,
                          ),
                          Expanded(
                            child: Text(
                              'Credito o debito (Con CVV)',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
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
                          Icon(
                            Icons.chevron_right,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24.0,
                          ),
                        ].divide(SizedBox(width: 4.0)),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () async {
                    var _shouldSetState = false;
                    _model.aceptaceToken1 = await actions.getAcceptanceToken(
                      FFDevEnvironmentValues().publicKey,
                      FFDevEnvironmentValues().isProduction,
                    );
                    _shouldSetState = true;
                    if (getJsonField(
                      _model.aceptaceToken,
                      r'''$.success''',
                    )) {
                      _model.pago1 =
                          await actions.createBancolombiaTransferTransaction(
                        FFDevEnvironmentValues().privateKey,
                        // Aqui va el token de aceptacion, que es el que se
                        // acaba de pedir arriba. Estaba pasandose el importe
                        // convertido a texto, asi que Wompi rechazaba el pago.
                        getJsonField(
                          _model.aceptaceToken,
                          r'''$.acceptanceToken''',
                        ).toString(),
                        (widget.recibo!.total * 100).round(),
                        'COP',
                        currentUserEmail,
                        widget.recibo!.id,
                        FFDevEnvironmentValues().isProduction,
                      );
                      _shouldSetState = true;
                      if (getJsonField(
                        _model.pago1,
                        r'''$.success''',
                      )) {
                        // Este es el flujo de Bancolombia, cuya respuesta esta
                        // en pago1. Se miraba el estado de `pago`, que es la
                        // del pago con tarjeta: si el cliente no habia pasado
                        // antes por ahi venia nulo y no se registraba nada.
                        if ('APPROVED' ==
                            getJsonField(
                              _model.pago1,
                              r'''$.status''',
                            ).toString()) {
                          await TransaccionesTable().insert({
                            'usuario_id': currentUserUid,
                            'monto': widget.recibo?.total,
                            'moneda': 'COP',
                            'proveedor_pago': 'WOMPI',
                            'numero_transaccion': getJsonField(
                              _model.pago1,
                              r'''$.transactionId''',
                            )?.toString(),
                            'referencia_externa': getJsonField(
                              _model.pago1,
                              r'''$.reference''',
                            )?.toString(),
                            // Lo que Wompi confirmo, no lo que calculo la app.
                            // Sin esto no hay forma de auditar un cobro.
                            'datos_pago': getJsonField(
                              _model.pago1,
                              r'''$.fullData''',
                            ),
                            'fecha_pago':
                                supaSerialize<DateTime>(getCurrentTimestamp),
                            'fecha_registro':
                                supaSerialize<DateTime>(getCurrentTimestamp),
                            'metodo_pago': 'Bancolombia',
                            'solicitud_id': widget.recibo?.solicitudId,
                          });
                          await RecibosTable().update(
                            data: {
                              'estado': 'aceptado',
                            },
                            matchingRows: (rows) => rows.eqOrNull(
                              'id',
                              widget.recibo?.id,
                            ),
                          );
                          Navigator.pop(context);
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
                                'pago rechazado',
                                style: TextStyle(
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
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
                                'pago no es aprobado',
                                style: TextStyle(
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'pago fallido',
                              style: TextStyle(
                                color: FlutterFlowTheme.of(context).primaryText,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error Aceptace Token',
                            style: TextStyle(
                              color: FlutterFlowTheme.of(context).primaryText,
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

                    if (_shouldSetState) safeSetState(() {});
                  },
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: 60.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(
                            Icons.business,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24.0,
                          ),
                          Expanded(
                            child: Text(
                              'Bancolombia',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
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
                          Icon(
                            Icons.chevron_right,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24.0,
                          ),
                        ].divide(SizedBox(width: 4.0)),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.sizeOf(context).width * 1.0,
                  height: 60.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Icon(
                          Icons.attach_money,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 24.0,
                        ),
                        Expanded(
                          child: Text(
                            'Nequi',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
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
                        Icon(
                          Icons.chevron_right,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 24.0,
                        ),
                      ].divide(SizedBox(width: 4.0)),
                    ),
                  ),
                ),
              ].divide(SizedBox(height: 8.0)),
            ),
          ),
        ),
      ),
    );
  }
}
