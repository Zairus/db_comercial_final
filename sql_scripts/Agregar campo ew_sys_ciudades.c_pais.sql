USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_sys_ciudades') AND [name] = 'c_pais')
BEGIN
	ALTER TABLE ew_sys_ciudades ADD c_pais VARCHAR(10) NOT NULL DEFAULT ''
END
