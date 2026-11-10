import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/backend/supabase/supabase.dart';

/// Lee importes guardados; abrir este panel no cotiza ni modifica el cobro.
class DesgloseServicioWidget extends StatefulWidget {
  const DesgloseServicioWidget(
      {super.key, required this.solicitudId, this.actualizacion, this.cargar});
  final String solicitudId;
  final Object? actualizacion;
  final Future<Map<String, dynamic>> Function()? cargar;

  @override
  State<DesgloseServicioWidget> createState() => _DesgloseServicioWidgetState();
}

class _DesgloseServicioWidgetState extends State<DesgloseServicioWidget> {
  static const verde = Color(0xFF086349);
  late Future<Map<String, dynamic>> _datos;
  bool _abierto = false;
  final _moneda =
      NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 2);
  @override
  void didUpdateWidget(covariant DesgloseServicioWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_abierto &&
        (oldWidget.solicitudId != widget.solicitudId ||
            oldWidget.actualizacion != widget.actualizacion)) {
      _datos = _iniciarConsulta();
    }
  }

  Future<Map<String, dynamic>> _iniciarConsulta() {
    final consulta = _consultar();
    // El panel se monta en el siguiente frame; FutureBuilder mostrará el error.
    consulta.ignore();
    return consulta;
  }

  Future<Map<String, dynamic>> _consultar() async {
    if (widget.cargar != null) return widget.cargar!();
    final r = await SupaFlow.client.functions.invoke('solicitudes-finanzas',
        body: {'accion': 'desglose_app', 'id': widget.solicitudId});
    final data = Map<String, dynamic>.from(r.data as Map);
    if (data['version'] != 1) throw StateError('Desglose no disponible');
    return data;
  }

  void _recargar() => setState(() {
        _datos = _iniciarConsulta();
      });
  String _importe(dynamic valor) => _moneda.format(num.parse(valor.toString()));
  Widget _fila(String texto, dynamic valor,
          {bool total = false, bool descuento = false}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Text(texto,
                    style: TextStyle(
                        fontSize: total ? 17 : 14,
                        color: total ? verde : const Color(0xFF62645E),
                        fontWeight:
                            total ? FontWeight.w700 : FontWeight.w400))),
            const SizedBox(width: 10),
            Flexible(
                child: Text('${descuento ? '− ' : ''}${_importe(valor)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: total ? 19 : 15,
                        color: total ? verde : const Color(0xFF353934),
                        fontWeight:
                            total ? FontWeight.w700 : FontWeight.w500))),
          ]));
  Widget _nota(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF73766F))));
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD2D6CE))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Material(
            color: const Color(0xFFEEF4EC),
            child: InkWell(
                onTap: () {
                  setState(() {
                    _abierto = !_abierto;
                    if (_abierto) _datos = _iniciarConsulta();
                  });
                },
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 13),
                    child: Row(children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          color: verde, size: 23),
                      const SizedBox(width: 9),
                      const Expanded(
                          child: Text('Tu pago',
                              style: TextStyle(
                                  color: verde,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700))),
                      Icon(_abierto ? Icons.expand_less : Icons.expand_more,
                          color: verde)
                    ])))),
        if (_abierto)
          FutureBuilder<Map<String, dynamic>>(
              future: _datos,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(children: [
                        const Text('No se pudo cargar el desglose.'),
                        TextButton(
                            onPressed: _recargar,
                            child: const Text('Reintentar'))
                      ]));
                }
                if (!snapshot.hasData) {
                  return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                          child: SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))));
                }
                final d = snapshot.data!;
                return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _fila('Pago por el servicio', d['pago_proveedor']),
                          _fila('Adelanto recibido', d['adelanto_proveedor'],
                              descuento: true),
                          if (d['adelanto_motivo'] != null &&
                              d['adelanto_motivo'].toString().trim().isNotEmpty)
                            _nota(d['adelanto_motivo'].toString()),
                          const Divider(),
                          Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFEEF4EC),
                                  borderRadius: BorderRadius.circular(10)),
                              child: _fila(
                                  'Saldo a transferir', d['saldo_transferir'],
                                  total: true)),
                          const SizedBox(height: 8),
                          _nota('El adelanto ya está descontado del saldo.'),
                          for (final recibo
                              in d['recibos_pagados'] as List? ?? [])
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: const Icon(Icons.check_circle_outline,
                                    color: verde),
                                title: Text(
                                    'Recibo del chat pagado · ${recibo['titulo']}'),
                                subtitle: const Text(
                                    'Este cobro no se suma a tus honorarios.')),
                          Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                  onPressed: _recargar,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Actualizar'),
                                  style: TextButton.styleFrom(
                                      foregroundColor: verde))),
                        ]));
              }),
      ]));
}
