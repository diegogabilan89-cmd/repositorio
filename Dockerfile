# syntax=docker/dockerfile:1
# =============================================================================
#  EPrints 3.5 — Repositorio Digital de Producción Científica e Investigación
#  del Hospital General de Itapúa
#
#  Imagen: Debian 13 (trixie) + Apache 2.4 + mod_perl 2 + EPrints 3.5
#  Se usa junto con docker-compose.yml (MariaDB + Mailpit). Ver
#  docs/DESPLIEGUE_DOCKER.md para la documentación completa.
# =============================================================================

# -----------------------------------------------------------------------------
# Etapa 1 — "source": prepara el código fuente de EPrints
# -----------------------------------------------------------------------------
FROM debian:trixie-slim AS source

# Commits exactos de los submódulos (los mismos que fija el repositorio git).
# Si se actualiza un submódulo con `git submodule update --remote`, actualizar
# también aquí el commit correspondiente.
ARG PUB_LIB_REF=439cde22aec7a63925c83f4642772d65cf321654
ARG EASY_PAGES_REF=15f6122331e581cd3fae596ede1a48dd73651ad5
ARG RICHTEXT_REF=942b5e7764a0911df554c0a735cc2a76df6be38d
ARG LATEST_ADDITIONS_REF=2b2a15fae88c0731cc83c9971551de8e9496e90e

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

COPY . /src
WORKDIR /src

# 1) Si el repositorio se clonó sin `--recurse-submodules`, las carpetas de los
#    submódulos llegan vacías: se descargan aquí desde github.com/eprints.
# 2) Git en Windows (core.symlinks=false) convierte los enlaces simbólicos del
#    repositorio (p. ej. lib/citations/*/panel_*.xml) en archivos de texto que
#    solo contienen la ruta de destino. Se detectan y se vuelven a convertir en
#    enlaces: archivo pequeño, de una línea, cuyo contenido es una ruta
#    relativa a un archivo que existe.
# 3) Se eliminan retornos de carro (CRLF) de los ejecutables por si el código
#    se clonó en Windows sin respetar .gitattributes.
RUN set -eu; \
    fetch() { \
      dir="$1"; name="$2"; ref="$3"; \
      if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then \
        echo ">> Submódulo $dir vacío: descargando eprints/$name@$ref"; \
        mkdir -p "$dir"; \
        curl -fsSL "https://codeload.github.com/eprints/$name/tar.gz/$ref" \
          | tar -xz --strip-components=1 -C "$dir"; \
      fi; \
    }; \
    fetch flavours/pub_lib            pub_lib          "$PUB_LIB_REF"; \
    fetch ingredients/easy_pages      easy_pages       "$EASY_PAGES_REF"; \
    fetch ingredients/richtext        richtext         "$RICHTEXT_REF"; \
    fetch ingredients/latest_additions latest_additions "$LATEST_ADDITIONS_REF"; \
    test -f flavours/pub_lib/package.yml.tmpl; \
    find lib perl_lib cgi flavours ingredients -type f -size -200c | while IFS= read -r f; do \
      [ "$(wc -l < "$f")" -le 1 ] || continue; \
      t=$(cat "$f"); \
      case "$t" in ""|*[!A-Za-z0-9_./-]*) continue ;; *.*) ;; *) continue ;; esac; \
      [ -f "$(dirname "$f")/$t" ] || continue; \
      ln -sfn "$t" "$f"; echo ">> Enlace simbólico restaurado: $f -> $t"; \
    done; \
    grep -rlI "$(printf '\r')" bin tools testdata/bin docker 2>/dev/null | xargs -r sed -i 's/\r$//'; \
    cp perl_lib/EPrints/SystemSettings.pm.tmpl perl_lib/EPrints/SystemSettings.pm


# -----------------------------------------------------------------------------
# Etapa 2 — imagen final
# -----------------------------------------------------------------------------
FROM debian:trixie-slim

LABEL org.opencontainers.image.title="EPrints 3.5 — Repositorio Digital HGI" \
      org.opencontainers.image.description="Repositorio Digital de Producción Científica e Investigación del Hospital General de Itapúa (EPrints 3.5)" \
      org.opencontainers.image.licenses="LGPL-3.0-or-later" \
      org.opencontainers.image.source="https://github.com/diegogabilan89-cmd/repositorio"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    EPRINTS_PATH=/opt/eprints3 \
    EPRINTS_PORT=8080 \
    EPRINTS_HOSTNAME=repositorio.localhost \
    APACHE_MAX_REQUEST_WORKERS=20

# Dependencias del sistema:
#  - Apache + mod_perl (servidor web de EPrints)
#  - Módulos Perl listados en perl_lib/EPrints/Bundle/EPrints.pm
#  - Bcrypt para el cifrado moderno de contraseñas
#  - Herramientas para indexar texto completo y crear miniaturas de PDF
#  - supervisor (gestiona Apache + indexador), cliente MariaDB, curl, envsubst
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      apache2 libapache2-mod-perl2 \
      libarchive-zip-perl libbibtex-parser-perl libcgi-pm-perl libconfig-general-perl \
      libdbi-perl libdbd-mysql-perl libfile-bom-perl libfile-slurp-perl \
      libhttp-message-perl libimage-exiftool-perl libio-string-perl \
      libjson-perl liblwp-mediatypes-perl liblwp-protocol-https-perl \
      libwww-perl libmailtools-perl libmime-types-perl libmime-lite-perl \
      libnet-ldap-perl libterm-readkey-perl libtex-encode-perl \
      libtext-unidecode-perl liburi-perl libxml-dom-perl libxml-libxml-perl \
      libxml-namespacesupport-perl libxml-parser-perl libxml-sax-expatxs-perl \
      libxml-libxslt-perl libyaml-tiny-perl libyaml-pp-perl \
      libcrypt-eksblowfish-perl libcrypt-urandom-perl libdata-entropy-perl \
      poppler-utils imagemagick ghostscript antiword html2text \
      unzip wget file ncal \
      supervisor mariadb-client curl ca-certificates gettext-base \
      cpanminus make \
 # Módulos que Debian no empaqueta: se instalan desde CPAN
 && cpanm --notest --quiet Text::Extract::Word Text::Refer URI::OpenURL \
 && apt-get purge -y --auto-remove cpanminus make \
 && rm -rf /root/.cpanm /var/lib/apt/lists/*

# Usuario de sistema propietario de EPrints (Apache también se ejecuta con él)
RUN groupadd --system eprints \
 && useradd --system --gid eprints --home-dir /opt/eprints3 --shell /bin/bash eprints

COPY --from=source --chown=eprints:eprints /src /opt/eprints3
RUN install -d -o eprints -g eprints /opt/eprints3/cfg /opt/eprints3/var /opt/eprints3/archives

# Apache: MPM prefork (requerido por mod_perl), sin el sitio por defecto,
# ejecutándose con el usuario eprints y con logs hacia stdout/stderr.
COPY --from=source /src/docker/apache/ports.conf   /etc/apache2/ports.conf
COPY --from=source /src/docker/apache/eprints.conf /etc/apache2/conf-available/eprints.conf
RUN a2dismod -q -f mpm_event \
 && a2enmod -q mpm_prefork perl headers \
 && a2dissite -q 000-default \
 && a2disconf -q other-vhosts-access-log \
 && a2enconf -q eprints \
 && sed -ri 's/^export APACHE_RUN_(USER|GROUP)=.*/export APACHE_RUN_\1=eprints/' /etc/apache2/envvars

# Scripts y plantillas propios del despliegue Docker
COPY --from=source /src/docker/supervisord.conf /etc/supervisor/supervisord.conf
COPY --from=source /src/docker/scripts/         /usr/local/bin/
COPY --from=source --chown=eprints:eprints /src/docker/archive/ /opt/eprints-docker/archive/
COPY --from=source --chown=eprints:eprints /src/docker/seed/    /opt/eprints-docker/seed/
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh \
               /usr/local/bin/eprints-indexer-supervised \
               /usr/local/bin/eprints-seed

WORKDIR /opt/eprints3
VOLUME ["/opt/eprints3/archives"]
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD curl -fsS -o /dev/null -H "Host: ${EPRINTS_HOSTNAME}" "http://127.0.0.1:${EPRINTS_PORT}/" || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
