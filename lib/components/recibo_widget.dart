import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recibo_model.dart';
export 'recibo_model.dart';

/// Un componente que muestra un titulo, una lista de articulos que tienen un
/// icono, un nombre, una cantidad, un precio por unidad, un precio total, y
/// abajo de todo un precio total de todo, y tambien un boton que diga, pagar.
class ReciboWidget extends StatefulWidget {
  const ReciboWidget({
    super.key,
    required this.recibo,
  });

  final RecibosRow? recibo;

  @override
  State<ReciboWidget> createState() => _ReciboWidgetState();
}

class _ReciboWidgetState extends State<ReciboWidget> {
  late ReciboModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReciboModel());

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
            color: Color(0xFFEFF3ED),
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
          child: Builder(
            builder: (context) {
              if (widget.recibo?.estado == 'pendiente') {
                return Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  12.0, 0.0, 12.0, 0.0),
                              child: Text(
                                valueOrDefault<String>(
                                  widget.recibo?.titulo,
                                  'Nuevo recibo',
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .override(
                                      font: GoogleFonts.interTight(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .fontStyle,
                                      ),
                                      fontSize: 14.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .headlineMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineMedium
                                          .fontStyle,
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
                        padding: EdgeInsetsDirectional.fromSTEB(
                            12.0, 0.0, 12.0, 0.0),
                        child: FutureBuilder<List<ReciboItemsRow>>(
                          future: ReciboItemsTable().queryRows(
                            queryFn: (q) => q.eqOrNull(
                              'recibo_id',
                              widget.recibo?.id,
                            ),
                          ),
                          builder: (context, snapshot) {
                            // Customize what your widget looks like when it's loading.
                            if (!snapshot.hasData) {
                              return Center(
                                child: SizedBox(
                                  width: 50.0,
                                  height: 50.0,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      FlutterFlowTheme.of(context).primary,
                                    ),
                                  ),
                                ),
                              );
                            }
                            List<ReciboItemsRow> columnReciboItemsRowList =
                                snapshot.data!;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children:
                                  List.generate(columnReciboItemsRowList.length,
                                      (columnIndex) {
                                final columnReciboItemsRow =
                                    columnReciboItemsRowList[columnIndex];
                                return Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      12.0, 0.0, 12.0, 0.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Container(
                                              width: 40.0,
                                              height: 40.0,
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .alternate,
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              child: Icon(
                                                Icons.shopping_cart,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                size: 20.0,
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    valueOrDefault<String>(
                                                      columnReciboItemsRow
                                                          .descripcion,
                                                      'Sin descripción',
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Text(
                                                        valueOrDefault<String>(
                                                          columnReciboItemsRow
                                                              .cantidad
                                                              .toString(),
                                                          '0',
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                      Text(
                                                        valueOrDefault<String>(
                                                          columnReciboItemsRow
                                                              .precioUnitario
                                                              .toString(),
                                                          '0',
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(width: 8.0)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ].divide(SizedBox(width: 12.0)),
                                        ),
                                      ),
                                      Text(
                                        valueOrDefault<String>(
                                          columnReciboItemsRow.total
                                              ?.toString(),
                                          '0',
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              font: GoogleFonts.interTight(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontStyle,
                                            ),
                                      ),
                                    ].divide(SizedBox(width: 12.0)),
                                  ),
                                );
                              }).divide(SizedBox(height: 16.0)),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            12.0, 0.0, 12.0, 0.0),
                        child: Container(
                          width: double.infinity,
                          height: 2.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            12.0, 0.0, 12.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontStyle,
                                    ),
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontStyle,
                                  ),
                            ),
                            Text(
                              valueOrDefault<String>(
                                formatNumber(
                                  widget.recibo?.total,
                                  formatType: FormatType.custom,
                                  currency: '\$',
                                  format: '',
                                  locale: '',
                                ),
                                '\$0',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).primary,
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontStyle,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            12.0, 0.0, 12.0, 0.0),
                        child: FFButtonWidget(
                          onPressed: (widget.recibo?.estado == 'aceptado')
                              ? null
                              : () async {
                                  var _shouldSetState = false;
                                  _model.tarjeta1 =
                                      await TarjetasGuardadasTable().queryRows(
                                    queryFn: (q) => q.eqOrNull(
                                      'usuario_id',
                                      currentUserUid,
                                    ),
                                  );
                                  _shouldSetState = true;
                                  // Resolver el método de pago: tarjeta activa o,
                                  // si no hay, un método alternativo activo.
                                  int? psId;
                                  String metodoLabel = 'Tarjeta';
                                  final tarjetaActiva = _model.tarjeta1
                                      ?.where((t) => t.activa == true)
                                      .firstOrNull;
                                  if (tarjetaActiva != null) {
                                    psId = functions.stringToIngeter(
                                        tarjetaActiva.paymentSourceId);
                                  } else {
                                    final metodos =
                                        await MetodosPagoTable().queryRows(
                                      queryFn: (q) => q.eqOrNull(
                                          'usuario_id', currentUserUid),
                                    );
                                    final metodo = metodos
                                        .where((m) =>
                                            m.estado.toLowerCase() ==
                                                'activo' ||
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
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                          ),
                                        ),
                                        duration: Duration(milliseconds: 4000),
                                        backgroundColor:
                                            FlutterFlowTheme.of(context)
                                                .secondary,
                                      ),
                                    );
                                    if (_shouldSetState) safeSetState(() {});
                                    return;
                                  }
                                  _model.aceptaceToken2 =
                                      await actions.getAcceptanceToken(
                                    FFDevEnvironmentValues().publicKey,
                                    FFDevEnvironmentValues().isProduction,
                                  );
                                  _shouldSetState = true;
                                  if (getJsonField(
                                    _model.aceptaceToken2,
                                    r'''$.success''',
                                  )) {
                                    _model.pago2 =
                                        await actions.createTransaction(
                                      FFDevEnvironmentValues().privateKey,
                                      FFDevEnvironmentValues().publicKey,
                                      psId,
                                      getJsonField(
                                        _model.aceptaceToken2,
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
                                      _model.pago2,
                                      r'''$.success''',
                                    )) {
                                      if ('APPROVED' ==
                                          getJsonField(
                                            _model.pago2,
                                            r'''$.status''',
                                          ).toString()) {
                                        await TransaccionesTable().insert({
                                          'usuario_id': currentUserUid,
                                          'monto': widget.recibo?.total,
                                          'moneda': 'COP',
                                          'proveedor_pago': 'WOMPI',
                                          'numero_transaccion': getJsonField(
                                            _model.pago2,
                                            r'''$.transactionId''',
                                          )?.toString(),
                                          'referencia_externa': getJsonField(
                                            _model.pago2,
                                            r'''$.reference''',
                                          )?.toString(),
                                          // Lo que Wompi confirmo, no lo que
                                          // calculo la app. Sin esto no hay
                                          // forma de auditar un cobro.
                                          'datos_pago': getJsonField(
                                            _model.pago2,
                                            r'''$.fullData''',
                                          ),
                                          'fecha_pago': supaSerialize<DateTime>(
                                              getCurrentTimestamp),
                                          'fecha_registro':
                                              supaSerialize<DateTime>(
                                                  getCurrentTimestamp),
                                          'metodo_pago': metodoLabel,
                                          'solicitud_id':
                                              widget.recibo?.solicitudId,
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
                                        if (_shouldSetState)
                                          safeSetState(() {});
                                        return;
                                      } else if ('DECLINED' ==
                                          getJsonField(
                                            _model.pago2,
                                            r'''$.status''',
                                          ).toString()) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'pago rechazado',
                                              style: TextStyle(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                              ),
                                            ),
                                            duration:
                                                Duration(milliseconds: 4000),
                                            backgroundColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondary,
                                          ),
                                        );
                                        if (_shouldSetState)
                                          safeSetState(() {});
                                        return;
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'pago no es aprobado',
                                              style: TextStyle(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                              ),
                                            ),
                                            duration:
                                                Duration(milliseconds: 4000),
                                            backgroundColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondary,
                                          ),
                                        );
                                        if (_shouldSetState)
                                          safeSetState(() {});
                                        return;
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'pago fallido',
                                            style: TextStyle(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                            ),
                                          ),
                                          duration:
                                              Duration(milliseconds: 4000),
                                          backgroundColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondary,
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
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                          ),
                                        ),
                                        duration: Duration(milliseconds: 4000),
                                        backgroundColor:
                                            FlutterFlowTheme.of(context)
                                                .secondary,
                                      ),
                                    );
                                    if (_shouldSetState) safeSetState(() {});
                                    return;
                                  }

                                  if (_shouldSetState) safeSetState(() {});
                                },
                          text: 'Aprobar',
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 50.0,
                            padding: EdgeInsets.all(8.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context).info,
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                            elevation: 0.0,
                            borderSide: BorderSide(
                              color: Colors.transparent,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(20.0),
                            disabledColor: FlutterFlowTheme.of(context).primary,
                          ),
                        ),
                      ),
                    ].divide(SizedBox(height: 16.0)),
                  ),
                );
              } else {
                return Container(
                  width: MediaQuery.sizeOf(context).width * 1.0,
                  decoration: BoxDecoration(),
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Recibo pagado correctamente',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    fontSize: 18.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                        FFButtonWidget(
                          onPressed: () async {
                            Navigator.pop(context);
                          },
                          text: 'Volver',
                          options: FFButtonOptions(
                            height: 40.0,
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 0.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                            elevation: 0.0,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ].divide(SizedBox(height: 12.0)),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
