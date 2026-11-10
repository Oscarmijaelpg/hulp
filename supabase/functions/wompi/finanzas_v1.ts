import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.119.0';

/** Only a server-to-server Wompi response may confirm a v1 transaction. */
export async function confirmarFinanzasV1(
  admin: SupabaseClient, actor: string, solicitudId: string,
  revision: number, reciboId: string | null, t: Record<string, any>,
): Promise<void> {
  if (t.status !== 'APPROVED') return;
  if (t.currency !== 'COP' || !Number.isSafeInteger(t.amount_in_cents) || t.amount_in_cents <= 0) {
    throw new Error('Respuesta monetaria inválida de Wompi');
  }
  const { data: attempts, error: attemptError } = await admin.from('intentos_cobro')
    .select('monto_centavos,detalle,recibo_id').eq('wompi_transaction_id', t.id).limit(1);
  if (attemptError || !attempts?.[0] || attempts[0].monto_centavos !== t.amount_in_cents ||
      attempts[0].recibo_id !== reciboId || attempts[0].detalle?.finanzas_revision !== revision) {
    throw new Error('La aprobación no coincide con la intención de cobro');
  }
  const { error } = await admin.rpc('solicitud_pago_confirmar_v1', {
    p_actor: actor, p_id: solicitudId, p_revision: revision,
    p_transaccion: crypto.randomUUID(), p_numero: t.id, p_monto: t.amount_in_cents / 100,
    p_metodo: t.payment_method_type ?? t.payment_method?.type ?? 'CARD',
    p_proveedor: 'WOMPI', p_recibo: reciboId, p_datos: t, p_referencia: t.reference ?? null,
  });
  if (error) throw error;
  await admin.from('intentos_cobro').update({ resultado: 'aprobado', wompi_status: 'APPROVED' })
    .eq('wompi_transaction_id', t.id);
}

/** El parámetro SQL conserva su nombre legado; aplica a TODOS los medios Wompi. */
export function prepararCobroWompiV1(
  admin: SupabaseClient,
  args: { p_actor: string; p_id: string; p_recibo: string | null;
    p_revision: number | null; p_centavos: number | null },
) {
  return admin.rpc('solicitud_cobro_preparar_v1', { ...args, p_tarjeta: true });
}
