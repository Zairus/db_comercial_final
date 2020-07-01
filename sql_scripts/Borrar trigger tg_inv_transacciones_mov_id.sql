USE db_comercial_final
GO
IF OBJECT_ID('tg_inv_transacciones_mov_id') IS NOT NULL
BEGIN
	DROP TRIGGER tg_inv_transacciones_mov_id
END
