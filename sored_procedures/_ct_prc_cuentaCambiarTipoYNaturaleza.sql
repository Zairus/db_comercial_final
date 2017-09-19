USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170526
-- Description:	Cambia la naturaleza y tipo de una cuenta y reprocesa saldos contables
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_cuentaCambiarTipoYNaturaleza] 
	@cuenta AS VARCHAR(20)
	, @tipo AS SMALLINT
	, @naturaleza AS SMALLINT
	, @confirm AS SMALLINT
AS

SET NOCOUNT ON

IF @confirm <> 7
BEGIN
	SELECT [resultado] = 'No se confirmo aplicar proceso, no se han hecho cambios.'
	RETURN
END

IF @tipo < 0 OR @naturaleza < 0
BEGIN
	RAISERROR('Error: No se ha indicado correctamente tipo y naturaleza.', 16, 1)
	RETURN
END

ALTER TABLE ew_ct_cuentas DISABLE TRIGGER tg_ew_ct_cuentas_u

UPDATE ew_ct_cuentas SET
	tipo = @tipo
	,@naturaleza = @naturaleza
WHERE
	cuenta = @cuenta

ALTER TABLE ew_ct_cuentas ENABLE TRIGGER tg_ew_ct_cuentas_u

EXEC [dbo].[_ct_prc_reprocesarSaldosContables] 1
GO
