USE db_comercial_final
GO
IF OBJECT_ID('ew_ban_formas_local') IS NOT NULL
BEGIN
	DROP TABLE ew_ban_formas_local
END
GO
CREATE TABLE ew_ban_formas_local (
	idr INT IDENTITY
	,idforma INT
	,codigo VARCHAR(4) NOT NULL
	,nombre VARCHAR(256) NOT NULL DEFAULT ''
	,activo BIT NOT NULL DEFAULT 1
	,maneja_cheques BIT NOT NULL DEFAULT 0
	,idmoneda INT NOT NULL DEFAULT 0
	,comentario VARCHAR(1000) NOT NULL DEFAULT ''
	,[version] VARCHAR(512) NOT NULL DEFAULT '3.2'

	,CONSTRAINT [PK_ew_ban_formas_local] PRIMARY KEY CLUSTERED (
		idforma
	)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_ew_ban_formas_local_codigo] ON [dbo].[ew_ban_formas_local] (codigo)
GO
INSERT INTO ew_ban_formas_local (
	idforma
	,codigo
	,nombre
	,activo
	,maneja_cheques
	,idmoneda
	,comentario
)
SELECT
	idforma
	,codigo
	,nombre
	,activo
	,maneja_cheques
	,idmoneda
	,comentario
FROM
	dbo.ew_ban_formas
GO
IF EXISTS(SELECT * FROM sys.objects WHERE [name] = 'ew_ban_formas' AND [type] = 'U')
BEGIN
	UPDATE bfl SET
		bfl.[version] = bfl.[version] + ',3.3'
	FROM
		ew_ban_formas_local AS bfl
		LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_formapago AS csf
			ON csf.c_formapago = bfl.codigo
	WHERE
		csf.idr IS NOT NULL
END
GO
IF EXISTS(SELECT * FROM sys.objects WHERE [name] = 'ew_ban_formas' AND [type] = 'U')
BEGIN
	DROP TABLE ew_ban_formas
END
GO
IF EXISTS(SELECT * FROM sys.objects WHERE [name] = 'ew_ban_formas' AND [type] = 'V')
BEGIN
	DROP VIEW ew_ban_formas
END
GO
CREATE VIEW ew_ban_formas
AS
SELECT
	bfl.idr
	,bfl.idforma
	,bfl.codigo
	,bfl.nombre
	,bfl.activo
	,bfl.maneja_cheques
	,bfl.idmoneda
	,bfl.comentario
	,bfl.[version]
FROM 
	ew_ban_formas_local AS bfl
	
UNION ALL

SELECT
	csf.idr
	,[idforma]  = csf.idr
	,[codigo] = csf.c_formapago
	,[nombre] = csf.descripcion
	,[activo] = 1
	,[maneja_cheques] = 0
	,[idmoneda] = 0
	,[comentario] = ''
	,[version] = '3.3'
FROM 
	db_comercial.dbo.evoluware_cfd_sat_formapago AS csf
WHERE
	(SELECT COUNT(*) FROM ew_ban_formas_local AS bfl WHERE bfl.codigo = csf.c_formapago) = 0
GO
IF OBJECT_ID('ew_ban_formas_aplica') IS NOT NULL
BEGIN
	DROP VIEW ew_ban_formas_aplica
END
GO
CREATE VIEW ew_ban_formas_aplica
AS
SELECT
	idforma
	,codigo
	,nombre
	,[descripcion] = '[' + codigo + '] ' + nombre
FROM 
	ew_ban_formas 
WHERE 
	activo = 1 
	AND dbo._sys_fnc_parametroTexto('CFDI_VERSION') IN (
		SELECT valor 
		FROM dbo._sys_fnc_separarMultilinea([version], ',')
	)
GO
SELECT * FROM ew_ban_formas

SELECT * FROM ew_ban_formas_aplica