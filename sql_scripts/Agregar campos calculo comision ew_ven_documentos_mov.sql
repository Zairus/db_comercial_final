USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_documentos_mov') AND name = 'importe_pagado')
BEGIN
	ALTER TABLE ew_ven_documentos_mov ADD importe_pagado DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_documentos_mov') AND name = 'comision_porcentaje')
BEGIN
	ALTER TABLE ew_ven_documentos_mov ADD comision_porcentaje DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_documentos_mov') AND name = 'comision_importe_prev')
BEGIN
	ALTER TABLE ew_ven_documentos_mov ADD comision_importe_prev DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_documentos_mov') AND name = 'comision_pago_anterior')
BEGIN
	ALTER TABLE ew_ven_documentos_mov ADD comision_pago_anterior DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_documentos_mov') AND name = 'comision_importe')
BEGIN
	ALTER TABLE ew_ven_documentos_mov ADD comision_importe DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_documentos_mov') AND name = 'fecha_referencia')
BEGIN
	ALTER TABLE ew_ven_documentos_mov ADD fecha_referencia SMALLDATETIME NULL
END
