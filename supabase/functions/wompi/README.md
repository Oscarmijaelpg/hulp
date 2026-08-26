# Función `wompi`

Centraliza las operaciones de Wompi que necesitan la **clave privada** y la
**clave de integridad**. Antes vivían en el bundle de las tres apps; en
`hulp_admin` eran descargables por URL.

## Qué cubre y qué no

Los **nueve** puntos del código que usaban la clave privada:

| acción | reemplaza | proyectos |
|---|---|---|
| `crear_cobro` | `create_transaction.dart` | admin, usuarios, talento |
| `crear_cobro_bancolombia` | `create_bancolombia_transfer_transaction.dart` | usuarios |
| `registrar_metodo_pago` `CARD` | `create_payment_source.dart` | usuarios |
| `registrar_metodo_pago` `NEQUI` | `nequi_verification_button.dart` | usuarios |
| `registrar_metodo_pago` `DAVIPLATA` | `daviplata_verification_widget.dart` | usuarios |
| `registrar_metodo_pago` `BANCOLOMBIA_TRANSFER` | `bancolombia_verification_widget.dart` y `api_calls.dart` | usuarios |

Los cuatro tipos van por la misma acción: comparten endpoint y solo cambian un
par de campos, así que separarlos sería repetir la misma validación cuatro
veces. El `tipo` va contra lista blanca.

**Fuera a propósito**: consultar el estado de una transacción,
`get_acceptance_token`, `tokenize_card` y los endpoints `/tokens/*` (incluidos
los de Nequi y DaviPlata). Todos usan la clave **pública**, que está pensada
para viajar en el cliente. Moverlos no aportaría nada y complicaría el cambio.

PSE no está implementado en ninguna app, así que no se cubre.

## Lo que la función NO acepta del cliente

Estas cuatro cosas se resuelven en el servidor aunque el cliente las mande:

- **El monto.** Sale de `recibos.total` cuando el cobro nace de un recibo
  —así paga el cliente desde Usuarios— y de `solicitudes_servicio.precio`
  cuando nace de una solicitud.

  **`precio` ya lleva los adicionales dentro.** Comprobado contra los cobros
  reales: de los diez últimos con `precio_adicionales` distinto de cero, nueve
  se cobraron por exactamente `precio` y ninguno por `precio + adicionales`.
  Sumarlos los cobraría dos veces —en un caso real, 169.800 en vez de 119.900.
  `precio_adicionales` es el desglose informativo y `precio_base` el precio de
  catálogo antes de ajustar.

- **El correo del cliente.** Sale de `usuarios.correo_electronico`.
- **La referencia y la firma.** La firma necesita la clave de integridad, que
  solo existe aquí.
- **De quién es el método de pago.** Se comprueba que el `payment_source_id`
  pertenece al cliente de esa solicitud, no a quien llama.

El `payment_source_id` se busca en **las dos** tablas que lo guardan:
`metodos_pago` (Nequi, DaviPlata, Bancolombia) y `tarjetas_guardadas` (las
tarjetas, 34 filas en producción frente a 3). Mirar solo una rechazaría pagos
válidos con un 403.

Quien llama solo elige *qué* solicitud cobrar, y tiene que ser el admin, el
cliente dueño de la solicitud o el proveedor asignado.

## Desplegar

```bash
# desde la raíz del repo de talento
supabase functions deploy wompi --project-ref <ref>
```

| entorno | project-ref |
|---|---|
| producción | `zexegravzidwloxeimxx` |
| test | `ptafsiwlhxomgqmdmidf` |

## Secrets

Cada proyecto lleva **sus propias** claves. El de test las de sandbox, el de
producción las de producción — así la separación de entornos se mantiene sola,
sin flags en el cliente.

```bash
supabase secrets set \
  WOMPI_PRIVATE_KEY=prv_... \
  WOMPI_INTEGRITY_KEY=..._integrity_... \
  WOMPI_ENTORNO=produccion \
  --project-ref <ref>
```

`WOMPI_ENTORNO` acepta `produccion` o `sandbox`; cualquier otro valor apunta a
sandbox, que es el fallo seguro.

`SUPABASE_URL`, `SUPABASE_ANON_KEY` y `SUPABASE_SERVICE_ROLE_KEY` los inyecta
la plataforma; no hay que cargarlos.

## Llamarla

```dart
final res = await Supabase.instance.client.functions.invoke(
  'wompi',
  body: {
    'accion': 'crear_cobro',
    'solicitud_id': solicitudId,
    'acceptance_token': tokenAceptacion,
    // 'payment_source_id': opcional; si falta se usa el predeterminado
  },
);
```

La respuesta tiene la **misma forma** que devolvía `createTransaction` en su
fase de creación (`success`, `transactionId`, `status`, `reference`, `amount`…),
así que el polling del cliente sigue funcionando sin cambios.

## Códigos de error

| código | significado |
|---|---|
| 401 | sin `Authorization` o sesión inválida |
| 403 | no participa en la solicitud, o el método de pago es de otro |
| 404 | la solicitud no existe |
| 409 | la solicitud ya figura pagada (pasar `reintentar: true` para forzar) |
| 422 | precio inválido, sin método de pago o sin correo |
| 502 | Wompi rechazó la operación; el detalle va en `details` |

## Pendiente

Esta función es el paso 1. Faltan, en este orden:

2. Que los tres proyectos la llamen y salgan `privateKey` e `integrityKey` de
   los `environment*.json`.
3. Publicar los tres y forzar la actualización con la tabla `AppVersion`.
4. **Solo entonces** rotar las claves en el panel de Wompi.

Rotar antes del paso 3 deja sin cobrar a todas las versiones instaladas.
