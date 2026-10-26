type ContextoTokensAceptacion = {
  baseWompi: string;
  clavePublica: string;
  responder: (cuerpo: unknown, status?: number) => Response;
  error: (
    mensaje: string,
    status?: number,
    extra?: Record<string, unknown>,
  ) => Response;
};

export async function obtenerTokensAceptacion(
  contexto: ContextoTokensAceptacion,
): Promise<Response> {
  const { baseWompi, responder, error } = contexto;
  const clavePublica = contexto.clavePublica.trim();

  if (!clavePublica) {
    return error('Falta configurar WOMPI_PUBLIC_KEY en Supabase', 500);
  }

  let respuesta: Response;

  try {
    respuesta = await fetch(`${baseWompi}/merchants/info`, {
      method: 'GET',
      headers: {
        'x-merchant-public-key': clavePublica,
        'Accept': 'application/json',
      },
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    return error(
      'No se pudo contactar con Wompi para obtener los tokens',
      502,
    );
  }

  if (!respuesta.ok) {
    return error(
      'Wompi no permitió obtener los tokens de aceptación',
      502,
      { statusCode: respuesta.status },
    );
  }

  const datos = await respuesta.json().catch(() => null);

  const acceptanceToken =
    datos?.data?.presigned_acceptance?.acceptance_token;

  const personalDataAuthToken =
    datos?.data?.presigned_personal_data_auth?.acceptance_token;

  if (
    typeof acceptanceToken !== 'string' ||
    !acceptanceToken.trim() ||
    typeof personalDataAuthToken !== 'string' ||
    !personalDataAuthToken.trim()
  ) {
    return error(
      'Wompi no devolvió ambos tokens de aceptación válidos',
      502,
    );
  }

  return responder({
    success: true,
    acceptanceToken: acceptanceToken.trim(),
    personalDataAuthToken: personalDataAuthToken.trim(),
    message: 'Tokens de aceptación obtenidos correctamente',
  });
}
