import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/components/cancelar_servicio_widget.dart';
import '/components/enlace_mapa_widget.dart';
import '/components/finalizar_servicio_widget.dart';
import '/components/lista_vacia_widget.dart';
import '/components/men_widget.dart';
import '/components/nueva_version_widget.dart';
import '/components/servicio_asignado_inicio_widget.dart';
import '/components/soporte_seleccion_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:async';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'solicitudes_model.dart';
export 'solicitudes_model.dart';

class SolicitudesWidget extends StatefulWidget {
  const SolicitudesWidget({super.key});

  static String routeName = 'Solicitudes';
  static String routePath = '/solicitudes';

  @override
  State<SolicitudesWidget> createState() => _SolicitudesWidgetState();
}

class _SolicitudesWidgetState extends State<SolicitudesWidget> {
  late SolicitudesModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SolicitudesModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.notificacionActiva = await actions.areNotificationsEnabled();
      _model.notificationEnabled = _model.notificacionActiva!;
      safeSetState(() {});
      if (FFDevEnvironmentValues().isProduction) {
        _model.versionDb2 = await AppVersionTable().queryRows(
          queryFn: (q) => q,
        );
        _model.appVersion2 = await actions.getVersion();
        if (isAndroid == true) {
          if (_model.appVersion2 !=
              _model.versionDb2?.firstOrNull?.versionProveedores) {
            await showDialog(
              context: context,
              builder: (dialogContext) {
                return Dialog(
                  elevation: 0,
                  insetPadding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  alignment: AlignmentDirectional(0.0, 0.0)
                      .resolve(Directionality.of(context)),
                  child: GestureDetector(
                    onTap: () {
                      FocusScope.of(dialogContext).unfocus();
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    child: NuevaVersionWidget(),
                  ),
                );
              },
            );
          }
        } else {
          if (_model.versionDb2?.firstOrNull?.testFlight != true) {
            if (_model.appVersion2 ==
                _model.versionDb2?.firstOrNull?.versionProveedoresIos) {
              return;
            }

            await showDialog(
              context: context,
              builder: (dialogContext) {
                return Dialog(
                  elevation: 0,
                  insetPadding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  alignment: AlignmentDirectional(0.0, 0.0)
                      .resolve(Directionality.of(context)),
                  child: GestureDetector(
                    onTap: () {
                      FocusScope.of(dialogContext).unfocus();
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    child: NuevaVersionWidget(),
                  ),
                );
              },
            );

            return;
          }
        }
      }
    });

    _model.aceptadasExpandableController =
        ExpandableController(initialExpanded: true)
          ..addListener(() => safeSetState(() {}));
    _model.finalizadasExpandableController =
        ExpandableController(initialExpanded: true)
          ..addListener(() => safeSetState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: PopScope(
          canPop: false,
          child: Scaffold(
            key: scaffoldKey,
            body: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: StreamBuilder<List<AppVersionRow>>(
                    stream: _model.containerSupabaseStream1 ??= SupaFlow.client
                        .from("AppVersion")
                        .stream(primaryKey: ['id']).map((list) =>
                            list.map((item) => AppVersionRow(item)).toList()),
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
                      List<AppVersionRow> containerAppVersionRowList =
                          snapshot.data!;

                      final containerAppVersionRow =
                          containerAppVersionRowList.isNotEmpty
                              ? containerAppVersionRowList.first
                              : null;

                      return Container(
                        decoration: BoxDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child:
                                  FutureBuilder<List<ProfesionalServiciosRow>>(
                                future: ProfesionalServiciosTable().queryRows(
                                  queryFn: (q) => q.eqOrNull(
                                    'usuario_id',
                                    currentUserUid,
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            FlutterFlowTheme.of(context)
                                                .primary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  List<ProfesionalServiciosRow>
                                      containerProfesionalServiciosRowList =
                                      snapshot.data!;

                                  return Container(
                                    decoration: BoxDecoration(),
                                    child: StreamBuilder<
                                        List<SolicitudesServicioRow>>(
                                      stream: _model
                                              .containerSupabaseStream2 ??=
                                          SupaFlow.client
                                              .from("solicitudes_servicio")
                                              .stream(primaryKey: ['id'])
                                              .eqOrNull(
                                                'profesional_id',
                                                currentUserUid,
                                              )
                                              .map((list) => list
                                                  .map((item) =>
                                                      SolicitudesServicioRow(
                                                          item))
                                                  .toList()),
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        List<SolicitudesServicioRow>
                                            containerSolicitudesServicioRowList =
                                            snapshot.data!;

                                        return Container(
                                          decoration: BoxDecoration(),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                StreamBuilder<
                                                    List<UsuariosRow>>(
                                                  stream: _model
                                                          .containerSupabaseStream3 ??=
                                                      SupaFlow.client
                                                          .from("usuarios")
                                                          .stream(primaryKey: [
                                                            'id'
                                                          ])
                                                          .eqOrNull(
                                                            'id',
                                                            currentUserUid,
                                                          )
                                                          .map((list) => list
                                                              .map((item) =>
                                                                  UsuariosRow(
                                                                      item))
                                                              .toList()),
                                                  builder: (context, snapshot) {
                                                    // Customize what your widget looks like when it's loading.
                                                    if (!snapshot.hasData) {
                                                      return Center(
                                                        child: SizedBox(
                                                          width: 50.0,
                                                          height: 50.0,
                                                          child:
                                                              CircularProgressIndicator(
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                    Color>(
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .primary,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                    List<UsuariosRow>
                                                        containerUsuariosRowList =
                                                        snapshot.data!;

                                                    final containerUsuariosRow =
                                                        containerUsuariosRowList
                                                                .isNotEmpty
                                                            ? containerUsuariosRowList
                                                                .first
                                                            : null;

                                                    return Container(
                                                      decoration:
                                                          BoxDecoration(),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        16.0,
                                                                        36.0,
                                                                        16.0,
                                                                        16.0),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Image.asset(
                                                                  'assets/images/28.png',
                                                                  width: 100.0,
                                                                  height: 36.0,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      children: [
                                                                        Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            if (_model.notificationEnabled ==
                                                                                false)
                                                                              InkWell(
                                                                                splashColor: Colors.transparent,
                                                                                focusColor: Colors.transparent,
                                                                                hoverColor: Colors.transparent,
                                                                                highlightColor: Colors.transparent,
                                                                                onTap: () async {
                                                                                  await actions.assignUserTags(
                                                                                    currentUserUid,
                                                                                  );
                                                                                  _model.notificationEnabled = true;
                                                                                  safeSetState(() {});
                                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                                    SnackBar(
                                                                                      content: Text(
                                                                                        'Notificaciones activadas, a partir de ahora recibiras notificaciones',
                                                                                        style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                              font: GoogleFonts.inter(
                                                                                                fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                              ),
                                                                                              color: FlutterFlowTheme.of(context).primaryBackground,
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                              fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                            ),
                                                                                      ),
                                                                                      duration: Duration(milliseconds: 4000),
                                                                                      backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                    ),
                                                                                  );
                                                                                },
                                                                                child: Icon(
                                                                                  Icons.notifications_off_outlined,
                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                  size: 26.0,
                                                                                ),
                                                                              ),
                                                                            if (_model.notificationEnabled ==
                                                                                true)
                                                                              InkWell(
                                                                                splashColor: Colors.transparent,
                                                                                focusColor: Colors.transparent,
                                                                                hoverColor: Colors.transparent,
                                                                                highlightColor: Colors.transparent,
                                                                                onTap: () async {
                                                                                  await actions.toggleNotification(
                                                                                    false,
                                                                                  );
                                                                                  _model.notificationEnabled = false;
                                                                                  safeSetState(() {});
                                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                                    SnackBar(
                                                                                      content: Text(
                                                                                        'Notificaciones desactivadas, ya no recibiras notificaciones',
                                                                                        style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                              font: GoogleFonts.inter(
                                                                                                fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                              ),
                                                                                              color: FlutterFlowTheme.of(context).primaryBackground,
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                              fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                            ),
                                                                                      ),
                                                                                      duration: Duration(milliseconds: 4000),
                                                                                      backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                    ),
                                                                                  );
                                                                                },
                                                                                child: Icon(
                                                                                  Icons.notifications_none,
                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                  size: 26.0,
                                                                                ),
                                                                              ),
                                                                          ],
                                                                        ),
                                                                        Text(
                                                                          _model.notificationEnabled == true
                                                                              ? 'Activado'
                                                                              : 'Desactivado',
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                font: GoogleFonts.inter(
                                                                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                ),
                                                                                color: FlutterFlowTheme.of(context).secondary,
                                                                                fontSize: 11.0,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                              ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        16.0,
                                                                        20.0,
                                                                        16.0,
                                                                        0.0),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Flexible(
                                                                  child:
                                                                      RichText(
                                                                    textScaler:
                                                                        MediaQuery.of(context)
                                                                            .textScaler,
                                                                    text:
                                                                        TextSpan(
                                                                      children: [
                                                                        TextSpan(
                                                                          text:
                                                                              'Estado: ',
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                font: GoogleFonts.inter(
                                                                                  fontWeight: FontWeight.w600,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                ),
                                                                                color: Color(0xFF606060),
                                                                                fontSize: 22.0,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FontWeight.w600,
                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                              ),
                                                                        ),
                                                                        TextSpan(
                                                                          text:
                                                                              valueOrDefault<String>(
                                                                            containerUsuariosRow!.disponibilidad!
                                                                                ? 'Activo'
                                                                                : 'Inactivo',
                                                                            'Activo',
                                                                          ),
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primary,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontSize:
                                                                                22.0,
                                                                          ),
                                                                        )
                                                                      ],
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.inter(
                                                                              fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primaryText,
                                                                            fontSize:
                                                                                14.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Switch.adaptive(
                                                                  value: _model
                                                                          .switchValue ??=
                                                                      containerUsuariosRow!
                                                                          .disponibilidad!,
                                                                  onChanged:
                                                                      (newValue) async {
                                                                    safeSetState(() =>
                                                                        _model.switchValue =
                                                                            newValue!);
                                                                    if (newValue!) {
                                                                      await UsuariosTable()
                                                                          .update(
                                                                        data: {
                                                                          'disponibilidad':
                                                                              true,
                                                                        },
                                                                        matchingRows:
                                                                            (rows) =>
                                                                                rows.eqOrNull(
                                                                          'id',
                                                                          containerUsuariosRow
                                                                              ?.id,
                                                                        ),
                                                                      );
                                                                    } else {
                                                                      await UsuariosTable()
                                                                          .update(
                                                                        data: {
                                                                          'disponibilidad':
                                                                              false,
                                                                        },
                                                                        matchingRows:
                                                                            (rows) =>
                                                                                rows.eqOrNull(
                                                                          'id',
                                                                          containerUsuariosRow
                                                                              ?.id,
                                                                        ),
                                                                      );
                                                                    }
                                                                  },
                                                                  activeColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary,
                                                                  activeTrackColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary,
                                                                  inactiveTrackColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .alternate,
                                                                  inactiveThumbColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          if (_model
                                                                  .switchValue ??
                                                              true)
                                                            StreamBuilder<
                                                                List<
                                                                    SolicitudesServicioRow>>(
                                                              stream: _model.containerSupabaseStream4 ??= SupaFlow
                                                                  .client
                                                                  .from(
                                                                      "solicitudes_servicio")
                                                                  .stream(
                                                                      primaryKey: [
                                                                        'id'
                                                                      ])
                                                                  .inFilterOrNull(
                                                                    'servicio_id',
                                                                    containerProfesionalServiciosRowList
                                                                        .map((e) =>
                                                                            e.servicioId)
                                                                        .toList(),
                                                                  )
                                                                  .map((list) => list
                                                                      .map((item) =>
                                                                          SolicitudesServicioRow(
                                                                              item))
                                                                      .toList()),
                                                              builder: (context,
                                                                  snapshot) {
                                                                // Customize what your widget looks like when it's loading.
                                                                if (!snapshot
                                                                    .hasData) {
                                                                  return Center(
                                                                    child:
                                                                        SizedBox(
                                                                      width:
                                                                          50.0,
                                                                      height:
                                                                          50.0,
                                                                      child:
                                                                          CircularProgressIndicator(
                                                                        valueColor:
                                                                            AlwaysStoppedAnimation<Color>(
                                                                          FlutterFlowTheme.of(context)
                                                                              .primary,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                                List<SolicitudesServicioRow>
                                                                    containerSolicitudesServicioRowList =
                                                                    snapshot
                                                                        .data!;

                                                                return Container(
                                                                  decoration:
                                                                      BoxDecoration(),
                                                                  child:
                                                                      Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            18.0,
                                                                            0.0,
                                                                            0.0),
                                                                    child:
                                                                        Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      children: [
                                                                        Align(
                                                                          alignment: AlignmentDirectional(
                                                                              -1.0,
                                                                              0.0),
                                                                          child:
                                                                              Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                16.0,
                                                                                8.0,
                                                                                0.0,
                                                                                8.0),
                                                                            child:
                                                                                Text(
                                                                              'Solicitudes Entrantes',
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    font: GoogleFonts.inter(
                                                                                      fontWeight: FontWeight.w600,
                                                                                      fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                    ),
                                                                                    color: Color(0xFF0B6244),
                                                                                    fontSize: 20.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.w600,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                  ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Padding(
                                                                          padding: EdgeInsetsDirectional.fromSTEB(
                                                                              16.0,
                                                                              20.0,
                                                                              16.0,
                                                                              0.0),
                                                                          child:
                                                                              Builder(
                                                                            builder:
                                                                                (context) {
                                                                              // REQ-001: orden ascendente por fecha y hora de la reserva.
                                                                              final serviciosent = containerSolicitudesServicioRowList.where((e) => e.estado == 'entrantes').toList()
                                                                                ..sort((a, b) {
                                                                                  final porFecha = a.fecha.compareTo(b.fecha);
                                                                                  if (porFecha != 0) {
                                                                                    return porFecha;
                                                                                  }
                                                                                  final horaA = a.hora.time;
                                                                                  final horaB = b.hora.time;
                                                                                  if (horaA == null || horaB == null) {
                                                                                    return 0;
                                                                                  }
                                                                                  return (horaA.hour * 3600 + horaA.minute * 60 + horaA.second).compareTo(horaB.hour * 3600 + horaB.minute * 60 + horaB.second);
                                                                                });
                                                                              if (serviciosent.isEmpty) {
                                                                                return ListaVaciaWidget(
                                                                                  texto: 'No hay solicitudes entrantes',
                                                                                );
                                                                              }

                                                                              return ListView.separated(
                                                                                padding: EdgeInsets.zero,
                                                                                primary: false,
                                                                                shrinkWrap: true,
                                                                                scrollDirection: Axis.vertical,
                                                                                itemCount: serviciosent.length,
                                                                                separatorBuilder: (_, __) => SizedBox(height: 12.0),
                                                                                itemBuilder: (context, serviciosentIndex) {
                                                                                  final serviciosentItem = serviciosent[serviciosentIndex];
                                                                                  return Container(
                                                                                    decoration: BoxDecoration(
                                                                                      color: Color(0xFFEEECE8),
                                                                                      borderRadius: BorderRadius.circular(20.0),
                                                                                      border: Border.all(
                                                                                        color: Color(0xFFE5E2DC),
                                                                                        width: 1.0,
                                                                                      ),
                                                                                    ),
                                                                                    child: Padding(
                                                                                      padding: EdgeInsets.all(12.0),
                                                                                      child: Column(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        children: [
                                                                                          Padding(
                                                                                            padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
                                                                                            child: Container(
                                                                                              decoration: BoxDecoration(
                                                                                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                borderRadius: BorderRadius.circular(20.0),
                                                                                              ),
                                                                                              child: Padding(
                                                                                                padding: EdgeInsets.all(8.0),
                                                                                                child: Row(
                                                                                                  mainAxisSize: MainAxisSize.max,
                                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                  children: [
                                                                                                    Expanded(
                                                                                                      child: RichText(
                                                                                                        textScaler: MediaQuery.of(context).textScaler,
                                                                                                        text: TextSpan(
                                                                                                          children: [
                                                                                                            TextSpan(
                                                                                                              text: valueOrDefault<String>(
                                                                                                                serviciosentItem.servicioNombre,
                                                                                                                '-',
                                                                                                              ),
                                                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                    font: GoogleFonts.inter(
                                                                                                                      fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                      fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                    ),
                                                                                                                    color: FlutterFlowTheme.of(context).accent3,
                                                                                                                    fontSize: 16.0,
                                                                                                                    letterSpacing: 0.0,
                                                                                                                    fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                  ),
                                                                                                            )
                                                                                                          ],
                                                                                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                font: GoogleFonts.inter(
                                                                                                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                ),
                                                                                                                fontSize: 14.0,
                                                                                                                letterSpacing: 0.0,
                                                                                                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          Padding(
                                                                                            padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
                                                                                            child: Container(
                                                                                              decoration: BoxDecoration(
                                                                                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                                              ),
                                                                                              child: Column(
                                                                                                mainAxisSize: MainAxisSize.max,
                                                                                                children: [
                                                                                                  Padding(
                                                                                                    padding: EdgeInsets.all(8.0),
                                                                                                    child: Row(
                                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                      children: [
                                                                                                        Text(
                                                                                                          'Ticket ',
                                                                                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                font: GoogleFonts.inter(
                                                                                                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                ),
                                                                                                                color: FlutterFlowTheme.of(context).accent3,
                                                                                                                fontSize: 14.0,
                                                                                                                letterSpacing: 0.0,
                                                                                                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                        ),
                                                                                                        Flexible(
                                                                                                          child: Text(
                                                                                                            valueOrDefault<String>(
                                                                                                              serviciosentItem.ticket?.toString(),
                                                                                                              '0000',
                                                                                                            ),
                                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                  font: GoogleFonts.inter(
                                                                                                                    fontWeight: FontWeight.w600,
                                                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                  ),
                                                                                                                  color: FlutterFlowTheme.of(context).secondary,
                                                                                                                  fontSize: 14.0,
                                                                                                                  letterSpacing: 0.0,
                                                                                                                  fontWeight: FontWeight.w600,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                ),
                                                                                                          ),
                                                                                                        ),
                                                                                                      ].divide(SizedBox(width: 8.0)),
                                                                                                    ),
                                                                                                  ),
                                                                                                  Padding(
                                                                                                    padding: EdgeInsets.all(8.0),
                                                                                                    child: Row(
                                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                      children: [
                                                                                                        Text(
                                                                                                          'Ubicación',
                                                                                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                font: GoogleFonts.inter(
                                                                                                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                ),
                                                                                                                color: FlutterFlowTheme.of(context).accent3,
                                                                                                                fontSize: 14.0,
                                                                                                                letterSpacing: 0.0,
                                                                                                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                        ),
                                                                                                        Flexible(
                                                                                                          child: Text(
                                                                                                            valueOrDefault<String>(
                                                                                                              serviciosentItem.ubicacion,
                                                                                                              'Sin ubicación',
                                                                                                            ),
                                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                  font: GoogleFonts.inter(
                                                                                                                    fontWeight: FontWeight.w600,
                                                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                  ),
                                                                                                                  color: FlutterFlowTheme.of(context).secondary,
                                                                                                                  fontSize: 14.0,
                                                                                                                  letterSpacing: 0.0,
                                                                                                                  fontWeight: FontWeight.w600,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                ),
                                                                                                          ),
                                                                                                        ),
                                                                                                      ].divide(SizedBox(width: 8.0)),
                                                                                                    ),
                                                                                                  ),
                                                                                                  EnlaceMapaWidget(
                                                                                                    latitud: serviciosentItem.latitud,
                                                                                                    longitud: serviciosentItem.longitud,
                                                                                                    direccion: serviciosentItem.ubicacion,
                                                                                                    navegacion: false,
                                                                                                  ),
                                                                                                  Padding(
                                                                                                    padding: EdgeInsets.all(8.0),
                                                                                                    child: Row(
                                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                      children: [
                                                                                                        Text(
                                                                                                          'Fecha',
                                                                                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                font: GoogleFonts.inter(
                                                                                                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                ),
                                                                                                                color: FlutterFlowTheme.of(context).accent3,
                                                                                                                fontSize: 14.0,
                                                                                                                letterSpacing: 0.0,
                                                                                                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                        ),
                                                                                                        Flexible(
                                                                                                          child: Text(
                                                                                                            valueOrDefault<String>(
                                                                                                              dateTimeFormat(
                                                                                                                "d \'de\' MMMM \'de\' yyyy",
                                                                                                                serviciosentItem.fecha,
                                                                                                                locale: FFLocalizations.of(context).languageCode,
                                                                                                              ),
                                                                                                              'Sin fecha',
                                                                                                            ),
                                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                  font: GoogleFonts.inter(
                                                                                                                    fontWeight: FontWeight.w600,
                                                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                  ),
                                                                                                                  color: FlutterFlowTheme.of(context).secondary,
                                                                                                                  fontSize: 14.0,
                                                                                                                  letterSpacing: 0.0,
                                                                                                                  fontWeight: FontWeight.w600,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                ),
                                                                                                          ),
                                                                                                        ),
                                                                                                      ].divide(SizedBox(width: 8.0)),
                                                                                                    ),
                                                                                                  ),
                                                                                                  Padding(
                                                                                                    padding: EdgeInsets.all(8.0),
                                                                                                    child: Row(
                                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                      children: [
                                                                                                        Text(
                                                                                                          'Hora',
                                                                                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                font: GoogleFonts.inter(
                                                                                                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                ),
                                                                                                                color: FlutterFlowTheme.of(context).accent3,
                                                                                                                fontSize: 14.0,
                                                                                                                letterSpacing: 0.0,
                                                                                                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                        ),
                                                                                                        Flexible(
                                                                                                          child: Text(
                                                                                                            valueOrDefault<String>(
                                                                                                              dateTimeFormat(
                                                                                                                "jm",
                                                                                                                serviciosentItem.hora.time,
                                                                                                                locale: FFLocalizations.of(context).languageCode,
                                                                                                              ),
                                                                                                              'Sin hora',
                                                                                                            ),
                                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                  font: GoogleFonts.inter(
                                                                                                                    fontWeight: FontWeight.w600,
                                                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                  ),
                                                                                                                  color: FlutterFlowTheme.of(context).secondary,
                                                                                                                  fontSize: 15.0,
                                                                                                                  letterSpacing: 0.0,
                                                                                                                  fontWeight: FontWeight.w600,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                ),
                                                                                                          ),
                                                                                                        ),
                                                                                                      ].divide(SizedBox(width: 8.0)),
                                                                                                    ),
                                                                                                  ),
                                                                                                  Padding(
                                                                                                    padding: EdgeInsets.all(8.0),
                                                                                                    child: Row(
                                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                      children: [
                                                                                                        Text(
                                                                                                          'Precio',
                                                                                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                font: GoogleFonts.inter(
                                                                                                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                ),
                                                                                                                color: FlutterFlowTheme.of(context).accent3,
                                                                                                                fontSize: 14.0,
                                                                                                                letterSpacing: 0.0,
                                                                                                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                        ),
                                                                                                        Flexible(
                                                                                                          child: Text(
                                                                                                            valueOrDefault<String>(
                                                                                                              '${functions.formatPrices(valueOrDefault<double>(
                                                                                                                    serviciosentItem.precio,
                                                                                                                    0.0,
                                                                                                                  ) + valueOrDefault<double>(
                                                                                                                    serviciosentItem.precioAdicionales,
                                                                                                                    0.0,
                                                                                                                  ))} COP',
                                                                                                              '\$0 COP',
                                                                                                            ),
                                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                  font: GoogleFonts.inter(
                                                                                                                    fontWeight: FontWeight.w600,
                                                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                  ),
                                                                                                                  color: Color(0xFF3D91F4),
                                                                                                                  fontSize: 14.0,
                                                                                                                  letterSpacing: 0.0,
                                                                                                                  fontWeight: FontWeight.w600,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                ),
                                                                                                          ),
                                                                                                        ),
                                                                                                      ].divide(SizedBox(width: 8.0)),
                                                                                                    ),
                                                                                                  ),
                                                                                                ],
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          Row(
                                                                                            mainAxisSize: MainAxisSize.max,
                                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                            children: [
                                                                                              Flexible(
                                                                                                child: Row(
                                                                                                  mainAxisSize: MainAxisSize.max,
                                                                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                                                                  children: [
                                                                                                    Flexible(
                                                                                                      child: Builder(
                                                                                                        builder: (context) => FFButtonWidget(
                                                                                                          onPressed: () async {
                                                                                                            await SolicitudesServicioTable().update(
                                                                                                              data: {
                                                                                                                'estado': 'aceptadas',
                                                                                                                'profesional_id': currentUserUid,
                                                                                                              },
                                                                                                              matchingRows: (rows) => rows.eqOrNull(
                                                                                                                'id',
                                                                                                                serviciosentItem.id,
                                                                                                              ),
                                                                                                            );
                                                                                                            unawaited(
                                                                                                              () async {
                                                                                                                _model.apiResultwgo21 = await SendNotificationUserCall.call(
                                                                                                                  userIdSupabase: serviciosentItem.usuarioId,
                                                                                                                  title: 'Solicitud aceptaada',
                                                                                                                  message: 'Tu solicitud ha sido aceptada',
                                                                                                                );
                                                                                                              }(),
                                                                                                            );
                                                                                                            await showDialog(
                                                                                                              context: context,
                                                                                                              builder: (dialogContext) {
                                                                                                                return Dialog(
                                                                                                                  elevation: 0,
                                                                                                                  insetPadding: EdgeInsets.zero,
                                                                                                                  backgroundColor: Colors.transparent,
                                                                                                                  alignment: AlignmentDirectional(0.0, 0.0).resolve(Directionality.of(context)),
                                                                                                                  child: GestureDetector(
                                                                                                                    onTap: () {
                                                                                                                      FocusScope.of(dialogContext).unfocus();
                                                                                                                      FocusManager.instance.primaryFocus?.unfocus();
                                                                                                                    },
                                                                                                                    child: ServicioAsignadoInicioWidget(),
                                                                                                                  ),
                                                                                                                );
                                                                                                              },
                                                                                                            );

                                                                                                            safeSetState(() {});
                                                                                                          },
                                                                                                          text: 'Aceptar',
                                                                                                          icon: Icon(
                                                                                                            Icons.check,
                                                                                                            size: 16.0,
                                                                                                          ),
                                                                                                          options: FFButtonOptions(
                                                                                                            height: 32.0,
                                                                                                            padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                                                                                            iconAlignment: IconAlignment.end,
                                                                                                            iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                                                                                            iconColor: FlutterFlowTheme.of(context).energia,
                                                                                                            color: FlutterFlowTheme.of(context).primary,
                                                                                                            textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                                                  font: GoogleFonts.interTight(
                                                                                                                    fontWeight: FontWeight.w600,
                                                                                                                    fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                                  ),
                                                                                                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                                  fontSize: 14.0,
                                                                                                                  letterSpacing: 0.0,
                                                                                                                  fontWeight: FontWeight.w600,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                                ),
                                                                                                            elevation: 0.0,
                                                                                                            borderSide: BorderSide(
                                                                                                              color: FlutterFlowTheme.of(context).primary,
                                                                                                              width: 1.0,
                                                                                                            ),
                                                                                                            borderRadius: BorderRadius.circular(20.0),
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ),
                                                                                                  ].divide(SizedBox(width: 4.0)),
                                                                                                ),
                                                                                              ),
                                                                                            ].divide(SizedBox(width: 8.0)),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                },
                                                                              );
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          Container(
                                                            width:
                                                                double.infinity,
                                                            color: Color(
                                                                0x00000000),
                                                            child:
                                                                ExpandableNotifier(
                                                              controller: _model
                                                                  .aceptadasExpandableController,
                                                              child:
                                                                  ExpandablePanel(
                                                                header: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Align(
                                                                      alignment:
                                                                          AlignmentDirectional(
                                                                              -1.0,
                                                                              0.0),
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            16.0,
                                                                            8.0,
                                                                            0.0,
                                                                            8.0),
                                                                        child:
                                                                            Text(
                                                                          'Solicitudes Aceptadas',
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                font: GoogleFonts.inter(
                                                                                  fontWeight: FontWeight.w600,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                ),
                                                                                color: Color(0xFF0B6244),
                                                                                fontSize: 20.0,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FontWeight.w600,
                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                              ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                collapsed:
                                                                    Container(),
                                                                expanded:
                                                                    Container(
                                                                  decoration:
                                                                      BoxDecoration(),
                                                                  child:
                                                                      Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            16.0,
                                                                            20.0,
                                                                            16.0,
                                                                            0.0),
                                                                    child:
                                                                        Builder(
                                                                      builder:
                                                                          (context) {
                                                                        final solicitudesAceptadasx = containerSolicitudesServicioRowList
                                                                            .where((e) =>
                                                                                (e.estado == 'aceptadas') ||
                                                                                (e.estado == 'iniciadas') ||
                                                                                (e.estado == 'en camino') ||
                                                                                (e.estado == 'en proceso'))
                                                                            .toList()
                                                                          // Orden descendente por fecha y hora del servicio (el más futuro primero).
                                                                          ..sort((a, b) {
                                                                            final porFecha = b.fecha.compareTo(a.fecha);
                                                                            if (porFecha != 0) {
                                                                              return porFecha;
                                                                            }
                                                                            final horaA = a.hora.time;
                                                                            final horaB = b.hora.time;
                                                                            if (horaA == null || horaB == null) {
                                                                              return 0;
                                                                            }
                                                                            return (horaB.hour * 3600 + horaB.minute * 60 + horaB.second).compareTo(horaA.hour * 3600 + horaA.minute * 60 + horaA.second);
                                                                          });
                                                                        if (solicitudesAceptadasx
                                                                            .isEmpty) {
                                                                          return ListaVaciaWidget(
                                                                            texto:
                                                                                'No hay solicitudes aceptadas',
                                                                          );
                                                                        }

                                                                        return ListView
                                                                            .separated(
                                                                          padding:
                                                                              EdgeInsets.zero,
                                                                          primary:
                                                                              false,
                                                                          shrinkWrap:
                                                                              true,
                                                                          scrollDirection:
                                                                              Axis.vertical,
                                                                          itemCount:
                                                                              solicitudesAceptadasx.length,
                                                                          separatorBuilder: (_, __) =>
                                                                              SizedBox(height: 12.0),
                                                                          itemBuilder:
                                                                              (context, solicitudesAceptadasxIndex) {
                                                                            final solicitudesAceptadasxItem =
                                                                                solicitudesAceptadasx[solicitudesAceptadasxIndex];
                                                                            return Container(
                                                                              decoration: BoxDecoration(
                                                                                color: Color(0xFFEEECE8),
                                                                                borderRadius: BorderRadius.circular(20.0),
                                                                                border: Border.all(
                                                                                  color: Color(0xFFE5E2DC),
                                                                                  width: 1.0,
                                                                                ),
                                                                              ),
                                                                              child: Padding(
                                                                                padding: EdgeInsets.all(12.0),
                                                                                child: Column(
                                                                                  mainAxisSize: MainAxisSize.max,
                                                                                  children: [
                                                                                    Padding(
                                                                                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
                                                                                      child: Container(
                                                                                        decoration: BoxDecoration(
                                                                                          color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                          borderRadius: BorderRadius.circular(8.0),
                                                                                        ),
                                                                                        child: Padding(
                                                                                          padding: EdgeInsets.all(8.0),
                                                                                          child: Row(
                                                                                            mainAxisSize: MainAxisSize.max,
                                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                            children: [
                                                                                              Flexible(
                                                                                                child: RichText(
                                                                                                  textScaler: MediaQuery.of(context).textScaler,
                                                                                                  text: TextSpan(
                                                                                                    children: [
                                                                                                      TextSpan(
                                                                                                        text: valueOrDefault<String>(
                                                                                                          solicitudesAceptadasxItem.servicioNombre,
                                                                                                          '-',
                                                                                                        ),
                                                                                                        style: TextStyle(
                                                                                                          color: FlutterFlowTheme.of(context).secondary,
                                                                                                          fontWeight: FontWeight.w600,
                                                                                                          fontSize: 16.0,
                                                                                                        ),
                                                                                                      )
                                                                                                    ],
                                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                          font: GoogleFonts.inter(
                                                                                                            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                          ),
                                                                                                          letterSpacing: 0.0,
                                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                        ),
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              FFButtonWidget(
                                                                                                onPressed: () {
                                                                                                  print('Button pressed ...');
                                                                                                },
                                                                                                text: valueOrDefault<String>(
                                                                                                  solicitudesAceptadasxItem.estado == 'aceptadas' ? 'Activo' : 'En curso',
                                                                                                  'Activo',
                                                                                                ),
                                                                                                options: FFButtonOptions(
                                                                                                  height: 20.0,
                                                                                                  padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                                                                                                  iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                                                                                  color: valueOrDefault<Color>(
                                                                                                    solicitudesAceptadasxItem.estado == 'aceptadas' ? Color(0xFFCFE3FC) : Color(0xFFFFE9CC),
                                                                                                    Color(0xFFFFE9CC),
                                                                                                  ),
                                                                                                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                                        font: GoogleFonts.interTight(
                                                                                                          fontWeight: FontWeight.bold,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                        ),
                                                                                                        color: valueOrDefault<Color>(
                                                                                                          solicitudesAceptadasxItem.estado == 'aceptadas' ? Color(0xFF0D70E7) : Color(0xFFED8600),
                                                                                                          Color(0xFFED8600),
                                                                                                        ),
                                                                                                        fontSize: 16.0,
                                                                                                        letterSpacing: 0.0,
                                                                                                        fontWeight: FontWeight.bold,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                      ),
                                                                                                  elevation: 0.0,
                                                                                                  borderSide: BorderSide(
                                                                                                    color: valueOrDefault<Color>(
                                                                                                      solicitudesAceptadasxItem.estado == 'aceptadas' ? Color(0xFF0D70E7) : Color(0xFFED8600),
                                                                                                      Color(0xFFED8600),
                                                                                                    ),
                                                                                                    width: 1.0,
                                                                                                  ),
                                                                                                  borderRadius: BorderRadius.circular(12.0),
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    Padding(
                                                                                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
                                                                                      child: Container(
                                                                                        decoration: BoxDecoration(
                                                                                          color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                          borderRadius: BorderRadius.circular(8.0),
                                                                                        ),
                                                                                        child: Column(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          children: [
                                                                                            Padding(
                                                                                              padding: EdgeInsets.all(8.0),
                                                                                              child: Row(
                                                                                                mainAxisSize: MainAxisSize.max,
                                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                children: [
                                                                                                  Text(
                                                                                                    'Ticket',
                                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                          font: GoogleFonts.inter(
                                                                                                            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                          ),
                                                                                                          color: FlutterFlowTheme.of(context).accent3,
                                                                                                          fontSize: 16.0,
                                                                                                          letterSpacing: 0.0,
                                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                        ),
                                                                                                  ),
                                                                                                  Flexible(
                                                                                                    child: Text(
                                                                                                      valueOrDefault<String>(
                                                                                                        solicitudesAceptadasxItem.ticket?.toString(),
                                                                                                        '-',
                                                                                                      ),
                                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                            font: GoogleFonts.inter(
                                                                                                              fontWeight: FontWeight.w600,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                            ),
                                                                                                            color: FlutterFlowTheme.of(context).secondary,
                                                                                                            fontSize: 16.0,
                                                                                                            letterSpacing: 0.0,
                                                                                                            fontWeight: FontWeight.w600,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                          ),
                                                                                                    ),
                                                                                                  ),
                                                                                                ].divide(SizedBox(width: 8.0)),
                                                                                              ),
                                                                                            ),
                                                                                            Padding(
                                                                                              padding: EdgeInsets.all(8.0),
                                                                                              child: Row(
                                                                                                mainAxisSize: MainAxisSize.max,
                                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                children: [
                                                                                                  Text(
                                                                                                    'Descripción',
                                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                          font: GoogleFonts.inter(
                                                                                                            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                          ),
                                                                                                          color: FlutterFlowTheme.of(context).accent3,
                                                                                                          fontSize: 16.0,
                                                                                                          letterSpacing: 0.0,
                                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                        ),
                                                                                                  ),
                                                                                                  Flexible(
                                                                                                    child: Align(
                                                                                                      alignment: AlignmentDirectional(1.0, 0.0),
                                                                                                      child: Text(
                                                                                                        valueOrDefault<String>(
                                                                                                          solicitudesAceptadasxItem.descripcion,
                                                                                                          '-',
                                                                                                        ),
                                                                                                        textAlign: TextAlign.end,
                                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                              font: GoogleFonts.inter(
                                                                                                                fontWeight: FontWeight.w600,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                              color: FlutterFlowTheme.of(context).secondary,
                                                                                                              fontSize: 16.0,
                                                                                                              letterSpacing: 0.0,
                                                                                                              fontWeight: FontWeight.w600,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                            ),
                                                                                                      ),
                                                                                                    ),
                                                                                                  ),
                                                                                                ].divide(SizedBox(width: 8.0)),
                                                                                              ),
                                                                                            ),
                                                                                            Padding(
                                                                                              padding: EdgeInsets.all(8.0),
                                                                                              child: Row(
                                                                                                mainAxisSize: MainAxisSize.max,
                                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                children: [
                                                                                                  Text(
                                                                                                    'Info adicional',
                                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                          font: GoogleFonts.inter(
                                                                                                            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                          ),
                                                                                                          color: FlutterFlowTheme.of(context).accent3,
                                                                                                          fontSize: 16.0,
                                                                                                          letterSpacing: 0.0,
                                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                        ),
                                                                                                  ),
                                                                                                  Flexible(
                                                                                                    child: Text(
                                                                                                      valueOrDefault<String>(
                                                                                                        solicitudesAceptadasxItem.informacionAdicional,
                                                                                                        '-',
                                                                                                      ),
                                                                                                      textAlign: TextAlign.end,
                                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                            font: GoogleFonts.inter(
                                                                                                              fontWeight: FontWeight.w600,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                            ),
                                                                                                            color: FlutterFlowTheme.of(context).secondary,
                                                                                                            fontSize: 16.0,
                                                                                                            letterSpacing: 0.0,
                                                                                                            fontWeight: FontWeight.w600,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                          ),
                                                                                                    ),
                                                                                                  ),
                                                                                                ].divide(SizedBox(width: 8.0)),
                                                                                              ),
                                                                                            ),
                                                                                            Padding(
                                                                                              padding: EdgeInsets.all(8.0),
                                                                                              child: Row(
                                                                                                mainAxisSize: MainAxisSize.max,
                                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                children: [
                                                                                                  Text(
                                                                                                    'Ubicación',
                                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                          font: GoogleFonts.inter(
                                                                                                            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                          ),
                                                                                                          color: FlutterFlowTheme.of(context).accent3,
                                                                                                          fontSize: 16.0,
                                                                                                          letterSpacing: 0.0,
                                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                        ),
                                                                                                  ),
                                                                                                  Flexible(
                                                                                                    child: Text(
                                                                                                      valueOrDefault<String>(
                                                                                                        solicitudesAceptadasxItem.ubicacion,
                                                                                                        '-',
                                                                                                      ),
                                                                                                      textAlign: TextAlign.end,
                                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                            font: GoogleFonts.inter(
                                                                                                              fontWeight: FontWeight.w600,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                            ),
                                                                                                            color: FlutterFlowTheme.of(context).secondary,
                                                                                                            fontSize: 16.0,
                                                                                                            letterSpacing: 0.0,
                                                                                                            fontWeight: FontWeight.w600,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                          ),
                                                                                                    ),
                                                                                                  ),
                                                                                                ].divide(SizedBox(width: 8.0)),
                                                                                              ),
                                                                                            ),
                                                                                            EnlaceMapaWidget(
                                                                                              latitud: solicitudesAceptadasxItem.latitud,
                                                                                              longitud: solicitudesAceptadasxItem.longitud,
                                                                                              direccion: solicitudesAceptadasxItem.ubicacion,
                                                                                              navegacion: true,
                                                                                            ),
                                                                                            Padding(
                                                                                              padding: EdgeInsets.all(8.0),
                                                                                              child: Row(
                                                                                                mainAxisSize: MainAxisSize.max,
                                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                children: [
                                                                                                  Text(
                                                                                                    'Fecha',
                                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                          font: GoogleFonts.inter(
                                                                                                            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                          ),
                                                                                                          color: FlutterFlowTheme.of(context).accent3,
                                                                                                          fontSize: 16.0,
                                                                                                          letterSpacing: 0.0,
                                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                        ),
                                                                                                  ),
                                                                                                  Flexible(
                                                                                                    child: Text(
                                                                                                      valueOrDefault<String>(
                                                                                                        dateTimeFormat(
                                                                                                          "d \'de\' MMMM \'de\' yyyy",
                                                                                                          solicitudesAceptadasxItem.fecha,
                                                                                                          locale: FFLocalizations.of(context).languageCode,
                                                                                                        ),
                                                                                                        '-',
                                                                                                      ),
                                                                                                      textAlign: TextAlign.end,
                                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                            font: GoogleFonts.inter(
                                                                                                              fontWeight: FontWeight.w600,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                            ),
                                                                                                            color: FlutterFlowTheme.of(context).secondary,
                                                                                                            fontSize: 16.0,
                                                                                                            letterSpacing: 0.0,
                                                                                                            fontWeight: FontWeight.w600,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                          ),
                                                                                                    ),
                                                                                                  ),
                                                                                                ].divide(SizedBox(width: 8.0)),
                                                                                              ),
                                                                                            ),
                                                                                            Padding(
                                                                                              padding: EdgeInsets.all(8.0),
                                                                                              child: Row(
                                                                                                mainAxisSize: MainAxisSize.max,
                                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                children: [
                                                                                                  Text(
                                                                                                    'Hora',
                                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                          font: GoogleFonts.inter(
                                                                                                            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                          ),
                                                                                                          color: FlutterFlowTheme.of(context).accent3,
                                                                                                          fontSize: 16.0,
                                                                                                          letterSpacing: 0.0,
                                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                        ),
                                                                                                  ),
                                                                                                  Flexible(
                                                                                                    child: Text(
                                                                                                      valueOrDefault<String>(
                                                                                                        dateTimeFormat(
                                                                                                          "jm",
                                                                                                          solicitudesAceptadasxItem.hora.time,
                                                                                                          locale: FFLocalizations.of(context).languageCode,
                                                                                                        ),
                                                                                                        '-',
                                                                                                      ),
                                                                                                      textAlign: TextAlign.end,
                                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                            font: GoogleFonts.inter(
                                                                                                              fontWeight: FontWeight.w600,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                            ),
                                                                                                            color: FlutterFlowTheme.of(context).secondary,
                                                                                                            fontSize: 16.0,
                                                                                                            letterSpacing: 0.0,
                                                                                                            fontWeight: FontWeight.w600,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                          ),
                                                                                                    ),
                                                                                                  ),
                                                                                                ].divide(SizedBox(width: 8.0)),
                                                                                              ),
                                                                                            ),
                                                                                            Padding(
                                                                                              padding: EdgeInsets.all(8.0),
                                                                                              child: Row(
                                                                                                mainAxisSize: MainAxisSize.max,
                                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                children: [
                                                                                                  Text(
                                                                                                    'Precio',
                                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                          font: GoogleFonts.inter(
                                                                                                            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                          ),
                                                                                                          color: FlutterFlowTheme.of(context).accent3,
                                                                                                          fontSize: 16.0,
                                                                                                          letterSpacing: 0.0,
                                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                        ),
                                                                                                  ),
                                                                                                  Flexible(
                                                                                                    child: Text(
                                                                                                      valueOrDefault<String>(
                                                                                                        '${valueOrDefault<String>(
                                                                                                          formatNumber(
                                                                                                            solicitudesAceptadasxItem.precio + (solicitudesAceptadasxItem.precioAdicionales!),
                                                                                                            formatType: FormatType.custom,
                                                                                                            currency: '\$',
                                                                                                            format: '',
                                                                                                            locale: '',
                                                                                                          ),
                                                                                                          '\$0',
                                                                                                        )} COP',
                                                                                                        '\$0 COP',
                                                                                                      ),
                                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                            font: GoogleFonts.inter(
                                                                                                              fontWeight: FontWeight.w600,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                            ),
                                                                                                            color: Color(0xFF3D91F4),
                                                                                                            fontSize: 16.0,
                                                                                                            letterSpacing: 0.0,
                                                                                                            fontWeight: FontWeight.w600,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                          ),
                                                                                                    ),
                                                                                                  ),
                                                                                                ].divide(SizedBox(width: 8.0)),
                                                                                              ),
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    Row(
                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                      children: [
                                                                                        Row(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          children: [
                                                                                            FutureBuilder<List<ChatsSolicitudRow>>(
                                                                                              future: ChatsSolicitudTable().querySingleRow(
                                                                                                queryFn: (q) => q.eqOrNull(
                                                                                                  'solicitud_id',
                                                                                                  solicitudesAceptadasxItem.id,
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
                                                                                                List<ChatsSolicitudRow> stackChatsSolicitudRowList = snapshot.data!;

                                                                                                final stackChatsSolicitudRow = stackChatsSolicitudRowList.isNotEmpty ? stackChatsSolicitudRowList.first : null;

                                                                                                return Container(
                                                                                                  width: 90.0,
                                                                                                  height: 32.0,
                                                                                                  child: Stack(
                                                                                                    children: [
                                                                                                      FFButtonWidget(
                                                                                                        onPressed: () async {
                                                                                                          _model.vvsid = await VwSolicitudesServiciosCompletaTable().queryRows(
                                                                                                            queryFn: (q) => q.eqOrNull(
                                                                                                              'solicitud_id',
                                                                                                              solicitudesAceptadasxItem.id,
                                                                                                            ),
                                                                                                          );

                                                                                                          context.pushNamed(
                                                                                                            ChatWidget.routeName,
                                                                                                            queryParameters: {
                                                                                                              'servicio': serializeParam(
                                                                                                                _model.vvsid?.firstOrNull,
                                                                                                                ParamType.SupabaseRow,
                                                                                                              ),
                                                                                                            }.withoutNulls,
                                                                                                          );

                                                                                                          safeSetState(() {});
                                                                                                        },
                                                                                                        text: 'Chat',
                                                                                                        icon: Icon(
                                                                                                          Icons.support_agent,
                                                                                                          size: 16.0,
                                                                                                        ),
                                                                                                        options: FFButtonOptions(
                                                                                                          height: 32.0,
                                                                                                          padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                                                                                          iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                                                                                          iconColor: FlutterFlowTheme.of(context).accent3,
                                                                                                          color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                          textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                                                font: GoogleFonts.interTight(
                                                                                                                  fontWeight: FontWeight.w600,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                                ),
                                                                                                                color: FlutterFlowTheme.of(context).accent3,
                                                                                                                fontSize: 12.0,
                                                                                                                letterSpacing: 0.0,
                                                                                                                fontWeight: FontWeight.w600,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                              ),
                                                                                                          elevation: 0.0,
                                                                                                          borderSide: BorderSide(
                                                                                                            color: FlutterFlowTheme.of(context).alternate,
                                                                                                            width: 1.0,
                                                                                                          ),
                                                                                                          borderRadius: BorderRadius.circular(8.0),
                                                                                                        ),
                                                                                                      ),
                                                                                                      Align(
                                                                                                        alignment: AlignmentDirectional(0.94, -3.54),
                                                                                                        child: FutureBuilder<List<MensajesChatRow>>(
                                                                                                          future: MensajesChatTable().queryRows(
                                                                                                            queryFn: (q) => q
                                                                                                                .eqOrNull(
                                                                                                                  'chat_id',
                                                                                                                  stackChatsSolicitudRow?.id,
                                                                                                                )
                                                                                                                .neqOrNull(
                                                                                                                  'remitente_id',
                                                                                                                  currentUserUid,
                                                                                                                )
                                                                                                                .eqOrNull(
                                                                                                                  'leido',
                                                                                                                  false,
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
                                                                                                            List<MensajesChatRow> containerMensajesChatRowList = snapshot.data!;

                                                                                                            return Container(
                                                                                                              decoration: BoxDecoration(
                                                                                                                color: FlutterFlowTheme.of(context).creatividad,
                                                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                                                              ),
                                                                                                              child: Padding(
                                                                                                                padding: EdgeInsetsDirectional.fromSTEB(8.0, 3.0, 8.0, 3.0),
                                                                                                                child: Text(
                                                                                                                  valueOrDefault<String>(
                                                                                                                    containerMensajesChatRowList.length.toString(),
                                                                                                                    '0',
                                                                                                                  ),
                                                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                        font: GoogleFonts.inter(
                                                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                        ),
                                                                                                                        color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                                        letterSpacing: 0.0,
                                                                                                                        fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                      ),
                                                                                                                ),
                                                                                                              ),
                                                                                                            );
                                                                                                          },
                                                                                                        ),
                                                                                                      ),
                                                                                                    ],
                                                                                                  ),
                                                                                                );
                                                                                              },
                                                                                            ),
                                                                                            if (solicitudesAceptadasxItem.estado != 'aceptadas')
                                                                                              FFButtonWidget(
                                                                                                onPressed: () async {
                                                                                                  await showModalBottomSheet(
                                                                                                    isScrollControlled: true,
                                                                                                    backgroundColor: Colors.transparent,
                                                                                                    isDismissible: false,
                                                                                                    useSafeArea: true,
                                                                                                    context: context,
                                                                                                    builder: (context) {
                                                                                                      return GestureDetector(
                                                                                                        onTap: () {
                                                                                                          FocusScope.of(context).unfocus();
                                                                                                          FocusManager.instance.primaryFocus?.unfocus();
                                                                                                        },
                                                                                                        child: Padding(
                                                                                                          padding: MediaQuery.viewInsetsOf(context),
                                                                                                          child: SoporteSeleccionWidget(
                                                                                                            idServicio: solicitudesAceptadasxItem.ticket!.toString(),
                                                                                                            action: (respuesta) async {
                                                                                                              Navigator.pop(context);
                                                                                                              FFAppState().addToSoporte(SoporteMensajesStruct(
                                                                                                                rol: 'soporte',
                                                                                                                mensaje: respuesta,
                                                                                                                fecha: getCurrentTimestamp.toString(),
                                                                                                              ));
                                                                                                              safeSetState(() {});

                                                                                                              context.pushNamed(
                                                                                                                SoporteWidget.routeName,
                                                                                                                extra: <String, dynamic>{
                                                                                                                  '__transition_info__': TransitionInfo(
                                                                                                                    hasTransition: true,
                                                                                                                    transitionType: PageTransitionType.fade,
                                                                                                                    duration: Duration(milliseconds: 0),
                                                                                                                  ),
                                                                                                                },
                                                                                                              );
                                                                                                            },
                                                                                                          ),
                                                                                                        ),
                                                                                                      );
                                                                                                    },
                                                                                                  ).then((value) => safeSetState(() {}));
                                                                                                },
                                                                                                text: 'Soporte',
                                                                                                icon: Icon(
                                                                                                  Icons.support_agent,
                                                                                                  size: 16.0,
                                                                                                ),
                                                                                                options: FFButtonOptions(
                                                                                                  height: 32.0,
                                                                                                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                                                                                  iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                                                                                  iconColor: FlutterFlowTheme.of(context).accent3,
                                                                                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                                        font: GoogleFonts.interTight(
                                                                                                          fontWeight: FontWeight.w600,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                        ),
                                                                                                        color: FlutterFlowTheme.of(context).accent3,
                                                                                                        fontSize: 12.0,
                                                                                                        letterSpacing: 0.0,
                                                                                                        fontWeight: FontWeight.w600,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                      ),
                                                                                                  elevation: 0.0,
                                                                                                  borderSide: BorderSide(
                                                                                                    color: FlutterFlowTheme.of(context).alternate,
                                                                                                    width: 1.0,
                                                                                                  ),
                                                                                                  borderRadius: BorderRadius.circular(8.0),
                                                                                                ),
                                                                                              ),
                                                                                            if (solicitudesAceptadasxItem.estado == 'aceptadas')
                                                                                              Builder(
                                                                                                builder: (context) => FFButtonWidget(
                                                                                                  onPressed: () async {
                                                                                                    await showDialog(
                                                                                                      context: context,
                                                                                                      builder: (dialogContext) {
                                                                                                        return Dialog(
                                                                                                          elevation: 0,
                                                                                                          insetPadding: EdgeInsets.zero,
                                                                                                          backgroundColor: Colors.transparent,
                                                                                                          alignment: AlignmentDirectional(0.0, 0.0).resolve(Directionality.of(context)),
                                                                                                          child: GestureDetector(
                                                                                                            onTap: () {
                                                                                                              FocusScope.of(dialogContext).unfocus();
                                                                                                              FocusManager.instance.primaryFocus?.unfocus();
                                                                                                            },
                                                                                                            child: CancelarServicioWidget(
                                                                                                              solicitudServicioId: solicitudesAceptadasxItem.id,
                                                                                                            ),
                                                                                                          ),
                                                                                                        );
                                                                                                      },
                                                                                                    );
                                                                                                  },
                                                                                                  text: 'Cancelar',
                                                                                                  icon: Icon(
                                                                                                    Icons.cancel_outlined,
                                                                                                    size: 16.0,
                                                                                                  ),
                                                                                                  options: FFButtonOptions(
                                                                                                    height: 32.0,
                                                                                                    padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                                                                                    iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                                                                                    iconColor: Color(0xFFBC1021),
                                                                                                    color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                                          font: GoogleFonts.interTight(
                                                                                                            fontWeight: FontWeight.w600,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                          ),
                                                                                                          color: Color(0xFFBC1021),
                                                                                                          fontSize: 12.0,
                                                                                                          letterSpacing: 0.0,
                                                                                                          fontWeight: FontWeight.w600,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                        ),
                                                                                                    elevation: 0.0,
                                                                                                    borderSide: BorderSide(
                                                                                                      color: Color(0xFFBC1021),
                                                                                                      width: 1.0,
                                                                                                    ),
                                                                                                    borderRadius: BorderRadius.circular(8.0),
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                          ].divide(SizedBox(width: 8.0)),
                                                                                        ),
                                                                                        Flexible(
                                                                                          child: Row(
                                                                                            mainAxisSize: MainAxisSize.max,
                                                                                            mainAxisAlignment: MainAxisAlignment.end,
                                                                                            children: [
                                                                                              Flexible(
                                                                                                child: Builder(
                                                                                                  builder: (context) => FFButtonWidget(
                                                                                                    onPressed: () async {
                                                                                                      if (solicitudesAceptadasxItem.estado == 'aceptadas') {
                                                                                                        await SolicitudesServicioTable().update(
                                                                                                          data: {
                                                                                                            'estado': 'iniciadas',
                                                                                                          },
                                                                                                          matchingRows: (rows) => rows.eqOrNull(
                                                                                                            'id',
                                                                                                            solicitudesAceptadasxItem.id,
                                                                                                          ),
                                                                                                        );
                                                                                                        _model.apiResultwgo = await SendNotificationUserCall.call(
                                                                                                          userIdSupabase: solicitudesAceptadasxItem.usuarioId,
                                                                                                          title: 'Solicitud iniciada',
                                                                                                          message: 'Tu solicitud ha sido iniciada',
                                                                                                        );
                                                                                                      } else if (solicitudesAceptadasxItem.estado == 'iniciadas') {
                                                                                                        await SolicitudesServicioTable().update(
                                                                                                          data: {
                                                                                                            'estado': 'en camino',
                                                                                                          },
                                                                                                          matchingRows: (rows) => rows.eqOrNull(
                                                                                                            'id',
                                                                                                            solicitudesAceptadasxItem.id,
                                                                                                          ),
                                                                                                        );
                                                                                                        _model.apiResult3 = await SendNotificationUserCall.call(
                                                                                                          userIdSupabase: solicitudesAceptadasxItem.usuarioId,
                                                                                                          title: 'Solicitud en camino',
                                                                                                          message: 'Tu solicitud esta en camino',
                                                                                                        );
                                                                                                      } else if (solicitudesAceptadasxItem.estado == 'en camino') {
                                                                                                        await SolicitudesServicioTable().update(
                                                                                                          data: {
                                                                                                            'estado': 'en proceso',
                                                                                                          },
                                                                                                          matchingRows: (rows) => rows.eqOrNull(
                                                                                                            'id',
                                                                                                            solicitudesAceptadasxItem.id,
                                                                                                          ),
                                                                                                        );
                                                                                                        _model.apiResult4 = await SendNotificationUserCall.call(
                                                                                                          userIdSupabase: solicitudesAceptadasxItem.usuarioId,
                                                                                                          title: 'Solicitud en proceso',
                                                                                                          message: 'Tu solicitud esta en proceso',
                                                                                                        );
                                                                                                      } else if (solicitudesAceptadasxItem.estado == 'en proceso') {
                                                                                                        await showDialog(
                                                                                                          context: context,
                                                                                                          builder: (dialogContext) {
                                                                                                            return Dialog(
                                                                                                              elevation: 0,
                                                                                                              insetPadding: EdgeInsets.zero,
                                                                                                              backgroundColor: Colors.transparent,
                                                                                                              alignment: AlignmentDirectional(0.0, 0.0).resolve(Directionality.of(context)),
                                                                                                              child: GestureDetector(
                                                                                                                onTap: () {
                                                                                                                  FocusScope.of(dialogContext).unfocus();
                                                                                                                  FocusManager.instance.primaryFocus?.unfocus();
                                                                                                                },
                                                                                                                child: FinalizarServicioWidget(
                                                                                                                  idservicio: solicitudesAceptadasxItem.id,
                                                                                                                ),
                                                                                                              ),
                                                                                                            );
                                                                                                          },
                                                                                                        );
                                                                                                      }

                                                                                                      safeSetState(() {});
                                                                                                    },
                                                                                                    text: () {
                                                                                                      if (solicitudesAceptadasxItem.estado == 'aceptadas') {
                                                                                                        return 'Iniciar servicio';
                                                                                                      } else if (solicitudesAceptadasxItem.estado == 'iniciadas') {
                                                                                                        return 'Me encuentro en camino';
                                                                                                      } else if (solicitudesAceptadasxItem.estado == 'en camino') {
                                                                                                        return 'El servicio ha comenzado';
                                                                                                      } else if (solicitudesAceptadasxItem.estado == 'en proceso') {
                                                                                                        return 'Finalizar servicio';
                                                                                                      } else {
                                                                                                        return 'Iniciar servicio';
                                                                                                      }
                                                                                                    }(),
                                                                                                    icon: Icon(
                                                                                                      Icons.check,
                                                                                                      size: 16.0,
                                                                                                    ),
                                                                                                    options: FFButtonOptions(
                                                                                                      height: 32.0,
                                                                                                      padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                                                                                      iconAlignment: IconAlignment.end,
                                                                                                      iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                                                                                      iconColor: FlutterFlowTheme.of(context).success,
                                                                                                      color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                      textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                                            font: GoogleFonts.interTight(
                                                                                                              fontWeight: FontWeight.w600,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                            ),
                                                                                                            color: FlutterFlowTheme.of(context).success,
                                                                                                            fontSize: 12.0,
                                                                                                            letterSpacing: 0.0,
                                                                                                            fontWeight: FontWeight.w600,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                          ),
                                                                                                      elevation: 0.0,
                                                                                                      borderSide: BorderSide(
                                                                                                        color: FlutterFlowTheme.of(context).success,
                                                                                                        width: 1.0,
                                                                                                      ),
                                                                                                      borderRadius: BorderRadius.circular(8.0),
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                            ].divide(SizedBox(width: 4.0)),
                                                                                          ),
                                                                                        ),
                                                                                      ].divide(SizedBox(width: 8.0)),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                ),
                                                                theme:
                                                                    ExpandableThemeData(
                                                                  tapHeaderToExpand:
                                                                      true,
                                                                  tapBodyToExpand:
                                                                      false,
                                                                  tapBodyToCollapse:
                                                                      false,
                                                                  headerAlignment:
                                                                      ExpandablePanelHeaderAlignment
                                                                          .center,
                                                                  hasIcon: true,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        0.0,
                                                                        40.0),
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                color: Color(
                                                                    0x00000000),
                                                                child:
                                                                    ExpandableNotifier(
                                                                  controller: _model
                                                                      .finalizadasExpandableController,
                                                                  child:
                                                                      ExpandablePanel(
                                                                    header:
                                                                        Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      children: [
                                                                        Align(
                                                                          alignment: AlignmentDirectional(
                                                                              -1.0,
                                                                              0.0),
                                                                          child:
                                                                              Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                16.0,
                                                                                8.0,
                                                                                0.0,
                                                                                8.0),
                                                                            child:
                                                                                Text(
                                                                              'Solicitudes Finalizadas',
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    font: GoogleFonts.inter(
                                                                                      fontWeight: FontWeight.w600,
                                                                                      fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                    ),
                                                                                    color: Color(0xFF0B6244),
                                                                                    fontSize: 20.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.w600,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                  ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    collapsed:
                                                                        Container(),
                                                                    expanded:
                                                                        Container(
                                                                      decoration:
                                                                          BoxDecoration(),
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            16.0,
                                                                            20.0,
                                                                            16.0,
                                                                            0.0),
                                                                        child:
                                                                            Builder(
                                                                          builder:
                                                                              (context) {
                                                                            final serviciosFinalizados =
                                                                                containerSolicitudesServicioRowList.where((e) => (e.estado == 'finalizadas') || (e.estado == 'canceladas')).toList()
                                                                                  // Orden descendente por fecha y hora del servicio (el más reciente primero).
                                                                                  ..sort((a, b) {
                                                                                    final porFecha = b.fecha.compareTo(a.fecha);
                                                                                    if (porFecha != 0) {
                                                                                      return porFecha;
                                                                                    }
                                                                                    final horaA = a.hora.time;
                                                                                    final horaB = b.hora.time;
                                                                                    if (horaA == null || horaB == null) {
                                                                                      return 0;
                                                                                    }
                                                                                    return (horaB.hour * 3600 + horaB.minute * 60 + horaB.second).compareTo(horaA.hour * 3600 + horaA.minute * 60 + horaA.second);
                                                                                  });
                                                                            if (serviciosFinalizados.isEmpty) {
                                                                              return ListaVaciaWidget(
                                                                                texto: 'No hay solicitudes finalizadas',
                                                                              );
                                                                            }

                                                                            return ListView.separated(
                                                                              padding: EdgeInsets.zero,
                                                                              primary: false,
                                                                              shrinkWrap: true,
                                                                              scrollDirection: Axis.vertical,
                                                                              itemCount: serviciosFinalizados.length,
                                                                              separatorBuilder: (_, __) => SizedBox(height: 12.0),
                                                                              itemBuilder: (context, serviciosFinalizadosIndex) {
                                                                                final serviciosFinalizadosItem = serviciosFinalizados[serviciosFinalizadosIndex];
                                                                                return Container(
                                                                                  decoration: BoxDecoration(
                                                                                    color: Color(0xFFEEECE8),
                                                                                    borderRadius: BorderRadius.circular(20.0),
                                                                                    border: Border.all(
                                                                                      color: Color(0xFFE5E2DC),
                                                                                      width: 1.0,
                                                                                    ),
                                                                                  ),
                                                                                  child: Padding(
                                                                                    padding: EdgeInsets.all(12.0),
                                                                                    child: Column(
                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                      children: [
                                                                                        Padding(
                                                                                          padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
                                                                                          child: Container(
                                                                                            decoration: BoxDecoration(
                                                                                              color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                              borderRadius: BorderRadius.circular(8.0),
                                                                                            ),
                                                                                            child: Padding(
                                                                                              padding: EdgeInsets.all(8.0),
                                                                                              child: Row(
                                                                                                mainAxisSize: MainAxisSize.max,
                                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                children: [
                                                                                                  Flexible(
                                                                                                    child: RichText(
                                                                                                      textScaler: MediaQuery.of(context).textScaler,
                                                                                                      text: TextSpan(
                                                                                                        children: [
                                                                                                          TextSpan(
                                                                                                            text: valueOrDefault<String>(
                                                                                                              serviciosFinalizadosItem.servicioNombre,
                                                                                                              '-',
                                                                                                            ),
                                                                                                            style: TextStyle(
                                                                                                              color: FlutterFlowTheme.of(context).secondary,
                                                                                                              fontWeight: FontWeight.w600,
                                                                                                              fontSize: 16.0,
                                                                                                            ),
                                                                                                          )
                                                                                                        ],
                                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                              font: GoogleFonts.inter(
                                                                                                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                              letterSpacing: 0.0,
                                                                                                              fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                            ),
                                                                                                      ),
                                                                                                    ),
                                                                                                  ),
                                                                                                  Text(
                                                                                                    '\$${(serviciosFinalizadosItem.precio + (serviciosFinalizadosItem.precioAdicionales!)).toString()} COP',
                                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                          font: GoogleFonts.inter(
                                                                                                            fontWeight: FontWeight.w600,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                          ),
                                                                                                          color: Color(0xFF3D91F4),
                                                                                                          fontSize: 16.0,
                                                                                                          letterSpacing: 0.0,
                                                                                                          fontWeight: FontWeight.w600,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                        ),
                                                                                                  ),
                                                                                                ],
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                        Padding(
                                                                                          padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
                                                                                          child: Container(
                                                                                            decoration: BoxDecoration(
                                                                                              color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                              borderRadius: BorderRadius.circular(8.0),
                                                                                            ),
                                                                                            child: Column(
                                                                                              mainAxisSize: MainAxisSize.max,
                                                                                              children: [
                                                                                                Padding(
                                                                                                  padding: EdgeInsets.all(8.0),
                                                                                                  child: Row(
                                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                    children: [
                                                                                                      Text(
                                                                                                        'Ticket',
                                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                              font: GoogleFonts.inter(
                                                                                                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                              color: FlutterFlowTheme.of(context).accent3,
                                                                                                              fontSize: 16.0,
                                                                                                              letterSpacing: 0.0,
                                                                                                              fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                            ),
                                                                                                      ),
                                                                                                      Flexible(
                                                                                                        child: Text(
                                                                                                          valueOrDefault<String>(
                                                                                                            serviciosFinalizadosItem.ticket?.toString(),
                                                                                                            '-',
                                                                                                          ),
                                                                                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                font: GoogleFonts.inter(
                                                                                                                  fontWeight: FontWeight.w600,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                ),
                                                                                                                color: FlutterFlowTheme.of(context).secondary,
                                                                                                                fontSize: 16.0,
                                                                                                                letterSpacing: 0.0,
                                                                                                                fontWeight: FontWeight.w600,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ].divide(SizedBox(width: 8.0)),
                                                                                                  ),
                                                                                                ),
                                                                                                Padding(
                                                                                                  padding: EdgeInsets.all(8.0),
                                                                                                  child: Row(
                                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                    children: [
                                                                                                      Text(
                                                                                                        'Descripcion',
                                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                              font: GoogleFonts.inter(
                                                                                                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                              color: FlutterFlowTheme.of(context).accent3,
                                                                                                              fontSize: 16.0,
                                                                                                              letterSpacing: 0.0,
                                                                                                              fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                            ),
                                                                                                      ),
                                                                                                      Flexible(
                                                                                                        child: Text(
                                                                                                          valueOrDefault<String>(
                                                                                                            serviciosFinalizadosItem.descripcion,
                                                                                                            'Sin ubicación',
                                                                                                          ),
                                                                                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                font: GoogleFonts.inter(
                                                                                                                  fontWeight: FontWeight.w600,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                ),
                                                                                                                color: FlutterFlowTheme.of(context).secondary,
                                                                                                                fontSize: 16.0,
                                                                                                                letterSpacing: 0.0,
                                                                                                                fontWeight: FontWeight.w600,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ].divide(SizedBox(width: 8.0)),
                                                                                                  ),
                                                                                                ),
                                                                                                Padding(
                                                                                                  padding: EdgeInsets.all(8.0),
                                                                                                  child: Row(
                                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                    children: [
                                                                                                      Text(
                                                                                                        'Estado',
                                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                              font: GoogleFonts.inter(
                                                                                                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                              color: FlutterFlowTheme.of(context).accent3,
                                                                                                              fontSize: 16.0,
                                                                                                              letterSpacing: 0.0,
                                                                                                              fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                            ),
                                                                                                      ),
                                                                                                      Flexible(
                                                                                                        child: Text(
                                                                                                          serviciosFinalizadosItem.estado == 'finalizadas' ? 'Finalizado' : 'Cancelado',
                                                                                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                font: GoogleFonts.inter(
                                                                                                                  fontWeight: FontWeight.w600,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                ),
                                                                                                                color: FlutterFlowTheme.of(context).secondary,
                                                                                                                fontSize: 16.0,
                                                                                                                letterSpacing: 0.0,
                                                                                                                fontWeight: FontWeight.w600,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ].divide(SizedBox(width: 8.0)),
                                                                                                  ),
                                                                                                ),
                                                                                                Padding(
                                                                                                  padding: EdgeInsets.all(8.0),
                                                                                                  child: Row(
                                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                    children: [
                                                                                                      Flexible(
                                                                                                        child: Text(
                                                                                                          dateTimeFormat(
                                                                                                            "d \'de\' MMMM \'de\' yyyy",
                                                                                                            serviciosFinalizadosItem.fecha,
                                                                                                            locale: FFLocalizations.of(context).languageCode,
                                                                                                          ),
                                                                                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                font: GoogleFonts.inter(
                                                                                                                  fontWeight: FontWeight.w600,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                                ),
                                                                                                                color: FlutterFlowTheme.of(context).secondary,
                                                                                                                fontSize: 16.0,
                                                                                                                letterSpacing: 0.0,
                                                                                                                fontWeight: FontWeight.w600,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                              ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ].divide(SizedBox(width: 8.0)),
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                        Row(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                          children: [
                                                                                            FFButtonWidget(
                                                                                              onPressed: () async {
                                                                                                await showModalBottomSheet(
                                                                                                  isScrollControlled: true,
                                                                                                  backgroundColor: Colors.transparent,
                                                                                                  isDismissible: false,
                                                                                                  useSafeArea: true,
                                                                                                  context: context,
                                                                                                  builder: (context) {
                                                                                                    return GestureDetector(
                                                                                                      onTap: () {
                                                                                                        FocusScope.of(context).unfocus();
                                                                                                        FocusManager.instance.primaryFocus?.unfocus();
                                                                                                      },
                                                                                                      child: Padding(
                                                                                                        padding: MediaQuery.viewInsetsOf(context),
                                                                                                        child: SoporteSeleccionWidget(
                                                                                                          idServicio: serviciosFinalizadosItem.ticket!.toString(),
                                                                                                          action: (respuesta) async {
                                                                                                            Navigator.pop(context);
                                                                                                            FFAppState().addToSoporte(SoporteMensajesStruct(
                                                                                                              rol: 'soporte',
                                                                                                              mensaje: respuesta,
                                                                                                              fecha: getCurrentTimestamp.toString(),
                                                                                                            ));
                                                                                                            safeSetState(() {});

                                                                                                            context.pushNamed(
                                                                                                              SoporteWidget.routeName,
                                                                                                              extra: <String, dynamic>{
                                                                                                                '__transition_info__': TransitionInfo(
                                                                                                                  hasTransition: true,
                                                                                                                  transitionType: PageTransitionType.fade,
                                                                                                                  duration: Duration(milliseconds: 0),
                                                                                                                ),
                                                                                                              },
                                                                                                            );
                                                                                                          },
                                                                                                        ),
                                                                                                      ),
                                                                                                    );
                                                                                                  },
                                                                                                ).then((value) => safeSetState(() {}));
                                                                                              },
                                                                                              text: 'Soporte',
                                                                                              icon: Icon(
                                                                                                Icons.support_agent,
                                                                                                size: 16.0,
                                                                                              ),
                                                                                              options: FFButtonOptions(
                                                                                                height: 32.0,
                                                                                                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                                                                                iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                                                                                iconColor: FlutterFlowTheme.of(context).accent3,
                                                                                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                                      font: GoogleFonts.interTight(
                                                                                                        fontWeight: FontWeight.w600,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                      ),
                                                                                                      color: FlutterFlowTheme.of(context).accent3,
                                                                                                      fontSize: 14.0,
                                                                                                      letterSpacing: 0.0,
                                                                                                      fontWeight: FontWeight.w600,
                                                                                                      fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                    ),
                                                                                                elevation: 0.0,
                                                                                                borderSide: BorderSide(
                                                                                                  color: FlutterFlowTheme.of(context).alternate,
                                                                                                  width: 1.0,
                                                                                                ),
                                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                                              ),
                                                                                            ),
                                                                                            FFButtonWidget(
                                                                                              onPressed: () async {
                                                                                                _model.vvsidd = await VwSolicitudesServiciosCompletaTable().queryRows(
                                                                                                  queryFn: (q) => q.eqOrNull(
                                                                                                    'solicitud_id',
                                                                                                    serviciosFinalizadosItem.id,
                                                                                                  ),
                                                                                                );

                                                                                                context.pushNamed(
                                                                                                  ChatWidget.routeName,
                                                                                                  queryParameters: {
                                                                                                    'servicio': serializeParam(
                                                                                                      _model.vvsidd?.firstOrNull,
                                                                                                      ParamType.SupabaseRow,
                                                                                                    ),
                                                                                                  }.withoutNulls,
                                                                                                );

                                                                                                safeSetState(() {});
                                                                                              },
                                                                                              text: 'Chat',
                                                                                              icon: Icon(
                                                                                                Icons.support_agent,
                                                                                                size: 16.0,
                                                                                              ),
                                                                                              options: FFButtonOptions(
                                                                                                height: 32.0,
                                                                                                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                                                                                iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                                                                                iconColor: FlutterFlowTheme.of(context).accent3,
                                                                                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                                      font: GoogleFonts.interTight(
                                                                                                        fontWeight: FontWeight.w600,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                      ),
                                                                                                      color: FlutterFlowTheme.of(context).accent3,
                                                                                                      fontSize: 12.0,
                                                                                                      letterSpacing: 0.0,
                                                                                                      fontWeight: FontWeight.w600,
                                                                                                      fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                    ),
                                                                                                elevation: 0.0,
                                                                                                borderSide: BorderSide(
                                                                                                  color: FlutterFlowTheme.of(context).alternate,
                                                                                                  width: 1.0,
                                                                                                ),
                                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                                              ),
                                                                                            ),
                                                                                          ].divide(SizedBox(width: 8.0)),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                              },
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    theme:
                                                                        ExpandableThemeData(
                                                                      tapHeaderToExpand:
                                                                          true,
                                                                      tapBodyToExpand:
                                                                          false,
                                                                      tapBodyToCollapse:
                                                                          false,
                                                                      headerAlignment:
                                                                          ExpandablePanelHeaderAlignment
                                                                              .center,
                                                                      hasIcon:
                                                                          true,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            height: 18.0)),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                wrapWithModel(
                  model: _model.menModel,
                  updateCallback: () => safeSetState(() {}),
                  child: MenWidget(
                    index: 0,
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
