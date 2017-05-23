USE db_comercial_final
GO
IF OBJECT_ID('ew_proveedores_conceptos') IS NOT NULL
BEGIN
	DROP TABLE ew_proveedores_conceptos
END
GO
CREATE TABLE ew_proveedores_conceptos (
	idr INT IDENTITY
	,idproveedor INT
	,idarticulo INT

	,CONSTRAINT [PK_ew_proveedores_conceptos] PRIMARY KEY CLUSTERED (
		[idproveedor] ASC
		,[idarticulo] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
