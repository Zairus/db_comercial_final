USE db_comercial_final
GO
ALTER VIEW ew_inv_documentos_relacion
AS
SELECT
	[idr] = it.idr
	, [idtran] = it.idtran2
	, [fecha] = it.fecha
	, [transaccion] = o.nombre + ' [' + it.transaccion + ']'
	, [folio] = it.folio
	, [cargos] = (CASE WHEN it.transaccion = 'GDC1' THEN it.total ELSE 0 END)
	, [abonos] = (CASE WHEN it.transaccion = 'GDA1' THEN it.total ELSE 0 END)
	, [idtran2] = it.idtran
	, [objidtran] = it.idtran
FROM 
	ew_inv_transacciones AS it
	LEFT JOIN objetos AS o
		ON o.codigo = it.transaccion
GO
