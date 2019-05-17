USE db_comercial_final
GO
IF OBJECT_ID('ew_ven_comprobacion_ventas') IS NOT NULL
BEGIN
	DROP VIEW ew_ven_comprobacion_ventas
END
GO
CREATE VIEW ew_ven_comprobacion_ventas
AS
SELECT
	vt.idtran
	, vt.fecha
	, vt.folio
	, [cliente] = c.nombre
	, [cliente_codigo] = c.codigo
	, [total_documento] = vt.total - vt.redondeo
	, [total_detalle] = (SELECT SUM(vtm.total) FROM ew_ven_transacciones_mov AS vtm WHERE vtm.idtran = vt.idtran)
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = vt.idcliente
WHERE
	vt.cancelado = 0
	AND vt.transaccion = 'EFA3'
GO
