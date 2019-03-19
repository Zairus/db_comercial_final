USE db_comercial_final
GO
IF OBJECT_ID('ew_sys_objetos') IS NOT NULL
BEGIN
	DROP TABLE ew_sys_objetos
END
GO
CREATE TABLE ew_sys_objetos (
	idr INT IDENTITY
	, objeto INT NOT NULL
	, nombre VARCHAR(100)
	, orden SMALLINT
	, menu SMALLINT
	, submenu SMALLINT
) ON [PRIMARY]
GO
