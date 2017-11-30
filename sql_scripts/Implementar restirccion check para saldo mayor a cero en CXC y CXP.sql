USE db_comercial_final

IF OBJECT_ID('CK_ew_cxp_transacciones_saldo') IS NOT NULL
BEGIN
	ALTER TABLE ew_cxp_transacciones DROP CONSTRAINT CK_ew_cxp_transacciones_saldo
END

IF OBJECT_ID('CK_ew_cxc_transacciones_saldo') IS NOT NULL
BEGIN
	ALTER TABLE ew_cxc_transacciones DROP CONSTRAINT CK_ew_cxc_transacciones_saldo
END

ALTER TABLE ew_cxp_transacciones ADD CONSTRAINT CK_ew_cxp_transacciones_saldo
CHECK (saldo >= 0)

ALTER TABLE ew_cxc_transacciones ADD CONSTRAINT CK_ew_cxc_transacciones_saldo
CHECK (saldo >= 0)
