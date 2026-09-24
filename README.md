# Repo Tracker

Sigue el progreso de repositorios git: por cada commit nuevo desde la última
comprobación, calcula líneas añadidas/eliminadas y las presenta en una tabla.
Incluye dos versiones independientes y un esquema opcional de Supabase para
persistir los datos en la nube.

## Archivos

| Archivo | Qué es |
|---|---|
| `repo_tracker.py` | Script de línea de comandos. Clona los repos en local y usa `git log` (no depende de la API de GitHub). |
| `repo_tracker.html` | Herramienta interactiva para usar como artifact dentro de Claude.ai. Usa la API de GitHub. |
| `supabase_schema.sql` | SQL para crear las tablas en Supabase (solo lo usa `repo_tracker.py`). |

---

## 1. Script Python (`repo_tracker.py`)

### Requisitos

- Python 3.9 o superior.
- `git` instalado y disponible en el PATH.
- Sin dependencias externas (solo librería estándar).

### Uso básico

```bash
# Empezar a seguir un repositorio
python3 repo_tracker.py add https://github.com/victorponz/javafx

# Comprobar commits nuevos desde la última vez
python3 repo_tracker.py check victorponz/javafx

# Comprobar todos los repos que sigues de una vez
python3 repo_tracker.py check --all

# Listar los repos seguidos y su estado
python3 repo_tracker.py list

# Dejar de seguir un repo
python3 repo_tracker.py remove victorponz/javafx
```

También se puede pasar la URL completa o solo `owner/repo`; ambas formas funcionan en todos los comandos.

Cada `check` solo procesa los commits posteriores al último que se vio, así que se puede ejecutar periódicamente (por ejemplo, con una tarea programada/cron) y siempre saldrá solo lo nuevo.

Opciones extra de `check`:

```bash
# Exporta además un CSV con la tabla de esa comprobación
python3 repo_tracker.py check victorponz/javafx --csv
```

### Repositorios privados (token de GitHub)

Pasa un [token personal de GitHub](https://github.com/settings/tokens) con permiso de lectura sobre el repo, vía variable de entorno o flag:

```bash
export GITHUB_TOKEN=ghp_xxxxxxxx
python3 repo_tracker.py add owner/repo-privado
python3 repo_tracker.py check owner/repo-privado

# o sin variable de entorno, solo para una ejecución:
python3 repo_tracker.py check owner/repo-privado --token ghp_xxxxxxxx
```

El token se usa solo en memoria (como cabecera HTTP para esa llamada a `git`) y nunca se escribe en ningún fichero ni en la configuración del clon local.

### Dónde se guarda el estado

Por defecto, en `~/.repo_tracker/state.json`. Los clones locales (en modo "bare", solo los datos de git, sin árbol de trabajo) viven en `~/.repo_tracker/cache/`.

---

## 2. Persistencia en Supabase (opcional)

Si quieres guardar el estado **y además el historial completo de cada commit**
(fecha, líneas añadidas, líneas eliminadas) en una base de datos en vez de en
el fichero local, puedes conectar el script a un proyecto de Supabase.

### Paso 1 — Crear las tablas

Abre el **SQL Editor** de tu proyecto en supabase.com y ejecuta una vez el contenido de `supabase_schema.sql`. Crea dos tablas:

- `repo_tracker_repos`: una fila por repositorio seguido (rama, último commit visto, totales).
- `repo_tracker_commits`: una fila por commit procesado (con fecha, añadidas, eliminadas).

### Paso 2 — Obtener las credenciales

En tu proyecto: **Project Settings → API**. Necesitas:

- **Project URL** (algo como `https://xxxxxxxx.supabase.co`)
- **service_role key** (no la `anon`/`public`). Se usa la `service_role` porque el script corre en tu propia máquina, no en un navegador, y esa key evita problemas con Row Level Security. Trátala como una contraseña: no la subas a un repositorio público.

### Paso 3 — Usarlo

```bash
export SUPABASE_URL=----
export SUPABASE_KEY=---- # service_role key

python3 repo_tracker.py add victorponz/javafx
python3 repo_tracker.py check victorponz/javafx
```

También puedes pasar las credenciales solo para una ejecución, sin variables de entorno: `--supabase-url ... --supabase-key ...` en `add`, `check`, `list`, `remove` o `history`.

Si configuras solo una de las dos (URL o key), el script avisa y usa el fichero local en su lugar, para que no se quede en un estado a medias.

### Nuevo comando: `history`

Solo funciona con Supabase configurado, ya que es el único sitio donde se guarda el historial completo (el fichero local solo guarda el último estado, no cada commit):

```bash
python3 repo_tracker.py history victorponz/javafx
python3 repo_tracker.py history victorponz/javafx --csv
```

### Importante sobre los clones git

Conectar Supabase no cambia cómo se obtienen los commits: el `clone`/`fetch` de git sigue siendo siempre local. Supabase solo sustituye **dónde se guarda** el estado y el historial.

---

## 3. Herramienta interactiva (`repo_tracker.html`)

Pensada para usarse como artifact dentro de una conversación de Claude.ai (ahí persiste los repos seguidos entre sesiones automáticamente). Si abres el archivo `.html` suelto en un navegador fuera de Claude.ai, funciona igual durante esa sesión pero lo mostrará con un aviso y no recordará nada al recargar la página.

Pasos:

1. Añade un repositorio (`owner/repo` o URL completa) y, opcionalmente, una rama.
2. Pulsa **Comprobar** en su tarjeta para traer los commits nuevos desde la última vez.
3. Cada commit se muestra con número, fecha, mensaje, líneas añadidas/eliminadas y una barra visual con la proporción.

Usa la API pública de GitHub (60 peticiones/hora sin autenticar, ya que cada commit necesita una llamada para sus estadísticas). Para repos con muchos commits, despliega "Usar token de GitHub" y pega un token personal de solo lectura: sube el límite a 5000/hora. El token no se guarda, solo vive mientras tengas la pestaña abierta.

---

## Resumen de cuándo usar cada cosa

- **Solo necesitas revisar un repo rápido desde el chat:** usa el artifact HTML.
- **Quieres automatizar comprobaciones periódicas (cron, CI, etc.) o repos privados:** usa el script Python.
- **Quieres consultar el historial completo más adelante, compartirlo entre máquinas, o construir un dashboard encima:** conecta el script a Supabase.
