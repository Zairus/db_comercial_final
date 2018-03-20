USE db_comercial_final
GO
-- =============================================
-- Author     : Paul Monge
-- Create date: 20180319
-- Description:	Listado de cheques
-- =============================================
ALTER PROCEDURE [dbo].[_ban_rpt_cheques]
	@idcuenta AS SMALLINT = 0
	,@fecha1 AS VARCHAR (50) = NULL
	,@fecha2 AS VARCHAR (50) = NULL
	,@cancelado AS SMALLINT = 0
	,@idconcepto AS SMALLINT = 0
AS

SET NOCOUNT ON

DECLARE
	@cuenta AS VARCHAR(50) = ''
	,@concepto AS VARCHAR(50) = ''

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(MONTH, -1, GETDATE())), 3) + ' 23:59')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

SELECT
	[cuenta] = r.nombre + ' - ' + d.no_cuenta
	,[chequera] = e.nombre
	,b.no_cheque
	,b.fecha_emision
	,[concepto] = c.nombre
	,a.referencia
	,b.nombre
	,b.importe
	,a.idtran
	,[usuario] = dbo.fn_sys_usuarioNombre(a.idu)
	,[estado] = dbo.fn_sys_estadoActualNombre(a.idtran)
	,a.cancelado
	,[empresa] = dbo.fn_sys_empresa()	
FROM 
	ew_ban_transacciones AS a
	LEFT JOIN ew_ban_transacciones_mov AS tm 
		ON tm.idtran = a.idtran
	LEFT JOIN ew_ban_cheques AS b 
		ON b.idtran = a.idtran
	LEFT JOIN conceptos AS c 
		ON c.idconcepto = tm.idconcepto
	LEFT JOIN c_transacciones AS t 
		ON t.idtran = a.idtran2
	LEFT JOIN ew_ban_chequeras AS e 
		ON e.idchequera =  b.idchequera
	LEFT JOIN ew_ban_cuentas AS d 
		ON d.idcuenta = e.idcuenta
	LEFT JOIN ew_ban_bancos AS r 
		ON r.idbanco = d.idbanco
WHERE 
	a.transaccion='BDA2'
	AND b.idr IS NOT NULL
	AND a.idcuenta = (CASE WHEN @idcuenta = 0 THEN a.idcuenta ELSE @idcuenta END)
	AND b.fecha_emision BETWEEN @fecha1 AND @fecha2
	AND tm.idconcepto = (CASE WHEN @idconcepto = 0 THEN tm.idconcepto ELSE @idconcepto END)
	AND a.cancelado = (CASE WHEN @cancelado = -1 THEN a.cancelado ELSE @cancelado END)
ORDER BY 
	r.nombre
	, d.no_cuenta
	, b.no_cheque
GO
