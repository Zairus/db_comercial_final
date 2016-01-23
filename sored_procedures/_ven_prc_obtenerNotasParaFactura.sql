USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160123
-- Description:	Obtener notas de venta para factura
-- =============================================
ALTER PROCEDURE _ven_prc_obtenerNotasParaFactura
	@codcliente AS VARCHAR(20)
	,@fecha AS SMALLDATETIME
	,@formas AS VARCHAR(MAX)
AS

SET NOCOUNT ON

IF @codcliente = 'Todos'
BEGIN
	SELECT @codcliente = ''
END

CREATE TABLE #_tmp_formas (
	idr INT IDENTITY
	,seleccionar BIT
	,nombre VARCHAR(200)
	,idforma INT
)

INSERT INTO #_tmp_formas (
	seleccionar
	,nombre
	,idforma
)
SELECT
	[seleccionar] = REPLACE(dbo.fn_sys_campoDeCadena(valor, '|', 1), '-', '')
	,[nombre] = dbo.fn_sys_campoDeCadena(valor, '|', 2)
	,[idforma] = dbo.fn_sys_campoDeCadena(valor, '|', 3)
FROM 
	dbo._sys_fnc_separarMultilinea(@formas, '	')

--SELECT * FROM #_tmp_formas

SELECT
	[referencia] = vt.idtran
	,[idtran2] = vt.idtran
	,[r_fecha] = vt.fecha
	,[r_folio] = vt.folio
	,[r_cliente] = c.nombre
	,[r_importe] = vt.subtotal
	,[r_impuesto1] = vt.impuesto1
	,[r_impuesto2] = vt.impuesto2
	,[r_total] = vt.total
	,[saldo] = ct.saldo
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = vt.idtran
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = vt.idcliente
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = vt.idtran
WHERE
	vt.transaccion = 'EFA3'
	AND vt.cancelado = 0
	AND st.idestado IN (0, 50)
	AND c.codigo = (CASE WHEN @codcliente = '' THEN c.codigo ELSE @codcliente END)
	AND CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), vt.fecha, 3)) = @fecha
	AND (
		SELECT
			vtp.idforma
		FROM
			ew_ven_transacciones_pagos AS vtp
		WHERE
			vtp.idtran = vt.idtran
	) IN (
		SELECT tf.idforma 
		FROM #_tmp_formas AS tf 
		WHERE tf.seleccionar = 1
	)

DROP TABLE #_tmp_formas
GO
