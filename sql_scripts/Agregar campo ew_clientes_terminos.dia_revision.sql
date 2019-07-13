USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_clientes_terminos') AND [name] = 'dia_revision')
BEGIN
	ALTER TABLE ew_clientes_terminos ADD dia_revision INT NOT NULL DEFAULT 1
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_clientes_terminos') AND [name] = 'hora_revision')
BEGIN
	ALTER TABLE ew_clientes_terminos ADD hora_revision VARCHAR(20) NOT NULL DEFAULT 1
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_clientes_terminos') AND [name] = 'dia_pago')
BEGIN
	ALTER TABLE ew_clientes_terminos ADD dia_pago INT NOT NULL DEFAULT 1
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_clientes_terminos') AND [name] = 'hora_pago')
BEGIN
	ALTER TABLE ew_clientes_terminos ADD hora_pago VARCHAR(20) NOT NULL DEFAULT 1
END
