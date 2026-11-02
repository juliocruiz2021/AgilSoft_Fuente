# Estado de trabajo VFP

Fecha: 2026-11-02
Rama: `feature/modulo-facturacion`

## Objetivo actual

Corregir de forma permanente la anulacion de ventas desde SIGA, recompilar `principal.exe` y conservar intactos los cambios locales ajenos.

## Cambios integrados

- Se integraron los 18 commits pendientes de `fork/feature/modulo-facturacion` con los tres commits locales de cierre.
- Se conservaron las pantallas y rutinas remotas de facturacion de pedidos, lecturas, inventarios, envios y ventas.
- `frm_com_login` conserva el inicio de sesion recordado y ejecuta las validaciones/migraciones vigentes al entrar a la empresa.
- `frm_ven_ventas_mod` combina las mejoras remotas de grabacion con las validaciones locales de documento activo y el soporte de `idEnvio`.
- Se conservaron las mejoras de usuarios, clave y vinculos provenientes de la rama compartida.
- `varios.prg` conserva las mejoras locales de Caja y Bancos, WhatsApp e IA, junto con las incorporaciones remotas; se retiraron tres redefiniciones duplicadas de `xlTop` que impedian compilar.
- `varios2.prg` incorpora las rutinas remotas de anulacion, importacion y conciliacion, junto con las validaciones locales DBC, retencion de renta y procedimientos almacenados.

## Correccion de anulacion de ventas SIGA

- La integracion habia reemplazado el alias exacto `cyvventas` por alias alternativos dentro de `ConfirmarCabeceraAnulacionVenta`, `ConfirmarCabeceraEliminacionVenta` y `ConfirmarCabeceraAnulacionFiscalVenta`.
- Los triggers de ventas esperan el alias exacto `cyvventas`; por eso SIGA alcanzaba a desactivar detalle y kardex, pero no confirmaba la cabecera ni mostraba un error util.
- Se restauro el bloque ya validado del commit `b533d6d8`: usa el alias `cyvventas`, respeta si ya estaba abierto y preserva/restaura `plconExistenciasNegativas`.
- Las facturas DIPRO FACV `00074070`/ID `112421742` y `00074071`/ID `112421768`, afectadas por el intento desde SIGA, se completaron mediante los workers oficiales de la API y pasaron el verificador integral.
- Respaldo verificable de sus registros: `D:\Desarrollo_.net\apisigavfp\respaldos_codex\void_invoices_74070_74071_20261102-1332`.
- FACV `00074069`/ID `112421640` tambien aparece parcialmente afectada por un intento anterior; se dejo intacta por no formar parte de la autorizacion actual.

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

## Decisiones

- No se revirtieron triggers ni validaciones funcionales ya terminadas; se combinaron las variantes local y remota.
- No se modificaron datos reales ni se desplego a produccion.
- Los directorios de empresas, salidas y copias locales permanecen fuera del commit.

## Siguiente paso exacto

Abrir el `principal.exe` nuevo, refrescar Facturacion y hacer una prueba controlada creando y anulando una venta no DTE desde SIGA; confirmar que la cabecera y sus efectos queden inactivos en una sola operacion.
