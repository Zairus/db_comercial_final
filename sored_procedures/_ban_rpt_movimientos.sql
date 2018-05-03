USE db_comercial_final
GO

-- =============================================
-- Author:		Fernanda Corona
-- Create date: FEBRERO 2010
-- Description:	Auxiliar de Movimientos de Bancos
-- Ejemplo:     EXEC _ban_rpt_movimientos 1, '01/05/10', '01/11/10', -1, -1
-- =============================================
ALTER PROCEDURE [dbo].[_ban_rpt_movimientos]
	@idsucursal AS SMALLINT
	,@fecha1 AS VARCHAR(50)
	,@fecha2 AS VARCHAR(50)
	,@idcuenta AS SMALLINT
	,@aplicados  AS SMALLINT 
AS

SET DATEFORMAT DMY
SET NOCOUNT ON

SELECT @fecha2 = @fecha2 + ' 23:59'

SELECT 
	[sucursal] = s.nombre
	,[cuenta] = ISNULL(RTRIM(bc.no_cuenta) + '-' + RTRIM(b.nombre ),'Sin Especificar')
	,[idtran] = bt.idtran
	,[idsucursal] = bt.idsucursal
	,[transaccion] = RTRIM(o.nombre)
	,[idcuenta] = bt.idcuenta 
	,[fecha] = bt.fecha
	,[folio] = bt.folio
	,[ingresos] = (CASE WHEN Cancelado = 0 THEN (CASE WHEN bt.tipo = 1 THEN bt.importe ELSE 0 END) ELSE 0 END)
	,[egresos] = (CASE WHEN Cancelado = 0 THEN (CASE WHEN bt.tipo<>1 THEN bt.importe ELSE 0 END) ELSE 0 END)
	,[saldo] = (CASE WHEN Cancelado = 0 THEN bt.importe * (CASE WHEN bt.tipo = 1 THEN 1 ELSE (-1) END) ELSE 0 END)
	,[aplicado] = bt.aplicado
	,[estado] = e.nombre
	,[tipo] = bt.tipo
	,[empresa] = dbo.fn_sys_empresa()	
FROM 
	ew_ban_transacciones AS bt
	LEFT JOIN ew_sys_sucursales	AS s
		ON s.idsucursal = bt.idsucursal 
	LEFT JOIN ew_ban_cuentas AS bc 
		ON bc.idcuenta = bt.idcuenta
	LEFT JOIN vew_entidades	AS b
		ON b.identidad = bc.idbanco AND b.idrelacion=5
	LEFT JOIN conceptos AS c
		ON c.idconcepto = bt.idconcepto
	LEFT JOIN estados AS e
		ON e.idestado = dbo.fn_sys_estadoActual(bt.idtran)
	LEFT JOIN objetos AS o
		ON o.codigo = bt.transaccion
WHERE
	bt.tipo IN (1,2)
	AND bt.idsucursal = (CASE @idsucursal WHEN 0 THEN bt.idsucursal ELSE @idsucursal END)
	AND bt.idcuenta = (CASE @idcuenta WHEN -1 THEN bt.idcuenta ELSE @idcuenta END)
	AND bt.fecha BETWEEN @fecha1 AND @fecha2
	AND bt.aplicado = (CASE @aplicados WHEN -1 THEN bt.aplicado ELSE @aplicados END)
ORDER BY
	cuenta
	,fecha
	,transaccion
GO
