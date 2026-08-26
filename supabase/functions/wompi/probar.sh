#!/usr/bin/env bash
# Ejercita la funcion wompi ya desplegada. Pensado para el proyecto de TEST,
# donde los secrets apuntan al sandbox de Wompi y ningun cobro es real.
#
#   ./probar.sh <url-del-proyecto> <anon-key> <jwt-de-un-usuario> [solicitud_id]
#
# El JWT se saca iniciando sesion como ese usuario; es el access_token de la
# sesion. Sin el, la funcion responde 401 y no se puede probar nada mas.

set -u

URL="${1:?falta la URL del proyecto, p.ej. https://ptafsiwlhxomgqmdmidf.supabase.co}"
ANON="${2:?falta la anon key}"
JWT="${3:?falta el JWT de un usuario}"
SOLICITUD="${4:-}"

FN="$URL/functions/v1/wompi"
ok=0
fallos=0

# Llama a la funcion y compara el codigo HTTP con el esperado.
probar() {
  local nombre="$1" esperado="$2" auth="$3" cuerpo="$4"
  local args=(-s -o /tmp/wompi_resp.json -w '%{http_code}' -X POST "$FN"
              -H "apikey: $ANON" -H 'Content-Type: application/json' -d "$cuerpo")
  [ -n "$auth" ] && args+=(-H "Authorization: Bearer $auth")

  local codigo
  codigo=$(curl "${args[@]}")

  if [ "$codigo" = "$esperado" ]; then
    printf '  \033[32mOK   \033[0m %-42s %s\n' "$nombre" "$codigo"
    ok=$((ok + 1))
  else
    printf '  \033[31mFALLA\033[0m %-42s esperaba %s, dio %s\n' "$nombre" "$esperado" "$codigo"
    echo "         $(head -c 200 /tmp/wompi_resp.json)"
    fallos=$((fallos + 1))
  fi
}

echo
echo "=== rechazos: lo que NO debe dejar pasar ==="
probar 'sin Authorization'            401 ''     '{"accion":"crear_cobro"}'
probar 'JWT invalido'                 401 'no-es-un-token' '{"accion":"crear_cobro"}'
probar 'accion desconocida'           400 "$JWT" '{"accion":"transferir_todo"}'
probar 'sin accion'                   400 "$JWT" '{}'
probar 'crear_cobro sin solicitud_id' 400 "$JWT" '{"accion":"crear_cobro","acceptance_token":"x"}'
probar 'solicitud inexistente'        404 "$JWT" \
  '{"accion":"crear_cobro","solicitud_id":"00000000-0000-0000-0000-000000000000","acceptance_token":"x"}'

echo
echo "=== registrar_metodo_pago: la lista blanca de tipos ==="
probar 'tipo no soportado (PSE)'      400 "$JWT"   '{"accion":"registrar_metodo_pago","tipo":"PSE","token":"x","acceptance_token":"y"}'
probar 'tipo inventado'               400 "$JWT"   '{"accion":"registrar_metodo_pago","tipo":"CRIPTO","token":"x","acceptance_token":"y"}'
probar 'sin tipo'                     400 "$JWT"   '{"accion":"registrar_metodo_pago","token":"x","acceptance_token":"y"}'
probar 'CARD sin token'               400 "$JWT"   '{"accion":"registrar_metodo_pago","tipo":"CARD","acceptance_token":"y"}'

echo
echo "=== crear_cobro_bancolombia: mismas defensas que crear_cobro ==="
probar 'bancolombia sin solicitud_id' 400 "$JWT"   '{"accion":"crear_cobro_bancolombia","acceptance_token":"x"}'
probar 'bancolombia, solicitud falsa' 404 "$JWT"   '{"accion":"crear_cobro_bancolombia","solicitud_id":"00000000-0000-0000-0000-000000000000","acceptance_token":"x"}'

if [ -n "$SOLICITUD" ]; then
  echo
  echo "=== con una solicitud real: $SOLICITUD ==="
  # El monto que se manda aqui debe ser IGNORADO por la funcion. Si el cobro
  # sale por esta cifra en vez de por el precio de la solicitud, hay un agujero.
  probar 'el monto del cliente se ignora' 200 "$JWT" \
    "{\"accion\":\"crear_cobro\",\"solicitud_id\":\"$SOLICITUD\",\"acceptance_token\":\"x\",\"amount_in_cents\":1}"
  echo "         respuesta: $(head -c 300 /tmp/wompi_resp.json)"
  echo
  echo "  Comprobar a mano que 'amount' es el precio de la solicitud x100,"
  echo "  no 1. Si dice 1, la funcion esta confiando en el cliente."
fi

echo
echo "=== $ok correctas, $fallos fallidas ==="
[ "$fallos" -eq 0 ]
