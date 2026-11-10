import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '/backend/direcciones_usuario.dart';
import '/backend/supabase/database/tables/ciudades.dart';
import '/environment_values.dart';
import '/flutter_flow/places_service.dart';
import '/flutter_flow/ubicacion_helpers.dart';
import 'direcciones_agenda_estilo.dart';
import 'pantalla_mapa_ubicacion.dart';

class AgregarDireccionAgendaPage extends StatefulWidget {
  const AgregarDireccionAgendaPage(
      {super.key,
      required this.ciudades,
      required this.guardar,
      this.ciudadInicial,
      this.elegirUbicacion,
      this.mapaBuilder,
      this.direccionInicial,
      this.archivar,
      this.usarAlGuardar = true});
  final List<CiudadesRow> ciudades;
  final Future<DireccionGuardada> Function(Map<String, dynamic>) guardar;
  final CiudadesRow? ciudadInicial;
  final Future<UbicacionElegida?> Function(BuildContext)? elegirUbicacion;
  final Widget Function(Coordenadas?, VoidCallback)? mapaBuilder;
  final DireccionGuardada? direccionInicial;
  final Future<void> Function()? archivar;
  final bool usarAlGuardar;

  @override
  State<AgregarDireccionAgendaPage> createState() =>
      _AgregarDireccionAgendaPageState();
}

class _AgregarDireccionAgendaPageState
    extends State<AgregarDireccionAgendaPage> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _direccion = TextEditingController();
  final _complemento = TextEditingController();
  final _referencia = TextEditingController();
  String _tipo = 'casa';
  CiudadesRow? _ciudad;
  Coordenadas? _punto;
  Coordenadas? _centro;
  int _revisionCentro = 0;
  bool _guardando = false;
  bool _ciudadAbierta = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ciudad = widget.ciudadInicial;
    final inicial = widget.direccionInicial;
    if (inicial != null) {
      _tipo = inicial.tipo;
      _nombre.text = inicial.data['nombre'] as String? ?? '';
      _direccion.text = inicial.direccion;
      _complemento.text = inicial.complemento;
      _referencia.text = inicial.referencia;
      _punto = inicial.punto;
      final ciudades = widget.ciudades.where((c) => c.id == inicial.ciudadId);
      _ciudad = ciudades.isEmpty ? null : ciudades.first;
    }
    _centrarCiudad();
  }

  Future<void> _centrarCiudad() async {
    final revision = ++_revisionCentro;
    final ciudad = _ciudad;
    if (ciudad == null || widget.mapaBuilder != null) return;
    final centro =
        await PlacesService(FFDevEnvironmentValues().googleMapsApiKey)
            .centroCiudad(ciudad.nombre);
    if (mounted && revision == _revisionCentro)
      setState(() => _centro = centro);
  }

  @override
  void dispose() {
    _revisionCentro++;
    for (final c in [_nombre, _direccion, _complemento, _referencia]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirCiudad() async {
    FocusScope.of(context).unfocus();
    setState(() => _ciudadAbierta = true);
    final ciudad = await showModalBottomSheet<CiudadesRow>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .6,
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                  child: Row(children: [
                    Expanded(
                        child: Text('Selecciona una ciudad',
                            style: textoDireccion(
                                size: 20, weight: FontWeight.w700))),
                    IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close)),
                  ])),
              Expanded(
                  child: ListView(children: [
                for (final c in widget.ciudades.where((c) => c.activo))
                  ListTile(
                      title: Text(c.nombre, style: textoDireccion(size: 16)),
                      trailing: c.id == _ciudad?.id
                          ? const Icon(Icons.check, color: direccionVerde)
                          : null,
                      onTap: () => Navigator.pop(context, c)),
              ])),
            ]),
          )),
    );
    if (!mounted) return;
    setState(() {
      _ciudadAbierta = false;
      if (ciudad != null && ciudad.id != _ciudad?.id) {
        _ciudad = ciudad;
        _punto = null;
        _centro = null;
      }
    });
    if (ciudad != null) _centrarCiudad();
  }

  Future<void> _abrirMapa() async {
    if (_guardando) return;
    FocusScope.of(context).unfocus();
    final callback = widget.elegirUbicacion;
    final ubicacion = callback != null
        ? await callback(context)
        : await Navigator.of(context).push<UbicacionElegida>(MaterialPageRoute(
            builder: (_) => PantallaMapaUbicacion(
                  ciudades: widget.ciudades,
                  inicial: _punto ?? _centro,
                  direccionInicial: _direccion.text,
                  separarCiudad: true,
                )));
    if (ubicacion == null || !mounted) return;
    _revisionCentro++;
    setState(() {
      _punto = ubicacion.coordenadas;
      _direccion.text = ubicacion.direccion;
      _ciudad = ubicacion.ciudad;
      _error = null;
    });
  }

  Future<void> _guardar() async {
    if (_guardando || !_form.currentState!.validate()) return;
    if (_ciudad == null || !_ciudad!.activo) {
      setState(() => _error = 'Selecciona una ciudad con cobertura.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final direccion = await widget.guardar({
        'tipo': _tipo,
        'nombre': _tipo == 'otra' ? _nombre.text.trim() : null,
        'direccion': _direccion.text.trim(),
        'complemento': _complemento.text.trim(),
        'referencia': _referencia.text.trim(),
        'ciudad_id': _ciudad!.id,
        // El centro de cámara nunca se guarda como un punto elegido.
        'latitud': _punto?.latitud, 'longitud': _punto?.longitud,
      });
      if (!mounted) return;
      // Permitir el pop tras la escritura sin volver a habilitar el botón.
      setState(() => _guardando = false);
      Navigator.of(context).pop(direccion);
    } catch (_) {
      if (mounted)
        setState(() {
          _guardando = false;
          _error = 'No pudimos guardar la dirección. Intenta de nuevo.';
        });
    }
  }

  Future<void> _archivar() async {
    if (_guardando || widget.archivar == null) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await widget.archivar!();
      if (!mounted) return;
      setState(() => _guardando = false);
      Navigator.of(context).pop(widget.direccionInicial);
    } catch (_) {
      if (mounted)
        setState(() {
          _guardando = false;
          _error = 'No pudimos archivar la dirección. Intenta de nuevo.';
        });
    }
  }

  InputDecoration _input(String hint, {IconData? icono}) => inputDireccion(hint,
      icono: icono, radio: widget.direccionInicial == null ? 12 : 24);

  Widget _campo(String label, TextEditingController controller,
          {required String hint,
          IconData? icono,
          bool obligatorio = false,
          VoidCallback? cambio}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: textoDireccion(color: direccionGris)),
          const SizedBox(height: 8),
          TextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              key: ValueKey(label),
              controller: controller,
              enabled: !_guardando,
              style: textoDireccion(size: 16),
              textCapitalization: TextCapitalization.sentences,
              decoration: _input(hint,
                  icono: widget.direccionInicial == null ? icono : null),
              validator: (v) => obligatorio && (v?.trim().isEmpty ?? true)
                  ? 'Completa este campo.'
                  : null,
              onChanged: (_) {
                if (cambio != null) cambio();
              }),
        ]),
      );

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_guardando,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false,
              leading: botonVolverDireccion(context,
                  onPressed: _guardando ? null : () => Navigator.pop(context)),
              title: Text(
                  widget.direccionInicial == null
                      ? 'Agregar dirección'
                      : 'Editar dirección',
                  style: textoDireccion(size: 21, weight: FontWeight.w700)),
              actions: [
                IconButton(
                    tooltip: 'Cerrar',
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close))
              ]),
          body: SafeArea(
              top: false,
              child: Form(
                key: _form,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tipo *',
                            style: textoDireccion(color: direccionGris)),
                        const SizedBox(height: 10),
                        Row(children: [
                          for (final tipo in ['casa', 'oficina', 'otra']) ...[
                            if (tipo != 'casa') const SizedBox(width: 8),
                            Expanded(
                                child: OutlinedButton(
                                    key: ValueKey('tipo-$tipo'),
                                    onPressed: _guardando
                                        ? null
                                        : () => setState(() => _tipo = tipo),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: _tipo == tipo
                                            ? Colors.white
                                            : const Color(0xFF333333),
                                        backgroundColor: _tipo == tipo
                                            ? direccionVerde
                                            : direccionSuperficie,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 14),
                                        side: BorderSide(
                                            color: _tipo == tipo
                                                ? direccionVerde
                                                : direccionBorde),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(iconoDireccion(tipo), size: 18),
                                          const SizedBox(width: 5),
                                          Flexible(
                                              child: Text(
                                                  switch (tipo) {
                                                    'casa' => 'Casa',
                                                    'oficina' => 'Oficina',
                                                    _ => 'Otra'
                                                  },
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontSize: 14))),
                                        ]))),
                          ],
                        ]),
                        const SizedBox(height: 22),
                        if (_tipo == 'otra')
                          _campo('Nombre de la dirección *', _nombre,
                              hint: 'Ej. Casa de la mamá',
                              icono: Icons.sell_outlined,
                              obligatorio: true),
                        _campo('Dirección *', _direccion,
                            hint: 'Calle y número',
                            icono: Icons.map_outlined,
                            obligatorio: true,
                            cambio: () => setState(() => _punto = null)),
                        _campo('Complemento (opcional)', _complemento,
                            hint: 'Ej. Apto 302, torre B',
                            icono: Icons.edit_note),
                        _campo('Referencia (opcional)', _referencia,
                            hint: 'Ej. Portería principal',
                            icono: Icons.edit_note),
                        Text('Ciudad *',
                            style: textoDireccion(color: direccionGris)),
                        const SizedBox(height: 8),
                        InkWell(
                            key: const ValueKey('ciudad-direccion'),
                            onTap: _guardando ? null : _elegirCiudad,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                                decoration: _input('Seleccionar ciudad',
                                    icono: Icons.location_on_outlined),
                                child: Row(children: [
                                  Expanded(
                                      child: Text(
                                          _ciudad?.nombre ??
                                              'Seleccionar ciudad',
                                          style: textoDireccion(
                                              size: 16,
                                              color: _ciudad == null
                                                  ? direccionGris
                                                  : const Color(0xFF0D0D0D)))),
                                  const Icon(Icons.chevron_right,
                                      color: direccionVerde),
                                ]))),
                        const SizedBox(height: 20),
                        Text('Ubicación exacta (opcional)',
                            style: textoDireccion(color: direccionGris)),
                        const SizedBox(height: 8),
                        InkWell(
                            key: const ValueKey('buscar-mapa-direccion'),
                            onTap: _guardando ? null : _abrirMapa,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                                decoration: _input('Buscar en el mapa',
                                    icono: Icons.search),
                                child: Text(
                                    _punto == null ||
                                            widget.direccionInicial != null
                                        ? 'Buscar en el mapa'
                                        : 'Ver ubicación seleccionada',
                                    style: textoDireccion(
                                        size: 16, color: direccionGris)))),
                        const SizedBox(height: 12),
                        SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: _ciudadAbierta
                                    ? const ColoredBox(
                                        color: direccionSuperficie)
                                    : widget.mapaBuilder
                                            ?.call(_punto, _abrirMapa) ??
                                        _MapaDireccionAgenda(
                                            punto: _punto,
                                            centro: _centro,
                                            onTap: _abrirMapa))),
                        const SizedBox(height: 8),
                        Text(
                            widget.direccionInicial == null
                                ? 'Puedes agregar un punto para facilitar la llegada.'
                                : 'Puedes ajustar el punto para facilitar la llegada.',
                            style:
                                textoDireccion(size: 12, color: direccionGris)),
                        if (widget.direccionInicial != null) ...[
                          const SizedBox(height: 20),
                          Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: direccionSeleccionada,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Row(children: [
                                const Icon(Icons.info_outline,
                                    color: direccionVerde, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(
                                        'Estos cambios se guardan en tu dirección.',
                                        style: textoDireccion(size: 13))),
                              ])),
                        ],
                      ]),
                ),
              )),
          bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(_error!,
                                  style: textoDireccion(
                                      size: 13,
                                      color: const Color(0xFFD32F2F)))),
                        _acciones(),
                      ]))),
        ),
      );

  Widget _acciones() {
    final editando = widget.direccionInicial != null;
    final guardar = ElevatedButton(
      key: const ValueKey('guardar-usar-direccion'),
      style: editando
          ? botonDireccion().copyWith(
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26))))
          : botonDireccion(),
      onPressed: _guardando ? null : _guardar,
      child: _guardando
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Text(
              editando
                  ? 'Guardar cambios'
                  : widget.usarAlGuardar
                      ? 'Guardar y usar dirección'
                      : 'Guardar dirección',
              textAlign: TextAlign.center),
    );
    if (widget.archivar == null) return guardar;
    final archivar = ElevatedButton(
      key: const ValueKey('archivar-direccion'),
      style: botonDireccion(contorno: true).copyWith(
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
              side: const BorderSide(color: direccionVerde)))),
      onPressed: _guardando ? null : _archivar,
      child: const Text('Archivar dirección', textAlign: TextAlign.center),
    );
    return LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= 380
            ? Row(children: [
                Expanded(child: archivar),
                const SizedBox(width: 12),
                Expanded(child: guardar)
              ])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [archivar, const SizedBox(height: 8), guardar]));
  }
}

class _MapaDireccionAgenda extends StatefulWidget {
  const _MapaDireccionAgenda({this.punto, this.centro, required this.onTap});
  final Coordenadas? punto;
  final Coordenadas? centro;
  final VoidCallback onTap;
  @override
  State<_MapaDireccionAgenda> createState() => _MapaDireccionAgendaState();
}

class _MapaDireccionAgendaState extends State<_MapaDireccionAgenda> {
  GoogleMapController? _controller;
  LatLng get _centro {
    final p =
        widget.punto ?? widget.centro ?? const Coordenadas(4.7109, -74.0721);
    return LatLng(p.latitud, p.longitud);
  }

  @override
  void didUpdateWidget(covariant _MapaDireccionAgenda oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.punto != widget.punto || oldWidget.centro != widget.centro) {
      _controller?.moveCamera(
          CameraUpdate.newLatLngZoom(_centro, widget.punto == null ? 12 : 16));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (FFDevEnvironmentValues().googleMapsApiKey.isEmpty) {
      return InkWell(
          onTap: widget.onTap,
          child: ColoredBox(
              color: direccionSeleccionada,
              child: Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.map_outlined, color: direccionVerde),
                const SizedBox(width: 8),
                Text('Abrir mapa',
                    style: textoDireccion(color: direccionVerde)),
              ]))));
    }
    return GoogleMap(
        initialCameraPosition: CameraPosition(
            target: _centro, zoom: widget.punto == null ? 12 : 16),
        onMapCreated: (controller) {
          if (mounted) {
            _controller = controller;
          } else {
            controller.dispose();
          }
        },
        onTap: (_) => widget.onTap(),
        markers: widget.punto == null
            ? {}
            : {
                Marker(
                    markerId: const MarkerId('direccion'),
                    position: _centro,
                    icon: BitmapDescriptor.defaultMarkerWithHue(160))
              },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        scrollGesturesEnabled: false,
        zoomGesturesEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false);
  }
}
