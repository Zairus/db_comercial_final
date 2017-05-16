USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cat_contactos_entidades') AND [name] = 'idsucursal')
BEGIN
	ALTER TABLE ew_cat_contactos_entidades ADD idsucursal SMALLINT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cat_contactos_entidades') AND [name] = 'puesto')
BEGIN
	ALTER TABLE ew_cat_contactos_entidades ADD puesto VARCHAR(50) NOT NULL DEFAULT ''
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cat_contactos_entidades') AND [name] = 'enviar_facturas')
BEGIN
	ALTER TABLE ew_cat_contactos_entidades ADD enviar_facturas BIT NOT NULL DEFAULT 0
END
