import '/flutter_flow/flutter_flow_util.dart';
import 'nequi_registro_widget.dart' show NequiRegistroWidget;
import 'package:flutter/material.dart';

class NequiRegistroModel extends FlutterFlowModel<NequiRegistroWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
