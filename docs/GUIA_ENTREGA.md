# Guía para el informe de entrega — `Despliegue_GrupoX.pdf`

Lista de comprobación para preparar el informe de la **Guía práctica: Despliegue y demostración del repositorio**. Reemplaza la `X` por el número de grupo.

---

## 1. Cómo se cumple cada punto de la consigna

| Consigna | Cómo se cumple | Evidencia sugerida |
|---|---|---|
| **Despliegue libre**: poner en funcionamiento la herramienta (localhost o VPS) con el método preferido | EPrints 3.5 en **contenedores Docker** (Docker Compose): servidor web, base de datos MariaDB y servidor de correo de pruebas | Capturas 1–4 |
| **Estructura inicial**: categorías del ámbito médico (Investigación, Tesis, Guías Clínicas) | Árbol de *Subjects* con las 3 categorías y sus subcategorías, más la estructura de servicios del hospital (*Divisions*) | Capturas 5–6 |
| **Validación**: al menos 3 PDF de prueba | Tres documentos ficticios publicados, uno por categoría, con búsqueda en el texto completo | Capturas 7–9 |
| **Validación**: cuentas de usuario con distintos roles | `admin` (administrador), `editor` (revisor) e `investigador` (depositante) | Capturas 10–12 |
| **Informe PDF** con resumen técnico, comandos y capturas (o enlace) | Este documento + [`DESPLIEGUE_DOCKER.md`](DESPLIEGUE_DOCKER.md) | — |

---

## 2. Resumen técnico (para copiar y adaptar al informe)

**Herramienta:** EPrints 3.5 (Universidad de Southampton, software libre, licencia LGPL v3).

**Método de despliegue:** contenedores Docker orquestados con Docker Compose, en entorno local (`localhost`). Opcionalmente, en un VPS.

**Arquitectura:** tres contenedores:

1. **eprints**: Debian 13, Apache 2.4, mod_perl 2 y EPrints 3.5. Incluye el indexador, que extrae el texto de los PDF para la búsqueda de texto completo.
2. **db**: MariaDB 11.8, que guarda metadatos, usuarios y categorías.
3. **mailpit**: captura los correos del sistema para pruebas.

Los datos persisten en dos volúmenes Docker: la base de datos y los documentos subidos.

**Automatización:** al primer arranque, el contenedor crea el repositorio con el instalador oficial (`epadmin create`) de forma no interactiva. También crea la base de datos y el usuario administrador, carga las categorías médicas y genera las páginas. Un script adicional (`eprints-seed`) crea los usuarios con roles y publica los 3 PDF de prueba.

### Comandos clave utilizados

```bash
# Requisitos (Windows): WSL2 + Docker Desktop + Git
wsl --install
git config --global core.longpaths true

# 1. Obtener el código
git clone --recurse-submodules https://github.com/diegogabilan89-cmd/repositorio.git
cd repositorio

# 2. Configuración (host, puerto, contraseñas)
cp .env.example .env

# 3. Construir la imagen y levantar los servicios
docker compose up -d --build

# 4. Verificar
docker compose ps
docker compose logs -f eprints

# 5. Crear usuarios con roles y cargar los 3 PDF de prueba
docker compose exec eprints eprints-seed

# 6. Comprobar el estado interno (Apache + indexador)
docker compose exec eprints supervisorctl status
```

**Acceso:** http://repositorio.localhost:8080 (o la URL del VPS).

---

## 3. Capturas de pantalla recomendadas

Usa `Win + Shift + S` (Windows) o `Cmd + Shift + 4` (macOS). Si `repositorio.localhost` no abre, consulta *Solución de problemas* en [`DESPLIEGUE_DOCKER.md`](DESPLIEGUE_DOCKER.md#11-solución-de-problemas).

| # | Qué capturar | Dónde |
|---|---|---|
| 1 | Docker Desktop con los 3 contenedores en verde, **o** la salida de `docker compose ps` con `eprints (healthy)` | Docker Desktop / terminal |
| 2 | Log de arranque con el mensaje `Repositorio listo en: http://repositorio.localhost:8080/` | `docker compose logs eprints` |
| 3 | Página de inicio del repositorio con el nombre y las *Latest Additions* | http://repositorio.localhost:8080 |
| 4 | Pantalla **Status**: versión de EPrints, base de datos OK, **Indexer: Running**, usuarios por rol y documentos | Login como `admin` → **Admin** → pestaña *System Tools* → **Status** |
| 5 | Árbol de categorías médicas (navegación pública) | **Browse** → *Subjects* (`/view/subjects/`) |
| 6 | Editor de categorías del administrador | **Admin** → *Config. Tools* → **Edit subject** |
| 7 | Ficha de un documento con la vista previa del PDF | p. ej. `/id/eprint/3/` |
| 8 | Listado de los 3 documentos dentro de una categoría | **Browse** → *Subjects* → *Guías Clínicas*, o **Browse** → *Year* → 2026 |
| 9 | Búsqueda de texto completo: buscar `lactato`. Devuelve la guía de sepsis, porque la palabra solo está dentro del PDF | Buscador de la portada |
| 10 | Lista de usuarios con sus roles | **Admin** → *Editorial Tools* → **Search users** → *Search* (sin filtros) |
| 11 | Sesión de `investigador` (depositante): menú **sin** *Review* ni *Admin* | Login como `investigador` |
| 12 | Sesión de `editor`: menú con **Review** | Login como `editor` → **Review** |

**Evidencia extra (flujo editorial completo, muy recomendable):**

1. Como `investigador`: **Manage deposits** → **New Item** → tipo *Article* → subir un PDF → completar los datos → elegir categoría → **Deposit Item Now**.
2. Como `editor`: **Review** → aparece el depósito → abrirlo → **Move to Repository** (publicar).
3. Capturar los tres momentos: el formulario, la cola de revisión y el documento ya publicado.

**Correo (opcional):** **Admin** → *System Tools* → **Send Test Email**, y luego capturar el correo recibido en http://localhost:8025 (Mailpit).

---

## 4. Estructura sugerida del informe

1. **Portada:** asignatura, título *Despliegue y Demostración del Repositorio*, grupo, integrantes y fecha.
2. **Herramienta elegida:** EPrints 3.5 y por qué se eligió (referencia al análisis comparativo de la fase anterior).
3. **Entorno y método de despliegue:** Docker / Docker Compose, el diagrama de arquitectura de [`DESPLIEGUE_DOCKER.md`](DESPLIEGUE_DOCKER.md#1-arquitectura) y los requisitos.
4. **Pasos de instalación:** los comandos clave de la sección 2, con una línea de explicación cada uno.
5. **Estructura inicial:** el árbol de categorías médicas (capturas 5–6).
6. **Validación:** documentos de prueba y usuarios por rol (capturas 7–12 y el flujo editorial).
7. **Acceso:** URL de la plataforma (si está en un VPS) o indicación de que se ejecuta en local.
8. **Problemas encontrados y soluciones:** por ejemplo, submódulos con rutas relativas, finales de línea de Windows o el nombre de host `localhost` no admitido por EPrints.
9. **Conclusiones.**

Exportar: Word → *Archivo › Guardar como › PDF*, o Google Docs → *Archivo › Descargar › PDF*. Nombre del archivo: **`Despliegue_GrupoX.pdf`**.
