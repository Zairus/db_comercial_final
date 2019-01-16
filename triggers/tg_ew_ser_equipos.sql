USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190114
-- Description:	Validar al guardar equipos
-- =============================================
ALTER TRIGGER [dbo].[tg_ew_ser_equipos]
	ON [dbo].[ew_ser_equipos]
	FOR INSERT
AS 

IF EXISTS(SELECT * FROM inserted WHERE idsucursal1 = 0 OR idsucursal2 = 0 OR idsucursal3 = 0)
BEGIN
	RAISERROR('Error: Se deben especificar sucurales de facturasion, servicio y almacen.', 16, 1)
	RETURN
END
GO
