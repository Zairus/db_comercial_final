USE db_comercial_final
GO
IF OBJECT_ID('_ser_prc_eventoCrear') IS NOT NULL
BEGIN
	DROP PROCEDURE _ser_prc_eventoCrear
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200320
-- Description:	Crear evento en agenda de servicio
-- =============================================
CREATE PROCEDURE [dbo].[_ser_prc_eventoCrear]
	@idevento AS INT
	, @fecha_inicial AS DATETIME
	, @fecha_final AS DATETIME
	, @familia_idr AS INT
	, @cliente_nombre AS VARCHAR(200)
	, @cliente_codigo AS VARCHAR(30)
	, @tecnico_ordenante_nombre AS VARCHAR(200)
	, @tecnico_ordenante_codigo AS VARCHAR(10)
	, @comentario AS VARCHAR(4000)
AS

SET NOCOUNT ON

DECLARE
	@idcliente AS INT
	, @idtecnico_ordenante AS INT
	, @familia_codigo AS VARCHAR(4)

-- ############## VERIFICAR Y OBTENER CLIENTE
SELECT 
	@idcliente = c.idcliente
FROM 
	ew_clientes AS c
WHERE
	c.codigo = @cliente_codigo
	AND LEN(REPLACE(c.codigo, ' ', '')) > 0

IF @idcliente IS NULL
BEGIN
	EXEC [dbo].[_ven_prc_clienteObtenerSiguienteId]
		@idcliente OUTPUT
		, @cliente_codigo OUTPUT

	INSERT INTO ew_clientes (
		idcliente
		, codigo
		, nombre
		, nombre_corto
		, idforma
		, cfd_iduso
	) SELECT
		[idcliente] = @idcliente
		, [codigo] = @cliente_codigo
		, [nombre] = @cliente_nombre
		, [nombre_corto] = LEFT(@cliente_nombre, 15)
		, [idforma] = ISNULL((
			SELECT TOP 1 
				bfa.idforma 
			FROM 
				ew_ban_formas_aplica AS bfa 
			WHERE 
				bfa.codigo = '99'
		), 1)
		, [cfd_iduso] = 3

	INSERT INTO ew_clientes_facturacion (
		idcliente
		, idfacturacion
		, razon_social
		, rfc
		, email
	) SELECT
		[idcliente] = @idcliente
		, [idfacturacion] =  0
		, [razon_social] = @cliente_nombre
		, [rfc] = 'XAXX010101000'
		, [email] = 'cliente@ejemplo.com'
END

-- ############## VERIFICAR Y OBTENER TECNICO
IF @tecnico_ordenante_codigo IS NULL AND @tecnico_ordenante_nombre IS NULL
BEGIN
	GOTO NOTECNICO
END

SELECT
	@idtecnico_ordenante = sto.idtecnico
FROM
	ew_ser_tecnicos AS sto
WHERE
	sto.codigo = @tecnico_ordenante_codigo
	AND LEN(REPLACE(sto.codigo, ' ', '')) > 0

IF @idtecnico_ordenante IS NULL
BEGIN
	SELECT 
		@idtecnico_ordenante = MAX(sto.idtecnico) 
	FROM 
		ew_ser_tecnicos AS sto

	SELECT @idtecnico_ordenante = ISNULL(@idtecnico_ordenante, 0) + 1
	
	INSERT INTO ew_ser_tecnicos (
		idtecnico
		, codigo
		, nombre
	)
	SELECT
		[idtecnico] = @idtecnico_ordenante
		, [codigo] = 'T' + [dbo].[_sys_fnc_rellenar](@idtecnico_ordenante, 4, '0')
		, [nombre] = @tecnico_ordenante_nombre
END

NOTECNICO:

-- ############## OBTENER CODIGO DE FAMILIA
IF @familia_idr IS NULL
BEGIN
	GOTO NOFAM
END

SELECT
	@familia_codigo = f.codigo
FROM
	ew_articulos_niveles AS f
WHERE
	f.idr = @familia_idr

SELECT @familia_codigo = ISNULL(@familia_codigo, '')

NOFAM:

-- ############## SI SE ESTA EDITANTO, IR A EDITAR
IF ISNULL(@idevento, 0) > 0
BEGIN
	GOTO EDITEVENT
END

-- ############## OBTENER SIGUIENTE ID EVENTO
SELECT 
	@idevento = MAX(sc.idevento) 
FROM 
	ew_ser_calendario AS sc

SELECT @idevento = ISNULL(@idevento, 0) + 1

INSERT INTO ew_ser_calendario (
	idevento
	, referencia
	, idcliente
	, fecha_inicial
	, fecha_final
	, idtecnico_ordenante
	, familia_codigo
	, comentario
)
SELECT
	[idevento] = @idevento
	, [referencia] = ''
	, [idcliente] = @idcliente
	, [fecha_inicial] = @fecha_inicial
	, [fecha_final] = @fecha_final
	, [idtecnico_ordenante] = @idtecnico_ordenante
	, [familia_codigo] = @familia_codigo
	, [comentario] = @comentario

GOTO RETURNDATA

EDITEVENT:

UPDATE ew_ser_calendario SET
	referencia = ''
	, idcliente = @idcliente
	, fecha_inicial = @fecha_inicial
	, fecha_final = @fecha_final
	, idtecnico_ordenante = ISNULL(@idtecnico_ordenante, idtecnico_ordenante)
	, familia_codigo = ISNULL(@familia_codigo, familia_codigo)
	, comentario = @comentario
WHERE
	idevento = @idevento

RETURNDATA:

SELECT * 
FROM 
	[dbo].[ew_ser_web_calendario_citas] 
WHERE 
	TaskID = @idevento
GO
