USE db_pesi_datos

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cfd_sat_clasificaciones') AND [name] = 'idclasificacion')
BEGIN
	ALTER TABLE ew_cfd_sat_clasificaciones ADD idclasificacion INT NOT NULL DEFAULT 0
END

GO

UPDATE ew_cfd_sat_clasificaciones SET idclasificacion = idr

GO

SELECT * FROM ew_cfd_sat_clasificaciones
