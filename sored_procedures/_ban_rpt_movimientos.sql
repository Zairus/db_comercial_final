USE db_comercial_final
GO
IF OBJECT_ID('_ban_rpt_movimientos') IS NOT NULL
BEGIN
	DROP PROCEDURE _ban_rpt_movimientos
END
GO
-- =============================================
-- Author:		Fernanda Corona
-- Create date: FEBRERO 2010
-- Description:	Auxiliar de Movimientos de Bancos
-- Ejemplo:     EXEC _ban_rpt_movimientos 1, '01/05/10', '01/11/10', -1, -1
-- =============================================
CREATE PROCEDURE [dbo].[_ban_rpt_movimientos]
	@idsucursal AS SMALLINT
	, @fecha1 AS VARCHAR(50)
	, @fecha2 AS VARCHAR(50)
	, @idcuenta AS SMALLINT
	, @aplicados  AS SMALLINT
	, @quefecha AS SMALLINT = 0 -- DESCONTINUADO... QUITAR.
AS

SET NOCOUNT ON

SELECT @fecha2 = @fecha2 + ' 23:59'

SELECT 
	[sucursal] = s.nombre
	, [cuenta] = ISNULL(RTRIM(bc.no_cuenta) + '-' + RTRIM(b.nombre ),'Sin Especificar')
	, [idtran] = bt.idtran
	, [idsucursal] = bt.idsucursal
	, [transaccion] = RTRIM(o.nombre)
	, [idcuenta] = bt.idcuenta 
	, [beneficiario] = ISNULL(ve.nombre, '')
	, [fecha] = bt.fecha
	, [concepto]=ISNULL(a.nombre, ISNULL(c.nombre, bc.no_cuenta))
	, [folio] = bt.folio
	, [ingresos] = (CASE WHEN Cancelado = 0 THEN (CASE WHEN bt.tipo = 1 THEN bt.importe ELSE 0 END) ELSE 0 END)
	, [egresos] = (CASE WHEN Cancelado = 0 THEN (CASE WHEN bt.tipo <> 1 THEN bt.importe ELSE 0 END) ELSE 0 END)
	, [saldo] = (CASE WHEN Cancelado = 0 THEN bt.importe * (CASE WHEN bt.tipo = 1 THEN 1 ELSE (-1) END) ELSE 0 END)
	, [aplicado] = bt.aplicado
	, [estado] = e.nombre
	, [tipo] = bt.tipo
	, [doc_comentario] = bt.comentario
	, [empresa] = dbo.fn_sys_empresa()	
FROM 
	ew_ban_transacciones AS bt
	LEFT JOIN ew_ban_transacciones_mov btm
		ON btm.idtran=bt.idtran
	LEFT JOIN ew_sys_sucursales	AS s
		ON s.idsucursal = bt.idsucursal 
	LEFT JOIN ew_ban_cuentas AS bc 
		ON bc.idcuenta = bt.idcuenta
	LEFT JOIN vew_entidades	AS b
		ON b.identidad = bc.idbanco AND b.idrelacion=5
	LEFT JOIN conceptos AS c
		ON c.idconcepto = btm.idconcepto
	LEFT JOIN estados AS e
		ON e.idestado = dbo.fn_sys_estadoActual(bt.idtran)
	LEFT JOIN objetos AS o
		ON o.codigo = bt.transaccion
	LEFT JOIN vew_entidades ve 
		ON ve.idrelacion=bt.idrelacion and ve.identidad=bt.identidad
	LEFT JOIN ew_articulos AS a
		ON a.idtipo = 2
		AND a.idarticulo = btm.idconcepto
WHERE
	bt.tipo IN (1, 2)
	AND bt.idsucursal = (CASE @idsucursal WHEN 0 THEN bt.idsucursal ELSE @idsucursal END)
	AND bt.idcuenta = (CASE @idcuenta WHEN -1 THEN bt.idcuenta ELSE @idcuenta END)
	AND bt.fecha BETWEEN @fecha1 AND @fecha2
	AND bt.aplicado = (CASE @aplicados WHEN -1 THEN bt.aplicado ELSE @aplicados END)
ORDER BY
	cuenta
	,bt.fecha
	,transaccion
GO
