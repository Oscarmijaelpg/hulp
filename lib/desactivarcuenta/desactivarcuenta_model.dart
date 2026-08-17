import '/components/menu_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'desactivarcuenta_widget.dart' show DesactivarcuentaWidget;
import 'package:flutter/material.dart';

class DesactivarcuentaModel extends FlutterFlowModel<DesactivarcuentaWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MenuBar component.
  late MenuBarModel menuBarModel;

  // Bloquea el boton mientras corre el borrado.
  bool eliminando = false;

  @override
  void initState(BuildContext context) {
    menuBarModel = createModel(context, () => MenuBarModel());
  }

  @override
  void dispose() {
    menuBarModel.dispose();
  }
}
