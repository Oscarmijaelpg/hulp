// ============================================================================
// Wompi del lado del servidor.
//
// Hasta ahora las tres apps llamaban a Wompi directamente con la clave privada
// y la de integridad dentro del bundle. En hulp_admin eso significaba que
// cualquiera podia descargarlas de
//   https://www.hulpweb.com/assets/assets/environment_values/environment.json
// y en las apps moviles sacarlas del bundle con herramientas corrientes.
//
// Esta funcion es la unica que conoce esas dos claves. Las apps le piden la
// operacion y ella decide si procede.
//
// NO cubre consultar el estado de una transaccion: eso usa la clave PUBLICA,
// que no es secreta, y sigue haciendose desde el cliente como hasta ahora.
// Tampoco get_acceptance_token ni tokenize_card, que tambien son de la publica.
//
// Desplegar (desde la raiz del repo de talento):
//   supabase functions deploy wompi --project-ref <ref>
//     produccion  zexegravzidwloxeimxx
//     test        ptafsiwlhxomgqmdmidf
//
// Secrets que hay que cargar en CADA proyecto, con sus valores propios
// (produccion las prv_prod_/prod_integrity_, test las de sandbox):
//   supabase secrets set WOMPI_PRIVATE_KEY=... WOMPI_INTEGRITY_KEY=... \
//     WOMPI_ENTORNO=produccion|sandbox --project-ref <ref>
//
// SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY los inyecta la plataforma sola.
//
// Se usa service role para leer la solicitud, asi que la autorizacion se
// comprueba a mano y de forma explicita: RLS no protege aqui.
// ============================================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { sha256Hex, cadenaDeFirma, centavosDeLaSolicitud } from './firma.ts';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const JSON_HEADERS = { ...CORS, 'Content-Type': 'application/json' };

/** Respuesta JSON con la forma que ya esperan las apps. */
function responder(cuerpo: unknown, status = 200): Response {
  return new Response(JSON.stringify(cuerpo), { status, headers: JSON_HEADERS });
}

/** Error con la misma forma que devolvian las acciones de FlutterFlow. */
function error(mensaje: string, status = 400, extra: Record<string, unknown> = {}): Response {
  return responder({ success: false, error: mensaje, ...extra }, status);
}

const BASE_WOMPI = Deno.env.get('WOMPI_ENTORNO') === 'produccion'
  ? 'https://production.wompi.co/v1'
  : 'https://sandbox.wompi.co/v1';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS });
  }

  try {
    const clavePrivada = Deno.env.get('WOMPI_PRIVATE_KEY');
    const claveIntegridad = Deno.env.get('WOMPI_INTEGRITY_KEY');
    if (!clavePrivada || !claveIntegridad) {
      console.error('Faltan los secrets de Wompi en este proyecto');
      return error('La funcion no esta configurada', 500);
    }

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return error('Falta Authorization', 401);

    // Cliente con el token de quien llama: sirve para saber QUIEN es.
    const comoUsuario = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: errAuth } = await comoUsuario.auth.getUser();
    if (errAuth || !user) return error('Sesion invalida', 401);

    // Cliente con service role: lee precios y correos sin depender de RLS.
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const cuerpo = await req.json().catch(() => ({}));
    const accion = cuerpo.accion;

    // ------------------------------------------------------------------
    // crear_cobro: reemplaza createTransaction en los tres proyectos.
    // ------------------------------------------------------------------
    if (accion === 'crear_cobro') {
      const { solicitud_id, acceptance_token } = cuerpo;
      if (!solicitud_id) return error('Falta solicitud_id', 400, { field: 'solicitud_id' });
      if (!acceptance_token) return error('Falta acceptance_token', 400, { field: 'acceptance_token' });

      const { data: solicitud, error: errSol } = await admin
        .from('solicitudes_servicio')
        .select('id, usuario_id, profesional_id, precio, precio_base, precio_adicionales, estado_pago')
        .eq('id', solicitud_id)
        .maybeSingle();
      if (errSol) {
        console.error('Error leyendo la solicitud:', errSol);
        return error('No se pudo leer la solicitud', 500);
      }
      if (!solicitud) return error('La solicitud no existe', 404);

      // Autorizacion explicita. Puede cobrar el admin, el cliente dueño de la
      // solicitud, o el proveedor asignado — nadie mas.
      const { data: quien } = await admin
        .from('usuarios')
        .select('rol')
        .eq('id', user.id)
        .maybeSingle();

      const esAdmin = quien?.rol === 'admin';
      const esCliente = user.id === solicitud.usuario_id;
      const esProveedor = user.id === solicitud.profesional_id;
      if (!esAdmin && !esCliente && !esProveedor) {
        console.warn(`Cobro rechazado: ${user.id} no participa en ${solicitud_id}`);
        return error('No autorizado para cobrar esta solicitud', 403);
      }

      // Evita el doble cobro: sin esto, dos toques seguidos en el boton pasan
      // dos veces por Wompi.
      if (solicitud.estado_pago === 'pagado' && cuerpo.reintentar !== true) {
        return error('Esta solicitud ya figura pagada', 409, { estado_pago: solicitud.estado_pago });
      }

      const montoEnCentavos = centavosDeLaSolicitud(solicitud);
      if (montoEnCentavos <= 0) {
        return error('La solicitud no tiene un precio valido', 422, { montoEnCentavos });
      }

      // El metodo de pago tiene que ser del cliente de ESTA solicitud, no de
      // quien llama: el admin cobra en nombre del cliente.
      let paymentSourceId = cuerpo.payment_source_id ?? null;
      if (paymentSourceId) {
        const { data: metodo } = await admin
          .from('metodos_pago')
          .select('payment_source_id')
          .eq('usuario_id', solicitud.usuario_id)
          .eq('payment_source_id', paymentSourceId)
          .maybeSingle();
        if (!metodo) return error('El metodo de pago no es de este cliente', 403);
      } else {
        const { data: metodo } = await admin
          .from('metodos_pago')
          .select('payment_source_id')
          .eq('usuario_id', solicitud.usuario_id)
          .eq('es_predeterminado', true)
          .maybeSingle();
        if (!metodo?.payment_source_id) {
          return error('El cliente no tiene metodo de pago predeterminado', 422);
        }
        paymentSourceId = metodo.payment_source_id;
      }

      const { data: cliente } = await admin
        .from('usuarios')
        .select('correo_electronico')
        .eq('id', solicitud.usuario_id)
        .maybeSingle();
      const correo = cliente?.correo_electronico?.trim().toLowerCase();
      if (!correo) return error('El cliente no tiene correo registrado', 422);

      const moneda = 'COP';
      const referencia = `${solicitud.id}-${Date.now()}`;
      const firma = await sha256Hex(
        cadenaDeFirma(referencia, montoEnCentavos, moneda, claveIntegridad),
      );

      const respuesta = await fetch(`${BASE_WOMPI}/transactions`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${clavePrivada}`,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: JSON.stringify({
          amount_in_cents: montoEnCentavos,
          currency: moneda,
          customer_email: correo,
          payment_method: { installments: 1 },
          reference: referencia,
          payment_source_id: Number(paymentSourceId),
          acceptance_token: String(acceptance_token).trim(),
          signature: firma,
        }),
      });

      const datos = await respuesta.json().catch(() => ({}));
      if (!respuesta.ok) {
        console.error('Wompi rechazo la transaccion:', respuesta.status, JSON.stringify(datos));
        return responder({
          success: false,
          error: datos?.error?.reason ?? datos?.error?.type ?? 'Error al crear transaccion',
          statusCode: respuesta.status,
          details: datos,
          phase: 'CREATION',
        }, 502);
      }

      const t = datos.data ?? {};
      console.log(`Cobro creado ${t.id} · solicitud ${solicitud.id} · ${montoEnCentavos} · ${t.status}`);

      // Misma forma que devolvia createTransaction, para que el cliente siga
      // haciendo su polling con la clave publica sin cambiar nada mas.
      return responder({
        success: true,
        transactionId: t.id,
        status: t.status,
        statusMessage: t.status_message ?? '',
        amount: t.amount_in_cents,
        currency: t.currency,
        customerEmail: t.customer_email,
        reference: t.reference,
        createdAt: t.created_at,
        finalizedAt: t.finalized_at,
        paymentMethod: t.payment_method,
        paymentSourceId: t.payment_source_id,
        fullData: t,
      });
    }

    // ------------------------------------------------------------------
    // registrar_metodo_pago: reemplaza createPaymentSource (tarjeta).
    // El token de tarjeta lo genera el cliente con la clave PUBLICA.
    // ------------------------------------------------------------------
    if (accion === 'registrar_metodo_pago') {
      const { card_token, acceptance_token } = cuerpo;
      if (!card_token) return error('Falta card_token', 400, { field: 'card_token' });
      if (!acceptance_token) return error('Falta acceptance_token', 400, { field: 'acceptance_token' });

      // El metodo se registra siempre a nombre de quien llama, con el correo
      // que tiene en la base: asi nadie registra tarjetas para otra cuenta.
      const { data: yo } = await admin
        .from('usuarios')
        .select('correo_electronico')
        .eq('id', user.id)
        .maybeSingle();
      const correo = (yo?.correo_electronico ?? user.email)?.trim().toLowerCase();
      if (!correo) return error('La cuenta no tiene correo registrado', 422);

      const respuesta = await fetch(`${BASE_WOMPI}/payment_sources`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${clavePrivada}`,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: JSON.stringify({
          type: 'CARD',
          token: String(card_token).trim(),
          customer_email: correo,
          acceptance_token: String(acceptance_token).trim(),
        }),
      });

      const datos = await respuesta.json().catch(() => ({}));
      if (!respuesta.ok) {
        console.error('Wompi rechazo el payment source:', respuesta.status, JSON.stringify(datos));
        return responder({
          success: false,
          error: datos?.error?.reason ?? datos?.error?.type ?? 'Error al registrar el metodo de pago',
          statusCode: respuesta.status,
          details: datos,
        }, 502);
      }

      const p = datos.data ?? {};
      return responder({
        success: true,
        paymentSourceId: p.id,
        status: p.status,
        type: p.type,
        customerEmail: p.customer_email,
        fullData: p,
      });
    }

    // ------------------------------------------------------------------
    // registrar_metodo_pago_bancolombia: reemplaza tanto
    // createBancolombiaTransferTransaction como la llamada suelta de
    // api_calls.dart ("Bancolombia paymentsources PROD").
    // ------------------------------------------------------------------
    if (accion === 'registrar_metodo_pago_bancolombia') {
      const { token, acceptance_token, accept_personal_auth } = cuerpo;
      if (!token) return error('Falta token', 400, { field: 'token' });
      if (!acceptance_token) return error('Falta acceptance_token', 400, { field: 'acceptance_token' });

      const { data: yo } = await admin
        .from('usuarios')
        .select('correo_electronico')
        .eq('id', user.id)
        .maybeSingle();
      const correo = (yo?.correo_electronico ?? user.email)?.trim().toLowerCase();
      if (!correo) return error('La cuenta no tiene correo registrado', 422);

      const respuesta = await fetch(`${BASE_WOMPI}/payment_sources`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${clavePrivada}`,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: JSON.stringify({
          type: 'BANCOLOMBIA_TRANSFER',
          token: String(token).trim(),
          payment_description: cuerpo.payment_description ?? 'Pago de servicio Hulp',
          customer_email: correo,
          acceptance_token: String(acceptance_token).trim(),
          accept_personal_auth: accept_personal_auth ?? '',
        }),
      });

      const datos = await respuesta.json().catch(() => ({}));
      if (!respuesta.ok) {
        console.error('Wompi rechazo el payment source Bancolombia:', respuesta.status, JSON.stringify(datos));
        return responder({
          success: false,
          error: datos?.error?.reason ?? datos?.error?.type ?? 'Error al registrar la cuenta',
          statusCode: respuesta.status,
          details: datos,
        }, 502);
      }

      const p = datos.data ?? {};
      return responder({
        success: true,
        paymentSourceId: p.id,
        status: p.status,
        type: p.type,
        customerEmail: p.customer_email,
        fullData: p,
      });
    }

    return error(`Accion desconocida: ${accion ?? '(ninguna)'}`, 400);
  } catch (e) {
    console.error('Error en la funcion wompi:', e);
    return error('Error interno', 500);
  }
});
