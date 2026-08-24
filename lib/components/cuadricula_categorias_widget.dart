import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/registro/pages/subcategorias/subcategorias_widget.dart';

/// Las categorías de la portada, pintadas **a partir de las que hay**.
///
/// Lo que había antes eran seis tarjetas fijas que leían la lista por índice
/// (`elementAtOrNull(0..5)`), cada una con un nombre y una imagen de reserva
/// escritos a mano: 'Plomería', 'Electricidad', 'Cerrajería', 'Mecánica',
/// 'Instalación'. Con menos de seis categorías reales el cliente veía oficios
/// que no existen, y no eran adornos: al tocarlos navegaba, con el parámetro
/// vacío, a una pantalla titulada «-» que listaba subcategorías de otra
/// categoría.
///
/// Aquí no hay reservas de ningún tipo. Si no hay categorías no se pinta
/// ninguna tarjeta, que es la verdad: es preferible a inventarse el catálogo.
class CuadriculaCategoriasWidget extends StatefulWidget {
  const CuadriculaCategoriasWidget({super.key, this.maximo = 6});

  /// Cuántas caben en la portada. El resto se ve en «Ver todos».
  final int maximo;

  @override
  State<CuadriculaCategoriasWidget> createState() =>
      _CuadriculaCategoriasWidgetState();
}

class _CuadriculaCategoriasWidgetState
    extends State<CuadriculaCategoriasWidget> {
  // En un State y no en build(): un FutureBuilder que crea el future dentro de
  // build vuelve a consultar en cada repintado.
  late final Future<List<CategoriasRow>> _categorias;

  @override
  void initState() {
    super.initState();
    _categorias = CategoriasTable().queryRows(
      queryFn: (q) => q.order('nombre', ascending: true),
      limit: widget.maximo,
    );
  }

  void _abrir(CategoriasRow categoria) {
    context.pushNamed(
      SubcategoriasWidget.routeName,
      queryParameters: {
        'rowcategoria': serializeParam(categoria, ParamType.SupabaseRow),
      }.withoutNulls,
      extra: <String, dynamic>{
        '__transition_info__': TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.fade,
          duration: Duration(milliseconds: 500),
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
      child: FutureBuilder<List<CategoriasRow>>(
        future: _categorias,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox(
              height: 120.0,
              child: Center(
                child: SizedBox(
                  width: 50.0,
                  height: 50.0,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(tema.primary),
                  ),
                ),
              ),
            );
          }

          final categorias = snapshot.data!;
          if (categorias.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'Todavía no hay categorías disponibles.',
                textAlign: TextAlign.center,
                style: tema.bodyMedium.override(
                  font: GoogleFonts.inter(),
                  color: tema.secondaryText,
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                ),
              ),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // Por ancho máximo y no por número fijo de columnas: con tres
            // columnas fijas, una sola categoría ocupa un tercio de la
            // pantalla y en tableta salen tarjetas gigantes. Así el tamaño de
            // la tarjeta manda y las columnas se ajustan solas.
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 170.0,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 1.1,
            ),
            itemCount: categorias.length,
            itemBuilder: (context, i) => _TarjetaCategoria(
              categoria: categorias[i],
              onTap: () => _abrir(categorias[i]),
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaCategoria extends StatelessWidget {
  const _TarjetaCategoria({required this.categoria, required this.onTap});

  final CategoriasRow categoria;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    final imagen = categoria.imagenUrl?.trim() ?? '';

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(20.0),
      onTap: onTap,
      // El Container va DENTRO del InkWell y ocupa toda la celda: antes la
      // zona que respondía al toque era solo el contenido, así que media
      // tarjeta no hacía nada al tocarla.
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F9),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1.2),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: imagen.isEmpty
                    ? _SinImagen(tema: tema)
                    : Image.network(
                        imagen,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        // Una categoría sin imagen no debe dejar el icono roto
                        // del navegador en mitad de la portada.
                        errorBuilder: (_, __, ___) => _SinImagen(tema: tema),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 0.0),
              child: Text(
                categoria.nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tema.bodyMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  color: tema.primaryText,
                  fontSize: 13.0,
                  letterSpacing: 0.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SinImagen extends StatelessWidget {
  const _SinImagen({required this.tema});
  final FlutterFlowTheme tema;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: const Color(0xFFE9ECEF),
        child: Icon(
          Icons.photo_camera_outlined,
          color: tema.secondaryText,
          size: 24.0,
        ),
      );
}
