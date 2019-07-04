USE db_aguate_datos

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_articulos_almacenes') AND [name] = 'ubicacion')
BEGIN
	ALTER TABLE ew_articulos_almacenes ADD ubicacion VARCHAR(25) NOT NULL DEFAULT ''
END
