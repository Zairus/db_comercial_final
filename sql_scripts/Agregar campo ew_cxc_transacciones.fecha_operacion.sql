USE db_comercial_final

ALTER TABLE ew_cxc_transacciones ADD fecha_operacion DATETIME NOT NULL DEFAULT GETDATE()
ALTER TABLE ew_ban_transacciones ADD fecha_operacion DATETIME NOT NULL DEFAULT GETDATE()
GO

UPDATE ew_cxc_transacciones SET fecha_operacion = fecha
UPDATE ew_ban_transacciones SET fecha_operacion = fecha
GO