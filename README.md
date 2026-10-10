# Repositorio Digital de Producción Científica e Investigación — Hospital General de Itapúa

Repositorio institucional basado en **[EPrints 3.5](https://www.eprints.org/software/)** (software libre de la Universidad de Southampton, licencia LGPL v3), desplegado con **Docker**.

Permite publicar, organizar y buscar la producción científica del hospital: artículos de **investigación**, **tesis** y **guías clínicas**, con búsqueda en el texto completo de los PDF, control de acceso por roles y un flujo de revisión editorial.

> El código de EPrints proviene de [github.com/eprints/eprints3.5](https://github.com/eprints/eprints3.5). Su documentación original está en [`README.pod`](README.pod). Este repositorio añade todo lo necesario para desplegarlo con Docker y adaptarlo al ámbito médico.

---

## Inicio rápido

**Requisitos:** [Git](https://git-scm.com/) y [Docker Desktop](https://www.docker.com/products/docker-desktop/) (en Windows, con WSL2).

```bash
# 1. Clonar (con los submódulos de EPrints)
git config --global core.longpaths true          # solo en Windows
git clone --recurse-submodules https://github.com/diegogabilan89-cmd/repositorio.git
cd repositorio

# 2. Crear el archivo de configuración y cambiar las contraseñas
cp .env.example .env

# 3. Construir y levantar (la primera vez tarda ~10 min en construir)
docker compose up -d --build
docker compose logs -f eprints                   # esperar "Repositorio listo"

# 4. Crear los usuarios de prueba y cargar los 3 PDF de ejemplo
docker compose exec eprints eprints-seed
```

| Qué | Dirección |
|---|---|
| Repositorio | http://repositorio.localhost:8080 |
| Correos capturados (Mailpit) | http://localhost:8025 |

Usuarios: `admin` (administrador), `editor` (revisor) e `investigador` (depositante). Las contraseñas son las que pusiste en `.env`.

---

## Qué incluye

| Componente | Descripción |
|---|---|
| [`Dockerfile`](Dockerfile) | Imagen Debian 13 + Apache 2.4 + mod_perl + EPrints 3.5 con todas sus dependencias |
| [`docker-compose.yml`](docker-compose.yml) | Servicios `eprints`, `db` (MariaDB 11.8) y `mailpit` |
| [`.env.example`](.env.example) | Plantilla de configuración (host, puerto, contraseñas) |
| [`docker/`](docker) | Script de arranque, configuración de Apache y supervisord, categorías médicas, script de datos de prueba y PDF de ejemplo |
| [`docs/DESPLIEGUE_DOCKER.md`](docs/DESPLIEGUE_DOCKER.md) | **Guía completa**: arquitectura, instalación, operación, copias de seguridad, VPS y solución de problemas |
| [`docs/GUIA_ENTREGA.md`](docs/GUIA_ENTREGA.md) | Lista de comprobación y capturas para el informe `Despliegue_GrupoX.pdf` |

### Estructura inicial orientada al ámbito médico

- **Áreas temáticas:** Investigación (clínica, epidemiología, ciencias biomédicas, enfermería, casos clínicos) · Tesis (grado, especialización/residencia, maestría, doctorado) · Guías Clínicas (GPC, protocolos, manuales de procedimientos, cuidados de enfermería).
- **Estructura del hospital:** Medicina Interna, Cirugía, Pediatría, Ginecología y Obstetricia, Urgencias, UTI, Laboratorio, Imágenes, Docencia e Investigación, Enfermería.
- **Roles:** administrador, editor/revisor, depositante.

---

## Cambios respecto al EPrints original

- `.gitmodules`: los submódulos apuntan a `https://github.com/eprints/...`. Antes usaban rutas relativas, que no funcionan en un fork.
- `.gitattributes`: fuerza finales de línea LF, para que los scripts funcionen en los contenedores Linux aunque se clone desde Windows.
- `.gitignore`: se ignora `.env` (contraseñas) y se permite versionar `docker/archive/overlay/cfg/`. La regla original `cfg` lo excluía.
- `Dockerfile.txt` (vacío) pasa a ser un `Dockerfile` completo. Si el código se clona en Windows, restaura los enlaces simbólicos de `lib/citations/` que Git convierte en texto.

## Licencia

EPrints es © University of Southampton, distribuido bajo la [GNU LGPL v3](LICENSE). Los archivos de despliegue añadidos se distribuyen bajo la misma licencia.
