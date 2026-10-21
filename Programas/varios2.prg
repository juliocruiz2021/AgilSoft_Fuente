FUNCTION _api_preparetriggerenv
    PUBLIC pcSysDir, pcDB, pncambiandoStructura, pLRecosteando, ;
           plconExistenciasNegativas, pcApiTriggerBasePath

    LOCAL lcDbcPath, lcBasePath, lcDbFolderNoSlash
    LOCAL llOpenedSisEmp, lcAliasSisEmp, lcTipoCampoSisEmp
    LOCAL lcAliasAnterior

    lcAliasAnterior = ALIAS()

    IF TYPE('pncambiandoStructura') <> 'N'
        pncambiandoStructura = 0
    ENDIF

    pLRecosteando = .f.
    plconExistenciasNegativas = .f.

    IF TYPE('pcSysDir') <> 'U' AND TYPE('pcDB') <> 'U' AND ;
       !EMPTY(pcSysDir) AND !EMPTY(pcDB)

        IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
            SELECT (lcAliasAnterior)
        ENDIF

    ENDIF

    lcDbcPath = DBC()
    IF !EMPTY(lcDbcPath)
        lcBasePath = lcDbcPath
    ELSE
        IF !EMPTY(ALIAS()) AND !EMPTY(DBF())
            lcBasePath = DBF()
        ELSE
            lcBasePath = ''
        ENDIF
    ENDIF

    IF EMPTY(lcBasePath)
        pcSysDir = ''
        pcDB = ''
        pcApiTriggerBasePath = ''

        IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
            SELECT (lcAliasAnterior)
        ENDIF

    ENDIF

    lcDbFolderNoSlash = JUSTPATH(lcBasePath)
    IF EMPTY(lcDbFolderNoSlash)
        pcSysDir = ''
        pcDB = ''
        pcApiTriggerBasePath = ''

        IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
            SELECT (lcAliasAnterior)
        ENDIF

    ENDIF

    pcSysDir = ADDBS(JUSTPATH(lcDbFolderNoSlash))
    pcDB = JUSTSTEM(lcDbFolderNoSlash)
    pcApiTriggerBasePath = lcBasePath

    IF EMPTY(pcSysDir) OR EMPTY(pcDB)
        IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
            SELECT (lcAliasAnterior)
        ENDIF

    ENDIF

    lcAliasSisEmp = 'apiSisEmpNeg'
    llOpenedSisEmp = !USED(lcAliasSisEmp)

    TRY
        IF llOpenedSisEmp
            USE (pcSysDir + pcDB + "\sisempresas") IN 0 SHARED AGAIN ALIAS (lcAliasSisEmp)
        ENDIF

        IF USED(lcAliasSisEmp)
            SELECT (lcAliasSisEmp)

            LOCATE FOR idempresa = 1
            IF !FOUND()
                GO TOP
            ENDIF


            IF !EOF()
                lcTipoCampoSisEmp = TYPE(lcAliasSisEmp + '.conExistenciasNegativas')

                DO CASE
                CASE lcTipoCampoSisEmp = 'L'
                    plconExistenciasNegativas = ;
                        EVALUATE(lcAliasSisEmp + '.conExistenciasNegativas')

                CASE lcTipoCampoSisEmp $ 'NIYB'
                    plconExistenciasNegativas = ;
                        (NVL(EVALUATE(lcAliasSisEmp + '.conExistenciasNegativas'), 0) = 1)
                ENDCASE
            ENDIF
        ENDIF
    CATCH
        plconExistenciasNegativas = .f.
    FINALLY
        IF llOpenedSisEmp AND USED(lcAliasSisEmp)
            USE IN (lcAliasSisEmp)
        ENDIF

        IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
            SELECT (lcAliasAnterior)
        ENDIF
    ENDTRY
ENDFUNC


FUNCTION COMRETURNERROR
    LPARAMETERS tcProcedure, tcMessage

    PUBLIC pcApiProcError

    pcApiProcError = TRANSFORM(tcProcedure) + ": " + TRANSFORM(tcMessage)

    IF TYPE('llEstamosCorriendoFVP') <> 'U'
        MESSAGEBOX(TRANSFORM(tcMessage), 16, ;
            "Error de Integridad... (" + TRANSFORM(tcProcedure) + ")", 3000)
    ELSE
        =_api_logtriggererror(tcProcedure, tcMessage)
    ENDIF

ENDFUNC


FUNCTION _api_logtriggererror
    LPARAMETERS tcProcedure, tcMessage

    PUBLIC pcApiRequestId

    LOCAL lcLogFile, lcRequestId

    =_api_preparetriggerenv()

    IF EMPTY(pcSysDir) OR EMPTY(pcDB)
        
    ENDIF

    lcRequestId = ""
    IF TYPE("pcApiRequestId") = "C"
        lcRequestId = pcApiRequestId
    ENDIF

    lcLogFile = pcSysDir + pcDB + "\api_trigger_errors.log"

    TRY
        STRTOFILE( ;
            TTOC(DATETIME(), 1) + "|" + ;
            lcRequestId + "|" + ;
            TRANSFORM(tcProcedure) + "|" + ;
            TRANSFORM(tcMessage) + CHR(13) + CHR(10), ;
            lcLogFile, ;
            1 ;
        )
    CATCH
    ENDTRY

ENDFUNC





FUNCTION _Select(lnIdConec,lcComando,lcTabla,lcCursor)
	SQLEXEC(lnIdConec,lcComando,lcCursor)
*	=CURSORSETPROP("Buffering",5,lcCursor)

	DO case
		CASE lcTabla=='usuarios'		
			 =CURSORSETPROP("Tables",lcCursor)	
			lcCampos1="idusuario  usuarios.idusuario,  usuario  usuarios.usuario,  clave  usuarios.clave,  nombre  usuarios.nombre,  idsucursal  usuarios.idsucursal,  "	
			lcCampos2="idvendedor  usuarios.idvendedor,  idcaja  usuarios.idcaja,  registros  usuarios.registros,  status  usuarios.status,idcajachica usuarios.idcajachica "	
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2)	
			 =CURSORSETPROP("KeyFieldList", "idusuario")	
			lcCamposb1="idusuario,  usuario,  clave,  nombre,  idsucursal,  idvendedor,  idcaja,  registros,  "	
			lcCamposb2="status,idcajachica  "	
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2)	
			 =CURSORSETPROP("SendUpdates", .T.)	

		CASE lcTabla=='cajas'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idcaja  cajas.idcaja,  caja  cajas.caja,  idsucursal  cajas.idsucursal,  fondo  cajas.fondo,  saldo  cajas.saldo,  "
			lcCampos2="fecha  cajas.fecha,  status  cajas.status,tipocaja cajas.tipocaja "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2)
			 =CURSORSETPROP("KeyFieldList", "idcaja")
			lcCamposb1="idcaja,  caja,  idsucursal,  fondo,  saldo,  fecha,  status,tipocaja "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)
			 =CURSORSETPROP("SendUpdates", .T.)
			
		CASE lcTabla=='abonos'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idabono  abonos.idabono,  idtipodocumento  abonos.idtipodocumento,  idcaja  abonos.idcaja,  idserie  abonos.idserie,  numeroabono  abonos.numeroabono,  "
			lcCampos2="fechaabono  abonos.fechaabono,  concepto  abonos.concepto,  valor  abonos.valor,  ctrolcaja  abonos.ctrolcaja,  modulo  abonos.modulo,  "
			lcCampos3="anulado  abonos.anulado,  idreferencia  abonos.idreferencia,  status  abonos.status "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3)
			 =CURSORSETPROP("KeyFieldList", "idabono")
			lcCamposb1="idabono,  idtipodocumento,  idcaja,  idserie,  numeroabono,  fechaabono,  concepto,  valor,  "
			lcCamposb2="ctrolcaja,  modulo,  anulado,  idreferencia,  status "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2)
			 =CURSORSETPROP("SendUpdates", .T.)

		CASE lcTabla=='sucursales'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idsucursal  sucursales.idsucursal,  sucursal  sucursales.sucursal,  direccion  sucursales.direccion,  telefono  sucursales.telefono,  correo  sucursales.correo,  "
			lcCampos2="status  sucursales.status  "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2)
			 =CURSORSETPROP("KeyFieldList", "idsucursal")
			lcCamposb1="idsucursal,  sucursal,  direccion,  telefono,  correo,  status "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)
			 =CURSORSETPROP("SendUpdates", .T.)
			
		CASE lcTabla=='impresores'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idimpresor  impresores.idimpresor,  impresor  impresores.impresor,  consumo  impresores.consumo,  tipoimpresor  impresores.tipoimpresor,  ancho  impresores.ancho,  "
			lcCampos2="idsucursal  impresores.idsucursal,  status  impresores.status "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2)
			 =CURSORSETPROP("KeyFieldList", "idimpresor")
			lcCamposb1="idimpresor,  impresor,  consumo,  tipoimpresor,  ancho,  idsucursal,  status "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)
			 =CURSORSETPROP("SendUpdates", .T.)
			
		CASE lcTabla=='productos'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idproducto  productos.idproducto,  codproducto  productos.codproducto,  producto  productos.producto,  descripcion  productos.descripcion,  tipoproducto  productos.tipoproducto,  "
			lcCampos2="unidadmedida  productos.unidadmedida,  marca  productos.marca,  idlinea  productos.idlinea,  ubicacion  productos.ubicacion,  existencia  productos.existencia,  "
			lcCampos3="existenciaminima  productos.existenciaminima,  existenciamaxima  productos.existenciamaxima,  costopromedio  productos.costopromedio,  costototal  productos.costototal,  costopromediolote  productos.costopromediolote,  "
			lcCampos4="costototallote  productos.costototallote,  ucostocompra  productos.ucostocompra,  uiddocumentocompra  productos.uiddocumentocompra,  uidsocionegociocompra  productos.uidsocionegociocompra,  ufechacompra  productos.ufechacompra,  "
			lcCampos5="precio  productos.precio,  preciominimo  productos.preciominimo,  preciominimotarjeta  productos.preciominimotarjeta,  tipoiva  productos.tipoiva,  tiposerie  productos.tiposerie,  "
			lcCampos6="usuario  productos.usuario,  fechaalta  productos.fechaalta,  status  productos.status,liquidacion productos.liquidacion,codrenta productos.codrenta "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5+lcCampos6)
			 =CURSORSETPROP("KeyFieldList", "idproducto")
			lcCamposb1="idproducto,  codproducto,  producto,  descripcion,  tipoproducto,  unidadmedida,  marca,  idlinea,  "
			lcCamposb2="ubicacion,  existencia,  existenciaminima,  existenciamaxima,  costopromedio,  costototal,  costopromediolote,  costototallote,  "
			lcCamposb3="ucostocompra,  uiddocumentocompra,  uidsocionegociocompra,  ufechacompra,  precio,  preciominimo,  preciominimotarjeta,  tipoiva,  "
			lcCamposb4="tiposerie,  usuario,  fechaalta,  status,liquidacion,codrenta "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3+lcCamposb4)
			 =CURSORSETPROP("SendUpdates", .T.)
			
			
		CASE lcTabla=='listas'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idlista  listas.idlista,  lista  listas.lista,  nivel  listas.nivel, idsucursal listas.idsucursal, status  listas.status "
			 =CURSORSETPROP("UpdateNameList",lcCampos1)
			 =CURSORSETPROP("KeyFieldList", "idlista")
			lcCamposb1="idlista,  lista,  nivel, idsucursal, status "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)
			 =CURSORSETPROP("SendUpdates", .T.)
			
		CASE lcTabla=='socionegocios'		
			 =CURSORSETPROP("Tables",lcCursor)	
			lcCampos1="idsocionegocio  socionegocios.idsocionegocio,  codsocionegocio  socionegocios.codsocionegocio,  socionegocio  socionegocios.socionegocio,  idsucursal  socionegocios.idsucursal,  direccion  socionegocios.direccion,  "	
			lcCampos2="departamento  socionegocios.departamento,  municipio  socionegocios.municipio,  telefono  socionegocios.telefono,  celular  socionegocios.celular,  ciacelular  socionegocios.ciacelular, tipoiva socionegocios.tipoiva, "	
			lcCampos3="correo  socionegocios.correo,  tipocontribuyente  socionegocios.tipocontribuyente,  nit  socionegocios.nit,  nrc  socionegocios.nrc,  giro  socionegocios.giro, nombre socionegocios.nombre,dui socionegocios.dui, "	
			lcCampos4="diascredito  socionegocios.diascredito,  limitecredito  socionegocios.limitecredito,  saldo  socionegocios.saldo,  tipo  socionegocios.tipo,  clientefinal  socionegocios.clientefinal,descuento socionegocios.descuento "	
			lcCampos5="equipos  socionegocios.equipos,  idlista  socionegocios.idlista,  idgrupocliente  socionegocios.idgrupocliente,  imagenfirma  socionegocios.imagenfirma,  status  socionegocios.status,condicionpago socionegocios.condicionpago, "	
			lcCampos6="idclasecredito socionegocios.idclasecredito "	
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5+lcCampos6)	
			 =CURSORSETPROP("KeyFieldList", "idsocionegocio")	
			lcCamposb1="idsocionegocio,  codsocionegocio,  socionegocio,  idsucursal,  direccion,  departamento,  municipio,  telefono,  "	
			lcCamposb2="celular,  ciacelular, tipoiva,correo,  tipocontribuyente,  nit,  nrc,  giro, nombre,dui, diascredito,  "	
			lcCamposb3="limitecredito,  saldo,  tipo,  clientefinal, descuento, equipos,  idlista,  idgrupocliente,  imagenfirma,  "	
			lcCamposb4="status,condicionpago,idclasecredito  "	
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3+lcCamposb4)	
			 =CURSORSETPROP("SendUpdates", .T.)	

		CASE lcTabla=='grupoclientes'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idgrupocliente  grupoclientes.idgrupocliente,  grupocliente  grupoclientes.grupocliente,  status  grupoclientes.status,  clipro  grupoclientes.clipro  "
			 =CURSORSETPROP("UpdateNameList",lcCampos1)
			 =CURSORSETPROP("KeyFieldList", "idgrupocliente")
			lcCamposb1="idgrupocliente,  grupocliente,  status,  clipro "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)
			 =CURSORSETPROP("SendUpdates", .T.)

				
		CASE lcTabla=='series'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idserie  series.idserie,  serie  series.serie,  inicial  series.inicial,  final  series.final,  siguiente  series.siguiente,  "
			lcCampos2="digitos  series.digitos,  automatica  series.automatica,  prefijo  series.prefijo,  tiraje  series.tiraje,  resolucion  series.resolucion,  "
			lcCampos3="autorizacion  series.autorizacion,  fechaautorizacion  series.fechaautorizacion,  status  series.status "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3)
			 =CURSORSETPROP("KeyFieldList", "idserie")
			lcCamposb1="idserie,  serie,  inicial,  final,  siguiente,  digitos,  automatica,  prefijo,  "
			lcCamposb2="tiraje,  resolucion,  autorizacion,  fechaautorizacion,  status "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2)
			 =CURSORSETPROP("SendUpdates", .T.)

		CASE lcTabla=='seriescajas'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idseriescaja  seriescajas.idseriescaja,  seriescaja  seriescajas.seriescaja,  idserie  seriescajas.idserie,  idtipodocumento  seriescajas.idtipodocumento,  idsucursal  seriescajas.idsucursal,  "
			lcCampos2="idcaja  seriescajas.idcaja,  formato  seriescajas.formato,  impresor  seriescajas.impresor "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2)
			 =CURSORSETPROP("KeyFieldList", "idseriescaja")
			lcCamposb1="idseriescaja,  seriescaja,  idserie,  idtipodocumento,  idsucursal,  idcaja,  formato,  impresor "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)
			 =CURSORSETPROP("SendUpdates", .T.)
			
					
		CASE lcTabla=='equipos'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idequipo  equipos.idequipo,  idsocionegocio  equipos.idsocionegocio,  codequipo  equipos.codequipo,  equipo  equipos.equipo,  marca  equipos.marca,  "
			lcCampos2="modelo  equipos.modelo,  ano  equipos.ano,  odo  equipos.odo,  motor  equipos.motor,  chasis  equipos.chasis,  "
			lcCampos3="color  equipos.color,  status  equipos.status "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3)
			 =CURSORSETPROP("KeyFieldList", "idequipo")
			lcCamposb1="idequipo,  idsocionegocio,  codequipo,  equipo,  marca,  modelo,  ano,  odo,  "
			lcCamposb2="motor,  chasis,  color,  status "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2)
			 =CURSORSETPROP("SendUpdates", .T.)
			
		CASE lcTabla=='bodegas'		
			 =CURSORSETPROP("Tables",lcCursor)	
			lcCampos1="idbodega  bodegas.idbodega,  bodega  bodegas.bodega,  idsucursal  bodegas.idsucursal "	
			 =CURSORSETPROP("UpdateNameList",lcCampos1)	
			 =CURSORSETPROP("KeyFieldList", "idbodega")	
			lcCamposb1="idbodega,  bodega,  idsucursal "	
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)	
			 =CURSORSETPROP("SendUpdates", .T.)	

		CASE lcTabla=='lineas'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idlinea  lineas.idlinea,  linea  lineas.linea,  nivel  lineas.nivel,  idpadre  lineas.idpadre,  status  lineas.status  "
			 =CURSORSETPROP("UpdateNameList",lcCampos1)
			 =CURSORSETPROP("KeyFieldList", "idlinea")
			lcCamposb1="idlinea,  linea,  nivel,  idpadre,  status "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)
			 =CURSORSETPROP("SendUpdates", .T.)

		CASE lcTabla=='existenciasbodega'		
			 =CURSORSETPROP("Tables",lcCursor)	
			lcCampos1="idexistenciasbodega  existenciasbodega.idexistenciasbodega,  idproducto  existenciasbodega.idproducto,  idbodega  existenciasbodega.idbodega,  ubicacion  existenciasbodega.ubicacion,  existenciasbodega  existenciasbodega.existenciasbodega "	
			 =CURSORSETPROP("UpdateNameList",lcCampos1)	
			 =CURSORSETPROP("KeyFieldList", "idexistenciasbodega")	
			lcCamposb1="idexistenciasbodega,  idproducto,  idbodega,  ubicacion,  existenciasbodega "	
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)	
			 =CURSORSETPROP("SendUpdates", .T.)	
			
		CASE lcTabla=='historicocompras'		
			 =CURSORSETPROP("Tables",lcCursor)	
			lcCampos1="idhistoricocompra  historicocompras.idhistoricocompra,  idproducto  historicocompras.idproducto,  idsocionegocio  historicocompras.idsocionegocio,  fecha  historicocompras.fecha,  iddocumento  historicocompras.iddocumento,  "	
			lcCampos2="cantidad  historicocompras.cantidad,  costocompra  historicocompras.costocompra,  codproductoproveedor  historicocompras.codproductoproveedor "	
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2)	
			 =CURSORSETPROP("KeyFieldList", "idhistoricocompra")	
			lcCamposb1="idhistoricocompra,  idproducto,  idsocionegocio,  fecha,  iddocumento,  cantidad,  costocompra,  codproductoproveedor "	
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)	
			 =CURSORSETPROP("SendUpdates", .T.)	
				
			
		CASE lcTabla=='medidas'		
			 =CURSORSETPROP("Tables",lcCursor)	
			lcCampos1="idmedida  medidas.idmedida,  idproducto  medidas.idproducto,  medida  medidas.medida,  factor  medidas.factor,  precio  medidas.precio "	
			 =CURSORSETPROP("UpdateNameList",lcCampos1)	
			 =CURSORSETPROP("KeyFieldList", "idmedida")	
			lcCamposb1="idmedida,  idproducto,  medida,  factor,  precio "	
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)	
			 =CURSORSETPROP("SendUpdates", .T.)	

		CASE lcTabla=='precios'		
			 =CURSORSETPROP("Tables",lcCursor)	
			lcCampos1="idprecio  precios.idprecio,  idlista  precios.idlista,  idproducto  precios.idproducto,  idmedida  precios.idmedida,  precio  precios.precio,  "	
			 =CURSORSETPROP("UpdateNameList",lcCampos1)	
			 =CURSORSETPROP("KeyFieldList", "idprecio")	
			lcCamposb1="idprecio,  idlista,  idproducto,  idmedida,  precio "	
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)	
			 =CURSORSETPROP("SendUpdates", .T.)	
				
		CASE lcTabla=='equivalencias'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idequivalencia  equivalencias.idequivalencia,  id1  equivalencias.id1,  id2  equivalencias.id2  "
			 =CURSORSETPROP("UpdateNameList",lcCampos1)
			 =CURSORSETPROP("KeyFieldList", "idequivalencia")
			lcCamposb1="idequivalencia,  id1,  id2 "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)
			 =CURSORSETPROP("SendUpdates", .T.)
			
		CASE lcTabla=='equivalencias2'	
			 =CURSORSETPROP("Tables","equivalencias")
			lcCampos1="idequivalencia  equivalencias.idequivalencia,  id1  equivalencias.id1,  id2  equivalencias.id2  "
			 =CURSORSETPROP("UpdateNameList",lcCampos1)
			 =CURSORSETPROP("KeyFieldList", "idequivalencia")
			lcCamposb1="idequivalencia,  id1,  id2 "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)
			 =CURSORSETPROP("SendUpdates", .T.)

		CASE lcTabla=='materiales'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idmaterial  materiales.idmaterial,  idproducto  materiales.idproducto,  idconsumible  materiales.idconsumible,  idmedida  materiales.idmedida,  cantidadfactor  materiales.cantidadfactor,  "
			lcCampos2="factor  materiales.factor,  cantidad  materiales.cantidad "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2)
			 =CURSORSETPROP("KeyFieldList", "idmaterial")
			lcCamposb1="idmaterial,  idproducto,  idconsumible,  idmedida,  cantidadfactor,  factor,  cantidad "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)
			 =CURSORSETPROP("SendUpdates", .T.)

		CASE lcTabla=='kits'		
			 =CURSORSETPROP("Tables",lcCursor)	
			lcCampos1="idkit  kits.idkit,  idproducto  kits.idproducto,  idconsumible  kits.idconsumible,  idmedida  kits.idmedida,  cantidadfactor  kits.cantidadfactor,  "	
			lcCampos2="factor  kits.factor,  cantidad  kits.cantidad,  preciofactor  kits.preciofactor,  preciounitario  kits.preciounitario,  preciototal  kits.preciototal "	
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2)	
			 =CURSORSETPROP("KeyFieldList", "idkit")	
			lcCamposb1="idkit,  idproducto,  idconsumible,  idmedida,  cantidadfactor,  factor,  cantidad,  preciofactor,  "	
			lcCamposb2="preciounitario,  preciototal "	
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2)	
			 =CURSORSETPROP("SendUpdates", .T.)	
				
		CASE lcTabla=='agrupados'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idagrupado  agrupados.idagrupado,  id1  agrupados.id1,  id2  agrupados.id2"
			 =CURSORSETPROP("UpdateNameList",lcCampos1)
			 =CURSORSETPROP("KeyFieldList", "idagrupado")
			lcCamposb1="idagrupado,  id1,  id2 "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)
			 =CURSORSETPROP("SendUpdates", .T.)

		CASE lcTabla=='referencias'			
			 =CURSORSETPROP("Tables",lcCursor)		
			lcCampos1="idreferencia  referencias.idreferencia,  idsocionegocio  referencias.idsocionegocio,  referencia  referencias.referencia,  direccion  referencias.direccion,  telefono  referencias.telefono "		
			 =CURSORSETPROP("UpdateNameList",lcCampos1)		
			 =CURSORSETPROP("KeyFieldList", "idreferencia")		
			lcCamposb1="idreferencia,  idsocionegocio,  referencia,  direccion,  telefono "		
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)		
			 =CURSORSETPROP("SendUpdates", .T.)		
					
		CASE lcTabla=='documentos'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="iddocumento  documentos.iddocumento,idsocionegocio documentos.idsocionegocio,  documento  documentos.documento,  valor  documentos.valor "
			 =CURSORSETPROP("UpdateNameList",lcCampos1)
			 =CURSORSETPROP("KeyFieldList", "iddocumento")
			lcCamposb1="iddocumento,idsocionegocio,  documento,  valor "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)
			 =CURSORSETPROP("SendUpdates", .T.)

		CASE lcTabla=='cuentascobrar'			
			 =CURSORSETPROP("Tables",lcCursor)		
			lcCampos1="idcuentacobrar  cuentascobrar.idcuentacobrar,  idtipodocumento  cuentascobrar.idtipodocumento,  idsucursal  cuentascobrar.idsucursal,  idcaja  cuentascobrar.idcaja,  idserie  cuentascobrar.idserie,  "		
			lcCampos2="numero  cuentascobrar.numero,  fecha  cuentascobrar.fecha,  fechavencimiento  cuentascobrar.fechavencimiento,  montodocumento  cuentascobrar.montodocumento,  montoaplicado  cuentascobrar.montoaplicado,  "		
			lcCampos3="concepto  cuentascobrar.concepto,  ctrol  cuentascobrar.ctrol,  modulo  cuentascobrar.modulo,  anulado  cuentascobrar.anulado,  idreferencia  cuentascobrar.idreferencia,  "		
			lcCampos4="referencia  cuentascobrar.referencia,  idsocionegocio  cuentascobrar.idsocionegocio, idvendedor cuentascobrar.idvendedor"		
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4)		
			 =CURSORSETPROP("KeyFieldList", "idcuentacobrar")		
			lcCamposb1="idcuentacobrar,  idtipodocumento,  idsucursal,  idcaja,  idserie,  numero,  fecha,  fechavencimiento,  "		
			lcCamposb2="montodocumento,  montoaplicado,  concepto,  ctrol,  modulo,  anulado,  idreferencia,  referencia,  "		
			lcCamposb3="idsocionegocio,idvendedor "		
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3)		
			 =CURSORSETPROP("SendUpdates", .T.)		

		CASE lcTabla=='vendedores'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idvendedor  vendedores.idvendedor,  vendedor  vendedores.vendedor,  idsucursal  vendedores.idsucursal,  telefono  vendedores.telefono,  correo  vendedores.correo,  "
			lcCampos2="status  vendedores.status "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2)
			 =CURSORSETPROP("KeyFieldList", "idvendedor")
			lcCamposb1="idvendedor,  vendedor,  idsucursal,  telefono,  correo,  status "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)
			 =CURSORSETPROP("SendUpdates", .T.)


		CASE lcTabla=='ventas'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idventa  ventas.idventa,  idtipodocumento  ventas.idtipodocumento,  idserie  ventas.idserie,  numero  ventas.numero,  fecha  ventas.fecha,  "
			lcCampos2="fechavencimiento  ventas.fechavencimiento,  idsocionegocio  ventas.idsocionegocio,  idequipo  ventas.idequipo,  clientefinal  ventas.clientefinal,  socionegocio  ventas.socionegocio,  "
			lcCampos3="direccion  ventas.direccion,  departamento  ventas.departamento,  municipio  ventas.municipio,  giro  ventas.giro,  nit  ventas.nit,  "
			lcCampos4="nrc  ventas.nrc,  dui  ventas.dui,  tipoiva  ventas.tipoiva,  tiporetper  ventas.tiporetper,  porcentajeretper  ventas.porcentajeretper,  "
			lcCampos5="editableretper  ventas.editableretper,  descuento  ventas.descuento,  idvendedor  ventas.idvendedor,  exento  ventas.exento,  gravado  ventas.gravado,  "
			lcCampos6="nosujeto  ventas.nosujeto,  iva  ventas.iva,  ivalote  ventas.ivalote,  retencion  ventas.retencion,  percepcion  ventas.percepcion,  "
			lcCampos7="total  ventas.total,  totallote  ventas.totallote,  numcompret  ventas.numcompret,  idsucursal  ventas.idsucursal,  notas  ventas.notas,  "
			lcCampos8="condicionpago  ventas.condicionpago,  idcaja  ventas.idcaja,  anulado  ventas.anulado,  ctrol  ventas.ctrol,  status  ventas.status,  "
			lcCampos9="modulo  ventas.modulo,  lote  ventas.lote,  idautorizador  ventas.idautorizador,  autorizarcredito  ventas.autorizarcredito,  creditoautorizado  ventas.creditoautorizado,  "
			lcCampos10="descuentoautorizado  ventas.descuentoautorizado,  computadora  ventas.computadora,  usuario  ventas.usuario,  fechaalta  ventas.fechaalta "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5+lcCampos6+lcCampos7+lcCampos8+lcCampos9+lcCampos10)
			 =CURSORSETPROP("KeyFieldList", "idventa")
			lcCamposb1="idventa,  idtipodocumento,  idserie,  numero,  fecha,  fechavencimiento,  idsocionegocio,  idequipo,  "
			lcCamposb2="clientefinal,  socionegocio,  direccion,  departamento,  municipio,  giro,  nit,  nrc,  "
			lcCamposb3="dui,  tipoiva,  tiporetper,  porcentajeretper,  editableretper,  descuento,  idvendedor,  exento,  "
			lcCamposb4="gravado,  nosujeto,  iva,  ivalote,  retencion,  percepcion,  total,  totallote,  "
			lcCamposb5="numcompret,  idsucursal,  notas,  condicionpago,  idcaja,  anulado,  ctrol,  status,  "
			lcCamposb6="modulo,  lote,  idautorizador,  autorizarcredito,  creditoautorizado,  descuentoautorizado,  computadora,  usuario,  "
			lcCamposb7="fechaalta "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3+lcCamposb4+lcCamposb5+lcCamposb6+lcCamposb7)
			 =CURSORSETPROP("SendUpdates", .T.)
			
		CASE lcTabla=='ventasdetalle'		
			 =CURSORSETPROP("Tables",lcCursor)	
			lcCampos1="idventadetalle  ventasdetalle.idventadetalle,  idventa  ventasdetalle.idventa,  idproducto  ventasdetalle.idproducto,  descripcion  ventasdetalle.descripcion,  idmedida  ventasdetalle.idmedida,preciofactorserie ventasdetalle.preciofactorserie,  "	
			lcCampos2="cantidadfactor  ventasdetalle.cantidadfactor,  preciofactor  ventasdetalle.preciofactor,  factor  ventasdetalle.factor,  cantidad  ventasdetalle.cantidad,  preciolista  ventasdetalle.preciolista,  "	
			lcCampos3="preciominimo ventasdetalle.preciominimo,preciominimotarjeta ventasdetalle.preciominimotarjeta,preciolote ventasdetalle.preciolote,porcentajedescuento ventasdetalle.porcentajedescuento,porcentajedescuentocliente ventasdetalle.porcentajedescuentocliente,"	
			lcCampos4="descuentoventa  ventasdetalle.descuentoventa,  precionetofactor  ventasdetalle.precionetofactor,  precio  ventasdetalle.precio,  totalventanetalote  ventasdetalle.totalventanetalote,  totalventaneta  ventasdetalle.totalventaneta,  "	
			lcCampos5="totalivalote  ventasdetalle.totalivalote,  totaliva  ventasdetalle.totaliva,  costopromedio  ventasdetalle.costopromedio,  costopromediolote  ventasdetalle.costopromediolote,  entradasalida  ventasdetalle.entradasalida,  "	
			lcCampos6="notas  ventasdetalle.notas,  modulo  ventasdetalle.modulo,  idbodega  ventasdetalle.idbodega,  tipoiva  ventasdetalle.tipoiva,  poriva  ventasdetalle.poriva,cantidadkit ventasdetalle.cantidadkit,  "	
			lcCampos7="tipoproducto  ventasdetalle.tipoproducto,  tiposerie  ventasdetalle.tiposerie,  idkit  ventasdetalle.idkit,  idagrupador  ventasdetalle.idagrupador,  autorizar  ventasdetalle.autorizar,  "	
			lcCampos8="idautorizador  ventasdetalle.idautorizador,  computadora  ventasdetalle.computadora,  usuario  ventasdetalle.usuario,  fechaalta  ventasdetalle.fechaalta,  iddetalleserie  ventasdetalle.iddetalleserie,cantidadserie ventasdetalle.cantidadserie "	
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5+lcCampos6+lcCampos7+lcCampos8)	
			 =CURSORSETPROP("KeyFieldList", "idventadetalle")	
			lcCamposb1="idventadetalle,  idventa,  idproducto,  descripcion,  idmedida,preciofactorserie,  cantidadfactor,  preciofactor,  factor,  "	
			lcCamposb2="cantidad,  preciolista,  preciominimo,  preciominimotarjeta,  preciolote,  porcentajedescuento,  porcentajedescuentocliente,  descuentoventa,  "	
			lcCamposb3="precionetofactor,  precio,  totalventanetalote,  totalventaneta,  totalivalote,  totaliva,  costopromedio,  costopromediolote,  "	
			lcCamposb4="entradasalida,  notas,  modulo,  idbodega,  tipoiva,  poriva,cantidadkit,  tipoproducto,  tiposerie,  "	
			lcCamposb5="idkit,  idagrupador,  autorizar,  idautorizador,  computadora,  usuario,  fechaalta,  iddetalleserie,cantidadserie  "	
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3+lcCamposb4+lcCamposb5)	
			 =CURSORSETPROP("SendUpdates", .T.)	
				
		CASE lcTabla=='ventasdetalleserie'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idventadetalleserie ventasdetalleserie.idventadetalleserie, iddetalleserie ventasdetalleserie.iddetalleserie,idventa ventasdetalleserie.idventa,idproducto ventasdetalleserie.idproducto,idbodega ventasdetalleserie.idbodega,"
			lcCampos2="idmedida  ventasdetalleserie.idmedida,  idtraspaso  ventasdetalleserie.idtraspaso,  idlote  ventasdetalleserie.idlote,  serie  ventasdetalleserie.serie,  cantidadfactor  ventasdetalleserie.cantidadfactor, "
			lcCampos3="factor ventasdetalleserie.factor,cantidad ventasdetalleserie.cantidad,entradasalida ventasdetalleserie.entradasalida,costopromedio ventasdetalleserie.costopromedio,costopromediolote ventasdetalleserie.costopromediolote,"
			lcCampos4="precio  ventasdetalleserie.precio,  preciolote  ventasdetalleserie.preciolote,  poriva  ventasdetalleserie.poriva,  modulo  ventasdetalleserie.modulo "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4)
			 =CURSORSETPROP("KeyFieldList", "idventadetalleserie")
			lcCamposb1="idventadetalleserie,  iddetalleserie,  idventa,  idproducto,  idbodega,  idmedida,  idtraspaso,  idlote,  "
			lcCamposb2="serie,  cantidadfactor,  factor,  cantidad,  entradasalida,  costopromedio,  costopromediolote,  precio,  "
			lcCamposb3="preciolote,  poriva,  modulo "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3)
			 =CURSORSETPROP("SendUpdates", .T.)
			
							
		CASE lcTabla=='tipodocumentos'		
			 =CURSORSETPROP("Tables",lcCursor)	
			lcCampos1="idtipodocumento  tipodocumentos.idtipodocumento,  tipodocumento  tipodocumentos.tipodocumento,  modulo  tipodocumentos.modulo,  caja  tipodocumentos.caja,  inventarios  tipodocumentos.inventarios,  "	
			lcCampos2="ventas  tipodocumentos.ventas,  compras  tipodocumentos.compras,  ventasp  tipodocumentos.ventasp,  comprasp  tipodocumentos.comprasp,  cxc  tipodocumentos.cxc,  "	
			lcCampos3="cxp  tipodocumentos.cxp,  tipofac  tipodocumentos.tipofac,  lineas  tipodocumentos.lineas,  referencia  tipodocumentos.referencia,  status  tipodocumentos.status,  "	
			lcCampos4="orden  tipodocumentos.orden, idtipodocumento2 tipodocumentos.idtipodocumento2 "	
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4)	
			 =CURSORSETPROP("KeyFieldList", "idtipodocumento")	
			lcCamposb1="idtipodocumento,  tipodocumento,  modulo,  caja,  inventarios,  ventas,  compras,  ventasp,  "	
			lcCamposb2="comprasp,  cxc,  cxp,  tipofac,  lineas,  referencia,  status,  orden,idtipodocumento2 "	
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2)	
			 =CURSORSETPROP("SendUpdates", .T.)	

		CASE lcTabla=='guiaretper'		
			 =CURSORSETPROP("Tables",lcCursor)	
			lcCampos1="idguiaretper  guiaretper.idguiaretper,  tipoempresa  guiaretper.tipoempresa,  tiposocionegocio  guiaretper.tiposocionegocio,  tipocontribuyente  guiaretper.tipocontribuyente,  tiporetper  guiaretper.tiporetper,  "	
			lcCampos2="editable  guiaretper.editable,  porcentaje  guiaretper.porcentaje "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2)
			 =CURSORSETPROP("KeyFieldList", "idguiaretper")	
			lcCamposb1="idguiaretper,  tipoempresa,  tiposocionegocio,  tipocontribuyente,  tiporetper,  editable,  porcentaje "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1)	
			 =CURSORSETPROP("SendUpdates", .T.)	
							

		CASE lcTabla=='compras'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idventa  compras.idventa,  idtipodocumento  compras.idtipodocumento,  idserie  compras.idserie,  numero  compras.numero,  fecha  compras.fecha,  "
			lcCampos2="fechavencimiento  compras.fechavencimiento,  idsocionegocio  compras.idsocionegocio,  idequipo  compras.idequipo,  clientefinal  compras.clientefinal,  socionegocio  compras.socionegocio,  "
			lcCampos3="direccion  compras.direccion,  departamento  compras.departamento,  municipio  compras.municipio,  giro  compras.giro,  nit  compras.nit,  "
			lcCampos4="nrc  compras.nrc,  dui  compras.dui,  tipoiva  compras.tipoiva,  tiporetper  compras.tiporetper,  porcentajeretper  compras.porcentajeretper,  "
			lcCampos5="editableretper  compras.editableretper,  descuento  compras.descuento,  idvendedor  compras.idvendedor,  exento  compras.exento,  gravado  compras.gravado,  "
			lcCampos6="nosujeto  compras.nosujeto,  iva  compras.iva,  ivalote  compras.ivalote,  retencion  compras.retencion,  percepcion  compras.percepcion,  "
			lcCampos7="total  compras.total,  totallote  compras.totallote,  numcompret  compras.numcompret,  idsucursal  compras.idsucursal,  notas  compras.notas,  "
			lcCampos8="condicionpago  compras.condicionpago,  idcaja  compras.idcaja,  anulado  compras.anulado,  ctrol  compras.ctrol,  status  compras.status,  "
			lcCampos9="modulo  compras.modulo,  lote  compras.lote,  idautorizador  compras.idautorizador,  autorizarcredito  compras.autorizarcredito,  creditoautorizado  compras.creditoautorizado,  "
			lcCampos10="descuentoautorizado  compras.descuentoautorizado,  computadora  compras.computadora,  usuario  compras.usuario,  fechaalta  compras.fechaalta,renta compras.renta "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5+lcCampos6+lcCampos7+lcCampos8+lcCampos9+lcCampos10)
			 =CURSORSETPROP("KeyFieldList", "idventa")
			lcCamposb1="idventa,  idtipodocumento,  idserie,  numero,  fecha,  fechavencimiento,  idsocionegocio,  idequipo,  "
			lcCamposb2="clientefinal,  socionegocio,  direccion,  departamento,  municipio,  giro,  nit,  nrc,  "
			lcCamposb3="dui,  tipoiva,  tiporetper,  porcentajeretper,  editableretper,  descuento,  idvendedor,  exento,  "
			lcCamposb4="gravado,  nosujeto,  iva,  ivalote,  retencion,  percepcion,  total,  totallote,  "
			lcCamposb5="numcompret,  idsucursal,  notas,  condicionpago,  idcaja,  anulado,  ctrol,  status,  "
			lcCamposb6="modulo,  lote,  idautorizador,  autorizarcredito,  creditoautorizado,  descuentoautorizado,  computadora,  usuario,  "
			lcCamposb7="fechaalta,renta "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3+lcCamposb4+lcCamposb5+lcCamposb6+lcCamposb7)
			 =CURSORSETPROP("SendUpdates", .T.)
			
		CASE lcTabla=='comprasdetalle'			
			 =CURSORSETPROP("Tables",lcCursor)		
			lcCampos1="idventadetalle  comprasdetalle.idventadetalle,  idventa  comprasdetalle.idventa,  idproducto  comprasdetalle.idproducto,  descripcion  comprasdetalle.descripcion,  idmedida  comprasdetalle.idmedida,  "		
			lcCampos2="cantidadfactor  comprasdetalle.cantidadfactor,  preciofactor  comprasdetalle.preciofactor,  factor  comprasdetalle.factor,  cantidad  comprasdetalle.cantidad,  preciolista  comprasdetalle.preciolista,  "		
			lcCampos3="preciominimo comprasdetalle.preciominimo,preciominimotarjeta comprasdetalle.preciominimotarjeta,preciolote comprasdetalle.preciolote,porcentajedescuento comprasdetalle.porcentajedescuento,"		
			lcCampos4="descuentoventa  comprasdetalle.descuentoventa,  precionetofactor  comprasdetalle.precionetofactor,  precio  comprasdetalle.precio,  totalventanetalote  comprasdetalle.totalventanetalote,  totalventaneta  comprasdetalle.totalventaneta,  "		
			lcCampos5="totalivalote  comprasdetalle.totalivalote,  totaliva  comprasdetalle.totaliva,  costopromedio  comprasdetalle.costopromedio,  costopromediolote  comprasdetalle.costopromediolote,  entradasalida  comprasdetalle.entradasalida,  "		
			lcCampos6="notas  comprasdetalle.notas,  modulo  comprasdetalle.modulo,  idbodega  comprasdetalle.idbodega,  tipoiva  comprasdetalle.tipoiva,  poriva  comprasdetalle.poriva,porcentajedescuentocliente comprasdetalle.porcentajedescuentocliente, "		
			lcCampos7="tipoproducto  comprasdetalle.tipoproducto,  tiposerie  comprasdetalle.tiposerie,  idkit  comprasdetalle.idkit,  idagrupador  comprasdetalle.idagrupador,  autorizar  comprasdetalle.autorizar,  "		
			lcCampos8="idautorizador  comprasdetalle.idautorizador,  computadora  comprasdetalle.computadora,  usuario  comprasdetalle.usuario,  fechaalta  comprasdetalle.fechaalta,  iddetalleserie  comprasdetalle.iddetalleserie,  "		
			lcCampos9="cantidadkit  comprasdetalle.cantidadkit,  cantidadserie  comprasdetalle.cantidadserie,  preciofactorserie  comprasdetalle.preciofactorserie,codrenta comprasdetalle.codrenta,"
			lcCampos10="porcentajerenta comprasdetalle.porcentajerenta,totalrenta comprasdetalle.totalrenta " 
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5+lcCampos6+lcCampos7+lcCampos8+lcCampos9+lcCampos10)		
			 =CURSORSETPROP("KeyFieldList", "idventadetalle")		
			lcCamposb1="idventadetalle,  idventa,  idproducto,  descripcion,  idmedida,  cantidadfactor,  preciofactor,  factor,  "		
			lcCamposb2="cantidad,  preciolista,  preciominimo,  preciominimotarjeta,  preciolote,  porcentajedescuentocliente,  descuentoventa,  "		
			lcCamposb3="precionetofactor,  precio,  totalventanetalote,  totalventaneta,  totalivalote,  totaliva,  costopromedio,  costopromediolote,  "		
			lcCamposb4="entradasalida,  notas,  modulo,  idbodega,  tipoiva,  poriva,porcentajedescuento,  tipoproducto,  tiposerie,  "		
			lcCamposb5="idkit,  idagrupador,  autorizar,  idautorizador,  computadora,  usuario,  fechaalta,  iddetalleserie,  "		
			lcCamposb6="cantidadkit,  cantidadserie,  preciofactorserie,codrenta,porcentajerenta,totalrenta  "		
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3+lcCamposb4+lcCamposb5+lcCamposb6)		
			 =CURSORSETPROP("SendUpdates", .T.)		
					
		CASE lcTabla=='comprasdetalleserie'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idventadetalleserie  comprasdetalleserie.idventadetalleserie,  iddetalleserie  comprasdetalleserie.iddetalleserie,  idventa  comprasdetalleserie.idventa,  idproducto  comprasdetalleserie.idproducto,  idbodega  comprasdetalleserie.idbodega,  "
			lcCampos2="serie  comprasdetalleserie.serie,  idmedida  comprasdetalleserie.idmedida,  cantidadfactor  comprasdetalleserie.cantidadfactor,  factor  comprasdetalleserie.factor,  cantidad  comprasdetalleserie.cantidad,  "
			lcCampos3="entradasalida  comprasdetalleserie.entradasalida,  idtraspaso  comprasdetalleserie.idtraspaso,  costopromedio  comprasdetalleserie.costopromedio,  costopromediolote  comprasdetalleserie.costopromediolote,  precio  comprasdetalleserie.precio,  "
			lcCampos4="preciolote  comprasdetalleserie.preciolote,  poriva  comprasdetalleserie.poriva,  modulo  comprasdetalleserie.modulo,idlote comprasdetalleserie.idlote  "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4)
			 =CURSORSETPROP("KeyFieldList", "idventadetalleserie")
			lcCamposb1="idventadetalleserie,  iddetalleserie,  idventa,  idproducto,  idbodega,  serie,  idmedida,  cantidadfactor,  "
			lcCamposb2="factor,  cantidad,  entradasalida,  idtraspaso,  costopromedio,  costopromediolote,  precio,  preciolote,  "
			lcCamposb3="poriva,  modulo,idlote "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3)
			 =CURSORSETPROP("SendUpdates", .T.)
			

		CASE lcTabla=='movimientos'		
			 =CURSORSETPROP("Tables",lcCursor)	
			lcCampos1="idventa  movimientos.idventa,  idtipodocumento  movimientos.idtipodocumento,  idserie  movimientos.idserie,  numero  movimientos.numero,  fecha  movimientos.fecha,  "	
			lcCampos2="fechavencimiento  movimientos.fechavencimiento,  idsocionegocio  movimientos.idsocionegocio,  idequipo  movimientos.idequipo,  clientefinal  movimientos.clientefinal,  socionegocio  movimientos.socionegocio,  "	
			lcCampos3="direccion  movimientos.direccion,  departamento  movimientos.departamento,  municipio  movimientos.municipio,  giro  movimientos.giro,  nit  movimientos.nit,  "	
			lcCampos4="nrc  movimientos.nrc,  dui  movimientos.dui,  tipoiva  movimientos.tipoiva,  tiporetper  movimientos.tiporetper,  porcentajeretper  movimientos.porcentajeretper,  "	
			lcCampos5="editableretper  movimientos.editableretper,  descuento  movimientos.descuento,  idvendedor  movimientos.idvendedor,  exento  movimientos.exento,  gravado  movimientos.gravado,  "	
			lcCampos6="nosujeto  movimientos.nosujeto,  iva  movimientos.iva,  ivalote  movimientos.ivalote,  retencion  movimientos.retencion,  percepcion  movimientos.percepcion,  "	
			lcCampos7="total  movimientos.total,  totallote  movimientos.totallote,  numcompret  movimientos.numcompret,  idsucursal  movimientos.idsucursal,  notas  movimientos.notas,  "	
			lcCampos8="condicionpago  movimientos.condicionpago,  idcaja  movimientos.idcaja,  anulado  movimientos.anulado,  ctrol  movimientos.ctrol,  status  movimientos.status,  "	
			lcCampos9="modulo  movimientos.modulo,  lote  movimientos.lote,  idautorizador  movimientos.idautorizador,  autorizarcredito  movimientos.autorizarcredito,  creditoautorizado  movimientos.creditoautorizado,  "	
			lcCampos10="descuentoautorizado  movimientos.descuentoautorizado,  computadora  movimientos.computadora,  usuario  movimientos.usuario,  fechaalta  movimientos.fechaalta,idtraspaso movimientos.idtraspaso "	
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5+lcCampos6+lcCampos7+lcCampos8+lcCampos9+lcCampos10)	
			 =CURSORSETPROP("KeyFieldList", "idventa")	
			lcCamposb1="idventa,  idtipodocumento,  idserie,  numero,  fecha,  fechavencimiento,  idsocionegocio,  idequipo,  "	
			lcCamposb2="clientefinal,  socionegocio,  direccion,  departamento,  municipio,  giro,  nit,  nrc,  "	
			lcCamposb3="dui,  tipoiva,  tiporetper,  porcentajeretper,  editableretper,  descuento,  idvendedor,  exento,  "	
			lcCamposb4="gravado,  nosujeto,  iva,  ivalote,  retencion,  percepcion,  total,  totallote,  "	
			lcCamposb5="numcompret,  idsucursal,  notas,  condicionpago,  idcaja,  anulado,  ctrol,  status,  "	
			lcCamposb6="modulo,  lote,  idautorizador,  autorizarcredito,  creditoautorizado,  descuentoautorizado,  computadora,  usuario,  "	
			lcCamposb7="fechaalta,idtraspaso "	
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3+lcCamposb4+lcCamposb5+lcCamposb6+lcCamposb7)	
			 =CURSORSETPROP("SendUpdates", .T.)	

		CASE lcTabla=='movimientosdetalle'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idventadetalle  movimientosdetalle.idventadetalle,  idventa  movimientosdetalle.idventa,  idproducto  movimientosdetalle.idproducto,  descripcion  movimientosdetalle.descripcion,"
			lcCampos2="idmedida  movimientosdetalle.idmedida,cantidadfactor  movimientosdetalle.cantidadfactor,  preciofactor  movimientosdetalle.preciofactor,  factor  movimientosdetalle.factor,"
			lcCampos3="cantidad  movimientosdetalle.cantidad,  preciolista  movimientosdetalle.preciolista,preciominimo  movimientosdetalle.preciominimo,  preciominimotarjeta  movimientosdetalle.preciominimotarjeta,"
			lcCampos4="preciolote  movimientosdetalle.preciolote,  porcentajedescuento  movimientosdetalle.porcentajedescuento,porcentajedescuentocliente  movimientosdetalle.porcentajedescuentocliente,"
			lcCampos5="descuentoventa movimientosdetalle.descuentoventa,precionetofactor movimientosdetalle.precionetofactor,precio movimientosdetalle.precio,totalventanetalote movimientosdetalle.totalventanetalote,"
			lcCampos6="totalventaneta  movimientosdetalle.totalventaneta, totalivalote  movimientosdetalle.totalivalote,  totaliva  movimientosdetalle.totaliva, costopromedio  movimientosdetalle.costopromedio,"
			lcCampos7="costopromediolote  movimientosdetalle.costopromediolote,entradasalida movimientosdetalle.entradasalida,notas movimientosdetalle.notas,modulo movimientosdetalle.modulo,"
			lcCampos8="idbodega movimientosdetalle.idbodega,tipoiva movimientosdetalle.tipoiva,poriva movimientosdetalle.poriva,tipoproducto movimientosdetalle.tipoproducto,tiposerie movimientosdetalle.tiposerie,"
			lcCampos9="idkit movimientosdetalle.idkit, idagrupador  movimientosdetalle.idagrupador,  autorizar  movimientosdetalle.autorizar,  idautorizador  movimientosdetalle.idautorizador,"
			lcCampos10="computadora  movimientosdetalle.computadora,usuario  movimientosdetalle.usuario, fechaalta movimientosdetalle.fechaalta, iddetalleserie movimientosdetalle.iddetalleserie, "
			lcCampos11="cantidadkit movimientosdetalle.cantidadkit,cantidadserie movimientosdetalle.cantidadserie,preciofactorserie  movimientosdetalle.preciofactorserie, idtraspaso movimientosdetalle.idtraspaso"
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5+lcCampos6+lcCampos7+lcCampos8+lcCampos9+lcCampos10+lcCampos11)
			 =CURSORSETPROP("KeyFieldList", "idventadetalle")
			lcCamposb1="idventadetalle,  idventa,  idproducto,  descripcion,  idmedida,  cantidadfactor,  preciofactor,  factor,  "
			lcCamposb2="cantidad,  preciolista,  preciominimo,  preciominimotarjeta,  preciolote,  porcentajedescuento,  porcentajedescuentocliente,  descuentoventa,  "
			lcCamposb3="precionetofactor,  precio,  totalventanetalote,  totalventaneta,  totalivalote,  totaliva,  costopromedio,  costopromediolote,  "
			lcCamposb4="entradasalida,  notas,  modulo,  idbodega,  tipoiva,  poriva,  tipoproducto,  tiposerie,  "
			lcCamposb5="idkit,  idagrupador,  autorizar,  idautorizador,  computadora,  usuario,  fechaalta,  iddetalleserie,  "
			lcCamposb6="cantidadkit,  cantidadserie,  preciofactorserie,idtraspaso "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3+lcCamposb4+lcCamposb5+lcCamposb6)
			 =CURSORSETPROP("SendUpdates", .T.)
			

		CASE lcTabla=='movimientosdetalleserie'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idventadetalleserie  movimientosdetalleserie.idventadetalleserie,  iddetalleserie  movimientosdetalleserie.iddetalleserie,  idventa  movimientosdetalleserie.idventa,  idproducto  movimientosdetalleserie.idproducto,  "
			lcCampos2="idbodega  movimientosdetalleserie.idbodega, idmedida  movimientosdetalleserie.idmedida,  idtraspaso  movimientosdetalleserie.idtraspaso,  idlote  movimientosdetalleserie.idlote,  serie  movimientosdetalleserie.serie,"
			lcCampos3="cantidadfactor  movimientosdetalleserie.cantidadfactor,  factor  movimientosdetalleserie.factor,  cantidad  movimientosdetalleserie.cantidad,  entradasalida  movimientosdetalleserie.entradasalida,  "
			lcCampos4="costopromedio  movimientosdetalleserie.costopromedio,  costopromediolote  movimientosdetalleserie.costopromediolote,  precio  movimientosdetalleserie.precio,  preciolote  movimientosdetalleserie.preciolote,  "
			lcCampos5="poriva  movimientosdetalleserie.poriva,  modulo  movimientosdetalleserie.modulo "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5)
			 =CURSORSETPROP("KeyFieldList", "idventadetalleserie")
			lcCamposb1="idventadetalleserie,  iddetalleserie,  idventa,  idproducto,  idbodega,  idmedida,  idtraspaso,  idlote,  "
			lcCamposb2="serie,  cantidadfactor,  factor,  cantidad,  entradasalida,  costopromedio,  costopromediolote,  precio,  "
			lcCamposb3="preciolote,  poriva,  modulo "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3)
			 =CURSORSETPROP("SendUpdates", .T.)
			
		CASE lcTabla=='retaceos'		
			 =CURSORSETPROP("Tables",lcCursor)	
			lcCampos1="idventa  retaceos.idventa,  idtipodocumento  retaceos.idtipodocumento,  idserie  retaceos.idserie,  numero  retaceos.numero,  fecha  retaceos.fecha,  "	
			lcCampos2="fechavencimiento  retaceos.fechavencimiento,  idsocionegocio  retaceos.idsocionegocio,  idequipo  retaceos.idequipo,  clientefinal  retaceos.clientefinal,  socionegocio  retaceos.socionegocio,  "	
			lcCampos3="direccion  retaceos.direccion,  departamento  retaceos.departamento,  municipio  retaceos.municipio,  giro  retaceos.giro,  nit  retaceos.nit,  "	
			lcCampos4="nrc  retaceos.nrc,  dui  retaceos.dui,  tipoiva  retaceos.tipoiva,  tiporetper  retaceos.tiporetper,  porcentajeretper  retaceos.porcentajeretper,  "	
			lcCampos5="editableretper  retaceos.editableretper,  descuento  retaceos.descuento,  idvendedor  retaceos.idvendedor,  exento  retaceos.exento,  gravado  retaceos.gravado,  "	
			lcCampos6="nosujeto  retaceos.nosujeto,  iva  retaceos.iva,  ivalote  retaceos.ivalote,  retencion  retaceos.retencion,  percepcion  retaceos.percepcion,  "	
			lcCampos7="total  retaceos.total,  totallote  retaceos.totallote,  numcompret  retaceos.numcompret,  idsucursal  retaceos.idsucursal,  notas  retaceos.notas,  "	
			lcCampos8="condicionpago  retaceos.condicionpago,  idcaja  retaceos.idcaja,  anulado  retaceos.anulado,  ctrol  retaceos.ctrol,  status  retaceos.status,  "	
			lcCampos9="modulo  retaceos.modulo,  lote  retaceos.lote,  idautorizador  retaceos.idautorizador,  autorizarcredito  retaceos.autorizarcredito,  creditoautorizado  retaceos.creditoautorizado,  "	
			lcCampos10="descuentoautorizado  retaceos.descuentoautorizado,  computadora  retaceos.computadora,  usuario  retaceos.usuario,  fechaalta  retaceos.fechaalta  "	
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5+lcCampos6+lcCampos7+lcCampos8+lcCampos9+lcCampos10)	
			 =CURSORSETPROP("KeyFieldList", "idventa")	
			lcCamposb1="idventa,  idtipodocumento,  idserie,  numero,  fecha,  fechavencimiento,  idsocionegocio,  idequipo,  "	
			lcCamposb2="clientefinal,  socionegocio,  direccion,  departamento,  municipio,  giro,  nit,  nrc,  "	
			lcCamposb3="dui,  tipoiva,  tiporetper,  porcentajeretper,  editableretper,  descuento,  idvendedor,  exento,  "	
			lcCamposb4="gravado,  nosujeto,  iva,  ivalote,  retencion,  percepcion,  total,  totallote,  "	
			lcCamposb5="numcompret,  idsucursal,  notas,  condicionpago,  idcaja,  anulado,  ctrol,  status,  "	
			lcCamposb6="modulo,  lote,  idautorizador,  autorizarcredito,  creditoautorizado,  descuentoautorizado,  computadora,  usuario,  "	
			lcCamposb7="fechaalta "	
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3+lcCamposb4+lcCamposb5+lcCamposb6+lcCamposb7)	
			 =CURSORSETPROP("SendUpdates", .T.)	
				
		CASE lcTabla=='retaceosdetalle'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idventadetalle  retaceosdetalle.idventadetalle,  idventa  retaceosdetalle.idventa,  idproducto  retaceosdetalle.idproducto,  descripcion  retaceosdetalle.descripcion,  idmedida  retaceosdetalle.idmedida,  "
			lcCampos2="cantidadfactor  retaceosdetalle.cantidadfactor,  preciofactor  retaceosdetalle.preciofactor,  factor  retaceosdetalle.factor,  cantidad  retaceosdetalle.cantidad,  preciolista  retaceosdetalle.preciolista,  "
			lcCampos3="preciominimo  retaceosdetalle.preciominimo,  preciominimotarjeta  retaceosdetalle.preciominimotarjeta,  preciolote  retaceosdetalle.preciolote,  porcentajedescuento  retaceosdetalle.porcentajedescuento,   "
			lcCampos4="porcentajedescuentocliente  retaceosdetalle.porcentajedescuentocliente, descuentoventa  retaceosdetalle.descuentoventa,  precionetofactor  retaceosdetalle.precionetofactor,  precio  retaceosdetalle.precio,   "
			lcCampos5="totalventanetalote  retaceosdetalle.totalventanetalote,  totalventaneta  retaceosdetalle.totalventaneta, totalivalote  retaceosdetalle.totalivalote,  totaliva  retaceosdetalle.totaliva,   "
			lcCampos6="costopromedio  retaceosdetalle.costopromedio,  costopromediolote  retaceosdetalle.costopromediolote,  entradasalida  retaceosdetalle.entradasalida, notas  retaceosdetalle.notas,  modulo  retaceosdetalle.modulo, "
			lcCampos7="idbodega  retaceosdetalle.idbodega,  tipoiva  retaceosdetalle.tipoiva,  poriva  retaceosdetalle.poriva, tipoproducto  retaceosdetalle.tipoproducto,  tiposerie  retaceosdetalle.tiposerie,  idkit  retaceosdetalle.idkit,   "
			lcCampos8="idagrupador  retaceosdetalle.idagrupador,  autorizar  retaceosdetalle.autorizar, idautorizador  retaceosdetalle.idautorizador,  computadora  retaceosdetalle.computadora,  usuario  retaceosdetalle.usuario,  "
			lcCampos9="fechaalta  retaceosdetalle.fechaalta,  iddetalleserie  retaceosdetalle.iddetalleserie, cantidadkit  retaceosdetalle.cantidadkit,  cantidadserie  retaceosdetalle.cantidadserie,  preciofactorserie  retaceosdetalle.preciofactorserie "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5+lcCampos6+lcCampos7+lcCampos8+lcCampos9)
			 =CURSORSETPROP("KeyFieldList", "idventa")
			lcCamposb1="idventadetalle,  idventa,  idproducto,  descripcion,  idmedida,  cantidadfactor,  preciofactor,  factor,  "
			lcCamposb2="cantidad,  preciolista,  preciominimo,  preciominimotarjeta,  preciolote,  porcentajedescuento,  porcentajedescuentocliente,  descuentoventa,  "
			lcCamposb3="precionetofactor,  precio,  totalventanetalote,  totalventaneta,  totalivalote,  totaliva,  costopromedio,  costopromediolote,  "
			lcCamposb4="entradasalida,  notas,  modulo,  idbodega,  tipoiva,  poriva,  tipoproducto,  tiposerie,  "
			lcCamposb5="idkit,  idagrupador,  autorizar,  idautorizador,  computadora,  usuario,  fechaalta,  iddetalleserie,  "
			lcCamposb6="cantidadkit,  cantidadserie,  preciofactorserie "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3+lcCamposb4+lcCamposb5+lcCamposb6)
			 =CURSORSETPROP("SendUpdates", .T.)
			
		CASE lcTabla=='retaceosdetalleserie'		
			 =CURSORSETPROP("Tables",lcCursor)	
			lcCampos1="idventadetalleserie retaceosdetalleserie.idventadetalleserie, iddetalleserie retaceosdetalleserie.iddetalleserie,idventa retaceosdetalleserie.idventa,idproducto retaceosdetalleserie.idproducto,idbodega retaceosdetalleserie.idbodega,"	
			lcCampos2="idmedida  retaceosdetalleserie.idmedida,  idtraspaso  retaceosdetalleserie.idtraspaso,  idlote  retaceosdetalleserie.idlote,  serie  retaceosdetalleserie.serie,  cantidadfactor  retaceosdetalleserie.cantidadfactor,  "	
			lcCampos3="factor retaceosdetalleserie.factor,cantidad retaceosdetalleserie.cantidad,entradasalida retaceosdetalleserie.entradasalida,costopromedio retaceosdetalleserie.costopromedio,costopromediolote retaceosdetalleserie.costopromediolote,"	
			lcCampos4="precio  retaceosdetalleserie.precio,  preciolote  retaceosdetalleserie.preciolote,  poriva  retaceosdetalleserie.poriva,  modulo  retaceosdetalleserie.modulo "	
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4)	
			 =CURSORSETPROP("KeyFieldList", "idventa")	
			lcCamposb1="idventadetalleserie,  iddetalleserie,  idventa,  idproducto,  idbodega,  idmedida,  idtraspaso,  idlote,  "	
			lcCamposb2="serie,  cantidadfactor,  factor,  cantidad,  entradasalida,  costopromedio,  costopromediolote,  precio,  "	
			lcCamposb3="preciolote,  poriva,  modulo "	
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3)	
			 =CURSORSETPROP("SendUpdates", .T.)	

		CASE lcTabla=='retaceos2detalle'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idventadetalle  retaceos2detalle.idventadetalle,  idventa  retaceos2detalle.idventa,  idproducto  retaceos2detalle.idproducto,  descripcion  retaceos2detalle.descripcion,  idmedida  retaceos2detalle.idmedida,  "
			lcCampos2="cantidadfactor  retaceos2detalle.cantidadfactor,  preciofactor  retaceos2detalle.preciofactor,  factor  retaceos2detalle.factor,  cantidad  retaceos2detalle.cantidad,  preciolista  retaceos2detalle.preciolista,  "
			lcCampos3="preciominimo  retaceos2detalle.preciominimo,  preciominimotarjeta  retaceos2detalle.preciominimotarjeta,  preciolote  retaceos2detalle.preciolote,  porcentajedescuento  retaceos2detalle.porcentajedescuento,"
			lcCampos4="porcentajedescuentocliente  retaceos2detalle.porcentajedescuentocliente,descuentoventa  retaceos2detalle.descuentoventa,  precionetofactor  retaceos2detalle.precionetofactor,  precio  retaceos2detalle.precio,"
			lcCampos5="totalventanetalote  retaceos2detalle.totalventanetalote,  totalventaneta  retaceos2detalle.totalventaneta, totalivalote  retaceos2detalle.totalivalote,  totaliva  retaceos2detalle.totaliva, "
			lcCampos6="costopromedio  retaceos2detalle.costopromedio,  costopromediolote  retaceos2detalle.costopromediolote,  entradasalida  retaceos2detalle.entradasalida, notas  retaceos2detalle.notas, "
			lcCampos7="modulo  retaceos2detalle.modulo,  idbodega  retaceos2detalle.idbodega,  tipoiva  retaceos2detalle.tipoiva,  poriva  retaceos2detalle.poriva, tipoproducto  retaceos2detalle.tipoproducto,    "
			lcCampos8="tiposerie  retaceos2detalle.tiposerie,  idkit  retaceos2detalle.idkit,  idagrupador  retaceos2detalle.idagrupador,  autorizar  retaceos2detalle.autorizar,idautorizador  retaceos2detalle.idautorizador,  "
			lcCampos9="computadora  retaceos2detalle.computadora,  usuario  retaceos2detalle.usuario,  fechaalta  retaceos2detalle.fechaalta,  iddetalleserie  retaceos2detalle.iddetalleserie, cantidadkit  retaceos2detalle.cantidadkit, "
			lcCampos10="cantidadserie retaceos2detalle.cantidadserie,preciofactorserie retaceos2detalle.preciofactorserie,codrenta retaceos2detalle.codrenta,porcentajerenta retaceos2detalle.porcentajerenta,totalrenta retaceos2detalle.totalrenta"
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5+lcCampos6+lcCampos7+lcCampos8+lcCampos9+lcCampos10)
			 =CURSORSETPROP("KeyFieldList", "idventadetalle")
			lcCamposb1="idventadetalle,  idventa,  idproducto,  descripcion,  idmedida,  cantidadfactor,  preciofactor,  factor,  "
			lcCamposb2="cantidad,  preciolista,  preciominimo,  preciominimotarjeta,  preciolote,  porcentajedescuento,  porcentajedescuentocliente,  descuentoventa,  "
			lcCamposb3="precionetofactor,  precio,  totalventanetalote,  totalventaneta,  totalivalote,  totaliva,  costopromedio,  costopromediolote,  "
			lcCamposb4="entradasalida,  notas,  modulo,  idbodega,  tipoiva,  poriva,  tipoproducto,  tiposerie,  "
			lcCamposb5="idkit,  idagrupador,  autorizar,  idautorizador,  computadora,  usuario,  fechaalta,  iddetalleserie,  "
			lcCamposb6="cantidadkit,  cantidadserie,  preciofactorserie,  codrenta,  porcentajerenta,  totalrenta "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3+lcCamposb4+lcCamposb5+lcCamposb6)
			 =CURSORSETPROP("SendUpdates", .T.)
			

	
		CASE lcTabla=='ctb_cuentas'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idcuenta  ctb_cuentas.idcuenta,  codcuenta  ctb_cuentas.codcuenta,  cuenta  ctb_cuentas.cuenta,  nivel  ctb_cuentas.nivel,  detalle  ctb_cuentas.detalle,  "
			lcCampos2="idtipocuenta  ctb_cuentas.idtipocuenta,  idpadre  ctb_cuentas.idpadre,  saldo  ctb_cuentas.saldo,  status  ctb_cuentas.status,  fechasistema  ctb_cuentas.fechasistema,  "
			lcCampos3="idusuario  ctb_cuentas.idusuario "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3)
			 =CURSORSETPROP("KeyFieldList", "idcuenta")
			lcCamposb1="idcuenta,  codcuenta,  cuenta,  nivel,  detalle,  idtipocuenta,  idpadre,  saldo,  "
			lcCamposb2="status,  fechasistema,  idusuario  "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2)
			 =CURSORSETPROP("SendUpdates", .T.)
			
		CASE lcTabla=='ctb_partidas'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idpartida  ctb_partidas.idpartida,  idtipopartida  ctb_partidas.idtipopartida,  fecha  ctb_partidas.fecha,  numero  ctb_partidas.numero,  concepto  ctb_partidas.concepto,  "
			lcCampos2="cargos  ctb_partidas.cargos,  abonos  ctb_partidas.abonos,  idrevisado  ctb_partidas.idrevisado,  Idauditado  ctb_partidas.Idauditado,  fechasistema  ctb_partidas.fechasistema,  "
			lcCampos3="periodo  ctb_partidas.periodo,  modulo  ctb_partidas.modulo,  anulado  ctb_partidas.anulado,  idreferencia  ctb_partidas.idreferencia "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3)
			 =CURSORSETPROP("KeyFieldList", "idpartida")
			lcCamposb1="idpartida,  idtipopartida,  fecha,  numero,  concepto,  cargos,  abonos,  idrevisado,  "
			lcCamposb2="Idauditado,  fechasistema,  periodo,  modulo,  anulado,  idreferencia "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2)
			 =CURSORSETPROP("SendUpdates", .T.)
			
		CASE lcTabla=='ctb_partidasdetalle'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idpartidadetalle  ctb_partidasdetalle.idpartidadetalle,  idpartida  ctb_partidasdetalle.idpartida,  idcuenta  ctb_partidasdetalle.idcuenta,  periodo  ctb_partidasdetalle.periodo,  concepto  ctb_partidasdetalle.concepto,  "
			lcCampos2="cargo  ctb_partidasdetalle.cargo,  abono  ctb_partidasdetalle.abono,  anulado  ctb_partidasdetalle.anulado,  idreferenciadetalle  ctb_partidasdetalle.idreferenciadetalle "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2)
			 =CURSORSETPROP("KeyFieldList", "idpartidadetalle")
			lcCamposb1="idpartidadetalle,  idpartida,  idcuenta,  periodo,  concepto,  cargo,  abono,  anulado,  "
			lcCamposb2="idreferenciadetalle  "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2)
			 =CURSORSETPROP("SendUpdates", .T.)
			

		CASE lcTabla=='produccion'		
			 =CURSORSETPROP("Tables",lcCursor)	
			lcCampos1="idventa  produccion.idventa,  idtipodocumento  produccion.idtipodocumento,  idserie  produccion.idserie,  numero  produccion.numero,  fecha  produccion.fecha,  "	
			lcCampos2="fechavencimiento produccion.fechavencimiento,idsocionegocio produccion.idsocionegocio,idequipo produccion.idequipo,clientefinal produccion.clientefinal,socionegocio produccion.socionegocio,"	
			lcCampos3="direccion  produccion.direccion,  departamento  produccion.departamento,  municipio  produccion.municipio,  giro  produccion.giro,  nit  produccion.nit,  "	
			lcCampos4="nrc  produccion.nrc,  dui  produccion.dui,  tipoiva  produccion.tipoiva,  tiporetper  produccion.tiporetper,  porcentajeretper  produccion.porcentajeretper,  "	
			lcCampos5="editableretper  produccion.editableretper,  descuento  produccion.descuento,  idvendedor  produccion.idvendedor,  exento  produccion.exento,  gravado  produccion.gravado,  "	
			lcCampos6="nosujeto  produccion.nosujeto,  iva  produccion.iva,  ivalote  produccion.ivalote,  retencion  produccion.retencion,  percepcion  produccion.percepcion,  "	
			lcCampos7="total  produccion.total,  totallote  produccion.totallote,  numcompret  produccion.numcompret,  idsucursal  produccion.idsucursal,  notas  produccion.notas,  "	
			lcCampos8="condicionpago  produccion.condicionpago,  idcaja  produccion.idcaja,  anulado  produccion.anulado,  ctrol  produccion.ctrol,  status  produccion.status,  "	
			lcCampos9="modulo  produccion.modulo,  lote  produccion.lote,  idautorizador  produccion.idautorizador,  autorizarcredito  produccion.autorizarcredito,  creditoautorizado  produccion.creditoautorizado,  "	
			lcCampos10="descuentoautorizado  produccion.descuentoautorizado,  computadora  produccion.computadora,  usuario  produccion.usuario,  fechaalta  produccion.fechaalta,  idtraspaso  produccion.idtraspaso  "	
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5+lcCampos6+lcCampos7+lcCampos8+lcCampos9+lcCampos10)	
			 =CURSORSETPROP("KeyFieldList", "idventa")	
			lcCamposb1="idventa,  idtipodocumento,  idserie,  numero,  fecha,  fechavencimiento,  idsocionegocio,  idequipo,  "	
			lcCamposb2="clientefinal,  socionegocio,  direccion,  departamento,  municipio,  giro,  nit,  nrc,  "	
			lcCamposb3="dui,  tipoiva,  tiporetper,  porcentajeretper,  editableretper,  descuento,  idvendedor,  exento,  "	
			lcCamposb4="gravado,  nosujeto,  iva,  ivalote,  retencion,  percepcion,  total,  totallote,  "	
			lcCamposb5="numcompret,  idsucursal,  notas,  condicionpago,  idcaja,  anulado,  ctrol,  status,  "	
			lcCamposb6="modulo,  lote,  idautorizador,  autorizarcredito,  creditoautorizado,  descuentoautorizado,  computadora,  usuario,  "	
			lcCamposb7="fechaalta,  idtraspaso "	
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3+lcCamposb4+lcCamposb5+lcCamposb6+lcCamposb7)	
			 =CURSORSETPROP("SendUpdates", .T.)	
				
		CASE lcTabla=='produccion2detalle'			
			 =CURSORSETPROP("Tables",lcCursor)		
			lcCampos1="idventadetalle  produccion2detalle.idventadetalle,  idventa  produccion2detalle.idventa,  idproducto  produccion2detalle.idproducto,  descripcion  produccion2detalle.descripcion, "		
			lcCampos2="idmedida  produccion2detalle.idmedida,cantidadfactor  produccion2detalle.cantidadfactor,  preciofactor  produccion2detalle.preciofactor,  factor  produccion2detalle.factor, "		
			lcCampos3="cantidad  produccion2detalle.cantidad,  preciolista  produccion2detalle.preciolista,preciominimo  produccion2detalle.preciominimo,  preciominimotarjeta  produccion2detalle.preciominimotarjeta, "		
			lcCampos4="preciolote  produccion2detalle.preciolote,  porcentajedescuento  produccion2detalle.porcentajedescuento,  porcentajedescuentocliente  produccion2detalle.porcentajedescuentocliente,   "		
			lcCampos5="descuentoventa  produccion2detalle.descuentoventa,  precionetofactor  produccion2detalle.precionetofactor,precio produccion2detalle.precio,totalventanetalote produccion2detalle.totalventanetalote,"		
			lcCampos6="totalventaneta  produccion2detalle.totalventaneta,totalivalote produccion2detalle.totalivalote, totaliva produccion2detalle.totaliva,costopromedio  produccion2detalle.costopromedio,   "		
			lcCampos7="costopromediolote  produccion2detalle.costopromediolote,entradasalida produccion2detalle.entradasalida,notas produccion2detalle.notas,modulo produccion2detalle.modulo,idbodega produccion2detalle.idbodega,"
			lcCampos8="tipoiva  produccion2detalle.tipoiva,  poriva  produccion2detalle.poriva,tipoproducto  produccion2detalle.tipoproducto,  tiposerie  produccion2detalle.tiposerie,  idkit  produccion2detalle.idkit,"		
			lcCampos9="idagrupador produccion2detalle.idagrupador,autorizar produccion2detalle.autorizar,idautorizador produccion2detalle.idautorizador,computadora produccion2detalle.computadora,usuario produccion2detalle.usuario,"	
			lcCampos10="fechaalta  produccion2detalle.fechaalta,  iddetalleserie  produccion2detalle.iddetalleserie,cantidadkit  produccion2detalle.cantidadkit,  cantidadserie  produccion2detalle.cantidadserie, "
			lcCampos11="preciofactorserie  produccion2detalle.preciofactorserie,  idtraspaso  produccion2detalle.idtraspaso"
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5+lcCampos6+lcCampos7+lcCampos8+lcCampos9+lcCampos10+lcCampos11)
			 =CURSORSETPROP("KeyFieldList", "idventadetalle")		
			lcCamposb1="idventadetalle,  idventa,  idproducto,  descripcion,  idmedida,  cantidadfactor,  preciofactor,  factor,  "		
			lcCamposb2="cantidad,  preciolista,  preciominimo,  preciominimotarjeta,  preciolote,  porcentajedescuento,  porcentajedescuentocliente,  descuentoventa,  "		
			lcCamposb3="precionetofactor,  precio,  totalventanetalote,  totalventaneta,  totalivalote,  totaliva,  costopromedio,  costopromediolote,  "		
			lcCamposb4="entradasalida,  notas,  modulo,  idbodega,  tipoiva,  poriva,  tipoproducto,  tiposerie,  "		
			lcCamposb5="idkit,  idagrupador,  autorizar,  idautorizador,  computadora,  usuario,  fechaalta,  iddetalleserie,  "		
			lcCamposb6="cantidadkit,  cantidadserie,  preciofactorserie,  idtraspaso  "		
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3+lcCamposb4+lcCamposb5+lcCamposb6)		
			 =CURSORSETPROP("SendUpdates", .T.)		
					
		CASE lcTabla=='produccion2detalleserie'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idventadetalleserie produccion2detalleserie.idventadetalleserie,iddetalleserie produccion2detalleserie.iddetalleserie,idventa produccion2detalleserie.idventa, idproducto produccion2detalleserie.idproducto,"
			lcCampos2="idbodega  produccion2detalleserie.idbodega,idmedida  produccion2detalleserie.idmedida,idtraspaso produccion2detalleserie.idtraspaso,idlote  produccion2detalleserie.idlote,serie produccion2detalleserie.serie,"
			lcCampos3="cantidadfactor  produccion2detalleserie.cantidadfactor,factor  produccion2detalleserie.factor,  cantidad  produccion2detalleserie.cantidad,  entradasalida  produccion2detalleserie.entradasalida,   "
			lcCampos4="costopromedio  produccion2detalleserie.costopromedio,  costopromediolote  produccion2detalleserie.costopromediolote,precio  produccion2detalleserie.precio,  preciolote  produccion2detalleserie.preciolote, "
			lcCampos5="poriva  produccion2detalleserie.poriva,  modulo  produccion2detalleserie.modulo"
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5)
			 =CURSORSETPROP("KeyFieldList", "idventadetalleserie")
			lcCamposb1="idventadetalleserie,  iddetalleserie,  idventa,  idproducto,  idbodega,  idmedida,  idtraspaso,  idlote,  "
			lcCamposb2="serie,  cantidadfactor,  factor,  cantidad,  entradasalida,  costopromedio,  costopromediolote,  precio,  "
			lcCamposb3="preciolote,  poriva,  modulo "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3)
			 =CURSORSETPROP("SendUpdates", .T.)
			
		CASE lcTabla=='producciondetalle'	
			 =CURSORSETPROP("Tables",lcCursor)
			lcCampos1="idventadetalle  producciondetalle.idventadetalle,  idventa  producciondetalle.idventa,  idproducto  producciondetalle.idproducto,  descripcion  producciondetalle.descripcion,  idmedida  producciondetalle.idmedida,  "
			lcCampos2="cantidadfactor  producciondetalle.cantidadfactor,  preciofactor  producciondetalle.preciofactor,  factor  producciondetalle.factor,  cantidad  producciondetalle.cantidad,  preciolista  producciondetalle.preciolista, "
			lcCampos3="preciominimo  producciondetalle.preciominimo,  preciominimotarjeta  producciondetalle.preciominimotarjeta,  preciolote  producciondetalle.preciolote,  porcentajedescuento  producciondetalle.porcentajedescuento,  "
			lcCampos4=" porcentajedescuentocliente  producciondetalle.porcentajedescuentocliente, descuentoventa  producciondetalle.descuentoventa,  precionetofactor  producciondetalle.precionetofactor,  precio  producciondetalle.precio, "
			lcCampos5="totalventanetalote  producciondetalle.totalventanetalote,  totalventaneta  producciondetalle.totalventaneta,totalivalote  producciondetalle.totalivalote,  totaliva  producciondetalle.totaliva, "
			lcCampos6="costopromedio  producciondetalle.costopromedio,costopromediolote producciondetalle.costopromediolote, entradasalida  producciondetalle.entradasalida, notas  producciondetalle.notas,  modulo  producciondetalle.modulo,"
			lcCampos7="idbodega  producciondetalle.idbodega,  tipoiva producciondetalle.tipoiva,poriva producciondetalle.poriva,tipoproducto producciondetalle.tipoproducto,tiposerie producciondetalle.tiposerie,idkit producciondetalle.idkit,"
			lcCampos8=" idagrupador  producciondetalle.idagrupador,  autorizar  producciondetalle.autorizar, idautorizador  producciondetalle.idautorizador,  computadora  producciondetalle.computadora,  usuario  producciondetalle.usuario,"
			lcCampos9="fechaalta  producciondetalle.fechaalta,  iddetalleserie  producciondetalle.iddetalleserie,cantidadkit  producciondetalle.cantidadkit,  cantidadserie  producciondetalle.cantidadserie, "
			lcCampos10="preciofactorserie  producciondetalle.preciofactorserie,  idtraspaso  producciondetalle.idtraspaso  "
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5+lcCampos6+lcCampos7+lcCampos8+lcCampos9+lcCampos10)
			 =CURSORSETPROP("KeyFieldList", "idventadetalle")
			lcCamposb1="idventadetalle,  idventa,  idproducto,  descripcion,  idmedida,  cantidadfactor,  preciofactor,  factor,  "
			lcCamposb2="cantidad,  preciolista,  preciominimo,  preciominimotarjeta,  preciolote,  porcentajedescuento,  porcentajedescuentocliente,  descuentoventa,  "
			lcCamposb3="precionetofactor,  precio,  totalventanetalote,  totalventaneta,  totalivalote,  totaliva,  costopromedio,  costopromediolote,  "
			lcCamposb4="entradasalida,  notas,  modulo,  idbodega,  tipoiva,  poriva,  tipoproducto,  tiposerie,  "
			lcCamposb5="idkit,  idagrupador,  autorizar,  idautorizador,  computadora,  usuario,  fechaalta,  iddetalleserie,  "
			lcCamposb6="cantidadkit,  cantidadserie,  preciofactorserie,  idtraspaso "
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3+lcCamposb4+lcCamposb5+lcCamposb6)
			 =CURSORSETPROP("SendUpdates", .T.)

		CASE lcTabla=='producciondetalleserie'				
			 =CURSORSETPROP("Tables",lcCursor)			
			lcCampos1="idventadetalleserie  producciondetalleserie.idventadetalleserie,  iddetalleserie  producciondetalleserie.iddetalleserie,  idventa  producciondetalleserie.idventa,  idproducto  producciondetalleserie.idproducto, "			
			lcCampos2="idbodega  producciondetalleserie.idbodega,idmedida  producciondetalleserie.idmedida,  idtraspaso  producciondetalleserie.idtraspaso,  idlote  producciondetalleserie.idlote,  serie  producciondetalleserie.serie, "			
			lcCampos3="cantidadfactor  producciondetalleserie.cantidadfactor,factor  producciondetalleserie.factor,  cantidad  producciondetalleserie.cantidad,  entradasalida  producciondetalleserie.entradasalida, "			
			lcCampos4="costopromedio  producciondetalleserie.costopromedio,  costopromediolote  producciondetalleserie.costopromediolote,precio  producciondetalleserie.precio,  preciolote  producciondetalleserie.preciolote, "			
			lcCampos5="poriva  producciondetalleserie.poriva,  modulo  producciondetalleserie.modulo"
			 =CURSORSETPROP("UpdateNameList",lcCampos1+lcCampos2+lcCampos3+lcCampos4+lcCampos5)
			 =CURSORSETPROP("KeyFieldList", "idventadetalleserie")			
			lcCamposb1="idventadetalleserie,  iddetalleserie,  idventa,  idproducto,  idbodega,  idmedida,  idtraspaso,  idlote,  "			
			lcCamposb2="serie,  cantidadfactor,  factor,  cantidad,  entradasalida,  costopromedio,  costopromediolote,  precio,  "			
			lcCamposb3="preciolote,  poriva,  modulo "			
			 =CURSORSETPROP("UpdatableFieldList", lcCamposb1+lcCamposb2+lcCamposb3)			
			 =CURSORSETPROP("SendUpdates", .T.)			
	ENDCASE 
ENDFUNC 


* Funciones comunes para integrar SIGA ERP con SIGA Documentos.
* Integradas en varios2.prg: esta es la biblioteca cargada por principal.prg.

* Registra de forma durable un documento para que SIGA Bridge lo publique.
* Primero escribe un temporal: el servicio nunca puede leer un evento parcial.
*
* Uso:
*   llEncolado = EncolarSigaDocumento("VTA", cyvventas.iddocto)
FUNCTION EncolarSigaDocumento
    LPARAMETERS tcOrigen, tnIdDocumento, tcPdfPath

    LOCAL lcOrigen, lcModulo, lcCarpeta, lcNombre, lcTemporal, lcDestino
    LOCAL lcCompletado, lcJson, lcMomento, lcPdfJson, llOk, loError

    llOk = .F.

    IF TYPE("pnUsaSigaDocumentos") <> "N"
        RETURN .F.
    ENDIF
    IF pnUsaSigaDocumentos <> 1
        RETURN .F.
    ENDIF
    IF VARTYPE(tnIdDocumento) <> "N" OR tnIdDocumento <= 0
        RETURN .F.
    ENDIF

    lcOrigen = UPPER(ALLTRIM(EVL(tcOrigen, "")))
    DO CASE
    CASE INLIST(lcOrigen, "VTA", "VENTAS")
        lcModulo = "ventas"
    CASE INLIST(lcOrigen, "COM", "COMPRAS")
        lcModulo = "compras"
    CASE INLIST(lcOrigen, "CYB", "BANCOS")
        lcModulo = "bancos"
    CASE INLIST(lcOrigen, "CTB", "PARTIDAS")
        lcModulo = "partidas"
    OTHERWISE
        RETURN .F.
    ENDCASE

    lcCarpeta = ADDBS(pcSysDir + pcDB) + "SigaDocumentosPendientes"
    lcNombre = lcModulo + "-" + ALLTRIM(STR(INT(tnIdDocumento))) + ".json"
    lcDestino = ADDBS(lcCarpeta) + lcNombre
    lcCompletado = lcDestino + ".done"

    * Un evento pendiente o completado representa la misma publicacion.
    IF FILE(lcDestino) OR FILE(lcCompletado)
        RETURN .T.
    ENDIF

    lcTemporal = ADDBS(lcCarpeta) + lcNombre + "." + SYS(2015) + ".tmp"

    TRY
        IF !DIRECTORY(lcCarpeta)
            MD (lcCarpeta)
        ENDIF

        lcMomento = TTOC(DATETIME(), 3)
        lcPdfJson = ""
        IF VARTYPE(tcPdfPath) = "C" AND !EMPTY(ALLTRIM(tcPdfPath))
            lcPdfJson = ',"pdfPath":"' + ;
                STRTRAN(STRTRAN(ALLTRIM(tcPdfPath), "\", "\\"), '"', '\"') + '"'
        ENDIF
        lcJson = '{"schemaVersion":1,"module":"' + lcModulo + ;
            '","idDocto":' + ALLTRIM(STR(INT(tnIdDocumento))) + ;
            ',"queuedAt":"' + lcMomento + '"' + lcPdfJson + '}'

        IF STRTOFILE(lcJson, lcTemporal, 0) <> LEN(lcJson)
            ERROR "No se pudo escribir completo el evento documental."
        ENDIF

        * Otra instancia pudo encolar el mismo documento mientras se escribia.
        IF FILE(lcDestino) OR FILE(lcCompletado)
            DELETE FILE (lcTemporal)
            RETURN .T.
        ENDIF

        RENAME (lcTemporal) TO (lcDestino)
        llOk = FILE(lcDestino)
    CATCH TO loError
        IF FILE(lcTemporal)
            DELETE FILE (lcTemporal)
        ENDIF
        WAIT WINDOW "No se pudo poner el documento en cola: " + ;
            loError.Message TIMEOUT 4
        llOk = .F.
    ENDTRY

    RETURN llOk
ENDFUNC


FUNCTION AdjuntarArchivoSigaDocumentos
    LPARAMETERS tcOrigen, tnIdDocumento, tnIdCliPro, tcArchivo, tcNaturaleza, tcTitulo

    LOCAL lcOrigen, lcModulo, lcNaturaleza, lcTitulo, lcArchivoOrigen
    LOCAL lcExtension, lcCarpeta, lcArchivoCola, lcEvento, lcTemporal
    LOCAL lcJson, lcIdDoc, lcAliasAnterior, laArchivo[1], lnTamano, loError

    lcArchivoCola = ""
    lcEvento = ""
    lcTemporal = ""

    IF TYPE("pnUsaSigaDocumentos") <> "N"
        RETURN .F.
    ENDIF
    IF pnUsaSigaDocumentos <> 1 OR VARTYPE(tnIdDocumento) <> "N" OR ;
            tnIdDocumento <= 0
        RETURN .F.
    ENDIF

    lcArchivoOrigen = ALLTRIM(EVL(tcArchivo, ""))
    IF EMPTY(lcArchivoOrigen) OR !FILE(lcArchivoOrigen)
        MESSAGEBOX("No se encontro el archivo seleccionado.", 48, ;
            "SIGA Documentos")
        RETURN .F.
    ENDIF
    lcExtension = LOWER(JUSTEXT(lcArchivoOrigen))
    IF !INLIST(lcExtension, "pdf", "png", "jpg", "jpeg", "webp", "heic", "heif")
        MESSAGEBOX("Puede adjuntar PDF, PNG, JPG, JPEG, WebP, HEIC o HEIF.", ;
            48, "SIGA Documentos")
        RETURN .F.
    ENDIF
    lnTamano = 0
    IF ADIR(laArchivo, lcArchivoOrigen) > 0
        lnTamano = laArchivo[1, 2]
    ENDIF
    IF lnTamano <= 0 OR lnTamano > (15 * 1024 * 1024)
        MESSAGEBOX("El archivo debe tener contenido y no superar 15 MB.", 48, ;
            "SIGA Documentos")
        RETURN .F.
    ENDIF

    lcOrigen = UPPER(ALLTRIM(EVL(tcOrigen, "")))
    DO CASE
    CASE INLIST(lcOrigen, "VTA", "VENTA", "VENTAS")
        lcOrigen = "VTA"
        lcModulo = "ventas"
    CASE INLIST(lcOrigen, "COM", "CMP", "COMPRA", "COMPRAS")
        lcOrigen = "COM"
        lcModulo = "compras"
    CASE INLIST(lcOrigen, "CYB", "BANCO", "BANCOS")
        lcOrigen = "CYB"
        lcModulo = "bancos"
    CASE INLIST(lcOrigen, "CTB", "PARTIDA", "PARTIDAS")
        lcOrigen = "CTB"
        lcModulo = "partidas"
    OTHERWISE
        MESSAGEBOX("El origen no admite archivos adjuntos.", 48, ;
            "SIGA Documentos")
        RETURN .F.
    ENDCASE

    lcNaturaleza = UPPER(ALLTRIM(EVL(tcNaturaleza, "SOPORTE")))
    IF !INLIST(lcNaturaleza, "PRINCIPAL", "SOPORTE", "ANEXO", "COMPLEMENTARIO")
        lcNaturaleza = "SOPORTE"
    ENDIF
    lcTitulo = LEFT(ALLTRIM(EVL(tcTitulo, JUSTSTEM(lcArchivoOrigen))), 160)
    IF EMPTY(lcTitulo)
        lcTitulo = JUSTSTEM(lcArchivoOrigen)
    ENDIF
    lcIdDoc = ""
    lcAliasAnterior = ALIAS()
    llOk = .F.

    TRY
        IF USED("sdFileVinc")
            USE IN sdFileVinc
        ENDIF
        USE (ADDBS(pcSysDir + pcDB) + "sisVinculos.dbf") IN 0 SHARED AGAIN ALIAS sdFileVinc
        SELECT sdFileVinc
        LOCATE FOR iddocto = tnIdDocumento AND ;
            UPPER(ALLTRIM(origen)) == lcOrigen AND activo AND !EMPTY(ALLTRIM(iddoc))
        IF FOUND()
            lcIdDoc = ALLTRIM(sdFileVinc.iddoc)
        ELSE
            * El adjunto queda esperando al documento principal sin perderse.
            lcIdDoc = ""
            =EncolarSigaDocumento(lcOrigen, tnIdDocumento)
        ENDIF
        USE IN sdFileVinc

        lcCarpeta = ADDBS(pcSysDir + pcDB) + "SigaDocumentosPendientes"
        IF !DIRECTORY(lcCarpeta)
            MD (lcCarpeta)
        ENDIF
        lcCarpeta = ADDBS(lcCarpeta) + "Archivos"
        IF !DIRECTORY(lcCarpeta)
            MD (lcCarpeta)
        ENDIF
        lcArchivoCola = ADDBS(lcCarpeta) + "archivo-" + SYS(2015) + "." + lcExtension
        COPY FILE (lcArchivoOrigen) TO (lcArchivoCola)
        IF !FILE(lcArchivoCola)
            ERROR "No se pudo copiar el archivo a la cola documental."
        ENDIF

        lcEvento = ADDBS(pcSysDir + pcDB) + "SigaDocumentosPendientes\adjunto-" + ;
            SYS(2015) + ".json"
        lcTemporal = lcEvento + ".tmp"
        lcJson = '{"schemaVersion":1,"kind":"attachment","module":"' + lcModulo + ;
            '","idDocto":' + ALLTRIM(STR(INT(tnIdDocumento))) + ;
            ',"idCliPro":' + ALLTRIM(STR(INT(EVL(tnIdCliPro, 0)))) + ;
            ',"documentId":"' + EscapeJsonSigaDocumentos(lcIdDoc) + ;
            '","filePath":"' + EscapeJsonSigaDocumentos(lcArchivoCola) + ;
            '","nature":"' + EscapeJsonSigaDocumentos(lcNaturaleza) + ;
            '","title":"' + EscapeJsonSigaDocumentos(lcTitulo) + ;
            '","captureSource":"archivo","queuedAt":"' + ;
            TTOC(DATETIME(), 3) + '"}'
        IF STRTOFILE(lcJson, lcTemporal, 0) <> LEN(lcJson)
            ERROR "No se pudo escribir el evento del adjunto."
        ENDIF
        RENAME (lcTemporal) TO (lcEvento)
        llOk = FILE(lcEvento)
    CATCH TO loError
        IF !EMPTY(lcTemporal) AND FILE(lcTemporal)
            DELETE FILE (lcTemporal)
        ENDIF
        IF !EMPTY(lcArchivoCola) AND FILE(lcArchivoCola) AND ;
                (EMPTY(lcEvento) OR !FILE(lcEvento))
            DELETE FILE (lcArchivoCola)
        ENDIF
        MESSAGEBOX("No se pudo adjuntar el archivo: " + loError.Message, 48, ;
            "SIGA Documentos")
        llOk = .F.
    FINALLY
        IF USED("sdFileVinc")
            USE IN sdFileVinc
        ENDIF
        IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
            SELECT (lcAliasAnterior)
        ENDIF
    ENDTRY

    RETURN llOk
ENDFUNC



FUNCTION AdjuntarImagenPortapapelesSigaDocumentos
    LPARAMETERS tcOrigen, tnIdDocumento, tnIdCliPro, tcNaturaleza, tcTitulo

    LOCAL lcOrigen, lcModulo, lcNaturaleza, lcTitulo, lcCarpeta, lcArchivo
    LOCAL lcEvento, lcTemporal, lcScript, lcComando, lcJson, lcIdDoc
    LOCAL loShell, lnSalida, lcAliasAnterior, loError

    IF TYPE("pnUsaSigaDocumentos") <> "N"
        RETURN .F.
    ENDIF
    IF pnUsaSigaDocumentos <> 1 OR VARTYPE(tnIdDocumento) <> "N" OR ;
            tnIdDocumento <= 0
        RETURN .F.
    ENDIF

    lcOrigen = UPPER(ALLTRIM(EVL(tcOrigen, "")))
    DO CASE
    CASE INLIST(lcOrigen, "VTA", "VENTA", "VENTAS")
        lcOrigen = "VTA"
        lcModulo = "ventas"
    CASE INLIST(lcOrigen, "COM", "CMP", "COMPRA", "COMPRAS")
        lcOrigen = "COM"
        lcModulo = "compras"
    CASE INLIST(lcOrigen, "CYB", "BANCO", "BANCOS")
        lcOrigen = "CYB"
        lcModulo = "bancos"
    CASE INLIST(lcOrigen, "CTB", "PARTIDA", "PARTIDAS")
        lcOrigen = "CTB"
        lcModulo = "partidas"
    OTHERWISE
        MESSAGEBOX("El origen no admite adjuntos desde el portapapeles.", 48, ;
            "SIGA Documentos")
        RETURN .F.
    ENDCASE

    lcNaturaleza = UPPER(ALLTRIM(EVL(tcNaturaleza, "SOPORTE")))
    IF !INLIST(lcNaturaleza, "PRINCIPAL", "SOPORTE", "ANEXO", "COMPLEMENTARIO")
        lcNaturaleza = "SOPORTE"
    ENDIF
    lcTitulo = ALLTRIM(EVL(tcTitulo, "Imagen pegada"))
    IF EMPTY(lcTitulo)
        lcTitulo = "Imagen pegada"
    ENDIF
    lcTitulo = LEFT(lcTitulo, 160)
    lcIdDoc = ""
    lcAliasAnterior = ALIAS()
    llOk = .F.

    TRY
        IF USED("sdClipVinc")
            USE IN sdClipVinc
        ENDIF
        USE (ADDBS(pcSysDir + pcDB) + "sisVinculos.dbf") IN 0 SHARED AGAIN ALIAS sdClipVinc
        SELECT sdClipVinc
        LOCATE FOR iddocto = tnIdDocumento AND ;
            UPPER(ALLTRIM(origen)) == lcOrigen AND activo AND !EMPTY(ALLTRIM(iddoc))
        IF FOUND()
            lcIdDoc = ALLTRIM(sdClipVinc.iddoc)
        ELSE
            * El adjunto queda esperando al documento principal sin perderse.
            lcIdDoc = ""
            =EncolarSigaDocumento(lcOrigen, tnIdDocumento)
        ENDIF
        USE IN sdClipVinc

        lcCarpeta = ADDBS(pcSysDir + pcDB) + "SigaDocumentosPendientes"
        IF !DIRECTORY(lcCarpeta)
            MD (lcCarpeta)
        ENDIF
        lcCarpeta = ADDBS(lcCarpeta) + "Archivos"
        IF !DIRECTORY(lcCarpeta)
            MD (lcCarpeta)
        ENDIF
        lcArchivo = ADDBS(lcCarpeta) + "imagen-" + SYS(2015) + ".png"
        lcScript = pcSysDir + "Programas\GuardarImagenPortapapeles.ps1"
        IF !FILE(lcScript)
            ERROR "No existe el auxiliar para leer el portapapeles."
        ENDIF

        lcComando = "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File " + ;
            CHR(34) + lcScript + CHR(34) + " -OutputPath " + ;
            CHR(34) + lcArchivo + CHR(34)
        loShell = CREATEOBJECT("WScript.Shell")
        lnSalida = loShell.Run(lcComando, 0, .T.)
        IF lnSalida <> 0 OR !FILE(lcArchivo)
            ERROR "El portapapeles no contiene una imagen."
        ENDIF

        lcEvento = ADDBS(pcSysDir + pcDB) + "SigaDocumentosPendientes\adjunto-" + ;
            SYS(2015) + ".json"
        lcTemporal = lcEvento + ".tmp"
        lcJson = '{"schemaVersion":1,"kind":"attachment","module":"' + lcModulo + ;
            '","idDocto":' + ALLTRIM(STR(INT(tnIdDocumento))) + ;
            ',"idCliPro":' + ALLTRIM(STR(INT(EVL(tnIdCliPro, 0)))) + ;
            ',"documentId":"' + EscapeJsonSigaDocumentos(lcIdDoc) + ;
            '","filePath":"' + EscapeJsonSigaDocumentos(lcArchivo) + ;
            '","nature":"' + EscapeJsonSigaDocumentos(lcNaturaleza) + ;
            '","title":"' + EscapeJsonSigaDocumentos(lcTitulo) + ;
            '","captureSource":"portapapeles","queuedAt":"' + ;
            TTOC(DATETIME(), 3) + '"}'
        IF STRTOFILE(lcJson, lcTemporal, 0) <> LEN(lcJson)
            ERROR "No se pudo escribir el evento del adjunto."
        ENDIF
        RENAME (lcTemporal) TO (lcEvento)
        llOk = FILE(lcEvento)
    CATCH TO loError
        IF !EMPTY(lcTemporal) AND FILE(lcTemporal)
            DELETE FILE (lcTemporal)
        ENDIF
        IF !EMPTY(lcArchivo) AND FILE(lcArchivo) AND EMPTY(lcEvento)
            DELETE FILE (lcArchivo)
        ENDIF
        MESSAGEBOX("No se pudo adjuntar la imagen: " + loError.Message, 48, ;
            "SIGA Documentos")
        llOk = .F.
    FINALLY
        IF USED("sdClipVinc")
            USE IN sdClipVinc
        ENDIF
        IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
            SELECT (lcAliasAnterior)
        ENDIF
    ENDTRY

    RETURN llOk
ENDFUNC


FUNCTION AdjuntarImagenUrlSigaDocumentos
    LPARAMETERS tcOrigen, tnIdDocumento, tnIdCliPro, tcUrl, tcNaturaleza, tcTitulo, tcFormato

    LOCAL lcOrigen, lcModulo, lcNaturaleza, lcTitulo, lcFormato, lcUrl
    LOCAL lcCarpeta, lcEvento, lcTemporal, lcJson, lcIdDoc, lcAliasAnterior, loError

    IF TYPE("pnUsaSigaDocumentos") <> "N"
        RETURN .F.
    ENDIF
    IF pnUsaSigaDocumentos <> 1 OR VARTYPE(tnIdDocumento) <> "N" OR tnIdDocumento <= 0
        RETURN .F.
    ENDIF
    lcUrl = ALLTRIM(EVL(tcUrl, ""))
    IF LOWER(LEFT(lcUrl, 8)) <> "https://"
        MESSAGEBOX("La imagen debe usar una direccion HTTPS.", 48, "SIGA Documentos")
        RETURN .F.
    ENDIF

    lcOrigen = UPPER(ALLTRIM(EVL(tcOrigen, "")))
    DO CASE
    CASE INLIST(lcOrigen, "VTA", "VENTA", "VENTAS")
        lcOrigen = "VTA"
        lcModulo = "ventas"
    CASE INLIST(lcOrigen, "COM", "CMP", "COMPRA", "COMPRAS")
        lcOrigen = "COM"
        lcModulo = "compras"
    CASE INLIST(lcOrigen, "CYB", "BANCO", "BANCOS")
        lcOrigen = "CYB"
        lcModulo = "bancos"
    CASE INLIST(lcOrigen, "CTB", "PARTIDA", "PARTIDAS")
        lcOrigen = "CTB"
        lcModulo = "partidas"
    OTHERWISE
        RETURN .F.
    ENDCASE

    lcNaturaleza = UPPER(ALLTRIM(EVL(tcNaturaleza, "SOPORTE")))
    IF !INLIST(lcNaturaleza, "PRINCIPAL", "SOPORTE", "ANEXO", "COMPLEMENTARIO")
        lcNaturaleza = "SOPORTE"
    ENDIF
    lcTitulo = LEFT(ALLTRIM(EVL(tcTitulo, "Imagen desde enlace")), 160)
    IF EMPTY(lcTitulo)
        lcTitulo = "Imagen desde enlace"
    ENDIF
    lcFormato = LOWER(ALLTRIM(EVL(tcFormato, "jpg")))
    IF !INLIST(lcFormato, "auto", "jpg", "jpeg", "png")
        lcFormato = "jpg"
    ENDIF
    lcIdDoc = ""
    lcAliasAnterior = ALIAS()
    llOk = .F.

    TRY
        IF USED("sdUrlVinc")
            USE IN sdUrlVinc
        ENDIF
        USE (ADDBS(pcSysDir + pcDB) + "sisVinculos.dbf") IN 0 SHARED AGAIN ALIAS sdUrlVinc
        SELECT sdUrlVinc
        LOCATE FOR iddocto = tnIdDocumento AND ;
            UPPER(ALLTRIM(origen)) == lcOrigen AND activo AND !EMPTY(ALLTRIM(iddoc))
        IF FOUND()
            lcIdDoc = ALLTRIM(sdUrlVinc.iddoc)
        ELSE
            * El adjunto queda esperando al documento principal sin perderse.
            lcIdDoc = ""
            =EncolarSigaDocumento(lcOrigen, tnIdDocumento)
        ENDIF
        USE IN sdUrlVinc

        lcCarpeta = ADDBS(pcSysDir + pcDB) + "SigaDocumentosPendientes"
        IF !DIRECTORY(lcCarpeta)
            MD (lcCarpeta)
        ENDIF
        lcEvento = ADDBS(lcCarpeta) + "adjunto-url-" + SYS(2015) + ".json"
        lcTemporal = lcEvento + ".tmp"
        lcJson = '{"schemaVersion":1,"kind":"attachment_url","module":"' + lcModulo + ;
            '","idDocto":' + ALLTRIM(STR(INT(tnIdDocumento))) + ;
            ',"idCliPro":' + ALLTRIM(STR(INT(EVL(tnIdCliPro, 0)))) + ;
            ',"documentId":"' + EscapeJsonSigaDocumentos(lcIdDoc) + ;
            '","url":"' + EscapeJsonSigaDocumentos(lcUrl) + ;
            '","nature":"' + EscapeJsonSigaDocumentos(lcNaturaleza) + ;
            '","title":"' + EscapeJsonSigaDocumentos(lcTitulo) + ;
            '","outputFormat":"' + EscapeJsonSigaDocumentos(lcFormato) + ;
            '","queuedAt":"' + TTOC(DATETIME(), 3) + '"}'
        IF STRTOFILE(lcJson, lcTemporal, 0) <> LEN(lcJson)
            ERROR "No se pudo escribir el evento de la imagen web."
        ENDIF
        RENAME (lcTemporal) TO (lcEvento)
        llOk = FILE(lcEvento)
    CATCH TO loError
        IF !EMPTY(lcTemporal) AND FILE(lcTemporal)
            DELETE FILE (lcTemporal)
        ENDIF
        MESSAGEBOX("No se pudo adjuntar el enlace: " + loError.Message, 48, ;
            "SIGA Documentos")
        llOk = .F.
    FINALLY
        IF USED("sdUrlVinc")
            USE IN sdUrlVinc
        ENDIF
        IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
            SELECT (lcAliasAnterior)
        ENDIF
    ENDTRY

    RETURN llOk
ENDFUNC


FUNCTION EscapeJsonSigaDocumentos
    LPARAMETERS tcTexto
    LOCAL lcTexto
    lcTexto = EVL(tcTexto, "")
    lcTexto = STRTRAN(lcTexto, "\", "\\")
    lcTexto = STRTRAN(lcTexto, '"', '\"')
    lcTexto = STRTRAN(lcTexto, CHR(13), "\r")
    lcTexto = STRTRAN(lcTexto, CHR(10), "\n")
    RETURN lcTexto
ENDFUNC


* Valida que la venta este facturada y, cuando es electronica, que Hacienda
* la haya aceptado. No altera la venta ni vuelve a generar el DTE.
FUNCTION PublicarVentaSigaDocumentos
    LPARAMETERS tnIdDocumento, tcPdfPath

    LOCAL lcRutaDatos, lcAliasAnterior, llElectronica, llVentaValida
    LOCAL llDteValido, llResultado, loError

    llResultado = .F.
    IF TYPE("pnUsaSigaDocumentos") <> "N"
        RETURN .F.
    ENDIF
    IF pnUsaSigaDocumentos <> 1 OR VARTYPE(tnIdDocumento) <> "N" OR ;
            tnIdDocumento <= 0 OR VARTYPE(tcPdfPath) <> "C" OR ;
            EMPTY(ALLTRIM(tcPdfPath)) OR !FILE(ALLTRIM(tcPdfPath))
        RETURN .F.
    ENDIF

    lcRutaDatos = ADDBS(pcSysDir + pcDB)
    lcAliasAnterior = ALIAS()

    TRY
        IF USED("sdPubVenta")
            USE IN sdPubVenta
        ENDIF
        IF USED("sdPubSerie")
            USE IN sdPubSerie
        ENDIF
        IF USED("sdPubDte")
            USE IN sdPubDte
        ENDIF

        USE (lcRutaDatos + "cyvVentas.dbf") IN 0 SHARED AGAIN ALIAS sdPubVenta
        SELECT sdPubVenta
        LOCATE FOR iddocto = tnIdDocumento AND UPPER(ALLTRIM(origen)) == "VTA" AND ;
            eliminado = 0 AND status = 1 AND ctrolvta <> 0
        llVentaValida = FOUND()
        IF !llVentaValida
            RETURN .F.
        ENDIF

        llElectronica = .F.
        USE (lcRutaDatos + "sisSeries.dbf") IN 0 SHARED AGAIN ALIAS sdPubSerie
        SELECT sdPubSerie
        LOCATE FOR idserie = sdPubVenta.idserie
        IF FOUND()
            llElectronica = NVL(sdPubSerie.electronica, 0) <> 0
        ENDIF

        llDteValido = !llElectronica
        IF llElectronica
            USE (lcRutaDatos + "sisDTE.dbf") IN 0 SHARED AGAIN ALIAS sdPubDte
            SELECT sdPubDte
            LOCATE FOR iddocto = tnIdDocumento AND ;
                UPPER(ALLTRIM(origen)) == "VTA" AND status = 1 AND ;
                !EMPTY(ALLTRIM(codigogeneracion)) AND ;
                !EMPTY(ALLTRIM(jsonenviado))
            llDteValido = FOUND()
        ENDIF

        IF llDteValido
            llResultado = EncolarSigaDocumento("VTA", tnIdDocumento, ;
                ALLTRIM(tcPdfPath))
        ENDIF
    CATCH TO loError
        =RegistrarMigracionSigaDocumentos(tnIdDocumento, "ERROR", ;
            "Publicacion automatica: " + loError.Message)
        llResultado = .F.
    FINALLY
        IF USED("sdPubDte")
            USE IN sdPubDte
        ENDIF
        IF USED("sdPubSerie")
            USE IN sdPubSerie
        ENDIF
        IF USED("sdPubVenta")
            USE IN sdPubVenta
        ENDIF
        IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
            SELECT (lcAliasAnterior)
        ENDIF
    ENDTRY

    RETURN llResultado
ENDFUNC


* Genera y encola ventas historicas sin reemplazar archivos que ya existen.
* El trabajador de SIGA Bridge sube, verifica, registra sisVinculos y borra
* los archivos locales solamente despues de confirmar todo el proceso.
*
* tnMaximo limita la cantidad encolada por ejecucion. Cero procesa el rango
* completo; para uso interactivo se recomiendan lotes de 25.
FUNCTION MigrarVentasSigaDocumentos
    LPARAMETERS tdDesde, tdHasta, tnMaximo, tlSimular

    LOCAL loResultado, ldDesde, ldHasta, lnMaximo, lcRutaDatos, lcAliasAnterior
    LOCAL lnId, llElectronica, llDteValido, lcPdf, lcFormato, lcEvento
    LOCAL llSimular
    LOCAL lnTipoConexion, llEncolado, loError, lcMensaje

    loResultado = CREATEOBJECT("Empty")
    ADDPROPERTY(loResultado, "ok", .F.)
    ADDPROPERTY(loResultado, "candidatos", 0)
    ADDPROPERTY(loResultado, "encolados", 0)
    ADDPROPERTY(loResultado, "yaPublicados", 0)
    ADDPROPERTY(loResultado, "yaPendientes", 0)
    ADDPROPERTY(loResultado, "porProcesar", 0)
    ADDPROPERTY(loResultado, "omitidos", 0)
    ADDPROPERTY(loResultado, "errores", 0)
    ADDPROPERTY(loResultado, "mensaje", "")

    IF TYPE("pnUsaSigaDocumentos") <> "N"
        loResultado.mensaje = "SIGA Documentos no esta activo para esta empresa."
        RETURN loResultado
    ENDIF
    IF pnUsaSigaDocumentos <> 1
        loResultado.mensaje = "SIGA Documentos no esta activo para esta empresa."
        RETURN loResultado
    ENDIF
    IF VARTYPE(tdDesde) <> "D" OR VARTYPE(tdHasta) <> "D" OR ;
            EMPTY(tdDesde) OR EMPTY(tdHasta) OR tdDesde > tdHasta
        loResultado.mensaje = "El rango de fechas no es valido."
        RETURN loResultado
    ENDIF

    ldDesde = tdDesde
    ldHasta = tdHasta + 1
    lnMaximo = IIF(VARTYPE(tnMaximo) = "N", MAX(0, INT(tnMaximo)), 25)
    llSimular = VARTYPE(tlSimular) = "L" AND tlSimular
    lcRutaDatos = ADDBS(pcSysDir + pcDB)
    lcAliasAnterior = ALIAS()
    lnTipoConexion = IIF(TYPE("pnTipoconeccion") = "N", pnTipoconeccion, 1)

    TRY
        =CerrarCursoresMigracionSigaDocumentos()

        USE (lcRutaDatos + "cyvVentas.dbf") IN 0 SHARED AGAIN ALIAS sdVentas
        USE (lcRutaDatos + "sisSeries.dbf") IN 0 SHARED AGAIN ALIAS sdSeries
        USE (lcRutaDatos + "sisTipoDoctos.dbf") IN 0 SHARED AGAIN ALIAS sdTipoDoc
        USE (lcRutaDatos + "sisCata.dbf") IN 0 SHARED AGAIN ALIAS sdCata
        USE (lcRutaDatos + "sisDTE.dbf") IN 0 SHARED AGAIN ALIAS sdDte
        IF FILE(lcRutaDatos + "sisVinculos.dbf")
            USE (lcRutaDatos + "sisVinculos.dbf") IN 0 SHARED AGAIN ALIAS sdVinculos
        ENDIF

        SELECT v.iddocto, v.fechadocto, v.numero, v.codigogeneracion, ;
               v.numerocontrol, v.idclipro, NVL(s.electronica, 0) AS electronica, ;
               NVL(t.clave, SPACE(20)) AS clave, ;
               NVL(c.cod, SPACE(20)) AS codsucursal ;
          FROM sdVentas v ;
          LEFT JOIN sdSeries s ON v.idserie = s.idserie ;
          LEFT JOIN sdTipoDoc t ON v.idtipodocto = t.idtipodocto ;
          LEFT JOIN sdCata c ON v.idsucursal = c.id AND c.origen = "SUC" ;
         WHERE v.origen = "VTA" AND v.eliminado = 0 AND v.status = 1 AND ;
               v.ctrolvta <> 0 AND v.fechadocto >= m.ldDesde AND ;
               v.fechadocto < m.ldHasta ;
         ORDER BY v.fechadocto, v.iddocto ;
          INTO CURSOR cSigaMigVentas READWRITE

        SELECT cSigaMigVentas
        SCAN
            lnId = cSigaMigVentas.iddocto
            loResultado.candidatos = loResultado.candidatos + 1

            IF VentaPublicadaSigaDocumentos(lnId, cSigaMigVentas.electronica <> 0)
                loResultado.yaPublicados = loResultado.yaPublicados + 1
                LOOP
            ENDIF

            lcEvento = lcRutaDatos + "SigaDocumentosPendientes\ventas-" + ;
                ALLTRIM(STR(lnId)) + ".json"
            IF FILE(lcEvento) OR FILE(lcEvento + ".done")
                loResultado.yaPendientes = loResultado.yaPendientes + 1
                IF !llSimular AND lnMaximo > 0 AND ;
                        loResultado.yaPendientes + loResultado.encolados >= lnMaximo
                    EXIT
                ENDIF
                LOOP
            ENDIF

            llElectronica = cSigaMigVentas.electronica <> 0
            llDteValido = DteVentaValidoSigaDocumentos(lnId)
            IF llElectronica AND !llDteValido
                loResultado.omitidos = loResultado.omitidos + 1
                =RegistrarMigracionSigaDocumentos(lnId, "OMITIDO", ;
                    "DTE electronico sin registro aceptado y JSON fiscal valido")
                LOOP
            ENDIF

            IF llSimular
                loResultado.porProcesar = loResultado.porProcesar + 1
                LOOP
            ENDIF

            lcPdf = RutaPdfVentaSigaDocumentos(lnId, ;
                cSigaMigVentas.fechadocto, cSigaMigVentas.codigogeneracion, ;
                cSigaMigVentas.numerocontrol, cSigaMigVentas.clave, ;
                cSigaMigVentas.codsucursal, cSigaMigVentas.numero)

            IF EMPTY(lcPdf)
                SELECT cSigaMigVentas
                WAIT WINDOW "Generando PDF para SIGA Documentos: " + ;
                    TRANSFORM(lnId) NOWAIT
                ImprimirFactura(lnId, 7, 0, lnTipoConexion, 1, 1, 1)
                lcPdf = RutaPdfVentaSigaDocumentos(lnId, ;
                    cSigaMigVentas.fechadocto, cSigaMigVentas.codigogeneracion, ;
                    cSigaMigVentas.numerocontrol, cSigaMigVentas.clave, ;
                    cSigaMigVentas.codsucursal, cSigaMigVentas.numero)
            ENDIF

            IF EMPTY(lcPdf) OR !FILE(lcPdf)
                loResultado.errores = loResultado.errores + 1
                =RegistrarMigracionSigaDocumentos(lnId, "ERROR", ;
                    "No fue posible localizar ni generar el PDF")
                LOOP
            ENDIF

            llEncolado = EncolarSigaDocumento("VTA", lnId, lcPdf)
            IF llEncolado
                loResultado.encolados = loResultado.encolados + 1
                =RegistrarMigracionSigaDocumentos(lnId, "ENCOLADO", lcPdf)
            ELSE
                loResultado.errores = loResultado.errores + 1
                =RegistrarMigracionSigaDocumentos(lnId, "ERROR", ;
                    "No fue posible crear el evento de publicacion")
            ENDIF

            IF lnMaximo > 0 AND ;
                    loResultado.encolados + loResultado.yaPendientes >= lnMaximo
                EXIT
            ENDIF
            DOEVENTS
        ENDSCAN

        loResultado.ok = loResultado.errores = 0
        loResultado.mensaje = "Candidatos: " + TRANSFORM(loResultado.candidatos) + ;
            ", encolados: " + TRANSFORM(loResultado.encolados) + ;
            ", publicados: " + TRANSFORM(loResultado.yaPublicados) + ;
            ", pendientes: " + TRANSFORM(loResultado.yaPendientes) + ;
            ", por procesar: " + TRANSFORM(loResultado.porProcesar) + ;
            ", omitidos: " + TRANSFORM(loResultado.omitidos) + ;
            ", errores: " + TRANSFORM(loResultado.errores) + "."
    CATCH TO loError
        loResultado.errores = loResultado.errores + 1
        loResultado.mensaje = "La migracion se detuvo: " + loError.Message + ;
            " (linea " + TRANSFORM(loError.LineNo) + ")"
        loResultado.ok = .F.
    FINALLY
        =CerrarCursoresMigracionSigaDocumentos()
        WAIT CLEAR
        IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
            SELECT (lcAliasAnterior)
        ENDIF
    ENDTRY

    RETURN loResultado
ENDFUNC


FUNCTION AbrirMigracionVentasSigaDocumentos
    LOCAL loFormulario

    loFormulario = CREATEOBJECT("frmSigaMigracionVentas")
    loFormulario.Show(1)
    RETURN .T.
ENDFUNC


FUNCTION VentaPublicadaSigaDocumentos
    LPARAMETERS tnIdDocumento, tlEsDte
    LOCAL lnPdf, lnJson

    IF !USED("sdVinculos")
        RETURN .F.
    ENDIF

    lnPdf = 0
    lnJson = 0
    SELECT sdVinculos
    SCAN ALL FOR iddocto = tnIdDocumento AND ;
            UPPER(ALLTRIM(origen)) == "VTA" AND activo
        IF UPPER(ALLTRIM(tipodoc)) == "PDF" AND ;
                UPPER(ALLTRIM(estado)) == "DISPONIBLE"
            lnPdf = lnPdf + 1
        ENDIF
        IF UPPER(ALLTRIM(tipodoc)) == "JSON DTE" AND ;
                UPPER(ALLTRIM(estado)) == "DISPONIBLE"
            lnJson = lnJson + 1
        ENDIF
    ENDSCAN

    RETURN lnPdf > 0 AND (!tlEsDte OR lnJson > 0)
ENDFUNC


FUNCTION DteVentaValidoSigaDocumentos
    LPARAMETERS tnIdDocumento
    LOCAL llValido

    llValido = .F.
    IF !USED("sdDte")
        RETURN .F.
    ENDIF

    SELECT sdDte
    SCAN ALL FOR iddocto = tnIdDocumento AND ;
            UPPER(ALLTRIM(origen)) == "VTA" AND status = 1
        IF !EMPTY(ALLTRIM(codigogeneracion)) AND ;
                !EMPTY(ALLTRIM(jsonenviado))
            llValido = .T.
            EXIT
        ENDIF
    ENDSCAN

    RETURN llValido
ENDFUNC


FUNCTION RutaPdfVentaSigaDocumentos
    LPARAMETERS tnIdDocumento, tdFecha, tcGeneracion, tcControl, ;
        tcClave, tcSucursal, tcNumero

    LOCAL lcCarpeta, lcAno, lcRuta, lcNombreNormal, lnForma
    LOCAL ARRAY laRutas[8]

    lcCarpeta = ADDBS(pcSysDir + pcDB) + "ArchivosPDF\"
    lcAno = TRANSFORM(YEAR(tdFecha))
    lcNombreNormal = ALLTRIM(EVL(tcClave, "")) + "-" + ;
        ALLTRIM(EVL(tcSucursal, "")) + "-" + ALLTRIM(EVL(tcNumero, ""))

    laRutas[1] = PdfPathDteSigaDocumentos(tnIdDocumento)
    laRutas[2] = lcCarpeta + ALLTRIM(EVL(tcGeneracion, "")) + ".pdf"
    laRutas[3] = lcCarpeta + lcAno + "-" + ALLTRIM(EVL(tcControl, "")) + ".pdf"
    laRutas[4] = lcCarpeta + lcAno + "-" + ALLTRIM(EVL(tcGeneracion, "")) + ".pdf"
    laRutas[5] = lcCarpeta + ALLTRIM(EVL(tcControl, "")) + ".pdf"
    laRutas[6] = lcCarpeta + lcAno + "-" + lcNombreNormal + ".pdf"
    laRutas[7] = lcCarpeta + lcNombreNormal + ".pdf"
    laRutas[8] = ""

    FOR lnForma = 1 TO ALEN(laRutas, 1)
        lcRuta = ALLTRIM(laRutas[lnForma])
        IF !EMPTY(lcRuta) AND FILE(lcRuta)
            RETURN lcRuta
        ENDIF
    ENDFOR

    RETURN ""
ENDFUNC


FUNCTION PdfPathDteSigaDocumentos
    LPARAMETERS tnIdDocumento
    LOCAL lcRuta

    lcRuta = ""
    IF !USED("sdDte")
        RETURN lcRuta
    ENDIF

    SELECT sdDte
    SCAN ALL FOR iddocto = tnIdDocumento AND ;
            UPPER(ALLTRIM(origen)) == "VTA" AND status = 1
        IF !EMPTY(ALLTRIM(pdf_path)) AND FILE(ALLTRIM(pdf_path))
            lcRuta = ALLTRIM(pdf_path)
            EXIT
        ENDIF
    ENDSCAN

    RETURN lcRuta
ENDFUNC


FUNCTION RegistrarMigracionSigaDocumentos
    LPARAMETERS tnIdDocumento, tcEstado, tcDetalle
    LOCAL lcCarpeta, lcLog, lcLinea

    lcCarpeta = ADDBS(pcSysDir + pcDB) + "SigaDocumentosPendientes"
    IF !DIRECTORY(lcCarpeta)
        MD (lcCarpeta)
    ENDIF
    lcLog = ADDBS(lcCarpeta) + "migracion-ventas.log"
    lcLinea = TTOC(DATETIME(), 3) + "|" + TRANSFORM(tnIdDocumento) + ;
        "|" + ALLTRIM(EVL(tcEstado, "")) + "|" + ;
        STRTRAN(STRTRAN(ALLTRIM(EVL(tcDetalle, "")), CHR(13), " "), CHR(10), " ") + ;
        CHR(13) + CHR(10)
    =STRTOFILE(lcLinea, lcLog, 1)
    RETURN .T.
ENDFUNC


FUNCTION CerrarCursoresMigracionSigaDocumentos
    LOCAL lnAlias
    LOCAL ARRAY laAlias[7]

    laAlias[1] = "cSigaMigVentas"
    laAlias[2] = "sdVentas"
    laAlias[3] = "sdSeries"
    laAlias[4] = "sdTipoDoc"
    laAlias[5] = "sdCata"
    laAlias[6] = "sdDte"
    laAlias[7] = "sdVinculos"

    FOR lnAlias = 1 TO ALEN(laAlias, 1)
        IF USED(laAlias[lnAlias])
            USE IN (laAlias[lnAlias])
        ENDIF
    ENDFOR
    RETURN .T.
ENDFUNC


DEFINE CLASS frmSigaMigracionVentas AS Form
    Caption = "Migrar ventas a SIGA Documentos"
    Width = 570
    Height = 285
    AutoCenter = .T.
    WindowType = 1
    BorderStyle = 2
    MaxButton = .F.
    MinButton = .F.

    ADD OBJECT lblTitulo AS Label WITH ;
        Caption = "Publicacion historica de PDF y JSON", ;
        Left = 18, Top = 16, Width = 360, Height = 22, FontBold = .T.
    ADD OBJECT lblDesde AS Label WITH ;
        Caption = "Desde", Left = 18, Top = 54, Width = 60, Height = 20
    ADD OBJECT txtDesde AS TextBox WITH ;
        Left = 82, Top = 50, Width = 105, Height = 24
    ADD OBJECT lblHasta AS Label WITH ;
        Caption = "Hasta", Left = 205, Top = 54, Width = 55, Height = 20
    ADD OBJECT txtHasta AS TextBox WITH ;
        Left = 260, Top = 50, Width = 105, Height = 24
    ADD OBJECT lblLote AS Label WITH ;
        Caption = "Maximo pendiente", Left = 383, Top = 54, Width = 110, Height = 20
    ADD OBJECT spnLote AS Spinner WITH ;
        Left = 495, Top = 50, Width = 58, Height = 24, ;
        KeyboardLowValue = 1, KeyboardHighValue = 500, Value = 25
    ADD OBJECT lblAviso AS Label WITH ;
        Caption = "Los archivos locales se borran solo despues de verificar Drive y sisVinculos.", ;
        Left = 18, Top = 88, Width = 535, Height = 20
    ADD OBJECT lblResultado AS Label WITH ;
        Caption = "Primero presione Analizar.", ;
        Left = 18, Top = 120, Width = 535, Height = 64, WordWrap = .T.
    ADD OBJECT cmdAnalizar AS CommandButton WITH ;
        Caption = "Analizar", Left = 168, Top = 205, Width = 95, Height = 32
    ADD OBJECT cmdProcesar AS CommandButton WITH ;
        Caption = "Preparar lote", Left = 273, Top = 205, Width = 115, Height = 32
    ADD OBJECT cmdCerrar AS CommandButton WITH ;
        Caption = "Cerrar", Left = 398, Top = 205, Width = 85, Height = 32

    PROCEDURE Init
        this.txtDesde.Value = DATE(YEAR(DATE()), 1, 1)
        this.txtHasta.Value = DATE()
        this.lblResultado.Caption = ;
            "El analisis no genera archivos ni modifica documentos."
    ENDPROC

    PROCEDURE cmdAnalizar.Click
        LOCAL loResultado
        loResultado = MigrarVentasSigaDocumentos(thisform.txtDesde.Value, ;
            thisform.txtHasta.Value, 0, .T.)
        thisform.lblResultado.Caption = loResultado.mensaje
    ENDPROC

    PROCEDURE cmdProcesar.Click
        LOCAL loPrevio, loResultado, lnRespuesta

        loPrevio = MigrarVentasSigaDocumentos(thisform.txtDesde.Value, ;
            thisform.txtHasta.Value, 0, .T.)
        thisform.lblResultado.Caption = loPrevio.mensaje
        IF !loPrevio.ok AND loPrevio.errores > 0
            MESSAGEBOX(loPrevio.mensaje, 16, "SIGA Documentos")
            RETURN
        ENDIF
        IF loPrevio.porProcesar = 0
            MESSAGEBOX("No hay ventas nuevas para preparar en este rango.", ;
                64, "SIGA Documentos")
            RETURN
        ENDIF

        lnRespuesta = MESSAGEBOX("Se preparara un lote de hasta " + ;
            TRANSFORM(INT(thisform.spnLote.Value)) + " documento(s)." + CHR(13) + ;
            "La carga continuara en segundo plano. Desea continuar?", ;
            4 + 32 + 256, "Migrar ventas")
        IF lnRespuesta <> 6
            RETURN
        ENDIF

        loResultado = MigrarVentasSigaDocumentos(thisform.txtDesde.Value, ;
            thisform.txtHasta.Value, INT(thisform.spnLote.Value), .F.)
        thisform.lblResultado.Caption = loResultado.mensaje
        MESSAGEBOX(loResultado.mensaje, ;
            IIF(loResultado.errores = 0, 64, 48), "SIGA Documentos")
    ENDPROC

    PROCEDURE cmdCerrar.Click
        thisform.Release()
    ENDPROC
ENDDEFINE




FUNCTION _CopiarDBM_YSQL()
	OPEN DATABASE pcsysdir+pcDB+"\masterdb"
	lntabls=ADBOBJECTS(tablas, "TABLE")
	lcmicomando=""
	FOR iii=1 TO lntabls
		lcmitab= LOWER(tablas(iii))
		lcmicomando=lcmicomando+CHR(13)+CHR(13)+_obtenerEstructuradelaTabla_MYSQL(lcmitab,1)+";"+CHR(13)
	ENDFOR 
	lcdirectorio=''

	lcmicomando=STRTRAN(lcmicomando,'"    -  -     :  :  "','"2017-12-31 12:00:00"')
	lcmicomando=STRTRAN(lcmicomando,'str(idcuenta)','idcuenta')
	lcmicomando=STRTRAN(lcmicomando,'str(idbodega)','idbodega')
	lcmicomando=STRTRAN(lcmicomando,'str(idproducto)','idproducto')
	lcmicomando=STRTRAN(lcmicomando,'str(tipoclipro)','tipoclipro')
	lcmicomando=STRTRAN(lcmicomando,'str(idproducto)','idproducto')
	lcmicomando=STRTRAN(lcmicomando,'dtoc(fechapartida)','fechapartida')
	lcmicomando=STRTRAN(lcmicomando,'"    -  -  "','null')
	
	RETURN lcdirectorio+"CREATE DATABASE mydb;"+CHR(13)+"use mydb;"+CHR(13)+CHR(13)+lcmicomando
ENDFUNC 



FUNCTION _CopiarDB()
	OPEN DATABASE pcsysdir+pcDB+"\masterdb"
	lntabls=ADBOBJECTS(tablas, "TABLE")
	lcmicomando=""
	FOR iii=1 TO lntabls
		lcmitab= LOWER(tablas(iii))
		lcmicomando=lcmicomando+CHR(13)+CHR(13)+_obtenerEstructuradelaTabla(lcmitab,1)
	ENDFOR 
	IF !DIRECTORY('C:\DESARROLLO VFP\AGILSOFT FUENTE\agilsoft_copia')
		lcdirectorio="MKDIR 'C:\DESARROLLO VFP\AGILSOFT FUENTE\agilsoft_copia'"+CHR(13)
	ELSE 
		lcdirectorio=''
	ENDIF 
	
	RETURN lcdirectorio+"CREATE DATABASE '"+pcsysdir+"agilsoft_copia\masterdb' "+CHR(13)+"OPEN DATABASE '"+pcsysdir+"agilsoft_copia\masterdb'"+CHR(13)+lcmicomando
ENDFUNC 


FUNCTION _obtenerEstructuradelaTabla(lcTa as Character,lnTip as Integer)
	lcRetEstru=''
	lctipoc=''
	lntama=0
	lcdeci=0
	lcnomc=''
	lctam=''
	lcComa=''
	lcComa2=''
	lcindices=''
	lcindcoma=''
	lcvalues=''
	lcalit=ALIAS()
	llabrio=.f.

	IF !EMPTY(lcTa)
		IF USED(lcTa)
			SELECT (lcTa)
			lcTa=ALIAS()
		ELSE 
			USE pcsysdir+pcDB+"\"+lcTa IN 0 SHARED again 
			llabrio=.t.
		ENDIF 
		lctab=lcTa
	ELSE
		lcTa=ALIAS()
	ENDIF 
	
	SELECT (lcTa)
	
	AFIELDS(lacampos,lcTa)

	***** indices
	lccampoprimario=''
	lcTagCampoprimario=''
	FOR ii = 1 TO 254 
		IF !EMPTY(TAG(ii)) && Checks for tags in the index 
			IF 	!PRIMARY(ii,lcTa)
				lcindices=lcindices+lcindcoma+'inde on '+LOWER(SYS(14, ii,lcTa))+' TAG '+LOWER(tag(ii,lcTa))
				lcindcoma=CHR(13)
			ELSE 
				lccampoprimario=LOWER(SYS(14, ii,lcTa))
				lcTagCampoprimario=LOWER(tag(ii,lcTa))
			ENDIF 
		ELSE 
			EXIT && Exit the loop when no more tags are found 
		ENDIF 
	ENDFOR

	**** structura de la tabla
	FOR i = 1 TO FCOUNT() 
	    STORE LOWER(FIELD(i)) TO lcnomc
	    STORE TYPE(FIELD(i))  TO lctipoc
	    STORE FSIZE(FIELD(i)) TO lntama
	   
	    IF lccampoprimario==lcnomc AND !EMPTY(lccampoprimario)
	    	lcprima=' primary key'
		    IF lacampos(i,17)>0
		    	lcprima=lcprima+' AUTOINC '
		    ENDIF
	    ELSE 
	    	lcprima=''
	    ENDIF 
	    
	    DO case
	    	CASE lctipoc='C'
	    		lctam='('+ALLTRIM(STR(lntama))+')'
	    		lcvalues=lcvalues+lcComa+'"'+"'+ALLTRIM("+lcnomc+")+'"+'"'
	    	CASE lctipoc='N'
	    		IF lntama=4
	    			lctam=''
	    			lctipoc='I'
	    			lcvalues=lcvalues+lcComa+"'+ALLTRIM(STR("+lcnomc+"))+'"
	    		ELSE 
	    			lctam='(18,8)'
	    			lcvalues=lcvalues+lcComa+"'+ALLTRIM(STR("+lcnomc+",18,8))+'"
	    		ENDIF 
	    	CASE lctipoc='T' OR lctipoc='D' OR lctipoc='M'
	    		lctam=''
	    		IF lctipoc='T'
	    			lcvalues=lcvalues+lcComa+"ctot("+'"'+"'+ttoc("+lcnomc+")+'"+'"'+")"
	    		ELSE
		    		IF lctipoc='D'
		    			lcvalues=lcvalues+lcComa+"ctod("+'"'+"'+dtoc("+lcnomc+")+'"+'"'+")"
		    		ELSE
		    			lcvalues=lcvalues+lcComa+'"'+"'+ALLTRIM("+lcnomc+")+'"+'"'
		    		ENDIF 
	    		ENDIF 
	    	OTHERWISE 
	    	lctam='()'
	    	lcvalues=lcvalues+lcComa+'"'+"'+ALLTRIM("+lcnomc+")+'"+'"'
	    ENDCASE 

		lcRetEstru=lcRetEstru+lcComa2+lcnomc+' '+lctipoc+lctam+' '+lcprima
		lcComa2=',;'+CHR(13)
		lcComa=','
	ENDFOR 

	lcvalores=''
	lccomval=''
	IF !EOF()
		SCAN
			lcmicoman="lcComan1a='("+lcvalues+")'"
			&lcmicoman
			lcvalores=lcvalores+lccomval+'insert into '+LOWER(lcTa)+' values '+lcComan1a
			lccomval=CHR(13)
		ENDSCAN 
		lcvalores=lcvalores
	ELSE 
		lcvalores=''
	ENDIF 

	IF llabrio=.t.
		IF !EMPTY(lcalit)
			SELECT (lcalit)
		ENDIF 
		USE IN (lcTa)
	ENDIF 
	
	RETURN 'create table "'+pcsysdir+'agilsoft_copia\'+LOWER(lcTa)+'" (;'+CHR(13)+lcRetEstru+')'+CHR(13)+lcindices+CHR(13)+lcvalores
ENDFUNC 



FUNCTION _obtenerEstructuradelaTabla_MYSQL(lcTa as Character,lnTip as Integer)
	lcRetEstru=''
	lctipoc=''
	lntama=0
	lcdeci=0
	lcnomc=''
	lctam=''
	lcComa=''
	lcComa2=''
	lcindices=''
	lcindcoma=''
	lcvalues=''
	lcalit=ALIAS()
	llabrio=.f.

	IF !EMPTY(lcTa)
		IF USED(lcTa)
			SELECT (lcTa)
			lcTa=ALIAS()
		ELSE 
			USE pcsysdir+pcDB+"\"+lcTa IN 0 SHARED again 
			llabrio=.t.
		ENDIF 
		lctab=lcTa
	ELSE
		lcTa=ALIAS()
	ENDIF 
	
	SELECT (lcTa)
	
	AFIELDS(lacampos,lcTa)

	***** indices
	lccampoprimario=''
	lcTagCampoprimario=''
	lcnotnull=''
	FOR ii = 1 TO 254 
		IF !EMPTY(TAG(ii)) && Checks for tags in the index 
			IF 	!PRIMARY(ii,lcTa)
				lcindices=lcindices+lcindcoma+'		KEY '+LOWER(tag(ii,lcTa))+' ('+STRTRAN(LOWER(SYS(14, ii,lcTa)),"+",",")+')'
				lcindcoma=','+CHR(13)
			ELSE 
				lcindices=lcindices+lcindcoma+'PRIMARY KEY '+LOWER(tag(ii,lcTa))+' ('+STRTRAN(LOWER(SYS(14, ii,lcTa)),"+",",")+')'
				lcindcoma=','+CHR(13)
				lccampoprimario=LOWER(SYS(14, ii,lcTa))
				lcTagCampoprimario=LOWER(tag(ii,lcTa))
			ENDIF 
		ELSE 
			EXIT && Exit the loop when no more tags are found 
		ENDIF 
	ENDFOR

	**** structura de la tabla
	FOR i = 1 TO FCOUNT() 
	    STORE LOWER(FIELD(i)) TO lcnomc
	    STORE TYPE(FIELD(i))  TO lctipoc
	    STORE FSIZE(FIELD(i)) TO lntama
	   
	    IF lccampoprimario==lcnomc AND !EMPTY(lccampoprimario)
	    	lcprima=''
	    	lcnotnull=' NOT NULL'
		    IF lacampos(i,17)>0
		    	lcprima=lcprima+' '
		    ENDIF
	    ELSE 
	    	lcprima=''
	    	lcnotnull=' DEFAULT NULL'
	    ENDIF 
	    
	    DO case
	    	CASE lctipoc='C'
	    		lctipoc='varchar'
	    		lctam='('+ALLTRIM(STR(lntama))+')'
	    		lcvalues=lcvalues+lcComa+'"'+"'+ALLTRIM("+lcnomc+")+'"+'"'
	    	CASE lctipoc='N'
	    		IF lntama=4
	    			lctipoc='int'
	    			lctam='(11)'
	    			lcvalues=lcvalues+lcComa+"'+ALLTRIM(STR("+lcnomc+"))+'"
	    		ELSE 
	    			lctipoc='decimal'
	    			lctam='(18,8)'
	    			lcvalues=lcvalues+lcComa+"'+ALLTRIM(STR("+lcnomc+",18,8))+'"
	    		ENDIF 
	    	CASE lctipoc='T' OR lctipoc='D' OR lctipoc='M'
	    		lctam=''
	    		IF lctipoc='T'
	    		lctipoc='DATETIME'
	    			lcvalues=lcvalues+lcComa+""+'"'+"'+_ConvertirToFechaHoraSQL("+lcnomc+")+'"+'"'+""
	    		ELSE
		    		IF lctipoc='D'
		    			lctipoc='DATE'
		    			lcvalues=lcvalues+lcComa+""+'"'+"'+_ConvertirToFechaSQL("+lcnomc+")+'"+'"'+""
		    		ELSE
		    			lctipoc='TEXT'
		    			lcvalues=lcvalues+lcComa+'"'+"'+ALLTRIM("+lcnomc+")+'"+'"'
		    		ENDIF 
	    		ENDIF 
	    	OTHERWISE 
	    	lctam='()'
	    	lcvalues=lcvalues+lcComa+'"'+"'+ALLTRIM("+lcnomc+")+'"+'"'
	    ENDCASE 

		lcRetEstru=lcRetEstru+lcComa2+'		'+lcnomc+' '+lctipoc+lctam+' '+lcprima+lcnotnull
		lcComa2=','+CHR(13)
		lcComa=','
	ENDFOR 

	lcvalores=''
	lccomval=''
	GO top
	IF !EOF()
		SCAN
			lcmicoman="lcComan1a='("+lcvalues+"'"+CHR(13)
			&lcmicoman
			lcvalores=lcvalores+lccomval+'insert into '+LOWER(lcTa)+' values '+lcComan1a
			lccomval=');'+CHR(13)
		ENDSCAN 
		lcvalores=lcvalores
	ELSE 
		lcvalores=''
	ENDIF 

	IF llabrio=.t.
		IF !EMPTY(lcalit)
			SELECT (lcalit)
		ENDIF 
		USE IN (lcTa)
	ENDIF 
	
	**RETURN 'create table '+LOWER(lcTa)+' ('+CHR(13)+lcRetEstru+','+CHR(13)+lcindices+") ENGINE=InnoDB DEFAULT CHARSET=utf8;"+CHR(13)+CHR(13)+lcvalores+IIF(!EMPTY(lcvalores),')','')
	RETURN 'create table '+LOWER(lcTa)+' ('+CHR(13)+lcRetEstru+','+CHR(13)+lcindices+") ENGINE=InnoDB DEFAULT CHARSET=utf8;"+CHR(13)+CHR(13)+IIF(!EMPTY(""),')','')
ENDFUNC 



FUNCTION _obtenerCamposdelaTabla(lcTablaOCDT as Character,lcTipoDatoOCDT as Integer)
	***** 	Funcion para obtener informacion de los cambos de una tabla 
	***** 	lcTipoDatoOCDT: 1=Nombre,2=Nombre y Tipo,3=Campos para Insertar,4=Campos para Actualizar

	LOCAL lcCamposOCDT,lcAndOCDT,lcAliasOCDT		&&& Inicializando variables locales
	STORE "" 		TO lcCamposOCDT,lcAndOCDT,lcAliasOCDT
	STORE ALIAS() 	to lcAliasOCDT


	IF PCOUNT( )<2						&&&& verificando que se hayan pasado parametros
		IF TYPE("lcTablaOCDT")<>"C"
			lcTablaOCDT=""
		ENDIF 
		IF TYPE("lcTipoDatoOCDT")<>"N"
			lcTipoDatoOCDT=1
		ENDIF 
	ENDIF 
	
	IF EMPTY(lcTablaOCDT)
		IF !EMPTY(lcAliasOCDT)
			lcTablaOCDT=lcAliasOCDT
		ENDIF 
	ENDIF 
	
	IF !EMPTY(lcTablaOCDT)
		IF lcTipoDatoOCDT<=2
			lncuatro=0
			lcunioncuatro=""
			FOR iOCDT=1 TO FCOUNT()
				lcCamposOCDT=lcCamposOCDT+lcAndOCDT+lcunioncuatro+LOWER(FIELD(iOCDT))+IIF(lcTipoDatoOCDT>1,CHR(9)+TYPE(FIELD(iOCDT)),"") && Muestra cada campo. 
				lcAndOCDT=","+IIF(lcTipoDatoOCDT>1,CHR(13),"")
				lncuatro=lncuatro+1
				IF lncuatro=6
					lncuatro=0
					lcunioncuatro=";"+chr(13)
				ELSE
					lcunioncuatro=""
				ENDIF 
			ENDFOR 
		ELSE
			DO CASE 
				CASE lcTipoDatoOCDT=3
					lcCamposOCDT='"VALUES ("+'
					FOR iOCDT=1 TO FCOUNT()
						lcinicio= IIF(TYPE(FIELD(iOCDT))="C",'"'+CHR(39)+'"+ALLTRIM(_sincomillias(',IIF(TYPE(FIELD(iOCDT))="T",'"'+CHR(39)+'"+_ConvertirToFechaHoraSQL((',IIF(TYPE(FIELD(iOCDT))="D",'"'+CHR(39)+'"+_ConvertirToFechaSQL((','""+ALLTRIM(STR(')))
						lcfin=IIF(TYPE(FIELD(iOCDT))="C" or TYPE(FIELD(iOCDT))="T" or TYPE(FIELD(iOCDT))="D",'))+"'+CHR(39)+',"+;'+CHR(13),',18,8))+","+;'+CHR(13))
						lcCamposOCDT=lcCamposOCDT+lcinicio+LOWER(FIELD(iOCDT))+lcfin && Muestra cada campo. 
					ENDFOR 
					
				CASE lcTipoDatoOCDT=4
					lcCamposOCDT=""
					FOR iOCDT=1 TO FCOUNT()
						lcCamposOCDT=lcCamposOCDT+LOWER(FIELD(iOCDT))+"=a."+LOWER(FIELD(iOCDT))+",;"+CHR(13)
					ENDFOR 

				CASE lcTipoDatoOCDT=5
					lcCamposOCDT='"SET "+'
					FOR iOCDT=1 TO FCOUNT()
						lcinicio= IIF(TYPE(FIELD(iOCDT))="C",'='+CHR(39)+'"+ALLTRIM(_sincomillias(',IIF(TYPE(FIELD(iOCDT))="T",'='+CHR(39)+'"+_ConvertirToFechaHoraSQL((',IIF(TYPE(FIELD(iOCDT))="D",'='+CHR(39)+'"+_ConvertirToFechaSQL((','="+ALLTRIM(STR(')))
						lcfin=IIF(TYPE(FIELD(iOCDT))="C" or TYPE(FIELD(iOCDT))="T" or TYPE(FIELD(iOCDT))="D",'))+"'+CHR(39)+',"+;'+CHR(13),'))+","+;'+CHR(13))
						lcCamposOCDT=lcCamposOCDT+'"'+LOWER(FIELD(iOCDT))+lcinicio+LOWER(FIELD(iOCDT))+lcfin && Muestra cada campo. 
					ENDFOR 

				CASE lcTipoDatoOCDT=6
					lcCamposOCDT=""
					FOR iOCDT=1 TO FCOUNT()
						lcCamposOCDT=lcCamposOCDT+'.txt'+LOWER(FIELD(iOCDT))+'.ControlSource=.cursor+".'+LOWER(FIELD(iOCDT))+'"'+CHR(13)
					ENDFOR 

				CASE lcTipoDatoOCDT=7
					lcCamposOCDT=""
					FOR iOCDT=1 TO FCOUNT()
						lcCamposOCDT=lcCamposOCDT+LOWER(lcTablaOCDT)+"."+LOWER(FIELD(iOCDT))+","
					ENDFOR 

					
			ENDCASE 
		ENDIF 
	ENDIF 


	IF !EMPTY(lcAliasOCDT)
		SELECT (lcAliasOCDT)
	ENDIF 

	RETURN lcCamposOCDT	
	
ENDFUNC 

FUNCTION _GenerarScripParaSincronizarTablas(lcTablaOCDT as Character)
	***** 	Funcion para obtener informacion de los cambos de una tabla 
	***** 	lcTipoDatoOCDT: 1=Nombre,2=Nombre y Tipo,3=Campos para Insertar,4=Campos para Actualizar

	LOCAL lcCamposOCDT,lcAndOCDT,lcAliasOCDT,lcscript		&&& Inicializando variables locales
	STORE "" 		TO lcCamposOCDT,lcAndOCDT,lcAliasOCDT,lcscript
	STORE ALIAS() 	to lcAliasOCDT
	lcTipoDatoOCDT=1
	
	IF EMPTY(lcTablaOCDT)
		IF !EMPTY(lcAliasOCDT)
			lcTablaOCDT=lcAliasOCDT
		ENDIF 
	ENDIF 
	
	IF USED(lcTablaOCDT)
		SELECT (lcTablaOCDT)
		llestausada=.t.
	ELSE
		USE pcsysdir+pcDB+"\"+lcTablaOCDT IN 0 SHARED AGAIN 
		SELECT (lcTablaOCDT)
		llestausada=.f. 
	ENDIF 
	
	lcscript='LPARAMETERS lncttrol,mifecact'+CHR(13)+CHR(13)
	lcscript=lcscript+'DO case'+CHR(13)
	lcscript=lcscript+'	CASE lncttrol=1'+CHR(13)+;
			 '		lccomandoretorna="UPDATE "+lcTabAcya+" "+;'+CHR(13)+;
			 '							"SET "+;'+CHR(13)

	****** primer caso
	FOR iOCDT=1 TO FCOUNT()
		*lcinicio= IIF(TYPE(FIELD(iOCDT))="C",'='+CHR(39)+'"+ALLTRIM(_sincomillias(',IIF(TYPE(FIELD(iOCDT))="T",'=CTOT('+CHR(39)+'"+TTOC(NVL(',IIF(TYPE(FIELD(iOCDT))="D",'=CTOD('+CHR(39)+'"+DTOC(NVL(','="+ALLTRIM(STR(')))
		lcinicio= IIF(TYPE(FIELD(iOCDT))="C" or TYPE(FIELD(iOCDT))="M",;
			'='+CHR(39)+'"+ALLTRIM(_sincomillias(',;
			IIF(TYPE(FIELD(iOCDT))="T",;
				'=CTOT('+CHR(39)+'"+TTOC(NVL(',;
				IIF(TYPE(FIELD(iOCDT))="D",;
					'=CTOD('+CHR(39)+'"+DTOC(NVL(',;
					'="+ALLTRIM(STR(')))
		**lcfin=IIF(TYPE(FIELD(iOCDT))="C" or TYPE(FIELD(iOCDT))="T" or TYPE(FIELD(iOCDT))="D",',CTOT('+CHR(39)+' '+CHR(39)+')))+"'+CHR(39)+'),"+;'+CHR(13),'))+","+;'+CHR(13))
		lcfin=IIF(TYPE(FIELD(iOCDT))="C" or TYPE(FIELD(iOCDT))="M",;
			'))+"'+CHR(39)+',"+;'+CHR(13),;
			IIF(TYPE(FIELD(iOCDT))="T",;
				',CTOT('+CHR(39)+' '+CHR(39)+')))+"'+CHR(39)+'),"+;'+CHR(13),;
				IIF(TYPE(FIELD(iOCDT))="D",;
					',CTOD('+CHR(39)+' '+CHR(39)+')))+"'+CHR(39)+'),"+;'+CHR(13),;
					',18,8))+","+;'+CHR(13))))
		IF LOWER(FIELD(iocdt))='fecactu'
			micampo='mifecact'
		ELSE
			micampo=LOWER(FIELD(iocdt))
		ENDIF 
		
		IF LOWER(FIELD(iocdt))<>'fecalta' and iocdt<>1 AND LOWER(FIELD(iocdt))<>'saldo' AND LOWER(FIELD(iocdt))<>'existencia' 
			lcscript=lcscript+'									'+;
				'"'+LOWER(FIELD(iOCDT))+lcinicio+micampo+lcfin && Muestra cada campo. 
		ENDIF 
	ENDFOR 
	lcscript=lcscript+'								"WHERE '+FIELD(1)+'="+ALLTRIM(STR('+FIELD(1)+'))'+CHR(13)+CHR(13)
	
		
	***** segundo caso
	lcscript=lcscript+'	CASE lncttrol=2'+CHR(13)
	lcscript=lcscript+'		lccomandoretorna="INSERT INTO "+lcTabAcya+" ("+;'+CHR(13)
	lcscript=lcscript+'								"'
	lncuatro=0
	lcunioncuatro=''
	lcinicio='								"'
	lccoma=''
	lcAndOCDT=''
	FOR iOCDT=1 TO FCOUNT()
		lncuatro=lncuatro+1
		IF lncuatro=6
			lncuatro=0
			lcunioncuatro='"+;'+chr(13)+'								"'
		ELSE
			lcunioncuatro=''
		ENDIF 

		lcscript=lcscript+lcAndOCDT+lcunioncuatro+LOWER(FIELD(iOCDT))+IIF(lcTipoDatoOCDT>1,CHR(9)+TYPE(FIELD(iOCDT)),"") && Muestra cada campo. 
		lcAndOCDT=","+IIF(lcTipoDatoOCDT>1,CHR(13),"")
		
	ENDFOR 
	lcscript=lcscript+') "+;'+CHR(13)+'						'
	lcscript=lcscript+'"VALUES ("+;'+CHR(13)
	FOR iOCDT=1 TO FCOUNT()
		*lcinicio= '							'+IIF(TYPE(FIELD(iOCDT))="C",'"'+CHR(39)+'"+ALLTRIM(_sincomillias(',IIF(TYPE(FIELD(iOCDT))="T",'"'+CHR(39)+'"+CTOT(NVL(',IIF(TYPE(FIELD(iOCDT))="D",'"'+CHR(39)+'"+DTOC(NVL(','""+ALLTRIM(STR(')))
		*lcfin=IIF(TYPE(FIELD(iOCDT))="C" or TYPE(FIELD(iOCDT))="T" or TYPE(FIELD(iOCDT))="D",'))+"'+CHR(39)+',"+;'+CHR(13),',18,8))+","+;'+CHR(13))
		lcinicio= IIF(TYPE(FIELD(iOCDT))="C" or TYPE(FIELD(iOCDT))="M",;
			'							"'+CHR(39)+'"+ALLTRIM(_sincomillias(',;
			IIF(TYPE(FIELD(iOCDT))="T",;
				'							"CTOT('+CHR(39)+'"+TTOC(NVL(',;
				IIF(TYPE(FIELD(iOCDT))="D",;
					'							"CTOD('+CHR(39)+'"+DTOC(NVL(',;
					'							""+ALLTRIM(STR(')))
		**lcfin=IIF(TYPE(FIELD(iOCDT))="C" or TYPE(FIELD(iOCDT))="T" or TYPE(FIELD(iOCDT))="D",',CTOT('+CHR(39)+' '+CHR(39)+')))+"'+CHR(39)+'),"+;'+CHR(13),'))+","+;'+CHR(13))
		lcfin=IIF(TYPE(FIELD(iOCDT))="C" or TYPE(FIELD(iOCDT))="M",;
			'))+"'+CHR(39)+',"+;'+CHR(13),;
			IIF(TYPE(FIELD(iOCDT))="T",;
				',CTOT('+CHR(39)+' '+CHR(39)+')))+"'+CHR(39)+'),"+;'+CHR(13),;
				IIF(TYPE(FIELD(iOCDT))="D",;
					',CTOD('+CHR(39)+' '+CHR(39)+')))+"'+CHR(39)+'),"+;'+CHR(13),;
					',18,8))+","+;'+CHR(13))))
		DO case
			CASE LOWER(FIELD(iocdt))='fecactu'
				micampo='mifecact'
			CASE SUBSTR(LOWER(FIELD(iocdt)),1,5)='saldo'
				micampo='0'	
			CASE LOWER(FIELD(iocdt))='existencia'
				micampo='0'
			OTHERWISE 
			micampo=LOWER(FIELD(iocdt))
		ENDCASE
		
		lcscript=lcscript+lcinicio+micampo+lcfin && Muestra cada campo. 
	ENDFOR 
	lcscript=lcscript+'							") "'
	lcscript=lcscript+CHR(13)+CHR(13)
	
	
	***** tercero caso
	lcscript=lcscript+'	CASE lncttrol=3'+CHR(13)
	lcscript=lcscript+'		lccomandoretorna="INSERT INTO "+lcTabAcya+" ("+;'+CHR(13)
	lcscript=lcscript+'								"'
	lncuatro=0
	lcunioncuatro=''
	lcinicio='								"'
	lccoma=''
	lcAndOCDT=''
	FOR iOCDT=1 TO FCOUNT()
		lncuatro=lncuatro+1
		IF lncuatro=6
			lncuatro=0
			lcunioncuatro='"+;'+chr(13)+'								"'
		ELSE
			lcunioncuatro=''
		ENDIF 

		lcscript=lcscript+lcAndOCDT+lcunioncuatro+LOWER(FIELD(iOCDT))+IIF(lcTipoDatoOCDT>1,CHR(9)+TYPE(FIELD(iOCDT)),"") && Muestra cada campo. 
		lcAndOCDT=","+IIF(lcTipoDatoOCDT>1,CHR(13),"")
		
	ENDFOR 
	lcscript=lcscript+') "+;'+CHR(13)+'						'
	lcscript=lcscript+'"VALUES ("+;'+CHR(13)
	FOR iOCDT=1 TO FCOUNT()
		lcinicio= '							'+IIF(TYPE(FIELD(iOCDT))="C" or TYPE(FIELD(iOCDT))="M",'"'+CHR(39)+'"+ALLTRIM(_sincomillias(',IIF(TYPE(FIELD(iOCDT))="T",'"'+CHR(39)+'"+_ConvertirToFechaHoraSQL((',IIF(TYPE(FIELD(iOCDT))="D",'"'+CHR(39)+'"+_ConvertirToFechaSQL((','""+ALLTRIM(STR(')))
		lcfin=IIF(TYPE(FIELD(iOCDT))="C" or TYPE(FIELD(iOCDT))="T" or TYPE(FIELD(iOCDT))="D" or TYPE(FIELD(iOCDT))="M",'))+"'+CHR(39)+',"+;'+CHR(13),',18,8))+","+;'+CHR(13))
		DO case
			CASE LOWER(FIELD(iocdt))='fecactu'
				micampo='mifecact'
			CASE SUBSTR(LOWER(FIELD(iocdt)),1,5)='saldo'
				micampo='0'	
			CASE LOWER(FIELD(iocdt))='existencia'
				micampo='0'
			OTHERWISE 
			micampo=LOWER(FIELD(iocdt))
		ENDCASE
		
		lcscript=lcscript+lcinicio+micampo+lcfin && Muestra cada campo. 
	ENDFOR 
	lcscript=lcscript+'							") "'
	lcscript=lcscript+CHR(13)+CHR(13)
	
	
	***** cuarto caso
	lcscript=lcscript+'	CASE lncttrol=4'+CHR(13)+;
			 '		lccomandoretorna="UPDATE "+lcTabAcya+" "+;'+CHR(13)+;
			 '							"SET "+;'+CHR(13)
	FOR iOCDT=1 TO FCOUNT()
		lcinicio= IIF(TYPE(FIELD(iOCDT))="C" or TYPE(FIELD(iOCDT))="M",'='+CHR(39)+'"+ALLTRIM(_sincomillias(',IIF(TYPE(FIELD(iOCDT))="T",'='+CHR(39)+'"+_ConvertirToFechaHoraSQL((',IIF(TYPE(FIELD(iOCDT))="D",'='+CHR(39)+'"+_ConvertirToFechaSQL((','="+ALLTRIM(STR(')))
		lcfin=IIF(TYPE(FIELD(iOCDT))="C" or TYPE(FIELD(iOCDT))="T" or TYPE(FIELD(iOCDT))="D" or TYPE(FIELD(iOCDT))="M",'))+"'+CHR(39)+',"+;'+CHR(13),',18,8))+","+;'+CHR(13))
		IF LOWER(FIELD(iocdt))='fecactu'
			micampo='mifecact'
		ELSE
			micampo=LOWER(FIELD(iocdt))
		ENDIF 
		IF LOWER(FIELD(iocdt))<>'fecalta' and iocdt<>1 AND LOWER(FIELD(iocdt))<>'saldo' AND LOWER(FIELD(iocdt))<>'existencia' 
			lcscript=lcscript+'									'+;
				'"'+LOWER(FIELD(iOCDT))+lcinicio+micampo+lcfin && Muestra cada campo. 
		ENDIF 
		
	ENDFOR 
	lcscript=lcscript+'								"WHERE '+FIELD(1)+'="+ALLTRIM(STR('+FIELD(1)+'))'+CHR(13)+CHR(13)
	
	lcscript=lcscript+'ENDCASE '+CHR(13)
	lcscript=lcscript+'RETURN lccomandoretorna'
	
	
	IF !EMPTY(lcAliasOCDT)
		SELECT (lcAliasOCDT)
	ENDIF 
	
	IF llestausada=.f.
		USE IN (lcTablaOCDT)
	ENDIF 

	RETURN lcscript
	
ENDFUNC 


FUNCTION _ObtenerPadreCta2(lcCodCtaPadB,lnNivCtaHija)
	lcCodCtaPadB=ALLTRIM(lcCodCtaPadB)
	lnRetTipoPadB=0
	IF LEN(lcCodCtaPadB)>1 AND lnNivCtaHija>1
		lcAliasctatPadB=ALIAS()
		USE pcsysdir+pcDB+"\ctbCuentas" SHARED AGAIN ORDER idcuenta IN 0 ALIAS tmpCtaPadB
		SELECT tmpCtaPadB
		LOCATE FOR ALLTRIM(codcta)==SUBSTR(lcCodCtaPadB,1,paLargoNivel(lnNivCtaHija-1)) AND !ALLTRIM(codcta)==ALLTRIM(lcCodCtaPadB)
		IF FOUND()
			IF nivel<=lnNivCtaHija
				lnRetTipoPadB=idcuenta
			ELSE 
				lnRetTipoPadB=0
			ENDIF 
		ENDIF 
		USE IN tmpCtaPadB
		IF !EMPTY(lcAliasctatPadB)
			SELECT (lcAliasctatPadB)
		ENDIF 
	ENDIF 
	RETURN lnRetTipoPadB
ENDFUNC 


**********************************
**********************************
**** Kardex de Productos *********
**********************************
PROCEDURE _insertkardex
	IF TYPE('llEstamosCorriendoFVP') = 'U'
	    RETURN .t.
	ELSE

	* lógica normal del ERP
		LOCAL lcidAliasExiBodIns,lcidMensExiBodIns,llTaKarInsAbierta,llTaExiBodInsAbierta,llTaCataBodInsAbierta,;
				lnidproExiIns,lccodExiIns,lnIdbodExiIns,lnidbodTraExiIns,lnEntSalExiBod,llokExiIns,;
				lncantiExiIns,lnCostoExiIns,lnCostoTotalExiIns
		
		IF plRecosteando=.t.
			RETURN .t.  &&& si se esta insertando cuentas desde la sincronizacion, no se hace nada
		ELSE	
			STORE ALIAS() TO lcidAliasExiBodIns
			STORE '' TO lcidMensExiBodIns
			STORE .t. TO llokExiIns

			STORE idproducto 	TO lnidproExiIns
			STORE idbodega 		TO lnIdbodExiIns
			STORE idbodegatras 	TO lnidbodTraExiIns
			STORE ctrolinv 		TO lnEntSalExiBod
			STORE cantidad 		TO lncantiExiIns
			STORE costounitario	TO lnCostoExiIns
			STORE preciosiniva	TO lnpreciosi
			STORE costototal 	TO lnCostoTotalExiIns
			STORE tipoprod 		TO lnTipProExiIns
			STORE fecalta		TO ltfecaltaprex
			STORE fecmod 		TO ltfecmodprex
			STORE nodo			TO lcnodprex
			STORE iduser		TO lnusrprex
			STORE pcuser		TO lcpcusprex
			STORE eliminado		TO lneliminado
			STORE origen		TO lcorigenmov
			STORE idtipodocto	TO lnidtipo
			STORE iddocto 		TO lniddoc
			STORE fechadocto	TO ldfecd
			STORE idclipro		TO lnidclpr
			STORE llavelote		TO lnLlaveLote

			************ Abriendo Tablas Necesarias si no estan abiertas todavia
			llTaExiBodInsAbierta=!USED("taexiIns")
			IF llTaExiBodInsAbierta
				USE pcsysdir+pcDB+"\invexisbodega" IN 0 SHARED AGAIN ALIAS taexiIns ORDER llave		&&idbodega+idproducto
			ENDIF 
			
			llTaExiBodLoteInsAbierta=!USED("taexiInsLote")
			IF llTaExiBodLoteInsAbierta
				USE pcsysdir+pcDB+"\invexisbodegaLote" IN 0 SHARED AGAIN ALIAS taexiInsLote ORDER llave		&&idbodega+idproducto+idlote
			ENDIF
			
			llTaCataBodInsAbierta=!USED("tacataIns")
			IF llTaCataBodInsAbierta
				USE pcsysdir+pcDB+"\invproductos" IN 0 SHARED AGAIN ALIAS tacataIns ORDER idproducto
			ENDIF 
			llTaTipBodInsAbierta=!USED("sistipodoctos")
			IF llTaTipBodInsAbierta
				USE pcsysdir+pcDB+"\sistipodoctos" IN 0 SHARED AGAIN ORDER IDTIPODOCT
			ENDIF 

			****** iniciando la actualizacion de existencias en el catalogo y en las bodegas
			
			IF SEEK(lnidproExiIns,"tacataIns")
				lccodExiIns=ALLTRIM(tacataIns.codprod)
				lnConNegativos=tacataIns.connegativos
			ELSE 
				lcidMensExiBodIns="No se encontró el registro con id: "+ALLTRIM(STR(lnidproExiIns))
				lccodExiIns=""
				llokExiIns=.f.
				lnConNegativos=0
			ENDIF 


			IF llokExiIns AND lnTipProExiIns=1 AND INLIST(lnEntSalExiBod,2,3) AND lncantiExiIns<>0 AND lnCostoTotalExiIns=0
				lnCostoTotalExiIns=lncantiExiIns*NVL(tacataIns.costopromedio,0)
			ENDIF 
			IF 	llokExiIns	AND lneliminado=0	&&& si todo bien continuamos y el registro no era un borrador eliminado
				***********************************
				***** actualizando catalogo  ******
				IF lnEntSalExiBod=1		&&& entrada
					IF lnTipProExiIns=3			&&&& es item servicio/gastos
						lnNewProExiBod=lnCostoExiIns
					ELSE
						lnNewProExiBod=IIF((NVL(tacataIns.existencia,0)+lncantiExiIns)=0,NVL(tacataIns.costopromedio,0),ABS((NVL(tacataIns.costototal,0)+lnCostoTotalExiIns)/(tacataIns.existencia+lncantiExiIns)))
					ENDIF 
					REPLACE existencia WITH NVL(tacataIns.existencia,0)+lncantiExiIns,;
						costototal WITH NVL(tacataIns.costototal,0)+lnCostoTotalExiIns,;
						costopromedio WITH lnNewProExiBod NEXT 1 IN tacataIns
					IF _tallY=0
						lcidMensExiBodIns="No fue posible Actualizar la Existencia del Registro  "+lccodExiIns
						llokExiIns=.f.
					ENDIF 
					****** se quito esta linea por que solo debe evaluarse la existencia en la bodega no en el producto global
	*!*					IF tacataIns.existencia<0 AND lnTipProExiIns=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
	*!*						lcidMensExiBodIns="Existencia Negativa en el Registro  "+lccodExiIns
	*!*						llokExiIns=.f.
	*!*					ENDIF 
					IF lcorigenmov='COM'
						IF SEEK(lnidtipo,'sistipodoctos','IDTIPODOCT')
							llEsCompra=INLIST(sistipodoctos.tipoicv,4,6,9,12,14,15)
						ELSE
							llEsCompra=.f.
						ENDIF
						IF llEsCompra	&&&& es compra y hay que guardar el ultimo dato de compra
							IF NVL(tacataIns.ultfechacompra,CTOD(' '))<=ldfecd OR EMPTY(NVL(tacataIns.ultfechacompra,CTOD(' ')))
								REPLACE tacataIns.ultcostocompra WITH lnCostoExiIns,;
										tacataIns.ultiddoctocompra with lniddoc,;
										tacataIns.ultfechacompra with ldfecd,;
										tacataIns.ultidcliprocompra with lnidclpr next 1 in tacataIns
							ENDIF 
						ENDIF  
					ENDIF 
					
				ENDIF 

				IF lnEntSalExiBod=2		&&& salida
					IF lnTipProExiIns=3
						lnNewProExiBod=lnCostoExiIns
					ELSE
						lnNewProExiBod=IIF((NVL(tacataIns.existencia,0)-lncantiExiIns)=0,NVL(tacataIns.costopromedio,0),ABS((NVL(tacataIns.costototal,0)-lnCostoTotalExiIns)/(tacataIns.existencia-lncantiExiIns)))
					ENDIF 
					REPLACE existencia WITH NVL(tacataIns.existencia,0)-lncantiExiIns,;
						costototal WITH NVL(tacataIns.costototal,0)-lnCostoTotalExiIns,;
						costopromedio WITH lnNewProExiBod NEXT 1 IN tacataIns
					IF _tallY=0
						lcidMensExiBodIns="No fue posible Actualizar la Existencia del Registro  "+lccodExiIns
						llokExiIns=.f.
					ENDIF 
					***** se quito esta linea por que solo debe evaluarse la existencia en la bodega no en el producto global
	*!*					IF tacataIns.existencia<0  AND lnTipProExiIns=1 AND plconExistenciasNegativas=.f.  AND lnConNegativos=0
	*!*						lcidMensExiBodIns="Existencia Negativa en el Registro  "+lccodExiIns
	*!*						llokExiIns=.f.
	*!*					ENDIF 
					IF lcorigenmov='VTA'
						IF SEEK(lnidtipo,'sistipodoctos','IDTIPODOCT')
							llEsVenta=INLIST(sistipodoctos.tipoicv,4,9,10,11,12)
						ELSE
							llEsVenta=.f.
						ENDIF
						IF llEsVenta	&&&& es compra y hay que guardar el ultimo dato de compra
							IF NVL(tacataIns.ultfechaventa,CTOD(' '))<=ldfecd OR EMPTY(NVL(tacataIns.ultfechaventa,CTOD(' ')))
								REPLACE tacataIns.ultprecioventa WITH lnpreciosi,;
										tacataIns.ultiddoctoventa with lniddoc,;
										tacataIns.ultfechaventa with ldfecd,;
										tacataIns.ultidcliproventa with lnidclpr next 1 in tacataIns
							ENDIF 
						ENDIF  
					ENDIF 
				ENDIF 
				**** si es traspaso no se hace nada en el catalgo

				*********************************
				***** Actualizando Bodegas ******
				IF llokExiIns &&& si todo bien continuamos
					IF !SEEK(STR(lnIdbodExiIns)+STR(lnidproExiIns),"taexiIns")		&&& si no esta lo inserta
						lnIdEXiBodNew=_SiguienteIdTabla(pcNodo,"SIS")
						INSERT INTO taexiIns (idexisbode,idproducto,idbodega,ubicacion,existencia,costo,costototal,fecalta,fecmod,nodo,iduser,pcuser) ;
								value (lnIdEXiBodNew,lnidproExiIns,lnIdbodExiIns,'',0,0,0,ltfecmodprex,ltfecmodprex,lcnodprex,lnusrprex,lcpcusprex) 
					ENDIF 

					IF SEEK(STR(lnIdbodExiIns)+STR(lnidproExiIns),"taexiIns")
						IF lnEntSalExiBod=1		&&& entrada
							lnNewProExiBod=IIF((NVL(taexiIns.existencia,0)+lncantiExiIns)=0,NVL(taexiIns.costo,0),ABS((NVL(taexiIns.costototal,0)+lnCostoTotalExiIns)/(NVL(taexiIns.existencia,0)+lncantiExiIns)))
							REPLACE existencia WITH NVL(taexiIns.existencia,0)+lncantiExiIns,;
								costototal WITH NVL(taexiIns.costototal,0)+lnCostoTotalExiIns,;
								costo WITH lnNewProExiBod NEXT 1 IN taexiIns
							IF _tallY=0
								lcidMensExiBodIns="No fue posible Actualizar la Existencia BODEGAS del Registro  "+lccodExiIns
								llokExiIns=.f.
							ENDIF
							**** se quito esta linea por que si es insercion de una entrada y el producto aun despues de la entrada es negativo siempre se inserta la entrada
	*!*							IF taexiIns.existencia<0 AND lnTipProExiIns=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
	*!*								lcidMensExiBodIns="Existencia Negativa en la bodega del Registro  "+lccodExiIns
	*!*								llokExiIns=.f.
	*!*							ENDIF 
						ENDIF 
						IF lnEntSalExiBod=2 OR lnEntSalExiBod=3		&&& salida o traspaso
							lnNewProExiBod=IIF((NVL(taexiIns.existencia,0)-lncantiExiIns)=0,NVL(taexiIns.costo,0),ABS((NVL(taexiIns.costototal,0)-lnCostoTotalExiIns)/(NVL(taexiIns.existencia,0)-lncantiExiIns)))
							REPLACE existencia WITH NVL(taexiIns.existencia,0)-lncantiExiIns,;
								costototal WITH NVL(taexiIns.costototal,0)-lnCostoTotalExiIns,;
								costo WITH lnNewProExiBod NEXT 1 IN taexiIns
							IF _tallY=0
								lcidMensExiBodIns="No fue posible Actualizar la Existencia BODEGAS del Registro  "+lccodExiIns
								llokExiIns=.f.
							ENDIF 
							IF taexiIns.existencia<0 AND lnTipProExiIns=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
								lcidMensExiBodIns="Existencia Negativa en la bodega del Registro  "+lccodExiIns
								llokExiIns=.f.
							ENDIF 
						ENDIF 
						IF lnEntSalExiBod=3		&&& Ingresamos la unidades en la bdega de traspaso
							IF !SEEK(STR(lnidbodTraExiIns)+STR(lnidproExiIns),"taexiIns")		&&& si no esta lo inserta
								lnIdEXiBodNew=_SiguienteIdTabla(pcNodo,"SIS")
								INSERT INTO taexiIns (idexisbode,idproducto,idbodega,ubicacion,existencia,costo,costototal,fecalta,fecmod,nodo,iduser,pcuser) ;
										value (lnIdEXiBodNew,lnidproExiIns,lnidbodTraExiIns,'',0,0,0,ltfecmodprex,ltfecmodprex,lcnodprex,lnusrprex,lcpcusprex) 
							ENDIF 

							IF SEEK(STR(lnidbodTraExiIns)+STR(lnidproExiIns),"taexiIns")
								lnNewProExiBod=IIF((NVL(taexiIns.existencia,0)+lncantiExiIns)=0,NVL(taexiIns.costo,0),ABS((NVL(taexiIns.costototal,0)+lnCostoTotalExiIns)/(NVL(taexiIns.existencia,0)+lncantiExiIns)))
								REPLACE existencia WITH NVL(taexiIns.existencia,0)+lncantiExiIns,;
									costototal WITH NVL(taexiIns.costototal,0)+lnCostoTotalExiIns,;
									costo WITH lnNewProExiBod NEXT 1 IN taexiIns
								IF _tallY=0
									lcidMensExiBodIns="No fue posible Actualizar la Existencia BODEGAS DE TRASPASO del Registro  "+lccodExiIns
									llokExiIns=.f.
								ENDIF 
								**** se quito esta linea por que si se esta insertando un traspaso para enviarle a esta bodega no importa que quede en negativo
	*!*								IF taexiIns.existencia<0 AND lnTipProExiIns=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
	*!*									lcidMensExiBodIns="Existencia Negativa en la bodega del Registro  "+lccodExiIns
	*!*									llokExiIns=.f.
	*!*								ENDIF 
							ELSE
								lcidMensExiBodIns="No fue posible Encontra la Bodega de TRASPASO en el registro "+lccodExiIns
							ENDIF 
						ENDIF 				
					ELSE 
						lcidMensExiBodIns="No fue posible Encontra la Bodega en el registro "+lccodExiIns
					ENDIF 
				ENDIF 
			ENDIF 
			
			
			
			********** todo esto aqui es igual que  lo anterior pero en la bodega por lotes
			IF lnLlaveLote<>0
				IF 	llokExiIns	AND lneliminado=0	&&& si todo bien continuamos y el registro no era un borrador eliminado
					*********************************
					***** Actualizando Bodegas ******
					IF llokExiIns &&& si todo bien continuamos
						IF !SEEK(STR(lnIdbodExiIns)+STR(lnidproExiIns)+STR(lnLlaveLote),"taexiInsLote")		&&& si no esta lo inserta
							lnIdEXiBodLoteNew=_SiguienteIdTabla(pcNodo,"SIS")
							INSERT INTO taexiInsLote (idexisbodelote,idproducto,idbodega,idlote,existencia,costo,costototal,fecalta,fecmod,nodo,iduser,pcuser) ;
									value (lnIdEXiBodLoteNew,lnidproExiIns,lnIdbodExiIns,lnLlaveLote,0,0,0,ltfecmodprex,ltfecmodprex,lcnodprex,lnusrprex,lcpcusprex) 
						ENDIF 

						IF SEEK(STR(lnIdbodExiIns)+STR(lnidproExiIns)+STR(lnLlaveLote),"taexiInsLote")
							IF lnEntSalExiBod=1		&&& entrada
								lnNewProExiBod=IIF((NVL(taexiInsLote.existencia,0)+lncantiExiIns)=0,NVL(taexiInsLote.costo,0),ABS((NVL(taexiInsLote.costototal,0)+lnCostoTotalExiIns)/(NVL(taexiInsLote.existencia,0)+lncantiExiIns)))
								REPLACE existencia WITH NVL(taexiInsLote.existencia,0)+lncantiExiIns,;
									costototal WITH NVL(taexiInsLote.costototal,0)+lnCostoTotalExiIns,;
									costo WITH lnNewProExiBod NEXT 1 IN taexiInsLote
								IF _tallY=0
									lcidMensExiBodIns="No fue posible Actualizar la Existencia BODEGAS DEL LOTE del Registro  "+lccodExiIns
									llokExiIns=.f.
								ENDIF
								**** (ya no se quito )se quito esta linea por que si es insercion de una entrada y el producto aun despues de la entrada es negativo siempre se inserta la entrada
								IF taexiInsLote.existencia<0 AND lnTipProExiIns=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
									lcidMensExiBodIns="Existencia Negativa en la bodega del Registro  "+lccodExiIns
									llokExiIns=.f.
								ENDIF 
							ENDIF 
							IF lnEntSalExiBod=2 OR lnEntSalExiBod=3		&&& salida o traspaso
								lnNewProExiBod=IIF((NVL(taexiInsLote.existencia,0)-lncantiExiIns)=0,NVL(taexiInsLote.costo,0),ABS((NVL(taexiInsLote.costototal,0)-lnCostoTotalExiIns)/(NVL(taexiInsLote.existencia,0)-lncantiExiIns)))
								REPLACE existencia WITH NVL(taexiInsLote.existencia,0)-lncantiExiIns,;
									costototal WITH NVL(taexiInsLote.costototal,0)-lnCostoTotalExiIns,;
									costo WITH lnNewProExiBod NEXT 1 IN taexiInsLote
								IF _tallY=0
									lcidMensExiBodIns="No fue posible Actualizar la Existencia BODEGAS DEL LOTE del Registro  "+lccodExiIns
									llokExiIns=.f.
								ENDIF 
								IF taexiInsLote.existencia<0 AND lnTipProExiIns=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
									lcidMensExiBodIns="Existencia Negativa en la bodega por lote del Registro  "+lccodExiIns
									llokExiIns=.f.
								ENDIF 
							ENDIF 
							IF lnEntSalExiBod=3		&&& Ingresamos la unidades en la bdega de traspaso
								IF !SEEK(STR(lnidbodTraExiIns)+STR(lnidproExiIns)+STR(lnLlaveLote),"taexiInsLote")		&&& si no esta lo inserta
									lnIdEXiBodLoteNew=_SiguienteIdTabla(pcNodo,"SIS")
									INSERT INTO taexiInsLote (idexisbodelote,idproducto,idbodega,idlote,existencia,costo,costototal,fecalta,fecmod,nodo,iduser,pcuser) ;
											value (lnIdEXiBodLoteNew,lnidproExiIns,lnidbodTraExiIns,lnLlaveLote,0,0,0,ltfecmodprex,ltfecmodprex,lcnodprex,lnusrprex,lcpcusprex) 
								ENDIF 

								IF SEEK(STR(lnidbodTraExiIns)+STR(lnidproExiIns)+STR(lnLlaveLote),"taexiInsLote")
									lnNewProExiBod=IIF((NVL(taexiInsLote.existencia,0)+lncantiExiIns)=0,NVL(taexiInsLote.costo,0),ABS((NVL(taexiInsLote.costototal,0)+lnCostoTotalExiIns)/(NVL(taexiInsLote.existencia,0)+lncantiExiIns)))
									REPLACE existencia WITH NVL(taexiInsLote.existencia,0)+lncantiExiIns,;
										costototal WITH NVL(taexiInsLote.costototal,0)+lnCostoTotalExiIns,;
										costo WITH lnNewProExiBod NEXT 1 IN taexiInsLote
									IF _tallY=0
										lcidMensExiBodIns="No fue posible Actualizar la Existencia BODEGAS DE TRASPASO del Registro  "+lccodExiIns
										llokExiIns=.f.
									ENDIF 
									**** (si importa... se descomento esto) se quito esta linea por que si se esta insertando un traspaso para enviarle a esta bodega no importa que quede en negativo
									IF taexiInsLote.existencia<0 AND lnTipProExiIns=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
										lcidMensExiBodIns="Existencia Negativa en la bodega por lote del Registro  "+lccodExiIns
										llokExiIns=.f.
									ENDIF 
								ELSE
									lcidMensExiBodIns="No fue posible Encontra la Bodega de TRASPASO DEL LOTE en el registro "+lccodExiIns
								ENDIF 
							ENDIF 				
						ELSE 
							lcidMensExiBodIns="No fue posible Encontra la Bodega DEL LOTE en el registro "+lccodExiIns
						ENDIF 
					ENDIF 
				ENDIF 
				
			ENDIF 
			
			
			
			IF llTaExiBodInsAbierta
				USE IN taexiIns
			ENDIF 
			IF llTaExiBodLoteInsAbierta
				USE IN taexiInsLote
			ENDIF 
			IF llTaCataBodInsAbierta
				USE IN tacataIns
			ENDIF 
			IF llTaTipBodInsAbierta
				USE IN sistipodoctos
			ENDIF 
			
			SELECT (lcidAliasExiBodIns)
			
			
			IF EMPTY(lcidMensExiBodIns)
			    RETURN .t.
			ELSE
		        MESSAGEBOX(lcidMensExiBodIns,16,'Error de Integridad... (_insertkardex)',2000)
			    RETURN .f.
			ENDIF
			
		ENDIF 
	ENDIF
ENDPROC 




PROCEDURE _updatekardex

IF TYPE('llEstamosCorriendoFVP') = 'U'
    RETURN .t.
ELSE
	* lógica normal del ERP

		LOCAL lcidAliasExiBodEdi,lcidMensExiBodEdi,llTaKarEdiAbierta,llTaExiBodEdiAbierta,llTaCataBodEdiAbierta,;
				lnidproExiEdi,lccodExiEdi,lnIdbodExiEdi,lnidbodTraExiEdi,lnEntSalExiBod,llokExiEdi,;
				lncantiExiEdi,lnCostoExiEdi,lnCostoTotalExiEdi
		
		IF plRecosteando=.t.
			RETURN .t.  &&& si se esta insertando cuentas desde la sincronizacion, no se hace nada
		ELSE	
			STORE ALIAS() TO lcidAliasExiBodEdi
			STORE '' TO lcidMensExiBodEdi
			STORE .t. TO llokExiEdi

			STORE idproducto 	TO lnidproExiEdi
			STORE idbodega 		TO lnIdbodExiEdi
			STORE idbodegatras 	TO lnidbodTraExiEdi
			STORE status		TO lnstaExiEdi
			STORE eliminado		TO lnEliExiEdi
			STORE ctrolinv 		TO lnEntSalExiBod
			STORE cantidad 		TO lncantiExiEdi
			STORE costounitario	TO lnCostoExiEdi
			STORE costototal 	TO lnCostoTotalExiEdi
			STORE tipoprod		TO lnTipProExiEdi
			STORE CURVAL("cantidad")		TO lncantiExiEdiold
			STORE CURVAL("costounitario")	TO lnCostoExiEdiold
			STORE CURVAL("costototal")	 	TO lnCostoTotalExiEdiold
			STORE CURVAL("status")			TO lnstaExiEdiOld
			STORE CURVAL("eliminado")		TO lnEliExiEdiOld
			STORE fecalta		TO ltfecaltaprex
			STORE fecmod 		TO ltfecmodprex
			STORE nodo			TO lcnodprex
			STORE iduser		TO lnusrprex
			STORE pcuser		TO lcpcusprex
			STORE llavelote		TO lnLlaveLote

			IF (lnstaExiEdi=0 AND lnstaExiEdiOld<>lnstaExiEdi) OR (lnEliExiEdi=1 AND lnEliExiEdi<>lnEliExiEdiOld)
				IF lnEntSalExiBod=1
					lnEntSalExiBod=2
				ELSE 
					IF lnEntSalExiBod=2
						lnEntSalExiBod=1
					ENDIF 
					IF lnEntSalExiBod=3
						lnEntSalExiBod=4	&&& anulacion de traspaso
					ENDIF 
					
				ENDIF
			ELSE
				STORE lncantiExiEdi-lncantiExiEdiold TO lncantiExiEdi
				STORE lnCostoTotalExiEdi-lnCostoTotalExiEdiold 	TO lnCostoTotalExiEdi
			ENDIF 

			IF (lnstaExiEdi=0 AND lnstaExiEdiOld=lnstaExiEdi) or (lnEliExiEdi=1 AND lnEliExiEdi=lnEliExiEdiOld) OR (lnstaExiEdi=0 AND lnstaExiEdiold=-1) OR lnEntSalExiBod<=0
				lcidMensExiBodEdi=""		&&& no hay nada que hacer
			ELSE 
				************ Abriendo Tablas Necesarias si no estan abiertas todavia
				llTaExiBodEdiAbierta=!USED("taexiEdi")
				IF llTaExiBodEdiAbierta
					USE pcsysdir+pcDB+"\invexisbodega" IN 0 SHARED AGAIN ALIAS taexiEdi ORDER llave		&&idbodega+idproducto
				ENDIF 

				llTaExiBodLoteEdiAbierta=!USED("taexiEdiLote")
				IF llTaExiBodLoteEdiAbierta
					USE pcsysdir+pcDB+"\invexisbodegaLote" IN 0 SHARED AGAIN ALIAS taexiEdiLote ORDER llave		&&idbodega+idproducto+idlote
				ENDIF
				
				llTaCataBodEdiAbierta=!USED("tacataEdi")
				IF llTaCataBodEdiAbierta
					USE pcsysdir+pcDB+"\invproductos" IN 0 SHARED AGAIN ALIAS tacataEdi ORDER idproducto
				ENDIF 

				****** iniciando la actualizacion de existencias en el catalogo y en las bodegas
				IF SEEK(lnidproExiEdi,"tacataEdi")
					lccodExiEdi=ALLTRIM(tacataEdi.codprod)
					lnConNegativos=tacataEdi.ConNegativos
				ELSE 
					lcidMensExiBodEdi="No fue posible encontrar el registro con id: "+ALLTRIM(STR(lnidproExiEdi))
					lccodExiEdi=""
					llokExiEdi=.f.
					lnConNegativos=0
				ENDIF 


					IF llokExiEdi AND lnTipProExiEdi=1 AND lncantiExiEdi<>0 AND lnCostoTotalExiEdi=0 AND ;
						(INLIST(lnEntSalExiBod,2,3,4) OR (lnEntSalExiBod=1 AND INLIST(origen,'VTA','VTP')))
						lnCostoTotalExiEdi=lncantiExiEdi*NVL(tacataEdi.costopromedio,0)
					ENDIF 
				IF 	llokExiEdi		&&& si todo bien continuamos
					***********************************
					***** actualizando catalogo  ******
					IF lnEntSalExiBod=1	AND (lncantiExiEdi<>0 OR lnCostoTotalExiEdi<>0)	&&& entrada
						IF lnTipProExiEdi=3
							lnNewProExiBod=lnCostoExiEdi
						ELSE  
							lnNewProExiBod=IIF((NVL(tacataEdi.existencia,0)+lncantiExiEdi)=0,NVL(tacataEdi.costopromedio,0),ABS((NVL(tacataEdi.costototal,0)+lnCostoTotalExiEdi)/(tacataEdi.existencia+lncantiExiEdi)))
						ENDIF 
						REPLACE tacataEdi.existencia WITH NVL(tacataEdi.existencia,0)+lncantiExiEdi,;
							tacataEdi.costototal WITH NVL(tacataEdi.costototal,0)+lnCostoTotalExiEdi,;
							tacataEdi.costopromedio WITH lnNewProExiBod NEXT 1 IN tacataEdi
						IF _tallY=0
							lcidMensExiBodEdi="No fue posible Actualizar la Existencia del Registro  "+lccodExiEdi
							llokExiEdi=.f.
						ENDIF 
	*!*						IF tacataEdi.existencia<0 AND lnTipProExiEdi=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
	*!*							lcidMensExiBodEdi="Existencia Negativa en el Registro  "+lccodExiEdi
	*!*							llokExiEdi=.f.
	*!*						ENDIF 
					ENDIF 
					IF lnEntSalExiBod=2	AND (lncantiExiEdi<>0 OR lnCostoTotalExiEdi<>0)	&&& salida
						IF lnTipProExiEdi=3
							lnNewProExiBod=lnCostoExiEdi
						ELSE  
							lnNewProExiBod=IIF((NVL(tacataEdi.existencia,0)-lncantiExiEdi)=0,NVL(tacataEdi.costopromedio,0),ABS((NVL(tacataEdi.costototal,0)-lnCostoTotalExiEdi)/(tacataEdi.existencia-lncantiExiEdi)))
						ENDIF 
						REPLACE tacataEdi.existencia WITH NVL(tacataEdi.existencia,0)-lncantiExiEdi,;
							tacataEdi.costototal WITH NVL(tacataEdi.costototal,0)-lnCostoTotalExiEdi,;
							tacataEdi.costopromedio WITH lnNewProExiBod NEXT 1 IN tacataEdi
						IF _tallY=0
							lcidMensExiBodEdi="No fue posible Actualizar la Existencia del Registro  "+lccodExiEdi
							llokExiEdi=.f.
						ENDIF 
	*!*						IF tacataEdi.existencia<0 AND lnTipProExiEdi=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
	*!*							lcidMensExiBodEdi="Existencia Negativa en el Registro  "+lccodExiEdi
	*!*							llokExiEdi=.f.
	*!*						ENDIF 
						
					ENDIF 
					**** si es traspaso no se hace nada en el catalgo

					*********************************
					***** Actualizando Bodegas ******
					IF llokExiEdi		&&& si todo bien continuamos
						IF !SEEK(STR(lnIdbodExiEdi)+STR(lnidproExiEdi),"taexiEdi")		&&& si no esta lo inserta
							lnIdEXiBodNew=_SiguienteIdTabla(pcNodo,"SIS")
							INSERT INTO taexiEdi (idexisbode,idproducto,idbodega,ubicacion,existencia,costo,costototal,fecalta,fecmod,nodo,iduser,pcuser) ;
									value (lnIdEXiBodNew,lnidproExiEdi,lnIdbodExiEdi,'',0,0,0,ltfecmodprex,ltfecmodprex,lcnodprex,lnusrprex,lcpcusprex) 
						ENDIF 

						IF SEEK(STR(lnIdbodExiEdi)+STR(lnidproExiEdi),"taexiEdi")
							IF lnEntSalExiBod=1	OR lnEntSalExiBod=4	&&& entrada o anulacion de traspaso
								IF (lncantiExiEdi<>0 OR lnCostoTotalExiEdi<>0)	
									lnNewProExiBod=IIF((NVL(taexiEdi.existencia,0)+lncantiExiEdi)=0,NVL(taexiEdi.costo,0),ABS((NVL(taexiEdi.costototal,0)+lnCostoTotalExiEdi)/(NVL(taexiEdi.existencia,0)+lncantiExiEdi))) 
									REPLACE existencia WITH NVL(taexiEdi.existencia,0)+lncantiExiEdi,;
										costototal WITH NVL(taexiEdi.costototal,0)+lnCostoTotalExiEdi,;
										costo WITH lnNewProExiBod NEXT 1 IN taexiEdi
									IF _tallY=0
										lcidMensExiBodEdi="No fue posible Actualizar la Existencia BODEGAS del Registro  "+lccodExiEdi
										llokExiEdi=.f.
									ENDIF
									IF taexiEdi.existencia<0 AND lnTipProExiEdi=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
										lcidMensExiBodEdi="Existencia Negativa en la bodega del Registro  "+lccodExiEdi
										llokExiEdi=.f.
									ENDIF 
								ENDIF 
							ENDIF 
							IF lnEntSalExiBod=2	OR lnEntSalExiBod=3	&&& salida o traspaso
								IF (lncantiExiEdi<>0 OR lnCostoTotalExiEdi<>0)	
									lnNewProExiBod=IIF((NVL(taexiEdi.existencia,0)-lncantiExiEdi)=0,NVL(taexiEdi.costo,0),ABS((NVL(taexiEdi.costototal,0)-lnCostoTotalExiEdi)/(NVL(taexiEdi.existencia,0)-lncantiExiEdi)))
									REPLACE existencia WITH NVL(taexiEdi.existencia,0)-lncantiExiEdi,;
										costototal WITH NVL(taexiEdi.costototal,0)-lnCostoTotalExiEdi,;
										costo WITH lnNewProExiBod NEXT 1 IN taexiEdi
									IF _tallY=0
										lcidMensExiBodEdi="No fue posible Actualizar la Existencia BODEGAS del Registro  "+lccodExiEdi
										llokExiEdi=.f.
									ENDIF 
									IF taexiEdi.existencia<0 AND lnTipProExiEdi=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
										lcidMensExiBodEdi="Existencia Negativa en la bodega del Registro  "+lccodExiEdi
										llokExiEdi=.f.
									ENDIF 
								ENDIF 
							ENDIF 
							IF lnEntSalExiBod=3		&&& Ingresamos la unidades en la bdega de traspaso
								IF (lncantiExiEdi<>0 OR lnCostoTotalExiEdi<>0)	
									IF !SEEK(STR(lnidbodTraExiEdi)+STR(lnidproExiEdi),"taexiEdi")		&&& si no esta lo inserta
										lnIdEXiBodNew=_SiguienteIdTabla(pcNodo,"SIS")
										INSERT INTO taexiEdi (idexisbode,idproducto,idbodega,ubicacion,existencia,costo,costototal,fecalta,fecmod,nodo,iduser,pcuser) ;
												value (lnIdEXiBodNew,lnidproExiEdi,lnidbodTraExiEdi,'',0,0,0,ltfecmodprex,ltfecmodprex,lcnodprex,lnusrprex,lcpcusprex) 
									ENDIF 
									IF SEEK(STR(lnidbodTraExiEdi)+STR(lnidproExiEdi),"taexiEdi")
										lnNewProExiBod=IIF((NVL(taexiEdi.existencia,0)+lncantiExiEdi)=0,NVL(taexiEdi.costo,0),ABS((NVL(taexiEdi.costototal,0)+lnCostoTotalExiEdi)/(NVL(taexiEdi.existencia,0)+lncantiExiEdi))) 
										REPLACE existencia WITH NVL(taexiEdi.existencia,0)+lncantiExiEdi,;
											costototal WITH NVL(taexiEdi.costototal,0)+lnCostoTotalExiEdi,;
											costo WITH lnNewProExiBod NEXT 1 IN taexiEdi
										IF _tallY=0
											lcidMensExiBodEdi="No fue posible Actualizar la Existencia BODEGAS DE TRASPASO del Registro  "+lccodExiEdi
											llokExiEdi=.f.
										ENDIF 
										IF taexiEdi.existencia<0 AND lnTipProExiEdi=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
											lcidMensExiBodEdi="Existencia Negativa en la bodega del Registro  "+lccodExiEdi
											llokExiEdi=.f.
										ENDIF 
									ELSE
										lcidMensExiBodEdi="No fue posible Encontra la Bodega de TRASPASO en el registro "+lccodExiEdi
									ENDIF 
								ENDIF 
							ENDIF 				
							IF lnEntSalExiBod=4		&&& Anulamos las unidades en la bdega de traspaso
								IF (lncantiExiEdi<>0 OR lnCostoTotalExiEdi<>0)	
									IF !SEEK(STR(lnidbodTraExiEdi)+STR(lnidproExiEdi),"taexiEdi")		&&& si no esta lo inserta
										lnIdEXiBodNew=_SiguienteIdTabla(pcNodo,"SIS")
										INSERT INTO taexiEdi (idexisbode,idproducto,idbodega,ubicacion,existencia,costo,costototal,fecalta,fecmod,nodo,iduser,pcuser) ;
												value (lnIdEXiBodNew,lnidproExiEdi,lnidbodTraExiEdi,'',0,0,0,ltfecmodprex,ltfecmodprex,lcnodprex,lnusrprex,lcpcusprex) 
									ENDIF 

									IF SEEK(STR(lnidbodTraExiEdi)+STR(lnidproExiEdi),"taexiEdi")
										lnNewProExiBod=IIF((NVL(taexiEdi.existencia,0)-lncantiExiEdi)=0,NVL(taexiEdi.costo,0),ABS((NVL(taexiEdi.costototal,0)-lnCostoTotalExiEdi)/(NVL(taexiEdi.existencia,0)-lncantiExiEdi)))
										REPLACE existencia WITH NVL(taexiEdi.existencia,0)-lncantiExiEdi,;
											costototal WITH NVL(taexiEdi.costototal,0)-lnCostoTotalExiEdi,;
											costo WITH lnNewProExiBod NEXT 1 IN taexiEdi
										IF _tallY=0
											lcidMensExiBodEdi="No fue posible Actualizar la Existencia BODEGAS DE TRASPASO del Registro  "+lccodExiEdi
											llokExiEdi=.f.
										ENDIF 
										IF taexiEdi.existencia<0 AND lnTipProExiEdi=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
											lcidMensExiBodEdi="Existencia Negativa en la bodega...  del Registro  "+lccodExiEdi
											llokExiEdi=.f.
										ENDIF 
									ELSE
										lcidMensExiBodEdi="No fue posible Encontra la Bodega de TRASPASO en el registro "+lccodExiEdi
									ENDIF 
								ENDIF 
							ENDIF 				
						ELSE 
							lcidMensExiBodEdi="No fue posible Encontra la Bodega en el registro "+lccodExiEdi
						ENDIF 
					ENDIF 
					
					
					
					*********************************
					***** Actualizando Bodegas POR LOTE ******
					IF lnLlaveLote<>0
						IF llokExiEdi		&&& si todo bien continuamos
							IF !SEEK(STR(lnIdbodExiEdi)+STR(lnidproExiEdi)+STR(lnLlaveLote),"taexiEdiLote")		&&& si no esta lo inserta
								lnIdEXiBodNew=_SiguienteIdTabla(pcNodo,"SIS")
								INSERT INTO taexiEdiLote (idexisbode,idproducto,idbodega,idlote,ubicacion,existencia,costo,costototal,fecalta,fecmod,nodo,iduser,pcuser) ;
										value (lnIdEXiBodNew,lnidproExiEdi,lnIdbodExiEdi,lnLlaveLote,'',0,0,0,ltfecmodprex,ltfecmodprex,lcnodprex,lnusrprex,lcpcusprex) 
							ENDIF 

							IF SEEK(STR(lnIdbodExiEdi)+STR(lnidproExiEdi)+STR(lnLlaveLote),"taexiEdiLote")
								IF lnEntSalExiBod=1	OR lnEntSalExiBod=4	&&& entrada o anulacion de traspaso
									IF (lncantiExiEdi<>0 OR lnCostoTotalExiEdi<>0)	
										lnNewProExiBod=IIF((NVL(taexiEdiLote.existencia,0)+lncantiExiEdi)=0,NVL(taexiEdiLote.costo,0),ABS((NVL(taexiEdiLote.costototal,0)+lnCostoTotalExiEdi)/(NVL(taexiEdiLote.existencia,0)+lncantiExiEdi))) 
										REPLACE existencia WITH NVL(taexiEdiLote.existencia,0)+lncantiExiEdi,;
											costototal WITH NVL(taexiEdiLote.costototal,0)+lnCostoTotalExiEdi,;
											costo WITH lnNewProExiBod NEXT 1 IN taexiEdiLote
										IF _tallY=0
											lcidMensExiBodEdi="No fue posible Actualizar la Existencia BODEGAS LOTE del Registro  "+lccodExiEdi
											llokExiEdi=.f.
										ENDIF
										IF taexiEdiLote.existencia<0 AND lnTipProExiEdi=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
											lcidMensExiBodEdi="Existencia Negativa en la bodega del Registro  "+lccodExiEdi
											llokExiEdi=.f.
										ENDIF 
									ENDIF 
								ENDIF 
								IF lnEntSalExiBod=2	OR lnEntSalExiBod=3	&&& salida o traspaso
									IF (lncantiExiEdi<>0 OR lnCostoTotalExiEdi<>0)	
										lnNewProExiBod=IIF((NVL(taexiEdiLote.existencia,0)-lncantiExiEdi)=0,NVL(taexiEdiLote.costo,0),ABS((NVL(taexiEdiLote.costototal,0)-lnCostoTotalExiEdi)/(NVL(taexiEdiLote.existencia,0)-lncantiExiEdi)))
										REPLACE existencia WITH NVL(taexiEdiLote.existencia,0)-lncantiExiEdi,;
											costototal WITH NVL(taexiEdiLote.costototal,0)-lnCostoTotalExiEdi,;
											costo WITH lnNewProExiBod NEXT 1 IN taexiEdiLote
										IF _tallY=0
											lcidMensExiBodEdi="No fue posible Actualizar la Existencia BODEGA LOTE del Registro  "+lccodExiEdi
											llokExiEdi=.f.
										ENDIF 
										IF taexiEdiLote.existencia<0 AND lnTipProExiEdi=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
											lcidMensExiBodEdi="Existencia Negativa en la bodega lote del Registro  "+lccodExiEdi
											llokExiEdi=.f.
										ENDIF 
									ENDIF 
								ENDIF 
								IF lnEntSalExiBod=3		&&& Ingresamos la unidades en la bdega de traspaso
									IF (lncantiExiEdi<>0 OR lnCostoTotalExiEdi<>0)	
										IF !SEEK(STR(lnidbodTraExiEdi)+STR(lnidproExiEdi)+STR(lnLlaveLote),"taexiEdiLote")		&&& si no esta lo inserta
											lnIdEXiBodNew=_SiguienteIdTabla(pcNodo,"SIS")
											INSERT INTO taexiEdiLote (idexisbode,idproducto,idbodega,idlote,ubicacion,existencia,costo,costototal,fecalta,fecmod,nodo,iduser,pcuser) ;
													value (lnIdEXiBodNew,lnidproExiEdi,lnidbodTraExiEdi,lnLlaveLote,'',0,0,0,ltfecmodprex,ltfecmodprex,lcnodprex,lnusrprex,lcpcusprex) 
										ENDIF 
										IF SEEK(STR(lnidbodTraExiEdi)+STR(lnidproExiEdi)+STR(lnLlaveLote),"taexiEdiLote")
											lnNewProExiBod=IIF((NVL(taexiEdiLote.existencia,0)+lncantiExiEdi)=0,NVL(taexiEdiLote.costo,0),ABS((NVL(taexiEdiLote.costototal,0)+lnCostoTotalExiEdi)/(NVL(taexiEdiLote.existencia,0)+lncantiExiEdi))) 
											REPLACE existencia WITH NVL(taexiEdiLote.existencia,0)+lncantiExiEdi,;
												costototal WITH NVL(taexiEdiLote.costototal,0)+lnCostoTotalExiEdi,;
												costo WITH lnNewProExiBod NEXT 1 IN taexiEdiLote
											IF _tallY=0
												lcidMensExiBodEdi="No fue posible Actualizar la Existencia BODEGA LOTE DE TRASPASO del Registro  "+lccodExiEdi
												llokExiEdi=.f.
											ENDIF 
											IF taexiEdiLote.existencia<0 AND lnTipProExiEdi=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
												lcidMensExiBodEdi="Existencia Negativa en la bodega lote del Registro  "+lccodExiEdi
												llokExiEdi=.f.
											ENDIF 
										ELSE
											lcidMensExiBodEdi="No fue posible Encontra la Bodega LOTE de TRASPASO en el registro "+lccodExiEdi
										ENDIF 
									ENDIF 
								ENDIF 				
								IF lnEntSalExiBod=4		&&& Anulamos las unidades en la bdega de traspaso
									IF (lncantiExiEdi<>0 OR lnCostoTotalExiEdi<>0)	
										IF !SEEK(STR(lnidbodTraExiEdi)+STR(lnidproExiEdi)+STR(lnLlaveLote),"taexiEdiLote")		&&& si no esta lo inserta
											lnIdEXiBodNew=_SiguienteIdTabla(pcNodo,"SIS")
											INSERT INTO taexiEdiLote (idexisbode,idproducto,idbodega,idlote,ubicacion,existencia,costo,costototal,fecalta,fecmod,nodo,iduser,pcuser) ;
													value (lnIdEXiBodNew,lnidproExiEdi,lnidbodTraExiEdi,lnLlaveLote,'',0,0,0,ltfecmodprex,ltfecmodprex,lcnodprex,lnusrprex,lcpcusprex) 
										ENDIF 

										IF SEEK(STR(lnidbodTraExiEdi)+STR(lnidproExiEdi)+STR(lnLlaveLote),"taexiEdiLote")
											lnNewProExiBod=IIF((NVL(taexiEdiLote.existencia,0)-lncantiExiEdi)=0,NVL(taexiEdiLote.costo,0),ABS((NVL(taexiEdiLote.costototal,0)-lnCostoTotalExiEdi)/(NVL(taexiEdiLote.existencia,0)-lncantiExiEdi)))
											REPLACE existencia WITH NVL(taexiEdiLote.existencia,0)-lncantiExiEdi,;
												costototal WITH NVL(taexiEdiLote.costototal,0)-lnCostoTotalExiEdi,;
												costo WITH lnNewProExiBod NEXT 1 IN taexiEdiLote
											IF _tallY=0
												lcidMensExiBodEdi="No fue posible Actualizar la Existencia BODEGAS LOTE DE TRASPASO del Registro  "+lccodExiEdi
												llokExiEdi=.f.
											ENDIF 
											IF taexiEdiLote.existencia<0 AND lnTipProExiEdi=1 AND plconExistenciasNegativas=.f. AND lnConNegativos=0
												lcidMensExiBodEdi="Existencia Negativa en la bodega Lote...  del Registro  "+lccodExiEdi
												llokExiEdi=.f.
											ENDIF 
										ELSE
											lcidMensExiBodEdi="No fue posible Encontra la Bodega lote de TRASPASO en el registro "+lccodExiEdi
										ENDIF 
									ENDIF 
								ENDIF 				
							ELSE 
								lcidMensExiBodEdi="No fue posible Encontra la Bodega Lote en el registro "+lccodExiEdi
							ENDIF 
						ENDIF 
					ENDIF 
				ENDIF 
						
				IF llTaExiBodEdiAbierta
					USE IN taexiEdi
				ENDIF 
				IF llTaExiBodLoteEdiAbierta
					USE IN taexiEdiLote
				ENDIF 
				IF llTaCataBodEdiAbierta
					USE IN tacataEdi
				ENDIF 
					
				SELECT (lcidAliasExiBodEdi)
			ENDIF 

			IF EMPTY(lcidMensExiBodEdi)
			    llretornafin=.t.
			ELSE
		        MESSAGEBOX(lcidMensExiBodEdi,16,'Error de Integridad... (_updatekardex)',2000)
			    llretornafin=.f.
			ENDIF
			
			RETURN llretornafin
		ENDIF 
	ENDIF 
ENDPROC 







**********************************
**** Kardex de CLIENTES Y PROVEEDORES INSERT y CAJA Y BANCOS
PROCEDURE _insertkardexcliprocajban
	LOCAL lcidAliascyvIns,lcidMenscyvIns,llTaKarInsAbierta,llTacyvInsAbierta,llTaCataInsAbierta,;
			lnidcliprocyvIns,lccodcyvIns,lnIdcyvIns,lnidTracyvIns,lnEntSalcyv,llokcyvIns,;
			lncanticyvIns,lnCostocyvIns,lnCostoTotalcyvIns
			
	
	STORE ALIAS() TO lcidAliascyvIns
	STORE '' TO lcidMenscyvIns
	STORE .t. TO llokcyvIns

	STORE idclipro		TO lnidcliprocyvIns
	STORE idcajban 		TO lnIdcyvIns
	STORE idcajbantras 		TO lnIdcyvtrasIns
	STORE ctrolcxcp 		TO lnEntSalclipro
	STORE ctrolcyb	 		TO lnEntSalcyv
	STORE condipago			TO lncondipagcyv
	STORE origen			TO lcorigenpagcyv
	
	STORE IIF(eliminado=1 OR status<=0,0,totaldocto-rentadocto) 	TO lnTotalDoccyvIns
	STORE IIF(eliminado=1 OR status<=0,0,totaldoctotras) 	TO lnTotalDoccyvInsTras

	************ Abriendo Tablas Necesarias si no estan abiertas todavia
	llTaCLIPROInsAbierta=!USED("taclipro")
	IF llTaCLIPROInsAbierta
		USE pcsysdir+pcDB+"\cyvclipro" IN 0 SHARED AGAIN ALIAS taclipro ORDER idclipro
	ENDIF 

	llTaCAJBANInsAbierta=!USED("tacajban")
	IF llTaCAJBANInsAbierta
		USE pcsysdir+pcDB+"\cybcajabancos" IN 0 SHARED AGAIN ALIAS tacajban ORDER idcajban
	ENDIF 

	IF lcorigenpagcyv='CYB' OR (lcorigenpagcyv<>'CYB' AND lncondipagcyv=0 AND lnEntSalcyv<>0)		&&& caja y bancos
		****** iniciando la actualizacion de cyvstencias en el catalogo y en las egas
		IF SEEK(lnIdcyvIns,"tacajban")
			lccodcyvIns=ALLTRIM(tacajban.codcajban)
		ELSE 
			lcidMenscyvIns="No fue posible encontrar el registro con id: "+ALLTRIM(STR(lnIdcyvIns))
			lccodcyvIns=""
			llokcyvIns=.f.
		ENDIF 

		IF 	llokcyvIns		&&& si todo bien continuamos
			***********************************
			***** actualizando caja y bancos
			IF lnEntSalcyv=1		&&& entrada
				REPLACE saldo WITH saldo+lnTotalDoccyvIns NEXT 1 IN tacajban
			ENDIF 
			IF lnEntSalcyv=2 OR lnEntSalcyv=3		&&& salida o transferencia
				REPLACE saldo WITH saldo-lnTotalDoccyvIns NEXT 1 IN tacajban
			ENDIF 
			IF _tallY=0
				lcidMenscyvIns="No fue posible Actualizar El Saldo del Registro  "+lccodcyvIns
				llokcyvIns=.f.
			ENDIF 
			IF tacajban.saldo<0 AND tacajban.sobregiro=0 AND pnSincronizandoTablas=.f.
				lcidMenscyvIns="Se Excedio el Saldo de la Cuenta "+lccodcyvIns
				llokcyvIns=.f.
			ENDIF 
		ENDIF 	

		IF lnEntSalcyv=3 AND llokcyvIns=.t.
			IF SEEK(lnIdcyvtrasIns,"tacajban")		&&& cuenta de Traspaso (Deposito)
				lccodcyvIns=ALLTRIM(tacajban.codcajban)
			ELSE 
				lcidMenscyvIns="No fue posible encontrar el registro de Deposito con id: "+ALLTRIM(STR(lnIdcyvtrasIns))
				lccodcyvIns=""
				llokcyvIns=.f.
			ENDIF 

			IF 	llokcyvIns		&&& si todo bien continuamos
				***********************************
				REPLACE saldo WITH saldo+lnTotalDoccyvInsTras NEXT 1 IN tacajban

				IF _tallY=0
					lcidMenscyvIns="No fue posible Actualizar El Saldo del Registro de Deposito "+lccodcyvIns
					llokcyvIns=.f.
				ENDIF 
				IF tacajban.saldo<0 AND tacajban.sobregiro=0 AND pnSincronizandoTablas=.f.
					lcidMenscyvIns="Se Exedio el Saldo de la Cuenta de Deposito"+lccodcyvIns
					llokcyvIns=.f.
				ENDIF 
			ENDIF 	
		ENDIF 

	ENDIF 
	
	IF lncondipagcyv=1	AND lnEntSalclipro<>0	&&& MOvimiento de credito
		****** iniciando la actualizacion de cyvstencias en el catalogo y en las egas
		IF SEEK(lnidcliprocyvIns,"taclipro")
			lccodcyvIns=ALLTRIM(taclipro.codclipro)
		ELSE 
			lcidMenscyvIns="No fue posible encontrar el registro con id: "+ALLTRIM(STR(lnidcliprocyvIns))
			lccodcyvIns=""
			llokcyvIns=.f.
		ENDIF 

		IF 	llokcyvIns		&&& si todo bien continuamos
			***********************************
			***** actualizando CLIENTES Y PROVEEDORES ******
			IF lnEntSalclipro=1		&&& entrada
				REPLACE saldo WITH saldo+lnTotalDoccyvIns NEXT 1 IN taclipro
			ENDIF 
			IF lnEntSalclipro=2		&&& salida
				REPLACE saldo WITH saldo-lnTotalDoccyvIns NEXT 1 IN taclipro
			ENDIF 
			IF _tallY=0
				lcidMenscyvIns="No fue posible Actualizar El Saldo del Registro  "+lccodcyvIns
				llokcyvIns=.f.
			ENDIF 

			IF taclipro.saldo>taclipro.limitecredito AND lnEntSalclipro=1 AND taclipro.sobregiro=0 AND pnSincronizandoTablas=.f.
				lcidMenscyvIns="Se Exedio el Limite de Credito de "+lccodcyvIns
				llokcyvIns=.f.
			ENDIF 
		ENDIF 
	ENDIF 
	
	IF llTaCLIPROInsAbierta
		USE IN taclipro
	ENDIF 
	IF llTaCAJBANInsAbierta
		USE IN tacajban
	ENDIF 
		
	SELECT (lcidAliascyvIns)
	
	IF EMPTY(lcidMenscyvIns)
		RETURN .t.
	ELSE
		MESSAGEBOX(lcidMenscyvIns,16,'Error de Integridad... (_insertkardexcliprocajban)',3000)
		RETURN .f.
	ENDIF 
ENDPROC 



**************************************************************
**** Kardex de CLIENTES Y PROVEEDORES UPDATE Y CAJA Y BANCOS
**** Actualizar kardes clipro y cajban
PROCEDURE _Updatekardexcliprocajban
	IF pnRecalculandoCXCP=1		&&& si no se esta recalculando saldos
		RETURN .t.
	ELSE 
		LOCAL lcidAliascyvEdit,lcidMenscyvEdit,llTaKarEditAbierta,llTacyvEditAbierta,llTaCataEditAbierta,;
				lnidcliprocyvEdit,lccodcyvEdit,lnIdcyvEdit,lnidTracyvEdit,lnEntSalcyv,llokcyvEdit,;
				lncanticyvEdit,lnCostocyvEdit,lnCostoTotalcyvEdit

		STORE ALIAS() TO lcidAliascyvEdit
		STORE '' TO lcidMenscyvEdit
		STORE .t. TO llokcyvEdit
		STORE idclipro		TO lnidcliprocyvEdit
		STORE idcajban 		TO lnIdcyvEdit
		STORE idcajbantras 		TO lnIdcyvEdittras
		STORE ctrolcxcp 		TO lnEntSalclipro
		STORE ctrolcyb	 		TO lnEntSalcyv
		STORE condipago			TO lncondipagcyv
		STORE origen			TO lcorigenpagcyv
		STORE status 			TO lnSta
		STORE iddocto 			TO lnidd
		STORE IIF(eliminado=1 OR status<=0,0,totaldocto-rentadocto) 	TO lnTotalDoccyvEdit
		STORE IIF(eliminado=1 OR status<=0,0,totaldoctotras) 	TO lnTotalDoccyvEdittras
		STORE IIF(CURVAL("eliminado")=1 OR CURVAL("status")<=0,0,CURVAL("totaldocto")-CURVAL("rentadocto"))	TO lnTotalDoccyvEditOld
		STORE IIF(CURVAL("eliminado")=1 OR CURVAL("status")<=0,0,CURVAL("totaldoctotras"))	TO lnTotalDoccyvEditOldtras

		************ Abriendo Tablas Necesarias si no estan abiertas todavia
		llTaCLIPROEditAbierta=!USED("taclipro")
		IF llTaCLIPROEditAbierta
			USE pcsysdir+pcDB+"\cyvclipro" IN 0 SHARED AGAIN ALIAS taclipro ORDER idclipro
		ENDIF 
		llTaCAJBANInsAbierta=!USED("tacajban")
		IF llTaCAJBANInsAbierta
			USE pcsysdir+pcDB+"\cybcajabancos" IN 0 SHARED AGAIN ALIAS tacajban ORDER idcajban
		ENDIF 
		IF lcorigenpagcyv='CYB' OR (lcorigenpagcyv<>'CYB' AND lncondipagcyv=0 AND lnEntSalcyv<>0)			&&&& caja y bancos
		****** iniciando la actualizacion de cyvstencias en el catalogo y en las egas
			IF SEEK(lnIdcyvEdit,"tacajban")
				lccodcyvEdit=ALLTRIM(tacajban.codcajban)
			ELSE 
				lcidMenscyvEdit="No fue posible encontrar el registro de Bancos con id: "+ALLTRIM(STR(lnIdcyvEdit))
				lccodcyvEdit=""
				llokcyvEdit=.f.
			ENDIF 

			IF 	llokcyvEdit		&&& si todo bien continuamos
				***********************************
				***** actualizando CLIENTES Y PROVEEDORES ******
				IF lnEntSalcyv=1		&&& entrada
					REPLACE saldo WITH saldo-lnTotalDoccyvEditOld+lnTotalDoccyvEdit NEXT 1 IN tacajban
					
				ENDIF 
				IF lnEntSalcyv=2 OR lnEntSalcyv=3		&&& salida o transferencia
					REPLACE saldo WITH saldo+lnTotalDoccyvEditOld-lnTotalDoccyvEdit NEXT 1 IN tacajban
				ENDIF 

				IF _tallY=0
					lcidMenscyvEdit="No fue posible Actualizar El Saldo de la cuenta  "+lccodcyvEdit
					llokcyvEdit=.f.
				ENDIF 
				IF tacajban.saldo<0 AND tacajban.sobregiro=0 AND pnSincronizandoTablas=.f.
					lcidMenscyvEdit="Se Exedio el Saldo de la Cuenta "+lccodcyvEdit
					llokcyvEdit=.f.
				ENDIF 
			ENDIF 
			
			IF lnEntSalcyv=3 AND llokcyvEdit=.t.		&&& salida o transferencia Deposito
				IF SEEK(lnIdcyvEdittras,"tacajban")
					lccodcyvEdit=ALLTRIM(tacajban.codcajban)
				ELSE 
					lcidMenscyvEdit="No fue posible encontrar el registro de Deposito con id: "+ALLTRIM(STR(lnIdcyvEdittras))
					lccodcyvEdit=""
					llokcyvEdit=.f.
				ENDIF 

				IF 	llokcyvEdit		&&& si todo bien continuamos
					***********************************
					***** actualizando CLIENTES Y PROVEEDORES ******
					REPLACE saldo WITH saldo-lnTotalDoccyvEditOldtras+lnTotalDoccyvEdittras NEXT 1 IN tacajban

					IF _tallY=0
						lcidMenscyvEdit="No fue posible Actualizar El Saldo de la cuenta de Deposito "+lccodcyvEdit
						llokcyvEdit=.f.
					ENDIF 
*!*						IF tacajban.saldo<0 AND tacajban.sobregiro=0 AND pnSincronizandoTablas=.f.
*!*							lcidMenscyvEdit="Se Exedio el Saldo de la Cuenta de Deposito "+lccodcyvEdit
*!*							llokcyvEdit=.f.
*!*						ENDIF 
				ENDIF 		
			ENDIF 
		ENDIF 
			
		IF lncondipagcyv=1	AND lnEntSalclipro<>0			&&&& movimiento de Credito
			****** iniciando la actualizacion de cyvstencias en el catalogo y en las egas
			IF SEEK(lnidcliprocyvEdit,"taclipro",'idclipro')
				lccodcyvEdit=ALLTRIM(taclipro.codclipro)
			ELSE 
				lcidMenscyvEdit="No fue posible encontrar el registro del Cliente/Proveedor con id: "+ALLTRIM(STR(lnidcliprocyvEdit))
				lccodcyvEdit=""
				llokcyvEdit=.f.
			ENDIF 

			IF 	llokcyvEdit		&&& si todo bien continuamos
				***********************************
				***** actualizando CLIENTES Y PROVEEDORES ******
				IF lnEntSalclipro=1		&&& entrada
					REPLACE saldo WITH saldo-lnTotalDoccyvEditOld+lnTotalDoccyvEdit NEXT 1 IN taclipro
				ENDIF 
				IF lnEntSalclipro=2		&&& salida
					REPLACE saldo WITH saldo+lnTotalDoccyvEditOld-lnTotalDoccyvEdit NEXT 1 IN taclipro
				ENDIF 
				IF _tallY=0
					lcidMenscyvEdit="No fue posible Actualizar El Saldo del Registro  "+lccodcyvEdit
					llokcyvEdit=.f.
				ENDIF 
  
*!*					IF taclipro.saldo>taclipro.limitecredito AND pnSincronizandoTablas=.f.
*!*						lcidMenscyvEdit="Se Exedio el Limite de Credito del Reg. "+lccodcyvEdit
*!*						llokcyvEdit=.f.
*!*					ENDIF 
				
			ENDIF 
		ENDIF 		
		IF llTaCLIPROEditAbierta
			USE IN taclipro
		ENDIF 
		IF llTaCAJBANInsAbierta
			USE IN tacajban
		ENDIF 
					
		SELECT (lcidAliascyvEdit)
		
		IF EMPTY(lcidMenscyvEdit)
			RETURN .t.
		ELSE
			MESSAGEBOX(lcidMenscyvEdit,16,'Error de Integridad... (_Updatekardexcliprocajban)',3000)
			RETURN .f.
		ENDIF 
	ENDIF 
ENDPROC 



**********************************
**** Insertar kardex caja y bancos
PROCEDURE _insertkardexCajBan
	LOCAL lcidAliascybIns,lcidMenscybIns,llTaKarInsAbierta,llTacybInsAbierta,llTaCataInsAbierta,;
			lnidcliprocybIns,lccodcybIns,lnIdcybIns,lnidTracybIns,lnEntSalcyb,llokcybIns,;
			lncanticybIns,lnCostocybIns,lnCostoTotalcybIns
			
	STORE ALIAS() TO lcidAliascybIns
	STORE '' TO lcidMenscybIns
	STORE .t. TO llokcybIns

	STORE idclipro		TO lnidcliprocybIns
	STORE idcajban 		TO lnIdcybIns
	STORE entsal 		TO lnEntSalcyb
	STORE IIF(eliminado=1 OR status<=0,0,totaldocto-rentadocto) 	TO lnTotalDoccybIns

	************ Abriendo Tablas Necesarias si no estan abiertas todavia
	lltacajbanInsAbierta=!USED("tacajban")
	IF lltacajbanInsAbierta
		USE pcsysdir+pcDB+"\cybcajabancos" IN 0 SHARED AGAIN ALIAS tacajban ORDER idcajban
	ENDIF 

	****** iniciando la actualizacion de cybstencias en el catalogo y en las egas
	IF SEEK(lnIdcybIns,"tacajban")
		lccodcybIns=ALLTRIM(tacajban.codcajban)
	ELSE 
		lcidMenscybIns="No fue posible encontrar el registro con id: "+ALLTRIM(STR(lnidcliprocybIns))
		lccodcybIns=""
		llokcybIns=.f.
	ENDIF 

	IF 	llokcybIns		&&& si todo bien continuamos
		***********************************
		***** actualizando caja y bancos
		IF lnEntSalcyb=1		&&& entrada
			REPLACE saldo WITH saldo+lnTotalDoccybIns NEXT 1 IN tacajban
		ENDIF 
		IF lnEntSalcyb=2		&&& salida
			REPLACE saldo WITH saldo-lnTotalDoccybIns NEXT 1 IN tacajban
		ENDIF 
		IF _tallY=0
			lcidMenscybIns="No fue posible Actualizar El Saldo del Registro  "+lccodcybIns
			llokcybIns=.f.
		ENDIF 
		IF tacajban.saldo<0 AND tacajban.sobregiro=0
			lcidMenscybIns="Se Sobregiro la Cuenta "+lccodcybEdit
			llokcybIns=.f.
		ENDIF 
	ENDIF 
			
	IF lltacajbanInsAbierta
		USE IN tacajban
	ENDIF 
		
	SELECT (lcidAliascybIns)
	
	IF EMPTY(lcidMenscybIns)
		RETURN .t.
	ELSE
		MESSAGEBOX(lcidMenscybIns,16,'Error de Integridad... (_insertkardexEfectivo)',3000)
		RETURN .f.
	ENDIF 
ENDPROC 



**** Actualizar Kardex de CAJA Y BANCOS
PROCEDURE _UpdatekardexCajBan
	LOCAL lcidAliascybEdit,lcidMenscybEdit,llTaKarEditAbierta,llTacybEditAbierta,llTaCataEditAbierta,;
			lnidcliprocybEdit,lccodcybEdit,lnIdcybEdit,lnidTracybEdit,lnEntSalcyb,llokcybEdit,;
			lncanticybEdit,lnCostocybEdit,lnCostoTotalcybEdit
			
	STORE ALIAS() TO lcidAliascybEdit
	STORE '' TO lcidMenscybEdit
	STORE .t. TO llokcybEdit

	STORE idclipro		TO lnidcliprocybEdit
	STORE idcajban 		TO lnIdcybEdit
	STORE entsal 		TO lnEntSalcyb

	STORE IIF(eliminado=1 OR status<=0,0,totaldocto-rentadocto) 	TO lnTotalDoccybEdit
	STORE IIF(eliminado=1 OR status<=0,0,CURVAL("totaldocto")-CURVAL("rentadocto")) 	TO lnTotalDoccybEditOld
	

	************ Abriendo Tablas Necesarias si no estan abiertas todavia
	lltacajbanEditAbierta=!USED("tacajban")
	IF lltacajbanEditAbierta
		USE pcsysdir+pcDB+"\cybcajabancos" IN 0 SHARED AGAIN ALIAS tacajban ORDER idcajban
	ENDIF 

	****** iniciando la actualizacion de cybstencias en el catalogo y en las egas
	IF SEEK(lnIdcybEdit,"tacajban")
		lccodcybEdit=ALLTRIM(tacajban.codcajban)
	ELSE 
		lcidMenscybEdit="No fue posible encontrar el registro con id: "+ALLTRIM(STR(lnidcliprocybEdit))
		lccodcybEdit=""
		llokcybEdit=.f.
	ENDIF 

	IF 	llokcybEdit		&&& si todo bien continuamos
		***********************************
		***** actualizando caja y bancos
		IF lnEntSalcyb=1		&&& entrada
			REPLACE saldo WITH saldo-lnTotalDoccybEditOld+lnTotalDoccybEdit NEXT 1 IN tacajban
		ENDIF 
		IF lnEntSalcyb=2		&&& salida
			REPLACE saldo WITH saldo+lnTotalDoccybEditOld-lnTotalDoccybEdit NEXT 1 IN tacajban
		ENDIF 
		IF _tallY=0
			lcidMenscybEdit="No fue posible Actualizar El Saldo del Registro  "+lccodcybEdit
			llokcybEdit=.f.
		ENDIF 
		IF tacajban.saldo<0 AND tacajban.sobregiro=0
			lcidMenscybEdit="Se Sobregiro la Cuenta "+lccodcybEdit
			llokcybEdit=.f.
		ENDIF 
	ENDIF 
			
	IF lltacajbanEditAbierta
		USE IN tacajban
	ENDIF 
		
	SELECT (lcidAliascybEdit)
	
	IF EMPTY(lcidMenscybEdit)
		RETURN .t.
	ELSE
		MESSAGEBOX(lcidMenscybEdit,16,'Error de Integridad... (_EditertkardexEfectivo)',3000)
		RETURN .f.
	ENDIF 
ENDPROC 



**********************************
**** Kardex de Aplicacion de Documentos
PROCEDURE _insertkardexaplicxcp
	LOCAL lcidAliasapliIns,lcidMensapliIns,llTaKarInsAbierta,llTaapliInsAbierta,llTaCataInsAbierta,;
			lnidcliproapliIns,lccodapliIns,lnIdapliIns,lnidTraapliIns,lnEntSalapli,llokapliIns,;
			lncantiapliIns,lnCostoapliIns,lnCostoTotalapliIns

	IF plRecosteando=.t.
		RETURN .t.  &&& si se esta insertando cuentas desde la sincronizacion, no se hace nada
	ELSE		
		STORE ALIAS() TO lcidAliasapliIns
		STORE '' TO lcidMensapliIns
		STORE .t. TO llokapliIns1,llokapliIns2

		STORE iddocto			TO lniddoctoIns
		STORE iddoctoaplicar	TO lniddoctoapliins
		STORE carabo 			TO lnEntSalclipro
		
		STORE IIF(eliminado=1 OR status<=0,0,IIF(carabo=1,monto*-1,monto)) 	TO lnTotalDoctIns
		STORE IIF(eliminado=1 OR status<=0,0,IIF(carabo=1,monto,monto*-1)) 	TO lnTotalDoctapliIns

		lltakardocInsAbierta=!USED("takardoc")
		IF lltakardocInsAbierta
			USE pcsysdir+pcDB+"\siskardexdoc" IN 0 SHARED AGAIN ALIAS takardoc ORDER iddocto
		ENDIF 

		IF lnEntSalclipro<>0		&&& MOvimiento de credito
			****** iniciando la actualizacion de aplistencias en el catalogo y en las egas

			IF SEEK(lniddoctoapliins,"takardoc","iddocto")
				lccodapliIns=ALLTRIM(takardoc.numero)
			ELSE 
				lcidMensapliIns="No fue posible encontrar el registro con id : "+ALLTRIM(STR(lniddoctoapliins))
				lccodapliIns=""
				llokapliIns1=.f.
			ENDIF 

			IF 	llokapliIns1		&&& si todo bien continuamos 
				***********************************
				***** actualizando CLIENTES Y PROVEEDORES ******
				REPLACE cargoabono WITH cargoabono+lnTotalDoctapliIns NEXT 1 IN takardoc

				IF _tallY=0 AND lnEntSalclipro<>3
					lcidMensapliIns="No fue posible Actualizar El Saldo del Registro  "+lccodapliIns
					llokapliIns1=.f.
				ENDIF 
			ENDIF 


			IF SEEK(lniddoctoIns,"takardoc","iddocto")
				lccodapliIns=ALLTRIM(takardoc.numero)
			ELSE 
				lcidMensapliIns="No fue posible encontrar el registro con id: "+ALLTRIM(STR(lniddoctoIns))
				lccodapliIns=""
				llokapliIns2=.f.
				RELEASE lcnum 
			ENDIF 

			IF 	llokapliIns2		&&& si todo bien continuamos
				***********************************
				***** actualizando CLIENTES Y PROVEEDORES ******
				REPLACE cargoabono WITH cargoabono+lnTotalDoctIns NEXT 1 IN takardoc

				IF _tallY=0 AND lnEntSalclipro<>3
					lcidMensapliIns="No fue posible Actualizar El Saldo del Registro  "+lccodapliIns
					llokapliIns2=.f.
				ENDIF 
			ENDIF 


		ENDIF 

		IF lltakardocInsAbierta
			USE IN takardoc 
		ENDIF 

		SELECT (lcidAliasapliIns)
		
		IF EMPTY(lcidMensapliIns)
			RETURN .t.
		ELSE
			MESSAGEBOX(lcidMensapliIns,16,'Error de Integridad... (_insertkardexaplicxcp)',3000)
			RETURN .f.
		ENDIF 
	ENDIF 
ENDPROC 



**** Actualizar Kardex de CAJA Y BANCOS
PROCEDURE _Updatekardexaplicxcp
	LOCAL lcidAliascybEdit,lcidMenscybEdit,llTaKarEditAbierta,llTacybEditAbierta,llTaCataEditAbierta,;
			lnidcliprocybEdit,lccodcybEdit,lnIdcybEdit,lnidTracybEdit,lnEntSalcyb,llokcybEdit,;
			lncanticybEdit,lnCostocybEdit,lnCostoTotalcybEdit
	IF plRecosteando=.t.
		RETURN .t.  &&& si se esta insertando cuentas desde la sincronizacion, no se hace nada
	ELSE			
		STORE ALIAS() TO lcidAliascybEdit
		STORE '' TO lcidMenscybEdit
		STORE .t. TO llokcybEdit

		STORE iddocto			TO lnidcliprocybEdit
		STORE iddoctoaplicar	TO lnidcliprocybEditApli
		STORE carabo 			TO lnEntSalcyb

		STORE IIF(eliminado=1 OR status<=0,0,IIF(carabo=1,monto*-1,monto)) 	TO lnTotalDoctIns
		STORE IIF(eliminado=1 OR status<=0,0,IIF(carabo=1,monto,monto*-1)) 	TO lnTotalDoctapliIns

		STORE IIF(CURVAL("eliminado")=1 OR CURVAL("status")<=0,0,IIF(CURVAL("carabo")=1,CURVAL("monto"),CURVAL("monto")*-1)) 	TO lnTotalDoctInsOld
		STORE IIF(CURVAL("eliminado")=1 OR CURVAL("status")<=0,0,IIF(CURVAL("carabo")=1,CURVAL("monto")*-1,CURVAL("monto"))) 	TO lnTotalDoctapliInsOld

		************ Abriendo Tablas Necesarias si no estan abiertas todavia
		lltacajbanEditAbierta=!USED("tacajban")
		IF lltacajbanEditAbierta
			USE pcsysdir+pcDB+"\cybcajabancos" IN 0 SHARED AGAIN ALIAS tacajban ORDER idcajban
		ENDIF 
		lltakardocEditAbierta2=!USED("takardoc")
		IF lltakardocEditAbierta2
			USE pcsysdir+pcDB+"\siskardexdoc" IN 0 SHARED AGAIN ALIAS takardoc ORDER iddocto
		ENDIF 

		IF lnEntSalcyb<>0
			****** iniciando la actualizacion de cybstencias en el catalogo y en las egas
			IF SEEK(lnidcliprocybEdit,"takardoc","iddocto")
				lccodcybEdit=ALLTRIM(takardoc.numero)
			ELSE 
				lcidMenscybEdit="No fue posible encontrar el registro con id: "+ALLTRIM(STR(lnidcliprocybEdit))
				lccodcybEdit=""
				llokcybEdit=.f.
			ENDIF 

			IF 	llokcybEdit		&&& si todo bien continuamos
				***********************************
				***** actualizando caja y bancos
				REPLACE takardoc.cargoabono WITH (takardoc.cargoabono*-1)-lnTotalDoctInsOld+lnTotalDoctIns NEXT 1 IN takardoc

				IF _tallY=0 AND lnEntSalcyb<>3
					lcidMenscybEdit="No fue posible Actualizar El Saldo del Registro  "+lccodcybEdit
					llokcybEdit=.f.
				ENDIF 			
			ENDIF 

			IF SEEK(lnidcliprocybEditApli,"takardoc","iddocto")
				lccodcybEdit=ALLTRIM(takardoc.numero)
			ELSE 
				lcidMenscybEdit="No fue posible encontrar el registro con id: "+ALLTRIM(STR(lnidcliprocybEdit))
				lccodcybEdit=""
				llokcybEdit=.f.
			ENDIF 

			IF 	llokcybEdit		&&& si todo bien continuamos
				***********************************
				***** actualizando caja y bancos
				REPLACE takardoc.cargoabono WITH IIF(takardoc.ctrolcxcp=1,-1,1)*((takardoc.cargoabono*-1)-lnTotalDoctapliInsOld+lnTotalDoctapliIns) NEXT 1 IN takardoc

				IF _tallY=0 AND lnEntSalcyb<>3
					lcidMenscybEdit="No fue posible Actualizar El Saldo del Registro  "+lccodcybEdit
					llokcybEdit=.f.
				ENDIF 			
			ENDIF 
		ENDIF 	
				
		IF lltacajbanEditAbierta
			USE IN tacajban
		ENDIF 
		IF lltakardocEditAbierta2
			USE IN takardoc 
		ENDIF 
			 
		SELECT (lcidAliascybEdit)
		
		IF EMPTY(lcidMenscybEdit)
			RETURN .t.
		ELSE
			MESSAGEBOX(lcidMenscybEdit,16,'Error de Integridad... (_Updatekardexaplicxcp)',3000)
			RETURN .f.
		ENDIF 
	ENDIF 
ENDPROC 




**********************************
**********************************
***** COMPRAS ********************
**** ComprasDetalle insertar
PROCEDURE _insertcomprasdeta
    LOCAL lcidAliasComIns, lcidMensComIns, llTaKarInsAbierta
    LOCAL llTaKarInsAbiertaR, lninsertado, lnregistrostotal
    LOCAL lnidComDIns, lnidpedidod, lnidllave, lnCantiped
    LOCAL ldidtipComDIns, lnidserComDInv, lcnumComDIns, ldFecComDIns
    LOCAL lnidclipComDIns, lnTotdComDIns, lnidcajbanComDIns
    LOCAL lnctrolCYBComDIns, lnctrolcomComDIns, lnctrolcxpComDIns
    LOCAL lcnotasComDins, lchoradoctoComDins
    LOCAL lcversiesta, lcmitmpllalias, llLlegoAlFinal

    STORE ALIAS() TO lcidAliasComIns
    STORE '' TO lcidMensComIns

    IF status = -1
        lcidMensComIns = ""
    ELSE
        llTaKarInsAbierta = !USED("takarIns")
        IF llTaKarInsAbierta
            USE pcsysdir + pcDB + "\siskardex" IN 0 SHARED AGAIN ALIAS takarIns ORDER iddoctod
        ENDIF

        llTaKarInsAbiertaR = !USED("cyvcompras")
        IF llTaKarInsAbiertaR
            USE pcsysdir + pcDB + "\cyvcompras" IN 0 SHARED AGAIN ALIAS cyvcompras ORDER iddocto
        ENDIF

        ***** KARDEX DE INVENTARIOS POR COMPRAS
        IF .t.
            lnidComDIns = cyvcomprasdeta.iddocto
            lnidpedidod = cyvcomprasdeta.idpedidod
            lnidllave = cyvcomprasdeta.iddoctod

            IF cyvcomprasdeta.entsal = 1
                lnCantiped = cyvcomprasdeta.cantidad
            ELSE
                IF cyvcomprasdeta.entsal = 2
                    lnCantiped = -cyvcomprasdeta.cantidad
                ELSE
                    lnCantiped = 0
                ENDIF
            ENDIF

            IF SEEK(lnidComDIns, "cyvcompras", "iddocto")
                ldidtipComDIns = cyvcompras.idtipodocto
                lnidserComDInv = cyvcompras.idserie
                lcnumComDIns = cyvcompras.numero
                ldFecComDIns = cyvcompras.fechadocto
                lnidclipComDIns = cyvcompras.idclipro
                lnTotdComDIns = cyvcompras.totaldocto
                lnidcajbanComDIns = cyvcompras.idcajban
                lnctrolCYBComDIns = cyvcompras.ctrolcyb
                lnctrolcomComDIns = cyvcompras.ctrolcom
                lnctrolcxpComDIns = cyvcompras.ctrolcxp
                lcnotasComDins = cyvcompras.notas
                lchoradoctoComDins = cyvcompras.horadocto
            ELSE
                ldidtipComDIns = 0
                lnidserComDInv = 0
                lcnumComDIns = ''
                ldFecComDIns = CTOD(' ')
                lnidclipComDIns = 0
                lnTotdComDIns = 0
                lnidcajbanComDIns = 0
                lchoradoctoComDins = ''
                lcnotasComDins = ''
                lnctrolCYBComDIns = 0
                lnctrolcomComDIns = 0
                lnctrolcxpComDIns = 0
            ENDIF

            IF ldidtipComDIns <> 0
                TRY
                    lnregistrostotal = RECCOUNT('takarIns')
                    lcversiesta = cyvcomprasdeta.iddoctod
                    lcmitmpllalias = ALIAS()

                    SELECT takarIns
                    llLlegoAlFinal = !SEEK(lcversiesta, 'takarIns', 'iddoctod')

                    IF !EMPTY(lcmitmpllalias)
                        SELECT (lcmitmpllalias)
                    ENDIF

                    IF llLlegoAlFinal
                        INSERT INTO takarIns (iddoctod,iddocto,idtipodocto,idserie,idcajban,numero,horadocto,fechadocto,idclipro,totaldocto,;
                                              idproducto,unimed,cantidad,idproductoUniMed,cantiunimed,;
                                              factor,largo,ancho,area,desperdicio,;
                                              costounitario,costounimed,costototal,idbodega,idbodegatras,idctrocosto,;
                                              idkit,llavekit,llavelote,tipoprod,periodo,origen,;
                                              cantidadkit,cantidadserie,ctrolcomvta,ctrolinv,ctrolcxcp,ctrolcyb,notas,status,eliminado,;
                                              fecalta,fecmod,fecactu,nodo,iduser,pcuser);
                            VALUES (cyvcomprasdeta.iddoctod,cyvcomprasdeta.iddocto,ldidtipComDIns,lnidserComDInv,lnidcajbanComDIns,;
                                    lcnumComDIns,lchoradoctoComDins,ldFecComDIns,lnidclipComDIns,lnTotdComDIns,cyvcomprasdeta.idproducto,;
                                    cyvcomprasdeta.unimed,cyvcomprasdeta.cantidad,cyvcomprasdeta.idproductoUniMed,cyvcomprasdeta.cantiunimed,;
                                    cyvcomprasdeta.factor,cyvcomprasdeta.largo,cyvcomprasdeta.ancho,;
                                    cyvcomprasdeta.area,cyvcomprasdeta.desperdicio,;
                                    cyvcomprasdeta.costounitario,cyvcomprasdeta.costounimed,cyvcomprasdeta.costototal,;
                                    cyvcomprasdeta.idbodega,cyvcomprasdeta.idbodegatras,cyvcomprasdeta.idctrocosto,;
                                    cyvcomprasdeta.idkit,cyvcomprasdeta.llavekit,cyvcomprasdeta.llavelote,;
                                    cyvcomprasdeta.tipoprod,cyvcomprasdeta.periodo,cyvcomprasdeta.origen,;
                                    cyvcomprasdeta.cantidadkit,cyvcomprasdeta.cantidadserie,;
                                    lnctrolcomComDIns,cyvcomprasdeta.entsal,lnctrolcxpComDIns,lnctrolCYBComDIns,;
                                    lcnotasComDins,cyvcomprasdeta.status,cyvcomprasdeta.eliminado,;
                                    cyvcomprasdeta.fecalta,cyvcomprasdeta.fecmod,cyvcomprasdeta.fecactu,;
                                    cyvcomprasdeta.nodo,cyvcomprasdeta.iduser,cyvcomprasdeta.pcuser)

                        lninsertado = RECCOUNT('takarIns') - lnregistrostotal
                    ELSE
                        UPDATE takarIns SET iddocto = cyvcomprasdeta.iddocto,;
                                            idtipodocto = ldidtipComDIns,;
                                            idserie = lnidserComDInv,;
                                            idcajban = lnidcajbanComDIns,;
                                            numero = lcnumComDIns,;
                                            horadocto = lchoradoctoComDins,;
                                            fechadocto = ldFecComDIns,;
                                            idclipro = lnidclipComDIns,;
                                            totaldocto = lnTotdComDIns,;
                                            idproducto = cyvcomprasdeta.idproducto,;
                                            unimed = cyvcomprasdeta.unimed,;
                                            cantidad = cyvcomprasdeta.cantidad,;
                                            idproductoUniMed = cyvcomprasdeta.idproductoUniMed,;
                                            cantiunimed = cyvcomprasdeta.cantiunimed,;
                                            factor = cyvcomprasdeta.factor,;
                                            largo = cyvcomprasdeta.largo,;
                                            ancho = cyvcomprasdeta.ancho,;
                                            area = cyvcomprasdeta.area,;
                                            desperdicio = cyvcomprasdeta.desperdicio,;
                                            costounitario = cyvcomprasdeta.costounitario,;
                                            costounimed = cyvcomprasdeta.costounimed,;
                                            costototal = cyvcomprasdeta.costototal,;
                                            idbodega = cyvcomprasdeta.idbodega,;
                                            idbodegatras = cyvcomprasdeta.idbodegatras,;
                                            idctrocosto = cyvcomprasdeta.idctrocosto,;
                                            idkit = cyvcomprasdeta.idkit,;
                                            llavekit = cyvcomprasdeta.llavekit,;
                                            llavelote = cyvcomprasdeta.llavelote,;
                                            tipoprod = cyvcomprasdeta.tipoprod,;
                                            periodo = cyvcomprasdeta.periodo,;
                                            origen = cyvcomprasdeta.origen,;
                                            cantidadkit = cyvcomprasdeta.cantidadkit,;
                                            cantidadserie = cyvcomprasdeta.cantidadserie,;
                                            ctrolcomvta = lnctrolcomComDIns,;
                                            ctrolinv = cyvcomprasdeta.entsal,;
                                            ctrolcxcp = lnctrolcxpComDIns,;
                                            ctrolcyb = lnctrolCYBComDIns,;
                                            notas = lcnotasComDins,;
                                            status = cyvcomprasdeta.status,;
                                            eliminado = cyvcomprasdeta.eliminado,;
                                            fecalta = cyvcomprasdeta.fecalta,;
                                            fecmod = cyvcomprasdeta.fecmod,;
                                            fecactu = cyvcomprasdeta.fecactu,;
                                            nodo = cyvcomprasdeta.nodo,;
                                            iduser = cyvcomprasdeta.iduser,;
                                            pcuser = cyvcomprasdeta.pcuser ;
                                        WHERE iddoctod = cyvcomprasdeta.iddoctod

                        lninsertado = _TALLY
                    ENDIF

                    **** posteando pedidos
                    IF lninsertado <> 0
                        UPDATE takarIns SET cantidadpedido = cantidadpedido + lnCantiped ;
                            WHERE iddoctod = lnidpedidod
                    ENDIF

                    IF lninsertado = 0
                        lcidMensComIns = "Error al Insertar datos en el Kardex de productos"
                    ENDIF

                CATCH TO lEx
                    lcidMensComIns = lcidMensComIns + " Error " + TRANSFORM(lEx.Message)

                FINALLY
                    IF !EMPTY(lcidAliasComIns)
                        SELECT (lcidAliasComIns)
                    ENDIF
                ENDTRY
            ELSE
                lcidMensComIns = 'El tipo de Documento no puede ser 0 (cero)'
            ENDIF
        ENDIF

        IF llTaKarInsAbierta
            USE IN takarIns
        ENDIF

        IF llTaKarInsAbiertaR
            USE IN cyvcompras
        ENDIF

        IF !EMPTY(lcidAliasComIns)
            SELECT (lcidAliasComIns)
        ENDIF
    ENDIF

    IF EMPTY(lcidMensComIns)
        RETURN .t.
    ELSE
        MESSAGEBOX(lcidMensComIns + '  Id:' + ALLTRIM(STR(lnidllave)),16,'Error de Integridad... (_insertcomprasdeta)',3000)
        RETURN .f.
    ENDIF
ENDPROC



**** ComprasDetalle Actualizar
PROCEDURE _updatecomprasdeta
    LOCAL lcidAliasComEdi, lcidMensComEdi, llTaKarEdiAbierta
    LOCAL llTaKarInsAbiertaR, llretorok, lninsertado, llNoExisteKardex
    LOCAL lnidComDEdi, lnidpedidod, lnCantiped
    LOCAL ldidtipComDEdi, lnidserComDEdi, lcnumComDEdi, ldFecComDEdi
    LOCAL lnidclipComDEdi, lnTotdComDEdi, lnidcajbanComEdi
    LOCAL lnctrolCYBComDIns, lnctrolcomComDIns, lnctrolcxpComDIns
    LOCAL lchoradoctoComEdi, lcnotasComEdi

    STORE ALIAS() TO lcidAliasComEdi
    STORE '' TO lcidMensComEdi
    llretorok = .t.

    IF (status = -1 AND CURVAL("status") = -1) AND ;
       !(CURVAL("status") = -1 AND status = 1) AND ;
       !(CURVAL("status") = 1 AND status = 0)

        llretorok = .t.

    ELSE
        llTaKarEdiAbierta = !USED("takarEdi")
        IF llTaKarEdiAbierta
            USE pcsysdir + pcDB + "\siskardex" IN 0 SHARED AGAIN ALIAS takarEdi ORDER iddoctod
        ENDIF

        llTaKarInsAbiertaR = !USED("cyvcompras")
        IF llTaKarInsAbiertaR
            USE pcsysdir + pcDB + "\cyvcompras" IN 0 SHARED AGAIN ALIAS cyvcompras ORDER iddocto
        ENDIF

        ***** KARDEX DE INVENTARIOS por COMPRAS
        IF .t.
            lnidComDEdi = cyvcomprasdeta.iddocto
            lnidpedidod = cyvcomprasdeta.idpedidod

            IF cyvcomprasdeta.entsal = 1
                IF (CURVAL("cyvcomprasdeta.status") <> 0 AND cyvcomprasdeta.status = 0)
                    lnCantiped = -CURVAL("cyvcomprasdeta.cantidad")
                ELSE
                    IF cyvcomprasdeta.status <> 0
                        lnCantiped = -CURVAL("cyvcomprasdeta.cantidad") + cyvcomprasdeta.cantidad
                    ELSE
                        lnCantiped = 0
                    ENDIF
                ENDIF
            ELSE
                IF cyvcomprasdeta.entsal = 2
                    IF (CURVAL("cyvcomprasdeta.status") <> 0 AND cyvcomprasdeta.status = 0)
                        lnCantiped = +CURVAL("cyvcomprasdeta.cantidad")
                    ELSE
                        IF cyvcomprasdeta.status <> 0
                            lnCantiped = +CURVAL("cyvcomprasdeta.cantidad") - cyvcomprasdeta.cantidad
                        ELSE
                            lnCantiped = 0
                        ENDIF
                    ENDIF
                ELSE
                    lnCantiped = 0
                ENDIF
            ENDIF

            IF SEEK(lnidComDEdi, "cyvcompras", "iddocto")
                ldidtipComDEdi = cyvcompras.idtipodocto
                lnidserComDEdi = cyvcompras.idserie
                lcnumComDEdi = cyvcompras.numero
                ldFecComDEdi = cyvcompras.fechadocto
                lnidclipComDEdi = cyvcompras.idclipro
                lnTotdComDEdi = cyvcompras.totaldocto
                lnidcajbanComEdi = cyvcompras.idcajban
                lnctrolCYBComDIns = cyvcompras.ctrolcyb
                lnctrolcomComDIns = cyvcompras.ctrolcom
                lnctrolcxpComDIns = cyvcompras.ctrolcxp
                lchoradoctoComEdi = cyvcompras.horadocto
                lcnotasComEdi = cyvcompras.notas
            ELSE
                ldidtipComDEdi = 0
                lnidserComDEdi = 0
                lcnumComDEdi = ''
                ldFecComDEdi = CTOD(' ')
                lnidclipComDEdi = 0
                lnTotdComDEdi = 0
                lnctrolCYBComDIns = 0
                lnidcajbanComEdi = 0
                lchoradoctoComEdi = ''
                lcnotasComEdi = ''
                lnctrolcomComDIns = 0
                lnctrolcxpComDIns = 0
            ENDIF

            IF ldidtipComDEdi <> 0
                TRY
                    lninsertado = 0
                    llNoExisteKardex = !SEEK(cyvcomprasdeta.iddoctod, "takarEdi", "iddoctod")

                    IF llNoExisteKardex
                        INSERT INTO takarEdi (iddoctod,iddocto,idtipodocto,idserie,idcajban,numero,horadocto,fechadocto,idclipro,totaldocto,;
                                              idproducto,unimed,cantidad,idproductoUniMed,cantiunimed,;
                                              factor,largo,ancho,area,desperdicio,;
                                              costounitario,costounimed,costototal,idbodega,idbodegatras,idctrocosto,;
                                              idkit,llavekit,llavelote,tipoprod,periodo,origen,;
                                              cantidadkit,cantidadserie,ctrolcomvta,ctrolinv,ctrolcxcp,ctrolcyb,notas,status,eliminado,;
                                              fecalta,fecmod,fecactu,nodo,iduser,pcuser);
                            VALUES (cyvcomprasdeta.iddoctod,cyvcomprasdeta.iddocto,ldidtipComDEdi,lnidserComDEdi,lnidcajbanComEdi,;
                                    lcnumComDEdi,lchoradoctoComEdi,ldFecComDEdi,lnidclipComDEdi,lnTotdComDEdi,cyvcomprasdeta.idproducto,;
                                    cyvcomprasdeta.unimed,cyvcomprasdeta.cantidad,cyvcomprasdeta.idproductoUniMed,cyvcomprasdeta.cantiunimed,;
                                    cyvcomprasdeta.factor,cyvcomprasdeta.largo,cyvcomprasdeta.ancho,;
                                    cyvcomprasdeta.area,cyvcomprasdeta.desperdicio,;
                                    cyvcomprasdeta.costounitario,cyvcomprasdeta.costounimed,cyvcomprasdeta.costototal,;
                                    cyvcomprasdeta.idbodega,cyvcomprasdeta.idbodegatras,cyvcomprasdeta.idctrocosto,;
                                    cyvcomprasdeta.idkit,cyvcomprasdeta.llavekit,cyvcomprasdeta.llavelote,;
                                    cyvcomprasdeta.tipoprod,cyvcomprasdeta.periodo,cyvcomprasdeta.origen,;
                                    cyvcomprasdeta.cantidadkit,cyvcomprasdeta.cantidadserie,;
                                    lnctrolcomComDIns,cyvcomprasdeta.entsal,lnctrolcxpComDIns,lnctrolCYBComDIns,;
                                    lcnotasComEdi,cyvcomprasdeta.status,cyvcomprasdeta.eliminado,;
                                    cyvcomprasdeta.fecalta,cyvcomprasdeta.fecmod,cyvcomprasdeta.fecactu,;
                                    cyvcomprasdeta.nodo,cyvcomprasdeta.iduser,cyvcomprasdeta.pcuser)

                        lninsertado = _TALLY
                    ELSE
                        UPDATE takarEdi SET iddocto = cyvcomprasdeta.iddocto,;
                                            idtipodocto = ldidtipComDEdi,;
                                            idserie = lnidserComDEdi,;
                                            idcajban = lnidcajbanComEdi,;
                                            numero = lcnumComDEdi,;
                                            horadocto = lchoradoctoComEdi,;
                                            fechadocto = ldFecComDEdi,;
                                            idclipro = lnidclipComDEdi,;
                                            totaldocto = lnTotdComDEdi,;
                                            idproducto = cyvcomprasdeta.idproducto,;
                                            unimed = cyvcomprasdeta.unimed,;
                                            cantidad = cyvcomprasdeta.cantidad,;
                                            idproductoUniMed = cyvcomprasdeta.idproductoUniMed,;
                                            cantiunimed = cyvcomprasdeta.cantiunimed,;
                                            factor = cyvcomprasdeta.factor,;
                                            largo = cyvcomprasdeta.largo,;
                                            ancho = cyvcomprasdeta.ancho,;
                                            area = cyvcomprasdeta.area,;
                                            desperdicio = cyvcomprasdeta.desperdicio,;
                                            costounitario = cyvcomprasdeta.costounitario,;
                                            costounimed = cyvcomprasdeta.costounimed,;
                                            costototal = cyvcomprasdeta.costototal,;
                                            idbodega = cyvcomprasdeta.idbodega,;
                                            idbodegatras = cyvcomprasdeta.idbodegatras,;
                                            idctrocosto = cyvcomprasdeta.idctrocosto,;
                                            idkit = cyvcomprasdeta.idkit,;
                                            llavekit = cyvcomprasdeta.llavekit,;
                                            llavelote = cyvcomprasdeta.llavelote,;
                                            tipoprod = cyvcomprasdeta.tipoprod,;
                                            periodo = cyvcomprasdeta.periodo,;
                                            origen = cyvcomprasdeta.origen,;
                                            cantidadkit = cyvcomprasdeta.cantidadkit,;
                                            cantidadserie = cyvcomprasdeta.cantidadserie,;
                                            ctrolcomvta = lnctrolcomComDIns,;
                                            ctrolinv = cyvcomprasdeta.entsal,;
                                            ctrolcxcp = lnctrolcxpComDIns,;
                                            ctrolcyb = lnctrolCYBComDIns,;
                                            notas = lcnotasComEdi,;
                                            status = cyvcomprasdeta.status,;
                                            eliminado = cyvcomprasdeta.eliminado,;
                                            fecalta = cyvcomprasdeta.fecalta,;
                                            fecmod = cyvcomprasdeta.fecmod,;
                                            fecactu = cyvcomprasdeta.fecactu,;
                                            nodo = cyvcomprasdeta.nodo,;
                                            iduser = cyvcomprasdeta.iduser,;
                                            pcuser = cyvcomprasdeta.pcuser ;
                                        WHERE iddoctod = cyvcomprasdeta.iddoctod

                        lninsertado = _TALLY
                    ENDIF

                    **** posteando pedidos
                    IF lninsertado <> 0 AND lnidpedidod <> 0
                        UPDATE takarEdi SET cantidadpedido = cantidadpedido + lnCantiped ;
                            WHERE iddoctod = lnidpedidod
                    ENDIF

                    IF lninsertado = 0
                        lcidMensComEdi = "Error al Editar datos en el Kardex de productos"
                    ENDIF

                CATCH TO lEx
                    lcidMensComEdi = lcidMensComEdi + " Error " + TRANSFORM(lEx.Message)
                    llretorok = .f.

                FINALLY
                    IF !EMPTY(lcidAliasComEdi)
                        SELECT (lcidAliasComEdi)
                    ENDIF
                ENDTRY
            ELSE
                lcidMensComEdi = 'El Tipo de Documento no puede Ser 0 (Cero)'
            ENDIF
        ENDIF

        IF llTaKarEdiAbierta
            USE IN takarEdi
        ENDIF

        IF llTaKarInsAbiertaR
            USE IN cyvcompras
        ENDIF

        IF !EMPTY(lcidAliasComEdi)
            SELECT (lcidAliasComEdi)
        ENDIF
    ENDIF

    IF !EMPTY(lcidMensComEdi)
        MESSAGEBOX(lcidMensComEdi,16,'Error de Integridad... (_updatecomprasdeta)',3000)
        llretorok = .f.
    ENDIF

    RETURN llretorok
ENDPROC




**********************************
**** Compras Cuentas por Cobra y Pagar y CAJA / BANCOS
PROCEDURE _comprascreditocontado
	LOCAL lcidAliasComIns,lcidMensComIns,llTaKarInsAbierta,llTaKarInvAnuAbierta,lnStatusKardexCmp
		
	***** si se esta haciendo un cambio en la estructura de la tabla no valida algunas cosas
	IF TYPE("pncambiandoStructura")<>'N'
		pncambiandoStructura=0
	ENDIF 


	STORE ALIAS() TO lcidAliasComIns
	STORE '' TO lcidMensComIns
	STORE '' TO lcandCOMiNS
	llOkCOMCred=.t.
	
	IF pncambiandoStructura=0
		IF status=-1		&&&& es borrador no se hace nada
			lcidMensComIns=""
		ELSE 
			lnStatusKardexCmp=IIF(NVL(cyvcompras.anulado,0)=1 OR NVL(cyvcompras.eliminado,0)=1 OR NVL(cyvcompras.status,0)<=0,0,cyvcompras.status)

			llTaKarInvAnuAbierta=!USED("takarInvAnu")
			IF llTaKarInvAnuAbierta
				USE pcsysdir+pcDB+"\siskardex" IN 0 SHARED AGAIN ALIAS takarInvAnu
			ENDIF

			lltakardocInsAbierta=!USED("takardoc")
			IF lltakardocInsAbierta
				USE pcsysdir+pcDB+"\siskardexdoc" IN 0 SHARED AGAIN ALIAS takardoc ORDER iddocto
			ENDIF 

			llTaCajBanInsAbierta=!USED("tacajban")
			IF llTaCajBanInsAbierta
				USE pcsysdir+pcDB+"\cybcajabancos" IN 0 SHARED AGAIN ALIAS tacajban ORDER idcajban
			ENDIF 

			llTaTipDocInsAbierta=!USED("sistipodoctos")
			IF llTaTipDocInsAbierta
				USE pcsysdir+pcDB+"\sistipodoctos" IN 0 SHARED AGAIN ALIAS sistipodoctos ORDER idtipodoct
			ENDIF 

			***** KARDEX DE Cuentas por Cobrar o Pagar		jrjrjr
			IF cyvcompras.ctrolcxp<>0 OR cyvcompras.ctrolcyb<>0 AND cyvcompras.noContabilizable=0
				lniddocCOMIns=iddocto
				lnidTipDocCOMIns=idtipodocto
				IF SEEK(lnidTipDocCOMIns,'sistipodoctos','idtipodoct')
					lnConRefCOMIns=sistipodoctos.conreferencia
				ELSE
					lnConRefCOMIns=0
				ENDIF 
				TRY 
					IF SEEK(STR(lniddocCOMIns)+STR(lnidTipDocCOMIns),'takardoc','llave')
						
						UPDATE takardoc ; 
									SET idtipodocto=cyvcompras.idtipodocto,;
										idserie=cyvcompras.idserie,;
										idcajban=cyvcompras.idcajban,;
										idsucursal=cyvcompras.idsucursal,;
										idctrocosto=cyvcompras.idctrocosto,;
										numero=cyvcompras.numero,;
										fechadocto=cyvcompras.fechadocto,;
										fechavenci=cyvcompras.fechavenci,;
										idclipro=cyvcompras.idclipro,;
										idagente=cyvcompras.idagente,;
										idcajbantras=0,;
										numerocontrol=cyvcompras.numerocontrol,;
										selloRecepcion=cyvcompras.selloRecepcion,;
										codigoGeneracion=cyvcompras.codigoGeneracion,;
										idseriechq=idseriechq,;
										numerochq=cyvcompras.numerochq,;
										nomcheque=cyvcompras.nomcheque,;
										totaldocto=cyvcompras.totaldocto,;
										rentadocto=cyvcompras.rentadocto,;
										conreferencia=lnConRefCOMIns,;
										presupuesto=cyvcompras.presupuesto,;
										ciclo=cyvcompras.ciclo,;
										turno=cyvcompras.turno,;
										periodo=cyvcompras.periodo,;
										origen=cyvcompras.origen,;
										ctrolcxcp=cyvcompras.ctrolcxp,;
										ctrolcyb=cyvcompras.ctrolcyb,;
										status=lnStatusKardexCmp,;
										eliminado=cyvcompras.eliminado,;
										fecalta=cyvcompras.fecalta,;
										fecmod=cyvcompras.fecmod,;
										fecactu=cyvcompras.fecactu,;
										condipago=cyvcompras.condipago,;
										nodo=cyvcompras.nodo,;
										noContabilizable=cyvcompras.noContabilizable,;
										iduser=cyvcompras.iduser,;
										pcuser=cyvcompras.pcuser ;
										WHERE iddocto=lniddocCOMIns
						lnregistrosprocesados=	_tally
					ELSE
						lncantidadregistros=RECCOUNT('takardoc')
						INSERT INTO takardoc (iddocto,idtipodocto,idserie,idcajban,idcajbantras,idsucursal,idctrocosto,;
												numero,fechadocto,fechavenci,idclipro,idagente,totaldocto,condipago,;
												rentadocto,rentaabono,cargoabono,conreferencia,idseriechq,numerochq,nomcheque,;
												turno,periodo,origen,ctrolcxcp,ctrolcyb,status,eliminado,fecalta,;
												fecmod,fecactu,nodo,iduser,pcuser,codigoGeneracion,selloRecepcion,;
												numeroControl,presupuesto,ciclo,noContabilizable);
								VALUES (cyvcompras.iddocto,cyvcompras.idtipodocto,cyvcompras.idserie,cyvcompras.idcajban,;
										0,cyvcompras.idsucursal,cyvcompras.idctrocosto,cyvcompras.numero,;
										cyvcompras.fechadocto,cyvcompras.fechavenci,cyvcompras.idclipro,cyvcompras.idagente,;
										cyvcompras.totaldocto,cyvcompras.condipago,cyvcompras.rentadocto,0,0,lnConRefCOMIns,;
										cyvcompras.idseriechq,cyvcompras.numerochq,cyvcompras.nomcheque,cyvcompras.turno,;
										cyvcompras.periodo,cyvcompras.origen,cyvcompras.ctrolcxp,cyvcompras.ctrolcyb,;
										lnStatusKardexCmp,cyvcompras.eliminado,cyvcompras.fecalta,cyvcompras.fecmod,;
										cyvcompras.fecactu,cyvcompras.nodo,cyvcompras.iduser,cyvcompras.pcuser,;
										cyvcompras.codigoGeneracion,cyvcompras.selloRecepcion,cyvcompras.numeroControl,;
										cyvcompras.presupuesto,cyvcompras.ciclo,cyvcompras.noContabilizable)
						lnregistrosprocesados=RECCOUNT('takardoc')-lncantidadregistros
					ENDIF 
					IF lnregistrosprocesados=0
						lcidMensComIns="Error al Insertar Movimientos de Credito o Contado en Compras "
						lcandCOMiNS=', '
						llOkCOMCred=.f.
					ENDIF
 
				CATCH TO lEx 
					lcidMensComIns=lcidMensComIns+lcandCOMiNS+"Error " + TRANSFORM(lEx.Message)
					lcandCOMiNS=', '
					llOkCOMCred=.f.
				FINALLY
					SELECT (lcidAliasComIns)
				ENDTRY			 	
			ENDIF 

			IF USED("takarInvAnu")
				IF NVL(cyvcompras.anulado,0)=1 OR NVL(cyvcompras.eliminado,0)=1 OR NVL(cyvcompras.status,0)<=0
					UPDATE takarInvAnu ;
						SET status=lnStatusKardexCmp,;
							eliminado=1,;
							fecmod=cyvcompras.fecmod,;
							fecactu=cyvcompras.fecactu,;
							iduser=cyvcompras.iduser,;
							pcuser=cyvcompras.pcuser ;
						WHERE iddocto=cyvcompras.iddocto ;
							AND origen=cyvcompras.origen
				ELSE
					llCyvComprasDetaAbierta = !USED("cyvcomprasdeta")
					IF llCyvComprasDetaAbierta
						USE pcsysdir+pcDB+"\cyvcomprasdeta" IN 0 SHARED AGAIN ALIAS cyvcomprasdeta ORDER iddoctod
					ENDIF

					UPDATE takarInvAnu ;
						SET status=lnStatusKardexCmp,;
							eliminado=d.eliminado,;
							fecmod=cyvcompras.fecmod,;
							fecactu=cyvcompras.fecactu,;
							iduser=cyvcompras.iduser,;
							pcuser=cyvcompras.pcuser ;
						FROM cyvcomprasdeta d ;
						WHERE takarInvAnu.iddoctod=d.iddoctod ;
							AND takarInvAnu.iddocto=cyvcompras.iddocto ;
							AND takarInvAnu.origen=cyvcompras.origen ;
							AND (takarInvAnu.status<>lnStatusKardexCmp OR takarInvAnu.eliminado<>d.eliminado)

					IF llCyvComprasDetaAbierta
						USE IN cyvcomprasdeta
					ENDIF
				ENDIF
			ENDIF

			IF llTaKarInvAnuAbierta
				USE IN takarInvAnu
			ENDIF

			IF llTaCajBanInsAbierta
				USE IN tacajban
			ENDIF 
 
			IF lltakardocInsAbierta
				USE IN takardoc 
			ENDIF 
			IF llTaTipDocInsAbierta
				USE IN sistipodoctos
			ENDIF 
				
			SELECT (lcidAliasComIns)
		ENDIF 
	ELSE
		lcidMensComIns=''
	ENDIF 
	
	IF EMPTY(lcidMensComIns)
		RETURN .t.
	ELSE
		MESSAGEBOX(lcidMensComIns,16,'Error de Integridad... (_comprascreditocontado)',3000)
		RETURN .f.
	ENDIF 
ENDPROC 






**********************************
**********************************
***** VENTAS ********************

**** ventasDetalle insertar
PROCEDURE _insertventasdeta
IF TYPE('llEstamosCorriendoFVP') = 'U'
    RETURN .t.
ELSE
	LOCAL lcidAliasComIns,lcidMensComIns,llTaKarInsAbierta

	STORE ALIAS() TO lcidAliasComIns
	STORE '' TO lcidMensComIns
		
	IF status=-1		&&&& es borrador no se hace nada
		lcidMensComIns=""
	ELSE 
		llTaKarInsAbierta=!USED("takarIns")
		IF llTaKarInsAbierta
			USE pcsysdir+pcDB+"\siskardex" IN 0 SHARED AGAIN ALIAS takarIns ORDER iddoctod
		ENDIF 

		llTaKarInsAbiertaR=!USED("cyvventas")
		IF llTaKarInsAbiertaR
			USE pcsysdir+pcDB+"\cyvventas" IN 0 SHARED AGAIN ALIAS cyvventas ORDER iddocto
		ENDIF 

		***** KARDEX DE INVENTARIOS POR ventas
		**cyvventasdeta.entsal<>0
		IF .t.
			lnidComDIns=cyvventasdeta.iddocto
			lnidpedidod=cyvventasdeta.idpedidod
			lnidllave=cyvventasdeta.iddoctod
			
			IF cyvventasdeta.entsal=1
				lnCantiped=-cyvventasdeta.cantidad
			ELSE
				IF cyvventasdeta.entsal=2
					lnCantiped=cyvventasdeta.cantidad
				ELSE
					lnCantiped=0
				ENDIF
			ENDIF  
			
			IF SEEK(lnidComDIns,"cyvventas","iddocto")
				ldidtipComDIns=cyvventas.idtipodocto
				lnidserComDInv=cyvventas.idserie
				lcnumComDIns=cyvventas.numero
				ldFecComDIns=cyvventas.fechadocto
				lnidclipComDIns=cyvventas.idclipro
				lnTotdComDIns=cyvventas.totaldocto
				lnidcajbanComDIns=cyvventas.idcajban
				lnctrolCYBComDIns=cyvventas.ctrolcyb
				lnctrolvtaComDIns=cyvventas.ctrolvta
				lnctrolcxcComDIns=cyvventas.ctrolcxc
				lcnotasComDins=cyvventas.notas
				lchoradoctoComDins=cyvventas.horadocto
				lnidIslComDInv=cyvventas.idisla
			ELSE 
				ldidtipComDIns=0
				lnidserComDInv=0
				lcnumComDIns=''
				ldFecComDIns=CTOD(' ')
				lnidclipComDIns=0
				lnTotdComDIns=0
				lnidcajbanComDIns=0
				lchoradoctoComDins=''
				lcnotasComDins=''
				lnctrolCYBComDIns=0
				lnctrolvtaComDIns=0
				lnctrolcxcComDIns=0
				lnidIslComDInv=0
			ENDIF 
			IF ldidtipComDIns<>0
				TRY 
					lnregistrostotal=RECCOUNT('takarIns')
					lcversiesta=cyvventasdeta.iddoctod
					lcmitmpllalias=ALIAS()
					SELECT takarIns
					
					*LOCATE FOR takarIns.iddoctod=lcversiesta
					*llLlegoAlFinal=EOF()
					llLlegoAlFinal=!SEEK(lcversiesta ,'takarIns','iddoctod')
					
					IF !EMPTY(lcmitmpllalias)
						SELECT (lcmitmpllalias)	
					ENDIF 

					IF llLlegoAlFinal
			
						INSERT INTO takarIns (iddoctod,iddocto,idtipodocto,idserie,idcajban,idisla,numero,horadocto,fechadocto,idclipro,totaldocto,;
													idproducto,unimed,cantidad,idproductoUniMed,cantiunimed,factor,largo,ancho,area,desperdicio,;
													totalcesc,totalrenta,tipoiva,poriva,totaliva,preciosinivaminimo,preciosiniva,preciosinivaunidad,totalventasiniva,;
													costounitario,costounimed,costototal,idbodega,idbodegatras,idctrocosto,;
													idvendedord,idkit,llavekit,llavelote,tipoprod,periodo,origen,;
													cantidadkit,cantidadserie,ctrolcomvta,ctrolinv,ctrolcxcp,ctrolcyb,notas,status,eliminado,;
													fecalta,fecmod,fecactu,nodo,iduser,pcuser);
								VALUES (cyvventasdeta.iddoctod,cyvventasdeta.iddocto,ldidtipComDIns,lnidserComDInv,lnidcajbanComDIns,;
										lnidIslComDInv,lcnumComDIns,lchoradoctoComDins,ldFecComDIns,lnidclipComDIns,lnTotdComDIns,cyvventasdeta.idproducto,;
										cyvventasdeta.unimed,cyvventasdeta.cantidad,cyvventasdeta.idproductoUniMed,cyvventasdeta.cantiunimed,;
										cyvventasdeta.factor,cyvventasdeta.largo,cyvventasdeta.ancho,cyvventasdeta.area,cyvventasdeta.desperdicio,;
										cyvventasdeta.totalcesc,cyvventasdeta.totalrenta,cyvventasdeta.tipoiva,cyvventasdeta.poriva,;
										cyvventasdeta.totaliva,cyvventasdeta.preciosinivaminimo,cyvventasdeta.preciosiniva,;
										cyvventasdeta.preciosinivaunidad,cyvventasdeta.totalventasiniva,;
										cyvventasdeta.costounitario,cyvventasdeta.costounimed,cyvventasdeta.costototal,;
										cyvventasdeta.idbodega,cyvventasdeta.idbodegatras,cyvventasdeta.idctrocosto,;
										cyvventasdeta.idvendedord,cyvventasdeta.idkit,cyvventasdeta.llavekit,cyvventasdeta.llavelote,;
										cyvventasdeta.tipoprod,cyvventasdeta.periodo,cyvventasdeta.origen,;
										cyvventasdeta.cantidadkit,cyvventasdeta.cantidadserie,;
										lnctrolvtaComDIns,cyvventasdeta.entsal,lnctrolcxcComDIns,lnctrolcybComDIns,;
										lcnotasComDins,cyvventasdeta.status,cyvventasdeta.eliminado,;
										cyvventasdeta.fecalta,cyvventasdeta.fecmod,cyvventasdeta.fecactu,;
										cyvventasdeta.nodo,cyvventasdeta.iduser,cyvventasdeta.pcuser)
						lninsertado = RECCOUNT('takarIns')-lnregistrostotal
										
					ELSE
						UPDATE takarIns SET iddocto=cyvventasdeta.iddocto,;
											idtipodocto=ldidtipComDIns,;
											idserie=lnidserComDInv,;
											idisla=lnidIslComDInv,;
											idcajban=lnidcajbanComDIns,;
											numero=lcnumComDIns,;
											fechadocto=ldFecComDIns,;
											idclipro=lnidclipComDIns,;
											totaldocto=lnTotdComDIns,;
											idproducto=cyvventasdeta.idproducto,;
											unimed=cyvventasdeta.unimed,;
											cantidad=cyvventasdeta.cantidad,;
											idproductoUniMed=cyvventasdeta.idproductoUniMed,;
											cantiunimed=cyvventasdeta.cantiunimed,;
											factor=cyvventasdeta.factor,;
											largo=cyvventasdeta.largo,;
											ancho=cyvventasdeta.ancho,;
											area=cyvventasdeta.area,;
											idvendedord=cyvventasdeta.idvendedord,;
											desperdicio=cyvventasdeta.desperdicio,;
											costounitario=cyvventasdeta.costounitario,;
											costounimed=cyvventasdeta.costounimed,;
											costototal=cyvventasdeta.costototal,;
											totalcesc=cyvventasdeta.totalcesc,;
											totalrenta=cyvventasdeta.totalrenta,;
											tipoiva=cyvventasdeta.tipoiva,;
											poriva=cyvventasdeta.poriva,;
											totaliva=cyvventasdeta.totaliva,;
											preciosinivaminimo=cyvventasdeta.preciosinivaminimo,;
											preciosiniva=cyvventasdeta.preciosiniva,;
											preciosinivaunidad=cyvventasdeta.preciosinivaunidad,;
											totalventasiniva=cyvventasdeta.totalventasiniva,;
											idbodega=cyvventasdeta.idbodega,;
											idbodegatras=cyvventasdeta.idbodegatras,;
											idctrocosto=cyvventasdeta.idctrocosto,;
											idkit=cyvventasdeta.idkit,;
											llavekit=cyvventasdeta.llavekit,;
											llavelote=cyvventasdeta.llavelote,;
											tipoprod=cyvventasdeta.tipoprod,;
											periodo=cyvventasdeta.periodo,;
											origen=cyvventasdeta.origen,;
											cantidadkit=cyvventasdeta.cantidadkit,;
											cantidadserie=cyvventasdeta.cantidadserie,;
											ctrolcomvta=lnctrolvtaComDIns,;
											ctrolinv=cyvventasdeta.entsal,;
											ctrolcxcp=lnctrolcxcComDIns,;
											ctrolcyb=lnctrolcybComDIns,;
											status=cyvventasdeta.status,;
											eliminado=cyvventasdeta.eliminado,;
											fecalta=cyvventasdeta.fecalta,;
											fecmod=cyvventasdeta.fecmod,;
											fecactu=cyvventasdeta.fecactu,;
											nodo=cyvventasdeta.nodo,;
											iduser=cyvventasdeta.iduser,;
											pcuser=cyvventasdeta.pcuser ;
										WHERE iddoctod=cyvventasdeta.iddoctod
						lninsertado=1
					ENDIF 					
					**** posteando pedidos
					IF lninsertado<>0
						*REPLACE cantidadpedido WITH  cantidadpedido+lnCantiped FOR iddoctod=lnidpedidod IN takarIns
						UPDATE takarIns SET cantidadpedido=cantidadpedido+lnCantiped WHERE iddoctod=lnidpedidod
					ENDIF 
					
					IF lninsertado=0
						lcidMensComIns="Error al Insertar datos en el Kardex de productos"
					ENDIF

				CATCH TO lEx 
					lcidMensComIns=lcidMensComIns+" Error.. " + TRANSFORM(lEx.Message)
				FINALLY
					IF !EMPTY(lcidAliasComIns)
						SELECT (lcidAliasComIns)
					ENDIF 
				ENDTRY
			ELSE 
				lcidMensComIns='El tipo de Documento no puede ser 0 (cero)'
			ENDIF 
		ENDIF 
		
		IF llTaKarInsAbierta
			USE IN takarIns
		ENDIF 
		IF llTaKarInsAbiertaR
			USE IN cyvventas 
		ENDIF 
		IF !EMPTY(lcidAliasComIns)
			SELECT (lcidAliasComIns)
		ENDIF 
	ENDIF 


	IF EMPTY(lcidMensComIns)
	    llretornafin=.t.
	ELSE
        MESSAGEBOX(lcidMensComIns,16,'Error de Integridad... (_insertventasdeta)',2000)
	    llretornafin=.f.
	ENDIF
	
	RETURN llretornafin
ENDIF 
ENDPROC 







**** ventasDetalle Actualizar
PROCEDURE _updateventasdeta
IF TYPE('llEstamosCorriendoFVP') = 'U'
    RETURN .t.
ELSE
	LOCAL lcidAliasComEdi,lcidMensComEdi,llTaKarEdiAbierta

	STORE ALIAS() TO lcidAliasComEdi
	STORE '' TO lcidMensComEdi
	llretorok=.t.

	IF (status=-1 and CURVAL("status")=-1) AND !(CURVAL("status")=-1 AND status=1) AND !(CURVAL("status")=1 AND status=0)		&&&& es borrador no se hace nada

		llretorok=.t.

	ELSE 

		llTaKarEdiAbierta=!USED("takarEdi")
		IF llTaKarEdiAbierta
			USE pcsysdir+pcDB+"\siskardex" IN 0 SHARED AGAIN ALIAS takarEdi ORDER iddoctod
		ENDIF  
		llTaKarInsAbiertaR=!USED("cyvventas")
		IF llTaKarInsAbiertaR
			USE pcsysdir+pcDB+"\cyvventas" IN 0 SHARED AGAIN ALIAS cyvventas ORDER iddocto
		ENDIF 

		***** KARDEX DE INVENTARIOS por ventas
		** cyvventasdeta.entsal<>0
		IF .t.
			lnidComDEdi=cyvventasdeta.iddocto
			lnidpedidod=cyvventasdeta.idpedidod
			lnregactu=cyvventasdeta.iddoctod
			
			IF cyvventasdeta.entsal=1
				IF (CURVAL("cyvventasdeta.status")<>0 AND cyvventasdeta.status=0)
					lnCantiped=+CURVAL("cyvventasdeta.cantidad")
				ELSE
					IF cyvventasdeta.status<>0
						lnCantiped=+CURVAL("cyvventasdeta.cantidad")-cyvventasdeta.cantidad
					ELSE
						lnCantiped=0
					ENDIF 
				ENDIF 
			ELSE
				IF cyvventasdeta.entsal=2
					IF (CURVAL("cyvventasdeta.status")<>0 AND cyvventasdeta.status=0)
						lnCantiped=-CURVAL("cyvventasdeta.cantidad")
					ELSE
						IF cyvventasdeta.status<>0
							lnCantiped=-CURVAL("cyvventasdeta.cantidad")+cyvventasdeta.cantidad
						ELSE 
							lnCantiped=0
						ENDIF 
					ENDIF 
				ELSE
					lnCantiped=0
				ENDIF
			ENDIF  

			IF SEEK(lnidComDEdi,"cyvventas","iddocto")	
				ldidtipComDEdi=cyvventas.idtipodocto
				lnidserComDEdi=cyvventas.idserie
				lcnumComDEdi=cyvventas.numero
				ldFecComDEdi=cyvventas.fechadocto
				lnidclipComDEdi=cyvventas.idclipro
				lnTotdComDEdi=cyvventas.totaldocto
				lnidcajbanComEdi=cyvventas.idcajban
				lnctrolCYBComDIns=cyvventas.ctrolcyb
				lnctrolvtaComDIns=cyvventas.ctrolvta
				lnctrolcxcComDIns=cyvventas.ctrolcxc
				lchoradoctoComEdi=cyvventas.horadocto
				lcnotasComEdi=cyvventas.notas
				lnidIslComDEdi=cyvventas.idisla
			ELSE 
				ldidtipComDEdi=0
				lnctrolcxcComDIns=0
				lnidserComDEdi=0
				lcnumComDEdi=''
				ldFecComDEdi=CTOD(' ')
				lnidclipComDEdi=0
				lnctrolcybcomdins=0
				lnTotdComDEdi=0
				lnidcajbanComEdi=0
				lchoradoctoComEdi=''
				lcnotasComEdi=''
				lnctrolvtaComDIns=0
				lnidIslComDEdi=0
			ENDIF 
			IF ldidtipComDEdi<>0
				TRY 
					IF (CURVAL("status")=-1 AND status<>-1)
						lnregistrostotal=RECCOUNT('takarEdi')
					
						INSERT INTO takarEdi (iddoctod,iddocto,idtipodocto,idserie,idcajban,idisla,numero,horadocto,fechadocto,idclipro,totaldocto,;
												idproducto,unimed,cantidad,idproductoUniMed,cantiunimed,factor,largo,ancho,area,desperdicio,;
												totalcesc,totalrenta,tipoiva,poriva,totaliva,preciosinivaminimo,preciosiniva,preciosinivaunidad,totalventasiniva,;
												costounitario,costounimed,costototal,idbodega,idbodegatras,idctrocosto,;
												idvendedord,idkit,llavekit,llavelote,tipoprod,periodo,origen,;
												cantidadkit,cantidadserie,ctrolcomvta,ctrolinv,ctrolcxcp,ctrolcyb,notas,status,eliminado,;
												fecalta,fecmod,fecactu,nodo,iduser,pcuser);
							VALUES (cyvventasdeta.iddoctod,cyvventasdeta.iddocto,ldidtipComDEdi,lnidserComDEdi,lnidcajbanComEdi,;
									lnidIslComDEdi,lcnumComDEdi,lchoradoctoComEdi,ldFecComDEdi,lnidclipComDEdi,lnTotdComDEdi,cyvventasdeta.idproducto,;
									cyvventasdeta.unimed,cyvventasdeta.cantidad,cyvventasdeta.idproductoUniMed,cyvventasdeta.cantiunimed,;
									cyvventasdeta.factor,cyvventasdeta.largo,cyvventasdeta.ancho,cyvventasdeta.area,cyvventasdeta.desperdicio,;
									cyvventasdeta.totalcesc,cyvventasdeta.totalrenta,cyvventasdeta.tipoiva,cyvventasdeta.poriva,;
									cyvventasdeta.totaliva,cyvventasdeta.preciosinivaminimo,cyvventasdeta.preciosiniva,;
									cyvventasdeta.preciosinivaunidad,cyvventasdeta.totalventasiniva,;
									cyvventasdeta.costounitario,cyvventasdeta.costounimed,cyvventasdeta.costototal,;
									cyvventasdeta.idbodega,cyvventasdeta.idbodegatras,cyvventasdeta.idctrocosto,;
									cyvventasdeta.idvendedord,cyvventasdeta.idkit,cyvventasdeta.llavekit,cyvventasdeta.llavelote,;
									cyvventasdeta.tipoprod,cyvventasdeta.periodo,cyvventasdeta.origen,;
									cyvventasdeta.cantidadkit,cyvventasdeta.cantidadserie,;
									lnctrolvtaComDIns,cyvventasdeta.entsal,lnctrolcxcComDIns,lnctrolcybComDIns,;
									lcnotasComEdi,cyvventasdeta.status,cyvventasdeta.eliminado,;
									cyvventasdeta.fecalta,cyvventasdeta.fecmod,cyvventasdeta.fecactu,;
									cyvventasdeta.nodo,cyvventasdeta.iduser,cyvventasdeta.pcuser)
						lninsertado=RECCOUNT('takarEdi')-lnregistrostotal
						
					ELSE 
						lninsertado = 0

						UPDATE takarEdi SET iddocto=cyvventasdeta.iddocto,;
						                    idtipodocto=ldidtipComDEdi,;
						                    idserie=lnidserComDEdi,;
						                    idisla=lnidIslComDEdi,;
						                    idcajban=lnidcajbanComEdi,;
						                    numero=lcnumComDEdi,;
						                    horadocto=lchoradoctoComEdi,;
						                    fechadocto=ldFecComDEdi,;
						                    idclipro=lnidclipComDEdi,;
						                    totaldocto=lnTotdComDEdi,;
						                    idproducto=cyvventasdeta.idproducto,;
						                    unimed=cyvventasdeta.unimed,;
						                    cantidad=cyvventasdeta.cantidad,;
						                    idproductoUniMed=cyvventasdeta.idproductoUniMed,;
						                    cantiunimed=cyvventasdeta.cantiunimed,;
						                    factor=cyvventasdeta.factor,;
						                    largo=cyvventasdeta.largo,;
						                    ancho=cyvventasdeta.ancho,;
						                    area=cyvventasdeta.area,;
						                    idvendedord=cyvventasdeta.idvendedord,;
						                    desperdicio=cyvventasdeta.desperdicio,;
						                    costounitario=cyvventasdeta.costounitario,;
						                    costounimed=cyvventasdeta.costounimed,;
						                    costototal=cyvventasdeta.costototal,;
						                    totalcesc=cyvventasdeta.totalcesc,;
						                    totalrenta=cyvventasdeta.totalrenta,;
						                    tipoiva=cyvventasdeta.tipoiva,;
						                    poriva=cyvventasdeta.poriva,;
						                    totaliva=cyvventasdeta.totaliva,;
						                    preciosinivaminimo=cyvventasdeta.preciosinivaminimo,;
						                    preciosiniva=cyvventasdeta.preciosiniva,;
						                    preciosinivaunidad=cyvventasdeta.preciosinivaunidad,;
						                    totalventasiniva=cyvventasdeta.totalventasiniva,;
						                    idbodega=cyvventasdeta.idbodega,;
						                    idbodegatras=cyvventasdeta.idbodegatras,;
						                    idctrocosto=cyvventasdeta.idctrocosto,;
						                    idkit=cyvventasdeta.idkit,;
						                    llavekit=cyvventasdeta.llavekit,;
						                    llavelote=cyvventasdeta.llavelote,;
						                    tipoprod=cyvventasdeta.tipoprod,;
						                    periodo=cyvventasdeta.periodo,;
						                    origen=cyvventasdeta.origen,;
						                    cantidadkit=cyvventasdeta.cantidadkit,;
						                    cantidadserie=cyvventasdeta.cantidadserie,;
						                    ctrolcomvta=lnctrolvtaComDIns,;
						                    ctrolinv=cyvventasdeta.entsal,;
						                    ctrolcxcp=lnctrolcxcComDIns,;
						                    ctrolcyb=lnctrolcybComDIns,;
						                    notas=lcnotasComEdi,;
						                    status=cyvventasdeta.status,;
						                    eliminado=cyvventasdeta.eliminado,;
						                    fecalta=cyvventasdeta.fecalta,;
						                    fecmod=cyvventasdeta.fecmod,;
						                    fecactu=cyvventasdeta.fecactu,;
						                    nodo=cyvventasdeta.nodo,;
						                    iduser=cyvventasdeta.iduser,;
						                    pcuser=cyvventasdeta.pcuser ;
						                WHERE iddoctod=cyvventasdeta.iddoctod

						lninsertado = _TALLY

						IF lninsertado = 0
						
						    INSERT INTO takarEdi (iddoctod,iddocto,idtipodocto,idserie,idcajban,idisla,numero,horadocto,fechadocto,idclipro,totaldocto,;
						                          idproducto,unimed,cantidad,idproductoUniMed,cantiunimed,factor,largo,ancho,area,desperdicio,;
						                          totalcesc,totalrenta,tipoiva,poriva,totaliva,preciosinivaminimo,preciosiniva,preciosinivaunidad,totalventasiniva,;
						                          costounitario,costounimed,costototal,idbodega,idbodegatras,idctrocosto,;
						                          idvendedord,idkit,llavekit,llavelote,tipoprod,periodo,origen,;
						                          cantidadkit,cantidadserie,ctrolcomvta,ctrolinv,ctrolcxcp,ctrolcyb,notas,status,eliminado,;
						                          fecalta,fecmod,fecactu,nodo,iduser,pcuser);
						        VALUES (cyvventasdeta.iddoctod,cyvventasdeta.iddocto,ldidtipComDEdi,lnidserComDEdi,lnidcajbanComEdi,;
						                lnidIslComDEdi,lcnumComDEdi,lchoradoctoComEdi,ldFecComDEdi,lnidclipComDEdi,lnTotdComDEdi,cyvventasdeta.idproducto,;
						                cyvventasdeta.unimed,cyvventasdeta.cantidad,cyvventasdeta.idproductoUniMed,cyvventasdeta.cantiunimed,;
						                cyvventasdeta.factor,cyvventasdeta.largo,cyvventasdeta.ancho,cyvventasdeta.area,cyvventasdeta.desperdicio,;
						                cyvventasdeta.totalcesc,cyvventasdeta.totalrenta,cyvventasdeta.tipoiva,cyvventasdeta.poriva,;
						                cyvventasdeta.totaliva,cyvventasdeta.preciosinivaminimo,cyvventasdeta.preciosiniva,;
						                cyvventasdeta.preciosinivaunidad,cyvventasdeta.totalventasiniva,;
						                cyvventasdeta.costounitario,cyvventasdeta.costounimed,cyvventasdeta.costototal,;
						                cyvventasdeta.idbodega,cyvventasdeta.idbodegatras,cyvventasdeta.idctrocosto,;
						                cyvventasdeta.idvendedord,cyvventasdeta.idkit,cyvventasdeta.llavekit,cyvventasdeta.llavelote,;
						                cyvventasdeta.tipoprod,cyvventasdeta.periodo,cyvventasdeta.origen,;
						                cyvventasdeta.cantidadkit,cyvventasdeta.cantidadserie,;
						                lnctrolvtaComDIns,cyvventasdeta.entsal,lnctrolcxcComDIns,lnctrolcybComDIns,;
						                lcnotasComEdi,cyvventasdeta.status,cyvventasdeta.eliminado,;
						                cyvventasdeta.fecalta,cyvventasdeta.fecmod,cyvventasdeta.fecactu,;
						                cyvventasdeta.nodo,cyvventasdeta.iduser,cyvventasdeta.pcuser)

						    lninsertado = 1
						ENDIF
					ENDIF 
					**** posteando pedidos

					IF lnidpedidod<>0
						*REPLACE cantidadpedido WITH cantidadpedido+lnCantiped FOR iddoctod=lnidpedidod IN  takarIns 
						UPDATE takarEdi SET cantidadpedido=cantidadpedido+lnCantiped WHERE iddoctod=lnidpedidod
					ENDIF 
					
					IF lninsertado=0

						lcidMensComEdi="Error al Editar datos en el Kardex de productos  .."
					ENDIF 	

				CATCH TO lEx 

					lcidMensComEdi=lcidMensComEdi+" Error " + TRANSFORM(lEx.Message)
 
					llretorok=.f.
				FINALLY
					IF llTaKarEdiAbierta
						USE IN takarEdi
					ENDIF 
					IF llTaKarInsAbiertaR
						USE IN cyvventas
					ENDIF 
						
					SELECT (lcidAliasComEdi)
					
					IF !EMPTY(lcidMensComEdi)
						llretorok=.f.
					ENDIF 

				ENDTRY
			ELSE
				lcidMensComEdi='El Tipo de Documento no puede Ser 0 (Cero)'
			ENDIF 	
		ENDIF 
	ENDIF 

	IF !EMPTY(lcidMensComEdi)
        MESSAGEBOX(lcidMensComEdi,16,'Error de Integridad... (_updateventasdeta)',2000)
	    llretorok = .f.
	ENDIF
	RETURN llretorok
ENDIF 
ENDPROC 


**********************************
**** ventas Cuentas por Cobra y Pagar y CAJA / BANCOS
PROCEDURE _ventascreditocontado
IF TYPE('llEstamosCorriendoFVP') = 'U'
    RETURN .t.
ELSE
	LOCAL lcidAliasComIns,lcidMensComIns,llTaKarInsAbierta,llTaKarInvAnuAbierta,lnStatusKardexVta
	***** si se esta haciendo un cambio en la estructura de la tabla no valida algunas cosas
	IF TYPE("pncambiandoStructura")<>'N'
		pncambiandoStructura=0
	ENDIF 
	
	STORE ALIAS() TO lcidAliasComIns
	STORE '' TO lcidMensComIns
	STORE '' TO lcandCOMiNS
	llOkCOMCred=.t.
	
	IF pncambiandoStructura=0
	
		IF status=-1		&&&& es borrador no se hace nada
			lcidMensComIns=""
		ELSE 
			lnStatusKardexVta=IIF(NVL(cyvventas.anulado,0)=1 OR NVL(cyvventas.eliminado,0)=1 OR NVL(cyvventas.status,0)<=0,0,cyvventas.status)

			llTaKarInvAnuAbierta=!USED("takarInvAnu")
			IF llTaKarInvAnuAbierta
				USE pcsysdir+pcDB+"\siskardex" IN 0 SHARED AGAIN ALIAS takarInvAnu
			ENDIF

			lltakardocInsAbierta=!USED("takardoc")
			IF lltakardocInsAbierta
				USE pcsysdir+pcDB+"\siskardexdoc" IN 0 SHARED AGAIN ALIAS takardoc ORDER iddocto
			ENDIF 

			llTaCajBanInsAbierta=!USED("tacajban")
			IF llTaCajBanInsAbierta
				USE pcsysdir+pcDB+"\cybcajabancos" IN 0 SHARED AGAIN ALIAS tacajban ORDER idcajban
			ENDIF 

			llTaTipDocInsAbierta=!USED("sistipodoctos")
			IF llTaTipDocInsAbierta
				USE pcsysdir+pcDB+"\sistipodoctos" IN 0 SHARED AGAIN ALIAS sistipodoctos ORDER idtipodoct
			ENDIF 

			IF TYPE("takardoc.MotivoVenta")='N'
				lcGuardarMotivo1="motivoventa=cyvventas.motivoventa,"
				lcGuardarMotivo2=",motivoventa"
				lcGuardarMotivo3=",cyvventas.motivoventa"
			ELSE
				lcGuardarMotivo1=''
				lcGuardarMotivo2=''
				lcGuardarMotivo3=''
			ENDIF 

			***** KARDEX DE Cuentas por Cobrar o Pagar
			IF cyvventas.ctrolcxc<>0 OR cyvventas.ctrolcyb<>0 AND cyvventas.noContabilizable=0
				lniddocCOMIns=iddocto
				lnidTipDocCOMIns=idtipodocto
				IF SEEK(lnidTipDocCOMIns,'sistipodoctos','idtipodoct')
					lnConRefCOMIns=sistipodoctos.conreferencia
				ELSE
					lnConRefCOMIns=0
				ENDIF 
				TRY 
					IF SEEK(lniddocCOMIns,'takardoc','iddocto')
						UPDATE takardoc ; 
									SET idtipodocto=cyvventas.idtipodocto,;
										idserie=cyvventas.idserie,;
										idcajban=cyvventas.idcajban,;
										idisla=cyvventas.idisla,;
										idsucursal=cyvventas.idsucursal,;
										idctrocosto=cyvventas.idctrocosto,;
										numero=cyvventas.numero,;
										fechadocto=cyvventas.fechadocto,;
										fechavenci=cyvventas.fechavenci,;
										idclipro=cyvventas.idclipro,;
										idagente=cyvventas.idagente,;
										idcajbantras=0,&lcGuardarMotivo1;
										numerocontrol=cyvventas.numerocontrol,;
										selloRecepcion=cyvventas.selloRecepcion,;
										codigoGeneracion=cyvventas.codigoGeneracion,;
										turno=cyvventas.turno,;
										idseriechq=idseriechq,;
										presupuesto=cyvventas.presupuesto,;
										ciclo=cyvventas.ciclo,;
										numerochq=cyvventas.numerochq,;
										nomcheque=cyvventas.nomcheque,;
										numerofin=cyvventas.numerofin,;
										idseriefu=cyvventas.idseriefu,;
										numerofu=cyvventas.numerofu,;
										totaldocto=cyvventas.totaldocto+cyvventas.propina,;
										rentadocto=cyvventas.rentadocto,;
										conreferencia=lnConRefCOMIns,;
										periodo=cyvventas.periodo,;
										origen=cyvventas.origen,;
										ctrolcxcp=cyvventas.ctrolcxc,;
										ctrolcyb=cyvventas.ctrolcyb,;
										status=lnStatusKardexVta,;
										eliminado=cyvventas.eliminado,;
										fecalta=cyvventas.fecalta,;
										fecmod=cyvventas.fecmod,;
										recintofiscal=cyvventas.recintofiscal,;
										regimen=cyvventas.regimen,;
										incoterms=cyvventas.incoterms,;
										fecactu=cyvventas.fecactu,;
										condipago=cyvventas.condipago,;
										nodo=cyvventas.nodo,;
										iduser=cyvventas.iduser,;
										noContabilizable=cyvventas.noContabilizable,;
										pcuser=cyvventas.pcuser ; 
										WHERE iddocto=lniddocCOMIns
						lncuentacambio=_tally 
						IF lncuentacambio=0
							lncuentacambio=1
						ENDIF 

					ELSE
						lncuentacambio=RECCOUNT("takardoc")
						INSERT INTO takardoc (iddocto,idtipodocto,idserie,idcajban,idcajbantras,idsucursal,idctrocosto,;
												idisla,numero,numerofin,idseriefu,numerofu,turno,fechadocto,fechavenci,idclipro,;
												idagente,totaldocto,condipago,rentadocto,rentaabono,cargoabono,conreferencia,;
												idseriechq,numerochq,nomcheque,periodo,origen,ctrolcxcp,ctrolcyb,;
												status,eliminado,fecalta,fecmod,fecactu,nodo,iduser,pcuser,regimen,;
												codigoGeneracion,selloRecepcion,numeroControl,presupuesto,recintofiscal,incoterms,;
												noContabilizable,ciclo &lcGuardarMotivo2);
								VALUES (cyvventas.iddocto,cyvventas.idtipodocto,cyvventas.idserie,cyvventas.idcajban,;
										0,cyvventas.idsucursal,cyvventas.idctrocosto,cyvventas.idisla,cyvventas.numero,;
										cyvventas.numerofin,cyvventas.idseriefu,cyvventas.numerofu,cyvventas.turno,;
										cyvventas.fechadocto,cyvventas.fechavenci,cyvventas.idclipro,cyvventas.idagente,;
										cyvventas.totaldocto+cyvventas.propina,cyvventas.condipago,cyvventas.rentadocto,0,0,lnConRefCOMIns,;
										cyvventas.idseriechq,cyvventas.numerochq,cyvventas.nomcheque,cyvventas.periodo,cyvventas.origen,;
										cyvventas.ctrolcxc,cyvventas.ctrolcyb,lnStatusKardexVta,cyvventas.eliminado,cyvventas.fecalta,;
										cyvventas.fecmod,cyvventas.fecactu,cyvventas.nodo,cyvventas.iduser,cyvventas.pcuser,cyvventas.regimen,;
										cyvventas.codigoGeneracion,cyvventas.selloRecepcion,cyvventas.numeroControl,;
										cyvventas.presupuesto,cyvventas.recintofiscal,cyvventas.incoterms,;
										cyvventas.noContabilizable,cyvventas.ciclo &lcGuardarMotivo3)
						lncuentacambio=RECCOUNT("takardoc")-lncuentacambio
					ENDIF 
					IF lncuentacambio=0
						lcidMensComIns="Error al Insertar Movimientos de Credito o Contado en ventas "
						lcandCOMiNS=', '
						llOkCOMCred=.f.
					ENDIF
				CATCH TO lEx 
					lcidMensComIns=lcidMensComIns+lcandCOMiNS+"Error " + TRANSFORM(lEx.Message)
					lcandCOMiNS=', '
					llOkCOMCred=.f.
				FINALLY
					SELECT (lcidAliasComIns)
				ENDTRY			 	
			ENDIF 

			IF USED("takarInvAnu")
				IF NVL(cyvventas.anulado,0)=1 OR NVL(cyvventas.eliminado,0)=1 OR NVL(cyvventas.status,0)<=0
					UPDATE takarInvAnu ;
						SET status=lnStatusKardexVta,;
							eliminado=1,;
							fecmod=cyvventas.fecmod,;
							fecactu=cyvventas.fecactu,;
							iduser=cyvventas.iduser,;
							pcuser=cyvventas.pcuser ;
						WHERE iddocto=cyvventas.iddocto ;
							AND origen=cyvventas.origen
				ELSE
					llCyvVentasDetaAbierta = !USED("cyvventasdeta")
					IF llCyvVentasDetaAbierta
						USE pcsysdir+pcDB+"\cyvventasdeta" IN 0 SHARED AGAIN ALIAS cyvventasdeta ORDER iddoctod
					ENDIF

					UPDATE takarInvAnu ;
						SET status=lnStatusKardexVta,;
							eliminado=d.eliminado,;
							fecmod=cyvventas.fecmod,;
							fecactu=cyvventas.fecactu,;
							iduser=cyvventas.iduser,;
							pcuser=cyvventas.pcuser ;
						FROM cyvventasdeta d ;
						WHERE takarInvAnu.iddoctod=d.iddoctod ;
							AND takarInvAnu.iddocto=cyvventas.iddocto ;
							AND takarInvAnu.origen=cyvventas.origen ;
							AND (takarInvAnu.status<>lnStatusKardexVta OR takarInvAnu.eliminado<>d.eliminado)

					IF llCyvVentasDetaAbierta
						USE IN cyvventasdeta
					ENDIF
				ENDIF
			ENDIF
			
			IF llTaKarInvAnuAbierta
				USE IN takarInvAnu
			ENDIF

			IF llTaCajBanInsAbierta
				USE IN tacajban
			ENDIF 

			IF lltakardocInsAbierta
				USE IN takardoc 
			ENDIF 
			IF llTaTipDocInsAbierta
				USE IN sistipodoctos
			ENDIF 
				
			SELECT (lcidAliasComIns)
		ENDIF 
	ELSE
		lcidMensComIns=''
	ENDIF 
	
	
	IF EMPTY(lcidMensComIns)
	    llretornafin=.t.
	ELSE
        MESSAGEBOX(lcidMensComIns,16,'Error de Integridad... (_ventascreditocontado)',2000)
	    llretornafin=.f.
	ENDIF


	RETURN llretornafin
ENDIF 
ENDPROC 





**********************************
**** Movimientos Bancarios
PROCEDURE _movimientosbancarios
	LOCAL lcidAliasComIns,lcidMensComIns,llTaKarInsAbierta
	
	STORE ALIAS() TO lcidAliasComIns
	STORE '' TO lcidMensComIns
	STORE '' TO lcandCOMiNS
	llOkMOVBcos=.t.
	
	IF status=-1		&&&& es borrador no se hace nada
		lcidMensComIns=""
	ELSE 
		lltakardocInsAbierta=!USED("takardoc")
		IF lltakardocInsAbierta
			USE pcsysdir+pcDB+"\siskardexdoc" IN 0 SHARED AGAIN ALIAS takardoc ORDER iddocto
		ENDIF 

		llTaCajBanInsAbierta=!USED("tacajban")
		IF llTaCajBanInsAbierta
			USE pcsysdir+pcDB+"\cybcajabancos" IN 0 SHARED AGAIN ALIAS tacajban ORDER idcajban
		ENDIF 

		llTaTipDocInsAbierta=!USED("sistipodoctos")
		IF llTaTipDocInsAbierta
			USE pcsysdir+pcDB+"\sistipodoctos" IN 0 SHARED AGAIN ALIAS sistipodoctos ORDER idtipodoct
		ENDIF 

		***** KARDEX DE Cuentas por Cobrar o Pagar
		IF cybmovimientos.ctrolcxcp<>0 OR cybmovimientos.ctrolcyb<>0
			lniddocCOMIns=iddocto
			lnidTipDocCOMIns=idtipodocto
			IF SEEK(lnidTipDocCOMIns,'sistipodoctos','idtipodoct')
				lnConRefCOMIns=sistipodoctos.conreferencia
			ELSE
				lnConRefCOMIns=0
			ENDIF 
			TRY 
				IF SEEK(lniddocCOMIns,'takardoc','iddocto')
					UPDATE takardoc ; 
								SET idtipodocto=cybmovimientos.idtipodocto,;
									idserie=cybmovimientos.idserie,;
									idcajban=cybmovimientos.idcajban,;
									idcajbantras=cybmovimientos.idcajbantras,;
									idsucursal=cybmovimientos.idsucursal,;
									idctrocosto=cybmovimientos.idctrocosto,;
									numero=cybmovimientos.numero,;
									fechadocto=cybmovimientos.fechadocto,;
									fechavenci=cybmovimientos.fechadocto,;
									idclipro=cybmovimientos.idclipro,;
									idagente=cybmovimientos.idagente,;
									turno=cybmovimientos.turno,;
									idseriechq=idseriechq,;
									presupuesto=cybmovimientos.presupuesto,;
									ciclo=cybmovimientos.ciclo,;
									numerochq=cybmovimientos.numerochq,;
									nomcheque=cybmovimientos.nomcheque,;
									totaldocto=cybmovimientos.totaldocto,;																																								
									totaldoctotras=cybmovimientos.totaldoctotras,;
									rentadocto=cybmovimientos.rentadocto,;
									conreferencia=lnConRefCOMIns,;
									periodo=cybmovimientos.periodo,;
									origen=cybmovimientos.origen,;
									ctrolcxcp=cybmovimientos.ctrolcxcp,;
									ctrolcyb=cybmovimientos.ctrolcyb,;
									status=cybmovimientos.status,;
									eliminado=cybmovimientos.eliminado,;
									fecalta=cybmovimientos.fecalta,;
									fecmod=cybmovimientos.fecmod,;
									fecactu=cybmovimientos.fecactu,;
									condipago=IIF(cybmovimientos.ctrolcxcp<>0,1,0),;
									nodo=cybmovimientos.nodo,;
									iduser=cybmovimientos.iduser,;
									pcuser=cybmovimientos.pcuser ; 
									WHERE iddocto=lniddocCOMIns
					lncuentareg=_tally
				ELSE
					lncuentaold=RECCOUNT('takardoc')
					INSERT INTO takardoc (iddocto,idtipodocto,idserie,idcajban,idcajbantras,idsucursal,idctrocosto,;
											numero,fechadocto,fechavenci,idclipro,idagente,totaldocto,totaldoctotras,condipago,;
											rentadocto,rentaabono,cargoabono,conreferencia,idseriechq,numerochq,nomcheque,;
											turno,periodo,origen,ctrolcxcp,ctrolcyb,status,eliminado,fecalta,;
											fecmod,fecactu,nodo,iduser,pcuser,presupuesto,ciclo);
							VALUES (cybmovimientos.iddocto,cybmovimientos.idtipodocto,cybmovimientos.idserie,cybmovimientos.idcajban,;
									cybmovimientos.idcajbantras,cybmovimientos.idsucursal,cybmovimientos.idctrocosto,cybmovimientos.numero,;
									cybmovimientos.fechadocto,cybmovimientos.fechadocto,cybmovimientos.idclipro,cybmovimientos.idagente,;
									cybmovimientos.totaldocto,cybmovimientos.totaldoctotras,IIF(cybmovimientos.ctrolcxcp<>0,1,0),cybmovimientos.rentadocto,0,0,lnConRefCOMIns,;
									cybmovimientos.idseriechq,cybmovimientos.numerochq,cybmovimientos.nomcheque,cybmovimientos.turno,;
									cybmovimientos.periodo,cybmovimientos.origen,cybmovimientos.ctrolcxcp,cybmovimientos.ctrolcyb,;
									cybmovimientos.status,cybmovimientos.eliminado,cybmovimientos.fecalta,cybmovimientos.fecmod,;
									cybmovimientos.fecactu,cybmovimientos.nodo,cybmovimientos.iduser,cybmovimientos.pcuser,cybmovimientos.presupuesto,cybmovimientos.ciclo)
					lncuentareg=RECCOUNT('takardoc')-lncuentaold
				ENDIF 
				IF lncuentareg=0
					lcidMensComIns="Error al Insertar Movimientos Bancarios"
					lcandCOMiNS=', '
					llOkMOVBcos=.f.
				ENDIF
			CATCH TO lEx 
				lcidMensComIns=lcidMensComIns+lcandCOMiNS+"Error " + TRANSFORM(lEx.Message)
				lcandCOMiNS=', '
				llOkMOVBcos=.f.
			FINALLY
				SELECT (lcidAliasComIns)
			ENDTRY			 	
		ENDIF 

		IF llTaCajBanInsAbierta
			USE IN tacajban
		ENDIF 

		IF lltakardocInsAbierta
			USE IN takardoc 
		ENDIF 
		IF llTaTipDocInsAbierta
			USE IN sistipodoctos
		ENDIF 
			
		SELECT (lcidAliasComIns)
	ENDIF 
	
	IF EMPTY(lcidMensComIns)
		RETURN .t.
	ELSE
		MESSAGEBOX(lcidMensComIns,16,'Error de Integridad... (_movimientosbancarios)',3000)
		RETURN .f.
	ENDIF 
ENDPROC 


**********************************
**** Movimientos Cuentas por Cobrar y Pagar
PROCEDURE _cuentascobrarpagar
	LOCAL lcidAliasComIns,lcidMensComIns,llTaKarInsAbierta
	
	STORE ALIAS() TO lcidAliasComIns
	STORE '' TO lcidMensComIns
	STORE '' TO lcandCOMiNS
	llOkMOVBcos=.t.
	
	IF status=-1		&&&& es borrador no se hace nada
		lcidMensComIns=""
	ELSE 
		lltakardocInsAbierta=!USED("takardoc")
		IF lltakardocInsAbierta
			USE pcsysdir+pcDB+"\siskardexdoc" IN 0 SHARED AGAIN ALIAS takardoc ORDER iddocto
		ENDIF 

		llTaCajBanInsAbierta=!USED("tacajban")
		IF llTaCajBanInsAbierta
			USE pcsysdir+pcDB+"\cybcajabancos" IN 0 SHARED AGAIN ALIAS tacajban ORDER idcajban
		ENDIF 

		llTaTipDocInsAbierta=!USED("sistipodoctos")
		IF llTaTipDocInsAbierta
			USE pcsysdir+pcDB+"\sistipodoctos" IN 0 SHARED AGAIN ALIAS sistipodoctos ORDER idtipodoct
		ENDIF 

		***** KARDEX DE Cuentas por Cobrar o Pagar
		IF cyvcuentasxcp.ctrolcxcp<>0
			lniddocCOMIns=iddocto
			lnidTipDocCOMIns=idtipodocto
			IF SEEK(lnidTipDocCOMIns,'sistipodoctos','idtipodoct')
				lnConRefCOMIns=sistipodoctos.conreferencia
			ELSE
				lnConRefCOMIns=0
			ENDIF 
			TRY 
				IF SEEK(lniddocCOMIns,'takardoc','iddocto')
					UPDATE takardoc ; 
								SET idtipodocto=cyvcuentasxcp.idtipodocto,;
									idserie=cyvcuentasxcp.idserie,;
									idsucursal=cyvcuentasxcp.idsucursal,;
									idctrocosto=cyvcuentasxcp.idctrocosto,;
									numero=cyvcuentasxcp.numero,;
									fechadocto=cyvcuentasxcp.fechadocto,;
									fechavenci=cyvcuentasxcp.fechavenci,;
									idclipro=cyvcuentasxcp.idclipro,;
									idagente=cyvcuentasxcp.idagente,;
									turno=cyvcuentasxcp.turno,;
									totaldocto=cyvcuentasxcp.totaldocto,;
									rentadocto=cyvcuentasxcp.rentadocto,;
									conreferencia=lnConRefCOMIns,;
									periodo=cyvcuentasxcp.periodo,;
									origen=cyvcuentasxcp.origen,;
									ctrolcxcp=cyvcuentasxcp.ctrolcxcp,;
									status=cyvcuentasxcp.status,;
									eliminado=cyvcuentasxcp.eliminado,;
									fecalta=cyvcuentasxcp.fecalta,;
									fecmod=cyvcuentasxcp.fecmod,;
									fecactu=cyvcuentasxcp.fecactu,;
									condipago=1,;
									nodo=cyvcuentasxcp.nodo,;
									iduser=cyvcuentasxcp.iduser,;
									pcuser=cyvcuentasxcp.pcuser ; 
									WHERE iddocto=lniddocCOMIns
					lncuentacambios=_tally
				ELSE
					lntotalregistros=RECCOUNT('takardoc')
					INSERT INTO takardoc (iddocto,idtipodocto,idserie,idsucursal,idctrocosto,;
											numero,fechadocto,fechavenci,idclipro,idagente,totaldocto,condipago,;
											rentadocto,rentaabono,cargoabono,conreferencia,;
											turno,periodo,origen,ctrolcxcp,status,eliminado,fecalta,;
											fecmod,fecactu,nodo,iduser,pcuser);
							VALUES (cyvcuentasxcp.iddocto,cyvcuentasxcp.idtipodocto,cyvcuentasxcp.idserie,;
									cyvcuentasxcp.idsucursal,cyvcuentasxcp.idctrocosto,cyvcuentasxcp.numero,;
									cyvcuentasxcp.fechadocto,cyvcuentasxcp.fechavenci,cyvcuentasxcp.idclipro,cyvcuentasxcp.idagente,;
									cyvcuentasxcp.totaldocto,1,cyvcuentasxcp.rentadocto,0,0,lnConRefCOMIns,;
									cyvcuentasxcp.turno,cyvcuentasxcp.periodo,cyvcuentasxcp.origen,;
									cyvcuentasxcp.ctrolcxcp,cyvcuentasxcp.status,cyvcuentasxcp.eliminado,cyvcuentasxcp.fecalta,;
									cyvcuentasxcp.fecmod,cyvcuentasxcp.fecactu,cyvcuentasxcp.nodo,cyvcuentasxcp.iduser,cyvcuentasxcp.pcuser)
					lncuentacambios=RECCOUNT('takardoc')-lntotalregistros
				ENDIF 
				IF lncuentacambios=0
				
					lcidMensComIns="Error al Insertar Movimientos Bancarios"
					lcandCOMiNS=', '
					llOkMOVBcos=.f.
				ENDIF
			CATCH TO lEx 
				lcidMensComIns=lcidMensComIns+lcandCOMiNS+"Error " + TRANSFORM(lEx.Message)
				lcandCOMiNS=', '
				llOkMOVBcos=.f.
			FINALLY
				SELECT (lcidAliasComIns)
			ENDTRY			 	
		ENDIF 

		IF llTaCajBanInsAbierta
			USE IN tacajban
		ENDIF 

		IF lltakardocInsAbierta
			USE IN takardoc 
		ENDIF 
		IF llTaTipDocInsAbierta
			USE IN sistipodoctos
		ENDIF 
			
		SELECT (lcidAliasComIns)
	ENDIF 
	
	IF EMPTY(lcidMensComIns)
		RETURN .t.
	ELSE
		MESSAGEBOX(lcidMensComIns,16,'Error de Integridad... (_cuentascobrarpagar)',3000)
		RETURN .f.
	ENDIF 
ENDPROC 


PROCEDURE _insertinventariosdeta
	LOCAL lcidAliasInvIns,lcidMensInvIns,llTaKarInsAbierta,llTaKarInsAbiertaR
	LOCAL lnidInvDIns,ldidtipInvDIns,lnidserInvDInv,lcnumInvDIns,ldFecInvDIns
	LOCAL lchoraInvDIns,lnidclipInvDIns,lnTotdInvDIns,lcnotasInvdIns,lnIdIslaInvdIns
	LOCAL lnregainsertar,lcaliasporaqui,llNoExisteKardex,lncuentacambios

	STORE ALIAS() TO lcidAliasInvIns
	STORE '' TO lcidMensInvIns
	lncuentacambios = 0

	IF status = -1
		lcidMensInvIns = ""
	ELSE
		llTaKarInsAbierta = !USED("takarIns")
		IF llTaKarInsAbierta
			USE pcsysdir+pcDB+"\siskardex" IN 0 SHARED AGAIN ALIAS takarIns ORDER iddoctod
		ENDIF

		llTaKarInsAbiertaR = !USED("invinventarios")
		IF llTaKarInsAbiertaR
			USE pcsysdir+pcDB+"\invinventarios" IN 0 SHARED AGAIN ALIAS invinventarios ORDER iddocto
		ENDIF

		lnidInvDIns = invinventariosdeta.iddocto

		IF SEEK(lnidInvDIns,"invinventarios","iddocto")
			ldidtipInvDIns = invinventarios.idtipodocto
			lnidserInvDInv = invinventarios.idserie
			lcnumInvDIns = invinventarios.numero
			ldFecInvDIns = invinventarios.fechadocto
			lchoraInvDIns = invinventarios.horadocto
			lnidclipInvDIns = invinventarios.idclipro
			lnTotdInvDIns = invinventarios.totaldocto
			lcnotasInvdIns = invinventarios.notas
			lnIdIslaInvdIns = invinventarios.idisla
		ELSE
			ldidtipInvDIns = 0
			lnidserInvDInv = 0
			lcnumInvDIns = ''
			ldFecInvDIns = CTOD(' ')
			lchoraInvDIns = ''
			lnidclipInvDIns = 0
			lnTotdInvDIns = 0
			lcnotasInvdIns = ''
			lnIdIslaInvdIns = 0
		ENDIF

		IF ldidtipInvDIns <> 0
			TRY
				lnregainsertar = invinventariosdeta.iddoctod
				lcaliasporaqui = ALIAS()

				SELECT takarIns
				llNoExisteKardex = !SEEK(lnregainsertar,'takarIns','iddoctod')

				IF !EMPTY(lcaliasporaqui)
					SELECT (lcaliasporaqui)
				ENDIF

				IF llNoExisteKardex
					INSERT INTO takarIns (iddoctod,iddocto,idtipodocto,idserie,numero,fechadocto,horadocto,idclipro,totaldocto,;
											idproducto,unimed,cantidad,idproductoUniMed,cantiunimed,;
											factor,largo,ancho,area,desperdicio,;
											costounitario,costounimed,costototal,idbodega,idbodegatras,idctrocosto,;
											idkit,llavekit,llavelote,tipoprod,periodo,origen,;
											cantidadkit,cantidadserie,ctrolinv,notas,status,idisla,eliminado,;
											fecalta,fecmod,fecactu,nodo,iduser,pcuser);
						VALUES (invinventariosdeta.iddoctod,invinventariosdeta.iddocto,ldidtipInvDIns,lnidserInvDInv,;
								lcnumInvDIns,ldFecInvDIns,lchoraInvDIns,lnidclipInvDIns,lnTotdInvDIns,invinventariosdeta.idproducto,;
								invinventariosdeta.unimed,invinventariosdeta.cantidad,invinventariosdeta.idproductoUniMed,invinventariosdeta.cantiunimed,;
								invinventariosdeta.factor,invinventariosdeta.largo,invinventariosdeta.ancho,;
								invinventariosdeta.area,invinventariosdeta.desperdicio,;
								invinventariosdeta.costounitario,invinventariosdeta.costounimed,invinventariosdeta.costototal,;
								invinventariosdeta.idbodega,invinventariosdeta.idbodegatras,invinventariosdeta.idctrocosto,;
								invinventariosdeta.idkit,invinventariosdeta.llavekit,invinventariosdeta.llavelote,;
								invinventariosdeta.tipoprod,invinventariosdeta.periodo,invinventariosdeta.origen,;
								invinventariosdeta.cantidadkit,invinventariosdeta.cantidadserie,;
								invinventariosdeta.entsal,lcnotasInvdIns,invinventariosdeta.status,lnIdIslaInvdIns,invinventariosdeta.eliminado,;
								invinventariosdeta.fecalta,invinventariosdeta.fecmod,invinventariosdeta.fecactu,;
								invinventariosdeta.nodo,invinventariosdeta.iduser,invinventariosdeta.pcuser)
					lncuentacambios = 1
				ELSE
					UPDATE takarIns SET iddocto=invinventariosdeta.iddocto,;
										idtipodocto=ldidtipInvDIns,;
										idserie=lnidserInvDInv,;
										numero=lcnumInvDIns,;
										horadocto=lchoraInvDIns,;
										fechadocto=ldFecInvDIns,;
										idclipro=lnidclipInvDIns,;
										totaldocto=lnTotdInvDIns,;
										idproducto=invinventariosdeta.idproducto,;
										unimed=invinventariosdeta.unimed,;
										cantidad=invinventariosdeta.cantidad,;
										idproductoUniMed=invinventariosdeta.idproductoUniMed,;
										cantiunimed=invinventariosdeta.cantiunimed,;
										factor=invinventariosdeta.factor,;
										largo=invinventariosdeta.largo,;
										ancho=invinventariosdeta.ancho,;
										area=invinventariosdeta.area,;
										idisla=lnIdIslaInvdIns,;
										desperdicio=invinventariosdeta.desperdicio,;
										costounitario=invinventariosdeta.costounitario,;
										costounimed=invinventariosdeta.costounimed,;
										costototal=invinventariosdeta.costototal,;
										idbodega=invinventariosdeta.idbodega,;
										idbodegatras=invinventariosdeta.idbodegatras,;
										idctrocosto=invinventariosdeta.idctrocosto,;
										idkit=invinventariosdeta.idkit,;
										llavekit=invinventariosdeta.llavekit,;
										llavelote=invinventariosdeta.llavelote,;
										tipoprod=invinventariosdeta.tipoprod,;
										periodo=invinventariosdeta.periodo,;
										origen=invinventariosdeta.origen,;
										cantidadkit=invinventariosdeta.cantidadkit,;
										cantidadserie=invinventariosdeta.cantidadserie,;
										ctrolinv=invinventariosdeta.entsal,;
										notas=lcnotasInvdIns,;
										status=invinventariosdeta.status,;
										eliminado=invinventariosdeta.eliminado,;
										fecalta=invinventariosdeta.fecalta,;
										fecmod=invinventariosdeta.fecmod,;
										fecactu=invinventariosdeta.fecactu,;
										nodo=invinventariosdeta.nodo,;
										iduser=invinventariosdeta.iduser,;
										pcuser=invinventariosdeta.pcuser ;
									WHERE iddoctod=invinventariosdeta.iddoctod
					lncuentacambios = _TALLY
				ENDIF

				IF lncuentacambios = 0
					lcidMensInvIns = "Error al Insertar datos en el Kardex de productos"
				ENDIF

			CATCH TO lEx
				lcidMensInvIns = lcidMensInvIns + " Error " + TRANSFORM(lEx.Message)
			FINALLY
				IF !EMPTY(lcidAliasInvIns)
					SELECT (lcidAliasInvIns)
				ENDIF
			ENDTRY
		ELSE
			lcidMensInvIns = 'El tipo de Documento no puede ser 0 (cero)'
		ENDIF

		IF llTaKarInsAbierta
			USE IN takarIns
		ENDIF

		IF llTaKarInsAbiertaR
			USE IN invinventarios
		ENDIF

		IF !EMPTY(lcidAliasInvIns)
			SELECT (lcidAliasInvIns)
		ENDIF
	ENDIF

	IF EMPTY(lcidMensInvIns)
		RETURN .t.
	ELSE
		MESSAGEBOX(lcidMensInvIns,16,'Error de Integridad... (_insertinventariosdeta)',3000)
		RETURN .f.
	ENDIF
ENDPROC


PROCEDURE _updateinventariosdeta
	LOCAL lcidAliasInvEdi,lcidMensInvEdi,llTaKarEdiAbierta,llTaKarInsAbiertaR
	LOCAL lnidInvDEdi,ldidtipInvDEdi,lnidserInvDInv,lcnumInvDEdi,ldFecInvDEdi
	LOCAL lnidclipInvDEdi,lnTotdInvDEdi,lchoraInvDEdi,lcnotasInvdEdi,lnIdIslaInvdEdi
	LOCAL lnregabuscar,lcaliasporaqui,llNoExisteKardex,lncuentacambios,llretorok

	STORE ALIAS() TO lcidAliasInvEdi
	STORE '' TO lcidMensInvEdi
	llretorok = .t.
	lncuentacambios = 0

	IF (status=-1 AND CURVAL("status")=-1) AND ;
	   !(CURVAL("status")=-1 AND status=1) AND ;
	   !(CURVAL("status")=1 AND status=0)

		llretorok = .t.
	ELSE
		llTaKarEdiAbierta = !USED("takarEdi")
		IF llTaKarEdiAbierta
			USE pcsysdir+pcDB+"\siskardex" IN 0 SHARED AGAIN ALIAS takarEdi ORDER iddoctod
		ENDIF

		llTaKarInsAbiertaR = !USED("invinventarios")
		IF llTaKarInsAbiertaR
			USE pcsysdir+pcDB+"\invinventarios" IN 0 SHARED AGAIN ALIAS invinventarios ORDER iddocto
		ENDIF

		lnidInvDEdi = invinventariosdeta.iddocto

		IF SEEK(lnidInvDEdi,"invinventarios","iddocto")
			ldidtipInvDEdi = invinventarios.idtipodocto
			lnidserInvDInv = invinventarios.idserie
			lcnumInvDEdi = invinventarios.numero
			ldFecInvDEdi = invinventarios.fechadocto
			lnidclipInvDEdi = invinventarios.idclipro
			lnTotdInvDEdi = invinventarios.totaldocto
			lchoraInvDEdi = invinventarios.horadocto
			lcnotasInvdEdi = invinventarios.notas
			lnIdIslaInvdEdi = invinventarios.idisla
		ELSE
			ldidtipInvDEdi = 0
			lnidserInvDInv = 0
			lcnumInvDEdi = ''
			ldFecInvDEdi = CTOD(' ')
			lnidclipInvDEdi = 0
			lnTotdInvDEdi = 0
			lchoraInvDEdi = ''
			lcnotasInvdEdi = ''
			lnIdIslaInvdEdi = 0
		ENDIF

		IF ldidtipInvDEdi <> 0
			TRY
				lnregabuscar = invinventariosdeta.iddoctod
				lcaliasporaqui = ALIAS()

				SELECT takarEdi
				llNoExisteKardex = !SEEK(lnregabuscar,'takarEdi','iddoctod')

				IF !EMPTY(lcaliasporaqui)
					SELECT (lcaliasporaqui)
				ENDIF

				IF llNoExisteKardex
					INSERT INTO takarEdi (iddoctod,iddocto,idtipodocto,idserie,numero,fechadocto,horadocto,idclipro,totaldocto,;
											idproducto,unimed,cantidad,idproductoUniMed,cantiunimed,;
											factor,largo,ancho,area,desperdicio,;
											costounitario,costounimed,costototal,idbodega,idbodegatras,idctrocosto,;
											idkit,llavekit,llavelote,tipoprod,periodo,origen,;
											cantidadkit,cantidadserie,ctrolinv,notas,status,idisla,eliminado,;
											fecalta,fecmod,fecactu,nodo,iduser,pcuser);
						VALUES (invinventariosdeta.iddoctod,invinventariosdeta.iddocto,ldidtipInvDEdi,lnidserInvDInv,;
								lcnumInvDEdi,ldFecInvDEdi,lchoraInvDEdi,lnidclipInvDEdi,lnTotdInvDEdi,invinventariosdeta.idproducto,;
								invinventariosdeta.unimed,invinventariosdeta.cantidad,invinventariosdeta.idproductoUniMed,invinventariosdeta.cantiunimed,;
								invinventariosdeta.factor,invinventariosdeta.largo,invinventariosdeta.ancho,;
								invinventariosdeta.area,invinventariosdeta.desperdicio,;
								invinventariosdeta.costounitario,invinventariosdeta.costounimed,invinventariosdeta.costototal,;
								invinventariosdeta.idbodega,invinventariosdeta.idbodegatras,invinventariosdeta.idctrocosto,;
								invinventariosdeta.idkit,invinventariosdeta.llavekit,invinventariosdeta.llavelote,;
								invinventariosdeta.tipoprod,invinventariosdeta.periodo,invinventariosdeta.origen,;
								invinventariosdeta.cantidadkit,invinventariosdeta.cantidadserie,;
								invinventariosdeta.entsal,lcnotasInvdEdi,invinventariosdeta.status,lnIdIslaInvdEdi,invinventariosdeta.eliminado,;
								invinventariosdeta.fecalta,invinventariosdeta.fecmod,invinventariosdeta.fecactu,;
								invinventariosdeta.nodo,invinventariosdeta.iduser,invinventariosdeta.pcuser)
					lncuentacambios = 1
				ELSE
					UPDATE takarEdi SET iddocto=invinventariosdeta.iddocto,;
										idtipodocto=ldidtipInvDEdi,;
										idserie=lnidserInvDInv,;
										numero=lcnumInvDEdi,;
										horadocto=lchoraInvDEdi,;
										fechadocto=ldFecInvDEdi,;
										idclipro=lnidclipInvDEdi,;
										totaldocto=lnTotdInvDEdi,;
										idproducto=invinventariosdeta.idproducto,;
										unimed=invinventariosdeta.unimed,;
										cantidad=invinventariosdeta.cantidad,;
										idproductoUniMed=invinventariosdeta.idproductoUniMed,;
										cantiunimed=invinventariosdeta.cantiunimed,;
										factor=invinventariosdeta.factor,;
										largo=invinventariosdeta.largo,;
										ancho=invinventariosdeta.ancho,;
										area=invinventariosdeta.area,;
										desperdicio=invinventariosdeta.desperdicio,;
										costounitario=invinventariosdeta.costounitario,;
										costounimed=invinventariosdeta.costounimed,;
										costototal=invinventariosdeta.costototal,;
										idbodega=invinventariosdeta.idbodega,;
										idbodegatras=invinventariosdeta.idbodegatras,;
										idctrocosto=invinventariosdeta.idctrocosto,;
										idkit=invinventariosdeta.idkit,;
										llavekit=invinventariosdeta.llavekit,;
										llavelote=invinventariosdeta.llavelote,;
										tipoprod=invinventariosdeta.tipoprod,;
										periodo=invinventariosdeta.periodo,;
										origen=invinventariosdeta.origen,;
										idisla=lnIdIslaInvdEdi,;
										cantidadkit=invinventariosdeta.cantidadkit,;
										cantidadserie=invinventariosdeta.cantidadserie,;
										ctrolinv=invinventariosdeta.entsal,;
										notas=lcnotasInvdEdi,;
										status=invinventariosdeta.status,;
										eliminado=invinventariosdeta.eliminado,;
										fecalta=invinventariosdeta.fecalta,;
										fecmod=invinventariosdeta.fecmod,;
										fecactu=invinventariosdeta.fecactu,;
										nodo=invinventariosdeta.nodo,;
										iduser=invinventariosdeta.iduser,;
										pcuser=invinventariosdeta.pcuser ;
									WHERE iddoctod=invinventariosdeta.iddoctod
					lncuentacambios = _TALLY
				ENDIF

				IF lncuentacambios = 0
					lcidMensInvEdi = "Error al Editar datos en el Kardex de productos"
				ENDIF

			CATCH TO lEx
				lcidMensInvEdi = lcidMensInvEdi + " Error " + TRANSFORM(lEx.Message)
				llretorok = .f.
			FINALLY
				IF !EMPTY(lcidAliasInvEdi)
					SELECT (lcidAliasInvEdi)
				ENDIF
			ENDTRY
		ELSE
			lcidMensInvEdi = 'El tipo de Documento no puede ser 0 (cero)'
		ENDIF

		IF llTaKarEdiAbierta
			USE IN takarEdi
		ENDIF

		IF llTaKarInsAbiertaR
			USE IN invinventarios
		ENDIF

		IF !EMPTY(lcidAliasInvEdi)
			SELECT (lcidAliasInvEdi)
		ENDIF

		IF !EMPTY(lcidMensInvEdi)
			MESSAGEBOX(lcidMensInvEdi,16,'Error de Integridad... (_updateinventariosdeta)',3000)
			llretorok = .f.
		ENDIF
	ENDIF

	RETURN llretorok
ENDPROC




************************
************************
************************
****** partidas

PROCEDURE _insertpartidasdeta
	RETURN .t.
	*****************************
	********** este proceso ya no se hara...
	
	LOCAL lnIdPartiDeta,lnIdPartida,lnIdctaii,lnnivctaii,;
	lciidAlias,lciidMensaje,lcpadresii,lnmontoii,lcTablaSalii
	
	STORE ALIAS() TO lciidAlias
	STORE '' TO lciidMensaje
	
	lcTablaSalii=!USED("saldospar")
	IF lcTablaSalii
		USE pcsysdir+pcDB+"\ctbsaldos" IN 0 SHARED AGAIN ALIAS saldosPar ORDER llave2
	ENDIF 
	
	lcTablaSalii22=!USED("iicta2")
	IF lcTablaSalii22
		USE pcsysdir+pcDB+"\ctbcuentas" IN 0 SHARED AGAIN ALIAS iicta2 ORDER idcuenta
	ENDIF 
	
	lcTablaSalii33=!USED("iicta3")
	IF lcTablaSalii33
		*USE pcsysdir+pcDB+"\ctbcuentaspadre" IN 0 SHARED AGAIN ALIAS iicta3 ORDER idcuenta
		_CtasPadre (0,'','iicta3')
	ENDIF 
	
	STORE idpartidad TO lnIdPartiDeta
	STORE idpartida TO lnIdPartida
	STORE periodo TO lcperii
	STORE idcuenta TO lnIdctaii
	STORE haber TO lnhabii
	STORE debe TO lndebii
	STORE fecmod TO ltfecmodii
	
	SELECT * FROM (;
	SELECT t0.idcuenta,lndebii as debe,lnhabii as haber,t0.codcta ;
		FROM iicta2 t0 ;
			INNER JOIN iicta3 t1 ON t0.idcuenta=t1.idcuentarelacion ;
			WHERE t1.idcuenta=lnIdctaii) c_t9 ;
	INTO CURSOR c_t9 READWRITE 

	SELECT c_t9
	SCAN all
		STORE idcuenta TO lnIdctaii
		STORE haber TO lnhabii
		STORE debe TO lndebii
		STORE ALLTRIM(codcta) TO lccodctaii
		IF pcnodo='11'
			IF SEEK(STR(lnIdctaii)+lcperii,'saldosPar','llave2')			&&&& Actualizando Existencia del Producto
				REPLACE saldosPar.debe WITH saldosPar.debe + lndebii,saldosPar.haber WITH saldosPar.haber+lnhabii ;
					FOR saldosPar.idcuenta=lnidctaii AND saldosPar.periodo=lcperii IN saldosPar
				IF _tally=0
					lciidMensaje="La cuenta "+lccodctaii+" no pudo mayorisarse !"
				ENDIF 
			ELSE
				lnidnewIdSalii=_SiguienteIdTabla(pcNodo,"SIS")
				lncuentarecno=RECCOUNT("saldosPar")
				INSERT INTO saldosPar (idsaldo,idcuenta,periodo,debe,haber,presupuesto,fecalta,fecmod,nodo) VALUES ;
					(lnidnewIdSalii,lnidctaii,lcperii,lndebii,lnhabii,0,ltfecmodii,ltfecmodii,pcnodo) 
				lncuentarecno=RECCOUNT("saldosPar")-lncuentarecno
				IF lncuentarecno=0
					lciidMensaje="La cuenta "+lccodctaii+" no pudo mayorisarse !"
				ENDIF 
			ENDIF 
		ENDIF 
	ENDSCAN 
	
	USE IN c_t9

	IF lcTablaSalii
		USE IN saldosPar
	ENDIF 
	
	IF lcTablaSalii22
		USE IN iicta2
	ENDIF 
	
	IF lcTablaSalii33
		USE IN iicta3 
	ENDIF 
	
	SELECT (lciidAlias)
	
	IF EMPTY(lciidMensaje)
		RETURN .t.
	ELSE
		MESSAGEBOX(lciidMensaje,16,'Error de Integridad... (_insertpartidasdeta)',3000)
		RETURN .f.
	ENDIF 
ENDPROC 


************************
PROCEDURE _Updatepartidasdeta
	RETURN .t.
	*****************************
	********** este proceso ya no se hara...
	
	LOCAL lnIdPartiDeta,lnIdPartida,lnIdctaiiUP,lnnivctaiiUP,;
	lciiUPdAlias,lciiUPdMensaje,lcpadresiiUP,lnmontoiiUP,lcTablaSaliiUP
		
	STORE ALIAS() TO lciiUPdAlias
	STORE '' TO lciiUPdMensaje

	lcTablaSaliiUP=!USED("saldospar")
	IF lcTablaSaliiUP
		USE pcsysdir+pcDB+"\ctbsaldos" IN 0 SHARED AGAIN ALIAS saldosPar ORDER llave2
	ENDIF 
	lcTablaSaliiUP22=!USED("iiUPcta2")
	IF lcTablaSaliiUP22
		USE pcsysdir+pcDB+"\ctbcuentas" IN 0 SHARED AGAIN ALIAS iiUPcta2 ORDER idcuenta
	ENDIF 
	lcTablaSaliiUP33=!USED("iiUPcta3")
	IF lcTablaSaliiUP33
		*USE pcsysdir+pcDB+"\ctbcuentaspadre" IN 0 SHARED AGAIN ALIAS iiUPcta3 ORDER idcuenta
		_CtasPadre (0,'','iiUPcta3')
	ENDIF 
	STORE idpartidad TO lnIdPartiDeta
	STORE idpartida TO lnIdPartida
	STORE periodo TO lcperiiUP
	STORE idcuenta TO lnIdctaiiUP
	STORE haber TO lnhabiiUP
	STORE debe TO lndebiiUP
	STORE CURVAL("haber") TO lnhabiiUPold
	STORE CURVAL("debe") TO lndebiiUPold
	IF CURVAL("idcuenta")<>idcuenta
		lciiUPdMensaje="La Cuenta no puede Modificarse...!"
	ENDIF  

	IF lnhabiiUP<>lnhabiiUPold OR lndebiiUP<>lndebiiUPold		&&& se poste solo si hay cambios en el debe o el haber
		IF EMPTY(lciiUPdMensaje)
			SELECT * FROM (;
				SELECT t0.idcuenta,lndebiiUP-lndebiiUPold as debe,lnhabiiUP-lnhabiiUPold as haber,t0.codcta ;
					FROM iiUPcta2 t0 ;
						INNER JOIN iiUPcta3 t1 ON t0.idcuenta=t1.idcuentarelacion ;
						WHERE t1.idcuenta=lnIdctaiiUP) c_t9 ;
				INTO CURSOR c_t9 READWRITE 

			SELECT c_t9
			SCAN all
				STORE idcuenta TO lnIdctaiiUP
				STORE haber TO lnhabiiUP
				STORE debe TO lndebiiUP
				STORE ALLTRIM(codcta) TO lccodctaiiUP
				IF pcnodo='11'
					IF SEEK(STR(lnIdctaiiUP)+lcperiiUP,'saldosPar','llave2')			&&&& Actualizando Existencia del Producto
						REPLACE saldosPar.debe WITH saldosPar.debe + lndebiiUP,saldosPar.haber WITH saldosPar.haber+lnhabiiUP ;
							FOR saldosPar.idcuenta=lnidctaiiUP AND saldosPar.periodo=lcperiiUP IN saldosPar
						IF _tally=0
							lciiUPdMensaje="La cuenta "+lccodctaiiUP+" no pudo mayorisarse !"
						ENDIF 
					ELSE
						lnidnewIdSaliiUP=_SiguienteIdTabla(pcNodo,"SIS")
						INSERT INTO saldosPar (idsaldo,idcuenta,periodo,debe,haber,presupuesto) VALUES ;
							(lnidnewIdSaliiUP,lnidctaiiUP,lcperiiUP,lndebiiUP,lnhabiiUP,0) 
						IF _tally=0
							lciiUPdMensaje="La cuenta "+lccodctaiiUP+" no pudo mayorisarse !"
						ENDIF 
					ENDIF 
				ENDIF 
			ENDSCAN 
			USE IN c_t9
		ENDIF 
	ENDIF 
				
	IF lcTablaSaliiUP
		USE IN saldosPar
	ENDIF 
	IF lcTablaSaliiUP22
		USE in iiUPcta2
	ENDIF 
	IF lcTablaSaliiUP33
		USE IN iiUPcta3
	ENDIF 
	
	SELECT (lciiUPdAlias)
	
	IF EMPTY(lciiUPdMensaje)
		RETURN .t.
	ELSE
		MESSAGEBOX(lciiUPdMensaje,16,'Error de Integridad... (_Updatepartidasdeta)',3000)
		RETURN .f.
	ENDIF 
ENDPROC 


************************
PROCEDURE _Deletepartidasdeta
	RETURN .t.
	*****************************
	********** este proceso ya no se hara...
	
	LOCAL lnIdPartiDeta,lnIdPartida,lnIdctaiiDP,lnnivctaiiDP,;
	lciiDPdAlias,lciiDPdMensaje,lcpadresiiDP,lnmontoiiDP,lcTablaSaliiDP
		
	STORE ALIAS() TO lciiDPdAlias
	STORE '' TO lciiDPdMensaje

	lcTablaSaliiDP=!USED("saldospar")
	IF lcTablaSaliiDP
		USE pcsysdir+pcDB+"\ctbsaldos" IN 0 SHARED AGAIN ALIAS saldosPar ORDER llave2
	ENDIF 
	
	lcTablaSalii22=!USED("iiDPcta2")
	IF lcTablaSalii22
		USE pcsysdir+pcDB+"\ctbcuentas" IN 0 SHARED AGAIN ALIAS iiDPcta2 ORDER idcuenta
	ENDIF 
	
	lcTablaSalii33=!USED("iiDPcta3")
	IF lcTablaSalii33
		*USE pcsysdir+pcDB+"\ctbcuentaspadre" IN 0 SHARED AGAIN ALIAS iiDPcta3 ORDER idcuenta
		_CtasPadre (0,'','iiDPcta3')
	ENDIF 

	STORE idpartidad TO lnIdPartiDeta
	STORE idpartida TO lnIdPartida
	STORE periodo TO lcperiiDP
	STORE idcuenta TO lnIdctaiiDP
	STORE CURVAL("haber") TO lnhabiiDPold
	STORE CURVAL("debe") TO lndebiiDPold
	IF CURVAL("idcuenta")<>idcuenta
		lciiDPdMensaje="La Cuenta no puede Modificarse...!"
	ENDIF  
	IF EMPTY(lciiDPdMensaje)
	SELECT * FROM (;
		SELECT t0.idcuenta,lndebiiDPold as debe,lnhabiiDPold as haber,t0.codcta ;
			FROM iiDPcta2 t0 ;
				INNER JOIN iiDPcta3 t1 ON t0.idcuenta=t1.idcuentarelacion ;
				WHERE t1.idcuenta=lnIdctaiiDP) c_t9 ;
		INTO CURSOR c_t9 READWRITE

		SELECT c_t9
		SCAN all
			STORE idcuenta TO lnIdctaiiDP
			STORE haber TO lnhabiiDP
			STORE debe TO lndebiiDP
			STORE ALLTRIM(codcta) TO lccodctaiiDP
			
			IF pcnodo='11'
				IF SEEK(STR(lnIdctaiiDP)+lcperiiDP,'saldosPar','llave2')			&&&& Actualizando Existencia del Producto
					REPLACE saldosPar.debe WITH saldosPar.debe - lndebiiDP,saldosPar.haber WITH saldosPar.haber-lnhabiiDP ;
						FOR saldosPar.idcuenta=lnidctaiiDP AND saldosPar.periodo=lcperiiDP IN saldosPar
					IF _tally=0
						lciiDPdMensaje="La cuenta "+lccodctaiiDP+" no pudo Eliminarse !"
					ENDIF 
				ELSE
					lciiDPdMensaje="La cuenta "+lccodctaiiDP+" no pudo Eliminarse !"
				ENDIF 
			ENDIF 
		ENDSCAN 
		USE IN c_t9
	ENDIF 
			
	IF lcTablaSalii22
		USE IN iiDPcta2
	ENDIF 
	
	IF lcTablaSaliiDP
		USE IN saldosPar
	ENDIF 
	
	IF lcTablaSalii33
		USE IN iiDPcta3 
	ENDIF
	
	SELECT (lciiDPdAlias)
	
	IF EMPTY(lciiDPdMensaje)
		RETURN .t.
	ELSE
		MESSAGEBOX(lciiDPdMensaje,16,'Error de Integridad... (_Deletepartidasdeta)',3000)
		RETURN .f.
	ENDIF 
ENDPROC 


*************************************
FUNCTION _insertcuentaspadre()
	IF pnSincronizandoTablas=.t.
		RETURN .t.  &&& si se esta insertando cuentas desde la sincronizacion, no se hace nada
	ELSE 
		lcTablaCuentas=ALIAS()
		SELECT (lcTablaCuentas)
		IF detalle=1
			USE pcsysdir+pcDB+"\ctbCuentas" SHARED AGAIN ORDER idcuenta IN 0 ALIAS c_cc

			LOCAL lni,lnidcta,lnniv,lnidpa,lnidpanew,lcnod,lneli,lnsta,ldfecal,ldfecmod,lnidus,lcpcus
			lni=1
			lnidcta=idcuenta
			lnniv=nivel
			lnidpa=idcuenta
			lnidpanew=idpadre
			lcnod=nodo
			lneli=eliminado
			lnsta=status
			ldfecal=fecalta
			ldfecmod=fecmod
			lnidus=iduser
			lcpcus=pcuser
			
			SELECT c_cc 
			FOR i=lnniv TO 1 STEP -1
				lniddd=_SiguienteIdTabla(pcNodo,"SIS")
				insert into ctbcuentaspadre (idcuentapadre,idcuenta,nivel,idcuentarelacion,nodo,eliminado,status,fecalta,fecmod,iduser,pcuser) ;
					values (lniddd,lnidcta,i,lnidpa,lcnod,lneli,lnsta,ldfecal,ldfecmod,lnidus,lcpcus)

				select top 1 * from ctbcuentas where idcuenta=lnidpanew and nivel=i-1 order by idcuenta INTO CURSOR cc_padre READWRITE 
				lnidpa=cc_padre.idcuenta
				lnidpanew=cc_padre.idpadre
				USE IN cc_padre
				
				SELECT c_cc 
			ENDFOR 
			USE IN c_cc
		ENDIF 
		RETURN .t.
	ENDIF 
ENDFUNC 




FUNCTION InsertarCampoRequeridodelFormulario(lcFormulario,lcCampoRequerido,lnDefinirRequerido)
	lcFormulario=PADR(STRTRAN(UPPER(ALLTRIM(lcFormulario)),"FRM_",""),50," ")
	lcCampoRequerido=PADR(UPPER(ALLTRIM(lcCampoRequerido)),50," ")
	lnConcc=_conecta(pcDB)
	lcAliasCamposReque=ALIAS()
	IF lnConcc<>0
		ldfechamodreque=DATETIME()
		IF pnTipoConeccion=1		&&& nativo
			USE pcsysdir+pcDB+"\sisRequeridos" IN 0 ALIAS c_req SHARED AGAIN  ORDER llave
			IF SEEK(lcFormulario+lcCampoRequerido,"c_req")
				REPLACE formulario WITH lcFormulario, campo WITH lcCampoRequerido,requerido WITH lnDefinirRequerido,;
						nodo WITH pcnodo,fecmod WITH ldfechamodreque, iduser WITH pnidusuario,pcuser WITH SYS(0) NEXT 1 IN c_req
			ELSE
				lnidnewidRequeridos=_SiguienteIdTabla(pcNodo,"SIS")
				INSERT INTO c_req (idrequerido,formulario,campo,requerido,fecalta,fecmod,nodo,iduser,pcuser) ;
					VALUES (lnidnewidRequeridos,lcFormulario,lcCampoRequerido,lnDefinirRequerido,ldfechamodreque,ldfechamodreque,;
							pcnodo,pnIdUsuario,SYS(0))
			ENDIF 
			USE IN c_req
		ELSE
			lcComandoGrabar=;
				"UPDATE sisRequeridos "+;
					"set formulario='"+ALLTRIM(lcFormulario)+"',"+;
						"campo='"+ALLTRIM(lcCampoRequerido)+"',"+;
						"requerido="+ALLTRIM(STR(lnDefinirRequerido))+","+;
						"fecmod'"+_ConvertirToFechaHoraSQL(ldfechamodreque)+"',"+;
						"nodo='"+ALLTRIM(pcnodo)+"',"+;
						"iduser="+ALLTRIM(STR(pnidusuario))+","+;
						"pcuser='"+ALLTRIM(SYS(0))+"' "+;
					"WHERE formulario='"+ALLTRIM(lcFormulario)+"' and "+;
						"campo='"+ALLTRIM(lcCampoRequerido)+"' "
								
			lnCtrlSql=miSQLEXEC(lnIdSqlGrabar,lcComandoGrabar,"")
			IF lnCtrlSql=<0
				lnidnewidRequeridos=_SiguienteIdTabla(pcNodo,"SIS")
				lcComandoGrabar=;
					"INSERT INTO sisRequeridos (idrequerido,formulario,campo,requerido,fecalta,fecmod,nodo,iduser,pcuser) "+;
						"VALUES ("+ALLTRIM(STR(lnidnewidRequeridos))+","+;
								"'"+ALLTRIM(lcFormulario)+"',"+;
								"'"+ALLTRIM(lcCampoRequerido)+"',"+;
								""+ALLTRIM(STR(lnDefinirRequerido))+","+;
								"'"+_ConvertirToFechaHoraSQL(ldfechamodreque)+"',"+;
								"'"+_ConvertirToFechaHoraSQL(ldfechamodreque)+"',"+;
								"'"+ALLTRIM(pcnodo)+"',"+;
								""+ALLTRIM(STR(pnidusuario))+","+;
								"'"+ALLTRIM(SYS(0))+"')"
					
			ENDIF 
		ENDIF 
		=miSQLDISCONNECT(lnConcc)
	ENDIF 
	IF !EMPTY(lcAliasCamposReque)
		SELECT (lcAliasCamposReque)
	ENDIF 
	RETURN .t.
ENDFUNC 




FUNCTION ObtenerCamposRequeridodelFormulario(lcFormulario)
	lcFormulario=PADR(STRTRAN(UPPER(ALLTRIM(lcFormulario)),"FRM_",""),50," ")
	lcCampoRequerido=""
	lnConcc=_conecta(pcDB)
	lcAliasCamposReque=ALIAS()
	IF lnConcc<>0
		IF pnTipoConeccion=1		&&& nativo
			USE pcsysdir+pcDB+"\sisRequeridos" IN 0 ALIAS c_req SHARED AGAIN  ORDER llave
			SELECT campo FROM c_req WHERE formulario=lcFormulario+" " AND requerido=1 INTO CURSOR c_requeridostmp
			lcunionrequ=""
			SELECT c_requeridostmp
			IF !EOF()
				SCAN 
					lcCampoRequerido=lcCampoRequerido+lcunionrequ+ALLTRIM(campo)
					lcunionrequ=","
				ENDSCAN 
			ENDIF 
			USE IN c_requeridostmp
			USE IN c_req
		ELSE
			lcComandoGrabar=;
				"SELECT campo FROM sisrequeridos WHERE formulario='"+lcFormulario+" ' AND requerido=1"
								
			lnCtrlSql=miSQLEXEC(lnConcc,lcComandoGrabar,"c_requeridostmp")
			IF lnCtrlSql=<0
				lcunionrequ=""
				SELECT c_requeridostmp
				IF !EOF()
					SCAN 
						lcCampoRequerido=lcCampoRequerido+lcunionrequ+ALLTRIM(campo)
						lcunionrequ=","
					ENDSCAN 
				ENDIF 
				USE IN c_requeridostmp
			ENDIF 
		ENDIF 
		=miSQLDISCONNECT(lnConcc)
	ENDIF 
	IF !EMPTY(lcAliasCamposReque)
		SELECT (lcAliasCamposReque)
	ENDIF 
	RETURN lcCampoRequerido
ENDFUNC 


FUNCTION _obtenerFechaHoraUltimaActualizacion(lnidConOUA,lcTablaOUA)
	lcAliasOUA=ALIAS()
	ltFecUltHoraAServRetorna=DATETIME()-(60*60*1)
	lcComandoOUA="SELECT fecultactu FROM sisloguactu WHERE tabla=='"+ALLTRIM(UPPER(lcTablaOUA))+" '"
	lnCtrlSqlOUA=miSQLEXEC(lnidConOUA,lcComandoOUA,"c_fechaHoraUltima")
	IF lnCtrlSqlOUA>0
		IF TYPE("c_fechaHoraUltima.fecultactu")="T"
			ltFecUltHoraAServRetorna=c_fechaHoraUltima.fecultactu-(60*60*1)
		ELSE
			ltFecUltHoraAServRetorna=CTOT(c_fechaHoraUltima.fecultactu)-(60*60*1)
		ENDIF 

		IF CTOT(" ")=ltFecUltHoraAServRetorna
			ltFecUltHoraAServRetorna=(DATETIME()-(13*60*60*1))
		ENDIF

		USE IN c_fechaHoraUltima
	ENDIF 
	IF !EMPTY(lcAliasOUA)
		SELECT (lcAliasOUA)
	ENDIF 
	RETURN ltFecUltHoraAServRetorna
ENDFUNC 



FUNCTION SubirRegistrosConta(lnTipoconeccion,lcDriverOdbcRemoto,lcServerRemoto,lcRootRemoto,lcDBRemoto,lcPuertoRemoto,lcClaveRemoto,lcTablaActualizar)
	lnCantRegActu=0
	STORE 0 TO lnCtrlSql01,lnCtrlSql02,lnCtrlSql03
	lnTransaccionIniciada=0
	oResActuRem= CREATEOBJECT( "respuesta" )
	lnCtrlConec01=_conectaRemoto(lcDBRemoto,lnTipoconeccion,lcDriverOdbcRemoto,lcServerRemoto,lcRootRemoto,lcClaveRemoto,lcPuertoRemoto)
	lcMensajeActuaRemota=""
	IF lnCtrlConec01>0
		ltFechaHoraActualizacion=FechaHoraServerMySQL(lnCtrlConec01)
	ELSE
		ltFechaHoraActualizacion=dateTIME()
	ENDIF 
	lcTiempoActu=STRTRAN(TIME(),":","")		&&& como no puedo conectar al server verifica la hora local
	lnTiempoIni=dateTIME()
	oResActuRem.fechahora=lnTiempoIni
	
	IF lnCtrlConec01>0
		lcAliasActutmp=ALIAS()
	*	SELECT (lcTablaActualizar)
		****** Coneccion remota
		DO case
			CASE lcTablaActualizar=="ctbcuentas"
				lnCtrlConec02=_conecta(pcDB)

				lcComando02="SELECT * FROM "+lcTablaActualizar+" WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
				lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"c_cur_"+lcTablaActualizar+lcTiempoActu)

				IF lnCtrlSql02>0 &&& hay registro a actualizar y ya se conecto al sever remoto
					lnCantRegActu=_tally

					IF lnCantRegActu>0	&&&& no hay registros a actualizar
						***** iniciando transaccion y buffering
						IF pnTipoConeccion=1	&&& usando coneccion Nativa local
							SELECT (lcTablaActualizar)
							CURSORSETPROP("Buffering",5,lcTablaActualizar)
						ENDIF 
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'BEGIN')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'BEGIN','',lnTipoconeccion)
						lnTransaccionIniciada=1
						
						**************************************************************************************************************
						***** le cambiomos la fecha de actualizacion a los registros locales para evitar que alguien mas los modifique
						IF pnTipoConeccion=1
							lcComando03=;
									"UPDATE "+lcTablaActualizar+" "+;
										"set fecactu=CTOT('"+TTOC(ltFechaHoraActualizacion)+"') "+;
										"WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
						ELSE 
							lcComando03=;
									"UPDATE "+lcTablaActualizar+" "+;
										"set fecactu='"+_ConvertirToFechaHoraSQL(ltFechaHoraActualizacion)+"' "+;
										"WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
						ENDIF 
						**** cambiando fecha a registros locales
						lnCtrlSql03=miSQLEXEC(lnCtrlConec02,lcComando03,"")
					
						**************************************************************************************************************
						****** enviamos los registros locales al remoto
						lcComando01=;
									"INSERT INTO "+lcTablaActualizar+" (idcuenta,codcta,cuenta,idtipocuenta,nivel,naturaleza,detalle,idpadre,eliminado,status,fecalta,fecmod,fecactu,nodo,iduser,pcuser) "+;
										"VALUES "
									lcComaUnion=""
									SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
									SCAN FOR idcuenta<>0 AND nodo=pcnodo	
										lcComando01=lcComando01+lcComaUnion;
											+"("+ALLTRIM(STR(idcuenta))+","+;
											"'"+ALLTRIM(codcta)+"',"+;
											"'"+ALLTRIM(_sincomillias(cuenta))+"',"+;
											""+ALLTRIM(STR(idtipocuenta))+","+;
											""+ALLTRIM(STR(nivel))+","+;
											""+ALLTRIM(STR(naturaleza))+","+;
											""+ALLTRIM(STR(detalle))+","+;
											""+ALLTRIM(STR(idpadre))+","+;
											""+ALLTRIM(STR(eliminado))+","+;
											""+ALLTRIM(STR(status))+","+;
											"'"+_ConvertirToFechaHoraSQL(fecalta)+"',"+;
											"'"+_ConvertirToFechaHoraSQL(fecmod)+"',"+;
											"'"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"',"+;
											"'"+ALLTRIM(nodo)+"',"+;
											""+ALLTRIM(STR(iduser))+","+;
											"'"+ALLTRIM(pcuser)+"' "+;
											")"
										lcComaUnion=","
									ENDSCAN 
										lcComando01=lcComando01+" ON DUPLICATE KEY UPDATE "+;
											"codcta = VALUES(codcta),"+;
											"cuenta = VALUES(cuenta),"+;
											"idtipocuenta = VALUES(idtipocuenta),"+;
											"nivel = VALUES(nivel),"+;
											"naturaleza = VALUES(naturaleza),"+;
											"detalle = VALUES(detalle),"+;
											"idpadre = VALUES(idpadre),"+;
											"eliminado = VALUES(eliminado),"+;
											"status = VALUES(status),"+;
											"fecalta = VALUES(fecalta),"+;
											"fecmod = VALUES(fecmod),"+;
											"fecactu= VALUES(fecactu),"+;
											"nodo = VALUES(nodo),"+;
											"iduser = VALUES(iduser),"+;
											"pcuser = VALUES(pcuser)"
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,lcComando01,"c_Cur_Remoto"+lcTablaActualizar,lnTipoconeccion)


						IF lnCtrlSql01<1
							oResActuRem.mensaje="Error al Actualizar los Registros en el Servidor Remoto"
							oResActuRem.iderror=1
						ENDIF 
					ELSE
						***** se cambian los controles de los comandos sql ejecutados a todos correctos por que no hay error... simplemente no hay registros
						lnCtrlSql01=1	
						lnCtrlSql02=1
						lnCtrlSql03=1
						oResActuRem.mensaje="No hay Registros para Subir en "+UPPER(lcTablaActualizar)
						oResActuRem.iderror=0
					ENDIF 
				ELSE
					AERROR(laMisErrores)
					oResActuRem.iderror=1
					oResActuRem.mensaje="Error en la Coneccion Local: "+laMisErrores(2)
				ENDIF 	

				********** aqui confirmamos los datos locales si se ejecuto todo bien y si hay registros a actualizar
				IF lnCtrlSql01>0 AND lnCtrlSql02>0 AND lnCtrlSql03>0 AND lnCantRegActu>0
					******* confirmando datos locales
					IF pnTipoConeccion=1	&&& usando coneccion Nativa datos locales
						llRet=TABLEUPDATE(1,.t.,lcTablaActualizar)
					ENDIF 
				ELSE
					IF lnCtrlSql03=<1 AND lnCantRegActu>0
						AERROR(laMisErrores)
						oResActuRem.mensaje="No fue Posible Cambiar la Fecha de Actualizacion en los Registros Locales: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF
					llRet=.f.
				ENDIF 

				**** aqui confirmamos los datos ya sea sql o nativo
				IF lnTransaccionIniciada=1
					IF llRet
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'COMMIT')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'COMMIT','',lnTipoconeccion)
						
						oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Registros Actualizados de "+UPPER(lcTablaActualizar)+" !!!"
						oResActuRem.iderror=0
					ELSE
						AERROR(laMisErrores)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'ROLLBACK')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'ROLLBACK','',lnTipoconeccion)

						oResActuRem.mensaje="Error al Actualizar los Datos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF 
				ENDIF 

				***** luego de terminar la transacccion
				IF pnTipoConeccion=1	&&& usando coneccion Nativa
					CURSORSETPROP("Buffering",1,lcTablaActualizar)
				ENDIF 

			CASE lcTablaActualizar=="ctbsaldos"
				lnCtrlConec02=_conecta(pcDB)

				lcComando02="SELECT * FROM "+lcTablaActualizar+" WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
				lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"c_cur_"+lcTablaActualizar+lcTiempoActu)

				IF lnCtrlSql02>0 &&& hay registro a actualizar y ya se conecto al sever remoto
					lnCantRegActu=_tally

					IF lnCantRegActu>0	&&&& no hay registros a actualizar
						***** iniciando transaccion y buffering
						IF pnTipoConeccion=1	&&& usando coneccion Nativa local
							SELECT (lcTablaActualizar)
							CURSORSETPROP("Buffering",5,lcTablaActualizar)
						ENDIF 
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'BEGIN')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'BEGIN','',lnTipoconeccion)
						lnTransaccionIniciada=1
						
						**************************************************************************************************************
						***** le cambiomos la fecha de actualizacion a los registros locales para evitar que alguien mas los modifique
						IF pnTipoConeccion=1
							lcComando03=;
									"UPDATE "+lcTablaActualizar+" "+;
										"set fecactu=CTOT('"+TTOC(ltFechaHoraActualizacion)+"') "+;
										"WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
						ELSE 
							lcComando03=;
									"UPDATE "+lcTablaActualizar+" "+;
										"set fecactu='"+_ConvertirToFechaHoraSQL(ltFechaHoraActualizacion)+"' "+;
										"WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
						ENDIF 
						**** cambiando fecha a registros locales
						lnCtrlSql03=miSQLEXEC(lnCtrlConec02,lcComando03,"")
					
						**************************************************************************************************************
						****** enviamos los registros locales al remoto
						lcComando01=;
									"INSERT INTO "+lcTablaActualizar+" (idsaldo,idcuenta,periodo,debe,haber,presupuesto,nodo,fecalta,fecmod,fecactu,iduser,pcuser) "+;
										"VALUES "
									lcComaUnion=""
									SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
									SCAN FOR idsaldo<>0 AND nodo=pcnodo	
										lcComando01=lcComando01+lcComaUnion;
											+"("+ALLTRIM(STR(idsaldo))+","+;
											""+ALLTRIM(STR(idcuenta))+","+;
											"'"+ALLTRIM(periodo)+"',"+;
											"0,"+;
											"0,"+;
											""+ALLTRIM(STR(presupuesto,16,6))+","+;
											"'"+ALLTRIM(nodo)+"',"+;
											"'"+_ConvertirToFechaHoraSQL(fecalta)+"',"+;
											"'"+_ConvertirToFechaHoraSQL(fecmod)+"',"+;
											"'"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"',"+;
											""+ALLTRIM(STR(iduser))+","+;
											"'"+ALLTRIM(pcuser)+"' "+;
											")"
										lcComaUnion=","
									ENDSCAN 
										lcComando01=lcComando01+" ON DUPLICATE KEY UPDATE "+;
											"idcuenta = VALUES(idcuenta),"+;
											"periodo = VALUES(periodo),"+;
											"presupuesto = VALUES(presupuesto),"+;
											"nodo = VALUES(nodo),"+;
											"fecalta = VALUES(fecalta),"+;
											"fecmod = VALUES(fecmod),"+;
											"fecactu= VALUES(fecactu),"+;
											"iduser = VALUES(iduser),"+;
											"pcuser = VALUES(pcuser)"
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,lcComando01,"c_Cur_Remoto"+lcTablaActualizar,lnTipoconeccion)


						IF lnCtrlSql01<1
							oResActuRem.mensaje="Error al Actualizar los Registros en el Servidor Remoto"
							oResActuRem.iderror=1
						ENDIF 
					ELSE
						***** se cambian los controles de los comandos sql ejecutados a todos correctos por que no hay error... simplemente no hay registros
						lnCtrlSql01=1	
						lnCtrlSql02=1
						lnCtrlSql03=1
						oResActuRem.mensaje="No hay Registros para Subir en "+UPPER(lcTablaActualizar)
						oResActuRem.iderror=0
					ENDIF 
				ELSE
					AERROR(laMisErrores)
					oResActuRem.iderror=1
					oResActuRem.mensaje="Error en la Coneccion Local: "+laMisErrores(2)
				ENDIF 	

				********** aqui confirmamos los datos locales si se ejecuto todo bien y si hay registros a actualizar
				IF lnCtrlSql01>0 AND lnCtrlSql02>0 AND lnCtrlSql03>0 AND lnCantRegActu>0
					******* confirmando datos locales
					IF pnTipoConeccion=1	&&& usando coneccion Nativa datos locales
						llRet=TABLEUPDATE(1,.t.,lcTablaActualizar)
					ENDIF 
				ELSE
					IF lnCtrlSql03=<1 AND lnCantRegActu>0
						AERROR(laMisErrores)
						oResActuRem.mensaje="No fue Posible Cambiar la Fecha de Actualizacion en los Registros Locales: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF
					llRet=.f.
				ENDIF 

				**** aqui confirmamos los datos ya sea sql o nativo
				IF lnTransaccionIniciada=1
					IF llRet
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'COMMIT')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'COMMIT','',lnTipoconeccion)
						
						oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Registros Actualizados de "+UPPER(lcTablaActualizar)+" !!!"
						oResActuRem.iderror=0
					ELSE
						AERROR(laMisErrores)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'ROLLBACK')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'ROLLBACK','',lnTipoconeccion)

						oResActuRem.mensaje="Error al Actualizar los Datos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF 
				ENDIF 

				***** luego de terminar la transacccion
				IF pnTipoConeccion=1	&&& usando coneccion Nativa
					CURSORSETPROP("Buffering",1,lcTablaActualizar)
				ENDIF 

			CASE lcTablaActualizar=="ctbtipopar"
				lnCtrlConec02=_conecta(pcDB)

				lcComando02="SELECT * FROM "+lcTablaActualizar+" WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
				lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"c_cur_"+lcTablaActualizar+lcTiempoActu)

				IF lnCtrlSql02>0 &&& hay registro a actualizar y ya se conecto al sever remoto
					lnCantRegActu=_tally

					IF lnCantRegActu>0	&&&& no hay registros a actualizar
						***** iniciando transaccion y buffering
						IF pnTipoConeccion=1	&&& usando coneccion Nativa local
							SELECT (lcTablaActualizar)
							CURSORSETPROP("Buffering",5,lcTablaActualizar)
						ENDIF 
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'BEGIN')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'BEGIN','',lnTipoconeccion)
						lnTransaccionIniciada=1
						
						**************************************************************************************************************
						***** le cambiomos la fecha de actualizacion a los registros locales para evitar que alguien mas los modifique
						IF pnTipoConeccion=1
							lcComando03=;
									"UPDATE "+lcTablaActualizar+" "+;
										"set fecactu=CTOT('"+TTOC(lnTiempoIni)+"') "+;
										"WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
						ELSE 
							lcComando03=;
									"UPDATE "+lcTablaActualizar+" "+;
										"set fecactu='"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"' "+;
										"WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
						ENDIF 
						**** cambiando fecha a registros locales
						lnCtrlSql03=miSQLEXEC(lnCtrlConec02,lcComando03,"")
					
						**************************************************************************************************************
						****** enviamos los registros locales al remoto
						lcComando01=;
									"INSERT INTO "+lcTablaActualizar+" (idtipopar,codtpar,tipopar,status,fecalta,fecmod,fecactu,nodo,eliminado,iduser,pcuser) "+;
										"VALUES "
									lcComaUnion=""
									SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
									SCAN FOR idtipopar<>0 AND nodo=pcnodo	
										lcComando01=lcComando01+lcComaUnion;
											+"("+ALLTRIM(STR(idtipopar))+","+;
											"'"+ALLTRIM(codtpar)+"',"+;
											"'"+ALLTRIM(tipopar)+"',"+;
											""+ALLTRIM(STR(status))+","+;
											"'"+_ConvertirToFechaHoraSQL(fecalta)+"',"+;
											"'"+_ConvertirToFechaHoraSQL(fecmod)+"',"+;
											"'"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"',"+;
											"'"+ALLTRIM(nodo)+"',"+;
											""+ALLTRIM(STR(eliminado))+","+;
											""+ALLTRIM(STR(iduser))+","+;
											"'"+ALLTRIM(pcuser)+"' "+;
											")"
										lcComaUnion=","
									ENDSCAN 
										lcComando01=lcComando01+" ON DUPLICATE KEY UPDATE "+;
											"codtpar = VALUES(codtpar),"+;
											"tipopar = VALUES(tipopar),"+;
											"status = VALUES(status),"+;
											"fecalta = VALUES(fecalta),"+;
											"fecmod = VALUES(fecmod),"+;
											"fecactu= VALUES(fecactu),"+;
											"nodo = VALUES(nodo),"+;
											"eliminado = VALUES(eliminado),"+;
											"iduser = VALUES(iduser),"+;
											"pcuser = VALUES(pcuser)"
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,lcComando01,"c_Cur_Remoto"+lcTablaActualizar,lnTipoconeccion)


						IF lnCtrlSql01<1
							oResActuRem.mensaje="Error al Actualizar los Registros en el Servidor Remoto"
							oResActuRem.iderror=1
						ENDIF 
					ELSE
						***** se cambian los controles de los comandos sql ejecutados a todos correctos por que no hay error... simplemente no hay registros
						lnCtrlSql01=1	
						lnCtrlSql02=1
						lnCtrlSql03=1
						oResActuRem.mensaje="No hay Registros para Subir en "+UPPER(lcTablaActualizar)
						oResActuRem.iderror=0
					ENDIF 
				ELSE
					AERROR(laMisErrores)
					oResActuRem.iderror=1
					oResActuRem.mensaje="Error en la Coneccion Local: "+laMisErrores(2)
				ENDIF 	

				********** aqui confirmamos los datos locales si se ejecuto todo bien y si hay registros a actualizar
				IF lnCtrlSql01>0 AND lnCtrlSql02>0 AND lnCtrlSql03>0 AND lnCantRegActu>0
					******* confirmando datos locales
					IF pnTipoConeccion=1	&&& usando coneccion Nativa datos locales
						llRet=TABLEUPDATE(1,.t.,lcTablaActualizar)
					ENDIF 
				ELSE
					IF lnCtrlSql03=<1 AND lnCantRegActu>0
						AERROR(laMisErrores)
						oResActuRem.mensaje="No fue Posible Cambiar la Fecha de Actualizacion en los Registros Locales: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF
					llRet=.f.
				ENDIF 

				**** aqui confirmamos los datos ya sea sql o nativo
				IF lnTransaccionIniciada=1
					IF llRet
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'COMMIT')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'COMMIT','',lnTipoconeccion)
						
						oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Registros Actualizados de "+UPPER(lcTablaActualizar)+" !!!"
						oResActuRem.iderror=0
					ELSE
						AERROR(laMisErrores)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'ROLLBACK')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'ROLLBACK','',lnTipoconeccion)

						oResActuRem.mensaje="Error al Actualizar los Datos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF 
				ENDIF 

				***** luego de terminar la transacccion
				IF pnTipoConeccion=1	&&& usando coneccion Nativa
					CURSORSETPROP("Buffering",1,lcTablaActualizar)
				ENDIF 


			CASE lcTablaActualizar=="ctbnumpar"
				lnCtrlConec02=_conecta(pcDB)

				lcComando02="SELECT * FROM "+lcTablaActualizar+" WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
				lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"c_cur_"+lcTablaActualizar+lcTiempoActu)

				IF lnCtrlSql02>0 &&& hay registro a actualizar y ya se conecto al sever remoto
					lnCantRegActu=_tally

					IF lnCantRegActu>0	&&&& no hay registros a actualizar
						***** iniciando transaccion y buffering
						IF pnTipoConeccion=1	&&& usando coneccion Nativa local
							SELECT (lcTablaActualizar)
							CURSORSETPROP("Buffering",5,lcTablaActualizar)
						ENDIF 
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'BEGIN')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'BEGIN','',lnTipoconeccion)
						lnTransaccionIniciada=1
						
						**************************************************************************************************************
						***** le cambiomos la fecha de actualizacion a los registros locales para evitar que alguien mas los modifique
						IF pnTipoConeccion=1
							lcComando03=;
									"UPDATE "+lcTablaActualizar+" "+;
										"set fecactu=CTOT('"+TTOC(lnTiempoIni)+"') "+;
										"WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
						ELSE 
							lcComando03=;
									"UPDATE "+lcTablaActualizar+" "+;
										"set fecactu='"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"' "+;
										"WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
						ENDIF 
						**** cambiando fecha a registros locales
						lnCtrlSql03=miSQLEXEC(lnCtrlConec02,lcComando03,"")
					
						**************************************************************************************************************
						****** enviamos los registros locales al remoto
						lcComando01=;
									"INSERT INTO "+lcTablaActualizar+" (idnumpar,numero,periodo,idtipopartida,tipodetresu,fecalta,fecmod,fecactu,nodo,iduser,pcuser) "+;
										"VALUES "
									lcComaUnion=""
									SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
									SCAN FOR idnumpar<>0 AND nodo=pcnodo	
										lcComando01=lcComando01+lcComaUnion;
											+"("+ALLTRIM(STR(idnumpar))+","+;
											""+ALLTRIM(STR(numero))+","+;
											"'"+ALLTRIM(periodo)+"',"+;
											""+ALLTRIM(STR(idtipopartida))+","+;
											""+ALLTRIM(STR(tipodetresu))+","+;
											"'"+_ConvertirToFechaHoraSQL(fecalta)+"',"+;
											"'"+_ConvertirToFechaHoraSQL(fecmod)+"',"+;
											"'"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"',"+;
											"'"+ALLTRIM(nodo)+"',"+;
											""+ALLTRIM(STR(iduser))+","+;
											"'"+ALLTRIM(pcuser)+"' "+;
											")"
										lcComaUnion=","
									ENDSCAN 
										lcComando01=lcComando01+" ON DUPLICATE KEY UPDATE "+;
											"numero = VALUES(numero),"+;
											"periodo = VALUES(periodo),"+;
											"idtipopartida = VALUES(idtipopartida),"+;
											"tipodetresu = VALUES(tipodetresu),"+;
											"fecalta = VALUES(fecalta),"+;
											"fecmod = VALUES(fecmod),"+;
											"fecactu= VALUES(fecactu),"+;
											"nodo = VALUES(nodo),"+;
											"iduser = VALUES(iduser),"+;
											"pcuser = VALUES(pcuser)"
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,lcComando01,"c_Cur_Remoto"+lcTablaActualizar,lnTipoconeccion)
						IF lnCtrlSql01<1
							oResActuRem.mensaje="Error al Actualizar los Registros en el Servidor Remoto"
							oResActuRem.iderror=1
						ENDIF 
					ELSE
						***** se cambian los controles de los comandos sql ejecutados a todos correctos por que no hay error... simplemente no hay registros
						lnCtrlSql01=1	
						lnCtrlSql02=1
						lnCtrlSql03=1
						oResActuRem.mensaje="No hay Registros para Subir en "+UPPER(lcTablaActualizar)
						oResActuRem.iderror=0
					ENDIF 
				ELSE
					AERROR(laMisErrores)
					oResActuRem.iderror=1
					oResActuRem.mensaje="Error en la Coneccion Local: "+laMisErrores(2)
				ENDIF 	

				********** aqui confirmamos los datos locales si se ejecuto todo bien y si hay registros a actualizar
				IF lnCtrlSql01>0 AND lnCtrlSql02>0 AND lnCtrlSql03>0 AND lnCantRegActu>0
					******* confirmando datos locales
					IF pnTipoConeccion=1	&&& usando coneccion Nativa datos locales
						llRet=TABLEUPDATE(1,.t.,lcTablaActualizar)
					ENDIF 
				ELSE
					IF lnCtrlSql03=<1 AND lnCantRegActu>0
						AERROR(laMisErrores)
						oResActuRem.mensaje="No fue Posible Cambiar la Fecha de Actualizacion en los Registros Locales: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF
					llRet=.f.
				ENDIF 

				**** aqui confirmamos los datos ya sea sql o nativo
				IF lnTransaccionIniciada=1
					IF llRet
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'COMMIT')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'COMMIT','',lnTipoconeccion)
						
						oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Registros Actualizados de "+UPPER(lcTablaActualizar)+" !!!"
						oResActuRem.iderror=0
					ELSE
						AERROR(laMisErrores)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'ROLLBACK')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'ROLLBACK','',lnTipoconeccion)

						oResActuRem.mensaje="Error al Actualizar los Datos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF 
				ENDIF 

				***** luego de terminar la transacccion
				IF pnTipoConeccion=1	&&& usando coneccion Nativa
					CURSORSETPROP("Buffering",1,lcTablaActualizar)
				ENDIF 




			CASE lcTablaActualizar=="ctbpartidas"
				lnCtrlConec02=_conecta(pcDB)

				lcComando02="SELECT * FROM "+lcTablaActualizar+" WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
				lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"c_cur_"+lcTablaActualizar+lcTiempoActu)

				IF lnCtrlSql02>0 &&& hay registro a actualizar y ya se conecto al sever remoto
					lnCantRegActu=_tally

					IF lnCantRegActu>0	&&&& no hay registros a actualizar
						***** iniciando transaccion y buffering
						IF pnTipoConeccion=1	&&& usando coneccion Nativa local
							SELECT (lcTablaActualizar)
							CURSORSETPROP("Buffering",5,lcTablaActualizar)
						ENDIF 
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'BEGIN')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'BEGIN','',lnTipoconeccion)
						lnTransaccionIniciada=1
						
						**************************************************************************************************************
						***** le cambiomos la fecha de actualizacion a los registros locales para evitar que alguien mas los modifique
						IF pnTipoConeccion=1
							lcComando03=;
									"UPDATE "+lcTablaActualizar+" "+;
										"set fecactu=CTOT('"+TTOC(lnTiempoIni)+"') "+;
										"WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
						ELSE 
							lcComando03=;
									"UPDATE "+lcTablaActualizar+" "+;
										"set fecactu='"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"' "+;
										"WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
						ENDIF 
						**** cambiando fecha a registros locales
						lnCtrlSql03=miSQLEXEC(lnCtrlConec02,lcComando03,"")
					
						**************************************************************************************************************
						****** enviamos los registros locales al remoto
						lcComando01=;
									"INSERT INTO "+lcTablaActualizar+" (idpartida,idtipopar,fechapartida,numeropartida,"+;
														"concepto,monto,periodo,origen,impreso,fecalta,fecmod,fecactu,"+;
														"idsucursal,idctrocosto,nodo,eliminado,iduser,pcuser) "+;
										"VALUES "
									lcComaUnion=""
									SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
									SCAN FOR idpartida<>0 AND nodo=pcnodo	
										lcComando01=lcComando01+lcComaUnion;
											+"("+ALLTRIM(STR(idpartida))+","+;
											""+ALLTRIM(STR(idtipopar))+","+;
											"'"+_ConvertirToFechaSQL(fechapartida)+"',"+;
											"'"+ALLTRIM(numeropartida)+"',"+;
											"'"+ALLTRIM(_sincomillias(concepto))+"',"+;
											""+ALLTRIM(STR(monto,16,6))+","+;
											"'"+ALLTRIM(periodo)+"',"+;
											"'"+ALLTRIM(origen)+"',"+;
											""+ALLTRIM(STR(impreso))+","+;
											"'"+_ConvertirToFechaHoraSQL(fecalta)+"',"+;
											"'"+_ConvertirToFechaHoraSQL(fecmod)+"',"+;
											"'"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"',"+;
											""+ALLTRIM(STR(idsucursal))+","+;
											""+ALLTRIM(STR(idctrocosto))+","+;
											"'"+ALLTRIM(nodo)+"',"+;
											""+ALLTRIM(STR(eliminado))+","+;
											""+ALLTRIM(STR(iduser))+","+;
											"'"+ALLTRIM(pcuser)+"' "+;
											")"
										lcComaUnion=","
									ENDSCAN 
										lcComando01=lcComando01+" ON DUPLICATE KEY UPDATE "+;
											"idtipopar = VALUES(idtipopar),"+;
											"fechapartida = VALUES(fechapartida),"+;
											"numeropartida = VALUES(numeropartida),"+;
											"concepto = VALUES(concepto),"+;
											"monto = VALUES(monto),"+;
											"periodo = VALUES(periodo),"+;
											"origen = VALUES(origen),"+;
											"impreso = VALUES(impreso),"+;
											"fecalta = VALUES(fecalta),"+;
											"fecmod = VALUES(fecmod),"+;
											"fecactu= VALUES(fecactu),"+;
											"idsucursal = VALUES(idsucursal),"+;
											"idctrocosto = VALUES(idctrocosto),"+;
											"nodo = VALUES(nodo),"+;
											"eliminado = VALUES(eliminado),"+;
											"iduser = VALUES(iduser),"+;
											"pcuser = VALUES(pcuser)"
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,lcComando01,"c_Cur_Remoto"+lcTablaActualizar,lnTipoconeccion)


						IF lnCtrlSql01<1
							oResActuRem.mensaje="Error al Actualizar los Registros en el Servidor Remoto"
							oResActuRem.iderror=1
						ENDIF 
					ELSE
						***** se cambian los controles de los comandos sql ejecutados a todos correctos por que no hay error... simplemente no hay registros
						lnCtrlSql01=1	
						lnCtrlSql02=1
						lnCtrlSql03=1
						oResActuRem.mensaje="No hay Registros para Subir en "+UPPER(lcTablaActualizar)
						oResActuRem.iderror=0
					ENDIF 
				ELSE
					AERROR(laMisErrores)
					oResActuRem.iderror=1
					oResActuRem.mensaje="Error en la Coneccion Local: "+laMisErrores(2)
				ENDIF 	

				********** aqui confirmamos los datos locales si se ejecuto todo bien y si hay registros a actualizar
				IF lnCtrlSql01>0 AND lnCtrlSql02>0 AND lnCtrlSql03>0 AND lnCantRegActu>0
					******* confirmando datos locales
					IF pnTipoConeccion=1	&&& usando coneccion Nativa datos locales
						llRet=TABLEUPDATE(1,.t.,lcTablaActualizar)
					ENDIF 
				ELSE
					IF lnCtrlSql03=<1 AND lnCantRegActu>0
						AERROR(laMisErrores)
						oResActuRem.mensaje="No fue Posible Cambiar la Fecha de Actualizacion en los Registros Locales: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF
					llRet=.f.
				ENDIF 

				**** aqui confirmamos los datos ya sea sql o nativo
				IF lnTransaccionIniciada=1
					IF llRet
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'COMMIT')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'COMMIT','',lnTipoconeccion)
						
						oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Registros Actualizados de "+UPPER(lcTablaActualizar)+" !!!"
						oResActuRem.iderror=0
					ELSE
						AERROR(laMisErrores)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'ROLLBACK')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'ROLLBACK','',lnTipoconeccion)

						oResActuRem.mensaje="Error al Actualizar los Datos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF 
				ENDIF 

				***** luego de terminar la transacccion
				IF pnTipoConeccion=1	&&& usando coneccion Nativa
					CURSORSETPROP("Buffering",1,lcTablaActualizar)
				ENDIF 


			CASE lcTablaActualizar=="ctbpartidasdeta"
				lnCtrlConec02=_conecta(pcDB)

				lcComando02="SELECT * FROM "+lcTablaActualizar+" WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
				lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"c_cur_"+lcTablaActualizar+lcTiempoActu)

				IF lnCtrlSql02>0 &&& hay registro a actualizar y ya se conecto al sever remoto
					lnCantRegActu=_tally

					IF lnCantRegActu>0	&&&& no hay registros a actualizar
						***** iniciando transaccion y buffering
						IF pnTipoConeccion=1	&&& usando coneccion Nativa local
							SELECT (lcTablaActualizar)
							CURSORSETPROP("Buffering",5,lcTablaActualizar)
						ENDIF 
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'BEGIN')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'BEGIN','',lnTipoconeccion)
						lnTransaccionIniciada=1
						
						**************************************************************************************************************
						***** le cambiomos la fecha de actualizacion a los registros locales para evitar que alguien mas los modifique
						IF pnTipoConeccion=1
							lcComando03=;
									"UPDATE "+lcTablaActualizar+" "+;
										"set fecactu=CTOT('"+TTOC(lnTiempoIni)+"') "+;
										"WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
						ELSE 
							lcComando03=;
									"UPDATE "+lcTablaActualizar+" "+;
										"set fecactu='"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"' "+;
										"WHERE EMPTY(fecActu) OR fecActu<fecMod and nodo='"+pcnodo+"' "
						ENDIF 
						**** cambiando fecha a registros locales
						lnCtrlSql03=miSQLEXEC(lnCtrlConec02,lcComando03,"")
					
						**************************************************************************************************************
						****** enviamos los registros locales al remoto
						lcComando01=;
									"INSERT INTO "+lcTablaActualizar+" (idpartidad,idpartida,idcuenta,conceptod,"+;
												"debe,haber,periodo,origen,idorigen,fecalta,fecmod,fecactu,"+;
												"idsucursal,idctrocosto,nodo,eliminado,iduser,pcuser) "+;
										"VALUES "
									lcComaUnion=""
									SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
									SCAN FOR idpartidad<>0 AND nodo=pcnodo	
										lcComando01=lcComando01+lcComaUnion;
											+"("+ALLTRIM(STR(idpartidad))+","+;
											""+ALLTRIM(STR(idpartida))+","+;
											""+ALLTRIM(STR(idcuenta))+","+;
											"'"+ALLTRIM(_sincomillias(conceptod))+"',"+;
											""+ALLTRIM(STR(debe,16,6))+","+;
											""+ALLTRIM(STR(haber,16,6))+","+;
											"'"+ALLTRIM(periodo)+"',"+;
											"'"+ALLTRIM(origen)+"',"+;
											""+ALLTRIM(STR(idorigen))+","+;
											"'"+_ConvertirToFechaHoraSQL(fecalta)+"',"+;
											"'"+_ConvertirToFechaHoraSQL(fecmod)+"',"+;
											"'"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"',"+;
											""+ALLTRIM(STR(idsucursal))+","+;
											""+ALLTRIM(STR(idctrocosto))+","+;
											"'"+ALLTRIM(nodo)+"',"+;
											""+ALLTRIM(STR(eliminado))+","+;
											""+ALLTRIM(STR(iduser))+","+;
											"'"+ALLTRIM(pcuser)+"' "+;
											")"
										lcComaUnion=","
									ENDSCAN 
										lcComando01=lcComando01+" ON DUPLICATE KEY UPDATE "+;
											"idpartida = VALUES(idpartida),"+;
											"idcuenta = VALUES(idcuenta),"+;
											"conceptod = VALUES(conceptod),"+;
											"debe = VALUES(debe),"+;
											"haber = VALUES(haber),"+;
											"periodo= VALUES(periodo),"+;
											"origen = VALUES(origen),"+;
											"idorigen = VALUES(idorigen),"+;
											"fecalta = VALUES(fecalta),"+;
											"fecmod = VALUES(fecmod),"+;
											"idsucursal = VALUES(idsucursal),"+;
											"idctrocosto = VALUES(idctrocosto),"+;
											"fecactu= VALUES(fecactu),"+;
											"nodo = VALUES(nodo),"+;
											"eliminado = VALUES(eliminado),"+;
											"iduser = VALUES(iduser),"+;
											"pcuser = VALUES(pcuser)"
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,lcComando01,"c_Cur_Remoto"+lcTablaActualizar,lnTipoconeccion)


						IF lnCtrlSql01<1
							oResActuRem.mensaje="Error al Actualizar los Registros en el Servidor Remoto"
							oResActuRem.iderror=1
						ENDIF 
					ELSE
						***** se cambian los controles de los comandos sql ejecutados a todos correctos por que no hay error... simplemente no hay registros
						lnCtrlSql01=1	
						lnCtrlSql02=1
						lnCtrlSql03=1
						oResActuRem.mensaje="No hay Registros para Subir en "+UPPER(lcTablaActualizar)
						oResActuRem.iderror=0
					ENDIF 
				ELSE
					AERROR(laMisErrores)
					oResActuRem.iderror=1
					oResActuRem.mensaje="Error en la Coneccion Local: "+laMisErrores(2)
				ENDIF 	

				********** aqui confirmamos los datos locales si se ejecuto todo bien y si hay registros a actualizar
				IF lnCtrlSql01>0 AND lnCtrlSql02>0 AND lnCtrlSql03>0 AND lnCantRegActu>0
					******* confirmando datos locales
					IF pnTipoConeccion=1	&&& usando coneccion Nativa datos locales
						llRet=TABLEUPDATE(1,.t.,lcTablaActualizar)
					ENDIF 
				ELSE
					IF lnCtrlSql03=<1 AND lnCantRegActu>0
						AERROR(laMisErrores)
						oResActuRem.mensaje="No fue Posible Cambiar la Fecha de Actualizacion en los Registros Locales: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF
					llRet=.f.
				ENDIF 

				**** aqui confirmamos los datos ya sea sql o nativo
				IF lnTransaccionIniciada=1
					IF llRet
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'COMMIT')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'COMMIT','',lnTipoconeccion)
						
						oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Registros Actualizados de "+UPPER(lcTablaActualizar)+" !!!"
						oResActuRem.iderror=0
					ELSE
						AERROR(laMisErrores)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'ROLLBACK')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'ROLLBACK','',lnTipoconeccion)

						oResActuRem.mensaje="Error al Actualizar los Datos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF 
				ENDIF 

				***** luego de terminar la transacccion
				IF pnTipoConeccion=1	&&& usando coneccion Nativa
					CURSORSETPROP("Buffering",1,lcTablaActualizar)
				ENDIF 


				
		ENDCASE 

		IF lnCtrlConec01>0
			=miSQLDISCONNECT(lnCtrlConec01)
		ENDIF 
		IF lnCtrlConec02>0
			=miSQLDISCONNECT(lnCtrlConec02)
		ENDIF 

		IF pnTipoConeccion=1
			IF USED("c_cur_"+lcTablaActualizar+lcTiempoActu)
				USE IN ("c_cur_"+lcTablaActualizar+lcTiempoActu)
			ENDIF 
		endif 

		IF !EMPTY(lcAliasActutmp)
			SELECT (lcAliasActutmp)
		ENDIF 
	ELSE
		AERROR(laMisErrores)
		oResActuRem.mensaje="Error en la Coneccion Remota, "+laMisErrores(2)
		oResActuRem.iderror=1
	ENDIF 
	lnTiempoFin=dateTIME()
	lnSegTrans=pasarSegundosAMinutos(lnTiempoFin-lnTiempoIni)
	oResActuRem.mensaje="("+lnSegTrans+")  "+oResActuRem.mensaje
	RETURN oResActuRem
ENDFUNC 


FUNCTION BajarRegistrosConta(lnTipoconeccion,lcDriverOdbcRemoto,lcServerRemoto,lcRootRemoto,lcDBRemoto,lcPuertoRemoto,lcClaveRemoto,lcTablaActualizar)
	lnCantRegActu=0
	lnCantRegActuIns=0
	lnCantRegActuAct=0
	STORE 0 TO lnCtrlSql01,lnCtrlSql02,lnCtrlSql03
	lnTransaccionIniciada=0
	oResActuRem= CREATEOBJECT( "respuesta" )
	lnCtrlConec01=_conectaRemoto(lcDBRemoto,lnTipoconeccion,lcDriverOdbcRemoto,lcServerRemoto,lcRootRemoto,lcClaveRemoto,lcPuertoRemoto)
	lcMensajeActuaRemota=""
	lcTiempoActu=STRTRAN(TIME(),":","")
	lnTiempoIni=dateTIME()		&&& como no puedo conectar al server verifica la hora local
	IF lnCtrlConec01>0
		ltFecHoraActualizacion=FechaHoraServerMySQL(lnCtrlConec01)
	ELSE
		ltFecHoraActualizacion=dateTIME()
	ENDIF 

	oResActuRem.fechahora=lnTiempoIni

	IF lnCtrlConec01>0
		lcAliasActutmp=ALIAS()
	*	SELECT (lcTablaActualizar)
		****** Coneccion remota
		DO case
			CASE lcTablaActualizar=="ctbcuentas"
				lnCtrlConec02=_conecta(pcDB)
				
				ltFecHoraActuAnterior=_obtenerFechaHoraUltimaActualizacion(lnCtrlConec02,lcTablaActualizar)	&&& obtiene la fecha y hora de la actualizacion anterior
				lcComando01="SELECT * FROM "+lcTablaActualizar+" WHERE fecActu>'"+_ConvertirToFechaHoraSQL(ltFecHoraActuAnterior)+"' and nodo<>'"+pcnodo+"' "
				lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,lcComando01,"c_cur_"+lcTablaActualizar+lcTiempoActu,lnTipoconeccion)

				IF lnCtrlSql01>0 &&& hay registro a actualizar y ya se conecto al sever remoto
					lnCantRegActu=RECCOUNT("c_cur_"+lcTablaActualizar+lcTiempoActu)
					
					IF lnCantRegActu>0	&&&& no hay registros a actualizar
						***** iniciando transaccion y buffering
						IF pnTipoConeccion=1	&&& usando coneccion Nativa local
							IF !USED(lcTablaActualizar)
								USE pcsysdir+pcDB+"\"+lcTablaActualizar IN 0 SHARED AGAIN 
							ENDIF 
							CURSORSETPROP("Buffering",5,lcTablaActualizar)
							CURSORSETPROP("Buffering",5,"sisloguactu")
						ENDIF 
						SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'BEGIN')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'BEGIN','',lnTipoconeccion)
						lnTransaccionIniciada=1
						**************************************************************************************************************
						***** le cambiomos la fecha de actualizacion a los registros Remotos para evitar que alguien mas los modifique
						IF pnTipoConeccion=1
							lcComando03=;
									"UPDATE sisloguactu "+;
										"set fecultactu=CTOT('"+ttoc(ltFecHoraActualizacion)+"') "+;
										"WHERE tabla='"+UPPER(lcTablaActualizar)+" '"
						ELSE
							lcComando03=;
									"UPDATE sisloguactu "+;
										"set fecultactu='"+_ConvertirToFechaHoraSQL(ltFecHoraActualizacion)+"' "+;
										"WHERE  tabla='"+UPPER(lcTablaActualizar)+" '"
						ENDIF 
						**** cambiando fecha a registros locales
						lnCtrlSql03=miSQLEXEC(lnCtrlConec02,lcComando03,"")
						**************************************************************************************************************
						****** enviamos los registros remotos al local
						IF pnTipoconeccion=1
							****** insertando registros nuevos
							lcComando02=;
										"INSERT INTO "+lcTablaActualizar+" (idcuenta,codcta,cuenta,idtipocuenta,nivel,naturaleza,detalle,idpadre,eliminado,status,fecalta,fecmod,fecactu,nodo,iduser,pcuser) "+;
											"select  idcuenta,codcta,cuenta,idtipocuenta,nivel,naturaleza,detalle,idpadre,eliminado,status,fecalta,fecmod,fecactu,nodo,iduser,pcuser "+;
												" from c_cur_"+lcTablaActualizar+lcTiempoActu+" "+; 
												" where idcuenta not in (select idcuenta from "+lcTablaActualizar+" where nodo<>'"+pcnodo+"') "
							lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"")
							lnCantRegActuIns=_tally
							
							IF lnCtrlSql02>1		&&&& si pudo insertar registros nuevo ahora actualizar los existentes
								lcComando02=;
									"update "+lcTablaActualizar+" "+;
										"set "+lcTablaActualizar+".codcta=a.codcta,"+;
											lcTablaActualizar+".cuenta=a.cuenta,"+;
											lcTablaActualizar+".idtipocuenta=a.idtipocuenta,"+;
											lcTablaActualizar+".nivel=a.nivel,"+;
											lcTablaActualizar+".naturaleza=a.naturaleza,"+;
											lcTablaActualizar+".detalle=a.detalle,"+;
											lcTablaActualizar+".idpadre=a.idpadre,"+;
											lcTablaActualizar+".eliminado=a.eliminado,"+;
											lcTablaActualizar+".status=a.status,"+;
											lcTablaActualizar+".fecalta=a.fecalta,"+;
											lcTablaActualizar+".fecmod=a.fecmod,"+;
											lcTablaActualizar+".fecactu=a.fecactu,"+;
											lcTablaActualizar+".nodo=a.nodo,"+;
											lcTablaActualizar+".iduser=a.iduser,"+;
											lcTablaActualizar+".pcuser=a.pcuser "+;
									"from c_cur_"+lcTablaActualizar+lcTiempoActu+" a where a.idcuenta="+lcTablaActualizar+".idcuenta "
								lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"")
								lnCantRegActuAct=_tally
							ENDIF 
							
						ELSE 
							lcComando02=;
										"INSERT INTO "+lcTablaActualizar+" (idcuenta,codcta,cuenta,idtipocuenta,nivel,naturaleza,detalle,idpadre,eliminado,status,fecalta,fecmod,fecactu,nodo,iduser,pcuser) "+;
											"VALUES "
										lcComaUnion=""
										SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
										SCAN FOR idcuenta<>0 
											lcComando01=lcComando01+lcComaUnion;
												+"("+ALLTRIM(STR(idcuenta))+","+;
												"'"+ALLTRIM(codcta)+"',"+;
												"'"+ALLTRIM(_sincomillias(cuenta))+"',"+;
												""+ALLTRIM(STR(idtipocuenta))+","+;
												""+ALLTRIM(STR(nivel))+","+;
												""+ALLTRIM(STR(naturaleza))+","+;
												""+ALLTRIM(STR(detalle))+","+;
												""+ALLTRIM(STR(idpadre))+","+;
												""+ALLTRIM(STR(eliminado))+","+;
												""+ALLTRIM(STR(status))+","+;
												"'"+_ConvertirToFechaHoraSQL(fecalta)+"',"+;
												"'"+_ConvertirToFechaHoraSQL(fecmod)+"',"+;
												"'"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"',"+;
												"'"+ALLTRIM(nodo)+"',"+;
												""+ALLTRIM(STR(iduser))+","+;
												"'"+ALLTRIM(pcuser)+"' "+;
												")"
											lcComaUnion=","
										ENDSCAN 
											lcComando01=lcComando01+" ON DUPLICATE KEY UPDATE "+;
												"codcta = VALUES(codcta),"+;
												"cuenta = VALUES(cuenta),"+;
												"idtipocuenta = VALUES(idtipocuenta),"+;
												"nivel = VALUES(nivel),"+;
												"naturaleza = VALUES(naturaleza),"+;
												"detalle = VALUES(detalle),"+;
												"idpadre = VALUES(idpadre),"+;
												"eliminado = VALUES(eliminado),"+;
												"status = VALUES(status),"+;
												"fecalta = VALUES(fecalta),"+;
												"fecmod = VALUES(fecmod),"+;
												"fecactu= VALUES(fecactu),"+;
												"nodo = VALUES(nodo),"+;
												"iduser = VALUES(iduser),"+;
												"pcuser = VALUES(pcuser)"
							lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"c_Cur_Remoto"+lcTablaActualizar,lnTipoconeccion)
						ENDIF 

						IF lnCtrlSql02<1
							oResActuRem.mensaje="Error al Actualizar los Registros en el Servidor Local "
							oResActuRem.iderror=1
						ENDIF 
					ELSE
						***** se cambian los controles de los comandos sql ejecutados a todos correctos por que no hay error... simplemente no hay registros
						lnCtrlSql01=1	
						lnCtrlSql02=1
						lnCtrlSql03=1
						oResActuRem.mensaje="No hay Registros para Bajar en "+UPPER(lcTablaActualizar)
						oResActuRem.iderror=0
					ENDIF 
				ELSE
					AERROR(laMisErrores)
					oResActuRem.iderror=1
					oResActuRem.mensaje="Error en la Coneccion Remota: "+laMisErrores(2)
				ENDIF 	

				********** aqui confirmamos los datos locales si se ejecuto todo bien y si hay registros a actualizar
				IF lnCtrlSql01>0 AND lnCtrlSql02>0 AND lnCtrlSql03>0 AND lnCantRegActu>0
					******* confirmando datos locales
					IF pnTipoConeccion=1	&&& usando coneccion Nativa datos locales
						llRet=TABLEUPDATE(1,.t.,lcTablaActualizar)
						IF llRet
							llRet=TABLEUPDATE(1,.t.,"sisloguactu")
						ENDIF 
					ENDIF 
				ELSE
					IF lnCtrlSql03=<1 AND lnCantRegActu>0
						AERROR(laMisErrores)
						oResActuRem.mensaje="No fue Posible Cambiar la Fecha de Actualizacion en los Registros Remotos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF
					llRet=.f.
				ENDIF 

				**** aqui confirmamos los datos ya sea sql o nativo
				IF lnTransaccionIniciada=1
					IF llRet
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'COMMIT',"")
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'COMMIT','',lnTipoconeccion)
						lcUnionMensaje=""
						IF lnCantRegActuIns<>0
							oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Reg. Insertados "
							lcUnionMensaje=" y "
						ENDIF
						IF lnCantRegActuAct<>0
							oResActuRem.mensaje=oResActuRem.mensaje+lcUnionMensaje+ALLTRIM(STR(lnCantRegActu))+" Reg. Actualizados "
						ENDIF
						IF lnCantRegActu<>0
							oResActuRem.mensaje=oResActuRem.mensaje+" de "+UPPER(lcTablaActualizar)+" !!!"
						ENDIF 
						
						oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Registros Actualizados de "+UPPER(lcTablaActualizar)+" !!!"
						oResActuRem.iderror=0
					ELSE
						AERROR(laMisErrores)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'ROLLBACK')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'ROLLBACK','',lnTipoconeccion)

						oResActuRem.mensaje="Error al Actualizar los Datos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF 
				ENDIF 

				***** luego de terminar la transacccion
				IF USED(lcTablaActualizar)
					IF pnTipoConeccion=1	&&& usando coneccion Nativa
						CURSORSETPROP("Buffering",1,lcTablaActualizar)
						CURSORSETPROP("Buffering",1,"sisloguactu")
					ENDIF 
				ENDIF 

			CASE lcTablaActualizar=="ctbsaldos"
				lnCtrlConec02=_conecta(pcDB)
				
				ltFecHoraActuAnterior=_obtenerFechaHoraUltimaActualizacion(lnCtrlConec02,lcTablaActualizar)	&&& obtiene la fecha y hora de la actualizacion anterior
				lcComando01="SELECT * FROM "+lcTablaActualizar+" WHERE fecActu>'"+_ConvertirToFechaHoraSQL(ltFecHoraActuAnterior)+"' and nodo<>'"+pcnodo+"' "
				lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,lcComando01,"c_cur_"+lcTablaActualizar+lcTiempoActu,lnTipoconeccion)

				IF lnCtrlSql01>0 &&& hay registro a actualizar y ya se conecto al sever remoto
					lnCantRegActu=RECCOUNT("c_cur_"+lcTablaActualizar+lcTiempoActu)
					
					IF lnCantRegActu>0	&&&& no hay registros a actualizar
						***** iniciando transaccion y buffering
						IF pnTipoConeccion=1	&&& usando coneccion Nativa local
							IF !USED(lcTablaActualizar)
								USE pcsysdir+pcDB+"\"+lcTablaActualizar IN 0 SHARED AGAIN 
							ENDIF 
							CURSORSETPROP("Buffering",5,lcTablaActualizar)
							CURSORSETPROP("Buffering",5,"sisloguactu")
						ENDIF 
						SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'BEGIN')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'BEGIN','',lnTipoconeccion)
						lnTransaccionIniciada=1
						**************************************************************************************************************
						***** le cambiomos la fecha de actualizacion a los registros Remotos para evitar que alguien mas los modifique
						IF pnTipoConeccion=1
							lcComando03=;
									"UPDATE sisloguactu "+;
										"set fecultactu=CTOT('"+ttoc(ltFecHoraActualizacion)+"') "+;
										"WHERE tabla='"+UPPER(lcTablaActualizar)+" '"
						ELSE
							lcComando03=;
									"UPDATE sisloguactu "+;
										"set fecultactu='"+_ConvertirToFechaHoraSQL(ltFecHoraActualizacion)+"' "+;
										"WHERE  tabla='"+UPPER(lcTablaActualizar)+" '"
						ENDIF 
						**** cambiando fecha a registros locales
						lnCtrlSql03=miSQLEXEC(lnCtrlConec02,lcComando03,"")
						**************************************************************************************************************
						****** enviamos los registros remotos al local
						IF pnTipoconeccion=1
							****** insertando registros nuevos
							lcComando02=;
										"INSERT INTO "+lcTablaActualizar+" (idsaldo,idcuenta,periodo,debe,haber,presupuesto,nodo,fecalta,fecmod,fecactu,iduser,pcuser) "+;
											"select  idsaldo,idcuenta,periodo,0,0,presupuesto,nodo,fecalta,fecmod,fecactu,iduser,pcuser "+;
												" from c_cur_"+lcTablaActualizar+lcTiempoActu+" "+; 
												" where idsaldo not in (select idsaldo from "+lcTablaActualizar+" where nodo<>'"+pcnodo+"') "
							lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"")
							lnCantRegActuIns=_tally
							
							IF lnCtrlSql02>1		&&&& si pudo insertar registros nuevo ahora actualizar los existentes
								lcComando02=;
									"update "+lcTablaActualizar+" "+;
										"set "+lcTablaActualizar+".idcuenta=a.idcuenta,"+;
											lcTablaActualizar+".periodo=a.periodo,"+;
											lcTablaActualizar+".presupuesto=a.presupuesto,"+;
											lcTablaActualizar+".nodo=a.nodo,"+;
											lcTablaActualizar+".fecalta=a.fecalta,"+;
											lcTablaActualizar+".fecmod=a.fecmod,"+;
											lcTablaActualizar+".fecactu=a.fecactu,"+;
											lcTablaActualizar+".iduser=a.iduser,"+;
											lcTablaActualizar+".pcuser=a.pcuser "+;
									"from c_cur_"+lcTablaActualizar+lcTiempoActu+" a where a.idsaldo="+lcTablaActualizar+".idsaldo "
								lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"")
								lnCantRegActuAct=_tally
							ENDIF 
							
						ELSE 
							lcComando02=;
										"INSERT INTO "+lcTablaActualizar+" (idsaldo,idcuenta,periodo,debe,haber,presupuesto,nodo,fecalta,fecmod,fecactu,iduser,pcuser) "+;
											"VALUES "
										lcComaUnion=""
										SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
										SCAN FOR idsaldo<>0 
											lcComando01=lcComando01+lcComaUnion;
												+"("+ALLTRIM(STR(idsaldo))+","+;
												""+ALLTRIM(STR(idcuenta))+","+;
												"'"+ALLTRIM(periodo)+"',"+;
												"0,"+;
												"0,"+;
												""+ALLTRIM(STR(presupuesto,16,6))+","+;
												"'"+ALLTRIM(nodo)+"',"+;
												"'"+_ConvertirToFechaHoraSQL(fecalta)+"',"+;
												"'"+_ConvertirToFechaHoraSQL(fecmod)+"',"+;
												"'"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"',"+;
												""+ALLTRIM(STR(iduser))+","+;
												"'"+ALLTRIM(pcuser)+"' "+;
												")"
											lcComaUnion=","
										ENDSCAN 
											lcComando01=lcComando01+" ON DUPLICATE KEY UPDATE "+;
												"idcuenta = VALUES(idcuenta),"+;
												"periodo = VALUES(periodo),"+;
												"presupuesto = VALUES(presupuesto),"+;
												"nodo = VALUES(nodo),"+;
												"fecalta = VALUES(fecalta),"+;
												"fecmod = VALUES(fecmod),"+;
												"fecactu= VALUES(fecactu),"+;
												"iduser = VALUES(iduser),"+;
												"pcuser = VALUES(pcuser)"
							lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"c_Cur_Remoto"+lcTablaActualizar,lnTipoconeccion)
						ENDIF 

						IF lnCtrlSql02<1
							oResActuRem.mensaje="Error al Actualizar los Registros en el Servidor Local "
							oResActuRem.iderror=1
						ENDIF 
					ELSE
						***** se cambian los controles de los comandos sql ejecutados a todos correctos por que no hay error... simplemente no hay registros
						lnCtrlSql01=1	
						lnCtrlSql02=1
						lnCtrlSql03=1
						oResActuRem.mensaje="No hay Registros para Bajar en "+UPPER(lcTablaActualizar)
						oResActuRem.iderror=0
					ENDIF 
				ELSE
					AERROR(laMisErrores)
					oResActuRem.iderror=1
					oResActuRem.mensaje="Error en la Coneccion Remota: "+laMisErrores(2)
				ENDIF 	

				********** aqui confirmamos los datos locales si se ejecuto todo bien y si hay registros a actualizar
				IF lnCtrlSql01>0 AND lnCtrlSql02>0 AND lnCtrlSql03>0 AND lnCantRegActu>0
					******* confirmando datos locales
					IF pnTipoConeccion=1	&&& usando coneccion Nativa datos locales
						llRet=TABLEUPDATE(1,.t.,lcTablaActualizar)
						IF llRet
							llRet=TABLEUPDATE(1,.t.,"sisloguactu")
						ENDIF 
					ENDIF 
				ELSE
					IF lnCtrlSql03=<1 AND lnCantRegActu>0
						AERROR(laMisErrores)
						oResActuRem.mensaje="No fue Posible Cambiar la Fecha de Actualizacion en los Registros Remotos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF
					llRet=.f.
				ENDIF 

				**** aqui confirmamos los datos ya sea sql o nativo
				IF lnTransaccionIniciada=1
					IF llRet
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'COMMIT',"")
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'COMMIT','',lnTipoconeccion)
						lcUnionMensaje=""
						IF lnCantRegActuIns<>0
							oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Reg. Insertados "
							lcUnionMensaje=" y "
						ENDIF
						IF lnCantRegActuAct<>0
							oResActuRem.mensaje=oResActuRem.mensaje+lcUnionMensaje+ALLTRIM(STR(lnCantRegActu))+" Reg. Actualizados "
						ENDIF
						IF lnCantRegActu<>0
							oResActuRem.mensaje=oResActuRem.mensaje+" de "+UPPER(lcTablaActualizar)+" !!!"
						ENDIF 
						
						oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Registros Actualizados de "+UPPER(lcTablaActualizar)+" !!!"
						oResActuRem.iderror=0
					ELSE
						AERROR(laMisErrores)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'ROLLBACK')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'ROLLBACK','',lnTipoconeccion)

						oResActuRem.mensaje="Error al Actualizar los Datos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF 
				ENDIF 

				***** luego de terminar la transacccion
				IF USED(lcTablaActualizar)
					IF pnTipoConeccion=1	&&& usando coneccion Nativa
						CURSORSETPROP("Buffering",1,lcTablaActualizar)
						CURSORSETPROP("Buffering",1,"sisloguactu")
					ENDIF 
				ENDIF 

			CASE lcTablaActualizar=="ctbtipopar"
				lnCtrlConec02=_conecta(pcDB)
				
				ltFecHoraActuAnterior=_obtenerFechaHoraUltimaActualizacion(lnCtrlConec02,lcTablaActualizar)	&&& obtiene la fecha y hora de la actualizacion anterior
				lcComando01="SELECT * FROM "+lcTablaActualizar+" WHERE fecActu>'"+_ConvertirToFechaHoraSQL(ltFecHoraActuAnterior)+"' and nodo<>'"+pcnodo+"' "

				lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,lcComando01,"c_cur_"+lcTablaActualizar+lcTiempoActu,lnTipoconeccion)

				IF lnCtrlSql01>0 &&& hay registro a actualizar y ya se conecto al sever remoto
					lnCantRegActu=RECCOUNT("c_cur_"+lcTablaActualizar+lcTiempoActu)
					
					IF lnCantRegActu>0	&&&& no hay registros a actualizar
						***** iniciando transaccion y buffering
						IF pnTipoConeccion=1	&&& usando coneccion Nativa local
							IF !USED(lcTablaActualizar)
								USE pcsysdir+pcDB+"\"+lcTablaActualizar IN 0 SHARED AGAIN 
							ENDIF 
							CURSORSETPROP("Buffering",5,lcTablaActualizar)
							CURSORSETPROP("Buffering",5,"sisloguactu")
						ENDIF 
						SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'BEGIN')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'BEGIN','',lnTipoconeccion)
						lnTransaccionIniciada=1
						**************************************************************************************************************
						***** le cambiomos la fecha de actualizacion a los registros Remotos para evitar que alguien mas los modifique
						IF pnTipoConeccion=1
							lcComando03=;
									"UPDATE sisloguactu "+;
										"set fecultactu=CTOT('"+ttoc(ltFecHoraActualizacion)+"') "+;
										"WHERE tabla='"+UPPER(lcTablaActualizar)+" '"
						ELSE
							lcComando03=;
									"UPDATE sisloguactu "+;
										"set fecultactu='"+_ConvertirToFechaHoraSQL(ltFecHoraActualizacion)+"' "+;
										"WHERE tabla='"+UPPER(lcTablaActualizar)+" '"
						ENDIF 
						**** cambiando fecha a registros locales
						lnCtrlSql03=miSQLEXEC(lnCtrlConec02,lcComando03,"")
						**************************************************************************************************************
						****** enviamos los registros remotos al local
						IF pnTipoconeccion=1
							****** insertando registros nuevos
							lcComando02=;
										"INSERT INTO "+lcTablaActualizar+" (idtipopar,codtpar,tipopar,status,fecalta,fecmod,fecactu,nodo,eliminado,iduser,pcuser) "+;
											"select  idtipopar,codtpar,tipopar,status,fecalta,fecmod,fecactu,nodo,eliminado,iduser,pcuser "+;
												" from c_cur_"+lcTablaActualizar+lcTiempoActu+" "+; 
												" where idtipopar not in (select idtipopar from "+lcTablaActualizar+" where nodo<>'"+pcnodo+"') "
							lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"")
							lnCantRegActuIns=_tally
							IF lnCtrlSql02>1		&&&& si pudo insertar registros nuevo ahora actualizar los existentes
								lcComando02=;
									"update "+lcTablaActualizar+" "+;
										"set "+lcTablaActualizar+".codtpar=a.codtpar,"+;
											lcTablaActualizar+".tipopar=a.tipopar,"+;
											lcTablaActualizar+".status=a.status,"+;
											lcTablaActualizar+".fecalta=a.fecalta,"+;
											lcTablaActualizar+".fecmod=a.fecmod,"+;
											lcTablaActualizar+".fecactu=a.fecactu,"+;
											lcTablaActualizar+".nodo=a.nodo,"+;
											lcTablaActualizar+".eliminado=a.eliminado,"+;
											lcTablaActualizar+".iduser=a.iduser,"+;
											lcTablaActualizar+".pcuser=a.pcuser "+;
									"from c_cur_"+lcTablaActualizar+lcTiempoActu+" a where a.idtipopar="+lcTablaActualizar+".idtipopar "
								lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"")
								lnCantRegActuAct=_tally
							ENDIF 
							
						ELSE 
							lcComando02=;
										"INSERT INTO "+lcTablaActualizar+" (idtipopar,codtpar,tipopar,status,fecalta,fecmod,fecactu,nodo,eliminado,iduser,pcuser) "+;
											"VALUES "
										lcComaUnion=""
										SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
										SCAN FOR idtipopar<>0 
											lcComando01=lcComando01+lcComaUnion;
												+"("+ALLTRIM(STR(idtipopar))+","+;
												"'"+ALLTRIM(_sincomillias(codtpar))+"',"+;
												"'"+ALLTRIM(_sincomillias(tipopar))+"',"+;
												""+ALLTRIM(STR(status))+","+;
												"'"+_ConvertirToFechaHoraSQL(fecalta)+"',"+;
												"'"+_ConvertirToFechaHoraSQL(fecmod)+"',"+;
												"'"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"',"+;
												"'"+ALLTRIM(nodo)+"',"+;
												""+ALLTRIM(STR(eliminado))+","+;
												""+ALLTRIM(STR(iduser))+","+;
												"'"+ALLTRIM(pcuser)+"' "+;
												")"
											lcComaUnion=","
										ENDSCAN 
											lcComando01=lcComando01+" ON DUPLICATE KEY UPDATE "+;
												"codtpar = VALUES(codtpar),"+;
												"tipopar = VALUES(tipopar),"+;
												"status = VALUES(status),"+;
												"fecalta = VALUES(fecalta),"+;
												"fecmod = VALUES(fecmod),"+;
												"fecactu= VALUES(fecactu),"+;
												"nodo = VALUES(nodo),"+;
												"eliminado = VALUES(eliminado),"+;
												"iduser = VALUES(iduser),"+;
												"pcuser = VALUES(pcuser)"
							lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"c_Cur_Remoto"+lcTablaActualizar,lnTipoconeccion)
						ENDIF 

						IF lnCtrlSql02<1
							oResActuRem.mensaje="Error al Actualizar los Registros en el Servidor Local "
							oResActuRem.iderror=1
						ENDIF 
					ELSE
						***** se cambian los controles de los comandos sql ejecutados a todos correctos por que no hay error... simplemente no hay registros
						lnCtrlSql01=1	
						lnCtrlSql02=1
						lnCtrlSql03=1
						oResActuRem.mensaje="No hay Registros para Bajar en "+UPPER(lcTablaActualizar)
						oResActuRem.iderror=0
					ENDIF 
				ELSE
					AERROR(laMisErrores)
					oResActuRem.iderror=1
					oResActuRem.mensaje="Error en la Coneccion Remota: "+laMisErrores(2)
				ENDIF 	

				********** aqui confirmamos los datos locales si se ejecuto todo bien y si hay registros a actualizar
				IF lnCtrlSql01>0 AND lnCtrlSql02>0 AND lnCtrlSql03>0 AND lnCantRegActu>0
					******* confirmando datos locales
					IF pnTipoConeccion=1	&&& usando coneccion Nativa datos locales
						llRet=TABLEUPDATE(1,.t.,lcTablaActualizar)
						IF llRet
							llRet=TABLEUPDATE(1,.t.,"sisloguactu")
						ENDIF 
					ENDIF 
				ELSE
					IF lnCtrlSql03=<1 AND lnCantRegActu>0
						AERROR(laMisErrores)
						oResActuRem.mensaje="No fue Posible Cambiar la Fecha de Actualizacion en los Registros Remotos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF
					llRet=.f.
				ENDIF 

				**** aqui confirmamos los datos ya sea sql o nativo
				IF lnTransaccionIniciada=1
					IF llRet
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'COMMIT',"")
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'COMMIT','',lnTipoconeccion)
						lcUnionMensaje=""
						IF lnCantRegActuIns<>0
							oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Reg. Insertados "
							lcUnionMensaje=" y "
						ENDIF
						IF lnCantRegActuAct<>0
							oResActuRem.mensaje=oResActuRem.mensaje+lcUnionMensaje+ALLTRIM(STR(lnCantRegActu))+" Reg. Actualizados "
						ENDIF
						IF lnCantRegActu<>0
							oResActuRem.mensaje=oResActuRem.mensaje+" de "+UPPER(lcTablaActualizar)+" !!!"
						ENDIF 
						
						oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Registros Actualizados de "+UPPER(lcTablaActualizar)+" !!!"
						oResActuRem.iderror=0
					ELSE
						AERROR(laMisErrores)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'ROLLBACK')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'ROLLBACK','',lnTipoconeccion)

						oResActuRem.mensaje="Error al Actualizar los Datos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF 
				ENDIF 

				***** luego de terminar la transacccion
				IF USED(lcTablaActualizar)
					IF pnTipoConeccion=1	&&& usando coneccion Nativa
						CURSORSETPROP("Buffering",1,lcTablaActualizar)
						CURSORSETPROP("Buffering",1,"sisloguactu")
					ENDIF 
				ENDIF 


			CASE lcTablaActualizar=="ctbnumpar"
				lnCtrlConec02=_conecta(pcDB)
				
				ltFecHoraActuAnterior=_obtenerFechaHoraUltimaActualizacion(lnCtrlConec02,lcTablaActualizar)	&&& obtiene la fecha y hora de la actualizacion anterior
				lcComando01="SELECT * FROM "+lcTablaActualizar+" WHERE fecActu>'"+_ConvertirToFechaHoraSQL(ltFecHoraActuAnterior)+"' and nodo<>'"+pcnodo+"' "

				lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,lcComando01,"c_cur_"+lcTablaActualizar+lcTiempoActu,lnTipoconeccion)

				IF lnCtrlSql01>0 &&& hay registro a actualizar y ya se conecto al sever remoto
					lnCantRegActu=RECCOUNT("c_cur_"+lcTablaActualizar+lcTiempoActu)
					
					IF lnCantRegActu>0	&&&& no hay registros a actualizar
						***** iniciando transaccion y buffering
						IF pnTipoConeccion=1	&&& usando coneccion Nativa local
							IF !USED(lcTablaActualizar)
								USE pcsysdir+pcDB+"\"+lcTablaActualizar IN 0 SHARED AGAIN 
							ENDIF 
							CURSORSETPROP("Buffering",5,lcTablaActualizar)
							CURSORSETPROP("Buffering",5,"sisloguactu")
						ENDIF 
						SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'BEGIN')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'BEGIN','',lnTipoconeccion)
						lnTransaccionIniciada=1
						**************************************************************************************************************
						***** le cambiomos la fecha de actualizacion a los registros Remotos para evitar que alguien mas los modifique
						IF pnTipoConeccion=1
							lcComando03=;
									"UPDATE sisloguactu "+;
										"set fecultactu=CTOT('"+ttoc(ltFecHoraActualizacion)+"') "+;
										"WHERE tabla='"+UPPER(lcTablaActualizar)+" '"
						ELSE
							lcComando03=;
									"UPDATE sisloguactu "+;
										"set fecultactu='"+_ConvertirToFechaHoraSQL(ltFecHoraActualizacion)+"' "+;
										"WHERE tabla='"+UPPER(lcTablaActualizar)+" '"
						ENDIF 
						**** cambiando fecha a registros locales
						lnCtrlSql03=miSQLEXEC(lnCtrlConec02,lcComando03,"")
						**************************************************************************************************************
						****** enviamos los registros remotos al local
						IF pnTipoconeccion=1
							****** insertando registros nuevos
							lcComando02=;
										"INSERT INTO "+lcTablaActualizar+" (idnumpar,numero,periodo,idtipopartida,tipodetresu,fecalta,fecmod,fecactu,nodo,iduser,pcuser) "+;
											"select  idnumpar,numero,periodo,idtipopartida,tipodetresu,fecalta,fecmod,fecactu,nodo,iduser,pcuser "+;
												" from c_cur_"+lcTablaActualizar+lcTiempoActu+" "+; 
												" where idnumpar not in (select idnumpar from "+lcTablaActualizar+" where nodo<>'"+pcnodo+"') "
							lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"")
							lnCantRegActuIns=_tally
							IF lnCtrlSql02>1		&&&& si pudo insertar registros nuevo ahora actualizar los existentes
								lcComando02=;
									"update "+lcTablaActualizar+" "+;
										"set "+lcTablaActualizar+".numero=a.numero,"+;
											lcTablaActualizar+".periodo=a.periodo,"+;
											lcTablaActualizar+".idtipopartida=a.idtipopartida,"+;
											lcTablaActualizar+".tipodetresu=a.tipodetresu,"+;
											lcTablaActualizar+".fecalta=a.fecalta,"+;
											lcTablaActualizar+".fecmod=a.fecmod,"+;
											lcTablaActualizar+".fecactu=a.fecactu,"+;
											lcTablaActualizar+".nodo=a.nodo,"+;
											lcTablaActualizar+".iduser=a.iduser,"+;
											lcTablaActualizar+".pcuser=a.pcuser "+;
									"from c_cur_"+lcTablaActualizar+lcTiempoActu+" a where a.idnumpar="+lcTablaActualizar+".idnumpar "
								lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"")
								lnCantRegActuAct=_tally
							ENDIF 
							
						ELSE 
							lcComando02=;
										"INSERT INTO "+lcTablaActualizar+" (idnumpar,numero,periodo,idtipopartida,tipodetresu,fecalta,fecmod,fecactu,nodo,iduser,pcuser) "+;
											"VALUES "
										lcComaUnion=""
										SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
										SCAN FOR idnumpar<>0 
											lcComando01=lcComando01+lcComaUnion;
												+"("+ALLTRIM(STR(idnumpar))+","+;
												""+ALLTRIM(STR(numero))+","+;
												"'"+ALLTRIM(periodo)+"',"+;
												""+ALLTRIM(STR(idtipopartida))+","+;
												""+ALLTRIM(STR(tipodetresu))+","+;
												"'"+_ConvertirToFechaHoraSQL(fecalta)+"',"+;
												"'"+_ConvertirToFechaHoraSQL(fecmod)+"',"+;
												"'"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"',"+;
												"'"+ALLTRIM(nodo)+"',"+;
												""+ALLTRIM(STR(iduser))+","+;
												"'"+ALLTRIM(pcuser)+"' "+;
												")"
											lcComaUnion=","
										ENDSCAN 
											lcComando01=lcComando01+" ON DUPLICATE KEY UPDATE "+;
												"numero = VALUES(numero),"+;
												"periodo = VALUES(periodo),"+;
												"idtipopartida = VALUES(idtipopartida),"+;
												"tipodetresu = VALUES(tipodetresu),"+;
												"fecalta = VALUES(fecalta),"+;
												"fecmod = VALUES(fecmod),"+;
												"fecactu= VALUES(fecactu),"+;
												"nodo = VALUES(nodo),"+;
												"iduser = VALUES(iduser),"+;
												"pcuser = VALUES(pcuser)"
							lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"c_Cur_Remoto"+lcTablaActualizar,lnTipoconeccion)
						ENDIF 

						IF lnCtrlSql02<1
							oResActuRem.mensaje="Error al Actualizar los Registros en el Servidor Local "
							oResActuRem.iderror=1
						ENDIF 
					ELSE
						***** se cambian los controles de los comandos sql ejecutados a todos correctos por que no hay error... simplemente no hay registros
						lnCtrlSql01=1	
						lnCtrlSql02=1
						lnCtrlSql03=1
						oResActuRem.mensaje="No hay Registros para Bajar en "+UPPER(lcTablaActualizar)
						oResActuRem.iderror=0
					ENDIF 
				ELSE
					AERROR(laMisErrores)
					oResActuRem.iderror=1
					oResActuRem.mensaje="Error en la Coneccion Remota: "+laMisErrores(2)
				ENDIF 	

				********** aqui confirmamos los datos locales si se ejecuto todo bien y si hay registros a actualizar
				IF lnCtrlSql01>0 AND lnCtrlSql02>0 AND lnCtrlSql03>0 AND lnCantRegActu>0
					******* confirmando datos locales
					IF pnTipoConeccion=1	&&& usando coneccion Nativa datos locales
						llRet=TABLEUPDATE(1,.t.,lcTablaActualizar)
						IF llRet
							llRet=TABLEUPDATE(1,.t.,"sisloguactu")
						ENDIF 
					ENDIF 
				ELSE
					IF lnCtrlSql03=<1 AND lnCantRegActu>0
						AERROR(laMisErrores)
						oResActuRem.mensaje="No fue Posible Cambiar la Fecha de Actualizacion en los Registros Remotos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF
					llRet=.f.
				ENDIF 

				**** aqui confirmamos los datos ya sea sql o nativo
				IF lnTransaccionIniciada=1
					IF llRet
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'COMMIT',"")
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'COMMIT','',lnTipoconeccion)
						lcUnionMensaje=""
						IF lnCantRegActuIns<>0
							oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Reg. Insertados "
							lcUnionMensaje=" y "
						ENDIF
						IF lnCantRegActuAct<>0
							oResActuRem.mensaje=oResActuRem.mensaje+lcUnionMensaje+ALLTRIM(STR(lnCantRegActu))+" Reg. Actualizados "
						ENDIF
						IF lnCantRegActu<>0
							oResActuRem.mensaje=oResActuRem.mensaje+" de "+UPPER(lcTablaActualizar)+" !!!"
						ENDIF 
						
						oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Registros Actualizados de "+UPPER(lcTablaActualizar)+" !!!"
						oResActuRem.iderror=0
					ELSE
						AERROR(laMisErrores)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'ROLLBACK')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'ROLLBACK','',lnTipoconeccion)

						oResActuRem.mensaje="Error al Actualizar los Datos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF 
				ENDIF 

				***** luego de terminar la transacccion
				IF USED(lcTablaActualizar)
					IF pnTipoConeccion=1	&&& usando coneccion Nativa
						CURSORSETPROP("Buffering",1,lcTablaActualizar)
						CURSORSETPROP("Buffering",1,"sisloguactu")
					ENDIF 
				ENDIF 

			CASE lcTablaActualizar=="ctbpartidas"
				lnCtrlConec02=_conecta(pcDB)
				
				ltFecHoraActuAnterior=_obtenerFechaHoraUltimaActualizacion(lnCtrlConec02,lcTablaActualizar)	&&& obtiene la fecha y hora de la actualizacion anterior
				lcComando01="SELECT * FROM "+lcTablaActualizar+" WHERE fecActu>'"+_ConvertirToFechaHoraSQL(ltFecHoraActuAnterior)+"' and nodo<>'"+pcnodo+"' "

				lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,lcComando01,"c_cur_"+lcTablaActualizar+lcTiempoActu,lnTipoconeccion)

				IF lnCtrlSql01>0 &&& hay registro a actualizar y ya se conecto al sever remoto
					lnCantRegActu=RECCOUNT("c_cur_"+lcTablaActualizar+lcTiempoActu)
					
					IF lnCantRegActu>0	&&&& no hay registros a actualizar
						***** iniciando transaccion y buffering
						IF pnTipoConeccion=1	&&& usando coneccion Nativa local
							IF !USED(lcTablaActualizar)
								USE pcsysdir+pcDB+"\"+lcTablaActualizar IN 0 SHARED AGAIN 
							ENDIF 
							CURSORSETPROP("Buffering",5,lcTablaActualizar)
							CURSORSETPROP("Buffering",5,"sisloguactu")
						ENDIF 
						SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'BEGIN')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'BEGIN','',lnTipoconeccion)
						lnTransaccionIniciada=1
						**************************************************************************************************************
						***** le cambiomos la fecha de actualizacion a los registros Remotos para evitar que alguien mas los modifique
						IF pnTipoConeccion=1
							lcComando03=;
									"UPDATE sisloguactu "+;
										"set fecultactu=CTOT('"+ttoc(ltFecHoraActualizacion)+"') "+;
										"WHERE tabla='"+UPPER(lcTablaActualizar)+" '"
						ELSE
							lcComando03=;
									"UPDATE sisloguactu "+;
										"set fecultactu='"+_ConvertirToFechaHoraSQL(ltFecHoraActualizacion)+"' "+;
										"WHERE tabla='"+UPPER(lcTablaActualizar)+" '"
						ENDIF 
						**** cambiando fecha a registros locales
						lnCtrlSql03=miSQLEXEC(lnCtrlConec02,lcComando03,"")
						**************************************************************************************************************
						****** enviamos los registros remotos al local
						IF pnTipoconeccion=1
							****** insertando registros nuevos
							lcComando02=;
										"INSERT INTO "+lcTablaActualizar+" (idpartida,idtipopar,fechapartida,numeropartida,concepto,idsucursal,idctrocosto,monto,periodo,origen,impreso,fecalta,fecmod,fecactu,nodo,eliminado,iduser,pcuser) "+;
											"select  idpartida,idtipopar,fechapartida,numeropartida,concepto,idsucursal,idctrocosto,monto,periodo,origen,impreso,fecalta,fecmod,fecactu,nodo,eliminado,iduser,pcuser "+;
												" from c_cur_"+lcTablaActualizar+lcTiempoActu+" "+; 
												" where idpartida not in (select idpartida from "+lcTablaActualizar+" where nodo<>'"+pcnodo+"') "
							lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"")
							lnCantRegActuIns=_tally
							IF lnCtrlSql02>1		&&&& si pudo insertar registros nuevo ahora actualizar los existentes
								lcComando02=;
									"update "+lcTablaActualizar+" "+;
										"set "+lcTablaActualizar+".idpartida=a.idpartida,"+;
											lcTablaActualizar+".idtipopar=a.idtipopar,"+;
											lcTablaActualizar+".fechapartida=a.fechapartida,"+;
											lcTablaActualizar+".numeropartida=a.numeropartida,"+;
											lcTablaActualizar+".concepto=a.concepto,"+;
											lcTablaActualizar+".idsucursal=a.idsucursal,"+;
											lcTablaActualizar+".idctrocosto=a.idctrocosto,"+;
											lcTablaActualizar+".monto=a.monto,"+;
											lcTablaActualizar+".periodo=a.periodo,"+;
											lcTablaActualizar+".origen=a.origen,"+;
											lcTablaActualizar+".impreso=a.impreso,"+;
											lcTablaActualizar+".fecalta=a.fecalta,"+;
											lcTablaActualizar+".fecmod=a.fecmod,"+;
											lcTablaActualizar+".fecactu=a.fecactu,"+;
											lcTablaActualizar+".nodo=a.nodo,"+;
											lcTablaActualizar+".eliminado=a.eliminado,"+;
											lcTablaActualizar+".iduser=a.iduser,"+;
											lcTablaActualizar+".pcuser=a.pcuser "+;
									"from c_cur_"+lcTablaActualizar+lcTiempoActu+" a where a.idpartida="+lcTablaActualizar+".idpartida "
								lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"")
								lnCantRegActuAct=_tally
							ENDIF 
							
						ELSE 
							lcComando02=;
										"INSERT INTO "+lcTablaActualizar+" (idpartida,idtipopar,fechapartida,numeropartida,concepto,idsucursal,idctrocosto,monto,periodo,origen,impreso,fecalta,fecmod,fecactu,nodo,eliminado,iduser,pcuser) "+;
											"VALUES "
										lcComaUnion=""
										SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
										SCAN FOR idpartida<>0 
											lcComando01=lcComando01+lcComaUnion;
												+"("+ALLTRIM(STR(idpartida))+","+;
												""+ALLTRIM(STR(idtipopar))+","+;
												"'"+_ConvertirToFechaSQL(fechapartida)+"',"+;
												"'"+ALLTRIM(numeropartida)+"',"+;
												"'"+ALLTRIM(_sincomillias(concepto))+"',"+;
												""+ALLTRIM(STR(idsucursal))+","+;
												""+ALLTRIM(STR(idctrocosto))+","+;
												""+ALLTRIM(STR(monto,16,6))+","+;
												"'"+ALLTRIM(periodo)+"',"+;
												"'"+ALLTRIM(origen)+"',"+;
												""+ALLTRIM(STR(impreso))+","+;
												"'"+_ConvertirToFechaHoraSQL(fecalta)+"',"+;
												"'"+_ConvertirToFechaHoraSQL(fecmod)+"',"+;
												"'"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"',"+;
												"'"+ALLTRIM(nodo)+"',"+;
												""+ALLTRIM(STR(eliminado))+","+;
												""+ALLTRIM(STR(iduser))+","+;
												"'"+ALLTRIM(pcuser)+"' "+;
												")"
											lcComaUnion=","
										ENDSCAN 
											lcComando01=lcComando01+" ON DUPLICATE KEY UPDATE "+;
												"idtipopar = VALUES(idtipopar),"+;
												"fechapartida = VALUES(fechapartida),"+;
												"numeropartida = VALUES(numeropartida),"+;
												"concepto = VALUES(concepto),"+;
												"idsucursal = VALUES(idsucursal),"+;
												"idctrocosto = VALUES(idctrocosto),"+;
												"monto = VALUES(monto),"+;
												"periodo = VALUES(periodo),"+;
												"origen = VALUES(origen),"+;
												"impreso = VALUES(impreso),"+;
												"fecalta = VALUES(fecalta),"+;
												"fecmod = VALUES(fecmod),"+;
												"fecactu= VALUES(fecactu),"+;
												"nodo = VALUES(nodo),"+;
												"eliminado = VALUES(eliminado),"+;
												"iduser = VALUES(iduser),"+;
												"pcuser = VALUES(pcuser)"
							lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"c_Cur_Remoto"+lcTablaActualizar,lnTipoconeccion)
						ENDIF 

						IF lnCtrlSql02<1
							oResActuRem.mensaje="Error al Actualizar los Registros en el Servidor Local "
							oResActuRem.iderror=1
						ENDIF 
					ELSE
						***** se cambian los controles de los comandos sql ejecutados a todos correctos por que no hay error... simplemente no hay registros
						lnCtrlSql01=1	
						lnCtrlSql02=1
						lnCtrlSql03=1
						oResActuRem.mensaje="No hay Registros para Bajar en "+UPPER(lcTablaActualizar)
						oResActuRem.iderror=0
					ENDIF 
				ELSE
					AERROR(laMisErrores)
					oResActuRem.iderror=1
					oResActuRem.mensaje="Error en la Coneccion Remota: "+laMisErrores(2)
				ENDIF 	

				********** aqui confirmamos los datos locales si se ejecuto todo bien y si hay registros a actualizar
				IF lnCtrlSql01>0 AND lnCtrlSql02>0 AND lnCtrlSql03>0 AND lnCantRegActu>0
					******* confirmando datos locales
					IF pnTipoConeccion=1	&&& usando coneccion Nativa datos locales
						llRet=TABLEUPDATE(1,.t.,lcTablaActualizar)
						IF llRet
							llRet=TABLEUPDATE(1,.t.,"sisloguactu")
						ENDIF 
					ENDIF 
				ELSE
					IF lnCtrlSql03=<1 AND lnCantRegActu>0
						AERROR(laMisErrores)
						oResActuRem.mensaje="No fue Posible Cambiar la Fecha de Actualizacion en los Registros Remotos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF
					llRet=.f.
				ENDIF 

				**** aqui confirmamos los datos ya sea sql o nativo
				IF lnTransaccionIniciada=1
					IF llRet
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'COMMIT',"")
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'COMMIT','',lnTipoconeccion)
						lcUnionMensaje=""
						IF lnCantRegActuIns<>0
							oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Reg. Insertados "
							lcUnionMensaje=" y "
						ENDIF
						IF lnCantRegActuAct<>0
							oResActuRem.mensaje=oResActuRem.mensaje+lcUnionMensaje+ALLTRIM(STR(lnCantRegActu))+" Reg. Actualizados "
						ENDIF
						IF lnCantRegActu<>0
							oResActuRem.mensaje=oResActuRem.mensaje+" de "+UPPER(lcTablaActualizar)+" !!!"
						ENDIF 
						
						oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Registros Actualizados de "+UPPER(lcTablaActualizar)+" !!!"
						oResActuRem.iderror=0
					ELSE
						AERROR(laMisErrores)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'ROLLBACK')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'ROLLBACK','',lnTipoconeccion)

						oResActuRem.mensaje="Error al Actualizar los Datos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF 
				ENDIF 

				***** luego de terminar la transacccion
				IF USED(lcTablaActualizar)
					IF pnTipoConeccion=1	&&& usando coneccion Nativa
						CURSORSETPROP("Buffering",1,lcTablaActualizar)
						CURSORSETPROP("Buffering",1,"sisloguactu")
					ENDIF 
				ENDIF 


			CASE lcTablaActualizar=="ctbpartidasdeta"
				lnCtrlConec02=_conecta(pcDB)
				
				ltFecHoraActuAnterior=_obtenerFechaHoraUltimaActualizacion(lnCtrlConec02,lcTablaActualizar)	&&& obtiene la fecha y hora de la actualizacion anterior
				lcComando01="SELECT * FROM "+lcTablaActualizar+" WHERE fecActu>'"+_ConvertirToFechaHoraSQL(ltFecHoraActuAnterior)+"' and nodo<>'"+pcnodo+"' "

				lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,lcComando01,"c_cur_"+lcTablaActualizar+lcTiempoActu,lnTipoconeccion)

				IF lnCtrlSql01>0 &&& hay registro a actualizar y ya se conecto al sever remoto
					lnCantRegActu=RECCOUNT("c_cur_"+lcTablaActualizar+lcTiempoActu)
					
					IF lnCantRegActu>0	&&&& no hay registros a actualizar
						***** iniciando transaccion y buffering
						IF pnTipoConeccion=1	&&& usando coneccion Nativa local
							IF !USED(lcTablaActualizar)
								USE pcsysdir+pcDB+"\"+lcTablaActualizar IN 0 SHARED AGAIN 
							ENDIF 
							CURSORSETPROP("Buffering",5,lcTablaActualizar)
							CURSORSETPROP("Buffering",5,"sisloguactu")
						ENDIF 
						SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'BEGIN')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'BEGIN','',lnTipoconeccion)
						lnTransaccionIniciada=1
						**************************************************************************************************************
						***** le cambiomos la fecha de actualizacion a los registros Remotos para evitar que alguien mas los modifique
						IF pnTipoConeccion=1
							lcComando03=;
									"UPDATE sisloguactu "+;
										"set fecultactu=CTOT('"+ttoc(ltFecHoraActualizacion)+"') "+;
										"WHERE tabla='"+UPPER(lcTablaActualizar)+" '"
						ELSE
							lcComando03=;
									"UPDATE sisloguactu "+;
										"set fecultactu='"+_ConvertirToFechaHoraSQL(ltFecHoraActualizacion)+"' "+;
										"WHERE tabla='"+UPPER(lcTablaActualizar)+" '"
						ENDIF 
						**** cambiando fecha a registros locales
						lnCtrlSql03=miSQLEXEC(lnCtrlConec02,lcComando03,"")
						**************************************************************************************************************
						****** enviamos los registros remotos al local
						IF pnTipoconeccion=1
							****** insertando registros nuevos
							lcComando02=;
										"INSERT INTO "+lcTablaActualizar+" (idpartidad,idpartida,idcuenta,conceptod,idsucursal,idctrocosto,debe,haber,periodo,origen,idorigen,fecalta,fecmod,fecactu,nodo,eliminado,iduser,pcuser) "+;
											"select  idpartidad,idpartida,idcuenta,conceptod,idsucursal,idctrocosto,debe,haber,periodo,origen,idorigen,fecalta,fecmod,fecactu,nodo,eliminado,iduser,pcuser "+;
												" from c_cur_"+lcTablaActualizar+lcTiempoActu+" "+; 
												" where idpartidad not in (select idpartidad from "+lcTablaActualizar+" where nodo<>'"+pcnodo+"') "
							lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"")
							lnCantRegActuIns=_tally
							
							IF lnCtrlSql02>1		&&&& si pudo insertar registros nuevo ahora actualizar los existentes
								lcComando02=;
									"update "+lcTablaActualizar+" "+;
										"set "+lcTablaActualizar+".idpartidad=a.idpartidad,"+;
											lcTablaActualizar+".idpartida=a.idpartida,"+;
											lcTablaActualizar+".idcuenta=a.idcuenta,"+;
											lcTablaActualizar+".conceptod=a.conceptod,"+;
											lcTablaActualizar+".idsucursal=a.idsucursal,"+;
											lcTablaActualizar+".idctrocosto=a.idctrocosto,"+;
											lcTablaActualizar+".debe=a.debe,"+;
											lcTablaActualizar+".haber=a.haber,"+;
											lcTablaActualizar+".periodo=a.periodo,"+;
											lcTablaActualizar+".origen=a.origen,"+;
											lcTablaActualizar+".idorigen=a.idorigen,"+;
											lcTablaActualizar+".fecalta=a.fecalta,"+;
											lcTablaActualizar+".fecmod=a.fecmod,"+;
											lcTablaActualizar+".fecactu=a.fecactu,"+;
											lcTablaActualizar+".nodo=a.nodo,"+;
											lcTablaActualizar+".eliminado=a.eliminado,"+;
											lcTablaActualizar+".iduser=a.iduser,"+;
											lcTablaActualizar+".pcuser=a.pcuser "+;
									"from c_cur_"+lcTablaActualizar+lcTiempoActu+" a where a.idpartidad="+lcTablaActualizar+".idpartidad "
								lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"")
								lnCantRegActuAct=_tally
							ENDIF 
							
						ELSE 
							lcComando02=;
										"INSERT INTO "+lcTablaActualizar+" (idpartidad,idpartida,idcuenta,conceptod,idsucursal,idctrocosto,debe,haber,periodo,origen,idorigen,fecalta,fecmod,fecactu,nodo,eliminado,iduser,pcuser) "+;
											"VALUES "
										lcComaUnion=""
										SELECT ("c_cur_"+lcTablaActualizar+lcTiempoActu)
										SCAN FOR idpartidad<>0 
											lcComando01=lcComando01+lcComaUnion;
												+"("+ALLTRIM(STR(idpartidad))+","+;
												""+ALLTRIM(STR(idpartida))+","+;
												""+ALLTRIM(STR(idcuenta))+","+;
												"'"+ALLTRIM(_sincomillias(conceptod))+"',"+;
												""+ALLTRIM(STR(idsucursal))+","+;
												""+ALLTRIM(STR(idctrocosto))+","+;
												""+ALLTRIM(STR(debe,16,6))+","+;
												""+ALLTRIM(STR(haber,16,6))+","+;
												"'"+ALLTRIM(periodo)+"',"+;
												"'"+ALLTRIM(origen)+"',"+;
												""+ALLTRIM(STR(idorigen))+","+;
												"'"+_ConvertirToFechaHoraSQL(fecalta)+"',"+;
												"'"+_ConvertirToFechaHoraSQL(fecmod)+"',"+;
												"'"+_ConvertirToFechaHoraSQL(lnTiempoIni)+"',"+;
												"'"+ALLTRIM(nodo)+"',"+;
												""+ALLTRIM(STR(eliminado))+","+;
												""+ALLTRIM(STR(iduser))+","+;
												"'"+ALLTRIM(pcuser)+"' "+;
												")"
											lcComaUnion=","
										ENDSCAN 
											lcComando01=lcComando01+" ON DUPLICATE KEY UPDATE "+;
												"idpartidad = VALUES(idpartidad),"+;
												"idpartida = VALUES(idpartida),"+;
												"idcuenta = VALUES(idcuenta),"+;
												"conceptod = VALUES(conceptod),"+;
												"idsucursal = VALUES(idsucursal),"+;
												"idctrocosto = VALUES(idctrocosto),"+;
												"debe = VALUES(debe),"+;
												"haber = VALUES(haber),"+;
												"periodo = VALUES(periodo),"+;
												"origen = VALUES(origen),"+;
												"idorigen = VALUES(idorigen),"+;
												"fecalta = VALUES(fecalta),"+;
												"fecmod = VALUES(fecmod),"+;
												"fecactu= VALUES(fecactu),"+;
												"nodo = VALUES(nodo),"+;
												"eliminado = VALUES(eliminado),"+;
												"iduser = VALUES(iduser),"+;
												"pcuser = VALUES(pcuser)"
							lnCtrlSql02=miSQLEXEC(lnCtrlConec02,lcComando02,"c_Cur_Remoto"+lcTablaActualizar,lnTipoconeccion)
						ENDIF 

						IF lnCtrlSql02<1
							oResActuRem.mensaje="Error al Actualizar los Registros en el Servidor Local "
							oResActuRem.iderror=1
						ENDIF 
					ELSE
						***** se cambian los controles de los comandos sql ejecutados a todos correctos por que no hay error... simplemente no hay registros
						lnCtrlSql01=1	
						lnCtrlSql02=1
						lnCtrlSql03=1
						oResActuRem.mensaje="No hay Registros para Bajar en "+UPPER(lcTablaActualizar)
						oResActuRem.iderror=0
					ENDIF 
				ELSE
					AERROR(laMisErrores)
					oResActuRem.iderror=1
					oResActuRem.mensaje="Error en la Coneccion Remota: "+laMisErrores(2)
				ENDIF 	

				********** aqui confirmamos los datos locales si se ejecuto todo bien y si hay registros a actualizar
				IF lnCtrlSql01>0 AND lnCtrlSql02>0 AND lnCtrlSql03>0 AND lnCantRegActu>0
					******* confirmando datos locales
					IF pnTipoConeccion=1	&&& usando coneccion Nativa datos locales
						llRet=TABLEUPDATE(1,.t.,lcTablaActualizar)
						IF llRet
							llRet=TABLEUPDATE(1,.t.,"sisloguactu")
						ENDIF 
					ENDIF 
				ELSE
					IF lnCtrlSql03=<1 AND lnCantRegActu>0
						AERROR(laMisErrores)
						oResActuRem.mensaje="No fue Posible Cambiar la Fecha de Actualizacion en los Registros Remotos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF
					llRet=.f.
				ENDIF 

				**** aqui confirmamos los datos ya sea sql o nativo
				IF lnTransaccionIniciada=1
					IF llRet
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'COMMIT',"")
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'COMMIT','',lnTipoconeccion)
						lcUnionMensaje=""
						IF lnCantRegActuIns<>0
							oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Reg. Insertados "
							lcUnionMensaje=" y "
						ENDIF
						IF lnCantRegActuAct<>0
							oResActuRem.mensaje=oResActuRem.mensaje+lcUnionMensaje+ALLTRIM(STR(lnCantRegActu))+" Reg. Actualizados "
						ENDIF
						IF lnCantRegActu<>0
							oResActuRem.mensaje=oResActuRem.mensaje+" de "+UPPER(lcTablaActualizar)+" !!!"
						ENDIF 
						
						oResActuRem.mensaje=ALLTRIM(STR(lnCantRegActu))+" Registros Actualizados de "+UPPER(lcTablaActualizar)+" !!!"
						oResActuRem.iderror=0
					ELSE
						AERROR(laMisErrores)
						lnCtrlSql02=miSQLEXEC(lnCtrlConec02,'ROLLBACK')
						lnCtrlSql01=miSQLEXECREMOTO(lnCtrlConec01,'ROLLBACK','',lnTipoconeccion)

						oResActuRem.mensaje="Error al Actualizar los Datos: "+laMisErrores(2)+", "+oResActuRem.mensaje
						oResActuRem.iderror=1
					ENDIF 
				ENDIF 

				***** luego de terminar la transacccion
				IF USED(lcTablaActualizar)
					IF pnTipoConeccion=1	&&& usando coneccion Nativa
						CURSORSETPROP("Buffering",1,lcTablaActualizar)
						CURSORSETPROP("Buffering",1,"sisloguactu")
					ENDIF 
				ENDIF 
				
		ENDCASE 

		IF lnCtrlConec01>0
			=miSQLDISCONNECT(lnCtrlConec01)
		ENDIF 
		IF lnCtrlConec02>0
			=miSQLDISCONNECT(lnCtrlConec02)
		ENDIF 

		IF pnTipoConeccion=1
			IF USED("c_cur_"+lcTablaActualizar+lcTiempoActu)
				USE IN ("c_cur_"+lcTablaActualizar+lcTiempoActu)
			ENDIF 
		endif 

		IF !EMPTY(lcAliasActutmp)
			SELECT (lcAliasActutmp)
		ENDIF 
	ELSE
		AERROR(laMisErrores)
		oResActuRem.mensaje="Error en la Coneccion Remota, "+laMisErrores(2)
		oResActuRem.iderror=1
	ENDIF 
	lnTiempoFin=dateTIME()
	lnSegTrans=pasarSegundosAMinutos(lnTiempoFin-lnTiempoIni)
	oResActuRem.mensaje="("+lnSegTrans+")  "+oResActuRem.mensaje
	RETURN oResActuRem
ENDFUNC 




FUNCTION cargarArchivoExcelPele()
	lcaliaspelexls=ALIAS()
	USE pcsysdir+pcDB+"\invproductos" IN 0 SHARED AGAIN ALIAS pro
	SET DELETED ON 
	llmalos=.f.
	
	SELECT idproducto,codprod3,producto,SPACE(20) as agrupa,SPACE(200) as nomagrupa,;
			unidadmedida,existencia,costoinicial,ultfechacompra,CTOD(' ') as ultfechaventa,;
			SPACE(5) as mieliminado,codprod,eliminado,idagrupador ;
		FROM pro WHERE idproducto=0 into cursor c_pro READWRITE

	lcFileXls=GETFILE("xls")
	IF !EMPTY(lcFileXls)
		APPEND FROM (lcFileXls) TYPE xl5
		GO top
		DELETE NEXT 1
		REPLACE eliminado WITH 1 for !EMPTY(mieliminado)
		DELETE ALL FOR eliminado=1
		REPLACE codprod WITH codprod3 for EMPTY(codprod)
		REPLACE codprod3 WITH '' for codprod3=codprod
		REPLACE codprod WITH UPPER(codprod) all
		REPLACE producto WITH UPPER(producto) all
		REPLACE agrupa WITH UPPER(agrupa) all
		REPLACE nomagrupa WITH UPPER(nomagrupa) all
		
		SELECT * FROM (SELECT codprod,SUM(1) as cuenta ;
						FROM c_pro WHERE eliminado=0 ;
						ORDER BY codprod GROUP BY codprod) as tt ;
				WHERE cuenta>1 INTO CURSOR c_repetidos READWRITE 
		IF !EOF()
			lcdigarepetidos=''
			lccoma=''
			SCAN all
				lcdigarepetidos=lcdigarepetidos+lccoma+ALLTRIM(codprod)
				lccoma=', '
			ENDSCAN 
			MESSAGEBOX(lcdigarepetidos,16,"Codigos Repetidos... no se puede continuar con el proceso")
			SELECT codprod,producto from c_pro WHERE codprod in (SELECT codprod FROM c_repetidos) INTO CURSOR c_repe
			lcfile2=GETFILE("xls","Guardar Archivo","Guardar",1,"Guardar Listado de Codigos Duplicados")
			IF !EMPTY(lcfile2)
				EXPORT TO (lcfile2) TYPE xl5
				SET DEFAULT TO (pcSysDir)

				DECLARE INTEGER ShellExecute IN shell32.dll ; 
				INTEGER hndWin, STRING cAction, STRING cFileName, ; 
				STRING cParams, STRING cDir, INTEGER nShowWin 
				ShellExecute(0,"open",lcfile2,"","",1)
				RELEASE ShellExecute
			ENDIF 
			USE IN c_repe
			llmalos=.t.
		ELSE
			llmalos=.f.
		ENDIF 
		USE IN c_repetidos 

	ENDIF 
	
	IF llmalos=.f. AND !EMPTY(lcFileXls)
		SELECT c_pro
		ldfecaltamia=DATETIME()
		GO top
		IF !EOF()
			USE pcsysdir+pcDB+"\siscata" IN 0 SHARED AGAIN ALIAS cata
			SELECT id,origen,cod,nombre,status,fecalta,fecmod,nodo,iduser,pcuser FROM cata WHERE id<0 INTO CURSOR c_agrTmp READWRITE 
			INSERT INTO c_agrTmp (origen,cod,nombre,status,fecalta,fecmod,nodo,iduser,pcuser) ;
				SELECT 'AGR',agrupa,MAX(nomagrupa) as nomagrupa,1,ldfecaltamia,ldfecaltamia,PCNODO,pnidusuario,SYS(0) ;
					FROM c_pro ORDER BY agrupa GROUP BY agrupa WHERE !EMPTY(agrupa)
			DELETE FROM c_agrTmp WHERE origen+cod in (select UPPER(origen+cod) FROM cata WHERE origen='AGR')
			REPLACE id WITH _SiguienteIdTabla(pcNodo,"MAS") all
			INSERT INTO cata (id,origen,cod,nombre,status,fecalta,fecmod,nodo,iduser,pcuser) SELECT * FROM  c_agrTmp
		
			******* definiendo familias y marcas etc
			SELECT TOP 1 id FROM siscata WHERE origen='MAR' AND status=1 AND eliminado=0 ORDER BY id INTO ARRAY arreglo
			IF _tally<>0
				lnidmar=arreglo
			ELSE
				lnidmar=0
			ENDIF 

			SELECT TOP 1 id FROM siscata WHERE origen='DIV' AND status=1 AND eliminado=0 ORDER BY id INTO ARRAY arreglo
				IF _tally<>0
					lniddiv=arreglo
				ELSE
					lniddiv=0
				ENDIF 
				
			SELECT TOP 1 id FROM siscata WHERE origen='SIS' AND status=1 AND eliminado=0 ORDER BY id INTO ARRAY arreglo
				IF _tally<>0
					lnidsis=arreglo
				ELSE
					lnidsis=0
				ENDIF 
			
			SELECT TOP 1 id FROM siscata WHERE origen='LIN' AND status=1 AND eliminado=0 ORDER BY id INTO ARRAY arreglo
				IF _tally<>0
					lnidlin=arreglo
				ELSE
					lnidlin=0
				ENDIF 
			
			SELECT TOP 1 id FROM siscata WHERE origen='RUB' AND status=1 AND eliminado=0 ORDER BY id INTO ARRAY arreglo
				IF _tally<>0
					lnidrub=arreglo
				ELSE
					lnidrub=0
				ENDIF 
			
			
			**** buscando id del agrupador
			SELECT cata
			SET ORDER TO cod
			SET FILTER TO origen='GRU'
	
			SELECT c_pro
			SET RELATION TO agrupa INTO cata
			REPLACE idagrupador WITH cata.id all
			SET RELATION to
			USE in cata	
			DELETE FROM c_pro WHERE idproducto in (select idproducto FROM pro) OR codprod in (select codprod FROM pro) 
			REPLACE idproducto WITH _SiguienteIdTabla(pcNodo,"MAS") all	 
			INSERT INTO pro (idproducto,codprod,codprod3,producto,descripcion,tipoprod,iddivision,idsistema,;
								idfamilia,idrubro,idagrupador,unidadmedida,idmarca,gravado,idimpuestoiva,;
								pordescuento,costoinicial,juegocompra,precioconiva,preciosiniva,juegoventa,;
								factorpresenta,status,fecalta,fecmod,nodo,iduser,pcuser) ;
					SELECT idproducto,codprod,codprod3,producto,producto,1,lniddiv,lnidsis,lnidlin,lnidrub,;
							idagrupador,unidadmedida,lnidmar,1,1,0,costoinicial,1,0,0,1,1,1,;
							ldfecaltamia,ldfecaltamia,pcnodo,pnidusuario,SYS(0) ;
					FROM c_pro
			lncargados=_tally
					
 			USE pcsysdir+pcDB+"\invexisbodega" IN 0 SHARED AGAIN ALIAS exi
			SELECT idexisbode,idproducto,idbodega,fecalta,fecmod,nodo,iduser,pcuser FROM exi WHERE idexisbode=0 INTO CURSOR c_exi READWRITE 
			INSERT INTO c_exi  ;
			select 0,t1.idproducto,t0.id as idbodega,ldfecaltamia,ldfecaltamia,pcnodo,pnidusuario,SYS(0) ;
				from siscata t0 full join c_pro t1 on t0.eliminado=0 ;
				where t0.origen='BOD' AND t1.idproducto in (SELECT idproducto FROM c_pro) order by t1.idproducto
			SELECT c_exi 
			DELETE from c_exi  WHERE STR(idproducto)+STR(idbodega) IN (select STR(idproducto)+STR(idbodega) from exi )
			REPLACE idexisbode WITH _SiguienteIdTabla(pcNodo,"SIS") all
			INSERT INTO exi (idexisbode,idproducto,idbodega,fecalta,fecmod,nodo,iduser,pcuser) ;
				SELECT idexisbode,idproducto,idbodega,ldfecaltamia,ldfecaltamia,pcnodo,pnidusuario,SYS(0) FROM c_exi
			USE IN c_exi
			USE IN exi
			WAIT WINDOW ALLTRIM(STR(lncargados))+' Archivos Cargos...'
			
		ENDIF 
	ENDIF 
		
	USE IN pro
	USE IN c_pro
	IF !EMPTY(lcaliaspelexls)
		SELECT (lcaliaspelexls)
	ENDIF 
	
ENDFUNC 




FUNCTION cargarArchivoExcelTiffany()		&&& tifani y surtidor
	lcaliaspelexls=ALIAS()
	USE pcsysdir+pcDB+"\invproductos" IN 0 SHARED AGAIN ALIAS pro
	
	SET DELETED ON 
	
	llmalos=.f.
	SELECT idproducto,codprod,producto,precioconiva,;
			SPACE(200) as familia,unidadmedida,SPACE(20) as agrupa,idfamilia,costoinicial,SPACE(20) as codCuenta,SPACE(254) as desmemo1,SPACE(254) as desmemo2,SPACE(254) as desmemo3,SPACE(254) as desmemo4  ;
		FROM pro WHERE idproducto=0 into cursor c_pro READWRITE
	
	lcFileXls=GETFILE("xls")
	IF !EMPTY(lcFileXls)
		APPEND FROM (lcFileXls) TYPE xl5
 
		GO top
		DELETE NEXT 1
		REPLACE producto WITH ALLTRIM(UPPER(producto)) all
		REPLACE familia WITH ALLTRIM(UPPER(familia)) all
		
*!*			REPLACE desmemo1 WITH ALLTRIM(UPPER(NVL(desmemo1,''))) ALL
*!*			REPLACE desmemo2 WITH ALLTRIM(UPPER(NVL(desmemo2,''))) ALL
*!*			REPLACE desmemo3 WITH ALLTRIM(UPPER(NVL(desmemo3,''))) ALL
*!*			REPLACE desmemo4 WITH ALLTRIM(UPPER(NVL(desmemo4,''))) ALL
		
*!*			REPLACE producto WITH _sincomillias2(producto) all
*!*			REPLACE desmemo1 WITH _sincomillias2(desmemo1) ALL
*!*			REPLACE desmemo2 WITH _sincomillias2(desmemo2) ALL
*!*			REPLACE desmemo3 WITH _sincomillias2(desmemo3) ALL
*!*			REPLACE desmemo4 WITH _sincomillias2(desmemo4) ALL
		
		DELETE ALL FOR EMPTY(codprod) 
	
		SELECT * FROM (SELECT codprod,SUM(1) as cuenta ;
						FROM c_pro ;
						ORDER BY codprod GROUP BY codprod) as tt ;
				WHERE cuenta>1 INTO CURSOR c_repetidos READWRITE 
		*DELETE FROM c_pro WHERE idproducto in (select idproducto FROM pro)
		DELETE FROM c_pro WHERE codprod in (select codprod FROM pro)
		DELETE FROM c_repetidos WHERE EMPTY(NVL(codprod,'')) 
 		
		IF !EOF()
			lcdigarepetidos=''
			lccoma=''
			SCAN all
				lcdigarepetidos=lcdigarepetidos+lccoma+ALLTRIM(codprod)
				lccoma=', '
			ENDSCAN 
			MESSAGEBOX(lcdigarepetidos,16,"Codigos Repetidos... no se puede continuar con el proceso")
			SELECT codprod,producto from c_pro WHERE codprod in (SELECT codprod FROM c_repetidos) INTO CURSOR c_repe
			lcfile2=GETFILE("xls","Guardar Archivo","Guardar",1,"Guardar Listado de Codigos Duplicados")
			IF !EMPTY(lcfile2)
				EXPORT TO (lcfile2) TYPE xl5
				SET DEFAULT TO (pcSysDir)

				DECLARE INTEGER ShellExecute IN shell32.dll ; 
				INTEGER hndWin, STRING cAction, STRING cFileName, ; 
				STRING cParams, STRING cDir, INTEGER nShowWin 
				ShellExecute(0,"open",lcfile2,"","",1)
				RELEASE ShellExecute
			ENDIF 
			USE IN c_repe
			llmalos=.t.
		ELSE
			llmalos=.f.
		ENDIF 
		USE IN c_repetidos 

	ENDIF 
	
	IF llmalos=.f. AND !EMPTY(lcFileXls)
		SELECT c_pro
		ldfecaltamia=DATETIME()
		GO top
		IF !EOF()
			USE pcsysdir+pcDB+"\siscata" IN 0 SHARED AGAIN ALIAS cata
			SELECT id,origen,cod,nombre,status,fecalta,fecmod,nodo,iduser,pcuser FROM cata WHERE id<0 INTO CURSOR c_agrTmp READWRITE 
			INSERT INTO c_agrTmp (origen,cod,nombre,status,fecalta,fecmod,nodo,iduser,pcuser) ;
				SELECT 'LIN',SUBSTR(familia,1,20) as agrupa,MAX(familia) as nomagrupa,1,ldfecaltamia,ldfecaltamia,PCNODO,pnidusuario,SYS(0) ;
					FROM c_pro ORDER BY familia GROUP BY familia WHERE !EMPTY(familia)
			REPLACE cod WITH SUBSTR(nombre,1,3)+ALLTRIM(STR(RECNO())) all
			DELETE FROM c_agrTmp WHERE origen+nombre in (select UPPER(origen+nombre) FROM cata WHERE origen='LIN')
			REPLACE id WITH _SiguienteIdTabla(pcNodo,"MAS") all
			INSERT INTO cata (id,origen,cod,nombre,status,fecalta,fecmod,nodo,iduser,pcuser) SELECT * FROM  c_agrTmp
		
			******* definiendo familias y marcas etc
			SELECT TOP 1 id FROM siscata WHERE origen='MAR' AND status=1 AND eliminado=0 ORDER BY id INTO ARRAY arreglo
			IF _tally<>0
				lnidmar=arreglo
			ELSE
				lnidmar=0
			ENDIF 

			SELECT TOP 1 id FROM siscata WHERE origen='DIV' AND status=1 AND eliminado=0 ORDER BY id INTO ARRAY arreglo
				IF _tally<>0
					lniddiv=arreglo
				ELSE
					lniddiv=0
				ENDIF 
			SELECT TOP 1 id FROM siscata WHERE origen='GRU' AND status=1 AND eliminado=0 ORDER BY id INTO ARRAY arreglo
				IF _tally<>0
					lnidAgr=arreglo
				ELSE
					lnidAgr=0
				ENDIF 
			
			SELECT TOP 1 id FROM siscata WHERE origen='SIS' AND status=1 AND eliminado=0 ORDER BY id INTO ARRAY arreglo
				IF _tally<>0
					lnidsis=arreglo
				ELSE
					lnidsis=0
				ENDIF 
					
			SELECT TOP 1 id FROM siscata WHERE origen='RUB' AND status=1 AND eliminado=0 ORDER BY id INTO ARRAY arreglo
				IF _tally<>0
					lnidrub=arreglo
				ELSE
					lnidrub=0
				ENDIF 
			
			
			**** buscando id del agrupador
			SELECT c_pro
			UPDATE c_pro SET idfamilia =id from cata a WHERE familia=a.nombre AND a.origen='LIN'
			USE in cata	
			DELETE FROM c_pro WHERE codprod in (select codprod FROM pro) 
			REPLACE idproducto WITH _SiguienteIdTabla(pcNodo,"MAS") all	 
			INSERT INTO pro (idproducto,codprod,producto,descripcion,tipoprod,iddivision,idsistema,;
								idfamilia,idrubro,idagrupador,unidadmedida,idmarca,gravado,idimpuestoiva,;
								pordescuento,costoinicial,juegocompra,precioconiva,preciosiniva,juegoventa,;
								factorpresenta,status,fecalta,fecmod,nodo,iduser,pcuser) ;
					SELECT idproducto,codprod,producto,producto,1,lniddiv,lnidsis,idfamilia,lnidrub,;
							lnidAgr,unidadmedida,lnidmar,pnIvaGeneral,1,0,costoinicial,1,precioconiva,precioconiva/(pnporiva+1),1,1,1,;
							ldfecaltamia,ldfecaltamia,pcnodo,pnidusuario,SYS(0) ;
					FROM c_pro
					
 			USE pcsysdir+pcDB+"\invexisbodega" IN 0 SHARED AGAIN ALIAS exi
			SELECT idexisbode,idproducto,idbodega,fecalta,fecmod,nodo,iduser,pcuser FROM exi WHERE idexisbode=0 INTO CURSOR c_exi READWRITE 
			INSERT INTO c_exi  ;
			select 0,t1.idproducto,t0.id as idbodega,ldfecaltamia,ldfecaltamia,pcnodo,pnidusuario,SYS(0) ;
				from siscata t0 full join c_pro t1 on t0.eliminado=0 ;
				where t0.origen='BOD' AND t1.idproducto in (SELECT idproducto FROM c_pro) order by t1.idproducto
			SELECT c_exi 
			DELETE from c_exi  WHERE STR(idproducto)+STR(idbodega) IN (select STR(idproducto)+STR(idbodega) from exi )
			REPLACE idexisbode WITH _SiguienteIdTabla(pcNodo,"SIS") all
			INSERT INTO exi (idexisbode,idproducto,idbodega,fecalta,fecmod,nodo,iduser,pcuser) ;
				SELECT idexisbode,idproducto,idbodega,ldfecaltamia,ldfecaltamia,pcnodo,pnidusuario,SYS(0) FROM c_exi
			USE IN c_exi
			USE IN exi
		ENDIF 
	ENDIF 
		
	USE IN pro
	
	***** cargando descripciones largas
	SELECT 0
	USE pcsysdir+pcDB+"\invproductos"  ALIAS pro SHARED AGAIN
	USE pcsysdir+pcDB+"\invproductosmemo"   IN 0  ALIAS me  SHARED AGAIN
	INSERT INTO me (idproducto,descripcion) SELECT idproducto,ALLTRIM(desmemo1) ;
		FROM c_pro WHERE !EMPTY(ALLTRIM(DESMEMO1)) AND idproducto NOT in (select idproducto FROM me)
	UPDATE me SET descripcion =ALLTRIM(descripcion)+' '+ALLTRIM(desmemo2) from c_pro WHERE me.idproducto=c_pro.idproducto AND !EMPTY(NVL(c_pro.desmemo2,''))
	UPDATE me SET descripcion =ALLTRIM(descripcion)+' '+ALLTRIM(desmemo3) from c_pro WHERE me.idproducto=c_pro.idproducto AND !EMPTY(NVL(c_pro.desmemo3,''))
	UPDATE me SET descripcion =ALLTRIM(descripcion)+' '+ALLTRIM(desmemo4) from c_pro WHERE me.idproducto=c_pro.idproducto AND !EMPTY(NVL(c_pro.desmemo4,''))

	INSERT INTO me (idproducto,descripcion) SELECT idproducto,producto FROM pro WHERE idproducto NOT in (select idproducto FROM me)

	
	USE IN pro
	USE IN me
	USE IN c_pro
	
	USE pcsysdir+pcDB+"\cyvventasdeta" ALIAS de IN 0 SHARED AGAIN
	USE pcsysdir+pcDB+"\cyvventasdetamemo" ALIAS me IN 0 SHARED AGAIN
	INSERT INTO me (iddoctod,iddocto,descripcion) SELECT iddoctod,iddocto,producto FROM de WHERE iddoctod NOT in (select iddoctod FROM me)
	USE IN me
	USE IN de

	IF !EMPTY(lcaliaspelexls)
		SELECT (lcaliaspelexls)
	ENDIF 
	
ENDFUNC 


FUNCTION cargarArchivoExcelPreciosBase()		&&& Cargar precios base
	lcaliaspelexls=ALIAS()
	USE pcsysdir+pcDB+"\invproductos" IN 0 SHARED AGAIN ALIAS pro
	USE pcsysdir+pcDB+"\invprodunimed" IN 0 SHARED AGAIN ALIAS Med
	SET DELETED ON 
	
	llmalos=.f.
	
	SELECT codprod,precioconiva ;
		FROM pro WHERE idproducto=0 into cursor c_pro READWRITE

	lcFileXls=GETFILE("xls")
	IF !EMPTY(lcFileXls)
		APPEND FROM (lcFileXls) TYPE xl5
		GO top
		DELETE NEXT 1
	ENDIF 
	
	IF !EMPTY(lcFileXls)
		SELECT c_pro
		ldfecaltamia=DATETIME()
		GO top
		lnDecimalpre=CuantosDecimales(pcmasprecio)
		IF !EOF()
			UPDATE pro SET precioconiva=ROUND(a.precioconiva,lnDecimalpre),preciosiniva=ROUND(a.precioconiva/IIF(pro.gravado=1,pnporiva+1,1),lnDecimalpre) ;
				from c_pro a WHERE pro.codprod=a.codprod 
			
			UPDATE med SET precioconiva=ROUND(a.precioconiva,lnDecimalpre),preciosiniva=ROUND(a.precioconiva/IIF(b.gravado=1,pnporiva+1,1),lnDecimalpre) ;
				from c_pro a inner join pro b on med.idproducto=b.idproducto WHERE med.codprod4=a.codprod 
		ENDIF 
		WAIT WINDOW "Precios Base actualizados..." NOWAIT 
	ENDIF 
		
	USE IN pro
	USE IN c_pro
	IF !EMPTY(lcaliaspelexls)
		SELECT (lcaliaspelexls)
	ENDIF 
	
ENDFUNC 




FUNCTION cargarArchivoExcelRetana()
	lcaliaspelexls=ALIAS()
	USE pcsysdir+pcDB+"\invproductos" IN 0 SHARED AGAIN ALIAS pro
	SET DELETED ON 
	llmalos=.f.
	
	SELECT SPACE(200) as familia,codprod,producto,precioconiva,idproducto;
			,unidadmedida,SPACE(20) as agrupa,idfamilia,SPACE(200) marca,idmarca ;
		FROM pro WHERE idproducto=0 into cursor c_pro READWRITE

	lcFileXls=GETFILE("xls")
	IF !EMPTY(lcFileXls)
		APPEND FROM (lcFileXls) TYPE xl5
		GO top
		DELETE NEXT 1
		REPLACE producto WITH UPPER(ALLTRIM(producto)) all
		REPLACE codprod WITH UPPER(ALLTRIM(codprod)) all
		REPLACE familia WITH UPPER(ALLTRIM(familia)) all
		DELETE ALL FOR EMPTY(codprod)
		SELECT * FROM (SELECT codprod,SUM(1) as cuenta ;
						FROM c_pro ;
						ORDER BY codprod GROUP BY codprod) as tt ;
				WHERE cuenta>1 INTO CURSOR c_repetidos READWRITE 
		IF !EOF()
			lcdigarepetidos=''
			lccoma=''
			SCAN all
				lcdigarepetidos=lcdigarepetidos+lccoma+ALLTRIM(codprod)
				lccoma=', '
			ENDSCAN 
			MESSAGEBOX(lcdigarepetidos,16,"Codigos Repetidos... no se puede continuar con el proceso")
			SELECT codprod,producto from c_pro WHERE codprod in (SELECT codprod FROM c_repetidos) INTO CURSOR c_repe
			lcfile2=GETFILE("xls","Guardar Archivo","Guardar",1,"Guardar Listado de Codigos Duplicados")
			IF !EMPTY(lcfile2)
				EXPORT TO (lcfile2) TYPE xl5
				SET DEFAULT TO (pcSysDir)

				DECLARE INTEGER ShellExecute IN shell32.dll ; 
				INTEGER hndWin, STRING cAction, STRING cFileName, ; 
				STRING cParams, STRING cDir, INTEGER nShowWin 
				ShellExecute(0,"open",lcfile2,"","",1)
				RELEASE ShellExecute
			ENDIF 
			USE IN c_repe
			llmalos=.t.
		ELSE
			llmalos=.f.
		ENDIF 
		USE IN c_repetidos 

	ENDIF 
	
	IF llmalos=.f. AND !EMPTY(lcFileXls)
		SELECT c_pro
		ldfecaltamia=DATETIME()
		GO top
		IF !EOF()
			USE pcsysdir+pcDB+"\siscata" IN 0 SHARED AGAIN ALIAS cata
			SELECT id,origen,cod,nombre,status,fecalta,fecmod,nodo,iduser,pcuser FROM cata WHERE id<0 INTO CURSOR c_agrTmp READWRITE 
			**** familias
			INSERT INTO c_agrTmp (origen,cod,nombre,status,fecalta,fecmod,nodo,iduser,pcuser) ;
				SELECT 'LIN',SUBSTR(familia,1,20) as agrupa,MAX(familia) as nomagrupa,1,ldfecaltamia,ldfecaltamia,PCNODO,pnidusuario,SYS(0) ;
					FROM c_pro ORDER BY familia GROUP BY familia WHERE !EMPTY(familia)
			REPLACE cod WITH SUBSTR(nombre,1,3)+ALLTRIM(STR(RECNO())) all
			DELETE FROM c_agrTmp WHERE origen+nombre in (select UPPER(origen+nombre) FROM cata WHERE origen='LIN')
			REPLACE id WITH _SiguienteIdTabla(pcNodo,"MAS") all
			INSERT INTO cata (id,origen,cod,nombre,status,fecalta,fecmod,nodo,iduser,pcuser) SELECT * FROM  c_agrTmp
		
			SELECT id,origen,cod,nombre,status,fecalta,fecmod,nodo,iduser,pcuser FROM cata WHERE id<0 INTO CURSOR c_agrTmp READWRITE 
			**** marca
			INSERT INTO c_agrTmp (origen,cod,nombre,status,fecalta,fecmod,nodo,iduser,pcuser) ;
				SELECT 'MAR',SUBSTR(familia,1,20) as agrupa,MAX(familia) as nomagrupa,1,ldfecaltamia,ldfecaltamia,PCNODO,pnidusuario,SYS(0) ;
					FROM c_pro ORDER BY familia GROUP BY familia WHERE !EMPTY(familia)
			REPLACE cod WITH SUBSTR(nombre,1,3)+ALLTRIM(STR(RECNO())) all
			DELETE FROM c_agrTmp WHERE origen+nombre in (select UPPER(origen+nombre) FROM cata WHERE origen='MAR')
			REPLACE id WITH _SiguienteIdTabla(pcNodo,"MAS") all
			INSERT INTO cata (id,origen,cod,nombre,status,fecalta,fecmod,nodo,iduser,pcuser) SELECT * FROM  c_agrTmp

			SELECT TOP 1 id FROM siscata WHERE origen='DIV' AND status=1 AND eliminado=0 ORDER BY id INTO ARRAY arreglo
				IF _tally<>0
					lniddiv=arreglo
				ELSE
					lniddiv=0
				ENDIF 
				
			
			SELECT TOP 1 id FROM siscata WHERE origen='SIS' AND status=1 AND eliminado=0 ORDER BY id INTO ARRAY arreglo
				IF _tally<>0
					lnidsis=arreglo
				ELSE
					lnidsis=0
				ENDIF 

			
			SELECT TOP 1 id FROM siscata WHERE origen='GRU' AND status=1 AND eliminado=0 ORDER BY id INTO ARRAY arreglo
				IF _tally<>0
					lnidagr=arreglo
				ELSE
					lnidagr=0
				ENDIF 

					
			SELECT TOP 1 id FROM siscata WHERE origen='RUB' AND status=1 AND eliminado=0 ORDER BY id INTO ARRAY arreglo
				IF _tally<>0
					lnidrub=arreglo
				ELSE
					lnidrub=0
				ENDIF 
			
			
			**** buscando id del agrupador
			SELECT c_pro
			UPDATE c_pro SET idfamilia =id from cata a WHERE familia=a.nombre AND a.origen='LIN'
			UPDATE c_pro SET idmarca =id from cata a WHERE familia=a.nombre AND a.origen='MAR'
			USE in cata	
			DELETE FROM c_pro WHERE idproducto in (select idproducto FROM pro) OR codprod in (select codprod FROM pro) 
			REPLACE idproducto WITH _SiguienteIdTabla(pcNodo,"MAS") all	 
			INSERT INTO pro (idproducto,codprod,producto,descripcion,tipoprod,iddivision,idsistema,;
								idfamilia,idrubro,idagrupador,unidadmedida,idmarca,gravado,idimpuestoiva,;
								pordescuento,costoinicial,juegocompra,precioconiva,preciosiniva,juegoventa,;
								factorpresenta,status,fecalta,fecmod,nodo,iduser,pcuser) ;
					SELECT idproducto,codprod,producto,producto,1,lniddiv,lnidsis,idfamilia,lnidrub,;
							lnidagr,'Unidad',idmarca,1,1,0,0.01,1,precioconiva,precioconiva/(pnporiva+1),1,1,1,;
							ldfecaltamia,ldfecaltamia,pcnodo,pnidusuario,SYS(0) ;
					FROM c_pro
					
 			USE pcsysdir+pcDB+"\invexisbodega" IN 0 SHARED AGAIN ALIAS exi
			SELECT idexisbode,idproducto,idbodega,fecalta,fecmod,nodo,iduser,pcuser FROM exi WHERE idexisbode=0 INTO CURSOR c_exi READWRITE 
			INSERT INTO c_exi  ;
			select 0,t1.idproducto,t0.id as idbodega,ldfecaltamia,ldfecaltamia,pcnodo,pnidusuario,SYS(0) ;
				from siscata t0 full join c_pro t1 on t0.eliminado=0 ;
				where t0.origen='BOD' AND t1.idproducto in (SELECT idproducto FROM c_pro) order by t1.idproducto
			SELECT c_exi 
			DELETE from c_exi  WHERE STR(idproducto)+STR(idbodega) IN (select STR(idproducto)+STR(idbodega) from exi )
			REPLACE idexisbode WITH _SiguienteIdTabla(pcNodo,"SIS") all
			INSERT INTO exi (idexisbode,idproducto,idbodega,fecalta,fecmod,nodo,iduser,pcuser) ;
				SELECT idexisbode,idproducto,idbodega,ldfecaltamia,ldfecaltamia,pcnodo,pnidusuario,SYS(0) FROM c_exi
			USE IN c_exi
			USE IN exi

			
		ENDIF 
	ENDIF 
		
	USE IN pro
	USE IN c_pro
	IF !EMPTY(lcaliaspelexls)
		SELECT (lcaliaspelexls)
	ENDIF 
	
ENDFUNC 





FUNCTION cargarArchivoExcelSurtidorCliPRO()
	lcaliaspelexls=ALIAS()
	USE pcsysdir+pcDB+"\cyvclipro" IN 0 SHARED AGAIN ALIAS cli
	SET DELETED ON 
	
	llmalos=.f. 

	SELECT idclipro,codclipro,clipro,direccion,correo,;
			telefono,SPACE(20) as fax,celular,nrc,nit,giro,tipocontri,;
			diascredito,limitecredito,tipoclipro,beneficiario,dui,variosnombres,condipago ;
		FROM cli WHERE idclipro=0 into cursor c_cli READWRITE

	lcFileXls=GETFILE("xls")
	IF !EMPTY(lcFileXls)
		APPEND FROM (lcFileXls) TYPE xl5
		GO top
		DELETE NEXT 1
		REPLACE clipro WITH ALLTRIM(UPPER(clipro)) all
		REPLACE codclipro WITH ALLTRIM(UPPER(codclipro)) all
		REPLACE beneficiario WITH ALLTRIM(beneficiario) all
		REPLACE correo WITH LOWER(ALLTRIM(correo)) ALL 
		REPLACE condipago WITH IIF(diascredito>0,1,0) all
			
		SELECT * FROM (SELECT codclipro,SUM(1) as cuenta ;
						FROM c_cli ;
						ORDER BY codclipro GROUP BY codclipro) as tt ;
				WHERE cuenta>1 INTO CURSOR c_repetidos READWRITE 
		IF !EOF()
			lcdigarepetidos=''
			lccoma=''
			SCAN all
				lcdigarepetidos=lcdigarepetidos+lccoma+ALLTRIM(codclipro)
				lccoma=', '
			ENDSCAN 
			MESSAGEBOX(lcdigarepetidos,16,"Codigos Repetidos... no se puede continuar con el proceso")
			SELECT codclipro,clipro from c_cli WHERE codclipro in (SELECT codclipro FROM c_repetidos) INTO CURSOR c_repe
			lcfile2=GETFILE("xls","Guardar Archivo","Repetidos",1,"Guardar Listado de Codigos Duplicados")
			IF !EMPTY(lcfile2)
				EXPORT TO (lcfile2) TYPE xl5
				SET DEFAULT TO (pcSysDir)

				DECLARE INTEGER ShellExecute IN shell32.dll ; 
				INTEGER hndWin, STRING cAction, STRING cFileName, ; 
				STRING cParams, STRING cDir, INTEGER nShowWin 
				ShellExecute(0,"open",lcfile2,"","",1)
				RELEASE ShellExecute
			ENDIF 
			USE IN c_repe
			llmalos=.t.
		ELSE
			llmalos=.f.
		ENDIF 
		USE IN c_repetidos 

	ENDIF 
	
	IF llmalos=.f. AND !EMPTY(lcFileXls)
		SELECT c_cli
		ldfecaltamia=DATETIME()
		GO top
		IF !EOF()
			REPLACE idclipro WITH _SiguienteIdTabla(pcNodo,"MAS") FOR idclipro=0	 
			INSERT INTO cli (idclipro,codclipro,clipro,nombre,tipoclipro,idsucursal,idgrupo,direccion,;
							iddepto,idmuni,correo,telefono,celular,giro,nit,nrc,dui,tipocontri,tipoiva,;
							condipago,diascredito,limitecredito,variosnombres,;
							status,fecalta,fecmod,nodo,iduser,pcuser) ;
					SELECT idclipro,codclipro,clipro,clipro,tipoclipro,151,261,direccion,1112,11210,correo,;
							telefono,celular,giro,nit,nrc,dui,tipocontri,1,;
							condipago,diascredito,limitecredito,variosnombres,; 
							1,ldfecaltamia,ldfecaltamia,pcnodo,pnidusuario,SYS(0) ;
					FROM c_cli
		ENDIF 
	ENDIF 
		
	USE IN cli
	USE IN cli
	*USE IN c_procliasdfasfasfasfasfasfasfasfasf
	IF !EMPTY(lcaliaspelexls)
		SELECT (lcaliaspelexls)
	ENDIF 
	
ENDFUNC 


FUNCTION CrearZonasImportacionMasiva
	LOCAL lcAliasAnterior,lcCodigo,lcCodigoGrupo,lcSector,lcZonasExistentes,lcZona,lnCodigo,lnRepetidos,lnIdSector,llValido,llCodigoExiste
	lcAliasAnterior=ALIAS()
	IF !USED("c_cli") OR !USED("clidep")
		RETURN .F.
	ENDIF
	IF USED("c_gru")
		USE IN c_gru
	ENDIF
	SELECT MAX(idgrupo) as idsector,MAX(SPACE(20)) as codSector,grupo as Sector,SPACE(254) as ZonasExistentes ;
		FROM c_cli WHERE !EMPTY(ALLTRIM(grupo)) ;
		AND UPPER(ALLTRIM(grupo)) NOT in (SELECT UPPER(ALLTRIM(nombre)) FROM clidep WHERE origen='GRU' AND status=1) ;
		AND UPPER(ALLTRIM(grupo)) NOT in (SELECT UPPER(ALLTRIM(cod)) FROM clidep WHERE origen='GRU' AND status=1) ;
		ORDER BY grupo GROUP BY grupo INTO CURSOR c_gru READWRITE
	IF RECCOUNT("c_gru")=0
		IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
			SELECT (lcAliasAnterior)
		ENDIF
		RETURN .T.
	ENDIF

	lcZonasExistentes=""
	SELECT clidep
	SCAN FOR origen='GRU' AND status=1 AND !DELETED()
		lcZona=ALLTRIM(cod)+" - "+ALLTRIM(nombre)
		IF LEN(lcZonasExistentes)+LEN(lcZona)+3<=254
			lcZonasExistentes=lcZonasExistentes+IIF(EMPTY(lcZonasExistentes),""," | ")+lcZona
		ENDIF
	ENDSCAN
	SELECT cod FROM clidep WHERE origen='GRU' AND !DELETED() INTO CURSOR c_codzonas READWRITE
	SELECT c_codzonas
	REPLACE cod WITH PADL(ALLTRIM(STR(VAL(cod))),3,'0') FOR !EMPTY(ALLTRIM(cod)) AND EMPTY(CHRTRAN(ALLTRIM(cod),'0123456789',''))
	INDEX ON UPPER(ALLTRIM(cod)) TAG codigo
	SELECT c_gru
	REPLACE ZonasExistentes WITH lcZonasExistentes ALL
	SCAN
		FOR lnCodigo=1 TO 999
			lcCodigo=PADL(ALLTRIM(STR(lnCodigo)),3,'0')
			IF !SEEK(UPPER(lcCodigo),"c_codzonas","codigo")
				REPLACE codSector WITH lcCodigo IN c_gru
				INSERT INTO c_codzonas (cod) VALUES (lcCodigo)
				EXIT
			ENDIF
		ENDFOR
		IF EMPTY(ALLTRIM(codSector))
			MESSAGEBOX("No hay codigos de zona disponibles entre 001 y 999.",16,"Importacion masiva")
			USE IN c_codzonas
			RETURN .F.
		ENDIF
	ENDSCAN

	DO WHILE .T.
		SELECT c_gru
		BROWSE NORMAL FIELDS codSector:H='CODIGO',Sector:R:H='NUEVA ZONA',ZonasExistentes:R:H='ZONAS EXISTENTES' ;
			TITLE 'CONFIRME LAS NUEVAS ZONAS (Ctrl+W para continuar)' NODELETE NOAPPEND
		llValido=.T.
		SELECT c_gru
		SCAN
			lcCodigo=UPPER(ALLTRIM(codSector))
			REPLACE codSector WITH lcCodigo IN c_gru
			SELECT clidep
			LOCATE FOR origen='GRU' AND !DELETED() AND (UPPER(ALLTRIM(cod))=lcCodigo OR ;
				(EMPTY(CHRTRAN(ALLTRIM(cod),'0123456789','')) AND PADL(ALLTRIM(STR(VAL(cod))),3,'0')=lcCodigo))
			llCodigoExiste=FOUND()
			IF llCodigoExiste AND status<>1
				MESSAGEBOX("El codigo "+lcCodigo+" pertenece a una zona inactiva y no se puede reutilizar.",16,"Codigo de zona")
				llValido=.F.
			ELSE
				IF !llCodigoExiste
					IF LEN(lcCodigo)<>3 OR VAL(lcCodigo)<1 OR VAL(lcCodigo)>999 OR PADL(ALLTRIM(STR(VAL(lcCodigo))),3,'0')<>lcCodigo
						MESSAGEBOX("El codigo nuevo "+lcCodigo+" debe tener tres digitos entre 001 y 999.",16,"Codigo de zona")
						llValido=.F.
					ELSE
						SELECT c_gru
						COUNT FOR UPPER(ALLTRIM(codSector))=lcCodigo TO lnRepetidos
						IF lnRepetidos>1
							MESSAGEBOX("El codigo "+lcCodigo+" esta repetido entre las zonas nuevas.",16,"Codigo de zona")
							llValido=.F.
						ENDIF
					ENDIF
				ENDIF
			ENDIF
			SELECT c_gru
			IF !llValido
				EXIT
			ENDIF
		ENDSCAN
		IF llValido
			EXIT
		ENDIF
	ENDDO
	IF MESSAGEBOX("Confirma crear o asociar las zonas mostradas?",36,"Importacion masiva")<>6
		USE IN c_codzonas
		IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
			SELECT (lcAliasAnterior)
		ENDIF
		RETURN .F.
	ENDIF

	SELECT c_gru
	SCAN
		lcCodigo=UPPER(ALLTRIM(codSector))
		lcCodigoGrupo=lcCodigo
		lcSector=UPPER(ALLTRIM(Sector))
		SELECT clidep
		LOCATE FOR origen='GRU' AND status=1 AND !DELETED() AND (UPPER(ALLTRIM(cod))=lcCodigo OR ;
			(EMPTY(CHRTRAN(ALLTRIM(cod),'0123456789','')) AND PADL(ALLTRIM(STR(VAL(cod))),3,'0')=lcCodigo))
		IF !FOUND()
			lnIdSector=_SiguienteIdTabla(pcNodo,"MAS")
			INSERT INTO clidep (id,origen,cod,nombre,idpadre,tipo,notas,ctainvent,ctacosvta,ctaingvta,eliminado,status,;
				fecalta,fecmod,fecactu,nodo,iduser,pcuser) ;
				VALUES (lnIdSector,'GRU',lcCodigo,lcSector,0,0,'',0,0,0,0,1,;
				DATETIME(),DATETIME(),DATETIME(),pcnodo,pnIdUsuario,SYS(0))
		ELSE
			lcCodigoGrupo=ALLTRIM(clidep.cod)
		ENDIF
		UPDATE c_cli SET grupo=lcCodigoGrupo WHERE UPPER(ALLTRIM(grupo))=lcSector
		SELECT c_gru
	ENDSCAN
	=SincronizarCorrelativoZonasImportacion()
	USE IN c_codzonas
	IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
		SELECT (lcAliasAnterior)
	ENDIF
	RETURN .T.
ENDFUNC


FUNCTION CrearLectoresImportacionMasiva
	LOCAL lcAliasAnterior,lcCodigo,lcCodigoLector,lcLector,lcLectoresExistentes,lcVendedor,lnCodigo,lnRepetidos,lnIdLector,llValido,llCodigoExiste
	lcAliasAnterior=ALIAS()
	IF !USED("c_cli") OR !USED("clidep")
		RETURN .F.
	ENDIF
	IF USED("c_age")
		USE IN c_age
	ENDIF
	SELECT MAX(idagente) as idlector,MAX(SPACE(20)) as codLector,agente as Lector,SPACE(254) as LectoresExistentes ;
		FROM c_cli WHERE !EMPTY(ALLTRIM(agente)) ;
		AND UPPER(ALLTRIM(agente)) NOT in (SELECT UPPER(ALLTRIM(nombre)) FROM clidep WHERE origen='VEN' AND status=1) ;
		AND UPPER(ALLTRIM(agente)) NOT in (SELECT UPPER(ALLTRIM(cod)) FROM clidep WHERE origen='VEN' AND status=1) ;
		ORDER BY agente GROUP BY agente INTO CURSOR c_age READWRITE
	IF RECCOUNT("c_age")=0
		USE IN c_age
		IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
			SELECT (lcAliasAnterior)
		ENDIF
		RETURN .T.
	ENDIF

	lcLectoresExistentes=""
	SELECT clidep
	SCAN FOR origen='VEN' AND status=1 AND !DELETED()
		lcVendedor=ALLTRIM(cod)+" - "+ALLTRIM(nombre)
		IF LEN(lcLectoresExistentes)+LEN(lcVendedor)+3<=254
			lcLectoresExistentes=lcLectoresExistentes+IIF(EMPTY(lcLectoresExistentes),""," | ")+lcVendedor
		ENDIF
	ENDSCAN
	SELECT cod FROM clidep WHERE origen='VEN' AND !DELETED() INTO CURSOR c_codlectores READWRITE
	SELECT c_codlectores
	REPLACE cod WITH PADL(ALLTRIM(STR(VAL(cod))),2,'0') FOR !EMPTY(ALLTRIM(cod)) AND EMPTY(CHRTRAN(ALLTRIM(cod),'0123456789',''))
	INDEX ON UPPER(ALLTRIM(cod)) TAG codigo
	SELECT c_age
	REPLACE LectoresExistentes WITH lcLectoresExistentes ALL
	SCAN
		FOR lnCodigo=1 TO 99
			lcCodigo=PADL(ALLTRIM(STR(lnCodigo)),2,'0')
			IF !SEEK(UPPER(lcCodigo),"c_codlectores","codigo")
				REPLACE codLector WITH lcCodigo IN c_age
				INSERT INTO c_codlectores (cod) VALUES (lcCodigo)
				EXIT
			ENDIF
		ENDFOR
		IF EMPTY(ALLTRIM(codLector))
			MESSAGEBOX("No hay codigos de lector disponibles entre 01 y 99.",16,"Importacion masiva")
			USE IN c_codlectores
			USE IN c_age
			RETURN .F.
		ENDIF
	ENDSCAN

	DO WHILE .T.
		SELECT c_age
		BROWSE NORMAL FIELDS codLector:H='CODIGO',Lector:R:H='NUEVO LECTOR',LectoresExistentes:R:H='LECTORES / VENDEDORES EXISTENTES' ;
			TITLE 'CONFIRME LOS NUEVOS LECTORES (Ctrl+W para continuar)' NODELETE NOAPPEND
		llValido=.T.
		SELECT c_age
		SCAN
			lcCodigo=UPPER(ALLTRIM(codLector))
			REPLACE codLector WITH lcCodigo IN c_age
			SELECT clidep
			LOCATE FOR origen='VEN' AND !DELETED() AND (UPPER(ALLTRIM(cod))=lcCodigo OR ;
				(EMPTY(CHRTRAN(ALLTRIM(cod),'0123456789','')) AND PADL(ALLTRIM(STR(VAL(cod))),2,'0')=lcCodigo))
			llCodigoExiste=FOUND()
			IF llCodigoExiste AND status<>1
				MESSAGEBOX("El codigo "+lcCodigo+" pertenece a un lector inactivo y no se puede reutilizar.",16,"Codigo de lector")
				llValido=.F.
			ELSE
				IF !llCodigoExiste
					IF LEN(lcCodigo)<>2 OR VAL(lcCodigo)<1 OR VAL(lcCodigo)>99 OR PADL(ALLTRIM(STR(VAL(lcCodigo))),2,'0')<>lcCodigo
						MESSAGEBOX("El codigo nuevo "+lcCodigo+" debe tener dos digitos entre 01 y 99.",16,"Codigo de lector")
						llValido=.F.
					ELSE
						SELECT c_age
						COUNT FOR UPPER(ALLTRIM(codLector))=lcCodigo TO lnRepetidos
						IF lnRepetidos>1
							MESSAGEBOX("El codigo "+lcCodigo+" esta repetido entre los lectores nuevos.",16,"Codigo de lector")
							llValido=.F.
						ENDIF
					ENDIF
				ENDIF
			ENDIF
			SELECT c_age
			IF !llValido
				EXIT
			ENDIF
		ENDSCAN
		IF llValido
			EXIT
		ENDIF
	ENDDO
	IF MESSAGEBOX("Confirma crear o asociar los lectores mostrados?",36,"Importacion masiva")<>6
		USE IN c_codlectores
		USE IN c_age
		IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
			SELECT (lcAliasAnterior)
		ENDIF
		RETURN .F.
	ENDIF

	SELECT c_age
	SCAN
		lcCodigo=UPPER(ALLTRIM(codLector))
		lcCodigoLector=lcCodigo
		lcLector=UPPER(ALLTRIM(Lector))
		SELECT clidep
		LOCATE FOR origen='VEN' AND status=1 AND !DELETED() AND (UPPER(ALLTRIM(cod))=lcCodigo OR ;
			(EMPTY(CHRTRAN(ALLTRIM(cod),'0123456789','')) AND PADL(ALLTRIM(STR(VAL(cod))),2,'0')=lcCodigo))
		IF !FOUND()
			lnIdLector=_SiguienteIdTabla(pcNodo,"MAS")
			INSERT INTO clidep (id,origen,cod,nombre,idpadre,tipo,notas,ctainvent,ctacosvta,ctaingvta,eliminado,status,;
				fecalta,fecmod,fecactu,nodo,iduser,pcuser) ;
				VALUES (lnIdLector,'VEN',lcCodigo,lcLector,151,0,'',0,0,0,0,1,;
				DATETIME(),DATETIME(),DATETIME(),pcnodo,pnIdUsuario,SYS(0))
		ELSE
			lcCodigoLector=ALLTRIM(clidep.cod)
		ENDIF
		UPDATE c_cli SET agente=lcCodigoLector WHERE UPPER(ALLTRIM(agente))=lcLector
		SELECT c_age
	ENDSCAN
	USE IN c_codlectores
	USE IN c_age
	IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
		SELECT (lcAliasAnterior)
	ENDIF
	RETURN .T.
ENDFUNC


FUNCTION ConvertirFechaImportacionClientes
	LPARAMETERS tuValor,tcFormato,tlValida
	LOCAL lcFecha,lcFormato,lnDia,lnMes,lnAnio,ldFecha,loError
	tlValida=.T.
	IF VARTYPE(tuValor)="D"
		RETURN tuValor
	ENDIF
	IF VARTYPE(tuValor)="T"
		RETURN TTOD(tuValor)
	ENDIF
	lcFecha=ALLTRIM(TRANSFORM(tuValor))
	IF EMPTY(lcFecha)
		RETURN CTOD("")
	ENDIF
	lcFecha=STRTRAN(STRTRAN(lcFecha,"-","/"),".","/")
	IF GETWORDCOUNT(lcFecha,"/")<>3
		tlValida=.F.
		RETURN CTOD("")
	ENDIF
	lcFormato=UPPER(ALLTRIM(tcFormato))
	DO CASE
	CASE LEN(GETWORDNUM(lcFecha,1,"/"))=4
		lnAnio=VAL(GETWORDNUM(lcFecha,1,"/"))
		lnMes=VAL(GETWORDNUM(lcFecha,2,"/"))
		lnDia=VAL(GETWORDNUM(lcFecha,3,"/"))
	CASE lcFormato="M/D/A"
		lnMes=VAL(GETWORDNUM(lcFecha,1,"/"))
		lnDia=VAL(GETWORDNUM(lcFecha,2,"/"))
		lnAnio=VAL(GETWORDNUM(lcFecha,3,"/"))
	CASE lcFormato="A/M/D"
		lnAnio=VAL(GETWORDNUM(lcFecha,1,"/"))
		lnMes=VAL(GETWORDNUM(lcFecha,2,"/"))
		lnDia=VAL(GETWORDNUM(lcFecha,3,"/"))
	OTHERWISE
		lnDia=VAL(GETWORDNUM(lcFecha,1,"/"))
		lnMes=VAL(GETWORDNUM(lcFecha,2,"/"))
		lnAnio=VAL(GETWORDNUM(lcFecha,3,"/"))
	ENDCASE
	IF lnAnio>=0 AND lnAnio<100
		lnAnio=2000+lnAnio
	ENDIF
	IF lnDia<1 OR lnDia>31 OR lnMes<1 OR lnMes>12 OR lnAnio<1900 OR lnAnio>9999
		tlValida=.F.
		RETURN CTOD("")
	ENDIF
	TRY
		ldFecha=DATE(lnAnio,lnMes,lnDia)
	CATCH TO loError
		tlValida=.F.
		RETURN CTOD("")
	ENDTRY
	IF YEAR(ldFecha)<>lnAnio OR MONTH(ldFecha)<>lnMes OR DAY(ldFecha)<>lnDia
		tlValida=.F.
		RETURN CTOD("")
	ENDIF
	RETURN ldFecha
ENDFUNC


FUNCTION RegistrarLogImportacionClientes
	LPARAMETERS tcArchivoLog,tcTipo,tcValor,tcResultado,tcDetalle
	LOCAL lcLinea
	IF EMPTY(tcArchivoLog)
		RETURN .F.
	ENDIF
	lcLinea=TTOC(DATETIME(),1)+" | "+UPPER(ALLTRIM(tcTipo))+" | "+ALLTRIM(tcResultado)+" | "+;
		STRTRAN(STRTRAN(ALLTRIM(TRANSFORM(tcValor)),CHR(13)," "),CHR(10)," ")+" | "+;
		STRTRAN(STRTRAN(ALLTRIM(TRANSFORM(tcDetalle)),CHR(13)," "),CHR(10)," ")+CHR(13)+CHR(10)
	RETURN STRTOFILE(lcLinea,tcArchivoLog,1)>0
ENDFUNC


FUNCTION RegistrarResultadoImportacionClientes
	LPARAMETERS tnFilaExcel,tcCodigo,tcEstado,tcMensaje
	LOCAL lcCodigo,lcEstado,lcMensaje
	IF !USED("c_resultadoImportacionClientes") OR VARTYPE(tnFilaExcel)<>"N" OR tnFilaExcel<2
		RETURN .F.
	ENDIF
	lcCodigo=LEFT(ALLTRIM(TRANSFORM(tcCodigo)),40)
	lcEstado=LEFT(UPPER(ALLTRIM(TRANSFORM(tcEstado))),20)
	lcMensaje=LEFT(STRTRAN(STRTRAN(ALLTRIM(TRANSFORM(tcMensaje)),CHR(13)," "),CHR(10)," "),254)
	SELECT c_resultadoImportacionClientes
	LOCATE FOR filaexcel=tnFilaExcel
	IF FOUND()
		REPLACE codigo WITH lcCodigo,estado WITH lcEstado,mensaje WITH lcMensaje IN c_resultadoImportacionClientes
	ELSE
		INSERT INTO c_resultadoImportacionClientes (filaexcel,codigo,estado,mensaje) ;
			VALUES (tnFilaExcel,lcCodigo,lcEstado,lcMensaje)
	ENDIF
	RETURN .T.
ENDFUNC


FUNCTION GenerarExcelResultadoImportacionClientes
	LPARAMETERS tcArchivoFuente,tcCursorResultado,tnTotal,tnSinError,tnConError
	LOCAL lcExtension,lcBaseResultado,lcArchivoResultado,lnConsecutivo,oExcel,loLibro,loMensajes,loResumen
	LOCAL lnUltimaCol,lnUltimaFilaResultado,lnFilasHoja,lcAliasAnterior,loError
	IF EMPTY(tcArchivoFuente) OR !FILE(tcArchivoFuente) OR EMPTY(tcCursorResultado) OR !USED(tcCursorResultado)
		RETURN ""
	ENDIF
	lcExtension=LOWER(JUSTEXT(tcArchivoFuente))
	IF EMPTY(lcExtension)
		lcExtension="xlsx"
	ENDIF
	lcBaseResultado=ADDBS(JUSTPATH(tcArchivoFuente))+JUSTSTEM(tcArchivoFuente)+"_RESULTADO_"+LEFT(DTOS(DATE()),4)+"-"+SUBSTR(DTOS(DATE()),5,2)+"-"+RIGHT(DTOS(DATE()),2)
	lcArchivoResultado=lcBaseResultado+"."+lcExtension
	lnConsecutivo=1
	DO WHILE FILE(lcArchivoResultado)
		lcArchivoResultado=lcBaseResultado+" ("+ALLTRIM(STR(lnConsecutivo))+" )."+lcExtension
		lcArchivoResultado=STRTRAN(lcArchivoResultado," )",")")
		lnConsecutivo=lnConsecutivo+1
	ENDDO

	TRY
		COPY FILE (tcArchivoFuente) TO (lcArchivoResultado)
		oExcel=CREATEOBJECT("Excel.Application")
		oExcel.Visible=.F.
		oExcel.DisplayAlerts=.F.
		loLibro=oExcel.Workbooks.Open(lcArchivoResultado)
		loMensajes=loLibro.Worksheets(1)
		loMensajes.Name="Mensajes"
		lnUltimaCol=loMensajes.UsedRange.Columns.Count
		loMensajes.Cells(1,lnUltimaCol+1).Value="ESTADO"
		loMensajes.Cells(1,lnUltimaCol+2).Value="MENSAJE"
		loMensajes.Cells(1,lnUltimaCol+1).Font.Bold=.T.
		loMensajes.Cells(1,lnUltimaCol+2).Font.Bold=.T.

		lcAliasAnterior=ALIAS()
		lnUltimaFilaResultado=1
		SELECT (tcCursorResultado)
		SCAN
			loMensajes.Cells(filaexcel,lnUltimaCol+1).Value=ALLTRIM(estado)
			loMensajes.Cells(filaexcel,lnUltimaCol+2).Value=ALLTRIM(mensaje)
			lnUltimaFilaResultado=MAX(lnUltimaFilaResultado,filaexcel)
		ENDSCAN
		lnFilasHoja=loMensajes.UsedRange.Rows.Count
		IF lnFilasHoja>lnUltimaFilaResultado
			loMensajes.Rows(ALLTRIM(STR(lnUltimaFilaResultado+1))+":"+ALLTRIM(STR(lnFilasHoja))).Delete
		ENDIF
		loMensajes.Columns(lnUltimaCol+1).AutoFit
		loMensajes.Columns(lnUltimaCol+2).ColumnWidth=70
		loMensajes.Rows(1).AutoFilter

		loResumen=loLibro.Worksheets.Add()
		loResumen.Name="Resumen"
		loMensajes.Move(loResumen)
		loResumen.Cells(1,1).Value="ARCHIVO ORIGINAL"
		loResumen.Cells(1,2).Value=JUSTFNAME(tcArchivoFuente)
		loResumen.Cells(2,1).Value="PROCESO"
		loResumen.Cells(2,2).Value="RESULTADO DE LA CARGA"
		loResumen.Cells(3,1).Value="TOTAL"
		loResumen.Cells(3,2).Value=tnTotal
		loResumen.Cells(4,1).Value="SIN ERROR"
		loResumen.Cells(4,2).Value=tnSinError
		loResumen.Cells(5,1).Value="CON ERROR"
		loResumen.Cells(5,2).Value=tnConError
		loResumen.Cells(6,1).Value="FORMATO DE FECHA"
		loResumen.Cells(6,2).Value="Dia / mes / anio"
		loResumen.Range("A1:A6").Font.Bold=.T.
		loResumen.Range("A1:B6").Borders.LineStyle=1
		loResumen.Columns("A:B").AutoFit

		loLibro.Save()
		loLibro.Close(.T.)
		oExcel.Quit
		IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
			SELECT (lcAliasAnterior)
		ENDIF
	CATCH TO loError
		IF VARTYPE(loLibro)="O"
			loLibro.Close(.F.)
		ENDIF
		IF VARTYPE(oExcel)="O"
			oExcel.Quit
		ENDIF
		IF FILE(lcArchivoResultado)
			DELETE FILE (lcArchivoResultado)
		ENDIF
		RETURN ""
	ENDTRY
	RETURN lcArchivoResultado
ENDFUNC


FUNCTION CrearZonasImportacionMasivaAutomatico
	LPARAMETERS tcArchivoLog,tnAgregadas,tnNoAgregadas
	LOCAL lcAliasAnterior,lcCodigo,lcSector,lcPrefijo,lcCaracter,lnCodigo,lnIdSector,lnPos,llDisponible,loError
	tnAgregadas=0
	tnNoAgregadas=0
	lcAliasAnterior=ALIAS()
	IF !USED("c_cli") OR !USED("clidep")
		=RegistrarLogImportacionClientes(tcArchivoLog,"ZONA","","NO AGREGADA","No estan disponibles los cursores c_cli y clidep.")
		RETURN .F.
	ENDIF
	IF USED("c_gru_auto")
		USE IN c_gru_auto
	ENDIF
	SELECT grupo as Sector FROM c_cli WHERE !EMPTY(ALLTRIM(grupo)) ;
		AND UPPER(ALLTRIM(grupo)) NOT in (SELECT UPPER(ALLTRIM(nombre)) FROM clidep WHERE origen='GRU' AND status=1) ;
		AND UPPER(ALLTRIM(grupo)) NOT in (SELECT UPPER(ALLTRIM(cod)) FROM clidep WHERE origen='GRU' AND status=1) ;
		ORDER BY grupo GROUP BY grupo INTO CURSOR c_gru_auto READWRITE
	SELECT c_gru_auto
	SCAN
		lcSector=UPPER(ALLTRIM(Sector))
		lcCodigo=""
		lcPrefijo=""
		FOR lnPos=1 TO MIN(4,LEN(lcSector))
			lcCaracter=SUBSTR(lcSector,lnPos,1)
			IF !BETWEEN(lcCaracter,"0","9")
				EXIT
			ENDIF
			lcPrefijo=lcPrefijo+lcCaracter
		ENDFOR
		llDisponible=.F.
		IF BETWEEN(LEN(lcPrefijo),1,3) AND BETWEEN(VAL(lcPrefijo),1,999)
			lcCodigo=PADL(ALLTRIM(STR(VAL(lcPrefijo))),3,'0')
			SELECT clidep
			LOCATE FOR origen='GRU' AND !DELETED() AND (UPPER(ALLTRIM(cod))=lcCodigo OR ;
				(EMPTY(CHRTRAN(ALLTRIM(cod),'0123456789','')) AND PADL(ALLTRIM(STR(VAL(cod))),3,'0')=lcCodigo))
			llDisponible=!FOUND()
		ENDIF
		IF !llDisponible
			FOR lnCodigo=1 TO 999
				lcCodigo=PADL(ALLTRIM(STR(lnCodigo)),3,'0')
				SELECT clidep
				LOCATE FOR origen='GRU' AND !DELETED() AND (UPPER(ALLTRIM(cod))=lcCodigo OR ;
					(EMPTY(CHRTRAN(ALLTRIM(cod),'0123456789','')) AND PADL(ALLTRIM(STR(VAL(cod))),3,'0')=lcCodigo))
				llDisponible=!FOUND()
				IF llDisponible
					EXIT
				ENDIF
			ENDFOR
		ENDIF
		IF EMPTY(lcCodigo) OR !llDisponible
			tnNoAgregadas=tnNoAgregadas+1
			=RegistrarLogImportacionClientes(tcArchivoLog,"ZONA",lcSector,"NO AGREGADA","No hay codigos disponibles entre 001 y 999.")
		ELSE
			TRY
				lnIdSector=_SiguienteIdTabla(pcNodo,"MAS")
				INSERT INTO clidep (id,origen,cod,nombre,idpadre,tipo,notas,ctainvent,ctacosvta,ctaingvta,eliminado,status,;
					fecalta,fecmod,fecactu,nodo,iduser,pcuser) ;
					VALUES (lnIdSector,'GRU',lcCodigo,lcSector,0,0,'',0,0,0,0,1,;
					DATETIME(),DATETIME(),DATETIME(),pcnodo,pnIdUsuario,SYS(0))
				UPDATE c_cli SET grupo=lcCodigo WHERE UPPER(ALLTRIM(grupo))=lcSector
				tnAgregadas=tnAgregadas+1
				=RegistrarLogImportacionClientes(tcArchivoLog,"ZONA",lcSector,"AGREGADA","Codigo "+lcCodigo)
			CATCH TO loError
				tnNoAgregadas=tnNoAgregadas+1
				=RegistrarLogImportacionClientes(tcArchivoLog,"ZONA",lcSector,"NO AGREGADA",loError.Message)
			ENDTRY
		ENDIF
		SELECT c_gru_auto
	ENDSCAN
	IF tnAgregadas>0
		=SincronizarCorrelativoZonasImportacion()
	ENDIF
	USE IN c_gru_auto
	IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
		SELECT (lcAliasAnterior)
	ENDIF
	RETURN .T.
ENDFUNC


FUNCTION CrearLectoresImportacionMasivaAutomatico
	LPARAMETERS tcArchivoLog,tnAgregados,tnNoAgregados
	LOCAL lcAliasAnterior,lcCodigo,lcLector,lnCodigo,lnIdLector,llDisponible,loError
	tnAgregados=0
	tnNoAgregados=0
	lcAliasAnterior=ALIAS()
	IF !USED("c_cli") OR !USED("clidep")
		=RegistrarLogImportacionClientes(tcArchivoLog,"LECTOR","","NO AGREGADO","No estan disponibles los cursores c_cli y clidep.")
		RETURN .F.
	ENDIF
	IF USED("c_age_auto")
		USE IN c_age_auto
	ENDIF
	SELECT agente as Lector FROM c_cli WHERE !EMPTY(ALLTRIM(agente)) ;
		AND UPPER(ALLTRIM(agente)) NOT in (SELECT UPPER(ALLTRIM(nombre)) FROM clidep WHERE origen='VEN' AND status=1) ;
		AND UPPER(ALLTRIM(agente)) NOT in (SELECT UPPER(ALLTRIM(cod)) FROM clidep WHERE origen='VEN' AND status=1) ;
		ORDER BY agente GROUP BY agente INTO CURSOR c_age_auto READWRITE
	SELECT c_age_auto
	SCAN
		lcLector=UPPER(ALLTRIM(Lector))
		lcCodigo=""
		FOR lnCodigo=1 TO 99
			lcCodigo=PADL(ALLTRIM(STR(lnCodigo)),2,'0')
			SELECT clidep
			LOCATE FOR origen='VEN' AND !DELETED() AND (UPPER(ALLTRIM(cod))=lcCodigo OR ;
				(EMPTY(CHRTRAN(ALLTRIM(cod),'0123456789','')) AND PADL(ALLTRIM(STR(VAL(cod))),2,'0')=lcCodigo))
			llDisponible=!FOUND()
			IF llDisponible
				EXIT
			ENDIF
		ENDFOR
		IF EMPTY(lcCodigo) OR !llDisponible
			tnNoAgregados=tnNoAgregados+1
			=RegistrarLogImportacionClientes(tcArchivoLog,"LECTOR",lcLector,"NO AGREGADO","No hay codigos disponibles entre 01 y 99.")
		ELSE
			TRY
				lnIdLector=_SiguienteIdTabla(pcNodo,"MAS")
				INSERT INTO clidep (id,origen,cod,nombre,idpadre,tipo,notas,ctainvent,ctacosvta,ctaingvta,eliminado,status,;
					fecalta,fecmod,fecactu,nodo,iduser,pcuser) ;
					VALUES (lnIdLector,'VEN',lcCodigo,lcLector,151,0,'',0,0,0,0,1,;
					DATETIME(),DATETIME(),DATETIME(),pcnodo,pnIdUsuario,SYS(0))
				UPDATE c_cli SET agente=lcCodigo WHERE UPPER(ALLTRIM(agente))=lcLector
				tnAgregados=tnAgregados+1
				=RegistrarLogImportacionClientes(tcArchivoLog,"LECTOR",lcLector,"AGREGADO","Codigo "+lcCodigo)
			CATCH TO loError
				tnNoAgregados=tnNoAgregados+1
				=RegistrarLogImportacionClientes(tcArchivoLog,"LECTOR",lcLector,"NO AGREGADO",loError.Message)
			ENDTRY
		ENDIF
		SELECT c_age_auto
	ENDSCAN
	USE IN c_age_auto
	IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
		SELECT (lcAliasAnterior)
	ENDIF
	RETURN .T.
ENDFUNC


FUNCTION SincronizarCorrelativoZonasImportacion
	LOCAL lcAliasAnterior,lcCodigo,lnCodigo,lnSiguiente
	lcAliasAnterior=ALIAS()
	=ValidarCorrelativo_SectoresAgua()
	lnSiguiente=1000
	FOR lnCodigo=1 TO 999
		lcCodigo=PADL(ALLTRIM(STR(lnCodigo)),3,'0')
		SELECT clidep
		LOCATE FOR origen='GRU' AND !DELETED() AND (UPPER(ALLTRIM(cod))=lcCodigo OR ;
			(EMPTY(CHRTRAN(ALLTRIM(cod),'0123456789','')) AND PADL(ALLTRIM(STR(VAL(cod))),3,'0')=lcCodigo))
		IF !FOUND()
			lnSiguiente=lnCodigo
			EXIT
		ENDIF
	ENDFOR
	USE pcSysDir+pcdb+'\sisseries' SHARE AGAIN IN 0 ALIAS zser
	SELECT zser
	LOCATE FOR idserie=-3
	IF FOUND()
		REPLACE inicial WITH 1,final WITH 999,siguiente WITH lnSiguiente,digitos WITH 3,status WITH IIF(lnSiguiente<=999,1,0) IN zser
	ENDIF
	USE IN zser
	IF !EMPTY(lcAliasAnterior) AND USED(lcAliasAnterior)
		SELECT (lcAliasAnterior)
	ENDIF
	RETURN .T.
ENDFUNC


FUNCTION cargarArchivoExcelCliPRO(lcMiOrigenCXCP)
	LOCAL llFechaValida,ldFechaImportacion
	lcaliaspelexls=ALIAS()
	USE pcsysdir+pcDB+"\cyvclipro" IN 0 SHARED AGAIN ALIAS cli
	USE pcsysdir+pcDB+"\siscata" IN 0 SHARED AGAIN ALIAS clidep
	USE pcsysdir+pcDB+"\cyvtarifas" IN 0 SHARED AGAIN ALIAS clitar
	USE pcsysdir+pcDB+"\ctbcuentas" IN 0 SHARED AGAIN ALIAS clictb
	
	llmalos=.f.
	
	SET DELETED ON 
				* 	departamento	ciudad	
				* email	telefono	fax	celular	ciacelular	rfc	nit	giro	
				* tiporetencionpercepcion	exentoiva	tiposocionegocio	clientefinal	
				* condicionpago	fechaalta	nacionalidad	descuento	diascredito	limitecredito	
				* saldo	notas	status	idlista
	IF pcVersionS='AZURE'
		lntipopago=1
		lndiaspag=10
		lnlimpag=60
	ELSE
		lntipopago=0
		lndiaspag=0
		lnlimpag=0
	ENDIF 

	SELECT idclipro,codclipro,clipro,direccion,SPACE(200) as departamento,SPACE(10) as ciudad,correodte,;
			telefono,SPACE(20) as fax,celular,000000000 as cia,nrc,dui,nit,giro,000000000 as exec,tipoclipro,tipocontri,tipoiva,;
			variosnombres,condipago,DATETIME() as fal,SPACE(20) as naci,pordescuento,diascredito,limitecredito, ;
			000000000.000000 as sal,SPACE(1) as not,status,000000000 as idli,000000000 as iddepto,000000000 as idmuni,;
			SPACE(20) as codmuni,SPACE(20) as coddepto, 000000000 as idgrupo,SPACE(100) as grupo,idsucursal,SPACE(20) as codsuc,;
			000000000 as idtarifa, SPACE(100) as tarifa,000000000 as ultimalectura,fecultilectura,codpais,nacionalidad,;
			SPACE(30) as ctacontable,000000000 as idctacontable,SPACE(20) as agente,000000000 as idagente,000000000.00 as saldo,CTOD(" ") as fechadoc,;
			SPACE(30) as fechalecturatexto,micromedidor,000000000 as filaexcel ;
		FROM cli WHERE idclipro=0 into cursor c_cli READWRITE
	llmalos=.t.
	
	lcFileXls=GETFILE('xls,xlsx')
	SET DEFAULT TO (pcsysdir)
	IF !EMPTY(lcFileXls)
		lcLogImportacion=ADDBS(JUSTPATH(lcFileXls))+JUSTSTEM(lcFileXls)+"_LOG_"+DTOS(DATE())+"_"+STRTRAN(TIME(),":","")+".txt"
		IF USED("c_resultadoImportacionClientes")
			USE IN c_resultadoImportacionClientes
		ENDIF
		CREATE CURSOR c_resultadoImportacionClientes (filaexcel I,codigo C(40),estado C(20),mensaje C(254))
		lnZonasAgregadas=0
		lnZonasNoAgregadas=0
		lnLectoresAgregados=0
		lnLectoresNoAgregados=0
		lnFilasNoAgregadas=0
		lnClientesPreparados=0
		lnClientesAgregados=0
		=STRTOFILE("LOG DE IMPORTACION MASIVA DE USUARIOS / CLIENTES"+CHR(13)+CHR(10)+;
			"Archivo: "+lcFileXls+CHR(13)+CHR(10)+"Inicio: "+TTOC(DATETIME(),1)+CHR(13)+CHR(10)+CHR(13)+CHR(10),lcLogImportacion,0)
		WAIT WINDOW 'Importando Registros.... ' NOWAIT 
		Local oExcel,llConDeta
		llConDeta=.f.
		oExcel = Createobject("Excel.Application")
		#DEFINE xlCenter -4108
		#DEFINE xlTop -4160	
		#DEFINE xlRight -4152
		lnxlsLin=1
		lcxlsCod=''
		lcxlsCta=''
		lcxlsDA=''
		lnCtrol=0
		lcxlsMMD=""

		With oExcel
			.WorkBooks.Open(lcfilexls) 
			
		 	DO WHILE .t.
				lnxlsLin=lnxlsLin+1
				lnvaltmp=NVL(oExcel.Cells(lnxlsLin,2).Value,"")
				IF TYPE("lnvaltmp")<>"C"
					lnvaltmp=STR(lnvaltmp)
				ENDIF 
				lnval=ALLTRIM(lnvaltmp)
				WAIT WINDOW "Importando registro "+lnval NOWAIT 
				IF !EMPTY(lnval)
					lcxlsCOD	=UPPER(NVL(lnval,''))
					lcxlsNOM	=UPPER(NVL(.Cells(lnxlsLin,3).Value,''))
					lcxlsSEC 	=UPPER(NVL(.Cells(lnxlsLin,4).Value,''))
					lcxlsDIR 	=NVL(.Cells(lnxlsLin,5).Value,'')
					lcxlsTEL 	=NVL(.Cells(lnxlsLin,6).Value,'')
					lcxlsCORRe 	=NVL(.Cells(lnxlsLin,7).Value,'')
					lcxlsTAR 	=UPPER(NVL(.Cells(lnxlsLin,8).Value,''))
					lcxlsLEC 	=NVL(.Cells(lnxlsLin,9).Value,0)
 					lcxlsFEC 	=NVL(.Cells(lnxlsLin,10).Value,'')
					lcxlsSUC 	=UPPER(NVL(.Cells(lnxlsLin,11).Value,""))
					lcxlsDEP 	=UPPER(NVL(.Cells(lnxlsLin,12).Value,""))
					lcxlsMUN 	=UPPER(NVL(.Cells(lnxlsLin,13).Value,""))
					lcxlsDUI 	=UPPER(NVL(.Cells(lnxlsLin,14).Value,""))
					lcxlsNIT 	=UPPER(NVL(.Cells(lnxlsLin,15).Value,""))
					lcxlsNRC 	=UPPER(NVL(.Cells(lnxlsLin,16).Value,""))
					lcxlsGIRO 	=UPPER(NVL(.Cells(lnxlsLin,17).Value,""))
					lcxlsCPAG 	=NVL(.Cells(lnxlsLin,18).Value,0)
					lcxlsTCON 	=IIF(NVL(.Cells(lnxlsLin,19).Value,0)=0,pnTipoContriCliPro,.Cells(lnxlsLin,19).Value)
					lcxlsTIVA 	=IIF(NVL(.Cells(lnxlsLin,20).Value,0)=0,pnIvaGeneral,.Cells(lnxlsLin,20).Value)
					lcxlsDCRE 	=NVL(.Cells(lnxlsLin,21).Value,0)
					lcxlsLCRE 	=NVL(.Cells(lnxlsLin,22).Value,0)

					lcxlsCTB 	=NVL(.Cells(lnxlsLin,23).Value,"")
					lcxlsAGE 	=NVL(.Cells(lnxlsLin,24).Value,"")
					lcxlsMMD 	=NVL(.Cells(lnxlsLin,25).Value,"")
					
					IF TYPE("lcxlsDCRE")<>"N"
						lcxlsDCRE =VAL(lcxlsDCRE )
					ENDIF 
					IF TYPE("lcxlsTEL")="N"
						lcxlsTEL =ALLTRIM(STR(lcxlsTEL))
					ENDIF 
					IF TYPE("lcxlsCORRe")<>"C"
						lcxlsCORRe=ALLTRIM(TRANSFORM(lcxlsCORRe))
					ENDIF
					IF EMPTY(ALLTRIM(lcxlsTEL))
						lcxlsTEL="7000-0000"
					ENDIF
					IF EMPTY(ALLTRIM(lcxlsCORRe))
						lcxlsCORRe="noenviar@gmail.com"
					ENDIF
					IF TYPE("lcxlsMMD")<>"C"
						lcxlsMMD=ALLTRIM(STR(lcxlsMMD))
					ELSE
						lcxlsMMD=ALLTRIM(lcxlsMMD)
					ENDIF 
					
					DO CASE
					CASE TYPE("lcxlsFEC")="D"
						lcFechaOriginal=ALLTRIM(STR(YEAR(lcxlsFEC),4))+"/"+PADL(ALLTRIM(STR(MONTH(lcxlsFEC))),2,"0")+"/"+PADL(ALLTRIM(STR(DAY(lcxlsFEC))),2,"0")
					CASE TYPE("lcxlsFEC")="T"
						lcFechaOriginal=ALLTRIM(STR(YEAR(TTOD(lcxlsFEC)),4))+"/"+PADL(ALLTRIM(STR(MONTH(TTOD(lcxlsFEC)))),2,"0")+"/"+PADL(ALLTRIM(STR(DAY(TTOD(lcxlsFEC)))),2,"0")
					OTHERWISE
						lcFechaOriginal=ALLTRIM(TRANSFORM(lcxlsFEC))
					ENDCASE
					IF TYPE("lcxlsLEC")<>"N"
						lcxlsLEC=VAL(lcxlsLEC)
					ENDIF 
							
					IF TYPE("lcxlsCTB")<>"C"
						lcxlsCTB=ALLTRIM(STR(lcxlsCTB))
					ENDIF 
					IF EMPTY(lcxlsMUN)
						lcxlsMUN=pcCodMunicipio
					ENDIF 
					IF EMPTY(lcxlsDEP)
						lcxlsDEP=pcCodDepartamento
					ENDIF 
					
					lnCtrol=1
					
					INSERT INTO c_cli (codclipro,clipro,grupo,direccion,celular,correodte,tarifa,ultimalectura,tipoclipro,dui,nit,nrc,giro,;
									tipoiva,condipago,diascredito,limitecredito,codsuc,codmuni,coddepto,tipocontri,fecultilectura,;
									fechalecturatexto,ctacontable,agente,micromedidor,codpais,nacionalidad,filaexcel) ;
								VALUES (lcxlsCod,lcxlsnom,lcxlssec,lcxlsdir,lcxlstel,lcxlsCORRe,lcxlstar,lcxlslec,IIF(lcMiOrigenCXCP="CLI",1,2),lcxlsDUI,lcxlsNIT,lcxlsNRC,;
									lcxlsGIRO,lcxlsTIVA,lcxlsCPAG,NVL(lcxlsDCRE,00000),lcxlsLCRE,lcxlsSUC,lcxlsMUN,lcxlsDEP,lcxlsTCON,CTOD(""),;
									lcFechaOriginal,lcxlsCTB,lcxlsAGE,lcxlsMMD,'SV','SALVADOREÑO',lnxlsLin)
					=RegistrarResultadoImportacionClientes(lnxlsLin,lcxlsCod,"PENDIENTE","Pendiente de procesar.")
				ELSE
					lnCtrol=0
					lcxlsCod=''
					lcxlsCta=''
					lcxlsDA=-1
				ENDIF 

				IF lnxlsLin>1 AND lnCtrol=0 AND EMPTY(lcxlsCod)
					EXIT 
				ENDIF 
			ENDDO 

			lcFormatoFecha="D/M/A"
			lnFechasInvalidas=0
			SELECT c_cli
			SCAN
				ldFechaImportacion=ConvertirFechaImportacionClientes(fechalecturatexto,lcFormatoFecha,@llFechaValida)
				IF llFechaValida
					REPLACE fecultilectura WITH ldFechaImportacion IN c_cli
				ELSE
					lnFechasInvalidas=lnFechasInvalidas+1
					lnFilasNoAgregadas=lnFilasNoAgregadas+1
					=RegistrarLogImportacionClientes(lcLogImportacion,"USUARIO",codclipro,"NO AGREGADO",;
						"La fecha de lectura '"+ALLTRIM(fechalecturatexto)+"' no es valida.")
					=RegistrarResultadoImportacionClientes(filaexcel,codclipro,"ERROR",;
						"La fecha de lectura '"+ALLTRIM(fechalecturatexto)+"' no es valida.")
					DELETE IN c_cli
				ENDIF
			ENDSCAN
			=RegistrarLogImportacionClientes(lcLogImportacion,"FORMATO DE FECHA",lcFormatoFecha,"FIJO",;
				"SIGA no solicita formato; las fechas no validas se informan y no se cargan.")
			IF lnFechasInvalidas>0
				lnContinuarImportacion=MESSAGEBOX("No se reconocieron "+ALLTRIM(STR(lnFechasInvalidas))+" fecha(s)."+CHR(13)+CHR(10)+;
					"Esas filas quedaron como error en el log:"+CHR(13)+CHR(10)+lcLogImportacion+CHR(13)+CHR(10)+CHR(13)+CHR(10)+;
					"Desea continuar y cargar solamente las filas validas?",36,"Log de carga generado")
				IF lnContinuarImportacion<>6
					=RegistrarLogImportacionClientes(lcLogImportacion,"IMPORTACION","","CANCELADA",;
						"El usuario decidio no cargar los registros validos despues de revisar los errores.")
					.DisplayAlerts = .F.
					.Workbooks.Close
					.QUIT
					USE IN c_cli
					USE IN clidep
					USE IN clictb
					USE IN clitar
					USE IN cli
					IF !EMPTY(lcaliaspelexls) AND USED(lcaliaspelexls)
						SELECT (lcaliaspelexls)
					ENDIF
					RETURN .F.
				ENDIF
				=RegistrarLogImportacionClientes(lcLogImportacion,"IMPORTACION","","CONTINUAR",;
					"El usuario autorizo cargar solamente los registros validos.")
			ENDIF

			GO top

			ldfec=datetime()
			IF !EOF()
				IF !CrearZonasImportacionMasivaAutomatico(lcLogImportacion,@lnZonasAgregadas,@lnZonasNoAgregadas)
					.DisplayAlerts = .F.
					.Workbooks.Close
					.QUIT
					USE IN c_cli
					USE IN clidep
					USE IN clictb
					USE IN clitar
					USE IN cli
					IF USED("c_gru")
						USE IN c_gru
					ENDIF
					IF !EMPTY(lcaliaspelexls) AND USED(lcaliaspelexls)
						SELECT (lcaliaspelexls)
					ENDIF
					RETURN .F.
				ENDIF
				IF !CrearLectoresImportacionMasivaAutomatico(lcLogImportacion,@lnLectoresAgregados,@lnLectoresNoAgregados)
					.DisplayAlerts = .F.
					.Workbooks.Close
					.QUIT
					USE IN c_cli
					USE IN clidep
					USE IN clictb
					USE IN clitar
					USE IN cli
					IF USED("c_gru")
						USE IN c_gru
					ENDIF
					IF USED("c_age")
						USE IN c_age
					ENDIF
					IF !EMPTY(lcaliaspelexls) AND USED(lcaliaspelexls)
						SELECT (lcaliaspelexls)
					ENDIF
					RETURN .F.
				ENDIF
				UPDATE c_cli SET iddepto =a.id from clidep a inner join c_cli on a.cod=c_cli.coddepto AND a.origen="DEP"
				UPDATE c_cli SET idmuni =a.id from clidep a inner join c_cli on a.cod=c_cli.codmuni AND a.origen="MUN"
				**** sucursal
				lnSucursalImportacion=0
				IF TYPE("pnIdSucursal")="N"
					lnSucursalImportacion=pnIdSucursal
				ENDIF
				IF lnSucursalImportacion>0
					SELECT clidep
					LOCATE FOR id=lnSucursalImportacion AND origen="SUC" AND status=1 AND !DELETED()
					IF !FOUND()
						lnSucursalImportacion=0
					ENDIF
				ENDIF
				IF lnSucursalImportacion=0
					SELECT clidep
					LOCATE FOR origen="SUC" AND status=1 AND !DELETED()
					IF FOUND()
						lnSucursalImportacion=clidep.id
					ENDIF
				ENDIF
				UPDATE c_cli SET idsucursal =a.id from clidep a inner join c_cli on a.cod=c_cli.codsuc AND a.origen="SUC"
				REPLACE idsucursal WITH lnSucursalImportacion FOR idsucursal=0 IN c_cli
				*****
				UPDATE c_cli SET idgrupo =a.id from clidep a inner join c_cli on (UPPER(ALLTRIM(a.nombre))=UPPER(ALLTRIM(c_cli.grupo)) OR UPPER(ALLTRIM(a.cod))=UPPER(ALLTRIM(c_cli.grupo))) AND a.origen="GRU"
				UPDATE c_cli SET idagente =a.id from clidep a inner join c_cli on (UPPER(ALLTRIM(a.cod))=UPPER(ALLTRIM(c_cli.agente)) OR UPPER(ALLTRIM(a.nombre))=UPPER(ALLTRIM(c_cli.agente))) AND a.origen="VEN"
				SELECT c_cli
				SCAN FOR idsucursal=0 OR idgrupo=0 OR idagente=0
					lcMotivoCatalogo=IIF(idsucursal=0,"No hay una sucursal activa disponible. ","")+;
						IIF(idgrupo=0,"Zona '"+ALLTRIM(grupo)+"' no disponible. ","")+;
						IIF(idagente=0,"Lector '"+ALLTRIM(agente)+"' no disponible.","")
					=RegistrarLogImportacionClientes(lcLogImportacion,"USUARIO",codclipro,"NO AGREGADO",lcMotivoCatalogo)
					=RegistrarResultadoImportacionClientes(filaexcel,codclipro,"ERROR",lcMotivoCatalogo)
					lnFilasNoAgregadas=lnFilasNoAgregadas+1
					DELETE IN c_cli
				ENDSCAN
				UPDATE c_cli SET idtarifa =a.idtarifa from clitar a inner join c_cli on a.tarifa=c_cli.tarifa 
				UPDATE C_CLI SET idctacontable=a.idCUENTA from clictb a inner join c_cli on a.CODCTA=c_cli.ctacontable
				SELECT c_cli
				SCAN FOR !EMPTY(ALLTRIM(ctacontable)) AND idctacontable=0
					=RegistrarLogImportacionClientes(lcLogImportacion,"CUENTA CONTABLE",codclipro,"INFORMATIVO",;
						"No se encontro '"+ALLTRIM(ctacontable)+"'; el usuario se cargara sin cuenta individual para permitir una cuenta comun.")
				ENDSCAN
			ENDIF 
			SELECT c_cli
			COUNT TO lnClientesPreparados
			llSinTarifa=.f. 
			lnMalosTarifa=0
	  		
			IF pcVersionS='AZURE'
				IF lcMiOrigenCXCP="CLI"
		 			COUNT FOR  NVL(idtarifa,0)<1 TO lnMalosTarifa
		 			IF lnMalosTarifa>0
		 				llSinTarifa=.t.
		 				WAIT WINDOW "Existen Clientes/Usuarios con Nombre de Tarifa Erroneos..."
		 			ENDIF 
		 		ENDIF 
 			ENDIF 
 			
			.DisplayAlerts = .F.
			.Workbooks.Close  
			.QUIT

			INDEX on codclipro TAG llave
			SET ORDER to llave
			REPLACE idclipro WITH _SiguienteIdTabla(pcNodo,"MAS") ALL 

			GO top
			
			**** verificando que no hayan cuentas duplicadas
			SELECT repetidas,codclipro,clipro ;
					FROM (SELECT CNT(*) as repetidas,codclipro,clipro ;
							FROM c_cli GROUP BY codclipro,clipro) as cc WHERE cc.repetidas>1 INTO CURSOR c_repetidas
			IF !EOF()
				llRepetidas=.t.
				SCAN
					REPLACE estado WITH "ERROR",mensaje WITH "El codigo aparece repetido en el archivo." ;
						FOR ALLTRIM(c_resultadoImportacionClientes.codigo)==ALLTRIM(c_repetidas.codclipro) IN c_resultadoImportacionClientes
				ENDSCAN
				WAIT WINDOW "Existen codigos Repetidos, favor Revisar el Archivo "+CHR(13)+"Ctrl+V para Pegar el Detalle de Registros Repetidos" 
				_vfp.DataToClip(,,3)
			ELSE 
				llRepetidas=.f.
			ENDIF 
			USE IN c_repetidas
			
			IF llSinTarifa
				SELECT c_cli
				SCAN FOR NVL(idtarifa,0)<1
					=RegistrarResultadoImportacionClientes(filaexcel,codclipro,"ERROR",;
						"No se encontro la tarifa '"+ALLTRIM(tarifa)+"'.")
				ENDSCAN
			ENDIF

			IF !llRepetidas OR llSinTarifa=.f.
				***** cargando
*!*								idclipro,codclipro,clipro,direccion,SPACE(200) as departamento,SPACE(10) as ciudad,correo,;
*!*				telefono,SPACE(20) as fax,celular,000000000 as cia,nrc,nit,giro,000000000 as exec,tipoclipro,;
*!*				variosnombres,condipago,DATETIME() as fal,SPACE(20) as naci,pordescuento,diascredito,limitecredito, ;
*!*				000000000.000000 as sal,SPACE(1) as not,status,000000000 as idli,000000000 as iddepto,000000000 as idmuni ;
*!*						
*!*				

				SELECT 0000000000 as id,idclipro,codclipro,clipro,direccion,celular,correodte,ultimalectura,1,tipoclipro,tipocontri,idgrupo,tipoiva,idtarifa,;
									ldfec,ldfec,pcnodo,pnidusuario,SYS(0),idsucursal,iddepto,idmuni,condipago,diascredito,limitecredito,fecultilectura, ;
									dui,nit,nrc,giro,idagente,micromedidor,idctacontable,codpais,nacionalidad,filaexcel ;
						FROM c_cli WHERE codclipro NOT in (select codclipro FROM cli where TIPOCLIPRO=IIF(lcMiOrigenCXCP="CLI",1,2) ) ;
						INTO CURSOR c_cargar READWRITE 
				llto=RECCOUNT()
				REPLACE id WITH RECNO() all
				GO top
				FOR i=1 TO llto
					WAIT WINDOW "Cargando "+ALLTRIM(STR(i))+" de "+ALLTRIM(STR(llto)) NOWAIT 
					SELECT c_cargar
					LOCATE FOR id=i
					lcCodigoCarga=IIF(FOUND(),ALLTRIM(codclipro),"")
					INSERT INTO cli (idclipro,codclipro,clipro,nombre,direccion,gps,celular,correodte,ultimalectura,status,tipoclipro,tipocontri,idgrupo,tipoiva,porrenta,idtarifa,;
										fecalta,fecmod,nodo,iduser,pcuser,idsucursal,iddepto,idmuni,condipago,diascredito,limitecredito,fecultilectura,;
										dui,nit,nrc,giro,idagente,micromedidor,ctacliloc,codpais,nacionalidad,variosnombres,sobregiro,idlista,pordescuento,saldo) ;
						SELECT idclipro,codclipro,clipro,clipro,direccion,SPACE(1),celular,correodte,ultimalectura,1,tipoclipro,tipocontri,idgrupo,tipoiva,0,idtarifa,;
										ldfec,ldfec,pcnodo,pnidusuario,SYS(0),idsucursal,iddepto,idmuni,condipago,diascredito,limitecredito,fecultilectura, ;
										dui,nit,nrc,giro,idagente,micromedidor,idctacontable,codpais,nacionalidad,0,0,0,0,0 ;
							FROM c_cargar WHERE codclipro NOT in (select codclipro FROM cli where TIPOCLIPRO=IIF(lcMiOrigenCXCP="CLI",1,2) ) AND id=i
					lnCargadosIteracion=_TALLY
					lnClientesAgregados=lnClientesAgregados+lnCargadosIteracion
					IF lnCargadosIteracion>0
						=RegistrarLogImportacionClientes(lcLogImportacion,"USUARIO",lcCodigoCarga,"CARGADO","OK")
						=RegistrarResultadoImportacionClientes(c_cargar.filaexcel,lcCodigoCarga,"CARGADO","OK")
					ELSE
						=RegistrarLogImportacionClientes(lcLogImportacion,"USUARIO",lcCodigoCarga,"NO CARGADO",;
							"El registro no se inserto; verifique si el codigo ya existe.")
						=RegistrarResultadoImportacionClientes(c_cargar.filaexcel,lcCodigoCarga,"ERROR",;
							"El registro no se inserto; verifique si el codigo ya existe.")
					ENDIF
				ENDFOR 
				USE IN c_cargar
				
				IF !EMPTY(lcaliaspelexls)
					SELECT (lcaliaspelexls)
					lnregimp=RECCOUNT()
				ENDIF 
				WAIT CLEAR 
			ENDIF 
			SELECT c_resultadoImportacionClientes
			REPLACE estado WITH "ERROR",mensaje WITH "El registro no se cargo; verifique si el codigo ya existe o si cumple las validaciones." ;
				FOR estado="PENDIENTE"
			COUNT TO lnTotalResultado
			COUNT FOR estado="CARGADO" TO lnSinErrorResultado
			lnConErrorResultado=lnTotalResultado-lnSinErrorResultado
			lnClientesNoAgregados=lnConErrorResultado
			lcResumen="Usuarios/clientes agregados: "+ALLTRIM(STR(lnClientesAgregados))+CHR(13)+;
				"Usuarios/clientes no agregados: "+ALLTRIM(STR(lnClientesNoAgregados))+CHR(13)+;
				"Zonas agregadas: "+ALLTRIM(STR(lnZonasAgregadas))+CHR(13)+;
				"Zonas no agregadas: "+ALLTRIM(STR(lnZonasNoAgregadas))+CHR(13)+;
				"Lectores agregados: "+ALLTRIM(STR(lnLectoresAgregados))+CHR(13)+;
				"Lectores no agregados: "+ALLTRIM(STR(lnLectoresNoAgregados))
			=RegistrarLogImportacionClientes(lcLogImportacion,"RESUMEN","","FINALIZADO",STRTRAN(lcResumen,CHR(13),"; "))
			lcArchivoResultado=GenerarExcelResultadoImportacionClientes(lcFileXls,"c_resultadoImportacionClientes",;
				lnTotalResultado,lnSinErrorResultado,lnConErrorResultado)
			IF !EMPTY(lcArchivoResultado) AND FILE(lcArchivoResultado)
				MESSAGEBOX(lcResumen+CHR(13)+CHR(13)+"Resultado Excel: "+lcArchivoResultado,;
					IIF(lnConErrorResultado+lnZonasNoAgregadas+lnLectoresNoAgregados>0,48,64),"Resultado de importacion")
				DECLARE INTEGER ShellExecute IN shell32.dll ;
					INTEGER hndWin,STRING cAction,STRING cFileName,STRING cParams,STRING cDir,INTEGER nShowWin
				ShellExecute(0,"open",lcArchivoResultado,"",JUSTPATH(lcArchivoResultado),1)
				RELEASE ShellExecute
			ELSE
				MESSAGEBOX(lcResumen+CHR(13)+CHR(13)+"No se pudo generar el resultado Excel. Log: "+lcLogImportacion,;
					48,"Resultado de importacion")
			ENDIF
		ENDWITH
		
		USE IN c_cli
		USE IN clidep
		USE IN clictb
		USE IN clitar
		USE IN cli
		IF USED("c_gru")
			USE IN c_gru
		ENDIF
		IF USED("c_resultadoImportacionClientes")
			USE IN c_resultadoImportacionClientes
		ENDIF
	
	ENDIF 
		
ENDFUNC 


FUNCTION cargarArchivoExcelPRamosUnidadMedida()
	lcaliaspelexls=ALIAS()
	USE pcsysdir+pcDB+"\invprodunimed" IN 0 SHARED AGAIN ALIAS xlsmed
	USE pcsysdir+pcDB+"\invproductos" IN 0 SHARED AGAIN ALIAS xlspro

	SELECT b.codprod,b.producto,a.unimed,a.factor,a.preciosiniva,a.precioconiva,a.codprod4,a.idunimed,a.idproducto ;
		FROM xlsmed a INNER JOIN xlspro b ON a.idproducto=b.idproducto WHERE a.idproducto=0 into cursor c_xlsmed READWRITE
	llmalos=.t.
	lcFileXls=GETFILE("xls")
	IF !EMPTY(lcFileXls)
		APPEND FROM (lcFileXls) TYPE xl5
		GO top
		DELETE NEXT 1
		REPLACE unimed WITH ALLTRIM(UPPER(unimed)) all
		REPLACE codprod WITH ALLTRIM(UPPER(codprod)) all
		REPLACE codprod4 WITH ALLTRIM(UPPER(codprod4)) all
		DELETE ALL FOR EMPTY(unimed)
		DELETE FROM c_xlsmed  WHERE idproducto in (select idproducto FROM xlsmed)
		UPDATE c_xlsmed SET idproducto=a.idproducto from xlspro a WHERE UPPER(ALLTRIM(c_xlsmed.codprod))==UPPER(ALLTRIM(a.codprod3)) 
		UPDATE c_xlsmed SET idproducto=a.idproducto from xlspro a WHERE UPPER(ALLTRIM(c_xlsmed.codprod))==UPPER(ALLTRIM(a.codprod))
		DELETE ALL FOR idproducto=0 
		
		SELECT * FROM (SELECT idproducto,unimed,SUM(1) as cuenta,MAX(codprod) as codprod,MAX(producto) as producto ;
						FROM c_xlsmed ;
						ORDER BY idproducto,unimed GROUP BY idproducto,unimed) as tt ;
				WHERE cuenta>1 INTO CURSOR c_repetidos READWRITE 
		IF !EOF()
			lcdigarepetidos=''
			lccoma=''
			SCAN all
				lcdigarepetidos=lcdigarepetidos+lccoma+ALLTRIM(codvenpro)
				lccoma=', '
			ENDSCAN 
			MESSAGEBOX(lcdigarepetidos,16,"Codigos Repetidos... no se puede continuar con el proceso")
			SELECT codprod,producto from c_xlsmed WHERE codprod in (SELECT codprod FROM c_repetidos) INTO CURSOR c_repe
			lcfile2=GETFILE("xls","Guardar Archivo","Repetidos",1,"Guardar Listado de Codigos Duplicados")
			IF !EMPTY(lcfile2)
				EXPORT TO (lcfile2) TYPE xl5
				SET DEFAULT TO (pcSysDir)

				DECLARE INTEGER ShellExecute IN shell32.dll ; 
				INTEGER hndWin, STRING cAction, STRING cFileName, ; 
				STRING cParams, STRING cDir, INTEGER nShowWin 
				ShellExecute(0,"open",lcfile2,"","",1)
				RELEASE ShellExecute
			ENDIF 
			USE IN c_repe
			llmalos=.t.
		ELSE
			llmalos=.f.
		ENDIF 
		USE IN c_repetidos 

	ENDIF 
	
	IF llmalos=.f. AND !EMPTY(lcFileXls)
		SELECT c_xlsmed
		ldfecaltamia=DATETIME()
		GO top
		IF !EOF()
			REPLACE idunimed WITH _SiguienteIdTabla(pcNodo,"MAS") FOR idunimed=0	 
			INSERT INTO xlsmed (idunimed,codprod4,unimed,factor,idproducto,preciosiniva,precioconiva,status,fecalta,fecmod,nodo,iduser,pcuser) ;
					SELECT idunimed,codprod4,unimed,factor,idproducto,preciosiniva,precioconiva,1,ldfecaltamia,ldfecaltamia,pcnodo,pnidusuario,SYS(0) ;
					FROM c_xlsmed
		ENDIF 
	ENDIF 
		
	USE IN xlsmed
	USE IN c_xlsmed
	USE IN xlspro
	IF !EMPTY(lcaliaspelexls)
		SELECT (lcaliaspelexls)
	ENDIF 
	
ENDFUNC 

FUNCTION cargarArchivoExcelSurtidorVendedores()
	lcaliaspelexls=ALIAS()
	USE pcsysdir+pcDB+"\siscata" IN 0 SHARED AGAIN ALIAS ven
	SET FILTER TO origen='VEN'
	SET DELETED ON 

	llmalos=.f. 

	SELECT ID,nombre,cod FROM ven WHERE id=0 into cursor c_ven READWRITE

	lcFileXls=GETFILE("xls")
	IF !EMPTY(lcFileXls)
		APPEND FROM (lcFileXls) TYPE xl5
		GO top
		DELETE NEXT 1
		REPLACE NOMBRE WITH ALLTRIM(UPPER(nombre)) all
		DELETE ALL FOR EMPTY(nombre)
		REPLACE cod WITH SUBSTR(nombre,1,2) FOR '-'$nombre
		REPLACE cod WITH SUBSTR(nombre,1,5) FOR !'-'$nombre
		REPLACE cod WITH SUBSTR(nombre,1,10) FOR EMPTY(cod)
		REPLACE cod WITH STRTRAN(cod,' ','') all
		REPLACE nombre WITH SUBSTR(nombre,AT('-',nombre)+1,200) all
		REPLACE nombre WITH ALLTRIM(nombre) all
		
		SELECT * FROM (SELECT cod,SUM(1) as cuenta ;
						FROM c_ven ;
						ORDER BY cod GROUP BY cod) as tt ;
				WHERE cuenta>1 INTO CURSOR c_repetidos READWRITE 
		IF !EOF()
			lcdigarepetidos=''
			lccoma=''
			SCAN all
				lcdigarepetidos=lcdigarepetidos+lccoma+ALLTRIM(codvenpro)
				lccoma=', '
			ENDSCAN 
			MESSAGEBOX(lcdigarepetidos,16,"Codigos Repetidos... no se puede continuar con el proceso")
			SELECT cod,nombre from c_ven WHERE cod in (SELECT cod FROM c_repetidos) INTO CURSOR c_repe
			lcfile2=GETFILE("xls","Guardar Archivo","Repetidos",1,"Guardar Listado de Codigos Duplicados")
			IF !EMPTY(lcfile2)
				EXPORT TO (lcfile2) TYPE xl5
				SET DEFAULT TO (pcSysDir)

				DECLARE INTEGER ShellExecute IN shell32.dll ; 
				INTEGER hndWin, STRING cAction, STRING cFileName, ; 
				STRING cParams, STRING cDir, INTEGER nShowWin 
				ShellExecute(0,"open",lcfile2,"","",1)
				RELEASE ShellExecute
			ENDIF 
			USE IN c_repe
			llmalos=.t.
		ELSE
			llmalos=.f.
		ENDIF 
		USE IN c_repetidos 

	ENDIF 
	
	IF llmalos=.f. AND !EMPTY(lcFileXls)
		SELECT c_ven
		ldfecaltamia=DATETIME()
		GO top
		IF !EOF()
			REPLACE id WITH _SiguienteIdTabla(pcNodo,"MAS") FOR id=0	 
			INSERT INTO ven (id,origen,cod,nombre,idpadre,status,fecalta,fecmod,nodo,iduser,pcuser) ;
					SELECT id,'VEN',cod,nombre,151,1,ldfecaltamia,ldfecaltamia,pcnodo,pnidusuario,SYS(0) ;
					FROM c_ven
		ENDIF 
	ENDIF 
		
	USE IN ven
	USE IN c_ven
	IF !EMPTY(lcaliaspelexls)
		SELECT (lcaliaspelexls)
	ENDIF 
	
ENDFUNC 



FUNCTION cargarArchivoExcelInventarioFisico()
	lcaliaspelexls=ALIAS()
	USE pcsysdir+pcDB+"\invproductos" IN 0 SHARED AGAIN ALIAS fis

	SELECT codprod,000000000.00000000 as cantidad,000000000.00000000 as costo,SPACE(200) nombre FROM fis WHERE idproducto=0 into cursor c_fis READWRITE
	USE IN fis
	SELECT c_fis
	lcFileXls=GETFILE("xls")
	IF !EMPTY(lcFileXls)
		APPEND FROM (lcFileXls) TYPE xl5
		GO top
		DELETE NEXT 1
		REPLACE codprod WITH UPPER(ALLTRIM(codprod)) all
		DELETE ALL FOR cantidad=0
		DELETE ALL FOR EMPTY(codprod)
		
	ENDIF 

	IF !EMPTY(lcaliaspelexls)
		SELECT (lcaliaspelexls)
	ENDIF 
	
ENDFUNC 



****** aqui generamos los codigos del gastos en el catalogo de productos y servicios, en base  alas cuentas que lo requieran
FUNCTION GenerarItemGastosdeCuentasContables()
	lcaliastmpgas=ALIAS()
	
	USE pcsysdir+pcDB+"\ctbcuentas" IN 0 SHARED AGAIN ALIAS c_ctagas
	USE pcsysdir+pcDB+"\invproductos" IN 0 SHARED AGAIN ALIAS c_progas
	ltFecHoraNew=DATETIME()
	INSERT INTO c_progas (idproducto,codprod,producto,tipoprod,iddivision,idsistema,idfamilia,idrubro,unidadmedida,idmarca,gravado,;
									idimpuestoiva,juegocompra,juegoventa,factorpresenta,idctainggasto,eliminado,;
									status,fecalta,fecmod,nodo,iduser,pcuser) ;
		SELECT _SiguienteIdTabla(pcNodo,"MAS"),codcta,cuenta,3,181,191,211,201,'Unidad',221,1,;
						1,1,1,1,idcuenta,0,1,ltFecHoraNew,ltFecHoraNew,pcnodo,pnidusuario,SYS(0) ;
				FROM c_ctagas WHERE ConItem=1 AND detalle=1 AND status=1 AND eliminado=0 AND conmodulo=0 and ;
				codcta NOT in (select codcta FROM c_ctagas)
	
	USE IN c_ctagas
	USE IN c_progas

	IF !EMPTY(lcaliastmpgas)
		SELECT (lcaliastmpgas)
	ENDIF 
	
ENDFUNC 




FUNCTION _seabrio()
	pnseabrio=pnseabrio+1
	RETURN .t.
ENDFUNC 

FUNCTION _semodifico()
	pnsemodifico=pnsemodifico+1
	RETURN .t.
ENDFUNC 



FUNCTION GenerarCuentasSaldosdelPeriodo()
	IF pcnodo=pcnodoctb AND plModuloConta=.t.
		USE pcsysdir+pcDB+"\ctbcuentas" IN 0 SHARED AGAIN ALIAS ctbCtasGenPer
		USE pcsysdir+pcDB+"\ctbSaldos" IN 0 SHARED AGAIN ALIAS ctbSalGenPer
		USE pcsysdir+pcDB+"\ctbpartidas" IN 0 SHARED AGAIN ALIAS ctbParGenPer

		SELECT periodo FROM ctbParGenPer ORDER BY periodo GROUP BY periodo INTO CURSOR c_periGenPer READWRITE 
		SELECT c_periGenPer
		INSERT INTO c_periGenPer value(SUBSTR(DTOS(gomonth(DATE()-day(DATE()),1)+1),1,6))
		lcpermiGenper=''
		SCAN 
			lcpermiGenper=periodo
			ldfectimgenper=DATETIME()
			INSERT INTO ctbSalGenPer ;
			SELECT _SiguienteIdTabla(pcNodo,"SIS") as idsaldo,idcuenta,;
					lcpermiGenper as periodo,0 as debe,0 as haber,0 as presupuesto,;
					pcnodo as nodo,ldfectimgenper as fecalta,ldfectimgenper as fecmod,;
					CTOT(' ') as fecactu,pnidusuario as iduser,SYS(0) as pcuser ;
				FROM ctbCtasGenPer ;
				WHERE STR(idcuenta)+lcpermiGenper NOT in (SELECT STR(idcuenta)+periodo FROM ctbSalGenPer)
		ENDSCAN
		
		USE IN c_periGenPer
		USE IN ctbCtasGenPer
		USE IN ctbSalGenPer
		USE IN ctbParGenPer
	ENDIF 		
ENDFUNC 



FUNCTION _mostrarImagen(lcCodPro,lcnomima)
	lcCodPro=ALLTRIM(lcCodPro)
	lcRutaimagen=''
	IF !DIRECTORY(pcsysdir+pcdb+"\Fotos\")
		MKDIR (pcsysdir+pcdb+"\Fotos\")
	ENDIF 
	IF !EMPTY(lcnomima)
		lcFileImagen=ALLTRIM(lcnomima)
		lcfileexiste=pcsysdir+pcdb+"\Fotos\"+lcFileImagen
		IF FILE(lcfileexiste)
			lcRutaimagen=lcfileexiste
		ENDIF 
	*	IF AT(UPPER(lcRutaimagen),UPPER(lcImagen))=0		&&& si es diferente de 0 ya no necesita copiarse
	*		COPY FILE (lcImagen) TO (lcRutaimagen)+lcNombre
	*	ENDIF
	ENDIF 
	IF EMPTY(lcRutaimagen)
		lcfileexiste=pcsysdir+pcdb+"\Fotos\IMG"+ALLTRIM(lcCodPro)+'.JPG'
		IF FILE(lcfileexiste)
			lcRutaimagen=lcfileexiste
		ENDIF 
	ENDIF 
	IF EMPTY(lcRutaimagen)
		lcfileexiste=pcsysdir+pcdb+"\Fotos\"+ALLTRIM(lcCodPro)+'.JPG'
		IF FILE(lcfileexiste)
			lcRutaimagen=lcfileexiste
		ENDIF 
	ENDIF 
	IF EMPTY(lcRutaimagen)
		lcfileexiste=pcsysdir+pcdb+"\Fotos\"+ALLTRIM(lcCodPro)+'.JPEG'
		IF FILE(lcfileexiste)
			lcRutaimagen=lcfileexiste
		ENDIF 
	ENDIF 
	
	RETURN lcRutaimagen
ENDFUNC 



FUNCTION _mostrarImagenSinRuta(lcCodPro,lcnomima)
	lcCodPro=ALLTRIM(lcCodPro)
	lcRutaimagen=''
	lcImagenMostrar=lcnomima
	IF !DIRECTORY(pcsysdir+pcdb+"\Fotos\")
		MKDIR (pcsysdir+pcdb+"\Fotos\")
	ENDIF 
	IF !EMPTY(lcnomima)
		lcFileImagen=ALLTRIM(lcnomima)
		lcfileexiste=pcsysdir+pcdb+"\Fotos\"+lcFileImagen
		IF FILE(lcfileexiste)
			lcRutaimagen=lcfileexiste
			lcImagenMostrar=lcFileImagen
		ENDIF 
	*	IF AT(UPPER(lcRutaimagen),UPPER(lcImagen))=0		&&& si es diferente de 0 ya no necesita copiarse
	*		COPY FILE (lcImagen) TO (lcRutaimagen)+lcNombre
	*	ENDIF
	ENDIF 
	IF EMPTY(lcRutaimagen)
		lcfileexiste=pcsysdir+pcdb+"\Fotos\IMG"+ALLTRIM(lcCodPro)+'.JPG'
		IF FILE(lcfileexiste)
			lcRutaimagen=lcfileexiste
			lcImagenMostrar="IMG"+ALLTRIM(lcCodPro)+'.JPG'
		ENDIF 
	ENDIF 
	IF EMPTY(lcRutaimagen)
		lcfileexiste=pcsysdir+pcdb+"\Fotos\"+ALLTRIM(lcCodPro)+'.JPG'
		IF FILE(lcfileexiste)
			lcRutaimagen=lcfileexiste
			lcImagenMostrar=ALLTRIM(lcCodPro)+'.JPG'
		ENDIF 
	ENDIF 
	
	RETURN lcImagenMostrar
ENDFUNC 


FUNCTION _AsignarImagen()
	lcImagenNew=GETFILE('jpg;gif;bmp;tif','imagen','Seleccione la Imagen...')
	IF !EMPTY(lcImagenNew)
		lcImagenNombre=Justfname(lcImagenNew)
		IF !DIRECTORY(pcsysdir+pcdb+"\Fotos\")
			MKDIR (pcsysdir+pcdb+"\Fotos\")
		ENDIF 
		lcRutafileCopiar=pcsysdir+pcdb+"\Fotos\"+lcImagenNombre
		COPY FILE(lcImagenNew) to (lcRutafileCopiar)
	*	IF AT(UPPER(lcRutaimagen),UPPER(lcImagen))=0		&&& si es diferente de 0 ya no necesita copiarse
	*		COPY FILE (lcImagen) TO (lcRutaimagen)+lcNombre
	*	ENDIF 
		lcImagenNew2=lcImagenNombre
	ELSE
		lcImagenNew2=''
	ENDIF 
	RETURN lcImagenNew2
ENDFUNC 




FUNCTION _mostrarPDF(lcCodCliPro,lcnomima)
	lcCodCliPro=ALLTRIM(lcCodCliPro)
	lcRutaimagen=''
	IF !DIRECTORY(pcsysdir+pcdb+"\PDFS\")
		MKDIR (pcsysdir+pcdb+"\PDFS\")
	ENDIF 
	IF !EMPTY(lcnomima)
		lcFileImagen=ALLTRIM(lcnomima)
		lcfileexiste=pcsysdir+pcdb+"\PDFS\"+lcFileImagen
		IF FILE(lcfileexiste)
			lcRutaimagen=lcfileexiste
		ENDIF 
	*	IF AT(UPPER(lcRutaimagen),UPPER(lcImagen))=0		&&& si es diferente de 0 ya no necesita copiarse
	*		COPY FILE (lcImagen) TO (lcRutaimagen)+lcNombre
	*	ENDIF
	ENDIF 
	IF EMPTY(lcRutaimagen)
		lcfileexiste=pcsysdir+pcdb+"\PDFS\IMG"+ALLTRIM(lcCodCliPro)+'.PDF'
		IF FILE(lcfileexiste)
			lcRutaimagen=lcfileexiste
		ENDIF 
	ENDIF 
	IF EMPTY(lcRutaimagen)
		lcfileexiste=pcsysdir+pcdb+"\PDFS\"+ALLTRIM(lcCodCliPro)+'.PDF'
		IF FILE(lcfileexiste)
			lcRutaimagen=lcfileexiste
		ENDIF 
	ENDIF 
	
	RETURN lcRutaimagen
ENDFUNC 



FUNCTION _AsignarPDF(lcOldPDF)
	lcImagenNew=GETFILE('pdf','PDF','Seleccione el PDF...')
	llActualizarPDF=.f.
	lcImagenNew2=""
	
	IF !EMPTY(lcImagenNew)
		lcImagenNombre=Justfname(lcImagenNew)
		IF !DIRECTORY(pcsysdir+pcdb+"\PDFS\")
			MKDIR (pcsysdir+pcdb+"\PDFS\")
		ENDIF 
		lcRutafileCopiar=pcsysdir+pcdb+"\PDFS\"+lcImagenNombre
		COPY FILE(lcImagenNew) to (lcRutafileCopiar)
	*	IF AT(UPPER(lcRutaimagen),UPPER(lcImagen))=0		&&& si es diferente de 0 ya no necesita copiarse
	*		COPY FILE (lcImagen) TO (lcRutaimagen)+lcNombre
	*	ENDIF 
		lcImagenNew2=lcImagenNombre
		llActualizarPDF=.t.
	ELSE
		IF !EMPTY(lcOldPDF)
			sn=MESSAGEBOX("Desea Eliminar el Archivo PDF Actual ?",4+32+256,"Archivo PDF")
			IF sn=6
				llActualizarPDF=.t.
				lcImagenNew2=''
			ELSE
				lcImagenNew2=lcOldPDF
			ENDIF 
		ENDIF 
	ENDIF 
	
	IF llActualizarPDF=.t.
		lnidprodPDF=idclipro
		UPDATE cyvCliPro SET archivoPDF=lcImagenNew2 WHERE idclipro=lnidprodPDF
		REPLACE archivoPDF WITH lcImagenNew2 NEXT 1
	ENDIF 
				
	RETURN lcImagenNew2
ENDFUNC 



FUNCTION _AbrirPdf(lcPdfNombre)
	IF !EMPTY(lcPdfNombre)
		LOCAL loShell
		loShell = CREATEOBJECT("Shell.Application")
		loShell.ShellExecute(pcsysdir+pcdb+"\PDFS\"+lcPdfNombre)
		RELEASE loShell
	ENDIF 
ENDFUNC 


FUNCTION CargarCuentasCPExcel(lcCXCoCXP,lcFileXLS,lcCursorXls)
	
	Local oExcel
	oExcel = Createobject("Excel.Application")

	#DEFINE xlCenter -4108
	#DEFINE xlTop -4160	
	#DEFINE xlRight -4152
	lnxlsLin=0
	lcxlsTip=''
	lcxlsCli=''
	lcxlsVal=''
	lcxlsFec=''
	lcxlsSer=''
	lcxlsNum=''
	With oExcel
		.WorkBooks.Open(lcFileXLS) 
	 	DO WHILE .t.
			lnxlsLin=lnxlsLin+1

			lcxlsTip=.Cells(lnxlsLin,1).Value
			lcxlsCli=.Cells(lnxlsLin,2).Value
			lcxlsSer=.Cells(lnxlsLin,5).Value

			IF TYPE("oExcel.Cells(lnxlsLin,3).Value")='N'
				lcxlsVal=.Cells(lnxlsLin,3).Value
			ELSE
				lcxlsVal=VAL(.Cells(lnxlsLin,3).Value)
			ENDIF 

			IF TYPE("oExcel.Cells(lnxlsLin,6).Value")='N'
				lcxlsNum=ALLTRIM(STR(.Cells(lnxlsLin,6).Value))
			ELSE
				lcxlsNum=.Cells(lnxlsLin,6).Value
			ENDIF 

			IF TYPE("oExcel.Cells(lnxlsLin,4).Value")='T'
				lcxlsFec=.Cells(lnxlsLin,4).Value
			ELSE
				IF TYPE("oExcel.Cells(lnxlsLin,4).Value")='D'
					lcxlsFec=.Cells(lnxlsLin,4).Value
				ELSE
					lcxlsFec=CTOD(.Cells(lnxlsLin,4).Value)
				ENDIF 
			ENDIF 
			
			
			IF lcxlsVal=0
				EXIT 
			ENDIF 
		ENDDO 
		
		.Visible = .T.
	Endwith
	RETURN .t.
ENDFUNC 


******* recalculo de saldos de cuentas por cobrar y pagar
FUNCTION _recalcularSaldosCXC()
	WAIT WINDOW 'Procesando...' NOWAIT 
	lcaliaskaap=ALIAS()
	USE pcsysdir+pcDB+"\siskardexapli" IN 0 SHARED AGAIN ALIAS skapli
	usE pcsysdir+pcDB+"\siskardexdoc" IN 0 SHARED AGAIN ALIAS skdoc
	usE pcsysdir+pcDB+"\cyvclipro" IN 0 SHARED AGAIN ALIAS skcli
	
	pnRecalculandoCXCP=1
	SELECT iddocto,SUM(IIF(carabo=1,monto*-1,monto)) as cargoabono from skapli ;
		where fechaaplicar<=DATE() AND status=1 AND eliminado=0 GROUP BY iddocto UNION ALL  ;
	SELECT iddoctoaplicar as iddocto,SUM(IIF(carabo=1,monto,monto*-1)) as cargoabono from skapli ;
		where fechaaplicar<=DATE() AND status=1 AND eliminado=0 GROUP BY iddoctoaplicar INTO CURSOR apli READWRITE

	IF _tally<>0
		SELECT skdoc
		REPLACE cargoabono WITH 0 FOR status=0
		SELECT apli
		INDEX on iddocto TAG llave
		SET ORDER TO llave
		SELECT skdoc
		SET RELATION TO iddocto INTO apli
		SET FILTER TO status=1 AND ctrolcxcp=1 AND condipago=1 AND eliminado=0 AND skdoc.cargoabono<>apli.cargoabono
		REPLACE cargoabono WITH NVL(apli.cargoabono,0) all
		SET FILTER TO status=1 AND ctrolcxcp=2 AND condipago=1 AND eliminado=0 AND skdoc.cargoabono<>apli.cargoabono
		REPLACE cargoabono WITH NVL(apli.cargoabono,0) all
		SET RELATION to
		
		SELECT idclipro,SUM(IIF(ctrolcxcp=1,totaldocto-rentadocto,(totaldocto-rentadocto)*-1)+cargoabono) as saldo ;
				FROM skdoc WHERE status=1 AND eliminado=0 AND condipago=1 AND ctrolcxcp<>0 ;
				ORDER BY idclipro GROUP BY idclipro INTO CURSOR c_sksal READWRITE 
		sele c_sksal
		INDEX on idclipro TAG llave
		SET ORDER TO llave
		SELECT skcli
		SET RELATION TO idclipro INTO c_sksal
		SET FILTER TO saldo<>c_sksal.saldo
		REPLACE saldo WITH c_sksal.saldo all
		SET FILTER TO 	
		
		USE IN c_sksal
		USE IN apli
		WAIT WINDOW 'Fin del Proceso...' NOWAIT 
	ENDIF 
	USE IN skapli
	USE IN skdoc
	USE IN skcli
	
	pnRecalculandoCXCP=0
	IF !EMPTY(lcaliaskaap)
		SELECT (lcaliaskaap)
	ENDIF 
 
ENDFUNC 




******* recalculo de saldos de cuentas por cobrar y pagar
FUNCTION _recalcularSaldosBancos()
	WAIT WINDOW 'Verificando Saldos de Bancos' NOWAIT 
	lcaliban=ALIAS()
	lcaliaskaap=ALIAS()
	usE pcsysdir+pcDB+"\siskardexdoc" IN 0 SHARED AGAIN 
	usE pcsysdir+pcDB+"\cyvcompras" IN 0 SHARED AGAIN
	usE pcsysdir+pcDB+"\cyvventas" IN 0 SHARED AGAIN
	usE pcsysdir+pcDB+"\cybcajabancos" IN 0 SHARED AGAIN
	usE pcsysdir+pcDB+"\sistipodoctos" IN 0 SHARED AGAIN
	usE pcsysdir+pcDB+"\cyvclipro" IN 0 SHARED AGAIN 
	usE pcsysdir+pcDB+"\cybmovimientos" IN 0 SHARED AGAIN


	SELECT idcajban,SUM(valor) as valor from (select IIF(t0.ctrolCyB=1,t0.totaldocto-t0.rentadocto,(t0.totaldocto-t0.rentadocto)*-1) as valor,t0.idcajban ;
		from siskardexdoc t0 ;
			inner join sistipodoctos t3 on t0.idtipodocto=t3.idtipodocto ;
			inner join cybcajabancos t4 on t0.idcajban=t4.idcajban ;
			left join cybcajabancos t5 on t0.idcajbantras=t5.idcajban ;
			left join cyvclipro t6 on t0.idclipro=t6.idclipro ;
			left join (select iddocto,fecactu,idtipodocto from cyvventas ;
						union all ;
						select iddocto,fecactu,idtipodocto from cyvcompras ;
						union all ;
						select iddocto,fecactu,idtipodocto from cybmovimientos ) as t9 on t0.iddocto=t9.iddocto AND t0.idtipodocto=t9.idtipodocto ;
			where INLIST(t0.ctrolCyB,1,2,3) and (t0.origen<>'VTA' or (t0.origen='VTA' and  t0.condipago=0)) AND t0.status=1 ;
		union all ;
		Select t0.totaldoctotras as valor,t0.idcajbantras AS idcajban ;
		from siskardexdoc t0 ;
			inner join sistipodoctos t3 on t0.idtipodocto=t3.idtipodocto ;
			inner join cybcajabancos t4 on t0.idcajban=t4.idcajban ;
			left join cybcajabancos t5 on t0.idcajbantras=t5.idcajban ;
			left join cyvclipro t6 on t0.idclipro=t6.idclipro ;
			left join (select iddocto,fecactu,idtipodocto from cyvventas ;
						union all ;
						select iddocto,fecactu,idtipodocto from cyvcompras ;
						union all ;
						select iddocto,fecactu,idtipodocto from cybmovimientos ) as t9 on t0.iddocto=t9.iddocto AND t0.idtipodocto=t9.idtipodocto ;
			where t0.ctrolcyb=3 and (t0.origen<>'VTA' or (t0.origen='VTA' and  t0.condipago=0)) AND t0.status=1 ) a ORDER BY a.idcajban GROUP BY a.idcajban INTO CURSOR c_BSal READWRITE 
		
	UPDATE cybcajabancos SET cybcajabancos.saldo=c_Bsal.valor from cybcajabancos inner join c_BSal on cybcajabancos.idcajban=c_Bsal.idcajban 

	USE IN siskardexdoc
	USE IN cyvcompras
	USE IN cyvventas
	USE IN cybmovimientos
	USE IN sistipodoctos
	USE IN cybcajabancos
	USE IN cyvclipro
	
	USE IN c_BSal
	
	IF !EMPTY(lcaliban)	
		SELECT (lcaliban)
	ENDIF 
ENDFUNC 


FUNCTION _conceptoResumido(lctippar,lcorig,ldfecdd)
	lctippar=UPPER(lctippar)
	lcconceresu=''
	
	DO case
		CASE lcorig='CYB'
			DO case
				case lctippar='ING'
					lcconceresu='Ingresos por movimientos Bancarios o de Efectivo del Dia '
				case lctippar='EGR'
					lcconceresu='Egresos por movimientos Bancarios o de Efectivo del Dia '
				case lctippar='DR'
					lcconceresu='movimientos Bancarios o de Efectivo del Dia '
				case lctippar='CIE'
					lcconceresu='movimientos de Cierre Bancarios o de Efectivo del Dia '
				OTHERWISE 
					lcconceresu='movimientos Bancarios o de Efectivo del Dia '
			ENDCASE 
		CASE lcorig='VTA'
			DO case
				case lctippar='ING'
					lcconceresu='Ingresos por movimientos de Venta del Dia '
				case lctippar='EGR'
					lcconceresu='Egresos por movimientos de Venta del Dia '
				case lctippar='DR'
					lcconceresu='movimientos de Venta del Dia '
				case lctippar='CIE'
					lcconceresu='movimientos de Cierre por Operaciones de Venta del Dia '
				OTHERWISE 
					lcconceresu='movimientos de Venta del Dia '
			ENDCASE 
		CASE lcorig='CTB'
			lcconceresu='movimientos del Dia '
		CASE lcorig='COM'
			DO case
				case lctippar='ING'
					lcconceresu='Ingresos por movimientos de Compra o Pagos del Dia '
				case lctippar='EGR'
					lcconceresu='Egresos por movimientos de Compra o Pagos del Dia '
				case lctippar='DR'
					lcconceresu='movimientos de Compra o Pagos del Dia '
				case lctippar='CIE'
					lcconceresu='movimientos de Cierre por Operaciones de Compra o Pagos del Dia '
				OTHERWISE 
					lcconceresu='movimientos de Compra o Pagos del Dia '
			ENDCASE 
		CASE lcorig='CXC'
			lcconceresu='movimientos de Cuentas por Cobrar del Dia '
		CASE lcorig='CXP'
			lcconceresu='movimientos de Cuentas por Pagar del Dia '
		OTHERWISE 
			lcconceresu='movimientos del Dia '
	ENDCASE 
	RETURN SUBSTR(lcconceresu+DTOC(ldfecdd)+SPACE(100),1,200)
ENDFUNC 

FUNCTION _conceptodResumido(lctippar,lcorig,ldfecdd)
	lctippar=UPPER(lctippar)
	lcconceresu=''
	
	DO case
		CASE lcorig='CYB'
			DO case
				case lctippar='ING'
					lcconceresu='movimientos Bancarios o de Efectivo del Dia '
				case lctippar='EGR'
					lcconceresu='movimientos Bancarios o de Efectivo del Dia '
				case lctippar='DR'
					lcconceresu='movimientos Bancarios o de Efectivo del Dia '
				case lctippar='CIE'
					lcconceresu='movimientos de Cierre Bancarios o de Efectivo del Dia '
				OTHERWISE 
					lcconceresu='movimientos Bancarios o de Efectivo del Dia '
			ENDCASE 
		CASE lcorig='VTA'
			DO case
				case lctippar='ING'
					lcconceresu='movimientos de Venta del Dia '
				case lctippar='EGR'
					lcconceresu='movimientos de Venta del Dia '
				case lctippar='DR'
					lcconceresu='movimientos de Venta del Dia '
				case lctippar='CIE'
					lcconceresu='movimientos de Cierre por Operaciones de Venta del Dia '
				OTHERWISE 
					lcconceresu='movimientos de Venta del Dia '
			ENDCASE 
		CASE lcorig='CTB'
			lcconceresu='movimientos del Dia '
		CASE lcorig='COM'
			DO case
				case lctippar='ING'
					lcconceresu='movimientos de Compra o Pagos del Dia '
				case lctippar='EGR'
					lcconceresu='movimientos de Compra o Pagos del Dia '
				case lctippar='DR'
					lcconceresu='movimientos de Compra o Pagos del Dia '
				case lctippar='CIE'
					lcconceresu='movimientos de Cierre por Operaciones de Compra o Pagos del Dia '
				OTHERWISE 
					lcconceresu='movimientos de Compra o Pagos del Dia '
			ENDCASE 
		CASE lcorig='CXC'
			lcconceresu='movimientos de Cuentas por Cobrar del Dia '
		CASE lcorig='CXP'
			lcconceresu='movimientos de Cuentas por Pagar del Dia '
		OTHERWISE 
			lcconceresu='movimientos del Dia '
	ENDCASE 
	RETURN SUBSTR(lcconceresu+DTOC(ldfecdd)+SPACE(100),1,200)
ENDFUNC 


FUNCTION _creaCursorModulos()
	lcaliasmodulos=ALIAS()
	CREATE CURSOR sismodulos (idmodulo i,modulo c(100),orden c(100),sistema i)
	&&&& Archivo
	INSERT INTO sismodulos VALUES (1,'Usuarios y Permisos','010100',1)
	INSERT INTO sismodulos VALUES (146,'Perfil de Usuarios','010102',1)
	
	&&&&& Caja y BAncos
	INSERT INTO sismodulos VALUES (3,'Catalogo de Caja y Bancos','020300',1)
	INSERT INTO sismodulos VALUES (4,'Movimientos Bancarios y de Efectivo','020400',1)
	IF pcVersionS<>'AZURE'
		INSERT INTO sismodulos VALUES (5,'Reporte de Caja y Bancos','020500',1)
	ENDIF
	INSERT INTO sismodulos VALUES (6,'Serie de Documentos de Caja y Bancos','020700',1)
	INSERT INTO sismodulos VALUES (7,'Tipos de Documentos de Caja y Bancos','020600',1)
	INSERT INTO sismodulos VALUES (8,'Formatos de Impresión de Caja y Bancos','020800',1)
	
	&&&&& Ventas
	INSERT INTO sismodulos VALUES (9,'Pedidos y Cotizaciones de Venta','030100',1)
	INSERT INTO sismodulos VALUES (10,'Ventas','030200',1)
	INSERT INTO sismodulos VALUES (11,'Reporte de Pedidos,Cotizaciones y Ventas','030300',1)
		INSERT INTO sismodulos VALUES (131,'     Corte de Caja','030301',1)
		INSERT INTO sismodulos VALUES (132,'     Reportes de Ventas ABC','030302',1)
		INSERT INTO sismodulos VALUES (133,'     Reportes de Ventas por Vendedor','030303',1)
		INSERT INTO sismodulos VALUES (134,'     Reportes de Comision por Ventas y Cobro','030304',1)
		INSERT INTO sismodulos VALUES (135,'     Rerpote de Ventas de Productos Controlados','030305',1)	
	INSERT INTO sismodulos VALUES (24,'Consulta de Venta','030400',1)
	INSERT INTO sismodulos VALUES (50,'Fecha Corte','030500',1)
	INSERT INTO sismodulos VALUES (15,'Ruteros','030600',1)
	INSERT INTO sismodulos VALUES (16,'Despachadores','030700',1)
	INSERT INTO sismodulos VALUES (17,'Vendedores / Cobradores','030800',1)
	INSERT INTO sismodulos VALUES (25,'Punto de Venta','030801',1)
	INSERT INTO sismodulos VALUES (145,'Parque Vehicular', '030802',1)

	IF pcVersionS='AZURE'
		INSERT INTO sismodulos VALUES (26,'Tarifas por Consumo','030802',1)
		INSERT INTO sismodulos VALUES (27,'Lecturas de Medidores','030803',1)
	ENDIF 
	INSERT INTO sismodulos VALUES (18,'Tipos de Documentos de Venta, Pedidos y Cotizaciones','030900',1)
	INSERT INTO sismodulos VALUES (19,'Serie de Documentos de Pedidos y Cotizaciones','031000',1)
	INSERT INTO sismodulos VALUES (20,'Serie de Documentos de Venta','031100',1)
	INSERT INTO sismodulos VALUES (21,'Formatos de Impresion de Pedidos y Cotizaciones','031200',1)
	INSERT INTO sismodulos VALUES (22,'Formatos de Impresion de Venta','031300',1)
	INSERT INTO sismodulos VALUES (23,'Cierre de Turno','031400',1)

	INSERT INTO sismodulos VALUES (28,'Clientes/Usuarios','040100',1)
	INSERT INTO sismodulos VALUES (29,'Qudan Clientes/Usuarios','040101',1)
	INSERT INTO sismodulos VALUES (30,'Cuentas por Cobrar','040102',1)
	INSERT INTO sismodulos VALUES (31,'Antiguedad de Saldos','040103',1)
	INSERT INTO sismodulos VALUES (2,'Reportes de Clientes y Cuentas por Cobrar','040104',1)
	INSERT INTO sismodulos VALUES (32,'     Reporte de Antiguedad de Saldos','040105',1)
	INSERT INTO sismodulos VALUES (33,'     Estado de Cuenta de Clientes','040106',1)

	INSERT INTO sismodulos VALUES (34,'Grupos/Sector de Clientes/Usuarios','040107',1)
	INSERT INTO sismodulos VALUES (35,'Lista de Precios','040108',1)
	INSERT INTO sismodulos VALUES (36,'Series de Cuentas por Cobrar','040109',1)
	INSERT INTO sismodulos VALUES (37,'Tipos de Documentos de Cuentas por Cobrar','040110',1)
	INSERT INTO sismodulos VALUES (38,'Formatos de Cuentas por Cobrar','040111',1)
	INSERT INTO sismodulos VALUES (39,'Generar PIN de Ventas','040112',1)

	&&&&& compras
	INSERT INTO sismodulos VALUES (40,'Pedidos y Cotizaciones de Compras','050100',1)
	INSERT INTO sismodulos VALUES (41,'Compas','050200',1)
	INSERT INTO sismodulos VALUES (42,'Retaceos','050300',1)
	INSERT INTO sismodulos VALUES (43,'Reporte de Pedidos,Cotizaciones y Compras','050400',1)
		INSERT INTO sismodulos VALUES (44,'     Reporte de Compras','050401',1)
	INSERT INTO sismodulos VALUES (45,'Encargado de Compras','050500',1)
	INSERT INTO sismodulos VALUES (46,'Tipo Documentos de Compra,Pedidos y Cotizaciones','050600',1)
	INSERT INTO sismodulos VALUES (47,'Series de Documentos de Pedidos y Cotizaciones','050700',1)
	INSERT INTO sismodulos VALUES (48,'Series de Documentos de Compras','050800',1)
	INSERT INTO sismodulos VALUES (147,'Serie de Comprobantes de Retención','050801',1)
	INSERT INTO sismodulos VALUES (49,'Formatos de Impresion de Pedidos y Cotizaciones','050900',1)
	INSERT INTO sismodulos VALUES (50,'Formatos de Impresion de Compras','051000',1)
	INSERT INTO sismodulos VALUES (143,'Formatos de Impresion de Comprobantes de Retención','051001',1)
	
	INSERT INTO sismodulos VALUES (51,'Proveedores','051100',1)
	INSERT INTO sismodulos VALUES (52,'Quedan Proveedores','051200',1)
	INSERT INTO sismodulos VALUES (53,'Cuentas por Pagar','051300',1)
	INSERT INTO sismodulos VALUES (54,'Antiguedad de Saldos','051400',1)
	INSERT INTO sismodulos VALUES (12,'Reportes de Cuentas por Pagar y Proveedores','051500',1)
	INSERT INTO sismodulos VALUES (55,'     Reporte de Antiguedad de Saldos','051501',1)
	INSERT INTO sismodulos VALUES (56,'     Estado de Cuenta de Proveedores','051502',1)
	INSERT INTO sismodulos VALUES (57,'Grupo/Sector de Proveedores','051700',1)
	INSERT INTO sismodulos VALUES (58,'Series de Cuentas por Pagar','051800',1)
	INSERT INTO sismodulos VALUES (59,'Tipo Documentos de Cuentas por Pagar','051900',1)
	INSERT INTO sismodulos VALUES (60,'Formatos de Cuentas por Pagar','052000',1)

	&&&&& Inventarios
	INSERT INTO sismodulos VALUES (61,'Productos, Servicios, Gastos y Más...','052100',1)
	INSERT INTO sismodulos VALUES (62,'Movimientos de Inventario','052200',1)
	INSERT INTO sismodulos VALUES (63,'Ordenes de Producción','052300',1)
	INSERT INTO sismodulos VALUES (64,'Kardex','052400',1)
	INSERT INTO sismodulos VALUES (65,'División','052500',1)
	INSERT INTO sismodulos VALUES (66,'Sistema','052600',1)
	INSERT INTO sismodulos VALUES (67,'Rubro','052700',1)
	INSERT INTO sismodulos VALUES (68,'Familias','052800',1)
	INSERT INTO sismodulos VALUES (69,'Lotes','052900',1)
	INSERT INTO sismodulos VALUES (70,'Marcas','053000',1)
	INSERT INTO sismodulos VALUES (71,'Bodegas','053100',1)
	INSERT INTO sismodulos VALUES (72,'Aplicaciones','053200',1)
	INSERT INTO sismodulos VALUES (73,'Agrupadores','053300',1)
	INSERT INTO sismodulos VALUES (74,'Reportes de Inventarios','053500',1)
		INSERT INTO sismodulos VALUES (75,'     Imprimir Etiquetas de Bultos','053501',1)
		INSERT INTO sismodulos VALUES (76,'     Existencias de Inventario y Pedidos Sugeridos','053502',1)
	INSERT INTO sismodulos VALUES (77,'Series de Documentos de Inventario','053600',1)
	INSERT INTO sismodulos VALUES (78,'Tipos de Documentos de Inventario','053700',1)
	INSERT INTO sismodulos VALUES (79,'Formatos de Impresion de Inventarios','053800',1)
	INSERT INTO sismodulos VALUES (80,'Revisión de Costos','053900',1)
	INSERT INTO sismodulos VALUES (81,'Tomas Fisicas y Muestreos','054000',1)


	&&&&& Contabilidad
	INSERT INTO sismodulos VALUES (83,'Cuentas Contables','060100',1)
	INSERT INTO sismodulos VALUES (84,'Partidas Contables','060200',1)
	INSERT INTO sismodulos VALUES (85,'Partidas Contables Consolidadas','060300',1)
	INSERT INTO sismodulos VALUES (86,'Balance General','060400',1)
	INSERT INTO sismodulos VALUES (87,'Estado de Resultados','060500',1)
	INSERT INTO sismodulos VALUES (88,'Flujo de Efectivo','060600',1)
	INSERT INTO sismodulos VALUES (89,'Cambios en el Patrimonio','060700',1)
	INSERT INTO sismodulos VALUES (90,'Libro Mayor','060800',1)
	INSERT INTO sismodulos VALUES (91,'Libro Diario Mayor','060900',1)
	INSERT INTO sismodulos VALUES (92,'Balanza de Comprobacion','061000',1)
	INSERT INTO sismodulos VALUES (93,'Auxiliar Contable','061100',1)
	INSERT INTO sismodulos VALUES (94,'Razones Financieras','061200',1)
	INSERT INTO sismodulos VALUES (95,'Tipo Partidas','061300',1)
	INSERT INTO sismodulos VALUES (96,'Fecha de Cierre Contable','061300',1)
	INSERT INTO sismodulos VALUES (97,'Cambiar los Digitos por Nivel','061300',1)
	INSERT INTO sismodulos VALUES (148,'Reenumeración de Partidas','061301',1)

	&&&&& Iva
	INSERT INTO sismodulos VALUES (98,'Consumidor Final','070100',1)
	INSERT INTO sismodulos VALUES (99,'Credito Fiscal','070200',1)
	INSERT INTO sismodulos VALUES (100,'Compras','070300',1)
	INSERT INTO sismodulos VALUES (101,'Fecha Cierre IVA','070400',1)


	&&&&& Sistemas
	INSERT INTO sismodulos VALUES (102,'Guías de Retención y Percepciópn','080100',1)
	INSERT INTO sismodulos VALUES (103,'Sucursales','080200',1)
	INSERT INTO sismodulos VALUES (104,'Centros de Costo','080300',1)
	INSERT INTO sismodulos VALUES (142,'Tipos de Transacciones Sospechosas','080400',1)
	INSERT INTO sismodulos VALUES (149,'Reconstrucción de Saldos','080401',1)
	INSERT INTO sismodulos VALUES (150,'Carga de Json de Compra','080402',1)
	
	INSERT INTO sismodulos VALUES (151,'Dashboar Web','080403',1)
	INSERT INTO sismodulos VALUES (152,'Revision Global de Errores','080404',1)
	INSERT INTO sismodulos VALUES (153,'Utiliza IA','080405',1)
	INSERT INTO sismodulos VALUES (154,'Depurar Errores WEB','080406',1)


**	INSERT INTO sismodulos VALUES (105,'','090400',1)


	&&&&& Financiera
	
	IF plModuloFinan=.t.
		INSERT INTO sismodulos VALUES (105,'Clientes','090100',1)
		INSERT INTO sismodulos VALUES (106,'Solicitudes','090200',1)
		INSERT INTO sismodulos VALUES (107,'Préstamos','090300',1)
		INSERT INTO sismodulos VALUES (108,'Abono a Préstamos/Movimien tos','090400',1)
		INSERT INTO sismodulos VALUES (109,'Tipos de Préstamo','090500',1)
		INSERT INTO sismodulos VALUES (110,'Empleados','090600',1)
		INSERT INTO sismodulos VALUES (111,'Reportes','090700',1)
	ENDIF 
	

	IF plModuloGas=.t.
		INSERT INTO sismodulos VALUES (121,'Turnos','110100',1)
			INSERT INTO sismodulos VALUES (122,'     Cambio de Turno','110101',1)
			INSERT INTO sismodulos VALUES (123,'     Cierre de Turno','110102',1)
		INSERT INTO sismodulos VALUES (124,'Pista','110200',1)
			INSERT INTO sismodulos VALUES (125,'     Isla','110201',1)
			INSERT INTO sismodulos VALUES (126,'     Pistolas','110201',1)
			INSERT INTO sismodulos VALUES (144,'     Tanques', '110202',1)
		INSERT INTO sismodulos VALUES (127,'Precios Combustibles','110300',1)
		INSERT INTO sismodulos VALUES (128,'Fovial','110400',1)
		INSERT INTO sismodulos VALUES (129,'Cotrans','110500',1)
		INSERT INTO sismodulos VALUES (130,'Reportes Kilometros por Galón','110600',1)
		
	ENDIF 
	

	IF plModuloResta=.t.
		INSERT INTO sismodulos VALUES (136,'Areas','120101',1)
		INSERT INTO sismodulos VALUES (137,'Mesas','120102',1)
		INSERT INTO sismodulos VALUES (138,'Meseros','120103',1)
		INSERT INTO sismodulos VALUES (139,'Comandas','120104',1)
		INSERT INTO sismodulos VALUES (140,'Plano del Restaurante','120105',1)
		INSERT INTO sismodulos VALUES (141,'Plano del Reportes','120106',1)
	ENDIF 


	
	INDEX on orden TAG orden
	SET ORDER TO orden 
	
	IF !EMPTY(lcaliasmodulos)
		SELECT (lcaliasmodulos)
	ENDIF 
ENDFUNC 





FUNCTION _idUltimoDocProdCliPro(lnsqlc,lnidprd,lnidclpr,lcori,lniddoc)
	lcaliasulti=ALIAS()
	IF pnTipoConeccion=1
		IF !USED('sistipodoctos')
			USE pcsysdir+pcDB+"\sistipodoctos" IN 0 SHARED AGAIN ORDER idtipodocto	
		ENDIF 
		IF !USED('siskardex')
			USE pcsysdir+pcDB+"\siskardex" IN 0 SHARED AGAIN ORDER iddocto
		ENDIF 
	ENDIF 
	CREATE CURSOR c_ultimo (ultimo c(240),uiddocto i,uiddoctod i,idproducto i,idclipro i)
	
	IF lcori='VTA'
		lcacuminnermes="(SELECT z.idproducto,ALLTRIM(TRANSFORM(SUM(z.cantidad),'999,999,999.99'))+' / '+"+;
							"alltrim(pcmonedasimbolo)+ALLTRIM(TRANSFORM(SUM(ROUND(z.totalventasiniva,2)),'999,999,999.99')) as ultimo2 "+;
							"FROM cyvventasdeta z "+;
									"INNER JOIN cyvventas y ON z.iddocto=y.iddocto "+;
									"INNER JOIN sistipodoctos x ON y.idtipodocto=x.idtipodocto "+;
							"where z.idproducto=lnidprd AND z.origen=lcori AND y.idclipro=lnidclpr AND  "+;
								"y.ctrolvta=1 AND y.eliminado=0 AND y.status=1 "+;
							"group by z.idproducto)"
		lcacuminnerano="(SELECT z.idproducto,ALLTRIM(TRANSFORM(SUM(z.cantidad),'999,999,999.99'))+' / '+"+;
							"alltrim(pcmonedasimbolo)+ALLTRIM(TRANSFORM(SUM(ROUND(z.totalventasiniva,2)),'999,999,999.99')) as ultimo3 "+;
							"FROM cyvventasdeta z "+;
									"INNER JOIN cyvventas y ON z.iddocto=y.iddocto "+;
									"INNER JOIN sistipodoctos x ON y.idtipodocto=x.idtipodocto "+;
							"where z.idproducto=lnidprd AND z.origen=lcori AND y.idclipro=lnidclpr AND  "+;
								"y.ctrolvta=1 AND y.eliminado=0 AND y.status=1  "+;
							"group by z.idproducto)"
*and BETWEEN(y.fechadocto,DATE(YEAR(DATE()),1,1),DATE())
											
		SELECT SUBSTR("Ult.Doc.: "+DTOC(b.fechadocto)+"  "+ALLTRIM(c.clave)+"#"+ALLTRIM(b.numero)+;
				"  "+ALLTRIM(NVL(a.unimed,''))+" "+ALLTRIM(STR(a.cantiunimed,12,2))+" / "+;
				ALLTRIM(pcmonedasimbolo)+ALLTRIM(TRANSFORM(ROUND(a.precioconiva-a.descuento,4),'999,999,999.9999'))+" C/IVA"+SPACE(200),1,240) as ultimo,+;
				"   Acumulado Mes:"+ALLTRIM(NVL(d.unidadmedida,''))+" "+ALLTRIM(c1.ultimo2)+" S/IVA" as ultimo2,+;
				"   Acumulado Año:"+ALLTRIM(NVL(d.unidadmedida,''))+" "+ALLTRIM(c2.ultimo3)+" S/IVA" as ultimo3,;
				b.iddocto,a.iddoctod,a.idproducto,b.idclipro ;
			FROM cyvventasdeta a ;
					INNER JOIN cyvventas b ON a.iddocto=b.iddocto ;
					INNER JOIN sistipodoctos c ON b.idtipodocto=c.idtipodocto ;
					INNER JOIN invproductos d ON a.idproducto=d.idproducto ;
					left JOIN &lcacuminnermes as c1 ON a.idproducto=c1.idproducto ;
					left JOIN &lcacuminnerano as c2 ON a.idproducto=c2.idproducto ;
			WHERE iddoctod in (SELECT cc.iddoctod FROM  (SELECT TOP 1 iddoctod,DTOS(fechadocto)+horadocto+numero as llave ;
									FROM siskardex ;
									WHERE idproducto=lnidprd AND origen=lcori AND idclipro=lnidclpr AND iddocto<>lniddoc;
											AND ctrolcomvta=1 AND eliminado=0 AND status=1 ORDER BY llave desc) as cc) ;
			INTO CURSOR c_ultimo READWRITE 
	ELSE
		lcacuminnermes="(SELECT z.idproducto,ALLTRIM(TRANSFORM(SUM(z.cantidad),'999,999,999.99'))+' / '+"+;
							"alltrim(pcmonedasimbolo)+ALLTRIM(TRANSFORM(SUM(ROUND(z.total-z.totaliva,2)),'999,999,999.99')) as ultimo2 "+;
							"FROM cyvcomprasdeta z "+;
									"INNER JOIN cyvcompras y ON z.iddocto=y.iddocto "+;
									"INNER JOIN sistipodoctos x ON y.idtipodocto=x.idtipodocto "+;
							"where z.idproducto=lnidprd AND z.origen=lcori AND y.idclipro=lnidclpr  AND "+;
								"y.ctrolcom=1 AND y.eliminado=0 AND y.status=1  and y.fechadocto>=DATE()-30  "+;
							"group by z.idproducto)"
		lcacuminnerano="(SELECT z.idproducto,ALLTRIM(TRANSFORM(SUM(z.cantidad),'999,999,999.99'))+' / '+"+;
							"alltrim(pcmonedasimbolo)+ALLTRIM(TRANSFORM(SUM(ROUND(z.total-z.totaliva,2)),'999,999,999.99')) as ultimo3 "+;
							"FROM cyvcomprasdeta z "+;
									"INNER JOIN cyvcompras y ON z.iddocto=y.iddocto "+;
									"INNER JOIN sistipodoctos x ON y.idtipodocto=x.idtipodocto "+;
							"where z.idproducto=lnidprd AND z.origen=lcori AND y.idclipro=lnidclpr  AND "+;
								"y.ctrolcom=1 AND y.eliminado=0 AND y.status=1  and y.fechadocto>=DATE()-365  "+;
							"group by z.idproducto)"
								
		SELECT SUBSTR("Ult.Doc:"+DTOC(b.fechadocto)+"  "+ALLTRIM(c.clave)+"#"+ALLTRIM(b.numero)+;
				"  "+ALLTRIM(NVL(a.unimed,''))+" "+ALLTRIM(STR(a.cantiunimed,12,2))+" / "+;
				ALLTRIM(pcmonedasimbolo)+ALLTRIM(TRANSFORM(ROUND(a.costounitario-a.descuento,4),'999,999,999.9999'))+" S/IVA"+SPACE(200),1,240) as ultimo,+;
				"   Acumulado Mes:"+ALLTRIM(NVL(d.unidadmedida,''))+" "+ALLTRIM(c1.ultimo2)+" S/IVA" as ultimo2,+;
				"   Acumulado Año:"+ALLTRIM(NVL(d.unidadmedida,''))+" "+ALLTRIM(c2.ultimo3)+" S/IVA" as ultimo3,;
				b.iddocto,a.iddoctod,a.idproducto,b.idclipro ;
			FROM cyvcomprasdeta a ;
					INNER JOIN cyvcompras b ON a.iddocto=b.iddocto ;
					INNER JOIN sistipodoctos c ON b.idtipodocto=c.idtipodocto ;
					INNER JOIN invproductos d ON a.idproducto=d.idproducto ;
					LEFT JOIN &lcacuminnermes as c1 ON a.idproducto=c1.idproducto ;
					LEFT JOIN &lcacuminnerano as c2 ON a.idproducto=c2.idproducto ;
			WHERE iddoctod in (SELECT cc.iddoctod FROM  (SELECT TOP 1 iddoctod,DTOS(fechadocto)+horadocto+numero as llave ;
									FROM siskardex ;
									WHERE idproducto=lnidprd AND origen=lcori AND idclipro=lnidclpr AND iddocto<>lniddoc;
											AND ctrolcomvta=1 AND eliminado=0 AND status=1 ORDER BY llave desc) as cc) ;
			INTO CURSOR c_ultimo READWRITE 

	ENDIF 
	REPLACE ultimo WITH ALLTRIM(ultimo)+"      "+ALLTRIM(NVL(ultimo2,''))+"      "+ALLTRIM(NVL(ultimo3,'')) IN c_ultimo all
	GO TOP IN c_ultimo
	IF !EMPTY(lcaliasulti)
		SELECT (lcaliasulti)
	ENDIF 
ENDFUNC 
						

FUNCTION _LimpiarFechaModificacion(lcDirEmp)
	lnaliascc=ALIAS()
	
	CREATE CURSOR mistablas (nombre c(50))
	INSERT INTO mistablas (nombre) values ('ctbCuentas.DBF')
	INSERT INTO mistablas (nombre) values ('ctbcuentaspadre.DBF')
	INSERT INTO mistablas (nombre) values ('ctbnumpar.dbf')
	INSERT INTO mistablas (nombre) values ('ctbpartidas.dbf')
	INSERT INTO mistablas (nombre) values ('ctbpartidasdeta.dbf')
	INSERT INTO mistablas (nombre) values ('ctbsaldos.dbf')
	INSERT INTO mistablas (nombre) values ('ctbtipoctas.dbf')
	INSERT INTO mistablas (nombre) values ('cybcajabancos.DBF')
	INSERT INTO mistablas (nombre) values ('cybmovimientos.dbf')
	INSERT INTO mistablas (nombre) values ('cyvclipro.DBF')
	INSERT INTO mistablas (nombre) values ('cyvcompras.dbf')
	INSERT INTO mistablas (nombre) values ('cyvcomprasdeta.dbf')
	INSERT INTO mistablas (nombre) values ('cyvcomprasdetalote.dbf')
	INSERT INTO mistablas (nombre) values ('cyvcuentasxcp.dbf')
	INSERT INTO mistablas (nombre) values ('cyvguiaretper.dbf')
	INSERT INTO mistablas (nombre) values ('cyvventas.dbf')
	INSERT INTO mistablas (nombre) values ('cyvventasdeta.dbf')
	INSERT INTO mistablas (nombre) values ('cyvventasdetalote.dbf')
	INSERT INTO mistablas (nombre) values ('invexisbodega.dbf')
	INSERT INTO mistablas (nombre) values ('invexisbodegalote.dbf')
	INSERT INTO mistablas (nombre) values ('invinventarios.dbf')
	INSERT INTO mistablas (nombre) values ('invinventariosdeta.dbf')
	INSERT INTO mistablas (nombre) values ('invinventariosdetalote.dbf')
	INSERT INTO mistablas (nombre) values ('invlotes.dbf')
	INSERT INTO mistablas (nombre) values ('invprodlistaspre.dbf')
	INSERT INTO mistablas (nombre) values ('invprodprecios.dbf')
	INSERT INTO mistablas (nombre) values ('invproductos.DBF')
	INSERT INTO mistablas (nombre) values ('invprodunimed.dbf')
	INSERT INTO mistablas (nombre) values ('sisautorizaciones.DBF')
	INSERT INTO mistablas (nombre) values ('siscata.dbf')
	INSERT INTO mistablas (nombre) values ('sisempresas.dbf')
	INSERT INTO mistablas (nombre) values ('sisformatos.dbf')
	INSERT INTO mistablas (nombre) values ('sisfunciones.dbf')
	INSERT INTO mistablas (nombre) values ('sisidtablas.dbf')
	INSERT INTO mistablas (nombre) values ('sisimptosporcen.dbf')
	INSERT INTO mistablas (nombre) values ('sisimptosreten.dbf')
	INSERT INTO mistablas (nombre) values ('siskardex.dbf')
	INSERT INTO mistablas (nombre) values ('siskardexapli.dbf')
	INSERT INTO mistablas (nombre) values ('siskardexdoc.dbf')
	INSERT INTO mistablas (nombre) values ('siskardexlote.dbf')
	INSERT INTO mistablas (nombre) values ('sislogactu.dbf')
	INSERT INTO mistablas (nombre) values ('sisloguactu.dbf')
	INSERT INTO mistablas (nombre) values ('sismodulos.dbf')
	INSERT INTO mistablas (nombre) values ('sispermisos.dbf')
	INSERT INTO mistablas (nombre) values ('sisprodaux.dbf')
	INSERT INTO mistablas (nombre) values ('sisrequeridos.dbf')
	INSERT INTO mistablas (nombre) values ('sisseries.dbf')
	INSERT INTO mistablas (nombre) values ('sistipodoctos.dbf')
	INSERT INTO mistablas (nombre) values ('sisusuarios.DBF')

	REPLACE nombre WITH '.\'+lcDirEmp+'\'+nombre all
	DELETE ALL FOR INLIST(RECNO(),41,42,43)

	SCAN all
		lcnomdb=ALLTRIM(nombre)
		USE &lcnomdb IN 0 ALIAS t0
		
		REPLACE fecactu WITH CTOT(' ') ALL IN t0
		
		USE IN t0
			
	ENDSCAN 
	
	*USE IN mistablas
	
	IF !EMPTY(lnaliascc)
		SELECT (lnaliascc)
	ENDIF 
ENDFUNC 


FUNCTION OcxRegistrado(cClase)
    Declare Integer RegOpenKey In Win32API ;
        Integer nHKey, String @cSubKey, Integer @nResult
    Declare Integer RegCloseKey In Win32API ;
        Integer nHKey
    nPos = 0
    lEsta = RegOpenKey(-2147483648, cClase, @nPos) = 0
 
    If lEsta
        RegCloseKey(nPos)
    Endif

    Return lEsta
Endfunc



FUNCTION PruebaServicioWeb
*!*		Local loRequest as Microsoft.XMLHTTP

*!*		loRequest = CREATEOBJECT("Microsoft.XMLHTTP")

*!*		**authData = {
*!*	    **  'email'    : email,
*!*	    **  'password' : password,
*!*	    **  'returnSecureToken' : true
*!*	    **};


*!*		*** Make the service call
*!*		loAlbums = loRequest.open("GET","https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=")
*!*		loRequest.send()
*!*		Do While loRequest.readyState <>4
*!*		   Doevents && Force && when using VFP9
*!*		EndDo
*!*		*** inspect the result
*!*		? loRequest.status && 200 means ok, 404 not found etc. http status numbers see wikipedia, w3c, google them, etc.
*!*		? Left(loRequest.responseText,1000)+"..." 
*!*		RETURN .t.
*!*		
		
	#Define clAsync .F.
	#Define ccAPIKey 'key=AIzaSyBzf3alobkeyFLYhrduzSs2Shf0UVkW53k'
	loRequest = Createobject('MsXml2.XmlHttp')
	loRequest.SetRequestHeader('X-CustomerToken',ccAPIKey)
	loRequest.Open("GET","https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword", clAsync)
	loRequest.Send()
	? loRequest.Status
	? loRequest.ResponseText 
	
	RETURN .t.
	
ENDFUNC 


**********************************
***SUBIR FTP
**********************************
FUNCTION SubirFTP(cFtp, cOrigen, cDestino, cUsername, cPassword)
	#DEFINE INTERNET_OPEN_TYPE_DIRECT 1
	LOCAL sAgent, sProxyName, sProxyBypass AS String
	LOCAL lFlags, nTipo, nNose, nNose2 AS Number

	DECLARE INTEGER InternetOpen IN wininet;
	STRING sAgent, INTEGER lAccessType,;
	STRING sProxyName, STRING sProxyBypass,;
	STRING lFlags

	DECLARE INTEGER InternetCloseHandle IN wininet INTEGER	hInet

	DECLARE INTEGER InternetConnect IN wininet;
	INTEGER hInternetSession,;
	STRING sServerName,;
	INTEGER nServerPort,;
	STRING sUsername,;
	STRING sPassword,;
	INTEGER lService,;
	INTEGER lFlags,;
	INTEGER lContext

	DECLARE INTEGER FtpPutFile IN wininet;
	INTEGER hConnect,;
	STRING lpszLocalFile,;
	STRING lpszNewRemoteFile,;
	INTEGER dwFlags,;
	INTEGER dwContext


	sAgent = "w32inetopen" && you can choose any name, say "John Dow"
	sProxyName = Chr(0) && no proxy
	sProxyBypass = Chr(0) && nothing to bypass
	lFlags = 0 && no flags used

	hOpen = InternetOpen (sAgent, INTERNET_OPEN_TYPE_DIRECT,;
	sProxyName, sProxyBypass, lFlags)

	nTipo = 1
	nNoSe = 1
	nNose2 = 1
	nConec = InternetConnect(hOpen,cFtp, 0,	cUsername, cPassword, nTipo, nNose, nNose2)

	RETURN (FtpPutFile(nConec, cOrigen, cDestino, 0, 0) = 1)

ENDFUNC 




******************** codigo para generar cuentas por cobrar de kairos xp pramos
** SELECT 'CXCINI' AS tipo,b.codsocionegocio,round(a.montodocumento-a.montoaplicado,2) as saldo,DATE_FORMAT(a.fechacxc, '%d/%m/%y') as fechacxc,'CXCINISUC1' AS serie,a.numerocxc,0 as ctrol,a.ctrolcxc FROM cuentascobrar a inner join socionegocios b on a.idsocionegocio=b.idsocionegocio where round(a.montodocumento-a.montoaplicado,2)<>0 and ctrolcxc=1 order by b.idsocionegocio,a.fechacxc




FUNCTION _EnviarDatosProductos()		
	WAIT WINDOW 'Procesando.....'  NOWAIT 
	lcaliasdatos=ALIAS()
	WAIT WINDOW 'Obteniendo Datos.....'  NOWAIT 
	USE pcsysdir+pcDB+"\invProductos" SHARED AGAIN ORDER idproducto IN 0 ALIAS rp
	USE pcsysdir+pcDB+"\siscata" SHARED AGAIN ORDER id IN 0 ALIAS rub
	USE pcsysdir+pcDB+"\invExisBodega" SHARED AGAIN ORDER idproducto IN 0 ALIAS exi
	USE pcsysdir+pcDB+"\siscata" SHARED AGAIN ORDER id IN 0 ALIAS alm
	USE pcsysdir+pcDB+"\invprodprecios" SHARED AGAIN ORDER idproducto IN 0 ALIAS  lpre
	USE pcsysdir+pcDB+"\invprodlistaspre" SHARED AGAIN ORDER idlistapre IN 0 ALIAS  llis
	
*!*		USE pcDatDir+"productos" SHARED AGAIN ORDER idproducto IN 0 ALIAS rp
*!*		USE pcDatDir+"socionegocio" SHARED AGAIN ORDER idclipro IN 0 ALIAS clpr
*!*		USE pcDatDir+"rubros" SHARED AGAIN ORDER idrubro IN 0 ALIAS rub
*!*		USE pcDatDir+"existencias" SHARED AGAIN ORDER idalmacen IN 0 ALIAS exi
*!*		USE pcDatDir+"almacenes" SHARED AGAIN ORDER idalmacen IN 0 ALIAS alm
*!*		USE pcDatDir+"unidadmedida" SHARED AGAIN ORDER idunimed IN 0 ALIAS UnM
*!*		USE pcDatDir+"compras" SHARED AGAIN ORDER iddocto IN 0 ALIAS cmp
*!*		USE pcDatDir+"comprasdeta" SHARED AGAIN ORDER IDDOCTODET IN 0 ALIAS cmpd
*!*		USE pcDatDir+"tipodoctos" SHARED AGAIN ORDER IDTIPODOCT IN 0 ALIAS td

	lndiauno=ObtenerDatosdeMes(DATE(),2,0)
	lndiafin=ObtenerDatosdeMes(DATE(),3,0)
	lnmesini=ObtenerDatosdeMes(DATE(),4,7)+1
	lnanoini=ObtenerDatosdeMes(DATE(),4,MONTH(DATE()))+1

	SELECT a.codprod,a.producto,SPACE(100) as nombre1,SPACE(100) as nombre2,NVL(c.cod,SPACE(20)) as codmarca,;
			IIF(EMPTY(NVL(c.nombre,'')),'S/M'+SPACE(30),C.nombre) as marca,;
			NVL(b.cod,SPACE(20)) as codfamilia,IIF(EMPTY(NVL(b.nombre,'')),'GENERAL'+SPACE(30),b.nombre) as familia,;
			codprod as imagen,precioconiva as preciopublico ;
			FROM rp a LEFT JOIN rub b ON a.idfamilia=b.id AND b.origen="LIN" LEFT JOIN rub c ON a.idmarca=c.id AND c.origen="MAR"  ;
		WHERE a.status=1 ORDER BY a.codprod ;
		INTO CURSOR c_dato READWRITE


	SELECT c_dato

	GO top
	IF !EOF()
		=enviarDatosProducto('c_dato')
	ENDIF 
	USE IN c_dato
	
	SELECT b.idexisbode as idexistencia,;
			a.codprod,c.cod as codbodega,c.nombre as bodega,;
			IIF(a.tipoprod=1,b.existencia,000000000.000000) as existencia ;
			FROM rp a ;
				INNER JOIN exi b ON a.idproducto=b.idproducto  ;
				INNER JOIN alm c ON b.idbodega=c.id AND c.origen="BOD" ;
		WHERE a.status=1 ORDER BY a.codprod ;
		INTO CURSOR c_dato2 READWRITE 
	
	SELECT c_dato2
	GO top
	IF !EOF()
		=enviarDatosProductoExistencia('c_dato2')
	ENDIF 
	USE IN c_dato2
	
	SELECT STR(a.idproducto,20,0) as idprecio,;
			a.codprod,"BASE"+SPACE(16) AS codprecio,"PRECIO BASE"+SPACE(50) AS nomprecio,A.precioconiva as precio ;
			FROM rp a WHERE a.status=1 AND NVL(A.precioconiva,0)<>0 ;
	UNION ALL ;
	SELECT STR(b.idprecio,20,0) as idprecio,;
			a.codprod,c.codlis as codprecio,c.listaprecio as nomprecio,b.precioconiva as precio ;
			FROM rp a ;
				INNER JOIN LPre b ON a.idproducto=b.idproducto ;
				INNER JOIN LLis c ON b.idlistapre=c.idlistapre ;
		WHERE a.status=1 AND NVL(c.status,1)=1 AND NVL(b.precioconiva,0)<>0  ;
		INTO CURSOR c_dato3 READWRITE 
	
	SELECT c_dato3
	GO top
	IF !EOF()
		=enviarDatosProductoPrecios('c_dato3')
	ENDIF 
	USE IN c_dato3

*!*		SELECT a.codclipro,a.clipro,a.limcredito as limitecredito,0 as saldovencido,a.saldo,;
*!*			IIF(!EMPTY(a.cel),a.cel,a.tel1) as telefono,a.email,a.tipocontri as tipocontribuyente ;
*!*				FROM clpr a  ;
*!*			WHERE a.status=1 AND a.tiposoc=1 ORDER BY a.codclipro ;
*!*			INTO CURSOR c_dato4 READWRITE 
*!*		
*!*		
*!*		SELECT c_dato4
*!*		GO top
*!*		IF !EOF()
*!*			=enviarDatosClientes('c_dato4')
*!*		ENDIF 
*!*		USE IN c_dato4

*!*		***** compras
*!*		SELECT t1.iddoctodeta,t2.codprod,t1.cantiunimed as cantidad,;
*!*				t1.descriunimed as unidadmedida,t1.costoprod*1.13 as costo,;
*!*				t0.numdocto as numero,t0.fecdocto as fecha,t0.clipro as proveedor ;
*!*			from cmp t0 ;
*!*				inner join cmpd t1 on t0.iddocto=t1.iddocto ;
*!*				INNER JOIN rp t2 ON t1.idproducto=t2.idproducto ;
*!*				INNER JOIN td t3 ON t0.idtipodocto=t3.idtipodocto ;
*!*				WHERE BETWEEN(t0.fecdocto,DATE()-30,DATE()) AND t3.ctrlcomp=1 AND ctrlinv=1 ;
*!*					INTO CURSOR c_dato5 READWRITE 
*!*		IF !EOF()
*!*			=enviarDatosCompras('c_dato5')
*!*		ENDIF 
*!*		USE IN c_dato5
*!*		
	USE IN rp
	*USE IN clpr
	USE IN rub
	USE IN exi
	USE IN alm
	USE IN lpre
	USE IN llis
	*USE IN UnM
	*USE IN cmp
	*USE IN cmpd
	*USE IN td

	IF !EMPTY(lcaliasdatos)
		SELECT (lcaliasdatos)
	ENDIF
ENDFUNC 



FUNCTION enviarDatosProducto(lcDat)

	lnsql=_conectaweb2(pcPTVDISALRUTA,pcPTVDISALUSER,pcPTVDISALPASS,pcPTVDISALEMPRE)
	
	IF lnsql>0
		WAIT WINDOW 'Preparando datos.....de Productos'  NOWAIT 
		lcComando=''
		SELECT (lcDat)
		lntotReg=RECCOUNT()
		lnpartes=CEILING(lntotReg/500)
		lcCursorWeb ='productos'
		
		FOR i=1 TO lnpartes
			
			lcComando="INSERT INTO "+lcCursorWeb+" (codprod,producto,nombre1,nombre2,codmarca,marca,codfamilia,familia,imagen,preciopublico) "+;
					"VALUES "
				lcComaUnion=""
			
			recini=(i*500)-499
			IF i=lnpartes
				recfin=lntotReg
			ELSE
				recfin=i*500
			ENDIF 
			SCAN for BETWEEN(RECNO(),recini,recfin)
				lcComando=lcComando+lcComaUnion+;
					"('"+ALLTRIM(codprod)+"',"+;
					"'"+ALLTRIM(_sincomillias(producto))+"',"+;
					"'"+ALLTRIM(_sincomillias(nombre1))+"',"+;
					"'"+ALLTRIM(_sincomillias(nombre2))+"',"+;
					"'"+ALLTRIM(_sincomillias(codmarca))+"',"+;
					"'"+ALLTRIM(_sincomillias(marca))+"',"+;
					"'"+ALLTRIM(_sincomillias(codfamilia))+"',"+;
					"'"+ALLTRIM(_sincomillias(familia))+"',"+;
					"'"+ALLTRIM(_sincomillias2(imagen))+"',"+;
					""+ALLTRIM(STR(preciopublico,16,6))+" "+;
					")"
				lcComaUnion=","+CHR(13)
			ENDSCAN 
			lcComando=lcComando+" ON DUPLICATE KEY UPDATE "+;
					"producto= VALUES(producto),"+;
					"familia= VALUES(familia),"+;
					"marca= VALUES(marca),"+;
					"imagen= VALUES(imagen),"+;
					"preciopublico= VALUES(preciopublico)"
		
			WAIT WINDOW 'Enviando Datos.....  '+ ALLTRIM(STR(i))+'/'+ALLTRIM(str(lnpartes))+;
							'   - Reg.:'+ALLTRIM(STR(recini))+' al '+ALLTRIM(STR(recfin))  NOWAIT 
			lnctrl=SQLEXEC(lnsql,lcComando,'')

			IF lnctrl<1
				EXIT 
			ENDIF 
		ENDFOR 
		
		IF lnctrl<1
			WAIT WINDOW "Error al Enviar Datos a la Web" NOWAIT 
		ELSE			
			WAIT WINDOW 'Envio Terminado   ' +ALLTRIM(STR(lntotReg))+" Reg. Enviados" NOWAIT 
		ENDIF 
		lnCt=SQLDISCONNECT(lnsql)
	ELSE 
		WAIT WINDOW 'Error de Coneccion....' NOWAIT 
	ENDIF 
ENDFUNC 
		


FUNCTION enviarDatosProductoExistencia(lcDat)

	lnsql=_conectaweb2(pcPTVDISALRUTA,pcPTVDISALUSER,pcPTVDISALPASS,pcPTVDISALEMPRE)
	
	IF lnsql>0
		WAIT WINDOW 'Preparando datos..... de Existencias'  NOWAIT 
		lcComando=''
		SELECT (lcDat)
		lntotReg=RECCOUNT()
		lnpartes=CEILING(lntotReg/500)
		lcCursorWeb ='existencias'
		
		FOR i=1 TO lnpartes
			
			lcComando="INSERT INTO "+lcCursorWeb+" (idexistencia,codprod,codbodega,bodega,existencia) "+;
					"VALUES "
				lcComaUnion=""
			
			recini=(i*500)-499
			IF i=lnpartes
				recfin=lntotReg
			ELSE
				recfin=i*500
			ENDIF 
			SCAN for BETWEEN(RECNO(),recini,recfin)
				lcComando=lcComando+lcComaUnion+;
					"('"+ALLTRIM(STR(idexistencia))+"',"+;
					"'"+ALLTRIM(_sincomillias(codprod))+"',"+;
					"'"+ALLTRIM(_sincomillias(codbodega))+"',"+;
					"'"+ALLTRIM(_sincomillias(bodega))+"',"+;
					""+ALLTRIM(STR(existencia,16,6))+" "+;
					")"
				lcComaUnion=","+CHR(13)
			ENDSCAN 
			lcComando=lcComando+" ON DUPLICATE KEY UPDATE "+;
					"existencia= VALUES(existencia)"
		
			WAIT WINDOW 'Enviando Datos.....  '+ ALLTRIM(STR(i))+'/'+ALLTRIM(str(lnpartes))+;
							'   - Reg.:'+ALLTRIM(STR(recini))+' al '+ALLTRIM(STR(recfin))  NOWAIT 
			lnctrl=SQLEXEC(lnsql,lcComando,'')

			IF lnctrl<1
				EXIT 
			ENDIF 
		ENDFOR 
		
		IF lnctrl<1
			WAIT WINDOW "Error al Enviar Datos de Existencias a la Web" NOWAIT 
		ELSE			
			WAIT WINDOW 'Envio Terminado Existencias  ' +ALLTRIM(STR(lntotReg))+" Reg. Enviados" NOWAIT 
		ENDIF 
		lnCt=SQLDISCONNECT(lnsql)
	ELSE 
		WAIT WINDOW 'Error de Coneccion....' NOWAIT 
	ENDIF 
ENDFUNC 
		


FUNCTION enviarDatosProductoPrecios(lcDat)

	lnsql=_conectaweb2(pcPTVDISALRUTA,pcPTVDISALUSER,pcPTVDISALPASS,pcPTVDISALEMPRE)
	
	IF lnsql>0
		WAIT WINDOW 'Preparando datos..... de Precios'  NOWAIT 
		lcComando=''
		SELECT (lcDat)
		lntotReg=RECCOUNT()
		lnpartes=CEILING(lntotReg/500)
		lcCursorWeb ='precios'
		
		FOR i=1 TO lnpartes
			
			lcComando="INSERT INTO "+lcCursorWeb+" (idprecio,codprod,codprecio,nomprecio,precio) "+;
					"VALUES "
				lcComaUnion=""
			
			recini=(i*500)-499
			IF i=lnpartes
				recfin=lntotReg
			ELSE
				recfin=i*500
			ENDIF 
			SCAN for BETWEEN(RECNO(),recini,recfin)
				lcComando=lcComando+lcComaUnion+;
					"('"+ALLTRIM(idprecio)+"',"+;
					"'"+ALLTRIM(_sincomillias(codprod))+"',"+;
					"'"+ALLTRIM(_sincomillias(codprecio))+"',"+;
					"'"+ALLTRIM(_sincomillias(nomprecio))+"',"+;
					""+ALLTRIM(STR(precio,16,6))+" "+;
					")"
				lcComaUnion=","+CHR(13)
			ENDSCAN 
			lcComando=lcComando+" ON DUPLICATE KEY UPDATE "+;
					"nomprecio= VALUES(nomprecio),"+;
					"precio= VALUES(precio)"
		
			WAIT WINDOW 'Enviando Datos.....  '+ ALLTRIM(STR(i))+'/'+ALLTRIM(str(lnpartes))+;
							'   - Reg.:'+ALLTRIM(STR(recini))+' al '+ALLTRIM(STR(recfin))  NOWAIT 
			lnctrl=SQLEXEC(lnsql,lcComando,'')

			IF lnctrl<1
				EXIT 
			ENDIF 
		ENDFOR 
		
		IF lnctrl<1
			WAIT WINDOW "Error al Enviar Datos de Precios a la Web" NOWAIT 
		ELSE			
			WAIT WINDOW 'Envio Terminado  Precios ' +ALLTRIM(STR(lntotReg))+" Reg. Enviados" NOWAIT 
		ENDIF 
		lnCt=SQLDISCONNECT(lnsql)
	ELSE 
		WAIT WINDOW 'Error de Coneccion....' NOWAIT 
	ENDIF 
ENDFUNC 
		


function captureScreen()
	&&capture entier screen
	DECLARE INTEGER keybd_event IN Win32API ;
	      INTEGER, INTEGER, INTEGER, INTEGER
	   KEYEVENTF_KEYUP = 2
	   KEYEVENTF_EXTENDEDKEY = 1
	    VK_SNAPSHOT = 44    && from the winuser.h
	*The following commands copy the entier screen to the 
	*clipboard (the equivalent of PrintScrn): 
	DOEVENTS
	keybd_event( VK_SNAPSHOT, 0, KEYEVENTF_EXTENDEDKEY, 0 )
	keybd_event( VK_SNAPSHOT, 0, KEYEVENTF_EXTENDEDKEY + KEYEVENTF_KEYUP, 0 )
	DOEVENTS
endfunc

function captureWin()
	&&capture active window
	DECLARE INTEGER keybd_event IN Win32API ;
	      INTEGER, INTEGER, INTEGER, INTEGER
	   VK_SNAPSHOT = 44    && from the winuser.h
	   VK_LMENU = 164
	   KEYEVENTF_KEYUP = 2
	   KEYEVENTF_EXTENDEDKEY = 1

	*The following commands copy the active application window to the 
	*clipboard (the equivalent of ALT+PrintScrn):click on the window to getfocus.
	DOEVENTS
	keybd_event( VK_LMENU,    0, KEYEVENTF_EXTENDEDKEY, 0 ) 
	keybd_event( VK_SNAPSHOT, 0, KEYEVENTF_EXTENDEDKEY, 0 )
	keybd_event( VK_SNAPSHOT, 0, KEYEVENTF_EXTENDEDKEY + KEYEVENTF_KEYUP, 0 )
	keybd_event( VK_LMENU,    0, KEYEVENTF_EXTENDEDKEY + KEYEVENTF_KEYUP, 0 )
	DOEVENTS
ENDFUNC

FUNCTION _GuardarImagen()
	CREATE CURSOR MiCursor (MiImagen G)
	BROWSE NOWAIT
	KEYBOARD '{CTRL+Y}'
	KEYBOARD '{CTRL+HOME}'
	KEYBOARD '{CTRL+V}'
	KEYBOARD '{CTRL+W}'
ENDFUNC 


**********************************
**********************************
****** funcion para todo lo relacionado con los DTE

FUNCTION GenerarTablaDTE()
	LPARAMETERS lcNumeroTabla,lcNombreCursor,lcFiltroPadre,lcFiltroBuscar
	IF PCOUNT()<3
		lcFiltroPadre=' '
	ELSE
		IF EMPTY(lcFiltroPadre)
			lcFiltroPadre=''
		ELSE 
			IF lcNumeroTabla='213'
				lcFiltroPadre='and a.padre="'+ALLTRIM(+lcFiltroPadre)+' " '
			ELSE 
				lcFiltroPadre='and a.padre="'+ALLTRIM(+lcFiltroPadre)+' " '
			ENDIF 
		ENDIF 
	ENDIF 
	IF PCOUNT()<4
		lcFiltroBusqueda=''
	ELSE
		IF !EMPTY(lcFiltroBuscar)
			lcFiltroBuscar=quitartildes(lcFiltroBuscar)
			lcFiltroBusqueda=' and '+_BuscarPalabra(UPPER(lcFiltroBuscar),"' '+UPPER(a.coddte)+UPPER(quitartildes(a.valor))")
		ELSE
			lcFiltroBusqueda=' '
		ENDIF 
	ENDIF
	 
	lcAliasDTE=ALIAS()
	USE pcSysDir+pcdb+"\dtecata" IN 0 share AGAIN ALIAS dteTabla
	
	**** Tipo de Retorno codigo
	DO case
		CASE INLIST(VAL(lcNumeroTabla),1)
			lcCampo1='alltrim(a.coddte) as codigo'
		OTHERWISE
			 lcCampo1='alltrim(a.coddte) as codigo'
	ENDCASE 
	
	**** Tipo de Retorno valor
	DO case
		CASE INLIST(VAL(lcNumeroTabla),999)
			lcCampo2=',UPPER(a.valor) as valor'
		OTHERWISE
			 lcCampo2=',UPPER(a.valor) as valor'
	ENDCASE 
	
	**** Tipo de Retorno padre
	DO case
		CASE INLIST(VAL(lcNumeroTabla),13)
			lcCampo3=',alltrim(UPPER(a.padre)) as padre'
		CASE INLIST(VAL(lcNumeroTabla),213)
			lcCampo3=',alltrim(UPPER(a.GRUPO)) as codDistri,alltrim(UPPER(a.padre)) as coddepto,b.valor as departamentoDis'
		CASE INLIST(VAL(lcNumeroTabla),113)
			lcCampo3=',alltrim(UPPER(a.padre)) as coddepto'
		OTHERWISE
			 lcCampo3=''
	ENDCASE 
	
	**** Tipo de Retorno descripcion
	DO case
		CASE INLIST(VAL(lcNumeroTabla),13)
			lcCampo4=',UPPER(NVL(b.valor,"Otro País  "+SPACE(200))) as descripcion'
		CASE INLIST(VAL(lcNumeroTabla),19)
			lcCampo4=',descripcion'
		OTHERWISE
			 lcCampo4=''
	ENDCASE 
	
	**** Unir con otra tabla
	lcInner=''
	DO case
		CASE INLIST(VAL(lcNumeroTabla),13)	&&& Municipio
			lcInner='left join (select ALLTRIM(coddte) as padre,UPPER(valor) as valor from dteTabla  where tipodte="012") as b on a.padre=b.padre '
		CASE INLIST(VAL(lcNumeroTabla),213)	&&& Distrito
			lcInner='left join (select ALLTRIM(coddte) as padre,UPPER(valor) as valor from dteTabla  where tipodte="012") as b on a.padre=b.padre '
		OTHERWISE
			lcInner=''
	ENDCASE 
	
	
	lcCursorDTE='Select '+lcCampo1+lcCampo2+lcCampo3+lcCampo4+;
						' from dteTabla a '+;
							lcInner+;
						'where a.tipodte="'+ALLTRIM(lcNumeroTabla)+'"'+lcFiltroPadre+lcFiltroBusqueda+' into cursor '+lcNombreCursor+' READWRITE'

*_cliptext=lcCursorDTE
	
	&lcCursorDTE

	INDEX on codigo TAG codigo
	IF INLIST(VAL(lcNumeroTabla),213)
		INDEX on coddistri TAG coddistri
	ENDIF 
	SET ORDER TO codigo
	
	IF !EMPTY(lcAliasDTE)
		SELECT (lcAliasDTE)
	ENDIF 
	USE IN DTETabla
	
	RETURN .t.
ENDFUNC 



FUNCTION ValidarActualizarCatalogTablaDTE()
	lcaliasdtetabla=ALIAS()
	USE pcSysDir+pcdb+"\dtecata" IN 0 SHARED AGAIN 
	
	***** si ya esta agregado el codigo extranjero es que ya se actualizo la tabla
	SELECT dtecata
	LOCATE FOR iddte=1648
	
	IF EOF()
		WAIT WINDOW "Actualizando Catalogos de Facturacion Electronica" NOWAIT 
		USE IN dtecata
		USE pcSysDir+pcdb+"\dtecata" IN 0 EXCLUSIVE
		ALTER table dtecata ADD COLUMN grupo c(20) DEFAULT ''
		USE IN dtecata
		
		USE pcSysDir+pcdb+"\cyvclipro" IN 0 SHARED AGAIN 
		**** cambiando codigo pais de los clipro
		REPLA codpais WITH "SV" for codpais="503 "  in cyvclipro
		REPLA codpais WITH "AI" for codpais="9320"  in cyvclipro
		REPLA codpais WITH "TC" for codpais="9539"  in cyvclipro
		REPLA codpais WITH "LT" for codpais="9565"  in cyvclipro
		REPLA codpais WITH "AF" for codpais="9303"  in cyvclipro
		REPLA codpais WITH "AL" for codpais="9306"  in cyvclipro
		REPLA codpais WITH "AD" for codpais="9317"  in cyvclipro
		REPLA codpais WITH "AO" for codpais="9318"  in cyvclipro
		REPLA codpais WITH "AG" for codpais="9319"  in cyvclipro
		REPLA codpais WITH "SA" for codpais="9324"  in cyvclipro
		REPLA codpais WITH "DZ" for codpais="9327"  in cyvclipro
		REPLA codpais WITH "AR" for codpais="9330"  in cyvclipro
		REPLA codpais WITH "AU" for codpais="9333"  in cyvclipro
		REPLA codpais WITH "AT" for codpais="9336"  in cyvclipro
		REPLA codpais WITH "BD" for codpais="9339"  in cyvclipro
		REPLA codpais WITH "BH" for codpais="9342"  in cyvclipro
		REPLA codpais WITH "BB" for codpais="9345"  in cyvclipro
		REPLA codpais WITH "BE" for codpais="9348"  in cyvclipro
		REPLA codpais WITH "BZ" for codpais="9349"  in cyvclipro
		REPLA codpais WITH "BJ" for codpais="9350"  in cyvclipro
		REPLA codpais WITH "BO" for codpais="9357"  in cyvclipro
		REPLA codpais WITH "BW" for codpais="9360"  in cyvclipro
		REPLA codpais WITH "BR" for codpais="9363"  in cyvclipro
		REPLA codpais WITH "BN" for codpais="9366"  in cyvclipro
		REPLA codpais WITH "BI" for codpais="9372"  in cyvclipro
		REPLA codpais WITH "BT" for codpais="9375"  in cyvclipro
		REPLA codpais WITH "CV" for codpais="9377"  in cyvclipro
		REPLA codpais WITH "KH" for codpais="9378"  in cyvclipro
		REPLA codpais WITH "CM" for codpais="9381"  in cyvclipro
		REPLA codpais WITH "CA" for codpais="9384"  in cyvclipro
		REPLA codpais WITH "CO" for codpais="9393"  in cyvclipro
		REPLA codpais WITH "KM" for codpais="9394"  in cyvclipro
		REPLA codpais WITH "CI" for codpais="9408"  in cyvclipro
		REPLA codpais WITH "CR" for codpais="9411"  in cyvclipro
		REPLA codpais WITH "CU" for codpais="9414"  in cyvclipro
		REPLA codpais WITH "TD" for codpais="9417"  in cyvclipro
		REPLA codpais WITH "CL" for codpais="9423"  in cyvclipro
		REPLA codpais WITH "CN" for codpais="9426"  in cyvclipro
		REPLA codpais WITH "CY" for codpais="9432"  in cyvclipro
		REPLA codpais WITH "DK" for codpais="9438"  in cyvclipro
		REPLA codpais WITH "DM" for codpais="9440"  in cyvclipro
		REPLA codpais WITH "EC" for codpais="9444"  in cyvclipro
		REPLA codpais WITH "AE" for codpais="9446"  in cyvclipro
		REPLA codpais WITH "ES" for codpais="9447"  in cyvclipro
		REPLA codpais WITH "ET" for codpais="9453"  in cyvclipro
		REPLA codpais WITH "FJ" for codpais="9456"  in cyvclipro
		REPLA codpais WITH "PH" for codpais="9459"  in cyvclipro
		REPLA codpais WITH "FI" for codpais="9462"  in cyvclipro
		REPLA codpais WITH "FR" for codpais="9465"  in cyvclipro
		REPLA codpais WITH "GA" for codpais="9468"  in cyvclipro
		REPLA codpais WITH "GM" for codpais="9471"  in cyvclipro
		REPLA codpais WITH "GH" for codpais="9474"  in cyvclipro
		REPLA codpais WITH "GI" for codpais="9477"  in cyvclipro
		REPLA codpais WITH "GD" for codpais="9480"  in cyvclipro
		REPLA codpais WITH "GR" for codpais="9481"  in cyvclipro
		REPLA codpais WITH "GT" for codpais="9483"  in cyvclipro
		REPLA codpais WITH "GN" for codpais="9486"  in cyvclipro
		REPLA codpais WITH "GY" for codpais="9487"  in cyvclipro
		REPLA codpais WITH "HT" for codpais="9495"  in cyvclipro
		REPLA codpais WITH "HN" for codpais="9501"  in cyvclipro
		REPLA codpais WITH "HK" for codpais="9504"  in cyvclipro
		REPLA codpais WITH "HU" for codpais="9507"  in cyvclipro
		REPLA codpais WITH "ID" for codpais="9513"  in cyvclipro
		REPLA codpais WITH "IQ" for codpais="9516"  in cyvclipro
		REPLA codpais WITH "IE" for codpais="9522"  in cyvclipro
		REPLA codpais WITH "IS" for codpais="9525"  in cyvclipro
		REPLA codpais WITH "IL" for codpais="9528"  in cyvclipro
		REPLA codpais WITH "IT" for codpais="9531"  in cyvclipro
		REPLA codpais WITH "JM" for codpais="9534"  in cyvclipro
		REPLA codpais WITH "JP" for codpais="9537"  in cyvclipro
		REPLA codpais WITH "JO" for codpais="9540"  in cyvclipro
		REPLA codpais WITH "KE" for codpais="9543"  in cyvclipro
		REPLA codpais WITH "KI" for codpais="9544"  in cyvclipro
		REPLA codpais WITH "KW" for codpais="9546"  in cyvclipro
		REPLA codpais WITH "LA" for codpais="9549"  in cyvclipro
		REPLA codpais WITH "LS" for codpais="9552"  in cyvclipro
		REPLA codpais WITH "LB" for codpais="9555"  in cyvclipro
		REPLA codpais WITH "LR" for codpais="9558"  in cyvclipro
		REPLA codpais WITH "LY" for codpais="9561"  in cyvclipro
		REPLA codpais WITH "LI" for codpais="9564"  in cyvclipro
		REPLA codpais WITH "LU" for codpais="9567"  in cyvclipro
		REPLA codpais WITH "MG" for codpais="9570"  in cyvclipro
		REPLA codpais WITH "MY" for codpais="9573"  in cyvclipro
		REPLA codpais WITH "MW" for codpais="9576"  in cyvclipro
		REPLA codpais WITH "MV" for codpais="9577"  in cyvclipro
		REPLA codpais WITH "MT" for codpais="9582"  in cyvclipro
		REPLA codpais WITH "MA" for codpais="9585"  in cyvclipro
		REPLA codpais WITH "MU" for codpais="9594"  in cyvclipro
		REPLA codpais WITH "MR" for codpais="9597"  in cyvclipro
		REPLA codpais WITH "MX" for codpais="9600"  in cyvclipro
		REPLA codpais WITH "FM" for codpais="9601"  in cyvclipro
		REPLA codpais WITH "MC" for codpais="9603"  in cyvclipro
		REPLA codpais WITH "MN" for codpais="9606"  in cyvclipro
		REPLA codpais WITH "MZ" for codpais="9609"  in cyvclipro
		REPLA codpais WITH "NR" for codpais="9611"  in cyvclipro
		REPLA codpais WITH "NP" for codpais="9612"  in cyvclipro
		REPLA codpais WITH "NI" for codpais="9615"  in cyvclipro
		REPLA codpais WITH "NE" for codpais="9618"  in cyvclipro
		REPLA codpais WITH "NG" for codpais="9621"  in cyvclipro
		REPLA codpais WITH "NO" for codpais="9624"  in cyvclipro
		REPLA codpais WITH "NC" for codpais="9627"  in cyvclipro
		REPLA codpais WITH "NZ" for codpais="9633"  in cyvclipro
		REPLA codpais WITH "PG" for codpais="9638"  in cyvclipro
		REPLA codpais WITH "PK" for codpais="9639"  in cyvclipro
		REPLA codpais WITH "PA" for codpais="9642"  in cyvclipro
		REPLA codpais WITH "PY" for codpais="9645"  in cyvclipro
		REPLA codpais WITH "PE" for codpais="9648"  in cyvclipro
		REPLA codpais WITH "PL" for codpais="9651"  in cyvclipro
		REPLA codpais WITH "QA" for codpais="9660"  in cyvclipro
		REPLA codpais WITH "GB" for codpais="9663"  in cyvclipro
		REPLA codpais WITH "EG" for codpais="9666"  in cyvclipro
		REPLA codpais WITH "RW" for codpais="9672"  in cyvclipro
		REPLA codpais WITH "RO" for codpais="9675"  in cyvclipro
		REPLA codpais WITH "SM" for codpais="9677"  in cyvclipro
		REPLA codpais WITH "LC" for codpais="9680"  in cyvclipro
		REPLA codpais WITH "SN" for codpais="9681"  in cyvclipro
		REPLA codpais WITH "ST" for codpais="9682"  in cyvclipro
		REPLA codpais WITH "SL" for codpais="9684"  in cyvclipro
		REPLA codpais WITH "SG" for codpais="9687"  in cyvclipro
		REPLA codpais WITH "SY" for codpais="9690"  in cyvclipro
		REPLA codpais WITH "SC" for codpais="9691"  in cyvclipro
		REPLA codpais WITH "SO" for codpais="9693"  in cyvclipro
		REPLA codpais WITH "ZA" for codpais="9696"  in cyvclipro
		REPLA codpais WITH "SD" for codpais="9699"  in cyvclipro
		REPLA codpais WITH "SE" for codpais="9702"  in cyvclipro
		REPLA codpais WITH "CH" for codpais="9705"  in cyvclipro
		REPLA codpais WITH "SR" for codpais="9706"  in cyvclipro
		REPLA codpais WITH "LK" for codpais="9707"  in cyvclipro
		REPLA codpais WITH "TZ" for codpais="9714"  in cyvclipro
		REPLA codpais WITH "TG" for codpais="9717"  in cyvclipro
		REPLA codpais WITH "TT" for codpais="9720"  in cyvclipro
		REPLA codpais WITH "TO" for codpais="9722"  in cyvclipro
		REPLA codpais WITH "TN" for codpais="9723"  in cyvclipro
		REPLA codpais WITH "TR" for codpais="9726"  in cyvclipro
		REPLA codpais WITH "TV" for codpais="9727"  in cyvclipro
		REPLA codpais WITH "UG" for codpais="9729"  in cyvclipro
		REPLA codpais WITH "UY" for codpais="9735"  in cyvclipro
		REPLA codpais WITH "VU" for codpais="9739"  in cyvclipro
		REPLA codpais WITH "VE" for codpais="9741"  in cyvclipro
		REPLA codpais WITH "YE" for codpais="9750"  in cyvclipro
		REPLA codpais WITH "ZM" for codpais="9759"  in cyvclipro
		REPLA codpais WITH "ZW" for codpais="9760"  in cyvclipro
		REPLA codpais WITH "PR" for codpais="9850"  in cyvclipro
		REPLA codpais WITH "BS" for codpais="9862"  in cyvclipro
		REPLA codpais WITH "BM" for codpais="9863"  in cyvclipro
		REPLA codpais WITH "MQ" for codpais="9865"  in cyvclipro
		REPLA codpais WITH "TW" for codpais="9899"  in cyvclipro
		REPLA codpais WITH "VG" for codpais="9897"  in cyvclipro
		REPLA codpais WITH "MK" for codpais="9571"  in cyvclipro
		REPLA codpais WITH "SV" for codpais="9300"  in cyvclipro
		REPLA codpais WITH "BG" for codpais="9369"  in cyvclipro
		REPLA codpais WITH "DJ" for codpais="9439"  in cyvclipro
		REPLA codpais WITH "IN" for codpais="9510"  in cyvclipro
		REPLA codpais WITH "ML" for codpais="9579"  in cyvclipro
		REPLA codpais WITH "PT" for codpais="9654"  in cyvclipro
		REPLA codpais WITH "TH" for codpais="9711"  in cyvclipro
		REPLA codpais WITH "UA" for codpais="9736"  in cyvclipro
		REPLA codpais WITH "UZ" for codpais="9737"  in cyvclipro
		REPLA codpais WITH "PS" for codpais="9640"  in cyvclipro
		REPLA codpais WITH "HR" for codpais="9641"  in cyvclipro
		REPLA codpais WITH "GE" for codpais="9472"  in cyvclipro
		REPLA codpais WITH "DE" for codpais="9311"  in cyvclipro
		REPLA codpais WITH "RU" for codpais="9733"  in cyvclipro
		REPLA codpais WITH "KZ" for codpais="9541"  in cyvclipro
		REPLA codpais WITH "VN" for codpais="9746"  in cyvclipro
		REPLA codpais WITH "LV" for codpais="9551"  in cyvclipro
		REPLA codpais WITH "SI" for codpais="9451"  in cyvclipro
		REPLA codpais WITH "AZ" for codpais="9338"  in cyvclipro
		REPLA codpais WITH "BY" for codpais="9353"  in cyvclipro
		REPLA codpais WITH "GL" for codpais="9482"  in cyvclipro
		REPLA codpais WITH "GW" for codpais="9494"  in cyvclipro
		REPLA codpais WITH "CC" for codpais="9524"  in cyvclipro
		REPLA codpais WITH "AX" for codpais="9304"  in cyvclipro
		REPLA codpais WITH "AW" for codpais="9332"  in cyvclipro
		REPLA codpais WITH "ER" for codpais="9454"  in cyvclipro
		REPLA codpais WITH "EE" for codpais="9457"  in cyvclipro
		REPLA codpais WITH "GP" for codpais="9489"  in cyvclipro
		REPLA codpais WITH "GF" for codpais="9491"  in cyvclipro
		REPLA codpais WITH "GG" for codpais="9492"  in cyvclipro
		REPLA codpais WITH "MP" for codpais="9535"  in cyvclipro
		REPLA codpais WITH "UM" for codpais="9542"  in cyvclipro
		REPLA codpais WITH "JE" for codpais="9547"  in cyvclipro
		REPLA codpais WITH "KG" for codpais="9548"  in cyvclipro
		REPLA codpais WITH "YT" for codpais="9598"  in cyvclipro
		REPLA codpais WITH "MD" for codpais="9602"  in cyvclipro
		REPLA codpais WITH "ME" for codpais="9607"  in cyvclipro
		REPLA codpais WITH "MS" for codpais="9608"  in cyvclipro
		REPLA codpais WITH "PF" for codpais="9652"  in cyvclipro
		REPLA codpais WITH "SJ" for codpais="9692"  in cyvclipro
		REPLA codpais WITH "TJ" for codpais="9709"  in cyvclipro
		REPLA codpais WITH "IO" for codpais="9712"  in cyvclipro
		REPLA codpais WITH "TL" for codpais="9716"  in cyvclipro
		REPLA codpais WITH "TK" for codpais="9718"  in cyvclipro
		REPLA codpais WITH "TM" for codpais="9719"  in cyvclipro
		REPLA codpais WITH "WF" for codpais="9452"  in cyvclipro
		REPLA codpais WITH "CZ" for codpais="9664"  in cyvclipro
		REPLA codpais WITH "CW" for codpais="9415"  in cyvclipro
		REPLA codpais WITH "BA" for codpais="9359"  in cyvclipro
		REPLA codpais WITH "GQ" for codpais="9493"  in cyvclipro
		REPLA codpais WITH "IM" for codpais="9521"  in cyvclipro
		REPLA codpais WITH "FK" for codpais="9533"  in cyvclipro
		REPLA codpais WITH "PN" for codpais="9538"  in cyvclipro
		REPLA codpais WITH "RS" for codpais="9689"  in cyvclipro
		REPLA codpais WITH "TF" for codpais="9713"  in cyvclipro
		REPLA codpais WITH "SK" for codpais="9449"  in cyvclipro
		REPLA codpais WITH "GU" for codpais="9490"  in cyvclipro
		REPLA codpais WITH "CK" for codpais="9527"  in cyvclipro
		REPLA codpais WITH "FO" for codpais="9529"  in cyvclipro
		REPLA codpais WITH "MH" for codpais="9536"  in cyvclipro
		REPLA codpais WITH "VI" for codpais="9545"  in cyvclipro
		REPLA codpais WITH "MO" for codpais="9568"  in cyvclipro
		REPLA codpais WITH "NA" for codpais="9610"  in cyvclipro
		REPLA codpais WITH "NU" for codpais="9622"  in cyvclipro
		REPLA codpais WITH "PW" for codpais="9643"  in cyvclipro
		REPLA codpais WITH "RE" for codpais="9667"  in cyvclipro
		REPLA codpais WITH "EH" for codpais="9676"  in cyvclipro
		REPLA codpais WITH "AS" for codpais="9685"  in cyvclipro
		REPLA codpais WITH "PM" for codpais="9686"  in cyvclipro
		REPLA codpais WITH "SH" for codpais="9688"  in cyvclipro
		REPLA codpais WITH "BF" for codpais="9371"  in cyvclipro
		USE IN cyvclipro

		USE pcSysDir+pcdb+"\dtecata" IN 0 SHARED AGAIN 
		
		DELETE FROM dtecata WHERE tipodte='009' AND coddte='20' 
		DELETE FROM dtecata WHERE tipodte='017' AND coddte='06' 
		DELETE FROM dtecata WHERE tipodte='017' AND coddte='10' 
		***** distritos
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1648,'012','00','Otros (Extranjeros)','00')
		
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1649,"113","00","Otros (Extranjeros)","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1650,"113","13","Ahuachapán Norte","01")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1651,"113","14","Ahuachapán Centro","01")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1652,"113","15","Ahuachapán Sur","01")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1653,"113","14","Santa Ana Norte","02")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1654,"113","15","Santa Ana Centro","02")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1655,"113","16","Santa Ana Este","02")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1656,"113","17","Santa Ana Oeste","02")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1657,"113","17","Sonsonate Norte","03")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1658,"113","18","Sonsonate Centro","03")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1659,"113","19","Sonsonate Este","03")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1660,"113","20","Sonsonate Oeste","03")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1661,"113","34","Chalatenango Norte","04")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1662,"113","35","Chalatenango Centro","04")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1663,"113","36","Chalatenango Sur","04")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1664,"113","23","La Libertad Norte","05")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1665,"113","24","La Libertad Centro","05")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1666,"113","25","La Libertad Oeste","05")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1667,"113","26","La Libertad Este","05")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1668,"113","27","La Libertad Costa","05")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1669,"113","28","La Libertad Sur","05")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1670,"113","20","San Salvador Norte","06")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1671,"113","21","San Salvador Oeste","06")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1672,"113","22","San Salvador Este","06")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1673,"113","23","San Salvador Centro","06")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1674,"113","24","San Salvador Sur","06")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1675,"113","17","Cuscatlán Norte","07")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1676,"113","18","Cuscatlán Sur","07")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1677,"113","23","La Paz Oeste","08")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1678,"113","24","La Paz Centro","08")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1679,"113","25","La Paz Este","08")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1680,"113","10","Cabañas Oeste","09")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1681,"113","11","Cabañas Este","09")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1682,"113","14","San Vicente Norte","10")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1683,"113","15","San Vicente Sur","10")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1684,"113","24","Usulután Norte","11")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1685,"113","25","Usulután Este","11")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1686,"113","26","Usulután Oeste","11")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1687,"113","21","San Miguel Norte","12")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1688,"113","22","San Miguel Centro","12")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1689,"113","23","San Miguel Oeste","12")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1690,"113","27","Morazán Norte","13")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1691,"113","28","Morazán Sur","13")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1692,"113","19","La Unión Norte","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1693,"113","20","La Unión Sur","17")
		
		*** municipios - distritos
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1694,"213","03","Atiquizaya, Distrito de Ahuachapán Norte","01","13")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1695,"213","05","El Refugio, Distrito de Ahuachapán Norte","01","13")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1696,"213","09","San Lorenzo, Distrito de Ahuachapán Norte","01","13")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1697,"213","12","Turín, Distrito de Ahuachapán Norte","01","13")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1698,"213","01","Ahuachapán, Distrito de Ahuachapán Centro","01","14")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1699,"213","02","Apaneca, Distrito de Ahuachapán Centro","01","14")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1700,"213","04","Concepción de Ataco, Distrito de Ahuachapán Centro","01","14")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1701,"213","11","Tacuba, Distrito de Ahuachapán Centro","01","14")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1702,"213","06","Guaymango, Distrito de Ahuachapán Sur","01","15")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1703,"213","07","Jujutla, Distrito de Ahuachapán Sur","01","15")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1704,"213","08","San Francisco Menendez, Distrito de Ahuachapán Sur","01","15")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1705,"213","10","San Pedro Puxtla, Distrito de Ahuachapán Sur","01","15")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1706,"213","02","Coatepeque, Distrito de Santa Ana Este","02","16")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1707,"213","04","El Congo, Distrito de Santa Ana Este","02","16")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1708,"213","01","Candelaria de la Frontera, Distrito de Santa Ana Oeste","02","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1709,"213","03","Chalchuapa, Distrito de Santa Ana Oeste","02","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1710,"213","05","El Porvenir, Distrito de Santa Ana Oeste","02","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1711,"213","08","San Antonio Pajonal, Distrito de Santa Ana Oeste","02","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1712,"213","09","San Sebastián Salitrillo, Distrito de Santa Ana Oeste","02","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1713,"213","12","Santiago de La Frontera, Distrito de Santa Ana Oeste","02","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1714,"213","06","Masahuat, Distrito de Santa Ana Norte","02","14")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1715,"213","07","Metapán, Distrito de Santa Ana Norte","02","14")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1716,"213","11","Santa Rosa Guachipilín, Distrito de Santa Ana Norte","02","14")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1717,"213","13","Texistepeque, Distrito de Santa Ana Norte","02","14")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1718,"213","10","Santa Ana, Distrito de Santa Ana Centro","02","15")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1719,"213","07","Juayúa, Distrito de Sonsonate Norte","03","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1720,"213","08","Nahuizalco, Distrito de Sonsonate Norte","03","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1721,"213","09","Nahulingo, Distrito de Sonsonate Norte","03","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1722,"213","10","Salcoatitán, Distrito de Sonsonate Norte","03","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1723,"213","11","San Antonio del Monte, Distrito de Sonsonate Norte","03","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1724,"213","13","Santa Catarina Masahuat, Distrito de Sonsonate Norte","03","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1725,"213","14","Santo Domingo de Guzmán, Distrito de Sonsonate Norte","03","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1726,"213","15","Sonsonate, Distrito de Sonsonate Norte","03","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1727,"213","16","Sonzacate, Distrito de Sonsonate Norte","03","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1728,"213","02","Armenia, Distrito de Sonsonate Este","03","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1729,"213","03","Caluco, Distrito de Sonsonate Este","03","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1730,"213","04","Cuisnahuat, Distrito de Sonsonate Este","03","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1731,"213","05","Santa Isabel lshuatán, Distrito de Sonsonate Este","03","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1732,"213","06","lzalco, Distrito de Sonsonate Este","03","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1733,"213","12","San Julián, Distrito de Sonsonate Este","03","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1734,"213","01","Acajutla, Distrito de Sonsonate Oeste","03","20")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1735,"213","04","Citalá, Distrito de Chalatenango Norte","04","34")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1736,"213","12","La Palma, Distrito de Chalatenango Norte","04","34")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1737,"213","25","San Ignacio, Distrito de Chalatenango Norte","04","34")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1738,"213","01","Agua Caliente, Distrito de Chalatenango Centro","04","35")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1739,"213","08","Dulce Nombre de María, Distrito de Chalatenango Centro","04","35")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1740,"213","10","El Paraíso, Distrito de Chalatenango Centro","04","35")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1741,"213","13","La Reina, Distrito de Chalatenango Centro","04","35")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1742,"213","16","Nueva Concepción, Distrito de Chalatenango Centro","04","35")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1743,"213","22","San Fernando, Distrito de Chalatenango Centro","04","35")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1744,"213","24","San Francisco Morazán, Distrito de Chalatenango Centro","04","35")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1745,"213","31","San Rafael, Distrito de Chalatenango Centro","04","35")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1746,"213","32","Santa Rita, Distrito de Chalatenango Centro","04","35")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1747,"213","33","Tejutla, Distrito de Chalatenango Centro","04","35")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1748,"213","02","Arcatao, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1749,"213","03","Azacualpa, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1750,"213","05","Comalapa, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1751,"213","06","Concepción Quezaltepeque, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1752,"213","07","Chalatenango, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1753,"213","09","El Carrizal, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1754,"213","11","La Laguna, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1755,"213","14","Las Vueltas, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1756,"213","15","Nombre de Jesús, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1757,"213","17","Nueva Trinidad, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1758,"213","18","Ojos de Agua, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1759,"213","19","Potonico, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1760,"213","20","San Antonio de La Cruz, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1761,"213","21","San Antonio Los Ranchos, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1762,"213","23","San Francisco Lempa, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1763,"213","26","San Isidro Labrador, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1764,"213","27","San José Cancasque, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1765,"213","28","San José Las Flores, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1766,"213","29","San Luis del Carmen, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1767,"213","30","San Miguel de Mercedes, Distrito de Chalatenango Sur","04","36")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1768,"213","12","Quezaltepeque, Distrito de La Libertad Norte","05","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1769,"213","16","San Matías, Distrito de La Libertad Norte","05","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1770,"213","17","San Pablo Tacachico, Distrito de La Libertad Norte","05","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1771,"213","02","Ciudad Arce, Distrito de La Libertad Centro","05","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1772,"213","15","San Juan Opico, Distrito de La Libertad Centro","05","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1773,"213","03","Colón, Distrito de La Libertad Oeste","05","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1774,"213","07","Jayaque, Distrito de La Libertad Oeste","05","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1775,"213","13","Sacacoyo, Distrito de La Libertad Oeste","05","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1776,"213","19","Talnique, Distrito de La Libertad Oeste","05","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1777,"213","21","Tepecoyo, Distrito de La Libertad Oeste","05","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1778,"213","01","Antiguo Cuscatlán, Distrito de La Libertad Este","05","26")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1779,"213","06","Huizucar, Distrito de La Libertad Este","05","26")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1780,"213","10","Nuevo Cuscatlán, Distrito de La Libertad Este","05","26")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1781,"213","14","San José Villanueva, Distrito de La Libertad Este","05","26")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1782,"213","22","Zaragoza, Distrito de La Libertad Este","05","26")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1783,"213","05","Chiltuipán, Distrito de La Libertad Costa","05","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1784,"213","08","Jicalapa, Distrito de La Libertad Costa","05","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1785,"213","09","La Libertad, Distrito de La Libertad Costa","05","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1786,"213","18","Tamanique, Distrito de La Libertad Costa","05","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1787,"213","20","Teotepeque, Distrito de La Libertad Costa","05","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1788,"213","04","Comasagua, Distrito de La Libertad Sur","05","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1789,"213","11","Santa Tecla, Distrito de La Libertad Sur","05","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1790,"213","01","Aguilares, Distrito de San Salvador Norte","06","20")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1791,"213","05","El Paisnal, Distrito de San Salvador Norte","06","20")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1792,"213","06","Guazapa, Distrito de San Salvador Norte","06","20")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1793,"213","02","Apopa, Distrito de San Salvador Oeste","06","21")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1794,"213","09","Nejapa, Distrito de San Salvador Oeste","06","21")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1795,"213","07","llopango, Distrito de San Salvador Este","06","22")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1796,"213","13","San Martín, Distrito de San Salvador Este","06","22")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1797,"213","17","Soyapango, Distrito de San Salvador Este","06","22")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1798,"213","18","Tonacatepeque, Distrito de San Salvador Este","06","22")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1799,"213","03","Ayutuxtepeque, Distrito de San Salvador Centro","06","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1800,"213","04","Cuscatancingo, Distrito de San Salvador Centro","06","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1801,"213","08","Mejicanos, Distrito de San Salvador Centro","06","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1802,"213","14","San Salvador, Distrito de San Salvador Centro","06","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1803,"213","19","Ciudad Delgado, Distrito de San Salvador Centro","06","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1804,"213","10","Panchimalco, Distrito de San Salvador Sur","06","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1805,"213","11","Rosario de Mora, Distrito de San Salvador Sur","06","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1806,"213","12","San Marcos, Distrito de San Salvador Sur","06","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1807,"213","15","Santiago Texacuangos, Distrito de San Salvador Sur","06","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1808,"213","16","Santo Tomás, Distrito de San Salvador Sur","06","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1809,"213","06","Oratorio de Concepción, Distrito de Cuscatlán Norte","07","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1810,"213","07","San Bartolomé Perulapán, Distrito de Cuscatlán Norte","07","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1811,"213","09","San José Guayabal, Distrito de Cuscatlán Norte","07","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1812,"213","10","San Pedro Perulapán, Distrito de Cuscatlán Norte","07","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1813,"213","15","Suchitoto, Distrito de Cuscatlán Norte","07","17")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1814,"213","01","Candelaria, Distrito de Cuscatlán Sur","07","18")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1815,"213","02","Cojutepeque, Distrito de Cuscatlán Sur","07","18")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1816,"213","03","El Carmen, Distrito de Cuscatlán Sur","07","18")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1817,"213","04","El Rosario, Distrito de Cuscatlán Sur","07","18")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1818,"213","05","Monte San Juan, Distrito de Cuscatlán Sur","07","18")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1819,"213","08","San Cristóbal, Distrito de Cuscatlán Sur","07","18")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1820,"213","11","San Rafael Cedros, Distrito de Cuscatlán Sur","07","18")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1821,"213","12","San Ramón, Distrito de Cuscatlán Sur","07","18")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1822,"213","13","Santa Cruz Analquito, Distrito de Cuscatlán Sur","07","18")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1823,"213","14","Santa Cruz Michapa, Distrito de Cuscatlán Sur","07","18")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1824,"213","16","Tenancingo, Distrito de Cuscatlán Sur","07","18")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1825,"213","01","Cuyultitán, Distrito de La Paz Oeste","08","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1826,"213","05","Olocuilta, Distrito de La Paz Oeste","08","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1827,"213","09","San Francisco Chinameca, Distrito de La Paz Oeste","08","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1828,"213","11","San Juan Talpa, Distrito de La Paz Oeste","08","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1829,"213","13","San Luis Talpa, Distrito de La Paz Oeste","08","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1830,"213","15","San Pedro Masahuat, Distrito de La Paz Oeste","08","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1831,"213","20","Tapalhuaca, Distrito de La Paz Oeste","08","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1832,"213","02","El Rosario, Distrito de La Paz Centro","08","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1833,"213","03","Jerusalén, Distrito de La Paz Centro","08","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1834,"213","04","Mercedes La Ceiba, Distrito de La Paz Centro","08","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1835,"213","06","Paraíso de Osorio, Distrito de La Paz Centro","08","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1836,"213","07","San Antonio Masahuat, Distrito de La Paz Centro","08","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1837,"213","08","San Emigdio, Distrito de La Paz Centro","08","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1838,"213","12","San Juan Tepezontes, Distrito de La Paz Centro","08","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1839,"213","14","San Miguel Tepezontes, Distrito de La Paz Centro","08","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1840,"213","16","San Pedro Nonualco, Distrito de La Paz Centro","08","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1841,"213","18","Santa María Ostuma, Distrito de La Paz Centro","08","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1842,"213","19","Santiago Nonualco, Distrito de La Paz Centro","08","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1843,"213","22","San Luis La Herradura, Distrito de La Paz Centro","08","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1844,"213","10","San Juan Nonualco, Distrito de La Paz Este","08","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1845,"213","17","San Rafael Obrajuelo, Distrito de La Paz Este","08","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1846,"213","21","Zacatecoluca, Distrito de La Paz Este","08","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1847,"213","02","Guacotecti, Distrito de Cabañas Este","09","10")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1848,"213","05","San Isidro, Distrito de Cabañas Este","09","10")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1849,"213","06","Sensuntepeque, Distrito de Cabañas Este","09","10")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1850,"213","08","Victoria, Distrito de Cabañas Este","09","10")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1851,"213","09","Dolores, Distrito de Cabañas Este","09","10")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1852,"213","01","Cinquera, Distrito de Cabañas Oeste","09","11")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1853,"213","03","llobasco, Distrito de Cabañas Oeste","09","11")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1854,"213","04","Jutiapa, Distrito de Cabañas Oeste","09","11")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1855,"213","07","Tejutepeque, Distrito de Cabañas Oeste","09","11")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1856,"213","01","Apastepeque, Distrito de San Vicente Norte","10","14")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1857,"213","04","Santa Clara, Distrito de San Vicente Norte","10","14")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1858,"213","05","Santo Domingo, Distrito de San Vicente Norte","10","14")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1859,"213","06","San Esteban Catarina, Distrito de San Vicente Norte","10","14")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1860,"213","07","San Ildefonso, Distrito de San Vicente Norte","10","14")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1861,"213","08","San Lorenzo, Distrito de San Vicente Norte","10","14")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1862,"213","09","San Sebastián, Distrito de San Vicente Norte","10","14")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1863,"213","02","Guadalupe, Distrito de San Vicente Sur","10","15")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1864,"213","03","San Cayetano lstepeque, Distrito de San Vicente Sur","10","15")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1865,"213","10","San Vicente, Distrito de San Vicente Sur","10","15")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1866,"213","11","Tecoluca, Distrito de San Vicente Sur","10","15")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1867,"213","12","Tepetitán, Distrito de San Vicente Sur","10","15")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1868,"213","13","Verapaz, Distrito de San Vicente Sur","10","15")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1869,"213","11","Mercedes Umana, Distrito de Usulután Norte","11","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1870,"213","01","Alegría, Distrito de Usulután Norte","11","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1871,"213","02","Berlín, Distrito de Usulután Norte","11","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1872,"213","05","El Triunfo, Distrito de Usulután Norte","11","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1873,"213","07","Estanzuelas, Distrito de Usulután Norte","11","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1874,"213","09","Jucuapa, Distrito de Usulután Norte","11","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1875,"213","12","Nueva Granada, Distrito de Usulután Norte","11","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1876,"213","16","San Buenaventura, Distrito de Usulután Norte","11","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1877,"213","21","Santiago de María, Distrito de Usulután Norte","11","24")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1878,"213","03","California, Distrito de Usulután Este","11","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1879,"213","04","Concepción Batres, Distrito de Usulután Este","11","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1880,"213","06","Ereguayquín, Distrito de Usulután Este","11","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1881,"213","10","Jucuarán, Distrito de Usulután Este","11","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1882,"213","13","Ozatlán, Distrito de Usulután Este","11","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1883,"213","17","San Dionisio, Distrito de Usulután Este","11","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1884,"213","18","Santa María, Distrito de Usulután Este","11","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1885,"213","18","Santa Elena, Distrito de Usulután Este","11","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1886,"213","22","Tecapán, Distrito de Usulután Este","11","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1887,"213","23","Usulután, Distrito de Usulután Este","11","25")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1888,"213","08","Jiquilisco, Distrito de Usulután Oeste","11","26")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1889,"213","14","Puerto El Triunfo, Distrito de Usulután Oeste","11","26")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1890,"213","15","San Agustín, Distrito de Usulután Oeste","11","26")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1891,"213","19","San Francisco Javier, Distrito de Usulután Oeste","11","26")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1892,"213","01","Carolina, Distrito de San Miguel Norte","12","21")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1893,"213","02","Ciudad Barrios, Distrito de San Miguel Norte","12","21")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1894,"213","04","Chapeltique, Distrito de San Miguel Norte","12","21")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1895,"213","11","Nuevo Edén de San Juan, Distrito de San Miguel Norte","12","21")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1896,"213","14","San Gerardo, Distrito de San Miguel Norte","12","21")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1897,"213","16","San Luis de La Reina, Distrito de San Miguel Norte","12","21")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1898,"213","19","Sesori, Distrito de San Miguel Norte","12","21")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1899,"213","13","San Antonio del Mosco, Distrito de San Miguel Norte","12","21")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1900,"213","03","Comacarán, Distrito de San Miguel Centro","12","22")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1901,"213","06","Chirilagua, Distrito de San Miguel Centro","12","22")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1902,"213","09","Moncagua, Distrito de San Miguel Centro","12","22")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1903,"213","12","Quelepa, Distrito de San Miguel Centro","12","22")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1904,"213","17","San Miguel, Distrito de San Miguel Centro","12","22")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1905,"213","20","Uluazapa, Distrito de San Miguel Centro","12","22")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1906,"213","05","Chinameca, Distrito de San Miguel Oeste","12","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1907,"213","07","El Tránsito, Distrito de San Miguel Oeste","12","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1908,"213","08","Lolotique, Distrito de San Miguel Oeste","12","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1909,"213","10","Nueva Guadalupe, Distrito de San Miguel Oeste","12","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1910,"213","15","San Jorge, Distrito de San Miguel Oeste","12","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1911,"213","18","San Rafael Oriente, Distrito de San Miguel Oeste","12","23")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1912,"213","01","Arambala, Distrito de Morazán Norte","13","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1913,"213","02","Cacaopera, Distrito de Morazán Norte","13","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1914,"213","03","Corinto, Distrito de Morazán Norte","13","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1915,"213","04","El Rosario, Distrito de Morazán Norte","13","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1916,"213","10","Joateca, Distrito de Morazán Norte","13","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1917,"213","11","Jocoaitique, Distrito de Morazán Norte","13","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1918,"213","14","Meanguera, Distrito de Morazán Norte","13","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1919,"213","16","Perquín, Distrito de Morazán Norte","13","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1920,"213","22","San Fernando, Distrito de Morazán Norte","13","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1921,"213","24","Torola, Distrito de Morazán Norte","13","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1922,"213","26","San Isidro, Distrito de Morazán Norte","13","27")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1923,"213","04","Chilanga, Distrito de Morazán Sur","13","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1924,"213","05","Delicias de Concepción, Distrito de Morazán Sur","13","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1925,"213","06","El Divisadero, Distrito de Morazán Sur","13","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1926,"213","08","Gualococti, Distrito de Morazán Sur","13","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1927,"213","09","Guatajiagua, Distrito de Morazán Sur","13","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1928,"213","12","Jocoro, Distrito de Morazán Sur","13","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1929,"213","13","Lolotiquillo, Distrito de Morazán Sur","13","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1930,"213","15","Osicala, Distrito de Morazán Sur","13","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1931,"213","17","San Carlos, Distrito de Morazán Sur","13","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1932,"213","19","San Francisco Gotera, Distrito de Morazán Sur","13","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1933,"213","21","San Simón, Distrito de Morazán Sur","13","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1934,"213","22","Sensembra, Distrito de Morazán Sur","13","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1935,"213","23","Sociedad, Distrito de Morazán Sur","13","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1936,"213","25","Yamabal, Distrito de Morazán Sur","13","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1937,"213","26","Yoloaiquín, Distrito de Morazán Sur","13","28")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1938,"213","01","Anamorós, Distrito de La Unión Norte","14","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1939,"213","02","Bolivar, Distrito de La Unión Norte","14","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1940,"213","03","Concepción de Oriente, Distrito de La Unión Norte","14","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1941,"213","06","El Sauce, Distrito de La Unión Norte","14","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1942,"213","09","Lislique, Distrito de La Unión Norte","14","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1943,"213","11","Nueva Esparta, Distrito de La Unión Norte","14","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1944,"213","12","Pasaquina, Distrito de La Unión Norte","14","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1945,"213","13","Polorós, Distrito de La Unión Norte","14","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1946,"213","16","Santa Rosa de Lima, Distrito de La Unión Norte","14","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1947,"213","15","San José La Fuente, Distrito de La Unión Norte","14","19")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1948,"213","04","Conchagua, Distrito de La Unión Sur","14","20")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1949,"213","05","El Carmen, Distrito de La Unión Sur","14","20")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1950,"213","07","lntipucá, Distrito de La Unión Sur","14","20")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1951,"213","08","La Unión, Distrito de La Unión Sur","14","20")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1952,"213","10","Meanguera del Golfo, Distrito de La Unión Sur","14","20")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1953,"213","14","San Alejo, Distrito de La Unión Sur","14","20")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1954,"213","17","Yayantique, Distrito de La Unión Sur","14","20")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,grupo) VALUES (1955,"213","18","Yucuaiquín, Distrito de La Unión Sur","14","20")



		*****014 medidas
		DELETE FOR iddte=323 IN DTECATA
		DELETE FOR iddte=324 IN DTECATA
		DELETE FOR iddte=325 IN DTECATA
		DELETE FOR iddte=327 IN DTECATA
		DELETE FOR iddte=330 IN DTECATA
		DELETE FOR iddte=331 IN DTECATA
		DELETE FOR iddte=333 IN DTECATA
		DELETE FOR iddte=335 IN DTECATA
		DELETE FOR iddte=336 IN DTECATA
		DELETE FOR iddte=338 IN DTECATA
		DELETE FOR iddte=340 IN DTECATA
		DELETE FOR iddte=344 IN DTECATA
		DELETE FOR iddte=346 IN DTECATA
		DELETE FOR iddte=347 IN DTECATA
		DELETE FOR iddte=349 IN DTECATA
		DELETE FOR iddte=353 IN DTECATA



		*** correccion de giros
*!*			REPLACE coddte WITH '15941' FOR iddte=586
*!*			REPLACE coddte WITH '15942' FOR iddte=587
*!*			REPLACE coddte WITH '15948' FOR iddte=588
*!*			REPLACE coddte WITH '15991' FOR iddte=589
*!*			REPLACE coddte WITH '15992' FOR iddte=590
*!*			REPLACE coddte WITH '15999' FOR iddte=591
*!*			REPLACE coddte WITH '46579' FOR iddte=822
*!*			REPLACE coddte WITH '46591' FOR iddte=823
*!*			REPLACE coddte WITH '46415' FOR iddte=831
*!*			REPLACE coddte WITH '46595' FOR iddte=862
*!*			REPLACE coddte WITH '46615' FOR iddte=871	
*!*			REPLACE coddte WITH '47500' FOR iddte=916
*!*			REPLACE coddte WITH '47754' FOR iddte=945
*!*			REPLACE coddte WITH '47755' FOR iddte=946
*!*			REPLACE coddte WITH '47759' FOR iddte=950
*!*			REPLACE coddte WITH '47745' FOR iddte=953
*!*			REPLACE coddte WITH '49215' FOR iddte=981
*!*			REPLACE coddte WITH '50110' FOR iddte=995

		***** giros
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,descripcion) VALUES (1956,"019","53201","Agencia privada de correo y encomiendas","53",'ACTIVIDADES POSTALES Y DE MENSAJERÍA')
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre,descripcion) VALUES (1957,"019","10006","Comerciante","10",'EMPLEADOS Y OTRAS PERSONAS NATURALES')
		
		REPLACE coddte WITH '0'+coddte FOR LEN(ALLTRIM(coddte))=4
		
		**** tabla paises
		REPLA CODDTE WITH "AI" for iddte=       1220 in dtecata
		REPLA CODDTE WITH "TC" for iddte=       1221 in dtecata
		REPLA CODDTE WITH "LT" for iddte=       1222 in dtecata
		REPLA CODDTE WITH "AF" for iddte=       1225 in dtecata
		REPLA CODDTE WITH "AL" for iddte=       1226 in dtecata
		REPLA CODDTE WITH "AD" for iddte=       1230 in dtecata
		REPLA CODDTE WITH "AO" for iddte=       1231 in dtecata
		REPLA CODDTE WITH "AG" for iddte=       1232 in dtecata
		REPLA CODDTE WITH "SA" for iddte=       1233 in dtecata
		REPLA CODDTE WITH "DZ" for iddte=       1234 in dtecata
		REPLA CODDTE WITH "AR" for iddte=       1235 in dtecata
		REPLA CODDTE WITH "AU" for iddte=       1236 in dtecata
		REPLA CODDTE WITH "AT" for iddte=       1237 in dtecata
		REPLA CODDTE WITH "BD" for iddte=       1238 in dtecata
		REPLA CODDTE WITH "BH" for iddte=       1239 in dtecata
		REPLA CODDTE WITH "BB" for iddte=       1240 in dtecata
		REPLA CODDTE WITH "BE" for iddte=       1241 in dtecata
		REPLA CODDTE WITH "BZ" for iddte=       1242 in dtecata
		REPLA CODDTE WITH "BJ" for iddte=       1243 in dtecata
		REPLA CODDTE WITH "BO" for iddte=       1245 in dtecata
		REPLA CODDTE WITH "BW" for iddte=       1246 in dtecata
		REPLA CODDTE WITH "BR" for iddte=       1247 in dtecata
		REPLA CODDTE WITH "BN" for iddte=       1248 in dtecata
		REPLA CODDTE WITH "BI" for iddte=       1249 in dtecata
		REPLA CODDTE WITH "BT" for iddte=       1251 in dtecata
		REPLA CODDTE WITH "CV" for iddte=       1252 in dtecata
		REPLA CODDTE WITH "KH" for iddte=       1253 in dtecata
		REPLA CODDTE WITH "CM" for iddte=       1254 in dtecata
		REPLA CODDTE WITH "CA" for iddte=       1255 in dtecata
		REPLA CODDTE WITH "CO" for iddte=       1258 in dtecata
		REPLA CODDTE WITH "KM" for iddte=       1259 in dtecata
		REPLA CODDTE WITH "CI" for iddte=       1264 in dtecata
		REPLA CODDTE WITH "CR" for iddte=       1265 in dtecata
		REPLA CODDTE WITH "CU" for iddte=       1266 in dtecata
		REPLA CODDTE WITH "TD" for iddte=       1267 in dtecata
		REPLA CODDTE WITH "CL" for iddte=       1269 in dtecata
		REPLA CODDTE WITH "CN" for iddte=       1270 in dtecata
		REPLA CODDTE WITH "CY" for iddte=       1271 in dtecata
		REPLA CODDTE WITH "DK" for iddte=       1273 in dtecata
		REPLA CODDTE WITH "DM" for iddte=       1274 in dtecata
		REPLA CODDTE WITH "EC" for iddte=       1276 in dtecata
		REPLA CODDTE WITH "AE" for iddte=       1277 in dtecata
		REPLA CODDTE WITH "ES" for iddte=       1278 in dtecata
		REPLA CODDTE WITH "ET" for iddte=       1280 in dtecata
		REPLA CODDTE WITH "FJ" for iddte=       1281 in dtecata
		REPLA CODDTE WITH "PH" for iddte=       1282 in dtecata
		REPLA CODDTE WITH "FI" for iddte=       1283 in dtecata
		REPLA CODDTE WITH "FR" for iddte=       1284 in dtecata
		REPLA CODDTE WITH "GA" for iddte=       1285 in dtecata
		REPLA CODDTE WITH "GM" for iddte=       1286 in dtecata
		REPLA CODDTE WITH "GH" for iddte=       1287 in dtecata
		REPLA CODDTE WITH "GI" for iddte=       1288 in dtecata
		REPLA CODDTE WITH "GD" for iddte=       1289 in dtecata
		REPLA CODDTE WITH "GR" for iddte=       1290 in dtecata
		REPLA CODDTE WITH "GT" for iddte=       1291 in dtecata
		REPLA CODDTE WITH "GN" for iddte=       1292 in dtecata
		REPLA CODDTE WITH "GY" for iddte=       1293 in dtecata
		REPLA CODDTE WITH "HT" for iddte=       1294 in dtecata
		REPLA CODDTE WITH "HN" for iddte=       1296 in dtecata
		REPLA CODDTE WITH "HK" for iddte=       1297 in dtecata
		REPLA CODDTE WITH "HU" for iddte=       1298 in dtecata
		REPLA CODDTE WITH "ID" for iddte=       1299 in dtecata
		REPLA CODDTE WITH "IQ" for iddte=       1300 in dtecata
		REPLA CODDTE WITH "IE" for iddte=       1302 in dtecata
		REPLA CODDTE WITH "IS" for iddte=       1303 in dtecata
		REPLA CODDTE WITH "IL" for iddte=       1305 in dtecata
		REPLA CODDTE WITH "IT" for iddte=       1306 in dtecata
		REPLA CODDTE WITH "JM" for iddte=       1307 in dtecata
		REPLA CODDTE WITH "JP" for iddte=       1308 in dtecata
		REPLA CODDTE WITH "JO" for iddte=       1309 in dtecata
		REPLA CODDTE WITH "KE" for iddte=       1310 in dtecata
		REPLA CODDTE WITH "KI" for iddte=       1311 in dtecata
		REPLA CODDTE WITH "KW" for iddte=       1312 in dtecata
		REPLA CODDTE WITH "LA" for iddte=       1313 in dtecata
		REPLA CODDTE WITH "LS" for iddte=       1314 in dtecata
		REPLA CODDTE WITH "LB" for iddte=       1315 in dtecata
		REPLA CODDTE WITH "LR" for iddte=       1316 in dtecata
		REPLA CODDTE WITH "LY" for iddte=       1317 in dtecata
		REPLA CODDTE WITH "LI" for iddte=       1318 in dtecata
		REPLA CODDTE WITH "LU" for iddte=       1319 in dtecata
		REPLA CODDTE WITH "MG" for iddte=       1320 in dtecata
		REPLA CODDTE WITH "MY" for iddte=       1321 in dtecata
		REPLA CODDTE WITH "MW" for iddte=       1322 in dtecata
		REPLA CODDTE WITH "MV" for iddte=       1323 in dtecata
		REPLA CODDTE WITH "MT" for iddte=       1324 in dtecata
		REPLA CODDTE WITH "MA" for iddte=       1325 in dtecata
		REPLA CODDTE WITH "MU" for iddte=       1327 in dtecata
		REPLA CODDTE WITH "MR" for iddte=       1328 in dtecata
		REPLA CODDTE WITH "MX" for iddte=       1329 in dtecata
		REPLA CODDTE WITH "FM" for iddte=       1330 in dtecata
		REPLA CODDTE WITH "MC" for iddte=       1331 in dtecata
		REPLA CODDTE WITH "MN" for iddte=       1332 in dtecata
		REPLA CODDTE WITH "MZ" for iddte=       1333 in dtecata
		REPLA CODDTE WITH "NR" for iddte=       1334 in dtecata
		REPLA CODDTE WITH "NP" for iddte=       1335 in dtecata
		REPLA CODDTE WITH "NI" for iddte=       1336 in dtecata
		REPLA CODDTE WITH "NE" for iddte=       1337 in dtecata
		REPLA CODDTE WITH "NG" for iddte=       1338 in dtecata
		REPLA CODDTE WITH "NO" for iddte=       1339 in dtecata
		REPLA CODDTE WITH "NC" for iddte=       1340 in dtecata
		REPLA CODDTE WITH "NZ" for iddte=       1341 in dtecata
		REPLA CODDTE WITH "PG" for iddte=       1343 in dtecata
		REPLA CODDTE WITH "PK" for iddte=       1344 in dtecata
		REPLA CODDTE WITH "PA" for iddte=       1345 in dtecata
		REPLA CODDTE WITH "PY" for iddte=       1346 in dtecata
		REPLA CODDTE WITH "PE" for iddte=       1347 in dtecata
		REPLA CODDTE WITH "PL" for iddte=       1348 in dtecata
		REPLA CODDTE WITH "QA" for iddte=       1349 in dtecata
		REPLA CODDTE WITH "GB" for iddte=       1350 in dtecata
		REPLA CODDTE WITH "EG" for iddte=       1351 in dtecata
		REPLA CODDTE WITH "RW" for iddte=       1353 in dtecata
		REPLA CODDTE WITH "RO" for iddte=       1354 in dtecata
		REPLA CODDTE WITH "SM" for iddte=       1355 in dtecata
		REPLA CODDTE WITH "LC" for iddte=       1358 in dtecata
		REPLA CODDTE WITH "SN" for iddte=       1359 in dtecata
		REPLA CODDTE WITH "ST" for iddte=       1360 in dtecata
		REPLA CODDTE WITH "SL" for iddte=       1362 in dtecata
		REPLA CODDTE WITH "SG" for iddte=       1363 in dtecata
		REPLA CODDTE WITH "SY" for iddte=       1364 in dtecata
		REPLA CODDTE WITH "SC" for iddte=       1365 in dtecata
		REPLA CODDTE WITH "SO" for iddte=       1366 in dtecata
		REPLA CODDTE WITH "ZA" for iddte=       1367 in dtecata
		REPLA CODDTE WITH "SD" for iddte=       1368 in dtecata
		REPLA CODDTE WITH "SE" for iddte=       1369 in dtecata
		REPLA CODDTE WITH "CH" for iddte=       1370 in dtecata
		REPLA CODDTE WITH "SR" for iddte=       1371 in dtecata
		REPLA CODDTE WITH "LK" for iddte=       1372 in dtecata
		REPLA CODDTE WITH "TZ" for iddte=       1374 in dtecata
		REPLA CODDTE WITH "TG" for iddte=       1375 in dtecata
		REPLA CODDTE WITH "TT" for iddte=       1376 in dtecata
		REPLA CODDTE WITH "TO" for iddte=       1377 in dtecata
		REPLA CODDTE WITH "TN" for iddte=       1378 in dtecata
		REPLA CODDTE WITH "TR" for iddte=       1380 in dtecata
		REPLA CODDTE WITH "TV" for iddte=       1381 in dtecata
		REPLA CODDTE WITH "UG" for iddte=       1382 in dtecata
		REPLA CODDTE WITH "UY" for iddte=       1384 in dtecata
		REPLA CODDTE WITH "VU" for iddte=       1386 in dtecata
		REPLA CODDTE WITH "VE" for iddte=       1388 in dtecata
		REPLA CODDTE WITH "YE" for iddte=       1391 in dtecata
		REPLA CODDTE WITH "ZM" for iddte=       1394 in dtecata
		REPLA CODDTE WITH "ZW" for iddte=       1395 in dtecata
		REPLA CODDTE WITH "PR" for iddte=       1396 in dtecata
		REPLA CODDTE WITH "BS" for iddte=       1397 in dtecata
		REPLA CODDTE WITH "BM" for iddte=       1398 in dtecata
		REPLA CODDTE WITH "MQ" for iddte=       1399 in dtecata
		REPLA CODDTE WITH "TW" for iddte=       1402 in dtecata
		REPLA CODDTE WITH "VG" for iddte=       1403 in dtecata
		REPLA CODDTE WITH "MK" for iddte=       1405 in dtecata
		REPLA CODDTE WITH "SV" for iddte=       1406 in dtecata
		REPLA CODDTE WITH "BG" for iddte=       1407 in dtecata
		REPLA CODDTE WITH "DJ" for iddte=       1408 in dtecata
		REPLA CODDTE WITH "IN" for iddte=       1409 in dtecata
		REPLA CODDTE WITH "ML" for iddte=       1410 in dtecata
		REPLA CODDTE WITH "PT" for iddte=       1411 in dtecata
		REPLA CODDTE WITH "TH" for iddte=       1412 in dtecata
		REPLA CODDTE WITH "UA" for iddte=       1413 in dtecata
		REPLA CODDTE WITH "UZ" for iddte=       1414 in dtecata
		REPLA CODDTE WITH "PS" for iddte=       1415 in dtecata
		REPLA CODDTE WITH "HR" for iddte=       1416 in dtecata
		REPLA CODDTE WITH "GE" for iddte=       1418 in dtecata
		REPLA CODDTE WITH "DE" for iddte=       1419 in dtecata
		REPLA CODDTE WITH "RU" for iddte=       1420 in dtecata
		REPLA CODDTE WITH "KZ" for iddte=       1421 in dtecata
		REPLA CODDTE WITH "VN" for iddte=       1422 in dtecata
		REPLA CODDTE WITH "LV" for iddte=       1423 in dtecata
		REPLA CODDTE WITH "SI" for iddte=       1424 in dtecata
		REPLA CODDTE WITH "AZ" for iddte=       1425 in dtecata
		REPLA CODDTE WITH "BY" for iddte=       1426 in dtecata
		REPLA CODDTE WITH "GL" for iddte=       1427 in dtecata
		REPLA CODDTE WITH "GW" for iddte=       1428 in dtecata
		REPLA CODDTE WITH "CC" for iddte=       1429 in dtecata
		REPLA CODDTE WITH "AX" for iddte=       1430 in dtecata
		REPLA CODDTE WITH "AW" for iddte=       1431 in dtecata
		REPLA CODDTE WITH "ER" for iddte=       1432 in dtecata
		REPLA CODDTE WITH "EE" for iddte=       1433 in dtecata
		REPLA CODDTE WITH "GP" for iddte=       1434 in dtecata
		REPLA CODDTE WITH "GF" for iddte=       1435 in dtecata
		REPLA CODDTE WITH "GG" for iddte=       1436 in dtecata
		REPLA CODDTE WITH "MP" for iddte=       1440 in dtecata
		REPLA CODDTE WITH "UM" for iddte=       1441 in dtecata
		REPLA CODDTE WITH "JE" for iddte=       1442 in dtecata
		REPLA CODDTE WITH "KG" for iddte=       1443 in dtecata
		REPLA CODDTE WITH "YT" for iddte=       1445 in dtecata
		REPLA CODDTE WITH "MD" for iddte=       1446 in dtecata
		REPLA CODDTE WITH "ME" for iddte=       1447 in dtecata
		REPLA CODDTE WITH "MS" for iddte=       1448 in dtecata
		REPLA CODDTE WITH "PF" for iddte=       1450 in dtecata
		REPLA CODDTE WITH "SJ" for iddte=       1451 in dtecata
		REPLA CODDTE WITH "TJ" for iddte=       1452 in dtecata
		REPLA CODDTE WITH "IO" for iddte=       1453 in dtecata
		REPLA CODDTE WITH "TL" for iddte=       1454 in dtecata
		REPLA CODDTE WITH "TK" for iddte=       1455 in dtecata
		REPLA CODDTE WITH "TM" for iddte=       1456 in dtecata
		REPLA CODDTE WITH "WF" for iddte=       1458 in dtecata
		REPLA CODDTE WITH "CZ" for iddte=       1462 in dtecata
		REPLA CODDTE WITH "CW" for iddte=       1463 in dtecata
		REPLA CODDTE WITH "BA" for iddte=       1467 in dtecata
		REPLA CODDTE WITH "GQ" for iddte=       1468 in dtecata
		REPLA CODDTE WITH "IM" for iddte=       1469 in dtecata
		REPLA CODDTE WITH "FK" for iddte=       1470 in dtecata
		REPLA CODDTE WITH "PN" for iddte=       1471 in dtecata
		REPLA CODDTE WITH "RS" for iddte=       1472 in dtecata
		REPLA CODDTE WITH "TF" for iddte=       1473 in dtecata
		REPLA CODDTE WITH "SK" for iddte=       1474 in dtecata
		REPLA CODDTE WITH "GU" for iddte=       1476 in dtecata
		REPLA CODDTE WITH "CK" for iddte=       1477 in dtecata
		REPLA CODDTE WITH "FO" for iddte=       1478 in dtecata
		REPLA CODDTE WITH "MH" for iddte=       1479 in dtecata
		REPLA CODDTE WITH "VI" for iddte=       1480 in dtecata
		REPLA CODDTE WITH "MO" for iddte=       1481 in dtecata
		REPLA CODDTE WITH "NA" for iddte=       1482 in dtecata
		REPLA CODDTE WITH "NU" for iddte=       1483 in dtecata
		REPLA CODDTE WITH "PW" for iddte=       1484 in dtecata
		REPLA CODDTE WITH "RE" for iddte=       1485 in dtecata
		REPLA CODDTE WITH "EH" for iddte=       1486 in dtecata
		REPLA CODDTE WITH "AS" for iddte=       1487 in dtecata
		REPLA CODDTE WITH "PM" for iddte=       1488 in dtecata
		REPLA CODDTE WITH "SH" for iddte=       1489 in dtecata
		REPLA CODDTE WITH "BF" for iddte=       1492 in dtecata


		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1958,"020","AQ","ANTÁRTICA","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1959,"020","AM","ARMENIA","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1960,"020","BQ","BONAIRE, SINT EUSTATIUS AND SABA","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1961,"020","KY","CAIMÁN, LSLAS","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1962,"020","CF","CENTROAFRICANA, REPÚBLICA","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1963,"020","VA","CIUDAD DEL VATICANO","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1964,"020","CG","CONGO","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1965,"020","US","ESTADOS UNIDOS","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1966,"020","BV","ISLA BOUVET","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1967,"020","NF","ISLA NORFOLK","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1968,"020","CX","ISLAS NAVIDAD","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1969,"020","GS","ISLAS GEORGIAS D. S.-SANDWICH D. S","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1970,"020","HM","ISLAS HEARD Y MCDONALD","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1971,"020","MM","MYANMAR","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1972,"020","OM","OMÁN","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1973,"020","NL","PAÍSES BAJOS","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1974,"020","KP","REP. DEMOCRÁTICA POPULAR DE COREA","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1975,"020","KR","REPÚBLICA DE COREA","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1976,"020","CD","REPÚBLICA DEMOCRÁTICA DEL CONGO","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1977,"020","DO","REPÚBLICA DOMINICANA","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1978,"020","IR","REPÚBLICA LSLÁMICA DE IRÁN","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1979,"020","BL","SAINT BARTHÉLEMY","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1980,"020","MF","SAINT MARTIN (FRENCH PART)","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1981,"020","SB","SALOMÓN, ISLAS","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1982,"020","WS","SAMOA","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1983,"020","KN","SAN CRISTÓBAL Y NIEVES","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1984,"020","VC","SAN VICENTE Y LAS GRANADINAS","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1985,"020","SX","SINT MAARTEN (DUTCH PART)","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1986,"020","SS","SOUTH SUDAN","00")
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1987,"020","SZ","SWAZILANDIA","00")

		
		delete for iddte=       1227 in dtecata
		delete for iddte=       1228 in dtecata
		delete for iddte=       1229 in dtecata
		delete for iddte=       1401 in dtecata
		delete for iddte=       1244 in dtecata
		delete for iddte=       1250 in dtecata
		delete for iddte=       1493 in dtecata
		delete for iddte=       1461 in dtecata
		delete for iddte=       1256 in dtecata
		delete for iddte=       1268 in dtecata
		delete for iddte=       1260 in dtecata
		delete for iddte=       1261 in dtecata
		delete for iddte=       1262 in dtecata
		delete for iddte=       1263 in dtecata
		delete for iddte=       1257 in dtecata
		delete for iddte=       1272 in dtecata
		delete for iddte=       1223 in dtecata
		delete for iddte=       1491 in dtecata
		delete for iddte=       1275 in dtecata
		delete for iddte=       1279 in dtecata
		delete for iddte=       1464 in dtecata
		delete for iddte=       1295 in dtecata
		delete for iddte=       1465 in dtecata
		delete for iddte=       1301 in dtecata
		delete for iddte=       1437 in dtecata
		delete for iddte=       1439 in dtecata
		delete for iddte=       1438 in dtecata
		delete for iddte=       1404 in dtecata
		delete for iddte=       1304 in dtecata
		delete for iddte=       1444 in dtecata
		delete for iddte=       1326 in dtecata
		delete for iddte=       1459 in dtecata
		delete for iddte=       1224 in dtecata
		delete for iddte=       1449 in dtecata
		delete for iddte=       1400 in dtecata
		delete for iddte=       1342 in dtecata
		delete for iddte=       1417 in dtecata
		delete for iddte=       1352 in dtecata
		delete for iddte=       1357 in dtecata
		delete for iddte=       1356 in dtecata
		delete for iddte=       1475 in dtecata
		delete for iddte=       1361 in dtecata
		delete for iddte=       1373 in dtecata
		delete for iddte=       1490 in dtecata
		delete for iddte=       1466 in dtecata
		delete for iddte=       1379 in dtecata
		delete for iddte=       1383 in dtecata
		delete for iddte=       1385 in dtecata
		delete for iddte=       1387 in dtecata
		delete for iddte=       1389 in dtecata
		delete for iddte=       1390 in dtecata
		delete for iddte=       1494 in dtecata
		delete for iddte=       1460 in dtecata
		delete for iddte=       1457 in dtecata
		delete for iddte=       1392 in dtecata
		delete for iddte=       1393 in dtecata

		
		*REPLACE tipodte WITH 'B'+tipodte FOR tipodte='014'
		
		***** tabla 021 otros documentos asociados
		REPLACE valor WITH 'Médico (solo aplica para contribuyentes obligados a la presentación de F-958)' FOR iddte=1497 IN dtecata
		DELETE FOR iddte=1498 IN dtecata
		
		*** tabla 024
		REPLACE valor WITH 'Error en la Información del Documento Tributario Electrónico a invalidar.' FOR iddte=1512 IN dtecata
		DELETE FOR iddte=1513 IN dtecata
		
		**** tabla 27
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1988,"027","85","Gutierrez Courier y Cargo","00")
		REPLACE valor WITH 'Delegacion DHL' FOR iddte=1561 IN dtecata
		
		
		***** tabla 28
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1989,"028","EX-2.2400.000","Traslados Definitivos","00")	
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1990,"028","EX-3.3071.000","Reexp. Prov. De Deposito","00")	
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1991,"028","EX-3.3052.000","Reexp. Prov. De Adm Temp. para Perfeccionamiento Activo","00")	
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1992,"028","EX-3.3054.000","Reexp. Prov. de Regimen de Zona Franca","00")	
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1993,"028","EX-3.3055.000","Reexp. Prov. de Adm. Temporal para Perfeccionamiento Activo con Garantia","00")	
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1994,"028","EX-3.3056.000","Re-Exp. Prov.de Adm.Temporal Ley de Servi. Internacionales","00")	
		INSERT INTO dtecata (iddte,tipodte,coddte,valor,padre) VALUES (1995,"028","EX-3.3057.000","Reexportacion Prov. de Centros de Servicios LSI","00")	

		**** tabla 30
		REPLACE valor WITH 'Aereo' FOR iddte=1624 IN dtecata
		REPLACE valor WITH 'Maritimo' FOR iddte=1625 IN dtecata
		REPLACE valor WITH 'Ferreo' FOR iddte=1626 IN dtecata
		REPLACE valor WITH 'Multimodal' FOR iddte=1627 IN dtecata
		REPLACE valor WITH 'Correo' FOR iddte=1628 IN dtecata
		DELETE FOR iddte=1624  IN dtecata
		
		**** tabla 31
		DELETE FOR iddte = 1641 IN dtecata
		DELETE FOR iddte = 1642 IN dtecata
		DELETE FOR iddte = 1643 IN dtecata
		DELETE FOR iddte = 1644 IN dtecata
		DELETE FOR iddte = 1645 IN dtecata
		
		
		
		
	ENDIF 
	
	USE IN dtecata
	IF !EMPTY(lcaliasdtetabla) AND !UPPER(ALIAS())<>'DTECATA'
		SELECT (lcaliasdtetabla)
	ENDIF 
	WAIT CLEAR 
ENDFUNC 



FUNCTION buscaCodigoDTE()
	LPARAMETERS lcCodigoDTE,lcNumeroTabla,lcNombreCursor,lcFiltroPadre
	lcCodigoDTE=lcCodigoDTE+' '
	lcAliasBuscarCodigo=ALIAS()
	
	lcCursorDTETmp=IIF(EMPTY(lcNombreCursor),"c_miCodDTETmp",lcNombreCursor)
	
	GenerarTablaDTE(lcNumeroTabla,lcCursorDTETmp,lcFiltroPadre)
	SELECT (lcCursorDTETmp)

	IF SEEK(lcCodigoDTE,lcCursorDTETmp)
		IF lcNumeroTabla='213'
			lcmunitempdte=ALLTRIM(STRTRAN(UPPER(valor)," DISTRITO DE ",''))
			lcdistetempdte=SUBSTR(lcmunitempdte,1,AT(',',lcmunitempdte)-1)
			lcRetornaValorDTE=ALLTRIM(coddistri)+' '+STRTRAN(lcmunitempdte,lcdistetempdte+',','')+', '+ALLTRIM(UPPER(departamentodis))
		ELSE 
			lcRetornaValorDTE=ALLTRIM(valor)
		ENDIF 
	ELSE
		lcRetornaValorDTE=''
	ENDIF 
	USE
		
	IF EMPTY(lcNombreCursor)
		USE IN (lcCursorDTETmp)
	ENDIF 
	
	IF !EMPTY(lcAliasBuscarCodigo)
		SELECT (lcAliasBuscarCodigo)
	ENDIF 
	RETURN lcRetornaValorDTE
ENDFUNC 


FUNCTION buscaCodigoDeptoDelDistritoDTE()
	LPARAMETERS lcCodigoDTE,lcNumeroTabla,lcNombreCursor,lcFiltroPadre
	lcCodigoDTE=lcCodigoDTE+' '
	lcAliasBuscarCodigo=ALIAS()
	
	lcCursorDTETmp=IIF(EMPTY(lcNombreCursor),"c_miCodDTETmp",lcNombreCursor)
	
	GenerarTablaDTE(lcNumeroTabla,lcCursorDTETmp,lcFiltroPadre)
	SELECT (lcCursorDTETmp)
	
	IF SEEK(lcCodigoDTE,lcCursorDTETmp,'codDistri')
		IF lcNumeroTabla='213'
			lcRetornaValorDTE=ALLTRIM(codigo)
		ELSE 
			lcRetornaValorDTE=ALLTRIM(valor)
		ENDIF 
	ELSE
		lcRetornaValorDTE=''
	ENDIF 
	USE
		
	IF EMPTY(lcNombreCursor)
		USE IN (lcCursorDTETmp)
	ENDIF 
	
	IF !EMPTY(lcAliasBuscarCodigo)
		SELECT (lcAliasBuscarCodigo)
	ENDIF 
	RETURN lcRetornaValorDTE
ENDFUNC 



****** como generar uuid mayuscuasl
FUNCTION nousar

	LOCAL loSb
	LOCAL lnLowercase

	loSb = CreateObject('Chilkat_9_5_0.StringBuilder')

	* Generate a lowercase UUID.
	lnLowercase = 1
	loSb.AppendUuid(lnLowercase)
	? loSb.GetAsString()

	* example: edb1bb24-e9be-4ada-98bd-c2d893f29f55

	lnLowercase = 0
	loSb.Clear()
	loSb.AppendUuid(lnLowercase)
	? loSb.GetAsString()

	* example: 338EAF28-631E-4303-BE27-A8D80E9191CB

	RETURN loSb
ENDFUNC 

* Función para subir un archivo mediante FTP
FUNCTION SubirArchivoFTP(lcArchivoLocal, lcRutaRemota, lcServidor, lcUsuario, lcClave)

    LOCAL lnHandleFTP, lnResultado

    * Inicializar la sesión FTP
    lnHandleFTP = InternetOpen("MiApp", 1, "", "", 0)
    
    IF lnHandleFTP <= 0
        WAIT WINDOW "Error al iniciar la sesión FTP" NOWAIT
        RETURN .F.
    ENDIF

    * Conectar al servidor FTP
    lnHandleFTP = InternetConnect(lnHandleFTP, lcServidor, 21, lcUsuario, lcClave, 1, 0, 0)
    
    IF lnHandleFTP <= 0
        WAIT WINDOW "Error al conectar al servidor FTP" NOWAIT
        InternetCloseHandle(lnHandleFTP)
        RETURN .F.
    ENDIF

    * Subir el archivo
    lnResultado = FtpPutFile(lnHandleFTP, lcArchivoLocal, lcRutaRemota, FTP_TRANSFER_TYPE_BINARY, 0)

    IF lnResultado = 0
        WAIT WINDOW "Error al subir el archivo" NOWAIT
        InternetCloseHandle(lnHandleFTP)
        RETURN .F.
    ELSE
        WAIT WINDOW "Archivo subido correctamente" NOWAIT
    ENDIF

    * Cerrar la conexión FTP
    InternetCloseHandle(lnHandleFTP)

    RETURN .T.
ENDFUNC


FUNCTION EnviarPorWhatsApp(lcNombreArchivoconExtencion,lcNumeroWhasapp,lnOpciondeEnvio,lcAsuntoWW,lcMensajeWW)
	_VerificarWhatsAppHabilitado()
	IF lnOpciondeEnvio>0  AND pnWhatsAppHabilitado=1
		lcNumeroWhasapp=solonumeros(lcNumeroWhasapp)
		IF LEN(lcNumeroWhasapp)=8
			lcNumeroWhasapp='503'+lcNumeroWhasapp
		ENDIF 
		IF !EMPTY(lcNumeroWhasapp) AND LEN(lcNumeroWhasapp)>=11
	
			snPDF=0
			IF lnOpciondeEnvio=3
				snPDF=6
			ELSE
				IF lnOpciondeEnvio=2
					snPDF=MESSAGEBOX("Desea enviar el archivo al WhatsApp "+lcNumeroWhasapp+" ?",256+32+4,'Enviar PDF')
				ENDIF 
			ENDIF 
			IF snPDF=6
				llSigaEnviando=.t.
				lcWhatsApp = CREATEOBJECT("WhatsApp")
			
				
				IF !FILE(lcNombreArchivoconExtencion)
					llSigaEnviando=.f.
				ENDIF 
				
				IF llSigaEnviando=.t.
					IF TYPE("_vfp.ActiveForm.cntDiga")='O'
						_vfp.ActiveForm.cntDiga.diga("Enviando por WhatsApp al Cel.: "+lcNumeroWhasapp,4,3)
					ENDIF 
					WAIT WINDOW "Enviando archivo al WhatsApp "+lcNumeroWhasapp NOWAIT 
					llStatusEnvioWS=lcwhatsApp.sendmessage(2,lcNumeroWhasapp,lcMensajeWW)
				
					IF llStatusEnvioWS=.t.
						lcArchivoJson=JUSTpath(lcNombreArchivoconExtencion)+'\'+JUSTSTEM(lcNombreArchivoconExtencion)+'.json'
						
						IF FILE(lcArchivoJson)
						**** enviando pdf y json
							llStatusEnvioWS=lcwhatsApp.sendmessage(4,lcNumeroWhasapp,lcNombreArchivoconExtencion)
							llStatusEnvioWS2=lcwhatsApp.sendmessage(4,lcNumeroWhasapp,lcArchivoJson)
						ELSE 
							***** enviando pdf
							llStatusEnvioWS=lcwhatsApp.sendmessage(4,lcNumeroWhasapp,lcNombreArchivoconExtencion)
						ENDIF 
						
						***** se envio el archivo por whasapp
						IF llStatusEnvioWS=.t.
							WAIT WINDOW "Mensaje Enviado Corectamente..." TIMEOUT 2
						ELSE 
							WAIT WINDOW "Error al Enviar el Archivo..." TIMEOUT 2
						ENDIF 

					ELSE
						WAIT WINDOW "Imposible enviar el mensaje...."  TIMEOUT 2
					ENDIF 
					
				ELSE
					WAIT WINDOW "Error al Generar el Arhivo ...." TIMEOUT 2
				ENDIF
				RELEASE lcWhatsApp 
			ENDIF
		ELSE
			WAIT WINDOW "El Destinatario no tiene Numero de Celular o no es un numero valido..." TIMEOUT 2
		ENDIF 
	ENDIF 
ENDFUNC 





FUNCTION EnviarMensajeWhatsApp(lcNumeroWhasapp,lcMensajeWW)
	_VerificarWhatsAppHabilitado()
	IF pnWhatsAppHabilitado=1
		lcNumeroWhasapp=solonumeros(lcNumeroWhasapp)
		IF LEN(lcNumeroWhasapp)=8
			lcNumeroWhasapp='503'+lcNumeroWhasapp
		ENDIF 
		IF !EMPTY(lcNumeroWhasapp) AND LEN(lcNumeroWhasapp)>=11
	
			llSigaEnviando=.t.
			lcWhatsApp = CREATEOBJECT("WhatsApp")
			
			IF TYPE("_vfp.ActiveForm.cntDiga")='O'
				_vfp.ActiveForm.cntDiga.diga("Enviando por WhatsApp al Cel.: "+lcNumeroWhasapp,4,3)
			ENDIF 
			
			WAIT WINDOW "Enviando archivo al WhatsApp "+lcNumeroWhasapp NOWAIT 
			llStatusEnvioWS=lcwhatsApp.sendmessage(2,lcNumeroWhasapp,lcMensajeWW)
		
			IF llStatusEnvioWS=.t.
				WAIT WINDOW "Mensaje Enviado Corectamente..." NOWAIT 
			ELSE
				WAIT WINDOW "Imposible enviar el mensaje...."  TIMEOUT 1
			ENDIF 
		ELSE
			WAIT WINDOW "El Destinatario no tiene Numero de Celular o no es un numero valido..." NOWAIT 
		ENDIF 
	ENDIF 
ENDFUNC 





FUNCTION GenerarArchivoPDF_DTE(lcfileReporWhast,lcFileArcPDFWhast)

	lcPrintActual=SET("PRINTER", 3)
	
	llseimprimio=1
	&pcArchivosProcedimientos
	lcFilepdfGenerar=LOWER(lcFileArcPDFWhast)
	SET REPORTBEHAVIOR 90

	IF TYPE("_Screen.oFoxyPreviewer")="O"
		IF PEMSTATUS(_Screen.oFoxyPreviewer,"_nDataSessionMode",5)
			_Screen.oFoxyPreviewer._nDataSessionMode=1
		ENDIF
	ENDIF

	REPORT FORM (lcfileReporWhast) OBJECT TYPE 10 TO FILE (lcFileArcPDFWhast) 
	
ENDFUNC 





****** enviar por whasapp
*	=EnviarPorWhatsApp(lcfileReporWhast,lcFileArcPDFWhast,lcnumcelWhast,lnOpcionEnvioPreguntas,lcAsuntoEnvWhast,lcMensajeWhast)


*=EnviarPorWhatsApp(pcSysDir+pcdb+"\formatos\"+IIF(EMPTY(lcFormatoPDF),lcArchivo,lcFormatoPDF),;
																lcNombreArchivoPdF,lcNumeroCelularPDF,lnEnviarWA,lcAsuntoWS,lcMensajeWS)

FUNCTION subrhttp(lcfile)
	
	
	#DEFINE CODIFICADO_EN_BASE64 13
   
	  CLEAR
	   
	  lcURL           = "http://localhost/subir/subir.php"
	  lcUsuario       = "MiNombre"
	  lcPassword      = "MiContraseña"
	  lcNombreArchivo = GETFILE()
	  
	  lcArchivo64     = STRCONV(FILETOSTR(lcNombreArchivo), CODIFICADO_EN_BASE64)
	   
	  loHTTP = CREATEOBJECT("MSXML2.ServerXMLHTTP.6.0")
	   
	  WITH loHTTP
	    .OPEN("POST", lcURL, .F., lcUsuario, lcPassword)
	    .SetRequestHeader("Content-type", "text/plain")
	    .SEND(lcArchivo64)
	    ? .Status, .StatusText
	    ?
	    ? .ResponseText
	  ENDWITH
	   
	  loHTTP = .NULL.
	   
	  RELEASE loHTTP
	   
	RETURN

ENDFUNC 

FUNCTION EnviarArchivosWeb(lcmiruta,lcdatos)
	lcmiruta=ALLTRIM(lcmiruta)
	
	IF EMPTY(lcdatos)
		lcruta='file=""'
	ELSE 
		lcruta=lcmiruta+'?file_data='+STRCONV(FILETOSTR(lcdatos), CODIFICADO_EN_BASE64)
	ENDIF 
	lcVerTmp=''
	*_cliptext=_cliptext+'               '+lcruta
	*** en lugar de enviar al portapapeles
	m.RespuestaWEB="Ruta: "+lcruta+CHR(13)
	
	
	LOCAL xhr
	xhr = CREATEOBJECT("Microsoft.XMLHTTP")
	xhr.Open("POST", lcruta, .f.)
	xhr.setRequestHeader("Content-type", "text/plain")
	xhr.send()

	LOCAL lcResultText
	lcResultText = xhr.responseText
	
	m.RespuestaWEB=m.RespuestaWEB+lcResultText 

	lcVerTmp=ALLTRIM(lcResultText)
	
	RETURN lcVerTmp
ENDFUNC 





********************************* json para envio a timbrado con empresa externa
******* FACTURA CONSUMIDOR FINAL
FUNCTION GenerarDTEVentasFC_V1_sub(lnIdDocVta as Integer)
	*#Define CR		Chr(13)
	*#Define TB		"  "
	lcOkErrorStatus='ok'
	lcMensajeOkError='documento generado correctamente'
	pcBitacoraDTE=''
	
	lcJsonTmp=''
	lcAliasDTEDoc=ALIAS()
	USE pcSysDir+pcdb+"\cyvVentas" IN 0 share AGAIN ALIAS c_DTE_Vta
	USE pcSysDir+pcdb+"\cyvVentasdeta" IN 0 share AGAIN ALIAS c_DTE_VtaD
	USE pcSysDir+pcdb+"\sisTipoDoctos" IN 0 share AGAIN ALIAS c_DTE_STD
	CrearCursorStatus(19,'c_DTE_TDo','') 
	USE pcSysDir+pcdb+"\sisCata" IN 0 share AGAIN ALIAS c_DTE_SUC
	USE pcSysDir+pcdb+"\cyvclipro" IN 0 share AGAIN ALIAS c_DTE_clipro
	USE pcSysDir+pcdb+"\invProductos" IN 0 share AGAIN ALIAS c_DTE_InvPro

	SELECT a.*,aa.idproducto,aa.cantiunimed,aa.producto,aa.precioconivaunidad,aa.descuento,;
			aa.fovial,aa.cotrans,aa.pfovial,aa.pcotrans,aa.totalgravado,c.tipd,PADL(SUBSTR(ALLTRIM(d.cod),1,4),4,"0") as CodSuc,;
			PADL(SUBSTR(ALLTRIM(e.cod),1,4),4,"0") as CodPTV,;
			d.tipoestablecimiento,d.correo as correosuc,d.telefono ,;
			SUBSTR(solonumeros(NVL(IIF(EMPTY(f.celular),f.telefono,f.celular),SPACE(20))),1,8) as telcel,;
			f.codgiro,f.giro as giroclipro,f.correoDTE as correo,;
			g.codprod,g.tipoprod,g.escombustible,g.esnota,;
			NVL(h.cod,SPACE(10)) as deptocli, NVL(i.cod,SPACE(10)) as municli , ;
			_ConvertirToFechaSQL(fechadocto) as fechaDTE,ALLTRIM(horadocto) as horaDTE,;
			d.cod AS codMatrizSuc,e.PtVenta as codMatrizPTV ;
		FROM c_DTE_Vta a ;
			inner JOIN c_DTE_VtaD aa ON a.iddocto=aa.iddocto AND aa.eliminado=0 AND INLIST(aa.tipoprod,1,2);
			inner JOIN c_DTE_STD b ON a.idtipodocto=b.idtipodocto ;
			inner JOIN c_DTE_TDo c ON b.tipoicv=c.id ;
			left join c_DTE_SUC d ON a.idsucursal=d.id and d.origen='SUC' ;
			left join c_DTE_SUC e ON a.idptovta=e.id and e.origen='PTV' ;
			left JOIN c_DTE_clipro f ON a.idclipro=f.idclipro ;
			INNER JOIN c_DTE_InvPro g ON aa.idproducto=g.idproducto ;
			LEFT JOIN c_DTE_SUC H ON a.iddepto=H.id AND h.origen='DEP' ;
			LEFT JOIN c_DTE_SUC I ON a.idMuni=I.id AND i.origen='MUN' ;
		WHERE a.iddocto=lnIdDocVta AND b.tipoicv<>0  AND ((aa.idproducto<>idkit AND aa.llavekit<>0) OR aa.llavekit=0) ;
		INTO CURSOR c_MiDocDTE READWRITE 
	
	SELECT c_MiDocDTE

	lcTipoDTE=ALLTRIM(ALLTRIM(tipd))
	
	oJson = newobject('json')

	IF !EMPTY(NVL(lcTipoDTE,''))
		IF lcTipoDTE='01'		&&& Factura Consumidor Final			
			****** Documento
			m.tipoDte='"tipo_dte": "'+lcTipoDTE+'"'
			m.ecodEstable='"establecimiento": "'+ALLTRIM(codmatrizSuc)+'"'
			m.ePuntoVenta='"punto_venta": "'+ALLTRIM(codmatrizPTV)+'"'
			IF pnuuidSello=1
				m.euuid=TB+TB+'"uuid": "'+ALLTRIM(codigoGeneracion)+'"'+', '+CR
				m.enumeroControl=TB+TB+'"numero_control": "'+ALLTRIM(numerocontrol)+'"'+', '+CR
				m.efechaEmision=TB+TB+'"fecha_emision": "'+fechaDTE+'"'+', '+CR
				m.ehoraEmision=TB+TB+'"hora_emision": "'+ALLTRIM(HoraDTE)+'"'+', '+CR
			ELSE
				m.euuid=''
				m.enumeroControl=''
				m.efechaEmision=''
				m.ehoraEmision=''
			ENDIF 
			
			m.econdiPago='"condicion_pago": '+ALLTRIM(STR(condipago+1))+' '
			m.etipocontingencia=''
			m.emotivocontingencia=''
			IF retperdocto<>0
				m.eretperdocto=TB+TB+'"percibir_iva": true , '+CR
			ELSE
				m.eretperdocto=''
			ENDIF 
			IF pnTipoContinDTE=1		&&& tipo contingencia ministerio de hacienda error
				IF pnuuidSello=0
					m.etipocontingencia=TB+TB+TB+'"tipo_contingencia": '+ALLTRIM(STR(pnTipoContinDTE))+', '+CR
				ENDIF 
			ENDIF 
			IF pnTipoContinDTE=5		&&& tipo contingencia ministerio de hacienda error
				m.etipocontingencia=TB+TB+TB+'"tipo_contingencia": '+ALLTRIM(STR(pnTipoContinDTE))+', '+CR
				m.emotivocontingencia=TB+TB+TB+'"motivo_contingencia": "'+ALLTRIM(pcContingenciaDTE)+'", '+CR
			ENDIF 

			***** receptor
			lcNumDoc=SoloNumeros(IIF(EMPTY(ValidarDUI(NVL(dui,''))),NVL(nit,''),NVL(dui,"")))
			lctipDoc=IIF(EMPTY(lcNumDoc),"null",IIF(LEN(lcNumdoc)>12,"36","13")) 
			IF lctipDoc="13" AND !EMPTY(lcNumDoc)		 &&&& poniendo gion al dui
				lcNumDoc=PADL(lcNumDoc,9,'0')
				lcNumDoc=SUBSTR(lcNumDoc,1,8)+'-'+SUBSTR(lcNumDoc,9,1)
				lcNumDoc='"'+ALLTRIM(lcNumDoc)+'"'
			ELSE
				IF EMPTY(lcNumDoc)
					lcNumDoc='null'
				ELSE
					lcNumDoc='"'+lcNumDoc+'"'
				ENDIF 
			ENDIF 
			IF lctipDoc<>'null'
				lctipDoc='"'+lctipDoc+'"'
			ENDIF 
			lcCorreoClienteTmp=ValidarVariosCorreos(correo,1)
			lccorreocliente=IIF(EMPTY(NVL(lcCorreoClienteTmp,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmp)+'"')
			m.rcorreo='"correo": '+lccorreocliente+' '
			lcCorreoClienteTmpCC=ValidarVariosCorreos(correo,2)
			lccorreoclienteCC=IIF(EMPTY(NVL(lcCorreoClienteTmpCC,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmpCC)+'"')
			m.rcorreo_cc='"correos_cc": '+lccorreoclienteCC+' '
		
			m.rnumDocumento='"numero_documento": '+lcNumDoc+' '
			m.rtipoDocumento='"tipo_documento": '+lctipDoc+' '
			m.rnombre='"nombre": "'+ALLTRIM(UPPER(clipro))+'" '
			m.rtelefono='"telefono": "'+ALLTRIM(solonumeros(telcel))+'"'
			
			***** direccion receptor
			lcDistritotmp=buscaCodigoDTE(ALLTRIM(municli),'213','c_Distri',ALLTRIM(deptocli))
			lccodDistrito=SUBSTR(lcDistritotmp,1,2)
			lcNomDistrito=ALLTRIM(SUBSTR(lcDistritotmp,AT(',',lcDistritotmp)+2,150))
			m.rdepartamento='"departamento": "'+ALLTRIM(deptocli)+'"'
			m.rmunicipio='"municipio": "'+ALLTRIM(lccodDistrito)+'"'
			*m.rcomplemento='"complemento": "'+ALLTRIM(_EscaparJson(ALLTRIM(Direccion)+', '+lcNomDistrito))+'"'
			m.rcomplemento='"complemento": "'+ALLTRIM(_EscaparJson(ALLTRIM(Direccion)+' '))+'"'
			
			m.receptor=;
				TB+'"receptor": {'+CR+;
					TB+TB+m.rnumDocumento+', '+CR+;
					TB+TB+m.rtipoDocumento+', '+CR+;
					TB+TB+m.rnombre+', '+CR+;
					TB+TB+'"direccion": {'+CR+;
						TB+TB+TB+m.rdepartamento+', '+CR+;
						TB+TB+TB+m.rmunicipio+', '+CR+;
						TB+TB+TB+m.rcomplemento+CR+;
					TB+TB+'}, '+CR+;
					TB+TB+m.rcorreo_cc+', '+CR+;
					TB+TB+m.rcorreo+' '+CR+;
				TB+'}'

			****** enviar emisor si estamos en contingencia
			****** Emisor
			IF pnTipoContinDTE>0
				m.enit='"nit": "'+SoloNumeros(ALLTRIM(pcNit))+'" '
				m.enrc='"nrc": "'+SoloNumeros(ALLTRIM(pcNRC))+'" '
				m.enombre='"nombre":"'+UPPER(ALLTRIM(pcNomEmpresa))+'"'
				m.ecodActividad='"codigo_actividad":"'+pcCodGiro+'"'
				m.enombreComercial='"nombre_comercial":"'+SUBSTR(UPPER(ALLTRIM(pcnombrecomercial)),1,150)+'"'
				m.etipoEstablecimiento='"tipo_establecimiento":"'+ALLTRIM(tipoestablecimiento)+'"'	&& 01 suc/agen, 02 casa matriz, 03 bodega,07 predio/patio, 20 otros
					***** direccion Emisor
					m.edepartamento='"departamento":"'+pcCodDepartamento+'"'
					m.emunicipio='"municipio":"'+pcCodMunicipio+'"'
					m.ecomplemento='"complemento": "'+ALLTRIM(_EscaparJson(pcDireccion))+'"'
				m.etelefono='"telefono":"'+ALLTRIM(solonumeros(telefono))+'"'
				m.ecorreo='"correo":"'+ALLTRIM(correosuc)+'"'
				
				m.ecodEstableMH='"codigo_establecimiento_mh":null'						
				m.emision=;
					TB+'"emisor":{'+CR+;
						TB+TB+m.enit+', '+CR+;
						TB+TB+m.enrc+', '+CR+;
						TB+TB+m.enombre+', '+CR+;
						TB+TB+m.ecodActividad+', '+CR+;
						TB+TB+m.enombreComercial+', '+CR+;
						TB+TB+m.etipoEstablecimiento+', '+CR+;
						TB+TB+'"direccion":{'+CR+;
							TB+TB+TB+m.edepartamento+', '+CR+;
							TB+TB+TB+m.emunicipio+', '+CR+;
							TB+TB+TB+m.ecomplemento+CR+;
						TB+TB+'}, '+CR+;
						TB+TB+m.etelefono+', '+CR+;
						TB+TB+m.ecorreo+', '+CR+;
						TB+TB+m.ecodEstableMH+' '+CR+;
					TB+'}, '+CR
			ELSE
				m.emision=''
			ENDIF 
			***** forma de pago
			IF condipago=1	&&& es contado
				m.pagos=;
				TB+'"pagos": null'
			ELSE
				m.pcodigo='"tipo": "01"'
				m.pmontoPago='"monto": '+ALLTRIM(STR(totaldocto-ABS(retperdocto),12,8))+' '
				m.pagos=;
				'"pagos": ['+CR+;
					TB+TB+TB+'{'+CR+;
						TB+TB+TB+TB+m.pcodigo+', '+CR+;
						TB+TB+TB+TB+m.pmontoPago+' '+CR+;
					TB+TB+TB+'}'+CR+;
				TB+TB+'] '
			ENDIF 
			
				
			 ****** Venta 
			m.detalledoc=''
			m.uniondetalle=''
			m.linea=0
			m.fila=''
			lcNotasDetalle=''
			lcUnionNotas=''
			SCAN all
				IF esnota=1		&&& es nota o comentario
					IF !EMPTY(ALLTRIM(producto))
						lcNotasDetalle=lcNotasDetalle+lcUnionNotas+ALLTRIM(producto)
						lcUnionNotas=',  '
					ENDIF 
				ELSE 		
					m.tipVenta='"tipo_venta": '+IIF(tipoiva=0,'"3"',IIF(tipoiva=1,'"1"',IIF(tipoiva=2,'"2"','"4"')))
					m.cdtipoItem='"tipo": '+ALLTRIM(STR(tipoprod))+''
					m.cdcantidad='"cantidad": '+ALLTRIM(STR(cantiunimed,12,6))+''
					m.cduniMedida='"unidad_medida": '+IIF(esCombustible=1,'22','59')
					*m.cddescuento='"descuento": '+ALLTRIM(STR(descuento,12,8))+''
					m.cddescripcion='"descripcion": "'+ALLTRIM(_sincomilliasoTildes(producto))+'"'
					m.cdprecioUni='"precio_unitario": '+ALLTRIM(STR(precioconivaunidad-descuento-pfovial-pcotrans,12,8))+''
					
					**** Item Tributo
					IF esCombustible=1
						m.cditemcotrans=''
						m.cditemfovial=''
						IF cotrans<>0
							m.cdcodcotrans='"codigo": "C8"'
							m.cdmontocotrans='"monto": '+ALLTRIM(STR(cotrans,12,8))+''
							m.cdcantidadgravablecotrans='"cantidad_gravable": '+ALLTRIM(STR(cantiunimed,12,6))+''
							m.cditemcotrans=TB+TB+'{'+CR+;
											TB+TB+TB+m.cdcodcotrans+', '+CR+;
											TB+TB+TB+m.cdmontocotrans+', '+CR+;
											TB+TB+TB+m.cdcantidadgravablecotrans+' '+CR+;
											TB+TB+'}'
						ENDIF 
						IF fovial<>0
							m.cdcodfovial='"codigo": "D1"'
							m.cdmontofovial='"monto": '+ALLTRIM(STR(fovial,12,8))+''
							m.cdcantidadgravablefovial='"cantidad_gravable": '+ALLTRIM(STR(cantiunimed,12,6))+''
							m.cditemfovial=TB+TB+TB+'{'+CR+;
											TB+TB+TB+TB+m.cdcodfovial+', '+CR+;
											TB+TB+TB+TB+m.cdmontofovial+', '+CR+;
											TB+TB+TB+TB+m.cdcantidadgravablefovial+' '+CR+;
											TB+TB+TB+'}'
						ENDIF 
						IF !EMPTY(m.cditemcotrans) AND !EMPTY(m.cditemfovial)
							m.itemtributo='"tributos": [ '+CR+;
											m.cditemcotrans+', '+CR+;
											m.cditemfovial+' '+CR+;
											TB+TB+']'+CR
						ELSE
							IF !EMPTY(m.cditemcotrans)
								m.itemtributo='"tributos": [ '+CR+;
											m.cditemcotrans+' '+CR+;
											TB+TB+']'+CR
							ENDIF 
							IF !EMPTY(m.cditemfovial)
								m.itemtributo='"tributos": [ '+CR+;
											m.cditemfovial+' '+CR+;
											TB+TB+']'+CR
							ENDIF 
						ENDIF 
					ELSE
						m.itemtributo='"tributos": null'
					ENDIF 

	*					TB+TB+TB+TB+m.cddescuento+', '+CR+;
					
					m.fila=m.fila+m.uniondetalle+TB+TB+'{'+CR+;
						TB+TB+TB+m.tipVenta+', '+CR+;
						TB+TB+TB+m.cdtipoItem+', '+CR+;
						TB+TB+TB+m.cdcantidad+', '+CR+;
						TB+TB+TB+TB+m.cduniMedida+', '+CR+;
						TB+TB+TB+m.cddescripcion+', '+CR+;
						TB+TB+TB+m.cdprecioUni+', '+CR+;
						TB+TB+TB+m.itemtributo+' '+CR+;
						TB+TB+'}'
					
					m.uniondetalle=', '+CR
					m.linea=m.linea+1
				ENDIF 
			ENDSCAN 
			GO top
			m.items='"items": [ '+CR+;
						m.fila+' '+CR+;
					TB+TB+']'

			**** apendice
			lcApendices=''
			lcmiPlaca=TB+TB+'{'+CR+;
					TB+TB+TB+'"campo": "placa", '+CR+;
					TB+TB+TB+'"etiqueta": "Placa:", '+CR+;
					TB+TB+TB+'"valor": "'+ALLTRIM(placa)+'" '+CR+;
				TB+'}'

			lcmiKM=TB+TB+'{'+CR+;
					TB+TB+TB+'"campo": "km", '+CR+;
					TB+TB+TB+'"etiqueta": "Km/Milla:", '+CR+;
					TB+TB+TB+'"valor": "'+ALLTRIM(KILOMETRAJE)+'" '+CR+;
				TB+'}'

			lcmiEq=TB+TB+'{'+CR+;
					TB+TB+TB+'"campo": "equipo", '+CR+;
					TB+TB+TB+'"etiqueta": "Eq.:", '+CR+;
					TB+TB+TB+'"valor": "'+ALLTRIM(marca)+'"  '+CR+;
				TB+'}'
				
			lcmiRec=TB+TB+'{'+CR+;
					TB+TB+TB+'"campo": "recibe", '+CR+;
					TB+TB+TB+'"etiqueta": "Recibe:", '+CR+;
					TB+TB+TB+'"valor": "'+ALLTRIM(recibe)+'"  '+CR+;
				TB+'}'
			
			lcmiDoc=TB+TB+'{'+CR+;
					TB+TB+TB+'"campo": "numDoctoSiga", '+CR+;
					TB+TB+TB+'"etiqueta": "No.Documento Siga:", '+CR+;
					TB+TB+TB+'"valor": "'+ALLTRIM(numero)+'"  '+CR+;
				TB+'}'
			m.apendice=;
					TB+'"apendice": ['+CR+;
						TB+lcMiPlaca+','+CR+;
						TB+lcmiKm+','+CR+;
						TB+lcmiEq+', '+CR+;
						TB+lcmiRec+', '+CR+;
						TB+lcmiDoc+' '+CR+;
					TB+']'

			**** extencion (notas)
			lcnotaDoc=ALLTRIM(notas)+IIF(!EMPTY(notas),',  ','')
			IF !EMPTY(ALLTRIM(lcNotasDetalle+lcnotaDoc))
				m.extencion=;
					TB+'"extension": {'+CR+;
						TB+TB+'"observaciones": "'+lcnotaDoc+lcNotasDetalle+'" '+CR+;
					TB+'}'
			else
				m.extencion=;
					TB+'"extension": {'+CR+;
						TB+TB+'"observaciones": null '+CR+;
					TB+'}'
			ENDIF 
			
			***** creando documento	
			m.documento=;
				TB+'"documento": {'+CR+;
					TB+TB+m.tipoDte+', '+CR+;
					TB+TB+m.ecodEstable+', '+CR+;
					TB+TB+m.ePuntoVenta+', '+CR+;
					m.euuid+;
					m.enumeroControl+;
					m.efechaEmision+;
					m.ehoraEmision+;
					m.etipocontingencia+;
					m.emotivocontingencia+;
					m.eretperdocto+;
					TB+TB+m.econdiPago+', '+CR+;
					m.emision+;
					TB+TB+m.receptor+', '+CR+;
					TB+TB+m.items+', '+CR+;
					TB+TB+m.pagos+', '+CR+;
					TB+TB+m.apendice+', '+CR+;
					TB+TB+m.extencion+' '+CR+;
				TB+'}';

			
			m.StringJson=   '{'+CR+;
								m.documento+' '+CR+;
							'}'+CR

			oJson=m.StringJson
			pcBitacoraDTE=m.StringJson
			
		ELSE 
			lcOkErrorStatus='error'
			lcMensajeOkError='El Documento no es Factura Consumidor Final'
			
		ENDIF 
	ELSE
		lcOkErrorStatus='error'
		lcMensajeOkError='No se encontro el Documento'
		
	ENDIF 


	USE IN c_DTE_STD
	USE IN c_DTE_Vta
	USE IN c_DTE_TDo 
	USE IN c_DTE_SUC
	*USE IN c_MiDocDTE
	USE IN c_DTE_clipro
	USE IN c_DTE_InvPro
	USE IN c_DTE_VtaD
	
	IF !EMPTY(lcAliasDTEDoc)
		SELECT (lcAliasDTEDoc)
	ENDIF 
	IF lcOkErrorStatus='error'
		oJson='null'
	ENDIF 
	
	loRetornaRespuesta = CREATEOBJECT( 'Empty' )
	ADDPROPERTY(loRetornaRespuesta , 'Status', lcOkErrorStatus)
	ADDPROPERTY(loRetornaRespuesta , 'Mensaje', lcMensajeOkError)
	ADDPROPERTY(loRetornaRespuesta , 'DTE', oJson)
	
	m.DTE_Json=oJson
	
	IF lcOkErrorStatus='ok'
		GO TOP IN c_MiDocDTE
		lcArchivoJson=pcRutaJson+'\DTE-'+lcTipoDTE+'-'+ALLTRIM(c_MiDocDTE.codsuc)+ALLTRIM(c_MiDocDTE.CodPTV)+'-'+PADL(ALLTRIM(c_MiDocDTE.numero),15,"0")+'.json'
		StrToFile(oJson,lcArchivoJson)
	ENDIF 
	
	RETURN loRetornaRespuesta
	
ENDFUNC 


******* FACTURA DE EXPORTACION
FUNCTION GenerarDTEVentasFE_V1_sub(lnIdDocVta as Integer)
	*#Define CR		Chr(13)
	*#Define TB		"  "
	lcOkErrorStatus='ok'
	lcMensajeOkError='documento generado correctamente'
	pcBitacoraDTE=''
	
	lcJsonTmp=''
	lcAliasDTEDoc=ALIAS()
	USE pcSysDir+pcdb+"\cyvVentas" IN 0 share AGAIN ALIAS c_DTE_Vta
	USE pcSysDir+pcdb+"\cyvVentasdeta" IN 0 share AGAIN ALIAS c_DTE_VtaD
	USE pcSysDir+pcdb+"\sisTipoDoctos" IN 0 share AGAIN ALIAS c_DTE_STD
	CrearCursorStatus(19,'c_DTE_TDo','') 
	USE pcSysDir+pcdb+"\sisCata" IN 0 share AGAIN ALIAS c_DTE_SUC
	USE pcSysDir+pcdb+"\cyvclipro" IN 0 share AGAIN ALIAS c_DTE_clipro
	USE pcSysDir+pcdb+"\invProductos" IN 0 share AGAIN ALIAS c_DTE_InvPro
	
	SELECT a.*,aa.idproducto,aa.cantiunimed,aa.producto,aa.precioconivaunidad,aa.descuento,;
			aa.pfovial,aa.pcotrans,c.tipd,PADL(SUBSTR(ALLTRIM(d.cod),1,4),4,"0") as CodSuc,;
			PADL(SUBSTR(ALLTRIM(e.cod),1,4),4,"0") as CodPTV,;
			d.tipoestablecimiento,d.correo as correosuc,d.telefono ,;
			SUBSTR(solonumeros(NVL(IIF(EMPTY(f.celular),f.telefono,f.celular),SPACE(20))),1,8) as telcel,;
			f.codgiro,f.giro as giroclipro,f.correoDTE as correo,g.codprod,g.tipoprod,g.escombustible ,;
			f.pasaporte as passcli,f.carnetresidente as carnetcli,f.otro as otrocli,;
			f.nombre,f.tipopersona,f.codpais,_ConvertirToFechaSQL(fechadocto) as fechaDTE,ALLTRIM(horadocto) as horaDTE,;
			d.cod AS codMatrizSuc,e.PtVenta as codMatrizPTV ;
		FROM c_DTE_Vta a ;
			inner JOIN c_DTE_VtaD aa ON a.iddocto=aa.iddocto AND aa.eliminado=0 AND INLIST(aa.tipoprod,1,2);
			inner JOIN c_DTE_STD b ON a.idtipodocto=b.idtipodocto ;
			inner JOIN c_DTE_TDo c ON b.tipoicv=c.id ;
			left join c_DTE_SUC d ON a.idsucursal=d.id and d.origen='SUC' ;
			left join c_DTE_SUC e ON a.idptovta=e.id and e.origen='PTV' ;
			left JOIN c_DTE_clipro f ON a.idclipro=f.idclipro ;
			INNER JOIN c_DTE_InvPro g ON aa.idproducto=g.idproducto ;
		WHERE a.iddocto=lnIdDocVta AND b.tipoicv<>0 AND !INLIST(g.codprod,"NOTA") AND ((aa.idproducto<>idkit AND aa.llavekit<>0) OR aa.llavekit=0) ;
		INTO CURSOR c_MiDocDTE
	
	SELECT c_MiDocDTE

	lcTipoDTE=ALLTRIM(ALLTRIM(tipd))

	oJson = newobject('json')

	IF !EMPTY(NVL(lcTipoDTE,''))
		IF lcTipoDTE='11'		&&& es factura exportacion	
			****** Documento
			m.tipoDte='"tipo_dte": "'+lcTipoDTE+'"'
			m.ecodEstable='"establecimiento": "'+ALLTRIM(codmatrizSuc)+'"'
			m.ePuntoVenta='"punto_venta": "'+ALLTRIM(codmatrizPTV)+'"'
			IF pnuuidSello=1
				m.euuid=TB+TB+'"uuid": "'+ALLTRIM(codigoGeneracion)+'"'+', '+CR
				m.enumeroControl=TB+TB+'"numero_control": "'+ALLTRIM(numerocontrol)+'"'+', '+CR
				m.efechaEmision=TB+TB+'"fecha_emision": "'+fechaDTE+'"'+', '+CR
				m.ehoraEmision=TB+TB+'"hora_emision": "'+ALLTRIM(HoraDTE)+'"'+', '+CR
			ELSE
				m.euuid=''
				m.enumeroControl=''
				m.efechaEmision=''
				m.ehoraEmision=''
			ENDIF 
			
			m.ecodEstable='"establecimiento": "'+ALLTRIM(codsuc)+'"'
			m.etipoItem='"tipo_item_exportacion": '+ALLTRIM(STR(tipoprod))+''
			m.econdiPago='"condicion_pago": '+ALLTRIM(STR(condipago+1))+' '
			m.ecodigoincoterm='"codigo_incoterm": "05"'
			
			m.etipocontingencia=''
			m.emotivocontingencia=''
			IF pnTipoContinDTE=1		&&& tipo contingencia ministerio de hacienda error
				IF pnuuidSello=0
					m.etipocontingencia=TB+TB+TB+'"tipo_contingencia": '+ALLTRIM(STR(pnTipoContinDTE))+', '+CR
				ENDIF 
			ENDIF 
			IF pnTipoContinDTE=5		&&& tipo contingencia ministerio de hacienda error
				m.etipocontingencia=TB+TB+TB+'"tipo_contingencia": '+ALLTRIM(STR(pnTipoContinDTE))+', '+CR
				m.emotivocontingencia=TB+TB+TB+'"motivo_contingencia": "'+ALLTRIM(pcContingenciaDTE)+'", '+CR
			ENDIF 


			
			****** receptor
			lcNumDoc=_DigaPassCar(passcli,carnetcli,otrocli)
			lctipDoc=_esPassCar(passcli,carnetcli,otrocli)
			lcCorreoClienteTmp=ValidarVariosCorreos(correo,1)
			lccorreocliente=IIF(EMPTY(NVL(lcCorreoClienteTmp,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmp)+'"')
			m.rcorreo='"correo": '+lccorreocliente+' '
			lcCorreoClienteTmpCC=ValidarVariosCorreos(correo,2)
			lccorreoclienteCC=IIF(EMPTY(NVL(lcCorreoClienteTmpCC,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmpCC)+'"')
			m.rcorreo_cc='"correos_cc": '+lccorreoclienteCC+' '
			
			IF EMPTY(lcNumDoc)
				lcNumDoc=SoloNumeros(nit)
				lctipDoc='36'		&& 36 nit, 13 dui
 				
			ENDIF 
			
			m.rnumDocumento='"numero_documento": "'+lcNumDoc+'"'
			m.rtipoDocumento='"tipo_documento": "'+lctipDoc+'"'
			m.rnombre='"nombre": "'+UPPER(ALLTRIM(clipro))+'"'
			m.rcodActividad='"descripcion_actividad": "'+IIF(EMPTY(NVL(giro,"")),"null",ALLTRIM(giro))+'"'
			m.rnombrecomercial='"nombre_comercial": "'+UPPER(ALLTRIM(nombre))+'"'
			m.rcodigopais='"codigo_pais": "'+UPPER(ALLTRIM(codpais))+'"'
			m.rcomplemento='"complemento": "'+ALLTRIM(_EscaparJson(Direccion))+'"'
			
			m.rtipopersona='"tipo_persona": '+ALLTRIM(STR(tipopersona))+''
			
			m.receptor=;
				TB+'"receptor": {'+CR+;
					TB+TB+m.rnumDocumento+', '+CR+;
					TB+TB+m.rtipoDocumento+', '+CR+;
					TB+TB+m.rnombre+', '+CR+;
					TB+TB+m.rcodActividad+', '+CR+;
					TB+TB+m.rnombreComercial+', '+CR+;
					TB+TB+m.rcodigopais+', '+CR+;
					TB+TB+m.rcomplemento+', '+CR+;
					TB+TB+m.rcorreo_cc+', '+CR+;
					TB+TB+m.rcorreo+', '+CR+;
					TB+TB+m.rtipopersona+' '+CR+;
				TB+'}'
				
		
			***** forma de pago
			IF condipago=1	&&& es contado
				m.pagos=;
				TB+'"pagos": null'
			ELSE
				m.pcodigo='"tipo": "01"'
				m.pmontoPago='"monto": '+ALLTRIM(STR(totaldocto,12,8))+' '
				m.pagos=;
				'"pagos": ['+CR+;
					TB+TB+TB+'{'+CR+;
						TB+TB+TB+TB+m.pcodigo+', '+CR+;
						TB+TB+TB+TB+m.pmontoPago+' '+CR+;
					TB+TB+TB+'}'+CR+;
				TB+TB+'] '
			ENDIF 
			
			
			 ****** Venta 
			m.detalledoc=''
			m.uniondetalle=''
			m.linea=0
			m.fila=''
			SCAN all
				m.cdcantidad='"cantidad": '+ALLTRIM(STR(cantiunimed,12,6))+''
				m.cduniMedida='"unidad_medida": '+IIF(esCombustible=1,'22','59')
				m.cddescripcion='"descripcion": "'+ALLTRIM(_sincomilliasoTildes(producto))+'"'
				m.cdprecioUni='"precio_unitario": '+ALLTRIM(STR(precioconivaunidad-pfovial-pcotrans-descuento,12,8))+''
				
				m.fila=m.fila+m.uniondetalle+'{'+CR+;
					TB+TB+TB+m.cdcantidad+', '+CR+;
					TB+TB+TB+TB+m.cduniMedida+', '+CR+;
					TB+TB+TB+m.cddescripcion+', '+CR+;
					TB+TB+TB+m.cdprecioUni+' '+CR+;
					TB+TB+'}'
				
				m.uniondetalle=', '+CR
				m.linea=m.linea+1
			ENDSCAN 
			GO TOP
			IF fovialdocto<>0
				m.cdcantidad='"cantidad": 1'
				m.cduniMedida='"unidad_medida": 99' 
				m.cddescripcion='"descripcion": "IMPUESTO: FOVIAL (D1)"'
				m.cdprecioUni='"precio_unitario": '+ALLTRIM(STR(fovialdocto,12,8))+''
				
				m.fila=m.fila+m.uniondetalle+'{'+CR+;
					TB+TB+TB+'"venta_no_gravada": true, '+CR+;
					TB+TB+TB+m.cdcantidad+', '+CR+;
					TB+TB+TB+TB+m.cduniMedida+', '+CR+;
					TB+TB+TB+m.cddescripcion+', '+CR+;
					TB+TB+TB+m.cdprecioUni+' '+CR+;
					TB+TB+'}'
				m.linea=m.linea+1
			ENDIF 
			IF cotransdocto<>0
				m.cdcantidad='"cantidad": 1'
				m.cduniMedida='"unidad_medida": 99' 
				m.cddescripcion='"descripcion": "IMPUESTO: COTRANS (C8)"'
				m.cdprecioUni='"precio_unitario": '+ALLTRIM(STR(cotransdocto,12,8))+''
				
				m.fila=m.fila+m.uniondetalle+'{'+CR+;
					TB+TB+TB+'"venta_no_gravada": true, '+CR+;
					TB+TB+TB+m.cdcantidad+', '+CR+;
					TB+TB+TB+TB+m.cduniMedida+', '+CR+;
					TB+TB+TB+m.cddescripcion+', '+CR+;
					TB+TB+TB+m.cdprecioUni+' '+CR+;
					TB+TB+'}'
				m.linea=m.linea+1
			ENDIF 
			m.items=;
					TB+'"items": [ '+CR+;
						m.fila+' '+CR+;
					']'+CR

			lcmiDoc=TB+TB+'{'+CR+;
					TB+TB+TB+'"campo": "numDoctoSiga", '+CR+;
					TB+TB+TB+'"etiqueta": "No.Documento Siga:", '+CR+;
					TB+TB+TB+'"valor": "'+ALLTRIM(numero)+'"  '+CR+;
				TB+'}'
				
			m.apendice=;
					TB+'"apendice": ['+CR+;
						TB+lcmiDoc+' '+CR+;
					TB+']'

			***** creando documento	
			m.documento=;
				TB+'"documento": {'+CR+;
					TB+TB+m.tipoDte+', '+CR+;
					TB+TB+m.ecodEstable+', '+CR+;
					TB+TB+m.ePuntoVenta+', '+CR+;
					m.euuid+;
					m.enumeroControl+;
					m.efechaEmision+;
					m.ehoraEmision+;
					m.etipocontingencia+;
					m.emotivocontingencia+;
					TB+TB+m.etipoItem+', '+CR+;
					TB+TB+m.econdiPago+', '+CR+;
					TB+TB+m.receptor+', '+CR+;
					TB+TB+m.ecodigoincoterm+', '+CR+;
					TB+TB+m.items+', '+CR+;
					TB+TB+m.pagos+', '+CR+;
					TB+TB+m.apendice+' '+CR+;
				TB+'}';

			
			m.StringJson=   '{'+CR+;
								m.documento+' '+CR+;
							'}'+CR

			oJson=m.StringJson
			pcBitacoraDTE=m.StringJson
		ELSE 
			lcOkErrorStatus='error'
			lcMensajeOkError='El Documento no es Credito Fiscal'
			
		ENDIF 
	ELSE
		lcOkErrorStatus='error'
		lcMensajeOkError='No se encontro el Documento'
		
	ENDIF 

	USE IN c_DTE_STD
	USE IN c_DTE_Vta
	USE IN c_DTE_TDo 
	USE IN c_DTE_SUC
	*USE IN c_MiDocDTE
	USE IN c_DTE_clipro
	USE IN c_DTE_InvPro
	USE IN c_DTE_VtaD
	
	IF !EMPTY(lcAliasDTEDoc)
		SELECT (lcAliasDTEDoc)
	ENDIF 
	IF lcOkErrorStatus='error'
		oJson='null'
	ENDIF 
	
	loRetornaRespuesta = CREATEOBJECT( 'Empty' )
	ADDPROPERTY(loRetornaRespuesta , 'Status', lcOkErrorStatus)
	ADDPROPERTY(loRetornaRespuesta , 'Mensaje', lcMensajeOkError)
	ADDPROPERTY(loRetornaRespuesta , 'DTE', oJson)
	
	IF lcOkErrorStatus='ok'
		GO TOP IN c_MiDocDTE
		lcArchivoJson=pcRutaJson+'\DTE-'+lcTipoDTE+'-'+ALLTRIM(c_MiDocDTE.codsuc)+ALLTRIM(c_MiDocDTE.CodPTV)+'-'+PADL(ALLTRIM(c_MiDocDTE.numero),15,"0")+'.json'
		StrToFile(oJson,lcArchivoJson)
	ENDIF 
	
	RETURN loRetornaRespuesta
	
ENDFUNC 



******************** JSON CREDITO FISCAL
FUNCTION GenerarDTEVentasCCF_V1_sub(lnIdDocVta as Integer)
	*#Define CR		Chr(13)
	*#Define TB		"  "
	lcOkErrorStatus='ok'
	lcMensajeOkError='documento generado correctamente'
	pcBitacoraDTE=''
	
	lcJsonTmp=''
	lcAliasDTEDoc=ALIAS()
	USE pcSysDir+pcdb+"\cyvVentas" IN 0 share AGAIN ALIAS c_DTE_Vta
	USE pcSysDir+pcdb+"\cyvVentasdeta" IN 0 share AGAIN ALIAS c_DTE_VtaD
	USE pcSysDir+pcdb+"\sisTipoDoctos" IN 0 share AGAIN ALIAS c_DTE_STD
	CrearCursorStatus(19,'c_DTE_TDo','') 
	USE pcSysDir+pcdb+"\sisCata" IN 0 share AGAIN ALIAS c_DTE_SUC
	USE pcSysDir+pcdb+"\cyvclipro" IN 0 share AGAIN ALIAS c_DTE_clipro
	USE pcSysDir+pcdb+"\invProductos" IN 0 share AGAIN ALIAS c_DTE_InvPro
	
	
	SELECT a.*,aa.idproducto,aa.cantiunimed,aa.producto,aa.precioconivaunidad,aa.preciosiniva,;
			aa.preciosinivaunidad,aa.descuento,aa.fovial,aa.cotrans,aa.pfovial,aa.pcotrans,;
			aa.totalgravado,aa.totaliva,aa.poriva,aa.totalventasiniva,;
			c.tipd,PADL(SUBSTR(ALLTRIM(d.cod),1,4),4,"0") as CodSuc,;
			PADL(SUBSTR(ALLTRIM(e.cod),1,4),4,"0") as CodPTV,;
			d.tipoestablecimiento,d.correo as correosuc,d.telefono ,;
			solonumeros(a.celular) as telcel,;
			f.codgiro,f.giro as giroclipro,f.correoDTE as correo,g.codprod,;
			g.tipoprod,g.escombustible,g.esnota,NVL(h.cod,SPACE(10)) as deptocli, ;
			NVL(i.cod,SPACE(10)) as municli ,_ConvertirToFechaSQL(fechadocto) as fechaDTE,ALLTRIM(horadocto) as horaDTE,;
			d.cod AS codMatrizSuc,e.PtVenta as codMatrizPTV ;
		FROM c_DTE_Vta a ;
			inner JOIN c_DTE_VtaD aa ON a.iddocto=aa.iddocto AND aa.eliminado=0 AND INLIST(aa.tipoprod,1,2);
			inner JOIN c_DTE_STD b ON a.idtipodocto=b.idtipodocto ;
			inner JOIN c_DTE_TDo c ON b.tipoicv=c.id ;
			left join c_DTE_SUC d ON a.idsucursal=d.id and d.origen='SUC' ;
			left join c_DTE_SUC e ON a.idptovta=e.id and e.origen='PTV' ;
			left JOIN c_DTE_clipro f ON a.idclipro=f.idclipro ;
			INNER JOIN c_DTE_InvPro g ON aa.idproducto=g.idproducto ;
			LEFT JOIN c_DTE_SUC H ON a.iddepto=H.id AND h.origen='DEP' ;
			LEFT JOIN c_DTE_SUC I ON a.idMuni=I.id AND i.origen='MUN' ;
		WHERE a.iddocto=lnIdDocVta AND b.tipoicv<>0  AND ((aa.idproducto<>idkit AND aa.llavekit<>0) OR aa.llavekit=0) ;
		INTO CURSOR c_MiDocDTE
	
	SELECT c_MiDocDTE

	
	lcTipoDTE=ALLTRIM(ALLTRIM(tipd))
	
	oJson = newobject('json')
	
	IF !EMPTY(NVL(lcTipoDTE,''))
		IF lcTipoDTE='03'		&&& es Credito Fiscal			
			****** Documento
			m.tipoDte='"tipo_dte": "'+lcTipoDTE+'"'
			m.ecodEstable='"establecimiento": "'+ALLTRIM(codmatrizSuc)+'"'
			m.ePuntoVenta='"punto_venta": "'+ALLTRIM(codmatrizPTV)+'"'
			IF pnuuidSello=1
				m.euuid=TB+TB+'"uuid": "'+ALLTRIM(codigoGeneracion)+'"'+', '+CR
				m.enumeroControl=TB+TB+'"numero_control": "'+ALLTRIM(numerocontrol)+'"'+', '+CR
				m.efechaEmision=TB+TB+'"fecha_emision": "'+fechaDTE+'"'+', '+CR
				m.ehoraEmision=TB+TB+'"hora_emision": "'+ALLTRIM(HoraDTE)+'"'+', '+CR
			ELSE
				m.euuid=''
				m.enumeroControl=''
				m.efechaEmision=''
				m.ehoraEmision=''
			ENDIF 
			m.ecodEstable='"establecimiento": "'+ALLTRIM(codsuc)+'"'
			m.econdiPago='"condicion_pago": '+ALLTRIM(STR(condipago+1))+' '		
			m.etipocontingencia=''
			m.emotivocontingencia=''
			IF retperdocto<>0
				m.eretperdocto=TB+TB+'"percibir_iva": true , '+CR
			ELSE
				m.eretperdocto=''
			ENDIF 

			IF pnTipoContinDTE=1		&&& tipo contingencia ministerio de hacienda error
				IF pnuuidSello=0
					m.etipocontingencia=TB+TB+TB+'"tipo_contingencia": '+ALLTRIM(STR(pnTipoContinDTE))+', '+CR
				ENDIF 
			ENDIF 
			IF pnTipoContinDTE=5		&&& tipo contingencia ministerio de hacienda error
				m.etipocontingencia=TB+TB+TB+'"tipo_contingencia": '+ALLTRIM(STR(pnTipoContinDTE))+', '+CR
				m.emotivocontingencia=TB+TB+TB+'"motivo_contingencia": "'+ALLTRIM(pcContingenciaDTE)+'", '+CR
			ENDIF 
			
			
			****** receptor
			lcNumDoc=SoloNumeros(IIF(EMPTY(NVL(nit,'')),ValidarDUI(NVL(dui,'')),NVL(nit,"")))
			lctipDoc=IIF(EMPTY(lcNumDoc),"null",IIF(LEN(lcNumdoc)>12,"36","13")) 
			lcCorreoClienteTmp=ValidarVariosCorreos(correo,1)
			lccorreocliente=IIF(EMPTY(NVL(lcCorreoClienteTmp,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmp)+'"')
			m.rcorreo='"correo": '+lccorreocliente+' '
			lcCorreoClienteTmpCC=ValidarVariosCorreos(correo,2)
			lccorreoclienteCC=IIF(EMPTY(NVL(lcCorreoClienteTmpCC,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmpCC)+'"')
			m.rcorreo_cc='"correos_cc": '+lccorreoclienteCC+' '
			
			
			IF lctipDoc="13" AND !EMPTY(lcNumDoc)		 &&&& poniendo gion al dui
				lcNumDoc=PADL(lcNumDoc,9,'0')
				lcNumDoc=SUBSTR(lcNumDoc,1,8)+'-'+SUBSTR(lcNumDoc,9,1)
				lcNumDoc='"'+ALLTRIM(lcNumDoc)+'"'
			ELSE
				IF EMPTY(lcNumDoc)
					lcNumDoc='null'
				ELSE
					lcNumDoc='"'+lcNumDoc+'"'
				ENDIF  
			ENDIF 
			IF lctipDoc<>'null'
				lctipDoc='"'+lctipDoc+'"'
			ENDIF 
			
			lcDistritotmp=buscaCodigoDTE(ALLTRIM(municli),'213','c_Distri',ALLTRIM(deptocli))
			lccodDistrito=SUBSTR(lcDistritotmp,1,2)
			lcNomDistrito=ALLTRIM(SUBSTR(lcDistritotmp,AT(',',lcDistritotmp)+2,150))

			m.rnumDocumento='"numero_documento": '+lcNumDoc+' '
			m.rtipoDocumento='"tipo_documento": '+lctipDoc+' '
			m.rnrc='"nrc": '+IIF(EMPTY(NVL(nrc,"")),"null",'"'+SoloNumeros(ALLTRIM(nrc))+'"')+' '
			m.rnombre='"nombre": "'+UPPER(ALLTRIM(clipro))+'"'
			m.rcodActividad='"codigo_actividad": "'+IIF(EMPTY(NVL(codgiro,"")),"null",ALLTRIM(codgiro))+'"'
			m.rnombreComercial='"nombre_comercial": "'+UPPER(ALLTRIM(clipro))+'"'
				***** direccion receptor
				m.rdepartamento='"departamento": "'+ALLTRIM(deptocli)+'"'
				m.rmunicipio='"municipio": "'+ALLTRIM(lccodDistrito)+'"'
				m.rcomplemento='"complemento": "'+ALLTRIM(_EscaparJson(ALLTRIM(Direccion)+''))+'"'
			m.rtelefono='"telefono": "'+ALLTRIM(solonumeros(telcel))+'"'
			
			m.receptor=;
				TB+'"receptor": {'+CR+;
					TB+TB+m.rnumDocumento+', '+CR+;
					TB+TB+m.rtipoDocumento+', '+CR+;
					TB+TB+m.rnrc+', '+CR+;
					TB+TB+m.rnombre+', '+CR+;
					TB+TB+m.rcodActividad+', '+CR+;
					TB+TB+m.rnombreComercial+', '+CR+;
					TB+TB+'"direccion": {'+CR+;
						TB+TB+TB+m.rdepartamento+', '+CR+;
						TB+TB+TB+m.rmunicipio+', '+CR+;
						TB+TB+TB+m.rcomplemento+CR+;
					TB+TB+'}, '+CR+;
					TB+TB+m.rtelefono+', '+CR+;
					TB+TB+m.rcorreo_cc+', '+CR+;
					TB+TB+m.rcorreo+' '+CR+;
				TB+'}'
				

			***** forma de pago
			IF condipago=1	&&& es contado
				m.pagos=;
				TB+'"pagos": null'
			ELSE
				m.pcodigo='"tipo": "01"'
				*.pmontoPago='"monto": '+ALLTRIM(STR(totaldocto+ABS(retperdocto),12,8))+' '
				m.pmontoPago='"monto": '+ALLTRIM(STR(totaldocto,12,8))+' '
				m.pagos=;
				'"pagos": ['+CR+;
					TB+TB+TB+'{'+CR+;
						TB+TB+TB+TB+m.pcodigo+', '+CR+;
						TB+TB+TB+TB+m.pmontoPago+' '+CR+;
					TB+TB+TB+'}'+CR+;
				TB+TB+'] '
			ENDIF 
			
				
			 ****** Venta 
			m.detalledoc=''
			m.uniondetalle=''
			m.linea=0
			m.fila=''
			lcNotasDetalle=''
			lcUnionNotas=''
			SCAN all
				IF esnota=1		&&& es nota o comentario
						IF !EMPTY(ALLTRIM(producto))
							lcNotasDetalle=lcNotasDetalle+lcUnionNotas+ALLTRIM(producto)
							lcUnionNotas=',  '
						ENDIF 
				ELSE
					m.tipVenta='"tipo_venta": '+IIF(tipoiva=0,'"3"',IIF(tipoiva=1,'"1"',IIF(tipoiva=2,'"2"','"4"')))
					m.cdtipoItem='"tipo": '+ALLTRIM(STR(tipoprod))+''
					m.cdcantidad='"cantidad": '+ALLTRIM(STR(cantiunimed,12,6))+''
					m.cduniMedida='"unidad_medida": '+IIF(esCombustible=1,'22','59')
					lndescusiniva=descuento/((poriva+100.00)/100)
					midescuento=lndescusiniva*cantiunimed
					m.cddescuento='"descuento": '+ALLTRIM(STR(midescuento,12,8))+''
					m.cddescripcion='"descripcion": "'+ALLTRIM(_sincomilliasoTildes(producto))+'"'
					m.cdprecioUni='"precio_unitario": '+ALLTRIM(STR(((totalventasiniva+midescuento)/IIF(cantiunimed=0,1,cantiunimed)),12,8))+''


					**** Item Tributo
					IF totaliva<>0
						m.cdcodiva='"codigo": "20"'
						m.cdmontoiva='"monto": '+ALLTRIM(STR(totaliva,12,8))+''
						m.cditemiva=TB+TB+'{'+CR+;
										TB+TB+TB+m.cdcodiva+', '+CR+;
										TB+TB+TB+m.cdmontoiva+' '+CR+;
										TB+TB+'}'
						IF cotrans<>0 OR fovial<>0
							m.cditemiva=m.cditemiva+', '+CR
						ENDIF 
					ELSE
						m.cditemiva=''
					ENDIF 
					IF esCombustible=1
						m.cditemcotrans=''
						m.cditemfovial=''
						IF cotrans<>0
							m.cdcodcotrans='"codigo": "C8"'
							m.cdmontocotrans='"monto": '+ALLTRIM(STR(cotrans,12,8))+''
							m.cdcantidadgravablecotrans='"cantidad_gravable": '+ALLTRIM(STR(cantiunimed,12,6))+''
							m.cditemcotrans=TB+TB+'{'+CR+;
											TB+TB+TB+m.cdcodcotrans+', '+CR+;
											TB+TB+TB+m.cdmontocotrans+', '+CR+;
											TB+TB+TB+m.cdcantidadgravablecotrans+' '+CR+;
											TB+TB+'}'
						ENDIF 
						IF fovial<>0
							m.cdcodfovial='"codigo": "D1"'
							m.cdmontofovial='"monto": '+ALLTRIM(STR(fovial,12,8))+''
							m.cdcantidadgravablefovial='"cantidad_gravable": '+ALLTRIM(STR(cantiunimed,12,6))+''
							m.cditemfovial=TB+TB+TB+'{'+CR+;
											TB+TB+TB+TB+m.cdcodfovial+', '+CR+;
											TB+TB+TB+TB+m.cdmontofovial+', '+CR+;
											TB+TB+TB+TB+m.cdcantidadgravablefovial+' '+CR+;
											TB+TB+TB+'}'
						ENDIF 
						*** uniendo tributos
						IF !EMPTY(m.cditemcotrans) AND !EMPTY(m.cditemfovial)
							m.itemtributo='"tributos": [ '+CR+;
											m.cditemiva+;
											m.cditemcotrans+', '+CR+;
											m.cditemfovial+' '+CR+;
											TB+TB+']'+CR
						ELSE
							IF !EMPTY(m.cditemcotrans)
								m.itemtributo='"tributos": [ '+CR+;
											m.cditemiva+;
											m.cditemcotrans+' '+CR+;
											TB+TB+']'+CR
							ENDIF 
							IF !EMPTY(m.cditemfovial)
								m.itemtributo='"tributos": [ '+CR+;
											m.cditemiva+;
											m.cditemfovial+' '+CR+;
											TB+TB+']'+CR
							ENDIF 
						ENDIF 
					ELSE
						IF totaliva<>0
							m.itemtributo='"tributos": [ '+CR+;
											m.cditemiva+' '+CR+;
											TB+TB+']'+CR
						ELSE 
							m.itemtributo='"tributos": null'
						ENDIF 
					ENDIF 
					
					m.fila=m.fila+m.uniondetalle+'{'+CR+;
						TB+TB+TB+m.tipVenta+', '+CR+;
						TB+TB+TB+m.cdtipoItem+', '+CR+;
						TB+TB+TB+m.cdcantidad+', '+CR+;
						TB+TB+TB+TB+m.cduniMedida+', '+CR+;
						TB+TB+TB+TB+m.cddescuento+', '+CR+;
						TB+TB+TB+m.cddescripcion+', '+CR+;
						TB+TB+TB+m.cdprecioUni+', '+CR+;
						TB+TB+TB+m.itemtributo+' '+CR+;
						TB+TB+'}'
					
					m.uniondetalle=', '+CR
					m.linea=m.linea+1
	
				ENDIF 
			ENDSCAN 
			GO TOP 
			
			m.items=;
					TB+'"items": [ '+CR+;
						m.fila+' '+CR+;
					']'+CR
			
			**** apendice
			lcApendices=''
			lcmiPlaca=TB+TB+'{'+CR+;
					TB+TB+TB+'"campo": "placa", '+CR+;
					TB+TB+TB+'"etiqueta": "Placa:", '+CR+;
					TB+TB+TB+'"valor": "'+ALLTRIM(placa)+'" '+CR+;
				TB+'}'

			lcmiKM=TB+TB+'{'+CR+;
					TB+TB+TB+'"campo": "km", '+CR+;
					TB+TB+TB+'"etiqueta": "Km/Milla:", '+CR+;
					TB+TB+TB+'"valor": "'+ALLTRIM(KILOMETRAJE)+'" '+CR+;
				TB+'}'

			lcmiEq=TB+TB+'{'+CR+;
					TB+TB+TB+'"campo": "equipo", '+CR+;
					TB+TB+TB+'"etiqueta": "Eq.:", '+CR+;
					TB+TB+TB+'"valor": "'+ALLTRIM(marca)+'"  '+CR+;
				TB+'}'
			
			lcmiRec=TB+TB+'{'+CR+;
					TB+TB+TB+'"campo": "recibe", '+CR+;
					TB+TB+TB+'"etiqueta": "Recibe:", '+CR+;
					TB+TB+TB+'"valor": "'+ALLTRIM(recibe)+'"  '+CR+;
				TB+'}'
				
			lcmiDoc=TB+TB+'{'+CR+;
					TB+TB+TB+'"campo": "numDoctoSiga", '+CR+;
					TB+TB+TB+'"etiqueta": "No.Documento Siga:", '+CR+;
					TB+TB+TB+'"valor": "'+ALLTRIM(numero)+'"  '+CR+;
				TB+'}'
			m.apendice=;
					TB+'"apendice": ['+CR+;
						TB+lcMiPlaca+','+CR+;
						TB+lcmiKm+','+CR+;
						TB+lcmiEq+', '+CR+;
						TB+lcmiRec+', '+CR+;
						TB+lcmiDoc+' '+CR+;
					TB+']'

			**** extencion (notas)
			lcnotaDoc=ALLTRIM(notas)+IIF(!EMPTY(notas),',  ','')
			IF !EMPTY(ALLTRIM(lcNotasDetalle+lcnotaDoc))
				m.extencion=;
					TB+'"extension": {'+CR+;
						TB+TB+'"observaciones": "'+lcnotaDoc+lcNotasDetalle+'" '+CR+;
					TB+'}'
			else
				m.extencion=;
					TB+'"extension": {'+CR+;
						TB+TB+'"observaciones": null '+CR+;
					TB+'}'
			ENDIF 
			
			
			***** creando documento	
			m.documento=;
				TB+'"documento": {'+CR+;
					TB+TB+m.tipoDte+', '+CR+;
					TB+TB+m.ecodEstable+', '+CR+;
					TB+TB+m.ePuntoVenta+', '+CR+;
					m.euuid+;
					m.enumeroControl+;
					m.efechaEmision+;
					m.ehoraEmision+;
					m.etipocontingencia+;
					m.emotivocontingencia+;
					m.eretperdocto+;
					TB+TB+m.econdiPago+', '+CR+;
					TB+TB+m.receptor+', '+CR+;
					TB+TB+m.items+', '+CR+;
					TB+TB+m.pagos+', '+CR+;
					TB+TB+m.apendice+', '+CR+;
					TB+TB+m.extencion+' '+CR+;
				TB+'}';

			
			m.StringJson=   '{'+CR+;
								m.documento+' '+CR+;
							'}'+CR

			oJson=m.StringJson
			pcBitacoraDTE=m.StringJson
 			
		ELSE 
			lcOkErrorStatus='error'
			lcMensajeOkError='El Documento no es Credito Fiscal'
			
		ENDIF 
	ELSE
		lcOkErrorStatus='error'
		lcMensajeOkError='No se encontro el Documento'
		
	ENDIF 

	USE IN c_DTE_STD
	USE IN c_DTE_Vta
	USE IN c_DTE_TDo 
	USE IN c_DTE_SUC
	*USE IN c_MiDocDTE
	USE IN c_DTE_clipro
	USE IN c_DTE_InvPro
	USE IN c_DTE_VtaD
	
	
	IF !EMPTY(lcAliasDTEDoc)
		SELECT (lcAliasDTEDoc)
	ENDIF 
	IF lcOkErrorStatus='error'
		oJson='null'
	ENDIF 
	
	loRetornaRespuesta = CREATEOBJECT( 'Empty' )
	ADDPROPERTY(loRetornaRespuesta , 'Status', lcOkErrorStatus)
	ADDPROPERTY(loRetornaRespuesta , 'Mensaje', lcMensajeOkError)
	ADDPROPERTY(loRetornaRespuesta , 'DTE', oJson)
	
	IF lcOkErrorStatus='ok'
		GO TOP IN c_MiDocDTE
		lcArchivoJson=pcRutaJson+'\DTE-'+lcTipoDTE+'-'+ALLTRIM(c_MiDocDTE.codsuc)+ALLTRIM(c_MiDocDTE.CodPTV)+'-'+PADL(ALLTRIM(c_MiDocDTE.numero),15,"0")+'.json'
		StrToFile(oJson,lcArchivoJson)
	ENDIF 
	
	
	RETURN loRetornaRespuesta
	
ENDFUNC 




******************** JSON REMISION
FUNCTION GenerarDTEVentasREM_V1_sub(lnIdDocVta as Integer)
	*#Define CR		Chr(13)
	*#Define TB		"  "
	lcOkErrorStatus='ok'
	lcMensajeOkError='documento generado correctamente'
	pcBitacoraDTE=''
	
	lcJsonTmp=''
	lcAliasDTEDoc=ALIAS()
	USE pcSysDir+pcdb+"\cyvVentas" IN 0 share AGAIN ALIAS c_DTE_Vta
	USE pcSysDir+pcdb+"\cyvVentasdeta" IN 0 share AGAIN ALIAS c_DTE_VtaD
	USE pcSysDir+pcdb+"\sisTipoDoctos" IN 0 share AGAIN ALIAS c_DTE_STD
	CrearCursorStatus(19,'c_DTE_TDo','') 
	USE pcSysDir+pcdb+"\sisCata" IN 0 share AGAIN ALIAS c_DTE_SUC
	USE pcSysDir+pcdb+"\cyvclipro" IN 0 share AGAIN ALIAS c_DTE_clipro
	USE pcSysDir+pcdb+"\invProductos" IN 0 share AGAIN ALIAS c_DTE_InvPro
	USE pcSysDir+pcdb+"\sisDTE" IN 0 share AGAIN ALIAS c_SIS_DTE
	
	**** REMISION
	SELECT a.*,aa.idproducto,aa.cantiunimed,aa.producto,aa.precioconivaunidad,aa.preciosiniva,;
			aa.preciosinivaunidad,aa.descuento,aa.fovial,aa.cotrans,aa.pfovial,aa.pcotrans,;
			aa.totalgravado,aa.totaliva,aa.poriva,aa.totalventasiniva,;
			c.tipd,PADL(SUBSTR(ALLTRIM(d.cod),1,4),4,"0") as CodSuc,;
			PADL(SUBSTR(ALLTRIM(e.cod),1,4),4,"0") as CodPTV,;
			d.tipoestablecimiento,d.correo as correosuc,d.telefono ,;
			solonumeros(f.celular)+SPACE(20) as telcel,;
			f.codgiro,f.giro as giroclipro,f.correoDTE as correo,g.codprod,g.tipoprod,g.escombustible, ;
			NVL(h.cod,SPACE(10)) as deptocli, NVL(i.cod,SPACE(10)) as municli, ;
			d.cod AS codMatrizSuc,e.PtVenta as codMatrizPTV ;
		FROM c_DTE_Vta a ;
			inner JOIN c_DTE_VtaD aa ON a.iddocto=aa.iddocto AND aa.eliminado=0 AND INLIST(aa.tipoprod,1,2);
			inner JOIN c_DTE_STD b ON a.idtipodocto=b.idtipodocto ;
			inner JOIN c_DTE_TDo c ON b.tipoicv=c.id ;
			left join c_DTE_SUC d ON a.idsucursal=d.id and d.origen='SUC' ;
			left join c_DTE_SUC e ON a.idptovta=e.id and e.origen='PTV' ;
			left JOIN c_DTE_clipro f ON a.idclipro=f.idclipro ;
			INNER JOIN c_DTE_InvPro g ON aa.idproducto=g.idproducto ;
			LEFT JOIN c_DTE_SUC H ON a.iddepto=H.id AND h.origen='DEP' ;
			LEFT JOIN c_DTE_SUC I ON a.idMuni=I.id AND i.origen='MUN' ;
		WHERE a.iddocto=lnIdDocVta AND b.tipoicv<>0 AND !INLIST(g.codprod,"NOTA") AND ((aa.idproducto<>idkit AND aa.llavekit<>0) OR aa.llavekit=0) ;
		INTO CURSOR c_MiDocDTE
	lnIdDoctoRelacion=iddoctorelacion
	
	**** documento relacionado
	IF lnIdDoctoRelacion<>0
		SELECT a.*,c.tipd,PADL(SUBSTR(ALLTRIM(d.cod),1,4),4,"0") as CodSuc,;
			PADL(SUBSTR(ALLTRIM(e.PtVenta),1,4),4,"0") as CodPTV,;
			d.tipoestablecimiento,d.correo as correosuc,d.telefono, ;
			j.codigoGeneracion as CodigoGeneracionDTE,TTOD(j.fechahora) as fechaDTE ;
		FROM c_DTE_Vta a ;
			inner JOIN c_DTE_STD b ON a.idtipodocto=b.idtipodocto ;
			inner JOIN c_DTE_TDo c ON b.tipoicv=c.id ;
			left join c_DTE_SUC d ON a.idsucursal=d.id and d.origen='SUC' ;
			left join c_DTE_SUC e ON a.idptovta=e.id and e.origen='PTV' ;
			LEFT JOIN c_SIS_DTE j ON a.iddocto=j.iddocto AND j.status=1 AND j.origen=a.origen ;
		WHERE a.iddocto=lnIdDoctoRelacion;
		INTO CURSOR c_MiDocDTERelacionado
		lcTipoDTER=ALLTRIM(ALLTRIM(tipd))
		lnDocRelacionado=RECCOUNT()
	ELSE
		lnDocRelacionado=0
		lcTipoDTER=''
	ENDIF 
	
	SELECT c_MiDocDTE

	
	lcTipoDTE=ALLTRIM(ALLTRIM(tipd))
	
	oJson = newobject('json')
	
	IF !EMPTY(NVL(lcTipoDTE,''))
		IF lcTipoDTE='04'		&&& es REMISION	
			****** Documento
			m.tipoDte='"tipo_dte": "'+lcTipoDTE+'"'
			m.ecodEstable='"establecimiento": "'+ALLTRIM(codmatrizSuc)+'"'
			m.ePuntoVenta='"punto_venta": "'+ALLTRIM(codmatrizPTV)+'"'
			m.econdiPago='"condicion_pago": '+ALLTRIM(STR(condipago+1))+' '
			m.etipocontingencia=''
			m.emotivocontingencia=''
			IF pnTipoContinDTE=1		&&& tipo contingencia ministerio de hacienda error
				m.etipocontingencia=TB+TB+TB+'"tipo_contingencia": '+ALLTRIM(STR(pnTipoContinDTE))+', '+CR
			ENDIF 
			IF pnTipoContinDTE=5		&&& tipo contingencia ministerio de hacienda error
				m.etipocontingencia=TB+TB+TB+'"tipo_contingencia": '+ALLTRIM(STR(pnTipoContinDTE))+', '+CR
				m.emotivocontingencia=TB+TB+TB+'"motivo_contingencia": "'+ALLTRIM(pcContingenciaDTE)+'", '+CR
			ENDIF 
			
			****** Documento Relacionado
			IF lnDocRelacionado<>0
				SELECT c_MiDocDTERelacionado

				m.drtipoDte='"tipo_documento": "'+lcTipoDTER+'"'
				m.drtipoGen='"tipo_generacion": '+IIF(EMPTY(NVL(CodigoGeneracionDTE,"")),'1','2')
				lcnumeroRela=IIF(EMPTY(NVL(CodigoGeneracionDTE,"")),codigoGeneracion,CodigoGeneracionDTE)
				m.drnumDocumento='"numero_documento": "'+ALLTRIM(lcnumeroRela)+'"'
				ldfechadte=IIF(EMPTY(NVL(fechaDTE,CTOD(" "))),fechadocto,fechaDTE)
				m.drfecEmi='"fecha_emision": "'+SUBSTR(_ConvertirToFechaHoraSQL(ldfechadte),1,10)+'"'

				m.docrelacionado=;
				TB+'"documentos_relacionados": ['+CR+;
					TB+TB+'{'+CR+;
					TB+TB+TB+m.drtipoDte+', '+CR+;
					TB+TB+TB+m.drtipoGen+', '+CR+;
					TB+TB+TB+m.drnumDocumento+', '+CR+;
					TB+TB+TB+m.drfecEmi+' '+CR+;
				TB+TB+'}'+;
				TB+']'
				
				SELECT c_MiDocDTE
			ELSE
				m.docrelacionado=;
				TB+'"documentos_relacionados": ['+CR+;
				TB+']'
				m.drnumDocumento='"numero_documento": ""'
			ENDIF 
			
			****** receptor
			lcNumDoc=SoloNumeros(IIF(EMPTY(NVL(nit,'')),ValidarDUI(NVL(dui,'')),NVL(nit,"")))
			lctipDoc=IIF(EMPTY(lcNumDoc),"null",IIF(LEN(lcNumdoc)>12,"36","13")) 
			lcCorreoClienteTmp=ValidarVariosCorreos(correo,1)
			lccorreocliente=IIF(EMPTY(NVL(lcCorreoClienteTmp,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmp)+'"')
			m.rcorreo='"correo": '+lccorreocliente+' '
			lcCorreoClienteTmpCC=ValidarVariosCorreos(correo,2)
			lccorreoclienteCC=IIF(EMPTY(NVL(lcCorreoClienteTmpCC,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmpCC)+'"')
			m.rcorreo_cc='"correos_cc": '+lccorreoclienteCC+' '
			
			IF lctipDoc="13" AND !EMPTY(lcNumDoc)		 &&&& poniendo gion al dui
				lcNumDoc=PADL(lcNumDoc,9,'0')
				lcNumDoc=SUBSTR(lcNumDoc,1,8)+'-'+SUBSTR(lcNumDoc,9,1)
				lcNumDoc='"'+ALLTRIM(lcNumDoc)+'"'
			ELSE
				IF EMPTY(lcNumDoc)
					lcNumDoc='null'
				ELSE
					lcNumDoc='"'+lcNumDoc+'"'
				ENDIF 
			ENDIF 
			IF lctipDoc<>'null'
				lctipDoc='"'+lctipDoc+'"'
			ENDIF 
			
			lcDistritotmp=buscaCodigoDTE(ALLTRIM(municli),'213','c_Distri',ALLTRIM(deptocli))
			lccodDistrito=SUBSTR(lcDistritotmp,1,2)
			lcNomDistrito=ALLTRIM(SUBSTR(lcDistritotmp,AT(',',lcDistritotmp)+2,150))

			m.rnumDocumento='"numero_documento": '+lcNumDoc+' '
			m.rtipoDocumento='"tipo_documento": '+lctipDoc+' '
			m.rnrc='"nrc": '+IIF(EMPTY(NVL(nrc,"")),"null",'"'+SoloNumeros(ALLTRIM(nrc))+'"')+' '
			m.rnombre='"nombre": "'+UPPER(ALLTRIM(clipro))+'"'
			m.rcodActividad='"codigo_actividad": "'+IIF(EMPTY(NVL(codgiro,"")),"null",ALLTRIM(codgiro))+'"'
			m.rnombreComercial='"nombre_comercial": "'+UPPER(ALLTRIM(clipro))+'"'
				***** direccion receptor
				m.rdepartamento='"departamento": "'+ALLTRIM(deptocli)+'"'
				m.rmunicipio='"municipio": "'+ALLTRIM(lccodDistrito)+'"'
				m.rcomplemento='"complemento": "'+ALLTRIM(_EscaparJson(ALLTRIM(Direccion)+', '+lcNomDistrito))+'"'

			m.rtelefono='"telefono": "'+ALLTRIM(solonumeros(telcel))+'"'
			m.rbienTitulo='"titulo_bienes": "02"'
			
			m.receptor=;
				TB+'"receptor": {'+CR+;
					TB+TB+m.rnumDocumento+', '+CR+;
					TB+TB+m.rtipoDocumento+', '+CR+;
					TB+TB+m.rnrc+', '+CR+;
					TB+TB+m.rnombre+', '+CR+;
					TB+TB+m.rcodActividad+', '+CR+;
					TB+TB+m.rnombreComercial+', '+CR+;
					TB+TB+m.rbienTitulo+', '+CR+;
					TB+TB+'"direccion": {'+CR+;
						TB+TB+TB+m.rdepartamento+', '+CR+;
						TB+TB+TB+m.rmunicipio+', '+CR+;
						TB+TB+TB+m.rcomplemento+CR+;
					TB+TB+'}, '+CR+;
					TB+TB+m.rtelefono+', '+CR+;
					TB+TB+m.rcorreo_cc+', '+CR+;
					TB+TB+m.rcorreo+' '+CR+;
				TB+'}'
			
			
			***** forma de pago
			IF condipago=1	&&& es contado
				m.pagos=;
				TB+'"pagos": null'
			ELSE
				m.pcodigo='"tipo": "01"'
				m.pmontoPago='"monto": '+ALLTRIM(STR(totaldocto-ABS(retperdocto),12,8))+' '
				m.pagos=;
				'"pagos": ['+CR+;
					TB+TB+TB+'{'+CR+;
						TB+TB+TB+TB+m.pcodigo+', '+CR+;
						TB+TB+TB+TB+m.pmontoPago+' '+CR+;
					TB+TB+TB+'}'+CR+;
				TB+TB+'] '
			ENDIF 
			
				
			 ****** detalle 
			m.detalledoc=''
			m.uniondetalle=''
			m.linea=0
			m.fila=''
			SCAN all
				m.cdtipoItem='"tipo": '+ALLTRIM(STR(tipoprod))+''
				m.cdcantidad='"cantidad": '+ALLTRIM(STR(cantiunimed,12,6))+''
				m.cduniMedida='"unidad_medida": '+IIF(esCombustible=1,'22','59')
				m.cdnumeroDocumento=m.drnumDocumento
				lndescusiniva=descuento/((poriva+100.00)/100)
				midescuento=lndescusiniva*cantiunimed
				m.cddescuento='"descuento": '+ALLTRIM(STR(midescuento,12,8))+''
				m.cddescripcion='"descripcion": "'+ALLTRIM(_sincomilliasoTildes(producto))+'"'
				m.cdprecioUni='"precio_unitario": '+ALLTRIM(STR(((totalventasiniva+midescuento)/IIF(cantiunimed=0,1,cantiunimed)),12,8))+''

				
				**** Item Tributo
				IF totaliva<>0
					m.cdcodiva='"codigo": "20"'
					m.cdmontoiva='"monto": '+ALLTRIM(STR(totaliva,12,8))+''
					m.cditemiva=TB+TB+'{'+CR+;
									TB+TB+TB+m.cdcodiva+', '+CR+;
									TB+TB+TB+m.cdmontoiva+' '+CR+;
									TB+TB+'}'
					IF cotrans<>0 OR fovial<>0
						m.cditemiva=m.cditemiva+', '+CR
					ENDIF 
				ELSE
					m.cditemiva=''
				ENDIF 
				
				IF esCombustible=1
					m.cditemcotrans=''
					m.cditemfovial=''
					IF cotrans<>0
						m.cdcodcotrans='"codigo": "C8"'
						m.cdmontocotrans='"monto": '+ALLTRIM(STR(cotrans,12,8))+''
						m.cdcantidadgravablecotrans='"cantidad_gravable": '+ALLTRIM(STR(cantiunimed,12,6))+''
						m.cditemcotrans=TB+TB+'{'+CR+;
										TB+TB+TB+m.cdcodcotrans+', '+CR+;
										TB+TB+TB+m.cdmontocotrans+', '+CR+;
										TB+TB+TB+m.cdcantidadgravablecotrans+' '+CR+;
										TB+TB+'}'
					ENDIF 
					IF fovial<>0
						m.cdcodfovial='"codigo": "D1"'
						m.cdmontofovial='"monto": '+ALLTRIM(STR(fovial,12,8))+''
						m.cdcantidadgravablefovial='"cantidad_gravable": '+ALLTRIM(STR(cantiunimed,12,6))+''
						m.cditemfovial=TB+TB+TB+'{'+CR+;
										TB+TB+TB+TB+m.cdcodfovial+', '+CR+;
										TB+TB+TB+TB+m.cdmontofovial+', '+CR+;
										TB+TB+TB+TB+m.cdcantidadgravablefovial+' '+CR+;
										TB+TB+TB+'}'
					ENDIF 
					*** uniendo tributos
					IF !EMPTY(m.cditemcotrans) AND !EMPTY(m.cditemfovial)
						m.itemtributo='"tributos": [ '+CR+;
										m.cditemiva+;
										m.cditemcotrans+', '+CR+;
										m.cditemfovial+' '+CR+;
										TB+TB+']'+CR
					ELSE
						IF !EMPTY(m.cditemcotrans)
							m.itemtributo='"tributos": [ '+CR+;
										m.cditemiva+;
										m.cditemcotrans+' '+CR+;
										TB+TB+']'+CR
						ENDIF 
						IF !EMPTY(m.cditemfovial)
							m.itemtributo='"tributos": [ '+CR+;
										m.cditemiva+;
										m.cditemfovial+' '+CR+;
										TB+TB+']'+CR
						ENDIF 
					ENDIF 
				ELSE
					IF totaliva<>0
						m.itemtributo='"tributos": [ '+CR+;
										m.cditemiva+' '+CR+;
										TB+TB+']'+CR
					ELSE 
						m.itemtributo='"tributos": null'
					ENDIF 
				ENDIF 
				
				
				m.fila=m.fila+m.uniondetalle+'{'+CR+;
					TB+TB+TB+m.cdtipoItem+', '+CR+;
					TB+TB+TB+m.cdcantidad+', '+CR+;
					TB+TB+TB+TB+m.cduniMedida+', '+CR+;
					TB+TB+TB+TB+m.cdnumeroDocumento+', '+CR+;
					TB+TB+TB+m.cddescripcion+', '+CR+;
					TB+TB+TB+m.cdprecioUni+', '+CR+;
					TB+TB+TB+m.itemtributo+' '+CR+;
					TB+TB+'}'
				
				m.uniondetalle=', '+CR
				m.linea=m.linea+1
			ENDSCAN 
			GO TOP 
			
			m.items=;
					TB+'"items": [ '+CR+;
						m.fila+' '+CR+;
					']'+CR

			lcmiDoc=TB+TB+'{'+CR+;
					TB+TB+TB+'"campo": "numDoctoSiga", '+CR+;
					TB+TB+TB+'"etiqueta": "No.Documento Siga:", '+CR+;
					TB+TB+TB+'"valor": "'+ALLTRIM(numero)+'"  '+CR+;
				TB+'}'
			
			m.apendice=;
					TB+'"apendice": ['+CR+;
						TB+lcmiDoc+' '+CR+;
					TB+']'

			***** creando documento	
			m.documento=;
				TB+'"documento": {'+CR+;
					TB+TB+m.tipoDte+', '+CR+;
					TB+TB+m.ecodEstable+', '+CR+;
					TB+TB+m.ePuntoVenta+', '+CR+;
					m.etipocontingencia+;
					m.emotivocontingencia+;
					TB+TB+m.econdiPago+', '+CR+;
					TB+TB+m.docrelacionado+', '+CR+;
					TB+TB+m.receptor+', '+CR+;
					TB+TB+m.items+', '+CR+;
					TB+TB+m.pagos+', '+CR+;
					TB+TB+m.apendice+' '+CR+;
				TB+'}';

			
			m.StringJson=   '{'+CR+;
								m.documento+' '+CR+;
							'}'+CR

			oJson=m.StringJson
			lcmiJsonDTE=lcmiJsonDTE+" JSON GENERADO "+CHR(13)+m.StringJson
			pcBitacoraDTE=m.StringJson
		ELSE 
			lcOkErrorStatus='error'
			lcMensajeOkError='El Documento no es Una Nota de Crédito'
			
		ENDIF 
	ELSE
		lcOkErrorStatus='error'
		lcMensajeOkError='No se encontro el Documento'
		
	ENDIF 

	USE IN c_DTE_STD
	USE IN c_DTE_Vta
	USE IN c_DTE_TDo 
	USE IN c_DTE_SUC
	*USE IN c_MiDocDTE
	USE IN c_DTE_clipro
	USE IN c_DTE_InvPro
	USE IN c_DTE_VtaD
	
	IF !EMPTY(lcAliasDTEDoc)
		SELECT (lcAliasDTEDoc)
	ENDIF 
	IF lcOkErrorStatus='error'
		oJson='null'
	ENDIF 
	
	loRetornaRespuesta = CREATEOBJECT( 'Empty' )
	ADDPROPERTY(loRetornaRespuesta , 'Status', lcOkErrorStatus)
	ADDPROPERTY(loRetornaRespuesta , 'Mensaje', lcMensajeOkError)
	ADDPROPERTY(loRetornaRespuesta , 'DTE', oJson)
	
	IF lcOkErrorStatus='ok'
		GO TOP IN c_MiDocDTE
		lcArchivoJson=pcRutaJson+'\DTE-'+lcTipoDTE+'-'+ALLTRIM(c_MiDocDTE.codsuc)+ALLTRIM(c_MiDocDTE.CodPTV)+'-'+PADL(ALLTRIM(c_MiDocDTE.numero),15,"0")+'.json'
		StrToFile(oJson,lcArchivoJson)
	ENDIF 
	
	
	RETURN loRetornaRespuesta
	
ENDFUNC 




******************** JSON NOTA DE CREDITO
FUNCTION GenerarDTEVentasNDC_V1_sub(lnIdDocVta as Integer)
	*#Define CR		Chr(13)
	*#Define TB		"  "
	lcOkErrorStatus='ok'
	lcMensajeOkError='documento generado correctamente'
	pcBitacoraDTE=''
	
	lcJsonTmp=''
	lcAliasDTEDoc=ALIAS()
	USE pcSysDir+pcdb+"\cyvVentas" IN 0 share AGAIN ALIAS c_DTE_Vta
	USE pcSysDir+pcdb+"\cyvVentasdeta" IN 0 share AGAIN ALIAS c_DTE_VtaD
	USE pcSysDir+pcdb+"\sisTipoDoctos" IN 0 share AGAIN ALIAS c_DTE_STD
	CrearCursorStatus(19,'c_DTE_TDo','') 
	USE pcSysDir+pcdb+"\sisCata" IN 0 share AGAIN ALIAS c_DTE_SUC
	USE pcSysDir+pcdb+"\cyvclipro" IN 0 share AGAIN ALIAS c_DTE_clipro
	USE pcSysDir+pcdb+"\invProductos" IN 0 share AGAIN ALIAS c_DTE_InvPro
	USE pcSysDir+pcdb+"\sisDTE" IN 0 share AGAIN ALIAS c_SIS_DTE
	
	**** nota de credito
	SELECT a.*,aa.idproducto,aa.cantiunimed,aa.producto,aa.precioconivaunidad,aa.preciosiniva,;
			aa.preciosinivaunidad,aa.descuento,aa.fovial,aa.cotrans,aa.pfovial,aa.pcotrans,;
			aa.totalgravado,aa.totaliva,aa.poriva,aa.totalventasiniva,;
			c.tipd,PADL(SUBSTR(ALLTRIM(d.cod),1,4),4,"0") as CodSuc,;
			PADL(SUBSTR(ALLTRIM(e.cod),1,4),4,"0") as CodPTV,;
			d.tipoestablecimiento,d.correo as correosuc,d.telefono ,;
			solonumeros(f.celular)+SPACE(20) as telcel,;
			f.codgiro,f.giro as giroclipro,f.correoDTE as correo,g.codprod,g.tipoprod,g.escombustible,;
			NVL(h.cod,SPACE(10)) as deptocli, NVL(i.cod,SPACE(10)) as municli, ;
			d.cod AS codMatrizSuc,e.PtVenta as codMatrizPTV ;
		FROM c_DTE_Vta a ;
			inner JOIN c_DTE_VtaD aa ON a.iddocto=aa.iddocto AND aa.eliminado=0 AND INLIST(aa.tipoprod,1,2);
			inner JOIN c_DTE_STD b ON a.idtipodocto=b.idtipodocto ;
			inner JOIN c_DTE_TDo c ON b.tipoicv=c.id ;
			left join c_DTE_SUC d ON a.idsucursal=d.id and d.origen='SUC' ;
			left join c_DTE_SUC e ON a.idptovta=e.id and e.origen='PTV' ;
			left JOIN c_DTE_clipro f ON a.idclipro=f.idclipro ;			
			INNER JOIN c_DTE_InvPro g ON aa.idproducto=g.idproducto ;
			LEFT JOIN c_DTE_SUC H ON a.iddepto=H.id AND h.origen='DEP' ;
			LEFT JOIN c_DTE_SUC I ON a.idMuni=I.id AND i.origen='MUN' ;
		WHERE a.iddocto=lnIdDocVta AND b.tipoicv<>0 AND !INLIST(g.codprod,"NOTA") AND ((aa.idproducto<>idkit AND aa.llavekit<>0) OR aa.llavekit=0) ;
		INTO CURSOR c_MiDocDTE
	lnIdDoctoRelacion=iddoctorelacion

	**** documento relacionado
	IF lnIdDoctoRelacion<>0
		SELECT a.*,c.tipd,PADL(SUBSTR(ALLTRIM(d.cod),1,4),4,"0") as CodSuc,;
			PADL(SUBSTR(ALLTRIM(e.PtVenta),1,4),4,"0") as CodPTV,;
			d.tipoestablecimiento,d.correo as correosuc,d.telefono, ;
			j.codigoGeneracion as CodigoGeneracionDTE,TTOD(j.fechahora) as fechaDTE ;
		FROM c_DTE_Vta a ;
			inner JOIN c_DTE_STD b ON a.idtipodocto=b.idtipodocto ;
			inner JOIN c_DTE_TDo c ON b.tipoicv=c.id ;
			left join c_DTE_SUC d ON a.idsucursal=d.id and d.origen='SUC' ;
			left join c_DTE_SUC e ON a.idptovta=e.id and e.origen='PTV' ;
			LEFT JOIN c_SIS_DTE j ON a.iddocto=j.iddocto AND j.status=1 AND j.origen=a.origen ;
		WHERE a.iddocto=lnIdDoctoRelacion;
		INTO CURSOR c_MiDocDTERelacionado
		lcTipoDTER=ALLTRIM(ALLTRIM(tipd))
		lnDocRelacionado=RECCOUNT()
	ELSE
		lnDocRelacionado=0
		lcTipoDTER=''
	ENDIF 
	
	SELECT c_MiDocDTE

	
	lcTipoDTE=ALLTRIM(ALLTRIM(tipd))
	
	oJson = newobject('json')
	
	IF !EMPTY(NVL(lcTipoDTE,''))
		IF lcTipoDTE='05'		&&& es Nota de Credito		
			****** Documento
			m.tipoDte='"tipo_dte": "'+lcTipoDTE+'"'
			m.ecodEstable='"establecimiento": "'+ALLTRIM(codmatrizSuc)+'"'
			m.ePuntoVenta='"punto_venta": "'+ALLTRIM(codmatrizPTV)+'"'
			m.econdiPago='"condicion_pago": '+ALLTRIM(STR(condipago+1))+' '
			m.etipocontingencia=''
			m.emotivocontingencia=''
			
			IF retperdocto<>0
				m.eretperdocto=TB+TB+'"percibir_iva": true , '+CR
			ELSE
				m.eretperdocto=''
			ENDIF 

			IF pnTipoContinDTE=1		&&& tipo contingencia ministerio de hacienda error
				m.etipocontingencia=TB+TB+TB+'"tipo_contingencia": '+ALLTRIM(STR(pnTipoContinDTE))+', '+CR
			ENDIF 
			IF pnTipoContinDTE=5		&&& tipo contingencia ministerio de hacienda error
				m.etipocontingencia=TB+TB+TB+'"tipo_contingencia": '+ALLTRIM(STR(pnTipoContinDTE))+', '+CR
				m.emotivocontingencia=TB+TB+TB+'"motivo_contingencia": "'+ALLTRIM(pcContingenciaDTE)+'", '+CR
			ENDIF
			
			****** Documento Relacionado
			IF lnDocRelacionado<>0
				SELECT c_MiDocDTERelacionado

				m.drtipoDte='"tipo_documento": "'+lcTipoDTER+'"'
				m.drtipoGen='"tipo_generacion": '+IIF(EMPTY(NVL(CodigoGeneracionDTE,"")),'1','2')
				lcnumeroRela=IIF(EMPTY(NVL(CodigoGeneracionDTE,"")),codigoGeneracion,CodigoGeneracionDTE)
				m.drnumDocumento='"numero_documento": "'+ALLTRIM(lcnumeroRela)+'"'
				ldfechadte=IIF(EMPTY(NVL(fechaDTE,CTOD(" "))),fechadocto,fechaDTE)
				m.drfecEmi='"fecha_emision": "'+SUBSTR(_ConvertirToFechaHoraSQL(ldfechadte),1,10)+'"'

				m.docrelacionado=;
				TB+'"documentos_relacionados": ['+CR+;
					TB+TB+'{'+CR+;
					TB+TB+TB+m.drtipoDte+', '+CR+;
					TB+TB+TB+m.drtipoGen+', '+CR+;
					TB+TB+TB+m.drnumDocumento+', '+CR+;
					TB+TB+TB+m.drfecEmi+' '+CR+;
				TB+TB+'}'+;
				TB+']'
				
				SELECT c_MiDocDTE
			ELSE
				m.docrelacionado=;
				TB+'"documentos_relacionados": ['+CR+;
				TB+']'
				m.drnumDocumento='"numero_documento": ""'
			ENDIF 
			
			****** receptor
			lcNumDoc=SoloNumeros(IIF(EMPTY(NVL(nit,'')),ValidarDUI(NVL(dui,'')),NVL(nit,"")))
			lctipDoc=IIF(EMPTY(lcNumDoc),"null",IIF(LEN(lcNumdoc)>12,"36","13")) 
			lcCorreoClienteTmp=ValidarVariosCorreos(correo,1)
			lccorreocliente=IIF(EMPTY(NVL(lcCorreoClienteTmp,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmp)+'"')
			m.rcorreo='"correo": '+lccorreocliente+' '
			lcCorreoClienteTmpCC=ValidarVariosCorreos(correo,2)
			lccorreoclienteCC=IIF(EMPTY(NVL(lcCorreoClienteTmpCC,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmpCC)+'"')
			m.rcorreo_cc='"correos_cc": '+lccorreoclienteCC+' '
			
			IF lctipDoc="13" AND !EMPTY(lcNumDoc)		 &&&& poniendo gion al dui
				lcNumDoc=PADL(lcNumDoc,9,'0')
				lcNumDoc=SUBSTR(lcNumDoc,1,8)+'-'+SUBSTR(lcNumDoc,9,1)
				lcNumDoc='"'+ALLTRIM(lcNumDoc)+'"'
			ELSE
				IF EMPTY(lcNumDoc)
					lcNumDoc='null'
				ELSE
					lcNumDoc=' "'+lcNumDoc+'" '
				ENDIF 
			ENDIF 
			IF lctipDoc<>'null'
				lctipDoc='"'+lctipDoc+'"'
			ENDIF 

			lcDistritotmp=buscaCodigoDTE(ALLTRIM(municli),'213','c_Distri',ALLTRIM(deptocli))
			lccodDistrito=SUBSTR(lcDistritotmp,1,2)
			lcNomDistrito=ALLTRIM(SUBSTR(lcDistritotmp,AT(',',lcDistritotmp)+2,150))

			m.rnumDocumento='"numero_documento": '+lcNumDoc+' '
			m.rtipoDocumento='"tipo_documento": '+lctipDoc+' '
			m.rnrc='"nrc": '+IIF(EMPTY(NVL(nrc,"")),"null",'"'+SoloNumeros(ALLTRIM(nrc))+'"')+' '
			m.rnombre='"nombre": "'+UPPER(ALLTRIM(clipro))+'"'
			m.rcodActividad='"codigo_actividad": "'+IIF(EMPTY(NVL(codgiro,"")),"null",ALLTRIM(codgiro))+'"'
			m.rnombreComercial='"nombre_comercial": "'+UPPER(ALLTRIM(clipro))+'"'
				***** direccion receptor
				m.rdepartamento='"departamento": "'+ALLTRIM(deptocli)+'"'
				m.rmunicipio='"municipio": "'+ALLTRIM(lccodDistrito)+'"'
				m.rcomplemento='"complemento": "'+ALLTRIM(_EscaparJson(ALLTRIM(Direccion)+' '))+'"'
			m.rtelefono='"telefono": "'+ALLTRIM(solonumeros(telcel))+'"'
			
			
			m.receptor=;
				TB+'"receptor": {'+CR+;
					TB+TB+m.rnumDocumento+', '+CR+;
					TB+TB+m.rtipoDocumento+', '+CR+;
					TB+TB+m.rnrc+', '+CR+;
					TB+TB+m.rnombre+', '+CR+;
					TB+TB+m.rcodActividad+', '+CR+;
					TB+TB+m.rnombreComercial+', '+CR+;
					TB+TB+'"direccion": {'+CR+;
						TB+TB+TB+m.rdepartamento+', '+CR+;
						TB+TB+TB+m.rmunicipio+', '+CR+;
						TB+TB+TB+m.rcomplemento+CR+;
					TB+TB+'}, '+CR+;
					TB+TB+m.rtelefono+', '+CR+;
					TB+TB+m.rcorreo_cc+', '+CR+;
					TB+TB+m.rcorreo+' '+CR+;
				TB+'}'
			
			***** forma de pago
			IF condipago=1	&&& es contado
				m.pagos=;
				TB+'"pagos": null'
			ELSE
				m.pcodigo='"tipo": "01"'
				*m.pmontoPago='"monto": '+ALLTRIM(STR(totaldocto-ABS(retperdocto),12,8))+' '
				m.pmontoPago='"monto": '+ALLTRIM(STR(totaldocto,12,8))+' '
				m.pagos=;
				'"pagos": ['+CR+;
					TB+TB+TB+'{'+CR+;
						TB+TB+TB+TB+m.pcodigo+', '+CR+;
						TB+TB+TB+TB+m.pmontoPago+' '+CR+;
					TB+TB+TB+'}'+CR+;
				TB+TB+'] '
			ENDIF 
			
			
				
			 ****** detalle 
			m.detalledoc=''
			m.uniondetalle=''
			m.linea=0
			m.fila=''
			SCAN all
				m.tipVenta='"tipo_venta": '+IIF(tipoiva=0,'"3"',IIF(tipoiva=1,'"1"',IIF(tipoiva=2,'"2"','"4"')))
				m.cdtipoItem='"tipo": '+ALLTRIM(STR(tipoprod))+''
				m.cdcantidad='"cantidad": '+ALLTRIM(STR(cantiunimed,12,6))+''
				m.cduniMedida='"unidad_medida": '+IIF(esCombustible=1,'22','59')
				m.cdnumeroDocumento=m.drnumDocumento
				lndescusiniva=descuento/((poriva+100.00)/100)
				midescuento=lndescusiniva*cantiunimed
				m.cddescuento='"descuento": '+ALLTRIM(STR(midescuento,12,8))+''
				
				m.cddescripcion='"descripcion": "'+ALLTRIM(_sincomilliasoTildes(producto))+'"'
				m.cdprecioUni='"precio_unitario": '+ALLTRIM(STR(((totalventasiniva+midescuento)/IIF(cantiunimed=0,1,cantiunimed)),12,8))+''


				
				**** Item Tributo
				IF totaliva<>0
					m.cdcodiva='"codigo": "20"'
					m.cdmontoiva='"monto": '+ALLTRIM(STR(totaliva,12,8))+''
					m.cditemiva=TB+TB+'{'+CR+;
									TB+TB+TB+m.cdcodiva+', '+CR+;
									TB+TB+TB+m.cdmontoiva+' '+CR+;
									TB+TB+'}'
					IF cotrans<>0 OR fovial<>0
						m.cditemiva=m.cditemiva+', '+CR
					ENDIF 
				ELSE
					m.cditemiva=''
				ENDIF 
				
				IF esCombustible=1
					m.cditemcotrans=''
					m.cditemfovial=''
					IF cotrans<>0
						m.cdcodcotrans='"codigo": "C8"'
						m.cdmontocotrans='"monto": '+ALLTRIM(STR(cotrans,12,8))+''
						m.cdcantidadgravablecotrans='"cantidad_gravable": '+ALLTRIM(STR(cantiunimed,12,6))+''
						m.cditemcotrans=TB+TB+'{'+CR+;
										TB+TB+TB+m.cdcodcotrans+', '+CR+;
										TB+TB+TB+m.cdmontocotrans+', '+CR+;
										TB+TB+TB+m.cdcantidadgravablecotrans+' '+CR+;
										TB+TB+'}'
					ENDIF 
					IF fovial<>0
						m.cdcodfovial='"codigo": "D1"'
						m.cdmontofovial='"monto": '+ALLTRIM(STR(fovial,12,8))+''
						m.cdcantidadgravablefovial='"cantidad_gravable": '+ALLTRIM(STR(cantiunimed,12,6))+''
						m.cditemfovial=TB+TB+TB+'{'+CR+;
										TB+TB+TB+TB+m.cdcodfovial+', '+CR+;
										TB+TB+TB+TB+m.cdmontofovial+', '+CR+;
										TB+TB+TB+TB+m.cdcantidadgravablefovial+' '+CR+;
										TB+TB+TB+'}'
					ENDIF 
					*** uniendo tributos
					IF !EMPTY(m.cditemcotrans) AND !EMPTY(m.cditemfovial)
						m.itemtributo='"tributos": [ '+CR+;
										m.cditemiva+;
										m.cditemcotrans+', '+CR+;
										m.cditemfovial+' '+CR+;
										TB+TB+']'+CR
					ELSE
						IF !EMPTY(m.cditemcotrans)
							m.itemtributo='"tributos": [ '+CR+;
										m.cditemiva+;
										m.cditemcotrans+' '+CR+;
										TB+TB+']'+CR
						ENDIF 
						IF !EMPTY(m.cditemfovial)
							m.itemtributo='"tributos": [ '+CR+;
										m.cditemiva+;
										m.cditemfovial+' '+CR+;
										TB+TB+']'+CR
						ENDIF 
					ENDIF 
				ELSE
					IF totaliva<>0
						m.itemtributo='"tributos": [ '+CR+;
										m.cditemiva+' '+CR+;
										TB+TB+']'+CR
					ELSE 
						m.itemtributo='"tributos": null'
					ENDIF 
				ENDIF 
				
				
				m.fila=m.fila+m.uniondetalle+'{'+CR+;
					TB+TB+TB+m.tipVenta+', '+CR+;
					TB+TB+TB+m.cdtipoItem+', '+CR+;
					TB+TB+TB+m.cdcantidad+', '+CR+;
					TB+TB+TB+TB+m.cduniMedida+', '+CR+;
					TB+TB+TB+TB+m.cddescuento+', '+CR+;
					TB+TB+TB+TB+m.cdnumeroDocumento+', '+CR+;
					TB+TB+TB+m.cddescripcion+', '+CR+;
					TB+TB+TB+m.cdprecioUni+', '+CR+;
					TB+TB+TB+m.itemtributo+' '+CR+;
					TB+TB+'}'
				
				m.uniondetalle=', '+CR
				m.linea=m.linea+1
			ENDSCAN 
			GO TOP
			m.items=;
					TB+'"items": [ '+CR+;
						m.fila+' '+CR+;
					']'+CR

			lcmiDoc=TB+TB+'{'+CR+;
					TB+TB+TB+'"campo": "numDoctoSiga", '+CR+;
					TB+TB+TB+'"etiqueta": "No.Documento Siga:", '+CR+;
					TB+TB+TB+'"valor": "'+ALLTRIM(numero)+'"  '+CR+;
				TB+'}'
			
			m.apendice=;
					TB+'"apendice": ['+CR+;
						TB+lcmiDoc+' '+CR+;
					TB+']'



			***** creando documento	
			m.documento=;
				TB+'"documento": {'+CR+;
					TB+TB+m.tipoDte+', '+CR+;
					TB+TB+m.ecodEstable+', '+CR+;
					TB+TB+m.ePuntoVenta+', '+CR+;
					m.etipocontingencia+;
					m.emotivocontingencia+;
					m.eretperdocto+;
					TB+TB+m.econdiPago+', '+CR+;
					TB+TB+m.docrelacionado+', '+CR+;
					TB+TB+m.receptor+', '+CR+;
					TB+TB+m.items+', '+CR+;
					TB+TB+m.pagos+', '+CR+;
					TB+TB+m.apendice+' '+CR+;
				TB+'}';

			
			m.StringJson=   '{'+CR+;
								m.documento+' '+CR+;
							'}'+CR

			oJson=m.StringJson
		_cliptext=m.StringJson
		
			pcBitacoraDTE=m.StringJson
			
		ELSE 
			lcOkErrorStatus='error'
			lcMensajeOkError='El Documento no es Una Nota de Crédito'
			
		ENDIF 
	ELSE
		lcOkErrorStatus='error'
		lcMensajeOkError='No se encontro el Documento'
		
	ENDIF 

	USE IN c_DTE_STD
	USE IN c_DTE_Vta
	USE IN c_DTE_TDo 
	USE IN c_DTE_SUC
	*USE IN c_MiDocDTE
	USE IN c_DTE_clipro
	USE IN c_DTE_InvPro
	USE IN c_DTE_VtaD
	
	IF !EMPTY(lcAliasDTEDoc)
		SELECT (lcAliasDTEDoc)
	ENDIF 
	IF lcOkErrorStatus='error'
		oJson='null'
	ENDIF 
	
	loRetornaRespuesta = CREATEOBJECT( 'Empty' )
	ADDPROPERTY(loRetornaRespuesta , 'Status', lcOkErrorStatus)
	ADDPROPERTY(loRetornaRespuesta , 'Mensaje', lcMensajeOkError)
	ADDPROPERTY(loRetornaRespuesta , 'DTE', oJson)
	
	IF lcOkErrorStatus='ok'
		GO TOP IN c_MiDocDTE
		lcArchivoJson=pcRutaJson+'\DTE-'+lcTipoDTE+'-'+ALLTRIM(c_MiDocDTE.codsuc)+ALLTRIM(c_MiDocDTE.CodPTV)+'-'+PADL(ALLTRIM(c_MiDocDTE.numero),15,"0")+'.json'
		StrToFile(oJson,lcArchivoJson)
	ENDIF 
	
 	
	RETURN loRetornaRespuesta
	
ENDFUNC 




******************** JSON NOTA DE DEBITO
FUNCTION GenerarDTEVentasNDD_V1_sub(lnIdDocVta as Integer)
	*#Define CR		Chr(13)
	*#Define TB		"  "
	lcOkErrorStatus='ok'
	lcMensajeOkError='documento generado correctamente'
	pcBitacoraDTE=''
	
	lcJsonTmp=''
	lcAliasDTEDoc=ALIAS()
	USE pcSysDir+pcdb+"\cyvVentas" IN 0 share AGAIN ALIAS c_DTE_Vta
	USE pcSysDir+pcdb+"\cyvVentasdeta" IN 0 share AGAIN ALIAS c_DTE_VtaD
	USE pcSysDir+pcdb+"\sisTipoDoctos" IN 0 share AGAIN ALIAS c_DTE_STD
	CrearCursorStatus(19,'c_DTE_TDo','') 
	USE pcSysDir+pcdb+"\sisCata" IN 0 share AGAIN ALIAS c_DTE_SUC
	USE pcSysDir+pcdb+"\cyvclipro" IN 0 share AGAIN ALIAS c_DTE_clipro
	USE pcSysDir+pcdb+"\invProductos" IN 0 share AGAIN ALIAS c_DTE_InvPro
	USE pcSysDir+pcdb+"\sisDTE" IN 0 share AGAIN ALIAS c_SIS_DTE
	
	**** nota de DEBITO
	SELECT a.*,aa.idproducto,aa.cantiunimed,aa.producto,aa.precioconivaunidad,aa.preciosiniva,;
			aa.preciosinivaunidad,aa.descuento,aa.fovial,aa.cotrans,aa.pfovial,aa.pcotrans,;
			aa.totalgravado,aa.totaliva,aa.poriva,aa.totalventasiniva,;
			c.tipd,PADL(SUBSTR(ALLTRIM(d.cod),1,4),4,"0") as CodSuc,;
			PADL(SUBSTR(ALLTRIM(e.cod),1,4),4,"0") as CodPTV,;
			d.tipoestablecimiento,d.correo as correosuc,d.telefono ,;
			solonumeros(f.celular)+SPACE(20) as telcel,;
			f.codgiro,f.giro as giroclipro,f.correoDTE as correo,g.codprod,g.tipoprod,g.escombustible,;
			NVL(h.cod,SPACE(10)) as deptocli, NVL(i.cod,SPACE(10)) as municli, ;
			d.cod AS codMatrizSuc,e.PtVenta as codMatrizPTV ;
		FROM c_DTE_Vta a ;
			inner JOIN c_DTE_VtaD aa ON a.iddocto=aa.iddocto AND aa.eliminado=0 AND INLIST(aa.tipoprod,1,2);
			inner JOIN c_DTE_STD b ON a.idtipodocto=b.idtipodocto ;
			inner JOIN c_DTE_TDo c ON b.tipoicv=c.id ;
			left join c_DTE_SUC d ON a.idsucursal=d.id and d.origen='SUC' ;
			left join c_DTE_SUC e ON a.idptovta=e.id and e.origen='PTV' ;
			left JOIN c_DTE_clipro f ON a.idclipro=f.idclipro ;
			INNER JOIN c_DTE_InvPro g ON aa.idproducto=g.idproducto ;
			LEFT JOIN c_DTE_SUC H ON a.iddepto=H.id AND h.origen='DEP' ;
			LEFT JOIN c_DTE_SUC I ON a.idMuni=I.id AND i.origen='MUN' ;
		WHERE a.iddocto=lnIdDocVta AND b.tipoicv<>0 AND !INLIST(g.codprod,"NOTA") AND ((aa.idproducto<>idkit AND aa.llavekit<>0) OR aa.llavekit=0) ;
		INTO CURSOR c_MiDocDTE
	lnIdDoctoRelacion=iddoctorelacion
	
	**** documento relacionado
	IF lnIdDoctoRelacion<>0
		SELECT a.*,c.tipd,PADL(SUBSTR(ALLTRIM(d.cod),1,4),4,"0") as CodSuc,;
			PADL(SUBSTR(ALLTRIM(e.PtVenta),1,4),4,"0") as CodPTV,;
			d.tipoestablecimiento,d.correo as correosuc,d.telefono, ;
			j.codigoGeneracion as CodigoGeneracionDTE,TTOD(j.fechahora) as fechaDTE ;
		FROM c_DTE_Vta a ;
			inner JOIN c_DTE_STD b ON a.idtipodocto=b.idtipodocto ;
			inner JOIN c_DTE_TDo c ON b.tipoicv=c.id ;
			left join c_DTE_SUC d ON a.idsucursal=d.id and d.origen='SUC' ;
			left join c_DTE_SUC e ON a.idptovta=e.id and e.origen='PTV' ;
			LEFT JOIN c_SIS_DTE j ON a.iddocto=j.iddocto AND j.status=1 AND j.origen=a.origen ;
		WHERE a.iddocto=lnIdDoctoRelacion;
		INTO CURSOR c_MiDocDTERelacionado
		lcTipoDTER=ALLTRIM(ALLTRIM(tipd))
		lnDocRelacionado=RECCOUNT()
	ELSE
		lnDocRelacionado=0
		lcTipoDTER=''
	ENDIF 
	
	SELECT c_MiDocDTE

	
	lcTipoDTE=ALLTRIM(ALLTRIM(tipd))
	
	oJson = newobject('json')
	
	IF !EMPTY(NVL(lcTipoDTE,''))
		IF lcTipoDTE='06'		&&& es Nota de DEBITO		
			****** Documento
			m.tipoDte='"tipo_dte": "'+lcTipoDTE+'"'
			m.ecodEstable='"establecimiento": "'+ALLTRIM(codmatrizSuc)+'"'
			m.ePuntoVenta='"punto_venta": "'+ALLTRIM(codmatrizPTV)+'"'
			m.econdiPago='"condicion_pago": '+ALLTRIM(STR(condipago+1))+' '
			m.etipocontingencia=''
			m.emotivocontingencia=''
			IF retperdocto<>0
				m.eretperdocto=TB+TB+'"percibir_iva": true , '+CR
			ELSE
				m.eretperdocto=''
			ENDIF 

			IF pnTipoContinDTE=1		&&& tipo contingencia ministerio de hacienda error
				m.etipocontingencia=TB+TB+TB+'"tipo_contingencia": '+ALLTRIM(STR(pnTipoContinDTE))+', '+CR
			ENDIF 
			IF pnTipoContinDTE=5		&&& tipo contingencia ministerio de hacienda error
				m.etipocontingencia=TB+TB+TB+'"tipo_contingencia": '+ALLTRIM(STR(pnTipoContinDTE))+', '+CR
				m.emotivocontingencia=TB+TB+TB+'"motivo_contingencia": "'+ALLTRIM(pcContingenciaDTE)+'", '+CR
			ENDIF 
			
			****** Documento Relacionado
			IF lnDocRelacionado<>0
				SELECT c_MiDocDTERelacionado

				m.drtipoDte='"tipo_documento": "'+lcTipoDTER+'"'
				m.drtipoGen='"tipo_generacion": '+IIF(EMPTY(NVL(CodigoGeneracionDTE,"")),'1','2')
				lcnumeroRela=IIF(EMPTY(NVL(CodigoGeneracionDTE,"")),codigoGeneracion,CodigoGeneracionDTE)
				m.drnumDocumento='"numero_documento": "'+ALLTRIM(lcnumeroRela)+'"'
				ldfechadte=IIF(EMPTY(NVL(fechaDTE,CTOD(" "))),fechadocto,fechaDTE)
				m.drfecEmi='"fecha_emision": "'+SUBSTR(_ConvertirToFechaHoraSQL(ldfechadte),1,10)+'"'

				m.docrelacionado=;
				TB+'"documentos_relacionados": ['+CR+;
					TB+TB+'{'+CR+;
					TB+TB+TB+m.drtipoDte+', '+CR+;
					TB+TB+TB+m.drtipoGen+', '+CR+;
					TB+TB+TB+m.drnumDocumento+', '+CR+;
					TB+TB+TB+m.drfecEmi+' '+CR+;
				TB+TB+'}'+;
				TB+']'
				
				SELECT c_MiDocDTE
			ELSE
				m.docrelacionado=;
				TB+'"documentos_relacionados": ['+CR+;
				TB+']'
				m.drnumDocumento='"numero_documento": ""'
			ENDIF 
			
			****** receptor
			lcNumDoc=SoloNumeros(IIF(EMPTY(NVL(nit,'')),ValidarDUI(NVL(dui,'')),NVL(nit,"")))
			lctipDoc=IIF(EMPTY(lcNumDoc),"null",IIF(LEN(lcNumdoc)>12,"36","13")) 
			lcCorreoClienteTmp=ValidarVariosCorreos(correo,1)
			lccorreocliente=IIF(EMPTY(NVL(lcCorreoClienteTmp,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmp)+'"')
			m.rcorreo='"correo": '+lccorreocliente+' '
			lcCorreoClienteTmpCC=ValidarVariosCorreos(correo,2)
			lccorreoclienteCC=IIF(EMPTY(NVL(lcCorreoClienteTmpCC,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmpCC)+'"')
			m.rcorreo_cc='"correos_cc": '+lccorreoclienteCC+' '
			
			
			IF lctipDoc="13" AND !EMPTY(lcNumDoc)		 &&&& poniendo gion al dui
				lcNumDoc=PADL(lcNumDoc,9,'0')
				lcNumDoc=SUBSTR(lcNumDoc,1,8)+'-'+SUBSTR(lcNumDoc,9,1)
				lcNumDoc='"'+ALLTRIM(lcNumDoc)+'"'
			ELSE
				IF EMPTY(lcNumDoc)
					lcNumDoc='null'
				ELSE
					lcNumDoc='"'+lcNumDoc+'"'
				ENDIF 
			ENDIF 
			IF lctipDoc<>'null'
				lctipDoc='"'+lctipDoc+'"'
			ENDIF 
			

			lcDistritotmp=buscaCodigoDTE(ALLTRIM(municli),'213','c_Distri',ALLTRIM(deptocli))
			lccodDistrito=SUBSTR(lcDistritotmp,1,2)
			lcNomDistrito=ALLTRIM(SUBSTR(lcDistritotmp,AT(',',lcDistritotmp)+2,150))
			
			m.rnumDocumento='"numero_documento": '+lcNumDoc+' '
			m.rtipoDocumento='"tipo_documento": '+lctipDoc+' '
			m.rnrc='"nrc": '+IIF(EMPTY(NVL(nrc,"")),"null",'"'+SoloNumeros(ALLTRIM(nrc)))
			m.rnombre='"nombre": "'+UPPER(ALLTRIM(clipro))+'"'
			m.rcodActividad='"codigo_actividad": "'+IIF(EMPTY(NVL(codgiro,"")),"null",ALLTRIM(codgiro))+'"'
			m.rnombreComercial='"nombre_comercial": "'+UPPER(ALLTRIM(clipro))+'"'
				***** direccion receptor
				m.rdepartamento='"departamento": "'+ALLTRIM(deptocli)+'"'
				m.rmunicipio='"municipio": "'+ALLTRIM(lccodDistrito)+'"'
				m.rcomplemento='"complemento": "'+ALLTRIM(_EscaparJson(ALLTRIM(Direccion)+', '+lcNomDistrito))+'"'
			m.rtelefono='"telefono": "'+ALLTRIM(solonumeros(telcel))+'"'
			
			m.receptor=;
				TB+'"receptor": {'+CR+;
					TB+TB+m.rnumDocumento+', '+CR+;
					TB+TB+m.rtipoDocumento+', '+CR+;
					TB+TB+m.rnrc+', '+CR+;
					TB+TB+m.rnombre+', '+CR+;
					TB+TB+m.rcodActividad+', '+CR+;
					TB+TB+m.rnombreComercial+', '+CR+;
					TB+TB+'"direccion": {'+CR+;
						TB+TB+TB+m.rdepartamento+', '+CR+;
						TB+TB+TB+m.rmunicipio+', '+CR+;
						TB+TB+TB+m.rcomplemento+CR+;
					TB+TB+'}, '+CR+;
					TB+TB+m.rtelefono+', '+CR+;
					TB+TB+m.rcorreo_cc+', '+CR+;
					TB+TB+m.rcorreo+' '+CR+;
				TB+'}'
			
			
			***** forma de pago
			IF condipago=1	&&& es credito
				m.pagos=;
				TB+'"pagos": null'
			ELSE
				m.pcodigo='"tipo": "01"'
				*m.pmontoPago='"monto": '+ALLTRIM(STR(totaldocto-ABS(retperdocto),12,8))+' '
				m.pmontoPago='"monto": '+ALLTRIM(STR(totaldocto,12,8))+' '
				m.pagos=;
				'"pagos": ['+CR+;
					TB+TB+TB+'{'+CR+;
						TB+TB+TB+TB+m.pcodigo+', '+CR+;
						TB+TB+TB+TB+m.pmontoPago+' '+CR+;
					TB+TB+TB+'}'+CR+;
				TB+TB+'] '
			ENDIF 
			
			
				
			 ****** detalle 
			m.detalledoc=''
			m.uniondetalle=''
			m.linea=0
			m.fila=''
			SCAN all
				m.tipVenta='"tipo_venta": '+IIF(tipoiva=0,'"3"',IIF(tipoiva=1,'"1"',IIF(tipoiva=2,'"2"','"4"')))
				m.cdtipoItem='"tipo": '+ALLTRIM(STR(tipoprod))+''
				m.cdcantidad='"cantidad": '+ALLTRIM(STR(cantiunimed,12,6))+''
				m.cduniMedida='"unidad_medida": '+IIF(esCombustible=1,'22','59')
				m.cdnumeroDocumento=m.drnumDocumento
				lndescusiniva=descuento/((poriva+100.00)/100)
				midescuento=lndescusiniva*cantiunimed
				m.cddescuento='"descuento": '+ALLTRIM(STR(midescuento,12,8))+''
				m.cddescripcion='"descripcion": "'+ALLTRIM(_sincomilliasoTildes(producto))+'"'
				m.cdprecioUni='"precio_unitario": '+ALLTRIM(STR(((totalventasiniva+midescuento)/IIF(cantiunimed=0,1,cantiunimed)),12,8))+''

	
				**** Item Tributo
				IF totaliva<>0
					m.cdcodiva='"codigo": "20"'
					m.cdmontoiva='"monto": '+ALLTRIM(STR(totaliva,12,8))+''
					m.cditemiva=TB+TB+'{'+CR+;
									TB+TB+TB+m.cdcodiva+', '+CR+;
									TB+TB+TB+m.cdmontoiva+' '+CR+;
									TB+TB+'}'
					IF cotrans<>0 OR fovial<>0
						m.cditemiva=m.cditemiva+', '+CR
					ENDIF 
				ELSE
					m.cditemiva=''
				ENDIF 
				
				IF esCombustible=1
					m.cditemcotrans=''
					m.cditemfovial=''
					IF cotrans<>0
						m.cdcodcotrans='"codigo": "C8"'
						m.cdmontocotrans='"monto": '+ALLTRIM(STR(cotrans,12,8))+''
						m.cdcantidadgravablecotrans='"cantidad_gravable": '+ALLTRIM(STR(cantiunimed,12,6))+''
						m.cditemcotrans=TB+TB+'{'+CR+;
										TB+TB+TB+m.cdcodcotrans+', '+CR+;
										TB+TB+TB+m.cdmontocotrans+', '+CR+;
										TB+TB+TB+m.cdcantidadgravablecotrans+' '+CR+;
										TB+TB+'}'
					ENDIF 
					IF fovial<>0
						m.cdcodfovial='"codigo": "D1"'
						m.cdmontofovial='"monto": '+ALLTRIM(STR(fovial,12,8))+''
						m.cdcantidadgravablefovial='"cantidad_gravable": '+ALLTRIM(STR(cantiunimed,12,6))+''
						m.cditemfovial=TB+TB+TB+'{'+CR+;
										TB+TB+TB+TB+m.cdcodfovial+', '+CR+;
										TB+TB+TB+TB+m.cdmontofovial+', '+CR+;
										TB+TB+TB+TB+m.cdcantidadgravablefovial+' '+CR+;
										TB+TB+TB+'}'
					ENDIF 
					*** uniendo tributos
					IF !EMPTY(m.cditemcotrans) AND !EMPTY(m.cditemfovial)
						m.itemtributo='"tributos": [ '+CR+;
										m.cditemiva+;
										m.cditemcotrans+', '+CR+;
										m.cditemfovial+' '+CR+;
										TB+TB+']'+CR
					ELSE
						IF !EMPTY(m.cditemcotrans)
							m.itemtributo='"tributos": [ '+CR+;
										m.cditemiva+;
										m.cditemcotrans+' '+CR+;
										TB+TB+']'+CR
						ENDIF 
						IF !EMPTY(m.cditemfovial)
							m.itemtributo='"tributos": [ '+CR+;
										m.cditemiva+;
										m.cditemfovial+' '+CR+;
										TB+TB+']'+CR
						ENDIF 
					ENDIF 
				ELSE
					IF totaliva<>0
						m.itemtributo='"tributos": [ '+CR+;
										m.cditemiva+' '+CR+;
										TB+TB+']'+CR
					ELSE 
						m.itemtributo='"tributos": null'
					ENDIF 
				ENDIF 
				
				
				m.fila=m.fila+m.uniondetalle+'{'+CR+;
					TB+TB+TB+m.tipVenta+', '+CR+;
					TB+TB+TB+m.cdtipoItem+', '+CR+;
					TB+TB+TB+m.cdcantidad+', '+CR+;
					TB+TB+TB+TB+m.cduniMedida+', '+CR+;
					TB+TB+TB+TB+m.cdnumeroDocumento+', '+CR+;
					TB+TB+TB+m.cddescripcion+', '+CR+;
					TB+TB+TB+m.cdprecioUni+', '+CR+;
					TB+TB+TB+m.itemtributo+' '+CR+;
					TB+TB+'}'
				
				m.uniondetalle=', '+CR
				m.linea=m.linea+1
			ENDSCAN 
			GO TOP
			
			m.items=;
					TB+'"items": [ '+CR+;
						m.fila+' '+CR+;
					']'+CR

			lcmiDoc=TB+TB+'{'+CR+;
					TB+TB+TB+'"campo": "numDoctoSiga", '+CR+;
					TB+TB+TB+'"etiqueta": "No.Documento Siga:", '+CR+;
					TB+TB+TB+'"valor": "'+ALLTRIM(numero)+'"  '+CR+;
				TB+'}'
			
			m.apendice=;
					TB+'"apendice": ['+CR+;
						TB+lcmiDoc+' '+CR+;
					TB+']'

			***** creando documento	
			m.documento=;
				TB+'"documento": {'+CR+;
					TB+TB+m.tipoDte+', '+CR+;
					TB+TB+m.ecodEstable+', '+CR+;
					TB+TB+m.ePuntoVenta+', '+CR+;
					m.etipocontingencia+;
					m.emotivocontingencia+;
					m.eretperdocto+;
					TB+TB+m.econdiPago+', '+CR+;
					TB+TB+m.docrelacionado+', '+CR+;
					TB+TB+m.receptor+', '+CR+;
					TB+TB+m.items+', '+CR+;
					TB+TB+m.pagos+', '+CR+;
					TB+TB+m.apendice+' '+CR+;
				TB+'}';

			
			m.StringJson=   '{'+CR+;
								m.documento+' '+CR+;
							'}'+CR

			oJson=m.StringJson
			pcBitacoraDTE=m.StringJson
			
		ELSE 
			lcOkErrorStatus='error'
			lcMensajeOkError='El Documento no es Una Nota de Crédito'
			
		ENDIF 
	ELSE
		lcOkErrorStatus='error'
		lcMensajeOkError='No se encontro el Documento'
		
	ENDIF 

	USE IN c_DTE_STD
	USE IN c_DTE_Vta
	USE IN c_DTE_TDo 
	USE IN c_DTE_SUC
	*USE IN c_MiDocDTE
	USE IN c_DTE_clipro
	USE IN c_DTE_InvPro
	USE IN c_DTE_VtaD
	
	IF !EMPTY(lcAliasDTEDoc)
		SELECT (lcAliasDTEDoc)
	ENDIF 
	IF lcOkErrorStatus='error'
		oJson='null'
	ENDIF 
	
	loRetornaRespuesta = CREATEOBJECT( 'Empty' )
	ADDPROPERTY(loRetornaRespuesta , 'Status', lcOkErrorStatus)
	ADDPROPERTY(loRetornaRespuesta , 'Mensaje', lcMensajeOkError)
	ADDPROPERTY(loRetornaRespuesta , 'DTE', oJson)
	
	IF lcOkErrorStatus='ok'
		GO TOP IN c_MiDocDTE
		lcArchivoJson=pcRutaJson+'\DTE-'+lcTipoDTE+'-'+ALLTRIM(c_MiDocDTE.codsuc)+ALLTRIM(c_MiDocDTE.CodPTV)+'-'+PADL(ALLTRIM(c_MiDocDTE.numero),15,"0")+'.json'
		StrToFile(oJson,lcArchivoJson)
	ENDIF 
	
	
	RETURN loRetornaRespuesta
	
ENDFUNC 






******************** JSON COMPROBANTE DE RETENCION
FUNCTION GenerarDTEComprasCRET_V1_sub(lnIdDocVta as Integer)
	*#Define CR		Chr(13)
	*#Define TB		"  "
	lcOkErrorStatus='ok'
	lcMensajeOkError='documento generado correctamente'
	pcBitacoraDTE=''
	
	lcJsonTmp=''
	lcAliasDTEDoc=ALIAS()
	USE pcSysDir+pcdb+"\cyvCompras" IN 0 share AGAIN ALIAS c_DTE_Vta
	USE pcSysDir+pcdb+"\cyvComprasdeta" IN 0 share AGAIN ALIAS c_DTE_VtaD
	USE pcSysDir+pcdb+"\sisTipoDoctos" IN 0 share AGAIN ALIAS c_DTE_STD
	CrearCursorStatus(18,'c_DTE_TDo','') 
	USE pcSysDir+pcdb+"\sisCata" IN 0 share AGAIN ALIAS c_DTE_SUC
	USE pcSysDir+pcdb+"\cyvclipro" IN 0 share AGAIN ALIAS c_DTE_clipro
	USE pcSysDir+pcdb+"\invProductos" IN 0 share AGAIN ALIAS c_DTE_InvPro
	USE pcSysDir+pcdb+"\sisDTE" IN 0 share AGAIN ALIAS c_SIS_DTE
	
	**** Comprobante de Retencion
	SELECT a.*,aa.idproducto,aa.cantiunimed,aa.totalnosujeto,aa.producto,;
			c.tipd,PADL(SUBSTR(ALLTRIM(d.cod),1,4),4,"0") as CodSuc,;
			d.tipoestablecimiento,d.correo as correosuc,d.telefono ,;
			SUBSTR(solonumeros(NVL(IIF(EMPTY(f.celular),f.telefono,f.celular),SPACE(20))),1,8) as telcel,;
			f.codgiro,f.giro as giroclipro,f.correoDTE as correo,g.codprod,g.tipoprod,g.escombustible , ;
			j.codigoGeneracion as CodigoGeneracionDTE,TTOD(j.fechahora) as fechaDTE,b.tipoicv,;
			NVL(h.cod,SPACE(10)) as deptocli, NVL(i.cod,SPACE(10)) as municli, ;
			d.cod AS codMatrizSuc,'P001   ' as codMatrizPTV ;
		FROM c_DTE_Vta a ;
			inner JOIN c_DTE_VtaD aa ON a.iddocto=aa.iddocto AND NVL(aa.eliminado,0)=0 AND INLIST(aa.tipoprod,1,2,3);
			inner JOIN c_DTE_STD b ON a.idtipodocto=b.idtipodocto ;
			left JOIN c_DTE_TDo c ON b.tipoicv=c.id ;
			left join c_DTE_SUC d ON a.idsucursal=d.id and d.origen='SUC' ;
			inner JOIN c_DTE_clipro f ON a.idclipro=f.idclipro ;
			inner JOIN c_DTE_InvPro g ON aa.idproducto=g.idproducto ;
			LEFT JOIN c_DTE_SUC H ON a.iddepto=H.id AND h.origen='DEP' ;
			LEFT JOIN c_DTE_SUC I ON a.idMuni=I.id AND i.origen='MUN' ;
			LEFT JOIN c_SIS_DTE j ON a.iddocto=j.iddocto AND j.status=1 AND j.origen=a.origen ;
		WHERE a.iddocto=lnIdDocVta ;
		INTO CURSOR c_MiDocDTE
	SELECT c_MiDocDTE

	
	lcTipoDTE=ALLTRIM(ALLTRIM(tipd))
	IF EMPTY(lcTipoDTE) AND  tipoicv=9	&&&& es factura 
		lcTipoDTE='01'
	ENDIF  
	oJson = newobject('json')
	
	IF !EMPTY(NVL(lcTipoDTE,''))
		IF retperdocto<>0		&&& es Comprobante de Retencion	
			****** Documento
			m.tipoDte='"tipo_dte": "07"'
			m.ecodEstable='"establecimiento": "'+ALLTRIM(codmatrizSuc)+'"'
			m.ePuntoVenta='"punto_venta": "'+ALLTRIM(codmatrizPTV)+'"'
			****** receptor
			lcNumDoc=IIF(EMPTY(NVL(nit,'')),ValidarDUI(NVL(dui,'')),SoloNumeros(NVL(nit,"")))
			lctipDoc=IIF(EMPTY(lcNumDoc),"null",IIF(LEN(lcNumdoc)>12,"36","13")) 
			lcCorreoClienteTmp=ValidarVariosCorreos(correo,1)
			lccorreocliente=IIF(EMPTY(NVL(lcCorreoClienteTmp,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmp)+'"')
			m.rcorreo='"correo": '+lccorreocliente+' '
			lcCorreoClienteTmpCC=ValidarVariosCorreos(correo,2)
			lccorreoclienteCC=IIF(EMPTY(NVL(lcCorreoClienteTmpCC,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmpCC)+'"')
			m.rcorreo_cc='"correos_cc": '+lccorreoclienteCC+' '
			
			
			lcNumDoc2=lcNumDoc
			m.rnumDocumento='"numero_documento": "'+lcNumDoc2+'"'
			m.rtipoDocumento='"tipo_documento": "'+lctipDoc+'"'
			m.rnrc='"nrc": '+IIF(EMPTY(NVL(nrc,"")),"null",'"'+SoloNumeros(ALLTRIM(nrc))+'"')+' '
			m.rnombre='"nombre": "'+UPPER(ALLTRIM(clipro))+'"'
			m.rcodActividad='"codigo_actividad": "'+IIF(EMPTY(NVL(codgiro,"")),"null",ALLTRIM(codgiro))+'"'
				***** direccion 
				m.rdepartamento='"departamento": "'+pcCodDepartamento+'"'
				m.rmunicipio='"municipio": "'+pcCodMunicipio+'"'
				m.rcomplemento='"complemento": "'+ALLTRIM(_EscaparJson(Direccion))+'"'
			
			m.drtipoDte='"tipo_documento": "'+lcTipoDTE+'"'
			m.drtipoGen='"tipo_generacion": '+IIF(EMPTY(NVL(CodigoGeneracionDTE,"")),'1','2')
*			m.drnumDocumento='"numero_documento": "'+ALLTRIM(numerocr)+'"'
			m.drnumDocumento='"numero_documento": "'+ALLTRIM(numero)+'"'
			m.drfecEmi='"fecha_emision": "'+SUBSTR(_ConvertirToFechaHoraSQL(IIF(EMPTY(fechaCR),fechadocto,fechacr)),1,10)+'"'
			m.drmonto='"monto": '+ALLTRIM(STR(gravadodoctoconretper,12,8))+''
			m.drcodigoretencion='"codigo_retencion":  "22"'

*	TB+'"cuerpoDocumento": {'+CR+;
			TB+TB+']'+CR+
			
			m.items=;
				TB+'"items": ['+CR+;
				TB+TB+'{'+CR+;
				TB+TB+TB+TB+m.drtipoDte+', '+CR+;
				TB+TB+TB+TB+m.drtipoGen+', '+CR+;
				TB+TB+TB+TB+m.drnumDocumento+', '+CR+;
				TB+TB+TB+TB+m.drfecEmi+', '+CR+;
				TB+TB+TB+TB+m.drmonto+', '+CR+;
				TB+TB+TB+TB+m.drcodigoretencion+' '+CR+;
				TB+TB+'} '+CR+;
				TB+'] '+CR

			
			****** receptor
			lcNumDoc3=IIF(EMPTY(NVL(dui,'')),SoloNumeros(NVL(nit,'')),ValidarDUI(NVL(dui,'')))
			lctipDoc=IIF(EMPTY(lcNumDoc),"null",IIF(LEN(lcNumdoc)>12,"36","13")) 
			lccorreocliente=IIF(EMPTY(NVL(correo,'')),"null",ALLTRIM(correo))
			
			lcDistritotmp=buscaCodigoDTE(ALLTRIM(municli),'213','c_Distri',ALLTRIM(deptocli))
			lccodDistrito=SUBSTR(lcDistritotmp,1,2)
			lcNomDistrito=ALLTRIM(SUBSTR(lcDistritotmp,AT(',',lcDistritotmp)+2,150))

			m.rnumDocumento='"numero_documento": "'+lcNumDoc3+'"'
			m.rtipoDocumento='"tipo_documento": "'+lctipDoc+'"'
			m.rnrc='"nrc": '+IIF(EMPTY(NVL(nrc,"")),"null",'"'+SoloNumeros(ALLTRIM(nrc))+'"')+' '
			m.rnombre='"nombre": "'+UPPER(ALLTRIM(clipro))+'"'
			m.rcodActividad='"codigo_actividad": "'+IIF(EMPTY(NVL(codgiro,"")),"null",ALLTRIM(codgiro))+'"'
				***** direccion receptor
				m.rdepartamento='"departamento": "'+ALLTRIM(deptocli)+'"'
				m.rmunicipio='"municipio": "'+ALLTRIM(lccodDistrito)+'"'
				m.rcomplemento='"complemento": "'+ALLTRIM(_EscaparJson(ALLTRIM(Direccion)+', '+lcNomDistrito))+'"'
			
			m.receptor=;
				TB+'"receptor": {'+CR+;
					TB+TB+m.rnumDocumento+', '+CR+;
					TB+TB+m.rtipoDocumento+', '+CR+;
					TB+TB+m.rnrc+', '+CR+;
					TB+TB+m.rnombre+', '+CR+;
					TB+TB+m.rcodActividad+', '+CR+;
					TB+TB+'"direccion": {'+CR+;
						TB+TB+TB+m.rdepartamento+', '+CR+;
						TB+TB+TB+m.rmunicipio+', '+CR+;
						TB+TB+TB+m.rcomplemento+CR+;
					TB+TB+'}, '+CR+;
					TB+TB+m.rcorreo_cc+', '+CR+;
					TB+TB+m.rcorreo+' '+CR+;
				TB+'}'
				

			***** creando documento	
			m.documento=;
				TB+'"documento": {'+CR+;
					TB+TB+m.tipoDte+', '+CR+;
					TB+TB+m.ecodEstable+', '+CR+;
					TB+TB+m.ePuntoVenta+', '+CR+;
					TB+TB+m.receptor+', '+CR+;
					TB+TB+m.items+' '+CR+;
				TB+'}'
			
			m.StringJson=   '{'+CR+;
								m.documento+' '+CR+;
							'}'+CR

			oJson=m.StringJson
			pcBitacoraDTE=m.StringJson
		ELSE 
			lcOkErrorStatus='error'
			lcMensajeOkError='El Documento no es un Comprobante de Retencion '
			
		ENDIF 
	ELSE
		lcOkErrorStatus='error'
		lcMensajeOkError='No se encontro el Documento'
		
	ENDIF 

	USE IN c_DTE_STD
	USE IN c_DTE_Vta
	USE IN c_DTE_TDo 
	USE IN c_DTE_SUC
	*USE IN c_MiDocDTE
	USE IN c_DTE_clipro
	USE IN c_DTE_InvPro
	USE IN c_DTE_VtaD
	USE IN c_SIS_DTE
	
	IF !EMPTY(lcAliasDTEDoc)
		SELECT (lcAliasDTEDoc)
	ENDIF 
	IF lcOkErrorStatus='error'
		oJson='null'
	ENDIF 
	
	loRetornaRespuesta = CREATEOBJECT( 'Empty' )
	ADDPROPERTY(loRetornaRespuesta , 'Status', lcOkErrorStatus)
	ADDPROPERTY(loRetornaRespuesta , 'Mensaje', lcMensajeOkError)
	ADDPROPERTY(loRetornaRespuesta , 'DTE', oJson)
	
	IF lcOkErrorStatus='ok'
		GO TOP IN c_MiDocDTE
		lcArchivoJson=pcRutaJson+'\DTE-'+lcTipoDTE+'-'+ALLTRIM(c_MiDocDTE.codsuc)+'-0P01-'+PADL(ALLTRIM(c_MiDocDTE.numerocr),15,"0")+'.json'
		StrToFile(oJson,lcArchivoJson)
	ENDIF 
	
	RETURN loRetornaRespuesta
	
ENDFUNC 





******************** JSON sujeto excluido
FUNCTION GenerarDTEComprasNSJ_V1_sub(lnIdDocVta as Integer)
	*#Define CR		Chr(13)
	*#Define TB		"  "
	lcOkErrorStatus='ok'
	lcMensajeOkError='documento generado correctamente'
	pcBitacoraDTE=''
	
	lcJsonTmp=''
	lcAliasDTEDoc=ALIAS()
	USE pcSysDir+pcdb+"\cyvCompras" IN 0 share AGAIN ALIAS c_DTE_Vta
	USE pcSysDir+pcdb+"\cyvComprasdeta" IN 0 share AGAIN ALIAS c_DTE_VtaD
	USE pcSysDir+pcdb+"\sisTipoDoctos" IN 0 share AGAIN ALIAS c_DTE_STD
	CrearCursorStatus(18,'c_DTE_TDo','') 
	USE pcSysDir+pcdb+"\sisCata" IN 0 share AGAIN ALIAS c_DTE_SUC
	USE pcSysDir+pcdb+"\cyvclipro" IN 0 share AGAIN ALIAS c_DTE_clipro
	USE pcSysDir+pcdb+"\invProductos" IN 0 share AGAIN ALIAS c_DTE_InvPro
	USE pcSysDir+pcdb+"\sisDTE" IN 0 share AGAIN ALIAS c_SIS_DTE
	
	SELECT a.*,aa.idproducto,aa.cantiunimed,aa.producto,aa.totalnosujeto,;
			aa.descuento,aa.fovial,aa.cotrans,aa.pfovial,aa.pcotrans,;
			aa.totalgravado,aa.totaliva,aa.poriva,;
			c.tipd,PADL(SUBSTR(ALLTRIM(d.cod),1,4),4,"0") as CodSuc,;
			d.tipoestablecimiento,d.correo as correosuc,d.telefono ,;
			solonumeros(f.celular)+SPACE(20) as telcel,;
			f.codgiro,f.giro as giroclipro,f.correoDTE as correo,g.codprod,g.tipoprod,g.escombustible, ;
			NVL(h.cod,SPACE(10)) as deptocli, NVL(i.cod,SPACE(10)) as municli, ;
			d.cod AS codMatrizSuc,'P001   ' as codMatrizPTV ;
		FROM c_DTE_Vta a ;
			inner JOIN c_DTE_VtaD aa ON a.iddocto=aa.iddocto AND NVL(aa.eliminado,0)=0 AND INLIST(aa.tipoprod,1,2,3);
			inner JOIN c_DTE_STD b ON a.idtipodocto=b.idtipodocto ;
			left JOIN c_DTE_TDo c ON b.tipoicv=c.id ;
			left join c_DTE_SUC d ON a.idsucursal=d.id and d.origen='SUC' ;
			inner JOIN c_DTE_clipro f ON a.idclipro=f.idclipro ;
			inner JOIN c_DTE_InvPro g ON aa.idproducto=g.idproducto ;
			LEFT JOIN c_DTE_SUC H ON a.iddepto=H.id AND h.origen='DEP' ;
			LEFT JOIN c_DTE_SUC I ON a.idMuni=I.id AND i.origen='MUN' ;
		WHERE a.iddocto=lnIdDocVta AND b.tipoicv=14 ;
		INTO CURSOR c_MiDocDTE
	SELECT c_MiDocDTE


	lcTipoDTE=ALLTRIM(ALLTRIM(tipd))
	
	oJson = newobject('json')
	IF !EMPTY(NVL(lcTipoDTE,''))
		IF lcTipoDTE='14'		&&& es Sujeto Excluido
			****** Documento
			m.tipoDte='"tipo_dte": "'+lcTipoDTE+'"'
			m.ecodEstable='"establecimiento": "'+ALLTRIM(codmatrizSuc)+'"'
			m.ePuntoVenta='"punto_venta": "'+ALLTRIM(codmatrizPTV)+'"'
			m.econdiPago='"condicion_pago": '+ALLTRIM(STR(condipago+1))+' '
			m.renta_retenida='"renta_retenida": '+ALLTRIM(STR(rentadocto,12,6))+''
			m.etipocontingencia=''
			m.emotivocontingencia=''
			IF pnTipoContinDTE=1		&&& tipo contingencia ministerio de hacienda error
				m.etipocontingencia=TB+TB+TB+'"tipo_contingencia": '+ALLTRIM(STR(pnTipoContinDTE))+', '+CR
			ENDIF 
			IF pnTipoContinDTE=5		&&& tipo contingencia ministerio de hacienda error
				m.etipocontingencia=TB+TB+TB+'"tipo_contingencia": '+ALLTRIM(STR(pnTipoContinDTE))+', '+CR
				m.emotivocontingencia=TB+TB+TB+'"motivo_contingencia": "'+ALLTRIM(pcContingenciaDTE)+'", '+CR
			ENDIF 
			
			
			****** receptor (sujeto excluido)
			lcNumDoc=IIF(EMPTY(NVL(nit,'')),ValidarDUI(NVL(dui,'')),SoloNumeros(NVL(nit,"")))
			lctipDoc=IIF(EMPTY(lcNumDoc),"null",IIF(LEN(lcNumdoc)>12,"36","13")) 
			lcCorreoClienteTmp=ValidarVariosCorreos(correo,1)
			lccorreocliente=IIF(EMPTY(NVL(lcCorreoClienteTmp,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmp)+'"')
			m.rcorreo='"correo": '+lccorreocliente+' '
			lcCorreoClienteTmpCC=ValidarVariosCorreos(correo,2)
			lccorreoclienteCC=IIF(EMPTY(NVL(lcCorreoClienteTmpCC,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmpCC)+'"')
			m.rcorreo_cc='"correos_cc": '+lccorreoclienteCC+' '
			
			lcDistritotmp=buscaCodigoDTE(ALLTRIM(municli),'213','c_Distri',ALLTRIM(deptocli))
			lccodDistrito=SUBSTR(lcDistritotmp,1,2)
			lcNomDistrito=ALLTRIM(SUBSTR(lcDistritotmp,AT(',',lcDistritotmp)+2,150))

			
			m.rnumDocumento='"numero_documento": "'+lcNumDoc+'"'
			m.rtipoDocumento='"tipo_documento": "'+lctipDoc+'"'
			m.rnombre='"nombre": "'+UPPER(ALLTRIM(clipro))+'"'
			m.rcodActividad='"codigo_actividad": "'+IIF(EMPTY(NVL(codgiro,"")),"null",ALLTRIM(codgiro))+'"'
			m.rnombreComercial='"nombre_comercial": "'+UPPER(ALLTRIM(clipro))+'"'
				***** direccion receptor
				m.rdepartamento='"departamento": "'+ALLTRIM(deptocli)+'"'
				m.rmunicipio='"municipio": "'+ALLTRIM(lccodDistrito)+'"'
				m.rcomplemento='"complemento": "'+ALLTRIM(_EscaparJson(ALLTRIM(Direccion)+', '+lcNomDistrito))+'"'
			m.rtelefono='"telefono": "'+ALLTRIM(solonumeros(telcel))+'"'
			
			m.receptor=;
				TB+'"sujeto_excluido": {'+CR+;
					TB+TB+m.rnumDocumento+', '+CR+;
					TB+TB+m.rtipoDocumento+', '+CR+;
					TB+TB+m.rnombre+', '+CR+;
					TB+TB+m.rcodActividad+', '+CR+;
					TB+TB+'"direccion": {'+CR+;
						TB+TB+TB+m.rdepartamento+', '+CR+;
						TB+TB+TB+m.rmunicipio+', '+CR+;
						TB+TB+TB+m.rcomplemento+CR+;
					TB+TB+'}, '+CR+;
					TB+TB+m.rtelefono+', '+CR+;
					TB+TB+m.rcorreo_cc+', '+CR+;
					TB+TB+m.rcorreo+' '+CR+;
				TB+'}'
				
			
			***** forma de pago
			IF condipago=1	&&& es contado
				m.pagos=;
				TB+'"pagos": null'
			ELSE
				m.pcodigo='"tipo": "01"'
				m.pmontoPago='"monto": '+ALLTRIM(STR(totaldocto-rentadocto,12,8))+' '
				m.pagos=;
				'"pagos": ['+CR+;
					TB+TB+TB+'{'+CR+;
						TB+TB+TB+TB+m.pcodigo+', '+CR+;
						TB+TB+TB+TB+m.pmontoPago+' '+CR+;
					TB+TB+TB+'}'+CR+;
				TB+TB+'] '
			ENDIF 
			
				
			 ****** Venta 
			m.detalledoc=''
			m.uniondetalle=''
			m.linea=0
			m.fila=''
			SCAN all
				m.cdtipoItem='"tipo": '+ALLTRIM(STR(tipoprod))+''
				m.cdcantidad='"cantidad": '+ALLTRIM(STR(cantiunimed,12,6))+''
				m.cduniMedida='"unidad_medida":  59'
				*.cddescuento='"descuento": '+ALLTRIM(STR(descuento,12,8))+''
				m.cddescripcion='"descripcion": "'+ALLTRIM(_sincomilliasoTildes(producto))+'"'
				m.cdprecioUni='"precio_unitario": '+ALLTRIM(STR(totalnosujeto/IIF(NVL(cantiunimed,0)=0,1,cantiunimed),12,8))+''
				m.cdtributos='"tributos": ["20"]'
				
				m.fila=m.fila+m.uniondetalle+'{'+CR+;
					TB+TB+TB+m.cdtipoItem+', '+CR+;
					TB+TB+TB+m.cdcantidad+', '+CR+;
					TB+TB+TB+TB+m.cduniMedida+', '+CR+;
					TB+TB+TB+m.cddescripcion+', '+CR+;
					TB+TB+TB+m.cdprecioUni+' '+CR+;
					TB+TB+'}'
				
				m.uniondetalle=', '+CR
				m.linea=m.linea+1
			ENDSCAN 
			GO TOP
			m.items=;
					TB+'"items": [ '+CR+;
						m.fila+' '+CR+;
					']'+CR


			lcmiDoc=TB+TB+'{'+CR+;
					TB+TB+TB+'"campo": "numDoctoSiga", '+CR+;
					TB+TB+TB+'"etiqueta": "No.Documento Siga:", '+CR+;
					TB+TB+TB+'"valor": "'+ALLTRIM(numero)+'"  '+CR+;
				TB+'}'
			
			m.apendice=;
					TB+'"apendice": ['+CR+;
						TB+lcmiDoc+' '+CR+;
					TB+']'
					
			***** creando documento	
			m.documento=;
				TB+'"documento": {'+CR+;
					TB+TB+m.tipoDte+', '+CR+;
					TB+TB+m.ecodEstable+', '+CR+;
					TB+TB+m.ePuntoVenta+', '+CR+;
					m.etipocontingencia+;
					m.emotivocontingencia+;
					m.renta_retenida+', '+CR+;
					TB+TB+m.econdiPago+', '+CR+;
					TB+TB+m.receptor+', '+CR+;
					TB+TB+m.items+', '+CR+;
					TB+TB+m.pagos+', '+CR+;
					TB+TB+m.apendice+' '+CR+;
				TB+'}';

			m.StringJson=   '{'+CR+;
								m.documento+' '+CR+;
							'}'+CR

			oJson=m.StringJson
			pcBitacoraDTE=m.StringJson
		ELSE 
			lcOkErrorStatus='error'
			lcMensajeOkError='El Documento no es Compra de sujeto excluido '
			
		ENDIF 
	ELSE
		lcOkErrorStatus='error'
		lcMensajeOkError='No se encontro el Documento'
		
	ENDIF 

	USE IN c_DTE_STD
	USE IN c_DTE_Vta
	USE IN c_DTE_TDo 
	USE IN c_DTE_SUC
	*USE IN c_MiDocDTE
	USE IN c_DTE_clipro
	USE IN c_DTE_InvPro
	USE IN c_DTE_VtaD
	USE IN c_SIS_DTE
	
	IF !EMPTY(lcAliasDTEDoc)
		SELECT (lcAliasDTEDoc)
	ENDIF 
	IF lcOkErrorStatus='error'
		oJson='null'
	ENDIF 
	
	loRetornaRespuesta = CREATEOBJECT( 'Empty' )
	ADDPROPERTY(loRetornaRespuesta , 'Status', lcOkErrorStatus)
	ADDPROPERTY(loRetornaRespuesta , 'Mensaje', lcMensajeOkError)
	ADDPROPERTY(loRetornaRespuesta , 'DTE', oJson)
	
	IF lcOkErrorStatus='ok'
		GO TOP IN c_MiDocDTE
		lcArchivoJson=pcRutaJson+'\DTE-'+lcTipoDTE+'-'+ALLTRIM(c_MiDocDTE.codsuc)+'-0P01-'+PADL(ALLTRIM(c_MiDocDTE.numero),15,"0")+'.json'
		StrToFile(oJson,lcArchivoJson)
	ENDIF 
	
	RETURN loRetornaRespuesta
	
ENDFUNC 



FUNCTION _NombreDelDia(lndiasemana)
	DO case
		case lndiasemana=1
			lcDiasemana='DOM'
		case lndiasemana=2
			lcDiasemana='LUN'
		case lndiasemana=3
			lcDiasemana='MAR'
		case lndiasemana=4
			lcDiasemana='MIE'
		case lndiasemana=5
			lcDiasemana='JUE'
		case lndiasemana=6
			lcDiasemana='VIE'
		case lndiasemana=7
			lcDiasemana='SAB'
		OTHERWISE 
			lcDiasemana='   '
	ENDCASE
	RETURN lcDiasemana 
ENDFUNC 


FUNCTION EnvioJson_Sub(lcJson,lnIntentos,lnIdDocto,lcOrigen,lnmodeloDTE,lntipotraDTE,lnTipoConDTE)
	lcaliasdtemp=ALIAS()
	
	&pcArchivosProcedimientos
	
	m.DTE_Json_EnvioVal=lcJson
	USE pcsysdir+pcdb+"\sisdte" in 0 share again
	lcRes=EnviarDatosWebDTE_Sub(lcJson)
_cliptext=lcJson

	lcRes=DecodeUnicode(lcRes)
	
	*m.DTE_Json_EnvioVal_Resp=lcRes
	pcBitacoraDTE=pcBitacoraDTE+CHR(13)+CHR(13)+" Respuesta Facturador:"+CHR(13)+lcRes
	lcRes=STRTRAN(lcRes,'"pago ','"pago')
	lcRes=STRTRAN(lcRes,': tipo":','_tipo":')
	lcRes=STRTRAN(lcRes,': monto":','_monto":')
	lcRes=STRTRAN(lcRes,': codigo":"',':"_codigo:')
	lcRes=STRTRAN(lcRes,': tipo_documento":"',':" TIPO DOCUMENTO :')
	lcRes=STRTRAN(lcRes,': numero_documento":"',':" NUMERO DOCUMENTO :')
	lcRes=STRTRAN(lcRes,'"receptor: correo"','"receptor_correo"')
	lcRes=STRTRAN(lcRes,'"receptor: codigo_pais"','"receptor_codigo_pais"')	
	lcRes=STRTRAN(lcRes,': correo":"',':" CORREO DTE : ')
	lcRes=STRTRAN(lcRes,': descuento":"',':" DESCUENTO : ')
	lcRes=STRTRAN(lcRes,': complemento":"',':" DIRECION : ')
	lcRes=STRTRAN(lcRes,': codigo_actividad":"',':" CODIGO GIRO : ')
	lcRes=STRTRAN(lcRes,': telefono":"',':" TELEFONO : ')
	lcRes=STRTRAN(lcRes,': nrc":"',':" NUMERO REGISTRO IVA (NRC): ')
	
	IF ': tributo'$lcRes		&&& error en el tributo
		lnfinal=AT('","errores":{"',lcRes)
		lcRes=SUBSTR(lcRes,1,lnfinal+11)+'"Error en el Tributo"}'
	ENDIF 
	
	lcRes2=STRTRAN(lcRes,'","','"'+CHR(13)+'"')
	lcRes2=STRTRAN(lcRes2,'&aacute;','á')
*_cliptext=lcJson

	lcResDiga=''
	lcResMensa=''
	lnStatustmp=0
	lccodigoGeneracion=''
	lcnumeroControl=''
	lcselloRecepcion=''
	lcpdf_path=''
	lcfirmaElectronica=''
	lnmessaerror=16
	lcjsonRespuesta=lcRes
	lcmotivoerror=''

m.DTE_Json_EnvioInVal_Res=lcRes
	lcRes=ALLTRIM(lcRes)
	IF !EMPTY(NVL(lcRes,''))
		json2Envio_sub= CREATEOBJECT("json2")
		*obRes = json_decode(lcRes)
		obRes =json2Envio_sub.Parse(lcRes)

		IF TYPE("obRes.ok")='U' OR obRes.ok=.f.
			lnmessaerror=16
			IF TYPE("obRes.ok")<>'U'
				lcResMensa=obRes.mensaje
			ELSE
				lcResMensa=lcRes2
			ENDIF 
			*lcResDiga=json2.Stringify(obRes.errores)
			lcResDiga=lcRes2
			lcmotivoerror=lcRes2
			lnStatustmp=-2		&&&&& envio con error
			
		ELSE
			lnmessaerror=64
			lcResDiga='Información enviada correctamente...'
			lcResMensa="Envio de Json ..."

			lccodigoGeneracion=obRes.respuesta.codigoGeneracion
			lcnumeroControl=obRes.respuesta.numeroControl
			IF pnTipoContinDTE>0
				lcselloRecepcion=''
			ELSE
				lcselloRecepcion=obRes.respuesta.selloRecepcion
			ENDIF 
			lcpdf_path=obRes.pdf_path
			lcpdf_path=STRTRAN(lcpdf_path,'\u0026','&')
			
			lcfirmaElectronica=obRes.json.firmaelectronica
			lnStatustmp=1
			
		ENDIF 
		RELEASE json2
	ELSE
		lnmessaerror=16
		lcResDiga='Server sin Respuesta ....!'
		lcResMensa="Envio de Json ..."
		lnStatustmp=-1		&&&&& server infile sin respuesta
		
		lcCerrarTabla=''
		DO case
			CASE lcOrigen='VTA'
				IF !USED('cyvventas')
					USE pcsysdir+pcdb+"\cyvventas" in 0 share again 
					lcCerrarTabla='use in cyvventas'
				ELSE
					SELECT cyvventas
				ENDIF 
			CASE lcOrigen='COM' OR lcOrigen='CRT'
				IF !USED('cyvcompras')
					USE pcsysdir+pcdb+"\cyvcompras" in 0 share again 
					lcCerrarTabla='use in cyvcompras'
				ELSE
					SELECT cyvcompras
				ENDIF 
			CASE lcOrigen='INV'
				IF !USED('invInventarios')
					USE pcsysdir+pcdb+"\invInventarios" in 0 share again 
					lcCerrarTabla='use in invInventarios'
				ELSE
					SELECT invInventarios
				ENDIF 
		ENDCASE 
		lddatim=DATETIME()
		IF lcOrigen='CRT'
			REPLACE intentosdte WITH NVL(lnIntentos,00000000)+1,statusDTE WITH lnStatustmp ;
				FOR iddocto=lnIdDocto														&&& REMPLAZANDO TABLA
		ELSE
			REPLACE intentosdte WITH NVL(lnIntentos,00000000)+1,statusDTE WITH lnStatustmp ;
				FOR iddocto=lnIdDocto	
		ENDIF 
		INSERT INTO sisdte (iddocto,origen,status,intentos,mensaje,motivoerror,fechahora,jsonenviado) ;
				VALUES (lnIdDocto,lcOrigen,lnStatustmp,NVL(lnIntentos,00000000)+1,lcResMensa,lcResDiga,;	&&&& INSERTANDO ENdte
				lddatim,lcJson)
		
		IF !EMPTY(lcCerrarTabla)
			&lcCerrarTabla
		ENDIF 
		
	ENDIF 
	lcCerrarTabla=''
	DO case
		CASE lcOrigen='VTA'
			IF !USED('cyvventas')
				USE pcsysdir+pcdb+"\cyvventas" in 0 share again 
				lcCerrarTabla='use in cyvventas'
			ELSE
				SELECT cyvventas
			ENDIF 
		CASE lcOrigen='COM' OR lcOrigen='CRT'
			IF !USED('cyvcompras')
				USE pcsysdir+pcdb+"\cyvcompras" in 0 share again 
				lcCerrarTabla='use in cyvcompras'
			ELSE
				SELECT cyvcompras
			ENDIF 
		CASE lcOrigen='INV'
			IF !USED('invInventarios')
				USE pcsysdir+pcdb+"\invInventarios" in 0 share again 
				lcCerrarTabla='use in invInventarios'
			ELSE
				SELECT invInventarios
			ENDIF 
	ENDCASE 
	lddatim=DATETIME()

	IF lcOrigen='CRT'
		REPLACE intentosdteCR WITH NVL(lnIntentos,00000000)+1,statusDTECR WITH lnStatustmp ;
				sellorecepcionCR WITH lcselloRecepcion,numerocontrolCR WITH lcnumeroControl, ;
				codigoGeneracionCR WITH lccodigoGeneracion,modeloFacturacionDTECR WITH lnmodeloDTE, ;
				TipoTransmisionDTECR WITH  lntipotraDTE ;
				FOR iddocto=lnIdDocto
		GO top		

	ELSE
		REPLACE intentosdte WITH NVL(lnIntentos,00000000)+1,statusDTE WITH lnStatustmp ;
				sellorecepcion WITH lcselloRecepcion,numerocontrol WITH lcnumeroControl, ;
				codigoGeneracion WITH lccodigoGeneracion,modeloFacturacionDTE WITH lnmodeloDTE, ;
				TipoTransmisionDTE WITH  lntipotraDTE ;
				FOR iddocto=lnIdDocto
		GO top
	ENDIF 
	INSERT INTO sisdte (iddocto,origen,status,intentos,mensaje,codigoGeneracion,numeroControl,;
					selloRecepcion,pdf_path,firmaElectronica,jsonRespuesta,motivoerror,fechahora,;
					modelofacturacion,tipotransmision,tipocontingencia,jsonenviado) ;
				VALUES (lnIdDocto,lcOrigen,lnStatustmp,NVL(lnIntentos,00000000)+1,lcResMensa,lccodigoGeneracion,;
						lcnumeroControl,lcselloRecepcion,lcpdf_path,lcfirmaElectronica,;
						lcjsonRespuesta,lcmotivoerror,lddatim,lnmodeloDTE,lntipotraDTE,;
						lnTipoConDTE,lcJson)

	USE IN sisdte
	
	IF !EMPTY(lcCerrarTabla)
		&lcCerrarTabla
	ENDIF 
	
	IF !EMPTY(lcaliasdtemp)
		SELECT (lcaliasdtemp)
	ENDIF 
	
	RETURN lnStatustmp
ENDFUNC 




FUNCTION EnviarDatosWebDTE_Sub(lcjson)
	lcruta=ALLTRIM(pcurlPruebasDTE)
	
	LOCAL xhr
	xhr = CREATEOBJECT("Microsoft.XMLHTTP")
	xhr.Open("POST", lcruta, .f.)
	TRY 
		xhr.setRequestHeader('Content-Type', 'application/json')
		xhr.setRequestHeader('usuario', pcusuarioDTE)
		xhr.setRequestHeader('llave', pcclaveDTE)
		xhr.send(lcjson)

		LOCAL lcResultText
		lcResultText = xhr.responseText
		
		lcVerTmp=ALLTRIM(lcResultText)
	CATCH TO oException1
	 	lcVerTmp=''
	
	ENDTRY 
	
	RETURN lcVerTmp
ENDFUNC 




FUNCTION _VerRespuestaJson(lniddoc,lcori)
	lcaliastt=ALIAS()
	IF INLIST(pcAmbienteDTE,'00','01')			&&&& no es envio a tercerros		Contingencia
		USE pcsysdir+pcdb+"\sisDTE" IN 0 ALIAS jsonDTE SHARED AGAIN 
		**** CODIGO ANTERIOR: ORDER BY intentos DESC INTO CURSOR c_jsonDTE READWRITE
		** correccion para mostrar la respuesta mas reciente aun cuando el error de token no incrementa intentos *****
		SELECT intentos,fechahora,jsonrespuesta,motivoerror,sellorecepcion,tipocontingencia ;
			FROM jsonDTE WHERE iddocto=lniddoc AND origen=lcori  ;
		ORDER BY intentos DESC,fechahora DESC INTO CURSOR c_jsonDTE READWRITE 
 
		IF RECCOUNT()>0
			*LOCATE FOR !EMPTY(sellorecepcion) 
			IF !EOF()
				lcdigasello=IIF(EMPTY(ALLTRIM(NVL(sellorecepcion,''))),'  !Sin Sello!','')
				lcDigacontingencia=IIF(NVL(tipocontingencia,0)<>0,'  Contingencia: '+ALLTRIM(STR(tipocontingencia))+'  ','')
				lcerrormoti=ALLTRIM(jsonrespuesta)
			ELSE 
*				GO bott
				*LOCATE FOR EMPTY(sellorecepcion)
				lcdigasello=IIF(EMPTY(ALLTRIM(NVL(sellorecepcion,''))),'  !Sin Sello!','')
				lcDigacontingencia=IIF(NVL(tipocontingencia,0)<>0,'  Contingencia: '+ALLTRIM(STR(tipocontingencia))+'  ','')
				lcerrormoti=ALLTRIM(NVL(jsonrespuesta,''))
			ENDIF 
			_cliptext=jsonrespuesta 
 
			MESSAGEBOX('Intentos '+ALLTRIM(STR(intentos))+' - Fecha y Hora : '+TTOC(fechahora)+lcDigacontingencia+lcdigasello+;
						CHR(13)+lcerrormoti,64,'Mensaje DTE' )
		ENDIF 	
	ELSE 
		USE pcsysdir+pcdb+"\sisDTE" IN 0 ALIAS jsonDTE SHARED AGAIN 
		**** CODIGO ANTERIOR: ORDER BY intentos DESC INTO CURSOR c_jsonDTE READWRITE
		** correccion para mostrar la respuesta mas reciente aun cuando el error de token no incrementa intentos *****
		SELECT intentos,fechahora,jsonrespuesta,motivoerror,sellorecepcion,tipocontingencia ;
			FROM jsonDTE WHERE iddocto=lniddoc AND origen=lcori  ;
		ORDER BY intentos DESC,fechahora DESC INTO CURSOR c_jsonDTE READWRITE 
		IF RECCOUNT()>0
			*LOCATE FOR !EMPTY(sellorecepcion)
			lcdigasello=IIF(EMPTY(ALLTRIM(NVL(sellorecepcion,''))),'  !Sin Sello!','')
*			GO bott
			_cliptext=jsonrespuesta 
			lcerrormoti=ALLTRIM(NVL(jsonrespuesta,''))
			lcdigasello=IIF(EMPTY(ALLTRIM(sellorecepcion)),'  !Sin Sello!','')
			lcDigacontingencia=IIF(NVL(tipocontingencia,0)<>0,'  Contingencia: '+ALLTRIM(STR(NVL(tipocontingencia,0)))+'  ','')
			MESSAGEBOX('Intentos '+ALLTRIM(STR(NVL(intentos,0)))+' - Fecha y Hora : '+TTOC(fechahora)+lcDigacontingencia+lcdigasello+;
						CHR(13)+lcerrormoti,64,'Mensaje DTE' )
		ENDIF 	
	ENDIF 
	USE IN jsonDTE
	USE IN c_jsonDTE

	IF !EMPTY(lcaliastt)
		SELECT(lcaliastt)
	ENDIF 
ENDFUNC 



FUNCTION _VerPDFJson(lniddoc,lcori,ldMifecDTE,lcminumcotrol)
	lcaliastt=ALIAS()
	lcfilePdf_path=''
	
	IF INLIST(pcAmbienteDTE,'00','01')		&&& no es terceros
		IF lcori='VTA'
			IF pnUsarOtroNombreJson=1
				lcNombreFilePDF_DTE=LOWER(pcSysDir+pcdb+"\ArchivosPDF\"+ALLTRIM(lcminumcotrol)+'.PDF')
			ELSE
				lcNombreFilePDF_DTE=LOWER(pcSysDir+pcdb+"\ArchivosPDF\"+ALLTRIM(STR(YEAR(ldMifecDTE)))+'-'+ALLTRIM(lcminumcotrol)+'.PDF')
			ENDIF 
		ELSE
			lcNombreFilePDF_DTE=LOWER(pcSysDir+pcdb+"\ArchivosPDF\"+ALLTRIM(STR(YEAR(ldMifecDTE)))+'-'+ALLTRIM(lcminumcotrol)+'.PDF')
		ENDIF 
		IF FILE(lcNombreFilePDF_DTE)
			lcfilePdf_path=lcNombreFilePDF_DTE
		ENDIF 
	ELSE 
		USE pcsysdir+pcdb+"\sisDTE" IN 0 ALIAS jsonDTE SHARED AGAIN 
		SELECT Pdf_path FROM jsonDTE WHERE iddocto=lniddoc AND origen=lcori AND !EMPTY(pdf_path) ;
		ORDER BY intentos DESC INTO CURSOR c_jsonDTE READWRITE 
		IF RECCOUNT()>0 AND !EMPTY(Pdf_path)
			lcfilePdf_path=ALLTRIM(Pdf_path)
		ENDIF 
		USE IN c_jsonDTE
		USE IN jsonDTE
	ENDIF 

	IF !EMPTY(lcfilePdf_path)
		loShell = CREATEOBJECT("Shell.Application")
		loShell.ShellExecute(ALLTRIM(lcfilePdf_path))
		RELEASE loShell
	ENDIF
	
	IF !EMPTY(lcaliastt)
		SELECT(lcaliastt)
	ENDIF 
ENDFUNC 





FUNCTION ConsultarSelloRecibidoJSON_Sub(lnidDoc,lcOri,lcUUID)
	loRetRespu = CREATEOBJECT( 'Empty' )
		ADDPROPERTY(loRetRespu , 'Status', 'error')
		ADDPROPERTY(loRetRespu , 'Mensaje', 'Imposible Consultar DTE')
		ADDPROPERTY(loRetRespu , 'Sello', '')

		lcOrigen=lcOri
		lcCerrarTabla=''
	
	IF lnIdDoc<>0 AND !EMPTY(lcOri) AND !EMPTY(LCUUID)
		
		USE pcsysdir+pcdb+"\sisDTE" IN 0 ALIAS selloDTE SHARED AGAIN
		
		IF !EMPTY(pcurlConsultasDTE)
			IF RIGHT(ALLTRIM(pcurlConsultasDTE),1)='/'
				lcruta=ALLTRIM(pcurlConsultasDTE)+ALLTRIM(lcUUID)
			ELSE 
				lcruta=ALLTRIM(pcurlConsultasDTE)+'/'+ALLTRIM(lcUUID)
			ENDIF 

			LOCAL xhr
			xhr = CREATEOBJECT("Microsoft.XMLHTTP")
			xhr.Open("GET", lcruta, .f.)
			
			xhr.setRequestHeader('Content-Type', 'application/json; charset=utf-8')
			xhr.setRequestHeader('usuario', pcusuarioDTE)
			xhr.setRequestHeader('llave', pcclaveDTE)
			xhr.send()

			LOCAL lcResultText
			lcResultText = xhr.responseText
			
			*** validando respuesta
			json2SR = CREATEOBJECT("json2")
			obRes =json2SR.Parse(lcResultText)

_cliptext=lcResultText
 		
			IF obRes.ok=.t.
				loRetRespu.Status='ok'
				loRetRespu.sello=NVL(obRes.respuesta.selloRecepcion,'')
				IF !EMPTY(loRetRespu.sello)
					lcSSEllo='   SELLO: '+ALLTRIM(loRetRespu.sello)
				ELSE
					IF NVL(obRes.respuesta.status,'')='contingencia'
						loRetRespu.sello=NVL(obRes.json.selloRecibido,'')
						IF !EMPTY(loRetRespu.sello)
							lcSSEllo='   SELLO: '+ALLTRIM(loRetRespu.sello)
						ELSE
							lcSSEllo='  !SIN SELLO! '
						ENDIF 
					ELSE
						lcSSEllo='  !SIN SELLO! '
					ENDIF 
				ENDIF 
				lcpathpdf=''
				IF 	!EMPTY(loRetRespu.sello)
					lcpathpdf=NVL(obRes.pdf_path,'')
					lcpathpdf=STRTRAN(lcpathpdf,'\u0026','&')
				ENDIF 

				DO case
					CASE lcOrigen='VTA'
						IF !USED('cyvventas')
							USE pcsysdir+pcdb+"\cyvventas" in 0 share again 
							lcCerrarTabla='use in cyvventas'
						ELSE
							SELECT cyvventas
						ENDIF 
						lcCursorActualizaDTE='c_cyvventas'
						
					CASE lcOrigen='COM'
						IF !USED('cyvcompras')
							USE pcsysdir+pcdb+"\cyvcompras" in 0 share again 
							lcCerrarTabla='use in cyvcompras'
						ELSE
							SELECT cyvcompras
						ENDIF 
						lcCursorActualizaDTE='c_cyvcompras'
						
					CASE lcOrigen='INV'
						IF !USED('invInventarios')
							USE pcsysdir+pcdb+"\invInventarios" in 0 share again 
							lcCerrarTabla='use in invInventarios'
						ELSE
							SELECT invInventarios
						ENDIF 
						lcCursorActualizaDTE='c_invInventarios'
						
				ENDCASE 
				
				loRetRespu.Mensaje=ALLTRIM(SUBSTR(ALLTRIM(obRes.mensaje)+lcSSEllo,1,250))
				IF !EMPTY(loRetRespu.sello)
					REPLACE sellorecepcion WITH ALLTRIM(loRetRespu.sello) ;
						FOR iddocto=lnidDoc AND origen=lcOri					&&& cambiando en tabla
					
					REPLACE sellorecepcion WITH ALLTRIM(loRetRespu.sello), ;
						pdf_path with IIF(EMPTY(lcpathpdf),pdf_path,lcpathpdf) ;
						FOR iddocto=lnidDoc AND origen=lcOri AND codigogeneracion=lcUUID ;
							AND status=1 IN selloDTE							&&& cambiando de sisDTE
				ENDIF 
				IF !EMPTY(lcCerrarTabla)
					&lcCerrarTabla
				ENDIF 
			ELSE
				loRetRespu.Status='error'
				loRetRespu.Mensaje=ALLTRIM(SUBSTR(obRes.mensaje,1,250))
			ENDIF 
			RELEASE json2SR
		ELSE
			loRetRespu.Mensaje='Configure en los Parametros la URL de consulta de DTE'	
		ENDIF 
		USE IN selloDTE
	ELSE
		loRetRespu.Mensaje='Imposible Realizar la consulta, falta informacion del DTE'	
	ENDIF 
	
	RETURN loRetRespu
ENDFUNC 



FUNCTION InvalidadDTE_VTA_Sub(lnidDocAnulaDTE,lcOriAnulaDTE,lcmotivoanulaDTEE,lcnotasAnula,lnidRegistroInvalidacion)
	&pcArchivosProcedimientos
	LOCAL lnidEventoInvalidacion
	lnidEventoInvalidacion=lnidDocAnulaDTE
	IF PCOUNT()>=5 AND VARTYPE(lnidRegistroInvalidacion)='N' AND lnidRegistroInvalidacion>0
		lnidEventoInvalidacion=lnidRegistroInvalidacion
	ENDIF
	loRetRespu = CREATEOBJECT( 'Empty' )
	ADDPROPERTY(loRetRespu , 'Status', 'error')
	ADDPROPERTY(loRetRespu , 'Mensaje', 'Imposible Consultar DTE')
	ADDPROPERTY(loRetRespu , 'comentario', '')

	IF lnidDocAnulaDTE<>0 AND !EMPTY(lcOriAnulaDTE) 
		*#Define CR		Chr(13)
		*#Define TB		"  "
		lcOkErrorStatus='ok'
		lcMensajeOkError='documento generado correctamente'
		
		lcJsonTmp=''
		lcAliasDTEDoc=ALIAS()
		USE pcSysDir+pcdb+"\cyvVentas" IN 0 share AGAIN ALIAS c_DTE_Vta
		USE pcSysDir+pcdb+"\cyvVentasdeta" IN 0 share AGAIN ALIAS c_DTE_VtaD
		USE pcSysDir+pcdb+"\sisTipoDoctos" IN 0 share AGAIN ALIAS c_DTE_STD
		CrearCursorStatus(19,'c_DTE_TDo','') 
		USE pcSysDir+pcdb+"\sisCata" IN 0 share AGAIN ALIAS c_DTE_SUC
		USE pcSysDir+pcdb+"\cyvclipro" IN 0 share AGAIN ALIAS c_DTE_clipro
		USE pcSysDir+pcdb+"\invProductos" IN 0 share AGAIN ALIAS c_DTE_InvPro
		USE pcSysDir+pcdb+"\sisDTE" IN 0 share AGAIN ALIAS c_DTE
		
		SELECT a.*,c.tipd,PADL(SUBSTR(ALLTRIM(d.cod),1,4),4,"0") as CodSuc,;
				PADL(SUBSTR(ALLTRIM(e.cod),1,4),4,"0") as CodPTV,;
				d.tipoestablecimiento,d.correo as correosuc,d.telefono ,;
				solonumeros(a.celular) as telcel,;
				f.codgiro,f.giro as giroclipro,f.correoDTE as correo,g.codigogeneracion as uuid ;
			FROM c_DTE_Vta a ;
				inner JOIN c_DTE_STD b ON a.idtipodocto=b.idtipodocto ;
				inner JOIN c_DTE_TDo c ON b.tipoicv=c.id ;
				left join c_DTE_SUC d ON a.idsucursal=d.id and d.origen='SUC' ;
				left join c_DTE_SUC e ON a.idptovta=e.id and e.origen='PTV' ;
				left JOIN c_DTE_clipro f ON a.idclipro=f.idclipro ;
				left JOIN c_DTE g ON a.iddocto=g.iddocto AND a.origen=g.origen  AND g.status=1 ;
			WHERE a.iddocto=lnidDocAnulaDTE AND a.origen=lcOriAnulaDTE AND b.tipoicv<>0 ;
			INTO CURSOR c_MiDocDTE
	
		
		lcTipoDTE=ALLTRIM(ALLTRIM(tipd))
				
		IF pcambienteDTE='02'			&& 02  pruebas , 03 produccion
			lcruta=ALLTRIM(pcUrlTestInvalidDTE)
		ELSE
			lcruta=ALLTRIM(pcUrlProdInvalidDTE)
		ENDIF 
		
		* Una reversion solo consulta Hacienda si el documento original tiene sello.
		* Sin sello, ambos procesos se resuelven exclusivamente dentro de SIGA.
		llReversionConSello=.F.
		IF c_MiDocDTE.idtipodocto=pnidtiponulfac
			lnIdDoctoOriginalSello=c_MiDocDTE.iddoctorelacion
			SELECT c_DTE
			LOCATE FOR iddocto=lnIdDoctoOriginalSello AND UPPER(ALLTRIM(origen))==UPPER(ALLTRIM(lcOriAnulaDTE)) AND status=1 AND !EMPTY(sellorecepcion)
			llReversionConSello=FOUND()
			SELECT c_MiDocDTE
		ENDIF

		IF (!EMPTY(lcruta) AND !EMPTY(sellorecepcion)) OR ;
			(c_MiDocDTE.idtipodocto=pnidtiponulfac AND llReversionConSello)	&&& documento actual u original con sello
			IF idtipodocto=pnidtiponulfac			&&&& se esta anulando una factura con una reversion en otra fecha
				lnidDocAnular=idDoctoRelacion
				SELECT a.iddocto,a.motivoanula,a.codigogeneracion,a.notas,;
							PADL(SUBSTR(ALLTRIM(d.cod),1,4),4,"0") as CodSuc,;
							g.codigogeneracion as uuid,g.pdf_path ;
					FROM c_DTE_Vta a ;
						left join c_DTE_SUC d ON a.idsucursal=d.id and d.origen='SUC' ;
						left JOIN c_DTE g ON a.iddocto=g.iddocto AND a.origen=g.origen  AND g.status=1 ;
					WHERE a.iddocto=lnidDocAnular INTO CURSOR c_rever READWRITE 
				lcuuid=ALLTRIM(uuid)
				
				lcSucAnula=ALLTRIM(codsuc)
				lcpdfanula=ALLTRIM(pdf_path)
				USE IN c_rever
				
			ELSE
				lnidDocAnular=0
				lcuuid=ALLTRIM(uuid)
				lcSucAnula=ALLTRIM(codsuc)
				lcpdfanula=''
			ENDIF 
			SELECT c_MiDocDTE
		
			*******responsable

			lcmotivo=IIF(lcmotivoanulaDTEE=1,"Error en la Información del Documento Tributario Electrónico a invalidar.",;
							IIF(lcmotivoanulaDTEE=2,"Rescindir de la operación realizada. ",ALLTRIM(lcnotasAnula)))
			lnidmotivoanula=lcmotivoanulaDTEE


			m.nombre='"nombre": "'+UPPER(ALLTRIM(pcNomEmpresa))+'"'
			m.tipo_documento='"tipo_documento": "36"'
			m.numero_documento='"numero_documento": "'+SoloNumeros(ALLTRIM(pcNIT))+'"'

			m.responsable=;
				'"responsable":{'+CR+;
					TB+TB+TB+m.nombre+', '+CR+;
					TB+TB+TB+m.tipo_documento+', '+CR+;
					TB+TB+TB+m.numero_documento+' '+CR+;
				TB+TB+'}'
	
			*******solicitante
			lnTempnit=SoloNumeros(NVL(nit,''))
			lcDuitemp=ValidarDUI(NVL(dui,''))
			lcNumDoc=IIF(EMPTY(lnTempnit),lcDuitemp,lnTempnit)
		
			
			lctipDoc=IIF(EMPTY(lcNumDoc),"null",IIF(LEN(lcNumdoc)>13,"36","13"))		&& 36 nit, 13 dui
			lcCorreoClienteTmp=ValidarVariosCorreos(correo,1)
			lccorreocliente=IIF(EMPTY(NVL(lcCorreoClienteTmp,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmp)+'"')
			m.rcorreo='"correo": '+lccorreocliente+' '
			lcCorreoClienteTmpCC=ValidarVariosCorreos(correo,2)
			lccorreoclienteCC=IIF(EMPTY(NVL(lcCorreoClienteTmpCC,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmpCC)+'"')
			m.rcorreo_cc='"correos_cc": '+lccorreoclienteCC+' '
			
			m.stipo_documento='"tipo_documento": "13"'
			IF EMPTY(lcNumDoc)
				IF EMPTY(lcNumDoc)
					lcDuitemp=''
					lnTempnit=''
					lcnitduitmp=INPUTBOX('Ingrese un Numero de Documento del Solicitante (dui/nit):','',pcDuiAnularDoc)
					IF LEN(lcnitduitmp)>12
						lnTempnit=SoloNumeros(lcnitduitmp)
						pcDuiAnularDoc=lcnitduitmp
					ELSE
						lcDuitemp=ValidarDUI(lcnitduitmp)
						pcDuiAnularDoc=lcDuitemp
					ENDIF 
					
					lcNumDoc=IIF(EMPTY(lnTempnit),lcDuitemp,lnTempnit)

				ENDIF 
				
				m.snumero_documento='"numero_documento": "02450408-4"'
				lctipDoc=IIF(EMPTY(lcNumDoc),"null",IIF(LEN(lcNumdoc)>13,'"36"','"13"'))		&& 36 nit, 13 dui
				m.stipo_documento='"tipo_documento": '+lctipDoc
			ELSE
				m.stipo_documento='"tipo_documento": "'+lctipDoc+'"'
				m.snumero_documento='"numero_documento": "'+lcNumDoc+'"'
			ENDIF 
			m.snombre='"nombre": "'+UPPER(ALLTRIM(clipro))+'"'

			m.solicitante=;
				'"solicitante":{'+CR+;
					TB+TB+TB+m.snombre+', '+CR+;
					TB+TB+TB+m.stipo_documento+', '+CR+;
					TB+TB+TB+m.snumero_documento+', '+CR+;
					TB+TB+TB+m.rcorreo_cc+', '+CR+;
					TB+TB+TB+m.rcorreo+''+CR+;
				TB+TB+'}'
					
			m.codEstable='"establecimiento": "'+ALLTRIM(lcSucAnula)+'"'
			m.uuid='"uuid": "'+lcuuid+'" '
			m.tipo_anulacion='"tipo_anulacion": '+ALLTRIM(STR(lnidmotivoanula))
			m.motivo='"motivo": "'+IIF(EMPTY(lcmotivo),"Anulacion de la Venta",lcmotivo)+'"'

*							TB+TB+m.emision+', '+CR+;
	
			docJson='{'+CR+;
						TB+TB+'"invalidacion": {'+CR+;
							TB+TB+m.codEstable+', '+CR+;
							TB+TB+m.uuid+', '+CR+;
							TB+TB+m.tipo_anulacion+', '+CR+;
							TB+TB+m.motivo+', '+CR+;
							TB+TB+m.responsable+', '+CR+;
							TB+TB+m.solicitante+' '+CR+;
						TB+'}'+CR+;
					'}'

m.DTE_Json_EnvioInVal=docJson

			USE IN c_DTE_Vta
			USE IN c_DTE_VtaD
			USE IN c_DTE_STD
			USE IN c_DTE_TDo
			USE IN c_DTE_SUC
			USE IN c_DTE_clipro
			USE IN c_DTE_InvPro
			USE IN c_DTE

			LOCAL xhr
			xhr = CREATEOBJECT("Microsoft.XMLHTTP")
			xhr.Open("GET", lcruta, .f.)
			
			xhr.setRequestHeader('Content-Type', 'application/json; charset=utf-8')
			xhr.setRequestHeader('usuario', pcusuarioDTE)
			xhr.setRequestHeader('llave', pcclaveDTE)
			xhr.send(docJson)
 
			LOCAL lcResultText
			lcResultText = xhr.responseText
			
			lcResultText=STRTRAN(lcResultText,': numero_documento":"',':" numero_documento:')
			lcResultText=STRTRAN(lcResultText,': tipo_documento":"',':" tipo_documento:')
			lcResultText=STRTRAN(lcResultText,': selloRecibido":"',':" selloRecibido:')
			lcResultText=STRTRAN(lcResultText,': correo":"',':" correo:')

			*** validando respuesta
			json2SR = CREATEOBJECT("json2")
m.DTE_Json_EnvioInVal_Res=lcResultText
			obRes =json2SR.Parse(lcResultText)
*_cliptext=	lcResultText		
			lcResultUpper=UPPER(ALLTRIM(lcResultText))
			llInvalidacionConfirmada=obRes.ok=.t. OR ;
				'DOCUMENTO SE ENCUENTRA INVALIDADO'$lcResultUpper OR ;
				'DOCUMENTO YA SE ENCUENTRA INVALIDADO'$lcResultUpper OR ;
				'YA FUE INVALIDADO'$lcResultUpper OR ;
				'YA ESTA INVALIDADO'$lcResultUpper OR ;
				'DOCUMENTO INVALIDADO'$lcResultUpper OR ;
				'DTE INVALIDADO'$lcResultUpper OR ;
				'EL DOCUMENTO YA SE ENCUENTRA ANULADO'$lcResultUpper
			IF llInvalidacionConfirmada
				loRetRespu.Status='ok'
				loRetRespu.Mensaje=ALLTRIM(NVL(obRes.mensaje,''))
				***** status 2 anulado
				*REPLACE anulada WITH 1,jsonanulacion WITH jsonRespuesta IN sisdte FOR iddocto=lnidDocAnulaDTE AND origen=lcOriAnulaDTE AND status=1
				INSERT INTO sisdte (iddocto,origen,status,mensaje,jsonRespuesta,pdf_path) ;
					VALUES (lnidEventoInvalidacion,lcOriAnulaDTE,2,loRetRespu.Mensaje,lcResultText+CHR(13)+CHR(13)+docJson,lcpdfanula)
				
				IF lnidDocAnular<>0		&&& se anulo otro dia con un doc de reversion
					* La invalidacion pertenece al documento reverso; la factura original permanece activa en SIGA.
					REPLACE statusdte WITH 2 IN cyvventas FOR iddocto=lnidDocAnulaDTE		&&&& este es el doc que revierte
				ENDIF 

			ENDIF 
			loRetRespu.Mensaje=NVL(obRes.mensaje,'')
			loRetRespu.comentario=lcResultText+CHR(13)+CHR(13)+docJson
			RELEASE json2SR
		ELSE
			IF EMPTY(sellorecepcion)
				loRetRespu.Status='ok'
				loRetRespu.Mensaje='Documento local sin sello de Hacienda'
				loRetRespu.comentario='Documento sin sello de recibido; no necesita validar con Hacienda y puede anularse localmente.'
			ELSE 
				loRetRespu.Mensaje='Configure en los Parametros la URL de consulta de DTE'
			ENDIF 
		ENDIF 
		*USE IN selloDTE
	ELSE
		loRetRespu.Mensaje='Imposible Realizar la consulta, falta informacion del DTE'	
	ENDIF 
	
	RETURN loRetRespu
ENDFUNC 



****** invalidacion de compras no sujetas o Comprobantes de Retencion.
FUNCTION InvalidadDTE_COM_Sub(lnidDocAnulaDTE,lcOriAnulaDTE)
	&pcArchivosProcedimientos
	loRetRespu = CREATEOBJECT( 'Empty' )
	ADDPROPERTY(loRetRespu , 'Status', 'error')
	ADDPROPERTY(loRetRespu , 'Mensaje', 'Imposible Consultar DTE')
	ADDPROPERTY(loRetRespu , 'comentario', '')
	
	IF lnidDocAnulaDTE<>0 AND !EMPTY(lcOriAnulaDTE) 
		*#Define CR		Chr(13)
		*#Define TB		"  "
		lcOkErrorStatus='ok'
		lcMensajeOkError='documento generado correctamente'
		
		lcJsonTmp=''
		lcAliasDTEDoc=ALIAS()
		USE pcSysDir+pcdb+"\cyvcompras" IN 0 share AGAIN ALIAS c_DTE_Vta
		USE pcSysDir+pcdb+"\cyvcomprasdeta" IN 0 share AGAIN ALIAS c_DTE_VtaD
		USE pcSysDir+pcdb+"\sisTipoDoctos" IN 0 share AGAIN ALIAS c_DTE_STD
		CrearCursorStatus(18,'c_DTE_TDo','') 
		USE pcSysDir+pcdb+"\sisCata" IN 0 share AGAIN ALIAS c_DTE_SUC
		USE pcSysDir+pcdb+"\cyvclipro" IN 0 share AGAIN ALIAS c_DTE_clipro
		USE pcSysDir+pcdb+"\invProductos" IN 0 share AGAIN ALIAS c_DTE_InvPro
		USE pcSysDir+pcdb+"\sisDTE" IN 0 share AGAIN ALIAS c_DTE
		
		SELECT a.*,c.tipd,PADL(SUBSTR(ALLTRIM(d.cod),1,4),4,"0") as CodSuc,;
				PADL(SUBSTR(ALLTRIM(e.cod),1,4),4,"0") as CodPTV,;
				d.tipoestablecimiento,d.correo as correosuc,d.telefono ,;
				solonumeros(F.celular) as telcel,;
				f.codgiro,f.giro as giroclipro,f.correoDTE as correo,g.codigogeneracion as uuid ;
			FROM c_DTE_Vta a ;
				inner JOIN c_DTE_STD b ON a.idtipodocto=b.idtipodocto ;
				inner JOIN c_DTE_TDo c ON b.tipoicv=c.id ;
				left join c_DTE_SUC d ON a.idsucursal=d.id and d.origen='SUC' ;
				left join c_DTE_SUC e ON a.idptovta=e.id and e.origen='PTV' ;
				left JOIN c_DTE_clipro f ON a.idclipro=f.idclipro ;
				left JOIN c_DTE g ON a.iddocto=g.iddocto AND a.origen=g.origen  AND g.status=1 ;
			WHERE a.iddocto=lnidDocAnulaDTE AND a.origen=lcOriAnulaDTE AND b.tipoicv<>0 ;
			INTO CURSOR c_MiDocDTE
		
		SELECT c_MiDocDTE

		lcuuid=ALLTRIM(uuid)
		lcTipoDTE=ALLTRIM(ALLTRIM(tipd))
		
				
		IF pcambienteDTE='02'			&& 02  pruebas , 03 produccion
			lcruta=ALLTRIM(pcUrlTestInvalidDTE)
		ELSE
			lcruta=ALLTRIM(pcUrlProdInvalidDTE)
		ENDIF 
		
		IF !EMPTY(lcruta) AND !EMPTY(sellorecepcion)		&&&  si tiene sello de Hacienda
			
			m.codEstable='"establecimiento": "'+ALLTRIM(codsuc)+'"'
			m.uuid='"uuid": "'+lcuuid+'" '
			m.tipo_anulacion='"tipo_anulacion": 2'
			m.motivo='"motivo": "anulacion de la operacion"'

			*******responsable
			m.nombre='"nombre": "'+UPPER(ALLTRIM(pcNomEmpresa))+'"'
			m.tipo_documento='"tipo_documento": "36"'
			m.numero_documento='"numero_documento": "'+SoloNumeros(ALLTRIM(pcNIT))+'"'

			m.responsable=;
				'"responsable":{'+CR+;
					TB+TB+TB+m.nombre+', '+CR+;
					TB+TB+TB+m.tipo_documento+', '+CR+;
					TB+TB+TB+m.numero_documento+' '+CR+;
				TB+TB+'}'
	
			*******solicitante
			lcnumnittmp=SoloNumeros(nit)
			lcDuitemp=ValidarDUI(NVL(dui,''))
			lcNumDoc=IIF(EMPTY(nit),NVL(lcDuitemp,''),NVL(lcnumnittmp,""))
			lctipDoc=IIF(EMPTY(lcNumDoc),"null",IIF(LEN(lcNumdoc)>13,"36","13"))		&& 36 nit, 13 dui
			lcCorreoClienteTmp=ValidarVariosCorreos(correo,1)
			lccorreocliente=IIF(EMPTY(NVL(lcCorreoClienteTmp,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmp)+'"')
			m.rcorreo='"correo": '+lccorreocliente+' '
			lcCorreoClienteTmpCC=ValidarVariosCorreos(correo,2)
			lccorreoclienteCC=IIF(EMPTY(NVL(lcCorreoClienteTmpCC,'')),"null",'"'+ALLTRIM(lcCorreoClienteTmpCC)+'"')
			m.rcorreo_cc='"correos_cc": '+lccorreoclienteCC+' '
			
			
			IF EMPTY(lcNumDoc)
				lcNumDoc=SoloNumeros(ALLTRIM(pcNIT))
				lctipDoc='36'
			ENDIF 
			m.snombre='"nombre": "'+UPPER(ALLTRIM(clipro))+'"'
			m.stipo_documento='"tipo_documento": "'+lctipDoc+'"'
			m.snumero_documento='"numero_documento": "'+lcNumDoc+'"'

			m.solicitante=;
				'"solicitante":{'+CR+;
					TB+TB+TB+m.snombre+', '+CR+;
					TB+TB+TB+m.stipo_documento+', '+CR+;
					TB+TB+TB+m.snumero_documento+', '+CR+;
					TB+TB+TB+m.rcorreo_cc+', '+CR+;
					TB+TB+TB+m.rcorreo+''+CR+;
				TB+TB+'}'
					
			m.codEstable='"establecimiento": "'+ALLTRIM(codsuc)+'"'
			m.uuid='"uuid": "'+lcuuid+'" '
			m.tipo_anulacion='"tipo_anulacion": 2'
			m.motivo='"motivo": "Mala Digitacion"'

*							TB+TB+m.emision+', '+CR+;
	
			docJson='{'+CR+;
						TB+TB+'"invalidacion": {'+CR+;
							TB+TB+m.codEstable+', '+CR+;
							TB+TB+m.uuid+', '+CR+;
							TB+TB+m.tipo_anulacion+', '+CR+;
							TB+TB+m.motivo+', '+CR+;
							TB+TB+m.responsable+', '+CR+;
							TB+TB+m.solicitante+' '+CR+;
						TB+'}'+CR+;
					'}'

m.DTE_Json_EnvioInVal=docJson

			USE IN c_DTE_Vta
			USE IN c_DTE_VtaD
			USE IN c_DTE_STD
			USE IN c_DTE_TDo
			USE IN c_DTE_SUC
			USE IN c_DTE_clipro
			USE IN c_DTE_InvPro

			LOCAL xhr
			xhr = CREATEOBJECT("Microsoft.XMLHTTP")
			xhr.Open("GET", lcruta, .f.)
			
			xhr.setRequestHeader('Content-Type', 'application/json; charset=utf-8')
			xhr.setRequestHeader('usuario', pcusuarioDTE)
			xhr.setRequestHeader('llave', pcclaveDTE)
			xhr.send(docJson)

			LOCAL lcResultText
			lcResultText = xhr.responseText
			
			lcResultText=STRTRAN(lcResultText,': numero_documento":"',':" numero_documento:')
			lcResultText=STRTRAN(lcResultText,': tipo_documento":"',':" tipo_documento:')
			lcResultText=STRTRAN(lcResultText,': selloRecibido":"',':" selloRecibido:')
			lcResultText=STRTRAN(lcResultText,': correo":"',':" correo:')

			*** validando respuesta
			json2SR = CREATEOBJECT("json2")
m.DTE_Json_EnvioInVal_Res=lcResultText
			obRes =json2SR.Parse(lcResultText)
*_cliptext=	lcResultText		
			IF obRes.ok=.t.
				loRetRespu.Status='ok'
				loRetRespu.Mensaje=ALLTRIM(NVL(obRes.mensaje,''))
				***** status 2 anulado
				*REPLACE anulada WITH 1,jsonanulacion WITH jsonRespuesta IN sisdte FOR iddocto=lnidDocAnulaDTE AND origen=lcOriAnulaDTE AND status=1
				INSERT INTO c_DTE (iddocto,origen,status,mensaje,jsonRespuesta) ;
					VALUES (lnidDocAnulaDTE,lcOriAnulaDTE,2,loRetRespu.Mensaje,lcResultText+CHR(13)+CHR(13)+docJson)
			ENDIF 
			loRetRespu.Mensaje=NVL(obRes.mensaje,'')
			loRetRespu.comentario=lcResultText+CHR(13)+CHR(13)+docJson
			USE IN c_DTE

			RELEASE json2SR
		ELSE
			IF EMPTY(sellorecepcion)
				loRetRespu.Status='ok'
				loRetRespu.Mensaje='Documento local sin sello de Hacienda'
				loRetRespu.comentario='Documento sin sello de recibido; no necesita validar con Hacienda y puede anularse localmente.'
			ELSE 
				loRetRespu.Mensaje='Configure en los Parametros la URL de consulta de DTE'
			ENDIF 
		ENDIF 
		*USE IN selloDTE
	ELSE
		loRetRespu.Mensaje='Imposible Realizar la consulta, falta informacion del DTE'	
	ENDIF 
	
	RETURN loRetRespu
ENDFUNC 




* ============================================================================
* Carga masiva DIPRO desde Excel usando la API de sincronizacion.
* Se mantiene en varios2.prg para no agregar PRG operativos nuevos.
* ============================================================================
FUNCTION ImportarPedidosExcelApi
	LPARAMETERS tcArchivo, toFormulario
	LOCAL lcArchivo, lcClave, lcUsuario, lcUrl, lcToken, lcResultado
	LOCAL lnLineas, lnPedidos, lnClientesNuevos, lnProductosNuevos, lnInvalidos, lnCargados, lnFallidos
	LOCAL llContinuar, llAutorizado, llTermino, loError, lnArea

	lcArchivo = FULLPATH(ALLTRIM(NVL(tcArchivo, "")))
	lnArea = SELECT()
	llTermino = .F.
	lcToken = ""
	lcResultado = ""

	IF EMPTY(lcArchivo) OR !FILE(lcArchivo)
		MESSAGEBOX("No se encontro el archivo Excel seleccionado.", 16, "Carga masiva de pedidos")
		RETURN .F.
	ENDIF
	IF LOWER(JUSTEXT(lcArchivo)) <> "xls"
		MESSAGEBOX("El archivo debe estar guardado en formato Excel 97-2003 (.xls).", 48, "Carga masiva de pedidos")
		RETURN .F.
	ENDIF
	IF TYPE("pcDB") <> "C" OR UPPER(ALLTRIM(pcDB)) <> "AGILSOFT_001_DIPRO"
		MESSAGEBOX("Esta carga por API esta habilitada solamente para la empresa DIPRO.", 48, "Carga masiva de pedidos")
		RETURN .F.
	ENDIF
	IF VARTYPE(toFormulario) <> "O" OR !PEMSTATUS(toFormulario, "txtClaveApi", 5)
		MESSAGEBOX("No esta disponible el campo de clave para autenticar la carga.", 16, "Carga masiva de pedidos")
		RETURN .F.
	ENDIF

	lcClave = ALLTRIM(TRANSFORM(toFormulario.txtClaveApi.Value))
	lcUsuario = IIF(TYPE("pcUsuario") = "C", ALLTRIM(pcUsuario), "")
	IF EMPTY(lcUsuario) OR EMPTY(lcClave)
		MESSAGEBOX("Escriba la clave del usuario actual de SIGA.", 48, "Carga masiva de pedidos")
		toFormulario.txtClaveApi.SetFocus()
		RETURN .F.
	ENDIF

	lcUrl = ApiPedidosUrlBase()
	ApiPedidosCerrarCursores()
	TRY
		ApiPedidosActualizarEstado(toFormulario, 3, "Leyendo y validando el archivo Excel...", "")
		ApiPedidosCrearCursores()
		IF !ApiPedidosLeerExcel(lcArchivo)
			ERROR "No se encontraron lineas DIPRO validas en el archivo."
		ENDIF
		ApiPedidosValidarLineas()
		SELECT c_ApiProductosNuevos
		COUNT TO lnProductosNuevos
		llContinuar = .T.
		IF lnProductosNuevos > 0
			ApiPedidosActualizarEstado(toFormulario, 15, "Productos nuevos detectados.", ;
				TRANSFORM(lnProductosNuevos) + " productos nuevos requieren autorizacion antes de cargar pedidos.")
			llContinuar = MESSAGEBOX("Productos nuevos: " + TRANSFORM(lnProductosNuevos) + CHR(13) + CHR(13) + ;
				"Autoriza crearlos en SIGA antes de cargar los pedidos?" + CHR(13) + ;
				"Los productos se confirmaran primero en transacciones independientes.", ;
				4 + 32 + 256, "Autorizar productos nuevos") = 6
			IF llContinuar
				ApiPedidosActualizarEstado(toFormulario, 17, "Autenticando para crear productos nuevos...", "")
				lcToken = ApiPedidosAutenticar(lcUrl, lcUsuario, lcClave)
				IF EMPTY(lcToken)
					ERROR "No fue posible autenticar el usuario en la API. Revise la clave y que la API este iniciada."
				ENDIF
				ApiPedidosCrearProductosDipro(lcUrl, lcToken, lcArchivo, toFormulario)

				* Los productos ya quedaron confirmados. Reconstruir la validacion
				* completa antes de mostrar o enviar cualquier pedido.
				ApiPedidosCerrarCursores()
				ApiPedidosCrearCursores()
				IF !ApiPedidosLeerExcel(lcArchivo)
					ERROR "No se pudo releer el archivo despues de crear los productos."
				ENDIF
				ApiPedidosValidarLineas()
				SELECT c_ApiProductosNuevos
				COUNT TO lnProductosNuevos
				IF lnProductosNuevos > 0
					ERROR "Quedaron productos nuevos sin confirmar. Vuelva a ejecutar la carga para revisar el resultado."
				ENDIF
			ELSE
				ApiPedidosActualizarEstado(toFormulario, 0, "Carga cancelada por el usuario.", ;
					"No se crearon productos ni se enviaron pedidos.")
			ENDIF
		ENDIF

		IF llContinuar
			ApiPedidosPrepararClientes()
			ApiPedidosPrepararEncabezados()

			SELECT c_ApiLineas
			COUNT TO lnLineas
			SELECT c_ApiPedidos
			COUNT TO lnPedidos
			COUNT FOR !valido TO lnInvalidos
			SELECT c_ApiClientes
			COUNT FOR nuevo AND valido TO lnClientesNuevos

			ApiPedidosActualizarEstado(toFormulario, 20, "Validacion terminada.", ;
				TRANSFORM(lnLineas) + " lineas, " + TRANSFORM(lnPedidos) + " pedidos, " + ;
				TRANSFORM(lnClientesNuevos) + " clientes nuevos, " + TRANSFORM(lnInvalidos) + " pedidos con problemas.")

			llContinuar = MESSAGEBOX("Archivo validado:" + CHR(13) + ;
				"Pedidos: " + TRANSFORM(lnPedidos) + CHR(13) + ;
				"Lineas: " + TRANSFORM(lnLineas) + CHR(13) + ;
				"Clientes nuevos: " + TRANSFORM(lnClientesNuevos) + CHR(13) + ;
				"Pedidos con problemas: " + TRANSFORM(lnInvalidos) + CHR(13) + CHR(13) + ;
				"Desea iniciar la carga por API?", 4 + 32 + 256, "Confirmar carga masiva") = 6

			IF llContinuar
				ApiPedidosActualizarEstado(toFormulario, 25, "Autenticando el usuario en la API...", "")
				IF EMPTY(lcToken)
					lcToken = ApiPedidosAutenticar(lcUrl, lcUsuario, lcClave)
				ENDIF
				IF EMPTY(lcToken)
					ERROR "No fue posible autenticar el usuario en la API. Revise la clave y que la API este iniciada."
				ENDIF

				IF lnClientesNuevos > 0
					ApiPedidosEnviarClientes(lcUrl, lcToken, toFormulario)
				ENDIF
				ApiPedidosAsignarClientes()
				ApiPedidosEnviarOrdenes(lcUrl, lcToken, toFormulario)
				ApiPedidosAgregarInvalidosAlResumen()
				lcResultado = ApiPedidosExportarResumen(lcArchivo)

				SELECT c_ApiResumen
				COUNT FOR tipo = "PEDIDO" AND estado = "CARGADO" TO lnCargados
				COUNT FOR tipo = "PEDIDO" AND estado <> "CARGADO" TO lnFallidos
				ApiPedidosActualizarEstado(toFormulario, 100, "Proceso finalizado.", ;
					"Pedidos cargados: " + TRANSFORM(lnCargados) + CHR(13) + ;
					"Pedidos no cargados: " + TRANSFORM(lnFallidos) + CHR(13) + ;
					"Ruta: " + ADDBS(JUSTPATH(lcResultado)) + CHR(13) + ;
					"Archivo: " + JUSTFNAME(lcResultado))
				toFormulario.cArchivoResultado = lcResultado
				IF lnFallidos > 0
					MESSAGEBOX("Carga finalizada con observaciones." + CHR(13) + ;
						"Cargados: " + TRANSFORM(lnCargados) + CHR(13) + ;
						"No cargados: " + TRANSFORM(lnFallidos) + CHR(13) + CHR(13) + ;
						"Ruta: " + ADDBS(JUSTPATH(lcResultado)) + CHR(13) + ;
						"Archivo: " + JUSTFNAME(lcResultado), 48, "Carga masiva de pedidos")
					ApiPedidosAbrirArchivo(lcResultado)
				ELSE
					MESSAGEBOX("Carga completada correctamente." + CHR(13) + ;
						"Pedidos cargados: " + TRANSFORM(lnCargados) + CHR(13) + CHR(13) + ;
						"Ruta: " + ADDBS(JUSTPATH(lcResultado)) + CHR(13) + ;
						"Archivo: " + JUSTFNAME(lcResultado), 64, "Carga masiva de pedidos")
				ENDIF
				llTermino = .T.
			ELSE
				ApiPedidosActualizarEstado(toFormulario, 0, "Carga cancelada por el usuario.", "No se envio ningun pedido.")
			ENDIF
		ENDIF
	CATCH TO loError
		ApiPedidosActualizarEstado(toFormulario, 0, "La carga no pudo completarse.", loError.Message)
		MESSAGEBOX("No se completo la carga:" + CHR(13) + loError.Message, 16, "Carga masiva de pedidos")
	FINALLY
		lcToken = ""
		lcClave = ""
		IF VARTYPE(toFormulario) = "O" AND PEMSTATUS(toFormulario, "txtClaveApi", 5)
			toFormulario.txtClaveApi.Value = ""
		ENDIF
		IF lnArea > 0
			SELECT (lnArea)
		ENDIF
	ENDTRY

	RETURN llTermino
ENDFUNC


FUNCTION ApiPedidosUrlBase
	LOCAL lcUrl, luValor
	lcUrl = "http://127.0.0.1:5088"
	IF TYPE("pcSysDir") = "C" AND TYPE("pcDB") = "C"
		luValor = _LeerIni(pcSysDir + pcDB + "\parametros.sys", "parametros", "SigaApiUrl")
		IF VARTYPE(luValor) = "C" AND !EMPTY(ALLTRIM(luValor))
			lcUrl = ALLTRIM(luValor)
		ENDIF
	ENDIF
	DO WHILE RIGHT(lcUrl, 1) = "/"
		lcUrl = LEFT(lcUrl, LEN(lcUrl) - 1)
	ENDDO
	RETURN lcUrl
ENDFUNC


PROCEDURE ApiPedidosCrearCursores
	CREATE CURSOR c_ApiXls (dipro C(20), fecha C(10), numero C(20), codclipro C(20), clipro C(200), nombrecli C(200), ;
		bblank1 C(20), direccion C(200), bblank2 C(20), bblank3 C(20), bblank4 C(20), bblank5 C(20), ;
		codprod C(20), producto C(200), unimed C(10), cantidadtexto C(25), cantddd N(18,6), cannet N(18,6), iva N(12,4), ;
		precno N(18,6), preciotexto C(25), premalo N(18,6), bbbla1 C(20), bbbla2 C(20), bbbla3 C(20), ;
		bbbla4 C(20), bbbla5 C(20), bbbla6 C(20), bbbla7 C(20), vendedor C(120), nada C(20), notaaf C(250))
	CREATE CURSOR c_ApiLineas (numero C(15), fecha D, codclipro C(20), clipro C(200), nombrecli C(200), direccion C(250), ;
		codprod C(20), producto C(200), idproducto I, cantidad N(18,6), precio N(18,6), total N(18,6), ;
		idagente I, vendedor C(120), notaaf C(250), valido L, error C(254))
	CREATE CURSOR c_ApiClientes (codclipro C(20), clipro C(200), nombre C(200), direccion C(250), idclipro I, ;
		nuevo L, valido L, error C(254), uid C(60), enviado L)
	CREATE CURSOR c_ApiPedidos (numero C(15), fecha D, codclipro C(20), idclipro I, idagente I, notaaf C(250), ;
		lineas I, total N(18,6), valido L, error C(254), uid C(60), enviado L)
	CREATE CURSOR c_ApiResumen (tipo C(12), numero C(20), codigo C(20), nombre C(120), fecha D, lineas I, ;
		total N(18,6), estado C(20), idservidor I, referencia C(30), mensaje C(254))
	CREATE CURSOR c_ApiProductosNuevos (codprod C(20), producto C(200), unimed C(20), precio N(18,6), iva N(12,4))
	SELECT c_ApiProductosNuevos
	INDEX ON UPPER(ALLTRIM(codprod)) TAG codprod
ENDPROC


FUNCTION ApiPedidosLeerExcel
	LPARAMETERS tcArchivo
	LOCAL lnFilas
	SELECT c_ApiXls
	APPEND FROM (tcArchivo) TYPE XL5
	DELETE ALL FOR UPPER(ALLTRIM(dipro)) <> "DIPRO"
	COUNT TO lnFilas
	RETURN lnFilas > 0
ENDFUNC


PROCEDURE ApiPedidosValidarLineas
	LOCAL lcNumero, lcCodCli, lcCodProd, lcVendedor, lcError, lcFecha
	LOCAL ldFecha, lnCantidad, lnTotal, lnPrecio, lnIdProducto, lnIdAgente, lnPos

	USE (pcSysDir + pcDB + "\invproductos") IN 0 SHARED AGAIN ALIAS c_ApiDbProd
	SELECT idproducto, ALLTRIM(codprod) AS codprod FROM c_ApiDbProd WHERE status = 1 INTO CURSOR c_ApiProductos READWRITE
	USE IN c_ApiDbProd
	SELECT c_ApiProductos
	INDEX ON UPPER(ALLTRIM(codprod)) TAG codprod

	USE (pcSysDir + pcDB + "\siscata") IN 0 SHARED AGAIN ALIAS c_ApiDbCat
	SELECT id, ALLTRIM(cod) AS cod FROM c_ApiDbCat WHERE UPPER(ALLTRIM(origen)) = "VEN" AND status = 1 INTO CURSOR c_ApiVendedores READWRITE
	USE IN c_ApiDbCat
	SELECT c_ApiVendedores
	INDEX ON id TAG id

	USE (pcSysDir + pcDB + "\cyvventas") IN 0 SHARED AGAIN ALIAS c_ApiDbVenta
	SELECT ALLTRIM(numero) AS numero FROM c_ApiDbVenta WHERE UPPER(ALLTRIM(origen)) = "VTP" INTO CURSOR c_ApiExistentes READWRITE
	USE IN c_ApiDbVenta
	SELECT c_ApiExistentes
	INDEX ON VAL(ALLTRIM(numero)) TAG numero

	SELECT c_ApiXls
	SCAN
		lcError = ""
		lcNumero = LEFT(ALLTRIM(solonumeros(c_ApiXls.numero)), 15)
		lcCodCli = LEFT(ALLTRIM(c_ApiXls.codclipro), 20)
		lcCodProd = LEFT(ALLTRIM(c_ApiXls.codprod), 20)
		lcFecha = ALLTRIM(c_ApiXls.fecha)
		ldFecha = {}
		IF LEN(lcFecha) >= 10
			ldFecha = DATE(VAL(SUBSTR(lcFecha, 1, 4)), VAL(SUBSTR(lcFecha, 6, 2)), VAL(SUBSTR(lcFecha, 9, 2)))
		ENDIF
		lnCantidad = VAL(STRTRAN(ALLTRIM(c_ApiXls.cantidadtexto), ",", ""))
		lnTotal = VAL(STRTRAN(ALLTRIM(c_ApiXls.preciotexto), ",", ""))
		lnPrecio = 0
		IF lnCantidad <> 0
			lnPrecio = lnTotal / lnCantidad
		ENDIF
		lnIdProducto = 0
		SELECT c_ApiProductos
		IF SEEK(UPPER(lcCodProd), "c_ApiProductos", "codprod")
			lnIdProducto = c_ApiProductos.idproducto
		ELSE
			lcError = ApiPedidosUnirError(lcError, "Producto no existe: " + lcCodProd)
			SELECT c_ApiProductosNuevos
			IF !EMPTY(lcCodProd) AND !SEEK(UPPER(lcCodProd), "c_ApiProductosNuevos", "codprod")
				INSERT INTO c_ApiProductosNuevos VALUES (lcCodProd, LEFT(ALLTRIM(c_ApiXls.producto), 200), ;
					LEFT(ALLTRIM(c_ApiXls.unimed), 20), lnPrecio, c_ApiXls.iva)
			ENDIF
		ENDIF
		lcVendedor = ALLTRIM(c_ApiXls.vendedor)
		lnPos = AT("-", lcVendedor)
		lnIdAgente = 0
		IF lnPos > 1
			lnIdAgente = VAL(LEFT(lcVendedor, lnPos - 1))
		ENDIF
		SELECT c_ApiVendedores
		IF lnIdAgente <= 0 OR !SEEK(lnIdAgente, "c_ApiVendedores", "id")
			lcError = ApiPedidosUnirError(lcError, "Vendedor no existe: " + TRANSFORM(lnIdAgente))
		ENDIF
		IF EMPTY(lcNumero)
			lcError = ApiPedidosUnirError(lcError, "Numero de pedido vacio")
		ENDIF
		IF EMPTY(lcCodCli)
			lcError = ApiPedidosUnirError(lcError, "Codigo de cliente vacio")
		ENDIF
		IF EMPTY(ldFecha)
			lcError = ApiPedidosUnirError(lcError, "Fecha invalida")
		ENDIF
		IF lnCantidad <= 0
			lcError = ApiPedidosUnirError(lcError, "Cantidad debe ser mayor que cero")
		ENDIF
		IF lnPrecio < 0
			lcError = ApiPedidosUnirError(lcError, "Precio invalido")
		ENDIF
		SELECT c_ApiLineas
		INSERT INTO c_ApiLineas VALUES (lcNumero, ldFecha, lcCodCli, LEFT(ALLTRIM(c_ApiXls.clipro), 200), ;
			LEFT(ALLTRIM(c_ApiXls.nombrecli), 200), LEFT(ALLTRIM(c_ApiXls.direccion), 250), lcCodProd, ;
			LEFT(ALLTRIM(c_ApiXls.producto), 200), lnIdProducto, lnCantidad, lnPrecio, lnTotal, lnIdAgente, ;
			LEFT(lcVendedor, 120), LEFT(ALLTRIM(c_ApiXls.notaaf), 250), EMPTY(lcError), LEFT(lcError, 254))
	ENDSCAN
	SELECT c_ApiLineas
	INDEX ON numero TAG numero
ENDPROC


PROCEDURE ApiPedidosCrearProductosDipro
	LPARAMETERS tcUrl, tcToken, tcArchivo, toFormulario
	LOCAL lcJson, loHttp, loJson, loDatos, lnSolicitados, lnCreados, lnExistentes, lnFallidos, loError

	ApiPedidosActualizarEstado(toFormulario, 18, "Creando productos nuevos...", ;
		"Esta etapa confirma cada producto por separado antes de cargar los pedidos.")
	lcJson = ApiPedidosJsonCrearProductosDipro(tcArchivo)
	loHttp = ApiPedidosHttp(tcUrl + "/api/pedidos/carga-masiva/crear-productos", lcJson, tcToken, "DIPRO")
	IF loHttp.status = 0
		ERROR "La conexion con la API se interrumpio mientras creaba los productos. Vuelva a ejecutar la carga; la API reconocera los productos ya confirmados. Detalle: " + loHttp.texto
	ENDIF
	IF loHttp.status < 200 OR loHttp.status >= 300
		ERROR ApiPedidosMensajeRespuesta(loHttp.texto, "No fue posible crear los productos nuevos")
	ENDIF

	TRY
		loJson = json_decode(loHttp.texto)
		loDatos = loJson.get("data")
		lnSolicitados = VAL(TRANSFORM(NVL(loDatos.get("requestedProducts"), 0)))
		lnCreados = VAL(TRANSFORM(NVL(loDatos.get("createdProducts"), 0)))
		lnExistentes = VAL(TRANSFORM(NVL(loDatos.get("existingProducts"), 0)))
		lnFallidos = VAL(TRANSFORM(NVL(loDatos.get("failedProducts"), 0)))
	CATCH TO loError
		ERROR "La API creo los productos, pero SIGA no pudo interpretar el resultado: " + loError.Message
	ENDTRY

	ApiPedidosActualizarEstado(toFormulario, 20, "Etapa de productos finalizada.", ;
		TRANSFORM(lnCreados) + " creados, " + TRANSFORM(lnExistentes) + " ya existentes y " + ;
		TRANSFORM(lnFallidos) + " con error.")
	IF lnFallidos > 0 OR lnCreados + lnExistentes < lnSolicitados
		ERROR "No se confirmaron todos los productos nuevos. Vuelva a ejecutar la carga para revisar solamente los pendientes."
	ENDIF
ENDPROC


FUNCTION ApiPedidosJsonCrearProductosDipro
	LPARAMETERS tcArchivo
	LOCAL lcFilas, lcCodigos, lcComaFila, lcComaCodigo, lcCodigo
	lcFilas = "["
	lcCodigos = "["
	lcComaFila = ""
	lcComaCodigo = ""

	SELECT c_ApiProductosNuevos
	SCAN
		lcCodigo = ALLTRIM(c_ApiProductosNuevos.codprod)
		lcCodigos = lcCodigos + lcComaCodigo + _JsonVentaTexto(lcCodigo)
		lcComaCodigo = ","
	ENDSCAN
	SELECT c_ApiXls
	SCAN
		lcCodigo = UPPER(ALLTRIM(c_ApiXls.codprod))
		IF !EMPTY(lcCodigo) AND SEEK(lcCodigo, "c_ApiProductosNuevos", "codprod")
			lcFilas = lcFilas + lcComaFila + ApiPedidosJsonFilaExcelDipro()
			lcComaFila = ","
		ENDIF
	ENDSCAN

	RETURN '{"branchId":' + TRANSFORM(pnIdSucursal) + ;
		',"defaultSellerId":0,"fileName":' + _JsonVentaTexto(JUSTFNAME(tcArchivo)) + ;
		',"formatId":"DIPRO","rows":' + lcFilas + '],"authorizedCustomerCodes":[]' + ;
		',"authorizedProductCodes":' + lcCodigos + "]}"
ENDFUNC


FUNCTION ApiPedidosJsonFilaExcelDipro
	LOCAL lcJson
	lcJson = "[" + _JsonVentaTexto(ALLTRIM(c_ApiXls.dipro)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.fecha)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.numero)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.codclipro)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.clipro)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.nombrecli)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.bblank1)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.direccion)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.bblank2)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.bblank3)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.bblank4)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.bblank5)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.codprod)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.producto)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.unimed)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.cantidadtexto)) + ;
		"," + _JsonVentaTexto(ALLTRIM(TRANSFORM(c_ApiXls.cantddd))) + ;
		"," + _JsonVentaTexto(ALLTRIM(TRANSFORM(c_ApiXls.cannet))) + ;
		"," + _JsonVentaTexto(ALLTRIM(TRANSFORM(c_ApiXls.iva))) + ;
		"," + _JsonVentaTexto(ALLTRIM(TRANSFORM(c_ApiXls.precno))) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.preciotexto)) + ;
		"," + _JsonVentaTexto(ALLTRIM(TRANSFORM(c_ApiXls.premalo))) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.bbbla1)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.bbbla2)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.bbbla3)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.bbbla4)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.bbbla5)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.bbbla6)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.bbbla7)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.vendedor)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.nada)) + ;
		"," + _JsonVentaTexto(ALLTRIM(c_ApiXls.notaaf)) + "]"
	RETURN lcJson
ENDFUNC


PROCEDURE ApiPedidosPrepararClientes
	LOCAL lcCodigo
	USE (pcSysDir + pcDB + "\cyvclipro") IN 0 SHARED AGAIN ALIAS c_ApiDbCli
	SELECT idclipro, ALLTRIM(codclipro) AS codclipro FROM c_ApiDbCli WHERE tipoclipro = 1 INTO CURSOR c_ApiClientesDb READWRITE
	USE IN c_ApiDbCli
	SELECT c_ApiClientesDb
	INDEX ON UPPER(ALLTRIM(codclipro)) TAG codclipro
	SELECT c_ApiClientes
	INDEX ON UPPER(ALLTRIM(codclipro)) TAG codclipro
	SELECT c_ApiLineas
	SCAN
		lcCodigo = ALLTRIM(c_ApiLineas.codclipro)
		IF !SEEK(UPPER(lcCodigo), "c_ApiClientes", "codclipro")
			SELECT c_ApiClientesDb
			IF SEEK(UPPER(lcCodigo), "c_ApiClientesDb", "codclipro")
				INSERT INTO c_ApiClientes VALUES (lcCodigo, c_ApiLineas.clipro, c_ApiLineas.nombrecli, c_ApiLineas.direccion, ;
					c_ApiClientesDb.idclipro, .F., .T., "", "", .T.)
			ELSE
				INSERT INTO c_ApiClientes VALUES (lcCodigo, c_ApiLineas.clipro, c_ApiLineas.nombrecli, c_ApiLineas.direccion, ;
					0, .T., !EMPTY(lcCodigo) AND !EMPTY(c_ApiLineas.clipro), ;
					IIF(EMPTY(c_ApiLineas.clipro), "Nombre de cliente vacio", ""), ;
					ApiPedidosUid("CLI", lcCodigo), .F.)
			ENDIF
		ENDIF
	ENDSCAN
ENDPROC


PROCEDURE ApiPedidosPrepararEncabezados
	LOCAL lcNumero, lcError, lcCodCli, ldFecha, lnIdAgente
	SELECT c_ApiPedidos
	INDEX ON numero TAG numero
	SELECT c_ApiLineas
	SCAN
		lcNumero = c_ApiLineas.numero
		IF !SEEK(lcNumero, "c_ApiPedidos", "numero")
			INSERT INTO c_ApiPedidos VALUES (lcNumero, c_ApiLineas.fecha, c_ApiLineas.codclipro, 0, c_ApiLineas.idagente, ;
				c_ApiLineas.notaaf, 0, 0, .T., "", ApiPedidosUid("PED", DTOC(c_ApiLineas.fecha, 1) + "-" + lcNumero), .F.)
		ENDIF
		SELECT c_ApiPedidos
		=SEEK(lcNumero, "c_ApiPedidos", "numero")
		lcError = c_ApiPedidos.error
		IF c_ApiLineas.fecha <> c_ApiPedidos.fecha
			lcError = ApiPedidosUnirError(lcError, "El pedido tiene fechas diferentes")
		ENDIF
		IF c_ApiLineas.codclipro <> c_ApiPedidos.codclipro
			lcError = ApiPedidosUnirError(lcError, "El pedido tiene clientes diferentes")
		ENDIF
		IF c_ApiLineas.idagente <> c_ApiPedidos.idagente
			lcError = ApiPedidosUnirError(lcError, "El pedido tiene vendedores diferentes")
		ENDIF
		IF !c_ApiLineas.valido
			lcError = ApiPedidosUnirError(lcError, c_ApiLineas.error)
		ENDIF
		SELECT c_ApiExistentes
		IF SEEK(VAL(lcNumero), "c_ApiExistentes", "numero")
			lcError = ApiPedidosUnirError(lcError, "El numero de pedido ya existe en SIGA")
		ENDIF
		SELECT c_ApiPedidos
		REPLACE lineas WITH lineas + 1, total WITH total + c_ApiLineas.total, ;
			error WITH LEFT(lcError, 254), valido WITH EMPTY(lcError)
	ENDSCAN
	ApiPedidosAsignarClientes()
ENDPROC


PROCEDURE ApiPedidosAsignarClientes
	LOCAL lcError
	SELECT c_ApiPedidos
	SCAN
		lcError = c_ApiPedidos.error
		SELECT c_ApiClientes
		IF SEEK(UPPER(ALLTRIM(c_ApiPedidos.codclipro)), "c_ApiClientes", "codclipro")
			SELECT c_ApiPedidos
			REPLACE idclipro WITH c_ApiClientes.idclipro
			IF c_ApiClientes.idclipro <= 0 AND (!c_ApiClientes.nuevo OR c_ApiClientes.enviado)
				lcError = ApiPedidosUnirError(lcError, IIF(EMPTY(c_ApiClientes.error), "Cliente no disponible", c_ApiClientes.error))
			ENDIF
		ELSE
			SELECT c_ApiPedidos
			lcError = ApiPedidosUnirError(lcError, "Cliente no resuelto")
		ENDIF
		SELECT c_ApiPedidos
		REPLACE error WITH LEFT(lcError, 254), valido WITH EMPTY(lcError)
	ENDSCAN
ENDPROC


FUNCTION ApiPedidosAutenticar
	LPARAMETERS tcUrl, tcUsuario, tcClave
	LOCAL lcJson, lcToken, loHttp, loJson, loDatos, loError
	lcToken = ""
	lcJson = "{" + '"tenant":"DIPRO","username":' + _JsonVentaTexto(tcUsuario) + ;
		',"password":' + _JsonVentaTexto(tcClave) + ',"deviceId":' + _JsonVentaTexto(ApiPedidosDispositivo()) + ;
		',"deviceName":"SIGA ERP","platform":"vfp-erp","appVersion":"1.0"}'
	loHttp = ApiPedidosHttp(tcUrl + "/api/auth/login", lcJson, "", "DIPRO")
	IF loHttp.status >= 200 AND loHttp.status < 300
		TRY
			loJson = json_decode(loHttp.texto)
			loDatos = loJson.get("data")
			lcToken = ALLTRIM(NVL(loDatos.get("accessToken"), ""))
		CATCH TO loError
			lcToken = ""
		ENDTRY
	ELSE
		ERROR ApiPedidosMensajeRespuesta(loHttp.texto, "HTTP " + TRANSFORM(loHttp.status) + " al autenticar")
	ENDIF
	RETURN lcToken
ENDFUNC


PROCEDURE ApiPedidosEnviarClientes
	LPARAMETERS tcUrl, tcToken, toFormulario
	LOCAL lnTotal, lnHechos, lnInicio, lnCantidad, lcJson, loHttp
	SELECT c_ApiClientes
	COUNT FOR nuevo AND valido AND !enviado TO lnTotal
	lnHechos = 0
	DO WHILE lnHechos < lnTotal
		lcJson = ApiPedidosJsonLoteClientes(50, @lnCantidad)
		IF lnCantidad <= 0
			EXIT
		ENDIF
		loHttp = ApiPedidosHttp(tcUrl + "/api/sync/push", lcJson, tcToken, "DIPRO")
		IF loHttp.status < 200 OR loHttp.status >= 300
			ERROR ApiPedidosMensajeRespuesta(loHttp.texto, "Fallo el envio de clientes")
		ENDIF
		ApiPedidosProcesarRespuesta(loHttp.texto, "CUSTOMER")
		lnHechos = lnHechos + lnCantidad
		ApiPedidosActualizarEstado(toFormulario, 25 + INT(15 * lnHechos / MAX(1, lnTotal)), ;
			"Creando clientes nuevos...", TRANSFORM(lnHechos) + " de " + TRANSFORM(lnTotal))
	ENDDO
ENDPROC


FUNCTION ApiPedidosJsonLoteClientes
	LPARAMETERS tnMaximo, tnCantidad
	LOCAL lcOps, lcComa, lcUid, lnCont
	tnCantidad = 0
	lcOps = "["
	lcComa = ""
	lnCont = 0
	SELECT c_ApiClientes
	SCAN FOR nuevo AND valido AND !enviado
		lcOps = lcOps + lcComa + ApiPedidosJsonCliente()
		lcComa = ","
		REPLACE enviado WITH .T.
		lnCont = lnCont + 1
		IF lnCont >= tnMaximo
			EXIT
		ENDIF
	ENDSCAN
	tnCantidad = lnCont
	RETURN '{"deviceId":' + _JsonVentaTexto(ApiPedidosDispositivo()) + ;
		',"batchUid":' + _JsonVentaTexto(LEFT(ApiPedidosUid("BCL", TTOC(DATETIME(), 1) + SYS(2015)), 36)) + ;
		',"deviceName":"SIGA ERP","platform":"vfp-erp","appVersion":"1.0","operations":' + lcOps + "]}"
ENDFUNC


FUNCTION ApiPedidosJsonCliente
	LOCAL lcNombre, lcLegal
	lcNombre = ALLTRIM(c_ApiClientes.clipro)
	lcLegal = ALLTRIM(c_ApiClientes.nombre)
	IF EMPTY(lcLegal)
		lcLegal = lcNombre
	ENDIF
	RETURN '{"clientUid":' + _JsonVentaTexto(c_ApiClientes.uid) + ;
		',"entity":"CUSTOMER","action":"CREATE","payload":{' + ;
		'"code":' + _JsonVentaTexto(c_ApiClientes.codclipro) + ;
		',"displayName":' + _JsonVentaTexto(lcNombre) + ;
		',"legalName":' + _JsonVentaTexto(lcLegal) + ;
		',"address":' + _JsonVentaTexto(ALLTRIM(c_ApiClientes.direccion)) + ;
		',"mobile":"7000-0000","email":"noenviar@gmail.com"' + ;
		',"customerType":1,"branchId":' + TRANSFORM(pnIdSucursal) + ;
		',"groupId":261,"departmentId":1106,"municipalityId":10518' + ;
		',"contributorType":1,"vatType":1,"paymentCondition":0,"personType":1' + ;
		',"domiciledCode":1,"countryCode":"SV","isActive":true}}'
ENDFUNC


PROCEDURE ApiPedidosEnviarOrdenes
	LPARAMETERS tcUrl, tcToken, toFormulario
	LOCAL lnTotal, lnHechos, lnCantidad, lcJson, loHttp
	SELECT c_ApiPedidos
	COUNT FOR valido AND !enviado TO lnTotal
	lnHechos = 0
	DO WHILE lnHechos < lnTotal
		* Cada pedido viaja en una solicitud corta. Crear 25 pedidos reales en una
		* sola peticion puede superar el tiempo del proxy/VPS y MSXML informa que
		* el servidor finalizo la conexion aunque la API siga procesando el lote.
		lcJson = ApiPedidosJsonLoteOrdenes(1, @lnCantidad)
		IF lnCantidad <= 0
			EXIT
		ENDIF
		loHttp = ApiPedidosHttp(tcUrl + "/api/sync/push", lcJson, tcToken, "DIPRO")
		IF loHttp.status = 0
			ERROR "La conexion con la API se interrumpio mientras procesaba el pedido. Espere un minuto y vuelva a ejecutar la carga; SIGA reconocera los pedidos ya recibidos. Detalle: " + loHttp.texto
		ENDIF
		IF loHttp.status < 200 OR loHttp.status >= 300
			ERROR ApiPedidosMensajeRespuesta(loHttp.texto, "Fallo el envio de pedidos")
		ENDIF
		ApiPedidosProcesarRespuesta(loHttp.texto, "ORDER")
		lnHechos = lnHechos + lnCantidad
		ApiPedidosActualizarEstado(toFormulario, 40 + INT(55 * lnHechos / MAX(1, lnTotal)), ;
			"Cargando pedidos uno por uno...", TRANSFORM(lnHechos) + " de " + TRANSFORM(lnTotal))
	ENDDO
ENDPROC


FUNCTION ApiPedidosJsonLoteOrdenes
	LPARAMETERS tnMaximo, tnCantidad
	LOCAL lcOps, lcComa, lnCont
	tnCantidad = 0
	lcOps = "["
	lcComa = ""
	lnCont = 0
	SELECT c_ApiPedidos
	SCAN FOR valido AND !enviado
		lcOps = lcOps + lcComa + ApiPedidosJsonPedido()
		lcComa = ","
		REPLACE enviado WITH .T.
		lnCont = lnCont + 1
		IF lnCont >= tnMaximo
			EXIT
		ENDIF
	ENDSCAN
	tnCantidad = lnCont
	RETURN '{"deviceId":' + _JsonVentaTexto(ApiPedidosDispositivo()) + ;
		',"batchUid":' + _JsonVentaTexto(LEFT(ApiPedidosUid("BPE", TTOC(DATETIME(), 1) + SYS(2015)), 36)) + ;
		',"deviceName":"SIGA ERP","platform":"vfp-erp","appVersion":"1.0","operations":' + lcOps + "]}"
ENDFUNC


FUNCTION ApiPedidosJsonPedido
	LOCAL lcLineas, lcComa, lcNotas, lcNumero, lcUid, lcFecha, lnCliente, lnAgente, lnRecno
	lnRecno = RECNO("c_ApiPedidos")
	lcNumero = c_ApiPedidos.numero
	lcUid = c_ApiPedidos.uid
	lcFecha = c_ApiPedidos.fecha
	lnCliente = c_ApiPedidos.idclipro
	lnAgente = c_ApiPedidos.idagente
	lcLineas = "["
	lcComa = ""
	SELECT c_ApiLineas
	SCAN FOR numero = lcNumero
		lcLineas = lcLineas + lcComa + '{"productId":' + TRANSFORM(c_ApiLineas.idproducto) + ;
			',"quantity":' + _JsonVentaNumero(c_ApiLineas.cantidad, 6) + ;
			',"unitPriceWithVat":' + _JsonVentaNumero(c_ApiLineas.precio, 6) + ;
			',"useCatalogPriceCalculation":false,"lineSellerId":' + TRANSFORM(c_ApiLineas.idagente) + "}"
		lcComa = ","
	ENDSCAN
	lcLineas = lcLineas + "]"
	SELECT c_ApiPedidos
	GO lnRecno
	lcNotas = "Pedido No. " + ALLTRIM(lcNumero)
	IF !EMPTY(ALLTRIM(c_ApiPedidos.notaaf))
		lcNotas = lcNotas + " - " + ALLTRIM(c_ApiPedidos.notaaf)
	ENDIF
	RETURN '{"clientUid":' + _JsonVentaTexto(lcUid) + ;
		',"entity":"ORDER","action":"CREATE","payload":{' + ;
		'"customerId":' + TRANSFORM(lnCliente) + ;
		',"documentDate":' + _JsonVentaFecha(lcFecha) + ;
		',"number":' + _JsonVentaTexto(lcNumero) + ;
		',"branchId":' + TRANSFORM(pnIdSucursal) + ;
		',"agentId":' + TRANSFORM(lnAgente) + ;
		',"paymentCondition":0,"notes":' + _JsonVentaTexto(LEFT(lcNotas, 250)) + ;
		',"lines":' + lcLineas + "}}"
ENDFUNC


PROCEDURE ApiPedidosProcesarRespuesta
	LPARAMETERS tcRespuesta, tcEntidad
	LOCAL loJson, loDatos, loOps, loOp, lnI, lcUid, lcEstado, lcMensaje, lcRef, lnId, loError
	TRY
		loJson = json_decode(tcRespuesta)
		loDatos = loJson.get("data")
		loOps = loDatos.get("operations")
		FOR lnI = 1 TO loOps.getsize()
			loOp = loOps.get(lnI)
			lcUid = ALLTRIM(NVL(loOp.get("clientUid"), ""))
			lcEstado = LOWER(ALLTRIM(NVL(loOp.get("status"), "")))
			lcMensaje = LEFT(ALLTRIM(NVL(loOp.get("message"), "")), 254)
			lnId = VAL(TRANSFORM(NVL(loOp.get("serverId"), 0)))
			lcRef = LEFT(ALLTRIM(TRANSFORM(NVL(loOp.get("serverRef"), ""))), 30)
			IF UPPER(tcEntidad) = "CUSTOMER"
				SELECT c_ApiClientes
				LOCATE FOR uid = lcUid
				IF FOUND("c_ApiClientes")
					SELECT c_ApiClientes
					IF lcEstado = "synced"
						REPLACE idclipro WITH lnId, valido WITH lnId > 0, error WITH IIF(lnId > 0, "", "La API no devolvio el ID del cliente")
					ELSE
						REPLACE valido WITH .F., error WITH lcMensaje
					ENDIF
					INSERT INTO c_ApiResumen VALUES ("CLIENTE", "", c_ApiClientes.codclipro, LEFT(c_ApiClientes.clipro, 120), {}, 0, 0, ;
						IIF(lcEstado = "synced", "CREADO", "NO CREADO"), lnId, lcRef, lcMensaje)
				ENDIF
			ELSE
				SELECT c_ApiPedidos
				LOCATE FOR uid = lcUid
				IF FOUND("c_ApiPedidos")
					SELECT c_ApiPedidos
					INSERT INTO c_ApiResumen VALUES ("PEDIDO", c_ApiPedidos.numero, c_ApiPedidos.codclipro, "", ;
						c_ApiPedidos.fecha, c_ApiPedidos.lineas, c_ApiPedidos.total, ;
						IIF(lcEstado = "synced", "CARGADO", "NO CARGADO"), lnId, lcRef, lcMensaje)
				ENDIF
			ENDIF
		ENDFOR
	CATCH TO loError
		ERROR "La API devolvio una respuesta que no se pudo interpretar: " + loError.Message
	ENDTRY
ENDPROC


PROCEDURE ApiPedidosAgregarInvalidosAlResumen
	SELECT c_ApiPedidos
	SCAN FOR !valido
		IF !ApiPedidosResumenExiste("PEDIDO", c_ApiPedidos.numero)
		INSERT INTO c_ApiResumen VALUES ("PEDIDO", c_ApiPedidos.numero, c_ApiPedidos.codclipro, "", ;
			c_ApiPedidos.fecha, c_ApiPedidos.lineas, c_ApiPedidos.total, ;
			"NO CARGADO", 0, "", LEFT(c_ApiPedidos.error, 254))
		ENDIF
	ENDSCAN
ENDPROC


FUNCTION ApiPedidosResumenExiste
	LPARAMETERS tcTipo, tcNumero
	LOCAL lnRecno, llExiste
	lnRecno = RECNO("c_ApiResumen")
	SELECT c_ApiResumen
	LOCATE FOR tipo = tcTipo AND numero = tcNumero
	llExiste = FOUND("c_ApiResumen")
	IF lnRecno > 0 AND lnRecno <= RECCOUNT("c_ApiResumen")
		GO lnRecno IN c_ApiResumen
	ENDIF
	RETURN llExiste
ENDFUNC


FUNCTION ApiPedidosExportarResumen
	LPARAMETERS tcArchivo
	LOCAL lcSalida
	lcSalida = ADDBS(JUSTPATH(tcArchivo)) + JUSTSTEM(tcArchivo) + "_STATUS_" + ;
		DTOS(DATE()) + "_" + STRTRAN(TIME(), ":", "") + ".xls"
	SELECT tipo, numero, codigo, nombre, fecha, lineas, total, estado, idservidor, referencia, mensaje ;
		FROM c_ApiResumen ORDER BY tipo, numero INTO CURSOR c_ApiExport READWRITE
	SELECT c_ApiExport
	COPY TO (lcSalida) TYPE XL5
	USE IN c_ApiExport
	RETURN lcSalida
ENDFUNC


FUNCTION ApiPedidosHttp
	LPARAMETERS tcUrl, tcJson, tcToken, tcTenant
	LOCAL loRet, loHttp, loError
	loRet = CREATEOBJECT("Empty")
	ADDPROPERTY(loRet, "status", 0)
	ADDPROPERTY(loRet, "texto", "")
	TRY
		loHttp = CREATEOBJECT("MSXML2.ServerXMLHTTP.6.0")
		loHttp.setTimeouts(10000, 10000, 30000, 180000)
		loHttp.Open("POST", tcUrl, .F.)
		loHttp.setRequestHeader("Content-Type", "application/json; charset=utf-8")
		loHttp.setRequestHeader("Accept", "application/json")
		IF !EMPTY(tcTenant)
			loHttp.setRequestHeader("X-Siga-Tenant", tcTenant)
		ENDIF
		IF !EMPTY(tcToken)
			loHttp.setRequestHeader("Authorization", "Bearer " + tcToken)
		ENDIF
		loHttp.Send(ApiPedidosUtf8(tcJson))
		loRet.status = loHttp.Status
		loRet.texto = ApiPedidosLeerUtf8(loHttp.responseBody)
	CATCH TO loError
		loRet.status = 0
		loRet.texto = loError.Message
	ENDTRY
	RETURN loRet
ENDFUNC


FUNCTION ApiPedidosUtf8
	LPARAMETERS tcTexto
	LOCAL loStream, luBytes
	loStream = CREATEOBJECT("ADODB.Stream")
	loStream.Type = 2
	loStream.Charset = "utf-8"
	loStream.Open()
	loStream.WriteText(tcTexto)
	loStream.Position = 0
	loStream.Type = 1
	loStream.Position = 3
	luBytes = loStream.Read()
	loStream.Close()
	RETURN luBytes
ENDFUNC


FUNCTION ApiPedidosLeerUtf8
	LPARAMETERS tuBytes
	LOCAL loStream, lcTexto
	loStream = CREATEOBJECT("ADODB.Stream")
	loStream.Type = 1
	loStream.Open()
	loStream.Write(tuBytes)
	loStream.Position = 0
	loStream.Type = 2
	loStream.Charset = "utf-8"
	lcTexto = loStream.ReadText()
	loStream.Close()
	RETURN lcTexto
ENDFUNC


FUNCTION ApiPedidosMensajeRespuesta
	LPARAMETERS tcRespuesta, tcPredeterminado
	LOCAL lcMensaje, loJson, loErrorObj, loError
	lcMensaje = tcPredeterminado
	TRY
		loJson = json_decode(tcRespuesta)
		loErrorObj = loJson.get("error")
		IF VARTYPE(loErrorObj) = "O"
			lcMensaje = ALLTRIM(NVL(loErrorObj.get("message"), lcMensaje))
		ENDIF
	CATCH TO loError
		IF !EMPTY(ALLTRIM(tcRespuesta))
			lcMensaje = LEFT(ALLTRIM(tcRespuesta), 500)
		ENDIF
	ENDTRY
	RETURN lcMensaje
ENDFUNC


PROCEDURE ApiPedidosActualizarEstado
	LPARAMETERS toFormulario, tnPorcentaje, tcEstado, tcDetalle
	LOCAL lnPorcentaje
	IF VARTYPE(toFormulario) <> "O"
		RETURN
	ENDIF
	lnPorcentaje = MAX(0, MIN(100, NVL(tnPorcentaje, 0)))
	toFormulario.nProgreso = lnPorcentaje
	IF PEMSTATUS(toFormulario, "lblEstadoCarga", 5)
		toFormulario.lblEstadoCarga.Caption = tcEstado
	ENDIF
	IF PEMSTATUS(toFormulario, "lblPorcentaje", 5)
		toFormulario.lblPorcentaje.Caption = TRANSFORM(lnPorcentaje) + "%"
	ENDIF
	IF PEMSTATUS(toFormulario, "shpProgreso", 5)
		toFormulario.shpProgreso.Width = MAX(1, INT((toFormulario.shpProgresoFondo.Width - 2) * lnPorcentaje / 100))
	ENDIF
	IF !EMPTY(NVL(tcDetalle, "")) AND PEMSTATUS(toFormulario, "Edt1", 5)
		IF EMPTY(toFormulario.Edt1.Value)
			toFormulario.Edt1.Value = tcDetalle
		ELSE
			toFormulario.Edt1.Value = toFormulario.Edt1.Value + CHR(13) + tcDetalle
		ENDIF
		toFormulario.Edt1.SelStart = LEN(toFormulario.Edt1.Value)
	ENDIF
	DOEVENTS
ENDPROC


FUNCTION ApiPedidosUid
	LPARAMETERS tcPrefijo, tcValor
	LOCAL lcValor
	lcValor = UPPER(ALLTRIM(NVL(tcValor, "")))
	lcValor = CHRTRAN(lcValor, " /\:.-", "______")
	RETURN LEFT(UPPER(tcPrefijo) + "-DIPRO-" + lcValor, 60)
ENDFUNC


FUNCTION ApiPedidosDispositivo
	RETURN LEFT("SIGA-VFP-" + UPPER(SYS(0)), 100)
ENDFUNC


FUNCTION ApiPedidosUnirError
	LPARAMETERS tcActual, tcNuevo
	LOCAL lcResultado
	lcResultado = ALLTRIM(NVL(tcActual, ""))
	IF !EMPTY(ALLTRIM(NVL(tcNuevo, ""))) AND !(ALLTRIM(tcNuevo) $ lcResultado)
		lcResultado = lcResultado + IIF(EMPTY(lcResultado), "", "; ") + ALLTRIM(tcNuevo)
	ENDIF
	RETURN LEFT(lcResultado, 254)
ENDFUNC


PROCEDURE ApiPedidosAbrirArchivo
	LPARAMETERS tcArchivo
	IF FILE(tcArchivo)
		DECLARE INTEGER ShellExecute IN shell32.dll INTEGER, STRING, STRING, STRING, STRING, INTEGER
		ShellExecute(0, "open", tcArchivo, "", JUSTPATH(tcArchivo), 1)
	ENDIF
ENDPROC


PROCEDURE ApiPedidosCerrarCursores
	LOCAL ARRAY laApi(1)
	LOCAL lnI, lnTotal
	lnTotal = AUSED(laApi)
	FOR lnI = 1 TO lnTotal
		IF UPPER(LEFT(laApi[lnI, 1], 5)) = "C_API"
			USE IN (laApi[lnI, 1])
		ENDIF
	ENDFOR
ENDPROC

* Credenciales del login almacenadas por Windows para el usuario actual.
* La clave nunca se escribe en INI, DBF ni archivos propios de SIGA.
FUNCTION NombreCredencialLoginWindows
	LPARAMETERS tnIdEmpresa, tcEmpresaDB, tcUsuario
	LOCAL lcIdentidad, lcHash
	lcIdentidad = LOWER(ALLTRIM(TRANSFORM(NVL(tnIdEmpresa, 0)))) + "|" + ;
		LOWER(ALLTRIM(NVL(tcEmpresaDB, ""))) + "|" + ;
		LOWER(ALLTRIM(NVL(tcUsuario, "")))
	lcHash = LOWER(STRCONV(Hash(lcIdentidad, 1), 15))
	RETURN "AgilSoft.SIGA.Login." + lcHash
ENDFUNC


FUNCTION GuardarClaveLoginWindows
	LPARAMETERS tnIdEmpresa, tcEmpresaDB, tcUsuario, tcClave
	LOCAL lcDestino
	IF EMPTY(ALLTRIM(NVL(tcEmpresaDB, ""))) OR ;
		EMPTY(ALLTRIM(NVL(tcUsuario, ""))) OR EMPTY(NVL(tcClave, ""))
		RETURN .F.
	ENDIF
	lcDestino = NombreCredencialLoginWindows(tnIdEmpresa, tcEmpresaDB, tcUsuario)
	RETURN CredencialWindowsGuardar(lcDestino, ALLTRIM(tcUsuario), tcClave)
ENDFUNC


FUNCTION LeerClaveLoginWindows
	LPARAMETERS tnIdEmpresa, tcEmpresaDB, tcUsuario
	LOCAL lcDestino
	IF EMPTY(ALLTRIM(NVL(tcEmpresaDB, ""))) OR EMPTY(ALLTRIM(NVL(tcUsuario, "")))
		RETURN ""
	ENDIF
	lcDestino = NombreCredencialLoginWindows(tnIdEmpresa, tcEmpresaDB, tcUsuario)
	RETURN CredencialWindowsLeer(lcDestino)
ENDFUNC


FUNCTION EliminarClaveLoginWindows
	LPARAMETERS tnIdEmpresa, tcEmpresaDB, tcUsuario
	LOCAL lcDestino
	IF EMPTY(ALLTRIM(NVL(tcEmpresaDB, ""))) OR EMPTY(ALLTRIM(NVL(tcUsuario, "")))
		RETURN .T.
	ENDIF
	lcDestino = NombreCredencialLoginWindows(tnIdEmpresa, tcEmpresaDB, tcUsuario)
	RETURN CredencialWindowsEliminar(lcDestino)
ENDFUNC


FUNCTION CredencialWindowsGuardar
	LPARAMETERS tcDestino, tcUsuario, tcSecreto
	LOCAL lnDestino, lnUsuario, lnSecreto, lnTamSecreto, lcCredencial, llResultado
	STORE 0 TO lnDestino, lnUsuario, lnSecreto, lnTamSecreto
	llResultado = .F.

	DECLARE INTEGER GlobalAlloc IN kernel32 INTEGER uFlags, INTEGER dwBytes
	DECLARE INTEGER GlobalFree IN kernel32 INTEGER hMem
	DECLARE INTEGER CredWriteA IN advapi32 STRING @Credential, INTEGER Flags

	TRY
		lnTamSecreto = LEN(tcSecreto)
		lnDestino = GlobalAlloc(64, LEN(tcDestino) + 1)
		lnUsuario = GlobalAlloc(64, LEN(tcUsuario) + 1)
		lnSecreto = GlobalAlloc(64, MAX(1, lnTamSecreto))
		IF lnDestino <> 0 AND lnUsuario <> 0 AND lnSecreto <> 0
			=SYS(2600, lnDestino, LEN(tcDestino) + 1, tcDestino + CHR(0))
			=SYS(2600, lnUsuario, LEN(tcUsuario) + 1, tcUsuario + CHR(0))
			=SYS(2600, lnSecreto, lnTamSecreto, tcSecreto)

			* CREDENTIALA de 32 bits: CRED_TYPE_GENERIC y persistencia local.
			lcCredencial = BINTOC(0, "4RS") + BINTOC(1, "4RS") + ;
				BINTOC(lnDestino, "4RS") + BINTOC(0, "4RS") + ;
				REPLICATE(CHR(0), 8) + BINTOC(lnTamSecreto, "4RS") + ;
				BINTOC(lnSecreto, "4RS") + BINTOC(2, "4RS") + ;
				BINTOC(0, "4RS") + BINTOC(0, "4RS") + ;
				BINTOC(0, "4RS") + BINTOC(lnUsuario, "4RS")
			llResultado = CredWriteA(@lcCredencial, 0) <> 0
		ENDIF
	CATCH
		llResultado = .F.
	FINALLY
		IF lnSecreto <> 0
			=SYS(2600, lnSecreto, MAX(1, lnTamSecreto), REPLICATE(CHR(0), MAX(1, lnTamSecreto)))
			=GlobalFree(lnSecreto)
		ENDIF
		IF lnUsuario <> 0
			=GlobalFree(lnUsuario)
		ENDIF
		IF lnDestino <> 0
			=GlobalFree(lnDestino)
		ENDIF
	ENDTRY
	RETURN llResultado
ENDFUNC


FUNCTION CredencialWindowsLeer
	LPARAMETERS tcDestino
	LOCAL lnCredencial, lcCredencial, lnTamSecreto, lnSecreto, lcResultado
	STORE 0 TO lnCredencial, lnTamSecreto, lnSecreto
	lcResultado = ""

	DECLARE INTEGER CredReadA IN advapi32 STRING TargetName, INTEGER Type, ;
		INTEGER Flags, INTEGER @Credential
	DECLARE INTEGER CredFree IN advapi32 INTEGER Buffer

	TRY
		IF CredReadA(tcDestino, 1, 0, @lnCredencial) <> 0 AND lnCredencial <> 0
			lcCredencial = SYS(2600, lnCredencial, 52)
			lnTamSecreto = CTOBIN(SUBSTR(lcCredencial, 25, 4), "4RS")
			lnSecreto = CTOBIN(SUBSTR(lcCredencial, 29, 4), "4RS")
			IF lnTamSecreto > 0 AND lnSecreto <> 0
				lcResultado = SYS(2600, lnSecreto, lnTamSecreto)
				=SYS(2600, lnSecreto, lnTamSecreto, REPLICATE(CHR(0), lnTamSecreto))
			ENDIF
		ENDIF
	CATCH
		lcResultado = ""
	FINALLY
		IF lnCredencial <> 0
			=CredFree(lnCredencial)
		ENDIF
	ENDTRY
	RETURN lcResultado
ENDFUNC


FUNCTION CredencialWindowsEliminar
	LPARAMETERS tcDestino
	LOCAL lnResultado, lnError
	DECLARE INTEGER CredDeleteA IN advapi32 STRING TargetName, INTEGER Type, INTEGER Flags
	DECLARE INTEGER GetLastError IN kernel32
	lnResultado = CredDeleteA(tcDestino, 1, 0)
	IF lnResultado <> 0
		RETURN .T.
	ENDIF
	lnError = GetLastError()
	* ERROR_NOT_FOUND significa que ya no habia nada que eliminar.
	RETURN lnError = 1168
ENDFUNC


PROCEDURE CargarClaveLoginRecordada
	LPARAMETERS toFormulario, tlCargarUltimoUsuario
	LOCAL lnAreaAnterior, lnIdEmpresa, lcEmpresaDB, lcUsuario, lcClave, lcSeccion, lcCursorEmpresa
	IF VARTYPE(toFormulario) <> "O" OR !PEMSTATUS(toFormulario, "grd1", 5)
		RETURN
	ENDIF
	lcCursorEmpresa = ALLTRIM(toFormulario.grd1.RecordSource)
	IF EMPTY(lcCursorEmpresa) OR !USED(lcCursorEmpresa)
		RETURN
	ENDIF
	lnAreaAnterior = SELECT()
	SELECT (lcCursorEmpresa)
	IF EOF()
		IF lnAreaAnterior > 0
			SELECT (lnAreaAnterior)
		ENDIF
		RETURN
	ENDIF
	lnIdEmpresa = EVALUATE(lcCursorEmpresa + ".idempresa")
	lcEmpresaDB = ALLTRIM(EVALUATE(lcCursorEmpresa + ".empresadb"))
	lcUsuario = ALLTRIM(toFormulario.txtUsuario.Value)
	IF tlCargarUltimoUsuario
		lcSeccion = "loginempresa_" + ALLTRIM(STR(lnIdEmpresa))
		STORE _LeerIni(pcFileUltimoAcceso, lcSeccion, "usuario") TO lcUsuario
		IF ISNULL(lcUsuario)
			lcUsuario = ""
		ENDIF
		toFormulario.txtUsuario.Value = lcUsuario
	ENDIF
	lcClave = ""
	IF !EMPTY(lcUsuario)
		lcClave = LeerClaveLoginWindows(lnIdEmpresa, lcEmpresaDB, lcUsuario)
	ENDIF
	toFormulario.chkRecuerda.Tag = "CARGANDO"
	toFormulario.txtClave.Value = lcClave
	toFormulario.chkRecuerda.Value = IIF(EMPTY(lcClave), 0, 1)
	toFormulario.chkRecuerda.Tag = ""
	IF lnAreaAnterior > 0
		SELECT (lnAreaAnterior)
	ENDIF
ENDPROC


PROCEDURE EliminarClaveLoginRecordadaActual
	LPARAMETERS toFormulario
	LOCAL lnAreaAnterior, lnIdEmpresa, lcEmpresaDB, lcUsuario, lcCursorEmpresa
	IF VARTYPE(toFormulario) <> "O" OR !PEMSTATUS(toFormulario, "grd1", 5)
		RETURN
	ENDIF
	lcCursorEmpresa = ALLTRIM(toFormulario.grd1.RecordSource)
	IF EMPTY(lcCursorEmpresa) OR !USED(lcCursorEmpresa)
		RETURN
	ENDIF
	lnAreaAnterior = SELECT()
	SELECT (lcCursorEmpresa)
	IF !EOF()
		lnIdEmpresa = EVALUATE(lcCursorEmpresa + ".idempresa")
		lcEmpresaDB = ALLTRIM(EVALUATE(lcCursorEmpresa + ".empresadb"))
		lcUsuario = ALLTRIM(toFormulario.txtUsuario.Value)
		IF !EMPTY(lcUsuario)
			=EliminarClaveLoginWindows(lnIdEmpresa, lcEmpresaDB, lcUsuario)
		ENDIF
	ENDIF
	IF lnAreaAnterior > 0
		SELECT (lnAreaAnterior)
	ENDIF
ENDPROC


FUNCTION ConfirmarCabeceraAnulacionVenta
	LPARAMETERS tnIdDocto, tnMotivo
	LOCAL lnAreaAnterior, llConfirmada, loError
	lnAreaAnterior=SELECT()
	llConfirmada=.F.
	TRY
		USE (pcSysDir+pcDB+"\cyvventas") SHARED AGAIN IN 0 ALIAS cIncVentaGeneral
		SELECT cIncVentaGeneral
		LOCATE FOR iddocto=tnIdDocto AND UPPER(ALLTRIM(origen))=="VTA" AND eliminado=0
		IF FOUND()
			IF status=0
				llConfirmada=.T.
			ELSE
				IF RLOCK()
					REPLACE status WITH 0, motivoanula WITH IIF(BETWEEN(tnMotivo,1,3),tnMotivo,2), fecmod WITH DATETIME()
					UNLOCK IN cIncVentaGeneral
					FLUSH IN cIncVentaGeneral
					llConfirmada=.T.
				ENDIF
			ENDIF
		ENDIF
	CATCH TO loError
		llConfirmada=.F.
	FINALLY
		IF USED("cIncVentaGeneral")
			UNLOCK IN cIncVentaGeneral
			USE IN cIncVentaGeneral
		ENDIF
		IF lnAreaAnterior>0
			SELECT (lnAreaAnterior)
		ENDIF
	ENDTRY
	RETURN llConfirmada
ENDFUNC


FUNCTION ConfirmarCabeceraEliminacionVenta
	LPARAMETERS tnIdDocto
	LOCAL lnAreaAnterior, llConfirmada, loError
	lnAreaAnterior=SELECT()
	llConfirmada=.F.
	TRY
		USE (pcSysDir+pcDB+"\cyvventas") SHARED AGAIN IN 0 ALIAS cIncVentaEliminar
		SELECT cIncVentaEliminar
		LOCATE FOR iddocto=tnIdDocto AND UPPER(ALLTRIM(origen))=="VTA"
		IF FOUND()
			IF eliminado=1 AND status=0
				llConfirmada=.T.
			ELSE
				IF RLOCK()
					REPLACE status WITH 0, eliminado WITH 1, fecmod WITH DATETIME()
					UNLOCK IN cIncVentaEliminar
					FLUSH IN cIncVentaEliminar
					llConfirmada=.T.
				ENDIF
			ENDIF
		ENDIF
	CATCH TO loError
		llConfirmada=.F.
	FINALLY
		IF USED("cIncVentaEliminar")
			UNLOCK IN cIncVentaEliminar
			USE IN cIncVentaEliminar
		ENDIF
		IF lnAreaAnterior>0
			SELECT (lnAreaAnterior)
		ENDIF
	ENDTRY
	RETURN llConfirmada
ENDFUNC

FUNCTION ConfirmarCabeceraAnulacionFiscalVenta
	LPARAMETERS tnIdDocto, tnMotivo
	LOCAL lnAreaAnterior, llAceptada, llConfirmada, loError
	lnAreaAnterior = SELECT()
	llAceptada = .F.
	llConfirmada = .F.
	TRY
		USE (pcSysDir+pcDB+"\sisDTE") SHARED AGAIN IN 0 ALIAS cIncFiscalDte
		SELECT cIncFiscalDte
		LOCATE FOR iddocto=tnIdDocto AND UPPER(ALLTRIM(origen))=="VTA" AND status=2
		llAceptada = FOUND()
		USE IN cIncFiscalDte
		IF llAceptada
			USE (pcSysDir+pcDB+"\cyvventas") SHARED AGAIN IN 0 ALIAS cIncFiscalVenta
			SELECT cIncFiscalVenta
			LOCATE FOR iddocto=tnIdDocto AND UPPER(ALLTRIM(origen))=="VTA" AND eliminado=0
			IF FOUND()
				IF status=0
					llConfirmada=.T.
				ELSE
					IF RLOCK()
						REPLACE status WITH 0, motivoanula WITH IIF(BETWEEN(tnMotivo,1,3),tnMotivo,2), fecmod WITH DATETIME()
						UNLOCK IN cIncFiscalVenta
						FLUSH IN cIncFiscalVenta
						llConfirmada=.T.
					ENDIF
				ENDIF
			ENDIF
			USE IN cIncFiscalVenta
		ENDIF
	CATCH TO loError
		llConfirmada=.F.
	FINALLY
		IF USED("cIncFiscalDte")
			USE IN cIncFiscalDte
		ENDIF
		IF USED("cIncFiscalVenta")
			UNLOCK IN cIncFiscalVenta
			USE IN cIncFiscalVenta
		ENDIF
		IF lnAreaAnterior>0
			SELECT (lnAreaAnterior)
		ENDIF
	ENDTRY
	RETURN llConfirmada
ENDFUNC


FUNCTION RegistrarInconsistenciaAnulacionVenta
	LPARAMETERS tnIdDocto, tcEtapa, tcCodigo, tcMensaje
	LOCAL lnAreaAnterior, lnIntento, llGuardada, loError
	lnAreaAnterior=SELECT()
	lnIntento=1
	llGuardada=.F.
	TRY
		USE (pcSysDir+pcDB+"\sisDTE") SHARED AGAIN IN 0 ALIAS cIncAnuVenta
		SELECT cIncAnuVenta
		LOCATE FOR iddocto=tnIdDocto AND UPPER(ALLTRIM(origen))=="VTA" AND status=-4 AND ;
			ALLTRIM(tipodte)=="IN" AND ALLTRIM(codigogeneracion)==LEFT(ALLTRIM(tcEtapa),80)
		IF FOUND()
			REPLACE intentos WITH intentos+1, mensaje WITH LEFT(ALLTRIM(tcMensaje),250), ;
				motivoerror WITH LEFT(ALLTRIM(tcCodigo),250), fechahora WITH DATETIME()
		ELSE
			CALCULATE MAX(intentos) TO lnIntento FOR iddocto=tnIdDocto AND UPPER(ALLTRIM(origen))=="VTA" AND ALLTRIM(tipodte)=="IN"
			lnIntento=NVL(lnIntento,0)+1
			INSERT INTO cIncAnuVenta (iddocto,origen,status,intentos,mensaje,motivoerror,codigogeneracion,fechahora,versiondte,tipodte) ;
				VALUES (tnIdDocto,"VTA",-4,lnIntento,LEFT(ALLTRIM(tcMensaje),250),LEFT(ALLTRIM(tcCodigo),250), ;
				LEFT(ALLTRIM(tcEtapa),80),DATETIME(),2,"IN")
		ENDIF
		FLUSH IN cIncAnuVenta
		llGuardada=.T.
	CATCH TO loError
		llGuardada=.F.
	FINALLY
		IF USED("cIncAnuVenta")
			USE IN cIncAnuVenta
		ENDIF
		IF lnAreaAnterior>0
			SELECT (lnAreaAnterior)
		ENDIF
	ENDTRY
	RETURN llGuardada
ENDFUNC


FUNCTION ResolverInconsistenciaAnulacionVenta
	LPARAMETERS tnIdDocto, tcEtapa
	LOCAL lnAreaAnterior, llResuelta, loError
	lnAreaAnterior=SELECT()
	llResuelta=.F.
	TRY
		USE (pcSysDir+pcDB+"\sisDTE") SHARED AGAIN IN 0 ALIAS cIncResVenta
		UPDATE cIncResVenta SET status=-5 WHERE iddocto=tnIdDocto AND UPPER(ALLTRIM(origen))=="VTA" AND ;
			status=-4 AND ALLTRIM(tipodte)=="IN" AND ALLTRIM(codigogeneracion)==LEFT(ALLTRIM(tcEtapa),80)
		FLUSH IN cIncResVenta
		llResuelta=.T.
	CATCH TO loError
		llResuelta=.F.
	FINALLY
		IF USED("cIncResVenta")
			USE IN cIncResVenta
		ENDIF
		IF lnAreaAnterior>0
			SELECT (lnAreaAnterior)
		ENDIF
	ENDTRY
	RETURN llResuelta
ENDFUNC

FUNCTION ValidarAnulacionVentaConsistente
	LPARAMETERS tnIdDocto
	LOCAL lnAreaAnterior, lcError, lcBase, lnEncabezado, lnDetalle, lnKardex
	LOCAL lnKardexDoc, lnCxc, lnPartida, lnPartidaDeta, loError

	lnAreaAnterior = SELECT()
	lcError = ""
	lcBase = pcSysDir + pcDB + "\"
	STORE 0 TO lnEncabezado, lnDetalle, lnKardex, lnKardexDoc, lnCxc, lnPartida, lnPartidaDeta

	TRY
		IF USED("cAuditAnuVenta")
			USE IN cAuditAnuVenta
		ENDIF
		IF USED("cAuditAnuDeta")
			USE IN cAuditAnuDeta
		ENDIF
		IF USED("cAuditAnuKar")
			USE IN cAuditAnuKar
		ENDIF
		IF USED("cAuditAnuKarDoc")
			USE IN cAuditAnuKarDoc
		ENDIF
		IF USED("cAuditAnuCxc")
			USE IN cAuditAnuCxc
		ENDIF
		IF USED("cAuditAnuPar")
			USE IN cAuditAnuPar
		ENDIF
		IF USED("cAuditAnuParDet")
			USE IN cAuditAnuParDet
		ENDIF

		USE (lcBase + "cyvventas") SHARED AGAIN IN 0 ALIAS cAuditAnuVenta
		USE (lcBase + "cyvventasdeta") SHARED AGAIN IN 0 ALIAS cAuditAnuDeta
		USE (lcBase + "siskardex") SHARED AGAIN IN 0 ALIAS cAuditAnuKar
		USE (lcBase + "siskardexdoc") SHARED AGAIN IN 0 ALIAS cAuditAnuKarDoc
		USE (lcBase + "cyvcuentasxcp") SHARED AGAIN IN 0 ALIAS cAuditAnuCxc
		USE (lcBase + "ctbpartidas") SHARED AGAIN IN 0 ALIAS cAuditAnuPar
		USE (lcBase + "ctbpartidasdeta") SHARED AGAIN IN 0 ALIAS cAuditAnuParDet

		SELECT cAuditAnuVenta
		COUNT TO lnEncabezado FOR iddocto = tnIdDocto AND UPPER(ALLTRIM(origen)) == "VTA" AND status = 0
		SELECT cAuditAnuDeta
		COUNT TO lnDetalle FOR iddocto = tnIdDocto AND status <> 0 AND eliminado = 0
		SELECT cAuditAnuKar
		COUNT TO lnKardex FOR iddocto = tnIdDocto AND status <> 0 AND eliminado = 0
		SELECT cAuditAnuKarDoc
		COUNT TO lnKardexDoc FOR iddocto = tnIdDocto AND status <> 0 AND eliminado = 0
		SELECT cAuditAnuCxc
		COUNT TO lnCxc FOR iddocto = tnIdDocto AND status <> 0 AND eliminado = 0
		SELECT cAuditAnuPar
		COUNT TO lnPartida FOR idpartida = tnIdDocto AND UPPER(ALLTRIM(origen)) == "VTA" AND monto <> 0 AND eliminado = 0
		SELECT cAuditAnuParDet
		COUNT TO lnPartidaDeta FOR idpartida = tnIdDocto AND UPPER(ALLTRIM(origen)) == "VTA" AND (debe <> 0 OR haber <> 0) AND eliminado = 0

		IF lnEncabezado <> 1
			lcError = lcError + " Encabezado no confirmado como anulado."
		ENDIF
		IF lnDetalle > 0
			lcError = lcError + " Detalle activo: " + ALLTRIM(STR(lnDetalle)) + "."
		ENDIF
		IF lnKardex > 0
			lcError = lcError + " Kardex de inventario activo: " + ALLTRIM(STR(lnKardex)) + "."
		ENDIF
		IF lnKardexDoc > 0
			lcError = lcError + " Kardex documental activo: " + ALLTRIM(STR(lnKardexDoc)) + "."
		ENDIF
		IF lnCxc > 0
			lcError = lcError + " Cuenta por cobrar activa: " + ALLTRIM(STR(lnCxc)) + "."
		ENDIF
		IF lnPartida > 0 OR lnPartidaDeta > 0
			lcError = lcError + " Partida contable con saldo."
		ENDIF
	CATCH TO loError
		lcError = "No se pudo verificar la anulacion: " + loError.Message
	FINALLY
		IF USED("cAuditAnuVenta")
			USE IN cAuditAnuVenta
		ENDIF
		IF USED("cAuditAnuDeta")
			USE IN cAuditAnuDeta
		ENDIF
		IF USED("cAuditAnuKar")
			USE IN cAuditAnuKar
		ENDIF
		IF USED("cAuditAnuKarDoc")
			USE IN cAuditAnuKarDoc
		ENDIF
		IF USED("cAuditAnuCxc")
			USE IN cAuditAnuCxc
		ENDIF
		IF USED("cAuditAnuPar")
			USE IN cAuditAnuPar
		ENDIF
		IF USED("cAuditAnuParDet")
			USE IN cAuditAnuParDet
		ENDIF
		IF lnAreaAnterior > 0
			SELECT (lnAreaAnterior)
		ENDIF
	ENDTRY

	RETURN ALLTRIM(lcError)
ENDFUNC

FUNCTION ValidarAnulacionCompraConsistente
	LPARAMETERS tnIdDocto
	LOCAL lnAreaAnterior, lcError, lcBase, lnEncabezado, lnDetalle, lnKardex
	LOCAL lnKardexDoc, lnCxp, lnPartida, lnPartidaDeta, loError

	lnAreaAnterior = SELECT()
	lcError = ""
	lcBase = pcSysDir + pcDB + "\"
	STORE 0 TO lnEncabezado, lnDetalle, lnKardex, lnKardexDoc, lnCxp, lnPartida, lnPartidaDeta

	TRY
		IF USED("cAuditAnuCompra")
			USE IN cAuditAnuCompra
		ENDIF
		IF USED("cAuditAnuComDet")
			USE IN cAuditAnuComDet
		ENDIF
		IF USED("cAuditAnuComKar")
			USE IN cAuditAnuComKar
		ENDIF
		IF USED("cAuditAnuComKarDoc")
			USE IN cAuditAnuComKarDoc
		ENDIF
		IF USED("cAuditAnuCxp")
			USE IN cAuditAnuCxp
		ENDIF
		IF USED("cAuditAnuComPar")
			USE IN cAuditAnuComPar
		ENDIF
		IF USED("cAuditAnuComParDet")
			USE IN cAuditAnuComParDet
		ENDIF

		USE (lcBase + "cyvcompras") SHARED AGAIN IN 0 ALIAS cAuditAnuCompra
		USE (lcBase + "cyvcomprasdeta") SHARED AGAIN IN 0 ALIAS cAuditAnuComDet
		USE (lcBase + "siskardex") SHARED AGAIN IN 0 ALIAS cAuditAnuComKar
		USE (lcBase + "siskardexdoc") SHARED AGAIN IN 0 ALIAS cAuditAnuComKarDoc
		USE (lcBase + "cyvcuentasxcp") SHARED AGAIN IN 0 ALIAS cAuditAnuCxp
		USE (lcBase + "ctbpartidas") SHARED AGAIN IN 0 ALIAS cAuditAnuComPar
		USE (lcBase + "ctbpartidasdeta") SHARED AGAIN IN 0 ALIAS cAuditAnuComParDet

		SELECT cAuditAnuCompra
		COUNT TO lnEncabezado FOR iddocto=tnIdDocto AND UPPER(ALLTRIM(origen))=="COM" AND (status=0 OR anulado=1 OR eliminado=1)
		SELECT cAuditAnuComDet
		COUNT TO lnDetalle FOR iddocto=tnIdDocto AND UPPER(ALLTRIM(origen))=="COM" AND status<>0 AND eliminado=0
		SELECT cAuditAnuComKar
		COUNT TO lnKardex FOR iddocto=tnIdDocto AND UPPER(ALLTRIM(origen))=="COM" AND status<>0 AND eliminado=0
		SELECT cAuditAnuComKarDoc
		COUNT TO lnKardexDoc FOR iddocto=tnIdDocto AND UPPER(ALLTRIM(origen))=="COM" AND status<>0 AND eliminado=0
		SELECT cAuditAnuCxp
		COUNT TO lnCxp FOR iddocto=tnIdDocto AND UPPER(ALLTRIM(origen))=="CXP" AND status<>0 AND eliminado=0
		SELECT cAuditAnuComPar
		COUNT TO lnPartida FOR idpartida=tnIdDocto AND UPPER(ALLTRIM(origen))=="COM" AND monto<>0
		SELECT cAuditAnuComParDet
		COUNT TO lnPartidaDeta FOR idpartida=tnIdDocto AND UPPER(ALLTRIM(origen))=="COM" AND (debe<>0 OR haber<>0)

		IF lnEncabezado<>1
			lcError=lcError+" Encabezado no confirmado como anulado."
		ENDIF
		IF lnDetalle>0
			lcError=lcError+" Detalle activo: "+ALLTRIM(STR(lnDetalle))+"."
		ENDIF
		IF lnKardex>0
			lcError=lcError+" Kardex de inventario activo: "+ALLTRIM(STR(lnKardex))+"."
		ENDIF
		IF lnKardexDoc>0
			lcError=lcError+" Kardex documental activo: "+ALLTRIM(STR(lnKardexDoc))+"."
		ENDIF
		IF lnCxp>0
			lcError=lcError+" Cuenta por pagar activa: "+ALLTRIM(STR(lnCxp))+"."
		ENDIF
		IF lnPartida>0 OR lnPartidaDeta>0
			lcError=lcError+" Partida contable con saldo."
		ENDIF
	CATCH TO loError
		lcError="No se pudo verificar la anulacion de compra: "+loError.Message
	FINALLY
		IF USED("cAuditAnuCompra")
			USE IN cAuditAnuCompra
		ENDIF
		IF USED("cAuditAnuComDet")
			USE IN cAuditAnuComDet
		ENDIF
		IF USED("cAuditAnuComKar")
			USE IN cAuditAnuComKar
		ENDIF
		IF USED("cAuditAnuComKarDoc")
			USE IN cAuditAnuComKarDoc
		ENDIF
		IF USED("cAuditAnuCxp")
			USE IN cAuditAnuCxp
		ENDIF
		IF USED("cAuditAnuComPar")
			USE IN cAuditAnuComPar
		ENDIF
		IF USED("cAuditAnuComParDet")
			USE IN cAuditAnuComParDet
		ENDIF
		IF lnAreaAnterior>0
			SELECT (lnAreaAnterior)
		ENDIF
	ENDTRY

	RETURN ALLTRIM(lcError)
ENDFUNC
