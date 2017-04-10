USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091203
-- Description:	Autorizar pago de acreedor
-- =============================================
ALTER PROCEDURE [dbo].[_cxp_prc_pagoAutorizar]
	 @idtran AS BIGINT
	,@idu AS SMALLINT
	,@debug AS BIT = 0
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################
DECLARE
	@sql AS VARCHAR(2000) = ''
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@idsucursal AS SMALLINT
	,@idproveedor AS INT
	,@identidad AS INT
	,@fecha AS SMALLDATETIME

DECLARE
	@idarticulo AS INT

DECLARE
	@egreso_idtran AS INT
	,@transaccion AS VARCHAR(4) = 'BDA1'
	,@folio AS VARCHAR(15)

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################
SELECT
	 @usuario = usuario
	,@password = [password]
FROM 
	ew_usuarios
WHERE
	idu = @idu
	
SELECT
	 @idsucursal = ct.idsucursal
	,@idproveedor = ct.idproveedor
	,@identidad = ISNULL(e.identidad, 0)
	,@fecha = ct.fecha
FROM 
	ew_cxp_transacciones AS ct
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = ct.idproveedor
	LEFT JOIN vew_entidades AS e
		ON e.idrelacion = 3
		AND e.codigo = p.codigo
WHERE
	ct.idtran = @idtran

SELECT 
	@idarticulo = idarticulo
FROM 
	ew_articulos
WHERE
	codigo = dbo._sys_fnc_parametroTexto('CXP_CONCEPTOPAGO')

IF @idarticulo IS NULL
BEGIN
	RAISERROR('Error: No se ha configurado concepto de pago en bancos.', 16, 1)
	RETURN
END

IF @idu IS NULL
BEGIN
	RAISERROR('Errir: El usuario no es correcto.', 16, 1)
	RETURN
END

EXEC _sys_prc_insertarTransaccion
	 @usuario
	,@password
	,@transaccion
	,@idsucursal
	,'A'
	,@sql
	,6 --Longitod del folio
	,@egreso_idtran OUTPUT
	,'' --Afolio
	,@fecha --Afecha

SELECT
	@folio = folio
FROM
	ew_sys_transacciones
WHERE
	idtran = @egreso_idtran

IF @egreso_idtran IS NULL OR @folio IS NULL
BEGIN
	RAISERROR('Error: No se ha podido generar egreso bancario.', 16, 1)
	RETURN
END

INSERT INTO ew_ban_transacciones (
	 idtran
	,idtran2
	,transaccion
	,idsucursal
	,idcuenta
	,folio
	,fecha
	,idu
	,tipo
	,identidad
	,idrelacion
	,idforma
	,forma_referencia
	,idmoneda
	,tipocambio
	,importe
	,subtotal
	,impuesto
	,comentario
)
SELECT
	[idtran] = @egreso_idtran
	,[idtran2] = ct.idtran
	,[transaccion] = @transaccion
	,[idsucursal] = @idsucursal
	,[idcuenta] = ct.idcuenta
	,[folio] = @folio
	,[fecha] = ct.fecha
	,[idu] = @idu
	,[tipo] = 2
	,[identidad] = @identidad
	,[idrelacion] = 3
	,[idforma] = ct.idforma
	,[forma_referencia] = ct.folio
	,[idmoneda] = ct.idmoneda
	,[tipocambio] = ct.tipocambio
	,[importe] = (CASE WHEN ct.idmoneda = bc.idmoneda THEN ct.total ELSE ((ct.total * ct.tipocambio) / bm.tipocambio) END)
	,[subtotal] = ct.subtotal
	,[impuesto] = (ct.impuesto1 + ct.impuesto2 + ct.impuesto3 + ct.impuesto4)
	,[comentario] = ct.comentario
FROM
	ew_cxp_transacciones AS ct
	LEFT JOIN ew_ban_cuentas AS bc
		ON bc.idcuenta = ct.idcuenta
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = bc.idmoneda
WHERE
	ct.idtran = @idtran
	
INSERT INTO ew_ban_transacciones_mov (
	 idtran
	,idtran2
	,idmov2
	,consecutivo
	,idconcepto
	,importe
)
SELECT
	[idtran] = @egreso_idtran
	,[idtran2] = ct.idtran
	,[idmov2] = ct.idmov
	,[consecutivo] = 1
	,[idconcepto] = @idarticulo
	,[importe] = (CASE WHEN ct.idmoneda = bc.idmoneda THEN ct.total ELSE ((ct.total * ct.tipocambio) / bm.tipocambio) END)
FROM
	ew_cxp_transacciones AS ct
	LEFT JOIN ew_ban_cuentas AS bc
		ON bc.idcuenta = ct.idcuenta
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = bc.idmoneda
WHERE
	ct.idtran = @idtran

--------------------------------------------------------------------------------
-- AUTORIZAR PAGO ##############################################################
EXEC _sys_prc_trnAplicarEstado @idtran, 'AUT', @idu, 1

--------------------------------------------------------------------------------
-- PROCESAR EGRESO DE PAGO #####################################################
EXEC _ban_prc_egresoProcesar @egreso_idtran

--------------------------------------------------------------------------------
-- CONTABILIZAR PAGO ###########################################################
EXEC _ct_prc_polizaAplicarDeConfiguracion @egreso_idtran, 'DDA3', @idtran
GO
