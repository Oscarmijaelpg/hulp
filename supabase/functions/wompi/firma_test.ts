// deno test --allow-none supabase/functions/wompi/firma_test.ts
//
// Los hashes esperados NO estan copiados de esta implementacion: se calcularon
// aparte con hashlib de Python. Si se generaran con el mismo codigo que se
// prueba, el test pasaria aunque el algoritmo estuviera mal.

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import {
  sha256Hex,
  cadenaDeFirma,
  centavosDeLaSolicitud,
  centavosDeRecibo,
} from './firma.ts';

Deno.test('sha256Hex coincide con hashlib', async () => {
  assertEquals(
    await sha256Hex(''),
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
  );
  assertEquals(
    await sha256Hex('abc'),
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
  );
});

Deno.test('sha256Hex rellena con cero los bytes menores que 0x10', async () => {
  // El digest de 'hulp-5' empieza por el byte 0x0f. Sin padStart saldria 'f'
  // en vez de '0f', el hex entero se correria un caracter y quedaria en 63:
  // es el fallo clasico de esta funcion, y Wompi lo devuelve como firma
  // invalida sin decir por que.
  const h = await sha256Hex('hulp-5');
  assertEquals(
    h,
    '0f5460c329b66daba117011b18ac3364f7f9456cf1696d21a81058d09a07a950',
  );
  assertEquals(h.length, 64);
});

Deno.test('la cadena de firma respeta el orden de Wompi', () => {
  // referencia + monto + moneda(mayusculas) + clave, sin separadores.
  assertEquals(
    cadenaDeFirma('REF-1', 4100000, 'cop', 'secreto'),
    'REF-14100000COPsecreto',
  );
  // Los espacios sobrantes se recortan, como hacia el codigo Dart.
  assertEquals(
    cadenaDeFirma('  REF-1  ', 100, 'COP', '  secreto  '),
    'REF-1100COPsecreto',
  );
});

Deno.test('la firma completa coincide con el calculo independiente', async () => {
  // hashlib.sha256(b'REF-14100000COPclave_de_integridad').hexdigest()
  assertEquals(
    await sha256Hex(cadenaDeFirma('REF-1', 4100000, 'COP', 'clave_de_integridad')),
    '15580ce34e94dc0abd50d246716cc09c8bb26892909011c4755acefaccb21944',
  );
});

Deno.test('el monto es `precio`, que ya lleva los adicionales dentro', () => {
  // Caso real de produccion: precio 119900 con 49900 de adicionales se cobro
  // por 119900. Sumarlos daria 169800 y cobraria los adicionales dos veces.
  assertEquals(centavosDeLaSolicitud({ precio: 119900 }), 11990000);
});

Deno.test('sin precio no hay cobro, y cero lo rechaza la funcion', () => {
  assertEquals(centavosDeLaSolicitud({ precio: null }), 0);
});

Deno.test('el recibo se cobra por su total, sin recalcular', () => {
  assertEquals(centavosDeRecibo(260000), 26000000);
  assertEquals(centavosDeRecibo(null), 0);
});

Deno.test('el redondeo no pierde un centavo por el error de coma flotante', () => {
  // 41000.1 * 100 en coma flotante da 4100009.999999999; truncar cobraria
  // 4100009. Se espera el redondeo.
  assertEquals(centavosDeLaSolicitud({ precio: 41000.1 }), 4100010);
  assertEquals(centavosDeRecibo(0.1 + 0.2), 30);
});
