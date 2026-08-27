import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/components/menu_bar_widget.dart';
import '/index.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'desactivarcuenta_model.dart';
export 'desactivarcuenta_model.dart';

class DesactivarcuentaWidget extends StatefulWidget {
  const DesactivarcuentaWidget({super.key});

  static String routeName = 'desactivarcuenta';
  static String routePath = '/desactivarcuenta';

  @override
  State<DesactivarcuentaWidget> createState() => _DesactivarcuentaWidgetState();
}

class _DesactivarcuentaWidgetState extends State<DesactivarcuentaWidget> {
  late DesactivarcuentaModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DesactivarcuentaModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  void _mostrarMensaje(String texto, {bool esError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: esError
            ? FlutterFlowTheme.of(context).error
            : FlutterFlowTheme.of(context).primary,
      ),
    );
  }

  Future<bool> _confirmar() async {
    final respuesta = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('¿Eliminar tu cuenta?'),
        content: Text(
          'Esta acción es permanente. No podrás recuperar tu cuenta '
          'ni volver a iniciar sesión con ella.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Eliminar',
              style: TextStyle(color: FlutterFlowTheme.of(context).error),
            ),
          ),
        ],
      ),
    );
    return respuesta ?? false;
  }

  Future<void> _eliminarCuenta() async {
    if (!await _confirmar()) return;

    safeSetState(() => _model.eliminando = true);

    try {
      await SupaFlow.client.rpc('eliminar_mi_cuenta');
    } catch (e) {
      debugPrint('Error eliminando la cuenta: $e');
      if (mounted) {
        safeSetState(() => _model.eliminando = false);
        _mostrarMensaje('No pudimos eliminar tu cuenta. Intenta más tarde.');
      }
      return;
    }

    // A partir de aqui el borrado YA se hizo. signOut() puede responder 401
    // porque la cuenta dejo de existir, y eso no es un fallo: si se dejara
    // dentro del try de arriba, se mostraria "no pudimos eliminar tu cuenta"
    // justo despues de haberla eliminado.
    if (!mounted) return;
    try {
      GoRouter.of(context).prepareAuthEvent();
      await authManager.signOut();
      GoRouter.of(context).clearRedirectLocation();
    } catch (e) {
      debugPrint('signOut tras eliminar la cuenta: $e');
    }

    if (!mounted) return;
    safeSetState(() => _model.eliminando = false);
    _mostrarMensaje('Tu cuenta fue eliminada', esError: false);
    context.goNamedAuth(LoginWidget.routeName, context.mounted);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        // El teclado se superpone en vez de encoger la pantalla: si no,
        // el menu inferior sube y queda pegado sobre las teclas.
        resizeToAvoidBottomInset: false,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: Color(0xFFEFF3ED),
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 54.0,
            icon: FaIcon(
              FontAwesomeIcons.angleLeft,
              color: FlutterFlowTheme.of(context).primaryText,
              size: 24.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            'Eliminar cuenta',
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
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: AlignmentDirectional(-1.0, 0.0),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 35.0, 16.0, 0.0),
                child: RichText(
                  textScaler: MediaQuery.of(context).textScaler,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Antes de continuar, ',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).texto1,
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
                      TextSpan(
                        text:
                            'asegúrate de comprender el significado de eliminar tu cuenta.',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).texto1,
                          fontWeight: FontWeight.w600,
                          fontSize: 16.0,
                        ),
                      ),
                      TextSpan(
                        text: '\n\nAl eliminarla, tu cuenta y tus datos personales ',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).texto1,
                          fontSize: 16.0,
                        ),
                      ),
                      TextSpan(
                        text: 'se borrarán de forma permanente. ',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).texto1,
                          fontWeight: FontWeight.w600,
                          fontSize: 16.0,
                        ),
                      ),
                      TextSpan(
                        text:
                            'No hay forma de recuperarla ni de volver a iniciar sesión con ella. Por obligaciones contables se conservan los comprobantes de los servicios ya pagados, sin ningún dato que te identifique.',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).texto1,
                          fontSize: 16.0,
                        ),
                      )
                    ],
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
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
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional(0.0, 1.0),
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 15.0),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    // Camino propio, sin AlertCerrarsesionWidget: ese componente
                    // lo comparte el "Cerrar sesion" de Mi Perfil y solo hace
                    // signOut(). Meterle el borrado ahi romperia el logout.
                    onTap: _model.eliminando ? null : () => _eliminarCuenta(),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      decoration: BoxDecoration(
                        color: Color(0xFFFDE7EA),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: Color(0xFFEF4354),
                        ),
                      ),
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(4.0, 8.0, 4.0, 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.asset(
                                'assets/images/account_circle_off_(1).png',
                                width: 24.0,
                                height: 24.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Text(
                              'Eliminar cuenta',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFFBC1021),
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(SizedBox(width: 8.0)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            wrapWithModel(
              model: _model.menuBarModel,
              updateCallback: () => safeSetState(() {}),
              child: MenuBarWidget(
                index: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
