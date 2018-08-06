USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cfd_cep') AND [name] = 'cep_cliente_path')
BEGIN
	ALTER TABLE ew_cfd_cep ADD cep_client_path VARCHAR(MAX) NOT NULL DEFAULT ''
END