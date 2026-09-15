// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

// Modelos de datos
class DatosPeriodo {
  final String periodo;
  final double valor;

  DatosPeriodo({required this.periodo, required this.valor});
}

class ServicioFrecuente {
  final String nombre;
  final int cantidad;
  final Color color;

  ServicioFrecuente({
    required this.nombre,
    required this.cantidad,
    required this.color,
  });
}

class DashboardProveedor extends StatefulWidget {
  const DashboardProveedor({
    super.key,
    required this.proveedorId,
    this.width,
    this.height,
  });

  final String proveedorId;
  final double? width;
  final double? height;

  @override
  State<DashboardProveedor> createState() => _DashboardProveedorState();
}

class _DashboardProveedorState extends State<DashboardProveedor> {
  bool isLoading = true;
  String? error;
  StreamSubscription<List<Map<String, dynamic>>>? _solicitudesSub;
  bool _primeraEmisionStream = true;

  // Datos del dashboard
  List<DatosPeriodo> serviciosPorSemana = [];
  List<DatosPeriodo> ingresosPorSemana = [];
  List<DatosPeriodo> evolucionMensual = [];
  List<ServicioFrecuente> serviciosFrecuentes = [];

  // Filtros activos
  String filtroActivo = 'servicios_realizados';

  // Colores para gráficos
  final Color colorPrimario = const Color(0xFF4CAF50);
  final List<Color> coloresPie = [
    const Color(0xFF4CAF50), // Verde - Plomería
    const Color(0xFFE8F5E8), // Verde claro - Limpieza
    const Color(0xFF9E9E9E), // Gris - Cerrajería
    const Color(0xFFEF5350), // Rojo - Mudanza
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    // Tiempo real: recarga las métricas cuando cambian las solicitudes del
    // proveedor (p. ej. al finalizar un servicio). Supabase Realtime no emite
    // sobre vistas, por eso se escucha la tabla base `solicitudes_servicio`.
    _solicitudesSub = SupaFlow.client
        .from('solicitudes_servicio')
        .stream(primaryKey: ['id'])
        .eq('profesional_id', widget.proveedorId)
        .listen((_) {
          if (_primeraEmisionStream) {
            _primeraEmisionStream = false;
            return;
          }
          if (mounted) {
            _cargarDatos();
          }
        });
  }

  @override
  void dispose() {
    _solicitudesSub?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Agregamos debug para ver el proveedorId
      print('DEBUG: Cargando datos para proveedorId: ${widget.proveedorId}');

      await Future.wait([
        _cargarServiciosPorSemana(),
        _cargarIngresosPorSemana(),
        _cargarEvolucionMensual(),
        _cargarServiciosFrecuentes(),
      ]);
    } catch (e) {
      print('DEBUG: Error al cargar datos: $e');
      setState(() {
        error = 'Error al cargar datos: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _cargarServiciosPorSemana() async {
    try {
      final now = DateTime.now();
      final inicioMes = DateTime(now.year, now.month, 1);

      List<DatosPeriodo> datos = [];

      for (int semana = 1; semana <= 4; semana++) {
        final inicioSemana = inicioMes.add(Duration(days: (semana - 1) * 7));
        final finSemana = inicioSemana.add(Duration(days: 6));

        // Formato de fecha mejorado - solo la parte de fecha
        final fechaInicio = inicioSemana.toIso8601String().substring(0, 10);
        final fechaFin = finSemana.toIso8601String().substring(0, 10);

        print(
            'DEBUG: Consultando servicios semana $semana: $fechaInicio a $fechaFin');

        final response = await SupaFlow.client
            .from('solicitudes_servicio')
            .select('id, fecha, estado, profesional_id')
            .eq('profesional_id', widget.proveedorId)
            .eq('estado', 'finalizadas')
            .gte('fecha', fechaInicio)
            .lte('fecha', fechaFin);

        print(
            'DEBUG: Respuesta servicios semana $semana: ${response?.length ?? 0} registros');
        if (response != null && response.isNotEmpty) {
          print('DEBUG: Primer registro: ${response.first}');
        }

        final cantidad = response?.length ?? 0;
        datos.add(
            DatosPeriodo(periodo: 'Sem $semana', valor: cantidad.toDouble()));
      }

      setState(() {
        serviciosPorSemana = datos;
      });
      print(
          'DEBUG: serviciosPorSemana cargados: ${datos.map((d) => '${d.periodo}: ${d.valor}').join(', ')}');
    } catch (e) {
      print('DEBUG: Error en _cargarServiciosPorSemana: $e');
      throw e;
    }
  }

  Future<void> _cargarIngresosPorSemana() async {
    try {
      final now = DateTime.now();
      final inicioMes = DateTime(now.year, now.month, 1);

      List<DatosPeriodo> datos = [];

      for (int semana = 1; semana <= 4; semana++) {
        final inicioSemana = inicioMes.add(Duration(days: (semana - 1) * 7));
        final finSemana = inicioSemana.add(Duration(days: 6));

        final fechaInicio = inicioSemana.toIso8601String().substring(0, 10);
        final fechaFin = finSemana.toIso8601String().substring(0, 10);

        print(
            'DEBUG: Consultando ingresos semana $semana: $fechaInicio a $fechaFin');

        final response = await SupaFlow.client
            .from('solicitudes_servicio')
            .select('precio_base, precio_adicionales, precio')
            .eq('profesional_id', widget.proveedorId)
            .eq('estado', 'finalizadas')
            .gte('fecha', fechaInicio)
            .lte('fecha', fechaFin);

        print(
            'DEBUG: Respuesta ingresos semana $semana: ${response?.length ?? 0} registros');

        double total = 0;
        if (response != null) {
          for (var item in response) {
            // Ingreso del proveedor = 72% del total que paga el cliente,
            // adicionales incluidos. `precio` es fallback legacy si no hay
            // precio_base.
            final base = double.tryParse(
                    (item['precio_base'] ?? item['precio'] ?? 0).toString()) ??
                0;
            final adicionales =
                double.tryParse((item['precio_adicionales'] ?? 0).toString()) ??
                    0;
            total += calcularIngresoProveedor(base + adicionales);
          }
        }

        datos.add(DatosPeriodo(periodo: 'Sem $semana', valor: total));
        print('DEBUG: Ingreso neto proveedor semana $semana: $total');
      }

      setState(() {
        ingresosPorSemana = datos;
      });
    } catch (e) {
      print('DEBUG: Error en _cargarIngresosPorSemana: $e');
      throw e;
    }
  }

  Future<void> _cargarEvolucionMensual() async {
    try {
      final now = DateTime.now();
      List<DatosPeriodo> datos = [];

      // Empezar desde enero del año actual
      for (int mes = 1; mes <= 12; mes++) {
        final inicioMes = DateTime(now.year, mes, 1);
        final finMes =
            DateTime(now.year, mes + 1, 1).subtract(Duration(days: 1));

        final fechaInicio = inicioMes.toIso8601String().substring(0, 10);
        final fechaFin = finMes.toIso8601String().substring(0, 10);

        print(
            'DEBUG: Consultando evolución mes $mes: $fechaInicio a $fechaFin');

        final response = await SupaFlow.client
            .from('solicitudes_servicio')
            .select('id')
            .eq('profesional_id', widget.proveedorId)
            .eq('estado', 'finalizadas')
            .gte('fecha', fechaInicio)
            .lte('fecha', fechaFin);

        final cantidad = response?.length ?? 0;
        // Cambiar índice para que coincida con los meses (0-11 para enero-diciembre)
        datos.add(DatosPeriodo(
            periodo: (mes - 1).toString(), valor: cantidad.toDouble()));
        print('DEBUG: Servicios mes $mes: $cantidad');
      }

      setState(() {
        evolucionMensual = datos;
      });
    } catch (e) {
      print('DEBUG: Error en _cargarEvolucionMensual: $e');
      throw e;
    }
  }

  Future<void> _cargarServiciosFrecuentes() async {
    try {
      print('DEBUG: Consultando servicios frecuentes');

      final response = await SupaFlow.client
          .from('solicitudes_servicio')
          .select('servicio_nombre')
          .eq('profesional_id', widget.proveedorId)
          .eq('estado', 'finalizadas');

      print(
          'DEBUG: Respuesta servicios frecuentes: ${response?.length ?? 0} registros');

      Map<String, int> conteoServicios = {};

      if (response != null) {
        for (var item in response) {
          final servicio = item['servicio_nombre'] ?? 'Sin nombre';
          conteoServicios[servicio] = (conteoServicios[servicio] ?? 0) + 1;
          print('DEBUG: Servicio encontrado: $servicio');
        }
      }

      print('DEBUG: Conteo servicios: $conteoServicios');

      List<ServicioFrecuente> datos = [];
      int colorIndex = 0;

      // Ordenar por cantidad descendente y tomar los primeros 4
      var serviciosOrdenados = conteoServicios.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      serviciosOrdenados.take(4).forEach((entry) {
        datos.add(ServicioFrecuente(
          nombre: entry.key,
          cantidad: entry.value,
          color: coloresPie[colorIndex % coloresPie.length],
        ));
        colorIndex++;
      });

      setState(() {
        serviciosFrecuentes = datos;
      });
      print('DEBUG: serviciosFrecuentes cargados: ${datos.length} servicios');
    } catch (e) {
      print('DEBUG: Error en _cargarServiciosFrecuentes: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height ?? 300, // Altura fija de 300px
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            _buildLoading()
          else if (error != null)
            _buildError()
          else
            _buildContent(),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorPrimario),
          const SizedBox(height: 12),
          Text(
            'Cargando datos...',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'Error al cargar',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            error!,
            style: TextStyle(color: Colors.red, fontSize: 10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _cargarDatos,
            child: Text('Reintentar', style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: Column(
        children: [
          // Filtros superiores - altura fija
          SizedBox(
            height: 40,
            child: _buildFiltros(),
          ),
          const SizedBox(height: 12),

          // Gráfico principal - usa el espacio restante
          Expanded(
            child: _buildGraficoPrincipal(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    final filtros = [
      {'key': 'servicios_realizados', 'label': 'Servicios realizados'},
      {'key': 'ingresos_promedio', 'label': 'Ingresos promedio'},
      {'key': 'evolucion_servicios', 'label': 'Evolución de servicios'},
      {'key': 'servicios_frecuentes', 'label': 'Servicios más frecuentes'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filtros.map((filtro) {
          final isActive = filtro['key'] == filtroActivo;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  filtroActivo = filtro['key']!;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.grey[800] : Colors.transparent,
                  border: Border.all(
                    color: isActive ? Colors.grey[800]! : Colors.grey[400]!,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filtro['label']!,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGraficoPrincipal() {
    switch (filtroActivo) {
      case 'servicios_realizados':
        return _buildGraficoBarras(
          titulo: 'Servicios realizados por semana',
          datos: serviciosPorSemana.isEmpty
              ? _getDatosVacios()
              : serviciosPorSemana,
          esMoneda: false,
        );
      case 'ingresos_promedio':
        return _buildGraficoBarras(
          titulo: 'Ingresos promedio semanales',
          datos:
              ingresosPorSemana.isEmpty ? _getDatosVacios() : ingresosPorSemana,
          esMoneda: true,
        );
      case 'evolucion_servicios':
        return _buildGraficoLineas();
      case 'servicios_frecuentes':
        return _buildGraficoPie();
      default:
        return _buildGraficoBarras(
          titulo: 'Servicios realizados por semana',
          datos: serviciosPorSemana.isEmpty
              ? _getDatosVacios()
              : serviciosPorSemana,
          esMoneda: false,
        );
    }
  }

  List<DatosPeriodo> _getDatosVacios() {
    return [
      DatosPeriodo(periodo: 'Sem 1', valor: 0),
      DatosPeriodo(periodo: 'Sem 2', valor: 0),
      DatosPeriodo(periodo: 'Sem 3', valor: 0),
      DatosPeriodo(periodo: 'Sem 4', valor: 0),
    ];
  }

  Widget _buildGraficoBarras({
    required String titulo,
    required List<DatosPeriodo> datos,
    required bool esMoneda,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              maxY: _getMaxY(datos, esMoneda),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < datos.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            datos[value.toInt()].periodo,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) {
                      if (esMoneda) {
                        // Para monedas, mostrar el valor real sin dividir por 1000 si es pequeño
                        if (value < 1000) {
                          return Text(
                            '\$${value.toInt()}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 9,
                            ),
                          );
                        } else {
                          return Text(
                            '\$${(value / 1000).toInt()}k',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 9,
                            ),
                          );
                        }
                      } else {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 9,
                          ),
                        );
                      }
                    },
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!, width: 1),
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _getMaxY(datos, esMoneda) / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 1,
                  );
                },
              ),
              barGroups: datos.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.valor == 0
                          ? _getMaxY(datos, esMoneda) * 0.02
                          : entry.value.valor,
                      color: entry.value.valor == 0
                          ? Colors.grey[300]
                          : colorPrimario,
                      width: 30,
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  double _getMaxY(List<DatosPeriodo> datos, bool esMoneda) {
    if (datos.isEmpty) return esMoneda ? 1000 : 10;

    final maxValue = datos.map((d) => d.valor).reduce((a, b) => a > b ? a : b);

    if (maxValue == 0) {
      return esMoneda ? 1000 : 10;
    }

    // Para monedas, ajustar el máximo basado en el valor real
    if (esMoneda) {
      if (maxValue <= 100) {
        return 150; // Para valores pequeños como 100, mostrar hasta 150
      } else if (maxValue <= 500) {
        return 600;
      } else if (maxValue <= 1000) {
        return 1200;
      } else {
        return maxValue * 1.2;
      }
    }

    // Para servicios (no moneda)
    return maxValue * 1.2;
  }

  Widget _buildGraficoLineas() {
    var datosParaGrafico = evolucionMensual;
    if (datosParaGrafico.isEmpty || datosParaGrafico.length < 12) {
      datosParaGrafico = List.generate(
          12, (index) => DatosPeriodo(periodo: index.toString(), valor: 0));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evolución de servicios prestados',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final monthNames = [
                        'E',
                        'F',
                        'M',
                        'A',
                        'M',
                        'J',
                        'J',
                        'A',
                        'S',
                        'O',
                        'N',
                        'D'
                      ];
                      final index = value.toInt();
                      if (index >= 0 && index < monthNames.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            monthNames[index],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 9,
                            ),
                          ),
                        );
                      }
                      return Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 25,
                    reservedSize: 25,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 9,
                        ),
                      );
                    },
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!, width: 1),
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              minX: 0,
              maxX: 11,
              minY: 0,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: _generateLineSpots(datosParaGrafico),
                  isCurved: true,
                  color: const Color(0xFF8E24AA),
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: const Color(0xFF8E24AA),
                        strokeWidth: 0,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _generateLineSpots(List<DatosPeriodo> datos) {
    if (datos.isNotEmpty && datos.length >= 12) {
      return datos.take(12).map((dato) {
        final x = double.tryParse(dato.periodo) ?? 0;
        return FlSpot(x, dato.valor);
      }).toList();
    }

    // Datos de ejemplo si no hay datos reales
    return [
      FlSpot(0, 15),
      FlSpot(1, 25),
      FlSpot(2, 18),
      FlSpot(3, 32),
      FlSpot(4, 42),
      FlSpot(5, 38),
      FlSpot(6, 52),
      FlSpot(7, 45),
      FlSpot(8, 36),
      FlSpot(9, 62),
      FlSpot(10, 47),
      FlSpot(11, 51),
    ];
  }

  Widget _buildGraficoPie() {
    var serviciosParaGrafico = serviciosFrecuentes;
    if (serviciosParaGrafico.isEmpty) {
      serviciosParaGrafico = [
        ServicioFrecuente(
            nombre: 'Sin servicios registrados',
            cantidad: 100,
            color: Colors.grey[300]!),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Servicios más frecuentes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              // Gráfico circular
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(enabled: false),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                    sections: serviciosParaGrafico.map((servicio) {
                      return PieChartSectionData(
                        color: servicio.color,
                        value: servicio.cantidad.toDouble(),
                        title: '',
                        radius: 60,
                        titleStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Leyenda
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: serviciosParaGrafico.map((servicio) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: servicio.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  servicio.nombre,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${servicio.cantidad}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
