// ============================================================================
// Wompi del lado del servidor.
//
// Hasta ahora las tres apps llamaban a Wompi directamente con la clave privada
// y la de integridad dentro del bundle. En hulp_admin eso significaba que
// cualquiera podia descargarlas de
//   https://www.hulpweb.com/assets/assets/environment_values/environment.json
// y en las apps moviles sacarlas del bundle con herramientas corrientes.
//
// Esta funcion es la unica que conoce esas dos claves.
//
// Cubre los NUEVE puntos del codigo que usaban la clave privada:
//
//   crear_cobro                  create_transaction.dart  (admin, usuarios, talento)
//   crear_cobro_bancolombia      create_bancolombia_transfer_transaction.dart
//   registrar_metodo_pago CARD                 create_payment_source.dart
//   registrar_metodo_pago NEQUI                nequi_verification_button.dart
//   registrar_metodo_pago DAVIPLATA            daviplata_verification_widget.dart
//   registrar_metodo_pago BANCOLOMBIA_TRANSFER bancolombia_verification_widget.dart
//                                              y api_calls.dart
//
// NO cubre, y es a proposito: consultar el estado de una transaccion,
// get_acceptance_token, tokenize_card y los endpoints /tokens/*. Todos usan la
// clave PUBLICA, que esta pensada para viajar en el cliente. Moverlos no
// aportaria nada.
//
// Desplegar (desde la raiz del repo de talento):
//   supabase functions deploy wompi --project-ref <ref>
//     produccion  zexegravzidwloxeimxx
//     test        ptafsiwlhxomgqmdmidf
//
// Secrets, con valores propios por proyecto:
//   supabase secrets set WOMPI_PRIVATE_KEY=... WOMPI_INTEGRITY_KEY=... \
//     WOMPI_ENTORNO=produccion|sandbox --project-ref <ref>
//
// Se usa service role para leer precios y correos, asi que la autorizacion se
// comprueba a mano y de forma explicita: RLS no protege aqui.
// ============================================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import {
  sha256Hex,
  cadenaDeFirma,
  centavosDeLaSolicitud,
  centavosDeRecibo,
} from './firma.ts';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const JSON_HEADERS = { ...CORS, 'Content-Type': 'application/json' };

/** Los cuatro tipos que las apps registran hoy. Lista blanca a proposito. */
const TIPOS_VALIDOS = ['CARD', 'NEQUI', 'DAVIPLATA', 'BANCOLOMBIA_TRANSFER'] as const;
type TipoMetodo = typeof TIPOS_VALIDOS[number];

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

// deno-lint-ignore no-explicit-any
type Cliente = any;

/** Correo de una cuenta, siempre desde la base y nunca desde el cliente. */
async function correoDe(admin: Cliente, uid: string): Promise<string | null> {
  const { data } = await admin
    .from('usuarios')
    .select('correo_electronico')
    .eq('id', uid)
    .maybeSingle();
  const correo = data?.correo_electronico?.trim().toLowerCase();
  return correo || null;
}

/**
 * Comprueba que un payment_source_id es del cliente indicado.
 *
 * Hay DOS tablas con payment_source_id y ambas se usan: `metodos_pago` guarda
 * Nequi, DaviPlata y Bancolombia, y `tarjetas_guardadas` las tarjetas. Mirar
 * solo una rechazaria pagos perfectamente validos.
 */
async function esDelCliente(
  admin: Cliente,
  paymentSourceId: string | number,
  usuarioId: string,
): Promise<boolean> {
  const { data: m } = await admin
    .from('metodos_pago')
    .select('id')
    .eq('usuario_id', usuarioId)
    .eq('payment_source_id', paymentSourceId)
    .maybeSingle();
  if (m) return true;

  const { data: t } = await admin
    .from('tarjetas_guardadas')
    .select('id')
    .eq('usuario_id', usuarioId)
    .eq('payment_source_id', String(paymentSourceId))
    .maybeSingle();
  return !!t;
}

/** El predeterminado del cliente, mirando tambien en las dos tablas. */
async function predeterminadoDe(admin: Cliente, usuarioId: string): Promise<string | null> {
  const { data: m } = await admin
    .from('metodos_pago')
    .select('payment_source_id')
    .eq('usuario_id', usuarioId)
    .eq('es_predeterminado', true)
    .maybeSingle();
  if (m?.payment_source_id) return String(m.payment_source_id);

  const { data: t } = await admin
    .from('tarjetas_guardadas')
    .select('payment_source_id')
    .eq('usuario_id', usuarioId)
    .eq('predeterminada', true)
    .eq('activa', true)
    .maybeSingle();
  return t?.payment_source_id ? String(t.payment_source_id) : null;
}

/** Traduce el error de Wompi a algo legible sin perder el detalle. */
async function fallo(respuesta: Response, contexto: string): Promise<Response> {
  const datos = await respuesta.json().catch(() => ({}));
  console.error(`Wompi rechazo ${contexto}:`, respuesta.status, JSON.stringify(datos));
  return responder({
    success: false,
    error: datos?.error?.reason ?? datos?.error?.type ?? `Error en ${contexto}`,
    statusCode: respuesta.status,
    details: datos,
  }, 502);
}

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

    const comoUsuario = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: errAuth } = await comoUsuario.auth.getUser();
    if (errAuth || !user) return error('Sesion invalida', 401);

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const cabeceraWompi = {
      'Authorization': `Bearer ${clavePrivada}`,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    const cuerpo = await req.json().catch(() => ({}));
    const accion = cuerpo.accion;

    // ------------------------------------------------------------------
    // Las dos acciones de cobro comparten toda la validacion: cargar la
    // solicitud, ver quien pide el cobro y cuanto vale de verdad.
    // ------------------------------------------------------------------
    if (accion === 'crear_cobro' || accion === 'crear_cobro_bancolombia') {
      const { recibo_id, acceptance_token } = cuerpo;
      let { solicitud_id } = cuerpo;
      if (!acceptance_token) return error('Falta acceptance_token', 400, { field: 'acceptance_token' });

      // El cobro nace de un recibo o de una solicitud. Desde la app de
      // Usuarios se paga un recibo; desde el admin y talento, la solicitud.
      let totalDelRecibo: number | null = null;
      if (recibo_id) {
        const { data: recibo } = await admin
          .from('recibos')
          .select('id, solicitud_id, total, estado')
          .eq('id', recibo_id)
          .maybeSingle();
        if (!recibo) return error('El recibo no existe', 404);
        totalDelRecibo = recibo.total;
        solicitud_id = recibo.solicitud_id;
      }
      if (!solicitud_id) {
        return error('Falta solicitud_id o recibo_id', 400, { field: 'solicitud_id' });
      }

      const { data: solicitud, error: errSol } = await admin
        .from('solicitudes_servicio')
        .select('id, usuario_id, profesional_id, precio, estado_pago')
        .eq('id', solicitud_id)
        .maybeSingle();
      if (errSol) {
        console.error('Error leyendo la solicitud:', errSol);
        return error('No se pudo leer la solicitud', 500);
      }
      if (!solicitud) return error('La solicitud no existe', 404);

      // Puede cobrar el admin, el cliente dueño de la solicitud o el proveedor
      // asignado. Nadie mas.
      const { data: quien } = await admin
        .from('usuarios')
        .select('rol')
        .eq('id', user.id)
        .maybeSingle();

      const autorizado = quien?.rol === 'admin'
        || user.id === solicitud.usuario_id
        || user.id === solicitud.profesional_id;
      if (!autorizado) {
        console.warn(`Cobro rechazado: ${user.id} no participa en ${solicitud_id}`);
        return error('No autorizado para cobrar esta solicitud', 403);
      }

      // Sin esto, dos toques seguidos en el boton pasan dos veces por Wompi.
      if (solicitud.estado_pago === 'pagado' && cuerpo.reintentar !== true) {
        return error('Esta solicitud ya figura pagada', 409, { estado_pago: solicitud.estado_pago });
      }

      const montoEnCentavos = totalDelRecibo !== null
        ? centavosDeRecibo(totalDelRecibo)
        : centavosDeLaSolicitud(solicitud);
      if (montoEnCentavos <= 0) {
        return error('No hay un importe valido que cobrar', 422, { montoEnCentavos });
      }

      const correo = await correoDe(admin, solicitud.usuario_id);
      if (!correo) return error('El cliente no tiene correo registrado', 422);

      const moneda = 'COP';
      // El reference identifica el cobro en Wompi y ha de ser unico. Se
      // mantiene el formato que ya usaban admin y talento.
      const referencia = `${recibo_id ?? solicitud.id}-${Date.now()}`;

      // --- transferencia Bancolombia, sin fuente de pago guardada ---
      if (accion === 'crear_cobro_bancolombia') {
        // El codigo actual no manda signature en este flujo. Se replica tal
        // cual: anadirla ahora cambiaria el comportamiento de un camino que
        // no se puede probar sin una cuenta de Bancolombia de verdad.
        const respuesta = await fetch(`${BASE_WOMPI}/transactions`, {
          method: 'POST',
          headers: cabeceraWompi,
          body: JSON.stringify({
            acceptance_token: String(acceptance_token).trim(),
            amount_in_cents: montoEnCentavos,
            currency: moneda,
            customer_email: correo,
            reference: referencia,
            payment_method: {
              type: 'BANCOLOMBIA_TRANSFER',
              payment_description: cuerpo.payment_description ?? 'Pago con Bancolombia',
              user_type: 'PERSON',
            },
          }),
        });
        if (!respuesta.ok) return await fallo(respuesta, 'la transferencia Bancolombia');

        const datos = await respuesta.json();
        const t = datos.data ?? {};
        console.log(`Transferencia creada ${t.id} · solicitud ${solicitud.id} · ${montoEnCentavos}`);
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
          fullData: t,
        });
      }

      // --- cobro contra una fuente de pago guardada ---
      let paymentSourceId = cuerpo.payment_source_id ?? null;
      if (paymentSourceId) {
        // Tiene que ser del cliente de ESTA solicitud, no de quien llama: el
        // admin cobra en nombre del cliente.
        if (!await esDelCliente(admin, paymentSourceId, solicitud.usuario_id)) {
          return error('El metodo de pago no es de este cliente', 403);
        }
      } else {
        paymentSourceId = await predeterminadoDe(admin, solicitud.usuario_id);
        if (!paymentSourceId) {
          return error('El cliente no tiene metodo de pago predeterminado', 422);
        }
      }

      const firma = await sha256Hex(
        cadenaDeFirma(referencia, montoEnCentavos, moneda, claveIntegridad),
      );

      const respuesta = await fetch(`${BASE_WOMPI}/transactions`, {
        method: 'POST',
        headers: cabeceraWompi,
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
      if (!respuesta.ok) return await fallo(respuesta, 'la transaccion');

      const datos = await respuesta.json();
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
    // registrar_metodo_pago: los cuatro tipos por el mismo camino.
    //
    // Todos van al mismo endpoint y solo cambian un par de campos, asi que
    // una accion por tipo seria repetir la misma validacion cuatro veces.
    // El token siempre lo genera el cliente con la clave PUBLICA.
    // ------------------------------------------------------------------
    if (accion === 'registrar_metodo_pago') {
      const { tipo, token, acceptance_token } = cuerpo;
      if (!tipo) return error('Falta tipo', 400, { field: 'tipo' });
      if (!TIPOS_VALIDOS.includes(tipo as TipoMetodo)) {
        return error(`Tipo no soportado: ${tipo}`, 400, { field: 'tipo', validos: TIPOS_VALIDOS });
      }
      if (!token) return error('Falta token', 400, { field: 'token' });
      if (!acceptance_token) return error('Falta acceptance_token', 400, { field: 'acceptance_token' });

      // El metodo se registra siempre a nombre de QUIEN LLAMA: el usuario_id
      // no se acepta del cliente, asi que nadie registra medios de pago en
      // otra cuenta.
      //
      // El correo si se respeta cuando viene, porque DaviPlata pide el suyo en
      // pantalla y no tiene por que ser el de Hulp. Es una etiqueta para
      // Wompi, no da acceso a nada: lo que ata el metodo a la cuenta es el
      // usuario_id con el que se guarda despues.
      const correo = String(cuerpo.customer_email ?? '').trim().toLowerCase()
        || (await correoDe(admin, user.id))
        || user.email?.trim().toLowerCase();
      if (!correo) return error('No hay correo para registrar el metodo', 422);
      if (!correo.includes('@')) return error('El correo no es valido', 400, { field: 'customer_email' });

      // deno-lint-ignore no-explicit-any
      const payload: Record<string, any> = {
        type: tipo,
        token: String(token).trim(),
        customer_email: correo,
        acceptance_token: String(acceptance_token).trim(),
      };
      // CARD es el unico que no lleva autorizacion de datos personales.
      if (tipo !== 'CARD') {
        payload.accept_personal_auth = cuerpo.accept_personal_auth ?? '';
      }
      if (tipo === 'BANCOLOMBIA_TRANSFER') {
        payload.payment_description = cuerpo.payment_description ?? 'Pago de servicio Hulp';
      }

      const respuesta = await fetch(`${BASE_WOMPI}/payment_sources`, {
        method: 'POST',
        headers: cabeceraWompi,
        body: JSON.stringify(payload),
      });
      if (!respuesta.ok) return await fallo(respuesta, `el registro de ${tipo}`);

      const datos = await respuesta.json();
      const p = datos.data ?? {};
      console.log(`Metodo ${tipo} registrado ${p.id} · usuario ${user.id}`);
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
