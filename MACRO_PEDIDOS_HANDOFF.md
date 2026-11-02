# Handoff: Macro de pedidos y cotizaciones a proveedores

Fecha del analisis: 2026-10-22  
Solicitado por: Julio  
Proyecto de referencia: SIGA ERP Visual FoxPro
Destino de implementacion: API SIGA + Dashboard/PWA

## Alcance acordado

El proyecto `D:\Desarrollo VFP\AgilSoft Fuente` se utilizara solamente para analizar la logica, tablas, indices, permisos y procesos existentes de SIGA ERP. No se modificaran formularios, programas, menus, DBF, DBC, indices ni datos del ERP para esta funcion.

La implementacion final se realizara en:

- API: `D:\Desarrollo_.net\apisigavfp`
- Dashboard/PWA: `D:\Desarrollo_.net\dashboarsiga`

Agregar en el Dashboard, debajo de `Reportes de ventas`, una opcion llamada `Macro de pedidos`.

La consulta debe calcular necesidades de compra, permitir seleccionar varios proveedores, exportar cotizaciones a Excel, volver a cargar las respuestas reales de los proveedores y convertir el resultado en borradores de pedidos de compra agrupados por proveedor. Los pedidos deben quedar pendientes de autorizacion; nunca deben emitirse automaticamente por importar una cotizacion.

El analisis funcional puede continuarse desde la sesion de SIGA ERP para aprovechar su contexto del modelo VFP, pero sus conclusiones deben documentarse y entregarse a las sesiones de API y Dashboard. La formula y las reglas de negocio deben vivir centralmente en la API para que el Dashboard no duplique calculos y, en el futuro, puedan reutilizarlas otros clientes autorizados.

El navegador no debe abrir DBF directamente. Toda lectura y escritura debe pasar por la API win-x86 que ya usa VFPOLEDB, respetando tenant, permisos, auditoria y confirmaciones.

## Fuente antigua analizada

- Proyecto historico: `D:\DESARROLLO VFP\SIGA\`
- Formulario: `D:\DESARROLLO VFP\SIGA\Formularios\frmconsulta1.scx/SCT`
- Primera opcion real: `1 - Macro de Pedidos`
- Metodos principales: `consulta1`, `filtrar1`, `filtrar2`, `filtrar3`, `filtrar4` y `filtrar5`.

No copiar directamente el SCX/SCT historico. Primero localizar el formulario/menu activo equivalente dentro de `D:\Desarrollo VFP\AgilSoft Fuente` y crear respaldo fechado de todo archivo VFP que vaya a editarse.

## Comportamiento legado confirmado

1. Lee ventas y devoluciones del intervalo seleccionado.
2. Excluye ventas anuladas (`ventas.anulado=0`).
3. Solo considera tipos de documento con `TipoDoctos.CtrlVtas` 1 o 2.
4. Las devoluciones se incorporan con cantidad e importes negativos.
5. La macro aplica solo a inventariables `productos.tipoprod=1`.
6. Agrupa unidades por producto y periodo mensual.
7. Calcula participacion acumulada por unidades y monto:
   - Movilidad 1: hasta 60%; 2: 60-80%; 3: 80-95%; 4: resto.
   - Monto A: hasta 60%; B: 60-80%; C: 80-95%; D: resto.
8. Forma una clase como `A1-12`: monto, movilidad y cantidad de meses con venta.
9. Factores historicos por meses con venta:
   - 10 a 12 meses: 3.09.
   - 8 a 9 meses: 0.99.
   - 6 a 7 meses: 0.52.
   - 1 a 5 meses: 0.
10. Aunque lee dias/meses del proveedor, luego impone a todos `Meses_Transito=0.25` y `Meses_A_Pedir=0.50`.
11. Formula historica:

```text
InventarioSeguridad = Factor * VariacionMensual * MesesRevision
Cobertura = MesesTransito + MesesRevision
Sugerido = PromedioMensual * Cobertura
           + InventarioSeguridad
           - Existencia
           - PedidosEnTransito
SugeridoRedondeado = CEILING(MAX(0, Sugerido) / Juego) * Juego
```

12. `VariacionMensual`, pese a llamarse `desviacion_estandar`, es el promedio de diferencias absolutas contra el promedio, no una desviacion estandar estadistica.
13. Calcula pedido de emergencia con demanda durante transito menos existencia y transito.
14. Recupera hasta tres proveedores historicos y hasta tres productos equivalentes.
15. Guarda nuevamente en `productos` clase, cobertura, punto de reorden, dias para pedir, transito y emergencia.

## Fallas del metodo historico que no se deben repetir

- Los filtros visibles de almacen, caja y condicion de pago no se aplican realmente a la consulta base.
- La existencia usada es general de `productos`, no necesariamente la existencia del almacen seleccionado.
- Los valores reales/configurados del proveedor se pierden por el reemplazo fijo 0.25/0.50.
- La supuesta desviacion estandar no es estadistica.
- El inventario de seguridad se multiplica linealmente por el horizonte; para demanda independiente debe escalarse por la raiz cuadrada del horizonte.
- Un producto con ventas en cinco meses o menos recibe seguridad cero, incluso si su demanda es importante o intermitente.
- Las clases `N` (nuevo) y `L` (liquidacion) no tienen factor de seguridad explicito.
- Los equivalentes se agrupan para visualizacion, pero no hay una asignacion segura que evite comprar de mas entre productos equivalentes.
- Ejecutar una consulta no deberia alterar silenciosamente el maestro de productos. Persistir parametros/resultados debe ser una accion separada, autorizada y auditada.

## Formula mejorada recomendada

Implementar primero el modo `Mejorado` y, solo para comparacion, permitir `Legado compatible` sin que este escriba en `productos`.

### Demanda

Usar todos los periodos del rango, incluidos meses con cero venta:

```text
PromedioMensual = SUM(DemandaMensual) / NumeroMeses
DesviacionMensual = SQRT(SUM((DemandaMes - PromedioMensual)^2) / (NumeroMeses - 1))
```

La demanda debe ser neta de devoluciones y excluir anulados/eliminados. El rango inicial recomendado es 12 meses, configurable a 3, 6 o 12 meses.

### Nivel de servicio

Propuesta inicial configurable:

| Clase por importancia | Nivel servicio | Z |
|---|---:|---:|
| A | 99% | 2.33 |
| B | 95% | 1.65 |
| C | 90% | 1.28 |
| D | 80% | 0.84 |

No codificar estos valores dentro del formulario; centralizarlos en parametros para poder afinarlos por empresa o familia.

### Horizonte y seguridad

Trabajar preferiblemente en dias para evitar fracciones ambiguas de meses:

```text
HorizonteDias = TiempoEntregaProveedorDias + PeriodoRevisionDias
DemandaEsperada = PromedioDiario * HorizonteDias
InventarioSeguridad = Z * DesviacionDiaria * SQRT(HorizonteDias)
DisponibleNeto = ExistenciaAlmacen
                 + EntradasConfirmadas
                 - Reservado
                 - Comprometido
Necesidad = MAX(0, DemandaEsperada + InventarioSeguridad - DisponibleNeto)
CantidadSugerida = redondear hacia arriba por EmpaqueCompra/MultiploCompra
```

Si existe variacion historica confiable del tiempo de entrega, usar:

```text
InventarioSeguridad = Z * SQRT(
    HorizonteDias * VarianzaDemandaDiaria
    + PromedioDiario^2 * VarianzaTiempoEntrega
)
```

Para demanda intermitente no inventar una precision falsa. Marcar el producto como `Demanda intermitente` y, en una segunda fase, evaluar Croston-SBA. La primera entrega puede usar el calculo general mostrando claramente ventas en meses/dias y nivel de confianza.

### Reglas de negocio

- Calcular existencia por almacen seleccionado.
- Permitir consolidar varios almacenes solamente cuando el usuario lo seleccione expresamente.
- Restar reservas/compromisos vigentes y sumar solo compras en transito confirmadas y no anuladas/eliminadas.
- Respetar empaque, multiplo de compra, cantidad minima y equivalencias de unidad.
- Producto nuevo: usar demanda manual, producto equivalente o promedio de familia; nunca asignar cero silenciosamente.
- Producto en liquidacion: sugerido cero por defecto, con inclusion manual autorizada.
- Productos equivalentes: mostrar necesidad consolidada, pero exigir seleccionar el producto exacto que se cotizara/comprara para no duplicar cantidades.
- Mostrar desglose auditable de cada formula por producto.

## Flujo de cotizacion y pedidos

### 1. Calcular macro

Filtros minimos:

- Fecha desde/hasta o rango 3/6/12 meses.
- Almacen o almacenes.
- Familia, rubro, sistema, division y productos.
- Proveedores candidatos.
- Incluir/excluir liquidacion, productos nuevos y demanda intermitente.
- Nivel de servicio o configuracion por clase.

Resultado en grid seleccionable con: codigo, producto, unidad, proveedor habitual, ventas por periodo, promedio, desviacion, meses con venta, existencia, reservado, comprometido, transito, tiempo de entrega, inventario de seguridad, necesidad, empaque y sugerido. Mantener las reglas visuales globales de SIGA para alineacion y ordenamiento.

### 2. Preparar solicitudes de cotizacion

- Seleccionar productos y uno o varios proveedores candidatos.
- Crear un lote con UID estable e idempotente.
- Un mismo requerimiento puede enviarse a varios proveedores para comparar, pero esto no multiplica la cantidad final a comprar.
- Exportar un XLSX por proveedor, o un libro maestro con hojas separadas, conservando identidad estable del lote, proveedor y producto.

Columnas no editables/validadas al reimportar:

- UID lote.
- ID proveedor.
- ID producto.
- Codigo SIGA.
- Descripcion.
- Unidad y empaque.
- Cantidad solicitada.

Columnas que llena el proveedor:

- Cantidad disponible.
- Precio unitario cotizado.
- Impuesto incluido/separado.
- Descuento.
- Empaque o minimo requerido.
- Dias de entrega.
- Vigencia de oferta.
- Observaciones.

No confiar en formulas, descripciones ni IDs modificados del Excel. Validar el UID y las claves contra el lote original.

### 3. Importar respuestas

- Reimportacion idempotente por lote/proveedor/producto.
- Mostrar filas validas, advertencias y errores antes de aplicar.
- Conservar historial de cada version de cotizacion y usuario/equipo/fecha.
- Normalizar precios a la misma unidad, moneda, impuesto y descuento antes de comparar.
- No alterar costos maestros ni crear compras al importar.

### 4. Evaluar y asignar

- Comparar costo neto, disponibilidad, plazo, vigencia y minimo de compra.
- Permitir adjudicar un producto a uno o varios proveedores cuando uno no cubra toda la cantidad.
- La suma adjudicada no debe superar la necesidad autorizada salvo confirmacion expresa.
- Mostrar faltante no cubierto.
- Si se usa un puntaje automatico, mostrar sus componentes y permitir correccion manual.

### 5. Generar pedidos reales

- Crear borradores agrupados por proveedor con la cotizacion elegida como respaldo.
- Conservar referencia a lote, respuesta y linea adjudicada.
- Estado inicial: `Pendiente de autorizacion`.
- Autorizar y emitir mediante el flujo normal de compras/pedidos de SIGA y sus permisos existentes.
- Evitar duplicados si se vuelve a ejecutar o importar el mismo lote.

Estados sugeridos del proceso:

```text
CALCULADO -> COTIZACION_GENERADA -> RESPUESTA_RECIBIDA -> EVALUADA
          -> PEDIDOS_BORRADOR -> AUTORIZADOS -> EMITIDOS
```

Agregar tambien `CANCELADO`, `VENCIDO` y `CON_ERRORES`.

## Alcance recomendado para la primera entrega web

1. Analizar en modo de solo lectura el proceso equivalente de SIGA ERP.
2. Definir en la API los DTO, consultas, formula, permisos y auditoria.
3. Insertar en el Dashboard `Macro de pedidos` debajo de `Reportes de ventas`.
4. Implementar formula mejorada sin escribir silenciosamente en `productos`.
5. Incorporar comparador opcional `Legado compatible` para validar productos de muestra.
6. Crear el grid web con explicacion completa de calculo y exportacion Excel.
7. Crear lotes de cotizacion para varios proveedores.
8. Importar y validar las respuestas.
9. Permitir evaluacion y adjudicacion manual asistida.
10. Generar por API borradores de pedidos por proveedor pendientes de autorizacion.

No crear DBF ni modificar DBC reales como parte de este analisis. Primero presentar a Julio el modelo de datos, los formularios/procesos VFP tomados como referencia, el contrato propuesto de API y las pantallas del Dashboard. Si se determina que hace falta persistencia nueva, proponerla antes de implementarla; cualquier cambio estructural requiere autorizacion explicita y prueba sobre copia aislada.

## Validacion minima

- Comparar modo legado contra la version historica usando el mismo rango y productos.
- Probar productos con ventas constantes, variables, intermitentes, sin venta, nuevos y en liquidacion.
- Probar una y varias bodegas.
- Probar compras en transito, reservas y empaques mayores que uno.
- Exportar cotizacion a dos proveedores, importar precios/disponibilidades distintos y adjudicar parcialmente.
- Confirmar que reimportar no duplique respuestas ni pedidos.
- Confirmar que antes de autorizacion no exista pedido emitido ni movimiento contable/inventario.
- Compilar formularios VFP sin `.ERR` y conservar respaldo fechado.

## Primer paso de la proxima sesion de SIGA ERP

Leer `AGENTS.md`, `WORK_STATUS.md` y este documento. Despues localizar en modo de solo lectura la consulta equivalente actual y los formularios/tablas vigentes de cotizaciones y pedidos de compra. Presentar un mapa del proceso, campos, relaciones, validaciones y permisos que la API/Dashboard deben reproducir. No modificar fuentes VFP, estructuras ni datos.

Al terminar el analisis, dejar un handoff concreto para `apisigavfp` y `dashboarsiga` con las consultas VFP necesarias, contrato HTTP propuesto, reglas de autorizacion, riesgos y casos de prueba.
