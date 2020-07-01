USE db_comercial_final
GO
IF OBJECT_ID('_cxp_rpt_analisisPorReferencia') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxp_rpt_analisisPorReferencia
END
GO
-- =============================================
-- Author:		Fernanda Corona
-- Create date: 20100101
-- Description:	Reporte que muestra los documentos por Referencia
-- =============================================
CREATE PROCEDURE [dbo].[_cxp_rpt_analisisPorReferencia]
	@codsuc AS INT = 0
	, @codigo AS VARCHAR(20)
	, @fecha1 AS VARCHAR(20)
	, @fecha2 AS VARCHAR(20)
	, @tipo AS TINYINT = 1
	, @idu AS SMALLINT 
	, @idmoneda AS SMALLINT = -1
AS

SET NOCOUNT ON

DECLARE	
	@msg AS VARCHAR(200)
	, @sql AS VARCHAR(4000)
	, @f1 AS VARCHAR(20)
	, @f2 AS VARCHAR(20)
	, @sCodsuc AS VARCHAR(100)
	, @sProvee AS VARCHAR(100)
	, @sucursales AS VARCHAR(20)

IF LEN(@codigo) = 0
BEGIN
	SELECT @msg = 'Falta seleccionar el proveedor.' 
	RAISERROR (@msg, 16, 1)
	RETURN
END

CREATE TABLE #tmp_cxp_axr (
	idtran BIGINT NOT NULL 
	, idtran1 BIGINT NOT NULL 
	, objlevel TINYINT DEFAULT(0)	
	, orden TINYINT DEFAULT (0)
	, tipo SMALLINT DEFAULT (1)
	, sucursal VARCHAR (60) DEFAULT ('')
	, transaccion VARCHAR (103) DEFAULT ('')
	, folio VARCHAR (20) DEFAULT ('')
	, concepto VARCHAR (150) DEFAULT ('')
	, fecha VARCHAR (8)  DEFAULT ('')
	, total DECIMAL(12, 2) DEFAULT (0)
	, aplicado DECIMAL(12, 2) DEFAULT (0)
	, saldo DECIMAL(12, 2) DEFAULT (0)
	, comentario TEXT DEFAULT('')
	, empresa VARCHAR (200) DEFAULT ('')	
	, proveedor VARCHAR (200) DEFAULT ('')	
	, moneda VARCHAR (10) DEFAULT ('')
	, caja_chica BIT DEFAULT(0)
)

SELECT 
	@f1 = CONVERT(VARCHAR(8), @fecha1, 3)
	, @f2 = CONVERT(VARCHAR(8), @fecha2, 3) + ' 23:59' 
	, @sProvee = ''
	, @sCodsuc = ''
	, @sucursales = sucursales 
FROM
	usuarios 
WHERE 
	idu = @idu
	
IF @codsuc > 0 
BEGIN
	SELECT @sCodsuc = 'AND (d.codsuc=' + CONVERT(VARCHAR(3),@codsuc) + ') '
END

-- Insertamos los documentos del proveedor
SELECT @sql = 'INSERT INTO #tmp_cxp_axr (
	idtran
	, idtran1
	, objlevel
	, orden
	, tipo
	, sucursal
	, fecha
	, transaccion
	, folio
	, concepto
	, total
	, aplicado
	, saldo
	, comentario
	, empresa
	, proveedor
	, moneda
	, caja_chica
)
SELECT
	d.idtran
	, d.idtran
	, 1
	, 1
	, d.tipo
	, s.nombre
	, CONVERT(VARCHAR(8), d.fecha, 3)
	, d.transaccion
	, d.folio
	, cc.nombre
	, d.total
	, aplicado = (
		CASE 
			WHEN d.caja_chica = 0 THEN 0 
			ELSE d.total * -1
		END
	)
	, saldo = (
		CASE 
			WHEN d.caja_chica = 0 THEN d.saldo 
			ELSE 0 
		END 
	)
	, d.comentario
	, empresa = dbo.fn_sys_empresa()
	, proveedor = p.nombre + '' ( '' + p.codigo + '' )''
	, moneda = m.nombre
	, caja_chica=d.caja_chica
FROM
	ew_cxp_transacciones AS d
	LEFT JOIN sucursales AS s 
		ON s.idsucursal = d.idsucursal
	LEFT JOIN ew_proveedores AS p 
		ON p.idproveedor = d.idproveedor
	LEFT JOIN ew_ban_monedas AS m 
		ON m.idmoneda = d.idmoneda
	LEFT JOIN conceptos AS cc 
		ON cc.idconcepto = d.idconcepto
WHERE
	d.cancelado = 0
	AND d.aplicado = 1
	AND d.tipo = ' + CONVERT(VARCHAR(1),@tipo) + '
	AND (''' + @sucursales + ''' = ''0'' OR s.idsucursal in (select codsuc = valor from  dbo.fn_sys_split(''' + @sucursales + ''','','')))	
	AND (d.fecha BETWEEN ''' + @f1 + ''' AND ''' + @f2 + ''')
	AND (p.codigo=''' + @codigo + ''') '
	+ (CASE WHEN @idmoneda>=0 THEN ' AND (d.idmoneda=' + CONVERT(VARCHAR(3),@idmoneda) + ') ' ELSE '' END) + '
ORDER BY
	d.idtran
'

EXEC (@sql)

-- Insertamos los movimientos que afectaron las facturas
INSERT INTO #tmp_cxp_axr (
	idtran
	, idtran1
	, objlevel
	, orden
	, tipo
	, sucursal
	, fecha
	, transaccion
	, folio
	, concepto
	, aplicado
	, saldo
	, comentario
	, empresa
	, proveedor
	, moneda
	, caja_chica
)
SELECT
	d.idtran
	, b.idtran1
	, 2
	, 1
	, d.tipo
	, s.nombre
	, CONVERT(VARCHAR(8),d.fecha,3)
	, transaccion = '. ' + d.transaccion
	, d.folio
	, ac.nombre
	, total = (
		CASE 
			WHEN d.tipo = b.tipo THEN a.importe 
			ELSE a.importe * -1
		END
	)
	, saldo = 0
	, d.comentario
	, empresa = dbo.fn_sys_empresa()
	, proveedor = p.nombre + '  ( ' + p.codigo + ' )'	
	, moneda = m.nombre
	, caja_chica = b.caja_chica
FROM
	#tmp_cxp_axr AS b
	LEFT JOIN ew_cxp_transacciones_mov AS a 
		ON b.idtran = (
			CASE 
				WHEN @tipo = 2 THEN a.idtran 
				ELSE a.idtran2 
			END
		)
	LEFT JOIN ew_cxp_transacciones AS d 
		ON d.idtran = (
			CASE 
				WHEN @tipo = 2 THEN a.idtran2 
				ELSE a.idtran 
			END
		)
	LEFT JOIN sucursales AS s 
		ON s.idsucursal = d.idsucursal
	LEFT JOIN ew_proveedores AS p 
		ON p.idproveedor = d.idproveedor
	LEFT JOIN ew_ban_monedas AS m 
		ON m.idmoneda = d.idmoneda
	LEFT JOIN conceptos AS ac 
		ON ac.idconcepto = d.idconcepto
WHERE
	d.cancelado = 0
	AND d.aplicado = 1
	AND d.cancelado = 0
	AND b.idtran > 0
	AND a.idtran IS NOT NULL
	AND d.tipo IN (1,2)
ORDER BY
	a.idtran

-- insertamos un renglon en blanco por cada factura
INSERT INTO #tmp_cxp_axr (
	idtran
	, idtran1
	, objlevel
	, orden
)
SELECT
	0
	, b.idtran1
	, 3
	, 2
FROM
	#tmp_cxp_axr AS b
WHERE
	b.objlevel = 1
	AND b.orden = 1

INSERT INTO #tmp_cxp_axr (
	idtran
	, idtran1
	, objlevel
	, orden
)
VALUES (
	0
	, 0
	, 0
	, 1
)

SELECT * 
FROM 
	#tmp_cxp_axr 
ORDER BY
	idtran1
	, objlevel
	, orden
	, idtran
GO
