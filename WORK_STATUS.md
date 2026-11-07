# Estado de trabajo VFP

Fecha: 2026-11-07
Rama: `feature/dte-hacienda-nuevas-versiones`

## Objetivo actual

Caja/Bancos versión 5: `_movimientosbancarios` y `_cuentascobrarpagar` siguen en `Programas/varios2.prg`, sin `TRY/CATCH` incompatible con VFPOLEDB y con todos los campos obligatorios de `siskardexdoc`. Respaldos `banking_v3_vfpole_20261107-103000` y `banking_v4_numerofin_20261107-104500`; `varios2.prg` compila sin `.ERR`. Regresión aislada de movimiento, aplicación CxC y trigger contable PASS. `pruebasazure` quedó `WEB=3;BANK=5` con respaldo v7; no se creó ningún cobro real. Pendiente reintento manual.
Pendiente de cierre SIGA: `frm_ven_rep_cierre` y `ven_cobros_clientes` compilan y la prueba del FRX pasa; VFP y auxiliares quedaron cerrados. Siguiente sesion: agregar el FRX al PJX y ejecutar build integral. Respaldo `filtros_ptv_caja_cobros_20261106-231402`; no se editaron datos.
## Correcciones de ventas 2026-11-05

- `STATUS`: la ruta no nativa construia el `UPDATE` de cabecera desde `c_cyvventasdeta`; ahora toma `thisform.cboStatus.Value` sin alterar reglas funcionales.
- Boton `verPDF`: ya no ejecuta `pcArchivosProcedimientos`; los procedimientos estan integrados y el cliente no necesita fuentes `.prg`.
- La vista manual (`lnCtrl=7`) genera PDF FoxyPreviewer tipo 11, aplanando plantilla, datos y QR; WhatsApp/correo conservan el PDF vectorial tipo 10.
- Respaldos: `frm_ven_ventas_mod_status_20261105-125908` y `ver_pdf_cliente_20261105-130940`.
- Formulario y PRG compilan; auditoria PASS (358 metodos, cero desbalances) y build integral aislado PASS (36,310,664 bytes, SHA-256 `44B551E84A21435B1A269B1433A35F11DAB6CC3D50E298D84EC407D254F17974`). No se modificaron datos reales.

## Revision de `frm_ven_ventas_mod` 2026-11-04

- Auditoria de metodos: 358 metodos, 47 `PROCEDURE`/47 `ENDPROC` en el registro principal y ningun bloque desbalanceado. `grabar` es el unico metodo cercano al limite (62,175 caracteres); coincide exactamente con `HEAD`, por lo que no es un crecimiento nuevo ni fue causado por la correccion de `Validg`.
- Mientras el formulario permanezca abierto en el disenador no se debe guardar esa instancia antigua: cerrarla sin guardar, reabrirla desde disco y repetir la prueba.
- Comparacion de solo lectura con `D:\respaldo 16-10-2026`: ambos formularios tienen 320 registros; el respaldo tiene `grabar` de 63,496 caracteres y el actual 62,175, por lo que el limite individual no explica el error.
- `PACK MEMO` y la regeneracion de 158 `UniqueID` duplicados no bastaron: Julio confirmo que Guardar seguia mostrando el error. El aviso de `icononew.ico` provenia de una copia abierta desde `.codex-work`; el recurso real existe en `imagenes/icononew.ico` y el fuente conserva `..\imagenes\icononew.ico`.
- Cada intento manual fallido agregaba 62,197 bytes al SCT, practicamente el tamano de `grabar` (62,173 bytes); retirar comentarios lo bajo a 60,249, pero no fue suficiente.
- Se extrajo el bloque DTE posterior al guardado a `ProcesarDTEPostGrabado`: `grabar` quedo en 54,041 bytes, helper de 6,243 bytes, 359 metodos, ninguno sobre 60 KB y cero bloques desbalanceados. Respaldos: `frm_ven_ventas_mod_grabar_limite_20261104-133251` y `frm_ven_ventas_mod_dividir_grabar_20261104-134239`.
- Reconstruccion integral: PASS; `principal.exe` 36,264,465 bytes, SHA-256 `4D0D371B8BC33787356F1E7568D95AE2B8D7A5597FF988CFE5E107CF7EE16031`, sin nuevos `.err`. Pendiente confirmar Guardar con una modificacion manual real del disenador.
- Respaldo exacto antes de reiniciar: `respaldos_codex/frm_ven_ventas_mod_pre_reinicio_20261104-122811`; hashes SCX/SCT verificados contra los originales.

## Continuacion 2026-11-03

- `Programas/varios.prg`: `_ValidarCicloyReferenciaCompras` revisa ahora por separado `cyvcompras`, `cyvventas`, `ctbpartidas`, `cybmovimientos` y `siskardexdoc`; abre exclusiva y altera solo la tabla a la que le falte `presupuesto` o `ciclo`.
- La nueva rutina `_ValidarCamposPresupuestoCiclo` conserva/restaura el area de trabajo, cierra sus alias y devuelve `.F.` con mensaje util si falta la tabla o no puede obtener apertura exclusiva.
- Respaldo previo: `respaldos_codex/validar_ciclo_presupuesto_20261103-082537`.
- Prueba sobre DBC aislado: PASS al crear ambos campos, agregar solo el faltante y repetir el proceso sin duplicarlos. No se abrieron ni modificaron DBF de empresas.
- `frm_ven_ventas`, opcion 4: para `pcnombrecomercial='DIPRO'` abre `frm_com_Fecha` con parametro `PTV` antes de `CONSULTAVFP`; las demas empresas conservan la consulta directa.
- Comparacion estructural del formulario contra `HEAD`: mismos 137 objetos; el unico cambio funcional es el bloque DIPRO anterior.
- Reconstruccion integral `BUILD EXE ... RECOMPILE`: PASS, sin `principal.err` ni `Programas/sistema.err`.
- `principal.exe`: 36,265,663 bytes; SHA-256 `6801E517BD486D4533654C1D7A43473500C3700E4B4AD2C45E5EF6AA6B5BE774`.
- VFP reescribio metadatos compilados de formularios no relacionados durante el build; se respaldaron en `respaldos_codex/metadata_build_20261103-105800` y se restauraron exactamente a `HEAD`. Permanecen solo los tres cambios fuente que ya estaban al iniciar.

## Cierre estable 2026-11-02

- `frm_ven_ventas` conserva el alias explicito `c_cyvventas` y activa `pnCargaMasivaDipro` durante el procesamiento por lote para impedir que el listado se refresque mientras se anulan o procesan documentos.
- Reconstruccion integral `BUILD EXE ... RECOMPILE` completada sin `sistema.err` ni `principal.err`.
- `principal.exe`: 36,264,199 bytes; SHA-256 `4AF32F5AC4C36E8046143F2B3DD796FF0E6A76600654076712299A0E12397617`.
- No se modificaron DBF/DBC, pedidos, facturas ni otros datos reales durante el cierre.
- Directorios de empresas, respaldos, salidas y herramientas temporales permanecen fuera del commit.

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
## Respaldos

- `respaldos_codex/stored_procedures_saltos_linea_20261102-121434`
- `respaldos_codex/integracion_final_principal_20261102-122038`

## Validaciones

- Prueba de limites de la fuente canonica: PASS.
- Instalacion directa del paquete DBC v2 sobre copia aislada: PASS.
- Migracion equivalente al login sobre copia aislada: version y firma v2, con salto correcto: PASS.
- Verificacion x86 posterior: FACV `00074070` y `00074071` tienen cabecera `status=0` y cero detalles, movimientos de inventario o kardex-documento activos.
- Respaldo previo a compilar: `.codex-work/backup_void_fix_20261102-133501`.
- Respaldo previo a la correccion del listado: `respaldos_codex/pedidos_pendientes_facturas_anuladas_20261102-134244`.
- Compilacion integral final: PASS, 550 miembros, `Programas/varios.fxp` de 1,296,254 bytes y sin `.err`.
- `principal.exe` final: 36,263,358 bytes; SHA-256 `64FF13E6E9C841447B078A986F1FF0BD7943F1E3F1942EE96D9799DC975992EC`.

## Decisiones

- No se revirtieron triggers ni validaciones funcionales ya terminadas; se combinaron las variantes local y remota.
- No se modificaron datos reales ni se desplego a produccion.
- Los directorios de empresas, salidas y copias locales permanecen fuera del commit.

## Cierre 2026-11-05: reportes contables

- Causa: el rollback `729d8d21` retiro `PrepararDetallePartidasReportes` y la sustitucion de `ctbpartidasdeta` en los 11 reportes contables activos; por eso reaparecian importes historicos anulados/eliminados.
- Se restauro la correccion del respaldo en Auxiliar, Balanza, Balance, Estados, anexos, Cambios de Patrimonio, Diario/Mayor, Flujo, Mayor y Razones Financieras; Libro Mayor PDF usa ahora la misma fuente normalizada.
- Las consultas SQL de Balance, Cambios de Patrimonio, Flujo y Razones excluyen cabeceras fuente inactivas mediante `_FiltroPartidaContableActivaSQL`; mantenimiento de partidas y formulario `OLD` quedan intactos para auditoria.
- Respaldos: `respaldos_codex/restaurar_reportes_anulados_20261105-013019` y `respaldos_codex/reportes_contables_anulados_20261105-013213`; 11 reportes + Caja/Bancos compilan, contrato nativo PASS, filtros SQL PASS y prueba aislada CYB/VTA/COM/INV/CXP PASS. No se abrieron ni modificaron DBF/DBC reales.

## Regeneracion PDF/JSON de ventas anuladas 2026-11-05

- Causas corregidas en `frm_ven_ventas.Procesar(51)`: al faltar el PDF local de un anulado se llamaba el reporte normal; `RELEASE lajsonnulo` dejaba la variable inexistente cuando `sisDTE.status=2` no devolvia filas; y tras intentar regenerar un JSON se ejecutaba `COPY FILE` aunque el archivo siguiera ausente.
- Se agrego `t13.telefono` a los cursores de impresion; los anulados priorizan `sisDTE.status=2.pdf_path`; la invalidacion se lee mediante cursor manteniendo `lajsonnulo=''` cuando no existe; y ambas ramas validan `FILE(lcfileJSONOrigen)` tras regenerar, muestran aviso y continuan si Hacienda no produjo el archivo.
- Respaldos: `respaldos_codex/anulados_regeneracion_pdf_20261105-103000` y `respaldos_codex/ventas_json_nulo_20261105-115852`. Regresion aislada con cero filas y con invalidacion existente PASS; formulario aislado y reconstruccion integral PASS, sin `.err`; `principal.exe` 36,310,420 bytes, SHA-256 `C2BD688723FCDDC40C5FBC07FE188D89F7D89197D1727FB691AA2CF68EDF6ED4`. Metadatos ajenos reescritos por el build se restauraron; no se modificaron DBF/DBC ni datos reales.
- CYB Importar: se retiraron 7 filtros invalidos a `siskardexdoc.anulado`, conservando `status=1` y `eliminado=0`; verificacion fresca del procedimiento `Importar`: 4 consultas, 0 referencias a `anulado`, PASS. Administrador de `sistema.pjx` cerrado y build integral PASS; `principal.exe` 36,311,134 bytes, SHA-256 `302BEB5FC10EBF1AEE72AC45F1249E2E59C04A5C13B85EB2446BFA5C5400145F`. Metadatos ajenos reescritos se respaldaron en `respaldos_codex/metadata_build_cyb_importar_20261106-054931` y restauraron a `HEAD`; respaldos fuente previos: `respaldos_codex/cyb_importar_sin_anulado_kardex_20261105-104500` y `respaldos_codex/principal_antes_cyb_importar_20261105-191917`. No se abrieron ni modificaron DBF/DBC o datos reales. Migracion API DBC v3 reducida: `Programas/varios2.prg` devuelve web 3/bancos 1; el paquete contiene solo ambos marcadores, `_cuentascobrarpagar` y `_movimientosbancarios`, sin ventas, kardex general, contabilidad ni cambios de triggers. Prueba aislada PASS (`OK|banking-stored-procedures-v3|3|banking-1`); no se creo ningun cobro real.
