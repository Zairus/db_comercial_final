USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ct_polizas_configuracion') AND [name] = 'cuadrar')
BEGIN
	ALTER TABLE ew_ct_polizas_configuracion ADD cuadrar BIT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ct_polizas_configuracion') AND [name] = 'cuenta_cuadre_cargos')
BEGIN
	ALTER TABLE ew_ct_polizas_configuracion ADD cuenta_cuadre_cargos VARCHAR(100) NOT NULL DEFAULT ''
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ct_polizas_configuracion') AND [name] = 'cuenta_cuadre_abonos')
BEGIN
	ALTER TABLE ew_ct_polizas_configuracion ADD cuenta_cuadre_abonos VARCHAR(100) NOT NULL DEFAULT ''
END

SELECT * FROM ew_ct_polizas_configuracion
