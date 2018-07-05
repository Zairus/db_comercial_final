USE db_comercial_final
GO
IF OBJECT_ID('ew_cfd_cep') IS NOT NULL
BEGIN
	DROP TABLE ew_cfd_cep
END
GO
CREATE TABLE ew_cfd_cep (
	idr INT IDENTITY
	, idcomprobante INT NOT NULL
	, fecha_operacion DATETIME
	, referencia VARCHAR(500) NOT NULL DEFAULT ''

	, idcliente INT NOT NULL DEFAULT 0
	, aplicado BIT NOT NULL DEFAULT 0

	, receptor_banco VARCHAR(500) NOT NULL DEFAULT ''
	, receptor_tipo_cuenta VARCHAR(10) NOT NULL DEFAULT ''
	, receptor_cuenta VARCHAR(50) NOT NULL DEFAULT ''
	, receptor_rfc VARCHAR(20) NOT NULL DEFAULT ''
	, receptor_concepto VARCHAR(MAX) NOT NULL DEFAULT ''
	, receptor_iva DECIMAL(18,6) NOT NULL DEFAULT 0
	, receptor_monto DECIMAL(18,6) NOT NULL DEFAULT 0

	, emisor_banco VARCHAR(500) NOT NULL DEFAULT ''
	, emisor_nombre VARCHAR(500) NOT NULL DEFAULT ''
	, emisor_tipo_cuenta VARCHAR(10) NOT NULL DEFAULT ''
	, emisor_cuenta VARCHAR(50) NOT NULL DEFAULT ''
	, emisor_rfc VARCHAR(20) NOT NULL DEFAULT ''

	, [cep_archivo] VARCHAR(MAX)
	, [cep_xml] XML

	, CONSTRAINT [PK_ew_cfd_cep] PRIMARY KEY CLUSTERED (
		[idcomprobante] ASC
	)
) ON [PRIMARY]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180629
-- Description:	Borrar CEP solo si no esta aplicado
-- =============================================
CREATE TRIGGER [dbo].[tg_ew_cfd_cep]
	ON [dbo].[ew_cfd_cep]
	INSTEAD OF DELETE
AS 

SET NOCOUNT ON

DECLARE
	@aplicado AS BIT

SELECT
	@aplicado = aplicado
FROM
	deleted
WHERE
	aplicado = 1

SELECT @aplicado = ISNULL(@aplicado, 0)

IF @aplicado = 0
BEGIN
	DELETE FROM ew_cfd_cep WHERE idcomprobante IN (SELECT idcomprobante FROM deleted)
END
GO
SELECT * FROM ew_cfd_cep
