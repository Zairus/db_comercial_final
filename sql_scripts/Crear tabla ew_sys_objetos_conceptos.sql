USE db_comercial_final
GO
IF OBJECT_ID('ew_sys_objetos_conceptos') IS NOT NULL
BEGIN
	DROP TABLE ew_sys_objetos_conceptos
END
GO
CREATE TABLE ew_sys_objetos_conceptos (
	idr INT IDENTITY
	,objeto INT
	,idconcepto INT
	,bancario BIT NOT NULL DEFAULT 0
	,contabilidad1 VARCHAR(50) NOT NULL DEFAULT ''
	,contabilidad2 VARCHAR(50) NOT NULL DEFAULT ''

	,CONSTRAINT [PK_ew_sys_objetos_conceptos] PRIMARY KEY CLUSTERED (
		[objeto] ASC
		,[idconcepto] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
SELECT * FROM ew_sys_objetos_conceptos
