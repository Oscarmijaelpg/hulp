import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/backend/direcciones_usuario.dart';
import '/backend/supabase/supabase.dart';
import '/components/agregar_direccion_agenda_page.dart';
import '/components/direcciones_agenda_estilo.dart';
import '/components/menu_bar_widget.dart';

class MisDireccionesPage extends StatefulWidget {
  static const routeName = 'MisDirecciones';
  static const routePath = '/misDirecciones';
  const MisDireccionesPage({super.key, this.repository, this.cargarCiudades});
  final DireccionesUsuarioRepository? repository;
  final Future<List<CiudadesRow>> Function()? cargarCiudades;

  @override
  State<MisDireccionesPage> createState() => _MisDireccionesPageState();
}

class _MisDireccionesPageState extends State<MisDireccionesPage> {
  late final DireccionesUsuarioRepository _repo;
  late Future<(List<DireccionGuardada>, List<CiudadesRow>)> _datos;
  bool _archivadas = false;
  bool _ocupado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? DireccionesUsuarioRepository();
    _datos = _cargar();
    _datos.ignore();
  }

  Future<(List<DireccionGuardada>, List<CiudadesRow>)> _cargar() async {
    final resultados = await Future.wait<Object>([
      _repo.cargarTodas(),
      widget.cargarCiudades?.call() ??
          CiudadesTable().queryRows(queryFn: (q) => q.order('nombre')),
    ]);
    return (
      resultados[0] as List<DireccionGuardada>,
      resultados[1] as List<CiudadesRow>
    );
  }

  void _recargar() => setState(() {
        _error = null;
        _datos = _cargar();
        _datos.ignore();
      });

  Future<void> _editar(List<CiudadesRow> ciudades,
      [DireccionGuardada? direccion]) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    final cambio =
        await Navigator.of(context).push<DireccionGuardada>(MaterialPageRoute(
            builder: (_) => AgregarDireccionAgendaPage(
                  ciudades: ciudades,
                  direccionInicial: direccion,
                  usarAlGuardar: false,
                  guardar: (datos) => direccion == null
                      ? _repo.guardar(datos)
                      : _repo.actualizar(direccion.id, datos,
                          activa: direccion.activa),
                  archivar: direccion?.activa == true
                      ? () => _repo.archivar(direccion!.id)
                      : null,
                )));
    if (!mounted) return;
    setState(() => _ocupado = false);
    if (cambio != null) _recargar();
  }

  Future<void> _desarchivar(DireccionGuardada direccion) async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await _repo.desarchivar(direccion.id);
      if (mounted) _recargar();
    } catch (_) {
      if (mounted)
        setState(() =>
            _error = 'No pudimos desarchivar la dirección. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            elevation: .5,
            automaticallyImplyLeading: false,
            leading: botonVolverDireccion(context, onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/datosPersonales');
              }
            }),
            title: Text('Mis direcciones',
                style: textoDireccion(size: 21, weight: FontWeight.w700))),
        body: FutureBuilder<(List<DireccionGuardada>, List<CiudadesRow>)>(
          future: _datos,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                  child: CircularProgressIndicator(color: direccionVerde));
            }
            if (snapshot.hasError)
              return Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('No pudimos cargar tus direcciones.',
                            style: textoDireccion()),
                        TextButton(
                            onPressed: _recargar,
                            child: const Text('Reintentar')),
                      ])));
            final (direcciones, ciudades) = snapshot.data!;
            final activas = direcciones.where((d) => d.activa).length;
            final archivadas = direcciones.length - activas;
            final visibles =
                direcciones.where((d) => d.activa != _archivadas).toList();
            return Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text(
                      'Guarda tus direcciones para tus próximos servicios.',
                      style: textoDireccion(color: direccionGris))),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    _tab('Activas ($activas)', false),
                    _tab('Archivadas ($archivadas)', true),
                  ])),
              Expanded(
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      children: [
                    if (visibles.isEmpty)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Text(
                              _archivadas
                                  ? 'No tienes direcciones archivadas.'
                                  : 'Aún no tienes direcciones guardadas.',
                              textAlign: TextAlign.center,
                              style: textoDireccion(color: direccionGris))),
                    for (final direccion in visibles)
                      _tarjeta(direccion, ciudades),
                    if (visibles.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                              'Los cambios se usarán en tus próximas solicitudes.',
                              style: textoDireccion(
                                  size: 13, color: direccionGris))),
                  ])),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(_error!,
                        style: textoDireccion(
                            size: 13, color: Colors.red.shade700))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: ElevatedButton.icon(
                      key: const ValueKey('mis-direcciones-agregar'),
                      style: botonDireccion().copyWith(
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)))),
                      onPressed: _ocupado ? null : () => _editar(ciudades),
                      icon: const Icon(Icons.add, size: 26),
                      label: const Text('Agregar dirección'))),
            ]);
          },
        ),
        bottomNavigationBar:
            const IntrinsicHeight(child: MenuBarWidget(index: 2)),
      );

  Widget _tab(String texto, bool archivadas) => Expanded(
          child: InkWell(
        onTap: _ocupado
            ? null
            : () => setState(() {
                  _archivadas = archivadas;
                  _error = null;
                }),
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: _archivadas == archivadas
                            ? direccionVerde
                            : direccionBorde,
                        width: _archivadas == archivadas ? 3 : 1))),
            child: Text(texto,
                textAlign: TextAlign.center,
                style: textoDireccion(
                    size: 16,
                    weight: _archivadas == archivadas
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: _archivadas == archivadas
                        ? direccionVerde
                        : direccionGris))),
      ));

  Widget _linea(IconData icono, String valor, {bool secundaria = false}) =>
      Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icono, size: 18, color: direccionGris),
            const SizedBox(width: 10),
            Expanded(
                child: Text(valor,
                    style: textoDireccion(
                        color: secundaria
                            ? direccionGris
                            : const Color(0xFF333333)))),
          ]));

  Widget _tarjeta(DireccionGuardada d, List<CiudadesRow> ciudades) {
    final coincidencias = ciudades.where((c) => c.id == d.ciudadId);
    final ciudad = coincidencias.isEmpty ? null : coincidencias.first;
    final puedeRestaurar = ciudad?.activo == true;
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: direccionBorde)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _ocupado ? null : () => _editar(ciudades, d),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(iconoDireccion(d.tipo),
                            size: 30, color: direccionVerde),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(d.nombre,
                                style: textoDireccion(
                                    size: 19, weight: FontWeight.w600)),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                    color: d.activa
                                        ? const Color(0xFFD6F4DC)
                                        : direccionSuperficie,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(d.activa ? 'Activa' : 'Archivada',
                                    style: textoDireccion(
                                        size: 11,
                                        color: d.activa
                                            ? direccionVerde
                                            : direccionGris,
                                        weight: FontWeight.w600))),
                          ],
                        )),
                        IconButton(
                            tooltip: 'Editar ${d.nombre}',
                            onPressed:
                                _ocupado ? null : () => _editar(ciudades, d),
                            icon: const Icon(Icons.edit_outlined,
                                color: direccionGris, size: 22)),
                      ]),
                      _linea(Icons.location_on_outlined, d.direccion),
                      _linea(Icons.location_on_outlined,
                          ciudad?.nombre ?? 'Ciudad por completar'),
                      if (d.complemento.trim().isNotEmpty)
                        _linea(Icons.apartment_outlined, d.complemento,
                            secundaria: true),
                      if (d.referencia.trim().isNotEmpty)
                        _linea(Icons.signpost_outlined, d.referencia,
                            secundaria: true),
                      if (!d.activa) ...[
                        if (!puedeRestaurar)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                  'Actualiza la ciudad para desarchivar.',
                                  style: textoDireccion(
                                      size: 12, color: direccionGris))),
                        Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                                key: ValueKey('desarchivar-${d.id}'),
                                style: TextButton.styleFrom(
                                    foregroundColor: direccionVerde),
                                onPressed: _ocupado || !puedeRestaurar
                                    ? null
                                    : () => _desarchivar(d),
                                icon: const Icon(Icons.unarchive_outlined,
                                    size: 19),
                                label: const Text('Desarchivar'))),
                      ],
                    ])),
          ),
        ));
  }
}
