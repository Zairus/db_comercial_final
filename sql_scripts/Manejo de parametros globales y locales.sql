USE db_comercial_final
GO
IF OBJECT_ID('ew_sys_parametros_local') IS NOT NULL
BEGIN
	DROP TABLE ew_sys_parametros_local
END
GO
CREATE TABLE ew_sys_parametros_local (
	idr INT IDENTITY
	,idparametro INT
	,codigo VARCHAR(100)
	,nombre VARCHAR(1000) NOT NULL DEFAULT ''
	,descripcion VARCHAR(MAX) NOT NULL DEFAULT ''
	,activo BIT NOT NULL DEFAULT 0
	,valor VARCHAR(MAX) NOT NULL DEFAULT ''
	,comando VARCHAR(MAX) NOT NULL DEFAULT ''

	,CONSTRAINT [PK_evoluware_parametros] PRIMARY KEY CLUSTERED (
		idparametro
	) ON [PRIMARY]
	,CONSTRAINT [UK_evoluware_parametros_codigo] UNIQUE (
		codigo
	) ON [PRIMARY]
) ON [PRIMARY]
GO
IF OBJECT_ID('ew_sys_parametros') IS NOT NULL
BEGIN
	INSERT INTO ew_sys_parametros_local (
		idparametro
		,codigo
		,nombre
		,descripcion
		,activo
		,valor
		,comando
	)
	SELECT
		idparametro
		,codigo
		,nombre
		,descripcion
		,activo
		,valor
		,comando
	FROM
		ew_sys_parametros
END
GO
IF EXISTS(SELECT * FROM sys.objects WHERE [name] = 'ew_sys_parametros' AND [type] = 'U')
BEGIN
	DROP TABLE ew_sys_parametros
END
GO
IF EXISTS(SELECT * FROM sys.objects WHERE [name] = 'ew_sys_parametros' AND [type] = 'V')
BEGIN
	DROP VIEW ew_sys_parametros
END
GO
CREATE VIEW ew_sys_parametros
AS
SELECT 
	pl.idr
	,pl.idparametro
	,pl.codigo
	,pl.nombre
	,pl.descripcion
	,pl.activo
	,pl.valor
	,pl.comando
FROM 
	ew_sys_parametros_local AS pl

UNION ALL

SELECT 
	ep.idr
	,ep.idparametro
	,ep.codigo
	,ep.nombre
	,ep.descripcion
	,ep.activo
	,ep.valor
	,ep.comando
FROM 
	db_comercial.dbo.evoluware_parametros AS ep
WHERE
	(SELECT COUNT(*) FROM ew_sys_parametros_local AS pl WHERE pl.codigo = ep.codigo) = 0
GO
CREATE TRIGGER [dbo].[tg_ew_sys_parametros_i]
	ON [dbo].[ew_sys_parametros]
	INSTEAD OF INSERT
AS

SET NOCOUNT ON

RAISERROR('Error: No se puede insertar registros de esta tabla.', 16, 1)
RETURN
GO
CREATE TRIGGER [dbo].[tg_ew_sys_parametros_u]
	ON [dbo].[ew_sys_parametros]
	INSTEAD OF UPDATE
AS

SET NOCOUNT ON

IF NOT EXISTS (
	SELECT * 
	FROM 
		ew_sys_parametros_local AS pl 
	WHERE 
		pl.idparametro IN (
			SELECT i.idparametro 
			FROM inserted AS i
		)
)
BEGIN
	INSERT INTO ew_sys_parametros_local (
		idparametro
		,codigo
		,nombre
		,descripcion
		,activo
		,valor
		,comando
	)
	SELECT
		idparametro
		,codigo
		,nombre
		,descripcion
		,activo
		,valor
		,comando
	FROM
		inserted
END
	ELSE
BEGIN
	UPDATE pl SET
		pl.activo = i.activo
		,pl.valor = i.valor
		,pl.comando = i.comando
	FROM
		inserted AS i
		LEFT JOIN ew_sys_parametros_local AS pl
			ON pl.idparametro = i.idparametro
END
GO
CREATE TRIGGER [dbo].[tg_ew_sys_parametros_d]
	ON [dbo].[ew_sys_parametros]
	INSTEAD OF DELETE
AS

SET NOCOUNT ON

RAISERROR('Error: No se puede borrar registros de esta tabla.', 16, 1)
RETURN
GO
SELECT * FROM ew_sys_parametros

SELECT * FROM ew_sys_parametros_local
