USE db_comercial_final

IF OBJECT_ID('_tmp_existencias_carga') IS NOT NULL
BEGIN
	DROP TABLE _tmp_existencias_carga
END

IF OBJECT_ID('ew_articulos_existencia_carga') IS NOT NULL
BEGIN
	DROP TABLE ew_articulos_existencia_carga
END

CREATE TABLE ew_articulos_existencia_carga (
	idr INT NOT NULL IDENTITY
	,idalmacen INT NOT NULL
	,codigo VARCHAR(30) NOT NULL
	,serie VARCHAR(50) NOT NULL
	,lote VARCHAR(20) NOT NULL
	,caducidad SMALLDATETIME NOT NULL DEFAULT GETDATE()
	,nombre VARCHAR(200) NOT NULL DEFAULT ''
	,idmoneda SMALLINT NOT NULL DEFAULT 0
	,existencia DECIMAL(18,6) NOT NULL DEFAULT 0
	,costo DECIMAL(18,6) NOT NULL DEFAULT 0
	,idimpuesto1_valor DECIMAL(18,6) NOT NULL DEFAULT 0
	,idimpuesto2_valor DECIMAL(18,6) NOT NULL DEFAULT 0
	,CONSTRAINT [PK_ew_articulos_migracion] PRIMARY KEY CLUSTERED (
		[idalmacen] ASC
		,[codigo] ASC
		,[serie] ASC
		,[lote] ASC
	)
) ON [PRIMARY]

SELECT * FROM ew_articulos_existencia_carga
