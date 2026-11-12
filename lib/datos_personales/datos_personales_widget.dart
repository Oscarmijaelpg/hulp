import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/components/menu_bar_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'datos_personales_model.dart';
import '/backend/direcciones_usuario.dart';
import 'mis_direcciones_acceso.dart';
export 'datos_personales_model.dart';

class DatosPersonalesWidget extends StatefulWidget {
  const DatosPersonalesWidget({
    super.key,
    this.direccionesRepository,
    this.cargarCiudades,
    this.perfilStream,
  });
  final DireccionesUsuarioRepository? direccionesRepository;
  final Future<List<CiudadesRow>> Function()? cargarCiudades;
  final Stream<List<UsuariosRow>>? perfilStream;

  static String routeName = 'DatosPersonales';
  static String routePath = '/datosPersonales';

  @override
  State<DatosPersonalesWidget> createState() => _DatosPersonalesWidgetState();
}

class _DatosPersonalesWidgetState extends State<DatosPersonalesWidget> {
  late DatosPersonalesModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DatosPersonalesModel());

    _model.textFieldNomFocusNode ??= FocusNode();

    _model.textFieldApeFocusNode ??= FocusNode();

    _model.textFieldNumDocFocusNode ??= FocusNode();

    _model.textFieldTelFocusNode ??= FocusNode();

    _model.textFieldCorFocusNode ??= FocusNode();

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
    bool readOnly = false,
  }) =>
      _campo(
        etiqueta,
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          readOnly: readOnly,
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
    return StreamBuilder<List<UsuariosRow>>(
      stream: _model.datosPersonalesSupabaseStream ??= widget.perfilStream ??
          SupaFlow.client
              .from("usuarios")
              .stream(primaryKey: ['id'])
              .eqOrNull(
                'id',
                currentUserUid,
              )
              .map((list) => list.map((item) => UsuariosRow(item)).toList()),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            ),
          );
        }
        List<UsuariosRow> datosPersonalesUsuariosRowList = snapshot.data!;

        final datosPersonalesUsuariosRow =
            datosPersonalesUsuariosRowList.isNotEmpty
                ? datosPersonalesUsuariosRowList.first
                : null;

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
                'Datos personales',
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
            body: Form(
              key: _model.formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Stack(
                              alignment: AlignmentDirectional.bottomEnd,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 34),
                                  child: ClipOval(
                                    child: Image.network(
                                      valueOrDefault<String>(
                                        datosPersonalesUsuariosRow
                                            ?.fotoPerfilUrl,
                                        'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                      ),
                                      width: 112,
                                      height: 112,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Material(
                                  color: const Color(0xFF5D5D5D),
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () async {
                                      final selectedMedia =
                                          await selectMediaWithSourceBottomSheet(
                                        context: context,
                                        storageFolderPath: 'perfil',
                                        maxWidth: 1080.00,
                                        maxHeight: 1080.00,
                                        allowPhoto: true,
                                      );
                                      if (selectedMedia != null &&
                                          selectedMedia.every((m) =>
                                              validateFileFormat(
                                                  m.storagePath, context))) {
                                        safeSetState(() => _model
                                            .isDataUploading_subir = true);
                                        var selectedUploadedFiles =
                                            <FFUploadedFile>[];

                                        var downloadUrls = <String>[];
                                        try {
                                          showUploadMessage(
                                            context,
                                            'Uploading file...',
                                            showLoading: true,
                                          );
                                          selectedUploadedFiles = selectedMedia
                                              .map((m) => FFUploadedFile(
                                                    name: m.storagePath
                                                        .split('/')
                                                        .last,
                                                    bytes: m.bytes,
                                                    height:
                                                        m.dimensions?.height,
                                                    width: m.dimensions?.width,
                                                    blurHash: m.blurHash,
                                                    originalFilename:
                                                        m.originalFilename,
                                                  ))
                                              .toList();

                                          downloadUrls =
                                              await uploadSupabaseStorageFiles(
                                            bucketName: 'fotosperfil',
                                            selectedFiles: selectedMedia,
                                          );
                                        } finally {
                                          ScaffoldMessenger.of(context)
                                              .hideCurrentSnackBar();
                                          _model.isDataUploading_subir = false;
                                        }
                                        if (selectedUploadedFiles.length ==
                                                selectedMedia.length &&
                                            downloadUrls.length ==
                                                selectedMedia.length) {
                                          safeSetState(() {
                                            _model.uploadedLocalFile_subir =
                                                selectedUploadedFiles.first;
                                            _model.uploadedFileUrl_subir =
                                                downloadUrls.first;
                                          });
                                          showUploadMessage(
                                              context, 'Success!');
                                        } else {
                                          safeSetState(() {});
                                          showUploadMessage(
                                              context, 'Failed to upload data');
                                          return;
                                        }
                                      }

                                      await UsuariosTable().update(
                                        data: {
                                          'foto_perfil_url':
                                              valueOrDefault<String>(
                                            _model.uploadedFileUrl_subir,
                                            'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                          ),
                                        },
                                        matchingRows: (rows) => rows.eqOrNull(
                                          'id',
                                          datosPersonalesUsuariosRow?.id,
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.mode_edit,
                                              size: 16, color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text('Editar',
                                              style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 15)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          _fila(
                            _campoTexto(
                              'Nombres *',
                              controller: _model.textFieldNomTextController ??=
                                  TextEditingController(
                                text: datosPersonalesUsuariosRow?.nombres,
                              ),
                              focusNode: _model.textFieldNomFocusNode,
                              validator: _model
                                  .textFieldNomTextControllerValidator
                                  .asValidator(context),
                            ),
                            _campoTexto(
                              'Apellidos *',
                              controller: _model.textFieldApeTextController ??=
                                  TextEditingController(
                                text: datosPersonalesUsuariosRow?.apellidos,
                              ),
                              focusNode: _model.textFieldApeFocusNode,
                              validator: _model
                                  .textFieldApeTextControllerValidator
                                  .asValidator(context),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _fila(
                            _selector(
                              'Tipo de documento *',
                              controller: _model.dropDownDocValueController ??=
                                  FormFieldController<String>(
                                _model.dropDownDocValue ??=
                                    datosPersonalesUsuariosRow?.tipoDocumento,
                              ),
                              options: const [
                                'Cédula ciudadanía',
                                'Carnet de extranjería',
                                'Pasaporte',
                                'NIT'
                              ],
                              optionLabels: const [
                                'Cédula de ciudadanía',
                                'Cédula de extranjería',
                                'Pasaporte',
                                'NIT'
                              ],
                              onChanged: (val) => safeSetState(
                                  () => _model.dropDownDocValue = val),
                              hintText:
                                  datosPersonalesUsuariosRow?.tipoDocumento,
                              height: 50,
                              selectedMaxLines: 2,
                            ),
                            _campoTexto(
                              'Número de documento *',
                              controller:
                                  _model.textFieldNumDocTextController ??=
                                      TextEditingController(
                                text:
                                    datosPersonalesUsuariosRow?.numeroDocumento,
                              ),
                              focusNode: _model.textFieldNumDocFocusNode,
                              validator: _model
                                  .textFieldNumDocTextControllerValidator
                                  .asValidator(context),
                              height: 50,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _fila(
                            _selector(
                              'País',
                              controller: _model.dropDownValueController ??=
                                  FormFieldController<String>(
                                _model.dropDownValue ??=
                                    datosPersonalesUsuariosRow?.codigoPais,
                              ),
                              options: const ['+57'],
                              onChanged: (val) => safeSetState(
                                  () => _model.dropDownValue = val),
                              hintText: 'Seleccionar',
                            ),
                            _campoTexto(
                              'Teléfono *',
                              controller: _model.textFieldTelTextController ??=
                                  TextEditingController(
                                text: datosPersonalesUsuariosRow?.telefono,
                              ),
                              focusNode: _model.textFieldTelFocusNode,
                              validator: _model
                                  .textFieldTelTextControllerValidator
                                  .asValidator(context),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _campoTexto(
                            'Correo electrónico *',
                            controller: _model.textFieldCorTextController ??=
                                TextEditingController(
                              text:
                                  datosPersonalesUsuariosRow?.correoElectronico,
                            ),
                            focusNode: _model.textFieldCorFocusNode,
                            validator: _model
                                .textFieldCorTextControllerValidator
                                .asValidator(context),
                            readOnly: true,
                          ),
                          const SizedBox(height: 28),
                          MisDireccionesAcceso(
                            repository: widget.direccionesRepository,
                            cargarCiudades: widget.cargarCiudades,
                          ),
                          const SizedBox(height: 38),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: FFButtonWidget(
                              onPressed: () async {
                                if (_model.formKey.currentState == null ||
                                    !_model.formKey.currentState!.validate()) {
                                  return;
                                }
                                if (_model.dropDownDocValue == null) {
                                  await showDialog(
                                    context: context,
                                    builder: (alertDialogContext) {
                                      return AlertDialog(
                                        title: Text('Tipo documento'),
                                        content: Text('Es requerido'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                                alertDialogContext),
                                            child: Text('Ok'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  return;
                                }
                                if (_model.dropDownValue == null) {
                                  await showDialog(
                                    context: context,
                                    builder: (alertDialogContext) {
                                      return AlertDialog(
                                        title: Text('Pais'),
                                        content: Text('Es requerido'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                                alertDialogContext),
                                            child: Text('Ok'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  return;
                                }
                                await UsuariosTable().update(
                                  data: {
                                    'nombres':
                                        _model.textFieldNomTextController.text,
                                    'apellidos':
                                        _model.textFieldApeTextController.text,
                                    'tipo_documento': _model.dropDownDocValue,
                                    'numero_documento': _model
                                        .textFieldNumDocTextController.text,
                                    'codigo_pais': _model.dropDownValue,
                                    'telefono':
                                        _model.textFieldTelTextController.text,
                                    'correo_electronico':
                                        _model.textFieldCorTextController.text,
                                  },
                                  matchingRows: (rows) => rows.eqOrNull(
                                    'id',
                                    datosPersonalesUsuariosRow?.id,
                                  ),
                                );
                                context.safePop();
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
                      ),
                    ),
                  ),
                  wrapWithModel(
                    model: _model.menuBarModel,
                    updateCallback: () => safeSetState(() {}),
                    child: const MenuBarWidget(index: 0, resaltarCuenta: true),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
