# Handoff antes de reiniciar la PC - 28 de octubre de 2026

## Objetivo al reanudar

Continuar exclusivamente con DIPRO hasta estabilizar SIGA y luego repetir las pruebas equivalentes en Web. No desplegar a produccion ni migrar otros tenants hasta completar las pruebas cruzadas.

## Estado general

- Los cierres observados son fallos nativos de `vfp9.exe` en `MSVCR71.dll`, normalmente como una pareja `c0000027` seguida de `c000041d`, desplazamiento `00002526`.
- La API y Hacienda no participaron en los cierres ocurridos antes de abrir la ventana de motivo o al abrir catalogos.
- No se hicieron reparaciones ni cambios manuales sobre datos reales durante el diagnostico.
- La API, los triggers y SIGA no deben revertirse en bloque. SIGA ejecuta triggers con `llEstamosCorriendoFVP=.T.`; la API prepara el runtime con la variable en `.F.` y aplica sus efectos explicitamente.
- El migrador de API ya no agrega procedimientos externos al DBC: valida y ajusta las expresiones de 24 triggers. La migracion productiva sigue pendiente.

## Pruebas y hallazgos cronologicos

### Anulacion SIGA

- `00067071`, anulada desde SIGA a las 08:43:04, fue la referencia que termino correctamente.
- `00072982` fue anulada desde Web para comparar ambos procesos.
- `00072984` habia sido anulada desde SIGA y se reviso como referencia anterior.
- Los intentos posteriores sobre `00067075` cerraban VFP antes de llamar a la API/Hacienda.
- Causa reproducida en copia: `frm_ven_ventas_mod.anular` hacia `REPLACE motivoanula` usando `c_cyvventas`; el trigger `_ventascreditocontado` espera el alias exacto `cyvventas` y producia Error 13.
- Correccion: `c_cyvventas` pasa a buffer 5 antes del primer cambio. La prueba de copia `motivoanula=2, BUFFER=5` no disparo el trigger ni produjo error.
- `Programas/varios2.prg` asegura temporalmente el alias `cyvventas` en `ConfirmarCabeceraAnulacionVenta`, `ConfirmarCabeceraEliminacionVenta` y `ConfirmarCabeceraAnulacionFiscalVenta`.
- Durante la reversion se permite temporalmente existencia negativa y se restaura el valor original en `FINALLY`. Las 13 lineas de inventario del caso de copia pasaron.
- Compilados sin `.ERR`: `varios2.fxp` y `ventas/frm_ven_ventas_mod.scx/SCT`.

### Video 12:33 - catalogo de productos

- No era una anulacion. El error visible fue `No se encuentra el alias 'C_INVPRODUCTOS'` en `frm_inv_productos.grd1.AfterRowColChange`.
- Correccion inicial: retorno temprano cuando `grd1.cursor` esta vacio o no esta abierto; `c_invprodequi` tambien queda protegido.
- Respaldo: `respaldos_codex/inv_productos_alias_carga_20261028-123557/`.

### Video 12:53 - impresion/PDF

- No era una anulacion. `ImprimirFactura`, linea 3910, intento usar `c_imp` despues de generar PDF/WhatsApp con FoxyPreviewer.
- El mensaje visible fue Error 13, alias `C_IMP`; al elegir Omitir el manejador quedo en estado inconsistente y VFP termino en `MSVCR71.dll` a las 13:01:05.
- Correccion en `Programas/varios.prg`: actualizar `impreso` sin depender de `c_imp`; proteger navegacion y cierre de `c_imp/c_impdeta`.
- `varios.fxp` compilo `COMPILE_OK`.
- Respaldo: `respaldos_codex/impresion_alias_c_imp_20261028-131000/`.

### Video 14:00 - pedido PED 000125

- Se estaba creando el pedido `PED 000125`. Al entrar en la columna Codigo, VFP cerro antes de mostrar el catalogo.
- Windows registro la misma pareja nativa a las 14:00:11 y 14:00:15. El pedido no llego a guardarse.
- Hallazgo adicional: `frm_inv_productos.grd1.Init` instalaba expresiones dinamicas que referenciaban `c_invProductos` antes de crear el cursor.
- `DynamicBackColor` estaba incompleta: faltaba un parentesis de cierre.
- Correccion: durante `Init` se usan colores/estilos constantes seguros. `configuragrid` instala las expresiones dinamicas, sin alias fijo, despues de asignar `RecordSource`.
- Verificacion por extraccion de metodos: expresiones presentes en `configuragrid`, constantes presentes en `Init`.
- `frm_inv_productos.scx/SCT` compilo `COMPILE_OK`, sin `.ERR`.
- Respaldo: `respaldos_codex/inv_productos_dynamic_init_20261028-141000/`.

## Pedidos duplicados

- La identidad documental es `idtipodocto + idserie + numero` dentro del tipo/origen correspondiente; `iddocto` identifica la fila actual.
- Al editar un pedido, la validacion excluye el mismo `iddocto` y no cambia numero/serie.
- Otro encabezado activo con la misma identidad bloquea; registros `status=0` no deben bloquear una modificacion activa.
- Pedidos anulados pueden volver a aparecer por una importacion posterior, pero no se reutiliza ni transforma el encabezado viejo.
- SIGA original actualiza el encabezado actual; no crea una version nueva cada vez que se modifica.

## Estado API y triggers

- La API Windows debe seguir `win-x86`, `self-contained` y arrancarse localmente solo con `D:\Desarrollo_.net\apisigavfp\Start-LocalApi.ps1`.
- Web necesita conservar la logica explicita de anulacion y sus comprobaciones de integridad: encabezado, detalle, inventario, kardex documental, CxC y contabilidad.
- Los triggers distinguen origen: con SIGA activo ejecutan los procedimientos VFP; con API activa no duplican efectos.
- No volver a anexar procedimientos desde un PRG externo. Las fuentes oficiales son `Programas/varios.prg` y `Programas/varios2.prg`.
- El tenant DIPRO aun requiere una decision controlada sobre cuando aplicar la migracion versionada en produccion. No hacerlo automaticamente durante estas pruebas locales.

## Primeras pruebas despues del reinicio

1. Abrir VFP/SIGA desde cero, sin restaurar ventanas del depurador.
2. Ejecutar `Programas/principal.prg` y entrar a DIPRO.
3. Crear un pedido de prueba y entrar en la columna Codigo. Confirmar que el catalogo abre, filtra y devuelve un producto.
4. Cerrar el pedido sin guardar si solo se valida el catalogo.
5. Abrir una factura activa de prueba y ejecutar anulacion desde SIGA. Debe aparecer confirmacion, ventana de motivo y finalizar sin cerrar VFP.
6. Registrar numero y hora exactos; revisar inmediatamente encabezado, detalle, inventario, CxC y partida.
7. Arrancar API local con `Start-LocalApi.ps1`, levantar Dashboard y repetir una anulacion Web controlada.
8. Comparar SIGA contra Web. Solo entonces probar anulacion masiva Web.
9. No desplegar VPS ni actualizar DIPRO productivo hasta que ambas rutas coincidan.

## Archivos principales modificados

- `Programas/varios.prg` / `varios.fxp`
- `Programas/varios2.prg` / `varios2.fxp`
- `ventas/frm_ven_ventas_mod.scx/SCT`
- `inventarios/frm_inv_productos.scx/SCT`
- En el cierre general se detecto `ENDPROCPROCEDURE Init` concatenado en `ventas/frm_ven_envio.scx`; se restauro el salto entre procedimientos. La compilacion final VFP termino `COMPILE_OK 8/8` para `varios`, `varios2`, productos, ventas activa, ventas buena, ventas modificada, envio y facturacion de pedidos.
- API: `Services/SigaSalesCommandService*.cs`, `Services/SigaApiTriggerRuntime.cs`, `Services/SigaTenantCompatibilityService.cs`, `Vfp/SigaTenantMigrator.prg/EXE`
- Dashboard: facturacion/anulacion, estados visuales, usuario activo, filtros contado/credito y diagnosticos documentales acumulados en la rama.

## Regla de interpretacion al continuar

No asumir que todo cierre ocurre durante anulacion. Primero identificar en el video la pantalla y la accion exacta. Los videos de 12:33, 12:53 y 14:00 correspondieron respectivamente a carga del catalogo, impresion/PDF y apertura del catalogo desde un pedido.
