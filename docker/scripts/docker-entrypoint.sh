#!/bin/bash
# =============================================================================
#  Punto de entrada del contenedor EPrints
#
#  1. Valida las variables del archivo .env.
#  2. Espera a que MariaDB acepte conexiones.
#  3. SOLO LA PRIMERA VEZ: crea el repositorio con `epadmin create` (base de
#     datos, tablas, usuario administrador), copia la personalización del
#     hospital (docker/archive/overlay) e importa las categorías médicas.
#  4. EN CADA ARRANQUE: sincroniza nombre de host, puerto, nombre del
#     repositorio y servidor de correo con el .env; regenera la configuración
#     de Apache, las páginas estáticas y las vistas de navegación.
#  5. Cede el control al comando del contenedor (supervisord: Apache + indexador).
# =============================================================================
set -Eeuo pipefail

EPRINTS_PATH=${EPRINTS_PATH:-/opt/eprints3}
DOCKER_DIR=/opt/eprints-docker

: "${ARCHIVE_ID:=hgi}"
: "${EPRINTS_HOSTNAME:=repositorio.localhost}"
: "${EPRINTS_PORT:=8080}"
: "${EPRINTS_DB_HOST:=db}"
: "${EPRINTS_DB_USER:=$ARCHIVE_ID}"
: "${EPRINTS_ADMIN_USER:=admin}"
: "${EPRINTS_ADMIN_EMAIL:=admin@${EPRINTS_HOSTNAME}}"
: "${EPRINTS_ARCHIVE_NAME:=Repositorio Digital de Producción Científica e Investigación}"
: "${EPRINTS_ORG_NAME:=Hospital General de Itapúa}"
: "${EPRINTS_SMTP_SERVER:=mailpit:1025}"
export ARCHIVE_ID EPRINTS_HOSTNAME EPRINTS_PORT EPRINTS_DB_HOST EPRINTS_DB_USER \
       EPRINTS_ADMIN_USER EPRINTS_ADMIN_EMAIL

ARCHIVE_DIR="$EPRINTS_PATH/archives/$ARCHIVE_ID"
INIT_MARKER="$ARCHIVE_DIR/var/.docker-initialized"

log()  { printf '[entrypoint] %s\n' "$*"; }
die()  { printf '[entrypoint] ERROR: %s\n' "$*" >&2; exit 1; }
as_eprints() { runuser -u eprints -- "$@"; }

# -----------------------------------------------------------------------------
validate_env() {
    local missing=()
    for v in MARIADB_ROOT_PASSWORD EPRINTS_DB_PASSWORD EPRINTS_ADMIN_PASSWORD; do
        [ -n "${!v:-}" ] || missing+=("$v")
    done
    [ ${#missing[@]} -eq 0 ] || die "Faltan variables en .env: ${missing[*]} (copia .env.example a .env)"

    [[ $ARCHIVE_ID =~ ^[a-z][a-z0-9_]*$ ]] \
        || die "ARCHIVE_ID='$ARCHIVE_ID' no es válido: minúsculas, números y '_', empezando por letra."
    [[ $EPRINTS_HOSTNAME =~ ^[a-z0-9-]+(\.[a-z0-9-]+)*$ ]] \
        || die "EPRINTS_HOSTNAME='$EPRINTS_HOSTNAME' no es un nombre de host válido (solo minúsculas)."
    if [[ $EPRINTS_HOSTNAME == localhost || $EPRINTS_HOSTNAME =~ ^[0-9.]+$ ]]; then
        die "EPRINTS_HOSTNAME no puede ser 'localhost' ni una IP (EPrints lo rechaza por las cookies). Usa 'repositorio.localhost' en local o '<IP>.nip.io' en un VPS."
    fi
    [[ $EPRINTS_PORT =~ ^[0-9]+$ ]] || die "EPRINTS_PORT='$EPRINTS_PORT' debe ser un número."
    [[ $EPRINTS_DB_PASSWORD =~ ^[A-Za-z][A-Za-z0-9_]*$ ]] \
        || die "EPRINTS_DB_PASSWORD solo admite letras, números y '_', y debe empezar por letra (restricción de EPrints)."
    [[ $EPRINTS_DB_USER =~ ^[A-Za-z][A-Za-z0-9_]*$ ]] || die "EPRINTS_DB_USER no es válido."
    [[ $EPRINTS_ADMIN_EMAIL =~ ^[^@]+@[a-z0-9-]+(\.[a-z0-9-]+)*$ ]] \
        || die "EPRINTS_ADMIN_EMAIL='$EPRINTS_ADMIN_EMAIL' no es válido (el dominio debe ir en minúsculas)."
    if [[ ${#EPRINTS_ADMIN_PASSWORD} -lt 8 || $EPRINTS_ADMIN_PASSWORD =~ [[:space:]\'] ]]; then
        die "EPRINTS_ADMIN_PASSWORD debe tener al menos 8 caracteres, sin espacios ni comillas simples."
    fi
    if [[ $MARIADB_ROOT_PASSWORD =~ [[:space:]\'] ]]; then
        die "MARIADB_ROOT_PASSWORD no puede contener espacios ni comillas simples."
    fi
}

# -----------------------------------------------------------------------------
wait_for_db() {
    log "Esperando a MariaDB en '$EPRINTS_DB_HOST'..."
    for _ in $(seq 1 90); do
        if MYSQL_PWD="$MARIADB_ROOT_PASSWORD" mariadb-admin ping \
               -h "$EPRINTS_DB_HOST" -u root --silent >/dev/null 2>&1; then
            log "MariaDB disponible."
            return 0
        fi
        sleep 2
    done
    die "MariaDB no respondió en 3 minutos. Revisa 'docker compose logs db'."
}

# -----------------------------------------------------------------------------
xml_escape() {
    local s=$1
    s=${s//&/&amp;}; s=${s//</&lt;}; s=${s//>/&gt;}
    printf '%s' "$s"
}

# Valores que pueden cambiar entre arranques: se reescriben siempre desde .env
sync_config() {
    local cfg="$ARCHIVE_DIR/cfg"

    as_eprints tee "$cfg/cfg.d/10_core.pl" >/dev/null <<EOF
# ARCHIVO GENERADO por docker-entrypoint.sh EN CADA ARRANQUE.
# No lo edites a mano: cambia EPRINTS_HOSTNAME / EPRINTS_PORT en .env y
# ejecuta 'docker compose up -d'.
\$c->{host} = '$EPRINTS_HOSTNAME';
\$c->{port} = $EPRINTS_PORT;
# Quien entre por http://localhost:$EPRINTS_PORT (o por la IP) es redirigido
# al nombre de host canónico.
\$c->{aliases} = [ { name => 'localhost', redirect => 'yes' } ];
\$c->{securehost} = undef;
\$c->{secureport} = 443;
\$c->{http_root} = undef;
EOF

    as_eprints tee "$cfg/cfg.d/adminemail.pl" >/dev/null <<EOF
# ARCHIVO GENERADO por docker-entrypoint.sh (EPRINTS_ADMIN_EMAIL en .env)
\$c->{adminemail} = '$EPRINTS_ADMIN_EMAIL';
EOF

    as_eprints tee "$cfg/cfg.d/zz_docker.pl" >/dev/null <<EOF
# ARCHIVO GENERADO por docker-entrypoint.sh EN CADA ARRANQUE.
# Servidor SMTP (por defecto Mailpit, que captura los correos para pruebas:
# http://localhost:8025). Cambiar EPRINTS_SMTP_SERVER en .env.
\$c->{smtp_server} = '$EPRINTS_SMTP_SERVER';
EOF

    as_eprints tee "$cfg/lang/en/phrases/archive_name.xml" >/dev/null <<EOF
<?xml version="1.0" encoding="utf-8" standalone="no" ?>
<!DOCTYPE phrases SYSTEM "entities.dtd">
<!-- ARCHIVO GENERADO por docker-entrypoint.sh (EPRINTS_ARCHIVE_NAME / EPRINTS_ORG_NAME en .env) -->
<epp:phrases xmlns="http://www.w3.org/1999/xhtml" xmlns:epp="http://eprints.org/ep3/phrase">
	<epp:phrase id="archive_name">$(xml_escape "$EPRINTS_ARCHIVE_NAME")</epp:phrase>
	<epp:phrase id="organisation_name">$(xml_escape "$EPRINTS_ORG_NAME")</epp:phrase>
</epp:phrases>
EOF
}

# -----------------------------------------------------------------------------
create_archive() {
    log "Creando el repositorio '$ARCHIVE_ID' (solo ocurre la primera vez; tarda 1-3 minutos)..."

    local cfgfile
    cfgfile=$(mktemp /tmp/archive-XXXXXX.yml)
    envsubst '$ARCHIVE_ID $EPRINTS_HOSTNAME $EPRINTS_PORT $EPRINTS_ADMIN_EMAIL $EPRINTS_DB_HOST $EPRINTS_DB_USER $EPRINTS_DB_PASSWORD $MARIADB_ROOT_PASSWORD $EPRINTS_ADMIN_USER $EPRINTS_ADMIN_PASSWORD' \
        < "$DOCKER_DIR/archive/archive.yml.tmpl" > "$cfgfile"
    chown eprints:eprints "$cfgfile"
    chmod 0600 "$cfgfile"

    # stdin=/dev/null + timeout: si a epadmin le faltara algún dato no se queda
    # esperando una respuesta por teclado indefinidamente.
    local rc=0
    as_eprints timeout 900 "$EPRINTS_PATH/bin/epadmin" create --config="$cfgfile" </dev/null || rc=$?
    rm -f "$cfgfile"
    if [ $rc -ne 0 ] || [ ! -f "$ARCHIVE_DIR/cfg/cfg.d/database.pl" ]; then
        die "epadmin create falló (código $rc). Revisa el log anterior. Para reintentar desde cero: docker compose down -v && docker compose up -d"
    fi

    log "Aplicando la personalización del hospital (categorías y configuración)..."
    as_eprints cp -a "$DOCKER_DIR/archive/overlay/." "$ARCHIVE_DIR/"
    sync_config

    log "Importando categorías médicas (Investigación, Tesis, Guías Clínicas)..."
    as_eprints "$EPRINTS_PATH/bin/import_subjects" --force "$ARCHIVE_ID"

    as_eprints touch "$INIT_MARKER"
    log "Repositorio '$ARCHIVE_ID' creado correctamente."
}

# -----------------------------------------------------------------------------
main() {
    validate_env

    # El volumen de archives puede venir de una versión anterior de la imagen
    chown eprints:eprints "$EPRINTS_PATH/archives" "$EPRINTS_PATH/cfg" "$EPRINTS_PATH/var"

    wait_for_db

    if [ ! -d "$ARCHIVE_DIR/cfg" ]; then
        create_archive
    elif [ ! -f "$INIT_MARKER" ]; then
        die "El repositorio '$ARCHIVE_ID' quedó a medio crear en un arranque anterior. Para empezar de cero: docker compose down -v && docker compose up -d"
    else
        log "Repositorio '$ARCHIVE_ID' existente: sincronizando configuración con .env..."
        sync_config
    fi

    log "Generando configuración de Apache..."
    as_eprints "$EPRINTS_PATH/bin/generate_apacheconf" --system --replace --quiet

    log "Generando páginas estáticas y vistas de navegación..."
    as_eprints "$EPRINTS_PATH/bin/generate_static" --quiet "$ARCHIVE_ID"
    as_eprints "$EPRINTS_PATH/bin/generate_views" --quiet "$ARCHIVE_ID" || log "Aviso: generate_views devolvió un error (no crítico)."

    rm -f "$EPRINTS_PATH/var/indexer.pid"

    log "----------------------------------------------------------------"
    log " Repositorio listo en:  http://$EPRINTS_HOSTNAME:$EPRINTS_PORT/"
    log " Usuario administrador: $EPRINTS_ADMIN_USER"
    log "----------------------------------------------------------------"

    exec "$@"
}

main "$@"
