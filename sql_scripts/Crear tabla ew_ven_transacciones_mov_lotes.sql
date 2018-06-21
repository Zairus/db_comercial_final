USE db_comercial_final
GO
IF OBJECT_ID('ew_ven_transacciones_mov_lotes') IS NOT NULL
BEGIN
	DROP TABLE ew_ven_transacciones_mov_lotes
END
GO
CREATE TABLE ew_ven_transacciones_mov_lotes (
	idr INT IDENTITY
	, idtran INT NOT NULL
	, idarticulo INT NOT NULL
	, lote VARCHAR(25) NOT NULL
	, idmov MONEY
	, consecutivo INT NOT NULL DEFAULT 0
	, cantidad DECIMAL(18,6) NOT NULL DEFAULT 0
	, comentario VARCHAR(500) NOT NULL DEFAULT ''

	,CONSTRAINT [PK_ew_ven_transacciones_mov_lotes] PRIMARY KEY CLUSTERED (
		idtran ASC
		, idarticulo ASC
		, lote ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
