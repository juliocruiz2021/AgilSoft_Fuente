# Continuidad de trabajo

- Autorizacion permanente de Julio (2026-10-27): despues de editar fuentes, guardar, compilar y ejecutar automaticamente las verificaciones locales proporcionales antes de indicar que el cambio esta listo; no volver a pedir permiso para compilar. Codex puede controlar la PC cuando la tarea lo requiera. La modificacion de DBF/DBC, datos reales, despliegues y acciones destructivas conserva las protecciones especificas.
- Al iniciar una sesion, lee `WORK_STATUS.md` y revisa `git status --short` sin asumir que Git contiene todo el estado real.
- No leas completo `CONTEXTO_CODEX.md` por defecto. Busca el formulario, proceso o decision pertinente y abre solo esa seccion.
- Este proyecto usa archivos Visual FoxPro y datos locales. Antes de editar fuentes VFP, crea un respaldo fechado de los archivos afectados.
- No alteres DBF, DBC, indices, datos de empresas ni binarios como operacion de limpieza o prueba sin autorizacion explicita.
- Si la tarea cruza API, dashboard, Flutter o catalogo, lee primero el `WORK_STATUS.md` del proyecto relacionado.
- Antes de pausar o cerrar una tarea, actualiza `WORK_STATUS.md` con objetivo, archivos, respaldos, pruebas y siguiente paso.
- Manten `WORK_STATUS.md` vigente y por debajo de 120 lineas. Usa `CONTEXTO_CODEX.md` para decisiones duraderas e historial.

