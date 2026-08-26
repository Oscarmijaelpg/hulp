// Piezas puras de la funcion wompi, separadas para poder probarlas sin
// levantar el servidor. Un error aqui no falla ruidosamente: Wompi devuelve
// que la firma es invalida y NINGUN cobro pasa.

/** SHA-256 en hexadecimal, igual que `sha256.convert(...).toString()` en Dart. */
export async function sha256Hex(texto: string): Promise<string> {
  const datos = new TextEncoder().encode(texto);
  const hash = await crypto.subtle.digest('SHA-256', datos);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

/**
 * Firma de integridad de Wompi: sha256 de referencia + monto + moneda + clave.
 * El orden y el formato son los que ya usaba create_transaction.dart; cambiar
 * cualquiera de los cuatro invalida la transaccion.
 */
export function cadenaDeFirma(
  referencia: string,
  centavos: number,
  moneda: string,
  claveIntegridad: string,
): string {
  return `${referencia.trim()}${centavos}${moneda.toUpperCase()}${claveIntegridad.trim()}`;
}

/** Lo que la solicitud vale, en centavos. */
export interface PreciosDeSolicitud {
  precio: number | null;
}

/**
 * El monto SIEMPRE se recalcula en el servidor, nunca se toma del cliente.
 *
 * `precio` es el TOTAL a cobrar y ya lleva los adicionales dentro. Se
 * comprobo contra los cobros reales de produccion: de los diez ultimos con
 * `precio_adicionales` distinto de cero, nueve se cobraron por exactamente
 * `precio` y ninguno por `precio + precio_adicionales`.
 *
 * Por eso NO se suma `precio_adicionales`, que es el desglose informativo:
 * sumarlo cobraria los adicionales dos veces. En un caso real —precio 119900
 * con 49900 de adicionales— serian 169800 en lugar de 119900.
 *
 * Tampoco se usa `precio_base`, que es el precio de catalogo antes de
 * ajustar: en esos mismos diez casos difiere de `precio` en nueve.
 *
 * El redondeo va al final para no arrastrar el error de los flotantes:
 * 41000.1 * 100 da 4100009.999... y truncar cobraria un centavo de menos.
 */
export function centavosDeLaSolicitud(s: PreciosDeSolicitud): number {
  return Math.round((s.precio ?? 0) * 100);
}

/**
 * Lo que vale un recibo. Cuando el cobro nace de un recibo —que es como paga
 * el cliente desde la app de Usuarios— el importe es su total, sin mas
 * calculo: el recibo ya es el desglose cerrado y aceptado.
 */
export function centavosDeRecibo(total: number | null): number {
  return Math.round((total ?? 0) * 100);
}
