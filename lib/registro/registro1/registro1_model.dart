import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'registro1_widget.dart' show Registro1Widget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Registro1Model extends FlutterFlowModel<Registro1Widget> {
  ///  Local state fields for this page.

  List<String> listRedes = [];
  void addToListRedes(String item) => listRedes.add(item);
  void removeFromListRedes(String item) => listRedes.remove(item);
  void removeAtIndexFromListRedes(int index) => listRedes.removeAt(index);
  void insertAtIndexInListRedes(int index, String item) =>
      listRedes.insert(index, item);
  void updateListRedesAtIndex(int index, Function(String) updateFn) =>
      listRedes[index] = updateFn(listRedes[index]);

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  bool isDataUploading_perfil2 = false;
  FFUploadedFile uploadedLocalFile_perfil2 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_perfil2 = '';

  // State field(s) for name widget.
  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;
  String? Function(BuildContext, String?)? nameTextControllerValidator;
  String? _nameTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'El nombre es obligatorio';
    }

    if (val.length < 1) {
      return 'Requires at least 1 characters.';
    }
    if (val.length > 25) {
      return '25 caracteres maximos';
    }

    return null;
  }

  // State field(s) for lastName widget.
  FocusNode? lastNameFocusNode;
  TextEditingController? lastNameTextController;
  String? Function(BuildContext, String?)? lastNameTextControllerValidator;
  String? _lastNameTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'El apellido es obligatorio';
    }

    if (val.length < 1) {
      return 'Requires at least 1 characters.';
    }
    if (val.length > 25) {
      return '25 caracteres maximos';
    }

    return null;
  }

  // State field(s) for dropdownTypeDocument widget.
  String? dropdownTypeDocumentValue;
  FormFieldController<String>? dropdownTypeDocumentValueController;
  // State field(s) for inputnNumberDocument widget.
  FocusNode? inputnNumberDocumentFocusNode;
  TextEditingController? inputnNumberDocumentTextController;
  String? Function(BuildContext, String?)?
      inputnNumberDocumentTextControllerValidator;
  String? _inputnNumberDocumentTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'El nro de documento es obligatorio';
    }

    if (val.length < 1) {
      return 'Requires at least 1 characters.';
    }
    if (val.length > 25) {
      return '25 caracteres maximos';
    }

    return null;
  }

  /// Ciudades en las que opera Hulp, leidas de la tabla `ciudades`.
  ///
  /// Arranca vacia y se rellena al abrir la pantalla: si la consulta falla, el
  /// desplegable queda sin opciones en vez de ofrecer ciudades inventadas.
  List<String> ciudades = [];

  Future<void> cargarCiudades() async {
    try {
      final filas = await CiudadesTable().queryRows(
        queryFn: (q) =>
            q.eqOrNull('activo', true).order('nombre', ascending: true),
      );
      ciudades = filas.map((c) => c.nombre).toList();
    } catch (e) {
      print('No se pudieron cargar las ciudades: $e');
    }
  }

  // State field(s) for dropdownCiudad widget.
  String? dropdownCiudadValue;
  FormFieldController<String>? dropdownCiudadValueController;
  // State field(s) for dropdownCountry widget.
  String? dropdownCountryValue;
  FormFieldController<String>? dropdownCountryValueController;
  // State field(s) for inputPhoneNumber widget.
  FocusNode? inputPhoneNumberFocusNode;
  TextEditingController? inputPhoneNumberTextController;
  String? Function(BuildContext, String?)?
      inputPhoneNumberTextControllerValidator;
  String? _inputPhoneNumberTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Telefono es requerido';
    }

    if (val.length < 1) {
      return 'Requires at least 1 characters.';
    }
    if (val.length > 25) {
      return '25 caracteres maximos';
    }

    return null;
  }

  // State field(s) for direccion widget.
  FocusNode? direccionFocusNode;
  TextEditingController? direccionTextController;
  String? Function(BuildContext, String?)? direccionTextControllerValidator;
  String? _direccionTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'La direccion es requerida';
    }

    return null;
  }

  // State field(s) for inputEmail widget.
  FocusNode? inputEmailFocusNode;
  TextEditingController? inputEmailTextController;
  String? Function(BuildContext, String?)? inputEmailTextControllerValidator;
  String? _inputEmailTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'El correo electronico es requerido';
    }

    if (!RegExp(kTextValidatorEmailRegex).hasMatch(val)) {
      return 'Has to be a valid email address.';
    }
    return null;
  }

  // State field(s) for red1 widget.
  FocusNode? red1FocusNode;
  TextEditingController? red1TextController;
  String? Function(BuildContext, String?)? red1TextControllerValidator;
  // State field(s) for red2 widget.
  FocusNode? red2FocusNode;
  TextEditingController? red2TextController;
  String? Function(BuildContext, String?)? red2TextControllerValidator;
  // Stores action output result for [Custom Action - checkEmail] action in Button widget.
  bool? emailExist;

  @override
  void initState(BuildContext context) {
    nameTextControllerValidator = _nameTextControllerValidator;
    lastNameTextControllerValidator = _lastNameTextControllerValidator;
    inputnNumberDocumentTextControllerValidator =
        _inputnNumberDocumentTextControllerValidator;
    inputPhoneNumberTextControllerValidator =
        _inputPhoneNumberTextControllerValidator;
    direccionTextControllerValidator = _direccionTextControllerValidator;
    inputEmailTextControllerValidator = _inputEmailTextControllerValidator;
  }

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();

    lastNameFocusNode?.dispose();
    lastNameTextController?.dispose();

    inputnNumberDocumentFocusNode?.dispose();
    inputnNumberDocumentTextController?.dispose();

    inputPhoneNumberFocusNode?.dispose();
    inputPhoneNumberTextController?.dispose();

    direccionFocusNode?.dispose();
    direccionTextController?.dispose();

    inputEmailFocusNode?.dispose();
    inputEmailTextController?.dispose();

    red1FocusNode?.dispose();
    red1TextController?.dispose();

    red2FocusNode?.dispose();
    red2TextController?.dispose();
  }
}
