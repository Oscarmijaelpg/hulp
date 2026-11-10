import 'package:flutter/material.dart';

import '/backend/direcciones_usuario.dart';
import '/backend/supabase/database/tables/ciudades.dart';
import '/components/direcciones_agenda_estilo.dart';
import 'mis_direcciones_page.dart';

class MisDireccionesAcceso extends StatefulWidget {
  const MisDireccionesAcceso({super.key, this.repository, this.cargarCiudades});
  final DireccionesUsuarioRepository? repository;
  final Future<List<CiudadesRow>> Function()? cargarCiudades;

  @override
  State<MisDireccionesAcceso> createState() => _MisDireccionesAccesoState();
}

class _MisDireccionesAccesoState extends State<MisDireccionesAcceso> {
  late final DireccionesUsuarioRepository _repo;
  late Future<int> _cantidad;
  bool _abierto = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? DireccionesUsuarioRepository();
    _cantidad = _contar();
    _cantidad.ignore();
  }

  Future<int> _contar() async => (await _repo.cargar()).length;

  Future<void> _abrir() async {
    if (_abierto) return;
    FocusScope.of(context).unfocus();
    setState(() => _abierto = true);
    await Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => MisDireccionesPage(
            repository: _repo, cargarCiudades: widget.cargarCiudades)));
    if (mounted)
      setState(() {
        _abierto = false;
        _cantidad = _contar();
        _cantidad.ignore();
      });
  }

  @override
  Widget build(BuildContext context) => Material(
        color: direccionSeleccionada,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: const ValueKey('acceso-mis-direcciones'),
          onTap: _abierto ? null : _abrir,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(children: [
                const Icon(Icons.location_on_outlined,
                    color: direccionVerde, size: 32),
                Container(
                    width: 1,
                    height: 42,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: const Color(0xFFB3BDB6)),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Mis direcciones',
                          style: textoDireccion(
                              size: 18, weight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      FutureBuilder<int>(
                          future: _cantidad,
                          builder: (context, snapshot) {
                            final n = snapshot.data;
                            final texto = snapshot.hasError
                                ? 'Administrar mis direcciones'
                                : n == null
                                    ? 'Cargando direcciones…'
                                    : n == 0
                                        ? 'Agrega tu primera dirección'
                                        : n == 1
                                            ? '1 dirección guardada'
                                            : '$n direcciones guardadas';
                            return Text(texto,
                                style: textoDireccion(
                                    size: 13, color: direccionGris));
                          }),
                    ])),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    color: direccionVerde, size: 28),
              ])),
        ),
      );
}
