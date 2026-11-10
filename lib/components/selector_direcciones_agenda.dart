import 'package:flutter/material.dart';

import '/backend/direcciones_usuario.dart';
import '/backend/supabase/database/tables/ciudades.dart';
import 'direcciones_agenda_estilo.dart';

class SelectorDireccionesAgenda extends StatefulWidget {
  const SelectorDireccionesAgenda(
      {super.key,
      required this.cargar,
      required this.ciudades,
      required this.agregar,
      this.seleccionadaId});
  final Future<List<DireccionGuardada>> Function() cargar;
  final List<CiudadesRow> ciudades;
  final Future<DireccionGuardada?> Function(BuildContext) agregar;
  final String? seleccionadaId;

  @override
  State<SelectorDireccionesAgenda> createState() =>
      _SelectorDireccionesAgendaState();
}

class _SelectorDireccionesAgendaState extends State<SelectorDireccionesAgenda> {
  late Future<List<DireccionGuardada>> _future;
  String? _id;
  bool _agregando = false;

  @override
  void initState() {
    super.initState();
    _id = widget.seleccionadaId;
    _future = Future.sync(widget.cargar);
  }

  Future<void> _agregar() async {
    setState(() => _agregando = true);
    try {
      final nueva = await widget.agregar(context);
      if (mounted && nueva != null) Navigator.of(context).pop(nueva);
    } finally {
      if (mounted) setState(() => _agregando = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFC7C7C7),
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: Text('Selecciona una dirección',
                      style:
                          textoDireccion(size: 21, weight: FontWeight.w700))),
              IconButton(
                  tooltip: 'Cerrar',
                  onPressed: _agregando ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ]),
            Align(
                alignment: Alignment.centerLeft,
                child: Text('Elige dónde necesitas el servicio.',
                    style: textoDireccion(color: direccionGris))),
            const SizedBox(height: 20),
            Flexible(
                child: FutureBuilder<List<DireccionGuardada>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: direccionVerde));
                }
                if (snapshot.hasError) {
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('No pudimos cargar tus direcciones.',
                        style: textoDireccion()),
                    TextButton(
                        onPressed: () => setState(() {
                              _future = Future.sync(widget.cargar);
                            }),
                        child: const Text('Reintentar')),
                  ]);
                }
                final direcciones =
                    snapshot.data!.where((d) => d.activa).toList();
                DireccionGuardada? seleccionada;
                for (final d in direcciones) {
                  if (d.id == _id &&
                      widget.ciudades
                          .any((c) => c.id == d.ciudadId && c.activo)) {
                    seleccionada = d;
                  }
                }
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(
                      child: SingleChildScrollView(
                          child: Column(children: [
                    if (direcciones.isEmpty)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text('Aún no tienes direcciones guardadas.',
                              style: textoDireccion(color: direccionGris))),
                    for (final d in direcciones) _tarjeta(d),
                  ]))),
                  const SizedBox(height: 8),
                  _botonAgregar(),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider()),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          key: const ValueKey('usar-direccion'),
                          style: botonDireccion(),
                          onPressed: seleccionada == null || _agregando
                              ? null
                              : () => Navigator.pop(context, seleccionada),
                          child: const Text('Usar esta dirección'))),
                ]);
              },
            )),
            if (!_agregando) const SizedBox(height: 2),
          ]),
        ),
      );

  Widget _botonAgregar() => SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
          key: const ValueKey('agregar-otra-direccion'),
          style: botonDireccion(contorno: true),
          onPressed: _agregando ? null : _agregar,
          icon: const Icon(Icons.add),
          label: const Text('Agregar otra dirección')));

  Widget _tarjeta(DireccionGuardada d) {
    final ciudades =
        widget.ciudades.where((c) => c.id == d.ciudadId && c.activo);
    final ciudad = ciudades.isEmpty ? null : ciudades.first;
    final seleccionada = d.id == _id && ciudad != null;
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: seleccionada ? direccionSeleccionada : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                  color: seleccionada ? direccionVerde : direccionBorde,
                  width: seleccionada ? 1.4 : 1)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: ciudad == null || _agregando
                ? null
                : () => setState(() => _id = d.id),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(iconoDireccion(d.tipo),
                          size: 28,
                          color: seleccionada ? direccionVerde : direccionGris),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(d.nombre,
                                style: textoDireccion(
                                    size: 17, weight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(d.direccion, style: textoDireccion()),
                            if (ciudad != null)
                              Text(ciudad.nombre, style: textoDireccion()),
                            if (d.complementoYReferencia.isNotEmpty)
                              Text(d.complementoYReferencia,
                                  style: textoDireccion(color: direccionGris)),
                            if (ciudad == null)
                              Text('Necesita una ciudad con cobertura.',
                                  style: textoDireccion(
                                      size: 12, color: direccionGris)),
                          ])),
                      const SizedBox(width: 8),
                      Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Icon(
                              seleccionada
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: seleccionada
                                  ? direccionVerde
                                  : direccionGris)),
                    ])),
          ),
        ));
  }
}
