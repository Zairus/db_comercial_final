USE db_comercial_final

ALTER TABLE ew_com_transacciones DROP CONSTRAINT DF_ew_com_transacciones_idmoneda

ALTER TABLE ew_com_transacciones ALTER COLUMN idmoneda INT NOT NULL

ALTER TABLE ew_com_transacciones ADD CONSTRAINT DF_ew_com_transacciones_idmoneda DEFAULT 0 FOR idmoneda
