# Estado operativo - ERP SIGA Visual FoxPro

Actualizado: 2026-09-24 (America/El_Salvador)

## Punto actual

- Rama Git visible: `main`.
- HEAD visible: `88fd78f1`; Git no es el mecanismo principal de recuperacion de este proyecto.
- Tarea activa: corregir la recontabilizacion de ventas que podia duplicar renglones en `ctbpartidasdeta`.
- `Programas/varios.prg`, funcion `_generaPartidaventas`, ahora localiza la cabecera por campos si falla `LLAVE2`, elimina renglones obsoletos antes de actualizar/insertar y limpia detalles huerfanos antes de crear una partida nueva.
- Se agrego `_SiguienteIdPartidaDetaDisponible`: cada ID nuevo se valida contra todos los registros de `ctbpartidasdeta`, incluso eliminados, para evitar reutilizar un ID historico o perteneciente a otra partida.
- Rendimiento por lote: la comprobacion de cada `idpartidad` usa el indice `idpartidad`; no recorre la tabla de detalle. El respaldo de busqueda de cabecera usa el indice `idpartida` y solo revisa el pequeno grupo con la misma clave.
- Respaldo previo: `respaldos_codex/recontabilizacion_ids_20260924-1515/varios.prg` (SHA-256 original `04605EA2E08D2A8FE635D7B66E7B1C20E07B695B5271C684814CEBBB228D962F`).
- El historial conserva como pendientes posteriores los procesos rapidos por lotes y micromedidores.

## Estado local

- Existen carpetas de empresas, archivos de sistema y temporales sin seguimiento.
- No limpiar ni modificar datos, DBF/DBC, indices o binarios para obtener un arbol Git limpio.
- Antes de editar una fuente VFP, crear respaldo fechado del archivo afectado.

## Relacion funcional

- Este repositorio es la referencia del comportamiento original del ERP SIGA.
- La API .NET traduce datos y procesos VFP para dashboard, Flutter y catalogo.
- Si se replica un proceso, mapear primero formulario, tablas, validaciones y efectos antes de implementar cambios externos.

## Validacion

- El fuente corregido, incluida la ruta indexada para procesos por lote, compilo con Visual FoxPro 9 en copia aislada: `respaldos_codex/recontabilizacion_ids_20260924-1515/validacion/varios_recontabilizacion_ids_test.fxp`.
- No se modificaron datos, DBF/DBC, indices, el FXP operativo ni el EXE. El ERP sigue abierto durante esta validacion.
- Las pruebas deben usar una empresa de prueba identificada, respaldos y comparacion contra el flujo original.
- Clave fuerte 2026-09-19: `ValidarClaveFuerte` y `OfrecerCambioClaveAlIngresar` se trasladaron a `Programas/varios.prg`, que ya forma parte del EXE. Login, cambio de clave y alta de usuario dejaron de ejecutar `SET PROCEDURE` para `clave_segura.prg` y `clave_login_postinicio.prg`. Los PRG anteriores se conservan temporalmente para compatibilidad con el EXE actualmente abierto. Respaldo: `respaldos_codex/clave_funciones_varios_20260919-142345/`.
- `Comun/frm_com_usuarios_clave.scx/SCT` valida la clave nueva antes de guardarla. `Comun/frm_com_usuarios_mod.scx/SCT` abre el dialogo enmascarado `Programas/frm_clave_nueva.prg` al crear usuario y guarda el hash de la clave elegida, sin derivarla del nombre de usuario.
- Respaldo previo: `respaldos_codex/clave_fuerte_20260916_094405/` contiene los 5 archivos fuente originales y una copia intermedia de ambos formularios. No se tocaron datos de empresas.
- Validacion: VFP 9 compilo ambos formularios y los tres PRG; prueba COM de clase y campos enmascarados correcta. Casos VFP con `SET COLLATE TO "GENERAL"` y `SET EXACT OFF`: clave fuerte acepta, usuario=clave, longitud menor de 8, sin mayuscula/minuscula/numero/simbolo y espacios rechazan. Falta prueba manual de alta/cambio en el ERP abierto y confirmar instalacion del codigo en el entorno de uso.
- PDF web de cotizacion `impmarrq` 2026-09-16: `AgilSoft_001_ImpMarrq/formatosweb/pedido-cot.json` usa ahora 50 caracteres por renglon de producto (antes 30); respaldo `pedido-cot.json.bak-20260916-1140`. La API genero y se renderizo COT-00004542: las descripciones largas caben completas en una linea sin tocar precios. No se alteraron DBF/DBC ni fuentes VFP; siguiente paso: abrir una cotizacion desde Pedidos y descargar el PDF para confirmacion visual en el navegador.
- Login con clave debil: `Comun/frm_com_login.scx/SCT` termina de cargar usuario, empresa y permisos, establece `plSiga=.t.` y llama `OfrecerCambioClaveAlIngresar` desde `varios.prg`. Una clave debil ofrece el cambio sin impedir el acceso. Los tres formularios compilaron; `varios.prg` compilo a FXP temporal porque el ERP abierto bloquea `Programas/varios.fxp`. Prueba VFP: `LvhpcT1203$` valida y usuario=clave se rechaza. Falta generar el EXE cuando se cierre la instancia actual y hacer prueba manual de login/alta/cambio.
- Cambio de clave 2026-09-16 16:31: `Comun/frm_com_usuarios_clave.scx/SCT` aplica `ALLTRIM()` a clave nueva y repetida antes de compararlas y validarlas; el guardado ya aplicaba `ALLTRIM()` al hash. Respaldo `respaldos_codex/clave_trim_20260916-163045/`. Formulario compilado con VFP 9 y verificado que contiene ambos cambios. Prueba COM de clave fuerte con espacios extremos devolvio True. Falta prueba manual en ERP reiniciado.
- Investigacion de espacio final 2026-09-16: en `frm_com_usuarios_clave` y clase base `txt` no hay asignacion que agregue espacios; prueba COM de TextBox y `txt` con MaxLength 30/PasswordChar devolvio longitud exacta sin relleno. `frm_clave_nueva.prg` del alta de usuario si leia ambos valores sin `ALLTRIM()`: ahora normaliza los dos campos antes de validar, comparar y entregar la clave para hash. Respaldo `respaldos_codex/clave_inicial_trim_20260916-164101/`. PRG compilado y prueba COM del formulario con espacios extremos confirmo clave aceptada de longitud normalizada. No se alteraron datos; falta prueba manual en ERP.

## Siguiente inicio

- Recontabilizacion 2026-09-24: cerrar el ERP, compilar el FXP/EXE operativo e iniciar una prueba controlada recontabilizando dos veces la misma venta. Confirmar que conserva una sola generacion de renglones y que todos los `idpartidad` son unicos globalmente. La limpieza de partidas historicas duplicadas queda separada y requiere autorizacion explicita.

- SIGA Documentos 2026-09-16: Julio pidió detener los cambios en formularios hasta acordar la integración. Se restauraron ventas, bancos y partidas desde `respaldos_codex/siga_documentos_20260916-220553/`; compras nunca se modificó. Los ocho SCX/SCT originales se verificaron por SHA-256 contra el respaldo. El PRG independiente `Programas/siga_documentos_evento.prg` quedó compilado pero sin llamadas desde formularios, por lo que está inactivo. El publicador de SIGA Bridge también está deshabilitado por defecto. No conectar ni desplegar esta integración hasta acordar el flujo con Julio.

1. Con el ERP cerrado, generar el EXE para incorporar las funciones nuevas de `Programas/varios.prg` y actualizar `Programas/varios.fxp`, incluida la correccion de recontabilizacion.
2. Probar login con clave fuerte y debil; en la debil probar No, Si, Cancelar y Guardar. Probar tambien alta y cambio de usuario. La distribucion solo mantiene como dependencia adicional `Programas/frm_clave_nueva.prg/.fxp` para el formulario de alta.

## Proyectos relacionados

- API: `D:\Desarrollo_.net\apisigavfp\context\WORK_STATUS.md`.
- Dashboard: `D:\Desarrollo_.net\dashboarsiga\context\WORK_STATUS.md`.
- Flutter: `D:\Desarrollo_.net\appsigavfp\context\WORK_STATUS.md`.
- Catalogo: `D:\Desarrollo_.net\catalogosiga\context\WORK_STATUS.md`.
