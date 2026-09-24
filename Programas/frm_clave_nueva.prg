* Captura modal de una contrasena inicial; nunca muestra el texto al escribir.
DEFINE CLASS frmClaveNueva AS Form
    Caption = "Contrasena inicial del usuario"
    Width = 420
    Height = 208
    AutoCenter = .T.
    WindowType = 1
    ShowWindow = 1
    MinButton = .F.
    MaxButton = .F.
    Closable = .T.
    cUsuario = ""
    cClave = ""
    lAceptada = .F.

    ADD OBJECT lblInstruccion AS Label WITH ;
        Left = 18, Top = 14, Width = 385, Height = 32, WordWrap = .T., ;
        Caption = "Minimo 8 caracteres: mayuscula, minuscula, numero y simbolo."
    ADD OBJECT lblClave1 AS Label WITH ;
        Left = 18, Top = 57, Width = 120, Caption = "Contrasena nueva"
    ADD OBJECT txtClave1 AS TextBox WITH ;
        Left = 150, Top = 53, Width = 240, PasswordChar = "*"
    ADD OBJECT lblClave2 AS Label WITH ;
        Left = 18, Top = 96, Width = 120, Caption = "Repita contrasena"
    ADD OBJECT txtClave2 AS TextBox WITH ;
        Left = 150, Top = 92, Width = 240, PasswordChar = "*"
    ADD OBJECT cmdAceptar AS CommandButton WITH ;
        Left = 193, Top = 146, Width = 93, Caption = "Aceptar", Default = .T.
    ADD OBJECT cmdCancelar AS CommandButton WITH ;
        Left = 297, Top = 146, Width = 93, Caption = "Cancelar", Cancel = .T.

    PROCEDURE cmdAceptar.Click
        LOCAL lcMensaje, lcClave, lcClaveRepetida
        lcClave = ALLTRIM(THISFORM.txtClave1.Value)
        lcClaveRepetida = ALLTRIM(THISFORM.txtClave2.Value)
        THISFORM.txtClave1.Value = lcClave
        THISFORM.txtClave2.Value = lcClaveRepetida
        lcMensaje = ""
        IF NOT ValidarClaveFuerte(THISFORM.cUsuario, lcClave, @lcMensaje)
            MESSAGEBOX(lcMensaje, 48, "Contrasena no valida")
            THISFORM.txtClave1.SetFocus()
            RETURN
        ENDIF
        IF lcClave <> lcClaveRepetida
            MESSAGEBOX("Las contrasenas no coinciden.", 48, "Contrasena no valida")
            THISFORM.txtClave2.SetFocus()
            RETURN
        ENDIF
        THISFORM.cClave = lcClave
        THISFORM.lAceptada = .T.
        THISFORM.Hide()
    ENDPROC

    PROCEDURE cmdCancelar.Click
        THISFORM.Hide()
    ENDPROC
ENDDEFINE
