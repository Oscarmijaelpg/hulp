import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'datospersonales_model.dart';
export 'datospersonales_model.dart';

class DatospersonalesWidget extends StatefulWidget {
  const DatospersonalesWidget({super.key});

  static String routeName = 'Datospersonales';
  static String routePath = '/datospersonales';

  @override
  State<DatospersonalesWidget> createState() => _DatospersonalesWidgetState();
}

class _DatospersonalesWidgetState extends State<DatospersonalesWidget> {
  late DatospersonalesModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DatospersonalesModel());

    _model.nombreFocusNode ??= FocusNode();

    _model.apellidoFocusNode ??= FocusNode();

    _model.numeroDocumentoFocusNode ??= FocusNode();

    _model.telefonoFocusNode ??= FocusNode();

    _model.direccionFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  static const _fondoCampo = Color(0xFFF7F7F7);
  static const _borde = Color(0xFFC4C4C8);
  static const _radioCampo = 14.0;

  TextStyle get _estiloValor => GoogleFonts.inter(
        color: const Color(0xFF161323),
        fontSize: 16,
      );

  InputDecoration _decoracion({String? hint, double height = 48}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radioCampo),
      borderSide: const BorderSide(color: _borde),
    );
    final errorBorder = border.copyWith(
      borderSide: BorderSide(color: FlutterFlowTheme.of(context).error),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: _estiloValor.copyWith(color: const Color(0xFF737373)),
      isDense: true,
      filled: true,
      fillColor: _fondoCampo,
      constraints: BoxConstraints(minHeight: height),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: (height - 18) / 2,
      ),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary),
      ),
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
    );
  }

  Widget _fila(Widget izquierda, Widget derecha) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: izquierda),
          const SizedBox(width: 18),
          Expanded(child: derecha),
        ],
      );

  Widget _campo(String etiqueta, Widget control) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            etiqueta,
            style: GoogleFonts.inter(
              color: const Color(0xFF505050),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          control,
        ],
      );

  Widget _campoTexto(
    String etiqueta, {
    required TextEditingController controller,
    required FocusNode? focusNode,
    required FormFieldValidator<String>? validator,
    double height = 48,
  }) =>
      _campo(
        etiqueta,
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          textAlignVertical: TextAlignVertical.center,
          decoration: _decoracion(hint: etiqueta, height: height),
          style: _estiloValor,
          cursorColor: FlutterFlowTheme.of(context).primaryText,
        ),
      );

  Widget _selector(
    String etiqueta, {
    required FormFieldController<String> controller,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    List<String>? optionLabels,
    String? hintText,
    double height = 48,
    int selectedMaxLines = 1,
  }) =>
      _campo(
        etiqueta,
        FlutterFlowDropDown<String>(
          controller: controller,
          options: options,
          optionLabels: optionLabels,
          onChanged: onChanged,
          hintText: hintText,
          height: height,
          selectedMaxLines: selectedMaxLines,
          textStyle: _estiloValor,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF5D5D5D),
            size: 24,
          ),
          fillColor: _fondoCampo,
          elevation: 2,
          borderColor: _borde,
          borderWidth: 1,
          borderRadius: _radioCampo,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          hidesUnderline: true,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: const Color(0xFF293332),
              size: 22,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            'Datos Personales',
            style: GoogleFonts.interTight(
              color: const Color(0xFF102621),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          toolbarHeight: 56,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: _borde),
          ),
        ),
        body: SafeArea(
          top: true,
          child: FutureBuilder<List<UsuariosRow>>(
            future: UsuariosTable().querySingleRow(
              queryFn: (q) => q.eqOrNull(
                'id',
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                );
              }
              List<UsuariosRow> columnUsuariosRowList = snapshot.data!;

              final columnUsuariosRow = columnUsuariosRowList.isNotEmpty
                  ? columnUsuariosRowList.first
                  : null;

              return Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Form(
                        key: _model.formKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: ClipOval(
                                child: Image.network(
                                  valueOrDefault<String>(
                                    columnUsuariosRow?.fotoPerfilUrl,
                                    'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                  ),
                                  width: 112,
                                  height: 112,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            _fila(
                              _campoTexto(
                                'Nombres *',
                                controller: _model.nombreTextController ??=
                                    TextEditingController(
                                  text: columnUsuariosRow?.nombres,
                                ),
                                focusNode: _model.nombreFocusNode,
                                validator: _model.nombreTextControllerValidator
                                    .asValidator(context),
                              ),
                              _campoTexto(
                                'Apellidos *',
                                controller: _model.apellidoTextController ??=
                                    TextEditingController(
                                  text: columnUsuariosRow?.apellidos,
                                ),
                                focusNode: _model.apellidoFocusNode,
                                validator: _model
                                    .apellidoTextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _fila(
                              _selector(
                                'Tipo documento *',
                                controller:
                                    _model.tipoDocumentoValueController ??=
                                        FormFieldController<String>(
                                  _model.tipoDocumentoValue ??=
                                      columnUsuariosRow?.tipoDocumento,
                                ),
                                options: const [
                                  'Cédula de ciudadana',
                                  'Cédula de extranjería',
                                  'NIT',
                                  'PPT',
                                ],
                                optionLabels: const [
                                  'Cédula de ciudadanía',
                                  'Cédula de extranjería',
                                  'NIT',
                                  'PPT',
                                ],
                                onChanged: (val) => safeSetState(
                                    () => _model.tipoDocumentoValue = val),
                                hintText: columnUsuariosRow?.tipoDocumento,
                                height: 50,
                                selectedMaxLines: 2,
                              ),
                              _campoTexto(
                                'Número de documento *',
                                controller:
                                    _model.numeroDocumentoTextController ??=
                                        TextEditingController(
                                  text: columnUsuariosRow?.numeroDocumento,
                                ),
                                focusNode: _model.numeroDocumentoFocusNode,
                                validator: _model
                                    .numeroDocumentoTextControllerValidator
                                    .asValidator(context),
                                height: 50,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _fila(
                              _selector(
                                'País *',
                                controller: _model.paisValueController ??=
                                    FormFieldController<String>(
                                  _model.paisValue ??=
                                      columnUsuariosRow?.codigoPais,
                                ),
                                options: const ['+57'],
                                onChanged: (val) =>
                                    safeSetState(() => _model.paisValue = val),
                                hintText: 'Seleccionar',
                              ),
                              _campoTexto(
                                'Teléfono *',
                                controller: _model.telefonoTextController ??=
                                    TextEditingController(
                                  text: columnUsuariosRow?.telefono,
                                ),
                                focusNode: _model.telefonoFocusNode,
                                validator: _model
                                    .telefonoTextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _campo(
                              'Correo electrónico',
                              InputDecorator(
                                decoration: _decoracion(),
                                child: SelectableText(
                                  (columnUsuariosRow?.correoElectronico
                                              ?.trim()
                                              .isNotEmpty ??
                                          false)
                                      ? columnUsuariosRow!.correoElectronico!
                                      : (currentUserEmail.isNotEmpty
                                          ? currentUserEmail
                                          : 'Sin correo registrado'),
                                  style: _estiloValor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _campoTexto(
                              'Dirección (Opcional)',
                              controller: _model.direccionTextController ??=
                                  TextEditingController(
                                text: columnUsuariosRow?.direccion,
                              ),
                              focusNode: _model.direccionFocusNode,
                              validator: _model.direccionTextControllerValidator
                                  .asValidator(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: FFButtonWidget(
                      onPressed: () async {
                        if (_model.formKey.currentState == null ||
                            !_model.formKey.currentState!.validate()) {
                          return;
                        }
                        if (_model.tipoDocumentoValue == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'El tipo de documento es obligatorio',
                                style: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFFFDFEFF),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                              ),
                              duration: Duration(milliseconds: 4000),
                              backgroundColor: Color(0xFFFC0505),
                            ),
                          );
                          return;
                        }
                        if (_model.paisValue == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Seleccione el codigo de pais',
                                style: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: Colors.white,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                              ),
                              duration: Duration(milliseconds: 4000),
                              backgroundColor:
                                  FlutterFlowTheme.of(context).error,
                            ),
                          );
                          return;
                        }
                        await UsuariosTable().update(
                          data: {
                            'nombres': _model.nombreTextController.text,
                            'apellidos': _model.apellidoTextController.text,
                            'tipo_documento': _model.tipoDocumentoValue,
                            'numero_documento':
                                _model.numeroDocumentoTextController.text,
                            'codigo_pais': _model.paisValue,
                            'telefono': _model.telefonoTextController.text,
                            'direccion': _model.direccionTextController.text,
                          },
                          matchingRows: (rows) => rows.eqOrNull(
                            'id',
                            currentUserUid,
                          ),
                        );

                        context.pushNamed(MiperfilWidget.routeName);
                      },
                      text: 'Guardar',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 52,
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: GoogleFonts.interTight(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        elevation: 0,
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
