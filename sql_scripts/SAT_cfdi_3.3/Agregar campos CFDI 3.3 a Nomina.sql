USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_nom_transacciones') AND [name] = 'idmetodo')
BEGIN
	ALTER TABLE ew_nom_transacciones ADD idmetodo INT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_nom_transacciones') AND [name] = 'cfd_iduso')
BEGIN
	ALTER TABLE ew_nom_transacciones ADD cfd_iduso INT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_nom_transacciones') AND [name] = 'idforma')
BEGIN
	ALTER TABLE ew_nom_transacciones ADD idforma INT NOT NULL DEFAULT 0
END
