# Estado de trabajo VFP

Fecha: 2026-11-02
Rama: `feature/modulo-facturacion`

## Objetivo actual

Cerrar en la fuente oficial VFP todos los cambios terminados en los proyectos relacionados, integrar la rama compartida, recompilar `principal.exe` y dejar Git sincronizado sin perder trabajo local ni remoto.

## Cambios integrados

- Se integraron los 18 commits pendientes de `fork/feature/modulo-facturacion` con los tres commits locales de cierre.
- Se conservaron las pantallas y rutinas remotas de facturacion de pedidos, lecturas, inventarios, envios y ventas.
- `frm_com_login` conserva el inicio de sesion recordado y ejecuta las validaciones/migraciones vigentes al entrar a la empresa.
- `frm_ven_ventas_mod` combina las mejoras remotas de grabacion con las validaciones locales de documento activo y el soporte de `idEnvio`.
- Se conservaron las mejoras de usuarios, clave y vinculos provenientes de la rama compartida.
- `varios.prg` conserva las mejoras locales de Caja y Bancos, WhatsApp e IA, junto con las incorporaciones remotas; se retiraron tres redefiniciones duplicadas de `xlTop` que impedian compilar.
- `varios2.prg` incorpora las rutinas remotas de anulacion, importacion y conciliacion, junto con las validaciones locales DBC, retencion de renta y procedimientos almacenados.

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

## Decisiones

- No se revirtieron triggers ni validaciones funcionales ya terminadas; se combinaron las variantes local y remota.
- No se modificaron datos reales ni se desplego a produccion.
- Los directorios de empresas, salidas y copias locales permanecen fuera del commit.

## Siguiente paso exacto

Confirmar la prueba funcional en Farmacia al iniciar sesion; el login instalara el paquete DBC v2 si la empresa aun conserva una version anterior.
