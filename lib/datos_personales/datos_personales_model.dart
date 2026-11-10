import '/backend/supabase/supabase.dart';
import '/components/menu_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'datos_personales_widget.dart' show DatosPersonalesWidget;
import 'package:flutter/material.dart';

class DatosPersonalesModel extends FlutterFlowModel<DatosPersonalesWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  Stream<List<UsuariosRow>>? datosPersonalesSupabaseStream;
  bool isDataUploading_subir = false;
  FFUploadedFile uploadedLocalFile_subir =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_subir = '';

  // State field(s) for TextFieldNom widget.
  FocusNode? textFieldNomFocusNode;
  TextEditingController? textFieldNomTextController;
  String? Function(BuildContext, String?)? textFieldNomTextControllerValidator;
  String? _textFieldNomTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'nombre es requerido';
    }

    return null;
  }

  // State field(s) for TextFieldApe widget.
  FocusNode? textFieldApeFocusNode;
  TextEditingController? textFieldApeTextController;
  String? Function(BuildContext, String?)? textFieldApeTextControllerValidator;
  String? _textFieldApeTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'apellidos es requerido';
    }

    return null;
  }

  // State field(s) for DropDownDoc widget.
  String? dropDownDocValue;
  FormFieldController<String>? dropDownDocValueController;
  // State field(s) for TextFieldNumDoc widget.
  FocusNode? textFieldNumDocFocusNode;
  TextEditingController? textFieldNumDocTextController;
  String? Function(BuildContext, String?)?
      textFieldNumDocTextControllerValidator;
  String? _textFieldNumDocTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'numero_documento es requerido';
    }

    return null;
  }

  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // State field(s) for TextFieldTel widget.
  FocusNode? textFieldTelFocusNode;
  TextEditingController? textFieldTelTextController;
  String? Function(BuildContext, String?)? textFieldTelTextControllerValidator;
  String? _textFieldTelTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'telefono es requerido';
    }

    return null;
  }

  // State field(s) for TextFieldCor widget.
  FocusNode? textFieldCorFocusNode;
  TextEditingController? textFieldCorTextController;
  String? Function(BuildContext, String?)? textFieldCorTextControllerValidator;
  String? _textFieldCorTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'correo_electronico es requerido';
    }

    return null;
  }

  // Model for MenuBar component.
  late MenuBarModel menuBarModel;

  @override
  void initState(BuildContext context) {
    textFieldNomTextControllerValidator = _textFieldNomTextControllerValidator;
    textFieldApeTextControllerValidator = _textFieldApeTextControllerValidator;
    textFieldNumDocTextControllerValidator =
        _textFieldNumDocTextControllerValidator;
    textFieldTelTextControllerValidator = _textFieldTelTextControllerValidator;
    textFieldCorTextControllerValidator = _textFieldCorTextControllerValidator;
    menuBarModel = createModel(context, () => MenuBarModel());
  }

  @override
  void dispose() {
    textFieldNomFocusNode?.dispose();
    textFieldNomTextController?.dispose();

    textFieldApeFocusNode?.dispose();
    textFieldApeTextController?.dispose();

    textFieldNumDocFocusNode?.dispose();
    textFieldNumDocTextController?.dispose();

    textFieldTelFocusNode?.dispose();
    textFieldTelTextController?.dispose();

    textFieldCorFocusNode?.dispose();
    textFieldCorTextController?.dispose();

    menuBarModel.dispose();
  }
}
