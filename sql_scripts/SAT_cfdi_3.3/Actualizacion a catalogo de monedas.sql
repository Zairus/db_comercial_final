USE db_comercial_final
GO
IF OBJECT_ID('DF_ew_ban_monedas_mov_Moneda') IS NOT NULL
BEGIN
	ALTER TABLE ew_ban_monedas_mov
	DROP CONSTRAINT [DF_ew_ban_monedas_mov_Moneda]
END
GO
IF OBJECT_ID('PK_Monedas_Historico') IS NOT NULL
BEGIN
	ALTER TABLE ew_ban_monedas_mov
	DROP CONSTRAINT [PK_Monedas_Historico]
END
GO
ALTER TABLE ew_ban_monedas_mov ALTER COLUMN idmoneda INT NOT NULL
GO
ALTER TABLE ew_ban_monedas_mov 
ADD CONSTRAINT [PK_Monedas_Historico] PRIMARY KEY CLUSTERED ([idmoneda],[fecha])
GO
IF OBJECT_ID('ew_ban_monedas_local') IS NULL
BEGIN
	CREATE TABLE ew_ban_monedas_local (
		idr INT IDENTITY
		,idmoneda INT
		,codigo VARCHAR(10)
		,nombre VARCHAR(50) NOT NULL DEFAULT ''
		,activo BIT NOT NULL DEFAULT 1
		,factor0 DECIMAL(18,6) NOT NULL DEFAULT 0
		,factor1 DECIMAL(18,6) NOT NULL DEFAULT 0
		,factor2 DECIMAL(18,6) NOT NULL DEFAULT 0
		,factor3 DECIMAL(18,6) NOT NULL DEFAULT 0
		,fecha DATETIME NOT NULL DEFAULT GETDATE()
		,comentario VARCHAR(1000) NOT NULL DEFAULT ''

		,CONSTRAINT [PK_ew_ban_monedas_local] PRIMARY KEY CLUSTERED (
			idmoneda
		) ON [PRIMARY]
		,CONSTRAINT [UK_ew_ban_monedas_local_codigo] UNIQUE (
			codigo
		)
	) ON [PRIMARY]
END
GO
IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ban_monedas_local') AND [name] = 'activo')
BEGIN
	ALTER TABLE ew_ban_monedas_local ADD activo BIT NOT NULL DEFAULT 1
END
GO
IF OBJECT_ID('ew_ban_monedas') IS NOT NULL AND OBJECT_ID('ew_ban_monedas_local') IS NOT NULL
BEGIN
	IF (SELECT COUNT(*) FROM ew_ban_monedas_local) = 0
	BEGIN
		INSERT INTO ew_ban_monedas_local (
			idmoneda
			, codigo
			, nombre
			, factor0
			, factor1
			, factor2
			, factor3
			, fecha
			, comentario
		)
		SELECT
			[idmoneda] = idmoneda
			, [codigo] = nombre
			, [nombre] = nombre_corto
			, [factor0] = tipoCambio
			, [factor1] = tipoCambio1
			, [factor2] = tipoCambio2
			, [factor3] = tipoCambio3
			, [fecha] = fecha
			, [comentario] = comentario
		FROM
			ew_ban_monedas
	END
END
GO
IF OBJECT_ID('tg_ew_ban_monedas_local') IS NOT NULL
BEGIN
	DROP TRIGGER tg_ew_ban_monedas_local
END
GO
CREATE TRIGGER [dbo].[tg_ew_ban_monedas_local]
	ON [dbo].[ew_ban_monedas_local]
	FOR INSERT, UPDATE, DELETE
AS

SET NOCOUNT ON

DECLARE		
	@i AS INT
	,@cont AS INT
	,@msg AS VARCHAR(100)
	,@inserted AS INT
	,@deleted AS INT
	,@accion AS SMALLINT
	,@fecha AS SMALLDATETIME

	,@idmoneda AS SMALLINT
	,@tipoCambio AS DECIMAL(18,6)
	,@tipoCambio1 AS DECIMAL(18,6)
	,@tipoCambio2 AS DECIMAL(18,6)
	,@tipoCambio3 AS DECIMAL(18,6)

SELECT @inserted = COUNT(*) FROM inserted 
SELECT @deleted = COUNT(*) FROM deleted 

SELECT @accion = 0

IF @inserted > 0 
BEGIN 
	IF @deleted = 0
	BEGIN
		-- INSERT
		SELECT @accion = 1
	END
		ELSE
	BEGIN
		-- UPDATE
		SELECT @accion = 2
	END
END
	ELSE 
BEGIN 
	-- DELETE
	SELECT @accion = 3
END

IF @accion = 1 
BEGIN
	INSERT INTO ew_ban_monedas_mov (
		 idmoneda
		,TipoCambio
		,tipoCambio1
		,TipoCambio2
		,TipoCambio3
	) 
	SELECT 
		 i.idmoneda
		,i.factor0
		,i.factor1
		,i.factor2
		,i.factor3
	FROM 
		inserted AS i

	RETURN
END

IF @accion = 2 
BEGIN 
	IF UPDATE(factor0) OR UPDATE(factor1) OR UPDATE(factor2) OR UPDATE(factor3)
	BEGIN
		SELECT 
			@idmoneda = idmoneda
			, @tipocambio = factor0
			, @tipocambio1 = factor1
			, @tipocambio2 = factor2
			, @tipocambio3 = factor3
		FROM 
			inserted

		IF @idmoneda = 0 AND (@tipocambio <> 1 OR @tipocambio1 <> 1 OR @tipocambio2 <> 1 OR @tipocambio3 <> 1)
		BEGIN
			SELECT @msg = 'El tipo de cambio para M.N. no puede ser diferente de 1.'
			RAISERROR (@msg, 16, 1)
			RETURN
		END

		SELECT @fecha = fecha
		FROM inserted

		IF DATEPART(HOUR,@fecha) = 0 AND DATEPART(MINUTE, @fecha) = 0
		BEGIN
			SELECT @fecha = DATEADD(HOUR, DATEPART(HOUR, GETDATE()), @fecha)
			SELECT @fecha = DATEADD(MINUTE, DATEPART(MINUTE, GETDATE()), @fecha)
		END

		INSERT INTO ew_ban_monedas_mov 
			(idmoneda, TipoCambio, tipoCambio1, TipoCambio2, TipoCambio3, fecha) 
		SELECT 
			idmoneda, factor0, factor1, factor2, factor3, @fecha
		FROM
			inserted
		
		RETURN 
	END
END 

IF @accion = 3 
BEGIN
	SELECT @msg = 'No se pueden eliminar registros en la tabla de monedas.'
	RAISERROR (@msg, 16, 1)
	RETURN
END
GO
IF EXISTS(SELECT * FROM sys.objects WHERE [name] = 'ew_ban_monedas' AND [type] = 'U')
BEGIN
	DROP TABLE ew_ban_monedas
END
GO
IF EXISTS(SELECT * FROM sys.objects WHERE [name] = 'ew_ban_monedas' AND [type] = 'V')
BEGIN
	DROP VIEW ew_ban_monedas
END
GO
CREATE VIEW ew_ban_monedas
AS
SELECT
	[idr] = bml.idr
	,[idmoneda] = bml.idmoneda
	,[nombre] = bml.codigo
	,[nombre_corto] = bml.nombre
	,[codigo] = bml.codigo
	,[activo] = bml.activo
	,[tipocambio] = bml.factor0
	,[tipocambio1] = bml.factor1
	,[tipocambio2] = bml.factor2
	,[tipocambio3] = bml.factor3
	,[fecha] = bml.fecha
	,[comentario] = bml.comentario
FROM 
	ew_ban_monedas_local AS bml

UNION ALL

SELECT
	[idr] = csm.id + 1000
	,[idmoneda] = csm.id + 1000
	,[nombre] = csm.c_moneda
	,[nombre_corto] = csm.descripcion
	,[codigo] = csm.c_moneda
	,[activo] = 0
	,[tipocambio] = 1.00
	,[tipocambio1] = 1.00
	,[tipocambio2] = 1.00
	,[tipocambio3] = 1.00
	,[fecha] = NULL
	,[comentario] = ''
FROM 
	db_comercial.dbo.evoluware_cfd_sat_monedas AS csm
WHERE
	csm.c_moneda NOT IN (SELECT bml.codigo FROM ew_ban_monedas_local AS bml)
GO
CREATE TRIGGER [dbo].[tg_ew_ban_monedas]
	ON [dbo].[ew_ban_monedas]
	INSTEAD OF UPDATE
AS

SET NOCOUNT ON

IF UPDATE(tipocambio) OR UPDATE(tipocambio1) OR UPDATE(tipocambio2) OR UPDATE(tipocambio3)
BEGIN
	IF EXISTS(
		SELECT
			*
		FROM
			inserted AS i
		WHERE
			i.idmoneda NOT IN (SELECT bml.idmoneda FROM ew_ban_monedas_local AS bml)
	)
	BEGIN
		INSERT INTO ew_ban_monedas_local (
			idmoneda
			,codigo
			,nombre
			,fecha
			,factor0
			,factor1
			,factor2
			,factor3
			,comentario
		)
		SELECT
			i.idmoneda
			,i.nombre
			,i.nombre_corto
			,i.fecha
			,i.tipocambio
			,i.tipocambio1
			,i.tipocambio2
			,i.tipocambio3
			,i.comentario
		FROM
			inserted AS i
		WHERE
			i.idmoneda NOT IN (SELECT bml.idmoneda FROM ew_ban_monedas_local AS bml)
	END

	IF @@ROWCOUNT = 0
	BEGIN
		UPDATE bml SET
			bml.codigo = i.nombre
			,bml.nombre = i.nombre_corto
			,bml.fecha = i.fecha
			,bml.activo = i.activo
			,bml.factor0 = i.tipocambio
			,bml.factor1 = i.tipocambio1
			,bml.factor2 = i.tipocambio2
			,bml.factor3 = i.tipocambio3
			,bml.comentario = i.comentario
		FROM
			inserted AS i
			LEFT JOIN ew_ban_monedas_local AS bml
				ON bml.idmoneda = i.idmoneda
	END
END
GO
SELECT * FROM ew_ban_monedas_local

SELECT * FROM ew_ban_monedas
