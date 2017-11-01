USE db_comercial

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('evoluware_cfd_sat_clasificaciones') AND [name] = 'idclasificacion')
BEGIN
	ALTER TABLE evoluware_cfd_sat_clasificaciones ADD idclasificacion INT NOT NULL DEFAULT 0
END

GO

UPDATE evoluware_cfd_sat_clasificaciones SET idclasificacion = idr

GO

SELECT * FROM evoluware_cfd_sat_clasificaciones
