# OJS 3.5 para SUMARC (test)

Imagen Docker de OJS 3.5.0-6 con PHP 8.3 y Apache, más MySQL 8.4 en Compose.
Incluye los plugins de SUMARC: `docxConverter`, `texture`, `XMLMetadataBuilder`,
`jatsParser` y `scieloAdapter`.

## Construir la imagen

Se necesita Docker y una clave SSH con acceso a los repos de `sedici` en GitHub,
porque `SciELO-JATS-Converter` es privado. Por eso la imagen tampoco debe subirse
a un registro público.

```bash
# El tarball no está en git
curl -LO https://pkp.sfu.ca/ojs/download/ojs-3.5.0-6.tar.gz

./docker/fetch-plugins.sh      # baja los plugins a plugins-src/
cp .env.example .env
docker compose build
```

## Llevarla al servidor

El servidor no necesita el tarball ni acceso a los repos, solo la imagen y estos
dos archivos:

```bash
docker save sedici/ojs:3.5.0-6 | gzip | ssh USUARIO@SERVIDOR 'gunzip | docker load'
scp docker-compose.yml .env.example USUARIO@SERVIDOR:RUTA/
```

## Configurar `.env`

Copiar `.env.example` a `.env` y completar **antes del primer arranque**:

| Variable | Valor |
|---|---|
| `OJS_BASE_URL` | URL pública, sin barra final |
| `MYSQL_ROOT_PASSWORD`, `MYSQL_PASSWORD` | Contraseñas nuevas, sin comillas dobles |
| `OJS_BEHIND_PROXY`, `OJS_BIND_ADDRESS` | `true` y `127.0.0.1` con proxy inverso; `false` y `0.0.0.0` sin proxy |
| `OJS_PUBLIC_PORT` | Puerto publicado en el servidor |

`config.inc.php` se genera una sola vez. Si cambia la URL o una contraseña después
del primer arranque, hay que editar `data/config/config.inc.php`.

## Instalar

**Hasta completar la instalación, cualquiera que llegue a la URL puede configurar
el sitio y crear el administrador.** Restringir el acceso hasta terminar.

```bash
docker compose up -d --no-build
```

1. Entrar a la URL definitiva y completar el formulario:
   - Base de datos: driver `mysqli`, host `db`, y el usuario, contraseña y nombre del `.env`.
   - Directorio de archivos: `/var/www/files`.
2. Revisar `base_url` y `allowed_hosts` en `data/config/config.inc.php`, porque el
   instalador los reescribe con los datos del pedido web.
3. Abrir el acceso público.
4. Activar los plugins genéricos en cada revista, en
   *Ajustes > Sitio web > Plugins*.

### Pendiente: HTTPS, proxy y correo

Esta parte todavía no se probó.

- **HTTPS con proxy:** OJS detecta HTTPS solo por `$_SERVER['HTTPS']` y no mira
  `X-Forwarded-Proto`. Si el proxy termina el TLS, el instalador puede guardar
  `base_url` con `http://`, y hay que corregirlo a mano. `force_ssl` puede generar
  redirecciones en bucle en ese esquema.
- **Correo:** la imagen no trae `sendmail`. Hay que configurar `smtp`, `smtp_server`
  y `smtp_port` en la sección `[email]` de `config.inc.php`.

## Datos

Todo queda en `DATA_DIR` (`./data` por defecto) y sobrevive a recrear los contenedores:

| Carpeta | Contenido |
|---|---|
| `config/` | `config.inc.php` |
| `files/` | Archivos privados de OJS |
| `public/` | Archivos públicos de OJS |
| `mysql/` | Base de datos |

Los plugins viven dentro de la imagen. Uno instalado desde la galería de OJS se
pierde al recrear el contenedor.

## Actualizar plugins

Los commits están fijados en `docker/plugins.lock`. Para tomar cambios: subirlos
a GitHub, actualizar el commit en ese archivo, correr `./docker/fetch-plugins.sh`,
reconstruir y volver a llevar la imagen al servidor.

La imagen corre `composer install` solo en `jatsParser` y `scieloAdapter`, y usa el
`build.iife.js` commiteado de `texture`, sin correr `npm`.

## phpMyAdmin

No se levanta por defecto y solo escucha en `127.0.0.1`:

```bash
docker compose --profile tools up -d
```
