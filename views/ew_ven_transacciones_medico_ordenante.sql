USE db_comercial_final
GO
IF OBJECT_ID('ew_ven_transacciones_medico_ordenante') IS NOT NULL
BEGIN
	DROP VIEW ew_ven_transacciones_medico_ordenante
END
GO
CREATE VIEW ew_ven_transacciones_medico_ordenante
AS
SELECT
	[idr] = vtt.idr
	, [idtran] = vtt.idtran
	, [tipo_ordenante] = vtt.tipo
	, [idtecnico_ordenante] = vtt.idtecnico
FROM 
	ew_ven_transacciones_tecnicos AS vtt
WHERE 
	vtt.tipo = 0
GO
