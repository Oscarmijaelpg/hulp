import { assertEquals, assertRejects } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.119.0';
import { confirmarFinanzasV1, prepararCobroWompiV1 } from './finanzas_v1.ts';
import { cadenaDeFirma, centavosDeLaSolicitud, sha256Hex } from './firma.ts';

function backend(monto = 6300000) {
  const calls: Array<Record<string, unknown>> = [];
  const admin = {
    from: () => ({
      select: () => ({ eq: () => ({ limit: async () => ({ data: [
        { monto_centavos: monto, recibo_id: 'recibo', detalle: { finanzas_revision: 2 } },
      ], error: null }) }) }),
      update: () => ({ eq: async () => ({ error: null }) }),
    }),
    rpc: async (_name: string, args: Record<string, unknown>) => { calls.push(args); return { error: null }; },
  } as unknown as SupabaseClient;
  return { admin, calls };
}
const approved = { id: 'wompi-test', status: 'APPROVED', currency: 'COP', amount_in_cents: 6300000,
  reference: 'referencia-prueba', payment_method: { type: 'CARD' } };

Deno.test('solo APPROVED comprobado registra el importe confirmado y el recibo', async () => {
  const { admin, calls } = backend();
  await confirmarFinanzasV1(admin, 'actor', 'solicitud', 2, 'recibo', { ...approved, status: 'DECLINED' });
  assertEquals(calls.length, 0);
  await confirmarFinanzasV1(admin, 'actor', 'solicitud', 2, 'recibo', approved);
  assertEquals(calls.length, 1);
  assertEquals(calls[0].p_monto, 63000);
  assertEquals(calls[0].p_recibo, 'recibo');
  assertEquals(calls[0].p_revision, 2);
  assertEquals(calls[0].p_datos, approved);
});

Deno.test('rechaza aprobación que no coincide con monto, recibo, revisión o moneda', async () => {
  const { admin, calls } = backend();
  for (const run of [
    () => confirmarFinanzasV1(admin, 'actor', 'solicitud', 2, 'recibo', { ...approved, amount_in_cents: 1 }),
    () => confirmarFinanzasV1(admin, 'actor', 'solicitud', 2, 'ajeno', approved),
    () => confirmarFinanzasV1(admin, 'actor', 'solicitud', 3, 'recibo', approved),
    () => confirmarFinanzasV1(admin, 'actor', 'solicitud', 2, 'recibo', { ...approved, currency: 'USD' }),
  ]) await assertRejects(run);
  assertEquals(calls.length, 0);
});

Deno.test('firma y cálculo legado mantienen su contrato', async () => {
  assertEquals(cadenaDeFirma('referencia', 150000, 'cop', 'clave-ficticia'), 'referencia150000COPclave-ficticia');
  assertEquals(centavosDeLaSolicitud({ precio: 100000, precio_base: 120000, precio_adicionales: 60000 }), 18000000);
  assertEquals(await sha256Hex('abc'), 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
});

Deno.test('preparar cobro Wompi aplica recargo sin depender de CARD', async () => {
  const { admin, calls } = backend();
  const args = { p_actor: 'actor', p_id: 'solicitud', p_recibo: null,
    p_revision: 1, p_centavos: 1420860 };
  // Ambos caminos (fuente guardada y transferencia Bancolombia) usan este contrato.
  await prepararCobroWompiV1(admin, args);
  assertEquals(calls, [{ ...args, p_tarjeta: true }]);
});
