# Estado de trabajo VFP

Fecha: 2026-11-02
Rama: `feature/modulo-facturacion`

## Objetivo actual

Corregir de forma permanente la anulacion de ventas y la liberacion visual de sus pedidos desde SIGA, recompilar `principal.exe` y conservar intactos los cambios locales ajenos.

## Pausa para reinicio 2026-11-02

- Diagnostico de compilacion 16:44: `frm_ven_ventas_mod.scx` compilo aislado `COMPILE_OK` y regenero su SCT exactamente igual al blob versionado `1cd2c49d`; respaldo previo en `respaldos_codex/diagnostico_sct_20261102-164500`. La reconstruccion integral no inicio porque `Programas/sistema.pjx` respondio `ERROR 3: El archivo ya esta en uso` en la linea 19 del finalizador; `principal.exe` no se reemplazo. Tras reiniciar, confirmar que no exista otro VFP y repetir la reconstruccion integral.
- Ultima correccion guardada y sincronizada: commit `a3ece8f5`. En la rama nativa de anulacion, la cabecera recibe `status=0` directamente; ya no vuelve a leer `status=1` desde `c_cyvventas` con buffering. Formulario `COMPILE_OK` y contrato `VERIFY_OK`.
- Estado real dejado intacto: FACV `00074060` y `00074061` tienen cabecera activa pero detalle inactivo; requieren reparacion controlada. FACV `00074062` sigue activa y no entro al intento. No volver a anular 74060/74061 como documentos normales.
- Siguiente paso exacto al reiniciar: ejecutar nuevamente el proyecto SIGA, probar una sola factura activa distinta de los casos parciales y verificar cabecera/detalle/kardex. Solo despues revisar la anulacion por seleccion multiple y el refresco/recorrido del listado.

## Cambios integrados

- Se integraron los 18 commits pendientes de `fork/feature/modulo-facturacion` con los tres commits locales de cierre.
- Se conservaron las pantallas y rutinas remotas de facturacion de pedidos, lecturas, inventarios, envios y ventas.
- `frm_com_login` conserva el inicio de sesion recordado y ejecuta las validaciones/migraciones vigentes al entrar a la empresa.
- `frm_ven_ventas_mod` combina las mejoras remotas de grabacion con las validaciones locales de documento activo y el soporte de `idEnvio`.
- Se conservaron las mejoras de usuarios, clave y vinculos provenientes de la rama compartida.
- `varios.prg` conserva las mejoras locales de Caja y Bancos, WhatsApp e IA, junto con las incorporaciones remotas; se retiraron tres redefiniciones duplicadas de `xlTop` que impedian compilar.
- `varios2.prg` incorpora las rutinas remotas de anulacion, importacion y conciliacion, junto con las validaciones locales DBC, retencion de renta y procedimientos almacenados.

## Correccion de anulacion de ventas SIGA

- Regresion localizada el 2026-11-02: `cboStatus` no tiene `ControlSource`; al anular, detalle y kardex recibian `status=0`, pero `c_cyvventas.status` podia conservar `1` y el `UPDATE` posterior reactivaba silenciosamente la cabecera.
- `frm_ven_ventas_mod.grabar` sincroniza ahora `c_cyvventas.status=0` antes del checkpoint de cabecera. La FACV `00074072` evidencio el caso (cabecera activa, detalle y kardex inactivos); se dejo intacta y no se repararon datos reales.
- Segunda causa confirmada: como `c_cyvventas` usa buffering, el `UPDATE ... FROM c_cyvventas` no veia el `REPLACE` pendiente y volvia a copiar `status=1`. La rama nativa que solo se ejecuta al anular fija ahora `status=0` directamente. FACV `00074060` y `00074061` evidenciaron el residuo; se dejaron intactas.
- Respaldo adicional: `respaldos_codex/anulacion_status_buffer_20261102-151000`. Formulario `COMPILE_OK` (47/47) y contrato `VERIFY_OK`.
- Respaldo de fuente: `respaldos_codex/anulacion_status_cursor_20261102-152000`. Formulario aislado `COMPILE_OK` (47/47 procedimientos), contrato de anulacion `VERIFY_OK` y reconstruccion integral `principal.exe` PASS (36,263,651 bytes; SHA-256 `1CAEB2B63DD000D6259BB734BC2FE3CAA5D029F7646A22CA2C8A768FBE3F9671`).
- La integracion habia reemplazado el alias exacto `cyvventas` por alias alternativos dentro de `ConfirmarCabeceraAnulacionVenta`, `ConfirmarCabeceraEliminacionVenta` y `ConfirmarCabeceraAnulacionFiscalVenta`.
- Los triggers de ventas esperan el alias exacto `cyvventas`; por eso SIGA alcanzaba a desactivar detalle y kardex, pero no confirmaba la cabecera ni mostraba un error util.
- Se restauro el bloque ya validado del commit `b533d6d8`: usa el alias `cyvventas`, respeta si ya estaba abierto y preserva/restaura `plconExistenciasNegativas`.
- Las facturas DIPRO FACV `00074070`/ID `112421742` y `00074071`/ID `112421768`, afectadas por el intento desde SIGA, se completaron mediante los workers oficiales de la API y pasaron el verificador integral.
- Respaldo verificable de sus registros: `D:\Desarrollo_.net\apisigavfp\respaldos_codex\void_invoices_74070_74071_20261102-1332`.
- FACV `00074069`/ID `112421640` tambien aparece parcialmente afectada por un intento anterior; se dejo intacta por no formar parte de la autorizacion actual.

## Pedidos liberados tras anular factura

- Los pedidos DIPRO `00322688`/ID `112421706` y `00322689`/ID `112421726` estaban activos y todas sus lineas tenian `siskardex.cantidadpedido=0`; no requerian reparacion de datos.
- `CrearCursorPendientesDocto` seguia restando facturas anuladas porque solo comprobaba `eliminado=0`. Ahora consume cantidades unicamente cuando la linea de factura tiene `status=1` y su cabecera tiene `status=1`, `anulado=0` y `eliminado=0`.
- Regresion sobre el respaldo aislado de las dos facturas: la consulta anterior retenia 26 vinculos/56.5 unidades; la corregida retiene cero. PASS.
- No se modificaron DBF reales durante esta correccion; solo se realizaron lecturas y pruebas sobre el respaldo.

## Correccion DBC v2

- La fuente canonica de procedimientos almacenados ahora inserta CRLF entre `_SigaStoredSourceParte01`, `02` y `03`.
- Esto evita que `IF _tallY=0` quede pegado al final del `REPLACE ... IN tacataEdi` dentro de `_insertkardex`.
- Paquete vigente: version `2`, firma `SIGA-DBC-SP-V2-20261102`.
- La correccion se instala desde el login mediante `_ValidarKardexDocDBC(.T., .T.)`; no depende de una modificacion manual en `principal`.
- Farmacia fue inspeccionada en solo lectura: su linea ya estaba separada manualmente. No se modificaron datos ni el DBC real durante las pruebas.

## Respaldos

- `respaldos_codex/stored_procedures_saltos_linea_20261102-121434`
- `respaldos_codex/integracion_final_principal_20261102-122038`

## Validaciones

- Prueba de limites de la fuente canonica: PASS.
- Instalacion directa del paquete DBC v2 sobre copia aislada: PASS.
- Migracion equivalente al login sobre copia aislada: version y firma v2, con salto correcto: PASS.
- Compilacion aislada de `varios.prg`, `varios2.prg`, login, usuarios, vinculos y ventas despues de la integracion: PASS.
- Compilacion integral `BUILD EXE ... RECOMPILE`: PASS, 550 miembros y sin archivos `.err`.
- `principal.exe`: 36,262,536 bytes; SHA-256 `5996FD1AC9DD0DC8949B631BD1A1D352656422ED4F490F936049E9A283E542DE`.
- Compilacion nueva de `Programas/varios2.prg`: PASS, FXP de 637,206 bytes y sin `.err`.
- Construccion integral nueva de `principal.exe`: PASS, 36,263,299 bytes, SHA-256 `3FA681B120DEC9C6A131CCC96BE9FDEEA6E81BB0D65316243E77DD36A375BEDE` y sin `.err`.
- Verificacion x86 posterior: FACV `00074070` y `00074071` tienen cabecera `status=0` y cero detalles, movimientos de inventario o kardex-documento activos.
- Respaldo previo a compilar: `.codex-work/backup_void_fix_20261102-133501`.
- Respaldo previo a la correccion del listado: `respaldos_codex/pedidos_pendientes_facturas_anuladas_20261102-134244`.
- Compilacion integral final: PASS, 550 miembros, `Programas/varios.fxp` de 1,296,254 bytes y sin `.err`.
- `principal.exe` final: 36,263,358 bytes; SHA-256 `64FF13E6E9C841447B078A986F1FF0BD7943F1E3F1942EE96D9799DC975992EC`.

## Decisiones

- No se revirtieron triggers ni validaciones funcionales ya terminadas; se combinaron las variantes local y remota.
- No se modificaron datos reales ni se desplego a produccion.
- Los directorios de empresas, salidas y copias locales permanecen fuera del commit.

## Siguiente paso exacto

Abrir el `principal.exe` nuevo y refrescar Pedidos: `00322688` y `00322689` deben volver a aparecer como pendientes. Luego hacer una prueba controlada creando y anulando una venta no DTE desde SIGA, sin que Codex anule documentos reales.
