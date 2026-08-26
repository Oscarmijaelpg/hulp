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
  precio_base: number | null;
  precio_adicionales: number | null;
}

/**
 * El monto SIEMPRE se recalcula desde la solicitud, nunca se toma del cliente.
 *
 * Replica la formula de los widgets: precio_base, y si viene nulo se cae a
 * precio; luego se suman los adicionales. El redondeo va al final para no
 * arrastrar el error de los flotantes: 41000.1 * 100 da 4100009.999... y
 * truncar en vez de redondear cobraria un centavo de menos.
 */
export function centavosDeLaSolicitud(s: PreciosDeSolicitud): number {
  const base = s.precio_base ?? s.precio ?? 0;
  const adicionales = s.precio_adicionales ?? 0;
  return Math.round((base + adicionales) * 100);
}
