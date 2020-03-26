USE db_comercial_final
GO
IF OBJECT_ID('ew_ven_transacciones_medico_receptor') IS NOT NULL
BEGIN
	DROP VIEW ew_ven_transacciones_medico_receptor
END
GO
CREATE VIEW ew_ven_transacciones_medico_receptor
AS
SELECT
	[idr] = vtt.idr
	, [idtran] = vtt.idtran
	, [tipo_receptor] = vtt.tipo
	, [idtecnico_receptor] = vtt.idtecnico
FROM 
	ew_ven_transacciones_tecnicos AS vtt
WHERE 
	vtt.tipo = 1
GO
