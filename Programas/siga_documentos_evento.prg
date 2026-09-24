* Encola un documento ya guardado para SIGA Documentos.
* No usa red ni credenciales; SIGA Bridge publica el evento desde el VPS.
LPARAMETERS tcModulo, tnIdDocto
LOCAL lcModulo, lcDirectorio, lcTemporal, lcFinal, lcJson, loArchivos

IF VARTYPE(tcModulo) <> "C" OR VARTYPE(tnIdDocto) <> "N" OR tnIdDocto <= 0
    RETURN .F.
ENDIF
lcModulo = LOWER(ALLTRIM(tcModulo))
IF !INLIST(lcModulo, "ventas", "compras", "bancos", "partidas")
    RETURN .F.
ENDIF

TRY
    lcDirectorio = ADDBS(ADDBS(pcSysDir + pcDB) + "SigaDocumentosPendientes")
    loArchivos = CREATEOBJECT("Scripting.FileSystemObject")
    IF !loArchivos.FolderExists(lcDirectorio)
        loArchivos.CreateFolder(lcDirectorio)
    ENDIF
    lcFinal = lcDirectorio + lcModulo + "-" + ALLTRIM(STR(tnIdDocto)) + "-" + SYS(2015) + ".json"
    lcTemporal = lcFinal + ".tmp"
    lcJson = '{"module":"' + lcModulo + '","idDocto":' + ALLTRIM(STR(tnIdDocto)) + '}'
    IF STRTOFILE(lcJson, lcTemporal, 0) <> LEN(lcJson)
        RETURN .F.
    ENDIF
    loArchivos.MoveFile(lcTemporal, lcFinal)
    RETURN .T.
CATCH
    * Nunca revertir una venta, compra, movimiento o partida ya guardada.
    RETURN .F.
ENDTRY
