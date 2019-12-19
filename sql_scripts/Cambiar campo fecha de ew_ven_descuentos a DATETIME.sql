USE db_comercial_final

ALTER TABLE ew_ven_descuentos ALTER COLUMN fecha_inicio DATETIME NOT NULL
GO

ALTER TABLE ew_ven_descuentos ALTER COLUMN fecha_final DATETIME NOT NULL
GO