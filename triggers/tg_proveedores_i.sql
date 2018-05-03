USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091201
-- Description:	Agregar términos para acreedores.
-- =============================================
ALTER TRIGGER [dbo].[tg_proveedores_i]
	ON [dbo].[ew_proveedores]
	FOR INSERT
AS 

SET NOCOUNT ON

IF EXISTS (SELECT * FROM inserted WHERE LEN(contabilidad) = 0)
BEGIN
	RAISERROR('Error: No es posible guardar un proveedor sin cuenta contable.', 16, 1)
	RETURN
END

INSERT INTO ew_proveedores_terminos
	(idproveedor)
SELECT
	idproveedor
FROM inserted
GO
