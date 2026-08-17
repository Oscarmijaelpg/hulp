-- ===========================================================================
-- eliminar_mi_cuenta() v2 — patron de "cuenta lapida"
--
-- Aplica a AMBAS apps: comparten el proyecto zexegravzidwloxeimxx.
-- Reemplaza la version desplegada, que solo era segura para proveedores.
--
-- QUE ESTABA MAL EN LA v1
--
-- 1. Un CLIENTE no podia borrarse sin destruir el historial de terceros.
--    solicitudes_servicio.usuario_id es CASCADE y NOT NULL, asi que borrar
--    su fila arrastraba en cadena:
--        solicitudes_servicio -> recibos     -> recibo_items, mensajes_chat
--                             -> transacciones   (los pagos)
--                             -> resenas, calificaciones, chats_solicitud
--    Es decir, los ingresos y el historial de los PROVEEDORES que lo
--    atendieron desaparecian con el.
--
-- 2. recibos.proveedor_id tambien es CASCADE y la v1 no lo cubria: borrar un
--    proveedor destruia los recibos de todos los trabajos que hizo. Ese bug
--    ya esta vivo en produccion.
--
-- 3. La v1 borraba transacciones.usuario_id del usuario. Para proveedores hoy
--    son 0 filas, pero un cliente tiene las suyas: se perdian los pagos.
--
-- 4. soporte guarda nombre/telefono/email del CLIENTE y no tiene id_usuario,
--    solo id_proveedor. Los datos personales del cliente sobrevivian al
--    borrado. Aqui se limpian cruzando por email.
--
-- COMO LO RESUELVE
--
-- Todo lo que tiene valor contable o pertenece tambien a la contraparte se
-- REASIGNA a una fila fija sin datos personales; solo se BORRA lo que es
-- exclusivamente de la cuenta. Asi se respetan los NOT NULL, no hace falta
-- tocar el esquema, y los getters no-nulables de Dart
-- (getField<String>('usuario_id')!) siguen funcionando.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1. La cuenta lapida
--
--    usuarios.id tiene FK a auth.users (fk_usuarios_auth, ON DELETE CASCADE),
--    asi que la lapida necesita su propia fila de autenticacion. Se crea sin
--    contrasena y sin identidad: no hay forma de iniciar sesion con ella. El
--    dominio .invalid esta reservado por el RFC 2606 y no puede recibir
--    correo, asi que tampoco se puede pedir un restablecimiento.
--
--    De auth.users solo 'id' es NOT NULL sin default; el resto se completa
--    para que la fila se vea correcta en el panel de Authentication.
--
--    rol='eliminado' mantiene la fila fuera de todo listado de la app, que
--    filtra por 'usuario' / 'proveedor' / 'administrador'.
-- ---------------------------------------------------------------------------
insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
values ('00000000-0000-0000-0000-000000000000',
        '00000000-0000-0000-0000-000000000000',
        'authenticated', 'authenticated',
        'cuenta-eliminada@no-reply.invalid', now(), now())
on conflict (id) do nothing;

insert into public.usuarios (id, nombres, apellidos, rol, verificado)
values ('00000000-0000-0000-0000-000000000000',
        'Cuenta', 'eliminada', 'eliminado', 'eliminado')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- 2. La funcion
-- ---------------------------------------------------------------------------
create or replace function public.eliminar_mi_cuenta()
returns json
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
declare
  c_lapida        constant uuid := '00000000-0000-0000-0000-000000000000';
  v_uid           uuid := auth.uid();
  v_email         text;
  v_rol           text;
  v_solicitudes   int := 0;
  v_transacciones int := 0;
  v_recibos       int := 0;
  v_perfil        int := 0;
begin
  -- Sin parametros a proposito: el usuario sale de auth.uid(), asi que es
  -- imposible pedir el borrado de la cuenta de otra persona.
  if v_uid is null then
    raise exception 'No hay sesion activa' using errcode = '28000';
  end if;

  -- Sin esto, un token con ese uuid vaciaria el historial de todos.
  if v_uid = c_lapida then
    raise exception 'La cuenta lapida no se puede eliminar' using errcode = '42501';
  end if;

  select rol into v_rol from public.usuarios where id = v_uid;
  select email into v_email from auth.users where id = v_uid;

  -- =========================================================================
  -- A. REASIGNAR A LA LAPIDA
  --    Va primero: en cuanto se borre la fila de usuarios, estas cascadas se
  --    disparan. Lo que aqui no se salve, se pierde.
  -- =========================================================================

  -- Lado CLIENTE: usuario_id es NOT NULL y CASCADE, asi que o va a la lapida
  -- o la solicitud entera se destruye con sus recibos, pagos y resenas.
  -- Cambiar solo esta columna no despierta al trigger de abajo, que se fija
  -- unicamente en profesional_id.
  update public.solicitudes_servicio
     set usuario_id = c_lapida
   where usuario_id = v_uid;
  get diagnostics v_solicitudes = row_count;

  -- Lado PROVEEDOR: aqui va NULL, no la lapida, y es a proposito.
  --
  -- trigger_crear_chat_al_asignar_proveedor corre AFTER UPDATE y, cuando el
  -- profesional cambia a un valor NO NULO, borra todos los mensajes del chat.
  -- Si ese chat tiene un recibo asociado (recibos.mensaje_id), el DELETE choca
  -- contra recibos_mensaje_id_fkey y aborta el borrado de cuenta entero.
  -- Poniendo NULL la condicion del trigger no se cumple y no se dispara.
  --
  -- Ademas es lo semanticamente correcto: profesional_id nulo significa "sin
  -- asignar", asi que los trabajos aun activos vuelven al pool. La identidad
  -- de quien presto el servicio no se pierde: queda en recibos.proveedor_id,
  -- que si apunta a la lapida.
  update public.solicitudes_servicio
     set profesional_id = null
   where profesional_id = v_uid;

  -- Pagos. transacciones.usuario_id es NO ACTION y NOT NULL: si queda una
  -- sola fila apuntando al usuario, el DELETE final aborta la transaccion
  -- entera.
  update public.transacciones
     set usuario_id = c_lapida
   where usuario_id = v_uid;
  get diagnostics v_transacciones = row_count;

  -- Recibos emitidos como proveedor: son el comprobante del CLIENTE.
  update public.recibos
     set proveedor_id = c_lapida
   where proveedor_id = v_uid;
  get diagnostics v_recibos = row_count;

  -- Reputacion: la resena escrita le sirve al proveedor, y la recibida le
  -- sirve al cliente. Se conservan sin autor identificable.
  update public.resenas       set usuario_id   = c_lapida where usuario_id   = v_uid;
  update public.resenas       set proveedor_id = c_lapida where proveedor_id = v_uid;
  update public.calificaciones set usuario_id   = c_lapida where usuario_id   = v_uid;
  update public.calificaciones set proveedor_id = c_lapida where proveedor_id = v_uid;

  -- Los mensajes se quedan para que la contraparte conserve el hilo legible.
  update public.mensajes_chat
     set remitente_id = c_lapida
   where remitente_id = v_uid;

  -- =========================================================================
  -- B. ANONIMIZAR TICKETS DE SOPORTE
  --    Guardan nombre, telefono y email en texto plano. id_proveedor es TEXT
  --    y sin FK; del cliente no hay id, solo el email.
  -- =========================================================================
  update public.soporte
     set nombre_proveedor   = 'Cuenta eliminada',
         telefono_proveedor = null,
         email_proveedor    = null
   where id_proveedor = v_uid::text;

  if v_email is not null then
    update public.soporte
       set nombre_usuario   = 'Cuenta eliminada',
           telefono_usuario = null,
           email_usuario    = null
     where email_usuario = v_email;
  end if;

  -- =========================================================================
  -- C. BORRAR LO EXCLUSIVAMENTE PERSONAL
  --    Casi todas tienen ON DELETE CASCADE, pero se listan explicitamente
  --    para que el borrado no dependa de que nadie afloje una FK mas adelante.
  --    conversaciones NO tiene FK: aqui es imprescindible.
  -- =========================================================================
  delete from public.tarjetas_guardadas    where usuario_id = v_uid;
  delete from public.metodos_pago          where usuario_id = v_uid;
  delete from public.cuentas_bancarias     where usuario_id = v_uid;
  delete from public.certificaciones       where usuario_id = v_uid;
  delete from public.referencias_laborales where usuario_id = v_uid;
  delete from public.profesional_servicios where usuario_id = v_uid;
  delete from public.favoritos             where usuario_id = v_uid;
  delete from public.conversaciones        where usuario_id = v_uid;
  delete from public.cleanup_programado    where usuario_id = v_uid;
  delete from public.user_notifications    where user_id    = v_uid;

  delete from public.notificaciones
   where usuario_id = v_uid or proveedor_id = v_uid;

  -- usuarios_externos.id es el uuid de auth; id_usuario es un bigint de
  -- secuencia, NO comparar contra un uuid.
  delete from public.usuarios_externos where id = v_uid;

  delete from public.usuarios where id = v_uid;
  get diagnostics v_perfil = row_count;

  -- =========================================================================
  -- D. Cuenta de autenticacion, al final: una vez borrada, auth.uid() deja de
  --    resolver dentro de esta misma transaccion.
  -- =========================================================================
  delete from auth.users where id = v_uid;

  return json_build_object(
    'ok', true,
    'uid', v_uid,
    'rol', v_rol,
    'perfil_borrado', v_perfil > 0,
    'solicitudes_preservadas', v_solicitudes,
    'transacciones_preservadas', v_transacciones,
    'recibos_preservados', v_recibos
  );
end;
$function$;

revoke all on function public.eliminar_mi_cuenta() from public, anon;
grant execute on function public.eliminar_mi_cuenta() to authenticated;

-- ===========================================================================
-- COMPROBACION posterior (con una cuenta de prueba):
--
--   select count(*) from solicitudes_servicio
--    where usuario_id = '00000000-0000-0000-0000-000000000000';
--
-- Debe crecer tras cada borrado, no quedarse en cero. Si se queda en cero y
-- el total de solicitudes bajo, la cascada gano y hay que revisar el orden.
-- ===========================================================================
