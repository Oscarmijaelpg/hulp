import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'registro6_model.dart';
export 'registro6_model.dart';

class Registro6Widget extends StatefulWidget {
  const Registro6Widget({super.key});

  static String routeName = 'registro6';
  static String routePath = '/registro6';

  @override
  State<Registro6Widget> createState() => _Registro6WidgetState();
}

class _Registro6WidgetState extends State<Registro6Widget> {
  late Registro6Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Registro6Model());

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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: FlutterFlowTheme.of(context).primaryText,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            'Registro',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 18.0,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 0.5,
        ),
        body: SafeArea(
          // Reserva el hueco de la barra de navegacion del movil:
          // sin esto el boton de abajo queda debajo de los botones
          // del sistema y no se puede pulsar bien.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          textScaler: MediaQuery.of(context).textScaler,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Antes de comenzar…',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context).primary,
                                      fontSize: 20.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                              TextSpan(
                                text: '',
                                style: TextStyle(
                                  color: Color(0xFF7C766C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20.0,
                                ),
                              )
                            ],
                            style:
                                FlutterFlowTheme.of(context).bodyMedium.override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF0B6244),
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
                        Padding(
                          padding:
                              EdgeInsetsDirectional.fromSTEB(1.0, 16.0, 0.0, 0.0),
                          child: Text(
                            'Queremos recordarte algunos puntos clave sobre el uso de Hulp como proveedor.',
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
                                  color:
                                      FlutterFlowTheme.of(context).secondaryText,
                                  fontSize: 17.0,
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
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 16.0, 16.0, 0.0),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: AlignmentDirectional(-1.0, 0.0),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        1.0, 0.0, 0.0, 0.0),
                                    child: RichText(
                                      textScaler:
                                          MediaQuery.of(context).textScaler,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '  1. Recuerda',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  color:
                                                      FlutterFlowTheme.of(context)
                                                          .primary,
                                                  fontSize: 20.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                          TextSpan(
                                            text: '',
                                            style: TextStyle(
                                              color: Color(0xFF7C766C),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20.0,
                                            ),
                                          )
                                        ],
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color: Color(0xFF0B6244),
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: AlignmentDirectional(-1.0, 0.0),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        10.0, 16.0, 10.0, 16.0),
                                    child: Text(
                                      'Hulp no es tu jefe. Somos una plataforma que te conecta con personas que necesitan tus servicios, pero tú decides cuándo, y dónde trabajas.\n\nActúas como proveedor independiente, lo que significa que no existe una relación laboral entre tú y Hulp. Tú eres el único responsable de la calidad del servicio, tu presentación personal y el cumplimiento de las normas legales.\n\nCualquier incumplimiento puede resultar en la suspensión o cancelación de tu cuenta. Usa la app con responsabilidad, sigue las buenas prácticas y sé siempre profesional.\n',
                                      textAlign: TextAlign.start,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontSize: 16.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                ),
                                Divider(
                                  thickness: 1.0,
                                  color: Color(0xFF757575),
                                ),
                                SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Align(
                                        alignment:
                                            AlignmentDirectional(-1.0, 0.0),
                                        child: RichText(
                                          textScaler:
                                              MediaQuery.of(context).textScaler,
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: '  2. Pagos y comisión',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: FlutterFlowTheme.of(
                                                              context)
                                                          .primary,
                                                      fontSize: 20.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight: FontWeight.w600,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                              TextSpan(
                                                text: '',
                                                style: TextStyle(
                                                  color: Color(0xFF7C766C),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20.0,
                                                ),
                                              )
                                            ],
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight: FontWeight.normal,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  color: Color(0xFF0B6244),
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.normal,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                          textAlign: TextAlign.start,
                                        ),
                                      ),
                                      Align(
                                        alignment:
                                            AlignmentDirectional(-1.0, 0.0),
                                        child: Padding(
                                          padding: EdgeInsetsDirectional.fromSTEB(
                                              10.0, 16.0, 10.0, 16.0),
                                          child: Text(
                                            'Todos los pagos se procesan a través de nuestra pasarela oficial. Por cada servicio realizado, Hulp retiene una comisión minoritaria, y el valor restante se transfiere semanalmente a la cuenta registrada. Hulp no aplica comisiones sobre materiales pagados directamente a través de la app.\nCualquier cobro o pago realizado por fuera de la plataforma con usuarios de Hulp puede resultar en sanciones o la suspensión de tu cuenta.\n\nEn caso de que un cliente presente una queja o solicite un reembolso, el pago podrá ser retenido temporalmente hasta que se resuelva el caso. La transparencia y el uso adecuado del sistema de pagos son esenciales para continuar operando dentro de la plataforma.\n\n.',
                                            textAlign: TextAlign.start,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
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
                                                  color:
                                                      FlutterFlowTheme.of(context)
                                                          .secondaryText,
                                                  fontSize: 16.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                        ),
                                      ),
                                      Divider(
                                        thickness: 1.0,
                                        color: Color(0xFF757575),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: AlignmentDirectional(-1.0, 0.0),
                          child: RichText(
                            textScaler: MediaQuery.of(context).textScaler,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '  3. Términos y condiciones',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .fontStyle,
                                        ),
                                        color:
                                            FlutterFlowTheme.of(context).primary,
                                        fontSize: 20.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                                TextSpan(
                                  text: '',
                                  style: TextStyle(
                                    color: Color(0xFF7C766C),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.0,
                                  ),
                                )
                              ],
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
                                    color: Color(0xFF0B6244),
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
                        Align(
                          alignment: AlignmentDirectional(-1.0, 0.0),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 16.0, 10.0, 16.0),
                            child: Text(
                              'Al usar Talento HULP aceptas nuestros Términos y Condiciones. Actúas como un proveedor independiente, y eres el único responsable por el servicio que prestas.\n\nDebes mantener tu información actualizada, cumplir con los horarios de los servicios que aceptar, asistir con las herramientas necesarias y actuar con respeto y profesionalismo. En caso de mal comportamiento, servicio deficiente o fraude, podrías ser suspendido.\n\nTe pedimos leer los términos y condiciones completos tanto en el app movil como en hulp.com/terminos para conocer tus derechos y obligaciones dentro de la plataforma.',
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
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
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
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Theme(
                        data: ThemeData(
                          checkboxTheme: CheckboxThemeData(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          unselectedWidgetColor:
                              FlutterFlowTheme.of(context).alternate,
                        ),
                        child: Checkbox(
                          value: _model.checkboxValue ??= false,
                          onChanged: (newValue) async {
                            safeSetState(() => _model.checkboxValue = newValue!);
                          },
                          side: (FlutterFlowTheme.of(context).alternate != null)
                              ? BorderSide(
                                  width: 2,
                                  color: FlutterFlowTheme.of(context).alternate!,
                                )
                              : null,
                          activeColor: FlutterFlowTheme.of(context).primary,
                          checkColor: FlutterFlowTheme.of(context).info,
                        ),
                      ),
                      Flexible(
                        child: Align(
                          alignment: AlignmentDirectional(-1.0, 0.0),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 16.0, 10.0, 16.0),
                            child: Text(
                              'He leído y acepto los términos y condiciones de la plataforma',
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
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
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
                      ),
                    ].divide(SizedBox(width: 8.0)),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(40.0, 20.0, 40.0, 36.0),
                    child: FFButtonWidget(
                      onPressed: (_model.checkboxValue == false)
                          ? null
                          : () async {
                              // En el registro con Apple la sesión de Supabase ya
                              // existe: solo falta crear el perfil.
                              if (!FFAppState().registroExterno) {
                                GoRouter.of(context).prepareAuthEvent();

                                final user =
                                    await authManager.createAccountWithEmail(
                                  context,
                                  FFAppState().registro.correo,
                                  FFAppState().registro.contrasena,
                                );
                                if (user == null) {
                                  return;
                                }
                              }

                              await UsuariosTable().insert({
                                'id': currentUserUid,
                                'nombres': FFAppState().registro.nombres,
                                'apellidos': FFAppState().registro.apellidos,
                                'tipo_documento':
                                    FFAppState().registro.tipodocumento,
                                'numero_documento':
                                    FFAppState().registro.numerodocumento,
                                'pais': FFAppState().registro.pais,
                                'codigo_pais': FFAppState().registro.pais,
                                'telefono': FFAppState().registro.telefono,
                                'correo_electronico':
                                    FFAppState().registro.correo,
                                'direccion': FFAppState().registro.direccion,
                                'foto_perfil_url': FFAppState().registro.foto,
                                'rol': 'proveedor',
                                'fecha_registro':
                                    supaSerialize<DateTime>(getCurrentTimestamp),
                                'anios_experiencia':
                                    FFAppState().registro.anosexp,
                                'registro_tributario':
                                    FFAppState().registro.tributario,
                                'verificado': 'pendiente',
                                'ciudad': FFAppState().registro.ciudad,
                                'usuario_externo': FFAppState().registroExterno,
                              });
                              await Future.wait([
                                Future(() async {
                                  if (FFAppState()
                                          .registro
                                          .certificaciones
                                          .length >
                                      0) {
                                    for (int loop1Index = 0;
                                        loop1Index <
                                            FFAppState()
                                                .registro
                                                .certificaciones
                                                .length;
                                        loop1Index++) {
                                      final currentLoop1Item = FFAppState()
                                          .registro
                                          .certificaciones[loop1Index];
                                      await CertificacionesTable().insert({
                                        'usuario_id': currentUserUid,
                                        'entidad_certificadora':
                                            currentLoop1Item.nombreentidad,
                                        'documento_url':
                                            currentLoop1Item.linkarchivo,
                                      });
                                    }
                                  } else {
                                    return;
                                  }

                                  await Future.delayed(
                                    Duration(
                                      milliseconds: 1,
                                    ),
                                  );
                                }),
                                Future(() async {
                                  if (FFAppState().registro.referencias.length >
                                      0) {
                                    for (int loop2Index = 0;
                                        loop2Index <
                                            FFAppState()
                                                .registro
                                                .referencias
                                                .length;
                                        loop2Index++) {
                                      final currentLoop2Item = FFAppState()
                                          .registro
                                          .referencias[loop2Index];
                                      await ReferenciasLaboralesTable().insert({
                                        'usuario_id': currentUserUid,
                                        'nombre_referencia':
                                            currentLoop2Item.nombres,
                                        'telefono_referencia':
                                            currentLoop2Item.telefono,
                                        'relacion_laboral':
                                            currentLoop2Item.relacion,
                                      });
                                    }
                                  } else {
                                    return;
                                  }

                                  await Future.delayed(
                                    Duration(
                                      milliseconds: 1,
                                    ),
                                  );
                                }),
                                Future(() async {
                                  if (FFAppState().idServiciosList.length > 0) {
                                    for (int loop3Index = 0;
                                        loop3Index <
                                            FFAppState().idServiciosList.length;
                                        loop3Index++) {
                                      final currentLoop3Item = FFAppState()
                                          .idServiciosList[loop3Index];
                                      await ProfesionalServiciosTable().insert({
                                        'usuario_id': currentUserUid,
                                        'servicio_id': currentLoop3Item,
                                      });
                                    }
                                  } else {
                                    return;
                                  }

                                  await Future.delayed(
                                    Duration(
                                      milliseconds: 1,
                                    ),
                                  );
                                }),
                                Future(() async {
                                  // La cuenta bancaria se guardaba solo si el
                                  // proveedor habia cargado referencias
                                  // laborales (la condicion venia copiada del
                                  // bloque de arriba), asi que quien no cargaba
                                  // referencias se quedaba sin datos de
                                  // facturacion. Ahora depende de sus propios
                                  // datos.
                                  if (FFAppState()
                                          .registro
                                          .numerodecuenta
                                          .isNotEmpty ||
                                      FFAppState().registro.entidad.isNotEmpty) {
                                    await CuentasBancariasTable().insert({
                                      'usuario_id': currentUserUid,
                                      'entidad_bancaria':
                                          FFAppState().registro.entidad,
                                      'tipo_cuenta':
                                          FFAppState().registro.tipodecuenta,
                                      'numero_cuenta':
                                          FFAppState().registro.numerodecuenta,
                                      'nombre_titular':
                                          FFAppState().registro.nombretitular,
                                    });
                                  } else {
                                    return;
                                  }

                                  await Future.delayed(
                                    Duration(
                                      milliseconds: 1,
                                    ),
                                  );
                                }),
                              ]);

                              FFAppState().registroExterno = false;

                              context.pushNamedAuth(
                                  SplashLoginWidget.routeName, context.mounted);
                            },
                      text: 'Aceptar y continuar',
                      options: FFButtonOptions(
                        width: MediaQuery.sizeOf(context).width * 1.0,
                        height: 44.0,
                        padding:
                            EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(20.0),
                        disabledColor: FlutterFlowTheme.of(context).primary,
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
