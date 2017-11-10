USE db_comercial_final
GO
IF OBJECT_ID('ew_cfd_comprobantes_mov_impuesto') IS NOT NULL
BEGIN
	DROP TABLE ew_cfd_comprobantes_mov_impuesto
END
GO
CREATE TABLE ew_cfd_comprobantes_mov_impuesto (
	idr INT IDENTITY
	,idtran INT NOT NULL
	,idmov2 MONEY NOT NULL
	,idimpuesto INT NOT NULL
	,idtasa INT NOT NULL
	,base DECIMAL(18,6) NOT NULL DEFAULT 0
	,importe DECIMAL(18,6) NOT NULL DEFAULT 0

	,CONSTRAINT [PK_ew_cfd_comprobantes_mov_impuesto] PRIMARY KEY CLUSTERED (
		[idtran]
		,[idmov2]
		,[idimpuesto]
		,[idtasa]
	)
) ON [PRIMARY]
GO
SELECT * FROM ew_cfd_comprobantes_mov_impuesto
