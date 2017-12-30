USE db_comercial_final

GO
IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_transacciones_pagos') AND [name] = 'clabe_origen')
BEGIN
	ALTER TABLE ew_ven_transacciones_pagos ADD clabe_origen VARCHAR(18) NOT NULL DEFAULT ''
END
GO

ALTER TABLE ew_ven_transacciones_pagos ALTER COLUMN subtotal DECIMAL(18,6)
ALTER TABLE ew_ven_transacciones_pagos ALTER COLUMN impuesto1 DECIMAL(18,6)
ALTER TABLE ew_ven_transacciones_pagos ALTER COLUMN total DECIMAL(18,6)
