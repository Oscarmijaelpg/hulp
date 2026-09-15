/// Identificador que no existe en ninguna tabla.
///
/// `eqOrNull(columna, valor)` **no filtra por NULL**: cuando el valor es null
/// devuelve la consulta *sin* el filtro, es decir, la tabla entera
/// (`backend/supabase/database/table.dart`). En un buscador opcional eso es lo
/// que se busca; en una consulta por clave ajena es un desastre silencioso: si
/// la solicitud fue borrada o todavía no tiene chat, la pantalla termina
/// leyendo los chats y mensajes de **otros clientes**, y el contador de no
/// leídos suma los de toda la base.
///
/// Usar `?? idInexistente` en esos casos deja la consulta vacía, que es lo que
/// la pantalla espera cuando no hay nada que mostrar.
const String idInexistente = '00000000-0000-0000-0000-0000000000ff';
