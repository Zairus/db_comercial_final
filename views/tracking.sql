USE db_comercial_final
GO
IF OBJECT_ID('tracking') IS NOT NULL
BEGIN
	DROP VIEW tracking
END
GO
CREATE VIEW [dbo].[tracking]
AS
SELECT TOP (100) PERCENT
	[idr] = ROW_NUMBER() OVER (PARTITION BY mov.idtran_padre ORDER BY mov.idtran_padre)
	, [objidtran] = mov.idtran_hijo
	, [idtran] = mov.idtran_padre
	, [transaccion] = RTRIM(o.nombre) + ' [' + t.transaccion + ']'
	, [folio] = t.folio
	, [fecha] = t.fecha
	, [sucursal] = s.nombre
	, [estado] = dbo.fn_sys_estadoActualNombre(t.idtran)
FROM
	(
	SELECT TOP (100) PERCENT
		[idtran_padre] = CONVERT(INT, FLOOR(idmov2))
		, [idtran_hijo] = CONVERT(INT, FLOOR(idmov1))
	FROM 
		dbo.ew_sys_movimientos_acumula AS ma
	GROUP BY 
		CONVERT(INT, FLOOR(idmov2))
		, CONVERT(INT, FLOOR(idmov1))
	
	UNION ALL
	
	SELECT TOP (100) PERCENT
		[idtran_padre] = CONVERT(INT, FLOOR(idmov1))
		, [idtran_hijo] = CONVERT(INT, FLOOR(idmov2))
	FROM
		dbo.ew_sys_movimientos_acumula AS ma
	GROUP BY
		CONVERT(INT, FLOOR(idmov1))
		, CONVERT(INT, FLOOR(idmov2))
	) AS mov
	LEFT JOIN dbo.ew_sys_transacciones AS t 
		ON t.idtran = mov.idtran_hijo 
	LEFT OUTER JOIN dbo.objetos AS o 
		ON o.codigo = t.transaccion
	LEFT OUTER JOIN dbo.ew_sys_sucursales AS s 
		ON s.idsucursal = t.idsucursal
WHERE
	t.idtran IS NOT NULL
	AND mov.idtran_padre > 0
ORDER BY
	[objidtran]
GO
