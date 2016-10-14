USE db_comercial_final

IF OBJECT_ID('DF_ew_sys_transacciones2_idu') IS NOT NULL
BEGIN
	ALTER TABLE ew_sys_transacciones2 DROP CONSTRAINT DF_ew_sys_transacciones2_idu
END

ALTER TABLE ew_sys_transacciones2 ALTER COLUMN idu INT NOT NULL
