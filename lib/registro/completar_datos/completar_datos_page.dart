import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/registro/login/login_widget.dart';
import '/registro/pages/home_page/home_page_widget.dart';

/// Pide los datos que faltan cuando alguien entra sin haberlos dado nunca.
///
/// Quien entra con Google, Apple o Facebook llega directo a la aplicación sin
/// pasar por el registro, así que se queda sin ficha en `usuarios`: al
/// 2026-08-27 eran 489 de las 512 cuentas de Google y las 7 de Apple. Sin
/// nombre ni teléfono no se les puede facturar ni un proveedor sabe a quién
/// va a atender.
///
/// Se comprueba en cada inicio de sesión —no solo en el primero— porque
/// también hay 18 cuentas de correo a las que les falta la ficha.
class CompletarDatosPage extends StatefulWidget {
  const CompletarDatosPage({super.key});

  static const String routeName = 'CompletarDatos';
  static const String routePath = '/completarDatos';

  @override
  State<CompletarDatosPage> createState() => _CompletarDatosPageState();
}

const _kPrimary = Color(0xFF1A3C2E);
const _kAccent = Color(0xFF2D8653);
const _kBg = Color(0xFFF7F8F9);
const _kBorde = Color(0xFFD9D9D9);
const _kError = Color(0xFFD32F2F);
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextSecondary = Color(0xFF6B7280);

/// Los que ya usa el registro normal. Se respetan tal cual para no añadir una
/// cuarta forma de escribir «Cédula de ciudadanía» a las que ya hay en la base.
const _tiposDocumento = <String>[
  'Cédula de ciudadanía',
  'Cédula de extranjería',
  'Pasaporte',
  'NIT',
];

class _CompletarDatosPageState extends State<CompletarDatosPage> {
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _documento = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();

  String? _tipoDocumento;
  final _errores = <String, String>{};
  bool _guardando = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _precargar();
  }

  @override
  void dispose() {
    _nombres.dispose();
    _apellidos.dispose();
    _documento.dispose();
    _telefono.dispose();
    _direccion.dispose();
    super.dispose();
  }

  /// Rellena lo que ya se sabe: lo que haya en la ficha y, si no, el nombre
  /// que devuelve el proveedor con el que entró.
  Future<void> _precargar() async {
    try {
      final filas = await UsuariosTable().queryRows(
        queryFn: (q) => q.eqOrNull('id', currentUserUid),
      );
      final ficha = filas.firstOrNull;
      if (ficha != null) {
        _nombres.text = ficha.nombres ?? '';
        _apellidos.text = ficha.apellidos ?? '';
        _documento.text = ficha.numeroDocumento ?? '';
        _telefono.text = ficha.telefono ?? '';
        _direccion.text = ficha.direccion ?? '';
        if (_tiposDocumento.contains(ficha.tipoDocumento)) {
          _tipoDocumento = ficha.tipoDocumento;
        }
      }

      // Google y Apple mandan el nombre completo en un solo campo.
      if (_nombres.text.isEmpty) {
        final completo = (currentUserDisplayName).trim();
        if (completo.isNotEmpty) {
          final partes = completo.split(RegExp(r'\s+'));
          _nombres.text = partes.first;
          if (partes.length > 1 && _apellidos.text.isEmpty) {
            _apellidos.text = partes.sublist(1).join(' ');
          }
        }
      }
    } catch (e) {
      debugPrint('No se pudo precargar la ficha: $e');
    }
    if (mounted) setState(() => _cargando = false);
  }

  bool _validar() {
    final errores = <String, String>{};
    if (_nombres.text.trim().isEmpty) errores['nombres'] = 'Falta tu nombre';
    if (_apellidos.text.trim().isEmpty) {
      errores['apellidos'] = 'Faltan tus apellidos';
    }
    if (_tipoDocumento == null) errores['tipo'] = 'Elige el tipo de documento';
    if (_documento.text.trim().isEmpty) {
      errores['documento'] = 'Falta el número de documento';
    }

    final doc = _documento.text.trim().replaceAll(RegExp(r'\s'), '');
    if (doc.isNotEmpty && doc.length < 5) {
      errores['documento'] = 'Ese documento es demasiado corto';
    }

    // El 96% de los teléfonos de la base tiene 10 dígitos, que es el móvil
    // colombiano. Se aceptan desde 7 para no rechazar los fijos que ya hay.
    final tel = _telefono.text.trim().replaceAll(RegExp(r'\D'), '');
    if (tel.isEmpty) {
      errores['telefono'] = 'Falta tu teléfono';
    } else if (tel.length < 7 || tel.length > 10) {
      errores['telefono'] = 'Escribe un teléfono de 10 dígitos';
    }

    setState(() {
      _errores
        ..clear()
        ..addAll(errores);
    });
    return errores.isEmpty;
  }

  Future<void> _guardar() async {
    if (_guardando || !_validar()) return;
    setState(() => _guardando = true);

    final datos = {
      'nombres': _nombres.text.trim(),
      'apellidos': _apellidos.text.trim(),
      'tipo_documento': _tipoDocumento,
      'numero_documento': _documento.text.trim(),
      'telefono': _telefono.text.trim(),
      'direccion': _direccion.text.trim(),
      'pais': 'Colombia',
      'codigo_pais': '+57',
      'correo_electronico': currentUserEmail,
      'rol': 'usuario',
      'usuario_externo': false,
    };

    try {
      final existentes = await UsuariosTable().queryRows(
        queryFn: (q) => q.eqOrNull('id', currentUserUid),
      );
      if (existentes.isEmpty) {
        await UsuariosTable().insert({...datos, 'id': currentUserUid});
      } else {
        await UsuariosTable().update(
          data: datos,
          matchingRows: (rows) => rows.eqOrNull('id', currentUserUid),
        );
      }
      if (!mounted) return;
      context.goNamedAuth(HomePageWidget.routeName, context.mounted);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudieron guardar tus datos. Inténtalo otra vez.'),
          backgroundColor: _kError,
        ),
      );
      debugPrint('Error guardando la ficha: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Sin esto, el botón atrás de Android devuelve a la portada y la
      // pantalla vuelve a salir en bucle. Para salir se cierra sesión.
      canPop: false,
      child: Scaffold(
      backgroundColor: Colors.white,
      // El teclado se superpone en vez de encoger la pantalla.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Completa tus datos',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
          ),
        ),
        actions: [
          // Una salida siempre: si alguien no quiere dar sus datos, que pueda
          // irse en vez de quedarse encerrado en esta pantalla.
          TextButton(
            onPressed: _guardando ? null : _cerrarSesion,
            child: Text(
              'Salir',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _kTextSecondary,
              ),
            ),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: _kAccent))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nos faltan algunos datos para poder atender tus '
                            'solicitudes. Solo te lo pediremos una vez.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: _kTextSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _campo('Nombres', _nombres, 'nombres',
                              capitalizar: true),
                          _campo('Apellidos', _apellidos, 'apellidos',
                              capitalizar: true),
                          _desplegableTipoDocumento(),
                          _campo('Número de documento', _documento, 'documento',
                              teclado: TextInputType.number),
                          _campo('Teléfono', _telefono, 'telefono',
                              teclado: TextInputType.phone, prefijo: '+57 '),
                          _campo('Dirección (opcional)', _direccion, 'direccion',
                              obligatorio: false),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _guardando ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          disabledBackgroundColor: _kPrimary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _guardando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Guardar y continuar',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(
          '¿Salir sin completar?',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Se cerrará tu sesión. Podrás volver a entrar cuando quieras, y te '
          'pediremos estos datos otra vez.',
          style: GoogleFonts.inter(fontSize: 14, color: _kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: Text('Seguir aquí',
                style: GoogleFonts.inter(color: _kTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: Text('Salir', style: GoogleFonts.inter(color: _kError)),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;
    await authManager.signOut();
    if (!mounted) return;
    context.goNamedAuth(LoginWidget.routeName, context.mounted);
  }

  Widget _campo(
    String etiqueta,
    TextEditingController controlador,
    String clave, {
    TextInputType teclado = TextInputType.text,
    bool obligatorio = true,
    bool capitalizar = false,
    String? prefijo,
  }) {
    final error = _errores[clave];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            obligatorio ? '$etiqueta *' : etiqueta,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _kTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controlador,
            keyboardType: teclado,
            textCapitalization:
                capitalizar ? TextCapitalization.words : TextCapitalization.none,
            onChanged: (_) {
              if (error != null) setState(() => _errores.remove(clave));
            },
            style: GoogleFonts.inter(fontSize: 15, color: _kTextPrimary),
            decoration: InputDecoration(
              prefixText: prefijo,
              prefixStyle: GoogleFonts.inter(fontSize: 15, color: _kTextSecondary),
              filled: true,
              fillColor: _kBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: error != null ? _kError : _kBorde),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: error != null ? _kError : _kAccent, width: 1.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kBorde),
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 2),
              child: Text(
                error,
                style: GoogleFonts.inter(fontSize: 12, color: _kError),
              ),
            ),
        ],
      ),
    );
  }

  Widget _desplegableTipoDocumento() {
    final error = _errores['tipo'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de documento *',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _kTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: error != null ? _kError : _kBorde),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _tipoDocumento,
                isExpanded: true,
                hint: Text(
                  'Selecciona',
                  style: GoogleFonts.inter(fontSize: 15, color: _kTextSecondary),
                ),
                icon: const Icon(Icons.keyboard_arrow_down, color: _kTextSecondary),
                style: GoogleFonts.inter(fontSize: 15, color: _kTextPrimary),
                dropdownColor: Colors.white,
                items: _tiposDocumento
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _tipoDocumento = v;
                  _errores.remove('tipo');
                }),
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 2),
              child: Text(
                error,
                style: GoogleFonts.inter(fontSize: 12, color: _kError),
              ),
            ),
        ],
      ),
    );
  }
}

/// Decide si a esta cuenta le faltan datos para operar.
///
/// Se mira contra la base y no contra lo que diga el proveedor de identidad:
/// Google da nombre y correo, pero nunca documento ni teléfono.
Future<bool> faltanDatosDelUsuario() async {
  try {
    final filas = await UsuariosTable().queryRows(
      queryFn: (q) => q.eqOrNull('id', currentUserUid),
    );
    final ficha = filas.firstOrNull;
    if (ficha == null) return true;

    bool vacio(String? v) => v == null || v.trim().isEmpty;
    return vacio(ficha.nombres) ||
        vacio(ficha.apellidos) ||
        vacio(ficha.numeroDocumento) ||
        vacio(ficha.telefono);
  } catch (e) {
    // Ante un fallo de red no se bloquea la entrada: es preferible dejar
    // pasar y volver a preguntar en el siguiente inicio de sesión.
    debugPrint('No se pudo comprobar la ficha del usuario: $e');
    return false;
  }
}
