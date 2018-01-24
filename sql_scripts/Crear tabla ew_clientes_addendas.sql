USE db_refriequipos_datos
GO
IF OBJECT_ID('ew_clientes_addendas') IS NOT NULL
BEGIN
	DROP TABLE ew_clientes_addendas
END
GO
CREATE TABLE [dbo].[ew_clientes_addendas] (
	idr INT IDENTITY
	,idcliente INT NOT NULL
	,procedimiento VARCHAR(500) NOT NULL
	,descripcion VARCHAR(500) NOT NULL DEFAULT ''

	,CONSTRAINT [PK_ew_clientes_addendas] PRIMARY KEY CLUSTERED (
		[idcliente]
		,[procedimiento]
	)
) ON [PRIMARY]
GO