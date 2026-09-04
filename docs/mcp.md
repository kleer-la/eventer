# Server MCP: editar el blog desde Claude

Eventer expone un server [MCP](https://modelcontextprotocol.io) en `/mcp` que
permite leer y editar los artículos del blog conversando con Claude, con los
mismos permisos que tenés en el admin.

- QA: `https://qa.eventos.kleer.la/mcp`
- Producción: `https://eventos.kleer.la/mcp`

## Conectar

La autenticación es **OAuth 2.1**: no hay tokens que copiar y pegar. El cliente
se registra solo, te manda al login de eventer, te pide permiso y listo.

### claude.ai o Claude Desktop (y por lo tanto el celular)

1. Settings → Connectors → **Add custom connector**.
2. URL: `https://qa.eventos.kleer.la/mcp` (sin token ni header).
3. Se abre la pantalla de eventer: entrás con tu usuario y apretás **Authorize**.

### Claude Code

```bash
claude mcp add --transport http eventer https://qa.eventos.kleer.la/mcp
```

Abre el navegador para autorizar igual que arriba. Verificá con `/mcp` dentro de
Claude Code: tiene que listar los tools.

## Qué se puede hacer

| Tool | Qué hace |
|---|---|
| `list_articles` | Lista artículos con filtros (título, idioma, publicado, categoría). Sin cuerpos |
| `get_article` | Un artículo completo, con el cuerpo, por slug o id |
| `create_article` | Crea uno nuevo |
| `update_article` | Edita uno existente, incluido publicar/despublicar |

Los tools de escritura funcionan **en dos pasos**: la primera llamada devuelve un
*preview* de lo que cambiaría sin guardar nada, y recién con `confirm=true`
persiste. Claude te tiene que mostrar el preview antes de confirmar.

Hay tools equivalentes para recursos, servicios, páginas, podcasts y novedades.

## Cursos y certificados

Además del contenido del sitio, el server expone la cadena que hace falta para
darle su certificado a alguien que quedó fuera del sistema: el curso que se dio,
el evento, la persona y el PDF.

| Tool | Qué hace |
|---|---|
| `list_event_types` | Busca tipos de curso: el id que necesita un evento, y el nombre y la duración que salen impresos |
| `create_event_type` | Crea un tipo de curso nuevo, **siempre fuera del catálogo público** |
| `list_events` | Busca ediciones de un curso, por nombre, ciudad o fecha |
| `create_event` | Crea una edición; **privada y gratuita** salvo que digas otra cosa |
| `search_participants` | Busca personas por nombre, mail o código de verificación |
| `create_participant` | Inscribe a alguien en un evento y devuelve su código de verificación |
| `issue_certificate` | Genera el PDF A4 y LETTER y los sube a S3 |

Los cuatro de escritura funcionan en dos pasos igual que los de contenido:
`confirm=false` (el default) muestra qué haría sin tocar nada.

### Por qué el certificado necesita toda la cadena

`kleer.la/certificado` no consulta esta base: lista el bucket `Keventer` por el
prefijo del código y devuelve el PDF que encuentre. O sea que un certificado es
verificable **recién cuando el archivo está en S3**, y el archivo saca su texto
del participante, del evento y del tipo de curso. De ahí el orden:

```
list_event_types  →  create_event  →  create_participant  →  issue_certificate
(o create_event_type si el curso no existe)
```

El link que devuelve `issue_certificate` en `verify_at` tiene una sola forma
que funciona: `https://www.kleer.la/es/certificado?q=<código>` (o
`/en/certificate` para un curso en inglés). El código va en el query string, no
en el path, y tiene que ser el host con `www` y con prefijo de idioma: el
dominio pelado redirige 301 y se come el `?q=`, con lo cual la página llega con
el formulario vacío.

`issue_certificate` no manda ningún mail salvo que le pases `notify=true`. Y no
genera nada si el participante no está en Presente (A) o Certificado (K), o si
el trainer 1 del evento no tiene firma cargada: el PDF saldría sin firmar. Los
dos motivos vienen también en `search_participants`, en
`certificate_blocked_by`, antes de que intentes emitir.

### Dos cosas que los tools deciden por vos

- **El tipo de curso se crea fuera del catálogo** (`include_in_catalog` en
  falso, sin argumento que lo cambie). Ese mismo registro es la ficha del curso
  en el sitio: ponerlo a la venta es una decisión que se sigue tomando desde el
  admin.
- **El evento se crea privado** (`visibility_type: 'pr'`) y con precio 0. Cargar
  un curso que ya se dio no es publicar un curso nuevo. Si querés uno público,
  pedilo explícitamente.

### Datos personales

`search_participants` devuelve mail y estado de cada persona, y vale la regla de
siempre: los mismos permisos que en el admin, donde `can :read, :all` alcanza a
cualquier usuario con rol, incluido `comercial`. Nunca lista a todo el mundo —
exige un término de búsqueda o un `event_id` — pero si querés que los datos de
participantes queden fuera del alcance de un conector, eso se cambia en
`ability.rb`, no en los tools.

## Listados: nunca devuelven "todo" en silencio

Los `list_*` truncan (25 por defecto, 100 máximo; imágenes 50 y 200) y lo dicen:
la respuesta trae `returned`, `total` y, cuando sobra algo, `truncated: true` y
una `note` que nombra los filtros con los que afinar. Es a propósito: un listado
de 25 sin más datos se lee como el mundo entero, y "no está en los primeros 25"
termina llegando al usuario como "no existe".

## Editar un texto largo sin reenviarlo entero

Cambiar una frase de un cuerpo de 6.000 caracteres no debería costar mandar los
6.000 de vuelta. Los tools de edición aceptan `replacements`, una lista de
reemplazos aplicados en orden sobre un campo largo:

```json
{
  "id": "mi-articulo",
  "replacements": [
    { "field": "body", "find": "la frase vieja", "replace": "la frase nueva" }
  ]
}
```

- `replace` vacío borra el texto encontrado; `all: true` reemplaza todas las
  apariciones.
- Si `find` no aparece, o aparece más de una vez sin `all`, **falla y no guarda
  nada**: es a propósito, para que una copia desactualizada del texto se note en
  lugar de editar la frase equivocada.
- El preview muestra cada edición con el texto que la rodea, no el principio del
  campo.
- Qué campos lo aceptan: `body` en artículos; `description` en novedades,
  podcasts y episodios; las cuatro descripciones largas de recursos; y los
  bloques de servicios. En los campos de texto enriquecido (podcast, episodio,
  servicios) el `find` se busca contra el **HTML**.

## Permisos

Valen las reglas de `app/models/ability.rb`, las mismas que las pantallas:

| Rol | Leer | Crear / editar | Publicar |
|---|---|---|---|
| sin rol | no | no | no |
| comercial | sí | no | no |
| content | sí | sí | **no** |
| publisher | sí | sí | sí |
| marketing | sí | sí | sí |
| administrator | sí | sí | sí |

Un usuario `content` que pida publicar recibe un error y no se guarda nada, igual
que si intentara hacerlo desde el formulario. Para cambiar esto se toca
`ability.rb`, no los tools.

## Revocar una conexión

Admin → **Others → MCP Connections**. Cada uno ve las suyas; el administrator ve
todas. **Revoke** corta el acceso de ese cliente en el acto: revoca todos los
tokens que tenga, no sólo el de esa fila, porque si no el refresh token le
conseguiría uno nuevo enseguida.

## Detalles

- Los access tokens duran 2 horas y se renuevan con refresh token. Se guardan
  hasheados.
- Clientes públicos con PKCE obligatorio; se registran solos por
  `POST /oauth/register` (RFC 7591). El descubrimiento va por
  `/.well-known/oauth-authorization-server` y `/.well-known/oauth-protected-resource`.
- El middleware MCP se monta **antes de Warden** a propósito: el failure app de
  Devise intercepta cualquier 401 de más abajo y le reescribe el header
  `WWW-Authenticate`, con lo cual el cliente nunca descubriría por dónde
  autorizar. Ver el comentario en `config/initializers/fast_mcp.rb`.
- Editar el cuerpo de un artículo dispara `GenerateArticleAudioJob`: se regenera
  el audio hablado. Los tools lo avisan en los warnings.
