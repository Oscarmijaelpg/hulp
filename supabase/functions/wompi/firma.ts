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
 * El monto SIEMPRE se recalcula en el servidor, nunca se toma del cliente.
 *
 * Es el precio del servicio mas los adicionales. Cual de las dos columnas de
 * precio es "el precio del servicio" se decide asi:
 *
 *   `precio`       se escribe UNA vez, al crear la solicitud, con el precio
 *                  de catalogo de ese dia. Nadie lo actualiza despues: no
 *                  aparece en ningun update de solicitudes_servicio.
 *   `precio_base`  es el que el admin edita en edicion_solicitud_widget, y
 *                  por tanto el vigente.
 *
 * Difieren en 38 de las 91 solicitudes de produccion, asi que la diferencia
 * es dinero real. Se usa `precio_base`, y `precio` solo cuando aquel viene
 * nulo, que son 5 casos.
 *
 * Esto tambien unifica una incoherencia del codigo actual: aceptar_servicio
 * de talento sumaba sobre `precio` —el congelado— mientras finalizar_servicio
 * y el admin sumaban sobre `precio_base`. Cobraban distinto por la misma
 * solicitud si el admin habia tocado el precio.
 *
 * El redondeo va al final para no arrastrar el error de los flotantes:
 * 41000.1 * 100 da 4100009.999... y truncar cobraria un centavo de menos.
 */
export function centavosDeLaSolicitud(s: PreciosDeSolicitud): number {
  const servicio = s.precio_base ?? s.precio ?? 0;
  const adicionales = s.precio_adicionales ?? 0;
  return Math.round((servicio + adicionales) * 100);
}

/**
 * Lo que vale un recibo. Cuando el cobro nace de un recibo —que es como paga
 * el cliente desde la app de Usuarios— el importe es su total, sin mas
 * calculo: el recibo ya es el desglose cerrado y aceptado.
 */
export function centavosDeRecibo(total: number | null): number {
  return Math.round((total ?? 0) * 100);
}
