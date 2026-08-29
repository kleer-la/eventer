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
