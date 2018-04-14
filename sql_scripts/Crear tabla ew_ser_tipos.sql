USE db_comercial_final
GO
IF OBJECT_ID('ew_ser_tipos') IS NOT NULL
BEGIN
	DROP TABLE ew_ser_tipos
END
GO
CREATE TABLE ew_ser_tipos (
	idr INT IDENTITY
	,idtiposervicio INT
	,codigo VARCHAR(30) NOT NULL DEFAULT ''
	,nombre VARCHAR(250) NOT NULL DEFAULT ''
	,activo BIT NOT NULL DEFAULT 1
	,fase SMALLINT NOT NULL DEFAULT 0
	,evaluacion BIT NOT NULL DEFAULT 0
	,comentario TEXT NOT NULL DEFAULT ''

	,CONSTRAINT [PK_ew_ser_tipos] PRIMARY KEY CLUSTERED (
		idtiposervicio
	)
	,CONSTRAINT [UK_ew_ser_tipos_codigo] UNIQUE (
		codigo
	)
) ON [PRIMARY]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180412
-- Description:	Administrar id de tipo de servicio
-- =============================================
CREATE TRIGGER tg_ew_ser_tipos_i
	ON ew_ser_tipos
	INSTEAD OF INSERT
AS 

SET NOCOUNT ON

INSERT INTO ew_ser_tipos (
	idtiposervicio
	,codigo
	,nombre
	,activo
	,fase
	,evaluacion
	,comentario
)
SELECT
	[idtiposervicio] = (
		ISNULL((
			SELECT MAX(st.idtiposervicio) 
			FROM ew_ser_tipos AS st
		), 0)
		+ ROW_NUMBER() OVER (ORDER BY i.codigo)
	)
	,i.codigo
	,i.nombre
	,i.activo
	,i.fase
	,i.evaluacion
	,i.comentario
FROM
	inserted AS i
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180412
-- Description:	No permitir borrar
-- =============================================
CREATE TRIGGER tg_ew_ser_tipos_d
	ON ew_ser_tipos
	INSTEAD OF DELETE
AS 

SET NOCOUNT ON

RAISERROR('Error: No sep ueden borrar registros.', 16, 1)
RETURN
GO
SELECT * FROM ew_ser_tipos